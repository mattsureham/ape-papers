# =============================================================================
# 03_main_analysis.R — DDD estimation: ULR × Black × Healthcare
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
ulr_states <- read_csv("../data/ulr_states.csv", show_col_types = FALSE)

cat("=== MAIN DDD ANALYSIS ===\n\n")

# --- Model 1: Baseline DDD with fixest ---
# Full triple interaction with high-dimensional FEs
m1 <- feols(
  log_earn ~ post_ulr:black:healthcare +
    post_ulr:black + post_ulr:healthcare + black:healthcare +
    post_ulr + black + healthcare |
    state_fips^quarter_id,
  data = df,
  weights = ~Emp,
  cluster = ~state_fips
)
cat("Model 1: Baseline DDD (state×quarter FE)\n")
summary(m1)

# --- Model 2: Full FE DDD ---
m2 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df,
  weights = ~Emp,
  cluster = ~state_fips
)
cat("\nModel 2: Full FE DDD (state×quarter + state×race×industry + quarter×race×industry FE)\n")
summary(m2)

# --- Model 3: Event study DDD ---
# Bin endpoints at -8 and +8 quarters
df_es <- df %>%
  filter(!is.na(event_time)) %>%
  mutate(
    event_time_binned = pmax(pmin(event_time, 8), -8),
    event_time_f = as.factor(event_time_binned)
  )

m3 <- feols(
  log_earn ~ i(event_time_binned, black_healthcare, ref = -1) |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df_es %>% mutate(black_healthcare = black * healthcare),
  weights = ~Emp,
  cluster = ~state_fips
)
cat("\nModel 3: Event study DDD\n")
summary(m3)

# --- Model 4: Callaway-Sant'Anna on differenced outcome ---
# Create state×quarter panel with DDD gap as outcome
df_gap <- df %>%
  select(state_fips, year, quarter, time_q, race_label, industry_label,
         log_earn, Emp, first_treat_cs, ulr_state) %>%
  pivot_wider(
    id_cols = c(state_fips, year, quarter, time_q, first_treat_cs, ulr_state),
    names_from = c(race_label, industry_label),
    values_from = c(log_earn, Emp),
    names_sep = "_"
  ) %>%
  mutate(
    # DDD gap: (Black HC - White HC) - (Black Mfg - White Mfg)
    ddd_gap = (log_earn_Black_Healthcare - log_earn_White_Healthcare) -
              (log_earn_Black_Manufacturing - log_earn_White_Manufacturing)
  ) %>%
  filter(!is.na(ddd_gap)) %>%
  # Create integer panel IDs for did package
  mutate(
    state_num = as.integer(as.factor(state_fips)),
    time_num = as.integer(as.factor(time_q)),
    # C-S needs integer first_treat: convert to quarter index
    first_treat_int = ifelse(first_treat_cs == 0, 0,
                             as.integer(as.factor(first_treat_cs)))
  )

# Map first_treat back to time_num scale
time_map <- df_gap %>%
  distinct(time_q, time_num) %>%
  arrange(time_q)

df_gap <- df_gap %>%
  mutate(
    first_treat_int = ifelse(
      first_treat_cs == 0, 0,
      time_map$time_num[match(first_treat_cs, time_map$time_q)]
    )
  )

cat("\nC-S gap panel: ", nrow(df_gap), "state-quarters\n")
cat("Treated states in gap panel: ",
    n_distinct(df_gap$state_fips[df_gap$first_treat_cs > 0]), "\n")

cs_out <- att_gt(
  yname = "ddd_gap",
  tname = "time_num",
  idname = "state_num",
  gname = "first_treat_int",
  data = as.data.frame(df_gap),
  control_group = "nevertreated",
  base_period = "universal"
)

cat("\nModel 4: Callaway-Sant'Anna on DDD gap\n")
summary(cs_out)

# Aggregate to overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nC-S aggregate ATT:\n")
summary(cs_agg)

# Dynamic event study
cs_dyn <- aggte(cs_out, type = "dynamic")
cat("\nC-S dynamic aggregation:\n")
summary(cs_dyn)

# --- Save results ---
results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_dyn = cs_dyn,
  df_gap = df_gap
)
saveRDS(results, "../data/main_results.rds")

# --- Write diagnostics.json ---
# n_treated = number of treated cells (state-quarter-race-industry observations with post_ulr=1)
# The treatment operates at the state level (11 states), but each state contributes
# multiple race x industry x quarter cells to the DDD
n_treated_cells <- sum(df$post_ulr == 1)
n_pre <- n_distinct(df$time_q[df$time_q < min(ulr_states$first_treat_q, na.rm = TRUE)])
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = as.integer(n_treated_cells),
  n_pre = as.integer(n_pre),
  n_obs = n_obs
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_states, n_pre, n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
