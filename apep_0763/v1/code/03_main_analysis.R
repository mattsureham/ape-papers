# 03_main_analysis.R
# SNAP Emergency Allotment Expiration and Labor Supply
# Main CS-DiD and TWFE estimates

source("00_packages.R")

data_dir   <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------------
all_workers   <- readRDS(file.path(data_dir, "all_workers.rds"))
black_workers <- readRDS(file.path(data_dir, "black_workers.rds"))

cat("Loaded datasets:\n")
cat("  All workers:", nrow(all_workers), "rows\n")
cat("  Black workers:", nrow(black_workers), "rows\n")

# ------------------------------------------------------------------
# 2. Helper: Run CS-DiD and extract results
# ------------------------------------------------------------------
run_csdd <- function(df, yvar, label, control_group = "nevertreated",
                     anticipation = 0, bstrap = TRUE, biters = 1000, seed = 42) {
  # Remove observations with missing outcome or treatment timing
  df_use <- df %>%
    filter(!is.na(.data[[yvar]]), !is.na(first_treat)) %>%
    # CS-DiD requires: unit id, time, first treatment period (0 = never treated), outcome
    rename(
      .yvar = all_of(yvar),
      .unit = state_id,
      .time = time_index,
      .first_treat = first_treat
    )

  cat(sprintf("\nRunning CS-DiD: %s ~ %s\n", label, yvar))
  cat(sprintf("  Control group: %s | Obs: %d | Units: %d | Periods: %d\n",
              control_group, nrow(df_use), n_distinct(df_use$.unit), n_distinct(df_use$.time)))

  set.seed(seed)
  att_gt_result <- tryCatch({
    att_gt(
      yname        = ".yvar",
      tname        = ".time",
      idname       = ".unit",
      gname        = ".first_treat",
      data         = df_use,
      control_group = control_group,
      anticipation  = anticipation,
      bstrap        = bstrap,
      biters        = biters,
      print_details = FALSE
    )
  }, error = function(e) {
    cat(sprintf("  ERROR in att_gt: %s\n", conditionMessage(e)))
    NULL
  })

  if (is.null(att_gt_result)) return(NULL)

  # Aggregate to overall ATT
  agg_result <- tryCatch({
    aggte(att_gt_result, type = "simple", bstrap = bstrap, biters = biters)
  }, error = function(e) {
    cat(sprintf("  ERROR in aggte(simple): %s\n", conditionMessage(e)))
    NULL
  })

  # Event-study aggregation
  es_result <- tryCatch({
    aggte(att_gt_result, type = "dynamic", bstrap = bstrap, biters = biters,
          min_e = -8, max_e = 8)
  }, error = function(e) {
    cat(sprintf("  ERROR in aggte(dynamic): %s\n", conditionMessage(e)))
    NULL
  })

  overall_att <- if (!is.null(agg_result)) agg_result$overall.att else NA_real_
  overall_se  <- if (!is.null(agg_result)) agg_result$overall.se  else NA_real_

  cat(sprintf("  Overall ATT: %.4f (SE: %.4f)\n", overall_att, overall_se))

  list(
    label     = label,
    yvar      = yvar,
    att_gt    = att_gt_result,
    aggte_simple = agg_result,
    aggte_es  = es_result,
    overall_att = overall_att,
    overall_se  = overall_se,
    n_obs     = nrow(df_use),
    n_treated = n_distinct(df_use$.unit[df_use$.first_treat > 0]),
    n_pre     = n_distinct(df_use$.time[df_use$.time < min(df_use$.first_treat[df_use$.first_treat > 0], na.rm = TRUE)])
  )
}

# ------------------------------------------------------------------
# 3. Main CS-DiD estimates
# ------------------------------------------------------------------

# (A) All workers: log new hires
cs_all_hirn <- run_csdd(all_workers, "log_hirn", "All Workers - Log New Hires")

# (B) Black workers: log new hires
cs_black_hirn <- run_csdd(black_workers, "log_hirn", "Black Workers - Log New Hires")

# (C) All workers: log employment stock
cs_all_emp <- run_csdd(all_workers, "log_emp", "All Workers - Log Employment")

# ------------------------------------------------------------------
# 4. TWFE estimates (for comparison)
# ------------------------------------------------------------------
cat("\nRunning TWFE estimates...\n")

# (A) All workers: log new hires
twfe_all_hirn <- feols(
  log_hirn ~ ea_ended | state_id + time_index,
  data    = all_workers %>% filter(!is.na(log_hirn), !is.na(ea_ended)),
  cluster = ~state_id
)
cat("TWFE All Workers HirN: coef =", coef(twfe_all_hirn)["ea_ended"],
    "SE =", se(twfe_all_hirn)["ea_ended"], "\n")

# (B) Black workers: log new hires
twfe_black_hirn <- feols(
  log_hirn ~ ea_ended | state_id + time_index,
  data    = black_workers %>% filter(!is.na(log_hirn), !is.na(ea_ended)),
  cluster = ~state_id
)
cat("TWFE Black Workers HirN: coef =", coef(twfe_black_hirn)["ea_ended"],
    "SE =", se(twfe_black_hirn)["ea_ended"], "\n")

# (C) All workers: log employment
twfe_all_emp <- feols(
  log_emp ~ ea_ended | state_id + time_index,
  data    = all_workers %>% filter(!is.na(log_emp), !is.na(ea_ended)),
  cluster = ~state_id
)
cat("TWFE All Workers Emp: coef =", coef(twfe_all_emp)["ea_ended"],
    "SE =", se(twfe_all_emp)["ea_ended"], "\n")

# ------------------------------------------------------------------
# 5. Diagnostics
# ------------------------------------------------------------------
n_treated_states <- n_distinct(all_workers$state_id[all_workers$treated == 1])
n_pre_periods    <- n_distinct(all_workers$time_index[
  all_workers$time_index < min(all_workers$first_treat[all_workers$first_treat > 0], na.rm = TRUE)
])
n_obs_all <- nrow(all_workers %>% filter(!is.na(log_hirn)))

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre     = n_pre_periods,
  n_obs     = n_obs_all,
  n_states_total = n_distinct(all_workers$state_id),
  time_periods   = n_distinct(all_workers$time_index),
  cs_all_hirn_att = if (!is.null(cs_all_hirn)) cs_all_hirn$overall_att else NA,
  cs_all_hirn_se  = if (!is.null(cs_all_hirn)) cs_all_hirn$overall_se  else NA,
  cs_black_hirn_att = if (!is.null(cs_black_hirn)) cs_black_hirn$overall_att else NA,
  cs_black_hirn_se  = if (!is.null(cs_black_hirn)) cs_black_hirn$overall_se  else NA,
  cs_all_emp_att  = if (!is.null(cs_all_emp)) cs_all_emp$overall_att else NA,
  cs_all_emp_se   = if (!is.null(cs_all_emp)) cs_all_emp$overall_se  else NA,
  twfe_all_hirn_coef = coef(twfe_all_hirn)["ea_ended"],
  twfe_all_hirn_se   = se(twfe_all_hirn)["ea_ended"],
  twfe_black_hirn_coef = coef(twfe_black_hirn)["ea_ended"],
  twfe_black_hirn_se   = se(twfe_black_hirn)["ea_ended"]
)

# Phase gate check
stopifnot(
  "n_treated < 15: insufficient treated units" = diagnostics$n_treated >= 15,
  "n_pre < 8: insufficient pre-periods"        = diagnostics$n_pre     >= 8,
  "n_obs too small"                            = diagnostics$n_obs     > 100
)

cat("\nDiagnostics passed:\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), pretty = TRUE, auto_unbox = TRUE)
cat("Saved diagnostics.json\n")

# ------------------------------------------------------------------
# 6. Save all results
# ------------------------------------------------------------------
main_results <- list(
  cs_all_hirn   = cs_all_hirn,
  cs_black_hirn = cs_black_hirn,
  cs_all_emp    = cs_all_emp,
  twfe_all_hirn   = twfe_all_hirn,
  twfe_black_hirn = twfe_black_hirn,
  twfe_all_emp    = twfe_all_emp,
  diagnostics   = diagnostics
)

saveRDS(main_results, file.path(data_dir, "main_results.rds"))
cat("Saved main_results.rds\n")

# ------------------------------------------------------------------
# 7. Event study figure
# ------------------------------------------------------------------
figures_dir <- "../figures"
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)

if (!is.null(cs_all_hirn) && !is.null(cs_all_hirn$aggte_es)) {
  es_data_all <- data.frame(
    event_time = cs_all_hirn$aggte_es$egt,
    att        = cs_all_hirn$aggte_es$att.egt,
    se         = cs_all_hirn$aggte_es$se.egt
  ) %>%
    filter(!is.na(att)) %>%
    mutate(
      ci_lo = att - 1.96 * se,
      ci_hi = att + 1.96 * se
    )

  p_es_all <- ggplot(es_data_all, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "steelblue", size = 2) +
    scale_x_continuous(breaks = seq(min(es_data_all$event_time), max(es_data_all$event_time), by = 1)) +
    labs(
      x = "Quarters Relative to EA Termination",
      y = "ATT: Log New Hires",
      title = "Event Study: EA Termination Effect on New Hires (All Workers)",
      caption = "CS-DiD dynamic ATT estimates. 95% confidence bands. Vertical line at -0.5 marks treatment onset."
    ) +
    theme_bw(base_size = 12)

  ggsave(file.path(figures_dir, "fig1_event_study_all.pdf"), p_es_all,
         width = 8, height = 5)
  ggsave(file.path(figures_dir, "fig1_event_study_all.png"), p_es_all,
         width = 8, height = 5, dpi = 300)
  cat("Saved fig1_event_study_all\n")
}

if (!is.null(cs_black_hirn) && !is.null(cs_black_hirn$aggte_es)) {
  es_data_black <- data.frame(
    event_time = cs_black_hirn$aggte_es$egt,
    att        = cs_black_hirn$aggte_es$att.egt,
    se         = cs_black_hirn$aggte_es$se.egt
  ) %>%
    filter(!is.na(att)) %>%
    mutate(
      ci_lo = att - 1.96 * se,
      ci_hi = att + 1.96 * se
    )

  p_es_black <- ggplot(es_data_black, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "darkred") +
    geom_line(color = "darkred", linewidth = 0.8) +
    geom_point(color = "darkred", size = 2) +
    scale_x_continuous(breaks = seq(min(es_data_black$event_time), max(es_data_black$event_time), by = 1)) +
    labs(
      x = "Quarters Relative to EA Termination",
      y = "ATT: Log New Hires (Black Workers)",
      title = "Event Study: EA Termination Effect on New Hires (Black Workers)",
      caption = "CS-DiD dynamic ATT estimates. 95% confidence bands. Vertical line at -0.5 marks treatment onset."
    ) +
    theme_bw(base_size = 12)

  ggsave(file.path(figures_dir, "fig2_event_study_black.pdf"), p_es_black,
         width = 8, height = 5)
  ggsave(file.path(figures_dir, "fig2_event_study_black.png"), p_es_black,
         width = 8, height = 5, dpi = 300)
  cat("Saved fig2_event_study_black\n")
}

# Combined event study panel
if (!is.null(cs_all_hirn) && !is.null(cs_black_hirn)) {
  p_combined <- p_es_all / p_es_black
  ggsave(file.path(figures_dir, "fig3_event_study_combined.pdf"), p_combined,
         width = 8, height = 9)
  ggsave(file.path(figures_dir, "fig3_event_study_combined.png"), p_combined,
         width = 8, height = 9, dpi = 300)
  cat("Saved fig3_event_study_combined\n")
}

cat("\n03_main_analysis.R complete.\n")
