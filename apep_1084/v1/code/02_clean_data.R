# =============================================================================
# 02_clean_data.R — Merge GE scores with IPEDS, construct treatment, build panel
# Paper: The Scarlet Score (apep_1084)
# =============================================================================

source("00_packages.R")

ge_raw <- readRDS("../data/ge_raw.rds")
completions <- readRDS("../data/ipeds_completions.rds")
inst <- readRDS("../data/ipeds_institutions.rds")

# --- 1. Clean GE data ---
cat("=== Cleaning GE data ===\n")

ge <- ge_raw %>%
  rename(
    opeid6 = `Institution Code (six-digit OPEID)`,
    inst_name_ge = `Institution Name`,
    inst_type = `Institution Type`,
    cipcode = `CIP Code`,
    cip_name = `CIP Name`,
    cred_level = `Credential Level`,
    ge_status = `Official Program Pass/Zone/Fail`,
    appeal_decision = `Official Appeal Decision`,
    appeal_status = `Appeal Status`,
    de_annual_rate = `Debt-to-Earnings Annual Rate`,
    de_annual_num = `Debt-to-Earnings Annual Rate Numerator`,
    de_annual_den = `Debt-to-Earnings Annual Rate Denominator`,
    de_annual_pzf = `Debt-to-Earnings Annual Rate Pass/Fail/Zone`,
    de_disc_rate = `Debt-to-Earnings Discretionary Income Rate`,
    de_disc_pzf = `Debt-to-Earnings Discretionary Income Rate Pass/Fail/Zone`,
    mean_earnings = `Mean  Annual Earnings From SSA`,
    median_earnings = `Median Annual Earnings from SSA`
  ) %>%
  mutate(
    # Clean OPEID to 6 digits for matching
    opeid6 = str_pad(opeid6, 6, pad = "0"),
    # Clean CIP code: GE format is "513901" → "51.3901"
    cipcode_raw = str_pad(cipcode, 6, pad = "0"),
    cipcode = paste0(substr(cipcode_raw, 1, 2), ".", substr(cipcode_raw, 3, 6)),
    # Treatment: Failed includes FAIL and FAIL** (appealed but still failed)
    ge_fail = as.integer(str_detect(ge_status, "^FAIL")),
    ge_zone = as.integer(str_detect(ge_status, "^ZONE")),
    ge_pass = as.integer(str_detect(ge_status, "^PASS")),
    # For-profit indicator
    is_forprofit = str_detect(inst_type, "PROPRIETARY|FOR.PROFIT"),
    # Numeric D/E rate
    de_annual_rate = as.numeric(de_annual_rate)
  )

cat("GE status distribution:\n")
print(table(ge$ge_status, useNA = "ifany"))
cat("\nInstitution type distribution:\n")
print(table(ge$inst_type, useNA = "ifany"))
cat("\nFor-profit programs:", sum(ge$is_forprofit, na.rm = TRUE), "\n")

# Focus on for-profit institutions (the primary GE targets)
ge_fp <- ge %>% filter(is_forprofit)
cat("For-profit GE programs:", nrow(ge_fp), "\n")
cat("For-profit FAIL:", sum(ge_fp$ge_fail), "\n")
cat("For-profit ZONE:", sum(ge_fp$ge_zone), "\n")
cat("For-profit PASS:", sum(ge_fp$ge_pass), "\n")

# --- 2. Create OPEID-to-unitid crosswalk ---
cat("\n=== Building OPEID-to-unitid crosswalk ===\n")

# IPEDS hd table has opeid as integer including branch code
# Format: XXXXXXBB where first 6 digits = institution, last 2 = branch
# Convert to 8-digit string, extract first 6 to match GE
inst_xwalk <- inst %>%
  filter(year == 2016, control == 3) %>%  # For-profit institutions, pre-treatment year
  mutate(
    opeid_str = str_pad(as.character(opeid), 8, pad = "0"),
    opeid6 = substr(opeid_str, 1, 6)
  ) %>%
  select(unitid, opeid6, institution_name, stabbr) %>%
  distinct(opeid6, .keep_all = TRUE)  # One unitid per opeid6 (main campus)

cat("Crosswalk entries:", nrow(inst_xwalk), "\n")

# Merge GE with crosswalk
ge_merged <- ge_fp %>%
  inner_join(inst_xwalk, by = "opeid6")

cat("GE programs matched to IPEDS:", nrow(ge_merged), "\n")
cat("Unique institutions matched:", n_distinct(ge_merged$unitid), "\n")

# --- 3. Merge with IPEDS completions to create panel ---
cat("\n=== Building analysis panel ===\n")

# Aggregate completions at program level (unitid × cipcode × year)
# IPEDS cipcode is numeric (e.g., 51.3901); convert to character "XX.XXXX" to match GE
comp_panel <- completions %>%
  filter(year >= 2012 & year <= 2021) %>%
  mutate(cipcode = sprintf("%07.4f", cipcode)) %>%
  group_by(unitid, cipcode, year) %>%
  summarize(
    total_completions = sum(ctotalt, na.rm = TRUE),
    black_completions = sum(cbkaat, na.rm = TRUE),
    hispanic_completions = sum(chispt, na.rm = TRUE),
    white_completions = sum(cwhitt, na.rm = TRUE),
    minority_completions = sum(cbkaat, na.rm = TRUE) + sum(chispt, na.rm = TRUE) +
      sum(caiant, na.rm = TRUE) + sum(cnhpit, na.rm = TRUE),
    .groups = "drop"
  )

cat("Completion panel rows:", nrow(comp_panel), "\n")

# Create treatment info for each program
ge_treat <- ge_merged %>%
  select(unitid, cipcode, ge_fail, ge_zone, ge_pass, ge_status,
         de_annual_rate, inst_name_ge, stabbr) %>%
  distinct(unitid, cipcode, .keep_all = TRUE)

cat("Unique GE program-institution pairs:", nrow(ge_treat), "\n")

# Merge: keep only programs that appear in the GE data
panel <- comp_panel %>%
  inner_join(ge_treat, by = c("unitid", "cipcode")) %>%
  arrange(unitid, cipcode, year) %>%
  mutate(
    # Time periods
    post_pub = as.integer(year >= 2017),       # After Jan 2017 score publication
    post_rollback = as.integer(year >= 2018),   # After Jun 2017 pause (first full year = 2018)
    # Program ID for fixed effects
    prog_id = paste0(unitid, "_", cipcode),
    # Minority share (pre-treatment)
    minority_share = minority_completions / pmax(total_completions, 1)
  )

cat("Analysis panel rows:", nrow(panel), "\n")
cat("Unique programs:", n_distinct(panel$prog_id), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")

# --- 4. Identify within-institution comparison ---
cat("\n=== Within-institution analysis ===\n")

# Institutions with BOTH failing AND passing programs
inst_both <- panel %>%
  group_by(unitid) %>%
  summarize(
    has_fail = any(ge_fail == 1),
    has_pass = any(ge_pass == 1),
    n_programs = n_distinct(cipcode),
    .groups = "drop"
  ) %>%
  filter(has_fail & has_pass)

cat("Institutions with both fail and pass programs:", nrow(inst_both), "\n")

panel <- panel %>%
  mutate(within_inst_sample = unitid %in% inst_both$unitid)

cat("Programs in within-institution sample:",
    n_distinct(panel$prog_id[panel$within_inst_sample]), "\n")

# --- 5. Compute pre-treatment means for scaling ---
cat("\n=== Pre-treatment statistics ===\n")

pre_stats <- panel %>%
  filter(year < 2017) %>%
  group_by(ge_status) %>%
  summarize(
    mean_completions = mean(total_completions, na.rm = TRUE),
    sd_completions = sd(total_completions, na.rm = TRUE),
    mean_minority_share = mean(minority_share, na.rm = TRUE),
    n_programs = n_distinct(prog_id),
    .groups = "drop"
  )

cat("Pre-treatment statistics by GE status:\n")
print(pre_stats)

# Save SD(Y) for SDE computation
pre_sd_all <- panel %>%
  filter(year < 2017) %>%
  summarize(sd_y = sd(total_completions, na.rm = TRUE)) %>%
  pull(sd_y)

pre_sd_minority <- panel %>%
  filter(year < 2017) %>%
  summarize(sd_y = sd(minority_completions, na.rm = TRUE)) %>%
  pull(sd_y)

cat("Pre-treatment SD(total completions):", pre_sd_all, "\n")
cat("Pre-treatment SD(minority completions):", pre_sd_minority, "\n")

# --- 6. Save analysis panel ---
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(pre_stats, "../data/pre_stats.rds")
saveRDS(list(sd_total = pre_sd_all, sd_minority = pre_sd_minority),
        "../data/pre_sds.rds")

cat("\n=== Panel construction complete ===\n")
cat("Final panel: ", nrow(panel), " program-years\n")
cat("Programs: ", n_distinct(panel$prog_id), "\n")
cat("Institutions: ", n_distinct(panel$unitid), "\n")
cat("Treatment (FAIL): ", sum(panel$ge_fail & panel$year == 2016), " programs\n")
cat("Control (PASS): ", sum(panel$ge_pass & panel$year == 2016), " programs\n")
