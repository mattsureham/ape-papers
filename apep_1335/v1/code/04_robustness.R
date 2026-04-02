# 04_robustness.R — Robustness checks and placebo tests
# apep_1335: Cannabis Lottery and Local Economic Renewal

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("Panel loaded:", nrow(panel), "rows\n")

# ============================================================================
# 1. Placebo Outcome: Manufacturing Employment (NAICS 31-33)
# ============================================================================

cat("\n=== Placebo: Manufacturing Employment ===\n")

# Fetch manufacturing QWI data (wasn't in the main fetch - need to add)
# Manufacturing should NOT respond to dispensary openings
# Use total employment as the channel — manufacturing is embedded in "00" (total)
# But we need a separate NAICS code. Let's use the total private minus retail/food
# as a proxy, or re-fetch manufacturing.

# Re-fetch manufacturing QWI
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) census_key <- Sys.getenv("CENSUS_KEY")

qwi_base <- "https://api.census.gov/data/timeseries/qwi/sa"

fetch_qwi_mfg <- function(year, quarter, key) {
  url <- paste0(qwi_base,
    "?get=Emp",
    "&for=county:*",
    "&in=state:17",
    "&year=", year,
    "&quarter=", quarter,
    "&industry=31-33",
    "&sex=0&agegrp=A00&race=A0&ethnicity=A0",
    "&education=E0&firmage=0&firmsize=0",
    "&ownercode=A05&seasonadj=U")
  if (nchar(key) > 0) url <- paste0(url, "&key=", key)

  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)
  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)

  json <- httr::content(resp, as = "text", encoding = "UTF-8")
  dat <- jsonlite::fromJSON(json)
  if (is.null(dat) || nrow(dat) < 2) return(NULL)

  df <- as.data.frame(dat[-1, ], stringsAsFactors = FALSE)
  names(df) <- dat[1, ]
  df$year <- year
  df$quarter <- quarter
  return(df)
}

mfg_list <- list()
for (yr in 2018:2024) {
  for (qtr in 1:4) {
    result <- fetch_qwi_mfg(yr, qtr, census_key)
    if (!is.null(result)) mfg_list[[length(mfg_list) + 1]] <- result
    Sys.sleep(0.3)
  }
  cat("  Year", yr, "done\n")
}

cat("Manufacturing QWI fetches:", length(mfg_list), "\n")

if (length(mfg_list) > 0) {
  mfg_df <- bind_rows(mfg_list) %>%
    mutate(
      emp_mfg = as.numeric(Emp),
      county_fips = paste0(state, county),
      year = as.integer(year),
      quarter = as.integer(quarter)
    ) %>%
    select(county_fips, year, quarter, emp_mfg)

  # Merge with panel
  panel_mfg <- panel %>%
    left_join(mfg_df, by = c("county_fips", "year", "quarter")) %>%
    mutate(log_emp_mfg = log(emp_mfg + 1)) %>%
    filter(!is.na(log_emp_mfg))

  cat("Manufacturing panel rows:", nrow(panel_mfg), "\n")

  # Run CS on manufacturing (placebo)
  cs_data_mfg <- panel_mfg %>%
    mutate(gname = first_treat, county_id = as.integer(as.factor(county_fips)))

  cs_mfg <- att_gt(
    yname = "log_emp_mfg",
    tname = "time_period",
    idname = "county_id",
    gname = "gname",
    data = cs_data_mfg,
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )

  att_mfg <- aggte(cs_mfg, type = "simple", na.rm = TRUE)
  cat("Placebo ATT (manufacturing):\n")
  summary(att_mfg)

  es_mfg <- aggte(cs_mfg, type = "dynamic", min_e = -8, max_e = 8, na.rm = TRUE)

  saveRDS(list(cs_mfg = cs_mfg, att_mfg = att_mfg, es_mfg = es_mfg),
          file.path(data_dir, "placebo_mfg.rds"))
} else {
  cat("WARNING: Could not fetch manufacturing data\n")
}

# ============================================================================
# 2. Heterogeneity: Small vs. Large Counties
# ============================================================================

cat("\n=== Heterogeneity: County Size ===\n")

# Split at median pre-treatment total employment
pre_median <- panel %>%
  filter(time_period < 14) %>%
  group_by(county_fips) %>%
  summarise(mean_emp = mean(emp_total, na.rm = TRUE), .groups = "drop") %>%
  summarise(median_emp = median(mean_emp, na.rm = TRUE)) %>%
  pull(median_emp)

cat("Median pre-treatment employment:", pre_median, "\n")

panel <- panel %>%
  group_by(county_fips) %>%
  mutate(pre_mean_emp = mean(emp_total[time_period < 14], na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(small_county = pre_mean_emp <= pre_median)

# Small counties
cs_small <- panel %>%
  filter(small_county, !is.na(log_emp_food)) %>%
  mutate(gname = first_treat, county_id = as.integer(as.factor(county_fips)))

if (n_distinct(cs_small$county_fips[cs_small$gname > 0]) >= 5) {
  cs_food_small <- att_gt(
    yname = "log_emp_food",
    tname = "time_period",
    idname = "county_id",
    gname = "gname",
    data = cs_small,
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )

  att_food_small <- aggte(cs_food_small, type = "simple", na.rm = TRUE)
  cat("ATT food (small counties):\n")
  summary(att_food_small)
} else {
  cat("Too few treated small counties for CS estimation\n")
  att_food_small <- NULL
}

# Large counties
cs_large <- panel %>%
  filter(!small_county, !is.na(log_emp_food)) %>%
  mutate(gname = first_treat, county_id = as.integer(as.factor(county_fips)))

if (n_distinct(cs_large$county_fips[cs_large$gname > 0]) >= 5) {
  cs_food_large <- att_gt(
    yname = "log_emp_food",
    tname = "time_period",
    idname = "county_id",
    gname = "gname",
    data = cs_large,
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )

  att_food_large <- aggte(cs_food_large, type = "simple", na.rm = TRUE)
  cat("ATT food (large counties):\n")
  summary(att_food_large)
} else {
  cat("Too few treated large counties for CS estimation\n")
  att_food_large <- NULL
}

# ============================================================================
# 3. Alternative Control Group: Never-Treated Only
# ============================================================================

cat("\n=== Alternative: Never-Treated Control Group ===\n")

cs_data <- panel %>%
  filter(!is.na(log_emp_food)) %>%
  mutate(gname = first_treat, county_id = as.integer(as.factor(county_fips)))

cs_food_nt <- att_gt(
  yname = "log_emp_food",
  tname = "time_period",
  idname = "county_id",
  gname = "gname",
  data = cs_data,
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

att_food_nt <- aggte(cs_food_nt, type = "simple", na.rm = TRUE)
cat("ATT food (never-treated controls):\n")
summary(att_food_nt)

# ============================================================================
# 4. TWFE with Controls for Pre-Existing Dispensaries
# ============================================================================

cat("\n=== TWFE with Pre-Existing Controls ===\n")

cs_data2 <- panel %>%
  filter(!is.na(log_emp_food)) %>%
  mutate(county_id = as.integer(as.factor(county_fips)))

twfe_food_controls <- feols(log_emp_food ~ treated + n_pre_existing:factor(time_period) |
                             county_id + time_period,
                             data = cs_data2, cluster = ~county_id)
cat("TWFE food with pre-existing controls:\n")
cat("  treated coef:", coef(twfe_food_controls)["treated"],
    "SE:", sqrt(vcov(twfe_food_controls)["treated", "treated"]), "\n")

# ============================================================================
# 5. HonestDiD Sensitivity Analysis
# ============================================================================

cat("\n=== HonestDiD Sensitivity ===\n")

# Apply HonestDiD to the food service event study
tryCatch({
  es_food <- results$es_food

  # Extract pre-treatment and post-treatment estimates
  pre_idx <- which(es_food$egt < 0)
  post_idx <- which(es_food$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Construct the required inputs for HonestDiD
    beta_hat <- es_food$att.egt
    sigma_hat <- es_food$V_analytical

    if (!is.null(sigma_hat) && all(dim(sigma_hat) > 0)) {
      # Relative magnitudes approach
      honest_result <- HonestDiD::createSensitivityResults_relativeMagnitudes(
        betahat = beta_hat,
        sigma = sigma_hat,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mbarvec = seq(0, 2, by = 0.5)
      )

      cat("HonestDiD sensitivity (relative magnitudes):\n")
      print(honest_result)

      saveRDS(honest_result, file.path(data_dir, "honest_did.rds"))
    } else {
      cat("Covariance matrix not available for HonestDiD\n")
    }
  }
}, error = function(e) {
  cat("HonestDiD failed:", conditionMessage(e), "\n")
})

# ============================================================================
# Save all robustness results
# ============================================================================

robustness <- list(
  att_food_small = att_food_small,
  att_food_large = att_food_large,
  att_food_nt = att_food_nt,
  twfe_food_controls = twfe_food_controls
)

if (exists("att_mfg")) robustness$att_mfg <- att_mfg

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))  # Updated with small_county

cat("\n=== Robustness checks complete ===\n")
