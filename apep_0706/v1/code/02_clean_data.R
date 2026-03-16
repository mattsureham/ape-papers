## 02_clean_data.R — Construct analysis dataset
## APEP Paper apep_0706: FPM Fiscal Windfalls and Homicide Rates
## Revised: uses annual threshold assignment (not time-averaged)

source("00_packages.R")

cat("=== Constructing analysis dataset ===\n")

# ─────────────────────────────────────────────────────────────────────
# 1. Load raw data
# ─────────────────────────────────────────────────────────────────────
pop_df <- readRDS("../data/population_raw.rds")
homicide_df <- readRDS("../data/homicides_raw.rds")

cat(sprintf("Population: %d obs, Homicides: %d obs\n", nrow(pop_df), nrow(homicide_df)))

# ─────────────────────────────────────────────────────────────────────
# 2. FPM thresholds
# ─────────────────────────────────────────────────────────────────────
fpm_thresholds <- c(
  10188.5, 13584.5, 16980.5, 23772.5, 30563.5, 37355.5,
  44147.5, 50939.5, 61127.5, 71315.5, 81503.5, 91691.5,
  101879.5, 115463.5, 129047.5, 142631.5, 156215.5
)

fpm_coefficients <- c(
  0.6, 0.8, 1.0, 1.2, 1.4, 1.6,
  1.8, 2.0, 2.2, 2.4, 2.6, 2.8,
  3.0, 3.2, 3.4, 3.6, 3.8, 4.0
)

# ─────────────────────────────────────────────────────────────────────
# 3. Annual threshold assignment (key fix per reviewer feedback)
# ─────────────────────────────────────────────────────────────────────
cat("Computing ANNUAL FPM brackets (year-specific assignment)...\n")

# For each municipality-year: find nearest threshold, compute running var
assign_fpm <- function(pop) {
  dists <- abs(pop - fpm_thresholds)
  nearest_idx <- which.min(dists)
  nearest <- fpm_thresholds[nearest_idx]
  above <- as.integer(pop > nearest)
  coeff <- fpm_coefficients[nearest_idx + above]

  list(
    nearest_threshold = nearest,
    threshold_idx = nearest_idx,
    running_var = pop - nearest,
    above_threshold = above,
    fpm_coeff = coeff
  )
}

# Apply to each row using annual population
pop_df$nearest_threshold <- NA_real_
pop_df$threshold_idx <- NA_integer_
pop_df$running_var <- NA_real_
pop_df$above_threshold <- NA_integer_
pop_df$fpm_coeff <- NA_real_

for (i in seq_len(nrow(pop_df))) {
  if (!is.na(pop_df$population[i]) && pop_df$population[i] > 0) {
    res <- assign_fpm(pop_df$population[i])
    pop_df$nearest_threshold[i] <- res$nearest_threshold
    pop_df$threshold_idx[i] <- res$threshold_idx
    pop_df$running_var[i] <- res$running_var
    pop_df$above_threshold[i] <- res$above_threshold
    pop_df$fpm_coeff[i] <- res$fpm_coeff
  }
}

cat(sprintf("Assigned FPM brackets: %d mun-years\n", sum(!is.na(pop_df$running_var))))

# ─────────────────────────────────────────────────────────────────────
# 4. Merge population and homicide data (annual panel)
# ─────────────────────────────────────────────────────────────────────
cat("Merging population and homicide data...\n")

panel <- pop_df %>%
  left_join(homicide_df %>% select(mun_code, year, homicides),
            by = c("mun_code", "year")) %>%
  mutate(
    homicides = ifelse(is.na(homicides), 0, homicides),
    homicide_rate = (homicides / population) * 100000,
    log_homicide_rate = log(homicide_rate + 1),
    state_code = substr(mun_code, 1, 2),
    region = case_when(
      state_code %in% c("11","12","13","14","15","16","17") ~ "North",
      state_code %in% c("21","22","23","24","25","26","27","28","29") ~ "Northeast",
      state_code %in% c("31","32","33","35") ~ "Southeast",
      state_code %in% c("41","42","43") ~ "South",
      state_code %in% c("50","51","52","53") ~ "Center-West",
      TRUE ~ "Unknown"
    )
  ) %>%
  filter(!is.na(running_var), !is.na(homicide_rate))

cat(sprintf("Panel dataset: %d mun-years, %d municipalities\n",
            nrow(panel), n_distinct(panel$mun_code)))
cat(sprintf("Mean homicide rate: %.1f per 100K\n", mean(panel$homicide_rate)))
cat(sprintf("SD homicide rate: %.1f\n", sd(panel$homicide_rate)))

# ─────────────────────────────────────────────────────────────────────
# 5. Youth homicide data (mechanism test)
# ─────────────────────────────────────────────────────────────────────
if (file.exists("../data/youth_homicides_raw.rds")) {
  youth_df <- readRDS("../data/youth_homicides_raw.rds")
  panel <- panel %>%
    left_join(youth_df, by = c("mun_code", "year")) %>%
    mutate(
      youth_homicides = ifelse(is.na(youth_homicides), 0, youth_homicides),
      youth_homicide_rate = (youth_homicides / population) * 100000
    )
  cat(sprintf("Youth homicide data merged: %d non-zero\n",
              sum(panel$youth_homicides > 0)))
}

# ─────────────────────────────────────────────────────────────────────
# 6. Also create cross-sectional version (for some robustness)
# ─────────────────────────────────────────────────────────────────────
rdd_data <- panel %>%
  group_by(mun_code, mun_code6, mun_name, state_code, region) %>%
  summarise(
    mean_homicide_rate = mean(homicide_rate, na.rm = TRUE),
    mean_homicides = mean(homicides, na.rm = TRUE),
    mean_population = mean(population, na.rm = TRUE),
    total_homicides = sum(homicides, na.rm = TRUE),
    mean_youth_hom_rate = if ("youth_homicide_rate" %in% names(panel))
      mean(youth_homicide_rate, na.rm = TRUE) else NA_real_,
    n_years = n(),
    .groups = "drop"
  )

# For cross-sectional RDD, use mean population for bracket assignment
pop_avg_info <- pop_df %>%
  group_by(mun_code) %>%
  summarise(pop_mean = mean(population, na.rm = TRUE), .groups = "drop")

for (i in seq_len(nrow(rdd_data))) {
  pm <- pop_avg_info$pop_mean[pop_avg_info$mun_code == rdd_data$mun_code[i]]
  if (length(pm) > 0 && !is.na(pm)) {
    res <- assign_fpm(pm)
    rdd_data$running_var[i] <- res$running_var
    rdd_data$above_threshold[i] <- res$above_threshold
    rdd_data$threshold_idx[i] <- res$threshold_idx
    rdd_data$nearest_threshold[i] <- res$nearest_threshold
  }
}

rdd_data$log_homicide_rate <- log(rdd_data$mean_homicide_rate + 1)

# ─────────────────────────────────────────────────────────────────────
# 7. Save
# ─────────────────────────────────────────────────────────────────────
saveRDS(panel, "../data/panel_rdd.rds")
saveRDS(rdd_data, "../data/rdd_analysis.rds")

cat(sprintf("\n=== Analysis datasets ===\n"))
cat(sprintf("Panel: %d mun-years (%d municipalities)\n", nrow(panel), n_distinct(panel$mun_code)))
cat(sprintf("Cross-section: %d municipalities\n", nrow(rdd_data)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))

# Quick check near thresholds
near_5k <- panel %>% filter(abs(running_var) < 5000)
cat(sprintf("Within ±5000 of threshold: %d mun-years\n", nrow(near_5k)))
