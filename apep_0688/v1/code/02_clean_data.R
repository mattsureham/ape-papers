## 02_clean_data.R — Build analysis panel from ONS PFA crime data
source("00_packages.R")

data_dir <- "../data"

## ─────────────────────────────────────────────────────────────────────────────
## 1. Load raw data
## ─────────────────────────────────────────────────────────────────────────────
knife  <- fread(file.path(data_dir, "knife_crime_panel.csv"))
firearm <- fread(file.path(data_dir, "firearm_panel.csv"))
pop     <- fread(file.path(data_dir, "population_pfa.csv"))
treat   <- fread(file.path(data_dir, "vru_treatment.csv"))
boundary <- fread(file.path(data_dir, "boundary_forces.csv"))

cat("Knife crime panel:", nrow(knife), "rows,", uniqueN(knife$area_name), "forces\n")
cat("Firearm panel:", nrow(firearm), "rows\n")

## ─────────────────────────────────────────────────────────────────────────────
## 2. Clean knife crime panel
## ─────────────────────────────────────────────────────────────────────────────
## Use year_end as the time variable (financial year ending)
## year_end = 2019 means April 2018 - March 2019
## Treatment starts April 2019, so first treated year = year_end 2020

knife_clean <- knife[!is.na(year_end) & !is.na(knife_crime),
                     .(area_code, area_name, year_end, knife_crime)]

## Drop City of London (tiny population, extreme rates)
knife_clean <- knife_clean[area_name != "City of London"]

## Deduplicate: some years have 2 entries (e.g., YE March 2025 and YE Sep 2025)
## Keep the last observation per force-year (most recent rolling annual)
knife_clean <- knife_clean[, .SD[.N], by = .(area_code, year_end)]

## Standardize force names — ONS appends "[note N]" or "[note N, M]" to some names
knife_clean[, force_std := gsub("\\s*\\[note[^]]*\\]", "", area_name)]
knife_clean[, force_std := trimws(force_std)]

## Check matching
cat("\nForce names after cleaning:\n")
cat(paste(" -", sort(unique(knife_clean$force_std)), collapse = "\n"), "\n")

unmatched <- setdiff(treat$force_name, knife_clean$force_std)
if (length(unmatched) > 0) {
  cat("\nUnmatched treatment forces:", paste(unmatched, collapse = ", "), "\n")
}
## Also update boundary force names to match cleaned ONS names
boundary[, force_name := gsub("\\s*\\[note \\d+\\]", "", force_name)]

## ─────────────────────────────────────────────────────────────────────────────
## 3. Merge population and compute rates
## ─────────────────────────────────────────────────────────────────────────────
## Population is from latest year only — use as denominator (stable approximation)
## Clean population names to match
pop_clean <- copy(pop)
pop_clean[, force_std := gsub("\\s*\\[note[^]]*\\]", "", area_name)]
pop_clean[, force_std := trimws(force_std)]

knife_clean <- merge(knife_clean, pop_clean[, .(force_std, population)],
                     by = "force_std", all.x = TRUE)

## Per 100,000 rate
knife_clean[, knife_rate := (knife_crime / population) * 100000]

## ─────────────────────────────────────────────────────────────────────────────
## 4. Merge treatment and boundary status
## ─────────────────────────────────────────────────────────────────────────────
knife_clean <- merge(knife_clean, treat[, .(force_name, cohort_year, vru)],
                     by.x = "force_std", by.y = "force_name", all.x = TRUE)
knife_clean[is.na(vru), vru := 0L]
knife_clean[is.na(cohort_year), cohort_year := 0L]

knife_clean <- merge(knife_clean, boundary,
                     by.x = "force_std", by.y = "force_name", all.x = TRUE)
knife_clean[is.na(boundary), boundary := 0L]

## Force classification
knife_clean[, force_type := fifelse(vru == 1, "VRU",
                                     fifelse(boundary == 1, "Boundary", "Interior"))]

## CS-DiD treatment variable
## Treatment starts in financial year ending March 2020 (i.e., April 2019 onward)
## For cohort 2019: first_treat = 2020 (year_end when treatment begins)
## For cohort 2022: first_treat = 2023
knife_clean[, first_treat := fcase(
  cohort_year == 2019, 2020L,
  cohort_year == 2022, 2023L,
  default = 0L
)]

## Force ID
knife_clean[, force_id := as.integer(factor(force_std))]

## Post indicator for simple DiD
knife_clean[, post := as.integer(year_end >= 2020)]

## VRU x Post
knife_clean[, vru_post := as.integer(vru == 1 & post == 1)]

## ─────────────────────────────────────────────────────────────────────────────
## 5. Build firearm panel similarly
## ─────────────────────────────────────────────────────────────────────────────
firearm_clean <- firearm[!is.na(year_end) & !is.na(firearm_offences),
                          .(area_code, area_name, year_end, firearm_offences)]
## Clean names for firearm panel too
firearm_clean[, area_name_clean := gsub("\\s*\\[note[^]]*\\]", "", area_name)]
firearm_clean[, area_name_clean := trimws(area_name_clean)]
firearm_clean <- firearm_clean[area_name_clean != "City of London"]

## Deduplicate
firearm_clean <- firearm_clean[, .SD[.N], by = .(area_code, year_end)]

## Clean population names too
pop_clean <- copy(pop)
pop_clean[, area_name_clean := gsub("\\s*\\[note[^]]*\\]", "", area_name)]
pop_clean[, area_name_clean := trimws(area_name_clean)]

firearm_clean <- merge(firearm_clean, pop_clean[, .(area_name_clean, population)],
                        by = "area_name_clean", all.x = TRUE)
firearm_clean[, firearm_rate := (firearm_offences / population) * 100000]

## Merge treatment
firearm_clean <- merge(firearm_clean, treat[, .(force_name, cohort_year, vru)],
                        by.x = "area_name_clean", by.y = "force_name", all.x = TRUE)
firearm_clean[is.na(vru), vru := 0L]
firearm_clean[is.na(cohort_year), cohort_year := 0L]
firearm_clean <- merge(firearm_clean, boundary,
                        by.x = "area_name_clean", by.y = "force_name", all.x = TRUE)
firearm_clean[is.na(boundary), boundary := 0L]
firearm_clean[, force_type := fifelse(vru == 1, "VRU",
                                       fifelse(boundary == 1, "Boundary", "Interior"))]
firearm_clean[, first_treat := fcase(cohort_year == 2019, 2020L,
                                      cohort_year == 2022, 2023L,
                                      default = 0L)]
firearm_clean[, force_id := as.integer(factor(area_name_clean))]
firearm_clean[, post := as.integer(year_end >= 2020)]
firearm_clean[, vru_post := as.integer(vru == 1 & post == 1)]

## ─────────────────────────────────────────────────────────────────────────────
## 6. Summary statistics
## ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat("Knife crime panel:", nrow(knife_clean), "rows\n")
cat("  Forces:", uniqueN(knife_clean$force_std), "\n")
cat("  Years:", paste(range(knife_clean$year_end), collapse = "-"), "\n")
cat("  VRU forces:", uniqueN(knife_clean[vru == 1, force_std]), "\n")
cat("  Boundary forces:", uniqueN(knife_clean[boundary == 1, force_std]), "\n")
cat("  Interior forces:", uniqueN(knife_clean[force_type == "Interior", force_std]), "\n")

cat("\nPre-treatment knife crime rates (per 100k) by force type:\n")
knife_clean[year_end < 2020,
            .(mean = mean(knife_rate, na.rm = TRUE),
              sd = sd(knife_rate, na.rm = TRUE),
              n = .N),
            by = force_type][order(-mean)] |> print()

cat("\nFirearm panel:", nrow(firearm_clean), "rows,",
    uniqueN(firearm_clean$area_name_clean), "forces\n")

## Report forces missing population
missing_pop <- knife_clean[is.na(population), unique(force_std)]
if (length(missing_pop) > 0) {
  cat("\nWARNING: Forces missing population data:", paste(missing_pop, collapse = ", "), "\n")
}

## ─────────────────────────────────────────────────────────────────────────────
## 7. Save analysis panels
## ─────────────────────────────────────────────────────────────────────────────
fwrite(knife_clean, file.path(data_dir, "knife_panel_clean.csv"))
fwrite(firearm_clean, file.path(data_dir, "firearm_panel_clean.csv"))

cat("\nAnalysis panels saved.\n")
