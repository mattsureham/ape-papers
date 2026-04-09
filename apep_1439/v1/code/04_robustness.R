## 04_robustness.R — Robustness checks
## apep_1439: The Switching Paradox

source("00_packages.R")

panel_weekly <- readRDS("../data/panel_weekly.rds")
panel_group <- readRDS("../data/panel_group.rds")

cat("=== Robustness Checks ===\n\n")

# =====================================================================
# R1: Placebo test — use pre-period fake treatment date (Jan 2020)
# =====================================================================
cat("--- R1: Placebo (fake treatment Jan 2020) ---\n")
panel_placebo <- panel_weekly %>%
  filter(week < as.Date("2022-01-01")) %>%
  mutate(
    post_placebo = as.integer(week >= as.Date("2020-01-01")),
    treat_post_placebo = treated * post_placebo
  )

m_placebo <- feols(hits ~ treat_post_placebo | keyword + week,
                   data = panel_placebo, se = "cluster", cluster = ~keyword)
cat("Placebo (Jan 2020):\n")
print(coeftable(m_placebo))

# =====================================================================
# R2: Drop individual control keywords one at a time
# =====================================================================
cat("\n--- R2: Leave-one-out (control keywords) ---\n")
control_kws <- unique(panel_weekly$keyword[panel_weekly$treated == 0])
loo_results <- list()
for (kw in control_kws) {
  df_loo <- panel_weekly %>% filter(keyword != kw)
  m_loo <- feols(hits ~ treat_post | keyword + week, data = df_loo, se = "cluster", cluster = ~keyword)
  loo_results[[kw]] <- c(coef = coef(m_loo)["treat_post"], se = se(m_loo)["treat_post"])
  cat(sprintf("  Drop %s: β=%.2f (%.2f)\n", kw, loo_results[[kw]]["coef"], loo_results[[kw]]["se"]))
}

# =====================================================================
# R3: Drop individual treated keywords one at a time
# =====================================================================
cat("\n--- R3: Leave-one-out (treated keywords) ---\n")
treated_kws <- unique(panel_weekly$keyword[panel_weekly$treated == 1])
for (kw in treated_kws) {
  df_loo <- panel_weekly %>% filter(keyword != kw)
  m_loo <- feols(hits ~ treat_post | keyword + week, data = df_loo, se = "cluster", cluster = ~keyword)
  cat(sprintf("  Drop %s: β=%.2f (%.2f)\n", kw, coef(m_loo)["treat_post"], se(m_loo)["treat_post"]))
}

# =====================================================================
# R4: Narrow window (±1 year around treatment)
# =====================================================================
cat("\n--- R4: Narrow window (±1 year) ---\n")
panel_narrow <- panel_weekly %>%
  filter(week >= as.Date("2021-01-01") & week <= as.Date("2022-12-31"))
m_narrow <- feols(hits ~ treat_post | keyword + week, data = panel_narrow,
                  se = "cluster", cluster = ~keyword)
cat("Narrow window:\n")
print(coeftable(m_narrow))

# =====================================================================
# R5: Monthly aggregation (reduce noise)
# =====================================================================
cat("\n--- R5: Monthly aggregation ---\n")
panel_monthly <- panel_weekly %>%
  mutate(month_date = floor_date(week, "month")) %>%
  group_by(keyword, month_date, group, treated) %>%
  summarise(hits = mean(hits, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    post = as.integer(month_date >= as.Date("2022-01-01")),
    treat_post = treated * post
  )
m_monthly <- feols(hits ~ treat_post | keyword + month_date, data = panel_monthly,
                   se = "cluster", cluster = ~keyword)
cat("Monthly aggregation:\n")
print(coeftable(m_monthly))

# =====================================================================
# R6: Permutation test — randomize treatment assignment
# =====================================================================
cat("\n--- R6: Permutation test (500 iterations) ---\n")
set.seed(42)
actual_coef <- coef(feols(hits ~ treat_post | keyword + week,
                          data = panel_weekly))["treat_post"]

keywords <- unique(panel_weekly$keyword)
n_treated <- sum(unique(panel_weekly[, c("keyword", "treated")])$treated)
n_perms <- 500
perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  fake_treated <- sample(keywords, n_treated)
  df_perm <- panel_weekly %>%
    mutate(
      treated_perm = as.integer(keyword %in% fake_treated),
      treat_post_perm = treated_perm * post
    )
  m_perm <- feols(hits ~ treat_post_perm | keyword + week, data = df_perm, warn = FALSE)
  perm_coefs[i] <- coef(m_perm)["treat_post_perm"]
}

perm_pval <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("Actual coefficient: %.3f\n", actual_coef))
cat(sprintf("Permutation p-value: %.3f (500 iterations)\n", perm_pval))

# Save robustness results
rob_results <- list(
  m_placebo = m_placebo,
  loo_results = loo_results,
  m_narrow = m_narrow,
  m_monthly = m_monthly,
  perm_pval = perm_pval,
  perm_coefs = perm_coefs,
  actual_coef = actual_coef
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
