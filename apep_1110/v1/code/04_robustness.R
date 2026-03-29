# 04_robustness.R — Robustness and falsification tests
# APEP paper apep_1110: UK Sugar Tax and Childhood Dental Decay

source("code/00_packages.R")

panel <- read_csv("data/analysis_panel.csv", show_col_types = FALSE)
results <- readRDS("data/main_results.rds")

# ============================================================================
# 1. Event study with t=-1 (2014) as reference — closer reference period
# ============================================================================
cat("=== Event Study: Reference t=-1 (2014) ===\n")

panel <- panel %>%
  mutate(event_factor = factor(event_time))

m_event_alt <- feols(decay_pct ~ i(event_factor, imd_std, ref = "-1") | area_code + year,
                     data = panel, cluster = ~area_code)

coefs <- coeftable(m_event_alt)
for (i in 1:nrow(coefs)) {
  cat("  ", rownames(coefs)[i], ": beta =", round(coefs[i, 1], 3),
      " SE =", round(coefs[i, 2], 3),
      " p =", round(coefs[i, 4], 4), "\n")
}

# ============================================================================
# 2. Pre-trend test: F-test for joint significance of pre-treatment leads
# ============================================================================
cat("\n=== Pre-trend F-test ===\n")
# Using reference t=-3, test H0: beta_{t=-2} = beta_{t=-1} = 0
m_event_main <- feols(decay_pct ~ i(event_factor, imd_std, ref = "-3") | area_code + year,
                      data = panel, cluster = ~area_code)

pre_test <- wald(m_event_main, c("event_factor::-2:imd_std", "event_factor::-1:imd_std"))
cat("Joint F-test of pre-treatment coefficients:\n")
print(pre_test)

# ============================================================================
# 3. Placebo: Pure pre-treatment DiD (2007-2014 only)
# ============================================================================
cat("\n=== Placebo: Pre-treatment DiD (fake treatment at 2014) ===\n")

panel_pre <- panel %>%
  filter(year <= 2014) %>%
  mutate(fake_post = ifelse(year >= 2014, 1, 0),
         fake_post_x_imd = fake_post * imd_std)

m_placebo <- feols(decay_pct ~ fake_post_x_imd | area_code + year,
                   data = panel_pre, cluster = ~area_code)

cat("Placebo beta =", round(coef(m_placebo)[1], 3),
    " SE =", round(se(m_placebo)[1], 3),
    " p =", round(pvalue(m_placebo)[1], 4), "\n")

# ============================================================================
# 4. Alternative treatment definitions
# ============================================================================
cat("\n=== Alternative: IMD terciles ===\n")

panel <- panel %>%
  mutate(imd_tercile = ntile(imd_score, 3),
         high_dep = ifelse(imd_tercile == 3, 1, 0),
         mid_dep = ifelse(imd_tercile == 2, 1, 0))

m_tercile <- feols(decay_pct ~ post:high_dep + post:mid_dep | area_code + year,
                   data = panel, cluster = ~area_code)
cat("High deprivation x Post:", round(coef(m_tercile)[1], 3),
    " (", round(se(m_tercile)[1], 3), ")\n")
cat("Mid deprivation x Post: ", round(coef(m_tercile)[2], 3),
    " (", round(se(m_tercile)[2], 3), ")\n")

# ============================================================================
# 5. Exclude transition period (2016/17)
# ============================================================================
cat("\n=== Exclude announcement transition year (2016/17) ===\n")

panel_no_trans <- panel %>% filter(year != 2016)
m_no_trans <- feols(decay_pct ~ post_x_imd | area_code + year,
                    data = panel_no_trans, cluster = ~area_code)

cat("Without 2016/17: beta =", round(coef(m_no_trans)[1], 3),
    " SE =", round(se(m_no_trans)[1], 3),
    " p =", round(pvalue(m_no_trans)[1], 4), "\n")

# ============================================================================
# 6. Exclude COVID + transition
# ============================================================================
cat("\n=== Exclude both COVID (2021) and transition (2016) ===\n")

panel_clean <- panel %>% filter(!year %in% c(2016, 2021))
m_clean <- feols(decay_pct ~ post_x_imd | area_code + year,
                 data = panel_clean, cluster = ~area_code)

cat("Clean panel: beta =", round(coef(m_clean)[1], 3),
    " SE =", round(se(m_clean)[1], 3),
    " p =", round(pvalue(m_clean)[1], 4), "\n")

# ============================================================================
# 7. Permutation inference: randomize IMD across LAs
# ============================================================================
cat("\n=== Permutation Inference (500 permutations) ===\n")

set.seed(42)
n_perms <- 500
true_beta <- coef(results$m1)["post_x_imd"]
perm_betas <- numeric(n_perms)

la_imd <- panel %>%
  distinct(area_code, imd_std)

for (p in 1:n_perms) {
  # Shuffle IMD scores across LAs
  shuffled_imd <- data.frame(
    area_code = la_imd$area_code,
    imd_std_perm = sample(la_imd$imd_std)
  )

  panel_perm <- panel %>%
    left_join(shuffled_imd, by = "area_code") %>%
    mutate(post_x_imd_perm = post * imd_std_perm)

  m_perm <- tryCatch(
    feols(decay_pct ~ post_x_imd_perm | area_code + year,
          data = panel_perm, cluster = ~area_code),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    perm_betas[p] <- coef(m_perm)["post_x_imd_perm"]
  } else {
    perm_betas[p] <- NA
  }
}

perm_betas <- perm_betas[!is.na(perm_betas)]
perm_p <- mean(abs(perm_betas) >= abs(true_beta))
cat("True beta:", round(true_beta, 3), "\n")
cat("Permutation p-value (two-sided):", round(perm_p, 3), "\n")
cat("Permutation SD:", round(sd(perm_betas), 3), "\n")

# ============================================================================
# 8. Power analysis: what effect could we detect?
# ============================================================================
cat("\n=== Power Analysis ===\n")

# MDE at 80% power, alpha = 0.05 (two-sided)
se_beta <- se(results$m1)["post_x_imd"]
mde <- 2.8 * se_beta  # approx (z_alpha/2 + z_beta) * SE
cat("Minimum detectable effect (80% power): ", round(mde, 2), " pp\n")
cat("This is", round(mde / mean(panel$decay_pct, na.rm=TRUE) * 100, 1),
    "% of mean decay rate\n")
cat("Actual estimate:", round(true_beta, 3), "pp per SD of IMD\n")

# ============================================================================
# 9. Detrended specification: remove linear pre-trend
# ============================================================================
cat("\n=== Detrended specification ===\n")

# Allow LA-specific linear trends
m_trend <- feols(decay_pct ~ post_x_imd | area_code[year],
                 data = panel, cluster = ~area_code)

cat("With LA-specific linear trends: beta =", round(coef(m_trend)["post_x_imd"], 3),
    " SE =", round(se(m_trend)["post_x_imd"], 3),
    " p =", round(pvalue(m_trend)["post_x_imd"], 4), "\n")

# ============================================================================
# 10. Save robustness results
# ============================================================================
rob_results <- list(
  m_event_alt = m_event_alt,
  m_event_main = m_event_main,
  m_placebo = m_placebo,
  m_tercile = m_tercile,
  m_no_trans = m_no_trans,
  m_clean = m_clean,
  m_trend = m_trend,
  perm_p = perm_p,
  perm_betas = perm_betas,
  true_beta = true_beta,
  mde = mde,
  panel = panel
)

saveRDS(rob_results, "data/robustness_results.rds")
cat("\nSaved robustness_results.rds\n")
