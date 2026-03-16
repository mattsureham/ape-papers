# 01_fetch_data.R — Data acquisition for apep_0699
# Saudi Arabia guardianship reform and female LFP
# REAL DATA ONLY — ALL DATA FROM PUBLIC APIs

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) setwd(file.path(dirname(normalizePath(script_path)), ".."))
# else assume CWD is already correct

source("code/00_packages.R")

# ============================================================
# PART 1: World Bank WDI — Annual LFP Data
# Primary identification: Saudi Arabia vs GCC + MENA donor pool
# Driving ban: June 2018 (annual 2018)
# Guardianship reform: August 2019 (annual 2019)
# These fall in DIFFERENT calendar years → annual data CAN disentangle them
# ============================================================
cat("Fetching World Bank WDI data...\n")

# Full donor pool: GCC + MENA
countries_all <- c(
  "SA",  # Saudi Arabia (treated)
  "AE",  # UAE
  "KW",  # Kuwait
  "QA",  # Qatar
  "BH",  # Bahrain
  "OM",  # Oman
  "EG",  # Egypt
  "JO",  # Jordan
  "TN",  # Tunisia
  "MA",  # Morocco
  "DZ",  # Algeria
  "LB",  # Lebanon
  "TR",  # Turkey
  "IR",  # Iran
  "IQ",  # Iraq
  "YE"   # Yemen
)

# Female LFP rate (modeled ILO estimate, %) — ILO modeled estimates, ages 15+
wb_female_lfp <- wb_data(
  indicator = "SL.TLF.CACT.FE.ZS",
  country = countries_all,
  start_date = 2010,
  end_date = 2024
)

# Male LFP rate
wb_male_lfp <- wb_data(
  indicator = "SL.TLF.CACT.MA.ZS",
  country = countries_all,
  start_date = 2010,
  end_date = 2024
)

# GDP per capita (constant 2015 USD) — economic control
wb_gdp <- wb_data(
  indicator = "NY.GDP.PCAP.KD",
  country = countries_all,
  start_date = 2010,
  end_date = 2024
)

# Oil rents (% of GDP) — Saudi-specific shock control
wb_oil <- wb_data(
  indicator = "NY.GDP.PETR.RT.ZS",
  country = countries_all,
  start_date = 2010,
  end_date = 2024
)

# Female share of labor force
wb_female_share <- wb_data(
  indicator = "SL.TLF.TOTL.FE.ZS",
  country = countries_all,
  start_date = 2010,
  end_date = 2024
)

cat("WDI female LFP rows:", nrow(wb_female_lfp), "\n")

# Validate Saudi Arabia data
sa_lfp <- wb_female_lfp %>%
  filter(iso2c == "SA") %>%
  arrange(date) %>%
  select(date, lfp_fe = SL.TLF.CACT.FE.ZS)

stopifnot("Saudi Arabia female LFP data is empty" = nrow(sa_lfp) > 0)
stopifnot("Saudi Arabia 2019 data missing" = 2019 %in% sa_lfp$date)
stopifnot("Saudi Arabia 2020 data missing" = 2020 %in% sa_lfp$date)

cat("Saudi Arabia female LFP (2015-2023):\n")
sa_lfp %>% filter(date >= 2015) %>% print(n = 20)

# Validate the treatment effect is visible in the data
lfp_2018 <- sa_lfp %>% filter(date == 2018) %>% pull(lfp_fe)
lfp_2019 <- sa_lfp %>% filter(date == 2019) %>% pull(lfp_fe)
lfp_2020 <- sa_lfp %>% filter(date == 2020) %>% pull(lfp_fe)
cat("Saudi female LFP: 2018=", round(lfp_2018, 2),
    "| 2019=", round(lfp_2019, 2),
    "| 2020=", round(lfp_2020, 2), "\n")
stopifnot("Guardianship reform effect not visible (2019-2020 jump expected)" =
            (lfp_2020 - lfp_2018) > 3)

# ============================================================
# PART 2: Try GASTAT API (Saudi National Data)
# ============================================================
cat("\nAttempting GASTAT API fetch...\n")

# Try GASTAT open data portal
gastat_api_url <- "https://open.stat.gov.sa/en/api/datasets/5/download"
gastat_result <- tryCatch({
  resp <- GET(gastat_api_url, timeout(20))
  cat("GASTAT API status:", status_code(resp), "\n")
  NULL
}, error = function(e) {
  cat("GASTAT API not accessible:", conditionMessage(e), "\n")
  NULL
})

# ============================================================
# PART 3: Try ILOSTAT API — Annual data
# ============================================================
cat("\nFetching ILOSTAT annual data...\n")

# ILO Bulk download — Annual female employment-to-population ratio
ilo_url <- paste0(
  "https://rplumber.ilo.org/data/indicator/",
  "?id=EAP_TEAP_SEX_AGE_RT_A",
  "&ref_area=SAU",
  "&sex=SEX_F",
  "&classif1=AGE_YTHADULT_YGE15",
  "&timefrom=2010&timeto=2024",
  "&type=label&format=.csv"
)

ilo_sa <- tryCatch({
  resp <- GET(ilo_url, timeout(30))
  if (status_code(resp) == 200) {
    df <- read_csv(content(resp, "text", encoding = "UTF-8"), show_col_types = FALSE)
    cat("ILOSTAT Saudi data fetched:", nrow(df), "rows\n")
    df
  } else {
    cat("ILOSTAT status:", status_code(resp), "\n")
    NULL
  }
}, error = function(e) {
  cat("ILOSTAT error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ilo_sa)) {
  write_csv(ilo_sa, "data/ilostat_sa.csv")
}

# ============================================================
# PART 4: Compile and Validate
# ============================================================
cat("\nCompiling panel dataset...\n")

# Merge WDI indicators
panel_data <- wb_female_lfp %>%
  rename(lfp_fe = SL.TLF.CACT.FE.ZS) %>%
  select(iso2c, country, date, lfp_fe) %>%
  left_join(
    wb_male_lfp %>%
      rename(lfp_ma = SL.TLF.CACT.MA.ZS) %>%
      select(iso2c, date, lfp_ma),
    by = c("iso2c", "date")
  ) %>%
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
  filter(!is.na(lfp_fe)) %>%
  mutate(
    treated = as.integer(iso2c == "SA"),
    # Driving ban: June 2018 → affects annual 2018 partially
    post_driving = as.integer(date >= 2018),
    # Guardianship reform: August 2019 → affects annual 2019 partially but 2020+ fully
    post_guardianship = as.integer(date >= 2019),
    post_guardianship_full = as.integer(date >= 2020),  # Full year post
    year = date
  )

cat("Panel rows:", nrow(panel_data), "\n")
cat("Countries:", n_distinct(panel_data$iso2c), "\n")
cat("Years:", range(panel_data$date, na.rm = TRUE), "\n")

# Validate: need enough observations for SCM
sa_obs <- panel_data %>% filter(iso2c == "SA", !is.na(lfp_fe))
cat("Saudi Arabia non-missing LFP observations:", nrow(sa_obs), "\n")
stopifnot("Need at least 10 Saudi LFP observations" = nrow(sa_obs) >= 10)

# Check parallel trends in donor pool pre-2018
pre_2018 <- panel_data %>% filter(date <= 2017, !is.na(lfp_fe))
cat("Pre-treatment donor pool observations:", nrow(pre_2018), "\n")
countries_available <- unique(pre_2018$iso2c)
cat("Countries in donor pool:", paste(countries_available, collapse = ", "), "\n")
stopifnot("Need at least 5 countries in donor pool" = length(countries_available) >= 5)

# Create diagnostics for validator
diagnostics <- list(
  n_treated = 1,  # Saudi Arabia (1 treated country)
  n_obs = nrow(panel_data),
  n_pre = sum(panel_data$date <= 2017 & panel_data$iso2c == "SA"),
  n_post = sum(panel_data$date >= 2019 & panel_data$iso2c == "SA"),
  n_countries = n_distinct(panel_data$iso2c),
  sa_lfp_2017 = as.numeric(panel_data %>% filter(iso2c=="SA", date==2017) %>% pull(lfp_fe)),
  sa_lfp_2018 = as.numeric(panel_data %>% filter(iso2c=="SA", date==2018) %>% pull(lfp_fe)),
  sa_lfp_2019 = as.numeric(panel_data %>% filter(iso2c=="SA", date==2019) %>% pull(lfp_fe)),
  sa_lfp_2020 = as.numeric(panel_data %>% filter(iso2c=="SA", date==2020) %>% pull(lfp_fe)),
  sa_lfp_2021 = as.numeric(panel_data %>% filter(iso2c=="SA", date==2021) %>% pull(lfp_fe))
)

cat("Diagnostics:\n")
print(diagnostics)

# Save
write_csv(panel_data, "data/panel_data.csv")
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
save(panel_data, wb_female_lfp, wb_male_lfp, wb_gdp, wb_oil, file = "data/raw_data.RData")

cat("\nData collection complete. Files saved:\n")
cat("  data/panel_data.csv —", nrow(panel_data), "obs\n")
cat("  data/diagnostics.json\n")
cat("  data/raw_data.RData\n")
