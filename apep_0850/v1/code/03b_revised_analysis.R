## 03b_revised_analysis.R — apep_0850
## Revised analysis: EXCLUDE VAUD (contaminated control)
## Vaud approved cantonal minimum wage Sept 2020, effective Jan 2021
## Uses: fixest, data.table, dplyr

source("00_packages.R")
library(fixest)
library(data.table)

panel <- readRDS("../data/analysis_panel_fr.rds")

cat("=== REVISED ANALYSIS: Excluding Vaud from controls ===\n\n")

# Exclude Vaud (canton 22) — contaminated control
ddd_panel <- panel[bite %in% c("high", "low") & canton != 22]
cat(sprintf("DDD panel (excl. Vaud): %s obs, %d cantons\n",
            format(nrow(ddd_panel), big.mark = ","), uniqueN(ddd_panel$canton)))

ddd_panel[, ge_hb := as.integer(canton == 25) * as.integer(bite == "high")]

# ---- Preferred: Clean pre-period (2015+), excl. Vaud ----
clean_panel <- ddd_panel[year >= 2015]

m_preferred <- feols(
  log_cbw ~ ge_hb:post | canton_sector + sector_quarter + canton_quarter,
  data = clean_panel,
  cluster = ~canton_sector
)

cat("--- Preferred specification (2015+, excl. Vaud) ---\n")
summary(m_preferred)

# ---- Full sample, excl. Vaud ----
m_full <- feols(
  log_cbw ~ ge_hb:post | canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel,
  cluster = ~canton_sector
)

cat("\n--- Full sample (excl. Vaud) ---\n")
summary(m_full)

# ---- Simple FE, excl. Vaud ----
m_simple <- feols(
  log_cbw ~ I(canton == 25):I(bite == "high"):post +
    I(canton == 25):post + I(bite == "high"):post |
    canton_sector + t,
  data = clean_panel,
  cluster = ~canton_sector
)

cat("\n--- Simple FE (2015+, excl. Vaud) ---\n")
summary(m_simple)

# ---- Within-Geneva DiD ----
geneva_panel <- clean_panel[canton == 25]
m_geneva <- feols(
  log_cbw ~ I(bite == "high"):post | noga + t,
  data = geneva_panel,
  cluster = ~noga
)

cat("\n--- Within-Geneva DiD (2015+) ---\n")
summary(m_geneva)

# ---- Poisson QMLE, excl. Vaud ----
m_poisson <- fepois(
  cbw ~ ge_hb:post | canton_sector + sector_quarter + canton_quarter,
  data = clean_panel[cbw > 0],
  cluster = ~canton_sector
)

cat("\n--- Poisson QMLE (2015+, excl. Vaud) ---\n")
summary(m_poisson)

# ---- Event study (2015+, excl. Vaud) ----
treatment_q <- clean_panel[TIME_PERIOD == "2020-Q4", unique(t)]
clean_panel[, event_time := t - treatment_q]
clean_panel[, event_time_bin := fcase(
  event_time <= -9, -9L,
  event_time >= 16, 16L,
  default = event_time
)]

m_event <- feols(
  log_cbw ~ i(event_time_bin, ge_hb, ref = -1) |
    canton_sector + sector_quarter + canton_quarter,
  data = clean_panel,
  cluster = ~canton_sector
)

cat("\n--- Event study (2015+, excl. Vaud) ---\n")
summary(m_event)

# Formal pre-trend test: joint significance of pre-treatment coefficients
pre_coefs <- grep("event_time_bin::-[2-9]", names(coef(m_event)), value = TRUE)
if (length(pre_coefs) > 1) {
  wald <- wald(m_event, pre_coefs)
  cat(sprintf("\nWald test for pre-trends: F = %.3f, p = %.4f\n", wald$stat, wald$p))
}

# ---- Placebo timing (Q4 2018, pre-treatment only) ----
clean_panel[, post_placebo := as.integer(time_q >= 2018.75)]
m_placebo_time <- feols(
  log_cbw ~ ge_hb:post_placebo | canton_sector + sector_quarter + canton_quarter,
  data = clean_panel[time_q < 2020.75],
  cluster = ~canton_sector
)

cat("\n--- Placebo timing (Q4 2018, excl. Vaud) ---\n")
summary(m_placebo_time)

# ---- Permutation test (placebo-in-space) ----
cat("\n--- Permutation test: each control canton as if treated ---\n")
control_cantons <- c(12, 24, 26)  # Basel-Stadt, Neuchâtel, Jura
perm_results <- data.table()

for (pc in control_cantons) {
  perm_data <- clean_panel[canton != 25]  # Exclude Geneva
  perm_data[, perm_ge_hb := as.integer(canton == pc) * as.integer(bite == "high")]
  m_perm <- feols(
    log_cbw ~ perm_ge_hb:post | canton_sector + sector_quarter + canton_quarter,
    data = perm_data,
    cluster = ~canton_sector
  )
  perm_results <- rbind(perm_results, data.table(
    canton = pc,
    coef = coef(m_perm)["perm_ge_hb:post"],
    se = se(m_perm)["perm_ge_hb:post"]
  ))
}

cat("Permutation results:\n")
print(perm_results)
cat(sprintf("Geneva preferred: %.4f\n", coef(m_preferred)["ge_hb:post"]))
cat(sprintf("Permutation range: [%.4f, %.4f]\n",
            min(perm_results$coef), max(perm_results$coef)))

# ---- Update diagnostics ----
beta_hat <- coef(m_preferred)["ge_hb:post"]
se_beta <- se(m_preferred)["ge_hb:post"]
sd_y <- sd(clean_panel[post == 0]$log_cbw, na.rm = TRUE)

diag <- list(
  n_treated = uniqueN(clean_panel[canton == 25 & ge_hb == 1]$canton_sector),
  n_control_cantons = 3,
  n_pre = uniqueN(clean_panel[post == 0]$TIME_PERIOD),
  n_obs = nrow(clean_panel),
  n_cantons = uniqueN(clean_panel$canton),
  n_sectors = uniqueN(clean_panel$noga),
  n_quarters = uniqueN(clean_panel$TIME_PERIOD),
  ddd_coef_preferred = round(beta_hat, 4),
  ddd_se_preferred = round(se_beta, 4),
  ddd_pval_preferred = round(pvalue(m_preferred)["ge_hb:post"], 4),
  sd_y_pre = round(sd_y, 4),
  sde_preferred = round(beta_hat / sd_y, 4),
  vaud_excluded = TRUE
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

# Save revised models
saveRDS(list(
  m_preferred = m_preferred,
  m_full = m_full,
  m_geneva = m_geneva,
  m_poisson = m_poisson,
  m_event = m_event,
  m_placebo_time = m_placebo_time,
  perm_results = perm_results
), "../data/revised_models.rds")

cat(sprintf("\n=== HEADLINE (revised) ===\n"))
cat(sprintf("DDD preferred (excl. Vaud, 2015+): %.4f (SE: %.4f, p: %.4f)\n",
            beta_hat, se_beta, pvalue(m_preferred)["ge_hb:post"]))
cat(sprintf("SDE: %.4f\n", beta_hat / sd_y))
cat(sprintf("95%% CI: [%.3f, %.3f]\n",
            beta_hat - 1.96 * se_beta, beta_hat + 1.96 * se_beta))
cat(sprintf("MDE (80%% power): %.3f log points\n", 2.8 * se_beta))
