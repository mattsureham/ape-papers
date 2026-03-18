## 03_main_analysis.R — Main DiD analysis for apep_0717
## Benefit cap reduction → temporary accommodation

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Panel Summary ===\n")
cat("Obs:", nrow(panel), " LAs:", uniqueN(panel$la_code),
    " Years:", paste(sort(unique(panel$year)), collapse = ","), "\n\n")

## =========================================================================
## 1. Main specification: Continuous-treatment DiD
## =========================================================================

cat("=== MAIN RESULTS ===\n\n")

## Specification 1: Baseline (LA + year FE, clustered at LA)
m1 <- feols(ta_rate ~ cap_intensity:post | la_code + year,
            data = panel, cluster = ~la_code)
cat("Model 1: Baseline (LA + year FE)\n")
print(summary(m1))

## Specification 2: Add claimant rate control
m2 <- feols(ta_rate ~ cap_intensity:post + claimant_rate | la_code + year,
            data = panel, cluster = ~la_code)
cat("\nModel 2: + Claimant rate control\n")
print(summary(m2))

## Specification 3: Exclude London (separate cap level)
m3 <- feols(ta_rate ~ cap_intensity:post | la_code + year,
            data = panel[london == 0], cluster = ~la_code)
cat("\nModel 3: Exclude London\n")
print(summary(m3))

## Specification 4: Region × year FE (absorb regional trends)
panel[, region_clean := gsub(" ", "_", region)]
m4 <- feols(ta_rate ~ cap_intensity:post | la_code + region_clean^year,
            data = panel, cluster = ~la_code)
cat("\nModel 4: Region × year FE\n")
print(summary(m4))

## =========================================================================
## 2. Event study specification
## =========================================================================

cat("\n=== EVENT STUDY ===\n")

## Create year dummies interacted with cap intensity
## Reference year: 2016 (last pre-treatment year)
panel[, year_f := relevel(factor(year), ref = "2016")]

m_event <- feols(ta_rate ~ i(year_f, cap_intensity, ref = "2016") | la_code + year,
                 data = panel, cluster = ~la_code)
cat("\nEvent study:\n")
print(summary(m_event))

## =========================================================================
## 3. Dose-response: Tercile-based heterogeneity
## =========================================================================

cat("\n=== DOSE-RESPONSE ===\n")

panel[, tercile := cut(cap_intensity,
                       breaks = quantile(cap_intensity, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                       labels = c("Low", "Medium", "High"),
                       include.lowest = TRUE)]

## Simple pre-post means by tercile
for (t in c("Low", "Medium", "High")) {
  sub <- panel[tercile == t]
  pre_m <- mean(sub[post == 0, ta_rate], na.rm = TRUE)
  post_m <- mean(sub[post == 1, ta_rate], na.rm = TRUE)
  cat(sprintf("  Tercile %s: pre = %.3f, post = %.3f, change = %.3f\n",
              t, pre_m, post_m, post_m - pre_m))
}

## Tercile event study (dose-response)
panel[, high := as.integer(tercile == "High")]
m_dose <- feols(ta_rate ~ high:i(year, ref = 2016) | la_code + year,
                data = panel, cluster = ~la_code)
cat("\nDose-response (High vs Low+Med) event study:\n")
print(summary(m_dose))

## =========================================================================
## 4. Compute key statistics for the paper
## =========================================================================

cat("\n=== KEY STATISTICS ===\n")

## Pre-treatment means
pre <- panel[post == 0]
cat("Pre-treatment mean TA rate (all):", round(mean(pre$ta_rate, na.rm = TRUE), 3), "\n")
cat("Pre-treatment SD TA rate (all):", round(sd(pre$ta_rate, na.rm = TRUE), 3), "\n")
cat("Pre-treatment mean TA rate (high tercile):", round(mean(pre[tercile == "High", ta_rate], na.rm = TRUE), 3), "\n")
cat("Pre-treatment mean TA rate (low tercile):", round(mean(pre[tercile == "Low", ta_rate], na.rm = TRUE), 3), "\n")

## Post-treatment means
post_data <- panel[post == 1]
cat("Post-treatment mean TA rate (all):", round(mean(post_data$ta_rate, na.rm = TRUE), 3), "\n")

## Change in TA
cat("\nMean TA change by tercile:\n")
change <- panel[, .(pre_mean = mean(ta_rate[post == 0], na.rm = TRUE),
                     post_mean = mean(ta_rate[post == 1], na.rm = TRUE)),
                by = tercile]
change[, diff := post_mean - pre_mean]
print(change)

## Main coefficient interpretation
beta <- coef(m1)["cap_intensity:post"]
se_beta <- se(m1)["cap_intensity:post"]
mean_cap <- mean(panel[post == 1, cap_intensity], na.rm = TRUE)
sd_y <- sd(pre$ta_rate, na.rm = TRUE)
cat(sprintf("\nMain coefficient: %.4f (se = %.4f)\n", beta, se_beta))
cat(sprintf("Mean cap intensity: %.3f per 1000\n", mean_cap))
cat(sprintf("Implied effect at mean intensity: %.3f TA per 1000\n", beta * mean_cap))
cat(sprintf("SD of TA rate: %.3f\n", sd_y))
cat(sprintf("SDE at mean intensity: %.4f\n", beta * mean_cap / sd_y))

## =========================================================================
## 5. Save diagnostics.json
## =========================================================================

n_treated <- uniqueN(panel[cap_intensity > median(panel$cap_intensity, na.rm = TRUE) & post == 1, la_code])
n_pre <- length(unique(panel$year[panel$post == 0]))

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_las = uniqueN(panel$la_code),
  n_years = uniqueN(panel$year),
  pre_mean_ta = round(mean(pre$ta_rate, na.rm = TRUE), 4),
  pre_sd_ta = round(sd(pre$ta_rate, na.rm = TRUE), 4),
  main_coef = round(beta, 6),
  main_se = round(se_beta, 6),
  main_p = round(pvalue(m1)["cap_intensity:post"], 6)
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nSaved diagnostics.json\n")

## Save model objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m_event = m_event, m_dose = m_dose),
        file.path(data_dir, "models.rds"))
cat("Saved models.rds\n")
