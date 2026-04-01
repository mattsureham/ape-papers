## 04b_reviewer_fixes.R — Address reviewer suggestions
## Permutation test, pre-trend F-test, MDE calculation

source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "regression_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))
panel <- read_csv(file.path(data_dir, "panel_indicators.csv"), show_col_types = FALSE) %>%
  mutate(date = floor_date(date, "month"))

# ============================================================
# 1. Permutation Test (randomization inference)
# ============================================================
cat("=== Permutation Test ===\n")

# Observed DiD coefficient
observed_did <- coef(m1_roa)["did"]
cat("Observed DiD (ROA):", round(observed_did, 6), "\n")

# Under H0, randomly assign treatment label to one of the 6 bank types
# and compute the DiD coefficient. Repeat 10,000 times.
set.seed(42)
n_perms <- 10000

# Full panel with all bank types
full_panel <- panel %>%
  dplyr::filter(treat_group %in% c("International License", "Panamanian Private",
                                    "Foreign Private", "Official",
                                    "Centro Bancario", "Sistema Bancario")) %>%
  mutate(
    grey_period = as.integer(date >= as.Date("2019-06-01") & date < as.Date("2023-10-01")),
    post_delist = as.integer(date >= as.Date("2023-10-01")),
    bank_id = as.integer(factor(treat_group))
  )

# For each permutation, pick one bank type as "treated" and Panamanian Private as control
bank_types <- unique(full_panel$treat_group)
other_types <- setdiff(bank_types, "Panamanian Private")

perm_coefs <- numeric(n_perms)
for (i in 1:n_perms) {
  # Randomly pick which type is "treated"
  fake_treat <- sample(other_types, 1)
  perm_df <- full_panel %>%
    dplyr::filter(treat_group %in% c(fake_treat, "Panamanian Private")) %>%
    mutate(
      treated = as.integer(treat_group == fake_treat),
      did = treated * grey_period,
      did_delist = treated * post_delist,
      bank_id = as.integer(factor(treat_group))
    )

  fit <- tryCatch(
    feols(roa ~ did + did_delist | bank_id + date, data = perm_df, vcov = "hetero"),
    error = function(e) NULL
  )

  if (!is.null(fit)) {
    perm_coefs[i] <- coef(fit)["did"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
p_perm <- mean(abs(perm_coefs) >= abs(observed_did))
cat("Permutation p-value (two-sided):", round(p_perm, 4), "\n")
cat("Permutation distribution: mean =", round(mean(perm_coefs), 6),
    ", SD =", round(sd(perm_coefs), 6), "\n")

# ============================================================
# 2. Joint F-test of pre-treatment event study coefficients
# ============================================================
cat("\n=== Joint F-test of Pre-treatment Coefficients ===\n")

# Use the binned event study for ROA
pre_coefs <- names(coef(es_binned_roa))
pre_names <- pre_coefs[grepl("::-[2-6]:", pre_coefs)]
cat("Pre-treatment coefficients tested:", pre_names, "\n")

# Wald test
if (length(pre_names) > 0) {
  wald <- wald(es_binned_roa, keep = pre_names)
  cat("Wald test result:\n")
  print(wald)
}

# ============================================================
# 3. Minimum Detectable Effect (MDE)
# ============================================================
cat("\n=== Minimum Detectable Effect ===\n")

# SE of the DiD coefficient
se_did <- se(m1_roa)["did"]
# MDE at 80% power, 5% significance (two-sided): MDE = 2.8 * SE
mde <- 2.8 * se_did
sd_y_pre <- sd(df$roa[df$date < as.Date("2019-06-01")], na.rm = TRUE)
mde_sde <- mde / sd_y_pre

cat("SE(DiD):", round(se_did, 5), "\n")
cat("MDE (80% power, 5% sig):", round(mde, 5), "pp\n")
cat("MDE as share of pre-treatment mean ROA:",
    round(mde / mean(df$roa[df$treated == 1 & df$date < as.Date("2019-06-01")], na.rm = TRUE) * 100, 1), "%\n")
cat("MDE in SDE units:", round(mde_sde, 2), "\n")

cat("\nDone. Key results for paper:\n")
cat("  Permutation p-value:", round(p_perm, 3), "\n")
cat("  MDE:", round(mde, 4), "pp (", round(mde_sde, 2), "SD)\n")
