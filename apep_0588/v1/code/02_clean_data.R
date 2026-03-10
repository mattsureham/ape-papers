# ==============================================================================
# 02_clean_data.R — Data Cleaning and Panel Construction for apep_0588
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"

# ==============================================================================
# 1. Load raw data
# ==============================================================================
dt_deaths    <- fread(paste0(data_dir, "weekly_deaths_total.csv"))
dt_age       <- fread(paste0(data_dir, "weekly_deaths_age.csv"))
gas_dep      <- fread(paste0(data_dir, "gas_dependence.csv"))
dt_hicp      <- fread(paste0(data_dir, "hicp_energy.csv"))
dt_pop       <- fread(paste0(data_dir, "population.csv"))
dt_pop_age   <- fread(paste0(data_dir, "population_age.csv"))
dt_hdd       <- fread(paste0(data_dir, "heating_degree_days.csv"))

# ==============================================================================
# 2. Clean total weekly deaths panel
# ==============================================================================
cat("Cleaning total weekly deaths panel...\n")

# Keep only countries that have gas dependence data
dt_deaths <- dt_deaths[geo %in% gas_dep$geo]

# Remove week 53 (incomplete in many countries)
dt_deaths <- dt_deaths[week <= 52]

# Merge gas dependence
dt_deaths <- merge(dt_deaths, gas_dep, by = "geo", all.x = TRUE)

# Merge population (use closest year)
pop_slim <- dt_pop[, .(geo, year, pop)]
dt_deaths <- merge(dt_deaths, pop_slim, by = c("geo", "year"), all.x = TRUE)

# Forward-fill population for years where pop is missing
dt_deaths[, pop := nafill(pop, type = "locf"), by = geo]
dt_deaths[, pop := nafill(pop, type = "nocb"), by = geo]

# Compute deaths per 100,000
dt_deaths[, deaths_pc := deaths / (pop / 100000)]

# Define heating season: Oct-Mar (weeks ~40-52 and 1-13)
dt_deaths[, heating_season := week >= 40 | week <= 13]

# Define treatment period: post Feb 2022 invasion
# Key dates: Feb 24 2022 invasion; gas flow cuts Jun-Sep 2022
# Heating season 2022/23 starts ~week 40 of 2022
dt_deaths[, post := year > 2022 | (year == 2022 & week >= 40)]

# Combined treatment: heating season AND post-shock
dt_deaths[, treated := heating_season & post]

# Heating season post specifically for winter 2022/23 and 2023/24
dt_deaths[, winter_2022 := (year == 2022 & week >= 40) | (year == 2023 & week <= 13)]
dt_deaths[, winter_2023 := (year == 2023 & week >= 40) | (year == 2024 & week <= 13)]
dt_deaths[, post_winter := winter_2022 | winter_2023]

# Interaction term: gas dependence x post-winter
dt_deaths[, gas_post := gas_dep_2021 * as.numeric(post_winter)]
dt_deaths[, gas_heating_post := gas_dep_2021 * gas_heating_share * as.numeric(post_winter)]

# Summer indicator (for placebo: weeks 22-35 = Jun-Aug)
dt_deaths[, summer := week >= 22 & week <= 35]
dt_deaths[, summer_post := gas_dep_2021 * as.numeric(summer & post)]

# Gas dependence groups for descriptives
dt_deaths[, gas_group := fcase(
  gas_dep_2021 >= 0.50, "High (>50%)",
  gas_dep_2021 >= 0.25, "Medium (25-50%)",
  default = "Low (<25%)"
)]
dt_deaths[, gas_group := factor(gas_group, levels = c("Low (<25%)", "Medium (25-50%)", "High (>50%)"))]

# Year-week identifier for FE
dt_deaths[, yw := paste0(year, "W", sprintf("%02d", week))]

# Country fixed effects
dt_deaths[, geo_fe := as.factor(geo)]

# Merge HDD (monthly -> approximate to weekly using year-month)
dt_hdd_slim <- dt_hdd[, .(geo, year, month, hdd)]
# Map week to month (approximate)
dt_deaths[, month_approx := ceiling(week * 12 / 52)]
dt_deaths[month_approx > 12, month_approx := 12]
dt_deaths <- merge(dt_deaths, dt_hdd_slim,
                   by.x = c("geo", "year", "month_approx"),
                   by.y = c("geo", "year", "month"),
                   all.x = TRUE)

cat("Total deaths panel: ", nrow(dt_deaths), " rows, ",
    uniqueN(dt_deaths$geo), " countries\n")

# ==============================================================================
# 3. Clean age-specific weekly deaths panel
# ==============================================================================
cat("Cleaning age-specific deaths panel...\n")

dt_age <- dt_age[geo %in% gas_dep$geo]
dt_age <- dt_age[week <= 52]

# Standardize age groups — create elderly vs. working-age
# Age groups in demo_r_mwk_05 are 5-year bands: Y_LT5, Y5-9, ..., Y85-89, Y_GE90
# Reclassify into broad categories
dt_age[, age_broad := fcase(
  age %in% c("Y_LT5", "Y5-9", "Y10-14", "Y15-19"), "0-19",
  age %in% c("Y20-24", "Y25-29", "Y30-34", "Y35-39", "Y40-44",
             "Y45-49", "Y50-54", "Y55-59", "Y60-64"), "20-64",
  age %in% c("Y65-69", "Y70-74"), "65-74",
  age %in% c("Y75-79", "Y80-84"), "75-84",
  age %in% c("Y85-89", "Y_GE90", "Y_GE85"), "85+",
  default = NA_character_
)]

# Aggregate to broad age groups
dt_age_broad <- dt_age[!is.na(age_broad),
                       .(deaths = sum(deaths, na.rm = TRUE)),
                       by = .(geo, time, year, week, age_broad)]

# Merge gas dependence
dt_age_broad <- merge(dt_age_broad, gas_dep, by = "geo", all.x = TRUE)

# Define elderly (75+) vs working-age (20-64)
dt_age_broad[, elderly := age_broad %in% c("75-84", "85+")]

# Treatment variables
dt_age_broad[, heating_season := week >= 40 | week <= 13]
dt_age_broad[, post := year > 2022 | (year == 2022 & week >= 40)]
dt_age_broad[, winter_2022 := (year == 2022 & week >= 40) | (year == 2023 & week <= 13)]
dt_age_broad[, winter_2023 := (year == 2023 & week >= 40) | (year == 2024 & week <= 13)]
dt_age_broad[, post_winter := winter_2022 | winter_2023]
dt_age_broad[, gas_post := gas_dep_2021 * as.numeric(post_winter)]
dt_age_broad[, yw := paste0(year, "W", sprintf("%02d", week))]

# Gas dependence groups
dt_age_broad[, gas_group := fcase(
  gas_dep_2021 >= 0.50, "High (>50%)",
  gas_dep_2021 >= 0.25, "Medium (25-50%)",
  default = "Low (<25%)"
)]

cat("Age-specific panel: ", nrow(dt_age_broad), " rows, ",
    uniqueN(dt_age_broad$geo), " countries, ",
    uniqueN(dt_age_broad$age_broad), " age groups\n")

# ==============================================================================
# 4. HICP energy prices — compute YoY change
# ==============================================================================
cat("Computing energy price changes...\n")

dt_hicp <- dt_hicp[geo %in% gas_dep$geo]
setorder(dt_hicp, geo, year, month)

# Year-over-year change
dt_hicp[, hicp_lag12 := shift(hicp_energy, 12), by = geo]
dt_hicp[, hicp_yoy := (hicp_energy / hicp_lag12 - 1) * 100]

# Merge gas dependence for first-stage
dt_hicp <- merge(dt_hicp, gas_dep, by = "geo", all.x = TRUE)

# Post indicator
dt_hicp[, post := year > 2022 | (year == 2022 & month >= 3)]
dt_hicp[, gas_post := gas_dep_2021 * as.numeric(post)]

cat("HICP panel: ", nrow(dt_hicp), " rows, ",
    uniqueN(dt_hicp$geo), " countries\n")

# ==============================================================================
# 5. Compute baseline mortality (2015-2019 average by week) for excess mortality
# ==============================================================================
cat("Computing baseline mortality...\n")

baseline <- dt_deaths[year >= 2015 & year <= 2019,
                      .(baseline_deaths = mean(deaths, na.rm = TRUE),
                        baseline_deaths_pc = mean(deaths_pc, na.rm = TRUE)),
                      by = .(geo, week)]

dt_deaths <- merge(dt_deaths, baseline, by = c("geo", "week"), all.x = TRUE)
dt_deaths[, excess_deaths := deaths - baseline_deaths]
dt_deaths[, excess_deaths_pc := deaths_pc - baseline_deaths_pc]
dt_deaths[, excess_ratio := deaths / baseline_deaths]

# ==============================================================================
# 6. Save analysis-ready panels
# ==============================================================================
cat("Saving analysis-ready panels...\n")

fwrite(dt_deaths, paste0(data_dir, "panel_total.csv"))
fwrite(dt_age_broad, paste0(data_dir, "panel_age.csv"))
fwrite(dt_hicp, paste0(data_dir, "panel_hicp.csv"))

# Save summary stats for tables
sumstats <- dt_deaths[year >= 2018 & year <= 2024,
                      .(mean_deaths = mean(deaths, na.rm = TRUE),
                        sd_deaths = sd(deaths, na.rm = TRUE),
                        mean_deaths_pc = mean(deaths_pc, na.rm = TRUE),
                        sd_deaths_pc = sd(deaths_pc, na.rm = TRUE),
                        mean_excess = mean(excess_deaths_pc, na.rm = TRUE),
                        pop_mean = mean(pop, na.rm = TRUE),
                        n_weeks = .N),
                      by = .(geo, gas_dep_2021, gas_heating_share, gas_group)]

fwrite(sumstats, paste0(data_dir, "summary_stats.csv"))

cat("\nPanel construction complete.\n")
cat("  Total panel: ", nrow(dt_deaths), " rows\n")
cat("  Age panel:   ", nrow(dt_age_broad), " rows\n")
cat("  HICP panel:  ", nrow(dt_hicp), " rows\n")
