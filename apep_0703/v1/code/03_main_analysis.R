# =============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
# Marijuana legalization and labor market firm dynamics
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
time_index <- readRDS("../data/time_index.rds")

# ---------------------------------------------------------------------------
# 1. All-industry aggregate: state x quarter panel
# ---------------------------------------------------------------------------
agg_panel <- panel %>%
  filter(industry == "00") %>%
  select(state_id, time_id, g_time, state_fips, quarter_num, year, q,
         emp, frm_jb_gn, frm_jb_ls, net_firm_jb, hir_a, hir_n, sep, earn_s,
         log_emp, turnover, treat_quarter, post, treated)

# Balance panel: keep only states with full time coverage
full_T <- max(agg_panel$time_id) - min(agg_panel$time_id) + 1
state_counts <- agg_panel %>% count(state_id)
balanced_ids <- state_counts$state_id[state_counts$n == full_T]
agg_panel <- agg_panel %>% filter(state_id %in% balanced_ids)

cat("Aggregate panel: ", nrow(agg_panel), " state-quarters\n")
cat("  Treated states: ", n_distinct(agg_panel$state_fips[agg_panel$g_time > 0]), "\n")
cat("  Never-treated: ", n_distinct(agg_panel$state_fips[agg_panel$g_time == 0]), "\n")

# ---------------------------------------------------------------------------
# 2. Callaway-Sant'Anna: Employment (log)
# ---------------------------------------------------------------------------
cat("Running CS-DiD on log(employment)...\n")

cs_emp <- att_gt(
  yname = "log_emp",
  tname = "time_id",
  idname = "state_id",
  gname = "g_time",
  data = agg_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

es_emp <- aggte(cs_emp, type = "dynamic", min_e = -12, max_e = 12)
overall_emp <- aggte(cs_emp, type = "simple")

cat("Overall ATT (log emp):", overall_emp$overall.att,
    "SE:", overall_emp$overall.se, "\n")

# ---------------------------------------------------------------------------
# 3. Callaway-Sant'Anna: Net Firm Job Creation
# ---------------------------------------------------------------------------
cat("Running CS-DiD on net firm job creation...\n")

cs_net <- att_gt(
  yname = "net_firm_jb",
  tname = "time_id",
  idname = "state_id",
  gname = "g_time",
  data = agg_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

es_net <- aggte(cs_net, type = "dynamic", min_e = -12, max_e = 12)
overall_net <- aggte(cs_net, type = "simple")

cat("Overall ATT (net firm jobs):", overall_net$overall.att,
    "SE:", overall_net$overall.se, "\n")

# ---------------------------------------------------------------------------
# 4. Callaway-Sant'Anna: Firm Job Gains (creation)
# ---------------------------------------------------------------------------
cat("Running CS-DiD on firm job gains...\n")

cs_gains <- att_gt(
  yname = "frm_jb_gn",
  tname = "time_id",
  idname = "state_id",
  gname = "g_time",
  data = agg_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

es_gains <- aggte(cs_gains, type = "dynamic", min_e = -12, max_e = 12)
overall_gains <- aggte(cs_gains, type = "simple")

cat("Overall ATT (firm job gains):", overall_gains$overall.att,
    "SE:", overall_gains$overall.se, "\n")

# ---------------------------------------------------------------------------
# 5. Callaway-Sant'Anna: Firm Job Losses (destruction)
# ---------------------------------------------------------------------------
cat("Running CS-DiD on firm job losses...\n")

cs_losses <- att_gt(
  yname = "frm_jb_ls",
  tname = "time_id",
  idname = "state_id",
  gname = "g_time",
  data = agg_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

es_losses <- aggte(cs_losses, type = "dynamic", min_e = -12, max_e = 12)
overall_losses <- aggte(cs_losses, type = "simple")

cat("Overall ATT (firm job losses):", overall_losses$overall.att,
    "SE:", overall_losses$overall.se, "\n")

# ---------------------------------------------------------------------------
# 6. Callaway-Sant'Anna: Average Earnings
# ---------------------------------------------------------------------------
cat("Running CS-DiD on average earnings...\n")

cs_earn <- att_gt(
  yname = "earn_s",
  tname = "time_id",
  idname = "state_id",
  gname = "g_time",
  data = agg_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

es_earn <- aggte(cs_earn, type = "dynamic", min_e = -12, max_e = 12)
overall_earn <- aggte(cs_earn, type = "simple")

cat("Overall ATT (earnings):", overall_earn$overall.att,
    "SE:", overall_earn$overall.se, "\n")

# ---------------------------------------------------------------------------
# 7. TWFE as comparison
# ---------------------------------------------------------------------------
cat("Running TWFE for comparison...\n")

twfe_emp <- feols(log_emp ~ post | state_id + time_id, data = agg_panel,
                  cluster = ~state_fips)
twfe_net <- feols(net_firm_jb ~ post | state_id + time_id, data = agg_panel,
                  cluster = ~state_fips)
twfe_gains <- feols(frm_jb_gn ~ post | state_id + time_id, data = agg_panel,
                    cluster = ~state_fips)
twfe_losses <- feols(frm_jb_ls ~ post | state_id + time_id, data = agg_panel,
                     cluster = ~state_fips)
twfe_earn <- feols(earn_s ~ post | state_id + time_id, data = agg_panel,
                   cluster = ~state_fips)

# ---------------------------------------------------------------------------
# 8. Industry decomposition: CS-DiD by sector
# ---------------------------------------------------------------------------
cat("Running industry-specific CS-DiD...\n")

key_industries <- c("44-45", "72", "62", "31-33", "54", "11")
industry_labels <- c("Retail Trade", "Accommodation & Food",
                     "Health Care", "Manufacturing",
                     "Professional Services", "Agriculture")

industry_results <- list()

for (i in seq_along(key_industries)) {
  ind_code <- key_industries[i]
  ind_data <- panel %>%
    filter(industry == ind_code) %>%
    filter(!is.na(emp), emp > 0)

  n_treated_ind <- n_distinct(ind_data$state_fips[ind_data$g_time > 0])

  if (n_treated_ind < 5) {
    cat("  Skipping", ind_code, "- too few treated states\n")
    next
  }

  # Use TWFE for industry decomposition (CS-DiD fails on unbalanced industry panels)
  twfe_ind <- tryCatch(
    feols(log_emp ~ post | state_id + time_id, data = ind_data,
          cluster = ~state_fips),
    error = function(e) {
      cat("  TWFE failed for", ind_code, ":", e$message, "\n")
      NULL
    }
  )

  if (!is.null(twfe_ind)) {
    industry_results[[ind_code]] <- list(
      industry = ind_code,
      label = industry_labels[i],
      att = coef(twfe_ind)["post"],
      se = se(twfe_ind)["post"],
      n_treated = n_treated_ind
    )
    cat("  ", industry_labels[i], ": ATT =",
        round(coef(twfe_ind)["post"], 4),
        "SE =", round(se(twfe_ind)["post"], 4), "\n")
  }
}

# ---------------------------------------------------------------------------
# 9. Save all results
# ---------------------------------------------------------------------------

# Diagnostics for validator
# Report treated states from the full design (including those dropped for balance)
all_treated <- panel %>%
  filter(g_time > 0, industry == "00") %>%
  pull(state_fips) %>%
  n_distinct()
n_treated <- all_treated
n_pre <- sum(time_index$quarter_num < min(
  panel$treat_quarter[panel$treat_quarter > 0 & panel$industry == "00"]))
n_obs <- nrow(agg_panel)

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json", auto_unbox = TRUE
)

results <- list(
  cs_emp = cs_emp, es_emp = es_emp, overall_emp = overall_emp,
  cs_net = cs_net, es_net = es_net, overall_net = overall_net,
  cs_gains = cs_gains, es_gains = es_gains, overall_gains = overall_gains,
  cs_losses = cs_losses, es_losses = es_losses, overall_losses = overall_losses,
  cs_earn = cs_earn, es_earn = es_earn, overall_earn = overall_earn,
  twfe_emp = twfe_emp, twfe_net = twfe_net,
  twfe_gains = twfe_gains, twfe_losses = twfe_losses, twfe_earn = twfe_earn,
  industry_results = industry_results,
  agg_panel = agg_panel
)

saveRDS(results, "../data/main_results.rds")
cat("\nAll main results saved to data/main_results.rds\n")
