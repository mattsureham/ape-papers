## 03_main_analysis.R — Main DiD analysis
## apep_0958: Dutch Nitrogen Ruling and Populist Backlash

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
cross_section <- readRDS(file.path(data_dir, "cross_section_clean.rds"))

cat("=== Panel Summary ===\n")
cat(sprintf("  %d obs, %d munis, %d quarters\n",
            nrow(panel), n_distinct(panel$gm_code), n_distinct(panel$time_fe)))
cat(sprintf("  Avg permits/quarter: %.1f (sd=%.1f)\n",
            mean(panel$total_dwellings, na.rm=TRUE), sd(panel$total_dwellings, na.rm=TRUE)))
cat(sprintf("  Pre-treatment periods: %d quarters (2012Q1-2019Q2)\n",
            n_distinct(panel$time_fe[panel$post == 0])))
cat(sprintf("  Post-treatment periods: %d quarters (2019Q3+)\n",
            n_distinct(panel$time_fe[panel$post == 1])))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Create quartile groups based on exposure
panel <- panel %>%
  mutate(
    exposure_q = ntile(exposure, 4),
    exposure_group = case_when(
      exposure == 0 ~ "No Exposure",
      exposure_q <= 2 ~ "Low Exposure",
      TRUE ~ "High Exposure"
    )
  )

sumstats <- panel %>%
  filter(post == 0) %>%  # Pre-treatment only
  group_by(exposure_group) %>%
  summarise(
    n_munis = n_distinct(gm_code),
    mean_permits = mean(total_dwellings, na.rm = TRUE),
    sd_permits = sd(total_dwellings, na.rm = TRUE),
    mean_permits_pc = mean(permits_pc, na.rm = TRUE),
    mean_n2k_share = mean(n2k_share, na.rm = TRUE),
    mean_exposure = mean(exposure, na.rm = TRUE),
    mean_agri = mean(agri_share, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE) / 1000,
    .groups = "drop"
  )

print(sumstats)

## ============================================================
## Table 2: Main DiD Results — Building Permits
## ============================================================
cat("\n=== Table 2: Main DiD Results ===\n")

# Specification 1: N2K share × Post (simple)
m1 <- feols(log_permits ~ n2k_post | gm_code + time_fe, data = panel,
            cluster = ~gm_code)

# Specification 2: Composite exposure × Post
m2 <- feols(log_permits ~ exposure_post | gm_code + time_fe, data = panel,
            cluster = ~gm_code)

# Specification 3: Per-capita permits
m3 <- feols(permits_pc ~ exposure_post | gm_code + time_fe, data = panel,
            cluster = ~gm_code)

# Specification 4: With COVID controls (drop 2020Q1-2020Q2)
panel_nocovid <- panel %>%
  filter(!(year == 2020 & quarter %in% 1:2))
m4 <- feols(log_permits ~ exposure_post | gm_code + time_fe, data = panel_nocovid,
            cluster = ~gm_code)

# Specification 5: High exposure binary × Post
panel <- panel %>%
  mutate(high_post = high_exposure * post)
m5 <- feols(log_permits ~ high_post | gm_code + time_fe, data = panel,
            cluster = ~gm_code)

cat("\n--- Main Results ---\n")
etable(m1, m2, m3, m4, m5,
       headers = c("N2K×Post", "Exposure×Post", "Permits/cap", "No COVID", "Binary"),
       se.below = TRUE)

# Save coefficients for paper
main_coefs <- list(
  m1_beta = coef(m1)["n2k_post"],
  m1_se = se(m1)["n2k_post"],
  m2_beta = coef(m2)["exposure_post"],
  m2_se = se(m2)["exposure_post"],
  m3_beta = coef(m3)["exposure_post"],
  m3_se = se(m3)["exposure_post"],
  m5_beta = coef(m5)["high_post"],
  m5_se = se(m5)["high_post"]
)
saveRDS(main_coefs, file.path(data_dir, "main_coefs.rds"))

## ============================================================
## Table 3: Event Study — Building Permits
## ============================================================
cat("\n=== Event Study ===\n")

# Create event time dummies interacted with exposure
panel <- panel %>%
  mutate(
    # Relative quarter (0 = 2019Q2, ruling quarter)
    rel_q = (year - 2019) * 4 + (quarter - 2),
    # Bin endpoints
    rel_q_bin = case_when(
      rel_q <= -12 ~ -12L,
      rel_q >= 12 ~ 12L,
      TRUE ~ rel_q
    )
  )

# Event study with binned endpoints
es_model <- feols(log_permits ~ i(rel_q_bin, exposure, ref = -1) | gm_code + time_fe,
                  data = panel, cluster = ~gm_code)

cat("Event study estimated.\n")

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs %>%
  filter(grepl("rel_q_bin", term)) %>%
  mutate(
    rel_q = as.integer(gsub("rel_q_bin::(-?\\d+):exposure", "\\1", term)),
    beta = Estimate,
    se = `Std. Error`,
    ci_lo = beta - 1.96 * se,
    ci_hi = beta + 1.96 * se
  )

saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# Pre-trend test: F-test on pre-treatment coefficients
pre_coefs <- es_coefs %>% filter(rel_q < -1)
cat(sprintf("Pre-trend coefficients: %d (all should be ~0)\n", nrow(pre_coefs)))
cat(sprintf("Max pre-trend |beta|: %.4f (se=%.4f)\n",
            max(abs(pre_coefs$beta)), pre_coefs$se[which.max(abs(pre_coefs$beta))]))

## ============================================================
## Table 4: Political Outcome — BBB Vote Share
## ============================================================
cat("\n=== Table 4: Cross-Section — BBB Vote Share ===\n")

# Specification 1: N2K share alone
p1 <- feols(bbb_share ~ n2k_share, data = cross_section,
            vcov = "hetero")

# Specification 2: Composite exposure
p2 <- feols(bbb_share ~ exposure, data = cross_section,
            vcov = "hetero")

# Specification 3: With controls
p3 <- feols(bbb_share ~ exposure + agri_share + bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")

# Specification 4: With pre-existing populist support (FvD 2023 as proxy)
p4 <- feols(bbb_share ~ exposure + agri_share + bev_dichtheid + log(population) + fvd_share,
            data = cross_section, vcov = "hetero")

# Specification 5: N2K share + agriculture share separately
p5 <- feols(bbb_share ~ n2k_share + agri_share + n2k_share:agri_share +
              bev_dichtheid + log(population),
            data = cross_section, vcov = "hetero")

cat("\n--- BBB Cross-Section Results ---\n")
etable(p1, p2, p3, p4, p5,
       headers = c("N2K", "Exposure", "+Controls", "+FvD", "Interact"),
       se.below = TRUE)

# Save for paper
political_coefs <- list(
  p2_beta = coef(p2)["exposure"],
  p2_se = se(p2)["exposure"],
  p3_beta = coef(p3)["exposure"],
  p3_se = se(p3)["exposure"]
)
saveRDS(political_coefs, file.path(data_dir, "political_coefs.rds"))

## ============================================================
## Diagnostics for validator
## ============================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(panel$exposure > 0 & panel$post == 1) / n_distinct(panel$time_fe[panel$post == 1]),
  n_pre = n_distinct(panel$time_fe[panel$post == 0]),
  n_obs = nrow(panel),
  n_munis = n_distinct(panel$gm_code),
  n_quarters = n_distinct(panel$time_fe),
  n_cross_section = nrow(cross_section),
  outcome_sd = sd(panel$log_permits[panel$post == 0], na.rm = TRUE),
  main_beta = unname(coef(m2)["exposure_post"]),
  main_se = unname(se(m2)["exposure_post"]),
  bbb_r2 = summary(p3)$r2
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("  n_treated=%.0f, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
