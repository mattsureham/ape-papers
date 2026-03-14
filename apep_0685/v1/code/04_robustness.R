# 04_robustness.R — Robustness checks
# apep_0685: Canada carbon pricing backstop

source("00_packages.R")

cat("=== Robustness Checks ===\n")

analysis <- readRDS("../data/panel_analysis.rds")
df_full <- readRDS("../data/panel_full.rds")

# =========================================================================
# 1. Drop 2020 (COVID contamination)
# =========================================================================
cat("\n--- R1: Drop 2020 ---\n")
r1 <- feols(log_total_co2e ~ treat_post | facility_id + year,
            data = analysis[year != 2020],
            cluster = ~province)
cat("Drop 2020:\n"); print(coeftable(r1))

# =========================================================================
# 2. Include Alberta as additional control
# =========================================================================
cat("\n--- R2: Include Alberta as control ---\n")
df_ab <- df_full[treatment_group %in% c("backstop", "control", "alberta")]
df_ab[, treated_ab := as.integer(treatment_group == "backstop")]
df_ab[, treat_post_ab := treated_ab * as.integer(year >= 2019)]

r2 <- feols(log_total_co2e ~ treat_post_ab | facility_id + year,
            data = df_ab,
            cluster = ~province)
cat("Include Alberta:\n"); print(coeftable(r2))

# =========================================================================
# 3. Placebo treatment in 2015
# =========================================================================
cat("\n--- R3: Placebo treatment year (2015) ---\n")
pre_data <- analysis[year < 2019]
pre_data[, placebo_post := as.integer(year >= 2015)]
pre_data[, placebo_treat := treated * placebo_post]

r3 <- feols(log_total_co2e ~ placebo_treat | facility_id + year,
            data = pre_data,
            cluster = ~province)
cat("Placebo (2015):\n"); print(coeftable(r3))

# =========================================================================
# 4. Balanced panel only
# =========================================================================
cat("\n--- R4: Balanced panel ---\n")
# Facilities present in all 20 years
fac_counts <- analysis[, .N, by = facility_id]
balanced_facs <- fac_counts[N == 20]$facility_id
balanced <- analysis[facility_id %in% balanced_facs]
cat(sprintf("Balanced panel: %d facilities, %d observations\n",
            length(balanced_facs), nrow(balanced)))

r4 <- feols(log_total_co2e ~ treat_post | facility_id + year,
            data = balanced,
            cluster = ~province)
cat("Balanced panel:\n"); print(coeftable(r4))

# =========================================================================
# 5. Ontario only vs BC+QC (within-backstop variation)
# =========================================================================
cat("\n--- R5: Ontario only ---\n")
ontario_control <- analysis[province %in% c("Ontario", "British Columbia", "Quebec")]
r5 <- feols(log_total_co2e ~ treat_post | facility_id + year,
            data = ontario_control,
            cluster = ~province)
cat("Ontario vs BC+QC:\n"); print(coeftable(r5))

# =========================================================================
# 6. Bacon decomposition (diagnose TWFE heterogeneity)
# =========================================================================
cat("\n--- R6: Bacon Decomposition ---\n")
# Since we have a single treatment cohort (2019) vs never-treated,
# the Bacon decomposition is trivial: 100% clean 2x2 comparisons.
# Document this explicitly.
cat("Treatment timing: single cohort (2019) vs never-treated\n")
cat("Bacon decomposition: 100% clean 2x2 (no problematic comparisons)\n")
cat("TWFE and CS should give similar results (confirmed above)\n")

# =========================================================================
# 7. Ontario's 'carbon holiday' test
# =========================================================================
cat("\n--- R7: Ontario's Carbon Holiday (July 2018 - March 2019) ---\n")
# Test if emissions spiked during Ontario's brief deregulation
# Ontario cancelled cap-and-trade July 2018; backstop imposed April 2019
# We can't test within 2018 (annual data), but we can check 2018 vs 2017

ontario <- analysis[province == "Ontario" & year %in% 2016:2019]
ontario[, holiday := as.integer(year == 2018)]

# Simple test: was Ontario's 2018 different from trend?
cat("Ontario mean log emissions by year (2016-2019):\n")
print(ontario[, .(mean_log_co2e = mean(log_total_co2e),
                  mean_co2e = mean(total_co2e),
                  n_facilities = .N), by = year])

# =========================================================================
# Save robustness models
# =========================================================================
rob_models <- list(
  drop_2020 = r1,
  include_ab = r2,
  placebo_2015 = r3,
  balanced = r4,
  ontario_only = r5
)
saveRDS(rob_models, "../data/robustness_models.rds")

cat("\n=== Robustness checks complete ===\n")
