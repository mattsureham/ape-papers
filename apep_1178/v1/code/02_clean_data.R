# ==============================================================================
# 02_clean_data.R — Build analysis panel with CRNA opt-out treatment
# ==============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_state_raw.rds")

# --------------------------------------------------------------------------
# 1. CRNA Supervision Opt-Out Dates (from CMS Federal Register notices)
#    Source: AANA tracking + CMS records
#    Year = calendar year opt-out became effective
#    Treatment quarter: Q1 of opt-out year (conservative)
# --------------------------------------------------------------------------

optout_states <- data.frame(
  state_abbr = c(
    "IA",  # Iowa — Dec 2001 (first state)
    "NE",  # Nebraska — 2002
    "ID",  # Idaho — 2002
    "MN",  # Minnesota — 2002
    "NH",  # New Hampshire — 2002
    "NM",  # New Mexico — 2002
    "KS",  # Kansas — 2003
    "ND",  # North Dakota — 2003
    "WA",  # Washington — 2003
    "AK",  # Alaska — 2003
    "OR",  # Oregon — 2003
    "MT",  # Montana — 2004
    "SD",  # South Dakota — 2005
    "WI",  # Wisconsin — 2005
    "CA",  # California — 2009
    "CO",  # Colorado — 2010
    "KY",  # Kentucky — 2012
    "AZ",  # Arizona — 2020
    "OK",  # Oklahoma — 2020
    "AL",  # Alabama — April 2022
    "AR",  # Arkansas — May 2022
    "MI"   # Michigan — May 2022
  ),
  optout_year = c(
    2002, 2002, 2002, 2002, 2002, 2002,  # Wave 1 (2001-02)
    2003, 2003, 2003, 2003, 2003,         # Wave 2 (2003)
    2004,                                  # Wave 3
    2005, 2005,                            # Wave 4
    2009,                                  # Wave 5
    2010,                                  # Wave 6
    2012,                                  # Wave 7
    2020, 2020,                            # Wave 8
    2022, 2022, 2022                       # Wave 9
  ),
  stringsAsFactors = FALSE
)

# Iowa's opt-out was Dec 2001 but effective 2002 for practical purposes
# Using annual opt-out year for Callaway-Sant'Anna (treatment onset year)

cat(sprintf("Opt-out states: %d\n", nrow(optout_states)))
cat(sprintf("  Wave composition: %s\n",
            paste(table(optout_states$optout_year), collapse = ", ")))

# --------------------------------------------------------------------------
# 2. Create time variables
# --------------------------------------------------------------------------

qwi$yq <- qwi$year + (qwi$quarter - 1) / 4   # Continuous time variable
qwi$time_id <- (qwi$year - 1998) * 4 + qwi$quarter  # Integer time index

# --------------------------------------------------------------------------
# 3. Merge opt-out status
# --------------------------------------------------------------------------

qwi <- merge(qwi, optout_states, by = "state_abbr", all.x = TRUE)
qwi$ever_optout <- !is.na(qwi$optout_year)
qwi$post_optout <- ifelse(qwi$ever_optout, qwi$year >= qwi$optout_year, FALSE)

# For never-treated states, set optout_year = 0 (C-S convention for never-treated)
qwi$g_period <- ifelse(qwi$ever_optout, qwi$optout_year, 0)

cat(sprintf("States in panel: %d\n", length(unique(qwi$state_abbr))))
cat(sprintf("  Treated (ever opt-out): %d\n",
            length(unique(qwi$state_abbr[qwi$ever_optout]))))
cat(sprintf("  Never-treated: %d\n",
            length(unique(qwi$state_abbr[!qwi$ever_optout]))))

# --------------------------------------------------------------------------
# 4. Filter to key analysis samples
# --------------------------------------------------------------------------

# Education codes in QWI:
# E0 = All, E1 = Less than HS, E2 = HS, E3 = Some College, E4 = BA+, E5 = Grad
# Sex: 0 = All, 1 = Male, 2 = Female

# Primary sample: BA+ workers (education E4), all sexes (sex 0), NAICS 621
# Also keep E1-E3 for placebo and 622/623 for DDD

# Use sex = 0 (all workers) to maximize cell sizes
qwi_all <- qwi %>%
  filter(sex == 0 | sex == "0")

cat(sprintf("Rows with sex=All: %s\n", format(nrow(qwi_all), big.mark = ",")))

# --------------------------------------------------------------------------
# 5. Create education groups
# --------------------------------------------------------------------------

# BA+ group (treatment-relevant: captures CRNAs, NPs, PAs)
qwi_ba <- qwi_all %>% filter(education == "E4" | education == 4)

# Non-BA group (placebo: should not be directly affected by CRNA opt-out)
qwi_nonba <- qwi_all %>%
  filter(education %in% c("E1", "E2", "E3", 1, 2, 3)) %>%
  mutate(Emp = ifelse(is.na(Emp), 0, Emp),
         EarnS = ifelse(is.na(EarnS), 0, EarnS)) %>%
  group_by(state_fips, state_abbr, year, quarter, yq, time_id, industry,
           optout_year, ever_optout, post_optout, g_period) %>%
  summarise(
    EarnS   = weighted.mean(EarnS, w = pmax(Emp, 0.01)),
    Emp     = sum(Emp),
    EmpEnd  = sum(EmpEnd, na.rm = TRUE),
    HirA    = sum(HirA, na.rm = TRUE),
    Sep     = sum(Sep, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    .groups = "drop"
  )
qwi_nonba$education <- "non_BA"

# --------------------------------------------------------------------------
# 6. Build primary analysis panel: state × year (annual aggregation)
#    Quarterly data is noisy for state-level; annualize for cleaner estimates
# --------------------------------------------------------------------------

build_annual <- function(df, ed_label) {
  df %>%
    mutate(Emp = ifelse(is.na(Emp), 0, Emp),
           EarnS = ifelse(is.na(EarnS), 0, EarnS)) %>%
    group_by(state_fips, state_abbr, year, industry,
             optout_year, ever_optout, g_period) %>%
    summarise(
      earn    = weighted.mean(EarnS, w = pmax(Emp, 0.01)),
      emp     = mean(Emp),  # Average quarterly employment
      hires   = sum(HirA, na.rm = TRUE),  # Total annual hires
      seps    = sum(Sep, na.rm = TRUE),
      job_gn  = sum(FrmJbGn, na.rm = TRUE),
      job_ls  = sum(FrmJbLs, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      post_optout = ifelse(g_period > 0, year >= g_period, FALSE),
      log_emp     = log(pmax(emp, 1)),
      log_earn    = log(pmax(earn, 1)),
      ed_group    = ed_label
    )
}

panel_ba    <- build_annual(qwi_ba, "BA_plus")
panel_nonba <- build_annual(qwi_nonba, "non_BA")
panel_full  <- bind_rows(panel_ba, panel_nonba)

# --------------------------------------------------------------------------
# 7. Create numeric state ID for did package
# --------------------------------------------------------------------------

state_ids <- data.frame(
  state_abbr = sort(unique(panel_full$state_abbr)),
  state_id   = seq_along(sort(unique(panel_full$state_abbr)))
)
panel_full <- merge(panel_full, state_ids, by = "state_abbr")

# --------------------------------------------------------------------------
# 8. Summary statistics
# --------------------------------------------------------------------------

cat("\n=== Panel Summary ===\n")
cat(sprintf("Total rows: %s\n", format(nrow(panel_full), big.mark = ",")))
cat(sprintf("States: %d\n", length(unique(panel_full$state_abbr))))
cat(sprintf("Years: %d-%d\n", min(panel_full$year), max(panel_full$year)))
cat(sprintf("Industries: %s\n", paste(unique(panel_full$industry), collapse = ", ")))
cat(sprintf("Education groups: %s\n", paste(unique(panel_full$ed_group), collapse = ", ")))

# Print mean employment by industry × education
cat("\nMean employment by industry × education:\n")
panel_full %>%
  group_by(industry, ed_group) %>%
  summarise(mean_emp = mean(emp, na.rm = TRUE), .groups = "drop") %>%
  print()

# --------------------------------------------------------------------------
# 9. Save analysis panels
# --------------------------------------------------------------------------

saveRDS(panel_full, "../data/analysis_panel.rds")

# Also save BA+ ambulatory only (main analysis sample)
panel_main <- panel_ba %>% filter(industry == "621")
panel_main <- merge(panel_main, state_ids, by = "state_abbr")
saveRDS(panel_main, "../data/panel_main.rds")

cat(sprintf("\nMain panel (BA+ ambulatory): %d rows, %d states, %d years\n",
            nrow(panel_main),
            length(unique(panel_main$state_abbr)),
            length(unique(panel_main$year))))

cat("Clean data complete.\n")
