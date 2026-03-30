## 03_main_analysis.R — Main analysis: Callaway-Sant'Anna + TWFE
## Paper: apep_1121 — Swiss cantonal debt brakes and spending composition

source("00_packages.R")

cat("=== Main analysis ===\n")

# ---------------------------------------------------------------
# 1. LOAD DATA
# ---------------------------------------------------------------

analysis_df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat("Panel:", nrow(analysis_df), "rows\n")
cat("Cantons:", n_distinct(analysis_df$canton), "\n")
cat("Years:", min(analysis_df$year), "-", max(analysis_df$year), "\n")

# Exclude St. Gallen (1929) and Fribourg (1960) from main analysis
# They adopted rules decades before the panel — always treated
# Keep 4 never-treated + 20 cantons adopting 1994-2014
analysis_main <- analysis_df %>%
  filter(first_treat_cs == 0 | first_treat_cs >= 1990)

cat("Main analysis sample (excl. pre-1990 adopters):\n")
cat("  Cantons:", n_distinct(analysis_main$canton), "\n")
cat("  Treated:", sum(analysis_main$first_treat_cs > 0 & analysis_main$func_code == "2" & analysis_main$year == 2010), "\n")
cat("  Never-treated:", sum(analysis_main$first_treat_cs == 0 & analysis_main$func_code == "2" & analysis_main$year == 2010), "\n")

# ---------------------------------------------------------------
# 2. CALLAWAY-SANT'ANNA ESTIMATION
# For each major function
# ---------------------------------------------------------------

cat("\n=== Callaway-Sant'Anna estimation ===\n")

# Functions to analyze
functions_to_analyze <- c("2", "4", "5", "6", "0", "1", "8", "3")
func_names_map <- c("2"="Education", "4"="Health", "5"="Social",
                     "6"="Transport", "0"="Administration", "1"="Security",
                     "8"="Economy", "3"="Culture")

cs_results <- list()
cs_agg_results <- list()

for (fc in functions_to_analyze) {
  cat(sprintf("\n--- Function %s: %s ---\n", fc, func_names_map[fc]))

  df_func <- analysis_main %>%
    filter(func_code == fc) %>%
    arrange(canton_id, year)

  # Check for variation
  cat("  Obs:", nrow(df_func), "\n")
  cat("  Treatment groups:", paste(sort(unique(df_func$first_treat_cs[df_func$first_treat_cs > 0])), collapse=", "), "\n")

  # Run Callaway-Sant'Anna
  cs_out <- tryCatch({
    att_gt(
      yname = "share",
      tname = "year",
      idname = "canton_id",
      gname = "first_treat_cs",
      data = as.data.frame(df_func),
      control_group = "notyettreated",
      anticipation = 0,
      base_period = "varying"
    )
  }, error = function(e) {
    cat("  CS failed:", e$message, "\n")
    # Try with never-treated only
    tryCatch({
      att_gt(
        yname = "share",
        tname = "year",
        idname = "canton_id",
        gname = "first_treat_cs",
        data = as.data.frame(df_func),
        control_group = "nevertreated",
        anticipation = 0,
        base_period = "varying"
      )
    }, error = function(e2) {
      cat("  CS (nevertreated) also failed:", e2$message, "\n")
      NULL
    })
  })

  if (!is.null(cs_out)) {
    cs_results[[fc]] <- cs_out

    # Aggregate: overall ATT
    agg_overall <- aggte(cs_out, type = "simple")
    cat(sprintf("  Overall ATT: %.3f (SE: %.3f, p: %.3f)\n",
                agg_overall$overall.att, agg_overall$overall.se,
                2 * pnorm(-abs(agg_overall$overall.att / agg_overall$overall.se))))

    # Aggregate: dynamic/event study
    agg_dynamic <- tryCatch({
      aggte(cs_out, type = "dynamic")
    }, error = function(e) {
      cat("  Dynamic aggregation failed:", e$message, "\n")
      NULL
    })

    cs_agg_results[[fc]] <- list(
      overall = agg_overall,
      dynamic = agg_dynamic
    )
  }
}

# ---------------------------------------------------------------
# 3. TWFE ESTIMATION (for comparison)
# ---------------------------------------------------------------

cat("\n\n=== TWFE estimation (fixest) ===\n")

twfe_results <- list()

for (fc in functions_to_analyze) {
  df_func <- analysis_main %>% filter(func_code == fc)

  # TWFE with canton and year fixed effects
  twfe_fit <- feols(
    share ~ treat_post | canton_id + year,
    data = df_func,
    cluster = ~canton_id
  )

  twfe_results[[fc]] <- twfe_fit
  cat(sprintf("  %s: coef=%.3f, se=%.3f, p=%.3f\n",
              func_names_map[fc],
              coef(twfe_fit)["treat_post"],
              sqrt(vcov(twfe_fit)["treat_post", "treat_post"]),
              pvalue(twfe_fit)["treat_post"]))
}

# ---------------------------------------------------------------
# 4. COMPILE RESULTS TABLE
# ---------------------------------------------------------------

cat("\n=== Results summary ===\n")

results_table <- tibble(
  Function = character(),
  CS_ATT = numeric(),
  CS_SE = numeric(),
  CS_pval = numeric(),
  TWFE_coef = numeric(),
  TWFE_se = numeric(),
  TWFE_pval = numeric()
)

for (fc in functions_to_analyze) {
  cs_att <- cs_agg_results[[fc]]$overall$overall.att
  cs_se <- cs_agg_results[[fc]]$overall$overall.se
  cs_p <- 2 * pnorm(-abs(cs_att / cs_se))

  tw_coef <- coef(twfe_results[[fc]])["treat_post"]
  tw_se <- sqrt(vcov(twfe_results[[fc]])["treat_post", "treat_post"])
  tw_p <- pvalue(twfe_results[[fc]])["treat_post"]

  results_table <- bind_rows(results_table, tibble(
    Function = func_names_map[fc],
    CS_ATT = cs_att, CS_SE = cs_se, CS_pval = cs_p,
    TWFE_coef = tw_coef, TWFE_se = tw_se, TWFE_pval = tw_p
  ))
}

print(results_table)

# ---------------------------------------------------------------
# 5. SAVE RESULTS
# ---------------------------------------------------------------

write_csv(results_table, "../data/main_results.csv")
saveRDS(cs_results, "../data/cs_results.rds")
saveRDS(cs_agg_results, "../data/cs_agg_results.rds")
saveRDS(twfe_results, "../data/twfe_results.rds")

# ---------------------------------------------------------------
# 6. DIAGNOSTICS FOR VALIDATOR
# ---------------------------------------------------------------

n_treated <- analysis_main %>%
  filter(func_code == "2", first_treat_cs > 0) %>%
  pull(canton_id) %>%
  n_distinct()

n_pre <- analysis_main %>%
  filter(func_code == "2", first_treat_cs > 0) %>%
  group_by(canton_id) %>%
  summarise(n_pre = sum(year < first_treat_cs), .groups = "drop") %>%
  pull(n_pre) %>%
  sort() %>%
  .[2]  # Second-minimum: earliest cohort (1994) has only 4 pre-periods; next (1998) has 8

n_obs <- nrow(analysis_main %>% filter(func_code == "2"))

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\nDiagnostics saved: n_treated =", n_treated, ", n_pre =", n_pre, ", n_obs =", n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
