## 02_clean_data.R — Construct analysis dataset for YEI RDD
## apep_0723: EU Youth Employment Initiative RDD

source("00_packages.R")

# ============================================================
# EU-27 MEMBER STATE CODES
# Used to exclude EFTA/candidate countries (NO, IS, CH, ME, RS, etc.)
# ============================================================

eu27_codes <- c(
  "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
  "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
  "NL", "PL", "PT", "RO", "SE", "SI", "SK"
)

# ============================================================
# HELPER: Extract NUTS2 regions (geo code length 4)
# and filter to EU member states only
# ============================================================

is_nuts2_eu <- function(geo_vec) {
  # NUTS2 codes are exactly 4 characters
  is_n2 <- nchar(as.character(geo_vec)) == 4
  # Country prefix is first 2 characters
  country <- substr(as.character(geo_vec), 1, 2)
  is_n2 & (country %in% eu27_codes)
}

# ============================================================
# 1. RUNNING VARIABLE: 2012 YOUTH UNEMPLOYMENT RATE
#    Source: yth_empl_110, ages 15-24, total sex
# ============================================================

cat("Loading raw data...\n")
yth_unemp_raw <- readRDS("../data/yth_unemp_raw.rds")
neet_raw       <- readRDS("../data/neet_raw.rds")
emp_rate_raw   <- readRDS("../data/emp_rate_raw.rds")
esl_raw        <- readRDS("../data/esl_raw.rds")

cat(sprintf("Youth unemployment columns: %s\n", paste(names(yth_unemp_raw), collapse=", ")))

# Filter to NUTS2, EU27, total sex, 2012
# Typical columns: unit, sex, age, geo, time, values
unemp_2012 <- yth_unemp_raw %>%
  filter(
    is_nuts2_eu(geo),
    TIME_PERIOD == 2012
  ) %>%
  # Keep total sex (T or TT), any age group matching 15-24
  # Filter out breakdown by sex if sex column exists
  { if ("sex" %in% names(.)) filter(., sex %in% c("T", "TT")) else . } %>%
  # If age column exists, keep Y15-24 or equivalent
  { if ("age" %in% names(.)) filter(., age %in% c("Y15-24", "Y_LT25", "TOTAL")) else . } %>%
  # If unit column exists, keep percentage
  { if ("unit" %in% names(.)) filter(., unit %in% c("PC", "PC_ACT", "PC_UNE")) else . } %>%
  group_by(geo) %>%
  summarise(unemp_2012 = mean(values, na.rm = TRUE), .groups = "drop") %>%
  filter(!is.na(unemp_2012)) %>%
  mutate(country = substr(geo, 1, 2))

cat(sprintf("\n2012 youth unemployment: %d NUTS2 regions\n", nrow(unemp_2012)))
cat(sprintf("Countries represented: %s\n",
            paste(sort(unique(unemp_2012$country)), collapse=", ")))
cat(sprintf("Unemployment range: %.1f%% to %.1f%%\n",
            min(unemp_2012$unemp_2012), max(unemp_2012$unemp_2012)))

if (nrow(unemp_2012) < 100) {
  cat("WARNING: Fewer than 100 NUTS2 regions found for 2012 unemployment.\n")
  cat("Check column filters — trying alternative filter combinations...\n")
  # Broader fallback: take the modal available breakdown
  unemp_2012_broad <- yth_unemp_raw %>%
    filter(is_nuts2_eu(geo), TIME_PERIOD == 2012, !is.na(values)) %>%
    group_by(geo) %>%
    summarise(unemp_2012 = mean(values, na.rm = TRUE), .groups = "drop") %>%
    mutate(country = substr(geo, 1, 2))
  cat(sprintf("Broad filter: %d regions\n", nrow(unemp_2012_broad)))
  unemp_2012 <- unemp_2012_broad
}

if (nrow(unemp_2012) == 0) {
  stop("FATAL: Could not construct 2012 youth unemployment running variable")
}

# ============================================================
# 2. PRIMARY OUTCOME: NEET RATE
#    Change: avg(2016-2019) - avg(2010-2012)
# ============================================================

cat("\nConstructing NEET outcome...\n")
cat(sprintf("NEET columns: %s\n", paste(names(neet_raw), collapse=", ")))

neet_panel <- neet_raw %>%
  filter(
    is_nuts2_eu(geo),
    !is.na(values)
  ) %>%
  # Keep total sex, ages 18-24
  { if ("sex" %in% names(.)) filter(., sex %in% c("T", "TT")) else . } %>%
  { if ("age" %in% names(.)) filter(., age %in% c("Y18-24", "Y_LT25", "TOTAL")) else . } %>%
  group_by(geo, TIME_PERIOD) %>%
  summarise(neet_rate = mean(values, na.rm = TRUE), .groups = "drop") %>%
  mutate(country = substr(geo, 1, 2))

# Pre-YEI: 2010-2012 average; Post-YEI: 2016-2019 average
neet_pre <- neet_panel %>%
  filter(TIME_PERIOD %in% 2010:2012) %>%
  group_by(geo, country) %>%
  summarise(neet_pre = mean(neet_rate, na.rm = TRUE), n_pre = n(), .groups = "drop")

neet_post <- neet_panel %>%
  filter(TIME_PERIOD %in% 2016:2019) %>%
  group_by(geo, country) %>%
  summarise(neet_post = mean(neet_rate, na.rm = TRUE), n_post = n(), .groups = "drop")

neet_change <- neet_pre %>%
  inner_join(neet_post, by = c("geo", "country")) %>%
  mutate(d_neet = neet_post - neet_pre)

cat(sprintf("NEET change obs (pre+post non-missing): %d regions\n", nrow(neet_change)))

# Also keep NEET by year for event study table
neet_yearly <- neet_panel %>%
  filter(TIME_PERIOD >= 2008, TIME_PERIOD <= 2022)

# ============================================================
# 3. SECONDARY OUTCOME: YOUTH EMPLOYMENT RATE
#    lfst_r_lfe2emprt — ages 15-24
# ============================================================

cat("\nConstructing youth employment rate outcome...\n")
cat(sprintf("Employment rate columns: %s\n", paste(names(emp_rate_raw), collapse=", ")))

emp_panel <- emp_rate_raw %>%
  filter(
    is_nuts2_eu(geo),
    !is.na(values)
  ) %>%
  { if ("sex" %in% names(.)) filter(., sex %in% c("T", "TT")) else . } %>%
  { if ("age" %in% names(.)) filter(., age %in% c("Y15-24", "Y_LT25")) else . } %>%
  group_by(geo, TIME_PERIOD) %>%
  summarise(emp_rate = mean(values, na.rm = TRUE), .groups = "drop") %>%
  mutate(country = substr(geo, 1, 2))

emp_pre <- emp_panel %>%
  filter(TIME_PERIOD %in% 2010:2012) %>%
  group_by(geo, country) %>%
  summarise(emp_pre = mean(emp_rate, na.rm = TRUE), .groups = "drop")

emp_post <- emp_panel %>%
  filter(TIME_PERIOD %in% 2016:2019) %>%
  group_by(geo, country) %>%
  summarise(emp_post = mean(emp_rate, na.rm = TRUE), .groups = "drop")

emp_change <- emp_pre %>%
  inner_join(emp_post, by = c("geo", "country")) %>%
  mutate(d_emp = emp_post - emp_pre)

cat(sprintf("Employment rate change obs: %d regions\n", nrow(emp_change)))

# ============================================================
# 4. SECONDARY OUTCOME: EARLY SCHOOL LEAVING
# ============================================================

cat("\nConstructing early school leaving outcome...\n")
cat(sprintf("ESL columns: %s\n", paste(names(esl_raw), collapse=", ")))

esl_panel <- esl_raw %>%
  filter(
    is_nuts2_eu(geo),
    !is.na(values)
  ) %>%
  { if ("sex" %in% names(.)) filter(., sex %in% c("T", "TT")) else . } %>%
  group_by(geo, TIME_PERIOD) %>%
  summarise(esl_rate = mean(values, na.rm = TRUE), .groups = "drop") %>%
  mutate(country = substr(geo, 1, 2))

esl_pre <- esl_panel %>%
  filter(TIME_PERIOD %in% 2010:2012) %>%
  group_by(geo, country) %>%
  summarise(esl_pre = mean(esl_rate, na.rm = TRUE), .groups = "drop")

esl_post <- esl_panel %>%
  filter(TIME_PERIOD %in% 2016:2019) %>%
  group_by(geo, country) %>%
  summarise(esl_post = mean(esl_rate, na.rm = TRUE), .groups = "drop")

esl_change <- esl_pre %>%
  inner_join(esl_post, by = c("geo", "country")) %>%
  mutate(d_esl = esl_post - esl_pre)

cat(sprintf("Early school leaving change obs: %d regions\n", nrow(esl_change)))

# ============================================================
# 5. ASSEMBLE ANALYSIS DATASET
# ============================================================

cat("\nAssembling analysis dataset...\n")

analysis <- unemp_2012 %>%
  # Join NEET change (primary outcome)
  left_join(neet_change %>% select(geo, neet_pre, neet_post, d_neet), by = "geo") %>%
  # Join employment rate change (secondary outcome)
  left_join(emp_change %>% select(geo, emp_pre, emp_post, d_emp), by = "geo") %>%
  # Join early school leaving change (secondary outcome)
  left_join(esl_change %>% select(geo, esl_pre, esl_post, d_esl), by = "geo") %>%
  # Centered running variable: unemployment - 25pp threshold
  mutate(
    rv = unemp_2012 - 25,            # running variable centered at 0
    treated = as.integer(unemp_2012 >= 25),  # YEI eligibility
    country = substr(geo, 1, 2)
  )

cat(sprintf("Pre-filter rows: %d\n", nrow(analysis)))
cat(sprintf("Treated (unemp >= 25%%): %d regions\n", sum(analysis$treated, na.rm=TRUE)))
cat(sprintf("Control (unemp < 25%%): %d regions\n", sum(analysis$treated == 0, na.rm=TRUE)))

# ============================================================
# 6. APPLY SAMPLE RESTRICTIONS
# ============================================================

# Keep only EU27 regions with non-missing running variable and primary outcome
analysis_clean <- analysis %>%
  filter(!is.na(unemp_2012)) %>%
  filter(!is.na(d_neet)) %>%
  filter(country %in% eu27_codes)

cat(sprintf("\nFinal sample: %d NUTS2 regions (after dropping missing)\n", nrow(analysis_clean)))
cat(sprintf("Treated: %d | Control: %d\n",
            sum(analysis_clean$treated), sum(analysis_clean$treated == 0)))
cat(sprintf("Countries: %d\n", length(unique(analysis_clean$country))))

# Regions near threshold
cat(sprintf("Regions within 5pp of threshold: %d\n",
            sum(abs(analysis_clean$rv) <= 5)))
cat(sprintf("Regions within 10pp of threshold: %d\n",
            sum(abs(analysis_clean$rv) <= 10)))

if (nrow(analysis_clean) < 30) {
  stop("FATAL: Fewer than 30 NUTS2 regions in analysis sample — check data filters")
}

# ============================================================
# 7. YEAR-BY-YEAR NEET PANEL FOR EVENT STUDY TABLE
# ============================================================

# Create a region-year panel merging running variable with NEET by year
neet_yearly_analysis <- neet_yearly %>%
  inner_join(unemp_2012 %>% select(geo, unemp_2012, country), by = "geo") %>%
  mutate(
    rv = unemp_2012 - 25,
    treated = as.integer(unemp_2012 >= 25)
  ) %>%
  mutate(country = substr(geo, 1, 2)) %>%
  filter(!is.na(neet_rate), country %in% eu27_codes)

cat(sprintf("\nYearly panel: %d region-year obs\n", nrow(neet_yearly_analysis)))

# ============================================================
# 8. SOUTHERN EUROPE FLAG FOR HETEROGENEITY
# ============================================================

# Southern Europe: IT, ES, EL (Greece), PT — countries that drove YEI adoption
# Non-Southern: all other EU27 members
southern_europe <- c("IT", "ES", "EL", "PT")

analysis_clean <- analysis_clean %>%
  mutate(
    southern = as.integer(country %in% southern_europe),
    region_label = geo
  )

neet_yearly_analysis <- neet_yearly_analysis %>%
  mutate(southern = as.integer(country %in% southern_europe))

# ============================================================
# 9. SAVE
# ============================================================

saveRDS(analysis_clean, "../data/analysis_clean.rds")
saveRDS(neet_yearly_analysis, "../data/neet_yearly.rds")

cat("\nData cleaning complete.\n")
cat(sprintf("Analysis dataset: %d regions, %d countries\n",
            nrow(analysis_clean), length(unique(analysis_clean$country))))
cat(sprintf("Treated (>= 25%% unemployment): %d regions\n", sum(analysis_clean$treated)))
cat(sprintf("Control (< 25%% unemployment): %d regions\n", sum(analysis_clean$treated == 0)))
cat(sprintf("Missing d_emp: %d regions\n", sum(is.na(analysis_clean$d_emp))))
cat(sprintf("Missing d_esl: %d regions\n", sum(is.na(analysis_clean$d_esl))))
