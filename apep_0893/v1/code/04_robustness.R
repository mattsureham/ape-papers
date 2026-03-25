## 04_robustness.R — Robustness checks
## Placebo tests, alternative treatment definitions, leave-one-out

source("00_packages.R")

DATA_DIR <- "../data"

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
agency_intensity <- readRDS(file.path(DATA_DIR, "agency_intensity.rds"))
nprm_panel <- readRDS(file.path(DATA_DIR, "nprm_panel.rds"))

# ---------------------------------------------------------------------------
# 1. Placebo: Fake treatment at 2014H1 (3 years before actual)
# ---------------------------------------------------------------------------
panel_placebo <- panel |>
  filter(year_sem < 2017) |>  # pre-period only
  mutate(
    post_placebo = as.integer(year_sem >= 2014),
    treat_placebo = post_placebo * sig_share
  )

placebo_count <- feols(
  log_nprm ~ treat_placebo | primary_agency + year_sem,
  data = panel_placebo,
  cluster = ~primary_agency
)

placebo_complete <- feols(
  completion_rate ~ treat_placebo | primary_agency + year_sem,
  data = panel_placebo |> filter(n_nprm > 0),
  cluster = ~primary_agency
)

cat("=== PLACEBO (2014H1) ===\n")
cat("NPRM count:\n")
print(summary(placebo_count))
cat("Completion rate:\n")
print(summary(placebo_complete))

# ---------------------------------------------------------------------------
# 2. Alternative treatment: binary high/low intensity (median split)
# ---------------------------------------------------------------------------
med_sig <- median(agency_intensity$sig_share)

panel_binary <- panel |>
  mutate(
    high_intensity = as.integer(sig_share > med_sig),
    treat_binary_eo = post_eo13771 * high_intensity,
    treat_binary_rescind = post_rescind * high_intensity
  )

binary_count <- feols(
  log_nprm ~ treat_binary_eo + treat_binary_rescind | primary_agency + year_sem,
  data = panel_binary,
  cluster = ~primary_agency
)

binary_complete <- feols(
  completion_rate ~ treat_binary_eo + treat_binary_rescind | primary_agency + year_sem,
  data = panel_binary |> filter(n_nprm > 0),
  cluster = ~primary_agency
)

cat("\n=== BINARY TREATMENT (median split) ===\n")
cat("NPRM count:\n")
print(summary(binary_count))
cat("Completion rate:\n")
print(summary(binary_complete))

# ---------------------------------------------------------------------------
# 3. Leave-one-out: drop each top-5 agency and re-estimate
# ---------------------------------------------------------------------------
top5 <- agency_intensity |>
  arrange(desc(n_nprm_pre)) |>
  head(5) |>
  pull(primary_agency)

cat("\n=== LEAVE-ONE-OUT (top 5 agencies) ===\n")
loo_results <- map_dfr(top5, function(drop_agency) {
  sub <- panel |> filter(primary_agency != drop_agency)
  m <- feols(
    log_nprm ~ treat_eo + treat_rescind | primary_agency + year_sem,
    data = sub,
    cluster = ~primary_agency
  )
  tibble(
    dropped = drop_agency,
    beta_eo = coef(m)["treat_eo"],
    se_eo = se(m)["treat_eo"],
    beta_rescind = coef(m)["treat_rescind"],
    se_rescind = se(m)["treat_rescind"]
  )
})

print(loo_results)

# ---------------------------------------------------------------------------
# 4. Weighted by pre-period NPRM volume (precision weighting)
# ---------------------------------------------------------------------------
panel_wt <- panel |>
  mutate(weight = n_nprm_pre / mean(n_nprm_pre, na.rm = TRUE))

weighted_count <- feols(
  log_nprm ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_wt,
  weights = ~weight,
  cluster = ~primary_agency
)

cat("\n=== WEIGHTED BY PRE-PERIOD VOLUME ===\n")
print(summary(weighted_count))

# ---------------------------------------------------------------------------
# 5. Excluding COVID period (2020H1-2021H1)
# ---------------------------------------------------------------------------
panel_nocovid <- panel |>
  filter(!(year_sem >= 2020 & year_sem <= 2021))

nocovid_count <- feols(
  log_nprm ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_nocovid,
  cluster = ~primary_agency
)

cat("\n=== EXCLUDING COVID (2020-2021) ===\n")
print(summary(nocovid_count))

# ---------------------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------------------
robust_results <- list(
  placebo_count = placebo_count,
  placebo_complete = placebo_complete,
  binary_count = binary_count,
  binary_complete = binary_complete,
  loo_results = loo_results,
  weighted_count = weighted_count,
  nocovid_count = nocovid_count
)

saveRDS(robust_results, file.path(DATA_DIR, "robustness_results.rds"))

# ---------------------------------------------------------------------------
# 6. Wild Cluster Bootstrap (key composition result)
# ---------------------------------------------------------------------------
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Composition model (the key 18pp result)
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
m4 <- results$m4_composition

# Use fixest's built-in bootstrapped SEs
# Wild cluster bootstrap for the composition result
panel_pos_full <- panel |> filter(n_nprm > 0) |> mutate(sig_rate = n_significant / n_nprm)

m4_boot <- feols(
  sig_rate ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_pos_full,
  cluster = ~primary_agency,
  ssc = ssc(adj = TRUE, cluster.adj = TRUE)
)

# Manual wild cluster bootstrap
set.seed(42)
n_boot <- 999
agencies <- unique(panel_pos_full$primary_agency)
G <- length(agencies)
beta_orig <- coef(m4_boot)["treat_eo"]
t_orig <- coef(m4_boot)["treat_eo"] / se(m4_boot)["treat_eo"]

boot_t <- numeric(n_boot)
for (b in seq_len(n_boot)) {
  # Rademacher weights at cluster level
  w <- sample(c(-1, 1), G, replace = TRUE)
  names(w) <- agencies
  panel_boot <- panel_pos_full |>
    mutate(
      boot_weight = w[primary_agency],
      sig_rate_boot = fitted(m4_boot) + residuals(m4_boot) * boot_weight
    )
  m_b <- tryCatch({
    feols(
      sig_rate_boot ~ treat_eo + treat_rescind | primary_agency + year_sem,
      data = panel_boot,
      cluster = ~primary_agency
    )
  }, error = function(e) NULL)
  if (!is.null(m_b)) {
    boot_t[b] <- coef(m_b)["treat_eo"] / se(m_b)["treat_eo"]
  } else {
    boot_t[b] <- NA
  }
}

boot_t <- boot_t[!is.na(boot_t)]
wcb_pvalue <- mean(abs(boot_t) >= abs(t_orig))
cat(sprintf("Wild cluster bootstrap p-value (composition): %.3f\n", wcb_pvalue))
cat(sprintf("  Original t-stat: %.3f\n", t_orig))
cat(sprintf("  Boot iterations: %d\n", length(boot_t)))

# Save WCB p-value
robust_results$wcb_pvalue_composition <- wcb_pvalue
saveRDS(robust_results, file.path(DATA_DIR, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
