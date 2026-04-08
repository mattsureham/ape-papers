## 02_clean_data.R — Clean and construct analysis variables
## apep_1407: The Insurance Denominator

source("00_packages.R")

data_dir <- "../data"

## ---- Load raw data ----
df_raw <- readRDS(file.path(data_dir, "fema_policies_raw.rds"))
cat(sprintf("Raw records: %s\n", format(nrow(df_raw), big.mark = ",")))

## ---- Parse dates ----
df <- df_raw |>
  mutate(
    eff_date = as.Date(substr(policyEffectiveDate, 1, 10)),
    term_date = as.Date(substr(policyTerminationDate, 1, 10)),
    cancel_date = as.Date(substr(cancellationDateOfFloodPolicy, 1, 10))
  )

## ---- Construct key variables ----
rr2_date <- as.Date("2021-10-01")

df <- df |>
  mutate(
    ## Treatment: grandfathered status
    grandfathered = as.integer(grandfatheringTypeCode == 3),

    ## Post-RR2.0 indicator
    post_rr2 = as.integer(eff_date >= rr2_date),

    ## Year-quarter
    year = year(eff_date),
    quarter = quarter(eff_date),
    yq = paste0(year, "Q", quarter),
    yq_num = year + (quarter - 1) / 4,

    ## Event time (quarters relative to 2021Q4)
    event_q = (year - 2021) * 4 + (quarter - 4),

    ## Premium (numeric)
    premium = as.numeric(totalInsurancePremiumOfThePolicy),

    ## Log premium
    log_premium = ifelse(premium > 0, log(premium), NA),

    ## Coverage ratio
    bldg_coverage = as.numeric(totalBuildingInsuranceCoverage),
    replacement_cost = as.numeric(buildingReplacementCost),
    coverage_ratio = ifelse(replacement_cost > 0, bldg_coverage / replacement_cost, NA),

    ## Lapse indicator: cancelled and not renewed within the same year-quarter
    lapsed = as.integer(!is.na(cancel_date)),

    ## Zone mismatch (potential RDD running variable)
    zone_mismatch = as.integer(floodZoneCurrent != ratedFloodZone),

    ## Mandatory purchase
    mandatory = as.integer(mandatoryPurchaseFlag == TRUE | mandatoryPurchaseFlag == "true"),

    ## Primary residence
    primary_res = as.integer(primaryResidenceIndicator == TRUE | primaryResidenceIndicator == "true"),

    ## County-level FE identifier
    county_fe = paste0(propertyState, "_", countyCode)
  )

## ---- Drop invalid records ----
n_before <- nrow(df)
df <- df |>
  filter(
    !is.na(premium),
    premium >= 0,
    !is.na(eff_date),
    year >= 2019,
    year <= 2024,
    !is.na(grandfatheringTypeCode)
  )
cat(sprintf("Dropped %s invalid records. Remaining: %s\n",
            format(n_before - nrow(df), big.mark = ","),
            format(nrow(df), big.mark = ",")))

## ---- Construct policy-level panel ----
## Each row is a policy-effective-date observation
## For the DiD, we use the cross-section of policies grouped by county × flood zone × quarter

cat(sprintf("\n=== Sample composition ===\n"))
cat(sprintf("Grandfathered: %s (%.1f%%)\n",
            format(sum(df$grandfathered), big.mark = ","),
            100 * mean(df$grandfathered)))
cat(sprintf("Non-grandfathered: %s (%.1f%%)\n",
            format(sum(df$grandfathered == 0), big.mark = ","),
            100 * mean(df$grandfathered == 0)))
cat(sprintf("Pre-RR2.0: %s | Post-RR2.0: %s\n",
            format(sum(df$post_rr2 == 0), big.mark = ","),
            format(sum(df$post_rr2 == 1), big.mark = ",")))
cat(sprintf("Years: %d - %d\n", min(df$year), max(df$year)))
cat(sprintf("States: %s\n", paste(sort(unique(df$propertyState)), collapse = ", ")))

## ---- Winsorize premium at 1st/99th percentile ----
p01 <- quantile(df$premium, 0.01, na.rm = TRUE)
p99 <- quantile(df$premium, 0.99, na.rm = TRUE)
df <- df |>
  mutate(
    premium_w = pmin(pmax(premium, p01), p99),
    log_premium_w = log(premium_w + 1)
  )

## ---- Summary statistics by group ----
summ <- df |>
  group_by(grandfathered) |>
  summarise(
    n = n(),
    mean_premium = mean(premium, na.rm = TRUE),
    sd_premium = sd(premium, na.rm = TRUE),
    median_premium = median(premium, na.rm = TRUE),
    mean_coverage_ratio = mean(coverage_ratio, na.rm = TRUE),
    lapse_rate = mean(lapsed, na.rm = TRUE),
    pct_mandatory = mean(mandatory, na.rm = TRUE),
    pct_primary_res = mean(primary_res, na.rm = TRUE),
    .groups = "drop"
  )
print(summ)

## ---- Save analysis dataset ----
saveRDS(df, file.path(data_dir, "fema_analysis.rds"))

cat(sprintf("\n=== Clean data saved: %s observations ===\n",
            format(nrow(df), big.mark = ",")))
