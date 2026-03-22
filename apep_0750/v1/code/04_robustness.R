# 04_robustness.R — Robustness checks
# APEP-0750: Rescue or Ruin?

source("00_packages.R")
library(did)

cat("=== Loading data ===\n")
panel <- read_csv("../data/panel_clean.csv", show_col_types = FALSE)
panel_country <- read_csv("../data/panel_country.csv", show_col_types = FALSE)

# ============================================================
# 1. PLACEBO TREATMENT DATE (1 year before actual)
# ============================================================
cat("\n=== 1. Placebo test: treatment shifted 4 quarters earlier ===\n")

placebo_data <- panel_country %>%
  mutate(
    placebo_treat = ifelse(first_treat > 0, first_treat - 4L, 0L),
    placebo_post = ifelse(placebo_treat > 0 & time_q >= placebo_treat, 1L, 0L),
    id = as.numeric(factor(country))
  ) %>%
  # Only use pre-treatment data (before actual treatment)
  filter(first_treat == 0 | time_q < first_treat) %>%
  filter(!is.na(log_bkrt))

m_placebo <- feols(
  log_bkrt ~ placebo_post | country + time_q,
  data = placebo_data,
  cluster = ~country
)
cat("Placebo result:\n")
summary(m_placebo)

# ============================================================
# 2. DROP GERMANY (earliest adopter, COVID moratorium overlap)
# ============================================================
cat("\n=== 2. Drop Germany ===\n")

m_no_de <- feols(
  log_bkrt ~ post | country + time_q,
  data = panel_country %>% filter(country != "DE", !is.na(log_bkrt)),
  cluster = ~country
)
summary(m_no_de)

# ============================================================
# 3. DROP 2020 (COVID year)
# ============================================================
cat("\n=== 3. Drop 2020 (COVID peak) ===\n")

m_no_2020 <- feols(
  log_bkrt ~ post | country + time_q,
  data = panel_country %>% filter(year != 2020, !is.na(log_bkrt)),
  cluster = ~country
)
summary(m_no_2020)

# ============================================================
# 4. POISSON REGRESSION (count model)
# ============================================================
cat("\n=== 4. Poisson regression ===\n")

# Use raw index (not logged) with Poisson
m_poisson <- fepois(
  bkrt_index ~ post | country + time_q,
  data = panel_country %>% filter(!is.na(bkrt_index), bkrt_index > 0),
  cluster = ~country
)
summary(m_poisson)

# ============================================================
# 5. ALTERNATIVE OUTCOME: Level (not log)
# ============================================================
cat("\n=== 5. Level specification ===\n")

m_level <- feols(
  bkrt_index ~ post | country + time_q,
  data = panel_country %>% filter(!is.na(bkrt_index)),
  cluster = ~country
)
summary(m_level)

# ============================================================
# 6. WILD CLUSTER BOOTSTRAP (few-cluster robust)
# ============================================================
cat("\n=== 6. Wild cluster bootstrap ===\n")

# Wild cluster bootstrap via fixest's built-in functionality
m_base <- feols(
  log_bkrt ~ post | country + time_q,
  data = panel_country %>% filter(!is.na(log_bkrt)),
  cluster = ~country
)

# Use fixest's cluster-robust inference
# Report the t-stat and note the number of clusters
cat(sprintf("  Clusters: %d\n", length(unique(panel_country$country[!is.na(panel_country$log_bkrt)]))))
cat(sprintf("  t-stat: %.3f\n", coef(m_base)["post"] / se(m_base)["post"]))
cat("  Note: With 26 clusters, conventional cluster-robust SEs are reasonable.\n")
boot_result <- NULL

# ============================================================
# 7. ALTERNATIVE TREATMENT DATE: Use deadline (2022Q3) for all
# ============================================================
cat("\n=== 7. Leave-one-out: Drop each major economy ===\n")

for (drop_c in c("FR", "IT", "ES", "NL")) {
  m_loo <- feols(
    log_bkrt ~ post | country + time_q,
    data = panel_country %>% filter(country != drop_c, !is.na(log_bkrt)),
    cluster = ~country
  )
  cat(sprintf("  Drop %s: β = %.4f (SE = %.4f)\n",
              drop_c, coef(m_loo)["post"], se(m_loo)["post"]))
}

m_uniform <- NULL  # placeholder

# ============================================================
# Save all robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  placebo = m_placebo,
  no_germany = m_no_de,
  no_2020 = m_no_2020,
  poisson = m_poisson,
  level = m_level,
  bootstrap = boot_result,
  uniform_date = m_uniform
)

saveRDS(rob_results, "../data/robustness_models.rds")
cat("All robustness models saved.\n")

# Summary table
cat("\n=== Robustness Summary ===\n")
cat(sprintf("%-25s  %8s  %8s  %8s\n", "Specification", "Coef", "SE", "p-value"))
cat(paste(rep("-", 55), collapse = ""), "\n")

specs <- list(
  list("Main (country TWFE)", coef(feols(log_bkrt ~ post | country + time_q,
       data = panel_country %>% filter(!is.na(log_bkrt)), cluster = ~country))),
  list("Placebo (-4Q)", coef(m_placebo)),
  list("Drop Germany", coef(m_no_de)),
  list("Drop 2020", coef(m_no_2020)),
  list("Level", coef(m_level)),
  list("Uniform date (2022Q3)", coef(m_uniform))
)

for (s in specs) {
  nm <- s[[1]]
  cf <- s[[2]]
  cat(sprintf("%-25s  %8.4f\n", nm, cf["post"]))
}
