# 03_main_analysis.R — Callaway-Sant'Anna staggered DiD + event studies
# apep_0970: UI Duration Cuts and Education Gradient

source("00_packages.R")

panel <- readRDS("../data/qwi_panel_clean.rds")
treatment_states <- readRDS("../data/treatment_states.rds")

cat(sprintf("Panel: %d obs, %d state-edu units, %d quarters\n",
            nrow(panel), n_distinct(panel$unit_id), n_distinct(panel$time_t)))

# ══════════════════════════════════════════════════════════════════════
# 1. CALLAWAY-SANT'ANNA — OVERALL ATT
# ══════════════════════════════════════════════════════════════════════

# The did package needs: yname, tname, idname, gname
# gname = first treated period (0 for never-treated)
# tname = time period
# idname = unit id

cat("\n=== Callaway-Sant'Anna: Log Earnings (all education) ===\n")
cs_earn <- att_gt(
  yname = "ln_earn_s",
  tname = "time_t",
  idname = "unit_id",
  gname = "first_treat_t",
  data = panel,
  control_group = "nevertreated",
  clustervars = "statefips",
  anticipation = 0,
  base_period = "universal"
)

# Aggregate to event-study
es_earn <- aggte(cs_earn, type = "dynamic", min_e = -12, max_e = 20)
cat("Event study (log earnings):\n")
summary(es_earn)

# Overall ATT
att_earn <- aggte(cs_earn, type = "simple")
cat("\nOverall ATT (log earnings):\n")
summary(att_earn)

# ══════════════════════════════════════════════════════════════════════
# 2. CALLAWAY-SANT'ANNA — HIRE RATE
# ══════════════════════════════════════════════════════════════════════

cat("\n=== Callaway-Sant'Anna: Hire Rate ===\n")
cs_hire <- att_gt(
  yname = "hire_rate_w",
  tname = "time_t",
  idname = "unit_id",
  gname = "first_treat_t",
  data = panel,
  control_group = "nevertreated",
  clustervars = "statefips",
  anticipation = 0,
  base_period = "universal"
)

es_hire <- aggte(cs_hire, type = "dynamic", min_e = -12, max_e = 20)
cat("Event study (hire rate):\n")
summary(es_hire)

att_hire <- aggte(cs_hire, type = "simple")
cat("\nOverall ATT (hire rate):\n")
summary(att_hire)

# ══════════════════════════════════════════════════════════════════════
# 3. EDUCATION-SPECIFIC ESTIMATES
# ══════════════════════════════════════════════════════════════════════

results_by_edu <- list()

for (edu in c("E1", "E2", "E3")) {
  label <- case_when(
    edu == "E1" ~ "HS or less",
    edu == "E2" ~ "Some college",
    edu == "E3" ~ "BA+"
  )
  cat(sprintf("\n=== %s ===\n", label))

  sub <- panel %>% filter(education == edu)

  # Log earnings
  cs_e <- att_gt(
    yname = "ln_earn_s",
    tname = "time_t",
    idname = "unit_id",
    gname = "first_treat_t",
    data = sub,
    control_group = "nevertreated",
    clustervars = "statefips",
    anticipation = 0,
    base_period = "universal"
  )

  es_e <- aggte(cs_e, type = "dynamic", min_e = -12, max_e = 20)
  att_e <- aggte(cs_e, type = "simple")

  cat(sprintf("  ATT (log earnings): %.4f (SE: %.4f)\n", att_e$overall.att, att_e$overall.se))

  # Hire rate
  cs_h <- att_gt(
    yname = "hire_rate_w",
    tname = "time_t",
    idname = "unit_id",
    gname = "first_treat_t",
    data = sub,
    control_group = "nevertreated",
    clustervars = "statefips",
    anticipation = 0,
    base_period = "universal"
  )

  att_h <- aggte(cs_h, type = "simple")
  es_h <- aggte(cs_h, type = "dynamic", min_e = -12, max_e = 20)

  cat(sprintf("  ATT (hire rate): %.5f (SE: %.5f)\n", att_h$overall.att, att_h$overall.se))

  results_by_edu[[edu]] <- list(
    label = label,
    cs_earn = cs_e, es_earn = es_e, att_earn = att_e,
    cs_hire = cs_h, es_hire = es_h, att_hire = att_h
  )
}

# ══════════════════════════════════════════════════════════════════════
# 4. TWFE (FIXEST) — TRIPLE DIFFERENCE
# ══════════════════════════════════════════════════════════════════════

cat("\n=== TWFE Triple-Difference: Earnings ===\n")

# Create interaction terms
panel <- panel %>%
  mutate(
    post = as.integer(time_t >= first_treat_t & first_treat_t > 0),
    low_edu = as.integer(education == "E1"),
    high_edu = as.integer(education == "E3"),
    treat_post = treated_state * post,
    treat_post_lowedu = treated_state * post * low_edu,
    treat_post_highedu = treated_state * post * high_edu
  )

# TWFE with state-edu and edu-time FE
twfe_earn <- feols(
  ln_earn_s ~ treat_post + treat_post_lowedu + treat_post_highedu |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)
cat("TWFE triple-diff (log earnings):\n")
summary(twfe_earn)

# Hire rate
twfe_hire <- feols(
  hire_rate_w ~ treat_post + treat_post_lowedu + treat_post_highedu |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)
cat("\nTWFE triple-diff (hire rate):\n")
summary(twfe_hire)

# Separation rate
twfe_sep <- feols(
  sep_rate_w ~ treat_post + treat_post_lowedu + treat_post_highedu |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)
cat("\nTWFE triple-diff (separation rate):\n")
summary(twfe_sep)

# ══════════════════════════════════════════════════════════════════════
# 5. SAVE RESULTS
# ══════════════════════════════════════════════════════════════════════

# Compile main results table
main_results <- tibble(
  outcome = c("Log earnings", "Log earnings", "Log earnings",
              "Hire rate", "Hire rate", "Hire rate"),
  education = rep(c("HS or less", "Some college", "BA+"), 2),
  att = c(
    results_by_edu$E1$att_earn$overall.att,
    results_by_edu$E2$att_earn$overall.att,
    results_by_edu$E3$att_earn$overall.att,
    results_by_edu$E1$att_hire$overall.att,
    results_by_edu$E2$att_hire$overall.att,
    results_by_edu$E3$att_hire$overall.att
  ),
  se = c(
    results_by_edu$E1$att_earn$overall.se,
    results_by_edu$E2$att_earn$overall.se,
    results_by_edu$E3$att_earn$overall.se,
    results_by_edu$E1$att_hire$overall.se,
    results_by_edu$E2$att_hire$overall.se,
    results_by_edu$E3$att_hire$overall.se
  )
) %>%
  mutate(
    pval = 2 * pnorm(-abs(att / se)),
    ci_lower = att - 1.96 * se,
    ci_upper = att + 1.96 * se,
    stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.10 ~ "*", TRUE ~ "")
  )

cat("\n=== Main Results Summary ===\n")
print(main_results)

# Save everything
saveRDS(list(
  cs_earn = cs_earn, es_earn = es_earn, att_earn = att_earn,
  cs_hire = cs_hire, es_hire = es_hire, att_hire = att_hire,
  results_by_edu = results_by_edu,
  twfe_earn = twfe_earn, twfe_hire = twfe_hire, twfe_sep = twfe_sep,
  main_results = main_results
), "../data/main_results.rds")

# Save panel with post indicator
saveRDS(panel, "../data/qwi_panel_clean.rds")

# ── Diagnostics for validate_v1.py ──────────────────────────────────
n_treated_states <- n_distinct(panel$statefips[panel$treated_state])
n_control_states <- n_distinct(panel$statefips[!panel$treated_state])
n_pre <- length(unique(panel$time_t[panel$time_t < min(treatment_states$first_treat_t)]))

diagnostics <- list(
  n_treated = n_treated_states * n_distinct(panel$education),  # state-edu treated units
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_states = n_distinct(panel$statefips),
  n_treated_states = n_treated_states,
  n_control_states = n_control_states,
  n_education_groups = n_distinct(panel$education),
  n_quarters = n_distinct(panel$time_t)
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nSaved: data/diagnostics.json\n")
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
