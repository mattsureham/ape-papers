## 04b_ri_and_balance.R — Randomization inference + covariate balance
## Addresses reviewer concern about inference with 5 clusters

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ============================================================
## 1. Randomization Inference (Fisher exact test)
## ============================================================
cat("=== Randomization Inference ===\n")

# Observed test statistic: TWFE coefficient on log(LTV)
m_obs <- feols(log_ltv ~ treated_post | la_id + year,
               data = panel %>% filter(!is.na(log_ltv)),
               cluster = ~ons_code)
beta_obs <- coef(m_obs)[1]
cat("  Observed beta:", round(beta_obs, 4), "\n")

# Permutation test: randomly reassign treatment status among LAs
set.seed(42)
n_perms <- 2000
la_ids <- unique(panel$ons_code)
n_treated <- sum(panel$ever_treated[!duplicated(panel$ons_code)])
n_control <- length(la_ids) - n_treated

perm_betas <- numeric(n_perms)

for (i in 1:n_perms) {
  # Randomly draw 5 LAs as "never-treated" (matching actual design)
  fake_control <- sample(la_ids, n_control)
  perm_data <- panel %>%
    filter(!is.na(log_ltv)) %>%
    mutate(
      perm_treated = !(ons_code %in% fake_control),
      perm_post = year >= 2013,
      perm_treat_post = perm_treated & perm_post
    )

  perm_fit <- tryCatch({
    feols(log_ltv ~ perm_treat_post | la_id + year, data = perm_data, warn = FALSE)
  }, error = function(e) NULL)

  if (!is.null(perm_fit)) {
    perm_betas[i] <- coef(perm_fit)[1]
  } else {
    perm_betas[i] <- NA
  }

  if (i %% 500 == 0) cat("  Completed", i, "permutations\n")
}

perm_betas <- perm_betas[!is.na(perm_betas)]
# Two-sided p-value: proportion of permuted betas at least as extreme
ri_pval <- mean(abs(perm_betas) >= abs(beta_obs))
cat("  RI p-value (two-sided):", round(ri_pval, 4), "\n")
cat("  Permutation distribution: mean =", round(mean(perm_betas), 4),
    ", sd =", round(sd(perm_betas), 4), "\n")

# Save
saveRDS(list(beta_obs = beta_obs, perm_betas = perm_betas, ri_pval = ri_pval),
        file.path(data_dir, "ri_results.rds"))

## ============================================================
## 2. Covariate Balance Table
## ============================================================
cat("\n=== Covariate Balance ===\n")

# Pre-treatment characteristics (2004-2012 average)
balance <- panel %>%
  filter(year >= 2004, year <= 2012) %>%
  group_by(ons_code, ever_treated, area_name) %>%
  summarise(
    mean_ltv = mean(long_term_vacant, na.rm = TRUE),
    mean_av = mean(all_vacant, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    ltv_growth_04_12 = ifelse(
      long_term_vacant[year == min(year)] > 0,
      (long_term_vacant[year == max(year)] - long_term_vacant[year == min(year)]) /
        long_term_vacant[year == min(year)] * 100,
      NA_real_
    ),
    .groups = "drop"
  )

# Summary by group
bal_summary <- balance %>%
  group_by(ever_treated) %>%
  summarise(
    n = n(),
    ltv_mean = mean(mean_ltv, na.rm = TRUE),
    ltv_sd = sd(mean_ltv, na.rm = TRUE),
    av_mean = mean(mean_av, na.rm = TRUE),
    av_sd = sd(mean_av, na.rm = TRUE),
    pop_mean = mean(mean_pop, na.rm = TRUE),
    pop_sd = sd(mean_pop, na.rm = TRUE),
    ltv_growth_mean = mean(ltv_growth_04_12, na.rm = TRUE),
    .groups = "drop"
  )

cat("  Balance summary:\n")
print(bal_summary)

# Control LAs detail
control_detail <- balance %>%
  filter(!ever_treated) %>%
  select(area_name, mean_ltv, mean_av, mean_pop, ltv_growth_04_12)
cat("\n  Control LA details:\n")
print(control_detail)

# Write balance table
t_row <- bal_summary %>% filter(ever_treated)
c_row <- bal_summary %>% filter(!ever_treated)

tex_bal <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Pre-Treatment Covariate Balance (2004--2012 Averages)}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Premium Adopters} & \\multicolumn{2}{c}{Never Adopted} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  sprintf("Long-term vacants & %s & %s & %s & %s \\\\\n",
          round(t_row$ltv_mean), round(t_row$ltv_sd),
          round(c_row$ltv_mean), round(c_row$ltv_sd)),
  sprintf("All vacants & %s & %s & %s & %s \\\\\n",
          format(round(t_row$av_mean), big.mark = ","),
          format(round(t_row$av_sd), big.mark = ","),
          format(round(c_row$av_mean), big.mark = ","),
          format(round(c_row$av_sd), big.mark = ",")),
  sprintf("Population & %s & %s & %s & %s \\\\\n",
          format(round(t_row$pop_mean), big.mark = ","),
          format(round(t_row$pop_sd), big.mark = ","),
          format(round(c_row$pop_mean), big.mark = ","),
          format(round(c_row$pop_sd), big.mark = ",")),
  sprintf("LTV growth 2004--2012 (\\%%) & %.1f & & %.1f & \\\\\n",
          t_row$ltv_growth_mean, c_row$ltv_growth_mean),
  "\\midrule\n",
  sprintf("Local authorities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          t_row$n, c_row$n),
  "\\midrule\n",
  sprintf("RI $p$-value (Fisher exact) & \\multicolumn{4}{c}{%.3f} \\\\\n", ri_pval),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} Pre-treatment averages computed over 2004--2012. ",
  "The five never-adopting LAs are Amber Valley, Bolsover, Castle Point, Gravesham, and Ribble Valley. ",
  "LTV growth is the percentage change in long-term vacants from the first to last pre-treatment year. ",
  "The Randomization Inference (RI) $p$-value is computed from 2,000 random permutations of treatment assignment ",
  "among the 274 LAs, holding the number of controls fixed at 5. It tests the sharp null of no effect for any LA.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:balance}\n",
  "\\end{table}\n"
)

writeLines(tex_bal, file.path(tables_dir, "tab5_balance_ri.tex"))
cat("  Wrote tab5_balance_ri.tex\n")

cat("\nRI and balance analysis complete.\n")
