## 02_clean_data.R — Build analysis panel: NAICS-state-quarter
## apep_1018: The Spotlight Effect on Safety Reporting

source("00_packages.R")

# --------------------------------------------------------------------------
# 1. Load processed data
# --------------------------------------------------------------------------
cat("=== Loading data ===\n")
sir <- read_csv("../data/sir_processed.csv", show_col_types = FALSE)
qcew_raw <- read_csv("../data/qcew_national.csv", show_col_types = FALSE,
                      col_types = cols(.default = "c"))
fema_q <- read_csv("../data/fema_quarterly.csv", show_col_types = FALSE)
fema_w <- read_csv("../data/fema_weekly.csv", show_col_types = FALSE)

cat("SIR:", nrow(sir), "| QCEW:", nrow(qcew_raw), "| FEMA:", nrow(fema_q), "quarters\n")

# --------------------------------------------------------------------------
# 2. Build QCEW employment panel at NAICS 2-digit x quarter
# --------------------------------------------------------------------------
# Use 2-digit NAICS (sector) because 4-digit x state would be too sparse
# in the SIR data. National sector-quarter gives good denominators.

qcew <- qcew_raw %>%
  filter(own_code == "5", size_code == "0", agglvl_code == "15") %>%
  mutate(
    year = as.integer(api_year),
    qtr = as.integer(api_qtr),
    naics2 = substr(industry_code, 1, 2),
    avg_emp = as.numeric(month3_emplvl),
    establishments = as.numeric(qtrly_estabs)
  ) %>%
  select(year, qtr, naics2, avg_emp, establishments) %>%
  filter(!is.na(avg_emp), avg_emp > 0) %>%
  # Aggregate in case of duplicates (multiple ownership types)
  group_by(year, qtr, naics2) %>%
  summarize(avg_emp = sum(avg_emp), establishments = sum(establishments),
            .groups = "drop")

cat("QCEW sector-quarter:", nrow(qcew), "rows\n")
cat("Sectors:", n_distinct(qcew$naics2), "\n")

# --------------------------------------------------------------------------
# 3. Aggregate SIR to NAICS 2-digit x state x quarter
# --------------------------------------------------------------------------
cat("\n=== Building SIR panel ===\n")

# Count SIR reports by NAICS2 x state x quarter
sir_panel <- sir %>%
  mutate(naics2 = as.character(naics2)) %>%
  filter(!is.na(naics2), !is.na(state)) %>%
  group_by(naics2, state, event_year, event_quarter) %>%
  summarize(
    sir_count = n(),
    hospitalizations = sum(hospitalized > 0, na.rm = TRUE),
    amputations = sum(amputation > 0, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(year = event_year, qtr = event_quarter)

cat("SIR panel (non-zero cells):", nrow(sir_panel), "\n")

# Create the full panel: all NAICS2 x state x quarter combinations
# Only use NAICS sectors with substantial SIR presence
top_sectors <- sir %>%
  mutate(naics2 = as.character(naics2)) %>%
  count(naics2, sort = TRUE) %>%
  filter(n >= 500) %>%  # At least 500 reports over 10 years
  pull(naics2)

top_states <- sir %>%
  count(state, sort = TRUE) %>%
  filter(n >= 200) %>%
  pull(state)

cat("Top sectors (>=500 reports):", length(top_sectors), "\n")
cat("Top states (>=200 reports):", length(top_states), "\n")

# Full balanced panel
full_panel <- expand_grid(
  naics2 = top_sectors,
  state = top_states,
  year = 2015:2024,
  qtr = 1:4
) %>%
  filter(!(year == 2024 & qtr > 3))  # Data through Q3 2024

# Merge SIR counts
panel <- full_panel %>%
  left_join(sir_panel, by = c("naics2", "state", "year", "qtr")) %>%
  mutate(
    sir_count = replace_na(sir_count, 0),
    hospitalizations = replace_na(hospitalizations, 0),
    amputations = replace_na(amputations, 0)
  )

cat("Full panel:", nrow(panel), "rows (", n_distinct(panel$naics2), "sectors x",
    n_distinct(panel$state), "states x", n_distinct(paste(panel$year, panel$qtr)),
    "quarters)\n")

# --------------------------------------------------------------------------
# 4. Merge QCEW employment denominator
# --------------------------------------------------------------------------
# Join national sector-quarter employment
panel <- panel %>%
  mutate(naics2 = as.character(naics2)) %>%
  left_join(qcew %>% mutate(naics2 = as.character(naics2)),
            by = c("naics2", "year", "qtr"))

# For state allocation: use state share of SIR reports as proxy for
# state share of employment (BLS QCEW by state not fetched at 2-digit NAICS)
state_share <- sir %>%
  mutate(naics2 = as.character(naics2)) %>%
  filter(naics2 %in% top_sectors, state %in% top_states) %>%
  group_by(naics2, state) %>%
  summarize(state_sir_total = n(), .groups = "drop") %>%
  group_by(naics2) %>%
  mutate(state_share = state_sir_total / sum(state_sir_total)) %>%
  ungroup()

panel <- panel %>%
  left_join(state_share %>% select(naics2, state, state_share),
            by = c("naics2", "state")) %>%
  mutate(
    state_share = replace_na(state_share, 1 / n_distinct(state)),
    state_emp_est = avg_emp * state_share,
    sir_rate = sir_count / (state_emp_est / 100000)  # per 100K employees
  )

# --------------------------------------------------------------------------
# 5. Construct peer-firm treatment: other-state SIR in same sector-quarter
# --------------------------------------------------------------------------
cat("\n=== Constructing peer exposure ===\n")

# Peer exposure: SIR events in the SAME sector, DIFFERENT state, same quarter
# This avoids own-state confounds
peer_sir <- sir_panel %>%
  mutate(naics2 = as.character(naics2)) %>%
  filter(naics2 %in% top_sectors) %>%
  group_by(naics2, year, qtr) %>%
  summarize(
    national_sir = sum(sir_count),
    .groups = "drop"
  )

panel <- panel %>%
  left_join(peer_sir, by = c("naics2", "year", "qtr")) %>%
  mutate(
    national_sir = replace_na(national_sir, 0),
    peer_sir = national_sir - sir_count  # exclude own state
  )

# --------------------------------------------------------------------------
# 6. Merge FEMA disaster instrument
# --------------------------------------------------------------------------
panel <- panel %>%
  left_join(fema_q, by = c("year", "qtr" = "quarter")) %>%
  mutate(
    n_disasters = replace_na(n_disasters, 0),
    n_major_disasters = replace_na(n_major_disasters, 0),
    n_states_affected = replace_na(n_states_affected, 0)
  )

# --------------------------------------------------------------------------
# 7. Create analysis variables
# --------------------------------------------------------------------------
panel <- panel %>%
  mutate(
    yearqtr = paste0(year, "Q", qtr),
    cell_id = paste0(naics2, "_", state),
    quarter_id = paste0(year, qtr),
    log_sir = log1p(sir_count),
    log_peer_sir = log1p(peer_sir),
    log_emp = log(pmax(state_emp_est, 1)),
    post_2020 = as.integer(year >= 2020),  # COVID period indicator
    # Instruments: disaster counts
    log_disasters = log1p(n_disasters),
    log_major_disasters = log1p(n_major_disasters)
  )

# --------------------------------------------------------------------------
# 8. Summary statistics
# --------------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat("Dimensions:", nrow(panel), "obs,", ncol(panel), "vars\n")
cat("Non-zero SIR cells:", sum(panel$sir_count > 0), "/", nrow(panel),
    "(", round(100 * mean(panel$sir_count > 0), 1), "%)\n")
cat("Mean SIR count per cell:", round(mean(panel$sir_count), 2), "\n")
cat("Mean peer SIR:", round(mean(panel$peer_sir, na.rm=TRUE), 1), "\n")
cat("Mean disasters per quarter:", round(mean(panel$n_disasters, na.rm=TRUE), 1), "\n")

# Summary stats table
summ <- panel %>%
  summarize(
    across(c(sir_count, sir_rate, peer_sir, n_disasters, state_emp_est),
           list(mean = ~mean(., na.rm=TRUE),
                sd = ~sd(., na.rm=TRUE),
                min = ~min(., na.rm=TRUE),
                max = ~max(., na.rm=TRUE)))
  )

# Save
write_csv(panel, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved:", nrow(panel), "rows\n")

# Save diagnostics for validator
diag <- list(
  n_treated = n_distinct(panel$cell_id[panel$sir_count > 0]),
  n_pre = length(unique(panel$year[panel$year < 2020])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved\n")
