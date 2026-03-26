## 03_main_analysis.R — Main regression analysis
## apep_0978: From Rice Paddies to Solar Panels

source("00_packages.R")

df <- read_csv("../data/clean_panel.csv", show_col_types = FALSE)
cat(sprintf("Loaded: %d rows, %d prefectures, years %d-%d\n",
            nrow(df), n_distinct(df$prefecture), min(df$year), max(df$year)))

## -------------------------------------------------------------------------
## 1. Main specification: Continuous DiD
## log(cultivated_land) = α_i + δ_t + β(FIT_rate × UplandShare) + ε
## -------------------------------------------------------------------------

cat("\n=== MAIN SPECIFICATION ===\n")
cat("log(cultivated_land) ~ FIT_rate × pre_upland_share | prefecture + year\n\n")

## Main model
m1 <- feols(log_cultivated ~ treatment_intensity | area_code + year,
            data = df, cluster = ~area_code)

## With farm household control
m2 <- feols(log_cultivated ~ treatment_intensity + log(farm_households_total) | area_code + year,
            data = df %>% filter(farm_households_total > 0), cluster = ~area_code)

## Separate paddy and field outcomes
m3 <- feols(log_paddy ~ treatment_intensity | area_code + year,
            data = df, cluster = ~area_code)

m4 <- feols(log_field ~ treatment_intensity | area_code + year,
            data = df, cluster = ~area_code)

## Print results
cat("Model 1: Main (no controls)\n")
summary(m1)
cat("\nModel 2: With farm household control\n")
summary(m2)
cat("\nModel 3: Paddy outcome\n")
summary(m3)
cat("\nModel 4: Field/upland outcome\n")
summary(m4)

## -------------------------------------------------------------------------
## 2. Event study: Year dummies × UplandShare
## -------------------------------------------------------------------------

cat("\n=== EVENT STUDY ===\n")

## Create year dummies interacted with upland share
## Omit 2011 (year before FIT introduction)
df <- df %>%
  mutate(rel_year_fac = factor(rel_year))

## Event study
m_es <- feols(log_cultivated ~ i(rel_year, pre_upland_share, ref = -1) |
                area_code + year,
              data = df, cluster = ~area_code)

cat("Event study coefficients:\n")
summary(m_es)

## Extract event study coefficients for table
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$term <- rownames(es_coefs)
cat("\nEvent study coefficient table:\n")
print(es_coefs)

## -------------------------------------------------------------------------
## 3. Binary treatment specification (high vs low upland share × post)
## -------------------------------------------------------------------------

cat("\n=== BINARY TREATMENT (High vs Low Upland × Post) ===\n")

m_binary <- feols(log_cultivated ~ high_upland:post_fit | area_code + year,
                  data = df, cluster = ~area_code)
summary(m_binary)

## -------------------------------------------------------------------------
## 4. Mechanism: converted farmland
## -------------------------------------------------------------------------

cat("\n=== MECHANISM: CONVERTED FARMLAND ===\n")

df_conv <- df %>% filter(!is.na(converted_farmland), converted_farmland > 0)
cat(sprintf("Converted farmland data: %d obs\n", nrow(df_conv)))

if (nrow(df_conv) > 50) {
  m_conv <- feols(log(converted_farmland) ~ treatment_intensity | area_code + year,
                  data = df_conv, cluster = ~area_code)
  cat("Converted farmland model:\n")
  summary(m_conv)
} else {
  cat("Insufficient data for converted farmland analysis.\n")
  m_conv <- NULL
}

## -------------------------------------------------------------------------
## 5. Save results
## -------------------------------------------------------------------------

## Store key results for tables
results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  m4 = m4,
  m_es = m_es,
  m_binary = m_binary,
  m_conv = m_conv
)

saveRDS(results, "../data/main_results.rds")
cat("\nSaved main results to data/main_results.rds\n")

## -------------------------------------------------------------------------
## 6. Write diagnostics.json for validator
## -------------------------------------------------------------------------

diag <- list(
  n_treated = sum(df$high_upland == 1 & !duplicated(df$area_code)),
  n_pre = length(unique(df$year[df$year < 2012])),
  n_obs = nrow(df)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

## -------------------------------------------------------------------------
## 7. Key numbers for the paper
## -------------------------------------------------------------------------

cat("\n=== KEY NUMBERS FOR PAPER ===\n")
beta_main <- coef(m1)["treatment_intensity"]
se_main <- se(m1)["treatment_intensity"]
cat(sprintf("Main coefficient (treatment_intensity): %.6f (SE=%.6f)\n", beta_main, se_main))

## Interpretation: 1 unit increase in FIT_rate × upland_share
## At mean FIT rate (24.5 for 2012-2022) and mean upland share (0.39),
## treatment_intensity mean is about 9.5
## A 10 yen/kWh increase in FIT rate for a prefecture with median upland share
## would change log cultivated land by beta * 10 * median_share

med_share <- median(df$pre_upland_share[!duplicated(df$area_code)])
cat(sprintf("Median upland share: %.3f\n", med_share))
cat(sprintf("Effect of 10 yen/kWh FIT increase for median-share pref: %.4f log points\n",
            beta_main * 10 * med_share))
cat(sprintf("  = %.2f%% change\n", (exp(beta_main * 10 * med_share) - 1) * 100))

## SD of outcome for SDE
sd_y <- sd(df$log_cultivated)
sd_x <- sd(df$treatment_intensity)
cat(sprintf("SD(log_cultivated): %.4f\n", sd_y))
cat(sprintf("SD(treatment_intensity): %.4f\n", sd_x))
cat(sprintf("SDE (continuous): beta * SD(X) / SD(Y) = %.4f\n",
            beta_main * sd_x / sd_y))
