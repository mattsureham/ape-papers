## 04_robustness.R — Robustness checks for Italy AUU fertility study
source("00_packages.R")

cat("=== Robustness Checks ===\n")

it_panel <- readRDS("../data/italy_panel.rds")
it_panel <- it_panel %>%
  mutate(
    selfemp_tercile = ntile(self_emp_share_2019, 3),
    south = as.integer(str_sub(nuts2, 1, 3) %in% c("ITF", "ITG"))
  )

# ---------------------------------------------------------------
# 1. Placebo tests (pseudo-treatment dates)
# ---------------------------------------------------------------
cat("\n--- Placebo: pseudo-treatment at 2018 ---\n")
plac_2018 <- it_panel %>%
  filter(year <= 2021) %>%
  mutate(
    post_plac = as.integer(year >= 2018),
    dd_plac = post_plac * self_emp_share_2019
  )
m_plac18 <- feols(birth_rate ~ dd_plac | nuts3 + year,
                  data = plac_2018, cluster = ~nuts2)
summary(m_plac18)

cat("\n--- Placebo: pseudo-treatment at 2019 ---\n")
plac_2019 <- it_panel %>%
  filter(year <= 2021) %>%
  mutate(
    post_plac = as.integer(year >= 2019),
    dd_plac = post_plac * self_emp_share_2019
  )
m_plac19 <- feols(birth_rate ~ dd_plac | nuts3 + year,
                  data = plac_2019, cluster = ~nuts2)
summary(m_plac19)

# ---------------------------------------------------------------
# 2. Shorter pre-period (2015-2023) — cleaner pre-trends
# ---------------------------------------------------------------
cat("\n--- Shorter pre-period (2015-2023) ---\n")
it_short <- it_panel %>% filter(year >= 2015)
m_short <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                 data = it_short, cluster = ~nuts2)
summary(m_short)

# Event study with shorter window
m_es_short <- feols(birth_rate ~ i(year, self_emp_share_2019, ref = 2021) |
                      nuts3 + year,
                    data = it_short, cluster = ~nuts2)
cat("\nEvent study (2015-2023):\n")
summary(m_es_short)

# ---------------------------------------------------------------
# 3. Alternative clustering
# ---------------------------------------------------------------
cat("\n--- Alternative clustering ---\n")

m_nuts3_cl <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                    data = it_panel, cluster = ~nuts3)
cat("Clustered at NUTS3:\n")
cat(sprintf("  Coef: %.3f, SE: %.3f, p: %.4f\n",
            coef(m_nuts3_cl), se(m_nuts3_cl), pvalue(m_nuts3_cl)))

# Conley SEs not available in fixest for panel, use HC robust
m_robust <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                  data = it_panel, vcov = "hetero")
cat("Heteroskedasticity-robust:\n")
cat(sprintf("  Coef: %.3f, SE: %.3f, p: %.4f\n",
            coef(m_robust), se(m_robust), pvalue(m_robust)))

# ---------------------------------------------------------------
# 4. Leave-one-out (drop each NUTS2 region)
# ---------------------------------------------------------------
cat("\n--- Leave-one-out (by NUTS2 region) ---\n")
nuts2_list <- unique(it_panel$nuts2)
loo_results <- tibble(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (r in nuts2_list) {
  loo_data <- it_panel %>% filter(nuts2 != r)
  m_loo <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                 data = loo_data, cluster = ~nuts2)
  loo_results <- bind_rows(loo_results, tibble(
    dropped = r,
    coef = coef(m_loo)[[1]],
    se = se(m_loo)[[1]],
    pval = pvalue(m_loo)[[1]]
  ))
}

cat(sprintf("  LOO coefficient range: [%.2f, %.2f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  Baseline coefficient: %.2f\n",
            coef(feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                       data = it_panel, cluster = ~nuts2))[[1]]))

# ---------------------------------------------------------------
# 5. Continuous treatment quartile specification
# ---------------------------------------------------------------
cat("\n--- Quartile specification ---\n")
it_panel <- it_panel %>%
  mutate(
    selfemp_q = ntile(self_emp_share_2019, 4),
    selfemp_q2 = as.integer(selfemp_q == 2),
    selfemp_q3 = as.integer(selfemp_q == 3),
    selfemp_q4 = as.integer(selfemp_q == 4)
  )

m_quart <- feols(birth_rate ~ post:selfemp_q2 + post:selfemp_q3 + post:selfemp_q4 |
                   nuts3 + year,
                 data = it_panel, cluster = ~nuts2)
cat("Quartile interactions (Q1 = reference):\n")
summary(m_quart)

# ---------------------------------------------------------------
# 6. Wild cluster bootstrap (for small # of clusters = 21 NUTS2)
# ---------------------------------------------------------------
cat("\n--- Wild cluster bootstrap (21 NUTS2 clusters) ---\n")
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cran.r-project.org")
}
library(fwildclusterboot)
# Use lm for compatibility with fwildclusterboot
it_panel_boot <- it_panel %>%
  mutate(nuts3_f = factor(nuts3), year_f = factor(year))
m_lm <- lm(birth_rate ~ dd_post_selfemp + nuts3_f + year_f,
            data = it_panel_boot)
set.seed(12345)
boot_res <- boottest(m_lm, param = "dd_post_selfemp",
                     B = 9999, clustid = ~nuts2, type = "webb")
cat(sprintf("  Bootstrap p-value: %.4f\n", boot_res$p_val))
cat(sprintf("  Bootstrap CI: [%.3f, %.3f]\n",
            boot_res$conf_int[1], boot_res$conf_int[2]))

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
rob_results <- list(
  placebo_2018 = m_plac18,
  placebo_2019 = m_plac19,
  short_window = m_short,
  event_study_short = m_es_short,
  quartile = m_quart,
  loo_range = c(min(loo_results$coef), max(loo_results$coef))
)
saveRDS(rob_results, "../data/robustness_results.rds")
saveRDS(loo_results, "../data/loo_results.rds")

cat("\n=== Robustness checks complete ===\n")
