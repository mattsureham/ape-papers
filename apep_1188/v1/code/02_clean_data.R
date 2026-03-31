# ==============================================================================
# 02_clean_data.R — Construct analysis panel
# ==============================================================================

source("00_packages.R")

qwi_2d <- readRDS("../data/qwi_2digit.rds")
trade_exposure <- readRDS("../data/trade_exposure.rds")

# --- Create year-quarter variable ---
qwi_2d <- qwi_2d %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    yearqtr = paste0(year, "Q", quarter),
    post = (yq >= 2018.5),  # 2018Q3 onward (GDPR enforced May 25 2018)
    info = as.integer(naics2 == "51"),
    # Drop transition quarter 2018Q2
    transition = (year == 2018 & quarter == 2)
  )

# --- Merge EU trade exposure ---
panel <- qwi_2d %>%
  left_join(trade_exposure %>% select(state_fips, eu_share), by = "state_fips") %>%
  filter(!is.na(eu_share))

cat(sprintf("After merging trade exposure: %d rows, %d states\n",
            nrow(panel), n_distinct(panel$state_fips)))

# --- Create balanced panel of counties present in all industries and quarters ---
# Require non-missing employment in all 4 industries and all quarters 2016Q1-2020Q1
panel_window <- panel %>%
  filter(year >= 2016, yq <= 2020.0,  # 2016Q1 through 2020Q1
         !transition)

# Count observations per county
county_coverage <- panel_window %>%
  group_by(county_fips) %>%
  summarise(
    n_ind = n_distinct(naics2),
    n_qtr = n_distinct(yearqtr),
    n_obs = n(),
    any_missing_emp = any(is.na(Emp) | Emp == 0),
    .groups = "drop"
  )

# Balanced: all 4 industries × 15 quarters (16 minus 2018Q2) = 60 obs
balanced_counties <- county_coverage %>%
  filter(n_ind == 4, n_obs >= 56, !any_missing_emp) %>%  # Allow some slack
  pull(county_fips)

cat(sprintf("Balanced panel counties: %d of %d\n",
            length(balanced_counties), n_distinct(panel_window$county_fips)))

panel_bal <- panel_window %>%
  filter(county_fips %in% balanced_counties)

# --- Construct outcome variables ---
panel_bal <- panel_bal %>%
  mutate(
    log_emp = log(Emp + 1),
    log_hira = log(HirA + 1),
    log_sep = log(Sep + 1),
    log_earns = log(EarnS + 1),
    # Triple-diff interaction terms
    info_post = info * post,
    info_eu = info * eu_share,
    post_eu = post * eu_share,
    info_post_eu = info * post * eu_share,
    # Binary EU exposure (above median)
    eu_high = as.integer(eu_share > median(trade_exposure$eu_share, na.rm = TRUE))
  )

# --- State name crosswalk for tables ---
state_names <- tibble(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,
                 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,
                 47,48,49,50,51,53,54,55,56),
  state_name = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
                 "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
                 "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
                 "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

panel_bal <- panel_bal %>%
  left_join(state_names, by = "state_fips")

# --- Summary statistics ---
cat("\n--- Panel Summary ---\n")
cat(sprintf("Counties: %d\n", n_distinct(panel_bal$county_fips)))
cat(sprintf("States: %d\n", n_distinct(panel_bal$state_fips)))
cat(sprintf("Quarters: %d (%s to %s)\n",
            n_distinct(panel_bal$yearqtr),
            min(panel_bal$yearqtr), max(panel_bal$yearqtr)))
cat(sprintf("Industries: %s\n", paste(unique(panel_bal$naics2), collapse = ", ")))
cat(sprintf("Observations: %d\n", nrow(panel_bal)))

cat("\nMean employment by industry:\n")
panel_bal %>%
  group_by(naics2) %>%
  summarise(mean_emp = mean(Emp, na.rm = TRUE), .groups = "drop") %>%
  print()

cat("\nEU trade share distribution:\n")
trade_exposure %>%
  summarise(
    mean = mean(eu_share, na.rm = TRUE),
    sd = sd(eu_share, na.rm = TRUE),
    p25 = quantile(eu_share, 0.25, na.rm = TRUE),
    p50 = quantile(eu_share, 0.50, na.rm = TRUE),
    p75 = quantile(eu_share, 0.75, na.rm = TRUE)
  ) %>%
  print()

# --- Save ---
saveRDS(panel_bal, "../data/panel_balanced.rds")
saveRDS(state_names, "../data/state_names.rds")

cat("\nPanel construction complete.\n")
