# =============================================================================
# 02_clean_data.R — Construct analysis panel
# =============================================================================

source("00_packages.R")

hd     <- readRDS("../data/hd_raw.rds")
f1a    <- readRDS("../data/f1a_raw.rds")
sfa    <- readRDS("../data/sfa_raw.rds")
ic_ay  <- readRDS("../data/ic_ay_raw.rds")
effy   <- readRDS("../data/effy_raw.rds")
c_a    <- readRDS("../data/c_a_raw.rds")

# --- Deduplicate tables with multiple rows per unitid-year ---
# EFFY: aggregate across levels (effylev/effyalev)
effy <- effy %>%
  group_by(unitid, year) %>%
  summarise(
    efytotlt = sum(efytotlt, na.rm = TRUE),
    efytotlm = sum(efytotlm, na.rm = TRUE),
    efytotlw = sum(efytotlw, na.rm = TRUE),
    .groups = "drop"
  )

# C_A: already aggregated in fetch query, but verify
c_a <- c_a %>%
  group_by(unitid, year) %>%
  summarise(
    ctotalt = sum(ctotalt, na.rm = TRUE),
    ctotalm = sum(ctotalm, na.rm = TRUE),
    ctotalw = sum(ctotalw, na.rm = TRUE),
    .groups = "drop"
  )

# IC_AY: deduplicate (keep first row per unitid-year)
ic_ay <- ic_ay %>%
  group_by(unitid, year) %>%
  slice(1) %>%
  ungroup()

# --- Merge all tables on unitid × year ---
panel <- hd %>%
  left_join(f1a, by = c("unitid", "year")) %>%
  left_join(sfa, by = c("unitid", "year")) %>%
  left_join(ic_ay, by = c("unitid", "year")) %>%
  left_join(effy, by = c("unitid", "year")) %>%
  left_join(c_a, by = c("unitid", "year"))

cat(sprintf("Merged panel: %d rows, %d institutions, years %d–%d\n",
            nrow(panel), length(unique(panel$unitid)),
            min(panel$year), max(panel$year)))

# --- Construct key variables ---
panel <- panel %>%
  mutate(
    total_revenue     = as.numeric(f1a01),
    fed_operating     = as.numeric(f1a05),
    fed_nonoperating  = as.numeric(f1a14),
    federal_revenue   = as.numeric(f1a05) + as.numeric(f1a14),  # Federal operating + nonoperating
    state_operating   = as.numeric(f1a06),
    state_approp      = as.numeric(f1a15),
    state_revenue     = as.numeric(f1a06) + as.numeric(f1a15),
    tuition_revenue   = as.numeric(f1a04),
    enrollment        = as.numeric(efytotlt),
    in_state_tuition  = as.numeric(tuition_in_state),
    out_state_tuition = as.numeric(tuition_out_state),
    pell_recipients   = as.numeric(pgrnt_n),
    pell_total        = as.numeric(pgrnt_t),
    total_grant_n     = as.numeric(agrnt_n),
    total_grant_t     = as.numeric(agrnt_t),
    inst_grant_n      = as.numeric(igrnt_n),
    inst_grant_t      = as.numeric(igrnt_t),
    completions       = as.numeric(ctotalt),
    # Net price by income quintile (4-year institutions)
    net_price_q1      = as.numeric(npis412),  # $0-30k
    net_price_q2      = as.numeric(npis422),  # $30-48k
    net_price_q3      = as.numeric(npis432),  # $48-75k
    net_price_q4      = as.numeric(npis442),  # $75-110k
    net_price_q5      = as.numeric(npis452),  # $110k+
    is_4year          = sector %in% c(1, 2),
    is_2year          = sector %in% c(4, 5),
    post              = as.integer(year >= 2020)
  )

# --- Compute per-student measures ---
panel <- panel %>%
  mutate(
    rev_per_student       = total_revenue / enrollment,
    fed_rev_per_student   = federal_revenue / enrollment,
    state_rev_per_student = state_revenue / enrollment,
    grant_per_student     = total_grant_t / total_grant_n,
    pell_per_recipient    = pell_total / pell_recipients,
    inst_grant_per        = inst_grant_t / inst_grant_n,
    completions_rate      = completions / enrollment
  )

# --- Construct Bartik IV instrument from 2018 baseline ---
# Use SFA undergraduate count (scugrad) as denominator for Pell share
# This is the correct financial aid cohort, not total 12-month enrollment
baseline <- panel %>%
  filter(year == 2018) %>%
  mutate(
    ugrad_n = as.numeric(scugrad),
    pell_share_2018 = ifelse(ugrad_n > 0, pell_recipients / ugrad_n, NA_real_),
    fte_2018        = enrollment
  ) %>%
  filter(!is.na(pell_share_2018) & !is.na(fte_2018) & fte_2018 > 0 &
         pell_share_2018 > 0 & pell_share_2018 <= 1) %>%
  select(unitid, pell_share_2018, fte_2018)

cat(sprintf("Baseline (2018): %d institutions with Pell share data\n", nrow(baseline)))

# Predicted HEERF per student
# Formula: (pell_share × FTE) / sum(pell_share × FTE) × TotalHEERF / FTE
baseline <- baseline %>%
  mutate(
    weight_2018 = pell_share_2018 * fte_2018,
    predicted_heerf_per_student = (weight_2018 / sum(weight_2018, na.rm = TRUE)) * 76e9 / fte_2018
  )

cat(sprintf("Predicted HEERF per student: min=$%.0f, median=$%.0f, max=$%.0f\n",
            min(baseline$predicted_heerf_per_student, na.rm = TRUE),
            median(baseline$predicted_heerf_per_student, na.rm = TRUE),
            max(baseline$predicted_heerf_per_student, na.rm = TRUE)))

# Merge instrument to panel
panel <- panel %>%
  inner_join(baseline, by = "unitid")

# --- Construct the IV: predicted HEERF × post ---
panel <- panel %>%
  mutate(
    predicted_heerf_post = predicted_heerf_per_student * post / 1000,  # In $1,000s
    fed_rev_per_student_k = fed_rev_per_student / 1000  # In $1,000s for 2SLS
  )

# --- Sample restrictions ---
cat(sprintf("Panel before restrictions: %d obs, %d institutions\n",
            nrow(panel), length(unique(panel$unitid))))

panel <- panel %>%
  filter(!is.na(in_state_tuition) & !is.na(enrollment) & enrollment > 0)

cat(sprintf("Panel after restrictions: %d obs, %d institutions\n",
            nrow(panel), length(unique(panel$unitid))))

# --- Create IDs for FE ---
panel <- panel %>%
  mutate(
    state_id = as.integer(factor(state)),
    state_year = paste0(state, "_", year)
  )

# --- Save ---
saveRDS(panel, "../data/analysis_panel.rds")

cat("\n=== Panel Summary ===\n")
cat(sprintf("Institutions: %d\n", length(unique(panel$unitid))))
cat(sprintf("Years: %d–%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("4-year: %d, 2-year: %d (in 2018)\n",
            sum(panel$is_4year & panel$year == 2018),
            sum(panel$is_2year & panel$year == 2018)))
cat(sprintf("Mean Pell share (2018): %.3f\n", mean(panel$pell_share_2018)))
cat(sprintf("Mean predicted HEERF/student: $%.0f\n",
            mean(panel$predicted_heerf_per_student)))
