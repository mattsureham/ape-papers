## =============================================================================
## 04b_additional_robustness.R — Additional robustness checks (Round 2)
## Addresses: zone-by-month FE, Conley sensitivity, cereal pre-trend F-test
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## Load data
wfp <- fread(file.path(data_dir, "wfp_clean.csv"))
wfp[, date := as.Date(date)]
wfp_food <- wfp[is_fuel == FALSE & !is.na(dist_nearest)]

rtep <- fread(file.path(data_dir, "rtep_clean.csv"))
rtep[, date := as.Date(date)]

## Load main models (for Conley)
load(file.path(data_dir, "main_models.RData"))

## ---------------------------------------------------------------------------
## 1. Geopolitical Zone Mapping
## ---------------------------------------------------------------------------

cat("=== Adding Geopolitical Zones ===\n")

# Nigeria's 6 geopolitical zones
zone_map <- data.table(
  state = c(
    # North Central
    "Benue", "Kogi", "Kwara", "Nasarawa", "Niger", "Plateau",
    "Federal Capital Territory", "FCT",
    # North East
    "Adamawa", "Bauchi", "Borno", "Gombe", "Taraba", "Yobe",
    # North West
    "Jigawa", "Kaduna", "Kano", "Katsina", "Kebbi", "Sokoto", "Zamfara",
    # South East
    "Abia", "Anambra", "Ebonyi", "Enugu", "Imo",
    # South South
    "Akwa Ibom", "Bayelsa", "Cross River", "Delta", "Edo", "Rivers",
    # South West
    "Ekiti", "Lagos", "Ogun", "Ondo", "Osun", "Oyo"
  ),
  zone = c(
    rep("North Central", 8),
    rep("North East", 6),
    rep("North West", 7),
    rep("South East", 5),
    rep("South South", 6),
    rep("South West", 6)
  )
)

# Map zones to WFP food data
wfp_food[, zone := zone_map$zone[match(admin1, zone_map$state)]]
# Try alternative column names if admin1 doesn't work
if (all(is.na(wfp_food$zone))) {
  cat("Trying 'state' column for zone matching...\n")
  if ("state" %in% names(wfp_food)) {
    wfp_food[, zone := zone_map$zone[match(state, zone_map$state)]]
  }
}

cat("Zone assignment coverage:", sum(!is.na(wfp_food$zone)), "of", nrow(wfp_food), "\n")
if (sum(!is.na(wfp_food$zone)) > 0) {
  cat("Zone distribution:\n")
  print(wfp_food[!is.na(zone), .N, by = zone][order(-N)])
}

# Map zones to RTEP data
rtep[, zone := zone_map$zone[match(adm1_name, zone_map$state)]]
cat("\nRTEP zone coverage:", sum(!is.na(rtep$zone)), "of", nrow(rtep), "\n")

## ---------------------------------------------------------------------------
## 2. Zone-by-Month FE for Food (addresses spatial confound concern)
## ---------------------------------------------------------------------------

cat("\n=== Zone-by-Month Fixed Effects (Food) ===\n")

if (sum(!is.na(wfp_food$zone)) > nrow(wfp_food) * 0.5) {
  wfp_food_z <- wfp_food[!is.na(zone)]
  wfp_food_z[, zone_month := paste0(zone, "_", date)]

  # All food with zone-by-month FE
  m_food_zone <- tryCatch({
    feols(log_price ~ dist_post_100 | market_commodity + zone_month,
          data = wfp_food_z, cluster = ~admin1)
  }, error = function(e) { cat("Zone-month FE (all food) failed:", e$message, "\n"); NULL })

  # Cereals with zone-by-month FE
  m_cereal_zone <- tryCatch({
    feols(log_price ~ dist_post_100 | market_commodity + zone_month,
          data = wfp_food_z[commodity_group == "Cereals"], cluster = ~admin1)
  }, error = function(e) { cat("Zone-month FE (cereals) failed:", e$message, "\n"); NULL })

  if (!is.null(m_food_zone)) {
    cat("All food + zone-month FE: beta =", round(coef(m_food_zone)["dist_post_100"], 4),
        ", SE =", round(se(m_food_zone)["dist_post_100"], 4), "\n")
  }
  if (!is.null(m_cereal_zone)) {
    cat("Cereals + zone-month FE: beta =", round(coef(m_cereal_zone)["dist_post_100"], 4),
        ", SE =", round(se(m_cereal_zone)["dist_post_100"], 4), "\n")
  }

  # Save zone-month results
  zone_results <- data.table(
    model = c("All Food + Zone-Month FE", "Cereals + Zone-Month FE"),
    coefficient = c(
      ifelse(!is.null(m_food_zone), coef(m_food_zone)["dist_post_100"], NA),
      ifelse(!is.null(m_cereal_zone), coef(m_cereal_zone)["dist_post_100"], NA)
    ),
    se = c(
      ifelse(!is.null(m_food_zone), se(m_food_zone)["dist_post_100"], NA),
      ifelse(!is.null(m_cereal_zone), se(m_cereal_zone)["dist_post_100"], NA)
    )
  )
  fwrite(zone_results, file.path(data_dir, "robustness_zone_month_fe.csv"))
} else {
  cat("Insufficient zone coverage for zone-month FE. Skipping.\n")
}

## ---------------------------------------------------------------------------
## 3. Joint F-test for Cereal Pre-Trends
## ---------------------------------------------------------------------------

cat("\n=== Joint F-test for Cereal Pre-Trends ===\n")

wfp_cereals <- wfp_food[commodity_group == "Cereals"]
wfp_cereals[, event_time := as.numeric(difftime(date, as.Date("2023-06-01"), units = "days")) / 30.44]
wfp_cereals[, event_time := round(event_time)]
wfp_cereals <- wfp_cereals[event_time >= -18 & event_time <= 18]

# Create event-time dummies interacted with distance (omit -1)
for (k in setdiff(-18:18, -1)) {
  vname <- paste0("etime_", ifelse(k < 0, "m", "p"), abs(k))
  wfp_cereals[, (vname) := as.numeric(event_time == k) * dist_100km]
}

# Get pre-period variable names
pre_vars <- paste0("etime_m", 18:2)
pre_vars <- pre_vars[pre_vars %in% names(wfp_cereals)]

# Build formula with all event-time variables
all_vars <- c(paste0("etime_m", sort(setdiff(2:18, 1), decreasing = TRUE)),
              paste0("etime_p", 0:18))
all_vars <- all_vars[all_vars %in% names(wfp_cereals)]

fml <- as.formula(paste0("log_price ~ ", paste(all_vars, collapse = " + "),
                         " | market_commodity + date"))

m_es_cereal <- tryCatch({
  feols(fml, data = wfp_cereals, cluster = ~admin1)
}, error = function(e) { cat("Cereal event study failed:", e$message, "\n"); NULL })

if (!is.null(m_es_cereal)) {
  # Joint F-test on pre-period coefficients
  pre_vars_present <- pre_vars[pre_vars %in% names(coef(m_es_cereal))]
  if (length(pre_vars_present) > 0) {
    f_test <- tryCatch({
      wald(m_es_cereal, keep = pre_vars_present)
    }, error = function(e) {
      cat("Wald test failed:", e$message, "\n")
      NULL
    })

    if (!is.null(f_test)) {
      cat("Joint F-test for cereal pre-trends:\n")
      print(f_test)
      cat("Number of pre-period coefficients tested:", length(pre_vars_present), "\n")

      ftest_result <- data.table(
        test = "Joint F-test cereal pre-trends",
        n_coeffs = length(pre_vars_present),
        stat = as.numeric(f_test$stat),
        p_value = as.numeric(f_test$p),
        df1 = as.numeric(f_test$df1),
        df2 = as.numeric(f_test$df2)
      )
      fwrite(ftest_result, file.path(data_dir, "cereal_pretrend_ftest.csv"))
    }
  }
}

## ---------------------------------------------------------------------------
## 4. Conley SE at Multiple Cutoffs
## ---------------------------------------------------------------------------

cat("\n=== Conley SE Sensitivity (Multiple Cutoffs) ===\n")

# Petrol
conley_cutoffs <- c(100, 200, 300, 400)
conley_multi <- list()

for (cut in conley_cutoffs) {
  se_petrol <- tryCatch({
    vc <- vcov_conley(m_a2, lat = "lat", lon = "lon", cutoff = cut)
    sqrt(diag(vc))["dist_post_100"]
  }, error = function(e) NA_real_)

  # Cereals
  wfp_cer <- wfp_food[commodity_group == "Cereals"]
  m_cer <- feols(log_price ~ dist_post_100 | market_commodity + date,
                 data = wfp_cer, cluster = ~admin1)
  se_cereal <- tryCatch({
    vc <- vcov_conley(m_cer, lat = "latitude", lon = "longitude", cutoff = cut)
    sqrt(diag(vc))["dist_post_100"]
  }, error = function(e) NA_real_)

  conley_multi[[as.character(cut)]] <- data.table(
    cutoff_km = cut,
    petrol_se_conley = se_petrol,
    petrol_coef = coef(m_a2)["dist_post_100"],
    cereal_se_conley = se_cereal,
    cereal_coef = coef(m_cer)["dist_post_100"]
  )
}

conley_multi_dt <- rbindlist(conley_multi)
# Add state-clustered baseline
conley_multi_dt <- rbind(
  data.table(cutoff_km = 0, petrol_se_conley = se(m_a2)["dist_post_100"],
             petrol_coef = coef(m_a2)["dist_post_100"],
             cereal_se_conley = se(m_cer)["dist_post_100"],
             cereal_coef = coef(m_cer)["dist_post_100"]),
  conley_multi_dt
)

cat("Conley SE sensitivity:\n")
print(conley_multi_dt)
fwrite(conley_multi_dt, file.path(data_dir, "conley_se_sensitivity.csv"))

## ---------------------------------------------------------------------------
## 5. Excluding Northeast (Borno, Yobe, Adamawa) for food
## ---------------------------------------------------------------------------

cat("\n=== Excluding Northeast States (Food) ===\n")

northeast_states <- c("Borno", "Yobe", "Adamawa")
wfp_no_ne <- wfp_food[!(admin1 %in% northeast_states)]

m_cereal_no_ne <- tryCatch({
  feols(log_price ~ dist_post_100 | market_commodity + date,
        data = wfp_no_ne[commodity_group == "Cereals"], cluster = ~admin1)
}, error = function(e) { cat("Excluding NE failed:", e$message, "\n"); NULL })

if (!is.null(m_cereal_no_ne)) {
  cat("Cereals excl. NE: beta =", round(coef(m_cereal_no_ne)["dist_post_100"], 4),
      ", SE =", round(se(m_cereal_no_ne)["dist_post_100"], 4),
      ", N =", nobs(m_cereal_no_ne), "\n")
}

# Also exclude northeast for all food
m_food_no_ne <- tryCatch({
  feols(log_price ~ dist_post_100 | market_commodity + date,
        data = wfp_no_ne, cluster = ~admin1)
}, error = function(e) { cat("Excluding NE (all food) failed:", e$message, "\n"); NULL })

if (!is.null(m_food_no_ne)) {
  cat("All food excl. NE: beta =", round(coef(m_food_no_ne)["dist_post_100"], 4),
      ", SE =", round(se(m_food_no_ne)["dist_post_100"], 4),
      ", N =", nobs(m_food_no_ne), "\n")
}

ne_results <- data.table(
  model = c("Cereals excl. NE", "All Food excl. NE"),
  coefficient = c(
    ifelse(!is.null(m_cereal_no_ne), coef(m_cereal_no_ne)["dist_post_100"], NA),
    ifelse(!is.null(m_food_no_ne), coef(m_food_no_ne)["dist_post_100"], NA)
  ),
  se = c(
    ifelse(!is.null(m_cereal_no_ne), se(m_cereal_no_ne)["dist_post_100"], NA),
    ifelse(!is.null(m_food_no_ne), se(m_food_no_ne)["dist_post_100"], NA)
  ),
  n = c(
    ifelse(!is.null(m_cereal_no_ne), nobs(m_cereal_no_ne), NA),
    ifelse(!is.null(m_food_no_ne), nobs(m_food_no_ne), NA)
  )
)
fwrite(ne_results, file.path(data_dir, "robustness_excl_northeast.csv"))

cat("\n=== Additional robustness checks complete ===\n")
