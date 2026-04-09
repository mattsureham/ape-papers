## 02_clean_data.R — Construct analysis panel with indexation treatment
source("00_packages.R")

data_dir <- "../data/"

# ========================================================================
# 1. Load employment data
# ========================================================================
employment <- readRDS(file.path(data_dir, "employment.rds"))

# Parse quarter to numeric time
employment <- employment |>
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    q = as.integer(substr(quarter, 7, 7)),
    time_q = year + (q - 1) / 4,
    quarter_date = as.Date(paste0(year, "-", (q - 1) * 3 + 1, "-01"))
  )

cat("Employment panel: ", n_distinct(employment$nace), " sectors, ",
    n_distinct(employment$quarter), " quarters\n")

# ========================================================================
# 2. Construct indexation treatment variable
# ========================================================================
# Belgium's automatic indexation operates through joint committees (CPs).
# Key timing regimes during the 2022-2023 cascade:
#
# PIVOT CROSSINGS: Feb 2022, Apr 2022, Aug 2022, Dec 2022, Sep 2023
# Each crossing = 2% mandatory wage increase, but timing differs:
#
# Group 1 - PIVOT-TRIGGERED (immediate, within 2 months):
#   Healthcare, social work (NACE Q), some public admin (NACE O)
#   → Received shocks in 2022Q1, Q2, Q3, Q4
#
# Group 2 - QUARTERLY adjustment:
#   Construction (NACE F, CP 124), some manufacturing
#   → Received shocks quarterly with 1-quarter lag
#
# Group 3 - ANNUAL-JANUARY:
#   CP 200 (auxiliary joint committee, largest: 500K+ workers)
#   Covers: professional services (NACE M), admin support (NACE N),
#   information/communication (NACE J), some retail (NACE G)
#   → Received full cumulative adjustment in 2023Q1

# Map NACE sections to indexation timing groups
# Based on Belgian joint committee (CP) assignments
indexation_regime <- tribble(
  ~nace, ~regime, ~regime_label,
  "A",   "annual",    "Annual (January)",      # Agriculture
  "B",   "quarterly", "Quarterly",             # Mining
  "C",   "quarterly", "Quarterly",             # Manufacturing
  "D",   "annual",    "Annual (January)",      # Utilities
  "E",   "annual",    "Annual (January)",      # Water/waste
  "F",   "quarterly", "Quarterly",             # Construction (CP 124)
  "G",   "annual",    "Annual (January)",      # Wholesale/retail (CP 200 dominant)
  "H",   "quarterly", "Quarterly",             # Transport
  "I",   "annual",    "Annual (January)",      # Accommodation/food
  "J",   "annual",    "Annual (January)",      # ICT (CP 200)
  "K",   "annual",    "Annual (January)",      # Finance
  "L",   "annual",    "Annual (January)",      # Real estate
  "M",   "annual",    "Annual (January)",      # Professional services (CP 200)
  "N",   "annual",    "Annual (January)",      # Admin support (CP 200)
  "O",   "pivot",     "Pivot-triggered",       # Public admin
  "P",   "pivot",     "Pivot-triggered",       # Education
  "Q",   "pivot",     "Pivot-triggered",       # Health/social work
  "R",   "annual",    "Annual (January)",      # Arts/entertainment
  "S",   "annual",    "Annual (January)",      # Other services
)

# Construct cumulative indexation intensity by regime and quarter
# Each pivot crossing adds ~2% to wages
pivot_crossings <- tibble(
  crossing_date = as.Date(c("2022-02-01", "2022-04-01", "2022-08-01",
                            "2022-12-01", "2023-09-01")),
  increment = 0.02  # Each crossing = 2%
)

# Build cumulative indexation by regime × quarter
all_quarters <- employment |>
  distinct(quarter, year, q, time_q, quarter_date) |>
  arrange(time_q)

build_indexation <- function(regime_type) {
  all_quarters |>
    mutate(
      cum_indexation = sapply(quarter_date, function(qd) {
        if (regime_type == "pivot") {
          # Immediate: count all crossings up to 2 months after quarter start
          sum(pivot_crossings$increment[pivot_crossings$crossing_date <= qd + 60])
        } else if (regime_type == "quarterly") {
          # Quarterly lag: count crossings from prior quarter
          sum(pivot_crossings$increment[pivot_crossings$crossing_date <= qd - 30])
        } else {
          # Annual January: all crossings before Jan of that year applied in Q1
          jan_date <- as.Date(paste0(year(qd), "-01-01"))
          if (month(qd) >= 1) {
            sum(pivot_crossings$increment[pivot_crossings$crossing_date < jan_date])
          } else {
            0
          }
        }
      }),
      regime = regime_type
    )
}

indexation_schedule <- bind_rows(
  build_indexation("pivot"),
  build_indexation("quarterly"),
  build_indexation("annual")
)

# ========================================================================
# 3. Merge employment with indexation treatment
# ========================================================================
panel <- employment |>
  left_join(indexation_regime, by = "nace") |>
  left_join(
    indexation_schedule |> select(quarter, regime, cum_indexation),
    by = c("quarter", "regime")
  )

# Drop sectors with no regime mapping or missing employment
panel <- panel |>
  filter(!is.na(regime), !is.na(employment_ths), !is.na(cum_indexation))

# Remove NACE T (households as employers) and U (extraterritorial) if present
panel <- panel |> filter(!nace %in% c("T", "U", "TOTAL"))

cat("Analysis panel:", nrow(panel), "observations\n")
cat("Sectors:", n_distinct(panel$nace), "\n")
cat("Quarters:", n_distinct(panel$quarter), "\n")
cat("Regimes:\n")
print(table(panel$regime))

# Create log employment
panel <- panel |>
  mutate(
    log_emp = log(employment_ths),
    post = as.integer(time_q >= 2022.0),
    early_treated = as.integer(regime == "pivot"),
    # Normalize indexation: 0 in pre-period, rising in treatment period
    treatment_intensity = cum_indexation
  )

# ========================================================================
# 4. Add hours worked if available
# ========================================================================
if (file.exists(file.path(data_dir, "hours_worked.rds"))) {
  hours <- readRDS(file.path(data_dir, "hours_worked.rds"))
  if (nrow(hours) > 0 && "nace" %in% names(hours) && "quarter" %in% names(hours)) {
    panel <- panel |>
      left_join(hours, by = c("nace", "quarter"))
    cat("Hours worked merged:", sum(!is.na(panel$hours_worked)), "non-missing\n")
  } else {
    cat("Hours worked data empty or missing required columns; skipping.\n")
  }
}

# ========================================================================
# 5. Save analysis panel
# ========================================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))

# Summary stats
cat("\n=== Panel Summary ===\n")
cat("Period:", min(panel$quarter), "to", max(panel$quarter), "\n")
cat("Pre-treatment quarters (before 2022-Q1):", sum(panel$time_q < 2022.0) / n_distinct(panel$nace), "\n")
cat("Employment range:", round(min(panel$employment_ths), 1), "to",
    round(max(panel$employment_ths), 1), "thousand\n")
cat("\nCumulative indexation by regime (max):\n")
panel |>
  group_by(regime) |>
  summarise(max_indexation = max(cum_indexation), .groups = "drop") |>
  print()
