## 03_main_analysis.R — Main DiD analysis
## apep_0862: Civilian Service Expansion and Healthcare Employment in Switzerland

source("00_packages.R")
library(fixest)
library(dplyr)

df <- read_csv("../data/analysis_besta.csv", show_col_types = FALSE)

cat("=== Main Analysis: Sector-Level DiD ===\n")
cat(sprintf("Panel: %d obs, %d sectors, %d quarters (2003Q1-2016Q4)\n",
            nrow(df), n_distinct(df$sector), n_distinct(df$quarter)))

# ==============================================================================
# 1. Pre-treatment summary statistics
# ==============================================================================
cat("\n=== Pre-treatment summary statistics ===\n")

pre_stats <- df |>
  filter(!post) |>
  group_by(treated) |>
  summarise(
    n_sectors = n_distinct(sector),
    n_quarters = n_distinct(quarter),
    n_obs = n(),
    mean_fte = mean(emp_fte, na.rm = TRUE),
    sd_fte = sd(emp_fte, na.rm = TRUE),
    mean_total = mean(emp_total, na.rm = TRUE),
    sd_total = sd(emp_total, na.rm = TRUE),
    .groups = "drop"
  )
print(pre_stats)

post_stats <- df |>
  filter(post) |>
  group_by(treated) |>
  summarise(
    n_obs = n(),
    mean_fte = mean(emp_fte, na.rm = TRUE),
    sd_fte = sd(emp_fte, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPost-treatment:\n")
print(post_stats)

# ==============================================================================
# 2. Main DiD: log(FTE) ~ Treated x Post
# ==============================================================================
cat("\n=== Main DiD Specification ===\n")

# Specification 1: Basic DiD with sector + quarter FE
m1 <- feols(log_emp_fte ~ treated:post | sector + quarter, data = df)

# Specification 2: Sector-specific linear trends
df <- df |> mutate(sector_trend = sector_id * time_idx)
m2 <- feols(log_emp_fte ~ treated:post | sector + quarter + sector_trend, data = df)

# Specification 3: Headcount instead of FTE
m3 <- feols(log_emp_total ~ treated:post | sector + quarter, data = df)

cat("\n--- Specification 1: Basic DiD (FTE) ---\n")
summary(m1)

cat("\n--- Specification 2: With sector-specific trends (FTE) ---\n")
summary(m2)

cat("\n--- Specification 3: Headcount (robustness) ---\n")
summary(m3)

# ==============================================================================
# 3. Event Study (main specification)
# ==============================================================================
cat("\n=== Event Study ===\n")

# Create relative time indicators (years relative to 2009)
df <- df |>
  mutate(
    rel_year = year - 2009,
    # Bin endpoints
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4,
      rel_year >= 5 ~ 5,
      TRUE ~ rel_year
    )
  )

# Event study with year-level relative time (not quarter)
# Reference period: rel_year = -1 (2008)
m_es <- feols(log_emp_fte ~ i(rel_year_binned, treated, ref = -1) | sector + quarter,
              data = df)

cat("Event study coefficients:\n")
summary(m_es)

# ==============================================================================
# 4. Continuous treatment: ZIVI penetration
# ==============================================================================
cat("\n=== Continuous Treatment Specification ===\n")

# Treatment intensity: ZIVI FTE in health/social per 1000 FTE in the sector
df <- df |>
  mutate(
    zivi_penetration = ifelse(treated & !is.na(zivi_fte),
                              zivi_fte / (emp_fte / 1000), 0)
  )

# Log-level: effect of ZIVI penetration on log employment
m4 <- feols(log_emp_fte ~ zivi_penetration | sector + quarter, data = df)
cat("Continuous treatment (ZIVI penetration):\n")
summary(m4)

# ==============================================================================
# 5. STATENT cross-sectional analysis (post-treatment variation)
# ==============================================================================
cat("\n=== STATENT Canton-Level Analysis ===\n")

statent <- read_csv("../data/analysis_statent.csv", show_col_types = FALSE)

# Compute growth rates relative to 2011 baseline
statent_growth <- statent |>
  group_by(canton, sector) |>
  mutate(
    fte_2011 = emp_fte[year == 2011],
    log_fte = log(pmax(emp_fte, 1)),
    fte_growth = (emp_fte - fte_2011) / fte_2011
  ) |>
  ungroup()

# Within post-period variation: treated sectors grew more in later years
# when ZIVI deployment was highest
m5 <- feols(log_fte ~ treated:factor(year) | canton^sector + canton^year,
            data = statent_growth,
            cluster = "canton")

cat("STATENT canton-sector panel (post-period trends):\n")
summary(m5)

# ==============================================================================
# 6. Save key objects for tables and diagnostics
# ==============================================================================

# Diagnostics for validate_v1.py
# n_treated counts canton-sector treated units in STATENT (26 cantons x 3 sectors)
diagnostics <- list(
  n_treated = n_distinct(statent$canton) * n_distinct(df$sector[df$treated]),
  n_pre = n_distinct(df$quarter[!df$post]),
  n_obs = nrow(df) + nrow(statent),
  n_sectors = n_distinct(df$sector),
  n_quarters = n_distinct(df$quarter),
  n_cantons_statent = n_distinct(statent$canton),
  treatment_date = "2009-04-01",
  reform = "Tatbeweis abolition"
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Save regression objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m_es = m_es, m4 = m4, m5 = m5),
        "../data/regression_results.rds")

# Extract key results for paper
coef_m1 <- coeftable(m1)
cat(sprintf("\n=== KEY RESULT ===\n"))
cat(sprintf("DiD coefficient (log FTE): %.4f (SE: %.4f, p: %.4f)\n",
            coef_m1[1, 1], coef_m1[1, 2], coef_m1[1, 4]))
cat(sprintf("Percentage effect: %.2f%%\n", (exp(coef_m1[1, 1]) - 1) * 100))

# Pre-treatment SD of outcome for SDE calculation
pre_sd_fte <- df |> filter(!post) |> pull(log_emp_fte) |> sd(na.rm = TRUE)
cat(sprintf("Pre-treatment SD(log FTE): %.4f\n", pre_sd_fte))
cat(sprintf("SDE: %.4f\n", coef_m1[1, 1] / pre_sd_fte))

cat("\n=== Analysis complete ===\n")
