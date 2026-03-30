# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# =============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
load("../data/main_results.RData")

prime <- panel[age_group == "prime_age" & year %in% 2005:2019]

# ─────────────────────────────────────────────────────────────────────────────
# 1. Alternative instrument windows
# ─────────────────────────────────────────────────────────────────────────────
message("Robustness: alternative instrument construction...")

# Reconstruct instrument using only 2008-2009 (shorter pre-period)
arcos_annual <- fread("../data/arcos_annual.csv")
inst_short <- arcos_annual[year %in% 2008:2009, .(
  oxycontin_pills = sum(oxycontin_pills, na.rm = TRUE),
  oxy_pills = sum(oxy_pills, na.rm = TRUE)
), by = fips]
inst_short[, oxy_share_short := fifelse(oxy_pills > 0, oxycontin_pills / oxy_pills, 0)]

prime_short <- merge(prime, inst_short[, .(fips, oxy_share_short)], by = "fips")
prime_short[, oxy_share_short_post := oxy_share_short * post]

rob_short <- feols(
  log_emp ~ oxy_share_short_post + i(year, total_pills_pc) |
    fips + year,
  data = prime_short,
  cluster = ~state_fips,
  weights = ~pop_2009
)

# ─────────────────────────────────────────────────────────────────────────────
# 2. Trimmed sample (drop extreme OxyContin shares)
# ─────────────────────────────────────────────────────────────────────────────
message("Robustness: trimmed sample...")

p5 <- quantile(prime$oxy_share, 0.05)
p95 <- quantile(prime$oxy_share, 0.95)

rob_trimmed <- feols(
  log_emp ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = prime[oxy_share >= p5 & oxy_share <= p95],
  cluster = ~state_fips,
  weights = ~pop_2009
)

# ─────────────────────────────────────────────────────────────────────────────
# 3. Unweighted regression
# ─────────────────────────────────────────────────────────────────────────────
message("Robustness: unweighted...")

rob_unweight <- feols(
  log_emp ~ oxy_share_post + i(year, total_pills_pc) |
    fips + year,
  data = prime,
  cluster = ~state_fips
)

# ─────────────────────────────────────────────────────────────────────────────
# 4. Placebo: elderly workers (65+)
# ─────────────────────────────────────────────────────────────────────────────
message("Placebo: elderly workers...")

elderly <- panel[age_group == "elderly" & year %in% 2005:2019]
if (nrow(elderly) > 0 && sum(!is.na(elderly$log_emp)) > 100) {
  rob_elderly <- feols(
    log_emp ~ oxy_share_post + i(year, total_pills_pc) |
      fips + year,
    data = elderly,
    cluster = ~state_fips,
    weights = ~pop_2009
  )
} else {
  message("  Insufficient elderly data, using older (45-64) as placebo")
  older <- panel[age_group == "older" & year %in% 2005:2019]
  rob_elderly <- feols(
    log_emp ~ oxy_share_post + i(year, total_pills_pc) |
      fips + year,
    data = older,
    cluster = ~state_fips,
    weights = ~pop_2009
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. HonestDiD sensitivity analysis
# ─────────────────────────────────────────────────────────────────────────────
message("HonestDiD sensitivity for event study...")

honest_result <- tryCatch({
  # Extract event study coefficients for log employment
  beta_hat <- coef(es_emp)[grep("event_time.*oxy_share", names(coef(es_emp)))]
  sigma_hat <- vcov(es_emp)[grep("event_time.*oxy_share", rownames(vcov(es_emp))),
                             grep("event_time.*oxy_share", colnames(vcov(es_emp)))]

  # Number of pre-treatment periods (excluding reference)
  n_pre_coefs <- sum(as.numeric(gsub(".*event_time::(-?\\d+):.*", "\\1",
                                      names(beta_hat))) < -1) + 1
  # Relative magnitudes approach
  if (length(beta_hat) >= 4 && n_pre_coefs >= 2) {
    delta_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = n_pre_coefs,
      numPostPeriods = length(beta_hat) - n_pre_coefs,
      Mbarvec = seq(0, 2, by = 0.5),
      l_vec = basisVector(1, length(beta_hat) - n_pre_coefs)
    )
    delta_rm
  } else {
    message("  Insufficient coefficients for HonestDiD")
    NULL
  }
}, error = function(e) {
  message(sprintf("  HonestDiD failed: %s", e$message))
  NULL
})

# ─────────────────────────────────────────────────────────────────────────────
# 6. Conley spatial SEs (state-level should be sufficient, note this)
# ─────────────────────────────────────────────────────────────────────────────
message("Clustering at commuting zone level as additional robustness...")

# Use a CZ crosswalk (county → commuting zone)
# USDA ERS commuting zones: https://www.ers.usda.gov/data-products/commuting-zones-and-labor-market-areas/
cz_url <- "https://www.ers.usda.gov/webdocs/DataFiles/48457/czlma903.xls?v=2035.3"

cz_crosswalk <- tryCatch({
  tmp_file <- tempfile(fileext = ".xls")
  download.file(cz_url, tmp_file, mode = "wb", quiet = TRUE)
  if (requireNamespace("readxl", quietly = TRUE)) {
    cz <- as.data.table(readxl::read_xls(tmp_file))
    setnames(cz, c("fips", "cz_1990", "cz_name", "pop_1990", "lma_1990", "lma_name"))
    cz[, fips := sprintf("%05d", as.integer(fips))]
    cz[, .(fips, cz_1990)]
  } else {
    NULL
  }
}, error = function(e) {
  message(sprintf("  CZ crosswalk failed: %s", e$message))
  NULL
})

if (!is.null(cz_crosswalk)) {
  prime_cz <- merge(prime, cz_crosswalk, by = "fips", all.x = TRUE)
  rob_cz_cluster <- feols(
    log_emp ~ oxy_share_post + i(year, total_pills_pc) |
      fips + year,
    data = prime_cz[!is.na(cz_1990)],
    cluster = ~cz_1990,
    weights = ~pop_2009
  )
} else {
  # Fallback: two-way clustering (state + year)
  rob_cz_cluster <- feols(
    log_emp ~ oxy_share_post + i(year, total_pills_pc) |
      fips + year,
    data = prime,
    cluster = ~state_fips + year,
    weights = ~pop_2009
  )
}

# ─────────────────────────────────────────────────────────────────────────────
# 7. Save all robustness results
# ─────────────────────────────────────────────────────────────────────────────
save(rob_short, rob_trimmed, rob_unweight, rob_elderly,
     rob_cz_cluster, honest_result,
     file = "../data/robustness_results.RData")

message("\n=== Robustness checks complete ===")
message(sprintf("  Short window:  β = %.4f (SE = %.4f)", coef(rob_short)["oxy_share_short_post"],
                se(rob_short)["oxy_share_short_post"]))
message(sprintf("  Trimmed:       β = %.4f (SE = %.4f)", coef(rob_trimmed)["oxy_share_post"],
                se(rob_trimmed)["oxy_share_post"]))
message(sprintf("  Unweighted:    β = %.4f (SE = %.4f)", coef(rob_unweight)["oxy_share_post"],
                se(rob_unweight)["oxy_share_post"]))
message(sprintf("  Elderly plac.: β = %.4f (SE = %.4f)", coef(rob_elderly)["oxy_share_post"],
                se(rob_elderly)["oxy_share_post"]))
