# ==============================================================================
# 02_clean_data.R — Variable construction and panel building
# Paper: The Picture Bride Premium
# ==============================================================================

source("00_packages.R")

dt <- readRDS("../data/census_asian_men.rds")
dt_women <- readRDS("../data/census_asian_women.rds")

# --------------------------------------------------------------------------
# A. Construct key variables
# --------------------------------------------------------------------------

# Race label
dt[, race_label := fifelse(RACE == 4, "Chinese", "Japanese")]

# Japanese indicator
dt[, japanese := as.integer(RACE == 5)]

# Married indicator (MARST: 1=married spouse present, 2=married spouse absent)
# Both 1 and 2 are "married" — key distinction is having a wife in the US
dt[, married := as.integer(MARST %in% c(1, 2))]

# Spouse present — stricter definition of "having a wife"
dt[, spouse_present := as.integer(MARST == 1)]

# Post-picture-bride indicator (1920+)
dt[, post := as.integer(YEAR >= 1920)]

# Treatment: Japanese × Post
dt[, treat := japanese * post]

# Literacy indicator (LIT: 1=No, cannot read or write; 2-4=literate levels)
# IPUMS: LIT 0=N/A, 1=Illiterate, 2=Cannot read but can write, 3=Literate, 4=Read/write
dt[, literate := as.integer(LIT >= 3)]

# Farm owner (FARM=1 means farm; OWNERSHP=1 means owned)
dt[, farm_owner := as.integer(FARM == 2 & OWNERSHP == 1)]

# Age squared
dt[, age_sq := AGE^2]

# --------------------------------------------------------------------------
# B. Alien Land Law (ALI) state indicator
# --------------------------------------------------------------------------

# States that enacted ALI before or during picture bride era
# California 1913, Arizona 1917, Washington 1921, Louisiana 1921,
# New Mexico 1922, Oregon 1923, Idaho 1923, Montana 1923, Kansas 1925
ali_states_1920 <- c(6)  # CA (1913) — only one before 1920 census
ali_states_1930 <- c(6, 4, 53, 22, 35, 41, 16, 30, 20)  # All by 1925

dt[, ali_state := 0L]
dt[YEAR <= 1920 & STATEFIP %in% ali_states_1920, ali_state := 1L]
dt[YEAR > 1920 & STATEFIP %in% ali_states_1930, ali_state := 1L]

# --------------------------------------------------------------------------
# C. Compute sex ratios by state × year × race
# --------------------------------------------------------------------------

sex_ratio <- dt[, .(n_men = .N), by = .(YEAR, STATEFIP, RACE, race_label)]
women_counts <- dt_women[, .(n_women = .N), by = .(YEAR, STATEFIP, RACE)]

sex_ratio <- merge(sex_ratio, women_counts,
                   by = c("YEAR", "STATEFIP", "RACE"), all.x = TRUE)
sex_ratio[is.na(n_women), n_women := 0]
sex_ratio[, sex_ratio := n_men / pmax(n_women, 1)]

cat("=== Sex Ratios (National) ===\n")
nat_sr <- sex_ratio[, .(n_men = sum(n_men), n_women = sum(n_women)),
                    by = .(YEAR, race_label)]
nat_sr[, sex_ratio := round(n_men / pmax(n_women, 1), 1)]
print(nat_sr[order(race_label, YEAR)])

# Merge state-level sex ratio back to individual data
dt <- merge(dt, sex_ratio[, .(YEAR, STATEFIP, RACE, state_sex_ratio = sex_ratio)],
            by = c("YEAR", "STATEFIP", "RACE"), all.x = TRUE)

# --------------------------------------------------------------------------
# D. Restrict to key analysis states (where Japanese presence meaningful)
# --------------------------------------------------------------------------

# Top Japanese states: CA, WA, OR, CO, NY, IL, UT, HI (not in census before 1960)
# Keep all states but flag concentrated ones
dt[, key_state := as.integer(STATEFIP %in% c(6, 53, 41, 8, 36, 17, 49))]

cat("\n=== Sample by state and race (1920) ===\n")
state_tab <- dt[YEAR == 1920, .(N = .N, pct_married = round(100*mean(married), 1)),
                by = .(STATEFIP, race_label)]
state_tab <- dcast(state_tab, STATEFIP ~ race_label, value.var = c("N", "pct_married"))
state_tab <- state_tab[order(-N_Japanese)]
print(head(state_tab, 15))

# --------------------------------------------------------------------------
# E. Summary statistics for analysis sample
# --------------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")

# Main analysis variables by race × year
summ <- dt[, .(
  N = .N,
  mean_age = round(mean(AGE), 1),
  married_pct = round(100 * mean(married), 1),
  spouse_present_pct = round(100 * mean(spouse_present), 1),
  mean_occscore = round(mean(OCCSCORE, na.rm = TRUE), 2),
  literate_pct = round(100 * mean(literate, na.rm = TRUE), 1),
  farm_owner_pct = round(100 * mean(farm_owner, na.rm = TRUE), 1)
), by = .(YEAR, race_label)]

print(summ[order(race_label, YEAR)])

# --------------------------------------------------------------------------
# F. Save cleaned data
# --------------------------------------------------------------------------

saveRDS(dt, "../data/analysis_sample.rds")
saveRDS(sex_ratio, "../data/sex_ratios.rds")

cat("\nCleaned data saved. Analysis sample:", nrow(dt), "observations.\n")
