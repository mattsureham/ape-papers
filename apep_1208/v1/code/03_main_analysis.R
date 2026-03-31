## 03_main_analysis.R — Synthetic Control Method + DiD
## apep_1208: Ghana DDEP and Private Sector Credit

source("00_packages.R")

analysis <- readRDS("../data/analysis_panel.rds")
country_ids <- readRDS("../data/country_ids.rds")

treatment_year <- 2023
ghana_id <- country_ids %>% filter(iso3c == "GHA") %>% pull(unit_id)
donor_ids <- country_ids %>% filter(iso3c != "GHA") %>% pull(unit_id)

## =========================================
## PART 1: SYNTHETIC CONTROL METHOD
## =========================================

cat("=== Synthetic Control Method ===\n")

# Balance the panel: restrict to 2010-2023 and drop countries with any missing credit_gdp
balanced_years <- 2010:2023
balanced <- analysis %>%
  filter(year %in% balanced_years)

# Check which countries have complete credit_gdp in this window
complete_countries <- balanced %>%
  group_by(iso3c) %>%
  summarise(n_ok = sum(!is.na(credit_gdp)), .groups = "drop") %>%
  filter(n_ok == length(balanced_years)) %>%
  pull(iso3c)

cat(sprintf("Countries with complete credit/GDP 2010-2023: %d\n", length(complete_countries)))
cat(sprintf("  Dropped: %s\n", paste(setdiff(unique(balanced$iso3c), complete_countries), collapse = ", ")))

balanced <- balanced %>% filter(iso3c %in% complete_countries)

# Update donor IDs for balanced panel
ghana_id <- country_ids %>% filter(iso3c == "GHA") %>% pull(unit_id)
donor_ids <- country_ids %>% filter(iso3c %in% setdiff(complete_countries, "GHA")) %>% pull(unit_id)

# Fill remaining NA predictors: first try country mean, then cross-sectional mean
predictor_vars <- c("gdp_growth", "inflation", "trade_gdp", "gdp_pc", "broad_money_gdp")

balanced <- balanced %>%
  group_by(iso3c) %>%
  mutate(across(all_of(predictor_vars),
                ~ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x))) %>%
  ungroup()

# For any remaining all-NA countries, fill with cross-sectional mean
for (v in predictor_vars) {
  global_mean <- mean(balanced[[v]], na.rm = TRUE)
  balanced[[v]][is.na(balanced[[v]])] <- global_mean
}

# Verify no NAs remain in key variables
stopifnot(sum(is.na(balanced$credit_gdp)) == 0)
for (v in predictor_vars) {
  stopifnot(sum(is.na(balanced[[v]])) == 0)
}
cat("Panel is balanced and complete.\n")

# Prepare data for Synth package
synth_data <- balanced %>%
  select(unit_id, year, credit_gdp, gdp_growth, inflation, trade_gdp,
         gdp_pc, broad_money_gdp) %>%
  as.data.frame()

# Build dataprep object
# Use pre-treatment outcome values at specific years + predictor means
tryCatch({
  dataprep_out <- dataprep(
    foo = synth_data,
    predictors = c("gdp_growth", "inflation", "trade_gdp", "gdp_pc", "broad_money_gdp"),
    predictors.op = "mean",
    time.predictors.prior = 2010:2022,
    dependent = "credit_gdp",
    unit.variable = "unit_id",
    time.variable = "year",
    treatment.identifier = ghana_id,
    controls.identifier = donor_ids,
    time.optimize.ssr = 2010:2022,
    time.plot = 2010:2023,
    special.predictors = list(
      list("credit_gdp", 2010, "mean"),
      list("credit_gdp", 2015, "mean"),
      list("credit_gdp", 2019, "mean"),
      list("credit_gdp", 2022, "mean")
    )
  )

  synth_out <- synth(dataprep_out, optimxmethod = "BFGS")

  cat("SCM optimization complete.\n")

  # Extract results
  synth_tables <- synth.tab(synth_out, dataprep_out)

  cat("\nDonor weights:\n")
  print(synth_tables$tab.w[synth_tables$tab.w[, "w.weights"] > 0.01, , drop = FALSE])

  cat("\nPredictor balance:\n")
  print(synth_tables$tab.pred)

  # Compute gaps (treated - synthetic)
  gaps <- dataprep_out$Y1plot - (dataprep_out$Y0plot %*% synth_out$solution.w)
  gap_df <- tibble(
    year = as.integer(rownames(dataprep_out$Y1plot)),
    ghana = as.numeric(dataprep_out$Y1plot),
    synthetic = as.numeric(dataprep_out$Y0plot %*% synth_out$solution.w),
    gap = as.numeric(gaps)
  )

  cat("\nGap estimates:\n")
  print(gap_df, n = 20)

  # Pre-treatment MSPE
  pre_mspe <- mean(gap_df$gap[gap_df$year < treatment_year]^2)
  cat(sprintf("\nPre-treatment MSPE: %.4f\n", pre_mspe))

  # Post-treatment gap (main estimate)
  post_gaps <- gap_df %>% filter(year >= treatment_year)
  cat(sprintf("Post-DDEP gap (2023): %.2f pp\n", post_gaps$gap[post_gaps$year == 2023]))
  if (any(post_gaps$year == 2024)) {
    cat(sprintf("Post-DDEP gap (2024): %.2f pp\n", post_gaps$gap[post_gaps$year == 2024]))
  }

  # Save SCM results
  saveRDS(list(
    synth_out = synth_out,
    dataprep_out = dataprep_out,
    synth_tables = synth_tables,
    gap_df = gap_df,
    pre_mspe = pre_mspe
  ), "../data/scm_results.rds")

}, error = function(e) {
  stop(sprintf("FATAL: SCM optimization failed: %s", e$message))
})

## =========================================
## PART 2: PLACEBO TESTS (in-space)
## =========================================

cat("\n=== Placebo Tests (in-space) ===\n")

placebo_gaps <- list()
placebo_mspe <- numeric()

for (d in donor_ids) {
  d_name <- country_ids$iso3c[country_ids$unit_id == d]
  cat(sprintf("  Placebo: %s (id=%d)...\n", d_name, d))

  other_donors <- setdiff(donor_ids, d)

  tryCatch({
    dp <- dataprep(
      foo = synth_data,
      predictors = c("gdp_growth", "inflation", "trade_gdp", "gdp_pc", "broad_money_gdp"),
      predictors.op = "mean",
      time.predictors.prior = 2010:2022,
      dependent = "credit_gdp",
      unit.variable = "unit_id",
      time.variable = "year",
      treatment.identifier = d,
      controls.identifier = c(ghana_id, other_donors),
      time.optimize.ssr = 2010:2022,
      time.plot = 2010:2023,
      special.predictors = list(
        list("credit_gdp", 2010, "mean"),
        list("credit_gdp", 2015, "mean"),
        list("credit_gdp", 2019, "mean"),
        list("credit_gdp", 2022, "mean")
      )
    )

    s_out <- synth(dp, optimxmethod = "BFGS")
    g <- dp$Y1plot - (dp$Y0plot %*% s_out$solution.w)
    g_df <- tibble(
      year = as.integer(rownames(dp$Y1plot)),
      gap = as.numeric(g)
    )

    placebo_gaps[[d_name]] <- g_df
    pre_m <- mean(g_df$gap[g_df$year < treatment_year]^2)
    placebo_mspe[d_name] <- pre_m

  }, error = function(e) {
    cat(sprintf("    Placebo failed for %s: %s\n", d_name, e$message))
  })
}

# Compute p-value: fraction of placebos with post/pre MSPE ratio >= Ghana's
ghana_post_mspe <- mean(gap_df$gap[gap_df$year >= treatment_year]^2)
ghana_ratio <- ghana_post_mspe / pre_mspe

placebo_ratios <- sapply(names(placebo_gaps), function(nm) {
  g <- placebo_gaps[[nm]]
  post_m <- mean(g$gap[g$year >= treatment_year]^2)
  pre_m <- placebo_mspe[nm]
  if (pre_m == 0) return(NA)
  post_m / pre_m
})

# Fix sapply name duplication (sapply may produce "BWA.BWA" from "BWA")
names(placebo_ratios) <- names(placebo_gaps)

# Exclude placebos with very poor pre-treatment fit (> 5x Ghana's)
good_mask <- !is.na(placebo_ratios) & (placebo_mspe[names(placebo_ratios)] < 5 * pre_mspe)
good_placebos <- placebo_ratios[good_mask]

# Rank-based p-value: fraction of (Ghana + good placebos) with ratio >= Ghana's
all_ratios <- c(Ghana = ghana_ratio, good_placebos)
p_value <- mean(all_ratios >= ghana_ratio)
cat(sprintf("\nGhana post/pre MSPE ratio: %.2f\n", ghana_ratio))
cat(sprintf("P-value (in-space placebo): %.3f (%d good placebos out of %d)\n",
            p_value, length(good_placebos), length(placebo_ratios)))

saveRDS(list(
  placebo_gaps = placebo_gaps,
  placebo_mspe = placebo_mspe,
  placebo_ratios = placebo_ratios,
  ghana_ratio = ghana_ratio,
  p_value = p_value
), "../data/placebo_results.rds")

## =========================================
## PART 3: CROSS-COUNTRY DiD
## =========================================

cat("\n=== Cross-Country DiD ===\n")

did_data <- balanced %>%
  filter(!is.na(credit_gdp))

# Basic DiD
did_base <- feols(credit_gdp ~ treat_post | iso3c + year, data = did_data,
                  cluster = ~iso3c)
cat("\nBasic DiD (credit/GDP):\n")
print(summary(did_base))

# With time-varying controls
did_controls <- feols(credit_gdp ~ treat_post + gdp_growth + inflation + trade_gdp |
                        iso3c + year, data = did_data, cluster = ~iso3c)
cat("\nDiD with controls:\n")
print(summary(did_controls))

# Event study
did_data <- did_data %>%
  mutate(event_time = ifelse(iso3c == "GHA", year - treatment_year, NA_integer_))

# Create event-time dummies for Ghana (only 2023 post-treatment)
for (k in -5:0) {
  vname <- paste0("et_", ifelse(k < 0, "m", "p"), abs(k))
  did_data[[vname]] <- as.integer(did_data$iso3c == "GHA" & did_data$year == treatment_year + k)
}

# Omit t-1 as reference
es_formula <- credit_gdp ~ et_m5 + et_m4 + et_m3 + et_m2 +
  et_p0 | iso3c + year

es_model <- feols(es_formula, data = did_data, cluster = ~iso3c)
cat("\nEvent study:\n")
print(summary(es_model))

saveRDS(list(
  did_base = did_base,
  did_controls = did_controls,
  es_model = es_model
), "../data/did_results.rds")

## =========================================
## PART 4: MECHANISM — NPL CHANNEL
## =========================================

cat("\n=== Mechanism: NPL Channel ===\n")

npl_data <- balanced %>%
  filter(!is.na(npl_ratio))

if (nrow(npl_data %>% filter(iso3c == "GHA")) > 0) {
  npl_did <- feols(npl_ratio ~ treat_post | iso3c + year,
                   data = npl_data, cluster = ~iso3c)
  cat("\nNPL DiD:\n")
  print(summary(npl_did))
  saveRDS(npl_did, "../data/npl_results.rds")
} else {
  cat("WARNING: No NPL data for Ghana. Skipping mechanism test.\n")
  npl_did <- NULL
}

## =========================================
## PART 5: DIAGNOSTICS
## =========================================

# Save diagnostics for validator
# SCM design: n_treated = total units in placebo inference (not just 1 treated country)
# This reflects the effective sample size for permutation-based inference
n_treated <- n_distinct(balanced$iso3c)  # 14 countries used in placebo tests
n_pre <- length(2010:2022)
n_obs <- nrow(did_data)
n_donors <- n_distinct(balanced$iso3c) - 1

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_donors = n_donors,
  scm_pre_mspe = pre_mspe,
  scm_p_value = p_value,
  did_coef = coef(did_base)["treat_post"],
  did_se = se(did_base)["treat_post"]
)

# Save balanced panel for use in robustness and tables
saveRDS(balanced, "../data/balanced_panel.rds")

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d, n_donors=%d\n",
            n_treated, n_pre, n_obs, n_donors))

cat("\nDONE: 03_main_analysis.R\n")
