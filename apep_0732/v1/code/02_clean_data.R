## 02_clean_data.R — Construct analysis panels for apep_0732
## Two panels: (1) county cross-section, (2) county × CHR-year panel

source("00_packages.R")

cat("=== Loading raw data ===\n")

border    <- readRDS("../data/border_counties.rds")
temp_cs   <- readRDS("../data/temp_crosssec.rds")
temp_ann  <- readRDS("../data/temp_annual.rds")
chr_cs    <- readRDS("../data/chr_crosssec.rds")
chr_panel <- readRDS("../data/chr_panel.rds")
acs       <- readRDS("../data/acs_demographics.rds")


## ============================================================
## Panel A: County cross-section
## ============================================================

cat("\n=== Building county cross-section ===\n")

## Start with border counties
cs <- border |>
  as.data.table() |>
  select(fips, boundary, late_sunset, dist_to_boundary, lon, lat, STATEFP, NAME)

## Merge temperature cross-section (long-run averages)
cs <- merge(cs, temp_cs, by = "fips", all.x = TRUE)

## Merge CHR mortality cross-section
cs <- merge(cs, chr_cs, by = "fips", all.x = TRUE)

## Merge ACS demographics
cs <- merge(cs, acs, by = "fips", all.x = TRUE)

## Drop missing
cs <- cs[!is.na(mean_ypll) & !is.na(mean_summer_temp)]

## Create interaction terms
cs[, heat_x_late := mean_summer_temp * late_sunset]
cs[, heat_dd_x_late := mean_summer_heat_dd * late_sunset]
cs[, winter_x_late := mean_winter_temp * late_sunset]

## Log population for weighting
cs[, log_pop := log(total_pop)]

cat("Cross-section panel:\n")
cat("  Counties:", nrow(cs), "\n")
cat("  Late-sunset:", sum(cs$late_sunset == 1), "\n")
cat("  Early-sunset:", sum(cs$late_sunset == 0), "\n")
cat("  By boundary:\n")
print(cs[, .(n = .N, mean_ypll = round(mean(mean_ypll), 1),
             mean_temp = round(mean(mean_summer_temp), 1)),
          by = .(boundary, late_sunset)])

saveRDS(cs, "../data/panel_crosssec.rds")


## ============================================================
## Panel B: County × CHR-year panel
## ============================================================

cat("\n=== Building county-year panel ===\n")

## Map CHR release years to approximate mortality data years
## CHR year → underlying mortality data years (approx):
## 2019 → 2015-2017, 2020 → 2016-2018, 2021 → 2017-2019,
## 2022 → 2018-2020, 2023 → 2019-2021, 2024 → 2020-2022
## Use midpoint: chr_year - 2

panel <- border |>
  as.data.table() |>
  select(fips, boundary, late_sunset, dist_to_boundary, lon, lat, STATEFP, NAME)

## Create county × year panel by merging border counties with CHR data
panel <- merge(panel, chr_panel[, .(fips, chr_year, ypll_rate)],
               by = "fips", allow.cartesian = TRUE)

## Match CHR year to temperature year (CHR year - 2 = midpoint of mortality window)
panel[, mort_year := chr_year - 2]

## Merge annual temperature
panel <- merge(panel, temp_ann,
               by.x = c("fips", "mort_year"), by.y = c("fips", "year"),
               all.x = TRUE)

## Merge demographics (time-invariant)
panel <- merge(panel, acs, by = "fips", all.x = TRUE)

## Drop missing
panel <- panel[!is.na(ypll_rate) & !is.na(summer_avg_temp)]

## Create variables
panel[, heat_x_late := summer_heat_dd65 * late_sunset]
panel[, winter_x_late := winter_avg_temp * late_sunset]
panel[, log_pop := log(total_pop)]

cat("County-year panel:\n")
cat("  Observations:", nrow(panel), "\n")
cat("  Counties:", uniqueN(panel$fips), "\n")
cat("  CHR years:", paste(sort(unique(panel$chr_year)), collapse = ", "), "\n")
cat("  Temperature years:", paste(sort(unique(panel$mort_year)), collapse = ", "), "\n")
cat("  By boundary:\n")
print(panel[, .(n_counties = uniqueN(fips), n_obs = .N,
                mean_ypll = round(mean(ypll_rate), 1)),
            by = boundary])

## SD of outcome for SDE computation
cat("\nOutcome statistics:\n")
cat("  Mean YPLL:", round(mean(panel$ypll_rate), 1), "\n")
cat("  SD YPLL:", round(sd(panel$ypll_rate), 1), "\n")
cat("  SD YPLL (cross-sec):", round(sd(cs$mean_ypll), 1), "\n")

saveRDS(panel, "../data/panel_annual.rds")


## ============================================================
## Panel C: State-week mortality (for supplementary analysis)
## ============================================================

cat("\n=== Processing state-week mortality ===\n")

state_mort <- tryCatch(readRDS("../data/state_weekly_mortality.rds"), error = function(e) NULL)

if (!is.null(state_mort)) {
  ## Identify TZ boundary state pairs
  ## ET/CT pairs: Indiana(ET) ↔ Illinois(CT), Tennessee(ET) ↔ Alabama(CT)
  ## CT/MT pairs: Kansas(CT) ↔ Colorado(MT), Nebraska(CT) ↔ Colorado(MT)
  ## MT/PT pairs: Idaho(MT) ↔ Oregon(PT), Idaho(MT) ↔ Washington(PT)

  tz_state_pairs <- data.table(
    state = c("Indiana", "Illinois", "Ohio", "Kentucky",
              "Tennessee", "Alabama", "Mississippi",
              "Kansas", "Colorado", "Nebraska",
              "North Dakota", "Montana",
              "Idaho", "Oregon", "Washington"),
    tz = c("Eastern", "Central", "Eastern", "Eastern",
           "Eastern", "Central", "Central",
           "Central", "Mountain", "Central",
           "Central", "Mountain",
           "Mountain", "Pacific", "Pacific"),
    boundary = c("ET_CT", "ET_CT", "ET_CT", "ET_CT",
                 "ET_CT", "ET_CT", "ET_CT",
                 "CT_MT", "CT_MT", "CT_MT",
                 "CT_MT", "CT_MT",
                 "MT_PT", "MT_PT", "MT_PT"),
    late_sunset = c(0L, 1L, 0L, 0L,
                    0L, 1L, 1L,
                    0L, 1L, 0L,
                    0L, 1L,
                    0L, 1L, 1L)
  )

  state_panel <- merge(state_mort, tz_state_pairs, by = "state")

  ## Add month for seasonal analysis
  state_panel[, `:=`(
    month = month(week_date),
    summer = as.integer(month(week_date) %in% 6:8),
    winter = as.integer(month(week_date) %in% c(12, 1, 2))
  )]

  cat("State-week panel:", nrow(state_panel), "state-weeks\n")
  cat("States:", length(unique(state_panel$state)), "\n")
  saveRDS(state_panel, "../data/state_panel.rds")
}

cat("\n=== Panel construction complete ===\n")
