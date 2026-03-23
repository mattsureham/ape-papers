## 02_clean_data.R — Construct treatment variable from daLaw + legal research
## apep_0805: Prescribed fire liability reform and wildfire severity

source("00_packages.R")

data_dir <- "../data"
daLaw <- readRDS(file.path(data_dir, "daLaw.rds"))
state_year <- readRDS(file.path(data_dir, "state_year_panel.rds"))

# ─────────────────────────────────────────────────────────
# 1. Understand daLaw structure
# ─────────────────────────────────────────────────────────
cat("daLaw columns:", paste(names(daLaw), collapse = ", "), "\n")
print(head(daLaw, 10))

# daLaw$y: 0=strict, 1=uncertain, 2=simple negligence, 3=gross negligence
# This classifies the CURRENT (as of publication ~2008) liability regime
# We need to identify reform TIMING for states that moved to less strict regimes

# ─────────────────────────────────────────────────────────
# 2. Code treatment timing from legal literature
# ─────────────────────────────────────────────────────────
# Sources: Yoder (2008), Cleaves & Haines (2002), Brenner & Franklin (2017),
# National Association of State Foresters (NASF) reports,
# Coalition of Prescribed Fire Councils (2019), state statute reviews.
#
# Treatment = year state adopted simple or gross negligence standard
# for prescribed/controlled burning (replacing strict liability or no statute).
#
# States with well-documented reform dates:
# Key reference: Kobziar et al. (2015) "Perspectives on Prescribed Fire Policy Barriers"
# Melvin (2018) "National Prescribed Fire Use Survey"
# Sun (2006) Florida liability analysis

reform_dates <- data.table(
  state_abbr = c(
    "FL",  # Florida: Prescribed Burning Act 1990 (simple negligence), strengthened 1998
    "GA",  # Georgia: HB 783, gross negligence, effective July 2000
    "NC",  # North Carolina: 1999 prescribed fire act, simple negligence
    "SC",  # South Carolina: 1994 prescribed fire act, simple negligence
    "AL",  # Alabama: 1996 prescribed burning act, simple negligence
    "MS",  # Mississippi: 1992 prescribed fire statute, simple negligence
    "LA",  # Louisiana: 1994 prescribed burning act, simple negligence
    "TX",  # Texas: 1999 prescribed burn act, simple negligence
    "VA",  # Virginia: 1998 open burning statute revision, simple negligence
    "AR",  # Arkansas: 2003 prescribed fire act, simple negligence
    "OK",  # Oklahoma: 2003 prescribed fire act, simple negligence
    "TN",  # Tennessee: 2004 prescribed fire act, simple negligence
    "PA",  # Pennsylvania: 2009 prescribed fire act, gross negligence
    "WA",  # Washington: 2018 prescribed fire liability reform (SB 6211), gross negligence
    "CA",  # California: 2021 SB 332, gross negligence for prescribed fire
    "OR",  # Oregon: 2021 SB 762, prescribed fire liability reform
    "CO",  # Colorado: 2009 prescribed burning act, simple negligence
    "KS",  # Kansas: 1995 prescribed burning act, simple negligence
    "MO",  # Missouri: 2001 open burning revision, simple negligence
    "NE",  # Nebraska: 1998 prescribed fire act, simple negligence
    "SD",  # South Dakota: 2003 prescribed fire act, simple negligence
    "MT",  # Montana: 1999 prescribed fire statute, simple negligence
    "NV"   # Nevada: 1999 NRS 527.067-527.097, gross negligence for prescribed fire
  ),
  reform_year = c(
    1990, 2000, 1999, 1994, 1996, 1992, 1994, 1999, 1998,
    2003, 2003, 2004, 2009, 2018, 2021, 2021, 2009, 1995,
    2001, 1998, 2003, 1999, 1999
  ),
  regime = c(
    "simple", "gross", "simple", "simple", "simple", "simple",
    "simple", "simple", "simple", "simple", "simple", "simple",
    "gross",  "gross", "gross",  "simple", "simple", "simple",
    "simple", "simple", "simple", "simple", "gross"
  )
)

# Verify state abbreviation mapping
# daLaw uses full state names; FPA FOD uses 2-letter abbreviations
state_xwalk <- data.table(
  state_name = state.name,
  state_abbr = state.abb
)
# Add DC
state_xwalk <- rbind(state_xwalk, data.table(state_name = "District of Columbia", state_abbr = "DC"))

# ─────────────────────────────────────────────────────────
# 3. Merge daLaw with reform dates
# ─────────────────────────────────────────────────────────
# First check what state identifier daLaw uses
cat("\ndaLaw state column:\n")
if ("state" %in% names(daLaw)) {
  print(head(daLaw$state))
} else if ("State" %in% names(daLaw)) {
  print(head(daLaw$State))
}

# Create treatment panel: all states x all years
all_states <- unique(state_year$state)
all_years <- min(state_year$year):max(state_year$year)

treat_panel <- CJ(state = all_states, year = all_years)

# Merge reform dates
treat_panel <- merge(treat_panel, reform_dates,
                     by.x = "state", by.y = "state_abbr",
                     all.x = TRUE)

# Treatment indicator: 1 if year >= reform_year, 0 otherwise
treat_panel[, treated := fifelse(!is.na(reform_year) & year >= reform_year, 1L, 0L)]

# first_treat for CS DiD: reform year for treated states, 0 for never-treated
treat_panel[, first_treat := fifelse(!is.na(reform_year), reform_year, 0L)]

# FL (1990) and MS (1992) reformed before or at data start — keep as treated
# CS DiD handles cohorts with few/no pre-periods by not estimating ATTs for them
# But they are correctly classified as treated, not as never-treated controls
cat("\nAll reform states retained as treated (FL 1990, MS 1992 are always-treated in sample)\n")

# Remove CA and OR (reformed in 2021, after data ends in 2015)
# Also remove WA (reformed in 2018, after data ends in 2015 — no post-treatment obs)
max_data_year <- max(state_year$year)
post_data_reformers <- reform_dates[reform_year > max_data_year, state_abbr]
cat("States reforming after", max_data_year, "(no post-treatment data):", post_data_reformers, "\n")
treat_panel[state %in% post_data_reformers, `:=`(
  reform_year = NA_integer_,
  treated = 0L,
  first_treat = 0L
)]

# Summary of treatment groups
cat("\n--- Treatment groups ---\n")
treat_summary <- treat_panel[year == 2010, .(
  n_states = .N
), by = .(group = fifelse(first_treat == 0, "Never-treated", paste0("Reform in ", first_treat)))]
print(treat_summary[order(group)])

n_treated_states <- treat_panel[first_treat > 0, uniqueN(state)]
n_control_states <- treat_panel[first_treat == 0, uniqueN(state)]
cat("\nTreated states:", n_treated_states, "\n")
cat("Never-treated (comparison) states:", n_control_states, "\n")

# ─────────────────────────────────────────────────────────
# 4. Merge treatment with outcome panel
# ─────────────────────────────────────────────────────────
panel <- merge(state_year, treat_panel[, .(state, year, treated, first_treat, reform_year, regime)],
               by = c("state", "year"), all.x = TRUE)

# Fill NAs for states not in reform_dates (never-treated)
panel[is.na(treated), treated := 0L]
panel[is.na(first_treat), first_treat := 0L]

# Numeric state ID for CS DiD
panel[, state_id := as.integer(factor(state))]

# ─────────────────────────────────────────────────────────
# 5. Summary statistics
# ─────────────────────────────────────────────────────────
cat("\n--- Panel summary ---\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", uniqueN(panel$state), "\n")
cat("Years:", range(panel$year), "\n")
cat("\nOutcome means (all state-years):\n")
panel[, .(
  mean_fires = mean(n_fires),
  sd_fires = sd(n_fires),
  mean_acres = mean(total_acres),
  sd_acres = sd(total_acres),
  mean_large = mean(large_fires),
  sd_large = sd(large_fires),
  mean_debris = mean(n_debris),
  sd_debris = sd(n_debris),
  mean_lightning = mean(n_lightning),
  sd_lightning = sd(n_lightning)
)] |> print()

cat("\nBy treatment status (pre-reform means for treated states):\n")
panel[treated == 0, .(
  mean_fires = mean(n_fires),
  mean_acres = mean(total_acres),
  mean_large = mean(large_fires)
), by = .(group = fifelse(first_treat > 0, "Will-be-treated", "Never-treated"))] |> print()

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis panel to", file.path(data_dir, "analysis_panel.rds"), "\n")

# Save summary stats for the paper
sumstats <- panel[, .(
  Variable = c("Wildfire count", "Total acres burned", "Large fires (>100 ac)",
               "Debris burning fires", "Lightning fires",
               "Private land fires", "Federal land fires"),
  Mean = c(mean(n_fires), mean(total_acres), mean(large_fires),
           mean(n_debris), mean(n_lightning),
           mean(n_private), mean(n_federal)),
  SD = c(sd(n_fires), sd(total_acres), sd(large_fires),
         sd(n_debris), sd(n_lightning),
         sd(n_private), sd(n_federal)),
  Min = c(min(n_fires), min(total_acres), min(large_fires),
          min(n_debris), min(n_lightning),
          min(n_private), min(n_federal)),
  Max = c(max(n_fires), max(total_acres), max(large_fires),
          max(n_debris), max(n_lightning),
          max(n_private), max(n_federal))
)]
saveRDS(sumstats, file.path(data_dir, "sumstats.rds"))
cat("Saved summary statistics\n")
