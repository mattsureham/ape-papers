## 04_robustness.R — Robustness checks and placebo tests
## apep_0862: Civilian Service Expansion and Healthcare Employment in Switzerland

source("00_packages.R")

df <- read_csv("../data/analysis_besta.csv", show_col_types = FALSE)

cat("=== Robustness Checks ===\n")

# Fix DiD specification: create explicit interaction variable
df <- df |>
  mutate(
    did = as.numeric(treated & post),
    rel_year = year - 2009,
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4L,
      rel_year >= 5 ~ 5L,
      TRUE ~ as.integer(rel_year)
    ),
    sector_id = as.integer(factor(sector)),
    sector_trend = sector_id * time_idx
  )

# ==============================================================================
# 1. Corrected main DiD with explicit interaction
# ==============================================================================
cat("\n=== Corrected Main DiD ===\n")

# Main spec: explicit did variable
m_main <- feols(log_emp_fte ~ did | sector + quarter, data = df,
                cluster = "sector")
cat("Main DiD (log FTE ~ did | sector + quarter):\n")
summary(m_main)

# With sector-specific trends
m_trend <- feols(log_emp_fte ~ did | sector + quarter + sector[time_idx],
                 data = df, cluster = "sector")
cat("\nWith sector-specific linear trends:\n")
summary(m_trend)

# Headcount
m_head <- feols(log_emp_total ~ did | sector + quarter,
                data = df, cluster = "sector")
cat("\nHeadcount (robustness):\n")
summary(m_head)

# ==============================================================================
# 2. Permutation inference (randomization inference)
# ==============================================================================
cat("\n=== Permutation Inference ===\n")

# The concern: only 3 treated sectors (86, 87, 88) out of 12.
# Standard clustering (12 clusters) may not be reliable.
# Solution: randomization inference — randomly assign treatment to 3 sectors.

set.seed(42)
n_perms <- 2000
actual_coef <- coef(m_main)["did"]

perm_coefs <- numeric(n_perms)
all_sectors <- unique(df$sector)
n_treated <- 3  # Match actual number of treated sectors

for (i in seq_len(n_perms)) {
  # Randomly assign 3 sectors as "treated"
  fake_treated <- sample(all_sectors, n_treated)
  df$fake_did <- as.numeric(df$sector %in% fake_treated & df$post)

  m_perm <- feols(log_emp_fte ~ fake_did | sector + quarter,
                  data = df, warn = FALSE)
  perm_coefs[i] <- coef(m_perm)["fake_did"]
}

# Two-sided p-value
ri_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("Actual DiD coefficient: %.4f\n", actual_coef))
cat(sprintf("Permutation p-value (2-sided, %d perms): %.4f\n", n_perms, ri_p))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f, [%.4f, %.4f]\n",
            mean(perm_coefs), sd(perm_coefs),
            quantile(perm_coefs, 0.025), quantile(perm_coefs, 0.975)))

# ==============================================================================
# 3. Leave-one-sector-out
# ==============================================================================
cat("\n=== Leave-One-Sector-Out ===\n")

loo_results <- tibble()
for (s in all_sectors) {
  df_loo <- df |> filter(sector != s)
  m_loo <- feols(log_emp_fte ~ did | sector + quarter, data = df_loo)
  loo_results <- bind_rows(loo_results, tibble(
    dropped = s,
    coef = coef(m_loo)["did"],
    se = se(m_loo)["did"]
  ))
}

cat("Leave-one-out range:\n")
cat(sprintf("  Min: %.4f (dropped %s)\n",
            min(loo_results$coef), loo_results$dropped[which.min(loo_results$coef)]))
cat(sprintf("  Max: %.4f (dropped %s)\n",
            max(loo_results$coef), loo_results$dropped[which.max(loo_results$coef)]))
cat(sprintf("  Full sample: %.4f\n", actual_coef))
print(loo_results)

# ==============================================================================
# 4. Placebo reform date (2006)
# ==============================================================================
cat("\n=== Placebo Test: Fake Reform in 2006 ===\n")

df_pre <- df |>
  filter(year <= 2008) |>  # Pre-treatment only
  mutate(
    fake_post = (year >= 2006),
    fake_did = as.numeric(treated & fake_post)
  )

m_placebo <- feols(log_emp_fte ~ fake_did | sector + quarter,
                   data = df_pre, cluster = "sector")
cat("Placebo (fake reform 2006, pre-treatment data only):\n")
summary(m_placebo)

# ==============================================================================
# 5. Alternative control groups
# ==============================================================================
cat("\n=== Alternative Control Groups ===\n")

# A: Only "care-adjacent" controls (education, public admin)
df_narrow <- df |> filter(sector %in% c("86", "87", "88", "85", "84"))
m_narrow <- feols(log_emp_fte ~ did | sector + quarter,
                  data = df_narrow, cluster = "sector")
cat("Narrow controls (education + public admin only):\n")
summary(m_narrow)

# B: Broad services (exclude manufacturing proxies)
df_broad <- df |> filter(!sector %in% c("90-93"))  # Drop arts/recreation
m_broad <- feols(log_emp_fte ~ did | sector + quarter,
                 data = df_broad, cluster = "sector")
cat("\nBroad services (excl. arts/recreation):\n")
summary(m_broad)

# ==============================================================================
# 6. Dose-response: 2011 partial reversal
# ==============================================================================
cat("\n=== Dose-Response: 2011 Partial Reversal ===\n")

# After 2011, admissions tightened and dropped ~15%.
# If the effect is causal, growth should slow in the later period.
df <- df |>
  mutate(
    period = case_when(
      !post ~ "pre",
      year >= 2009 & year <= 2010 ~ "early_post",
      year >= 2011 ~ "late_post"
    ),
    did_early = as.numeric(treated & period == "early_post"),
    did_late = as.numeric(treated & period == "late_post")
  )

m_dose <- feols(log_emp_fte ~ did_early + did_late | sector + quarter,
                data = df, cluster = "sector")
cat("Split-period DiD (early vs late post):\n")
summary(m_dose)

# Test if late effect > early effect (continued growth, not reversal)
cat(sprintf("\nEarly post effect: %.4f\n", coef(m_dose)["did_early"]))
cat(sprintf("Late post effect: %.4f\n", coef(m_dose)["did_late"]))
cat("Note: Late > Early indicates continued divergence (ZIVI stock accumulating)\n")

# ==============================================================================
# 7. Save all robustness results
# ==============================================================================
robustness <- list(
  main = list(coef = coef(m_main)["did"], se = se(m_main)["did"],
              pval = pvalue(m_main)["did"]),
  trend = list(coef = coef(m_trend)["did"], se = se(m_trend)["did"],
               pval = pvalue(m_trend)["did"]),
  headcount = list(coef = coef(m_head)["did"], se = se(m_head)["did"],
                   pval = pvalue(m_head)["did"]),
  ri_pvalue = ri_p,
  placebo_coef = coef(m_placebo)["fake_did"],
  placebo_pval = pvalue(m_placebo)["fake_did"],
  loo_range = c(min(loo_results$coef), max(loo_results$coef)),
  narrow_coef = coef(m_narrow)["did"],
  dose_early = coef(m_dose)["did_early"],
  dose_late = coef(m_dose)["did_late"]
)

saveRDS(robustness, "../data/robustness_results.rds")
saveRDS(list(m_main = m_main, m_trend = m_trend, m_head = m_head,
             m_placebo = m_placebo, m_narrow = m_narrow, m_dose = m_dose,
             perm_coefs = perm_coefs, loo_results = loo_results),
        "../data/robustness_models.rds")

cat("\n=== Robustness complete ===\n")
