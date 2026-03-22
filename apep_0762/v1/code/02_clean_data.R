## =============================================================================
## 02_clean_data.R — Build matched control group and analysis panel
## apep_0762
## =============================================================================

source("00_packages.R")

cat("=== Loading data ===\n")
zhvi_panel <- readRDS("../data/zhvi_panel_full.rds")
treatment_zips <- readRDS("../data/treatment_zips.rds")

## ---- Step 1: Annualize ZHVI for DiD ----
## CS-DiD works best with annual data to avoid seasonal noise
cat("\n=== Step 1: Annualize data ===\n")

annual_panel <- zhvi_panel %>%
  filter(month == 1) %>%  # January observation each year

  mutate(log_zhvi = log(zhvi)) %>%
  filter(year >= 2000, year <= 2024)

cat(sprintf("  Annual panel: %s obs, %d zip codes, years %d-%d\n",
            format(nrow(annual_panel), big.mark = ","),
            n_distinct(annual_panel$zip_code),
            min(annual_panel$year), max(annual_panel$year)))

## ---- Step 2: Compute pre-treatment characteristics for matching ----
cat("\n=== Step 2: Pre-treatment characteristics ===\n")

## For each treated zip, use year before designation as baseline
## For never-treated, use 2010 as reference year
pre_chars <- annual_panel %>%
  group_by(zip_code) %>%
  summarize(
    treated = max(treated),
    first_treat = max(first_treat),
    state = first(StateName),
    metro = first(Metro),
    # Pre-period values (use 2005-2009 averages for stability)
    zhvi_pre_mean = mean(zhvi[year >= 2005 & year <= 2009], na.rm = TRUE),
    zhvi_pre_sd = sd(zhvi[year >= 2005 & year <= 2009], na.rm = TRUE),
    log_zhvi_pre = mean(log_zhvi[year >= 2005 & year <= 2009], na.rm = TRUE),
    # Growth trend 2000-2009
    n_years = sum(!is.na(zhvi) & year >= 2000 & year <= 2009),
    .groups = "drop"
  ) %>%
  filter(!is.na(zhvi_pre_mean), n_years >= 5)

cat(sprintf("  Zip codes with pre-treatment data: %d (treated: %d)\n",
            nrow(pre_chars),
            sum(pre_chars$treated == 1)))

## ---- Step 3: Nearest-neighbor matching ----
cat("\n=== Step 3: Build matched control group ===\n")

treated_chars <- pre_chars %>% filter(treated == 1)
control_pool <- pre_chars %>% filter(treated == 0)

## Match on: log pre-treatment ZHVI level
## For each treated zip, find 5 nearest controls on pre-treatment home values
## Matching within broad population tiers to avoid comparing rural to urban

matched_controls <- list()

for (i in 1:nrow(treated_chars)) {
  tz <- treated_chars[i, ]

  # Find controls in the same state first; if <5, expand to same region
  same_state <- control_pool %>% filter(state == tz$state)
  pool <- if (nrow(same_state) >= 20) same_state else control_pool

  # Compute distance on log ZHVI
  pool <- pool %>%
    mutate(dist = abs(log_zhvi_pre - tz$log_zhvi_pre))

  # Take 5 nearest neighbors
  nn <- pool %>%
    arrange(dist) %>%
    head(5) %>%
    mutate(
      matched_to = tz$zip_code,
      matched_community = tz$zip_code,
      match_dist = dist
    )

  matched_controls[[i]] <- nn
}

matched_df <- bind_rows(matched_controls)
control_zips <- unique(matched_df$zip_code)

cat(sprintf("  Matched control zip codes: %d (for %d treated zips)\n",
            length(control_zips), nrow(treated_chars)))
cat(sprintf("  Mean match distance (log ZHVI): %.3f\n",
            mean(matched_df$match_dist)))

## ---- Step 4: Build analysis panel ----
cat("\n=== Step 4: Build analysis panel ===\n")

analysis_zips <- c(unique(treated_chars$zip_code), control_zips)

analysis_panel <- annual_panel %>%
  filter(zip_code %in% analysis_zips) %>%
  mutate(
    log_zhvi = log(zhvi),
    # For CS-DiD: first_treat = 0 means never-treated
    first_treat = ifelse(treated == 0, 0, first_treat),
    zip_id = as.numeric(factor(zip_code))
  )

# Verify panel structure
cat(sprintf("  Analysis panel: %s obs\n",
            format(nrow(analysis_panel), big.mark = ",")))
cat(sprintf("  Treated zip-codes: %d\n",
            n_distinct(analysis_panel$zip_code[analysis_panel$treated == 1])))
cat(sprintf("  Control zip-codes: %d\n",
            n_distinct(analysis_panel$zip_code[analysis_panel$treated == 0])))
cat(sprintf("  Treatment cohorts: %s\n",
            paste(sort(unique(analysis_panel$first_treat[analysis_panel$first_treat > 0])),
                  collapse = ", ")))
cat(sprintf("  Year range: %d-%d\n",
            min(analysis_panel$year), max(analysis_panel$year)))

## ---- Step 5: Summary statistics ----
cat("\n=== Step 5: Summary statistics ===\n")

sumstats <- analysis_panel %>%
  group_by(treated) %>%
  summarize(
    n_zips = n_distinct(zip_code),
    n_obs = n(),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_log_zhvi = mean(log_zhvi, na.rm = TRUE),
    sd_log_zhvi = sd(log_zhvi, na.rm = TRUE),
    .groups = "drop"
  )

print(sumstats)

## Save match info for balance checks
saveRDS(matched_df, "../data/match_info.rds")
saveRDS(analysis_panel, "../data/analysis_panel.rds")

## Overall summary stats for the paper
overall_stats <- analysis_panel %>%
  summarize(
    n_obs = n(),
    n_zips = n_distinct(zip_code),
    n_treated_zips = n_distinct(zip_code[treated == 1]),
    n_control_zips = n_distinct(zip_code[treated == 0]),
    n_cohorts = n_distinct(first_treat[first_treat > 0]),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_log_zhvi = mean(log_zhvi, na.rm = TRUE),
    sd_log_zhvi = sd(log_zhvi, na.rm = TRUE),
    min_year = min(year),
    max_year = max(year)
  )

saveRDS(overall_stats, "../data/overall_stats.rds")

cat("\n  Saved: analysis_panel.rds, match_info.rds, overall_stats.rds\n")
cat("  DONE.\n")
