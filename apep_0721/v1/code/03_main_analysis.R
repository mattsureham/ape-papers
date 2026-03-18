## 03_main_analysis.R — Continuous-treatment DiD regressions
## apep_0721: UK NLW Wage Distribution Compression

source("00_packages.R")

cat("=== Loading analysis dataset ===\n")
df <- readRDS("../data/analysis_dataset.rds")

cat(sprintf("Observations: %d, LAs: %d, Years: %d\n",
            nrow(df), n_distinct(df$la_code), n_distinct(df$year)))

# ============================================================================
# MAIN SPECIFICATION: log(percentile) ~ Bite × Post | LA FE + Year FE
# ============================================================================
cat("\n=== Main regressions: Continuous-treatment DiD ===\n")

outcomes <- c("log_p10", "log_p25", "log_p50", "log_p60", "log_p90")
labels <- c("Log p10", "Log p25", "Log p50", "Log p60", "Log p90")

main_results <- list()

for (i in seq_along(outcomes)) {
  yvar <- outcomes[i]
  cat(sprintf("\n--- %s ---\n", labels[i]))

  # Main specification: bite × post with LA and year FE
  fml <- as.formula(paste0(yvar, " ~ bite_post | la_code + year"))
  fit <- feols(fml, data = df, cluster = ~la_code)

  cat(sprintf("  Bite × Post: %.4f (SE: %.4f, p: %.4f)\n",
              coef(fit)["bite_post"], se(fit)["bite_post"], pvalue(fit)["bite_post"]))

  main_results[[yvar]] <- fit
}

saveRDS(main_results, "../data/main_results.rds")

# ============================================================================
# EVENT STUDY: Year-by-year bite × year interactions
# ============================================================================
cat("\n=== Event Study ===\n")

# Create year dummies interacted with bite (omitting 2015 as reference)
df <- df %>%
  mutate(year_factor = factor(year))

es_results <- list()

for (i in seq_along(outcomes)) {
  yvar <- outcomes[i]

  # Event study: bite × year dummies (2015 omitted)
  fml_es <- as.formula(paste0(yvar, " ~ bite:i(year, ref = 2015) | la_code + year"))
  fit_es <- feols(fml_es, data = df, cluster = ~la_code)

  # Extract coefficients
  coefs <- coeftable(fit_es)
  es_coefs <- coefs[grep("bite:", rownames(coefs)), ]

  cat(sprintf("\nEvent study: %s\n", labels[i]))
  print(es_coefs)

  es_results[[yvar]] <- fit_es
}

saveRDS(es_results, "../data/es_results.rds")

# ============================================================================
# PERCENTILE RATIOS: Direct compression measures
# ============================================================================
cat("\n=== Percentile ratio regressions ===\n")

ratio_outcomes <- c("p10_p50", "p25_p50", "p10_p90")
ratio_labels <- c("p10/p50 Ratio", "p25/p50 Ratio", "p10/p90 Ratio")

ratio_results <- list()

for (i in seq_along(ratio_outcomes)) {
  yvar <- ratio_outcomes[i]
  cat(sprintf("\n--- %s ---\n", ratio_labels[i]))

  fml <- as.formula(paste0(yvar, " ~ bite_post | la_code + year"))
  fit <- feols(fml, data = df, cluster = ~la_code)

  cat(sprintf("  Bite × Post: %.4f (SE: %.4f, p: %.4f)\n",
              coef(fit)["bite_post"], se(fit)["bite_post"], pvalue(fit)["bite_post"]))

  ratio_results[[yvar]] <- fit
}

saveRDS(ratio_results, "../data/ratio_results.rds")

# ============================================================================
# Diagnostics JSON
# ============================================================================
n_treated <- n_distinct(df$la_code[df$bite > median(df$bite, na.rm = TRUE)])
n_pre <- sum(unique(df$year) < 2016)
diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(df)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
