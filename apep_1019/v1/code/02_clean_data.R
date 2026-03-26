# =============================================================================
# 02_clean_data.R — Construct treatment, clean variables, create analysis sample
# =============================================================================

source("00_packages.R")

cat("Reading analysis panel...\n")
panel <- arrow::read_parquet("../data/analysis_panel.parquet")
setDT(panel)

cat("Rows:", nrow(panel), "| Persons:", uniqueN(panel$histid), "\n")

# ---------------------------------------------------------------------------
# 1. Define state old-age pension adoption years
#    Source: Social Security Board (1937); Epstein (1933); Rubinow (1934)
# ---------------------------------------------------------------------------

# Pre-1930 Census adopters (first_treat = 1930)
early_adopters <- data.table(
  statefip = c(30L, 32L, 55L, 21L, 8L, 24L, 27L, 49L, 56L, 6L),
  adopt_year = c(1923L, 1925L, 1925L, 1926L, 1927L, 1927L, 1929L, 1929L, 1929L, 1929L),
  state_name = c("Montana", "Nevada", "Wisconsin", "Kentucky", "Colorado",
                 "Maryland", "Minnesota", "Utah", "Wyoming", "California")
)

# 1930-1935 adopters (first_treat = 1940)
late_adopters <- data.table(
  statefip = c(36L, 25L, 10L, 16L, 33L, 34L, 54L, 4L, 18L, 23L,
               26L, 31L, 38L, 39L, 41L, 53L, 42L, 19L),
  adopt_year = c(1930L, 1930L, 1931L, 1931L, 1931L, 1931L, 1931L, 1933L, 1933L, 1933L,
                 1933L, 1933L, 1933L, 1933L, 1933L, 1933L, 1934L, 1934L),
  state_name = c("New York", "Massachusetts", "Delaware", "Idaho", "New Hampshire",
                 "New Jersey", "West Virginia", "Arizona", "Indiana", "Maine",
                 "Michigan", "Nebraska", "North Dakota", "Ohio", "Oregon",
                 "Washington", "Pennsylvania", "Iowa")
)

pension_laws <- rbind(early_adopters, late_adopters)
cat("Treated states:", nrow(pension_laws), "(", nrow(early_adopters), "early,",
    nrow(late_adopters), "late )\n")

# ---------------------------------------------------------------------------
# 2. Assign treatment cohorts based on 1920 state of residence (ITT)
# ---------------------------------------------------------------------------
panel[, first_treat := fcase(
  statefip_origin %in% early_adopters$statefip, 1930L,
  statefip_origin %in% late_adopters$statefip, 1940L,
  default = 0L  # never-treated
)]

# Binary treatment indicator (time-varying)
panel[, treated := as.integer(first_treat > 0L & year >= first_treat)]

# Treatment group labels
panel[, treat_group := fcase(
  first_treat == 1930L, "Early (1923-1929)",
  first_treat == 1940L, "Late (1930-1935)",
  default = "Never treated"
)]

cat("\nTreatment assignment:\n")
print(panel[year == 1920, .N, by = treat_group][order(treat_group)])

# ---------------------------------------------------------------------------
# 3. Clean and recode variables
# ---------------------------------------------------------------------------

# IPUMS farm: 1 = non-farm, 2 = farm → recode to 0/1
panel[, farm_binary := as.integer(farm == 2L)]

# Occupational status: occ1950 = 999 means not in labor force
panel[, in_labor_force := as.integer(occ1950 != 999L)]

# Co-resident child in 1920: relate codes 3 (child) or 4 (child-in-law)
# These men lived in their parents' household at baseline
panel[, child_1920 := as.integer(relate_1920_base %in% c(3L, 4L))]

# Small family in 1920 (fewer siblings to share eldercare burden)
panel[, small_family_1920 := as.integer(famsize_1920_base <= 3L)]

# Homeowner (IPUMS ownershp: 1 = owned, 2 = rented)
panel[, homeowner := as.integer(ownershp == 1L)]

# Native-born (nativity: 0 = native)
panel[, native_born := as.integer(nativity %in% c(0L, 1L))]

# Race (IPUMS: 1 = white, 2 = Black)
panel[, white := as.integer(race == 1L)]

# Self-employed (classwkr: 1 = self-employed)
panel[, self_employed := as.integer(classwkr == 1L)]

# ---------------------------------------------------------------------------
# 4. Summary statistics
# ---------------------------------------------------------------------------
cat("\n--- Pre-treatment (1920) summary by treatment group ---\n")
summ <- panel[year == 1920, .(
  N = .N,
  age = mean(age),
  occscore = mean(occscore),
  sei = mean(sei),
  farm_pct = mean(farm_binary) * 100,
  in_lf_pct = mean(in_labor_force) * 100,
  child_pct = mean(child_1920) * 100,
  small_fam_pct = mean(small_family_1920) * 100,
  homeowner_pct = mean(homeowner) * 100,
  native_pct = mean(native_born) * 100,
  white_pct = mean(white) * 100
), by = treat_group]
print(summ)

# ---------------------------------------------------------------------------
# 5. Save cleaned panel
# ---------------------------------------------------------------------------
arrow::write_parquet(panel, "../data/clean_panel.parquet")
cat("\nSaved clean_panel.parquet with", nrow(panel), "rows\n")
