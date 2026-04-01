## 03_main_analysis.R — Main DiD regressions for carbon tax effects

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
elec <- panel[industry == "electricity"]

cat("=== Main Analysis: Carbon Tax Effects on Electricity Employment ===\n")
cat("Electricity obs:", nrow(elec), "\n")
cat("States:", length(unique(elec$state)), "\n")
cat("Quarters:", length(unique(elec$yq)), "\n\n")

# ---------------------------------------------------------------
# 1. MAIN SPECIFICATION: Continuous-treatment DiD
# Y_st = alpha_s + gamma_t + beta1 * CoalShare_s * TaxPeriod_t
#                           + beta2 * CoalShare_s * PostRepeal_t + eps_st
# ---------------------------------------------------------------
cat("--- Model 1: Coal Share × Period (main spec) ---\n")
m1 <- feols(log_emp ~ coal_x_tax + coal_x_post | state + yq,
            data = elec, cluster = ~state)
summary(m1)

# ---------------------------------------------------------------
# 2. With carbon intensity (brown coal adjustment)
# ---------------------------------------------------------------
cat("\n--- Model 2: Carbon Intensity × Period ---\n")
m2 <- feols(log_emp ~ carbon_x_tax + carbon_x_post | state + yq,
            data = elec, cluster = ~state)
summary(m2)

# ---------------------------------------------------------------
# 3. With state economic controls (non-electricity employment)
# ---------------------------------------------------------------
cat("\n--- Model 3: Coal Share × Period + state economic controls ---\n")
m3 <- feols(log_emp ~ coal_x_tax + coal_x_post + log_non_elec | state + yq,
            data = elec, cluster = ~state)
summary(m3)

# ---------------------------------------------------------------
# 4. Binary treatment: High-coal states (NSW, VIC, QLD) vs rest
# ---------------------------------------------------------------
cat("\n--- Model 4: Binary high-coal × Period ---\n")
elec[, high_x_tax := high_coal * tax_period]
elec[, high_x_post := high_coal * post_repeal]
m4 <- feols(log_emp ~ high_x_tax + high_x_post | state + yq,
            data = elec, cluster = ~state)
summary(m4)

# ---------------------------------------------------------------
# 5. EVENT STUDY: Coal Share × quarter indicators
# ---------------------------------------------------------------
cat("\n--- Model 5: Event Study ---\n")
# Drop event_time == -1 as reference period (Q2 2012, last pre-treatment quarter)
# Keep reasonable window: -12 to +20 quarters
elec_es <- elec[event_time >= -12 & event_time <= 20]
elec_es[, event_f := factor(event_time)]
# Relevel so -1 is reference
elec_es[, event_f := relevel(event_f, ref = "-1")]

m5 <- feols(log_emp ~ i(event_time, coal_share, ref = -1) | state + yq,
            data = elec_es, cluster = ~state)

cat("Event study coefficients:\n")
es_coefs <- coeftable(m5)
print(es_coefs)

# Save event study coefficients for plotting
es_dt <- data.table(
  event_time = as.integer(gsub("event_time::", "", gsub(":coal_share", "", rownames(es_coefs)))),
  estimate = es_coefs[, "Estimate"],
  se = es_coefs[, "Std. Error"],
  pval = es_coefs[, "Pr(>|t|)"]
)
es_dt[, ci_lower := estimate - 1.96 * se]
es_dt[, ci_upper := estimate + 1.96 * se]
fwrite(es_dt, "../data/event_study_coefs.csv")

# ---------------------------------------------------------------
# Save model results for tables
# ---------------------------------------------------------------
models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5)
saveRDS(models, "../data/main_models.rds")

# ---------------------------------------------------------------
# Diagnostics for validator
# ---------------------------------------------------------------
diag <- list(
  n_treated = length(unique(elec[coal_share > 0.50]$state)),  # NSW, VIC, QLD = 3 high-coal
  n_pre = length(unique(elec[period == "pre"]$yq)),
  n_obs = nrow(elec),
  n_states = length(unique(elec$state)),
  n_quarters = length(unique(elec$yq)),
  coal_share_range = range(unique(elec$coal_share)),
  main_coef_tax = coef(m1)["coal_x_tax"],
  main_se_tax = sqrt(vcov(m1)["coal_x_tax", "coal_x_tax"]),
  main_coef_post = coef(m1)["coal_x_post"],
  main_se_post = sqrt(vcov(m1)["coal_x_post", "coal_x_post"])
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics saved ===\n")
cat("N treated (high coal):", diag$n_treated, "\n")
cat("N pre periods:", diag$n_pre, "\n")
cat("N observations:", diag$n_obs, "\n")
cat("Main tax effect (coal_x_tax):", round(diag$main_coef_tax, 4),
    "SE:", round(diag$main_se_tax, 4), "\n")
cat("Post-repeal effect (coal_x_post):", round(diag$main_coef_post, 4),
    "SE:", round(diag$main_se_post, 4), "\n")
