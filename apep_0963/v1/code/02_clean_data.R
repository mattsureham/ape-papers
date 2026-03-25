## 02_clean_data.R — Clean and merge data for apep_0963
## Creates analysis-ready dataset

source("00_packages.R")

data_dir <- "../data"

## Load raw data
cps_raw <- readRDS(file.path(data_dir, "cps_fss_raw.rds"))
snap_rates <- readRDS(file.path(data_dir, "snap_rates_2019.rds"))
unemp_rates <- readRDS(file.path(data_dir, "unemp_rates.rds"))
ea_status <- readRDS(file.path(data_dir, "ea_status.rds"))

cat(sprintf("Raw CPS: %d obs, %d columns\n", nrow(cps_raw), ncol(cps_raw)))

## =========================================================================
## Step 1: Filter to reference persons (one per household)
## =========================================================================
## PERRP coding changed over time:
##   2018-2019: 1 = Reference person w/ relatives, 2 = Ref person w/o relatives
##   2020+: 40 = Reference person, 41 = Opposite-sex spouse
## Filter to reference persons only for household-level analysis

cps <- cps_raw %>%
  mutate(
    is_ref_person = case_when(
      year <= 2019 & PERRP %in% c(1, 2) ~ TRUE,
      year >= 2020 & PERRP %in% c(40, 41) ~ TRUE,
      TRUE ~ FALSE
    )
  ) %>%
  filter(is_ref_person)

## Deduplicate to one person per household using HRHHID + HRHHID2
if ("HRHHID" %in% names(cps) & "HRHHID2" %in% names(cps)) {
  cps <- cps %>%
    group_by(year, HRHHID, HRHHID2) %>%
    slice(1) %>%
    ungroup()
} else {
  ## Fallback: group by year + state + multiple variables for quasi-uniqueness
  cps <- cps %>%
    group_by(year, statefip, HWHHWGT, HEFAMINC, HRNUMHOU, PRTAGE) %>%
    slice(1) %>%
    ungroup()
}

cat(sprintf("After reference person filter: %d households\n", nrow(cps)))
cat("Households by year:\n")
print(table(cps$year))

## =========================================================================
## Step 2: Create food security indicators
## =========================================================================
## HRFS12M1 in Census API uses 3-level coding:
##   1 = Food secure (combines USDA high + marginal)
##   2 = Low food security (food insecure)
##   3 = Very low food security (most severe)
##  -1 = Not in universe, -9 = No response
## USDA defines "food insecure" = low + very low = levels 2+3

cps <- cps %>%
  filter(!is.na(HRFS12M1), HRFS12M1 > 0) %>%
  mutate(
    food_insecure = as.integer(HRFS12M1 >= 2),       # Low + very low (USDA food insecure)
    very_low_fs = as.integer(HRFS12M1 == 3),          # Very low food security only
    food_secure = as.integer(HRFS12M1 == 1)           # Food secure
  )

cat(sprintf("After food security filter: %d households\n", nrow(cps)))

## =========================================================================
## Step 3: Create household controls
## =========================================================================
cps <- cps %>%
  mutate(
    age = ifelse(!is.na(PRTAGE) & PRTAGE > 0, PRTAGE, NA_real_),
    college = as.integer(!is.na(PEEDUCA) & PEEDUCA >= 43),
    black = as.integer(!is.na(PTDTRACE) & PTDTRACE == 2),
    hispanic = as.integer(!is.na(PEHSPNON) & PEHSPNON == 1),
    hh_size = ifelse(!is.na(HRNUMHOU) & HRNUMHOU > 0, HRNUMHOU, NA_real_),
    has_children = as.integer(!is.na(PRCHLD) & PRCHLD > 0),
    n_children = ifelse(!is.na(PRCHLD) & PRCHLD >= 0, PRCHLD, 0),
    snap_receipt = as.integer(!is.na(HESP1) & HESP1 == 1),
    low_income = as.integer(!is.na(HEFAMINC) & HEFAMINC <= 7),  # Under $25K
    ## Household weight (HWHHWGT has 4 implied decimal places)
    hh_weight = ifelse(!is.na(HWHHWGT) & HWHHWGT > 0, HWHHWGT / 10000, NA_real_)
  )

## =========================================================================
## Step 4: Merge with state SNAP rates (treatment intensity)
## =========================================================================
cps <- cps %>%
  left_join(snap_rates %>% select(statefip, snap_rate, state_name),
            by = "statefip") %>%
  filter(!is.na(snap_rate))

cat(sprintf("After SNAP rate merge: %d obs\n", nrow(cps)))

## =========================================================================
## Step 5: Merge with EA status and unemployment
## =========================================================================
cps <- cps %>%
  left_join(ea_status %>% select(statefip, year, ea_active, early_ea_end),
            by = c("statefip", "year")) %>%
  mutate(
    ea_active = replace_na(ea_active, 0),
    early_ea_end = replace_na(early_ea_end, 0)
  ) %>%
  left_join(unemp_rates, by = c("statefip", "year"))

## =========================================================================
## Step 6: Define treatment variables
## =========================================================================
cps <- cps %>%
  mutate(
    post = as.integer(year >= 2022),
    treat_intensity = snap_rate,
    post_treat = post * treat_intensity,
    year_factor = factor(year),
    clean_sample = as.integer(year %in% c(2018, 2019, 2022, 2023)),
    extended_sample = as.integer(year %in% c(2015, 2016, 2017, 2018, 2019, 2022, 2023))
  )

## =========================================================================
## Summary
## =========================================================================
cat("\n=== Final dataset summary ===\n")
cat(sprintf("Total: %d households, %d states, years: %s\n",
            nrow(cps), n_distinct(cps$statefip),
            paste(sort(unique(cps$year)), collapse = ", ")))

cat("\nUnweighted food insecurity rates by year:\n")
cps %>%
  group_by(year) %>%
  summarise(
    n = n(),
    food_insecure_wtd = weighted.mean(food_insecure, hh_weight, na.rm = TRUE),
    very_low_fs_wtd = weighted.mean(very_low_fs, hh_weight, na.rm = TRUE),
    snap_receipt = weighted.mean(snap_receipt, hh_weight, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nClean sample (2018-19 vs 2022-23):\n")
cps %>%
  filter(clean_sample == 1) %>%
  group_by(post) %>%
  summarise(
    n = n(),
    food_insecure_wtd = weighted.mean(food_insecure, hh_weight, na.rm = TRUE),
    snap_receipt_wtd = weighted.mean(snap_receipt, hh_weight, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nSNAP rate distribution (treatment intensity):\n")
cat(sprintf("  Min: %.3f  Q1: %.3f  Med: %.3f  Q3: %.3f  Max: %.3f\n",
            min(cps$snap_rate), quantile(cps$snap_rate, 0.25),
            median(cps$snap_rate), quantile(cps$snap_rate, 0.75),
            max(cps$snap_rate)))

## =========================================================================
## Save
## =========================================================================
saveRDS(cps, file.path(data_dir, "analysis_data.rds"))

analysis_clean <- cps %>% filter(clean_sample == 1)
saveRDS(analysis_clean, file.path(data_dir, "analysis_clean.rds"))

cat(sprintf("\nSaved: analysis_data.rds (%d), analysis_clean.rds (%d)\n",
            nrow(cps), nrow(analysis_clean)))
