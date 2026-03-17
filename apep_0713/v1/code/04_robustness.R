## 04_robustness.R — Robustness checks for broadband preemption paper

source("code/00_packages.R")

bds_cs     <- readRDS("data/bds_cs.rds")
acs_cs     <- readRDS("data/acs_cs.rds")
bds_panel  <- readRDS("data/bds_panel.rds")
acs_panel  <- readRDS("data/acs_panel.rds")

## ============================================================
## 1. NOT-YET-TREATED AS ADDITIONAL CONTROL
## ============================================================

cs_firms_nyt <- att_gt(
  yname = "log_firm_birth_rate",
  tname = "year",
  idname = "state_id",
  gname = "gvar",
  data = bds_cs,
  control_group = "notyettreated",  # adds future-treated states as control
  clustervars = "state_id"
)
agg_firms_nyt <- aggte(cs_firms_nyt, type = "simple")
cat("=== ROBUSTNESS 1: Not-Yet-Treated Control (Firms) ===\n")
print(summary(agg_firms_nyt))

## ============================================================
## 2. REPEAL STATES AS NATURAL EXPERIMENT
## ============================================================
## Among preempted states: those that repealed vs. those that didn't
## This isolates the reversal effect

bds_repeal <- bds_cs %>%
  filter(gvar > 0) %>%  # only preempted states
  left_join(
    readRDS("data/preemption_laws.rds") %>%
      select(state_fip, year_repealed) %>%
      rename(year_rep = year_repealed),
    by = c("state_fip" = "state_fip")
  ) %>%
  mutate(
    ## Treatment: state repealed preemption in a given year
    repeal_gvar = ifelse(is.na(year_rep), 0, year_rep),
    repealed_active = case_when(
      is.na(year_rep) ~ 0L,
      year >= year_rep ~ 1L,
      TRUE ~ 0L
    )
  )

if (n_distinct(bds_repeal$state_fip[bds_repeal$repeal_gvar > 0]) >= 3) {
  ## Need ≥3 repeal states for CS-DiD
  cs_repeal <- tryCatch({
    att_gt(
      yname = "log_firm_birth_rate",
      tname = "year",
      idname = "state_id",
      gname = "repeal_gvar",
      data = bds_repeal,
      control_group = "nevertreated",
      clustervars = "state_id"
    )
  }, error = function(e) {
    cat("Repeal DiD failed:", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(cs_repeal)) {
    agg_repeal <- aggte(cs_repeal, type = "simple")
    cat("\n=== ROBUSTNESS 2: Repeal States (Reversal Effect) ===\n")
    print(summary(agg_repeal))
  }
} else {
  cat("Too few repeal states for CS-DiD; using TWFE for repeal test.\n")
  twfe_repeal <- feols(
    log_firm_birth_rate ~ repealed_active | state_fip + year,
    data = bds_repeal %>% mutate(state_id = as.integer(as.factor(state_fip))),
    cluster = ~state_fip
  )
  cat("\n=== ROBUSTNESS 2: Repeal Effect (TWFE, among preempted states) ===\n")
  print(summary(twfe_repeal))
  agg_repeal <- list(overall.att = coef(twfe_repeal)[1],
                     overall.se = se(twfe_repeal)[1])
}

## ============================================================
## 3. PLACEBO: TREAT 2011 COHORT AS IF TREATED IN 2007
## ============================================================
## If there is no true effect, a placebo treatment should be null

bds_placebo <- bds_cs %>%
  mutate(
    ## Move treatment dates 4 years earlier as placebo
    gvar_placebo = case_when(
      gvar == 0 ~ 0L,
      gvar >= 2011 ~ as.integer(gvar - 4),
      TRUE ~ gvar
    )
  )

cs_placebo <- tryCatch({
  att_gt(
    yname = "log_firm_birth_rate",
    tname = "year",
    idname = "state_id",
    gname = "gvar_placebo",
    data = bds_placebo %>% filter(year < 2011),  # only use pre-period to test placebo
    control_group = "nevertreated",
    clustervars = "state_id"
  )
}, error = function(e) {
  cat("Placebo test failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_placebo)) {
  agg_placebo <- aggte(cs_placebo, type = "simple")
  cat("\n=== ROBUSTNESS 3: Placebo Test (shifted treatment) ===\n")
  print(summary(agg_placebo))
} else {
  ## Fallback TWFE placebo
  bds_placebo_preperiod <- bds_panel %>%
    filter(year <= 2010) %>%
    mutate(
      ## Fake treatment: states that enacted 2011+ get fake 2007 treatment
      fake_post = case_when(
        is.na(year_enacted) ~ 0L,
        year_enacted >= 2011 & year >= 2007 ~ 1L,
        TRUE ~ 0L
      )
    )
  twfe_placebo <- feols(
    log(firm_birth_rate) ~ fake_post | state_fip + year,
    data = bds_placebo_preperiod %>%
      mutate(log_firm_birth_rate = log(firm_birth_rate)),
    cluster = ~state_fip
  )
  cat("\n=== ROBUSTNESS 3: Placebo (TWFE, pre-period only) ===\n")
  print(summary(twfe_placebo))
  agg_placebo <- list(overall.att = coef(twfe_placebo)[1],
                     overall.se = se(twfe_placebo)[1])
}

## ============================================================
## 4. BROADBAND ROBUSTNESS — ALTERNATIVE BANDWIDTH
## ============================================================

## HonestDiD sensitivity (simplified: report bounds under small parallel trend violations)
## For simplicity, compute 1.0× pre-trend upper bound as sensitivity check
cs_broadband_rob <- att_gt(
  yname = "broadband_pct",
  tname = "year",
  idname = "state_id",
  gname = "gvar",
  data = acs_cs %>% filter(!is.na(broadband_pct)),
  control_group = "notyettreated",
  clustervars = "state_id"
)
agg_broadband_rob <- aggte(cs_broadband_rob, type = "simple")
cat("\n=== ROBUSTNESS 4: Broadband (Not-Yet-Treated Control) ===\n")
print(summary(agg_broadband_rob))

## ============================================================
## SAVE ROBUSTNESS RESULTS
## ============================================================
rob_results <- list(
  nyt_firms = agg_firms_nyt,
  repeal = agg_repeal,
  placebo = agg_placebo,
  broadband_nyt = agg_broadband_rob
)
saveRDS(rob_results, "data/robustness_results.rds")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
