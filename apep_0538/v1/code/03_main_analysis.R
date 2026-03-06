## 03_main_analysis.R — Main DiD regressions and event study
## APEP-0538: ZFE Housing Price Capitalization

source("00_packages.R")

data_dir <- "../data"

## =========================================================================
## A. Load analysis data
## =========================================================================

cat("=== A. Loading analysis data ===\n")

dvf <- fread(file.path(data_dir, "dvf_boundary_2km.csv"))
dvf_1km <- fread(file.path(data_dir, "dvf_boundary_1km.csv"))
dvf_full <- fread(file.path(data_dir, "dvf_analysis_full.csv"))
dvf_res <- fread(file.path(data_dir, "dvf_residential_boundary.csv"))
dvf_com <- fread(file.path(data_dir, "dvf_commercial_boundary.csv"))

## Prepare factor variables
for (dt in list(dvf, dvf_1km, dvf_full, dvf_res, dvf_com)) {
  dt[, city_f := as.factor(city)]
  dt[, yq_f := as.factor(year_quarter)]
  dt[, property_type_f := as.factor(property_type)]
  dt[, code_commune_f := as.factor(code_commune)]
}

cat("  2km boundary sample:", format(nrow(dvf), big.mark = ","), "\n")
cat("  1km boundary sample:", format(nrow(dvf_1km), big.mark = ","), "\n")

## =========================================================================
## B. Main DiD specification (TWFE baseline)
## =========================================================================

cat("\n=== B. Main TWFE specifications ===\n")

## Model 1: Basic DiD with city + year-quarter FE
m1 <- feols(log_price_m2 ~ treated | city_f + yq_f, data = dvf_res,
            cluster = ~code_commune_f)

## Model 2: Add hedonic controls
m2 <- feols(log_price_m2 ~ treated + surface + nombre_pieces_principales +
              i(property_type_f) | city_f + yq_f,
            data = dvf_res, cluster = ~code_commune_f)

## Model 3: City x year-quarter FE (absorb city-specific trends)
m3 <- feols(log_price_m2 ~ treated + surface + nombre_pieces_principales |
              city_f^yq_f,
            data = dvf_res, cluster = ~code_commune_f)

## Model 4: Commune FE + year-quarter FE (finest geographic granularity)
m4 <- feols(log_price_m2 ~ treated + surface + nombre_pieces_principales |
              code_commune_f + yq_f,
            data = dvf_res, cluster = ~code_commune_f)

## Model 5: 1km bandwidth
m5 <- feols(log_price_m2 ~ treated + surface + nombre_pieces_principales |
              code_commune_f + yq_f,
            data = dvf_1km[property_type %in% c("house", "apartment")],
            cluster = ~code_commune_f)

cat("Main TWFE results:\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Basic", "Hedonic", "CityxTime", "Commune", "1km"),
       se.below = TRUE, keep = "treated")

## Save coefficients for table generation
main_results <- data.table(
  model = c("Basic DiD", "Hedonic controls", "City x Time FE",
            "Commune FE", "1km bandwidth"),
  coef = c(coef(m1)["treated"], coef(m2)["treated"],
           coef(m3)["treated"], coef(m4)["treated"], coef(m5)["treated"]),
  se = c(se(m1)["treated"], se(m2)["treated"],
         se(m3)["treated"], se(m4)["treated"], se(m5)["treated"]),
  n_obs = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5))
)
main_results[, pval := 2 * pnorm(-abs(coef / se))]
main_results[, ci_lower := coef - 1.96 * se]
main_results[, ci_upper := coef + 1.96 * se]

fwrite(main_results, file.path(data_dir, "main_results.csv"))

## =========================================================================
## C. Event study specification
## =========================================================================

cat("\n=== C. Event study ===\n")

## Create relative time variable
dvf_res[, zfe_start_numeric := year(as.Date(zfe_start_date)) +
          (quarter(as.Date(zfe_start_date)) - 1) / 4]
dvf_res[, rel_time := time_numeric - zfe_start_numeric]
dvf_res[, rel_quarter := round(rel_time * 4)]

## Trim to reasonable window
dvf_es <- dvf_res[abs(rel_quarter) <= 12]

## Event study with fixest
es_model <- feols(log_price_m2 ~ i(rel_quarter, inside_zfe, ref = -1) +
                    surface + nombre_pieces_principales |
                    code_commune_f + yq_f,
                  data = dvf_es, cluster = ~code_commune_f)

cat("Event study coefficients:\n")
summary(es_model)

## Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_model))
es_coefs <- es_coefs[grepl("rel_quarter", rownames(coeftable(es_model))), ]
es_coefs[, rel_quarter := as.integer(gsub(".*::([-0-9]+).*", "\\1",
                                           rownames(coeftable(es_model))[grepl("rel_quarter",
                                           rownames(coeftable(es_model)))]))]
setnames(es_coefs, c("estimate", "se", "tval", "pval", "rel_quarter"))
es_coefs[, ci_lower := estimate - 1.96 * se]
es_coefs[, ci_upper := estimate + 1.96 * se]

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

## =========================================================================
## D. Callaway & Sant'Anna (2021) staggered DiD
## =========================================================================

cat("\n=== D. Callaway & Sant'Anna staggered DiD ===\n")

## Prepare data for did package
## Group variable: ZFE adoption quarter (numeric)
dvf_did <- dvf_res[!is.na(zfe_start_date)]

## Exclude always-treated cities (adopted before DVF data starts in 2020)
## Paris (2017) and Grenoble (2019) have no pre-treatment data
dvf_did <- dvf_did[!(city %in% c("Paris", "Grenoble"))]
cat("  Excluded Paris and Grenoble (always-treated). Remaining:", nrow(dvf_did), "obs\n")

## Convert year-quarter to numeric period
dvf_did[, period := year * 4 + quarter]
dvf_did[, first_treat := year(as.Date(zfe_start_date)) * 4 +
          quarter(as.Date(zfe_start_date))]

## For not-yet-treated observations in late-adopting cities
## (properties inside cities that haven't adopted ZFE yet during observation)
## Set first_treat = 0 for never-treated (outside ZFE boundary)
dvf_did[inside_zfe == 0, first_treat := 0]

## Create a numeric ID for each unit (commune)
dvf_did[, commune_id := as.integer(as.factor(code_commune))]

## Aggregate to commune-quarter level for CS-DiD (individual-level too slow)
dvf_agg <- dvf_did[, .(
  log_price_m2 = mean(log_price_m2, na.rm = TRUE),
  n_trans = .N,
  mean_surface = mean(surface, na.rm = TRUE)
), by = .(commune_id, period, first_treat)]

## Run CS-DiD
cs_result <- tryCatch({
  att_gt(
    yname = "log_price_m2",
    tname = "period",
    idname = "commune_id",
    gname = "first_treat",
    data = as.data.frame(dvf_agg),
    control_group = "notyettreated",
    base_period = "varying"
  )
}, error = function(e) {
  cat("  CS-DiD error:", e$message, "\n")
  cat("  Proceeding with TWFE results as primary.\n")
  NULL
})

if (!is.null(cs_result)) {
  cat("  CS-DiD ATT(g,t) computed\n")

  ## Aggregate to overall ATT
  cs_agg <- aggte(cs_result, type = "simple", na.rm = TRUE)
  cat("  Overall ATT:", round(cs_agg$overall.att, 4),
      " SE:", round(cs_agg$overall.se, 4), "\n")

  ## Dynamic effects
  cs_dyn <- aggte(cs_result, type = "dynamic", na.rm = TRUE)

  ## Save CS results
  cs_dynamic_coefs <- data.table(
    rel_period = cs_dyn$egt,
    att = cs_dyn$att.egt,
    se = cs_dyn$se.egt
  )
  cs_dynamic_coefs[, ci_lower := att - 1.96 * se]
  cs_dynamic_coefs[, ci_upper := att + 1.96 * se]
  fwrite(cs_dynamic_coefs, file.path(data_dir, "cs_did_dynamic.csv"))

  cs_overall <- data.table(
    att = cs_agg$overall.att,
    se = cs_agg$overall.se,
    ci_lower = cs_agg$overall.att - 1.96 * cs_agg$overall.se,
    ci_upper = cs_agg$overall.att + 1.96 * cs_agg$overall.se
  )
  fwrite(cs_overall, file.path(data_dir, "cs_did_overall.csv"))
}

## =========================================================================
## E. Air quality first stage
## =========================================================================

cat("\n=== E. Air quality first stage ===\n")

## Load full data with air quality
dvf_aq <- fread(file.path(data_dir, "dvf_analysis_full.csv"))
dvf_aq <- dvf_aq[!is.na(mean_no2)]

## City-month level regression: does ZFE adoption reduce NO2?
aq_monthly <- dvf_aq[, .(
  mean_no2 = mean(mean_no2, na.rm = TRUE),
  mean_pm25 = mean(mean_pm25, na.rm = TRUE),
  post_zfe = max(post_zfe)
), by = .(city, month)]

aq_monthly[, city_f := as.factor(city)]
aq_monthly[, month_f := as.factor(month)]
aq_monthly[, year_month := as.Date(paste0(month, "-01"))]
aq_monthly[, year := year(year_month)]
aq_monthly[, month_of_year := as.factor(month(year_month))]

## First stage: post_zfe -> NO2 (with month-of-year FE for seasonality)
fs_no2 <- feols(mean_no2 ~ post_zfe | city_f + year + month_of_year, data = aq_monthly,
                cluster = ~city_f)
fs_pm25 <- feols(mean_pm25 ~ post_zfe | city_f + year + month_of_year, data = aq_monthly,
                 cluster = ~city_f)

cat("First stage results:\n")
cat("  NO2: coef =", round(coef(fs_no2)["post_zfe"], 2),
    "SE =", round(se(fs_no2)["post_zfe"], 2), "\n")
cat("  PM2.5: coef =", round(coef(fs_pm25)["post_zfe"], 2),
    "SE =", round(se(fs_pm25)["post_zfe"], 2), "\n")

fs_results <- data.table(
  outcome = c("NO2 (ug/m3)", "PM2.5 (ug/m3)"),
  coef = c(coef(fs_no2)["post_zfe"], coef(fs_pm25)["post_zfe"]),
  se = c(se(fs_no2)["post_zfe"], se(fs_pm25)["post_zfe"]),
  n_obs = c(nobs(fs_no2), nobs(fs_pm25))
)
fs_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(fs_results, file.path(data_dir, "first_stage_results.csv"))

## =========================================================================
## F. Placebo test: Commercial properties
## =========================================================================

cat("\n=== F. Placebo test: Commercial properties ===\n")

if (nrow(dvf_com) > 100) {
  dvf_com[, city_f := as.factor(city)]
  dvf_com[, yq_f := as.factor(year_quarter)]
  dvf_com[, code_commune_f := as.factor(code_commune)]

  placebo_com <- feols(log_price_m2 ~ treated + surface |
                        city_f + yq_f,
                      data = dvf_com, cluster = ~code_commune_f)
  cat("  Commercial placebo: coef =", round(coef(placebo_com)["treated"], 4),
      "SE =", round(se(placebo_com)["treated"], 4), "\n")

  placebo_results <- data.table(
    outcome = "Commercial price/m2",
    coef = coef(placebo_com)["treated"],
    se = se(placebo_com)["treated"],
    n = nobs(placebo_com)
  )
  fwrite(placebo_results, file.path(data_dir, "placebo_commercial.csv"))
} else {
  cat("  Insufficient commercial transactions for placebo test\n")
}

cat("\n=== Main analysis complete ===\n")
