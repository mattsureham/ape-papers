## 02_clean_data.R — Construct analysis dataset
## apep_0825: Networked Backlash in Sweden

source("00_packages.R")

DATA_DIR <- "../data"

## ============================================================================
## 1. Load raw data
## ============================================================================

sd_votes    <- read_csv(file.path(DATA_DIR, "sd_votes.csv"), show_col_types = FALSE)
kolada      <- read_csv(file.path(DATA_DIR, "kolada_demographics.csv"), show_col_types = FALSE)
population  <- read_csv(file.path(DATA_DIR, "population.csv"), show_col_types = FALSE)
crosswalk   <- read_csv(file.path(DATA_DIR, "muni_crosswalk.csv"), show_col_types = FALSE)
sci_pairs   <- read_csv(file.path(DATA_DIR, "sci_se_pairs.csv"), show_col_types = FALSE)
turnout     <- read_csv(file.path(DATA_DIR, "turnout.csv"), show_col_types = FALSE)
income      <- read_csv(file.path(DATA_DIR, "income.csv"), show_col_types = FALSE)

cat("=== Raw data loaded ===\n")

## ============================================================================
## 2. SD vote shares — long difference
## ============================================================================

# Keep only 4-digit municipality codes
sd_votes <- sd_votes %>%
  filter(nchar(muni_code) == 4)

# Wide format: one row per municipality with vote shares for each election
sd_wide <- sd_votes %>%
  filter(year %in% c(2010, 2014, 2018, 2022)) %>%
  select(muni_code, year, sd_share) %>%
  pivot_wider(names_from = year, values_from = sd_share,
              names_prefix = "sd_")

# Long difference: 2014 → 2018 (main), 2010 → 2014 (placebo)
sd_wide <- sd_wide %>%
  mutate(
    delta_sd_1418 = sd_2018 - sd_2014,   # Main: post-Bosättningslagen
    delta_sd_1014 = sd_2014 - sd_2010    # Placebo: pre-Bosättningslagen
  )

cat("SD long differences: ", nrow(sd_wide), "municipalities\n")
cat("Mean ΔSD 2014→2018:", round(mean(sd_wide$delta_sd_1418, na.rm = TRUE), 2), "pp\n")
cat("Mean ΔSD 2010→2014:", round(mean(sd_wide$delta_sd_1014, na.rm = TRUE), 2), "pp\n")

## ============================================================================
## 3. Treatment: Refugee exposure (Δ foreign-born share 2014→2017)
## ============================================================================

# Use foreign-born excl. EU/EFTA as better refugee proxy
# Treatment = change in non-EU foreign-born share from 2014 to 2017
# (Bosättningslagen effective March 2016; most placements 2016-2017)

kolada <- kolada %>%
  filter(nchar(muni_code) == 4)

treatment <- kolada %>%
  filter(year %in% c(2014, 2017)) %>%
  select(muni_code, year, foreign_noneu_share) %>%
  pivot_wider(names_from = year, values_from = foreign_noneu_share,
              names_prefix = "fnoneu_") %>%
  mutate(delta_fnoneu = fnoneu_2017 - fnoneu_2014)

# Also compute total foreign-born change
treatment_total <- kolada %>%
  filter(year %in% c(2014, 2017)) %>%
  select(muni_code, year, foreign_share) %>%
  pivot_wider(names_from = year, values_from = foreign_share,
              names_prefix = "fborn_") %>%
  mutate(delta_fborn = fborn_2017 - fborn_2014)

# treatment already has fnoneu_2014 from the pivot; add total foreign-born change
treatment <- treatment %>%
  left_join(treatment_total %>% select(muni_code, delta_fborn, fborn_2014), by = "muni_code")

cat("Treatment variable: ", nrow(treatment), "municipalities\n")
cat("Mean Δ non-EU foreign share:", round(mean(treatment$delta_fnoneu, na.rm = TRUE), 2), "pp\n")
cat("SD Δ non-EU foreign share:", round(sd(treatment$delta_fnoneu, na.rm = TRUE), 2), "pp\n")

## ============================================================================
## 4. SCI Bartik Network Exposure
## ============================================================================

# Row-normalize SCI within each origin county
sci_norm <- sci_pairs %>%
  group_by(user_nuts3) %>%
  mutate(
    sci_weight = sci / sum(sci)
  ) %>%
  ungroup()

# Verify: weights sum to 1 within each user_nuts3
sci_check <- sci_norm %>%
  group_by(user_nuts3) %>%
  summarise(w_sum = sum(sci_weight), .groups = "drop")
cat("SCI weight sums (should be ~1):", range(sci_check$w_sum), "\n")

# County-level treatment: mean Δ non-EU foreign share per NUTS3
county_treatment <- crosswalk %>%
  filter(!is.na(nuts3)) %>%
  left_join(treatment %>% select(muni_code, delta_fnoneu), by = "muni_code") %>%
  group_by(nuts3) %>%
  summarise(
    county_delta_fnoneu = mean(delta_fnoneu, na.rm = TRUE),
    n_munis = n(),
    .groups = "drop"
  )

cat("County-level treatment:\n")
print(county_treatment %>% arrange(desc(county_delta_fnoneu)))

# Construct network exposure: for each county c,
# NetworkExposure_c = Σ_k≠c w(c,k) × Treatment_k
# (Exclude own county to separate own vs network effects)
network_exposure <- sci_norm %>%
  filter(user_nuts3 != friend_nuts3) %>%  # exclude own-county
  left_join(county_treatment %>% select(nuts3, county_delta_fnoneu),
            by = c("friend_nuts3" = "nuts3")) %>%
  group_by(user_nuts3) %>%
  summarise(
    network_exposure = sum(sci_weight * county_delta_fnoneu, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nNetwork exposure by county:\n")
print(network_exposure %>% arrange(desc(network_exposure)))

# Assign to municipalities via crosswalk
muni_network <- crosswalk %>%
  filter(!is.na(nuts3)) %>%
  left_join(network_exposure, by = c("nuts3" = "user_nuts3")) %>%
  select(muni_code, nuts3, network_exposure)

cat("\nMunicipalities with network exposure:", sum(!is.na(muni_network$network_exposure)), "\n")

## ============================================================================
## 5. Controls (baseline levels)
## ============================================================================

# Baseline characteristics from 2014
# Baseline foreign-born share from Kolada (total, not non-EU — non-EU is in treatment)
baseline <- kolada %>%
  filter(year == 2014) %>%
  select(muni_code, fb_2014 = foreign_share)

pop_2014 <- population %>%
  filter(year == 2014, nchar(muni_code) == 4) %>%
  select(muni_code, pop_2014 = population)

turnout_2014 <- turnout %>%
  filter(year == 2014) %>%
  select(muni_code, turnout_2014 = turnout)

## ============================================================================
## 6. Merge into analysis dataset
## ============================================================================

analysis <- sd_wide %>%
  left_join(treatment, by = "muni_code") %>%
  left_join(muni_network, by = "muni_code") %>%
  left_join(baseline, by = "muni_code") %>%
  left_join(pop_2014, by = "muni_code") %>%
  left_join(turnout_2014, by = "muni_code") %>%
  mutate(
    log_pop = log(pop_2014),
    sd_2014_level = sd_2014
  )

cat("\n=== Analysis dataset ===\n")
cat("Total obs:", nrow(analysis), "\n")
cat("With SD data:", sum(!is.na(analysis$delta_sd_1418)), "\n")
cat("With treatment:", sum(!is.na(analysis$delta_fnoneu)), "\n")
cat("With network exposure:", sum(!is.na(analysis$network_exposure)), "\n")
cat("Complete cases:", sum(complete.cases(
  analysis$delta_sd_1418, analysis$delta_fnoneu,
  analysis$network_exposure, analysis$sd_2014)), "\n")

# Keep complete cases for main analysis
analysis_clean <- analysis %>%
  filter(
    !is.na(delta_sd_1418),
    !is.na(delta_fnoneu),
    !is.na(network_exposure),
    !is.na(sd_2014)
  )

cat("Analysis sample (complete):", nrow(analysis_clean), "municipalities\n")

# Summary stats
cat("\n--- Summary Statistics ---\n")
summ_vars <- c("delta_sd_1418", "delta_sd_1014", "sd_2014",
               "delta_fnoneu", "network_exposure",
               "fb_2014", "fnoneu_2014", "pop_2014")
for (v in summ_vars) {
  if (v %in% names(analysis_clean)) {
    x <- analysis_clean[[v]]
    cat(sprintf("%-20s mean=%7.2f  sd=%7.2f  min=%7.2f  max=%7.2f  N=%d\n",
                v, mean(x, na.rm=T), sd(x, na.rm=T),
                min(x, na.rm=T), max(x, na.rm=T), sum(!is.na(x))))
  }
}

# Save
write_csv(analysis_clean, file.path(DATA_DIR, "analysis.csv"))
cat("\nSaved analysis.csv\n")

# Also save county-level dataset for SCI Bartik analysis
county_analysis <- county_treatment %>%
  left_join(network_exposure, by = c("nuts3" = "user_nuts3"))

# County-level SD changes
county_sd <- crosswalk %>%
  filter(!is.na(nuts3)) %>%
  left_join(sd_wide %>% select(muni_code, delta_sd_1418, delta_sd_1014, sd_2014),
            by = "muni_code") %>%
  group_by(nuts3, county_name) %>%
  summarise(
    county_delta_sd_1418 = mean(delta_sd_1418, na.rm = TRUE),
    county_delta_sd_1014 = mean(delta_sd_1014, na.rm = TRUE),
    county_sd_2014 = mean(sd_2014, na.rm = TRUE),
    n_munis = n(),
    .groups = "drop"
  )

county_full <- county_analysis %>%
  left_join(county_sd, by = c("nuts3", "n_munis"))

write_csv(county_full, file.path(DATA_DIR, "county_analysis.csv"))
cat("Saved county_analysis.csv (", nrow(county_full), "counties)\n")
