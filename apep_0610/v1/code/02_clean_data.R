## 02_clean_data.R — Construct analysis dataset with treatment coding
## apep_0610: The Marginal Birth

library(data.table)

panel <- fread("data/natality_panel.csv")
cat(sprintf("Loaded panel: %d rows, %d states, years %d-%d\n",
            nrow(panel), uniqueN(panel$state_abbr),
            min(panel$year), max(panel$year)))

# ====================================================================
# Treatment coding: Post-Dobbs abortion bans
# ====================================================================
# Source: Guttmacher Institute, KFF Abortion Policy Tracker
# Dobbs v. Jackson decided June 24, 2022
#
# Timing for ANNUAL birth data:
#   - Bans enacted June-Sept 2022 affect births starting ~March 2023
#   - For annual data: first_treat = 2023 (first year with substantially affected births)
#   - Exception: Oklahoma (SB612 signed May 25, 2022, predating Dobbs) → still 2023
#
# Treatment groups:
#   Group 1: Total bans (near-complete prohibition) effective 2022 → first_treat = 2023
#   Group 2: Total bans effective 2023 → first_treat = 2023 or 2024
#   Group 3: Gestational limits (6-15 weeks) → first_treat = 2023 or 2024
#   Never-treated: States with no new abortion restrictions post-Dobbs
# ====================================================================

# Total bans effective in 2022 (trigger laws + quick enactment)
# These affect births primarily in 2023 → first_treat = 2023
total_ban_2022 <- c(
  "AL",  # Alabama - trigger law, June 24, 2022
  "AR",  # Arkansas - trigger law, July 24, 2022
  "ID",  # Idaho - trigger law, August 25, 2022
  "KY",  # Kentucky - trigger law, June 24, 2022
  "LA",  # Louisiana - trigger law, June 24, 2022
  "MO",  # Missouri - trigger law, June 24, 2022 (first state)
  "MS",  # Mississippi - trigger law, July 7, 2022
  "OK",  # Oklahoma - SB612 signed May 25, 2022 + trigger post-Dobbs
  "SD",  # South Dakota - trigger law, June 24, 2022
  "TN",  # Tennessee - trigger law, August 25, 2022
  "TX",  # Texas - trigger law, August 25, 2022 (SB8 from Sept 2021 preceded)
  "WV"   # West Virginia - enacted September 16, 2022
)

# Total bans effective in 2023
total_ban_2023 <- c(
  "IN",  # Indiana - September 15, 2022 enacted, blocked, effective January 2023
  "ND"   # North Dakota - effective April 2023
)

# Gestational limits (6-15 weeks) effective in 2022-2023
gest_limit <- c(
  "GA",  # Georgia - 6-week ban, effective July 2022 (blocked, reinstated Oct 2023)
  "OH",  # Ohio - 6-week ban, effective April 2023 (blocked Nov 2023)
  "SC",  # South Carolina - 6-week ban, effective August 2023
  "FL",  # Florida - 15 weeks July 2022, then 6 weeks May 2024
  "NC",  # North Carolina - 12-week ban, effective July 2023
  "NE",  # Nebraska - 12-week ban, effective June 2023
  "IA"   # Iowa - 6-week ban enacted July 2023 (initially blocked, later upheld)
)

# Assign treatment status
panel[, ban_type := "none"]
panel[state_abbr %in% total_ban_2022, ban_type := "total_ban"]
panel[state_abbr %in% total_ban_2023, ban_type := "total_ban"]
panel[state_abbr %in% gest_limit, ban_type := "gest_limit"]

# First treated year (for CS-DiD)
# Key: we code first_treat based on when BIRTHS are first affected
# Bans in 2022 → first affected births in 2023 (9-month pregnancy lag)
panel[, first_treat := 0L]  # 0 = never-treated
panel[state_abbr %in% total_ban_2022, first_treat := 2023L]
panel[state_abbr %in% total_ban_2023, first_treat := 2024L]

# For gestational limits: more complex — partial restriction reduces some abortions
# but doesn't eliminate them. Code based on when effective:
panel[state_abbr == "GA", first_treat := 2023L]  # Effective July 2022, affects births 2023
panel[state_abbr == "FL", first_treat := 2023L]  # 15-week limit July 2022, affects births 2023
panel[state_abbr == "OH", first_treat := 2024L]  # Effective April 2023, then blocked
panel[state_abbr == "SC", first_treat := 2024L]  # Effective August 2023
panel[state_abbr == "NC", first_treat := 2024L]  # Effective July 2023
panel[state_abbr == "NE", first_treat := 2024L]  # Effective June 2023, affects births late 2023/2024
panel[state_abbr == "IA", first_treat := 2024L]  # Enacted July 2023, blocked until June 2024

# Binary treatment indicator (any ban in effect)
panel[, treated := as.integer(first_treat > 0 & year >= first_treat)]

# ====================================================================
# Alternative treatment definitions (for robustness)
# ====================================================================

# Narrow: total bans only (drop gestational limits)
panel[, first_treat_narrow := 0L]
panel[state_abbr %in% total_ban_2022, first_treat_narrow := 2023L]
panel[state_abbr %in% total_ban_2023, first_treat_narrow := 2024L]

# Broad: include all restrictions
panel[, first_treat_broad := first_treat]

# ====================================================================
# Summary
# ====================================================================
cat("\n=== TREATMENT ASSIGNMENT ===\n")
cat(sprintf("Total ban states: %d\n", length(c(total_ban_2022, total_ban_2023))))
cat(sprintf("Gestational limit states: %d\n", length(gest_limit)))
cat(sprintf("Never-treated states: %d\n",
            uniqueN(panel[first_treat == 0]$state_abbr)))

cat("\nTreatment cohorts:\n")
tab <- panel[first_treat > 0, .(states = paste(unique(state_abbr), collapse = ", ")),
             by = first_treat]
for (i in seq_len(nrow(tab))) {
  cat(sprintf("  Cohort %d: %s\n", tab$first_treat[i], tab$states[i]))
}

cat(sprintf("\nPre-treatment years: %d-%d\n",
            min(panel$year), min(panel[first_treat > 0]$first_treat) - 1))
cat(sprintf("Post-treatment years: %d-%d\n",
            min(panel[first_treat > 0]$first_treat), max(panel$year)))

# ====================================================================
# Verify key design parameters
# ====================================================================
n_treated <- uniqueN(panel[first_treat > 0]$state_abbr)
n_control <- uniqueN(panel[first_treat == 0]$state_abbr)
n_pre <- length(unique(panel[year < 2023]$year))

cat(sprintf("\nDesign parameters:\n"))
cat(sprintf("  Treated units: %d states\n", n_treated))
cat(sprintf("  Control units: %d states\n", n_control))
cat(sprintf("  Pre-periods: %d years\n", n_pre))
cat(sprintf("  Post-periods: %d years\n",
            length(unique(panel[year >= 2023]$year))))

stopifnot(n_treated >= 20,
          n_control >= 20,
          n_pre >= 5)

# ====================================================================
# State numeric ID (for fixest/did packages)
# ====================================================================
panel[, state_id := as.integer(as.factor(state_abbr))]

# ====================================================================
# Log total births (extensive margin outcome)
# ====================================================================
panel[, log_births := log(total_births)]

# ====================================================================
# Save
# ====================================================================
fwrite(panel, "data/analysis_panel.csv")
cat(sprintf("\nSaved: data/analysis_panel.csv (%d rows)\n", nrow(panel)))
