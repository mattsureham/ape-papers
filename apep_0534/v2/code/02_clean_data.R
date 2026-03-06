## 02_clean_data.R — Build application-level analysis dataset
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)
##
## KEY CHANGE FROM v1: Include abandoned applications (ABN) alongside grants (ISS).
## Construct examiner grant RATE (applications denominator) not just grant share.

source("00_packages.R")

cat("=== Loading PatEx application data ===\n")
patex <- as.data.table(read_parquet(file.path(DATA_DIR, "patex_applications.parquet")))
cat("PatEx rows:", format(nrow(patex), big.mark = ","), "\n")

# ── Parse dates ──────────────────────────────────────────────────────────
patex[, filing_date := as.Date(filing_date)]
patex[, filing_year := year(filing_date)]
patex[, granted := as.integer(disposal_type == "ISS")]

# ── Load PatentsView CPC for Y02 identification ─────────────────────────
cat("\n=== Loading CPC data for Y02 identification ===\n")
cpc <- fread(file.path(DATA_DIR, "g_cpc_current.tsv"),
             colClasses = c(patent_id = "character"))
cpc_cols <- names(cpc)
cat("CPC records:", format(nrow(cpc), big.mark = ","), "\n")
cat("CPC columns:", paste(cpc_cols, collapse = ", "), "\n")

# Identify Y02 patents in PatentsView
if ("cpc_group" %in% cpc_cols) {
  y02_cpc <- cpc[grepl("^Y02", cpc_group) | grepl("^Y02", cpc_subclass)]
} else {
  y02_cpc <- cpc[grepl("^Y02", cpc_subclass)]
}

# Primary Y02 code per patent
seq_col <- intersect(names(y02_cpc), "cpc_sequence")
if (length(seq_col) > 0) {
  y02_cpc <- y02_cpc[order(patent_id, cpc_sequence)]
} else {
  y02_cpc <- y02_cpc[order(patent_id)]
}
y02_primary <- y02_cpc[, .SD[1], by = patent_id]

if (!"cpc_group" %in% names(y02_primary)) {
  y02_primary[, cpc_group := cpc_subclass]
}

y02_primary[, y02_domain := fcase(
  grepl("^Y02E", cpc_group) | grepl("^Y02E", cpc_subclass), "Energy",
  grepl("^Y02B", cpc_group) | grepl("^Y02B", cpc_subclass), "Buildings",
  grepl("^Y02P", cpc_group) | grepl("^Y02P", cpc_subclass), "Production",
  grepl("^Y02T", cpc_group) | grepl("^Y02T", cpc_subclass), "Transport",
  grepl("^Y02C", cpc_group) | grepl("^Y02C", cpc_subclass), "CarbonCapture",
  grepl("^Y02W", cpc_group) | grepl("^Y02W", cpc_subclass), "Waste",
  default = "Other_Y02"
)]

y02_ids <- unique(y02_primary$patent_id)
cat("Y02 patents in PatentsView:", format(length(y02_ids), big.mark = ","), "\n")

# ── Link PatEx ISS applications to PatentsView Y02 ──────────────────────
cat("\n=== Linking PatEx to Y02 classifications ===\n")

# For granted patents: direct link via patent_number
patex[, patent_number_clean := trimws(patent_number)]
patex[patent_number_clean == "", patent_number_clean := NA_character_]

# Tag which PatEx grants are Y02
patex[, is_y02_direct := patent_number_clean %in% y02_ids]
cat("Direct Y02 match (ISS with patent_number):",
    format(sum(patex$is_y02_direct, na.rm = TRUE), big.mark = ","), "\n")

# Merge Y02 CPC info for matched patents
patex <- merge(patex,
               y02_primary[, .(patent_id, cpc_group, cpc_subclass, y02_domain)],
               by.x = "patent_number_clean", by.y = "patent_id",
               all.x = TRUE)

# ── Identify Y02 art units for ABN application inclusion ────────────────
# Strategy: Art units where >10% of resolved applications are Y02 grants
cat("\n=== Identifying Y02 art units ===\n")

au_y02_share <- patex[disposal_type == "ISS",
                       .(n_total = .N,
                         n_y02 = sum(is_y02_direct, na.rm = TRUE)),
                       by = examiner_art_unit]
au_y02_share[, y02_share := n_y02 / n_total]
y02_art_units <- au_y02_share[y02_share > 0.10 & n_y02 >= 50]$examiner_art_unit
cat("Art units with >10% Y02 share:", length(y02_art_units), "\n")
cat("  Total ISS in these AUs:", format(sum(au_y02_share[examiner_art_unit %in% y02_art_units]$n_total), big.mark = ","), "\n")
cat("  Y02 ISS in these AUs:", format(sum(au_y02_share[examiner_art_unit %in% y02_art_units]$n_y02), big.mark = ","), "\n")

# Tag ABN applications in Y02 art units
patex[, is_y02_au := examiner_art_unit %in% y02_art_units]

# Final Y02 flag: ISS with direct match OR in a Y02 art unit (for both ISS and ABN)
# For the analysis: use applications in Y02 art units
# (ISS patents are confirmed Y02; ABN applications are in the same technology space)
patex[, in_sample := is_y02_au]

dt <- patex[in_sample == TRUE]
cat("\nSample in Y02 art units:", format(nrow(dt), big.mark = ","), "applications\n")
cat("  ISS:", format(sum(dt$granted), big.mark = ","), "\n")
cat("  ABN:", format(sum(1 - dt$granted), big.mark = ","), "\n")
cat("  Grant rate:", round(mean(dt$granted) * 100, 1), "%\n")

# ── Construct examiner grant RATE ────────────────────────────────────────
cat("\n=== Computing examiner grant rate (application-level) ===\n")

# Count grants and total applications per examiner × art_unit × filing_year
exam_stats <- dt[, .(n_grants = sum(granted),
                      n_apps = .N),
                  by = .(examiner_id, examiner_art_unit, filing_year)]

# Total per art_unit × filing_year
au_fy_total <- dt[, .(au_grants = sum(granted),
                       au_apps = .N,
                       n_examiners = uniqueN(examiner_id)),
                   by = .(examiner_art_unit, filing_year)]

exam_stats <- merge(exam_stats, au_fy_total,
                    by = c("examiner_art_unit", "filing_year"))

# Leave-one-out grant rate:
# Z_i = (grants by examiner j in cell, excluding i's outcome) / (apps in cell, excluding i)
# For application i assigned to examiner j:
#   numerator = grants by j in this AU-year minus i's own grant status
#   denominator = total apps by j in this AU-year minus 1
# But we compute at examiner-cell level first, then adjust per-observation
exam_stats[, loo_grant_rate := (n_grants - 1) / (n_apps - 1)]
exam_stats[n_apps <= 1, loo_grant_rate := NA]

# Also compute examiner grant rate using ALL other examiners in the cell (standard LOO)
exam_stats[, loo_rate_cell := (au_grants - n_grants) / (au_apps - n_apps)]
exam_stats[au_apps <= n_apps, loo_rate_cell := NA]

# Keep cells with enough examiners for variation
exam_stats <- exam_stats[n_examiners >= 3]

cat("Examiner-year cells:", format(nrow(exam_stats), big.mark = ","), "\n")
cat("LOO grant rate range:",
    round(range(exam_stats$loo_grant_rate, na.rm = TRUE), 3), "\n")

# ── Merge grant rate into analysis dataset ───────────────────────────────
dt <- merge(dt,
            exam_stats[, .(examiner_id, examiner_art_unit, filing_year,
                           loo_grant_rate, loo_rate_cell,
                           n_grants, n_apps, au_apps, n_examiners)],
            by = c("examiner_id", "examiner_art_unit", "filing_year"),
            all.x = TRUE)

# Per-observation LOO adjustment: for each application, adjust the examiner's
# rate by removing this specific application's outcome
dt[!is.na(loo_grant_rate), loo_grant_rate_i := (n_grants - granted) / (n_apps - 1)]
dt[n_apps <= 1, loo_grant_rate_i := NA]

# Drop observations without valid instrument
dt <- dt[!is.na(loo_grant_rate_i)]

cat("\nAfter grant rate merge:", format(nrow(dt), big.mark = ","), "applications\n")
cat("  ISS:", format(sum(dt$granted), big.mark = ","), "\n")
cat("  ABN:", format(sum(1 - dt$granted), big.mark = ","), "\n")

# ── Build follow-on innovation outcomes ──────────────────────────────────
cat("\n=== Building follow-on innovation outcomes ===\n")

# Load patent metadata for grant dates
patent <- fread(file.path(DATA_DIR, "g_patent.tsv"),
                select = c("patent_id", "patent_date", "patent_type", "num_claims"),
                colClasses = c(patent_id = "character"))

# All Y02 patents with their CPC subclass and grant date
y02_all <- merge(
  patent[patent_id %in% y02_ids, .(patent_id, patent_date, num_claims)],
  y02_primary[, .(patent_id, cpc_subclass, cpc_group)],
  by = "patent_id"
)
y02_all[, patent_date := as.Date(patent_date)]
y02_all[, grant_year := year(patent_date)]

# Annual follow-on activity by subclass
y02_annual <- y02_all[, .(n_y02 = .N), by = .(cpc_subclass, year = grant_year)]

all_sub <- unique(y02_annual$cpc_subclass)
all_yr  <- min(y02_annual$year):max(y02_annual$year)
grid <- CJ(cpc_subclass = all_sub, year = all_yr)
grid <- merge(grid, y02_annual, by = c("cpc_subclass", "year"), all.x = TRUE)
grid[is.na(n_y02), n_y02 := 0L]
setkey(grid, cpc_subclass, year)
grid[, cum_y02 := cumsum(n_y02), by = cpc_subclass]

# Build lookup
cum_lookup <- grid[, .(key = paste0(cpc_subclass, "_", year), cum_y02)]
cum_env <- new.env(hash = TRUE, size = nrow(cum_lookup))
for (i in seq_len(nrow(cum_lookup))) {
  cum_env[[cum_lookup$key[i]]] <- cum_lookup$cum_y02[i]
}
max_grid_yr <- max(grid$year)

max_cum_lookup <- grid[year == max_grid_yr, .(cpc_subclass, cum_max = cum_y02)]
max_cum_env <- new.env(hash = TRUE, size = nrow(max_cum_lookup))
for (i in seq_len(nrow(max_cum_lookup))) {
  max_cum_env[[max_cum_lookup$cpc_subclass[i]]] <- max_cum_lookup$cum_max[i]
}

get_cum <- function(sub, yr) {
  if (yr > max_grid_yr) {
    v <- max_cum_env[[sub]]
  } else {
    v <- cum_env[[paste0(sub, "_", yr)]]
  }
  if (is.null(v)) 0 else v
}

compute_followon <- function(subs, yrs, window) {
  n <- length(subs)
  result <- integer(n)
  for (i in seq_len(n)) {
    cum_base <- get_cum(subs[i], yrs[i])
    cum_end  <- get_cum(subs[i], yrs[i] + window)
    result[i] <- max(0L, cum_end - cum_base)
  }
  result
}

# For granted patents: use filing_year as the base year (consistent with ABN)
# This is a key change from v1 which used grant_year
dt_with_sub <- dt[!is.na(cpc_subclass)]
cat("Applications with CPC subclass:", format(nrow(dt_with_sub), big.mark = ","), "\n")

# For ABN applications without CPC, we assign the most common subclass in their art unit
if (sum(is.na(dt$cpc_subclass)) > 0) {
  cat("  Applications without CPC subclass:", format(sum(is.na(dt$cpc_subclass)), big.mark = ","), "\n")
  # Get modal CPC subclass per art unit from ISS patents
  au_modal_cpc <- dt[granted == 1 & !is.na(cpc_subclass),
                      .N, by = .(examiner_art_unit, cpc_subclass)][
                      order(examiner_art_unit, -N)][
                      , .SD[1], by = examiner_art_unit]
  dt <- merge(dt, au_modal_cpc[, .(examiner_art_unit, modal_cpc = cpc_subclass)],
              by = "examiner_art_unit", all.x = TRUE)
  dt[is.na(cpc_subclass), cpc_subclass := modal_cpc]

  # Also assign y02_domain from modal CPC
  au_modal_domain <- dt[granted == 1 & !is.na(y02_domain),
                         .N, by = .(examiner_art_unit, y02_domain)][
                         order(examiner_art_unit, -N)][
                         , .SD[1], by = examiner_art_unit]
  dt <- merge(dt, au_modal_domain[, .(examiner_art_unit, modal_domain = y02_domain)],
              by = "examiner_art_unit", all.x = TRUE)
  dt[is.na(y02_domain), y02_domain := modal_domain]
  dt[, c("modal_cpc", "modal_domain") := NULL]
  cat("  After imputation, missing CPC:", sum(is.na(dt$cpc_subclass)), "\n")
}

# Drop if still no subclass
dt <- dt[!is.na(cpc_subclass)]

cat("Computing follow-on outcomes (filing-year base)...\n")
cat("  3-year window...\n")
dt[, followon_3yr := compute_followon(cpc_subclass, filing_year, 3L)]
cat("  5-year window...\n")
dt[, followon_5yr := compute_followon(cpc_subclass, filing_year, 5L)]
cat("  10-year window...\n")
dt[, followon_10yr := compute_followon(cpc_subclass, filing_year, 10L)]

# ── Forward citations (for granted patents only) ────────────────────────
cat("\n=== Computing forward citations ===\n")
cite_file <- file.path(DATA_DIR, "g_us_patent_citation.tsv")
if (file.exists(cite_file)) {
  cite <- fread(cite_file, colClasses = c(patent_id = "character",
                                           citation_patent_id = "character"))
  # Forward citations: count of patents citing the focal patent
  granted_pids <- dt[granted == 1]$patent_number_clean
  granted_pids <- granted_pids[!is.na(granted_pids)]

  fwd_cites <- cite[citation_patent_id %in% granted_pids,
                    .(fwd_citations = .N), by = .(patent_id = citation_patent_id)]
  dt <- merge(dt, fwd_cites, by.x = "patent_number_clean", by.y = "patent_id", all.x = TRUE)
  dt[is.na(fwd_citations), fwd_citations := 0L]
  # ABN patents get 0 citations by definition
  dt[granted == 0, fwd_citations := 0L]

  # Backward citations for granted patents
  bwd_cites <- cite[patent_id %in% granted_pids,
                    .(bwd_citations = .N), by = patent_id]
  dt <- merge(dt, bwd_cites, by.x = "patent_number_clean", by.y = "patent_id", all.x = TRUE)
  dt[is.na(bwd_citations), bwd_citations := 0L]

  rm(cite); gc()
  cat("Citations merged.\n")
} else {
  dt[, fwd_citations := 0L]
  dt[, bwd_citations := 0L]
  cat("Citation file not available.\n")
}

# ── Merge num_claims from PatentsView (for granted patents) ─────────────
patent_claims <- patent[, .(patent_id, num_claims)]
dt <- merge(dt, patent_claims, by.x = "patent_number_clean", by.y = "patent_id", all.x = TRUE)
dt[is.na(num_claims), num_claims := 0L]

rm(patent, y02_all, y02_primary, y02_cpc, cpc, patex); gc()

# ── Create fixed effect variables ────────────────────────────────────────
dt[, au_fy := paste0(examiner_art_unit, "_", filing_year)]

# ── Save analysis dataset ──────────────────────────────────────────────
keep_cols <- c("application_number", "patent_number_clean", "filing_date", "filing_year",
               "granted", "disposal_type",
               "examiner_id", "examiner_art_unit", "au_fy",
               "uspc_class", "cpc_subclass", "cpc_group", "y02_domain",
               "loo_grant_rate_i", "loo_rate_cell", "n_grants", "n_apps", "au_apps", "n_examiners",
               "followon_3yr", "followon_5yr", "followon_10yr",
               "fwd_citations", "bwd_citations", "num_claims",
               "small_entity_indicator")
keep_cols <- intersect(keep_cols, names(dt))

analysis <- dt[, ..keep_cols]
fwrite(analysis, file.path(DATA_DIR, "analysis_dataset.csv"))
cat("\n=== Analysis dataset saved ===\n")
cat("Observations:", format(nrow(analysis), big.mark = ","), "\n")
cat("Granted:", format(sum(analysis$granted), big.mark = ","), "\n")
cat("Abandoned:", format(sum(1 - analysis$granted), big.mark = ","), "\n")
cat("Grant rate:", round(mean(analysis$granted) * 100, 1), "%\n")
cat("Unique examiners:", format(uniqueN(analysis$examiner_id), big.mark = ","), "\n")
cat("Unique art units:", format(uniqueN(analysis$examiner_art_unit), big.mark = ","), "\n")
cat("Filing year range:", min(analysis$filing_year), "-", max(analysis$filing_year), "\n")
cat("Y02 domains:\n")
print(table(analysis$y02_domain))
cat("LOO grant rate summary:\n")
print(summary(analysis$loo_grant_rate_i))
cat("Follow-on 5yr summary:\n")
print(summary(analysis$followon_5yr))

# ── Data validation ────────────────────────────────────────────────────
stopifnot("Expected 10000+ applications" = nrow(analysis) >= 10000)
stopifnot("Expected 100+ examiners" = uniqueN(analysis$examiner_id) >= 100)
stopifnot("Expected 5+ art units" = uniqueN(analysis$examiner_art_unit) >= 5)
stopifnot("Grant rate has variation" = sd(analysis$loo_grant_rate_i, na.rm = TRUE) > 0.001)
stopifnot("Both ISS and ABN present" = sum(analysis$granted == 0) > 100)

cat("\nData validation passed.\n")
