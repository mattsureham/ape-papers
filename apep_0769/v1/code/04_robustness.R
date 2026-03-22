# ============================================================
# 04_robustness.R — Robustness checks
# apep_0765
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# ----------------------------------------------------------
# 1. Dose-response: cumulative SM exits
# ----------------------------------------------------------
cat("=== Dose-response ===\n")

# Load SM exits by county-year
retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"), showProgress = FALSE)
setnames(retailers, gsub(" ", "_", names(retailers)))
retailers[, end_date := as.Date(End_Date, format = "%m/%d/%Y")]
retailers[, is_supermarket := Store_Type %in% c("Large Grocery Store",
                                                  "Supermarket", "Super Store")]

# State FIPS
state_fips_map <- data.table(
  State = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,
                                  15,16,17,18,19,20,21,22,23,24,
                                  25,26,27,28,29,30,31,32,33,34,
                                  35,36,37,38,39,40,41,42,44,45,
                                  46,47,48,49,50,51,53,54,55,56))
)
retailers <- merge(retailers, state_fips_map, by = "State", all.x = TRUE)

# County FIPS crosswalk
fips_url <- "https://www2.census.gov/geo/docs/reference/codes2020/national_county2020.txt"
resp <- httr::GET(fips_url, httr::timeout(30))
fips_xwalk <- fread(text = httr::content(resp, "text", encoding = "UTF-8"), sep = "|", header = TRUE)
fips_xwalk[, county_fips := paste0(sprintf("%02d", as.integer(STATEFP)),
                                    sprintf("%03d", as.integer(COUNTYFP)))]
fips_xwalk[, state_fips := sprintf("%02d", as.integer(STATEFP))]
fips_xwalk[, county_name_clean := toupper(gsub(" County$| Parish$| Borough$| Census Area$| Municipality$| city$", "",
                                                 COUNTYNAME))]
retailers[, county_name_clean := toupper(gsub(" County$| Parish$| Borough$", "", County))]
snap_fips <- merge(retailers[, .(Record_ID, state_fips, county_name_clean,
                                  is_supermarket, end_date)],
                   fips_xwalk[, .(state_fips, county_name_clean, county_fips)],
                   by = c("state_fips", "county_name_clean"), all.x = TRUE)
snap_fips <- unique(snap_fips, by = "Record_ID")

# Cumulative SM exits per county up to each year
cum_exits <- list()
for (yr in 2018:2023) {
  ce <- snap_fips[is_supermarket == TRUE & !is.na(end_date) &
                    year(end_date) <= yr & !is.na(county_fips),
                  .(cum_sm_exits = .N), by = county_fips]
  ce[, year := yr]
  cum_exits[[as.character(yr)]] <- ce
}
cum_exits_dt <- rbindlist(cum_exits, fill = TRUE)

panel_dose <- merge(panel, cum_exits_dt, by = c("county_fips", "year"), all.x = TRUE)
panel_dose[is.na(cum_sm_exits), cum_sm_exits := 0L]

twfe_dose_deny <- feols(denial_rate ~ cum_sm_exits | county_fips + year,
                        data = panel_dose, cluster = ~county_fips)
cat("  Denial rate ~ cumulative exits:\n")
print(summary(twfe_dose_deny))

twfe_dose_orig <- feols(ln_orig ~ cum_sm_exits | county_fips + year,
                        data = panel_dose, cluster = ~county_fips)
cat("  Log orig ~ cumulative exits:\n")
print(summary(twfe_dose_orig))

saveRDS(twfe_dose_deny, file.path(data_dir, "twfe_dose_deny.rds"))
saveRDS(twfe_dose_orig, file.path(data_dir, "twfe_dose_orig.rds"))

# ----------------------------------------------------------
# 2. Level outcome: number of originations
# ----------------------------------------------------------
cat("\n=== Level: origination count ===\n")

twfe_level <- feols(n_originations ~ treated | county_fips + year,
                    data = panel, cluster = ~county_fips)
cat("  N originations ~ treated:\n")
print(summary(twfe_level))

saveRDS(twfe_level, file.path(data_dir, "twfe_level.rds"))

# ----------------------------------------------------------
# 3. State-clustered
# ----------------------------------------------------------
cat("\n=== State-clustered ===\n")

twfe_deny_state <- feols(denial_rate ~ treated | county_fips + year,
                         data = panel, cluster = ~state_fips)
cat("  Denial rate (state-clustered):\n")
cat("    Estimate:", round(coef(twfe_deny_state)["treated"], 5),
    "SE:", round(sqrt(vcov(twfe_deny_state)["treated", "treated"]), 5), "\n")

saveRDS(twfe_deny_state, file.path(data_dir, "twfe_deny_state.rds"))

# ----------------------------------------------------------
# 4. Save robustness results
# ----------------------------------------------------------
robustness <- list(
  dose_deny = twfe_dose_deny,
  dose_orig = twfe_dose_orig,
  level = twfe_level,
  state_cluster = twfe_deny_state
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("=== Robustness complete ===\n")
