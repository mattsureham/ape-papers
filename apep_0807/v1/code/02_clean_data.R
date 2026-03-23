## 02_clean_data.R — Construct analysis variables
## APEP-0807: Legislating at Midnight

source("00_packages.R")

laws <- readRDS("../data/enacted_laws_raw.rds")
cat(sprintf("Loaded %d enacted laws\n", nrow(laws)))

# --- Basic cleaning ---
df <- laws %>%
  filter(
    !is.na(enacted_date),
    !is.na(introduced_date),
    !is.na(days_remaining),
    days_remaining >= 0  # Enacted during the session
  ) %>%
  mutate(
    # Calendar pressure variables
    final_30    = as.integer(days_remaining <= 30),
    final_60    = as.integer(days_remaining <= 60),
    final_90    = as.integer(days_remaining <= 90),
    lame_duck   = as.integer(days_remaining <= 60 & (congress %% 2 == 0 | TRUE)),
    # Note: "lame duck" technically is post-election (Nov) to Jan 3 in even years
    # We approximate: final 60 days of each Congress

    # Process quality indicators
    log_deliberation = log1p(deliberation_days),
    log_actions      = log1p(n_major_actions),

    # Binary outcomes
    skipped_conference = as.integer(!has_conference),
    voice_only         = as.integer(has_voice_vote & !has_roll_call),
    unanimous_passage  = as.integer(has_unanimous),

    # Bill type classification
    is_house = as.integer(bill_type == "house_bill"),
    is_senate = as.integer(bill_type == "senate_bill"),
    is_joint_res = as.integer(bill_type %in% c("house_joint_resolution", "senate_joint_resolution")),

    # Naming/postal bills (common "trivial" legislation)
    is_naming = as.integer(grepl("designat|renam|naming|post office|postal", title, ignore.case = TRUE)),

    # Congress era groupings
    era = case_when(
      congress <= 98  ~ "Pre-Reform (93-98)",
      congress <= 103 ~ "Reform Era (99-103)",
      congress <= 108 ~ "Polarization (104-108)",
      congress <= 113 ~ "Gridlock (109-113)",
      TRUE            ~ "Modern (114-118)"
    ),
    era = factor(era, levels = c("Pre-Reform (93-98)", "Reform Era (99-103)",
                                  "Polarization (104-108)", "Gridlock (109-113)",
                                  "Modern (114-118)"))
  )

# --- Identify "substantive" vs. "ceremonial" legislation ---
# Naming bills and postal designations are trivially passed and should be
# analyzed separately
df <- df %>%
  mutate(
    substantive = as.integer(!is_naming),
    # Create bins for days remaining
    days_remaining_bin = cut(days_remaining,
                              breaks = c(-1, 7, 14, 30, 60, 90, 180, 365, Inf),
                              labels = c("0-7", "8-14", "15-30", "31-60",
                                         "61-90", "91-180", "181-365", "366+"))
  )

# --- Summary statistics ---
cat("\n=== Sample Composition ===\n")
cat(sprintf("Total laws: %d\n", nrow(df)))
cat(sprintf("Substantive: %d (%.1f%%)\n", sum(df$substantive), 100*mean(df$substantive)))
cat(sprintf("Naming/ceremonial: %d (%.1f%%)\n", sum(!df$substantive), 100*mean(!df$substantive)))

cat("\n=== Calendar Pressure Distribution ===\n")
print(table(df$days_remaining_bin))

cat("\n=== Final 30 Days ===\n")
cat(sprintf("Laws enacted in final 30 days: %d (%.1f%% of total)\n",
            sum(df$final_30), 100*mean(df$final_30)))

cat("\n=== Process Indicators (Full Sample) ===\n")
cat(sprintf("Mean major actions: %.1f (sd=%.1f)\n",
            mean(df$n_major_actions), sd(df$n_major_actions)))
cat(sprintf("Mean deliberation days: %.1f (sd=%.1f)\n",
            mean(df$deliberation_days), sd(df$deliberation_days)))
cat(sprintf("Voice vote only: %.1f%%\n", 100*mean(df$voice_only)))
cat(sprintf("Has roll call: %.1f%%\n", 100*mean(df$has_roll_call)))
cat(sprintf("Has conference: %.1f%%\n", 100*mean(df$has_conference)))

cat("\n=== Final 30 vs. Earlier (Substantive Bills) ===\n")
sub <- filter(df, substantive == 1)
for (var in c("n_major_actions", "deliberation_days", "voice_only", "has_roll_call", "has_conference")) {
  m1 <- mean(sub[[var]][sub$final_30 == 1], na.rm = TRUE)
  m0 <- mean(sub[[var]][sub$final_30 == 0], na.rm = TRUE)
  cat(sprintf("  %s: final30=%.2f vs earlier=%.2f (diff=%.2f)\n", var, m1, m0, m1-m0))
}

# --- Save clean data ---
saveRDS(df, "../data/analysis_data.rds")
cat("\nSaved analysis data: ", nrow(df), "observations\n")
