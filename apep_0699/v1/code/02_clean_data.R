# 02_clean_data.R — Data cleaning for apep_0699
# Saudi Arabia guardianship reform and female LFP

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) setwd(file.path(dirname(normalizePath(script_path)), ".."))

source("code/00_packages.R")
load("data/raw_data.RData")

# ============================================================
# CONSTRUCT LONG PANEL: country × gender × year
# ============================================================
cat("Constructing long panel...\n")

# Female LFP panel
female_panel <- wb_female_lfp %>%
  rename(lfp = SL.TLF.CACT.FE.ZS) %>%
  select(iso2c, country, date, lfp) %>%
  filter(!is.na(lfp)) %>%
  mutate(gender = "female")

# Male LFP panel
male_panel <- wb_male_lfp %>%
  rename(lfp = SL.TLF.CACT.MA.ZS) %>%
  select(iso2c, country, date, lfp) %>%
  filter(!is.na(lfp)) %>%
  mutate(gender = "male")

# Stack gender × country × year
long_panel <- bind_rows(female_panel, male_panel) %>%
  left_join(
    wb_gdp %>%
      rename(gdp_pc = NY.GDP.PCAP.KD) %>%
      select(iso2c, date, gdp_pc),
    by = c("iso2c", "date")
  ) %>%
  left_join(
    wb_oil %>%
      rename(oil_rents = NY.GDP.PETR.RT.ZS) %>%
      select(iso2c, date, oil_rents),
    by = c("iso2c", "date")
  ) %>%
  mutate(
    year = date,
    is_saudi = as.integer(iso2c == "SA"),
    is_female = as.integer(gender == "female"),

    # Reform indicators
    # Driving ban: June 2018 (affects 2018 annual data)
    post_driving = as.integer(year >= 2018),
    # Guardianship reform: August 2019
    post_guard = as.integer(year >= 2019),
    # First full calendar year post-guardianship: 2020
    post_guard_full = as.integer(year >= 2020),

    # Treatment interactions for DDD
    treated_guard = is_saudi * is_female * post_guard,
    treated_guard_full = is_saudi * is_female * post_guard_full,
    treated_driving = is_saudi * is_female * post_driving,
    saudi_female = is_saudi * is_female,
    saudi_post_guard = is_saudi * post_guard,
    female_post_guard = is_female * post_guard,

    # Year relative to guardianship reform
    rel_year_guard = year - 2019,
    rel_year_drive = year - 2018,

    # Country-gender ID for fixed effects
    country_gender = paste(iso2c, gender, sep = "_"),

    # Log GDP (control)
    log_gdp = log(gdp_pc + 1)
  )

cat("Long panel rows:", nrow(long_panel), "\n")
cat("Countries:", n_distinct(long_panel$iso2c), "\n")
cat("Years:", paste(range(long_panel$year, na.rm = TRUE), collapse = "-"), "\n")
cat("Saudi female observations:", nrow(long_panel %>% filter(iso2c=="SA", gender=="female")), "\n")

# ============================================================
# COUNTRY-LEVEL FEMALE LFP PANEL (for SCM)
# ============================================================
female_panel_wide <- female_panel %>%
  filter(!is.na(lfp)) %>%
  rename(year = date) %>%
  left_join(
    wb_gdp %>% rename(gdp_pc = NY.GDP.PCAP.KD, year = date) %>%
      select(iso2c, year, gdp_pc),
    by = c("iso2c", "year")
  ) %>%
  left_join(
    wb_oil %>% rename(oil_rents = NY.GDP.PETR.RT.ZS, year = date) %>%
      select(iso2c, year, oil_rents),
    by = c("iso2c", "year")
  ) %>%
  mutate(
    is_saudi = as.integer(iso2c == "SA"),
    post_guard = as.integer(year >= 2019),
    post_driving = as.integer(year >= 2018),
    rel_year = year - 2019
  )

cat("Female panel (for SCM):", nrow(female_panel_wide), "rows\n")

# Validate: Saudi Arabia LFP trend
sa_female <- female_panel_wide %>%
  filter(iso2c == "SA") %>%
  arrange(year) %>%
  select(year, lfp, is_saudi, post_guard)

cat("\nSaudi Arabia female LFP:\n")
print(sa_female, n = 20)

# Key effect check
lfp_2017 <- sa_female %>% filter(year == 2017) %>% pull(lfp)
lfp_2018 <- sa_female %>% filter(year == 2018) %>% pull(lfp)
lfp_2019 <- sa_female %>% filter(year == 2019) %>% pull(lfp)
lfp_2020 <- sa_female %>% filter(year == 2020) %>% pull(lfp)
lfp_2021 <- sa_female %>% filter(year == 2021) %>% pull(lfp)

driving_effect_raw <- lfp_2018 - lfp_2017
guard_effect_raw <- lfp_2020 - lfp_2018  # Full year effect vs pre-reform
total_increase <- lfp_2021 - lfp_2017

cat("\nRaw effects (Saudi Arabia):\n")
cat("  Driving ban (2018-2017):", round(driving_effect_raw, 2), "pp\n")
cat("  Guardianship (2020-2018):", round(guard_effect_raw, 2), "pp\n")
cat("  Total 2017-2021:", round(total_increase, 2), "pp\n")

# ============================================================
# DONOR POOL CONSTRUCTION
# All non-SA countries with complete pre-treatment data
# ============================================================
pre_period <- female_panel_wide %>%
  filter(year >= 2010, year <= 2017)

# Countries with complete pre-period data
complete_donors <- pre_period %>%
  group_by(iso2c) %>%
  summarise(n_obs = n(), n_lfp = sum(!is.na(lfp)), .groups = "drop") %>%
  filter(iso2c != "SA", n_lfp >= 6)  # At least 6 of 8 pre-years

cat("\nDonor pool countries:", nrow(complete_donors), "\n")
cat(paste(complete_donors$iso2c, collapse = ", "), "\n")

donor_countries <- complete_donors$iso2c

# ============================================================
# SAVE CLEANED DATA
# ============================================================
save(long_panel, female_panel_wide, donor_countries,
     lfp_2017, lfp_2018, lfp_2019, lfp_2020, lfp_2021,
     driving_effect_raw, guard_effect_raw, total_increase,
     file = "data/cleaned_data.RData")

write_csv(long_panel, "data/long_panel.csv")
write_csv(female_panel_wide, "data/female_panel.csv")

cat("\nCleaning complete. Files saved.\n")
