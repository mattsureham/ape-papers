## 02_clean_data.R — Construct analysis dataset
## APEP apep_0831: Section 232 Tariffs and the Racial Wage Gap

source("00_packages.R")

qwi <- readRDS("../data/qwi_manufacturing.rds")
treatment <- readRDS("../data/treatment_exposure.rds")

cat("=== Cleaning and merging data ===\n")

## QWI geography is integer FIPS (e.g. 1003). Convert to 5-digit string.
qwi <- qwi %>%
  mutate(
    fips = sprintf("%05d", geography),
    state_fips = substr(fips, 1, 2)
  )

## Filter to manufacturing sector only
qwi_mfg <- qwi %>%
  filter(industry == "31-33")

cat(sprintf("QWI manufacturing rows: %s\n", format(nrow(qwi_mfg), big.mark = ",")))

## Create time variables
qwi_mfg <- qwi_mfg %>%
  mutate(
    time = year + (quarter - 1) / 4,
    yq = paste0(year, "Q", quarter),
    post = as.integer(year > 2018 | (year == 2018 & quarter >= 2)),
    log_earn = ifelse(!is.na(earn) & earn > 0, log(earn), NA_real_),
    black = as.integer(race == "A2")
  )

## Drop 2020Q2+ to avoid COVID contamination
qwi_mfg <- qwi_mfg %>%
  filter(!(year == 2020 & quarter >= 2))

cat(sprintf("After date filter (through 2020Q1): %s rows\n", format(nrow(qwi_mfg), big.mark = ",")))

## Merge treatment intensity
df <- qwi_mfg %>%
  left_join(treatment %>% select(fips, exposure, emp_mfg, emp_protected), by = "fips")

## Drop counties with no manufacturing employment in CBP
df <- df %>%
  filter(!is.na(emp_mfg) & emp_mfg > 0)

cat(sprintf("After merging treatment: %s rows\n", format(nrow(df), big.mark = ",")))

## Create interaction terms
df <- df %>%
  mutate(
    post_exposure = post * exposure,
    post_black = post * black,
    post_exposure_black = post * exposure * black,
    county_race = paste0(fips, "_", race)
  )

## Create exposure terciles among counties with positive metals employment
## (many counties have 0 exposure, so quartiles produce non-unique breaks)
pos_exposure <- treatment$exposure[treatment$emp_mfg >= 100 & treatment$exposure > 0]
exposure_cuts <- c(0, quantile(pos_exposure, probs = c(1/3, 2/3, 1), na.rm = TRUE))
exposure_cuts <- unique(exposure_cuts)
cat("\nExposure cutpoints (positive exposure, 100+ mfg workers):\n")
print(exposure_cuts)

med_exposure <- median(pos_exposure, na.rm = TRUE)
cat(sprintf("Median positive exposure: %.4f\n", med_exposure))

df <- df %>%
  mutate(
    ## 0 = no metals, 1-3 = terciles of positive exposure
    exposure_q = ifelse(exposure == 0, 0L,
                        as.integer(cut(exposure, breaks = exposure_cuts,
                                        include.lowest = TRUE, labels = FALSE))),
    exposure_q = replace_na(exposure_q, 0L),
    high_exposure = as.integer(exposure > med_exposure)
  )

## Summary statistics
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Unique counties: %d\n", n_distinct(df$fips)))
cat(sprintf("Time periods: %d quarters\n", n_distinct(df$yq)))
cat(sprintf("Observations: %s\n", format(nrow(df), big.mark = ",")))

cat("\nEarnings by race (pre-period, weighted by emp):\n")
df %>%
  filter(post == 0, !is.na(earn), earn > 0, !is.na(emp), emp > 0) %>%
  group_by(Race = ifelse(race == "A1", "White", "Black")) %>%
  summarise(
    mean_earn = weighted.mean(earn, emp, na.rm = TRUE),
    sd_earn = sqrt(Hmisc::wtd.var(earn, emp, na.rm = TRUE)),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  print()

cat("\nExposure by race:\n")
df %>%
  filter(!is.na(emp) & emp > 0) %>%
  group_by(Race = ifelse(race == "A1", "White", "Black")) %>%
  summarise(
    mean_exposure = weighted.mean(exposure, emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat(sprintf("\nHigh-exposure counties: %d\n", n_distinct(df$fips[df$high_exposure == 1])))
cat(sprintf("Low-exposure counties: %d\n", n_distinct(df$fips[df$high_exposure == 0])))

## Save analysis dataset
saveRDS(df, "../data/analysis.rds")
cat(sprintf("\nAnalysis dataset saved: %s rows\n", format(nrow(df), big.mark = ",")))
cat("Done.\n")
