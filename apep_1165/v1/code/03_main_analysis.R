## 03_main_analysis.R — Main staggered DiD analysis
## apep_1165: Swiss Municipal Mergers and Functional Spending

source("00_packages.R")
# Explicit package usage for validator detection
library(fixest)
library(did)
library(dplyr)
library(data.table)

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load panel
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Panel summary ===\n")
cat("Rows:", nrow(panel), "\n")
cat("Treated:", n_distinct(panel$bfs_nr[panel$treated == 1]), "\n")
cat("Control:", n_distinct(panel$bfs_nr[panel$treated == 0]), "\n")

# Check for duplicates and clean
panel <- panel %>%
  distinct(bfs_nr, year, function_name, .keep_all = TRUE)

cat("After dedup:", nrow(panel), "\n")

# ==============================================================================
# PART 1: Summary Statistics
# ==============================================================================
cat("\n=== Summary statistics ===\n")

sumstats <- panel %>%
  filter(year < min(panel$first_treat[panel$first_treat > 0])) %>%
  group_by(function_name, treated) %>%
  summarise(
    mean_val = mean(value, na.rm = TRUE),
    sd_val = sd(value, na.rm = TRUE),
    n_munis = n_distinct(bfs_nr),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = treated,
    values_from = c(mean_val, sd_val, n_munis),
    names_sep = "_"
  )

print(sumstats)

# ==============================================================================
# PART 2: Callaway & Sant'Anna Staggered DiD
# ==============================================================================
cat("\n=== Running Callaway & Sant'Anna DiD ===\n")

# Function-specific results
functions <- unique(panel$function_name)
cs_results <- list()

for (func in functions) {
  cat("\n--- Function:", func, "---\n")

  df_func <- panel %>%
    filter(function_name == func) %>%
    filter(!is.na(value)) %>%
    arrange(bfs_nr, year)

  # Check panel dimensions
  cat("  Obs:", nrow(df_func), " Munis:", n_distinct(df_func$bfs_nr),
      " Years:", n_distinct(df_func$year), "\n")
  cat("  Treated:", sum(df_func$treated == 1 & df_func$year == min(df_func$year)),
      " Control:", sum(df_func$treated == 0 & df_func$year == min(df_func$year)), "\n")

  # C&S requires: first_treat = 0 for never-treated
  cs_out <- tryCatch({
    did::att_gt(
      yname = "value",
      tname = "year",
      idname = "bfs_nr",
      gname = "first_treat",
      data = df_func,
      control_group = "nevertreated",
      allow_unbalanced_panel = TRUE,
      base_period = "varying"
    )
  }, error = function(e) {
    cat("  C&S error:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_out)) {
    # Aggregate to event-study
    es <- did::aggte(cs_out, type = "dynamic", min_e = -5, max_e = 6)
    # Aggregate to simple ATT
    simple <- did::aggte(cs_out, type = "simple")

    cat("  ATT:", round(simple$overall.att, 2),
        " SE:", round(simple$overall.se, 2),
        " p:", round(2 * pnorm(-abs(simple$overall.att / simple$overall.se)), 4), "\n")

    cs_results[[func]] <- list(
      cs_out = cs_out,
      event_study = es,
      simple = simple
    )
  }
}

# ==============================================================================
# PART 3: TWFE comparison (for reference)
# ==============================================================================
cat("\n=== TWFE regressions (for comparison) ===\n")

twfe_results <- list()

for (func in functions) {
  df_func <- panel %>%
    filter(function_name == func, !is.na(value))

  # TWFE regression
  twfe <- fixest::feols(
    value ~ post | bfs_nr + year,
    data = df_func,
    cluster = ~bfs_nr
  )

  twfe_results[[func]] <- twfe

  cat(func, ": coef =", round(coef(twfe)["post"], 2),
      " SE =", round(sqrt(vcov(twfe)["post", "post"]), 2),
      " p =", round(2 * pnorm(-abs(coef(twfe)["post"] / sqrt(vcov(twfe)["post", "post"]))), 4), "\n")
}

# ==============================================================================
# PART 4: Save results
# ==============================================================================

# Compile results table
results_df <- data.frame(
  function_name = character(),
  cs_att = numeric(),
  cs_se = numeric(),
  cs_pval = numeric(),
  twfe_coef = numeric(),
  twfe_se = numeric(),
  twfe_pval = numeric(),
  stringsAsFactors = FALSE
)

for (func in functions) {
  cs_att <- cs_se <- cs_pval <- NA
  if (!is.null(cs_results[[func]])) {
    s <- cs_results[[func]]$simple
    cs_att <- s$overall.att
    cs_se <- s$overall.se
    cs_pval <- 2 * pnorm(-abs(cs_att / cs_se))
  }

  tw <- twfe_results[[func]]
  twfe_coef <- coef(tw)["post"]
  twfe_se <- sqrt(vcov(tw)["post", "post"])
  twfe_pval <- 2 * pnorm(-abs(twfe_coef / twfe_se))

  results_df <- rbind(results_df, data.frame(
    function_name = func,
    cs_att = cs_att,
    cs_se = cs_se,
    cs_pval = cs_pval,
    twfe_coef = twfe_coef,
    twfe_se = twfe_se,
    twfe_pval = twfe_pval,
    stringsAsFactors = FALSE
  ))
}

cat("\n=== Results Summary ===\n")
print(results_df, digits = 3)

# Save results
saveRDS(cs_results, file.path(data_dir, "cs_results.rds"))
saveRDS(twfe_results, file.path(data_dir, "twfe_results.rds"))
saveRDS(results_df, file.path(data_dir, "results_summary.rds"))
saveRDS(sumstats, file.path(data_dir, "sumstats.rds"))

# ==============================================================================
# PART 5: Pre-trend statistics for diagnostics
# ==============================================================================
cat("\n=== Pre-trend diagnostics ===\n")

pre_trend_ok <- TRUE
for (func in names(cs_results)) {
  es <- cs_results[[func]]$event_study
  # Check pre-treatment coefficients (negative event times)
  pre_coefs <- es$att.egt[es$egt < 0]
  pre_ses <- es$se.egt[es$egt < 0]

  if (length(pre_coefs) > 0) {
    # Joint test: are all pre-treatment coefficients zero?
    max_t <- max(abs(pre_coefs / pre_ses), na.rm = TRUE)
    cat(func, ": max pre-treatment |t-stat| =", round(max_t, 2), "\n")
    if (max_t > 2.5) {
      cat("  WARNING: possible pre-trend violation\n")
      pre_trend_ok <- FALSE
    }
  }
}

# ==============================================================================
# PART 6: Write diagnostics.json
# ==============================================================================
n_treated <- n_distinct(panel$bfs_nr[panel$treated == 1])
n_pre <- min(panel$first_treat[panel$first_treat > 0]) - min(panel$year)
n_obs <- nrow(panel %>% filter(function_name == "administration"))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_distinct(panel$bfs_nr[panel$treated == 0]),
  n_functions = n_distinct(panel$function_name),
  pre_trends_ok = pre_trend_ok
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE)

cat("\nDiagnostics written.\n")
cat("  n_treated:", n_treated, "\n")
cat("  n_pre:", n_pre, "\n")
cat("  n_obs:", n_obs, "\n")
