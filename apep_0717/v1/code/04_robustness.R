## 04_robustness.R — Robustness checks for apep_0717
## Benefit cap reduction → temporary accommodation

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

## =========================================================================
## 1. Dose-response (fixed version: use interaction, not absorbed post)
## =========================================================================

cat("=== 1. Dose-Response by Tercile ===\n")

panel[, tercile := cut(cap_intensity,
                       breaks = quantile(cap_intensity, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                       labels = c("Low", "Medium", "High"),
                       include.lowest = TRUE)]

## Triple-diff: tercile × year interactions
panel[, high := as.integer(tercile == "High")]
panel[, med := as.integer(tercile == "Medium")]

m_dose <- feols(ta_rate ~ high:i(year, ref = 2016) + med:i(year, ref = 2016) | la_code + year,
                data = panel, cluster = ~la_code)
cat("Tercile event study:\n")
print(summary(m_dose))

## Simple pre-post comparison by tercile
for (t in c("Low", "Medium", "High")) {
  sub <- panel[tercile == t]
  pre_mean <- mean(sub[post == 0, ta_rate], na.rm = TRUE)
  post_mean <- mean(sub[post == 1, ta_rate], na.rm = TRUE)
  change <- post_mean - pre_mean
  cat(sprintf("  %s tercile: pre = %.3f, post = %.3f, change = %.3f\n",
              t, pre_mean, post_mean, change))
}

## =========================================================================
## 2. Placebo timing tests
## =========================================================================

cat("\n=== 2. Placebo Timing Tests ===\n")

## Placebo treatment at 2015 (using only 2013-2016 pre-treatment data)
pre_only <- panel[year <= 2016]
pre_only[, placebo_post := as.integer(year >= 2015)]

m_placebo2015 <- feols(ta_rate ~ cap_intensity:placebo_post | la_code + year,
                       data = pre_only, cluster = ~la_code)
cat("Placebo at 2015:\n")
cat(sprintf("  coef = %.4f, se = %.4f, p = %.4f\n",
            coef(m_placebo2015)[1], se(m_placebo2015)[1], pvalue(m_placebo2015)[1]))

## Placebo at 2014
pre_only[, placebo_post14 := as.integer(year >= 2014)]
m_placebo2014 <- feols(ta_rate ~ cap_intensity:placebo_post14 | la_code + year,
                       data = pre_only, cluster = ~la_code)
cat("Placebo at 2014:\n")
cat(sprintf("  coef = %.4f, se = %.4f, p = %.4f\n",
            coef(m_placebo2014)[1], se(m_placebo2014)[1], pvalue(m_placebo2014)[1]))

## =========================================================================
## 3. Alternative treatment intensity measures
## =========================================================================

cat("\n=== 3. Alternative Treatment Measures ===\n")

## Binary treatment: above median cap intensity
panel[, high_cap := as.integer(cap_intensity > median(cap_intensity, na.rm = TRUE))]

m_binary <- feols(ta_rate ~ high_cap:i(year, ref = 2016) | la_code + year,
                  data = panel, cluster = ~la_code)
cat("Binary treatment (above median) event study:\n")
print(summary(m_binary))

## Log transformation of outcome
panel[, log_ta := log(ta_rate + 0.01)]  ## small constant to handle zeros
m_log <- feols(log_ta ~ cap_intensity:post | la_code + year,
               data = panel, cluster = ~la_code)
cat("\nLog TA outcome:\n")
cat(sprintf("  coef = %.4f, se = %.4f, p = %.4f\n",
            coef(m_log)[1], se(m_log)[1], pvalue(m_log)[1]))

## =========================================================================
## 4. First-difference specification
## =========================================================================

cat("\n=== 4. First Difference ===\n")

## Create first differences
panel <- panel[order(la_code, year)]
panel[, delta_ta := ta_rate - shift(ta_rate, 1), by = la_code]
panel[, delta_claimant := claimant_rate - shift(claimant_rate, 1), by = la_code]

m_fd <- feols(delta_ta ~ cap_intensity:post | year,
              data = panel[!is.na(delta_ta)], cluster = ~la_code)
cat("First-difference:\n")
cat(sprintf("  coef = %.4f, se = %.4f, p = %.4f\n",
            coef(m_fd)[1], se(m_fd)[1], pvalue(m_fd)[1]))

## =========================================================================
## 5. Exclude outliers
## =========================================================================

cat("\n=== 5. Excluding Outlier LAs ===\n")

## Drop top 5% by cap intensity (most extreme treatment)
q95 <- quantile(panel$cap_intensity, 0.95, na.rm = TRUE)
m_no_outlier <- feols(ta_rate ~ cap_intensity:post | la_code + year,
                      data = panel[cap_intensity < q95], cluster = ~la_code)
cat(sprintf("Excluding top 5%% (cap > %.2f):\n", q95))
cat(sprintf("  coef = %.4f, se = %.4f, p = %.4f\n",
            coef(m_no_outlier)[1], se(m_no_outlier)[1], pvalue(m_no_outlier)[1]))

## Drop London
m_no_london <- feols(ta_rate ~ cap_intensity:post | la_code + year,
                     data = panel[london == 0], cluster = ~la_code)
cat("Excluding London:\n")
cat(sprintf("  coef = %.4f, se = %.4f, p = %.4f\n",
            coef(m_no_london)[1], se(m_no_london)[1], pvalue(m_no_london)[1]))

## =========================================================================
## 6. Summary statistics for Table 1
## =========================================================================

cat("\n=== SUMMARY STATISTICS ===\n")

pre_data <- panel[post == 0 & !is.na(ta_rate)]

stats <- data.table(
  Variable = c("TA households per 1,000 pop",
               "Capped HH per 1,000 pop",
               "Claimant rate per 1,000",
               "Population (thousands)",
               "Number of LAs",
               "Years"),
  Mean = c(mean(pre_data$ta_rate, na.rm = TRUE),
           mean(pre_data$cap_intensity, na.rm = TRUE),
           mean(pre_data$claimant_rate, na.rm = TRUE),
           mean(pre_data$population, na.rm = TRUE) / 1000,
           uniqueN(pre_data$la_code),
           uniqueN(pre_data$year)),
  SD = c(sd(pre_data$ta_rate, na.rm = TRUE),
         sd(pre_data$cap_intensity, na.rm = TRUE),
         sd(pre_data$claimant_rate, na.rm = TRUE),
         sd(pre_data$population, na.rm = TRUE) / 1000,
         NA, NA),
  Min = c(min(pre_data$ta_rate, na.rm = TRUE),
          min(pre_data$cap_intensity, na.rm = TRUE),
          min(pre_data$claimant_rate, na.rm = TRUE),
          min(pre_data$population, na.rm = TRUE) / 1000,
          NA, NA),
  Max = c(max(pre_data$ta_rate, na.rm = TRUE),
          max(pre_data$cap_intensity, na.rm = TRUE),
          max(pre_data$claimant_rate, na.rm = TRUE),
          max(pre_data$population, na.rm = TRUE) / 1000,
          NA, NA)
)

print(stats, digits = 3)

## Save robustness models
saveRDS(list(m_dose = m_dose, m_placebo2015 = m_placebo2015,
             m_placebo2014 = m_placebo2014, m_binary = m_binary,
             m_log = m_log, m_fd = m_fd, m_no_outlier = m_no_outlier,
             m_no_london = m_no_london),
        file.path(data_dir, "robustness_models.rds"))
cat("\nSaved robustness_models.rds\n")
