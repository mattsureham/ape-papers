## 02_clean_data.R — Clean and construct analysis variables
## apep_0978: From Rice Paddies to Solar Panels

source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat(sprintf("Loaded panel: %d rows\n", nrow(df)))

## -------------------------------------------------------------------------
## Restrict to analysis window: 2005-2022
## Need 2005-2011 for pre-trends, 2012-2022 for post-treatment
## -------------------------------------------------------------------------

df <- df %>%
  filter(year >= 2005, year <= 2022)

cat(sprintf("Analysis window (2005-2022): %d rows\n", nrow(df)))
cat(sprintf("Prefectures: %d\n", n_distinct(df$prefecture)))
cat(sprintf("Years: %d to %d\n", min(df$year), max(df$year)))

## -------------------------------------------------------------------------
## Construct outcome variables
## -------------------------------------------------------------------------

df <- df %>%
  mutate(
    ## Log cultivated land (main outcome)
    log_cultivated = log(cultivated_land_total),
    ## Log paddy area
    log_paddy = log(paddy_area),
    ## Log field/upland area
    log_field = log(field_area),
    ## Upland share (time-varying)
    upland_share_tv = field_area / cultivated_land_total,
    ## Post-FIT indicator
    post_fit = as.integer(year >= 2012),
    ## Year relative to FIT introduction (2012 = 0)
    rel_year = year - 2012
  )

## -------------------------------------------------------------------------
## Construct treatment variables
## -------------------------------------------------------------------------

## Pre-FIT upland share is already in the data (computed from 2009-2011 avg)
## Treatment intensity = FIT rate × pre-FIT upland share
## Already computed as treatment_intensity

## Quartiles of pre-FIT upland share for heterogeneity
quartiles <- quantile(df$pre_upland_share[!duplicated(df$area_code)],
                      probs = c(0.25, 0.5, 0.75), na.rm = TRUE)

df <- df %>%
  mutate(
    upland_quartile = case_when(
      pre_upland_share <= quartiles[1] ~ "Q1 (low)",
      pre_upland_share <= quartiles[2] ~ "Q2",
      pre_upland_share <= quartiles[3] ~ "Q3",
      TRUE ~ "Q4 (high)"
    ),
    ## Binary: high vs low upland share (above/below median)
    high_upland = as.integer(pre_upland_share > quartiles[2])
  )

cat(sprintf("\nQuartile cutoffs: Q1=%.3f, Q2=%.3f, Q3=%.3f\n",
            quartiles[1], quartiles[2], quartiles[3]))

## Prefectures per quartile
cat("\nPrefectures per upland quartile:\n")
df %>%
  filter(!duplicated(area_code)) %>%
  count(upland_quartile) %>%
  print()

## -------------------------------------------------------------------------
## Controls (where available)
## -------------------------------------------------------------------------

## Check if population is available
if ("population" %in% names(df) && !all(is.na(df$population))) {
  df <- df %>%
    mutate(
      log_pop = log(as.numeric(population)),
      farm_hh_density = (farm_households_total / as.numeric(population)) * 1000
    )
} else {
  cat("Note: Population data not available in panel.\n")
  df$log_pop <- NA_real_
  df$farm_hh_density <- NA_real_
}

## -------------------------------------------------------------------------
## Summary statistics
## -------------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")
summ_vars <- c("cultivated_land_total", "paddy_area", "field_area",
                "pre_upland_share", "fit_rate", "treatment_intensity",
                "farm_households_total")

for (v in summ_vars) {
  vals <- df[[v]]
  if (!is.null(vals) && sum(!is.na(vals)) > 0) {
    cat(sprintf("  %-25s  mean=%.1f  sd=%.1f  min=%.1f  max=%.1f  N=%d\n",
                v, mean(vals, na.rm = TRUE), sd(vals, na.rm = TRUE),
                min(vals, na.rm = TRUE), max(vals, na.rm = TRUE),
                sum(!is.na(vals))))
  }
}

## -------------------------------------------------------------------------
## Save cleaned panel
## -------------------------------------------------------------------------
write_csv(df, "../data/clean_panel.csv")
cat(sprintf("\nSaved clean panel: %d rows to data/clean_panel.csv\n", nrow(df)))

## Save summary stats for the paper
summ_df <- df %>%
  filter(year <= 2011) %>%  # Pre-treatment summary
  summarize(
    across(c(cultivated_land_total, paddy_area, field_area,
             upland_share_tv, farm_households_total),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

write_csv(summ_df, "../data/summary_stats_pre.csv")
cat("Saved pre-treatment summary stats.\n")
