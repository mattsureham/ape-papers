## 02_clean_data.R — Construct analysis panel
source("00_packages.R")

dt <- readRDS("../data/qwi_raw.rds")

# ---- Time variable ----
dt[, time_q := year + (quarter - 1) / 4]  # continuous quarter
dt[, yq := paste0(year, "Q", quarter)]

# ---- Treatment classification ----
# NCA ban states and timing (quarter of enactment)
ban_states <- data.table(
  state_abbr = c("OR", "WA", "CO", "IL", "MN"),
  ban_quarter = c(2020.00, 2020.00, 2022.50, 2022.00, 2023.50)  # year + (q-1)/4
)

# Always-treated states (never enforced NCAs)
always_treated <- c("CA", "OK", "ND")

dt <- merge(dt, ban_states, by = "state_abbr", all.x = TRUE)

# Treatment indicators
dt[, ban_state := state_abbr %in% ban_states$state_abbr]
dt[, always_treated := state_abbr %in% always_treated]
dt[, post := !is.na(ban_quarter) & time_q >= ban_quarter]

# For CS estimator: treatment cohort (first treated quarter)
dt[, treat_cohort := fifelse(ban_state, ban_quarter, Inf)]

# ---- Industry classification ----
dt[, knowledge := industry %in% c("51", "54")]
dt[, ind_label := fcase(
  industry == "51", "Information",
  industry == "54", "Professional",
  industry == "72", "Accommodation"
)]

# ---- Race labels ----
dt[, black := as.integer(race == "A2")]
dt[, race_label := fifelse(race == "A1", "White", "Black")]

# ---- Outcome construction ----
# Separation rate
dt[, sep_rate := fifelse(Emp > 0 & !is.na(Emp) & !is.na(Sep), Sep / Emp, NA_real_)]
# Hire rate
dt[, hire_rate := fifelse(Emp > 0 & !is.na(Emp) & !is.na(HirA), HirA / Emp, NA_real_)]
# Log earnings
dt[, log_earn := fifelse(EarnS > 0 & !is.na(EarnS), log(EarnS), NA_real_)]

# ---- State group for analysis ----
dt[, state_group := fcase(
  ban_state, "Ban",
  always_treated, "Always-Treated",
  default = "Control"
)]

# ---- Drop post-2023 for cleaner analysis (MN ban is Jul 2023) ----
dt <- dt[year <= 2023]

# ---- Filter to balanced cells with minimum employment ----
# Drop cells with suppressed data (Emp == 0 or NA)
dt <- dt[!is.na(Emp) & Emp > 0]

# ---- Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(dt), "\n")
cat("States:", uniqueN(dt$state_abbr), "\n")
cat("State groups:\n")
print(dt[, .N, by = state_group])
cat("\nIndustry breakdown:\n")
print(dt[, .(N = .N, mean_emp = mean(Emp, na.rm = TRUE)), by = ind_label])
cat("\nRace breakdown:\n")
print(dt[, .(N = .N, mean_emp = mean(Emp, na.rm = TRUE)), by = race_label])
cat("\nSeparation rates by group (pre-ban, 2016-2019):\n")
pre <- dt[year <= 2019]
print(pre[, .(mean_sep = mean(sep_rate, na.rm = TRUE)), by = .(state_group, ind_label, race_label)])

saveRDS(dt, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds with", nrow(dt), "rows\n")
