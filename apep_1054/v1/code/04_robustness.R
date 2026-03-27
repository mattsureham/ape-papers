## 04_robustness.R — Robustness checks and placebos
## apep_1054: Mexico DST Abolition and Crime

source("00_packages.R")

cat("=== Loading Data ===\n")
df <- fread("../data/analysis_panel.csv")
df[, date := as.Date(date)]

results <- readRDS("../data/main_results.rds")

## ---------------------------------------------------------------
## 1. Wild Cluster Bootstrap (small number of clusters concern)
## ---------------------------------------------------------------
cat("\n=== Wild Cluster Bootstrap ===\n")
cat("Border municipalities are few (~33 clusters). Testing inference.\n\n")

## Use fwildclusterboot for Webb 6-point distribution
## Main specification: street crime
m_street <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                   data = df, cluster = ~muni_id)

tryCatch({
  boot_street <- boottest(m_street, param = "treat_post",
                           clustid = ~muni_id,
                           B = 9999, type = "webb")
  cat("WCB p-value (street crime):", boot_street$p_val, "\n")
  cat("WCB 95% CI:", boot_street$conf_int, "\n")

  ## Total crime
  m_total <- feols(ihs_total ~ treat_post | muni_id + state_ym,
                    data = df, cluster = ~muni_id)
  boot_total <- boottest(m_total, param = "treat_post",
                          clustid = ~muni_id,
                          B = 9999, type = "webb")
  cat("WCB p-value (total crime):", boot_total$p_val, "\n")

  ## Save bootstrap results
  boot_results <- list(
    street_pval = boot_street$p_val,
    street_ci = boot_street$conf_int,
    total_pval = boot_total$p_val,
    total_ci = boot_total$conf_int
  )
}, error = function(e) {
  cat("Bootstrap error:", conditionMessage(e), "\n")
  cat("Falling back to cluster-robust SEs only.\n")
  boot_results <- list(street_pval = NA, total_pval = NA)
})

## ---------------------------------------------------------------
## 2. Leave-One-State-Out
## ---------------------------------------------------------------
cat("\n=== Leave-One-State-Out ===\n")

states <- unique(df$cve_ent)
state_names <- c("5" = "Coahuila", "8" = "Chihuahua", "19" = "Nuevo León",
                 "28" = "Tamaulipas")

loso_results <- data.table()
for (s in states) {
  df_loo <- df[cve_ent != s]
  m_loo <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                  data = df_loo, cluster = ~muni_id)
  loso_results <- rbind(loso_results, data.table(
    dropped_state = state_names[as.character(s)],
    estimate = coef(m_loo)["treat_post"],
    se = se(m_loo)["treat_post"],
    p = pvalue(m_loo)["treat_post"],
    n_muni = uniqueN(df_loo$muni_id)
  ))
}

cat("\nLeave-one-state-out results (street crime):\n")
print(loso_results)

## ---------------------------------------------------------------
## 3. Alternative Outcome: Log(Y + 1) and Levels
## ---------------------------------------------------------------
cat("\n=== Alternative Outcome Transformations ===\n")

## Log(Y+1)
m_log <- feols(log_street ~ treat_post | muni_id + state_ym,
                data = df, cluster = ~muni_id)

## Levels (Poisson-like with count data)
m_levels <- feols(street_crime ~ treat_post | muni_id + state_ym,
                   data = df, cluster = ~muni_id)

cat("IHS(street):  β =", round(coef(results$m1_street), 4), "\n")
cat("Log(street+1): β =", round(coef(m_log), 4), "\n")
cat("Levels:        β =", round(coef(m_levels), 4), "\n")

## ---------------------------------------------------------------
## 4. Seasonal Dose Response
## ---------------------------------------------------------------
cat("\n=== Seasonal Dose Response ===\n")
cat("Effect should peak in months with maximal sunset difference (June-July)\n\n")

## Interact treatment effect with month-of-year in post period
df[, month_f := factor(month)]

## Monthly treatment effects (post-reform only)
df_post <- df[post == 1]
m_seasonal <- feols(ihs_street ~ i(month_f, treated, ref = "12") |
                     muni_id + state_ym,
                    data = df_post, cluster = ~muni_id)

seasonal_coefs <- as.data.table(coeftable(m_seasonal), keep.rownames = TRUE)
setnames(seasonal_coefs, c("term", "estimate", "se", "t", "p"))
cat("Monthly treatment effects (post-reform, ref = December):\n")
print(seasonal_coefs)

## ---------------------------------------------------------------
## 5. Urban vs Rural Heterogeneity
## ---------------------------------------------------------------
cat("\n=== Urban vs Rural Heterogeneity ===\n")

## Classify municipalities by pre-treatment crime level as proxy for urbanization
## (High crime = more urban, more opportunity for street crime)
pre_mean <- df[post == 0, .(pre_crime = mean(total_crime)), by = muni_id]
median_crime <- median(pre_mean$pre_crime)
pre_mean[, urban := as.integer(pre_crime >= median_crime)]

df <- merge(df, pre_mean[, .(muni_id, urban)], by = "muni_id", all.x = TRUE)

m_urban <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                  data = df[urban == 1], cluster = ~muni_id)
m_rural <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                  data = df[urban == 0], cluster = ~muni_id)

cat("Urban (high-crime) municipalities: β =", round(coef(m_urban), 4),
    " SE =", round(se(m_urban), 4), "\n")
cat("Rural (low-crime) municipalities:  β =", round(coef(m_rural), 4),
    " SE =", round(se(m_rural), 4), "\n")

## ---------------------------------------------------------------
## 6. Excluding Large Border Cities (Juárez, Reynosa, Matamoros, Nuevo Laredo)
## ---------------------------------------------------------------
cat("\n=== Excluding Large Border Cities ===\n")

## These cities are outliers in crime and population
## Juárez (8037), Reynosa (28032), Matamoros (28022), Nuevo Laredo (28027)
large_border <- c(8037, 28032, 28022, 28027)
df_nolarge <- df[!(muni_id %in% large_border)]

m_nolarge <- feols(ihs_street ~ treat_post | muni_id + state_ym,
                    data = df_nolarge, cluster = ~muni_id)

cat("Excluding 5 large border cities: β =", round(coef(m_nolarge), 4),
    " SE =", round(se(m_nolarge), 4),
    " p =", round(pvalue(m_nolarge), 4), "\n")

## ---------------------------------------------------------------
## 7. Pre-treatment parallel trends test
## ---------------------------------------------------------------
cat("\n=== Pre-Treatment Parallel Trends ===\n")

## Linear pre-trend test: interact treated with a linear time trend in pre-period
df_pre <- df[post == 0]
df_pre[, time_trend := as.numeric(date - min(date)) / 365]

m_pretrend <- feols(ihs_street ~ treated:time_trend | muni_id + state_ym,
                     data = df_pre, cluster = ~muni_id)

cat("Pre-treatment differential trend: β =", round(coef(m_pretrend), 4),
    " SE =", round(se(m_pretrend), 4),
    " p =", round(pvalue(m_pretrend), 4), "\n")

## ---------------------------------------------------------------
## Save all robustness results
## ---------------------------------------------------------------
robust_results <- list(
  loso = loso_results,
  m_log = m_log,
  m_levels = m_levels,
  m_urban = m_urban,
  m_rural = m_rural,
  m_nolarge = m_nolarge,
  m_pretrend = m_pretrend,
  m_seasonal = m_seasonal
)

saveRDS(robust_results, "../data/robustness_results.rds")

## Also save the updated df with urban variable
fwrite(df, "../data/analysis_panel.csv")

cat("\n=== Robustness Checks Complete ===\n")
