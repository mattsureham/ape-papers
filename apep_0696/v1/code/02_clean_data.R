## 02_clean_data.R — Build analysis dataset
## apep_0696: FPM fiscal windfalls and agricultural expansion in Brazil
##
## Steps:
##   1. Load raw data
##   2. Assign FPM coefficient and running variable from population
##   3. Build normalized multi-cutoff running variable
##   4. Merge population + PAM into analysis panel
##   5. Construct analytic variables

library(tidyverse)

# Run from the v1/ directory (e.g., Rscript code/$(basename $0))

cat("=== Cleaning Data for apep_0696 ===\n")

## ─────────────────────────────────────────────────────────────────────────────
## Load data
## ─────────────────────────────────────────────────────────────────────────────
pop    <- read_csv("data/population.csv", col_types = cols(mun_code = col_character()))
pam    <- read_csv("data/pam_crop_area.csv", col_types = cols(mun_code = col_character()))
fpm_sched <- read_csv("data/fpm_schedule.csv")

cat("Population rows:", nrow(pop), "\n")
cat("PAM rows:", nrow(pam), "\n")

## ─────────────────────────────────────────────────────────────────────────────
## 2. Assign FPM coefficient based on census population
##    Municipalities use 2000 census pop to determine bracket pre-2010 update
##    and 2010 census pop for post-2010 (though update was phased)
##    Key identification: use 2000 census for the cross-sectional design
## ─────────────────────────────────────────────────────────────────────────────

# FPM thresholds (the cutoffs for the running variable)
fpm_thresholds <- fpm_sched$pop_min[-1]  # first threshold is population = 10,189
cat("FPM thresholds:", fpm_thresholds, "\n")

# Function to assign FPM bracket and coefficient given population
assign_fpm <- function(pop, fpm_sched) {
  bracket <- findInterval(pop, c(0, fpm_sched$pop_min[-1]))
  coeff   <- fpm_sched$coeff[bracket]
  coeff
}

# Apply to 2000 census population
pop_2000 <- pop %>%
  filter(year == 2000) %>%
  mutate(
    fpm_coeff_2000 = assign_fpm(pop, fpm_sched),
    # Which threshold is each municipality closest to?
    # Find the nearest FPM threshold from above (pop / threshold - 1)
    # We normalize relative to each threshold: run_var_k = pop/threshold_k - 1
    bracket_2000 = findInterval(pop, c(0, fpm_thresholds))
  )

pop_2010 <- pop %>%
  filter(year == 2010) %>%
  mutate(
    fpm_coeff_2010 = assign_fpm(pop, fpm_sched),
    bracket_2010 = findInterval(pop, c(0, fpm_thresholds))
  )

cat("2000 census: FPM coefficient distribution\n")
print(table(pop_2000$fpm_coeff_2000))

## ─────────────────────────────────────────────────────────────────────────────
## 3. Build multi-cutoff normalized running variable
##    For each municipality, compute normalized distance to the threshold
##    that defines its FPM bracket assignment:
##    x_k = (pop - threshold_k) / threshold_k
##    where threshold_k is the lower boundary of the municipality's bracket
##    Municipalities just above the threshold (x_k > 0) get higher coefficient
## ─────────────────────────────────────────────────────────────────────────────

# Assign running variable relative to each municipality's binding threshold
pop_2000 <- pop_2000 %>%
  mutate(
    # The threshold that determines this municipality's bracket
    # (threshold they crossed most recently = lower bound of their bracket)
    binding_threshold_2000 = ifelse(
      bracket_2000 == 1,
      fpm_thresholds[1],  # below first threshold, bind to first threshold
      fpm_thresholds[pmin(bracket_2000, length(fpm_thresholds))]
    ),
    # Normalized running variable: (pop / threshold) - 1
    # Negative = below threshold (lower bracket), Positive = above (higher bracket)
    run_var_2000 = (pop - binding_threshold_2000) / binding_threshold_2000,
    # Indicator: above the threshold (treatment = higher FPM bracket)
    above_threshold_2000 = (pop >= binding_threshold_2000) & (bracket_2000 > 1)
  )

# Check distribution of running variable near cutoffs
cat("\nRunning variable |x| < 0.1 (near threshold):",
    sum(abs(pop_2000$run_var_2000) < 0.1, na.rm = TRUE), "municipalities\n")
cat("Running variable |x| < 0.2:",
    sum(abs(pop_2000$run_var_2000) < 0.2, na.rm = TRUE), "municipalities\n")

## ─────────────────────────────────────────────────────────────────────────────
## 4. Merge population + PAM into analysis panel
##    We use 2000 census population as the RDD running variable
##    Outcomes: PAM crop area across years 2000-2019
## ─────────────────────────────────────────────────────────────────────────────

# Join population (2000 census) with PAM annual data
df_panel <- pam %>%
  left_join(
    pop_2000 %>% dplyr::select(mun_code, mun_name, pop, fpm_coeff_2000,
                               bracket_2000, binding_threshold_2000,
                               run_var_2000, above_threshold_2000),
    by = "mun_code"
  ) %>%
  filter(!is.na(pop))  # drop municipalities not in 2000 census (new municipalities)

cat("\nPanel after merge:", nrow(df_panel), "municipality-year obs\n")
cat("Unique municipalities:", n_distinct(df_panel$mun_code), "\n")

## ─────────────────────────────────────────────────────────────────────────────
## 5. Construct analytic variables
## ─────────────────────────────────────────────────────────────────────────────

df_panel <- df_panel %>%
  mutate(
    # Log crop area (main outcome)
    log_crop_area = log(crop_area_ha + 1),
    # Standardize crop area to pre-period mean
    # Year indicators
    post_2010 = as.integer(year >= 2010),  # after 2010 census update
    # Continuous year trend
    year_trend = year - 2000,
    # FPM coefficient increment at each threshold (0.2 per bracket step)
    coeff_increment = ifelse(above_threshold_2000, 0.2, 0)
  )

# Compute pre-period mean crop area (2000-2003) for each municipality
pre_means <- df_panel %>%
  filter(year <= 2003) %>%
  group_by(mun_code) %>%
  summarise(mean_crop_pre = mean(crop_area_ha, na.rm = TRUE), .groups = "drop")

df_panel <- df_panel %>%
  left_join(pre_means, by = "mun_code") %>%
  mutate(
    crop_area_pct_pre = (crop_area_ha - mean_crop_pre) / (mean_crop_pre + 1),
    log_crop_pct = log(crop_area_ha / (mean_crop_pre + 1) + 0.01)
  )

## ─────────────────────────────────────────────────────────────────────────────
## 6. Cross-sectional dataset for the RDD (average post-period outcomes)
## ─────────────────────────────────────────────────────────────────────────────

# For the RDD: use average crop area 2005-2015 (post-2000 census)
df_cross <- df_panel %>%
  filter(year >= 2005 & year <= 2015) %>%
  group_by(mun_code, mun_name, pop, fpm_coeff_2000, bracket_2000,
           binding_threshold_2000, run_var_2000, above_threshold_2000) %>%
  summarise(
    avg_crop_area = mean(crop_area_ha, na.rm = TRUE),
    avg_log_crop  = mean(log_crop_area, na.rm = TRUE),
    n_years       = n(),
    .groups = "drop"
  ) %>%
  filter(!is.na(avg_crop_area) & avg_crop_area > 0)

cat("\nCross-sectional RDD dataset:", nrow(df_cross), "municipalities\n")

## ─────────────────────────────────────────────────────────────────────────────
## 7. Stacked multi-cutoff dataset
##    For each of the 17 thresholds, compute running variable relative to that threshold
##    Each municipality appears once per threshold it is near (within 30% bandwidth)
## ─────────────────────────────────────────────────────────────────────────────

# For the multi-cutoff RDD, we need to compute x_ik = (pop_i / threshold_k) - 1
# for each threshold k
# Treatment at threshold k: municipality has pop >= threshold_k

stacked_list <- list()
bw_factor <- 0.30  # include municipalities within 30% of threshold

for (k in seq_along(fpm_thresholds)) {
  thresh <- fpm_thresholds[k]
  coeff_below <- fpm_sched$coeff[k]      # coefficient just below threshold k
  coeff_above <- fpm_sched$coeff[k + 1]  # coefficient at/above threshold k

  # Normalized running variable relative to threshold k
  df_k <- df_cross %>%
    mutate(
      run_var_k = (pop - thresh) / thresh,  # normalized distance
      above_k   = as.integer(pop >= thresh),  # treatment indicator
      threshold_k = thresh,
      k_index = k,
      coeff_below_k = coeff_below,
      coeff_above_k = coeff_above,
      coeff_jump = coeff_above - coeff_below  # always 0.2 in this schedule
    ) %>%
    filter(abs(run_var_k) <= bw_factor)  # within bandwidth

  if (nrow(df_k) >= 10) {  # need sufficient observations
    stacked_list[[k]] <- df_k
  }
}

df_stacked <- bind_rows(stacked_list)
cat("Stacked multi-cutoff dataset:", nrow(df_stacked), "municipality-threshold obs\n")
cat("Thresholds represented:", n_distinct(df_stacked$k_index), "of 17\n")

## ─────────────────────────────────────────────────────────────────────────────
## 8. Save analysis datasets
## ─────────────────────────────────────────────────────────────────────────────

write_csv(df_panel, "data/panel_clean.csv")
write_csv(df_cross, "data/cross_section_rdd.csv")
write_csv(df_stacked, "data/stacked_multicutoff.csv")

cat("\n=== Clean Data Summary ===\n")
cat("Panel:", nrow(df_panel), "obs,", n_distinct(df_panel$mun_code), "municipalities,",
    n_distinct(df_panel$year), "years\n")
cat("Cross-section:", nrow(df_cross), "municipalities\n")
cat("Stacked multi-cutoff:", nrow(df_stacked), "obs across",
    n_distinct(df_stacked$k_index), "thresholds\n")
cat("Near threshold (|x|<0.1):", sum(abs(df_cross$run_var_2000) < 0.1), "\n")
cat("Near threshold (|x|<0.2):", sum(abs(df_cross$run_var_2000) < 0.2), "\n")

# Describe the threshold assignment
cat("\nFPM bracket distribution (2000 census):\n")
print(table(df_cross$bracket_2000))
