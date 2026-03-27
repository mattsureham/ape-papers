# 03_main_analysis.R — Triple-difference estimation
# apep_1071: Golden Visa and Existing-New Dwelling Price Divergence

source("00_packages.R")

hpi <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
gap_data <- read_csv("../data/gap_data.csv", show_col_types = FALSE)

# ── Restrict sample: pre-COVID window ────────────────────────────
hpi_pre <- hpi %>% filter(time <= as.Date("2019-12-31"))
gap_pre <- gap_data %>% filter(time <= as.Date("2019-12-31"))

cat("=== SAMPLE SIZES ===\n")
cat("Full panel:", nrow(hpi), "| Pre-COVID:", nrow(hpi_pre), "\n")
cat("Gap panel:", nrow(gap_data), "| Pre-COVID:", nrow(gap_pre), "\n")
cat("Countries:", length(unique(gap_pre$country)), "\n")

# ── 1. MAIN: DD on existing-new gap ──────────────────────────────
cat("\n=== MAIN DD ON EXISTING-NEW GAP ===\n")

m_dd <- feols(gap ~ portugal:post | country + quarter_id,
              data = gap_pre,
              cluster = ~country)

cat("DD coefficient (Portugal × Post on gap):\n")
cat("  β =", round(coef(m_dd)["portugal:post"], 3), "\n")
cat("  SE =", round(se(m_dd)["portugal:post"], 3), "\n")
cat("  p =", round(pvalue(m_dd)["portugal:post"], 4), "\n")

# ── 2. DDD on HPI levels ────────────────────────────────────────
cat("\n=== DDD ON HPI LEVELS ===\n")

m_ddd <- feols(hpi ~ ddd |
                 country_dwelling + country^quarter_id + dwelling_type^quarter_id,
               data = hpi_pre,
               cluster = ~country)

cat("DDD coefficient:\n")
cat("  β =", round(coef(m_ddd)["ddd"], 3), "\n")
cat("  SE =", round(se(m_ddd)["ddd"], 3), "\n")

# ── 3. RANDOMIZATION INFERENCE ───────────────────────────────────
cat("\n=== RANDOMIZATION INFERENCE ===\n")

set.seed(42)
observed_beta <- coef(m_dd)["portugal:post"]

# Permute treatment: assign "treated" to each country in turn
country_list <- unique(gap_pre$country)
n_countries <- length(country_list)
ri_betas <- numeric(n_countries)

for (i in seq_along(country_list)) {
  gap_perm <- gap_pre %>%
    mutate(portugal_perm = as.integer(country == country_list[i]))
  m_perm <- feols(gap ~ portugal_perm:post | country + quarter_id,
                  data = gap_perm,
                  cluster = ~country)
  ri_betas[i] <- coef(m_perm)["portugal_perm:post"]
}

ri_p_twosided <- mean(abs(ri_betas) >= abs(observed_beta))
ri_p_onesided <- mean(ri_betas >= observed_beta)

cat("N countries for RI:", n_countries, "\n")
cat("Observed beta (Portugal):", round(observed_beta, 2), "\n")
cat("RI distribution (sorted):", paste(round(sort(ri_betas), 2), collapse = ", "), "\n")
cat("RI p-value (two-sided):", ri_p_twosided, "\n")
cat("RI p-value (one-sided, Portugal largest positive):", ri_p_onesided, "\n")

# Rank of Portugal's coefficient
portugal_rank <- sum(ri_betas >= observed_beta)
cat("Portugal's rank (1 = largest):", portugal_rank, "of", n_countries, "\n")

# ── 4. WILD CLUSTER BOOTSTRAP ────────────────────────────────────
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Remove singleton FE observations first
gap_pre_clean <- gap_pre %>%
  group_by(country) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  group_by(quarter_id) %>%
  filter(n() > 1) %>%
  ungroup()

m_dd_clean <- feols(gap ~ portugal:post + i(country) + i(quarter_id),
                    data = gap_pre_clean,
                    cluster = ~country)

boot_result <- tryCatch({
  boottest(m_dd_clean, param = "portugal:post",
           clustid = ~country,
           B = 9999,
           type = "webb",
           impose_null = TRUE)
}, error = function(e) {
  cat("Wild bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  wcb_p <- pval(boot_result)
  wcb_ci <- boot_result$conf_int
  cat("Wild cluster bootstrap p-value:", round(wcb_p, 4), "\n")
  cat("95% CI:", round(wcb_ci[1], 2), "to", round(wcb_ci[2], 2), "\n")
} else {
  wcb_p <- NA
  wcb_ci <- c(NA, NA)
}

# ── 5. EVENT STUDY ───────────────────────────────────────────────
cat("\n=== EVENT STUDY ===\n")

# Bin at endpoints
gap_pre <- gap_pre %>%
  mutate(
    event_time = as.integer(round(
      as.numeric(difftime(time, as.Date("2012-10-01"), units = "days")) / 91.25
    )),
    event_time_bin = pmax(pmin(event_time, 28), -12)
  )

m_es <- feols(gap ~ i(event_time_bin, portugal, ref = -1) | country + quarter_id,
              data = gap_pre,
              cluster = ~country)

# Extract coefficients
es_raw <- coeftable(m_es)
es_coefs <- data.frame(
  event_time = as.integer(gsub(".*::(-?\\d+):.*", "\\1", rownames(es_raw))),
  beta = es_raw[, "Estimate"],
  se = es_raw[, "Std. Error"],
  p = es_raw[, "Pr(>|t|)"],
  stringsAsFactors = FALSE
) %>%
  arrange(event_time)

# Pre-trends test: joint F-test on pre-period coefficients
pre_mask <- es_coefs$event_time < 0
cat("Pre-trend coefficients:\n")
for (i in which(pre_mask)) {
  cat(sprintf("  t=%+d: β=%.2f (SE=%.2f)\n",
              es_coefs$event_time[i], es_coefs$beta[i], es_coefs$se[i]))
}

# Max absolute pre-trend coefficient
max_pre <- max(abs(es_coefs$beta[pre_mask]), na.rm = TRUE)
cat("\nMax |pre-trend coef|:", round(max_pre, 2), "\n")
cat("Post-treatment coef at t=0:", round(es_coefs$beta[es_coefs$event_time == 0], 2), "\n")
cat("Post-treatment coef at t=12:", round(es_coefs$beta[es_coefs$event_time == 12], 2), "\n")
cat("Post-treatment coef at t=28:",
    round(es_coefs$beta[es_coefs$event_time == 28], 2), "\n")

# ── 6. SAVE RESULTS ──────────────────────────────────────────────
results <- list(
  ddd_beta = coef(m_ddd)["ddd"],
  ddd_se = se(m_ddd)["ddd"],
  dd_beta = coef(m_dd)["portugal:post"],
  dd_se = se(m_dd)["portugal:post"],
  dd_p = pvalue(m_dd)["portugal:post"],
  ri_p_twosided = ri_p_twosided,
  ri_p_onesided = ri_p_onesided,
  ri_betas = ri_betas,
  ri_countries = country_list,
  portugal_rank = portugal_rank,
  n_countries_ri = n_countries,
  wcb_p = wcb_p,
  wcb_ci = wcb_ci,
  n_obs = nrow(hpi_pre),
  n_obs_gap = nrow(gap_pre),
  n_countries = length(unique(hpi_pre$country)),
  n_quarters = length(unique(hpi_pre$quarter_id)),
  n_pre = length(unique(hpi_pre$quarter_id[hpi_pre$post == 0])),
  event_study = es_coefs
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json
diagnostics <- list(
  n_treated = sum(gap_pre$portugal == 1 & gap_pre$post == 1),
  n_pre = results$n_pre,
  n_obs = results$n_obs_gap
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat("n_treated (Portugal post-treatment quarters):", diagnostics$n_treated, "\n")
cat("n_pre:", diagnostics$n_pre, "\n")
cat("n_obs:", diagnostics$n_obs, "\n")
cat("n_countries for RI:", n_countries, "\n")

cat("\nMain analysis complete.\n")
