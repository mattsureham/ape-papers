## ============================================================
## 02_clean_data.R — Variable construction for SCM and DiD
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

source("00_packages.R")

## ============================================================
## 1. Load raw data
## ============================================================

wb   <- fread(file.path(data_dir, "wb_oecd_panel.csv"))
hours_ilo <- fread(file.path(data_dir, "oecd_hours_total.csv"))
kor_hours <- fread(file.path(data_dir, "kor_hours_industry.csv"))
kor_emp   <- fread(file.path(data_dir, "kor_employment_industry.csv"))

cat("WB panel:", nrow(wb), "rows,", uniqueN(wb$iso2), "countries\n")
cat("ILO hours:", nrow(hours_ilo), "rows,", uniqueN(hours_ilo$ref_area), "countries\n")

## ============================================================
## 2. Clean ILO hours → country-year panel of mean weekly hours
## ============================================================

hours_panel <- hours_ilo[sex == "SEX_T" & classif1 == "ECO_AGGREGATE_TOTAL",
                         .(iso3 = ref_area, year = as.integer(time),
                           mean_weekly_hours = as.numeric(obs_value))]
hours_panel <- hours_panel[!is.na(mean_weekly_hours)]
cat("Hours panel:", nrow(hours_panel), "rows,", uniqueN(hours_panel$iso3), "countries\n")

## Map ISO3 → ISO3 (WB uses ISO3 in iso2 column oddly)
## WB actually stored ISO3 codes in iso2 column
wb[, iso3 := iso2]  # WB API returns countryiso3code

## Merge hours into WB panel
panel <- merge(wb, hours_panel, by = c("iso3", "year"), all.x = TRUE)

## ============================================================
## 3. Create SCM-ready panel (balanced, no missing key vars)
## ============================================================

## Identify countries with complete TFR and hours data 2005-2023
complete_countries <- panel[year >= 2005 & year <= 2023,
                            .(n_tfr = sum(!is.na(tfr)),
                              n_hours = sum(!is.na(mean_weekly_hours))),
                            by = iso3]
complete_countries <- complete_countries[n_tfr >= 15 & n_hours >= 10]
cat("Countries with 15+ years TFR and 10+ years hours:", nrow(complete_countries), "\n")

## Make sure Korea is included
stopifnot("Korea must be in panel" = "KOR" %in% complete_countries$iso3)

## Filter to complete countries — keep all WB columns
scm_panel <- panel[iso3 %in% complete_countries$iso3 & year >= 2005 & year <= 2023]

## Ensure cbr is present
if (!"cbr" %in% names(scm_panel)) {
  cat("WARNING: cbr not in panel. Check WB merge.\n")
  scm_panel[, cbr := NA_real_]
}

## Create numeric country ID for Synth package
scm_panel[, country_id := as.integer(factor(iso3))]
kor_id <- scm_panel[iso3 == "KOR", unique(country_id)]
cat("Korea country_id:", kor_id, "\n")

## Interpolate missing hours for some country-years
scm_panel[, mean_weekly_hours := approx(year, mean_weekly_hours, year, rule = 2)$y,
          by = iso3]

## Compute annual hours (approximation: weekly × 52)
scm_panel[, annual_hours := mean_weekly_hours * 52]

## Treatment indicator
scm_panel[, treated := as.integer(iso3 == "KOR")]
scm_panel[, post := as.integer(year >= 2018)]

## ============================================================
## 4. Clean Korea industry-level hours data
## ============================================================

## Extract ISIC Rev 4 industry codes (1-letter)
kor_ind <- kor_hours[sex == "SEX_T" & grepl("^ECO_ISIC4_[A-U]$", classif1),
                     .(industry = sub("ECO_ISIC4_", "", classif1),
                       year = as.integer(time),
                       hours = as.numeric(obs_value))]
kor_ind <- kor_ind[!is.na(hours)]

## ISIC4 industry labels
isic4_labels <- c(
  A = "Agriculture", B = "Mining", C = "Manufacturing",
  D = "Utilities", E = "Water/Waste", F = "Construction",
  G = "Wholesale/Retail", H = "Transportation", I = "Accommodation/Food",
  J = "Information/Comm", K = "Finance/Insurance", L = "Real Estate",
  M = "Professional/Scientific", N = "Admin/Support", O = "Public Admin",
  P = "Education", Q = "Health/Social", R = "Arts/Entertainment",
  S = "Other Services", T = "Households", U = "International Orgs"
)
kor_ind[, industry_name := isic4_labels[industry]]

## Compute baseline (2015-2017 mean) hours by industry
baseline <- kor_ind[year >= 2015 & year <= 2017,
                    .(baseline_hours = mean(hours, na.rm = TRUE)),
                    by = .(industry, industry_name)]
kor_ind <- merge(kor_ind, baseline, by = c("industry", "industry_name"))

## Treatment intensity = how binding the 52-hour cap is
## Higher baseline hours = more binding = higher treatment intensity
kor_ind[, treatment_intensity := pmax(baseline_hours - 40, 0)]
kor_ind[, post := as.integer(year >= 2018)]

cat("\nKorea industry hours:\n")
print(baseline[order(-baseline_hours)][1:15])

## ============================================================
## 5. Clean Korea employment by industry
## ============================================================

kor_emp_clean <- kor_emp[sex == "SEX_T" & grepl("^ECO_ISIC4_[A-U]$", classif1),
                         .(industry = sub("ECO_ISIC4_", "", classif1),
                           year = as.integer(time),
                           employment = as.numeric(obs_value))]
kor_emp_clean <- kor_emp_clean[!is.na(employment)]

## Merge employment into industry hours
kor_ind <- merge(kor_ind, kor_emp_clean, by = c("industry", "year"), all.x = TRUE)

## Compute employment shares at baseline
total_emp_baseline <- kor_emp_clean[year >= 2015 & year <= 2017,
                                    .(total_emp = mean(employment)), by = year]
total_baseline <- mean(total_emp_baseline$total_emp)

emp_shares <- kor_emp_clean[year >= 2015 & year <= 2017,
                            .(emp_share = mean(employment) / total_baseline),
                            by = industry]
kor_ind <- merge(kor_ind, emp_shares, by = "industry", all.x = TRUE)

## ============================================================
## 6. Hours bands data (if available)
## ============================================================

if (file.exists(file.path(data_dir, "kor_hours_bands.csv"))) {
  hb <- fread(file.path(data_dir, "kor_hours_bands.csv"))
  if (nrow(hb) > 0) {
    cat("\nHours bands data available:", nrow(hb), "rows\n")
    cat("Bands:", paste(unique(hb$classif1), collapse = ", "), "\n")
  }
} else {
  cat("\nNo hours bands data file found.\n")
}

## ============================================================
## 7. Save cleaned data
## ============================================================

fwrite(scm_panel, file.path(data_dir, "scm_panel.csv"))
fwrite(kor_ind, file.path(data_dir, "korea_industry_panel.csv"))

cat("\n=== CLEANING SUMMARY ===\n")
cat(sprintf("SCM panel: %d obs, %d countries, years %d-%d\n",
            nrow(scm_panel), uniqueN(scm_panel$iso3),
            min(scm_panel$year), max(scm_panel$year)))
cat(sprintf("Korea industry panel: %d obs, %d industries, years %d-%d\n",
            nrow(kor_ind), uniqueN(kor_ind$industry),
            min(kor_ind$year), max(kor_ind$year)))
cat(sprintf("Korea TFR 2017 (pre-treatment): %.3f\n",
            scm_panel[iso3 == "KOR" & year == 2017, tfr]))
cat(sprintf("Korea TFR 2019 (post-treatment): %.3f\n",
            scm_panel[iso3 == "KOR" & year == 2019, tfr]))
cat(sprintf("Korea mean weekly hours 2017: %.1f\n",
            scm_panel[iso3 == "KOR" & year == 2017, mean_weekly_hours]))
cat(sprintf("Korea mean weekly hours 2019: %.1f\n",
            scm_panel[iso3 == "KOR" & year == 2019, mean_weekly_hours]))
