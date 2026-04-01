# =============================================================================
# 02_clean_data.R — Construct analysis panel for ARRA Pell Bartik design
# =============================================================================

source("00_packages.R")

# ---- 1. Load raw data ----
enrollment_raw <- readRDS("../data/enrollment_raw.rds")
sfa_raw <- readRDS("../data/sfa_raw.rds")
inst_dir <- readRDS("../data/inst_directory.rds")

setDT(enrollment_raw)
setDT(sfa_raw)
setDT(inst_dir)

# ---- 2. Also get Pell data from the DuckDB SFA table ----
ipeds_path <- "../../../apep_1237/v1/data/ipeds.duckdb"
if (!file.exists(ipeds_path)) {
  candidates <- c("../../../apep_0859/v1/data/ipeds.duckdb",
                   "../../../apep_0858/v1/data/ipeds.duckdb")
  for (cand in candidates) if (file.exists(cand)) { ipeds_path <- cand; break }
}

ipeds_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ipeds_path, read_only = TRUE)

# Get Pell recipient counts and totals from SFA
sfa_db <- DBI::dbGetQuery(ipeds_con, "
  SELECT s.unitid, s.year,
         s.upgrntp AS pell_n,        -- Number of Pell recipients
         s.upgrntt AS pell_total,    -- Total Pell dollars
         s.scugrad AS sfa_undergrad, -- SFA-universe undergrad count
         s.fgrnt_p AS pct_fed_grant, -- % receiving federal grants
         s.pgrnt_p AS pct_pell       -- % receiving Pell (2007+)
  FROM sfa s
  JOIN hd h ON s.unitid = h.unitid AND s.year = h.year
  WHERE h.sector IN (4, 5)
    AND s.year BETWEEN 2002 AND 2015
")
DBI::dbDisconnect(ipeds_con, shutdown = TRUE)
setDT(sfa_db)
message(sprintf("SFA from DuckDB: %d obs", nrow(sfa_db)))

# ---- 3. Clean enrollment data ----
enroll <- enrollment_raw[, .(
  unitid, year,
  enroll_total = as.numeric(enroll_total),
  enroll_black = as.numeric(enroll_black),
  enroll_hisp  = as.numeric(enroll_hisp),
  enroll_white = as.numeric(enroll_white)
)]

# Drop rows with missing total enrollment
enroll <- enroll[!is.na(enroll_total) & enroll_total > 0]
message(sprintf("Enrollment after cleaning: %d obs, %d institutions",
                nrow(enroll), uniqueN(enroll$unitid)))

# ---- 4. Clean SFA/Pell data ----
# Use DuckDB SFA for Pell recipient counts; merge by unitid-year
sfa_clean <- sfa_db[, .(unitid, year, pell_n, sfa_undergrad, pct_pell)]
sfa_clean[, pell_n := as.numeric(pell_n)]
sfa_clean[, sfa_undergrad := as.numeric(sfa_undergrad)]
sfa_clean[, pct_pell := as.numeric(pct_pell)]

# Compute Pell share where we have counts
sfa_clean[, pell_share := fifelse(
  !is.na(pell_n) & !is.na(sfa_undergrad) & sfa_undergrad > 0,
  pell_n / sfa_undergrad,
  pct_pell / 100  # Fallback to percentage column
)]

message(sprintf("SFA with Pell share: %d obs, non-NA share: %d",
                nrow(sfa_clean), sum(!is.na(sfa_clean$pell_share))))

# ---- 5. Merge enrollment + SFA ----
panel <- merge(enroll, sfa_clean[, .(unitid, year, pell_n, pell_share)],
               by = c("unitid", "year"), all.x = TRUE)

message(sprintf("Merged panel: %d obs, Pell share non-NA: %d (%.1f%%)",
                nrow(panel), sum(!is.na(panel$pell_share)),
                100 * mean(!is.na(panel$pell_share))))

# ---- 6. Construct Bartik dose ----
# Pre-ARRA Pell share = average of 2007 and 2008 Pell shares
pre_arra <- panel[year %in% c(2007, 2008) & !is.na(pell_share),
                  .(pre_pell_share = mean(pell_share, na.rm = TRUE)),
                  by = unitid]

message(sprintf("Institutions with pre-ARRA Pell share: %d", nrow(pre_arra)))
message(sprintf("Pre-ARRA Pell share: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f",
                mean(pre_arra$pre_pell_share), sd(pre_arra$pre_pell_share),
                min(pre_arra$pre_pell_share), max(pre_arra$pre_pell_share)))

panel <- merge(panel, pre_arra, by = "unitid", all.x = TRUE)

# Bartik dose = pre-ARRA Pell share (continuous treatment intensity)
# $619 maximum award increase × share exposed
panel[, bartik_dose := pre_pell_share * 619]

# Post-ARRA indicator
panel[, post := as.integer(year >= 2009)]

# ARRA active period (2009-2011)
panel[, arra_active := as.integer(year >= 2009 & year <= 2011)]

# Phase-out period (2012+)
panel[, arra_phaseout := as.integer(year >= 2012)]

# ---- 7. Create high/low Pell terciles for descriptives ----
panel[!is.na(pre_pell_share), pell_tercile := cut(
  pre_pell_share,
  breaks = quantile(pre_pell_share, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
  labels = c("Low", "Medium", "High"),
  include.lowest = TRUE
)]

# ---- 8. Compute log outcomes ----
panel[, log_enroll_total := log(enroll_total + 1)]
panel[, log_enroll_black := log(enroll_black + 1)]
panel[, log_enroll_hisp  := log(enroll_hisp + 1)]
panel[, log_enroll_white := log(enroll_white + 1)]

# Compute racial shares
panel[enroll_total > 0, black_share := enroll_black / enroll_total]
panel[enroll_total > 0, hisp_share := enroll_hisp / enroll_total]
panel[enroll_total > 0, white_share := enroll_white / enroll_total]

# ---- 9. Filter to balanced-ish panel ----
# Check year coverage distribution
inst_coverage <- panel[, .N, by = unitid]
message("Coverage distribution:")
print(quantile(inst_coverage$N, probs = c(0, 0.1, 0.25, 0.5, 0.75, 0.9, 1)))

# Keep institutions observed in at least 5 years (flexible for IPEDS reporting gaps)
keep_insts <- inst_coverage[N >= 5, unitid]
panel <- panel[unitid %in% keep_insts]

# Must have pre-ARRA Pell share
panel <- panel[!is.na(pre_pell_share)]

message(sprintf("\n=== Final Panel ==="))
message(sprintf("Institutions: %d", uniqueN(panel$unitid)))
message(sprintf("Years: %d - %d", min(panel$year), max(panel$year)))
message(sprintf("Obs: %d", nrow(panel)))
message(sprintf("Pre-ARRA Pell share: mean=%.3f, sd=%.3f",
                mean(panel$pre_pell_share), sd(panel$pre_pell_share)))

# ---- 10. Summary stats by Pell tercile ----
summ <- panel[year == 2008, .(
  n_inst = .N,
  mean_enroll = mean(enroll_total, na.rm = TRUE),
  mean_black = mean(enroll_black, na.rm = TRUE),
  mean_hisp = mean(enroll_hisp, na.rm = TRUE),
  mean_white = mean(enroll_white, na.rm = TRUE),
  mean_pell_share = mean(pre_pell_share, na.rm = TRUE)
), by = pell_tercile]
print(summ)

# ---- 11. Save ----
saveRDS(panel, "../data/analysis_panel.rds")
message("Panel saved to ../data/analysis_panel.rds")
