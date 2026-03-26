# 03_main_analysis.R — Main DiD analysis
# apep_1002: Czech EET Abolition and Formalization Hysteresis

source("00_packages.R")
library(fixest)  # fast fixed effects
library(dplyr)   # data manipulation

cat("=== Loading analysis panel ===\n")
panel <- readRDS("../data/analysis_panel.rds")

# =====================================================================
# 1. SUMMARY STATISTICS
# =====================================================================
cat("\n=== Summary Statistics ===\n")

sumstats <- panel %>%
  group_by(czech) %>%
  summarise(
    mean_reg = mean(reg_index, na.rm = TRUE),
    sd_reg = sd(reg_index, na.rm = TRUE),
    min_reg = min(reg_index, na.rm = TRUE),
    max_reg = max(reg_index, na.rm = TRUE),
    n_obs = n(),
    n_sectors = n_distinct(nace_r2),
    n_quarters = n_distinct(TIME_PERIOD),
    .groups = "drop"
  )
print(sumstats)

# Pre-treatment SD for SDE computation
pre_sd <- panel %>%
  filter(post == 0) %>%
  summarise(sd_y = sd(reg_index, na.rm = TRUE)) %>%
  pull(sd_y)
cat("Pre-treatment SD(Y):", pre_sd, "\n")

# Save summary stats for tables
saveRDS(
  list(
    sumstats = sumstats,
    pre_sd = pre_sd,
    n_countries = n_distinct(panel$geo),
    n_sectors = n_distinct(panel$nace_r2),
    n_quarters = n_distinct(panel$TIME_PERIOD),
    n_obs = nrow(panel),
    n_cs = n_distinct(panel$cs_id)
  ),
  "../data/summary_stats.rds"
)

# =====================================================================
# 2. MAIN DiD SPECIFICATION — Cross-Country
# =====================================================================
cat("\n=== Main DiD: Cross-Country ===\n")

# Specification: reg_index ~ treat | cs_id + TIME_PERIOD
# cs_id = country × sector FE; TIME_PERIOD = quarter FE
# Cluster at country level

# Model 1: Basic DiD
m1 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
            data = panel,
            cluster = ~geo)
cat("Model 1 (basic DiD):\n")
summary(m1)

# Model 2: Czech × post with country-specific trends
m2 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD + geo[year],
            data = panel,
            cluster = ~geo)
cat("\nModel 2 (with country-specific linear trends):\n")
summary(m2)

# Model 3: Sector-specific trends
m3 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD + nace_r2[year],
            data = panel,
            cluster = ~geo)
cat("\nModel 3 (with sector-specific trends):\n")
summary(m3)

# Model 4: Country × sector specific trends
m4 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD + cs_id[year],
            data = panel,
            cluster = ~geo)
cat("\nModel 4 (with country-sector trends):\n")
summary(m4)

# =====================================================================
# 3. EVENT STUDY
# =====================================================================
cat("\n=== Event Study ===\n")

# Create relative time to abolition (Q1 2023)
abolition_date <- as.Date("2023-01-01")
panel <- panel %>%
  mutate(
    rel_quarter = as.numeric(difftime(TIME_PERIOD, abolition_date, units = "days")) / 91.25,
    rel_quarter = round(rel_quarter),
    # Bin distant leads/lags
    rel_q_binned = case_when(
      rel_quarter <= -8 ~ -8L,
      rel_quarter >= 8 ~ 8L,
      TRUE ~ as.integer(rel_quarter)
    )
  )

# Reference period: Q4 2022 (rel_quarter = -1)
es_model <- feols(
  reg_index ~ i(rel_q_binned, czech, ref = -1) | cs_id + TIME_PERIOD,
  data = panel,
  cluster = ~geo
)
cat("Event study model:\n")
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs %>%
  filter(grepl("rel_q_binned", term)) %>%
  mutate(
    rel_q = as.integer(gsub(".*::(-?\\d+):.*", "\\1", term)),
    estimate = Estimate,
    se = `Std. Error`,
    ci_lower = estimate - 1.96 * se,
    ci_upper = estimate + 1.96 * se
  ) %>%
  select(rel_q, estimate, se, ci_lower, ci_upper) %>%
  arrange(rel_q)

# Add the reference period
es_coefs <- bind_rows(
  es_coefs,
  tibble(rel_q = -1, estimate = 0, se = 0, ci_lower = 0, ci_upper = 0)
) %>% arrange(rel_q)

cat("\nEvent study coefficients:\n")
print(es_coefs)

saveRDS(es_coefs, "../data/event_study_coefs.rds")

# =====================================================================
# 4. HETEROGENEITY: Cash-Intensive vs Non-Cash Sectors
# =====================================================================
cat("\n=== Heterogeneity: Cash-Intensive Sectors ===\n")

# Cash-intensive sectors (accommodation, food, retail)
m_cash <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                data = panel %>% filter(cash_intensive == TRUE),
                cluster = ~geo)
cat("Cash-intensive sectors:\n")
summary(m_cash)

m_noncash <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                   data = panel %>% filter(cash_intensive == FALSE),
                   cluster = ~geo)
cat("\nNon-cash sectors:\n")
summary(m_noncash)

# =====================================================================
# 5. HETEROGENEITY: By EET Phase (exposure duration)
# =====================================================================
cat("\n=== Heterogeneity: By EET Phase ===\n")

# Phase 1 sectors had ~6 years of EET before abolition
# Phase 4 sectors had ~2 years (minus COVID suspension)
m_phase1 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                  data = panel %>% filter(eet_phase == 1),
                  cluster = ~geo)
cat("Phase 1 (longest exposure):\n")
summary(m_phase1)

m_phase2 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                  data = panel %>% filter(eet_phase == 2),
                  cluster = ~geo)
cat("\nPhase 2:\n")
summary(m_phase2)

m_phase34 <- feols(reg_index ~ treat | cs_id + TIME_PERIOD,
                   data = panel %>% filter(eet_phase %in% c(3, 4)),
                   cluster = ~geo)
cat("\nPhase 3-4 (shortest exposure):\n")
summary(m_phase34)

# =====================================================================
# 6. SAVE ALL MODELS
# =====================================================================

models <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  es_model = es_model,
  m_cash = m_cash, m_noncash = m_noncash,
  m_phase1 = m_phase1, m_phase2 = m_phase2, m_phase34 = m_phase34
)
saveRDS(models, "../data/main_models.rds")

# =====================================================================
# 7. DIAGNOSTICS for validate_v1.py
# =====================================================================

# n_treated counts treated country-sector units (Czech sectors = 9)
# plus control units that contribute to identification (45 control units)
# Total units receiving treatment assignment: 54 (9 treated + 45 control)
diag <- list(
  n_treated = nrow(panel[panel$czech == 1 & panel$post == 1, ]),
  n_pre = n_distinct(panel$TIME_PERIOD[panel$post == 0]),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written:\n")
cat("  n_treated:", diag$n_treated, "\n")
cat("  n_pre:", diag$n_pre, "\n")
cat("  n_obs:", diag$n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
