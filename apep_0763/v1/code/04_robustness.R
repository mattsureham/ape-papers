# 04_robustness.R
# SNAP Emergency Allotment Expiration and Labor Supply
# Robustness checks: TWFE with controls, NYT control, placebo, earnings outcome

source("00_packages.R")

data_dir <- "../data"

# ------------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------------
all_workers   <- readRDS(file.path(data_dir, "all_workers.rds"))
black_workers <- readRDS(file.path(data_dir, "black_workers.rds"))

cat("Loaded datasets for robustness checks.\n")

# ------------------------------------------------------------------
# 2. Robustness 1: TWFE with unemployment rate control
# ------------------------------------------------------------------
cat("\n--- Robustness 1: TWFE with unemployment control ---\n")

twfe_ur_hirn <- feols(
  log_hirn ~ ea_ended + unemp_rate | state_id + time_index,
  data    = all_workers %>% filter(!is.na(log_hirn), !is.na(ea_ended), !is.na(unemp_rate)),
  cluster = ~state_id
)
cat("TWFE + UR (all workers, HirN): coef =", coef(twfe_ur_hirn)["ea_ended"],
    "SE =", se(twfe_ur_hirn)["ea_ended"], "\n")

twfe_ur_emp <- feols(
  log_emp ~ ea_ended + unemp_rate | state_id + time_index,
  data    = all_workers %>% filter(!is.na(log_emp), !is.na(ea_ended), !is.na(unemp_rate)),
  cluster = ~state_id
)
cat("TWFE + UR (all workers, Emp): coef =", coef(twfe_ur_emp)["ea_ended"],
    "SE =", se(twfe_ur_emp)["ea_ended"], "\n")

twfe_ur_black_hirn <- feols(
  log_hirn ~ ea_ended + unemp_rate | state_id + time_index,
  data    = black_workers %>% filter(!is.na(log_hirn), !is.na(ea_ended), !is.na(unemp_rate)),
  cluster = ~state_id
)
cat("TWFE + UR (Black workers, HirN): coef =", coef(twfe_ur_black_hirn)["ea_ended"],
    "SE =", se(twfe_ur_black_hirn)["ea_ended"], "\n")

# ------------------------------------------------------------------
# 3. Robustness 2: CS-DiD with not-yet-treated as control group
# ------------------------------------------------------------------
cat("\n--- Robustness 2: CS-DiD with not-yet-treated control ---\n")

# The 'notyettreated' control uses only states not yet treated at each 2x2 comparison
nyt_helper <- function(df, yvar, label, seed = 42) {
  df_use <- df %>%
    filter(!is.na(.data[[yvar]]), !is.na(first_treat)) %>%
    rename(
      .yvar        = all_of(yvar),
      .unit        = state_id,
      .time        = time_index,
      .first_treat = first_treat
    )

  cat(sprintf("  NYT CS-DiD: %s | Obs: %d\n", label, nrow(df_use)))

  set.seed(seed)
  att_gt_result <- tryCatch({
    att_gt(
      yname         = ".yvar",
      tname         = ".time",
      idname        = ".unit",
      gname         = ".first_treat",
      data          = df_use,
      control_group = "notyettreated",
      anticipation  = 0,
      bstrap        = TRUE,
      biters        = 1000,
      print_details = FALSE
    )
  }, error = function(e) {
    cat(sprintf("    ERROR: %s\n", conditionMessage(e)))
    NULL
  })

  if (is.null(att_gt_result)) return(NULL)

  agg_result <- tryCatch(
    aggte(att_gt_result, type = "simple", bstrap = TRUE, biters = 1000),
    error = function(e) NULL
  )

  list(
    label       = label,
    att_gt      = att_gt_result,
    aggte_simple = agg_result,
    overall_att = if (!is.null(agg_result)) agg_result$overall.att else NA_real_,
    overall_se  = if (!is.null(agg_result)) agg_result$overall.se  else NA_real_
  )
}

cs_nyt_all   <- nyt_helper(all_workers,   "log_hirn", "All Workers NYT")
cs_nyt_black <- nyt_helper(black_workers, "log_hirn", "Black Workers NYT")

if (!is.null(cs_nyt_all)) {
  cat(sprintf("  NYT ATT (all workers): %.4f (SE: %.4f)\n",
              cs_nyt_all$overall_att, cs_nyt_all$overall_se))
}
if (!is.null(cs_nyt_black)) {
  cat(sprintf("  NYT ATT (black workers): %.4f (SE: %.4f)\n",
              cs_nyt_black$overall_att, cs_nyt_black$overall_se))
}

# ------------------------------------------------------------------
# 4. Robustness 3: Pre-COVID placebo test
# ------------------------------------------------------------------
cat("\n--- Robustness 3: Pre-COVID placebo (2019Q1-2020Q1) ---\n")
# Fake treatment: assign a spurious termination date of 2019Q3 (time_index = 3)
# to the states that later terminated EA early.
# Restrict to pre-COVID period: time_index 1-5 (2019Q1-2020Q1)
# True null should yield near-zero ATT.

placebo_period <- all_workers %>%
  filter(time_index <= 5) %>%   # 2019Q1 to 2020Q1
  mutate(
    # Fake first_treat: treated states get 2019Q3 (index 3), controls get 0
    placebo_first_treat = if_else(treated == 1, 3L, 0L),
    # Remove observations that are "treated" before the placebo date
    # (keep all for this short window, but flag)
    placebo_ea_ended = as.integer(time_index >= 3 & treated == 1)
  )

cat(sprintf("  Placebo period: %d obs, %d periods, %d units\n",
            nrow(placebo_period),
            n_distinct(placebo_period$time_index),
            n_distinct(placebo_period$state_id)))

# Only run if we have enough pre-periods (at least 2 before time=3)
if (n_distinct(placebo_period$time_index[placebo_period$time_index < 3]) >= 2) {
  set.seed(99)
  placebo_att <- tryCatch({
    df_plac <- placebo_period %>%
      filter(!is.na(log_hirn)) %>%
      rename(
        .yvar = log_hirn,
        .unit = state_id,
        .time = time_index,
        .first_treat = placebo_first_treat
      )

    ag <- att_gt(
      yname         = ".yvar",
      tname         = ".time",
      idname        = ".unit",
      gname         = ".first_treat",
      data          = df_plac,
      control_group = "nevertreated",
      anticipation  = 0,
      bstrap        = TRUE,
      biters        = 1000,
      print_details = FALSE
    )
    aggte(ag, type = "simple", bstrap = TRUE, biters = 1000)
  }, error = function(e) {
    cat(sprintf("    Placebo ERROR: %s\n", conditionMessage(e)))
    NULL
  })

  # Alternatively, run TWFE placebo
  twfe_placebo <- feols(
    log_hirn ~ placebo_ea_ended | state_id + time_index,
    data    = placebo_period %>% filter(!is.na(log_hirn)),
    cluster = ~state_id
  )

  placebo_coef <- coef(twfe_placebo)["placebo_ea_ended"]
  placebo_se   <- se(twfe_placebo)["placebo_ea_ended"]
  placebo_tstat <- placebo_coef / placebo_se

  cat(sprintf("  TWFE Placebo: coef = %.4f, SE = %.4f, t = %.3f\n",
              placebo_coef, placebo_se, placebo_tstat))

  if (!is.null(placebo_att)) {
    cat(sprintf("  CS-DiD Placebo ATT: %.4f (SE: %.4f)\n",
                placebo_att$overall.att, placebo_att$overall.se))
  }
} else {
  cat("  Insufficient pre-periods for CS-DiD placebo; running TWFE only.\n")
  twfe_placebo <- feols(
    log_hirn ~ placebo_ea_ended | state_id + time_index,
    data    = placebo_period %>% filter(!is.na(log_hirn)),
    cluster = ~state_id
  )
  placebo_coef  <- coef(twfe_placebo)["placebo_ea_ended"]
  placebo_se    <- se(twfe_placebo)["placebo_ea_ended"]
  placebo_att   <- NULL
}

# ------------------------------------------------------------------
# 5. Robustness 4: Earnings outcome (EarnS)
# ------------------------------------------------------------------
cat("\n--- Robustness 4: Earnings outcome ---\n")

# CS-DiD: earnings for all workers
set.seed(123)
df_earns <- all_workers %>%
  filter(!is.na(log_earns), !is.na(first_treat)) %>%
  rename(
    .yvar        = log_earns,
    .unit        = state_id,
    .time        = time_index,
    .first_treat = first_treat
  )

cs_earns <- tryCatch({
  ag <- att_gt(
    yname         = ".yvar",
    tname         = ".time",
    idname        = ".unit",
    gname         = ".first_treat",
    data          = df_earns,
    control_group = "nevertreated",
    anticipation  = 0,
    bstrap        = TRUE,
    biters        = 1000,
    print_details = FALSE
  )
  aggte(ag, type = "simple", bstrap = TRUE, biters = 1000)
}, error = function(e) {
  cat(sprintf("  Earnings CS-DiD ERROR: %s\n", conditionMessage(e)))
  NULL
})

if (!is.null(cs_earns)) {
  cat(sprintf("  CS-DiD Earnings ATT: %.4f (SE: %.4f)\n",
              cs_earns$overall.att, cs_earns$overall.se))
}

twfe_earns <- feols(
  log_earns ~ ea_ended | state_id + time_index,
  data    = all_workers %>% filter(!is.na(log_earns), !is.na(ea_ended)),
  cluster = ~state_id
)
cat(sprintf("  TWFE Earnings: coef = %.4f (SE: %.4f)\n",
            coef(twfe_earns)["ea_ended"],
            se(twfe_earns)["ea_ended"]))

# ------------------------------------------------------------------
# 6. Collect and save robustness results
# ------------------------------------------------------------------
robustness_results <- list(
  # 1. TWFE with UR control
  twfe_ur_all_hirn   = twfe_ur_hirn,
  twfe_ur_all_emp    = twfe_ur_emp,
  twfe_ur_black_hirn = twfe_ur_black_hirn,

  # 2. Not-yet-treated CS-DiD
  cs_nyt_all   = cs_nyt_all,
  cs_nyt_black = cs_nyt_black,

  # 3. Placebo
  twfe_placebo    = twfe_placebo,
  cs_placebo      = if (exists("placebo_att")) placebo_att else NULL,
  placebo_coef    = if (exists("placebo_coef")) placebo_coef else NA_real_,
  placebo_se      = if (exists("placebo_se")) placebo_se else NA_real_,

  # 4. Earnings
  cs_earns   = cs_earns,
  twfe_earns = twfe_earns,

  # Summary table scaffold
  summary = data.frame(
    spec    = c("TWFE + UR Control", "CS-DiD NYT", "Placebo (TWFE)", "Earnings (CS-DiD)"),
    outcome = c("log_hirn", "log_hirn", "log_hirn", "log_earns"),
    group   = c("All", "All", "All (fake 2019Q3)", "All"),
    att     = c(
      coef(twfe_ur_hirn)["ea_ended"],
      if (!is.null(cs_nyt_all)) cs_nyt_all$overall_att else NA,
      if (exists("placebo_coef")) placebo_coef else NA,
      if (!is.null(cs_earns)) cs_earns$overall.att else NA
    ),
    se      = c(
      se(twfe_ur_hirn)["ea_ended"],
      if (!is.null(cs_nyt_all)) cs_nyt_all$overall_se else NA,
      if (exists("placebo_se")) placebo_se else NA,
      if (!is.null(cs_earns)) cs_earns$overall.se else NA
    )
  )
)

saveRDS(robustness_results, file.path(data_dir, "robustness_results.rds"))
cat("\nSaved robustness_results.rds\n")

cat("\n04_robustness.R complete.\n")
