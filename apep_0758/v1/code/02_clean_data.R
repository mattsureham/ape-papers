# 02_clean_data.R — Build state-year panel for BBCE analysis
source("00_packages.R")

data_dir <- "../data"

# Load data
bbce     <- readRDS(file.path(data_dir, "bbce_timing.rds"))
acs_snap <- readRDS(file.path(data_dir, "acs_snap.rds"))
fred_ur  <- readRDS(file.path(data_dir, "fred_ur.rds"))

# ── Merge SNAP + BBCE timing ──
analysis <- acs_snap %>%
  left_join(bbce %>% select(fips, first_treat, state_abbr), by = c("state_fips" = "fips"))

# Merge unemployment from FRED
fred_merge <- fred_ur %>% select(fips, year, unemp_rate)
analysis <- analysis %>%
  left_join(fred_merge, by = c("state_fips" = "fips", "year"))

# Drop states not in our BBCE panel (territories)
analysis <- analysis %>% filter(!is.na(first_treat))

# Create numeric state ID for did package
analysis <- analysis %>%
  mutate(state_id = as.integer(state_fips))

message(sprintf("Panel: %d obs, %d states, years %d-%d",
                nrow(analysis), n_distinct(analysis$state_fips),
                min(analysis$year), max(analysis$year)))

# How many states adopted during our panel?
first_year <- min(analysis$year)
adopted_in_panel <- sum(bbce$first_treat >= first_year & bbce$first_treat > 0)
always_treated   <- sum(bbce$first_treat > 0 & bbce$first_treat < first_year)
never_treated    <- sum(bbce$first_treat == 0)

message(sprintf("Adopted during panel: %d | Already treated: %d | Never treated: %d",
                adopted_in_panel, always_treated, never_treated))

# For CS-DiD: states already treated at start get first_treat = 0 (excluded)
# or we can set them to first year so they are used as always-treated
# Better: set always-treated to 0 so CS-DiD treats them as "never-treated" comparisons
# This is valid: they provide a counterfactual for late adopters
analysis <- analysis %>%
  mutate(
    # CS-DiD gname: 0 = never/always treated (comparison group)
    gname_cs = ifelse(first_treat >= first_year & first_treat > 0, first_treat, 0L),
    # Binary BBCE indicator for TWFE
    bbce_on  = as.integer(first_treat > 0 & year >= first_treat),
    # Post indicator
    post     = as.integer(year >= first_treat & first_treat > 0)
  )

# Baseline poverty for heterogeneity (use first-year SNAP rate as proxy)
base_snap <- analysis %>%
  filter(year == first_year) %>%
  mutate(high_snap_base = as.integer(snap_rate >= median(snap_rate, na.rm = TRUE))) %>%
  select(state_fips, high_snap_base, snap_rate_base = snap_rate)

analysis <- analysis %>% left_join(base_snap, by = "state_fips")

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Observations: %d\n", nrow(analysis)))
cat(sprintf("States: %d\n", n_distinct(analysis$state_fips)))
cat(sprintf("Years: %d-%d\n", min(analysis$year), max(analysis$year)))
cat(sprintf("Mean SNAP rate: %.3f (SD: %.3f)\n",
            mean(analysis$snap_rate, na.rm = TRUE), sd(analysis$snap_rate, na.rm = TRUE)))
cat(sprintf("Mean unemp rate: %.3f (SD: %.3f)\n",
            mean(analysis$unemp_rate, na.rm = TRUE), sd(analysis$unemp_rate, na.rm = TRUE)))
cat(sprintf("CS-DiD treated groups: %s\n",
            paste(sort(unique(analysis$gname_cs[analysis$gname_cs > 0])), collapse = ", ")))

saveRDS(analysis, file.path(data_dir, "analysis.rds"))
message("Analysis dataset saved.")
