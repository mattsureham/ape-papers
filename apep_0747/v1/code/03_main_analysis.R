## 03_main_analysis.R — Triple-difference and CS-DiD estimation
source("00_packages.R")

panel <- readRDS("../data/panel.rds")
panel$state_fips_f <- as.factor(panel$state_fips)

# ===================================================================
# 1. Summary statistics
# ===================================================================
cat("=== Summary Statistics ===\n")

pre <- panel %>%
  filter(year <= 2012) %>%
  group_by(rtf_state, high_cafo) %>%
  summarize(
    n_counties = n_distinct(county_fips),
    mean_hisp_share = mean(hisp_share, na.rm = TRUE),
    mean_poverty = mean(poverty_rate, na.rm = TRUE),
    mean_income = mean(med_income, na.rm = TRUE),
    mean_pop = mean(total_pop, na.rm = TRUE),
    mean_white_share = mean(white_share, na.rm = TRUE),
    mean_black_share = mean(black_share, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPre-treatment means by group:\n")
print(pre)

# ===================================================================
# 2. Triple-Difference: fixest
# ===================================================================
cat("\n=== Triple-Difference Regressions ===\n")

# Model 1: Hispanic share
m1 <- feols(
  hisp_share ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n--- M1: Hispanic Share (DDD) ---\n")
summary(m1)

# Model 2: Poverty rate
m2 <- feols(
  poverty_rate ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n--- M2: Poverty Rate (DDD) ---\n")
summary(m2)

# Model 3: Log median income
m3 <- feols(
  log_income ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n--- M3: Log Median Income (DDD) ---\n")
summary(m3)

# Model 4: White share
m4 <- feols(
  white_share ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("\n--- M4: White Share (DDD) ---\n")
summary(m4)

# ===================================================================
# 3. Continuous intensity (log hogs x post_rtf)
# ===================================================================
cat("\n=== Continuous Treatment Intensity ===\n")

m5 <- feols(
  hisp_share ~ post_rtf:log_hogs |
    county_fips + state_fips_f^year,
  data = panel,
  cluster = ~state_fips
)
cat("\n--- M5: Hispanic Share (Continuous) ---\n")
summary(m5)

m6 <- feols(
  white_share ~ post_rtf:log_hogs |
    county_fips + state_fips_f^year,
  data = panel,
  cluster = ~state_fips
)
cat("\n--- M6: White Share (Continuous) ---\n")
summary(m6)

# ===================================================================
# 4. Event study (pre-trend test)
# ===================================================================
cat("\n=== Event Study ===\n")

# Create event time for RTF-state counties
panel_rtf <- panel %>%
  filter(rtf_state == 1) %>%
  mutate(
    rel_time = year - rtf_year,
    rel_time_bin = case_when(
      rel_time <= -5L ~ -5L,
      rel_time >= 6L ~ 6L,
      TRUE ~ rel_time
    )
  )

m_es <- feols(
  hisp_share ~ i(rel_time_bin, high_cafo, ref = -1) |
    county_fips + year,
  data = panel_rtf,
  cluster = ~state_fips
)
cat("\n--- Event Study: Hispanic Share ---\n")
summary(m_es)

m_es_w <- feols(
  white_share ~ i(rel_time_bin, high_cafo, ref = -1) |
    county_fips + year,
  data = panel_rtf,
  cluster = ~state_fips
)
cat("\n--- Event Study: White Share ---\n")
summary(m_es_w)

# ===================================================================
# 5. CS-DiD (high-CAFO counties only)
# ===================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

cs_data <- panel %>%
  filter(high_cafo == 1) %>%
  mutate(
    id = as.integer(as.factor(county_fips)),
    g = ifelse(rtf_state == 1, rtf_year, 0L)
  ) %>%
  filter(!is.na(hisp_share))

cat(sprintf("CS sample: %d obs, %d counties, cohorts: %s\n",
            nrow(cs_data), n_distinct(cs_data$id),
            paste(sort(unique(cs_data$g[cs_data$g > 0])), collapse = ", ")))

cs_out <- NULL
tryCatch({
  cs_out <- att_gt(
    yname = "hisp_share",
    tname = "year",
    idname = "id",
    gname = "g",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    est_method = "reg",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )
  cat("\nCS ATT(g,t) summary:\n")
  print(summary(cs_out))

  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS Overall ATT:\n")
  print(summary(cs_agg))

  cs_es <- aggte(cs_out, type = "dynamic")
  cat("\nCS Event Study:\n")
  print(summary(cs_es))

  saveRDS(cs_out, "../data/cs_results.rds")
  saveRDS(cs_agg, "../data/cs_agg.rds")
  saveRDS(cs_es, "../data/cs_es.rds")
}, error = function(e) {
  cat(sprintf("CS-DiD failed: %s\n", e$message))
})

# ===================================================================
# 6. Diagnostics and summary
# ===================================================================
n_treated <- n_distinct(panel$county_fips[panel$rtf_state == 1 & panel$high_cafo == 1])
diag <- list(
  n_treated = n_treated,
  n_pre = 5L,
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

saveRDS(list(m1=m1, m2=m2, m3=m3, m4=m4, m5=m5, m6=m6, m_es=m_es, m_es_w=m_es_w),
        "../data/models.rds")

cat("\n=== Key Results ===\n")
coefs <- data.frame(
  outcome = c("Hispanic Share", "Poverty Rate", "Log Income", "White Share"),
  coef = c(coef(m1)["post_rtf:high_cafo"],
           coef(m2)["post_rtf:high_cafo"],
           coef(m3)["post_rtf:high_cafo"],
           coef(m4)["post_rtf:high_cafo"]),
  se = c(se(m1)["post_rtf:high_cafo"],
         se(m2)["post_rtf:high_cafo"],
         se(m3)["post_rtf:high_cafo"],
         se(m4)["post_rtf:high_cafo"])
)
coefs$t_stat <- coefs$coef / coefs$se
coefs$sd_y <- c(sd(panel$hisp_share, na.rm=TRUE),
                sd(panel$poverty_rate, na.rm=TRUE),
                sd(panel$log_income, na.rm=TRUE),
                sd(panel$white_share, na.rm=TRUE))
print(coefs, digits = 4)
saveRDS(coefs, "../data/key_coefs.rds")
