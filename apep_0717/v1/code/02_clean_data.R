## 02_clean_data.R — Construct analysis panel for apep_0717
## Benefit cap reduction (November 2016) → temporary accommodation

source("00_packages.R")

data_dir <- "../data"

## =========================================================================
## 1. Extract benefit cap LA data (treatment intensity)
## =========================================================================

cat("=== Extracting benefit cap data ===\n")

## May 2017: Point-in-time capped households by LA (Sheet 7)
cap_raw <- read_ods(file.path(data_dir, "benefit_cap_may2017.ods"), sheet = "7")

## LA data starts after "Local Authority" header row
## Find it: rows where column 2 starts with E0 (LA codes)
la_rows <- which(grepl("^E0", cap_raw[[2]]))
cat("LA rows found:", length(la_rows), "\n")

cap_la <- data.table(
  la_code = as.character(cap_raw[[2]][la_rows]),
  la_name_cap = as.character(cap_raw[[3]][la_rows]),
  capped_hh_may2017 = as.numeric(cap_raw[[4]][la_rows])
)

## Keep only English LAs (E06, E07, E08, E09)
cap_la <- cap_la[grepl("^E0[6789]", la_code)]
cat("English LAs with cap data:", nrow(cap_la), "\n")
cat("Total capped households:", sum(cap_la$capped_hh_may2017, na.rm = TRUE), "\n")
cat("Top 10:\n")
print(cap_la[order(-capped_hh_may2017)][1:10])

## =========================================================================
## 2. Parse TA from annual Table 784 (2009/10 to 2017/18)
## =========================================================================

cat("\n=== Parsing Table 784 annual TA data ===\n")
raw784 <- fread(file.path(data_dir, "table_784_annual.csv"), header = TRUE)
cat("Raw dims:", nrow(raw784), "x", ncol(raw784), "\n")

## Find TA columns
ta_cols <- grep("Total households in temporary accommodation", names(raw784), value = TRUE)
cat("TA columns found:", length(ta_cols), "\n")

## Extract year from column names
ta_years <- as.integer(str_extract(ta_cols, "[0-9]{4}"))
names(ta_cols) <- ta_years

## Build long panel
ta_long <- raw784[, c("ONS code", "Local authority area", "Region"), with = FALSE]
for (yr in ta_years) {
  col_nm <- ta_cols[as.character(yr)]
  ta_long[, paste0("ta_", yr) := as.character(raw784[[col_nm]])]
}

## Keep English LAs only
ta_long <- ta_long[grepl("^E0[6789]", `ONS code`)]
cat("English LAs in Table 784:", nrow(ta_long), "\n")

## Melt to long format
id_cols <- c("ONS code", "Local authority area", "Region")
ta_cols_new <- paste0("ta_", ta_years)
ta_panel <- melt(ta_long, id.vars = id_cols, measure.vars = ta_cols_new,
                 variable.name = "year_var", value.name = "ta_households")
ta_panel[, year := as.integer(str_extract(year_var, "[0-9]+"))]
ta_panel[, year_var := NULL]

## Clean values
ta_panel[, ta_households := as.numeric(gsub("[^0-9.]", "", ta_households))]
setnames(ta_panel, c("ONS code", "Local authority area", "Region"),
         c("la_code", "la_name", "region"))

cat("Panel rows:", nrow(ta_panel), "\n")
cat("Years:", paste(sort(unique(ta_panel$year)), collapse = ", "), "\n")
cat("LAs:", uniqueN(ta_panel$la_code), "\n")
cat("NA TA values:", sum(is.na(ta_panel$ta_households)), "\n")

## =========================================================================
## 3. Population data from NOMIS
## =========================================================================

cat("\n=== Parsing population data ===\n")
pop <- fread(file.path(data_dir, "nomis_population.csv"))

## Clean: extract year from DATE_NAME
pop[, year := as.integer(DATE_NAME)]
pop <- pop[!is.na(year)]
setnames(pop, c("GEOGRAPHY_CODE", "OBS_VALUE"), c("la_code", "population"))
pop <- pop[, .(la_code, year, population)]
pop <- pop[grepl("^E0[6789]", la_code)]
cat("Pop observations:", nrow(pop), "\n")
cat("Years:", paste(sort(unique(pop$year)), collapse = ", "), "\n")

## =========================================================================
## 4. Claimant count data (annual average as control)
## =========================================================================

cat("\n=== Parsing claimant data ===\n")
claimant <- fread(file.path(data_dir, "nomis_claimants.csv"))
claimant[, month_str := DATE_NAME]
claimant[, year := as.integer(substr(month_str, nchar(month_str) - 3, nchar(month_str)))]
claimant <- claimant[!is.na(year)]
setnames(claimant, c("GEOGRAPHY_CODE", "OBS_VALUE"), c("la_code", "claimants"))
claimant <- claimant[grepl("^E0[6789]", la_code)]

## Annual average
claimant_annual <- claimant[, .(claimants = mean(claimants, na.rm = TRUE)), by = .(la_code, year)]
cat("Claimant annual obs:", nrow(claimant_annual), "\n")

## =========================================================================
## 5. Merge into analysis panel
## =========================================================================

cat("\n=== Constructing analysis panel ===\n")

## Merge TA with population
## Population years 2013-2019; TA years 2010-2018 (measured at March of that year)
## For TA measured at March 2016, the relevant pop is mid-2015 or mid-2016
## Use same year (TA year = pop year) as approximation
panel <- merge(ta_panel, pop, by = c("la_code", "year"), all.x = TRUE)

## For years without pop data (2010-2012), use earliest available (2013)
earliest_pop <- pop[year == 2013, .(la_code, pop_2013 = population)]
panel <- merge(panel, earliest_pop, by = "la_code", all.x = TRUE)
panel[is.na(population), population := pop_2013]
panel[, pop_2013 := NULL]

## Merge claimant counts
panel <- merge(panel, claimant_annual, by = c("la_code", "year"), all.x = TRUE)

## Merge treatment intensity (time-invariant)
panel <- merge(panel, cap_la[, .(la_code, capped_hh_may2017)], by = "la_code", all.x = TRUE)

## Create treatment variables
## Treatment: November 2016. TA measured at 31 March each year.
## March 2017 = first post-treatment observation (4 months of exposure)
## March 2018 = second post-treatment observation (16 months of exposure)
panel[, post := as.integer(year >= 2017)]

## Treatment intensity = capped households per 1000 population
panel[, cap_intensity := capped_hh_may2017 / (population / 1000)]

## Per-capita TA rate
panel[, ta_rate := ta_households / (population / 1000)]

## Claimant rate
panel[, claimant_rate := claimants / (population / 1000)]

## =========================================================================
## 6. Sample restrictions and diagnostics
## =========================================================================

## Drop LAs without cap data
panel <- panel[!is.na(cap_intensity)]

## Drop LAs with all-missing TA
panel <- panel[!is.na(ta_households)]

## Focus on 2012-2018 (7 years: 5 pre, 2 post)
panel <- panel[year >= 2012]

cat("\n=== Final Panel ===\n")
cat("Observations:", nrow(panel), "\n")
cat("LAs:", uniqueN(panel$la_code), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Pre-treatment years:", sum(unique(panel$year) < 2017), "\n")
cat("Post-treatment years:", sum(unique(panel$year) >= 2017), "\n")

cat("\nCap intensity distribution:\n")
print(summary(panel[year == 2017, cap_intensity]))

cat("\nTA rate distribution:\n")
print(summary(panel$ta_rate))

cat("\nTop 10 LAs by cap intensity:\n")
top <- panel[year == 2017][order(-cap_intensity)][1:10, .(la_code, la_name, capped_hh_may2017, population, cap_intensity)]
print(top)

cat("\nBottom 10 LAs by cap intensity:\n")
bot <- panel[year == 2017][order(cap_intensity)][1:10, .(la_code, la_name, capped_hh_may2017, population, cap_intensity)]
print(bot)

## London indicator
panel[, london := as.integer(grepl("^E09", la_code))]

## =========================================================================
## 7. Save
## =========================================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis_panel.rds and analysis_panel.csv\n")

## Summary stats for diagnostics
cat("\nBalance check (pre-treatment means by cap intensity tercile):\n")
pre <- panel[year < 2017]
pre[, tercile := cut(cap_intensity, breaks = quantile(cap_intensity, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                     labels = c("Low", "Medium", "High"), include.lowest = TRUE)]
pre_summary <- pre[, .(mean_ta = mean(ta_rate, na.rm = TRUE),
                       mean_pop = mean(population, na.rm = TRUE),
                       mean_claimant = mean(claimant_rate, na.rm = TRUE),
                       n_la = uniqueN(la_code)),
                   by = tercile]
print(pre_summary)
