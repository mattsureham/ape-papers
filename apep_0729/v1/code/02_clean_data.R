## 02_clean_data.R — Construct analysis dataset for apep_0729

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. LOAD PARSED DATA
# ============================================================
storting <- fread(file.path(data_dir, "storting_turnout.csv"))
local <- fread(file.path(data_dir, "local_turnout.csv"))
subsidy <- fread(file.path(data_dir, "subsidy_local.csv"))
pop <- fread(file.path(data_dir, "population.csv"))

# ============================================================
# 2. CREATE MUNICIPALITY-LEVEL TREATMENT VARIABLES
# ============================================================
# Treatment = municipality has at least one subsidized local newspaper in 2021
# Intensity = total subsidy amount in NOK

treated_munis <- subsidy[, .(
  n_subsidized_papers = .N,
  total_subsidy_nok = sum(subsidy_2021, na.rm = TRUE),
  total_circulation = sum(circulation, na.rm = TRUE),
  subsidy_2020_total = sum(subsidy_2020, na.rm = TRUE),
  had_subsidy_2020 = any(subsidy_2020 > 0, na.rm = TRUE),
  new_subsidy_2021 = any(subsidy_2020 == 0 | is.na(subsidy_2020), na.rm = TRUE)
), by = municipality_name]

cat(sprintf("Treated municipalities: %d\n", nrow(treated_munis)))
cat(sprintf("Total subsidized newspapers in these: %d\n", sum(treated_munis$n_subsidized_papers)))

# ============================================================
# 3. BUILD UNIFIED ELECTION PANEL
# ============================================================
# Stack Storting and local elections into one long panel
storting_long <- storting[, .(region_code, region_name, year,
                              turnout = turnout_storting,
                              election_type = "storting")]
local_long <- local[, .(region_code, region_name, year,
                         turnout = turnout_local,
                         election_type = "local")]
elections <- rbind(storting_long, local_long)

# Use the most recent name for each municipality
# Norwegian municipalities merged extensively in 2020
# We need a clean mapping from region_code to municipality_name

# Create a lookup: strip parenthetical suffixes and extra text for matching
elections[, clean_name := gsub("\\s*\\(.*\\)", "", region_name)]
elections[, clean_name := gsub("\\s*-\\s*\\d{4}$", "", clean_name)]
elections[, clean_name := trimws(clean_name)]

# ============================================================
# 4. MATCH TREATMENT TO ELECTION DATA
# ============================================================
# Match on municipality name (fuzzy matching needed due to Norwegian naming)
# First, get unique election municipality names
election_munis <- unique(elections[, .(region_code, clean_name)])

# Direct name matching
election_munis[, treated := clean_name %in% treated_munis$municipality_name]

# Also try partial matching for cases where names differ slightly
# (e.g., "Tromsø" in subsidy data matches "Tromsø" in SSB)
treated_names <- treated_munis$municipality_name

# Manual matching for remaining cases
extra_matches <- data.table(
  region_code = character(0),
  municipality_name = character(0)
)

# Check match quality
n_matched <- sum(election_munis$treated)
cat(sprintf("Direct name matches: %d municipalities\n", n_matched))

# Merge treatment status into election panel
elections <- merge(elections, election_munis[, .(region_code, treated)],
                   by = "region_code", all.x = TRUE)
elections[is.na(treated), treated := FALSE]

# Add subsidy details for treated municipalities
elections <- merge(elections, treated_munis,
                   by.x = "clean_name", by.y = "municipality_name",
                   all.x = TRUE)
elections[is.na(n_subsidized_papers), n_subsidized_papers := 0]
elections[is.na(total_subsidy_nok), total_subsidy_nok := 0]
elections[is.na(total_circulation), total_circulation := 0]

# ============================================================
# 5. ADD POPULATION DATA
# ============================================================
# Population is available for years 2015, 2017, 2019, 2021, 2023, 2025
# Match to nearest available year
pop_wide <- dcast(pop, region_code + region_name ~ year, value.var = "population")

# For election years not in population data, use nearest year
# Storting: 1993, 1997, 2001, 2005, 2009, 2013, 2017, 2021, 2025
# Local: 1995, 1999, 2003, 2007, 2011, 2015, 2019, 2023
# Population data: 2015, 2017, 2019, 2021, 2023, 2025

# Use 2021 population as a cross-sectional control for all elections
pop_2021 <- pop[year == 2021, .(region_code, population_2021 = population)]
elections <- merge(elections, pop_2021, by = "region_code", all.x = TRUE)

# Create log population
elections[, log_pop := log(population_2021)]

# Create subsidy per capita
elections[, subsidy_per_capita := total_subsidy_nok / population_2021]
elections[is.na(subsidy_per_capita) | is.infinite(subsidy_per_capita),
          subsidy_per_capita := 0]

# ============================================================
# 6. CREATE COUNTY (FYLKE) VARIABLE FROM REGION CODE
# ============================================================
# Norwegian municipality codes: first 2 digits = county (pre-2020 system)
# Post-2020 codes start with 31xx-56xx
elections[, county_code := substr(region_code, 1, 2)]

# ============================================================
# 7. RESTRICT TO ANALYSIS SAMPLE
# ============================================================
# Focus on post-2000 elections where we have good coverage
# and where subsidized papers were operating under modern rules
analysis <- elections[year >= 2001 & !is.na(turnout) & !is.na(population_2021)]

cat(sprintf("\nAnalysis sample:\n"))
cat(sprintf("  Total obs: %d\n", nrow(analysis)))
cat(sprintf("  Municipalities: %d\n", uniqueN(analysis$region_code)))
cat(sprintf("  Treated municipalities: %d\n", uniqueN(analysis[treated == TRUE, region_code])))
cat(sprintf("  Control municipalities: %d\n", uniqueN(analysis[treated == FALSE, region_code])))
cat(sprintf("  Election types: %s\n", paste(unique(analysis$election_type), collapse = ", ")))
cat(sprintf("  Years: %s\n", paste(sort(unique(analysis$year)), collapse = ", ")))

# Summary stats by treatment
cat("\nTurnout by treatment status:\n")
print(analysis[, .(
  mean_turnout = mean(turnout, na.rm = TRUE),
  sd_turnout = sd(turnout, na.rm = TRUE),
  mean_pop = mean(population_2021, na.rm = TRUE),
  n_obs = .N
), by = treated])

# ============================================================
# 8. SAVE ANALYSIS DATASET
# ============================================================
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\nAnalysis dataset saved: %s\n", file.path(data_dir, "analysis_panel.csv")))
