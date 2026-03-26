# 02_clean_data.R — Clean data and prepare for analysis
# apep_0970: UI Duration Cuts and Education Gradient

source("00_packages.R")

panel <- readRDS("../data/qwi_panel.rds")
treatment_states <- readRDS("../data/treatment_states.rds")

cat(sprintf("Loaded panel: %d rows, %d states, %d quarters\n",
            nrow(panel), n_distinct(panel$statefips), n_distinct(panel$time_t)))

# ── Drop states with excessive missing data ─────────────────────────
# Check coverage per state
state_coverage <- panel %>%
  group_by(statefips, education) %>%
  summarise(
    n_quarters = n(),
    pct_earn_na = mean(is.na(earn_s)),
    pct_hir_na = mean(is.na(earn_hir)),
    .groups = "drop"
  )

# Drop states with >20% missing earnings
bad_states <- state_coverage %>%
  filter(pct_earn_na > 0.2) %>%
  pull(statefips) %>%
  unique()

if (length(bad_states) > 0) {
  cat(sprintf("Dropping %d states with >20%% missing earnings: %s\n",
              length(bad_states), paste(bad_states, collapse = ", ")))
  panel <- panel %>% filter(!statefips %in% bad_states)
}

# ── Winsorize extreme values ────────────────────────────────────────
# Top/bottom 1% of earnings to reduce outlier influence
winsorize <- function(x, p = 0.01) {
  q <- quantile(x, probs = c(p, 1 - p), na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}

panel <- panel %>%
  group_by(education) %>%
  mutate(
    earn_s_w = winsorize(earn_s),
    earn_hir_w = winsorize(earn_hir),
    hire_rate_w = winsorize(hire_rate),
    sep_rate_w = winsorize(sep_rate)
  ) %>%
  ungroup()

# ── Create state-education panel ID ─────────────────────────────────
panel <- panel %>%
  mutate(
    state_edu_id = paste0(statefips, "_", education),
    # Numeric ID for did package
    unit_id = as.integer(as.factor(state_edu_id))
  )

# ── Summary statistics for paper ────────────────────────────────────
cat("\n=== Summary Statistics for Paper ===\n")

# Pre-treatment means (before any state cut, i.e., before 2011Q2)
pre_panel <- panel %>% filter(time_t <= 17)  # up to 2011Q1

sumstats <- pre_panel %>%
  group_by(edu_label) %>%
  summarise(
    mean_earn = mean(earn_s, na.rm = TRUE),
    sd_earn = sd(earn_s, na.rm = TRUE),
    mean_hire_earn = mean(earn_hir, na.rm = TRUE),
    sd_hire_earn = sd(earn_hir, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    mean_emp_millions = mean(emp / 1e6, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )
print(sumstats)

# Treatment vs control comparison
treat_comp <- pre_panel %>%
  group_by(treated_state, edu_label) %>%
  summarise(
    mean_earn = mean(earn_s, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
cat("\nPre-treatment means by treatment status:\n")
print(treat_comp, n = 20)

# ── Save clean panel ────────────────────────────────────────────────
saveRDS(panel, "../data/qwi_panel_clean.rds")
cat(sprintf("\nSaved clean panel: %d obs\n", nrow(panel)))

# ── Save summary stats for tables ───────────────────────────────────
saveRDS(sumstats, "../data/summary_stats.rds")
saveRDS(treat_comp, "../data/treatment_comparison.rds")
