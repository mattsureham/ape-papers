# 02_clean_data.R — Clean and merge all data into analysis panel
# apep_1131: The Hollow Safety Net

source("00_packages.R")

raw_dir <- "../data/raw"
out_dir <- "../data"

# State FIPS mapping
state_info <- tibble(
  state_fips = c("01","02","04","05","06","08","09","10","11","12","13",
                 "15","16","17","18","19","20","21","22","23","24","25",
                 "26","27","28","29","30","31","32","33","34","35","36",
                 "37","38","39","40","41","42","44","45","46","47","48",
                 "49","50","51","53","54","55","56"),
  state_abbrev = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                   "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                   "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                   "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                   "UT","VT","VA","WA","WV","WI","WY"),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                 "Connecticut","Delaware","District of Columbia","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky",
                 "Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota",
                 "Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire",
                 "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah",
                 "Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming")
)

# Census of Governments state code → FIPS
census_to_fips <- tibble(
  census_code = sprintf("%02d", 1:51),
  state_fips = c("01","02","04","05","06","08","09","10","11","12","13",
                 "15","16","17","18","19","20","21","22","23","24","25",
                 "26","27","28","29","30","31","32","33","34","35","36",
                 "37","38","39","40","41","42","44","45","46","47","48",
                 "49","50","51","53","54","55","56")
)

# ============================================================================
# A. Parse QWI industry employment — construct annual Bartik instrument
# ============================================================================
cat("=== Processing QWI data ===\n")
qwi <- read_csv(file.path(raw_dir, "qwi_industry_emp.csv"), show_col_types = FALSE)
qwi <- qwi %>%
  mutate(
    year = as.integer(str_extract(time, "^\\d{4}")),
    qtr  = as.integer(str_extract(time, "\\d$")),
    Emp  = as.numeric(Emp)
  ) %>%
  # QWI returns 'state' column with FIPS — ensure state_fips exists
  mutate(state_fips = coalesce(state_fips, state)) %>%
  select(-any_of("state")) %>%
  filter(!is.na(Emp), Emp > 0)

# Annual average employment by state × industry
qwi_annual <- qwi %>%
  group_by(state_fips, industry, year) %>%
  summarise(emp = mean(Emp, na.rm = TRUE), .groups = "drop")

# --- Bartik shares: 2006 industry employment shares ---
shares <- qwi_annual %>%
  filter(year == 2006) %>%
  group_by(state_fips) %>%
  mutate(
    total_emp_2006 = sum(emp),
    share = emp / total_emp_2006
  ) %>%
  ungroup() %>%
  select(state_fips, industry, share, total_emp_2006)

cat(sprintf("  Bartik shares: %d state-industry pairs\n", nrow(shares)))

# --- National (leave-one-out) industry employment growth ---
nat_ind_yr <- qwi_annual %>%
  group_by(industry, year) %>%
  summarise(nat_emp = sum(emp), .groups = "drop")

st_ind_yr <- qwi_annual %>%
  select(state_fips, industry, year, st_emp = emp)

# For each state-industry-year, compute LOO growth
growth_data <- st_ind_yr %>%
  inner_join(nat_ind_yr, by = c("industry", "year")) %>%
  mutate(loo_emp = nat_emp - st_emp) %>%
  arrange(state_fips, industry, year) %>%
  group_by(state_fips, industry) %>%
  mutate(loo_emp_lag = lag(loo_emp)) %>%
  ungroup() %>%
  filter(!is.na(loo_emp_lag), loo_emp_lag > 0) %>%
  mutate(g_loo = (loo_emp - loo_emp_lag) / loo_emp_lag)

# --- Bartik shock: weighted sum of LOO industry growth ---
bartik <- growth_data %>%
  inner_join(shares %>% select(state_fips, industry, share),
             by = c("state_fips", "industry")) %>%
  group_by(state_fips, year) %>%
  summarise(bartik_shock = sum(share * g_loo, na.rm = TRUE), .groups = "drop")

cat(sprintf("  Bartik shocks: %d state-year observations\n", nrow(bartik)))

# Total employment by state-year (from QWI)
total_emp <- qwi_annual %>%
  group_by(state_fips, year) %>%
  summarise(total_private_emp = sum(emp), .groups = "drop")

# ============================================================================
# B. Parse BTQ — First Payment Timeliness (annual, state × year)
# ============================================================================
cat("=== Processing BTQ timeliness ===\n")
btq_raw <- read_csv(file.path(raw_dir, "btq_raw.csv"), show_col_types = FALSE)
names(btq_raw) <- c("col1","workload","pct_7d","pct_14d","pct_21d",
                     "pct_28d","pct_35d","pct_42d","pct_49d","pct_56d",
                     "pct_63d","pct_70d","pct_gt70d","year")

# Identify data rows (col1 contains a date pattern mm/dd/yyyy)
btq_raw <- btq_raw %>%
  mutate(is_data = grepl("^\\d{2}/\\d{2}/\\d{4}", col1))

# State name rows: carry forward
btq_raw <- btq_raw %>%
  mutate(state_raw = ifelse(!is_data, str_extract(col1, "^[A-Za-z ]+"), NA_character_)) %>%
  mutate(state_raw = str_trim(str_remove(state_raw, "\\*.*"))) %>%
  fill(state_raw, .direction = "down") %>%
  filter(is_data)

# Parse percentages
parse_pct <- function(x) as.numeric(gsub("%", "", x))

btq <- btq_raw %>%
  mutate(
    date = as.Date(col1, "%m/%d/%Y"),
    workload_n = as.numeric(gsub(",", "", workload)),
    timeliness_14d = parse_pct(pct_14d),
    timeliness_21d = parse_pct(pct_21d),
    timeliness_7d  = parse_pct(pct_7d)
  ) %>%
  select(state_raw, year, date, workload_n, timeliness_7d, timeliness_14d, timeliness_21d)

# Map state names to FIPS
btq <- btq %>%
  left_join(state_info, by = c("state_raw" = "state_name")) %>%
  filter(!is.na(state_fips))

cat(sprintf("  BTQ: %d state-year observations, %d states, years %d-%d\n",
            nrow(btq), n_distinct(btq$state_fips), min(btq$year), max(btq$year)))
cat(sprintf("  Timeliness 14d range: %.1f%% to %.1f%%\n",
            min(btq$timeliness_14d, na.rm = TRUE), max(btq$timeliness_14d, na.rm = TRUE)))

# ============================================================================
# C. Parse ASPEP — State government FTE employment (2007)
# ============================================================================
cat("=== Processing ASPEP 2007 ===\n")

aspep_file <- file.path(raw_dir, "aspep_2007", "07state.dat")
aspep_lines <- readLines(aspep_file)

aspep_parsed <- tibble(raw = aspep_lines) %>%
  mutate(
    census_code = substr(raw, 1, 2),
    func_code   = str_trim(substr(raw, 18, 20)),
    # Split remaining by whitespace
    nums = str_trim(substr(raw, 21, nchar(raw)))
  ) %>%
  separate(nums, into = paste0("v", 1:6), sep = "\\s+", fill = "right",
           convert = TRUE) %>%
  # v1 = FTE employees, v2 = March payroll
  rename(fte_emp = v1, march_payroll = v2) %>%
  filter(func_code == "000") %>%  # Total government employment
  inner_join(census_to_fips, by = "census_code") %>%
  select(state_fips, govt_fte_2007 = fte_emp)

cat(sprintf("  ASPEP: %d states with total government FTE employment\n", nrow(aspep_parsed)))

# ============================================================================
# D. Parse ETA 539 — Weekly initial claims → aggregate to annual
# ============================================================================
cat("=== Processing ETA 539 claims ===\n")

eta539 <- fread(file.path(raw_dir, "eta539.csv"))
# c3 appears to be initial claims (based on magnitude check)
eta539 <- eta539 %>%
  as_tibble() %>%
  mutate(
    rptdate_parsed = as.Date(rptdate, "%m/%d/%Y"),
    year = year(rptdate_parsed),
    initial_claims = as.numeric(c3)
  ) %>%
  filter(year >= 2005, year <= 2012, !is.na(initial_claims)) %>%
  left_join(state_info %>% select(state_fips, state_abbrev), by = c("st" = "state_abbrev"))

# Validate magnitude: CA 2009 should have ~2-3M total annual initial claims
ca_2009 <- eta539 %>% filter(st == "CA", year == 2009) %>%
  summarise(total = sum(initial_claims, na.rm = TRUE))
cat(sprintf("  ETA 539 validation: CA 2009 total initial claims = %s\n",
            format(ca_2009$total, big.mark = ",")))

# Aggregate to annual
claims_annual <- eta539 %>%
  filter(!is.na(state_fips)) %>%
  group_by(state_fips, year) %>%
  summarise(
    annual_initial_claims = sum(initial_claims, na.rm = TRUE),
    weeks_reported = n(),
    .groups = "drop"
  )

cat(sprintf("  Claims: %d state-year observations\n", nrow(claims_annual)))

# ============================================================================
# E. Parse BEA — State personal income (control)
# ============================================================================
cat("=== Processing BEA income ===\n")

bea <- read_csv(file.path(raw_dir, "bea_state_income.csv"), show_col_types = FALSE)
bea_clean <- bea %>%
  filter(nchar(GeoFips) == 5, GeoFips != "00000") %>%
  mutate(
    state_fips = substr(GeoFips, 1, 2),
    year = as.integer(TimePeriod),
    personal_income_m = as.numeric(DataValue)
  ) %>%
  filter(!is.na(personal_income_m)) %>%
  select(state_fips, year, personal_income_m)

cat(sprintf("  BEA: %d state-year observations\n", nrow(bea_clean)))

# ============================================================================
# F. Merge into analysis panel
# ============================================================================
cat("=== Merging panel ===\n")

# Thinness measure: government FTE per 1000 private workers (2007 baseline)
baseline_emp <- total_emp %>% filter(year == 2007) %>%
  select(state_fips, priv_emp_2007 = total_private_emp)

thinness <- aspep_parsed %>%
  inner_join(baseline_emp, by = "state_fips") %>%
  mutate(
    staff_per_1000 = govt_fte_2007 / priv_emp_2007 * 1000,
    thinness = -staff_per_1000  # Higher = thinner (fewer staff)
  ) %>%
  select(state_fips, govt_fte_2007, priv_emp_2007, staff_per_1000, thinness)

# Claims per staff (capacity strain)
strain <- claims_annual %>%
  inner_join(aspep_parsed, by = "state_fips") %>%
  mutate(claims_per_staff = annual_initial_claims / govt_fte_2007)

# Main panel
panel <- btq %>%
  select(state_fips, year, timeliness_14d, timeliness_21d, timeliness_7d, workload_n) %>%
  left_join(bartik, by = c("state_fips", "year")) %>%
  left_join(total_emp, by = c("state_fips", "year")) %>%
  left_join(thinness, by = "state_fips") %>%
  left_join(strain %>% select(state_fips, year, annual_initial_claims, claims_per_staff),
            by = c("state_fips", "year")) %>%
  left_join(bea_clean, by = c("state_fips", "year")) %>%
  filter(!is.na(bartik_shock), !is.na(timeliness_14d), !is.na(staff_per_1000))

# Create key variables
panel <- panel %>%
  mutate(
    log_claims = log(annual_initial_claims + 1),
    log_income = log(personal_income_m + 1),
    bartik_x_thinness = bartik_shock * thinness,
    # Median split for heterogeneity
    thin_state = staff_per_1000 < median(staff_per_1000, na.rm = TRUE)
  )

cat(sprintf("  Panel: %d observations, %d states, %d years\n",
            nrow(panel), n_distinct(panel$state_fips), n_distinct(panel$year)))
cat(sprintf("  Timeliness 14d: mean=%.1f, sd=%.1f\n",
            mean(panel$timeliness_14d), sd(panel$timeliness_14d)))
cat(sprintf("  Bartik shock: mean=%.4f, sd=%.4f\n",
            mean(panel$bartik_shock), sd(panel$bartik_shock)))
cat(sprintf("  Staff per 1000: mean=%.1f, sd=%.1f\n",
            mean(panel$staff_per_1000, na.rm = TRUE), sd(panel$staff_per_1000, na.rm = TRUE)))

stopifnot("Panel has too few observations" = nrow(panel) >= 200)
stopifnot("Panel must have multiple states" = n_distinct(panel$state_fips) >= 40)
stopifnot("Panel must have pre and post recession" = min(panel$year) <= 2007 & max(panel$year) >= 2010)

write_csv(panel, file.path(out_dir, "analysis_panel.csv"))
cat(sprintf("  Saved: %s\n", file.path(out_dir, "analysis_panel.csv")))

# Also save the Bartik shares for Rotemberg weight analysis
write_csv(shares, file.path(out_dir, "bartik_shares.csv"))
write_csv(growth_data, file.path(out_dir, "industry_growth.csv"))

cat("\n=== Data cleaning complete ===\n")
