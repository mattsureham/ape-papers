## 04_robustness.R — Robustness checks
## apep_1165: Swiss Municipal Mergers and Functional Spending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>% distinct(bfs_nr, year, function_name, .keep_all = TRUE)

cs_results <- readRDS(file.path(data_dir, "cs_results.rds"))

# ==============================================================================
# ROBUSTNESS 1: Alternative estimator — Sun & Abraham (2021)
# ==============================================================================
cat("=== Sun & Abraham (2021) via fixest ===\n")

sa_results <- list()
for (func in unique(panel$function_name)) {
  df_func <- panel %>%
    filter(function_name == func, !is.na(value)) %>%
    mutate(
      # sunab requires: cohort variable (first_treat), period variable (year)
      # Never-treated coded as a large number outside the data range
      cohort = ifelse(first_treat == 0, 10000, first_treat)
    )

  sa <- tryCatch({
    fixest::feols(
      value ~ sunab(cohort, year) | bfs_nr + year,
      data = df_func,
      cluster = ~bfs_nr
    )
  }, error = function(e) {
    cat("  SA error for", func, ":", e$message, "\n")
    NULL
  })

  if (!is.null(sa)) {
    agg <- summary(sa, agg = "att")
    sa_att <- coef(agg)
    sa_se <- sqrt(diag(vcov(agg)))
    cat(func, ": SA ATT =", round(sa_att, 2), " SE =", round(sa_se, 2), "\n")
    sa_results[[func]] <- sa
  }
}

# ==============================================================================
# ROBUSTNESS 2: Leave-one-cohort-out
# ==============================================================================
cat("\n=== Leave-one-cohort-out (administration) ===\n")

cohorts <- unique(panel$first_treat[panel$first_treat > 0])
loco_results <- list()

for (excl_cohort in cohorts) {
  df_excl <- panel %>%
    filter(function_name == "administration",
           !is.na(value),
           first_treat != excl_cohort)

  cs_excl <- tryCatch({
    did::att_gt(
      yname = "value", tname = "year", idname = "bfs_nr",
      gname = "first_treat", data = df_excl,
      control_group = "nevertreated",
      allow_unbalanced_panel = TRUE,
      base_period = "varying"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_excl)) {
    simple_excl <- did::aggte(cs_excl, type = "simple")
    loco_results[[as.character(excl_cohort)]] <- data.frame(
      excluded_cohort = excl_cohort,
      att = simple_excl$overall.att,
      se = simple_excl$overall.se,
      n_treated = n_distinct(df_excl$bfs_nr[df_excl$first_treat > 0])
    )
    cat("Excl cohort", excl_cohort, ": ATT =", round(simple_excl$overall.att, 2),
        " SE =", round(simple_excl$overall.se, 2),
        " (", n_distinct(df_excl$bfs_nr[df_excl$first_treat > 0]), "treated)\n")
  }
}

loco_df <- bind_rows(loco_results)

# ==============================================================================
# ROBUSTNESS 3: Placebo — finance_taxes (formula-driven transfers)
# ==============================================================================
cat("\n=== Placebo: Finance & Taxes (formula-driven) ===\n")

# Finance/taxes spending includes fiscal equalization transfers which are
# formula-based and should NOT respond to mergers
finance_cs <- cs_results[["finance_taxes"]]
if (!is.null(finance_cs)) {
  cat("Finance/taxes ATT:", round(finance_cs$simple$overall.att, 2),
      " SE:", round(finance_cs$simple$overall.se, 2),
      " p:", round(2 * pnorm(-abs(finance_cs$simple$overall.att / finance_cs$simple$overall.se)), 4), "\n")
  cat("  -> Good placebo: no significant effect expected\n")
}

# ==============================================================================
# ROBUSTNESS 4: TWFE with restricted sample (post-2005 only)
# ==============================================================================
cat("\n=== TWFE restricted sample (2005-2024) ===\n")

df_recent <- panel %>%
  filter(function_name == "administration", !is.na(value), year >= 2005)

twfe_recent <- fixest::feols(
  value ~ post | bfs_nr + year,
  data = df_recent,
  cluster = ~bfs_nr
)

cat("TWFE 2005+: coef =", round(coef(twfe_recent)["post"], 2),
    " SE =", round(sqrt(vcov(twfe_recent)["post", "post"]), 2), "\n")

# ==============================================================================
# ROBUSTNESS 5: Heterogeneity by merger size
# ==============================================================================
cat("\n=== Heterogeneity by merger size ===\n")

merger_events <- readRDS(file.path(data_dir, "merger_events.rds"))

# Small mergers: 2 dissolved municipalities
# Large mergers: 3+ dissolved municipalities
small_mergers <- merger_events %>% filter(n_dissolved == 2) %>% pull(successor_bfs)
large_mergers <- merger_events %>% filter(n_dissolved >= 3) %>% pull(successor_bfs)

for (label in c("small (2 munis)", "large (3+ munis)")) {
  subset_bfs <- if (grepl("small", label)) small_mergers else large_mergers

  df_het <- panel %>%
    filter(function_name == "administration", !is.na(value)) %>%
    filter(first_treat == 0 | bfs_nr %in% subset_bfs)

  n_treated <- n_distinct(df_het$bfs_nr[df_het$first_treat > 0])
  if (n_treated < 2) {
    cat(label, ": Too few treated (", n_treated, "), skipping\n")
    next
  }

  cs_het <- tryCatch({
    did::att_gt(
      yname = "value", tname = "year", idname = "bfs_nr",
      gname = "first_treat", data = df_het,
      control_group = "nevertreated",
      allow_unbalanced_panel = TRUE,
      base_period = "varying"
    )
  }, error = function(e) { cat("  Error:", e$message, "\n"); NULL })

  if (!is.null(cs_het)) {
    simple_het <- did::aggte(cs_het, type = "simple")
    cat(label, ": ATT =", round(simple_het$overall.att, 2),
        " SE =", round(simple_het$overall.se, 2), "\n")
  }
}

# ==============================================================================
# Save robustness results
# ==============================================================================

saveRDS(sa_results, file.path(data_dir, "sa_results.rds"))
saveRDS(loco_df, file.path(data_dir, "loco_results.rds"))

cat("\n=== Robustness checks complete ===\n")
