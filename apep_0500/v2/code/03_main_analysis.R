## ===========================================================
## 03_main_analysis.R — Primary regressions
## APEP-0500: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

source("00_packages.R")

# -----------------------------------------------------------
# 1. Load data
# -----------------------------------------------------------
state_panel <- read_csv(file.path(data_dir, "state_panel.csv"),
                        show_col_types = FALSE)
lga_panel <- read_csv(file.path(data_dir, "lga_panel.csv"),
                      show_col_types = FALSE)

cat(sprintf("State panel: %d obs\n", nrow(state_panel)))
cat(sprintf("LGA panel: %d obs\n", nrow(lga_panel)))

# -----------------------------------------------------------
# 2. Descriptive Statistics
# -----------------------------------------------------------
cat("\n=== Descriptive Statistics ===\n")

# Treatment summary
treat_summary <- state_panel %>%
  filter(year == 2020) %>%
  group_by(treated = first_treat > 0) %>%
  summarise(
    n_states = n(),
    mean_nonstate_events = mean(events_nonstate),
    mean_total_events = mean(events_total),
    .groups = "drop"
  )
print(treat_summary)

# Violence trends by treatment group
trends <- state_panel %>%
  mutate(group = ifelse(first_treat > 0, "Treated (law adopted)", "Never treated")) %>%
  group_by(group, year) %>%
  summarise(
    mean_nonstate = mean(events_nonstate),
    mean_total = mean(events_total),
    .groups = "drop"
  )

write_csv(trends, file.path(tab_dir, "violence_trends.csv"))

# -----------------------------------------------------------
# 3. State-Level Callaway-Sant'Anna DiD
# -----------------------------------------------------------
cat("\n=== Callaway-Sant'Anna: State-Year Level ===\n")

# Main outcome: non-state violence events (farmer-herder proxy)
cs_nonstate <- att_gt(
  yname = "events_nonstate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = state_panel,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0
)

# Aggregate to dynamic event study
es_nonstate <- aggte(cs_nonstate, type = "dynamic", min_e = -5, max_e = 5)
cat("\nDynamic ATT (non-state violence):\n")
summary(es_nonstate)

# Overall ATT
att_nonstate <- aggte(cs_nonstate, type = "simple")
cat("\nOverall ATT (non-state violence):\n")
summary(att_nonstate)

# -----------------------------------------------------------
# 4. Placebo: State-based violence (Boko Haram, should be null)
# -----------------------------------------------------------
cat("\n=== Placebo: State-Based Violence ===\n")

cs_statebased <- att_gt(
  yname = "events_statebased",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = state_panel,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0
)

es_statebased <- aggte(cs_statebased, type = "dynamic", min_e = -5, max_e = 5)
cat("Dynamic ATT (state-based violence - PLACEBO):\n")
summary(es_statebased)

att_statebased <- aggte(cs_statebased, type = "simple")
cat("\nOverall ATT (state-based violence - PLACEBO):\n")
summary(att_statebased)

# -----------------------------------------------------------
# 5. DDD: LGA-Level Analysis
# -----------------------------------------------------------
cat("\n=== Triple-Difference: LGA-Year Level ===\n")

# Restrict to analysis window (2010-2024)
lga_analysis <- lga_panel %>%
  filter(year >= 2010 & year <= 2024) %>%
  mutate(
    post = as.integer(first_treat > 0 & year >= first_treat),
    treat_state = as.integer(first_treat > 0)
  )

# NOTE: Since post = I(first_treat > 0 & year >= first_treat), post already
# embeds treat_state. So post:treat_state ≡ post, and post:treat_state:pastoral
# ≡ post:pastoral. We restructure accordingly.

# (1) Simple DD: effect of law on ALL LGAs in treated states
dd_simple <- feols(
  events_nonstate ~ post | lga_num + year,
  data = lga_analysis,
  cluster = ~ state_id
)

cat("\nDD Simple (all LGAs):\n")
summary(dd_simple)

# (2) DDD with LGA + year FE: post captures DD, post×pastoral captures DDD
ddd_main <- feols(
  events_nonstate ~
    post +               # DD: treated state × post-treatment
    post:pastoral |      # DDD: differential effect on pastoral LGAs
    lga_num + year,
  data = lga_analysis,
  cluster = ~ state_id
)

cat("\nDDD Main Result (non-state violence):\n")
summary(ddd_main)

# (3) DDD with state × year FE (most demanding — PREFERRED SPECIFICATION)
# State×year FE absorbs all state-level time-varying confounders
# Coefficient identified from within-state pastoral vs. non-pastoral variation
ddd_saturated <- feols(
  events_nonstate ~
    post:pastoral |
    lga_num + state_id^year,       # LGA FE + State×Year FE
  data = lga_analysis,
  cluster = ~ state_id
)

cat("\nDDD Saturated (state×year FE) — PREFERRED:\n")
summary(ddd_saturated)

# (4) DDD for deaths
ddd_deaths <- feols(
  deaths_nonstate ~
    post:pastoral |
    lga_num + state_id^year,
  data = lga_analysis,
  cluster = ~ state_id
)

cat("\nDDD Deaths (non-state):\n")
summary(ddd_deaths)

# -----------------------------------------------------------
# 6. DDD Placebo: State-based violence
# -----------------------------------------------------------
cat("\n=== DDD Placebo: State-Based Violence ===\n")

# (5) Placebo: state-based violence with state×year FE
ddd_placebo <- feols(
  events_statebased ~
    post:pastoral |
    lga_num + state_id^year,
  data = lga_analysis,
  cluster = ~ state_id
)

cat("DDD Placebo (state-based violence):\n")
summary(ddd_placebo)

# -----------------------------------------------------------
# 7. Effective Sample Table (Fix 5)
# -----------------------------------------------------------
cat("\n=== Effective Sample: Which States Identify the DDD? ===\n")

# With state×year FE, the DDD coefficient is identified from states
# that have BOTH pastoral and non-pastoral LGAs (within-state variation).
# States that are 100% pastoral or 100% non-pastoral contribute nothing.

effective_sample <- lga_analysis %>%
  filter(year == 2015) %>%  # use a single year for LGA counts
  group_by(state, state_id) %>%
  summarise(
    n_lgas = n(),
    n_pastoral = sum(pastoral),
    n_nonpastoral = n() - sum(pastoral),
    .groups = "drop"
  ) %>%
  left_join(
    lga_analysis %>%
      distinct(state, first_treat, treat_state) %>%
      distinct(),
    by = "state"
  ) %>%
  mutate(
    pct_pastoral = round(100 * n_pastoral / n_lgas, 1),
    contributes = n_pastoral > 0 & n_nonpastoral > 0,
    cohort = case_when(
      first_treat == 0 ~ "Never treated",
      TRUE ~ as.character(first_treat)
    )
  ) %>%
  arrange(desc(treat_state), first_treat, state)

cat("Effective sample by state:\n")
print(as.data.frame(effective_sample %>%
  select(state, n_lgas, n_pastoral, n_nonpastoral, pct_pastoral, cohort, contributes)))

n_contributing <- sum(effective_sample$contributes)
n_contributing_treated <- sum(effective_sample$contributes & effective_sample$treat_state == 1)
cat(sprintf("\nContributing states: %d total (%d treated, %d control)\n",
            n_contributing, n_contributing_treated,
            n_contributing - n_contributing_treated))

saveRDS(effective_sample, file.path(data_dir, "effective_sample.rds"))

# -----------------------------------------------------------
# 8. Save results
# -----------------------------------------------------------
results <- list(
  cs_nonstate = cs_nonstate,
  es_nonstate = es_nonstate,
  att_nonstate = att_nonstate,
  cs_statebased = cs_statebased,
  es_statebased = es_statebased,
  att_statebased = att_statebased,
  dd_simple = dd_simple,
  ddd_main = ddd_main,
  ddd_saturated = ddd_saturated,
  ddd_deaths = ddd_deaths,
  ddd_placebo = ddd_placebo,
  effective_sample = effective_sample
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("\nMain analysis complete. Results saved.\n")
