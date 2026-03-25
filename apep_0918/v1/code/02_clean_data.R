## 02_clean_data.R — Clean panel and construct analysis variables
## APEP paper apep_0918: ULEZ expansion and NO2

source("code/00_packages.R")

panel <- fread("data/panel.csv")

cat("=== Cleaning panel ===\n")
cat(sprintf("  Raw panel rows: %s\n", format(nrow(panel), big.mark = ",")))

## ---- 1. Restrict to study period ----
panel <- panel[year_month >= "2018-01" & year_month <= "2023-08"]

## ---- 2. Require balanced-ish panel ----
n_total_months <- uniqueN(panel$year_month)
station_coverage <- panel[, .(n_months = .N), by = site_code]
good_stations <- station_coverage[n_months >= 0.70 * n_total_months]$site_code
panel <- panel[site_code %in% good_stations]

cat(sprintf("  Stations with >=70%% month coverage: %d\n", length(good_stations)))
cat(sprintf("  Panel rows after filtering: %s\n", format(nrow(panel), big.mark = ",")))

## ---- 3. Additional variables ----
panel[, cal_month := factor(month)]
panel[, ym_numeric := as.numeric(factor(year_month))]

## Site type indicators
panel[, background := as.integer(site_type %in% c("Suburban", "Urban Background"))]

## Distance categories for heterogeneity
panel[treat == 1, dist_cat := cut(abs(dist_boundary_km),
                                   breaks = c(0, 2, 4, Inf),
                                   labels = c("0-2km", "2-4km", ">4km"))]
panel[treat == 0, dist_cat := "Control"]

## ---- 4. Summary statistics ----
cat("\n=== Summary Statistics ===\n")
n_inner <- uniqueN(panel[treat == 1]$site_code)
n_outer <- uniqueN(panel[treat == 0]$site_code)
cat(sprintf("  Inner stations: %d, Outer stations: %d\n", n_inner, n_outer))
cat(sprintf("  Total station-months: %s\n", format(nrow(panel), big.mark = ",")))

for (grp in c("Inner (pre)", "Inner (post)", "Outer (pre)", "Outer (post)")) {
  tr <- ifelse(grepl("Inner", grp), 1, 0)
  po <- ifelse(grepl("post", grp), 1, 0)
  sub <- panel[treat == tr & post == po]
  cat(sprintf("  %s: mean=%.1f, sd=%.1f, n=%d\n", grp,
              mean(sub$no2_mean), sd(sub$no2_mean), nrow(sub)))
}

## Save
fwrite(panel, "data/panel_clean.csv")
cat("\n=== Saved data/panel_clean.csv ===\n")
