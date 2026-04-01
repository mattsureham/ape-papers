# 04_robustness.R — apep_1239: Swiss NFA Reform
# Robustness checks: placebos, leave-one-out, randomization inference

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(paste0(data_dir, "analysis_panel.rds"))

canton_names <- c(
  "Switzerland", "Zürich", "Bern", "Luzern", "Uri", "Schwyz",
  "Obwalden", "Nidwalden", "Glarus", "Zug", "Fribourg",
  "Solothurn", "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
  "Appenzell A.Rh.", "Appenzell I.Rh.", "St. Gallen", "Graubünden",
  "Aargau", "Thurgau", "Ticino", "Vaud", "Valais",
  "Neuchâtel", "Genève", "Jura"
)

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. PLACEBO CUTOFFS (2004, 2006)
# ============================================================

cat("--- Placebo test: false reform dates ---\n")

placebo_results <- list()
for (placebo_year in c(2004, 2006)) {
  panel_placebo <- panel %>%
    filter(year < 2008) %>%  # Pre-reform data only
    mutate(
      post_placebo = as.integer(year >= placebo_year),
      treat_placebo = transfer_intensity * post_placebo
    )

  m_placebo <- feols(
    net_migration_rate ~ treat_placebo | canton_f + year_f,
    data = panel_placebo,
    cluster = ~canton_f
  )

  placebo_results[[as.character(placebo_year)]] <- list(
    coef = coef(m_placebo)["treat_placebo"],
    se = se(m_placebo)["treat_placebo"],
    pval = pvalue(m_placebo)["treat_placebo"]
  )

  cat(sprintf("  Placebo %d: coef=%.4f, se=%.4f, p=%.3f\n",
              placebo_year,
              coef(m_placebo)["treat_placebo"],
              se(m_placebo)["treat_placebo"],
              pvalue(m_placebo)["treat_placebo"]))
}

# ============================================================
# 2. LEAVE-ONE-OUT: Drop each canton
# ============================================================

cat("\n--- Leave-one-out: Drop each canton ---\n")

loo_results <- tibble()
for (c_drop in 1:26) {
  m_loo <- feols(
    net_migration_rate ~ treat_cont | canton_f + year_f,
    data = panel %>% filter(canton_code != c_drop),
    cluster = ~canton_f
  )
  loo_results <- bind_rows(loo_results, tibble(
    dropped_canton = c_drop,
    canton_name = canton_names[c_drop + 1],
    coef = coef(m_loo)["treat_cont"],
    se = se(m_loo)["treat_cont"],
    pval = pvalue(m_loo)["treat_cont"]
  ))
}

cat(sprintf("  LOO coefficient range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  Full-sample coefficient: %.4f\n",
            coef(feols(net_migration_rate ~ treat_cont | canton_f + year_f,
                       data = panel, cluster = ~canton_f))["treat_cont"]))

# Check if dropping Zug (largest payer, code=9) changes results substantially
zug_row <- loo_results %>% filter(dropped_canton == 9)
cat(sprintf("  Dropping Zug (largest payer): coef=%.4f (p=%.3f)\n",
            zug_row$coef, zug_row$pval))

# ============================================================
# 3. RANDOMIZATION INFERENCE
# ============================================================

cat("\n--- Randomization inference (1000 permutations) ---\n")

set.seed(42)
n_perms <- 1000

# True coefficient
m_true <- feols(
  net_migration_rate ~ treat_cont | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
true_coef <- coef(m_true)["treat_cont"]

# Permute treatment intensity across cantons
canton_intensities <- panel %>%
  distinct(canton_code, transfer_intensity) %>%
  pull(transfer_intensity)

ri_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  perm_intensity <- sample(canton_intensities)  # Shuffle across cantons
  panel_perm <- panel %>%
    left_join(
      tibble(canton_code = 1:26, perm_intensity = perm_intensity),
      by = "canton_code"
    ) %>%
    mutate(treat_perm = perm_intensity * post)

  m_perm <- feols(
    net_migration_rate ~ treat_perm | canton_f + year_f,
    data = panel_perm,
    cluster = ~canton_f,
    warn = FALSE
  )

  ri_coefs[i] <- coef(m_perm)["treat_perm"]
}

ri_pval <- mean(abs(ri_coefs) >= abs(true_coef))
cat(sprintf("  True coefficient: %.4f\n", true_coef))
cat(sprintf("  RI p-value (two-sided): %.3f\n", ri_pval))
cat(sprintf("  RI distribution: mean=%.4f, sd=%.4f\n", mean(ri_coefs), sd(ri_coefs)))

# ============================================================
# 4. ALTERNATIVE SPECIFICATIONS
# ============================================================

cat("\n--- Alternative specifications ---\n")

# Winsorized migration rate (trim extreme values)
q01 <- quantile(panel$net_migration_rate, 0.01, na.rm = TRUE)
q99 <- quantile(panel$net_migration_rate, 0.99, na.rm = TRUE)
panel_wins <- panel %>%
  mutate(net_mig_wins = pmin(pmax(net_migration_rate, q01), q99))

m_wins <- feols(
  net_mig_wins ~ treat_cont | canton_f + year_f,
  data = panel_wins,
  cluster = ~canton_f
)
cat(sprintf("  Winsorized: coef=%.4f, se=%.4f, p=%.3f\n",
            coef(m_wins)["treat_cont"], se(m_wins)["treat_cont"],
            pvalue(m_wins)["treat_cont"]))

# Weighted by population
m_wpop <- feols(
  net_migration_rate ~ treat_cont | canton_f + year_f,
  data = panel,
  cluster = ~canton_f,
  weights = ~population
)
cat(sprintf("  Pop-weighted: coef=%.4f, se=%.4f, p=%.3f\n",
            coef(m_wpop)["treat_cont"], se(m_wpop)["treat_cont"],
            pvalue(m_wpop)["treat_cont"]))

# Shorter post-period (2008-2015) to reduce GFC confound
m_short <- feols(
  net_migration_rate ~ treat_cont | canton_f + year_f,
  data = panel %>% filter(year <= 2015),
  cluster = ~canton_f
)
cat(sprintf("  Short post (2008-2015): coef=%.4f, se=%.4f, p=%.3f\n",
            coef(m_short)["treat_cont"], se(m_short)["treat_cont"],
            pvalue(m_short)["treat_cont"]))

# ============================================================
# SAVE RESULTS
# ============================================================

robustness <- list(
  placebo = placebo_results,
  loo = loo_results,
  ri_pval = ri_pval,
  ri_coefs = ri_coefs,
  true_coef = true_coef,
  m_wins = m_wins,
  m_wpop = m_wpop,
  m_short = m_short
)
saveRDS(robustness, paste0(data_dir, "robustness.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
