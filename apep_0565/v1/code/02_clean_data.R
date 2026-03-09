# ==============================================================================
# 02_clean_data.R — Data Cleaning and Variable Construction
# The Credential Cliff: Multi-Cutoff RDD on South Africa Matric Pass Levels
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"

# ==============================================================================
# 1. CLEAN WORLD BANK DATA
# ==============================================================================
cat("=== Cleaning World Bank data ===\n")

wb <- fread(file.path(data_dir, "wb_cross_country.csv"))

# Reshape to wide format (one column per indicator)
wb_wide <- wb %>%
  pivot_wider(
    id_cols = c(country_code, country_name, year),
    names_from = indicator_id,
    values_from = value
  ) %>%
  rename(
    tertiary_enroll = SE.TER.ENRR,
    secondary_enroll = SE.SEC.ENRR,
    sec_completion = SE.SEC.CMPT.LO.ZS,
    unemployment = SL.UEM.TOTL.ZS,
    youth_unemployment = SL.UEM.1524.ZS,
    lfp_rate = SL.TLF.ACTI.ZS,
    gdp_pc_ppp = NY.GDP.PCAP.PP.CD,
    educ_expenditure = SE.XPD.TOTL.GD.ZS,
    working_age_share = SP.POP.1564.TO.ZS,
    unemp_advanced = SL.UEM.ADVN.ZS
  ) %>%
  mutate(
    is_south_africa = country_code %in% c("ZAF", "ZA"),
    # Region classification
    region = case_when(
      country_code %in% c("ZAF", "ZA", "BWA", "BW", "NAM", "MUS", "MU", "KEN", "KE", "NGA", "NG", "GHA", "GH") ~ "Sub-Saharan Africa",
      country_code %in% c("BRA", "BR", "MEX", "MX", "COL", "CO", "PER", "PE", "CHL", "CL") ~ "Latin America",
      country_code %in% c("MYS", "MY", "THA", "TH", "IDN", "ID", "PHL", "PH") ~ "East/Southeast Asia",
      country_code %in% c("EGY", "EG", "MAR", "MA", "TUN", "TN", "TUR", "TR") ~ "MENA/Turkey",
      TRUE ~ "Other"
    ),
    # Income group (approximate using GDP per capita)
    income_group = case_when(
      gdp_pc_ppp > 20000 ~ "Upper middle",
      gdp_pc_ppp > 10000 ~ "Middle",
      gdp_pc_ppp > 5000 ~ "Lower middle",
      TRUE ~ "Low"
    )
  )

cat("World Bank panel:", nrow(wb_wide), "country-years,",
    n_distinct(wb_wide$country_code), "countries\n")
fwrite(wb_wide, file.path(data_dir, "wb_panel_clean.csv"))

# ==============================================================================
# 2. CLEAN NSC DATA — National and Provincial
# ==============================================================================
cat("\n=== Cleaning NSC data ===\n")

nsc <- fread(file.path(data_dir, "nsc_national.csv"))

# Create pass type shares in long format for plotting
nsc_long <- nsc %>%
  select(year, bachelors_rate, diploma_rate, higher_cert_rate, fail_rate) %>%
  pivot_longer(
    cols = -year,
    names_to = "pass_type",
    values_to = "share"
  ) %>%
  mutate(
    pass_type = case_when(
      pass_type == "bachelors_rate" ~ "Bachelor's Pass",
      pass_type == "diploma_rate" ~ "Diploma Pass",
      pass_type == "higher_cert_rate" ~ "Higher Certificate",
      pass_type == "fail_rate" ~ "Fail"
    ),
    pass_type = factor(pass_type,
                       levels = c("Fail", "Higher Certificate",
                                  "Diploma Pass", "Bachelor's Pass"))
  )

cat("NSC national long:", nrow(nsc_long), "rows\n")
fwrite(nsc_long, file.path(data_dir, "nsc_long.csv"))

# Province data
prov <- fread(file.path(data_dir, "province_nsc.csv"))

# Compute diploma rate (pass_rate - bachelors_rate approximation for HC+Dip)
prov <- prov %>%
  mutate(
    non_bachelors_pass_rate = pass_rate - bachelors_rate,
    province_short = case_when(
      province == "Eastern Cape" ~ "EC",
      province == "Free State" ~ "FS",
      province == "Gauteng" ~ "GP",
      province == "KwaZulu-Natal" ~ "KZN",
      province == "Limpopo" ~ "LP",
      province == "Mpumalanga" ~ "MP",
      province == "North West" ~ "NW",
      province == "Northern Cape" ~ "NC",
      province == "Western Cape" ~ "WC"
    )
  )

cat("Province data:", nrow(prov), "province-years\n")
fwrite(prov, file.path(data_dir, "province_nsc_clean.csv"))

# ==============================================================================
# 3. CLEAN QLFS EDUCATION-EMPLOYMENT DATA
# ==============================================================================
cat("\n=== Cleaning QLFS data ===\n")

qlfs <- fread(file.path(data_dir, "qlfs_education.csv"))

# Create education ordering
qlfs <- qlfs %>%
  mutate(
    educ_order = case_when(
      education == "No schooling" ~ 1,
      education == "Less than matric" ~ 2,
      education == "Matric (Grade 12)" ~ 3,
      education == "Certificate/Diploma" ~ 4,
      education == "Bachelor's degree" ~ 5,
      education == "Postgraduate degree" ~ 6
    ),
    education_short = case_when(
      education == "No schooling" ~ "None",
      education == "Less than matric" ~ "<Matric",
      education == "Matric (Grade 12)" ~ "Matric",
      education == "Certificate/Diploma" ~ "Cert/Dip",
      education == "Bachelor's degree" ~ "Bachelor's",
      education == "Postgraduate degree" ~ "Postgrad"
    ),
    education_short = factor(education_short,
                             levels = c("None", "<Matric", "Matric",
                                        "Cert/Dip", "Bachelor's", "Postgrad"))
  )

cat("QLFS clean:", nrow(qlfs), "education-year obs\n")
fwrite(qlfs, file.path(data_dir, "qlfs_clean.csv"))

# ==============================================================================
# 4. CLEAN PASS TYPE OUTCOMES
# ==============================================================================
cat("\n=== Cleaning pass type outcomes ===\n")

pto <- fread(file.path(data_dir, "pass_type_outcomes.csv"))

pto <- pto %>%
  mutate(
    credential_order = case_when(
      grepl("Higher Certificate", credential) ~ 1,
      grepl("Diploma-eligible", credential) ~ 2,
      grepl("Post-school", credential) ~ 3,
      grepl("University", credential) ~ 4
    ),
    credential_short = case_when(
      grepl("Higher Certificate", credential) ~ "HC Pass",
      grepl("Diploma-eligible", credential) ~ "Diploma Pass",
      grepl("Post-school", credential) ~ "Post-school Diploma",
      grepl("University", credential) ~ "University Degree"
    ),
    credential_short = factor(credential_short,
                              levels = c("HC Pass", "Diploma Pass",
                                         "Post-school Diploma", "University Degree")),
    # Log earnings
    log_earnings = log(median_earnings)
  )

cat("Pass type outcomes:", nrow(pto), "credential-year obs\n")
fwrite(pto, file.path(data_dir, "pass_type_clean.csv"))

# ==============================================================================
# 5. MERGE TERTIARY AND NSC DATA
# ==============================================================================
cat("\n=== Merging tertiary enrollment with NSC data ===\n")

tertiary <- fread(file.path(data_dir, "tertiary_enrollment.csv"))

nsc_tertiary <- nsc %>%
  filter(year >= 2010 & year <= 2021) %>%
  left_join(tertiary, by = "year") %>%
  mutate(
    # Transition rate: first-time UG as share of bachelor's passes (lagged)
    bachelors_lag1 = lag(bachelors_pass, 1),
    transition_rate = first_time_ug / (bachelors_lag1 / 1000) * 100,
    # TVET as share of non-bachelor's passes (lagged)
    non_bach_lag1 = lag(higher_cert_pass + diploma_pass, 1),
    tvet_rate = tvet_total / (non_bach_lag1 / 1000) * 100
  )

cat("NSC-tertiary merged:", nrow(nsc_tertiary), "years\n")
fwrite(nsc_tertiary, file.path(data_dir, "nsc_tertiary_merged.csv"))

# ==============================================================================
# 6. SOUTH AFRICA SPOTLIGHT — Key statistics
# ==============================================================================
cat("\n=== Computing South Africa summary statistics ===\n")

za_wb <- wb_wide %>% filter(country_code == "ZAF")

# Latest available stats
za_latest <- za_wb %>%
  filter(year == max(year[!is.na(unemployment)])) %>%
  select(year, unemployment, youth_unemployment, tertiary_enroll,
         gdp_pc_ppp, lfp_rate)

cat("\nSouth Africa latest statistics:\n")
print(za_latest)

# Cross-country ranking
za_rank <- wb_wide %>%
  filter(year == 2022 | year == 2021) %>%
  group_by(country_code) %>%
  slice_max(year) %>%
  ungroup() %>%
  mutate(
    unemp_rank = rank(-unemployment, na.last = "keep"),
    youth_unemp_rank = rank(-youth_unemployment, na.last = "keep"),
    tertiary_rank = rank(-tertiary_enroll, na.last = "keep")
  ) %>%
  filter(country_code == "ZAF")

cat("\nSouth Africa cross-country ranking (among 20 comparators):\n")
cat("  Unemployment rank:", za_rank$unemp_rank, "(highest = 1)\n")
cat("  Youth unemployment rank:", za_rank$youth_unemp_rank, "\n")
cat("  Tertiary enrollment rank:", za_rank$tertiary_rank, "\n")

# Save summary stats
fwrite(za_wb, file.path(data_dir, "za_wb_timeseries.csv"))

cat("\n=== Data cleaning complete ===\n")
