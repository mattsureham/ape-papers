# ─────────────────────────────────────────────
# 02_clean_data.R — Merge SIH, population, and treatment data
# ─────────────────────────────────────────────

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")

# ─────────────────────────────────────────────
# 1. Load datasets
# ─────────────────────────────────────────────
cat("Loading datasets...\n")

sih <- fread(file.path(DATA_DIR, "sih_waterborne.csv"), colClasses = c(muni_code = "character"))
pop <- fread(file.path(DATA_DIR, "ibge_population.csv"), colClasses = c(muni_code = "character"))
treatment <- fread(file.path(DATA_DIR, "treatment_panel.csv"), colClasses = c(muni_code = "character"))

cat(sprintf("  SIH: %d rows, %d municipalities\n", nrow(sih), uniqueN(sih$muni_code)))
cat(sprintf("  Population: %d rows, %d municipalities\n", nrow(pop), uniqueN(pop$muni_code)))
cat(sprintf("  Treatment: %d treated municipalities\n", nrow(treatment)))

# ─────────────────────────────────────────────
# 2. Standardize municipality codes
# ─────────────────────────────────────────────
# DATASUS uses 6-digit muni codes (no check digit)
# IBGE and treatment use 7-digit codes
# Strategy: use 6-digit matching throughout

# Create 6-digit versions for matching
pop[, muni6 := substr(muni_code, 1, 6)]
treatment[, muni6 := substr(muni_code, 1, 6)]
sih[, muni6 := sprintf("%06d", as.integer(muni_code))]

# Build 6-to-7 digit crosswalk from IBGE
xwalk <- unique(pop[, .(muni6, muni_code7 = muni_code)])
xwalk <- xwalk[!duplicated(muni6)]

# Map SIH to 7-digit codes via crosswalk
sih <- merge(sih, xwalk, by = "muni6", all.x = TRUE)
sih[!is.na(muni_code7), muni_code := muni_code7]
sih[, muni_code7 := NULL]

# Verify match rate
ibge_munis <- unique(pop$muni_code)
sih_match <- sum(unique(sih$muni_code) %in% ibge_munis)
cat(sprintf("  SIH-IBGE match: %d / %d municipalities (%.0f%%)\n",
            sih_match, uniqueN(sih$muni_code),
            100 * sih_match / uniqueN(sih$muni_code)))

# Clean up temporary columns
sih[, muni6 := NULL]
pop[, muni6 := NULL]
treatment[, muni6 := NULL]

# ─────────────────────────────────────────────
# 2b. Extrapolate population for 2023
# ─────────────────────────────────────────────
# IBGE API has population through 2022; use 2022 values for 2023
pop_2022 <- pop[year == 2022]
pop_2023 <- copy(pop_2022)
pop_2023[, year := 2023L]
pop <- rbind(pop, pop_2023)
cat(sprintf("  Population extended to 2023 (%d municipality-year obs)\n", nrow(pop)))

# ─────────────────────────────────────────────
# 3. Merge SIH + Population
# ─────────────────────────────────────────────
cat("Merging SIH with population...\n")

# Ensure year types match
sih[, year := as.integer(year)]
pop[, year := as.integer(year)]

panel <- merge(sih, pop, by = c("muni_code", "year"), all.x = TRUE)

# Drop obs without population (can't compute rates)
n_before <- nrow(panel)
panel <- panel[!is.na(population) & population > 0]
cat(sprintf("  Dropped %d obs without population data\n", n_before - nrow(panel)))

# ─────────────────────────────────────────────
# 4. Compute hospitalization rates
# ─────────────────────────────────────────────
panel[, `:=`(
  hosp_rate = n_hosp / population * 100000,       # per 100K
  under5_rate = n_under5 / population * 100000,    # per 100K (total pop denom)
  cost_per_cap = total_cost / population * 1000    # per 1000 pop in BRL
)]

# ─────────────────────────────────────────────
# 5. Add treatment variable
# ─────────────────────────────────────────────
cat("Adding treatment variable...\n")

# Treatment year = first full year of private operation
treat_info <- treatment[, .(treatment_year = min(treatment_year), wave = first(wave)), by = muni_code]

panel <- merge(panel, treat_info, by = "muni_code", all.x = TRUE)

# Never-treated municipalities get treatment_year = 0 (for CS estimator)
panel[is.na(treatment_year), treatment_year := 0L]
panel[is.na(wave), wave := "never_treated"]

# Binary treatment indicator
panel[, treated := as.integer(treatment_year > 0 & year >= treatment_year)]

# ─────────────────────────────────────────────
# 6. Add state and region identifiers
# ─────────────────────────────────────────────
panel[, state_code := substr(muni_code, 1, 2)]
panel[, region := fcase(
  state_code %in% c("27", "28", "26", "29"), "Northeast",  # AL, SE, PE, BA
  state_code %in% c("33", "35", "31", "32"), "Southeast",  # RJ, SP, MG, ES
  state_code %in% c("43", "42", "41"), "South",            # RS, SC, PR
  default = "Other"
)]

# ─────────────────────────────────────────────
# 7. Summary statistics
# ─────────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat(sprintf("Total: %d municipality-year obs, %d municipalities, %d years\n",
            nrow(panel), uniqueN(panel$muni_code), uniqueN(panel$year)))

cat("\nBy treatment status:\n")
print(panel[, .(
  n_munis = uniqueN(muni_code),
  mean_hosp_rate = round(mean(hosp_rate, na.rm = TRUE), 2),
  sd_hosp_rate = round(sd(hosp_rate, na.rm = TRUE), 2),
  mean_pop = round(mean(population, na.rm = TRUE), 0)
), by = .(ever_treated = treatment_year > 0)])

cat("\nBy wave:\n")
print(panel[, .(
  n_munis = uniqueN(muni_code),
  treatment_year = first(treatment_year)
), by = wave])

cat("\nBy year:\n")
print(panel[, .(
  total_hosp = sum(n_hosp),
  mean_rate = round(mean(hosp_rate, na.rm = TRUE), 2),
  n_munis = uniqueN(muni_code)
), by = year][order(year)])

# ─────────────────────────────────────────────
# 8. Winsorize extreme values
# ─────────────────────────────────────────────
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}

panel[, hosp_rate_w := winsorize(hosp_rate)]
panel[, under5_rate_w := winsorize(under5_rate)]

# ─────────────────────────────────────────────
# 9. Save analysis-ready panel
# ─────────────────────────────────────────────
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("\nAnalysis panel saved: %d rows\n", nrow(panel)))

# Also save summary stats for the paper
sumstats <- panel[, .(
  Variable = c("Waterborne hosp. rate (per 100K)", "Under-5 hosp. rate (per 100K)",
               "Cost per capita (BRL/1000)", "Population", "Treated"),
  Mean = round(c(mean(hosp_rate), mean(under5_rate), mean(cost_per_cap),
                 mean(population), mean(treated)), 2),
  SD = round(c(sd(hosp_rate), sd(under5_rate), sd(cost_per_cap),
               sd(population), sd(treated)), 2),
  Min = round(c(min(hosp_rate), min(under5_rate), min(cost_per_cap),
                min(population), min(treated)), 2),
  Max = round(c(max(hosp_rate), max(under5_rate), max(cost_per_cap),
                max(population), max(treated)), 2)
)]
fwrite(sumstats, file.path(DATA_DIR, "summary_stats.csv"))
cat("Summary statistics saved.\n")
