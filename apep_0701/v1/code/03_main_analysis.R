################################################################################
# 03_main_analysis.R — Main DiD regressions
# Paper: apep_0701 — FUNDEB Fiscal Equalization and Education Spending
#
# Specifications:
#   (1) DiD: log_edu_total ~ treated:post | mun_FE + year_FE
#   (2) DiD: edu_share     ~ treated:post | mun_FE + year_FE
#   (3) DiD: share_secondary ~ treated:post | mun_FE + year_FE (2004-2011)
#   (4) Event study: interact treated with year indicators
#   (5) DDD: secondary vs primary spending differential
#
# Treatment: complementação state (binary, state-level)
# Cluster: state level (sigla_uf), ~27 clusters
################################################################################

source("code/00_packages.R")
setwd(here::here())

panel   <- read_csv("data/panel_balanced.csv", show_col_types = FALSE)
panel_ddd <- read_csv("data/panel_ddd.csv",    show_col_types = FALSE)

cat("Panel dimensions:", nrow(panel), "rows,", n_distinct(panel$id_municipio), "municipalities\n")
cat("Years:", paste(sort(unique(panel$year)), collapse=","), "\n")

YEARS     <- sort(unique(panel$year))
N_MUN     <- n_distinct(panel$id_municipio)
N_OBS     <- nrow(panel)
N_TREATED <- sum(panel$treated == 1 & panel$year == 2006)
N_PRE     <- sum(YEARS < 2007)

cat("Treated municipalities:", N_TREATED, "\n")
cat("Pre-periods:", N_PRE, "\n")

# ─────────────────────────────────────────────────────────────────
# (1) MAIN DiD: Log total education spending
# ─────────────────────────────────────────────────────────────────
cat("\n=== (1) Main DiD: Log total education spending ===\n")

did_log_total <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = panel,
  cluster = ~sigla_uf
)

did_log_total_mun <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = panel,
  cluster = ~id_municipio
)

cat("DiD (log total edu) coef:", round(coef(did_log_total)["treated:post"], 5),
    "| p =", round(fixest::pvalue(did_log_total)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (2) DiD: Education share of total spending
# ─────────────────────────────────────────────────────────────────
cat("\n=== (2) DiD: Education share ===\n")

did_edu_share <- feols(
  edu_share ~ treated:post | id_municipio + year,
  data    = panel,
  cluster = ~sigla_uf
)

cat("DiD (edu share) coef:", round(coef(did_edu_share)["treated:post"], 5),
    "| p =", round(fixest::pvalue(did_edu_share)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (3) DiD: Secondary share (2004-2011)
# ─────────────────────────────────────────────────────────────────
cat("\n=== (3) DiD: Secondary share (2004-2011) ===\n")

panel_04 <- panel %>%
  filter(year >= 2004, !is.na(share_secondary), is.finite(share_secondary))

did_share_sec <- feols(
  share_secondary ~ treated:post | id_municipio + year,
  data    = panel_04,
  cluster = ~sigla_uf
)

cat("DiD (secondary share) coef:", round(coef(did_share_sec)["treated:post"], 5),
    "| p =", round(fixest::pvalue(did_share_sec)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (4) EVENT STUDY: Leads and lags (log total edu, 2002-2011)
# Omit 2006 as reference year
# ─────────────────────────────────────────────────────────────────
cat("\n=== (4) Event Study ===\n")

panel_es <- panel %>%
  mutate(year_fct = relevel(as.factor(year), ref = "2006"))

es_main <- feols(
  log_edu_total ~ i(year_fct, treated, ref = "2006") | id_municipio + year,
  data    = panel_es,
  cluster = ~sigla_uf
)

cat("Event study coefficients:\n")
print(round(coef(es_main), 5))

# Pre-trend test (joint test that 2002-2005 coefficients = 0)
pre_years <- grep("^year_fct::200[2-5]", names(coef(es_main)), value = TRUE)
cat("\nPre-trend test (2002-2005 jointly = 0):\n")
if (length(pre_years) >= 2) {
  tryCatch({
    pt <- wald(es_main, keep = pre_years)
    cat("  Chi-sq =", round(pt$stat, 3), "| p =", round(pt$p, 4), "\n")
  }, error = function(e) cat("  Wald test error:", e$message, "\n"))
}

# Event study for secondary share (2004-2011)
panel_es_sec <- panel_04 %>%
  mutate(year_fct = relevel(as.factor(year), ref = "2006"))

es_share_sec <- feols(
  share_secondary ~ i(year_fct, treated, ref = "2006") | id_municipio + year,
  data    = panel_es_sec,
  cluster = ~sigla_uf
)

cat("\nSecondary share event study:\n")
print(round(coef(es_share_sec), 5))

# ─────────────────────────────────────────────────────────────────
# (5) DDD: Secondary vs primary spending differential (2004-2011)
# Estimate differential effect on secondary vs primary
# ─────────────────────────────────────────────────────────────────
cat("\n=== (5) DDD: Secondary vs primary ===\n")

panel_ddd_filt <- panel_ddd %>%
  filter(!is.na(log_level_spending), is.finite(log_level_spending))

ddd_main <- feols(
  log_level_spending ~ treated:post:secondary_ind | id_municipio^level + year^level,
  data    = panel_ddd_filt,
  cluster = ~sigla_uf
)

cat("DDD coef (treated × post × secondary):",
    round(coef(ddd_main)["treated:post:secondary_ind"], 5),
    "| p =", round(fixest::pvalue(ddd_main)["treated:post:secondary_ind"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# Save results
# ─────────────────────────────────────────────────────────────────
results <- list(
  did_log_total      = did_log_total,
  did_log_total_mun  = did_log_total_mun,
  did_edu_share      = did_edu_share,
  did_share_sec      = did_share_sec,
  es_main            = es_main,
  es_share_sec       = es_share_sec,
  ddd_main           = ddd_main
)

saveRDS(results, "data/results.rds")
saveRDS(panel,     "data/panel_rds.rds")
saveRDS(panel_04,  "data/panel_04.rds")
saveRDS(panel_ddd_filt, "data/panel_ddd_filt.rds")

# ─────────────────────────────────────────────────────────────────
# Diagnostics JSON (for validate_v1.py)
# ─────────────────────────────────────────────────────────────────
diag <- list(
  n_treated        = N_TREATED,
  n_pre            = N_PRE,
  n_obs            = N_OBS,
  n_municipalities = N_MUN,
  years            = paste(YEARS, collapse=","),
  treatment_year   = 2007,
  main_coef_log_total = coef(did_log_total)["treated:post"],
  main_coef_edu_share = coef(did_edu_share)["treated:post"],
  main_coef_ddd       = coef(ddd_main)["treated:post:secondary_ind"]
)

jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written:\n")
cat("  n_treated:", diag$n_treated, "\n")
cat("  n_pre:", diag$n_pre, "\n")
cat("  n_obs:", diag$n_obs, "\n")
cat("  Main DiD coef:", round(diag$main_coef_log_total, 5), "\n")
cat("  Education share coef:", round(diag$main_coef_edu_share, 5), "\n")
cat("  DDD coef:", round(diag$main_coef_ddd, 5), "\n")
