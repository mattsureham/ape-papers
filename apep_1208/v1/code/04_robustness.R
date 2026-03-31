## 04_robustness.R — Robustness checks
## apep_1208: Ghana DDEP and Private Sector Credit

source("00_packages.R")

analysis <- readRDS("../data/balanced_panel.rds")
scm_results <- readRDS("../data/scm_results.rds")

treatment_year <- 2023

## =========================================
## 1. PLACEBO-IN-TIME TEST
## =========================================

cat("=== Placebo-in-Time Test (fake treatment at 2019) ===\n")

# If the gap appeared before 2023, it's not the DDEP
country_ids <- readRDS("../data/country_ids.rds")
ghana_id <- country_ids %>% filter(iso3c == "GHA") %>% pull(unit_id)
donor_ids <- country_ids %>% filter(iso3c %in% setdiff(unique(analysis$iso3c), "GHA")) %>% pull(unit_id)

# Restrict to pre-DDEP data only (2010-2022) with fake treatment at 2019
synth_data_pre <- analysis %>%
  filter(year <= 2022) %>%
  select(unit_id, year, credit_gdp, gdp_growth, inflation, trade_gdp,
         gdp_pc, broad_money_gdp) %>%
  as.data.frame()

tryCatch({
  dp_time <- dataprep(
    foo = synth_data_pre,
    predictors = c("gdp_growth", "inflation", "trade_gdp", "gdp_pc", "broad_money_gdp"),
    predictors.op = "mean",
    time.predictors.prior = 2010:2018,
    dependent = "credit_gdp",
    unit.variable = "unit_id",
    time.variable = "year",
    treatment.identifier = ghana_id,
    controls.identifier = donor_ids,
    time.optimize.ssr = 2010:2018,
    time.plot = 2010:2022,
    special.predictors = list(
      list("credit_gdp", 2010, "mean"),
      list("credit_gdp", 2014, "mean"),
      list("credit_gdp", 2018, "mean")
    )
  )

  s_time <- synth(dp_time, optimxmethod = "BFGS")
  gaps_time <- dp_time$Y1plot - (dp_time$Y0plot %*% s_time$solution.w)
  gap_time_df <- tibble(
    year = as.integer(rownames(dp_time$Y1plot)),
    gap = as.numeric(gaps_time)
  )

  cat("Placebo-in-time gaps (fake treatment 2019):\n")
  print(gap_time_df %>% filter(year >= 2017), n = 10)

  # Pre-fake-treatment MSPE
  pre_fake_mspe <- mean(gap_time_df$gap[gap_time_df$year < 2019]^2)
  post_fake_mspe <- mean(gap_time_df$gap[gap_time_df$year >= 2019 & gap_time_df$year <= 2022]^2)
  cat(sprintf("Placebo MSPE ratio (2019 fake): %.2f\n", post_fake_mspe / pre_fake_mspe))

  saveRDS(gap_time_df, "../data/placebo_time_results.rds")

}, error = function(e) {
  cat(sprintf("Placebo-in-time failed: %s\n", e$message))
})

## =========================================
## 2. LEAVE-ONE-OUT DONOR TEST
## =========================================

cat("\n=== Leave-One-Out Donor Test ===\n")

# Check if results are sensitive to any single donor
synth_tables <- scm_results$synth_tables
top_donors <- rownames(synth_tables$tab.w)[synth_tables$tab.w[, "w.weights"] > 0.05]

synth_data <- analysis %>%
  select(unit_id, year, credit_gdp, gdp_growth, inflation, trade_gdp,
         gdp_pc, broad_money_gdp) %>%
  as.data.frame()

loo_results <- list()

for (drop_name in top_donors) {
  drop_id <- country_ids$unit_id[country_ids$iso3c == drop_name | country_ids$country == drop_name]
  if (length(drop_id) == 0) {
    # Try matching by country name in tab.w
    drop_id <- country_ids$unit_id[country_ids$unit_id == as.integer(drop_name)]
  }
  if (length(drop_id) == 0) next

  remaining_donors <- setdiff(donor_ids, drop_id)
  cat(sprintf("  Dropping donor id=%s...\n", drop_name))

  tryCatch({
    dp_loo <- dataprep(
      foo = synth_data,
      predictors = c("gdp_growth", "inflation", "trade_gdp", "gdp_pc", "broad_money_gdp"),
      predictors.op = "mean",
      time.predictors.prior = 2010:2022,
      dependent = "credit_gdp",
      unit.variable = "unit_id",
      time.variable = "year",
      treatment.identifier = ghana_id,
      controls.identifier = remaining_donors,
      time.optimize.ssr = 2010:2022,
      time.plot = 2010:2023,
      special.predictors = list(
        list("credit_gdp", 2010, "mean"),
        list("credit_gdp", 2015, "mean"),
        list("credit_gdp", 2019, "mean"),
        list("credit_gdp", 2022, "mean")
      )
    )

    s_loo <- synth(dp_loo, optimxmethod = "BFGS")
    g_loo <- dp_loo$Y1plot - (dp_loo$Y0plot %*% s_loo$solution.w)
    gap_2023 <- g_loo[rownames(dp_loo$Y1plot) == "2023", ]

    loo_results[[drop_name]] <- list(
      gap_2023 = as.numeric(gap_2023),
      gaps = tibble(
        year = as.integer(rownames(dp_loo$Y1plot)),
        gap = as.numeric(g_loo)
      )
    )

    cat(sprintf("    Gap at 2023 (drop %s): %.2f pp\n", drop_name, gap_2023))

  }, error = function(e) {
    cat(sprintf("    LOO failed for %s: %s\n", drop_name, e$message))
  })
}

saveRDS(loo_results, "../data/loo_results.rds")

## =========================================
## 3. ALTERNATIVE PRE-TREATMENT WINDOW
## =========================================

cat("\n=== Alternative Pre-Treatment Window (2015-2022) ===\n")

tryCatch({
  dp_short <- dataprep(
    foo = synth_data,
    predictors = c("gdp_growth", "inflation", "trade_gdp", "gdp_pc", "broad_money_gdp"),
    predictors.op = "mean",
    time.predictors.prior = 2015:2022,
    dependent = "credit_gdp",
    unit.variable = "unit_id",
    time.variable = "year",
    treatment.identifier = ghana_id,
    controls.identifier = donor_ids,
    time.optimize.ssr = 2015:2022,
    time.plot = 2015:2023,
    special.predictors = list(
      list("credit_gdp", 2015, "mean"),
      list("credit_gdp", 2018, "mean"),
      list("credit_gdp", 2022, "mean")
    )
  )

  s_short <- synth(dp_short, optimxmethod = "BFGS")
  g_short <- dp_short$Y1plot - (dp_short$Y0plot %*% s_short$solution.w)
  gap_short_df <- tibble(
    year = as.integer(rownames(dp_short$Y1plot)),
    gap = as.numeric(g_short)
  )

  cat("Short window gaps:\n")
  print(gap_short_df, n = 15)

  saveRDS(gap_short_df, "../data/scm_short_window.rds")

}, error = function(e) {
  cat(sprintf("Short window SCM failed: %s\n", e$message))
})

## =========================================
## 4. WILD CLUSTER BOOTSTRAP (DiD)
## =========================================

cat("\n=== Wild Cluster Bootstrap for DiD ===\n")

did_data <- analysis %>%
  filter(!is.na(credit_gdp))

did_base <- feols(credit_gdp ~ treat_post | iso3c + year, data = did_data,
                  cluster = ~iso3c)

# Twoway clustering (country + year)
boot_did <- feols(credit_gdp ~ treat_post | iso3c + year, data = did_data,
                  vcov = ~iso3c + year)

cat("\nDiD with twoway clustering:\n")
print(summary(boot_did))

saveRDS(boot_did, "../data/did_twoway.rds")

cat("\nDONE: 04_robustness.R\n")
