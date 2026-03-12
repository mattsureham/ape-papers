## 02_clean_data.R — Merge CDR with IPEDS and construct analysis variables
## apep_0602: CDR Threshold and For-Profit College Behavior

library(tidyverse)

set.seed(20260312)

# --- Load intermediate data ---
cdr_panel <- readRDS("data/cdr_panel_raw.rds")
enroll <- readRDS("data/ipeds_enrollment.rds")
completions <- readRDS("data/ipeds_completions.rds")
inst_chars <- readRDS("data/ipeds_inst_chars.rds")
fin_aid <- readRDS("data/ipeds_fin_aid.rds")

# --- Step 1: Merge CDR with IPEDS ---
# CDR unitid comes as character from API; IPEDS unitid is integer
cdr_panel <- cdr_panel %>%
  mutate(unitid = as.integer(unitid))

enroll <- enroll %>% mutate(unitid = as.integer(unitid))
completions <- completions %>% mutate(unitid = as.integer(unitid))
inst_chars <- inst_chars %>% mutate(unitid = as.integer(unitid))
fin_aid <- fin_aid %>% mutate(unitid = as.integer(unitid))

# Start with CDR panel, merge on IPEDS outcomes
df <- cdr_panel %>%
  filter(!is.na(cdr3)) %>%
  left_join(enroll, by = c("unitid", "year")) %>%
  left_join(completions, by = c("unitid", "year")) %>%
  left_join(inst_chars %>% select(unitid, year, deathyr, closed_in_year, carnegie, sector,
                                   longitude, latitude, opeflag),
            by = c("unitid", "year")) %>%
  left_join(fin_aid, by = c("unitid", "year"))

cat(sprintf("Merged panel: %d obs, %d institutions\n", nrow(df), n_distinct(df$unitid)))

# --- Step 2: Construct key variables ---
df <- df %>%
  mutate(
    # Running variable centered at 30% cutoff (in percentage points)
    cdr3_pct = cdr3 * 100,
    cdr_centered = cdr3_pct - 30,

    # Treatment indicator: CDR >= 30%
    above_30 = as.integer(cdr3_pct >= 30),

    # Secondary cutoffs
    above_25 = as.integer(cdr3_pct >= 25),
    above_40 = as.integer(cdr3_pct >= 40),

    # Log enrollment (handle zeros)
    log_enrollment = log(pmax(total_enrollment, 1)),

    # Completion rate (completions / enrollment)
    completion_rate = ifelse(total_enrollment > 0,
                             total_completions / total_enrollment, NA),

    # Pell share
    pell_share = ifelse(total_enrollment > 0 & !is.na(pell_recipients),
                        pell_recipients / total_enrollment, NA),

    # Closure indicator: is the institution reported as closed in this year?
    closed_this_yr = ifelse(is.na(closed_in_year), 0L, closed_in_year),

    # Cohort size (denominator of CDR calculation)
    log_cohort = log(pmax(cdr3_denom, 1))
  )

# Construct forward-looking closure: did the institution close within 3 years?
# Use the inst_chars panel to identify closure events
closure_events <- inst_chars %>%
  filter(closed_in_year == 1) %>%
  group_by(unitid) %>%
  summarize(first_closure_year = min(year), .groups = "drop")

# Also check: institution disappears from IPEDS (not observed in future years)
last_observed <- inst_chars %>%
  group_by(unitid) %>%
  summarize(last_year = max(year), .groups = "drop")

# Merge closure info
df <- df %>%
  left_join(closure_events, by = "unitid") %>%
  left_join(last_observed, by = "unitid") %>%
  mutate(
    # Closed within 3 years: either explicitly closed or disappears from IPEDS
    closed_3yr = as.integer(
      (!is.na(first_closure_year) & first_closure_year <= year + 3) |
      (last_year <= year + 2 & last_year < 2023)  # Disappeared, not just end of data
    )
  ) %>%
  select(-first_closure_year, -last_year)

# --- Step 3: Define analysis sample ---
# Restrict to years with good CDR data (FY2010-2019 = Scorecard years 2009-2018)
# Restrict to institutions with at least some enrollment data
analysis <- df %>%
  filter(
    year >= 2009 & year <= 2019,
    !is.na(cdr3_pct),
    cdr3_denom >= 30  # Minimum cohort size for reliable CDR
  )

cat(sprintf("Analysis sample: %d obs, %d institutions, years %d-%d\n",
            nrow(analysis), n_distinct(analysis$unitid),
            min(analysis$year), max(analysis$year)))

# --- Step 4: Summary statistics for the analysis bandwidth ---
# Focus on institutions in the 15-45% CDR range (main analysis window)
bw_sample <- analysis %>% filter(cdr3_pct >= 15 & cdr3_pct <= 45)

cat(sprintf("\nBandwidth sample (15-45%% CDR): %d obs, %d institutions\n",
            nrow(bw_sample), n_distinct(bw_sample$unitid)))

cat("\nCDR distribution in analysis sample:\n")
cat(sprintf("  Mean CDR: %.1f%%\n", mean(analysis$cdr3_pct)))
cat(sprintf("  Median CDR: %.1f%%\n", median(analysis$cdr3_pct)))
cat(sprintf("  CDR 25-35%%: %d obs (%.1f%%)\n",
            sum(analysis$cdr3_pct >= 25 & analysis$cdr3_pct <= 35),
            100 * mean(analysis$cdr3_pct >= 25 & analysis$cdr3_pct <= 35)))
cat(sprintf("  CDR >= 30%%: %d obs (%.1f%%)\n",
            sum(analysis$cdr3_pct >= 30),
            100 * mean(analysis$cdr3_pct >= 30)))

cat("\nOutcome summary (full sample):\n")
cat(sprintf("  Mean enrollment: %.0f\n", mean(analysis$total_enrollment, na.rm = TRUE)))
cat(sprintf("  Mean completion rate: %.3f\n", mean(analysis$completion_rate, na.rm = TRUE)))
cat(sprintf("  Closure rate (3yr): %.3f\n", mean(analysis$closed_3yr, na.rm = TRUE)))
cat(sprintf("  Mean Pell share: %.3f\n", mean(analysis$pell_share, na.rm = TRUE)))

# --- Step 5: Save analysis dataset ---
saveRDS(analysis, "data/analysis_panel.rds")

cat("\nAnalysis dataset saved to data/analysis_panel.rds\n")
