# =============================================================================
# 03_main_analysis.R — DDD estimation for E-Verify geographic spillovers
# =============================================================================

source("00_packages.R")

county_panel <- readRDS("../data/county_panel.rds")
ind_panel <- readRDS("../data/ind_panel.rds")
border_treatment <- readRDS("../data/border_treatment.rds")

# ── 1. Summary statistics ────────────────────────────────────────────────────
cat("=== Summary Statistics ===\n")
cat("Panel dimensions:", format(nrow(county_panel), big.mark = ","), "\n")

summ <- county_panel[, .(
  mean_emp = mean(Emp, na.rm = TRUE),
  sd_emp = sd(Emp, na.rm = TRUE),
  mean_earn = mean(EarnS_wtd, na.rm = TRUE),
  mean_hir = mean(HirA, na.rm = TRUE),
  N = .N
), by = .(border, hispanic)]
cat("\nMean employment by group:\n")
print(summ)

# ── 2. Fix specification ─────────────────────────────────────────────────────
# The DDD uses: county_eth FE + time×ethnicity FE
# post is only non-zero for border counties, so:
#   post:hispanic = the DDD interaction (border × post × hispanic)
#   post = border × post (main treatment effect on both groups)
# time×ethnicity FE absorbs national Hispanic employment trends

cat("\n=== Main DDD Results ===\n")

# Specification 1: DDD with county-ethnicity FE and time × ethnicity FE
m1 <- feols(log_emp ~ post:hispanic + post |
              county_eth + time_id^hispanic,
            data = county_panel,
            cluster = ~statefip)

# Specification 2: Add state × quarter FE (absorbs state trends)
m2 <- feols(log_emp ~ post:hispanic + post |
              county_eth + statefip^time_id + time_id^hispanic,
            data = county_panel,
            cluster = ~statefip)

# Specification 3: Earnings
m3 <- feols(log_earn ~ post:hispanic + post |
              county_eth + time_id^hispanic,
            data = county_panel[!is.na(log_earn)],
            cluster = ~statefip)

# Specification 4: Hires
m4 <- feols(log_hir ~ post:hispanic + post |
              county_eth + time_id^hispanic,
            data = county_panel,
            cluster = ~statefip)

cat("Specification 1 (base):\n")
print(summary(m1))
cat("\nSpecification 2 (state×time FE):\n")
print(summary(m2))
cat("\nSpecification 3 (earnings):\n")
print(coeftable(m3))
cat("\nSpecification 4 (hires):\n")
print(coeftable(m4))

main_results <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4)
saveRDS(main_results, "../data/main_results.rds")

# ── 3. Event study ───────────────────────────────────────────────────────────
cat("\n=== Event Study ===\n")

# Create relative time for border counties; NA for interior
county_panel[, rel_time := fifelse(
  border == TRUE & is.finite(ev_mandate_yq),
  as.integer(round((yq - ev_mandate_yq) * 4)),
  NA_integer_
)]

# Trim to event window
county_panel[!is.na(rel_time) & rel_time < -8, rel_time := -8L]
county_panel[!is.na(rel_time) & rel_time > 12, rel_time := 12L]

# Event study: interior counties contribute to FE estimation
# i() in fixest handles NA by excluding those obs from the interaction
m_es <- feols(log_emp ~ i(rel_time, hispanic, ref = -1) + i(rel_time, ref = -1) |
                county_eth + time_id^hispanic,
              data = county_panel,
              cluster = ~statefip)

cat("Event study:\n")
print(summary(m_es))
saveRDS(m_es, "../data/event_study.rds")

# ── 4. Industry heterogeneity ────────────────────────────────────────────────
cat("\n=== Industry Heterogeneity ===\n")

# Add time_id to industry panel
ind_panel[, time_id := year * 10 + quarter]
ind_panel[, county_eth_ind := paste0(county_fips, "_", ethnicity, "_", industry)]

# Construction (NAICS 23) — high Hispanic share
m_constr <- feols(log_emp ~ post:hispanic + post |
                    county_eth_ind + time_id^hispanic,
                  data = ind_panel[industry == "23"],
                  cluster = ~statefip)

# Accommodation and Food (NAICS 72) — high Hispanic share
m_food <- feols(log_emp ~ post:hispanic + post |
                  county_eth_ind + time_id^hispanic,
                data = ind_panel[industry == "72"],
                cluster = ~statefip)

# Professional Services (NAICS 54) — low Hispanic share (placebo)
m_prof <- feols(log_emp ~ post:hispanic + post |
                  county_eth_ind + time_id^hispanic,
                data = ind_panel[industry == "54"],
                cluster = ~statefip)

# Manufacturing (NAICS 31-33)
m_mfg <- feols(log_emp ~ post:hispanic + post |
                 county_eth_ind + time_id^hispanic,
               data = ind_panel[industry == "31-33"],
               cluster = ~statefip)

cat("Construction DDD:\n")
print(coeftable(m_constr))
cat("Accommodation/Food DDD:\n")
print(coeftable(m_food))
cat("Professional Services DDD (placebo):\n")
print(coeftable(m_prof))
cat("Manufacturing DDD:\n")
print(coeftable(m_mfg))

ind_results <- list(constr = m_constr, food = m_food, prof = m_prof, mfg = m_mfg)
saveRDS(ind_results, "../data/ind_results.rds")

# ── 5. Write diagnostics for validator ───────────────────────────────────────
diag <- list(
  n_treated = length(unique(county_panel[border == TRUE]$county_fips)),
  n_pre = length(unique(county_panel[post == 0 & border == TRUE]$time_id)),
  n_obs = nrow(county_panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", paste(names(diag), unlist(diag), sep = "=", collapse = ", "), "\n")

cat("\nMain analysis complete.\n")
