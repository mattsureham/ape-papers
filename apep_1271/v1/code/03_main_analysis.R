# 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
# Paper: Mandated to Stay (apep_1271)

source("00_packages.R")

food <- fread("../data/panel_food.csv")

cat("=== MAIN ANALYSIS: Callaway-Sant'Anna Staggered DiD ===\n")
cat(sprintf("Panel: %s obs, %d counties, %d states\n",
            format(nrow(food), big.mark = ","),
            uniqueN(food$county_fips),
            uniqueN(food$state_fips)))

# ---- Helper: run CS-DiD for one outcome ----
run_cs <- function(data, yname, control = "notyettreated", label = yname) {
  cat(sprintf("\n--- %s (control: %s) ---\n", label, control))

  # Remove NAs in outcome
  d <- data[!is.na(get(yname))]

  cs <- att_gt(
    yname = yname,
    tname = "quarter_num",
    idname = "county_fips",
    gname = "treatment_quarter",
    data = d,
    control_group = control,
    clustervars = "state_fips",
    base_period = "universal",
    anticipation = 0
  )

  # Aggregate: simple weighted average
  agg_simple <- aggte(cs, type = "simple")
  cat(sprintf("  ATT(simple): %.5f (SE: %.5f, p: %.4f)\n",
              agg_simple$overall.att, agg_simple$overall.se,
              2 * pnorm(-abs(agg_simple$overall.att / agg_simple$overall.se))))

  # Aggregate: event study (dynamic)
  agg_dyn <- aggte(cs, type = "dynamic", min_e = -12, max_e = 12)

  list(cs = cs, simple = agg_simple, dynamic = agg_dyn)
}

# ---- Main results: Four-way decomposition ----
outcomes <- c("sep_rate", "hirn_rate", "hirr_rate", "stability")
labels <- c("Separation Rate", "New Hire Rate", "Recall Rate", "Stable Employment Share")

results <- list()
for (i in seq_along(outcomes)) {
  results[[outcomes[i]]] <- run_cs(food, outcomes[i], label = labels[i])
}

# Also run turnover rate
results[["turnover"]] <- run_cs(food, "turnover", label = "Turnover Rate")

# ---- Collect ATT estimates for Table 1 ----
att_table <- data.table(
  outcome = c(labels, "Turnover Rate"),
  att = sapply(c(outcomes, "turnover"), function(o) results[[o]]$simple$overall.att),
  se = sapply(c(outcomes, "turnover"), function(o) results[[o]]$simple$overall.se),
  ci_lo = sapply(c(outcomes, "turnover"), function(o) {
    a <- results[[o]]$simple
    a$overall.att - 1.96 * a$overall.se
  }),
  ci_hi = sapply(c(outcomes, "turnover"), function(o) {
    a <- results[[o]]$simple
    a$overall.att + 1.96 * a$overall.se
  })
)

att_table[, pval := 2 * pnorm(-abs(att / se))]
att_table[, stars := fifelse(pval < 0.01, "***",
                     fifelse(pval < 0.05, "**",
                     fifelse(pval < 0.10, "*", "")))]

cat("\n=== TABLE 1: Four-Way Decomposition ===\n")
print(att_table)

# ---- Pre-treatment summary stats for SDE computation ----
pre_food <- food[treatment_quarter == 0 | quarter_num < treatment_quarter]
pre_sds <- data.table(
  outcome = c(labels, "Turnover Rate"),
  variable = c(outcomes, "turnover"),
  pre_mean = sapply(c(outcomes, "turnover"), function(o) mean(pre_food[[o]], na.rm = TRUE)),
  pre_sd = sapply(c(outcomes, "turnover"), function(o) sd(pre_food[[o]], na.rm = TRUE))
)

cat("\n=== Pre-Treatment Summary Statistics ===\n")
print(pre_sds)

# ---- Save results ----
saveRDS(results, "../data/cs_results.rds")
fwrite(att_table, "../data/att_table.csv")
fwrite(pre_sds, "../data/pre_sds.csv")

# ---- Diagnostics JSON ----
n_treated_counties <- uniqueN(food[treatment_quarter > 0, county_fips])
n_pre_quarters <- food[treatment_quarter > 0, min(treatment_quarter) - min(quarter_num)]
n_obs <- nrow(food)
n_states <- uniqueN(food$state_fips)

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = as.integer(n_pre_quarters),
  n_obs = n_obs,
  n_states = n_states,
  n_treated_states = uniqueN(food[treatment_quarter > 0, state_fips]),
  n_control_states = uniqueN(food[treatment_quarter == 0, state_fips])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: %d treated counties, %d pre-periods, %s obs, %d states\n",
            diagnostics$n_treated, diagnostics$n_pre, format(n_obs, big.mark = ","), n_states))

cat("\n03_main_analysis.R completed successfully.\n")
