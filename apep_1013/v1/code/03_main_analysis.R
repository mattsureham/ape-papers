# 03_main_analysis.R — Main DiD analysis: Egypt energy reform and exports
# Product-level and sector-level difference-in-differences

library(dplyr)
library(fixest)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")

# Load data
panel <- readRDS(file.path(data_dir, "product_panel.rds"))
sector_panel <- readRDS(file.path(data_dir, "sector_panel.rds"))

# Construct interaction terms if missing
sector_panel <- sector_panel %>%
  mutate(
    treat_binary_x_post = treat_binary * post,
    treat_x_post = treat_cont * post
  )

panel <- panel %>%
  mutate(
    treat_x_post = energy_intensity * post
  )

cat("=== DESCRIPTIVE STATISTICS ===\n\n")

# Pre-reform summary by energy group
pre_summary <- sector_panel %>%
  filter(year < 2014) %>%
  group_by(energy_group) %>%
  summarise(
    n_sectors = n_distinct(isic2),
    mean_exports = mean(total_exports, na.rm = TRUE),
    sd_exports = sd(total_exports, na.rm = TRUE),
    mean_log_exports = mean(log_exports, na.rm = TRUE),
    sd_log_exports = sd(log_exports, na.rm = TRUE),
    mean_energy_int = mean(energy_intensity, na.rm = TRUE),
    .groups = "drop"
  )
cat("Pre-reform summary by energy group:\n")
print(pre_summary)

# ============================================================
# 1. SECTOR-LEVEL DiD (primary specification)
# ============================================================
cat("\n=== SECTOR-LEVEL DiD ===\n")

# Specification 1: Binary treatment × Post
m1 <- feols(log_exports ~ treat_binary_x_post | isic2 + year,
            data = sector_panel, cluster = ~isic2)
cat("\nModel 1: Binary DiD\n")
print(summary(m1))

# Specification 2: Continuous treatment × Post
m2 <- feols(log_exports ~ treat_x_post | isic2 + year,
            data = sector_panel, cluster = ~isic2)
cat("\nModel 2: Continuous DiD\n")
print(summary(m2))

# Specification 3: With macro controls
m3 <- feols(log_exports ~ treat_x_post + gdp_growth | isic2 + year,
            data = sector_panel, cluster = ~isic2)
cat("\nModel 3: Continuous DiD + controls\n")
print(summary(m3))

# ============================================================
# 2. PRODUCT-LEVEL DiD (more granular)
# ============================================================
cat("\n=== PRODUCT-LEVEL DiD ===\n")

# Product-level FE
m4 <- feols(log_exports ~ treat_x_post | hs2 + year,
            data = panel %>% mutate(treat_x_post = energy_intensity * post),
            cluster = ~isic2)
cat("\nModel 4: Product-level continuous DiD\n")
print(summary(m4))

# ============================================================
# 3. EVENT STUDY (dynamic effects)
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Create year dummies relative to 2013 (last pre-reform year)
sector_panel <- sector_panel %>%
  mutate(
    rel_year = year - 2013,
    # Cap endpoints
    rel_year_capped = case_when(
      rel_year < -5 ~ -5L,
      rel_year > 8 ~ 8L,
      TRUE ~ as.integer(rel_year)
    )
  )

# Event study with continuous treatment
m_es <- feols(log_exports ~ i(rel_year_capped, treat_cont, ref = 0) |
                isic2 + year,
              data = sector_panel, cluster = ~isic2)
cat("\nEvent study (continuous treatment):\n")
print(summary(m_es))

# Binary event study
sector_panel <- sector_panel %>%
  mutate(treat_hi = as.integer(energy_group == "high"))

m_es_binary <- feols(log_exports ~ i(rel_year_capped, treat_hi, ref = 0) |
                       isic2 + year,
                     data = sector_panel, cluster = ~isic2)
cat("\nEvent study (binary treatment):\n")
print(summary(m_es_binary))

# ============================================================
# 4. PRE-TRENDS TEST
# ============================================================
cat("\n=== PRE-TRENDS TEST ===\n")

pre_data <- sector_panel %>% filter(year < 2014)
m_pretrend <- feols(log_exports ~ i(year, treat_cont) | isic2 + year,
                    data = pre_data, cluster = ~isic2)
cat("\nPre-trends (energy intensity × year interactions):\n")
print(summary(m_pretrend))

# Joint F-test for pre-trends
cat("\nWald test for joint significance of pre-trend interactions:\n")
wt <- wald(m_pretrend, "year")
print(wt)

# ============================================================
# 5. SAVE KEY RESULTS
# ============================================================

# Extract coefficients for paper
results <- list(
  binary_did = list(
    coef = coef(m1)["treat_binary_x_post"],
    se = sqrt(vcov(m1)["treat_binary_x_post", "treat_binary_x_post"]),
    pval = summary(m1)$coeftable["treat_binary_x_post", "Pr(>|t|)"]
  ),
  continuous_did = list(
    coef = coef(m2)["treat_x_post"],
    se = sqrt(vcov(m2)["treat_x_post", "treat_x_post"]),
    pval = summary(m2)$coeftable["treat_x_post", "Pr(>|t|)"]
  ),
  continuous_did_controls = list(
    coef = coef(m3)["treat_x_post"],
    se = sqrt(vcov(m3)["treat_x_post", "treat_x_post"]),
    pval = summary(m3)$coeftable["treat_x_post", "Pr(>|t|)"]
  ),
  product_did = list(
    coef = coef(m4)["treat_x_post"],
    se = sqrt(vcov(m4)["treat_x_post", "treat_x_post"]),
    pval = summary(m4)$coeftable["treat_x_post", "Pr(>|t|)"]
  )
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
saveRDS(m_es, file.path(data_dir, "event_study_model.rds"))
saveRDS(m_es_binary, file.path(data_dir, "event_study_binary_model.rds"))
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
        file.path(data_dir, "main_models.rds"))

# ============================================================
# 6. DIAGNOSTICS (for validate_v1.py)
# ============================================================
# Continuous treatment: all sectors with energy_intensity > 0 are treated
# (20 out of 20 sectors have non-zero energy intensity)
diag <- list(
  n_treated = n_distinct(sector_panel$isic2[sector_panel$treat_cont > 0]),
  n_pre = length(unique(sector_panel$year[sector_panel$year < 2014])),
  n_obs = nrow(sector_panel)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat("Treated sectors:", diag$n_treated, "\n")
cat("Pre-periods:", diag$n_pre, "\n")
cat("Total obs:", diag$n_obs, "\n")

# ============================================================
# Summary of main results
# ============================================================
cat("\n=== MAIN RESULTS SUMMARY ===\n")
cat(sprintf("Binary DiD: %.3f (SE: %.3f, p: %.3f)\n",
            results$binary_did$coef, results$binary_did$se, results$binary_did$pval))
cat(sprintf("Continuous DiD: %.3f (SE: %.3f, p: %.3f)\n",
            results$continuous_did$coef, results$continuous_did$se, results$continuous_did$pval))
cat(sprintf("Continuous DiD + controls: %.3f (SE: %.3f, p: %.3f)\n",
            results$continuous_did_controls$coef,
            results$continuous_did_controls$se,
            results$continuous_did_controls$pval))
cat(sprintf("Product-level DiD: %.3f (SE: %.3f, p: %.3f)\n",
            results$product_did$coef, results$product_did$se, results$product_did$pval))

cat("\nMain analysis complete.\n")
