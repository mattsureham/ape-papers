## 02_clean_data.R — Build analysis panel: PFA × quarter crime + treatment intensity
source("00_packages.R")
library(readODS)

data_dir <- "../data"

# ============================================================================
# 1. Read and stack PFA crime data across financial years
# ============================================================================
cat("=== Reading PFA crime data ===\n")
pfa_file <- file.path(data_dir, "prc_pfa_tables.ods")

# Read sheets from 2015_16 to 2024_25 (covers Apr 2015 - Mar 2025)
target_sheets <- c("2015_16", "2016_17", "2017_18", "2018_19",
                    "2019_20", "2020_21", "2021_22", "2022_23",
                    "2023_24", "2024_25")

crime_raw <- list()
for (sh in target_sheets) {
  cat("  Reading sheet:", sh, "...")
  d <- read_ods(pfa_file, sheet = sh)
  if (nrow(d) > 0) {
    crime_raw[[sh]] <- d
    cat("->", nrow(d), "rows\n")
  }
}
crime_all <- bind_rows(crime_raw)
cat("Total crime rows:", nrow(crime_all), "\n")

# Exclude non-geographic forces
non_geo_forces <- c("Action Fraud", "British Transport Police", "CIFAS", "UK Finance")
crime <- crime_all %>%
  filter(!`Force Name` %in% non_geo_forces)

cat("After excluding non-geo forces:", nrow(crime), "rows\n")
cat("Geographic forces:", length(unique(crime$`Force Name`)), "\n")

# ============================================================================
# 2. Aggregate to PFA × quarter × offence group
# ============================================================================
cat("\n=== Aggregating crime by PFA × quarter × offence group ===\n")

# Create a proper time variable
# Financial Year 2018/19 Q1 = Apr-Jun 2018
crime <- crime %>%
  rename(fy = `Financial Year`, quarter = `Financial Quarter`,
         force = `Force Name`, offence_group = `Offence Group`,
         offence_subgroup = `Offence Subgroup`,
         n_offences = `Number of Offences`) %>%
  mutate(
    fy_start = as.integer(substr(fy, 1, 4)),
    # Calendar quarter: FY Q1 = calendar Q2 (Apr-Jun), etc.
    cal_year = case_when(
      quarter <= 3 ~ fy_start,
      quarter == 4 ~ fy_start + 1L
    ),
    cal_quarter = case_when(
      quarter == 1 ~ 2L,  # Apr-Jun
      quarter == 2 ~ 3L,  # Jul-Sep
      quarter == 3 ~ 4L,  # Oct-Dec
      quarter == 4 ~ 1L   # Jan-Mar
    ),
    yearq = cal_year + (cal_quarter - 1) / 4,
    time_id = (cal_year - 2015) * 4 + cal_quarter
  )

# Aggregate by force × quarter × offence group
crime_pfa <- crime %>%
  group_by(force, cal_year, cal_quarter, yearq, time_id, offence_group) %>%
  summarise(n_offences = sum(n_offences, na.rm = TRUE), .groups = "drop")

# Also create separate panels for key subgroups
crime_sub <- crime %>%
  filter(offence_subgroup %in% c("Residential burglary", "Shoplifting",
                                  "Theft from the person", "Vehicle offences")) %>%
  group_by(force, cal_year, cal_quarter, yearq, time_id, offence_subgroup) %>%
  summarise(n_offences = sum(n_offences, na.rm = TRUE), .groups = "drop")

# Pivot to wide: one column per offence group
crime_wide <- crime_pfa %>%
  mutate(offence_var = case_when(
    offence_group == "Violence against the person" ~ "violence",
    offence_group == "Theft offences" ~ "theft",
    offence_group == "Robbery" ~ "robbery",
    offence_group == "Criminal damage and arson" ~ "damage",
    offence_group == "Public order offences" ~ "public_order",
    offence_group == "Drug offences" ~ "drugs",
    offence_group == "Sexual offences" ~ "sexual",
    offence_group == "Fraud offences" ~ "fraud",
    offence_group == "Possession of weapons offences" ~ "weapons",
    offence_group == "Miscellaneous crimes against society" ~ "misc",
    TRUE ~ "other"
  )) %>%
  select(force, cal_year, cal_quarter, yearq, time_id, offence_var, n_offences) %>%
  pivot_wider(names_from = offence_var, values_from = n_offences, values_fill = 0)

# Add subgroup columns
sub_wide <- crime_sub %>%
  mutate(sub_var = case_when(
    offence_subgroup == "Residential burglary" ~ "burglary_res",
    offence_subgroup == "Shoplifting" ~ "shoplifting",
    offence_subgroup == "Theft from the person" ~ "theft_person",
    offence_subgroup == "Vehicle offences" ~ "vehicle",
    TRUE ~ "other_sub"
  )) %>%
  select(force, cal_year, cal_quarter, yearq, time_id, sub_var, n_offences) %>%
  pivot_wider(names_from = sub_var, values_from = n_offences, values_fill = 0)

crime_wide <- left_join(crime_wide, sub_wide,
                         by = c("force", "cal_year", "cal_quarter", "yearq", "time_id"))

# Total crime
crime_wide <- crime_wide %>%
  mutate(total_crime = violence + theft + robbery + damage + public_order +
           drugs + sexual + fraud + weapons + misc)

cat("Crime panel: ", nrow(crime_wide), " PFA-quarters\n")
cat("PFAs:", length(unique(crime_wide$force)), "\n")
cat("Time range:", min(crime_wide$yearq), "to", max(crime_wide$yearq), "\n")

# ============================================================================
# 3. Map LAs to PFAs using geographic reference
# ============================================================================
cat("\n=== Mapping LAs to PFAs ===\n")
geo <- read.csv(file.path(data_dir, "geo_pfa.csv"), stringsAsFactors = FALSE)
names(geo) <- c("csp_name", "force", "region", "ons_code")

# Load NOMIS data
gambling <- readRDS(file.path(data_dir, "gambling_biz.rds"))
food_svc <- readRDS(file.path(data_dir, "food_biz.rds"))
population <- readRDS(file.path(data_dir, "population.rds"))

# The geo file maps CSPs to forces. NOMIS has LA codes.
# We need to match NOMIS LAs to PFAs.
# Strategy: merge by name (CSP name ≈ LA name for most cases)

# Clean names for matching
clean_name <- function(x) {
  x <- tolower(x)
  x <- gsub(",.*", "", x)  # Remove after comma
  x <- gsub("\\s+", " ", trimws(x))
  x
}

# Create a lookup from NOMIS LA names to PFA forces
# First, try matching NOMIS la_name to geo csp_name
geo_lookup <- geo %>%
  mutate(csp_clean = clean_name(csp_name)) %>%
  select(csp_clean, force) %>%
  distinct()

gambling_la <- gambling %>%
  filter(year == 2018) %>%  # pre-treatment
  mutate(la_clean = clean_name(la_name))

# Match
matched <- gambling_la %>%
  left_join(geo_lookup, by = c("la_clean" = "csp_clean"))

cat("Matched to PFA:", sum(!is.na(matched$force)), "of", nrow(matched), "LAs\n")

# For unmatched, try partial matching
unmatched <- matched %>% filter(is.na(force))
if (nrow(unmatched) > 0) {
  cat("Unmatched LAs:", nrow(unmatched), "\n")
  # Manual mapping for common mismatches
  manual_map <- tribble(
    ~la_clean, ~force_manual,
    "bristol, city of", "Avon and Somerset",
    "kingston upon hull, city of", "Humberside",
    "herefordshire, county of", "West Mercia",
    "city of london", "London, City of"
  )
  matched <- matched %>%
    left_join(manual_map, by = "la_clean") %>%
    mutate(force = coalesce(force, force_manual)) %>%
    select(-force_manual)
}

# Aggregate gambling businesses to PFA level
la_to_pfa <- matched %>%
  filter(!is.na(force)) %>%
  select(la_code, force) %>%
  distinct()

# Merge all NOMIS data to PFA
gambling_pfa <- gambling %>%
  inner_join(la_to_pfa, by = "la_code") %>%
  group_by(force, year) %>%
  summarise(gambling_biz = sum(count, na.rm = TRUE), .groups = "drop")

food_pfa <- food_svc %>%
  inner_join(la_to_pfa, by = "la_code") %>%
  group_by(force, year) %>%
  summarise(food_biz = sum(count, na.rm = TRUE), .groups = "drop")

pop_pfa <- population %>%
  inner_join(la_to_pfa, by = "la_code") %>%
  group_by(force, year) %>%
  summarise(pop = sum(population, na.rm = TRUE), .groups = "drop")

cat("PFAs with gambling data:", length(unique(gambling_pfa$force)), "\n")

# ============================================================================
# 4. Construct treatment intensity
# ============================================================================
cat("\n=== Constructing treatment intensity ===\n")

# Pre-treatment betting shop density: average 2016-2018
pre_treatment <- gambling_pfa %>%
  filter(year %in% 2016:2018) %>%
  inner_join(pop_pfa %>% filter(year %in% 2016:2018), by = c("force", "year")) %>%
  group_by(force) %>%
  summarise(
    gambling_biz_pre = mean(gambling_biz),
    pop_pre = mean(pop),
    betting_density = gambling_biz_pre / pop_pre * 10000,
    .groups = "drop"
  )

cat("Treatment intensity (betting density per 10K):\n")
cat("  Mean:", round(mean(pre_treatment$betting_density), 2), "\n")
cat("  SD:", round(sd(pre_treatment$betting_density), 2), "\n")
cat("  Min:", round(min(pre_treatment$betting_density), 2), "\n")
cat("  Max:", round(max(pre_treatment$betting_density), 2), "\n")

# Placebo: food service density
pre_food <- food_pfa %>%
  filter(year %in% 2016:2018) %>%
  inner_join(pop_pfa %>% filter(year %in% 2016:2018), by = c("force", "year")) %>%
  group_by(force) %>%
  summarise(
    food_biz_pre = mean(food_biz),
    food_density = food_biz_pre / mean(pop) * 10000,
    .groups = "drop"
  )

# ============================================================================
# 5. Build final analysis panel
# ============================================================================
cat("\n=== Building analysis panel ===\n")

# Post indicator: April 2019 = FY 2019/20 Q1 = cal 2019 Q2
# yearq >= 2019.25 is post
panel <- crime_wide %>%
  inner_join(pre_treatment, by = "force") %>%
  left_join(pre_food, by = "force") %>%
  left_join(pop_pfa %>% rename(pop_year = pop), by = c("force", "cal_year" = "year")) %>%
  mutate(
    post = as.integer(yearq >= 2019.25),
    treat_x_post = betting_density * post,
    # Crime rates per 10,000 pop
    pop_use = coalesce(pop_year, pop_pre),
    total_rate = total_crime / pop_use * 10000,
    violence_rate = violence / pop_use * 10000,
    theft_rate = theft / pop_use * 10000,
    robbery_rate = robbery / pop_use * 10000,
    damage_rate = damage / pop_use * 10000,
    public_order_rate = public_order / pop_use * 10000,
    drugs_rate = drugs / pop_use * 10000,
    shoplifting_rate = shoplifting / pop_use * 10000,
    burglary_res_rate = burglary_res / pop_use * 10000,
    # Time relative to treatment (in quarters)
    rel_time = time_id - 18,  # Q2 2019 = time_id 18
    # Force as factor for FE
    force_id = as.integer(factor(force)),
    # COVID indicator (Q2 2020 through Q1 2021)
    covid = as.integer(yearq >= 2020.25 & yearq <= 2021.0)
  )

# Drop observations with missing population
panel <- panel %>% filter(!is.na(pop_use) & pop_use > 0)

cat("Final panel:", nrow(panel), "PFA-quarters\n")
cat("PFAs:", length(unique(panel$force)), "\n")
cat("Pre-treatment quarters:", sum(panel$post == 0 & !duplicated(panel$time_id)), "\n")
cat("Post-treatment quarters:", sum(panel$post == 1 & !duplicated(panel$time_id)), "\n")

# Time-varying gambling business counts for dose-response
gambling_annual <- gambling_pfa %>%
  inner_join(pop_pfa, by = c("force", "year")) %>%
  mutate(gambling_rate = gambling_biz / pop * 10000) %>%
  select(force, year, gambling_rate_annual = gambling_rate,
         gambling_biz_annual = gambling_biz)

panel <- panel %>%
  left_join(gambling_annual, by = c("force", "cal_year" = "year"))

# Save
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))

# Summary stats
cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("PFAs:", length(unique(panel$force)), "\n")
cat("Time range:", min(panel$yearq), "to", max(panel$yearq), "\n")
cat("Mean total crime rate:", round(mean(panel$total_rate, na.rm=T), 1), "per 10K\n")
cat("Mean betting density:", round(mean(panel$betting_density), 2), "per 10K\n")
cat("SD betting density:", round(sd(panel$betting_density), 2), "\n")
