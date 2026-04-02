## 04b_wild_bootstrap.R — Permutation inference for few-cluster DiD

source("00_packages.R")

baltic <- readRDS("../data/baltic_clean.rds")
panel  <- readRDS("../data/panel_clean.rds")

# ── Permutation inference (Baltic DiD) ────────────────────────────────────────
# With only 3 countries, there are 3 possible treatment assignments
# We test whether Estonia's effect is extreme relative to the distribution

cat("=== Permutation Inference: Baltic DiD ===\n")

baltic_countries <- unique(baltic$iso3)
actual_est <- coef(readRDS("../data/did_main.rds"))["treat_post"]

perm_coefs <- numeric(length(baltic_countries))
for (i in seq_along(baltic_countries)) {
  c <- baltic_countries[i]
  temp <- baltic %>%
    mutate(perm_treated = as.integer(iso3 == c),
           perm_tp = perm_treated * post)
  fit <- feols(biz_density ~ perm_tp | iso3 + year, data = temp, cluster = ~iso3)
  perm_coefs[i] <- coef(fit)["perm_tp"]
  cat(sprintf("  Treat %s: coef = %.3f\n", c, perm_coefs[i]))
}

# p-value: fraction of permutations with |coef| >= |actual|
perm_p <- mean(abs(perm_coefs) >= abs(actual_est))
cat(sprintf("\nBaltic permutation p-value: %.3f (actual = %.3f, %d permutations)\n",
            perm_p, actual_est, length(perm_coefs)))

# ── Permutation inference (Full panel) ────────────────────────────────────────
cat("\n=== Permutation Inference: Full Panel ===\n")

panel_countries <- unique(panel$iso3[!is.na(panel$biz_density)])
actual_full <- coef(readRDS("../data/did_full.rds"))["treat_post"]

perm_full_coefs <- numeric(length(panel_countries))
for (i in seq_along(panel_countries)) {
  c <- panel_countries[i]
  temp <- panel %>%
    filter(!is.na(biz_density)) %>%
    mutate(perm_treated = as.integer(iso3 == c),
           perm_tp = perm_treated * post)
  fit <- feols(biz_density ~ perm_tp | iso3 + year, data = temp, cluster = ~iso3)
  perm_full_coefs[i] <- coef(fit)["perm_tp"]
  cat(sprintf("  Treat %s: coef = %.3f\n", c, perm_full_coefs[i]))
}

perm_full_p <- mean(abs(perm_full_coefs) >= abs(actual_full))
cat(sprintf("\nFull panel permutation p-value: %.3f (actual = %.3f, %d permutations)\n",
            perm_full_p, actual_full, length(perm_full_coefs)))

# ── Rank-based test ──────────────────────────────────────────────────────────
# Estonia's rank among all permutations
rank_baltic <- sum(perm_coefs >= actual_est)
rank_full   <- sum(perm_full_coefs >= actual_full)
cat(sprintf("\nEstonia rank: Baltic = %d/%d, Full = %d/%d\n",
            rank_baltic, length(perm_coefs), rank_full, length(perm_full_coefs)))

# ── Save ──────────────────────────────────────────────────────────────────────
boot_results <- list(
  baltic = list(
    actual_coef = actual_est,
    perm_coefs = perm_coefs,
    perm_p = perm_p,
    rank = rank_baltic,
    n_perms = length(perm_coefs)
  ),
  full = list(
    actual_coef = actual_full,
    perm_coefs = perm_full_coefs,
    perm_p = perm_full_p,
    rank = rank_full,
    n_perms = length(perm_full_coefs)
  )
)

saveRDS(boot_results, "../data/wild_bootstrap.rds")
cat("\nPermutation inference results saved.\n")
