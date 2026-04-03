# 04_robustness.R — Robustness checks for apep_1342
# UK FCA HCSTC Price Cap: Supply-Side Destruction

source("00_packages.R")

data_dir <- "../data"

market_panel <- readRDS(file.path(data_dir, "market_panel.rds"))
regional_panel <- readRDS(file.path(data_dir, "regional_panel.rds"))
firm_exits <- readRDS(file.path(data_dir, "firm_exits.rds"))
boe_panel <- readRDS(file.path(data_dir, "boe_panel.rds"))

# Add derived variables needed for robustness
market_panel <- market_panel %>%
  mutate(
    trend = row_number(),
    phase1 = as.integer(phase == "phase1_cap"),
    phase2 = as.integer(phase == "phase2_compensation"),
    phase3 = as.integer(phase == "phase3_steady_state"),
    trend_phase1 = trend * phase1,
    trend_phase2 = trend * phase2,
    trend_phase3 = trend * phase3
  )

# ============================================================================
# 1. Placebo: Pre-cap trends
# ============================================================================
cat("=== Robustness 1: Pre-cap trends ===\n")

# Test for pre-existing trends in pre-cap period (2012-2014)
pre_cap <- market_panel %>% filter(post_cap == 0)

r1_pretrend_loans <- feols(ln_loans ~ trend, data = pre_cap)
r1_pretrend_firms <- feols(ln_firms ~ trend, data = pre_cap)

cat("Pre-cap trend in loans: ", round(coef(r1_pretrend_loans)["trend"], 4),
    " (p=", round(pvalue(r1_pretrend_loans)["trend"], 3), ")\n")
cat("Pre-cap trend in firms: ", round(coef(r1_pretrend_firms)["trend"], 4),
    " (p=", round(pvalue(r1_pretrend_firms)["trend"], 3), ")\n")

# ============================================================================
# 2. Placebo: OFT transfer period (April 2014) as false treatment
# ============================================================================
cat("\n=== Robustness 2: OFT transfer placebo ===\n")

# The OFT-to-FCA transfer in April 2014 was administrative, not a price shock
# Use this as a placebo treatment date
pre_cap_extended <- market_panel %>%
  filter(date < as.Date("2015-01-02")) %>%
  mutate(post_oft = as.integer(date >= as.Date("2014-04-01")))

r2_oft_placebo <- feols(ln_loans ~ post_oft, data = pre_cap_extended)
cat("OFT transfer placebo effect on loans: ", round(coef(r2_oft_placebo)["post_oft"], 4),
    " (p=", round(pvalue(r2_oft_placebo)["post_oft"], 3), ")\n")

# ============================================================================
# 3. Phase 2 as placebo for Phase 1 mechanism
# ============================================================================
cat("\n=== Robustness 3: Compensation-wave placebo ===\n")

# If the cap drives exit in Phase 1, compensation drives exit in Phase 2
# Test that Phase 2 exits cluster AFTER compensation events, not during Phase 1

phase1_exits <- firm_exits %>% filter(phase == "phase1")
phase2_exits <- firm_exits %>% filter(phase == "phase2")

cat("Phase 1 exits — all before Aug 2018: ",
    all(phase1_exits$exit_date < as.Date("2018-08-01")), "\n")
cat("Phase 2 exits — all after Jan 2018: ",
    all(phase2_exits$exit_date > as.Date("2018-01-01")), "\n")
cat("No Phase 1 exits after Wonga collapse: ",
    all(phase1_exits$exit_date < as.Date("2018-08-30")), "\n")

# Rate of exit by phase
phase1_duration_months <- as.numeric(difftime(as.Date("2018-08-01"),
                                               as.Date("2015-01-02"),
                                               units = "days")) / 30.44
phase2_duration_months <- as.numeric(difftime(as.Date("2020-03-01"),
                                               as.Date("2018-08-01"),
                                               units = "days")) / 30.44

cat("Phase 1 exit rate: ", round(nrow(phase1_exits) / phase1_duration_months, 2),
    " firms/month (over ", round(phase1_duration_months, 0), " months)\n")
cat("Phase 2 exit rate: ", round(nrow(phase2_exits) / phase2_duration_months, 2),
    " firms/month (over ", round(phase2_duration_months, 0), " months)\n")

# ============================================================================
# 4. Alternative specifications for aggregate collapse
# ============================================================================
cat("\n=== Robustness 4: Alternative specifications ===\n")

# Level rather than log
r4_level_loans <- feols(total_loans_000 ~ phase1 + phase2 + phase3 +
                          trend_phase1 + trend_phase2 + trend_phase3,
                        data = market_panel,
                        vcov = NW ~ yearqtr)

cat("\n--- Level Specification (Loans '000) ---\n")
summary(r4_level_loans)

# Index specification
r4_index <- feols(loans_index ~ phase1 + phase2 + phase3,
                  data = market_panel,
                  vcov = NW ~ yearqtr)

cat("\n--- Index Specification (2013Q3 = 100) ---\n")
summary(r4_index)

# ============================================================================
# 5. Regional heterogeneity: North vs South
# ============================================================================
cat("\n=== Robustness 5: North-South heterogeneity ===\n")

regional_panel <- regional_panel %>%
  mutate(
    north = as.integer(region %in% c("North East", "North West",
                                      "Yorkshire and The Humber",
                                      "Scotland", "Wales"))
  )

r5_north_south <- feols(ln_loans ~ north:i(quarter) | region + quarter,
                        data = regional_panel,
                        vcov = ~region)

cat("\n--- North-South × Time Interaction ---\n")
summary(r5_north_south)

# ============================================================================
# 6. COVID robustness: Exclude 2020+ data
# ============================================================================
cat("\n=== Robustness 6: Excluding COVID period ===\n")

pre_covid <- market_panel %>% filter(date < as.Date("2020-01-01"))

r6_no_covid <- feols(ln_firms ~ phase1 + phase2 +
                       trend_phase1 + trend_phase2,
                     data = pre_covid,
                     vcov = NW ~ yearqtr)

cat("\n--- Pre-COVID Phase Decomposition (Firms) ---\n")
summary(r6_no_covid)

# ============================================================================
# Save robustness results
# ============================================================================
cat("\n=== Saving robustness results ===\n")

saveRDS(list(
  r1_pretrend_loans = r1_pretrend_loans,
  r1_pretrend_firms = r1_pretrend_firms,
  r2_oft_placebo = r2_oft_placebo,
  r4_level_loans = r4_level_loans,
  r4_index = r4_index,
  r5_north_south = r5_north_south,
  r6_no_covid = r6_no_covid
), file.path(data_dir, "robustness_results.rds"))

cat("Robustness results saved.\nDONE.\n")
