# 04_robustness.R — Robustness checks
# apep_0970: UI Duration Cuts and Education Gradient

source("00_packages.R")

panel <- readRDS("../data/qwi_panel_clean.rds")
results <- readRDS("../data/main_results.rds")

# ══════════════════════════════════════════════════════════════════════
# 1. ALTERNATIVE CONTROL GROUP: NOT-YET-TREATED
# ══════════════════════════════════════════════════════════════════════
cat("=== CS-DiD with not-yet-treated control group ===\n")

cs_nyt <- att_gt(
  yname = "hire_rate_w",
  tname = "time_t",
  idname = "unit_id",
  gname = "first_treat_t",
  data = panel,
  control_group = "notyettreated",
  clustervars = "statefips",
  anticipation = 0,
  base_period = "universal"
)
att_nyt <- aggte(cs_nyt, type = "simple")
cat(sprintf("Not-yet-treated ATT (hire rate): %.5f (SE: %.5f)\n",
            att_nyt$overall.att, att_nyt$overall.se))

# ══════════════════════════════════════════════════════════════════════
# 2. LEAVE-ONE-OUT (DROP EACH TREATED STATE)
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Leave-one-out robustness ===\n")

treated_fips <- unique(panel$statefips[panel$treated_state])
loo_results <- list()

for (fips in treated_fips) {
  sub <- panel %>% filter(statefips != fips)
  # Re-create unit IDs
  sub <- sub %>% mutate(unit_id = as.integer(as.factor(state_edu_id)))

  cs_loo <- tryCatch(
    att_gt(
      yname = "hire_rate_w",
      tname = "time_t",
      idname = "unit_id",
      gname = "first_treat_t",
      data = sub,
      control_group = "nevertreated",
      clustervars = "statefips",
      anticipation = 0,
      base_period = "universal"
    ),
    error = function(e) NULL
  )

  if (!is.null(cs_loo)) {
    att_loo <- aggte(cs_loo, type = "simple")
    state <- panel$state_abbr[panel$statefips == fips][1]
    loo_results[[state]] <- list(att = att_loo$overall.att, se = att_loo$overall.se)
    cat(sprintf("  Drop %s: ATT = %.5f (SE: %.5f)\n", state, att_loo$overall.att, att_loo$overall.se))
  }
}

# ══════════════════════════════════════════════════════════════════════
# 3. DOSE-RESPONSE: LARGER VS SMALLER CUTS
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Dose-response: Large cuts (>6 weeks) vs small cuts (≤6 weeks) ===\n")

# Large cuts: AR (10 weeks), NC/GA/SC/MO/MI (6 weeks)
# Small cuts: FL (3 weeks)
# Actually: FL=3, SC/MO/MI/GA/NC=6, AR=10
# Split: large = AR (10), medium = SC/MO/MI/GA/NC (6), small = FL (3)

twfe_dose <- feols(
  hire_rate_w ~ i(treated_state, cut_magnitude, ref = 0) : i(post, ref = 0) |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)
cat("Dose-response (hire rate × cut magnitude):\n")
summary(twfe_dose)

# Continuous dose
panel <- panel %>%
  mutate(dose_post = cut_magnitude * post)

twfe_continuous <- feols(
  hire_rate_w ~ dose_post | state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)
cat("\nContinuous dose (hire rate per week cut):\n")
summary(twfe_continuous)

# ══════════════════════════════════════════════════════════════════════
# 4. ALTERNATIVE OUTCOMES: SEPARATION RATE, NET JOB CREATION
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Alternative outcomes ===\n")

# Separation rate
twfe_sep2 <- feols(
  sep_rate_w ~ treat_post + treat_post_lowedu + treat_post_highedu |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)

# New hire rate (new hires only, not recalls)
twfe_newhire <- feols(
  new_hire_rate ~ treat_post + treat_post_lowedu + treat_post_highedu |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)

# Log hire earnings
twfe_hireearn <- feols(
  ln_earn_hir ~ treat_post + treat_post_lowedu + treat_post_highedu |
    state_edu_id + education^time_t,
  data = panel,
  cluster = ~statefips
)

cat("Separation rate:\n")
print(coeftable(twfe_sep2))
cat("\nNew hire rate:\n")
print(coeftable(twfe_newhire))
cat("\nLog hire earnings:\n")
print(coeftable(twfe_hireearn))

# ══════════════════════════════════════════════════════════════════════
# 5. PRE-TREATMENT BALANCE TEST
# ══════════════════════════════════════════════════════════════════════
cat("\n=== Pre-treatment balance ===\n")

# Compare 2009 means (pre-treatment for all states)
balance <- panel %>%
  filter(year == 2009) %>%
  group_by(treated_state, edu_label) %>%
  summarise(
    earn = mean(earn_s, na.rm = TRUE),
    hire_rate = mean(hire_rate, na.rm = TRUE),
    sep_rate = mean(sep_rate, na.rm = TRUE),
    emp_millions = mean(emp / 1e6, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(edu_label, treated_state)
print(balance)

# ══════════════════════════════════════════════════════════════════════
# 6. SAVE ROBUSTNESS RESULTS
# ══════════════════════════════════════════════════════════════════════

saveRDS(list(
  cs_nyt = cs_nyt, att_nyt = att_nyt,
  loo_results = loo_results,
  twfe_dose = twfe_dose,
  twfe_continuous = twfe_continuous,
  twfe_sep2 = twfe_sep2,
  twfe_newhire = twfe_newhire,
  twfe_hireearn = twfe_hireearn,
  balance = balance
), "../data/robustness_results.rds")
cat("\nSaved: data/robustness_results.rds\n")
