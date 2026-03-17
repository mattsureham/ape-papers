## 03_main_analysis.R — Main regression analysis
## apep_0711: Online sports betting and suicide mortality

source("00_packages.R")

cat("=== Main Analysis ===\n")

## --- 1. Load data ---
panel <- readRDS("../data/suicide_panel.rds")
panel <- panel %>% filter(!is.na(suicide_median))
cat("Panel:", nrow(panel), "observations,", n_distinct(panel$state_abbr), "states\n")

## --- 2. Create period variable ---
## Use year*100 + week for period FE in TWFE
panel <- panel %>%
  mutate(
    period = year * 100 + week,
    ## First treatment period for CS-DiD (0 = never treated)
    first_treat_period = ifelse(ever_treated == 1,
                                legal_year * 100 + legal_week,
                                0)
  )

## --- 3. TWFE baseline (weekly) ---
cat("\n--- TWFE: Weekly State Panel ---\n")
twfe <- feols(suicide_median ~ treated_post | state_id + period,
              data = panel,
              cluster = ~state_id)
cat("TWFE coefficient:\n")
print(summary(twfe))

## --- 4. Aggregate to monthly for CS-DiD ---
cat("\n--- Monthly Aggregation for CS-DiD ---\n")

## Create month variable from MMWR week (approximate)
panel <- panel %>%
  mutate(month = ceiling(week / 4.345),
         month = pmin(month, 12),
         ym = year * 100 + month)

monthly <- panel %>%
  group_by(state_id, state_abbr, year, month, ym, ever_treated) %>%
  summarise(
    suicide_median = mean(suicide_median, na.rm = TRUE),
    treated_post = max(treated_post),  # 1 if any week in month is post-treatment
    nfl_season = mean(nfl_season, na.rm = TRUE),
    n_weeks = n(),
    .groups = "drop"
  )

## First treatment month for CS-DiD
monthly <- monthly %>%
  left_join(
    panel %>%
      filter(ever_treated == 1) %>%
      group_by(state_abbr) %>%
      summarise(
        legal_ym = first(legal_year) * 100 + ceiling(first(legal_week) / 4.345),
        .groups = "drop"
      ),
    by = "state_abbr"
  ) %>%
  mutate(
    first_treat_m = ifelse(is.na(legal_ym), 0, legal_ym),
    ## Create sequential time index for CS-DiD (must be sequential integers)
    t_idx = as.integer(factor(ym))
  )

## Map first_treat to sequential index
first_treat_map <- monthly %>%
  filter(first_treat_m > 0) %>%
  distinct(state_abbr, first_treat_m) %>%
  left_join(
    monthly %>% distinct(ym, t_idx),
    by = c("first_treat_m" = "ym")
  )

monthly <- monthly %>%
  left_join(
    first_treat_map %>% select(state_abbr, first_treat_t = t_idx),
    by = "state_abbr"
  ) %>%
  mutate(first_treat_t = ifelse(is.na(first_treat_t), 0, first_treat_t))

cat("Monthly panel:", nrow(monthly), "obs,",
    n_distinct(monthly$state_abbr), "states,",
    n_distinct(monthly$ym), "months\n")

## Balance check
month_balance <- monthly %>% count(state_id) %>% pull(n)
cat("Months per state: min=", min(month_balance), "max=", max(month_balance), "\n")

## Balance the panel
if (min(month_balance) != max(month_balance)) {
  target_n <- quantile(month_balance, 0.25) |> as.integer()
  ## Keep states with at least target_n months
  good_states <- monthly %>% count(state_id) %>% filter(n >= target_n) %>% pull(state_id)
  ## Keep common months
  common_months <- monthly %>%
    filter(state_id %in% good_states) %>%
    count(t_idx) %>%
    filter(n == length(good_states)) %>%
    pull(t_idx)
  monthly_bal <- monthly %>% filter(state_id %in% good_states, t_idx %in% common_months)
  cat("Balanced monthly panel:", nrow(monthly_bal), "obs,",
      n_distinct(monthly_bal$state_abbr), "states,",
      n_distinct(monthly_bal$t_idx), "periods\n")
} else {
  monthly_bal <- monthly
}

## TWFE on monthly
cat("\n--- TWFE: Monthly ---\n")
twfe_m <- feols(suicide_median ~ treated_post | state_id + ym,
                data = monthly, cluster = ~state_id)
print(summary(twfe_m))

## --- 5. CS-DiD on monthly ---
cat("\n--- CS-DiD: Monthly ---\n")

cs_out <- tryCatch({
  att_gt(
    yname = "suicide_median",
    tname = "t_idx",
    idname = "state_id",
    gname = "first_treat_t",
    data = as.data.frame(monthly_bal),
    control_group = "nevertreated",
    est_method = "reg",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  ## Try without bootstrap
  tryCatch({
    att_gt(
      yname = "suicide_median",
      tname = "t_idx",
      idname = "state_id",
      gname = "first_treat_t",
      data = as.data.frame(monthly_bal),
      control_group = "nevertreated",
      est_method = "reg",
      bstrap = FALSE
    )
  }, error = function(e2) {
    cat("CS-DiD also failed without bootstrap:", conditionMessage(e2), "\n")
    NULL
  })
})

cs_agg <- NULL
cs_es <- NULL

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS-DiD Simple ATT:\n")
  print(summary(cs_agg))

  cs_es <- tryCatch({
    aggte(cs_out, type = "dynamic", min_e = -12, max_e = 12)
  }, error = function(e) {
    cat("CS event study error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(cs_es)) {
    cat("\nCS-DiD Event Study:\n")
    print(summary(cs_es))
  }
} else {
  cat("CS-DiD not available — using TWFE only.\n")
}

## --- 6. NFL Season Interaction ---
cat("\n--- NFL Season Heterogeneity ---\n")
nfl_int <- feols(suicide_median ~ treated_post * nfl_season | state_id + period,
                 data = panel,
                 cluster = ~state_id)
cat("TWFE with NFL interaction:\n")
print(summary(nfl_int))

## --- 7. Log specification ---
cat("\n--- Log Specification ---\n")
## Log-transform to get percent effects (avoids scale differences across states)
panel_log <- panel %>%
  filter(suicide_median > 0) %>%
  mutate(log_suicide = log(suicide_median))

twfe_log <- feols(log_suicide ~ treated_post | state_id + period,
                  data = panel_log, cluster = ~state_id)
cat("Log TWFE:\n")
print(summary(twfe_log))

## --- 8. Save results ---
results <- list(
  twfe = twfe,
  twfe_m = twfe_m,
  twfe_log = twfe_log,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_es = cs_es,
  nfl_int = nfl_int,
  panel = panel,
  monthly = monthly,
  monthly_bal = monthly_bal
)
saveRDS(results, "../data/main_results.rds")

## --- 9. Diagnostics for validation ---
diagnostics <- list(
  n_treated = n_distinct(panel$state_abbr[panel$ever_treated == 1 & panel$treated_post == 1]),
  n_pre = length(unique(panel$period[panel$period < min(panel$first_treat_period[panel$first_treat_period > 0])])),
  n_obs = nrow(panel)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")

cat("\n=== Main Analysis Complete ===\n")
