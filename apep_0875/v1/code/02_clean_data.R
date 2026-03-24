# =============================================================================
# 02_clean_data.R — Construct analysis panel
# =============================================================================

source("00_packages.R")

# --- Load raw data ---
completions <- readRDS("../data/ipeds_completions.rds")
institutions <- readRDS("../data/ipeds_institutions.rds")
enrollment <- readRDS("../data/ipeds_enrollment.rds")

# --- 1. Merge completions with institution characteristics ---
# Use institution's MOST RECENT control status (some institutions change sector)
# But primarily use the year-matched version
cat("Merging completions with institution data...\n")

panel <- completions %>%
  inner_join(
    institutions %>% select(unitid, year, control, state, state_fips, sector),
    by = c("unitid", "year")
  )

cat(sprintf("  Merged panel: %s rows\n", format(nrow(panel), big.mark = ",")))

# --- 2. Define sector ---
# control: 1 = public, 2 = private nonprofit, 3 = private for-profit
panel <- panel %>%
  mutate(
    for_profit = as.integer(control == 3),
    sector_label = case_when(
      control == 1 ~ "Public",
      control == 2 ~ "Private NP",
      control == 3 ~ "For-Profit"
    )
  )

# --- 3. Create program identifier ---
# A "program" is a unique (institution × CIP × award level) combination
panel <- panel %>%
  mutate(
    cip2 = substr(cipcode, 1, 2),
    program_id = paste(unitid, cipcode, award_level, sep = "_")
  )

# --- 4. Create program survival panel ---
# Identify all programs that existed in the pre-treatment window (2011-2014)
cat("Constructing program survival panel...\n")

# Programs active in any year 2011-2014
pre_programs <- panel %>%
  filter(year >= 2011, year <= 2014, total_completions > 0) %>%
  distinct(program_id, unitid, cipcode, award_level, cip2, for_profit, state, control) %>%
  mutate(existed_pre = 1)

cat(sprintf("  Programs active 2011-2014: %s\n", format(nrow(pre_programs), big.mark = ",")))

# For each pre-period program, track whether it exists in each subsequent year
years <- 2008:2023
alive_by_year <- panel %>%
  filter(total_completions > 0) %>%
  distinct(program_id, year) %>%
  mutate(alive = 1)

# Create balanced panel: all pre-period programs × all years
survival_panel <- expand.grid(
  program_id = unique(pre_programs$program_id),
  year = years,
  stringsAsFactors = FALSE
) %>%
  left_join(pre_programs %>% select(program_id, unitid, cipcode, award_level, cip2, for_profit, state, control),
            by = "program_id") %>%
  left_join(alive_by_year, by = c("program_id", "year")) %>%
  mutate(alive = replace_na(alive, 0))

cat(sprintf("  Survival panel: %s rows (%s programs × %d years)\n",
            format(nrow(survival_panel), big.mark = ","),
            format(n_distinct(survival_panel$program_id), big.mark = ","),
            length(years)))

# --- 5. Create CIP-level aggregated panel ---
# For-profit vs public program counts by CIP × year
cat("Constructing CIP-level panel...\n")

cip_panel <- panel %>%
  filter(total_completions > 0) %>%
  group_by(cip2, year, for_profit) %>%
  summarise(
    n_programs = n_distinct(program_id),
    n_institutions = n_distinct(unitid),
    total_completions = sum(total_completions, na.rm = TRUE),
    .groups = "drop"
  )

# Focus on CIP codes present in both sectors
cips_both_sectors <- cip_panel %>%
  group_by(cip2) %>%
  filter(any(for_profit == 1) & any(for_profit == 0)) %>%
  ungroup() %>%
  distinct(cip2) %>%
  pull(cip2)

cip_panel <- cip_panel %>%
  filter(cip2 %in% cips_both_sectors)

cat(sprintf("  CIP-level panel: %s rows, %d CIP2 codes in both sectors\n",
            format(nrow(cip_panel), big.mark = ","), length(cips_both_sectors)))

# --- 6. Treatment timing variables ---
survival_panel <- survival_panel %>%
  mutate(
    post_ge = as.integer(year >= 2015),
    post_repeal = as.integer(year >= 2020),  # Repeal effective July 2020
    treat_ge = for_profit * post_ge,
    treat_repeal = for_profit * post_repeal,
    # Event time relative to 2015
    event_time = year - 2015
  )

# --- 7. Enrollment data ---
cat("Processing enrollment data...\n")
enrollment_panel <- enrollment %>%
  inner_join(
    institutions %>% select(unitid, year, control, state),
    by = c("unitid", "year")
  ) %>%
  mutate(
    for_profit = as.integer(control == 3),
    log_enrollment = log(pmax(total_enrollment, 1))
  )

# --- 8. Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat("\nPrograms by sector (pre-treatment 2011-2014):\n")
pre_programs %>%
  group_by(for_profit) %>%
  summarise(
    n_programs = n(),
    n_institutions = n_distinct(unitid),
    n_cip2 = n_distinct(cip2)
  ) %>%
  print()

cat("\nSurvival rates by sector and year:\n")
surv_rates <- survival_panel %>%
  group_by(year, for_profit) %>%
  summarise(
    survival_rate = mean(alive),
    n = n(),
    .groups = "drop"
  )
surv_rates %>%
  pivot_wider(names_from = for_profit, values_from = c(survival_rate, n),
              names_prefix = "fp_") %>%
  print(n = 20)

# --- Save ---
saveRDS(survival_panel, "../data/survival_panel.rds")
saveRDS(cip_panel, "../data/cip_panel.rds")
saveRDS(enrollment_panel, "../data/enrollment_panel.rds")
saveRDS(pre_programs, "../data/pre_programs.rds")

cat("\nData cleaning complete. Files saved to data/\n")
