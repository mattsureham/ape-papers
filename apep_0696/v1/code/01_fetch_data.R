## 01_fetch_data.R — Fetch data for apep_0696
## FPM fiscal windfalls and agricultural expansion in Brazilian municipalities
## Multi-cutoff RDD using 17 FPM population thresholds
##
## Sources:
##   1. IBGE SIDRA table 200: Municipal population, 2000 + 2010 census
##   2. IBGE SIDRA table 1612: PAM crop area, annual 2000-2019
##   3. FPM coefficient schedule: statutory (no download needed)

library(tidyverse)
library(httr)
library(jsonlite)

# Run from the v1/ directory (e.g., Rscript code/$(basename $0))
dir.create("data", showWarnings = FALSE)

cat("=== Fetching Data for apep_0696 ===\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1. Municipal Population: 2000 and 2010 Censuses
##    SIDRA table 200, variable 93 (população residente total)
##    Batch by state; filter for total (D4=0, D5=0, D6=0)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Fetching Municipal Population ---\n")

state_codes <- c(
  11, 12, 13, 14, 15, 16, 17,     # North
  21, 22, 23, 24, 25, 26, 27, 28, 29,  # Northeast
  31, 32, 33, 35,                  # Southeast
  41, 42, 43,                      # South
  50, 51, 52, 53                   # Center-West
)

pop_list <- list()
for (yr in c(2000, 2010)) {
  cat(sprintf("  Fetching %d census...\n", yr))
  state_pops <- list()

  for (st in state_codes) {
    url <- sprintf(
      "https://apisidra.ibge.gov.br/values/t/200/n6/in%%20n3%%20%d/v/93/p/%d",
      st, yr
    )
    df <- tryCatch({
      resp <- GET(url, timeout(30))
      if (status_code(resp) != 200) stop(sprintf("HTTP %d", status_code(resp)))
      fromJSON(content(resp, "text", encoding = "UTF-8"))
    }, error = function(e) {
      cat(sprintf("    Warning: state %d year %d: %s\n", st, yr, conditionMessage(e)))
      NULL
    })

    if (!is.null(df) && is.data.frame(df) && nrow(df) > 1) {
      # Keep total (D4C=0=total situation, D5C=0=total sex, D6C=0=total age)
      df_clean <- df[df$D4C == "0" & df$D5C == "0" & df$D6C == "0" & df$D2C == "93", ]
      if (nrow(df_clean) > 0) {
        df_clean$mun_code <- df_clean$D1C
        df_clean$mun_name <- df_clean$D1N
        df_clean$pop <- as.numeric(df_clean$V)
        df_clean$year <- yr
        state_pops[[as.character(st)]] <- df_clean[, c("mun_code", "mun_name", "pop", "year")]
      }
    }
    Sys.sleep(0.15)
  }

  pop_yr <- bind_rows(state_pops) %>% filter(!is.na(pop))
  pop_list[[as.character(yr)]] <- pop_yr
  cat(sprintf("    %d census: %d municipalities\n", yr, nrow(pop_yr)))
}

pop_all <- bind_rows(pop_list)
write_csv(pop_all, "data/population.csv")
cat("Population saved:", nrow(pop_all), "rows\n")

# Validate
if (nrow(pop_all) < 5000) stop("FATAL: Population data incomplete. Need at least 5000 rows.")

## ─────────────────────────────────────────────────────────────────────────────
## 2. PAM Annual Crop Area — SIDRA table 1612, variable 109
##    Area planted (hectares) for all annual crops, by municipality
##    Fetch year by year to avoid API timeout
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Fetching PAM Crop Area ---\n")

pam_list <- list()
years_pam <- 2000:2019

for (yr in years_pam) {
  url <- sprintf(
    "https://apisidra.ibge.gov.br/values/t/1612/n6/all/v/109/p/%d",
    yr
  )
  df <- tryCatch({
    resp <- GET(url, timeout(60))
    if (status_code(resp) != 200) stop(sprintf("HTTP %d", status_code(resp)))
    fromJSON(content(resp, "text", encoding = "UTF-8"))
  }, error = function(e) {
    cat(sprintf("  Warning: PAM year %d failed: %s\n", yr, conditionMessage(e)))
    NULL
  })

  if (!is.null(df) && is.data.frame(df) && nrow(df) > 1) {
    df_clean <- df[-1, ] %>%
      mutate(
        mun_code = D1C,
        crop_area_ha = suppressWarnings(as.numeric(V)),
        year = yr
      ) %>%
      dplyr::select(mun_code, crop_area_ha, year) %>%
      filter(!is.na(crop_area_ha))
    pam_list[[as.character(yr)]] <- df_clean
    cat(sprintf("  PAM %d: %d municipalities\n", yr, nrow(df_clean)))
  }
  Sys.sleep(0.2)
}

pam_all <- bind_rows(pam_list)
write_csv(pam_all, "data/pam_crop_area.csv")
cat("PAM crop area saved:", nrow(pam_all), "municipality-year rows\n")

if (nrow(pam_all) < 50000) stop("FATAL: PAM data incomplete. Need at least 50000 rows.")

## ─────────────────────────────────────────────────────────────────────────────
## 3. FPM Coefficient Schedule (Statutory)
##    Source: Decree-Law 1.881/1981 and LC 91/1997
##    17 population thresholds with corresponding coefficient multipliers
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Constructing FPM Coefficient Schedule ---\n")

fpm_schedule <- tribble(
  ~bracket, ~pop_min,  ~pop_max,    ~coeff,
  1,        0,         10188,       0.6,
  2,        10189,     13584,       0.8,
  3,        13585,     16980,       1.0,
  4,        16981,     23772,       1.2,
  5,        23773,     30564,       1.4,
  6,        30565,     37356,       1.6,
  7,        37357,     44148,       1.8,
  8,        44149,     50940,       2.0,
  9,        50941,     61128,       2.2,
  10,       61129,     71316,       2.4,
  11,       71317,     81504,       2.6,
  12,       81505,     91692,       2.8,
  13,       91693,     101880,      3.0,
  14,       101881,    115464,      3.2,
  15,       115465,    129048,      3.4,
  16,       129049,    142632,      3.6,
  17,       142633,    156216,      3.8,
  18,       156217,    Inf,         4.0
)

write_csv(fpm_schedule, "data/fpm_schedule.csv")
cat("FPM schedule: 18 brackets, 17 thresholds\n")

## ─────────────────────────────────────────────────────────────────────────────
## Summary
## ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Data Fetch Summary ===\n")
cat("Population (2000+2010):", nrow(pop_all), "municipality-year obs\n")
cat("PAM crop area:", nrow(pam_all), "municipality-year obs\n")
cat("FPM schedule: 18 brackets, 17 thresholds\n")
