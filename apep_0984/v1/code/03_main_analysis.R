## 03_main_analysis.R — Main DiD + price decomposition
## Paper: The Deterrence Dividend (apep_0984)

source("00_packages.R")

cat("=== MAIN ANALYSIS ===\n\n")

panel <- readRDS("../data/analysis_panel.rds")

# -----------------------------------------------------------------------
# 1. TWFE BASELINE: Law effect on search intensity
# -----------------------------------------------------------------------
cat("1. TWFE regressions\n")

# (1) Simple TWFE
m1 <- feols(search_index ~ treated | state_id + time_num, data = panel,
            cluster = ~state_id)

# (2) TWFE with palladium price
m2 <- feols(search_index ~ treated + log_palladium | state_id + time_num,
            data = panel, cluster = ~state_id)

# (3) TWFE with price interaction (deterrence dividend decomposition)
m3 <- feols(search_index ~ treated * log_palladium | state_id + time_num,
            data = panel, cluster = ~state_id)

# (4) With unemployment control
m4 <- feols(search_index ~ treated * log_palladium + unemp_rate |
              state_id + time_num, data = panel, cluster = ~state_id)

# (5) IHS transformation
m5 <- feols(ihs_search ~ treated * log_palladium | state_id + time_num,
            data = panel, cluster = ~state_id)

cat("TWFE Results:\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Baseline", "+Price", "+Interaction", "+Controls", "IHS"),
       se.below = TRUE, keep = c("treated", "log_palladium",
                                  "treated:log_palladium", "unemp_rate"))

# -----------------------------------------------------------------------
# 2. CALLAWAY-SANT'ANNA DiD
# -----------------------------------------------------------------------
cat("\n2. Callaway-Sant'Anna staggered DiD\n")

# Prepare data for did package
cs_data <- panel %>%
  filter(!is.na(search_index)) %>%
  mutate(
    # C-S requires numeric ID and period
    unit_id = state_id,
    period = time_num,
    g = first_treat
  )

# ATT(g,t) with not-yet-treated as control
cs_out <- tryCatch({
  att_gt(
    yname = "search_index",
    tname = "period",
    idname = "unit_id",
    gname = "g",
    data = cs_data,
    control_group = "notyettreated",
    base_period = "universal",
    clustervars = "unit_id",
    print_details = FALSE
  )
}, error = function(e) {
  cat(sprintf("  C-S with not-yet-treated failed: %s\n", e$message))
  cat("  Trying with never-treated control...\n")
  att_gt(
    yname = "search_index",
    tname = "period",
    idname = "unit_id",
    gname = "g",
    data = cs_data,
    control_group = "nevertreated",
    base_period = "universal",
    clustervars = "unit_id",
    print_details = FALSE
  )
})

# Aggregate ATT
cs_agg <- aggte(cs_out, type = "simple")
cat(sprintf("\nC-S aggregate ATT: %.3f (SE: %.3f, p=%.4f)\n",
            cs_agg$overall.att, cs_agg$overall.se,
            2 * pnorm(-abs(cs_agg$overall.att / cs_agg$overall.se))))

# Dynamic event study
cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 8)
cat("C-S dynamic event study computed\n")

# Group-level ATTs
cs_group <- aggte(cs_out, type = "group")
cat("C-S group-level ATTs:\n")
print(data.frame(
  group = cs_group$egt,
  att = round(cs_group$att.egt, 3),
  se = round(cs_group$se.egt, 3)
))

# -----------------------------------------------------------------------
# 3. PRICE DECOMPOSITION
# -----------------------------------------------------------------------
cat("\n3. Price decomposition analysis\n")

# Decomposition: how much of the search decline is due to price vs law?
# Compare predicted search under:
# (a) Actual (price decline + law)
# (b) Counterfactual: price decline only (set treated=0)
# (c) Counterfactual: law only (hold price at peak)

if (!is.null(coef(m3)["treated"]) && !is.null(coef(m3)["treated:log_palladium"])) {
  peak_log_price <- log(max(panel$palladium_price, na.rm = TRUE))
  trough_log_price <- log(min(panel$palladium_price[panel$year >= 2022], na.rm = TRUE))

  # For a treated state, the law effect at different price levels:
  law_effect_at_peak <- coef(m3)["treated"] +
    coef(m3)["treated:log_palladium"] * peak_log_price
  law_effect_at_trough <- coef(m3)["treated"] +
    coef(m3)["treated:log_palladium"] * trough_log_price

  cat(sprintf("\nDeterrence dividend decomposition (from interaction model):\n"))
  cat(sprintf("  Law effect at peak price ($%.0f):   %.2f index points\n",
              exp(peak_log_price), law_effect_at_peak))
  cat(sprintf("  Law effect at trough price ($%.0f): %.2f index points\n",
              exp(trough_log_price), law_effect_at_trough))
  cat(sprintf("  Difference (price-dependent deterrence): %.2f\n",
              law_effect_at_peak - law_effect_at_trough))
}

# -----------------------------------------------------------------------
# 4. PLACEBO TESTS
# -----------------------------------------------------------------------
cat("\n4. Pre-treatment parallel trends test\n")

# Restrict to pre-treatment period only
pre_panel <- panel %>%
  filter(first_treat == 0 | time_num < first_treat)

# Placebo treatment: assign treatment 4 quarters early
panel_placebo <- panel %>%
  mutate(
    placebo_treat = ifelse(first_treat > 0 & time_num >= (first_treat - 4), 1, 0)
  ) %>%
  filter(first_treat == 0 | time_num < first_treat)

m_placebo <- feols(search_index ~ placebo_treat | state_id + time_num,
                   data = panel_placebo, cluster = ~state_id)

cat(sprintf("  Placebo treatment (4Q early): coef=%.3f, se=%.3f, p=%.3f\n",
            coef(m_placebo)["placebo_treat"],
            se(m_placebo)["placebo_treat"],
            pvalue(m_placebo)["placebo_treat"]))

# -----------------------------------------------------------------------
# 5. DIAGNOSTICS
# -----------------------------------------------------------------------
cat("\n5. Computing diagnostics\n")

n_treated_units <- n_distinct(panel$state_abbr[panel$first_treat > 0])
n_pre <- panel %>%
  filter(first_treat > 0) %>%
  group_by(state_abbr) %>%
  summarise(n_pre = sum(time_num < first_treat), .groups = "drop") %>%
  pull(n_pre) %>%
  min()

diagnostics <- list(
  n_treated = n_treated_units,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_states = n_distinct(panel$state_abbr),
  n_quarters = n_distinct(panel$time_num),
  cs_att = cs_agg$overall.att,
  cs_se = cs_agg$overall.se,
  twfe_coef = coef(m1)["treated"],
  twfe_se = se(m1)["treated"],
  sd_y = sd(panel$search_index, na.rm = TRUE),
  mean_y = mean(panel$search_index, na.rm = TRUE),
  placebo_p = pvalue(m_placebo)["placebo_treat"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("  Saved diagnostics.json\n")

# -----------------------------------------------------------------------
# 6. SAVE RESULTS
# -----------------------------------------------------------------------
results <- list(
  twfe = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_dynamic = cs_dynamic,
  cs_group = cs_group,
  m_placebo = m_placebo,
  diagnostics = diagnostics
)

saveRDS(results, "../data/main_results.rds")
cat("\nSaved main_results.rds\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
