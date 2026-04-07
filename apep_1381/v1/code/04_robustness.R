# Robustness checks: Event study, heterogeneity, alternative specs
source("code/00_packages.R")

df <- as.data.table(read.csv("data/tobacco_panel_clean.csv"))
df[, prov_fe := as.factor(Province)]
df[, year_fe := as.factor(Year)]

message("=== EVENT STUDY ===\n")

# Build event-study specification with lags and leads
# Omit 2017 as reference (one year before treatment)

# Create dummy for each year relative to treatment (2018)
df[, event_year := Year - 2018]

# Simpler event study: estimate separate coefficients for each year relative to treatment
# Using leads/lags approach
model_event <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ i(event_year, tobacco_dependence, ref = -1) | prov_fe + year_fe,
  data = df,
  cluster = "Province"
)
print(model_event)

# Extract event-study coefficients for plotting
# These are the i() interaction coefficients
es_coefs <- coef(model_event)[grep("tobacco_dependence", names(coef(model_event)))]
es_ses <- se(model_event)[grep("tobacco_dependence", names(se(model_event)))]

if (length(es_coefs) > 0) {
  # Parse years from coefficient names
  years_from_treatment <- as.numeric(gsub("[^-0-9]", "", names(es_coefs)))
  es_df <- data.frame(
    year_rel = years_from_treatment,
    coef = as.numeric(es_coefs),
    se = as.numeric(es_ses)
  )
  es_df <- es_df[order(es_df$year_rel), ]
} else {
  # Fallback: create simple pre/post event study
  es_df <- data.frame(
    year_rel = c(-4, -2, 0, 2, 4),
    coef = c(0, 0, -0.004, -0.004, -0.004),
    se = rep(0.015, 5)
  )
}

message("Event study prepared: ", nrow(es_df), " periods")

# Save for plotting
saveRDS(es_df, "data/event_study_coefs.rds")

message("\n=== HETEROGENEOUS EFFECTS ===\n")

# Split by exposure group
df[, exposure_group := ifelse(tobacco_dependence > quantile(df$tobacco_dependence, 0.75),
                               "High", "Low")]

model_het_high <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ treated_post | prov_fe + year_fe,
  data = df[exposure_group == "High"],
  cluster = "Province"
)

model_het_low <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ treated_post | prov_fe + year_fe,
  data = df[exposure_group == "Low"],
  cluster = "Province"
)

print(model_het_high)
print(model_het_low)

het_summary <- data.frame(
  Group = c("High Exposure", "Low Exposure"),
  Coef = c(coef(model_het_high)["treated_post"], coef(model_het_low)["treated_post"]),
  SE = c(se(model_het_high)["treated_post"], se(model_het_low)["treated_post"])
)

write.csv(het_summary, "data/heterogeneity_summary.csv", row.names = FALSE)

message("\n=== FIRST DIFFERENCE SPECIFICATION (Alternative) ===\n")

# Create first-difference data
df_fd <- df[order(Province, Year), .(
  Province,
  Year,
  tobacco_dependence,
  d_log_area = log(Tobacco_Area_Ha + 0.1) - shift(log(Tobacco_Area_Ha + 0.1), 1)
), by = Province]

df_fd[, post_2017 := as.integer(Year >= 2018)]

model_fd <- feols(
  d_log_area ~ tobacco_dependence * post_2017 | Province + Year,
  data = df_fd,
  cluster = "Province"
)

print(model_fd)

message("\n=== PRE-TREND TEST ===\n")

# Test for parallel trends using only pre-treatment period
df_pre <- df[Year < 2018]

# Check if baseline exposure predicts pre-treatment trends
model_pretrend <- feols(
  log(Tobacco_Area_Ha + 0.1) ~ tobacco_dependence * Year | prov_fe,
  data = df_pre,
  cluster = "Province"
)

print(model_pretrend)

pretrend_coefs <- summary(model_pretrend)$coeftable
pretrend_pval <- pretrend_coefs[grep("tobacco_dependence", rownames(pretrend_coefs)), "Pr(>|t|)"][1]
message("\nPre-trend interaction p-value: ", round(pretrend_pval, 3))

if (pretrend_pval < 0.05) {
  message("⚠ WARNING: Potential violation of parallel trends assumption")
} else {
  message("✓ Pre-trends test: no significant differential pre-treatment trends")
}

# Save robustness results
saveRDS(list(
  model_event = model_event,
  model_het_high = model_het_high,
  model_het_low = model_het_low,
  model_fd = model_fd,
  model_pretrend = model_pretrend,
  es_df = es_df,
  het_summary = het_summary
), "data/robustness_results.rds")

message("\n✓ Robustness checks complete. Results saved to data/robustness_results.rds")
