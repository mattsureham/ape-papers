## 02_clean_data.R — Construct analysis panel (aggregate weekly → monthly)
## apep_1169: Click to Incorporate

source("00_packages.R")

# ---- Load data ----
raw <- readRDS("../data/bfs_monthly.rds")
treatment <- readRDS("../data/treatment_panel.rds")

cat("Raw data:", nrow(raw), "rows x", ncol(raw), "cols\n")
cat("States:", length(unique(raw$state)), "\n")
cat("Date range:", as.character(min(raw$date)), "to", as.character(max(raw$date)), "\n")
cat("Frequency: weekly (", length(unique(raw$date[raw$state == "NV"])), "obs per state)\n")

# ---- Aggregate weekly to monthly ----
raw$year_month <- format(raw$date, "%Y-%m")

panel <- raw %>%
  group_by(state, year_month) %>%
  summarise(
    BA  = sum(BA, na.rm = TRUE),
    HBA = sum(HBA, na.rm = TRUE),
    WBA = sum(WBA, na.rm = TRUE),
    CBA = sum(CBA, na.rm = TRUE),
    n_weeks = n(),
    any_ba_missing = any(is.na(BA)),
    .groups = "drop"
  ) %>%
  mutate(
    year = as.integer(substr(year_month, 1, 4)),
    month = as.integer(substr(year_month, 6, 7)),
    ym = year * 12L + month
  )

cat("Monthly panel:", nrow(panel), "rows\n")
cat("States:", length(unique(panel$state)), "\n")
cat("Months:", length(unique(panel$ym)), "\n")

# ---- Drop months with fewer than 3 weeks (partial months at edges) ----
panel <- panel %>% filter(n_weeks >= 3)
cat("After dropping partial months:", nrow(panel), "rows\n")

# ---- Merge treatment status ----
panel <- panel %>%
  left_join(treatment %>% select(state, launch_ym, portal_name), by = "state") %>%
  mutate(
    treated_state = !is.na(launch_ym),
    treated = ifelse(treated_state & ym >= launch_ym, 1L, 0L),
    first_treat = ifelse(treated_state, launch_ym, 0L),
    event_time = ifelse(treated_state, ym - launch_ym, NA_integer_)
  )

cat("Treated states:", sum(panel$treated_state & !duplicated(panel$state)), "\n")
cat("Never-treated:", sum(!panel$treated_state & !duplicated(panel$state)), "\n")

# ---- Log transform outcomes ----
panel <- panel %>%
  mutate(
    log_BA  = log(BA + 1),
    log_HBA = log(HBA + 1),
    log_WBA = log(WBA + 1),
    log_CBA = log(CBA + 1)
  )

# ---- State numeric ID ----
panel <- panel %>%
  mutate(state_id = as.integer(factor(state)))

# ---- Summary statistics ----
cat("\n=== Summary Statistics ===\n")
for (var in c("WBA","BA","HBA","CBA")) {
  vals <- panel[[var]]
  cat(sprintf("%s - Mean: %.0f  SD: %.0f  Min: %.0f  Max: %.0f\n",
              var, mean(vals, na.rm=TRUE), sd(vals, na.rm=TRUE),
              min(vals, na.rm=TRUE), max(vals, na.rm=TRUE)))
}

# ---- Save ----
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis panel:", nrow(panel), "rows\n")
