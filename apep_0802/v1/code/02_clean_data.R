## 02_clean_data.R — Construct analysis panels
## apep_0802

source("00_packages.R")

## Load raw data
region_type <- readRDS("../data/region_type.rds")
ta_consents <- readRDS("../data/ta_consents.rds")
bonds_long  <- readRDS("../data/bonds_long.rds")
pop         <- readRDS("../data/pop.rds")

## ========================================================================
## PANEL A: Region × Dwelling Type × Month (Primary specification)
## ========================================================================

# Convert date
region_type[, date := as.Date(date)]
region_type[, ym := as.integer(format(date, "%Y")) * 12L +
              as.integer(format(date, "%m"))]

# Keep only Houses and Multi-unit (drop Total to avoid collinearity)
panel_A <- region_type[dwelling_type %in% c("Houses", "Multi-unit")]

# Create binary indicator: 1 = Multi-unit (rental-oriented), 0 = Houses
panel_A[, multi := as.integer(dwelling_type == "Multi-unit")]

# Policy timing indicators
# Oct 2021: First reduction (100% → 75%)
# Apr 2022: Second step (75% → 50%)
# Apr 2023: Third step (50% → 25%)
# Apr 2024: Restoration to 80% (reversal)
# Apr 2025: Full restoration to 100%
panel_A[, policy_phase := fcase(
  date < as.Date("2021-10-01"), "pre",
  date < as.Date("2022-04-01"), "phase1",  # 75% deductible
  date < as.Date("2023-04-01"), "phase2",  # 50% deductible
  date < as.Date("2024-04-01"), "phase3",  # 25% deductible
  date < as.Date("2025-04-01"), "reversal1", # 80% restored
  default = "reversal2"  # 100% restored
)]

# New-build premium: tax advantage of new builds over existing
# = (1 - deductibility_existing / deductibility_new)
panel_A[, new_build_premium := fcase(
  date < as.Date("2021-10-01"), 0,
  date < as.Date("2022-04-01"), 0.25,   # 100% vs 75%
  date < as.Date("2023-04-01"), 0.50,   # 100% vs 50%
  date < as.Date("2024-04-01"), 0.75,   # 100% vs 25%
  date < as.Date("2025-04-01"), 0.20,   # 100% vs 80%
  default = 0                            # 100% vs 100%
)]

# Event time relative to Oct 2021
ref_ym <- 2021L * 12L + 10L  # Oct 2021
panel_A[, event_time := ym - ref_ym]

# Region-dwelling_type ID for FE
panel_A[, region_type_id := paste0(region, "_", dwelling_type)]
panel_A[, region_id := as.integer(factor(region))]

cat("Panel A: ", nrow(panel_A), "rows,",
    uniqueN(panel_A$region), "regions,",
    "date range:", as.character(min(panel_A$date)), "to",
    as.character(max(panel_A$date)), "\n")

# Summary stats
cat("\nConsents by type (monthly mean):\n")
print(panel_A[, .(mean_consents = round(mean(consents), 1),
                   sd_consents = round(sd(consents), 1)),
               by = dwelling_type])

## ========================================================================
## PANEL B: TA × Month (Secondary specification)
## ========================================================================

ta_consents[, date := as.Date(date)]
ta_consents[, ym := as.integer(format(date, "%Y")) * 12L +
              as.integer(format(date, "%m"))]

# Get pre-reform rental intensity from Oct 2020 bonds data
bonds_oct2020 <- bonds_long[date == as.Date("2020-10-01"),
                            .(ta, active_bonds)]

# Harmonize TA names between bonds (old MBIE names) and consents (Stats NZ)
# MBIE uses pre-amalgamation Auckland names; Stats NZ uses post-2010 names
# Sum Auckland sub-areas from MBIE data
auck_tas <- c("Auckland", "Manukau", "North Shore", "Waitakere",
              "Papakura District", "Rodney District", "Franklin District")
auck_total <- bonds_long[date == as.Date("2020-10-01") & ta %in% auck_tas,
                         sum(active_bonds, na.rm = TRUE)]

# Add consolidated Auckland
bonds_oct2020 <- rbind(
  bonds_oct2020[!ta %in% auck_tas],
  data.table(ta = "Auckland", active_bonds = auck_total)
)

# Fuzzy match TA names (handle "District" suffix differences)
bonds_oct2020[, ta_clean := gsub(" District$", "", ta)]
ta_consents[, ta_clean := gsub(" district$", "", ta, ignore.case = TRUE)]
ta_consents[, ta_clean := gsub(" city$", "", ta_clean, ignore.case = TRUE)]

# Merge population (use 2023 as middle of study period)
pop_2023 <- pop[year == 2023, .(ta, population)]
pop_2023[, ta_clean := gsub(" district$| city$| District$| City$", "", ta)]

# Merge bonds with consents
panel_B <- merge(ta_consents, bonds_oct2020[, .(ta_clean, active_bonds)],
                 by = "ta_clean", all.x = TRUE)
panel_B <- merge(panel_B, pop_2023[, .(ta_clean, population)],
                 by = "ta_clean", all.x = TRUE)

# Compute exposure: active bonds per 1000 population
panel_B[, bonds_per_1k := active_bonds / population * 1000]
panel_B[, consents_per_1k := consents / population * 1000]

# Same policy timing as Panel A
panel_B[, event_time := ym - ref_ym]
panel_B[, new_build_premium := fcase(
  date < as.Date("2021-10-01"), 0,
  date < as.Date("2022-04-01"), 0.25,
  date < as.Date("2023-04-01"), 0.50,
  date < as.Date("2024-04-01"), 0.75,
  date < as.Date("2025-04-01"), 0.20,
  default = 0
)]

panel_B[, ta_id := as.integer(factor(ta))]

# Drop TAs without bonds data or population
n_before <- uniqueN(panel_B$ta)
panel_B <- panel_B[!is.na(bonds_per_1k) & !is.na(population) & population > 0]
n_after <- uniqueN(panel_B$ta)
cat("\nPanel B: Dropped", n_before - n_after, "TAs without bonds/pop data.",
    n_after, "TAs remain.\n")
cat("Panel B:", nrow(panel_B), "rows,",
    "date range:", as.character(min(panel_B$date)), "to",
    as.character(max(panel_B$date)), "\n")

# Summary of exposure variable
cat("\nBonds per 1000 population (exposure):\n")
cat("  Mean:", round(mean(panel_B$bonds_per_1k[panel_B$event_time == 0], na.rm = TRUE), 1), "\n")
cat("  SD:", round(sd(panel_B$bonds_per_1k[panel_B$event_time == 0], na.rm = TRUE), 1), "\n")
cat("  Range:", round(min(panel_B$bonds_per_1k[panel_B$event_time == 0], na.rm = TRUE), 1),
    "to", round(max(panel_B$bonds_per_1k[panel_B$event_time == 0], na.rm = TRUE), 1), "\n")

## Save panels
saveRDS(panel_A, "../data/panel_A.rds")
saveRDS(panel_B, "../data/panel_B.rds")

cat("\n✓ Analysis panels constructed.\n")
