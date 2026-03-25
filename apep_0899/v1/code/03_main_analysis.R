## 03_main_analysis.R — Main regressions
## apep_0899: Finland compulsory education extension
##
## Design:
## - DiD with continuous treatment intensity (pre-reform vocational unemployment)
## - DDD: vocational vs general × high vs low intensity × pre vs post
## - Event study: year-by-year intensity interactions

source("00_packages.R")

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
# Keep all 20 regions including "Unknown" (students with unrecorded region)

cat("Panel: ", nrow(panel), "obs,", n_distinct(panel$region_name), "regions\n")

## ============================================================
## Table 2: Main DiD — Employment outcomes
## ============================================================
cat("\n=== Main Results: Intensity DiD ===\n")

# Primary outcome: employed_pct (employment rate 1yr after graduation)
# Treatment: intensity × post (continuous DiD)

# Spec 1: Basic DiD, vocational only
m1 <- feols(employed_pct ~ intensity:post |
              region_id + year,
            data = filter(panel, sector == "vocational"),
            cluster = ~region_id)
cat("\nSpec 1: Vocational only, basic intensity × post\n")
summary(m1)

# Spec 2: DiD with region × year FE (absorbs common shocks)
# Cannot use region × year FE in this setting because it absorbs treatment!
# Use: sector FE + region FE + year FE
m2 <- feols(employed_pct ~ vocational:intensity:post + vocational:post |
              region_id + year + vocational,
            data = panel,
            cluster = ~region_id)
cat("\nSpec 2: DDD — vocational × intensity × post\n")
summary(m2)

# Spec 3: Full DDD with separate sector-year and sector-region interactions
m3 <- feols(employed_pct ~ vocational:intensity:post + vocational:post +
              intensity:post |
              region_id^vocational + year^vocational,
            data = panel,
            cluster = ~region_id)
cat("\nSpec 3: Full DDD with sector-year and sector-region FE\n")
summary(m3)

# Spec 4: Unemployed pct as outcome
m4 <- feols(unemployed_pct ~ vocational:intensity:post + vocational:post +
              intensity:post |
              region_id^vocational + year^vocational,
            data = panel,
            cluster = ~region_id)
cat("\nSpec 4: Unemployment rate as outcome\n")
summary(m4)

# Spec 5: Student pct as outcome
m5 <- feols(student_pct ~ vocational:intensity:post + vocational:post +
              intensity:post |
              region_id^vocational + year^vocational,
            data = panel,
            cluster = ~region_id)
cat("\nSpec 5: Student continuation rate as outcome\n")
summary(m5)

## ============================================================
## Table 3: Event Study
## ============================================================
cat("\n=== Event Study ===\n")

# Create event time dummies interacted with intensity, vocational sector
# Base period: year 2020 (t = -1)
panel <- panel %>%
  mutate(event_time = year - 2021)

# Vocational only event study
es_voc <- feols(employed_pct ~ i(event_time, intensity, ref = -1) |
                  region_id + year,
                data = filter(panel, sector == "vocational"),
                cluster = ~region_id)
cat("\nEvent study (vocational, employed_pct):\n")
summary(es_voc)

# DDD event study: create interaction manually
panel <- panel %>%
  mutate(voc_intensity = vocational * intensity)

es_ddd <- feols(employed_pct ~ i(event_time, voc_intensity, ref = -1) +
                  i(event_time, intensity, ref = -1) |
                  region_id^vocational + year^vocational,
                data = panel,
                cluster = ~region_id)
cat("\nDDD event study (vocational × intensity by year):\n")
summary(es_ddd)

## ============================================================
## Store results and diagnostics
## ============================================================

# Save diagnostics for validator
# All 19 regions are treated (universal reform, continuous intensity design)
n_treated_regions <- n_distinct(panel$region_name)

n_pre <- panel %>%
  filter(year < 2021) %>%
  pull(year) %>%
  n_distinct()

diag <- list(
  n_treated = n_treated_regions,
  n_pre = n_pre,
  n_obs = nrow(panel)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")

# Save model objects for tables
pre_reform <- read_csv("../data/pre_reform_intensity.csv", show_col_types = FALSE)

save(m1, m2, m3, m4, m5, es_voc, es_ddd, panel, pre_reform,
     file = "../data/main_models.RData")

cat("\n=== Main analysis complete ===\n")
