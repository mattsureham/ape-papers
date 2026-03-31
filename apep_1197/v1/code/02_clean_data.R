## 02_clean_data.R — Construct analysis variables for Panic of 1907 study
## Outcome: change in occupational income score (occscore) 1900-1910
## Treatment: state-level Panic of 1907 severity (Wicker 2000; Moen & Tallman 1992)

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# Load raw panel
# ============================================================================
panel <- readRDS(file.path(data_dir, "mlp_panel.rds"))
cat("=== Raw panel loaded ===\n")
cat("Rows:", formatC(nrow(panel), big.mark = ","), "\n")
cat("Columns:", paste(names(panel), collapse = ", "), "\n")

# ============================================================================
# 1. Panic of 1907 severity classification
# ============================================================================
# Based on Wicker (2000) "The Banking Panics of the Gilded Age" and
# Moen & Tallman (1992) "The Bank Panic of 1907"
#
# Core panic states: Major trust company failures, widespread bank runs,
#   clearing house certificate issuance, stock exchange disruption
# Moderate: Secondary bank suspensions, clearing house activity,
#   significant but not systemic disruption
# Low: Minimal direct banking disruption

panic_classification <- data.table(
  statefip_1900 = c(
    # Core panic (3): Trust company epicenter + immediate contagion
    36L, 34L, 9L, 42L, 25L, 44L,
    # Moderate (2): Secondary bank suspensions, clearing house certificates
    17L, 24L, 29L, 39L, 26L, 55L, 27L, 19L, 20L, 31L, 6L, 41L, 53L
  ),
  panic_severity = c(
    rep(3L, 6),   # NY, NJ, CT, PA, MA, RI
    rep(2L, 13)   # IL, MD, MO, OH, MI, WI, MN, IA, KS, NE, CA, OR, WA
  ),
  panic_label = c(
    rep("Core", 6),
    rep("Moderate", 13)
  )
)

# All other states = Low (1)
all_states <- unique(panel$statefip_1900)
low_states <- setdiff(all_states, panic_classification$statefip_1900)
panic_low <- data.table(
  statefip_1900 = low_states,
  panic_severity = 1L,
  panic_label = "Low"
)
panic_classification <- rbind(panic_classification, panic_low)

cat("\n=== Panic severity classification ===\n")
cat("Core panic (3):", sum(panic_classification$panic_severity == 3), "states\n")
cat("Moderate (2):", sum(panic_classification$panic_severity == 2), "states\n")
cat("Low (1):", sum(panic_classification$panic_severity == 1), "states\n")

# Merge onto panel
panel <- merge(panel, panic_classification, by = "statefip_1900", all.x = TRUE)
cat("\nPanic severity distribution in panel:\n")
print(panel[, .N, by = .(panic_severity, panic_label)][order(panic_severity)])

# ============================================================================
# 2. Outcome variable: change in occscore
# ============================================================================
panel[, delta_occscore := occscore_1910 - occscore_1900]

cat("\n=== Outcome: Delta occscore ===\n")
cat("Mean:", round(mean(panel$delta_occscore, na.rm = TRUE), 3), "\n")
cat("SD:", round(sd(panel$delta_occscore, na.rm = TRUE), 3), "\n")
cat("Median:", median(panel$delta_occscore, na.rm = TRUE), "\n")
print(summary(panel$delta_occscore))

# ============================================================================
# 3. Sector classification (based on 1900 occupation)
# ============================================================================
# IPUMS OCC1950 coding:
#   100-199: Agriculture
#   200-299: Trade (sales, retail)
#   300-399: Service
#   500-699: Manufacturing/mechanical
#   700-799: Transport
#   800-899: Clerical
# Banking-dependent sectors: manufacturing, trade, services (need credit/capital)
# Agriculture: relatively insulated from financial panics

panel[, sector := fcase(
  occ1950_1900 >= 100 & occ1950_1900 <= 199, "Agriculture",
  occ1950_1900 >= 200 & occ1950_1900 <= 299, "Trade",
  occ1950_1900 >= 300 & occ1950_1900 <= 399, "Service",
  occ1950_1900 >= 500 & occ1950_1900 <= 699, "Manufacturing",
  occ1950_1900 >= 700 & occ1950_1900 <= 799, "Transport",
  occ1950_1900 >= 800 & occ1950_1900 <= 899, "Clerical",
  occ1950_1900 >= 0   & occ1950_1900 <= 99,  "Professional",
  occ1950_1900 >= 900 & occ1950_1900 <= 970,  "Laborer",
  default = "Other"
)]

# Banking-dependent indicator: manufacturing, trade, services, clerical
# These sectors rely on credit, commercial banking, and trust company financing
panel[, banking_dependent := sector %in% c("Manufacturing", "Trade", "Service", "Clerical")]

cat("\n=== Sector distribution (1900) ===\n")
print(panel[, .(N = .N, pct = round(.N / nrow(panel) * 100, 1),
                mean_occscore_1900 = round(mean(occscore_1900), 1),
                mean_delta = round(mean(delta_occscore), 2)),
            by = sector][order(-N)])

cat("\nBanking-dependent vs agriculture:\n")
print(panel[, .(N = .N, pct = round(.N / nrow(panel) * 100, 1),
                mean_delta = round(mean(delta_occscore), 2)),
            by = banking_dependent])

# ============================================================================
# 4. Control variables
# ============================================================================

# Age polynomial
panel[, age_1900_sq := age_1900^2]

# Race indicator (IPUMS: 1=White, 2=Black, 3+=Other)
panel[, white := as.integer(race_1900 == 1)]
panel[, black := as.integer(race_1900 == 2)]

# Nativity (IPUMS: 0=Native born, 1-5=Foreign born variants)
panel[, foreign_born := as.integer(nativity_1900 >= 3)]  # 3,4,5 = foreign born

# Literacy (IPUMS LIT: 1=No, 2=Cannot determine, 3=Cannot read/write, 4=Can read/write)
# Recode: 4 = literate, everything else = not
panel[, literate_1900 := as.integer(lit_1900 == 4)]
panel[, literate_1910 := as.integer(lit_1910 == 4)]
panel[, delta_literate := literate_1910 - literate_1900]

# Marital status (IPUMS MARST: 1=Married spouse present, 2=Married absent,
#   3=Separated, 4=Divorced, 5=Widowed, 6=Never married)
panel[, married_1900 := as.integer(marst_1900 <= 2)]

# Farm status (IPUMS FARM: 1=Non-farm, 2=Farm)
panel[, on_farm_1900 := as.integer(farm_1900 == 2)]

# Home ownership (IPUMS OWNERSHP: 0=N/A, 1=Owned, 2=Rented)
panel[, owner_1900 := as.integer(ownershp_1900 == 1)]
panel[, owner_1910 := as.integer(ownershp_1910 == 1)]
panel[, delta_ownership := owner_1910 - owner_1900]

# Age groups for heterogeneity
panel[, age_group := fcase(
  age_1900 >= 18 & age_1900 <= 30, "Young (18-30)",
  age_1900 >= 31 & age_1900 <= 50, "Old (31-50)"
)]

# Binary treatment: core panic vs rest
panel[, core_panic := as.integer(panic_severity == 3)]

cat("\n=== Control variable summaries ===\n")
cat("White:", round(mean(panel$white) * 100, 1), "%\n")
cat("Foreign born:", round(mean(panel$foreign_born) * 100, 1), "%\n")
cat("Literate (1900):", round(mean(panel$literate_1900) * 100, 1), "%\n")
cat("Married (1900):", round(mean(panel$married_1900) * 100, 1), "%\n")
cat("On farm (1900):", round(mean(panel$on_farm_1900) * 100, 1), "%\n")
cat("Homeowner (1900):", round(mean(panel$owner_1900) * 100, 1), "%\n")
cat("Age group:\n")
print(panel[, .N, by = age_group])

# ============================================================================
# 5. Filter out observations with missing key variables
# ============================================================================
n_before <- nrow(panel)

# Remove rows with missing occscore (0 might be legitimate for unemployed)
# Keep 0 values — they represent "no occupation" or very low-status work
# Remove if panic_severity is missing (shouldn't happen)
panel <- panel[!is.na(panic_severity)]

# Remove if occupation code suggests non-response (OCC1950 = 995, 997, 999)
panel <- panel[occ1950_1900 < 980 | occ1950_1900 == 0]
panel <- panel[occ1950_1910 < 980 | occ1950_1910 == 0]

n_after <- nrow(panel)
cat("\n=== Filtering ===\n")
cat("Before:", formatC(n_before, big.mark = ","), "\n")
cat("After:", formatC(n_after, big.mark = ","), "\n")
cat("Dropped:", formatC(n_before - n_after, big.mark = ","),
    "(", round((n_before - n_after) / n_before * 100, 1), "%)\n")

# ============================================================================
# 6. Create state-level controls for robustness
# ============================================================================
# County-level urbanization proxy: fraction on farms in 1900
county_urban <- panel[, .(
  county_farm_share = mean(on_farm_1900),
  county_n = .N
), by = .(statefip_1900, county_1900)]

panel <- merge(panel, county_urban, by = c("statefip_1900", "county_1900"), all.x = TRUE)

cat("\n=== County farm share (urbanization proxy) ===\n")
cat("Mean county farm share:", round(mean(panel$county_farm_share, na.rm = TRUE), 3), "\n")
cat("SD:", round(sd(panel$county_farm_share, na.rm = TRUE), 3), "\n")

# ============================================================================
# 7. Summary by panic severity
# ============================================================================
cat("\n=== Summary by panic severity ===\n")
summ <- panel[, .(
  N = .N,
  mean_age = round(mean(age_1900), 1),
  pct_white = round(mean(white) * 100, 1),
  pct_foreign = round(mean(foreign_born) * 100, 1),
  pct_literate = round(mean(literate_1900) * 100, 1),
  pct_married = round(mean(married_1900) * 100, 1),
  pct_farm = round(mean(on_farm_1900) * 100, 1),
  pct_owner = round(mean(owner_1900) * 100, 1),
  mean_occscore_1900 = round(mean(occscore_1900), 2),
  mean_occscore_1910 = round(mean(occscore_1910), 2),
  mean_delta = round(mean(delta_occscore), 3),
  sd_delta = round(sd(delta_occscore), 3),
  pct_banking_dep = round(mean(banking_dependent) * 100, 1)
), by = .(panic_severity, panic_label)]
print(summ[order(panic_severity)])

# ============================================================================
# 8. Save analysis-ready data
# ============================================================================
saveRDS(panel, file.path(data_dir, "analysis_data.rds"))
saveRDS(panic_classification, file.path(data_dir, "panic_classification.rds"))

cat("\n=== Analysis data saved ===\n")
cat("Observations:", formatC(nrow(panel), big.mark = ","), "\n")
cat("States:", length(unique(panel$statefip_1900)), "\n")
cat("Counties:", length(unique(paste(panel$statefip_1900, panel$county_1900))), "\n")
cat("File: data/analysis_data.rds\n")
