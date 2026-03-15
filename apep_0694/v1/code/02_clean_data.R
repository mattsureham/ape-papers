## 02_clean_data.R — Clean ABS building approvals for HomeBuilder analysis
## apep_0694: HomeBuilder Net Additionality

source("00_packages.R")

# ------------------------------------------------------------------
# 1. Load raw ABS data
# ------------------------------------------------------------------
abs <- fread("../data/abs_building_approvals.csv")
cat(sprintf("Raw ABS data: %d rows\n", nrow(abs)))

# ------------------------------------------------------------------
# 2. Filter to dwelling approvals (number, not value)
# ------------------------------------------------------------------
# MEASURE: 1 = number, 2 = value, 3 = ???
# BUILDING_TYPE: 110 = new houses, 850 = other residential (apartments etc.)
# TSEST: 10 = original, 20 = seasonally adjusted, 30 = trend
# SECTOR: TOT = total (private + public)
# WORK_TYPE: TOT = total (new work)

cat("Filtering to dwelling counts...\n")

# Get number of dwelling approvals (MEASURE=1), original series (TSEST=10)
# SECTOR: 9 = total (private + public)
# WORK_TYPE: TOT = total (new + alterations)
# VALUE: 1-7 are value bands — need to sum across them
dwellings <- abs %>%
  as_tibble() %>%
  filter(
    MEASURE == 1,        # Number of approvals (not value)
    TSEST == 10,         # Original (not seasonally adjusted)
    BUILDING_TYPE %in% c("110", "850", "TOT"),  # Houses, other res, total
    SECTOR == 9,         # Total (private + public)
    WORK_TYPE == "TOT",  # Total (new + alterations)
    FREQ == "M"          # Monthly
  ) %>%
  # Sum across VALUE bands to get total approvals
  group_by(BUILDING_TYPE, REGION, TIME_PERIOD) %>%
  summarise(
    OBS_VALUE = sum(as.numeric(OBS_VALUE), na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("After filtering: %d rows\n", nrow(dwellings)))

# ------------------------------------------------------------------
# 3. Parse time period and create date
# ------------------------------------------------------------------
dwellings <- dwellings %>%
  mutate(
    date = as.Date(paste0(TIME_PERIOD, "-01")),
    year = year(date),
    month = month(date),
    approvals = as.numeric(OBS_VALUE),
    # Region labels
    region_type = case_when(
      REGION == "AUS" ~ "national",
      nchar(REGION) == 1 ~ "state",
      grepl("^[0-9]G", REGION) ~ "gccsa_capital",
      grepl("^[0-9]R", REGION) ~ "gccsa_rest",
      REGION == "8ACTE" ~ "gccsa_capital",
      TRUE ~ "other"
    ),
    dwelling_type = case_when(
      BUILDING_TYPE == "110" ~ "houses",
      BUILDING_TYPE == "850" ~ "other_residential",
      BUILDING_TYPE == "TOT" ~ "total",
      TRUE ~ "other"
    ),
    # State mapping
    state = case_when(
      REGION %in% c("1", "1GSYD", "1RNSW") ~ "NSW",
      REGION %in% c("2", "2GMEL", "2RVIC") ~ "VIC",
      REGION %in% c("3", "3GBRI", "3RQLD") ~ "QLD",
      REGION %in% c("4", "4GADE", "4RSAU") ~ "SA",
      REGION %in% c("5", "5GPER", "5RWAU") ~ "WA",
      REGION %in% c("6", "6GHOB", "6RTAS") ~ "TAS",
      REGION %in% c("7", "7GDAR", "7RNTE") ~ "NT",
      REGION %in% c("8", "8ACTE") ~ "ACT",
      REGION == "AUS" ~ "AUS",
      TRUE ~ "Other"
    )
  )

# ------------------------------------------------------------------
# 4. Create national time series for ITS
# ------------------------------------------------------------------
national <- dwellings %>%
  filter(REGION == "AUS") %>%
  select(date, year, month, dwelling_type, approvals) %>%
  pivot_wider(names_from = dwelling_type, values_from = approvals) %>%
  arrange(date) %>%
  mutate(
    # Time index (months since Jan 2016)
    t = as.numeric(difftime(date, as.Date("2016-01-01"), units = "days")) / 30.44,
    # Program indicators
    homebuilder_full = ifelse(date >= "2020-06-01" & date <= "2020-12-01", 1L, 0L),
    homebuilder_reduced = ifelse(date >= "2021-01-01" & date <= "2021-03-01", 1L, 0L),
    homebuilder_any = ifelse(homebuilder_full == 1 | homebuilder_reduced == 1, 1L, 0L),
    post_program = ifelse(date >= "2021-04-01", 1L, 0L),
    # Time since program end (for hangover analysis)
    months_post = pmax(0, as.numeric(difftime(date, as.Date("2021-03-01"), units = "days")) / 30.44),
    # Log outcomes
    log_houses = log(houses),
    log_other = log(other_residential),
    log_total = log(total)
  )

cat(sprintf("\nNational time series: %d months\n", nrow(national)))
cat(sprintf("Date range: %s to %s\n", min(national$date), max(national$date)))
cat(sprintf("Houses range: %d to %d\n", min(national$houses, na.rm=T), max(national$houses, na.rm=T)))

# HomeBuilder period stats
hb_period <- national %>% filter(homebuilder_any == 1)
pre_period <- national %>% filter(date >= "2019-01-01" & date <= "2020-05-01")

cat(sprintf("\nPre-program mean houses: %.0f\n", mean(pre_period$houses, na.rm=T)))
cat(sprintf("HomeBuilder mean houses: %.0f\n", mean(hb_period$houses, na.rm=T)))
cat(sprintf("Surge: +%.1f%%\n",
            (mean(hb_period$houses, na.rm=T) / mean(pre_period$houses, na.rm=T) - 1) * 100))

# ------------------------------------------------------------------
# 5. Create state-level panel for cross-region DiD
# ------------------------------------------------------------------
state_panel <- dwellings %>%
  filter(region_type == "state", dwelling_type %in% c("houses", "other_residential")) %>%
  select(date, year, month, state, dwelling_type, approvals) %>%
  pivot_wider(names_from = dwelling_type, values_from = approvals) %>%
  arrange(state, date) %>%
  mutate(
    t = as.numeric(difftime(date, as.Date("2016-01-01"), units = "days")) / 30.44,
    homebuilder_any = ifelse(date >= "2020-06-01" & date <= "2021-03-01", 1L, 0L),
    post_program = ifelse(date >= "2021-04-01", 1L, 0L),
    log_houses = log(houses + 1),
    log_other = log(other_residential + 1),
    # State numeric ID
    state_id = as.integer(factor(state))
  )

# Treatment intensity: high-price states (Sydney, Melbourne) vs affordable
# Median house prices 2020: Sydney ~$900K, Melbourne ~$750K, Brisbane ~$500K,
# Adelaide ~$450K, Perth ~$450K, Hobart ~$500K
state_panel <- state_panel %>%
  mutate(
    high_price = ifelse(state %in% c("NSW", "VIC"), 1L, 0L),
    # Interaction for DDD
    hb_x_affordable = homebuilder_any * (1 - high_price)
  )

cat(sprintf("\nState panel: %d obs, %d states\n", nrow(state_panel), n_distinct(state_panel$state)))

# ------------------------------------------------------------------
# 6. Create GCCSA panel
# ------------------------------------------------------------------
gccsa_panel <- dwellings %>%
  filter(region_type %in% c("gccsa_capital", "gccsa_rest"),
         dwelling_type %in% c("houses", "other_residential")) %>%
  select(date, year, month, REGION, state, dwelling_type, approvals) %>%
  pivot_wider(names_from = dwelling_type, values_from = approvals) %>%
  arrange(REGION, date) %>%
  mutate(
    t = as.numeric(difftime(date, as.Date("2016-01-01"), units = "days")) / 30.44,
    homebuilder_any = ifelse(date >= "2020-06-01" & date <= "2021-03-01", 1L, 0L),
    post_program = ifelse(date >= "2021-04-01", 1L, 0L),
    log_houses = log(houses + 1),
    log_other = log(other_residential + 1),
    region_id = as.integer(factor(REGION)),
    # Capital city = high-price (binding cap)
    capital = ifelse(grepl("G", REGION) | REGION == "8ACTE", 1L, 0L),
    high_price = ifelse(REGION %in% c("1GSYD", "2GMEL"), 1L, 0L)
  )

cat(sprintf("GCCSA panel: %d obs, %d GCCSAs\n", nrow(gccsa_panel), n_distinct(gccsa_panel$REGION)))

# ------------------------------------------------------------------
# 7. Save cleaned data
# ------------------------------------------------------------------
saveRDS(national, "../data/national_ts.rds")
saveRDS(state_panel, "../data/state_panel.rds")
saveRDS(gccsa_panel, "../data/gccsa_panel.rds")

cat("\nCleaned data saved.\n")
