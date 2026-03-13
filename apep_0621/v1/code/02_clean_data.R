# =============================================================================
# 02_clean_data.R — Clean and construct analysis datasets
# APEP Working Paper apep_0621
# =============================================================================

source("00_packages.R")

# Load raw data
panel_short <- readRDS("../data/panel_short.rds")
state_cl_raw <- readRDS("../data/state_child_labor_raw.rds")
state_long <- readRDS("../data/state_long_run.rds")
mp_dates <- readRDS("../data/mp_adoption_dates.rds")

# =============================================================================
# 1. Short-run panel (state × year, 1910-1920)
# =============================================================================
cat("=== Cleaning short-run panel ===\n")

# For CS-DiD: need panel with state ID, year, first_treat, outcomes
# Bucket MP adoption into census-compatible cohorts
# Since censuses are 1910 and 1920, treatments 1911-1919 all fall between
# We create adoption cohorts: 1911, 1913, 1915, 1917, 1919, never (0)
panel_short$cohort_group <- cut(panel_short$mp_year,
                                breaks = c(-Inf, 0.5, 1912, 1914, 1916, 1918, 1920, Inf),
                                labels = c("Never", "1911", "1913", "1915", "1917", "1919", "Post-1920"),
                                right = TRUE)

cat("Panel short dimensions: ", nrow(panel_short), " rows, ", ncol(panel_short), " cols\n")
cat("States by cohort group:\n")
print(table(panel_short$cohort_group[panel_short$year == 1910]))

# Create treated indicator (adopted by 1919)
panel_short$treated_by_1920 <- as.integer(panel_short$mp_year > 0 & panel_short$mp_year <= 1919)
panel_short$post <- as.integer(panel_short$year == 1920)

# For the 2x2 DiD: change in outcomes
state_changes <- state_cl_raw[, c("statefip", "n_children", "child_labor_1910",
                                   "school_attend_1910", "child_labor_1920",
                                   "school_attend_1920", "share_male", "share_white",
                                   "mean_age_1910")]
state_changes$delta_child_labor <- state_changes$child_labor_1920 - state_changes$child_labor_1910
state_changes$delta_school <- state_changes$school_attend_1920 - state_changes$school_attend_1910
state_changes <- merge(state_changes, mp_dates[, c("statefip", "mp_year", "state_name")],
                       by = "statefip", all.x = TRUE)
state_changes$mp_year[is.na(state_changes$mp_year)] <- 0
state_changes$treated_by_1920 <- as.integer(state_changes$mp_year > 0 & state_changes$mp_year <= 1919)

# Southern states indicator (for restricted sample)
southern_fips <- c(1, 5, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54)
state_changes$southern <- as.integer(state_changes$statefip %in% southern_fips)
panel_short$southern <- as.integer(panel_short$statefip %in% southern_fips)

saveRDS(panel_short, "../data/panel_short_clean.rds")
saveRDS(state_changes, "../data/state_changes.rds")

# =============================================================================
# 2. Long-run cross-section (state level, 1920 baseline → 1940 outcomes)
# =============================================================================
cat("\n=== Cleaning long-run data ===\n")

# Continuous treatment: years of MP exposure for children aged 0-10 in 1920
# Children born ~1910-1920; MP adopted mp_year
# Average exposure = max(0, 1920 - max(mp_year, birth_year_approx))
# Since average age in 1920 is ~5, average birth year is ~1915
# Exposure = years from MP adoption to 1920 (capped at child's age)
state_long$mp_exposure <- ifelse(state_long$mp_year > 0,
                                  pmax(0, 1920 - state_long$mp_year),
                                  0)
state_long$treated <- as.integer(state_long$mp_year > 0 & state_long$mp_year <= 1919)
state_long$southern <- as.integer(state_long$statefip %in% southern_fips)

# Early adopters (1911-1913) vs middle (1915-1917) vs late (1918-1919) vs never
state_long$adoption_group <- cut(state_long$mp_year,
                                  breaks = c(-Inf, 0.5, 1914, 1918, 1920, Inf),
                                  labels = c("Never", "Early (1911-1913)",
                                             "Middle (1915-1917)", "Late (1918-1919)",
                                             "Post-1920"))

cat("Long-run data: ", nrow(state_long), " states\n")
cat("Treated (adopted by 1919): ", sum(state_long$treated), " states\n")
cat("Mean SEI by group:\n")
print(aggregate(mean_sei_1940 ~ adoption_group, data = state_long, mean))

saveRDS(state_long, "../data/state_long_clean.rds")

# =============================================================================
# 3. Summary statistics
# =============================================================================
cat("\n=== Computing summary statistics ===\n")

# Short-run panel summary
summ_short <- data.frame(
  Variable = c("Child labor rate (1910)", "Child labor rate (1920)",
                "School attendance (1910)", "School attendance (1920)",
                "Share male", "Share white", "N children per state"),
  Mean = c(mean(state_cl_raw$child_labor_1910),
           mean(state_cl_raw$child_labor_1920),
           mean(state_cl_raw$school_attend_1910),
           mean(state_cl_raw$school_attend_1920),
           mean(state_cl_raw$share_male),
           mean(state_cl_raw$share_white),
           mean(state_cl_raw$n_children)),
  SD = c(sd(state_cl_raw$child_labor_1910),
         sd(state_cl_raw$child_labor_1920),
         sd(state_cl_raw$school_attend_1910),
         sd(state_cl_raw$school_attend_1920),
         sd(state_cl_raw$share_male),
         sd(state_cl_raw$share_white),
         sd(state_cl_raw$n_children)),
  Min = c(min(state_cl_raw$child_labor_1910),
          min(state_cl_raw$child_labor_1920),
          min(state_cl_raw$school_attend_1910),
          min(state_cl_raw$school_attend_1920),
          min(state_cl_raw$share_male),
          min(state_cl_raw$share_white),
          min(state_cl_raw$n_children)),
  Max = c(max(state_cl_raw$child_labor_1910),
          max(state_cl_raw$child_labor_1920),
          max(state_cl_raw$school_attend_1910),
          max(state_cl_raw$school_attend_1920),
          max(state_cl_raw$share_male),
          max(state_cl_raw$share_white),
          max(state_cl_raw$n_children))
)

saveRDS(summ_short, "../data/summary_short.rds")

# Long-run summary
summ_long <- data.frame(
  Variable = c("SEI (1940)", "Occscore (1940)", "Labor force participation (1940)",
                "Farm residence (1940)", "Home ownership (1940)",
                "School attendance (1930)", "MP exposure (years)",
                "N children per state"),
  Mean = c(mean(state_long$mean_sei_1940, na.rm = TRUE),
           mean(state_long$mean_occscore_1940, na.rm = TRUE),
           mean(state_long$lfp_1940, na.rm = TRUE),
           mean(state_long$farm_1940, na.rm = TRUE),
           mean(state_long$homeowner_1940, na.rm = TRUE),
           mean(state_long$school_attend_1930, na.rm = TRUE),
           mean(state_long$mp_exposure),
           mean(state_long$n_children)),
  SD = c(sd(state_long$mean_sei_1940, na.rm = TRUE),
         sd(state_long$mean_occscore_1940, na.rm = TRUE),
         sd(state_long$lfp_1940, na.rm = TRUE),
         sd(state_long$farm_1940, na.rm = TRUE),
         sd(state_long$homeowner_1940, na.rm = TRUE),
         sd(state_long$school_attend_1930, na.rm = TRUE),
         sd(state_long$mp_exposure),
         sd(state_long$n_children))
)

saveRDS(summ_long, "../data/summary_long.rds")

cat("\nShort-run summary:\n")
print(summ_short, row.names = FALSE)
cat("\nLong-run summary:\n")
print(summ_long, row.names = FALSE)
cat("\nData cleaning complete.\n")
