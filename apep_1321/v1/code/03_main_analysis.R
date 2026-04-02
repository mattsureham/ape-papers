# 03_main_analysis.R — Main DiD analysis
source("00_packages.R")

data_dir <- "../data"
panel <- read.csv(file.path(data_dir, "analysis_panel.csv"))

cat("=== Main Analysis: Dose-Response DiD ===\n")
cat(sprintf("Panel: %d obs, %d districts, %d years\n",
            nrow(panel), n_distinct(panel$gid), n_distinct(panel$year)))

# ============================================================================
# 1. Primary specification: Continuous treatment intensity
# ============================================================================
cat("\n=== Specification 1: Continuous treatment DiD ===\n")

# Y_{dt} = alpha_d + gamma_t + beta * (Intensity_d * Post_t) + eps_{dt}
# Clustering at region level (treatment is assigned at regional level)

m1 <- feols(log_ntl ~ treat_post | gid + year,
            data = panel, cluster = ~region)
cat("Model 1: Log NTL ~ Intensity x Post (post = 2020+)\n")
summary(m1)

# Including 2019 as post
m1b <- feols(log_ntl ~ treat_post_incl | gid + year,
             data = panel, cluster = ~region)
cat("\nModel 1b: Including 2019 as post-treatment\n")
summary(m1b)

# ============================================================================
# 2. Binary treatment specification
# ============================================================================
cat("\n=== Specification 2: Binary treatment DiD ===\n")

m2 <- feols(log_ntl ~ high_treat_post | gid + year,
            data = panel, cluster = ~region)
cat("Model 2: Log NTL ~ High-treatment x Post\n")
summary(m2)

# ============================================================================
# 3. Event study
# ============================================================================
cat("\n=== Specification 3: Event study ===\n")

# Create event time relative to 2019 (treatment year)
panel$event_time <- panel$year - 2019

# Use 2018 as reference year (event_time = -1)
m3 <- feols(log_ntl ~ i(event_time, intensity_regional, ref = -1) | gid + year,
            data = panel, cluster = ~region)
cat("Event study with continuous treatment intensity:\n")
summary(m3)

# Binary event study
m3b <- feols(log_ntl ~ i(event_time, high_treatment, ref = -1) | gid + year,
             data = panel, cluster = ~region)
cat("\nEvent study with binary treatment:\n")
summary(m3b)

# ============================================================================
# 4. Level specification (not log)
# ============================================================================
cat("\n=== Specification 4: Level NTL ===\n")

m4 <- feols(ntl_mean ~ treat_post | gid + year,
            data = panel, cluster = ~region)
cat("Model 4: NTL level ~ Intensity x Post\n")
summary(m4)

# ============================================================================
# 5. Store results for tables
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  m1_continuous_post2020 = m1,
  m1b_continuous_incl2019 = m1b,
  m2_binary = m2,
  m3_eventstudy = m3,
  m3b_eventstudy_binary = m3b,
  m4_level = m4
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================================
# 6. Write diagnostics.json for validator
# ============================================================================
n_treated <- n_distinct(panel$gid[panel$high_treatment == 1])
n_pre <- sum(unique(panel$year) < 2019)
n_obs <- nrow(panel)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    n_districts = n_distinct(panel$gid),
    n_years = n_distinct(panel$year),
    n_regions = n_distinct(panel$region),
    treatment_years = sort(unique(panel$year[panel$post == 1])),
    pre_years = sort(unique(panel$year[panel$post == 0]))
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

cat("Results and diagnostics saved.\n")

# Print key coefficients for paper
cat("\n=== KEY RESULTS ===\n")
cat(sprintf("Continuous DiD (post 2020+): beta = %.4f, SE = %.4f, p = %.4f\n",
            coef(m1), se(m1), pvalue(m1)))
cat(sprintf("Binary DiD: beta = %.4f, SE = %.4f, p = %.4f\n",
            coef(m2), se(m2), pvalue(m2)))
cat(sprintf("SD(log_ntl) pre-treatment: %.4f\n",
            sd(panel$log_ntl[panel$year < 2019], na.rm = TRUE)))
