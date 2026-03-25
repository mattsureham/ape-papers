## ============================================================================
## 04_robustness.R — Robustness checks for NIBRS measurement artifact
## ============================================================================

paper_dir <- here::here()
if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
setwd(here::here())
source("code/00_packages.R")

load("data/main_results.RData")
panel <- readRDS("data/analysis_panel.rds")

## ---------------------------------------------------------------------------
## 1. TWFE Event Study (fixest) for visual pre-trends
## ---------------------------------------------------------------------------

cat("\n=== TWFE EVENT STUDY ===\n")

# Create event-time dummies for treated states
panel_es <- panel %>%
  filter(!is.na(rel_time_binned)) %>%
  mutate(rel_time_f = factor(rel_time_binned))

# Property crime event study
es_twfe_property <- feols(log_property_rate ~ i(rel_time_f, ref = "-1") |
                            state_id + year,
                          data = panel_es, cluster = ~state_id)
cat("TWFE Event study (property):\n")
print(summary(es_twfe_property))

# Violent crime event study
es_twfe_violent <- feols(log_violent_rate ~ i(rel_time_f, ref = "-1") |
                           state_id + year,
                         data = panel_es, cluster = ~state_id)

# Murder placebo event study
es_twfe_murder <- feols(log_murder_rate ~ i(rel_time_f, ref = "-1") |
                          state_id + year,
                        data = panel_es, cluster = ~state_id)

## ---------------------------------------------------------------------------
## 2. Leave-one-state-out sensitivity
## ---------------------------------------------------------------------------

cat("\n=== LEAVE-ONE-STATE-OUT ===\n")

treated_states <- unique(cs_data$id[cs_data$g > 0])
loo_results <- list()

for (s in treated_states) {
  loo_data <- cs_data %>% filter(id != s)
  loo_cs <- tryCatch(
    att_gt(
      yname = "log_violent_rate",
      tname = "t", idname = "id", gname = "g",
      data = loo_data,
      control_group = "nevertreated",
      base_period = "universal",
      est_method = "reg",
      allow_unbalanced_panel = TRUE,
      bstrap = FALSE, pl = FALSE
    ),
    error = function(e) NULL
  )
  if (!is.null(loo_cs)) {
    loo_agg <- tryCatch(
      aggte(loo_cs, type = "simple", na.rm = TRUE),
      error = function(e) NULL
    )
    if (!is.null(loo_agg)) {
      state_name <- panel$state[panel$state_id == s][1]
      loo_results[[as.character(s)]] <- tibble(
        dropped_state = state_name,
        att = loo_agg$overall.att,
        se = loo_agg$overall.se
      )
    }
  }
}

loo_df <- bind_rows(loo_results)
cat("LOO results (violent crime ATT):\n")
cat("  Full sample ATT:", round(agg_violent$overall.att, 4), "\n")
cat("  LOO range:", round(min(loo_df$att), 4), "to", round(max(loo_df$att), 4), "\n")
cat("  Most influential state:", loo_df$dropped_state[which.max(abs(loo_df$att - agg_violent$overall.att))], "\n")

## ---------------------------------------------------------------------------
## 3. Alternative control group: not-yet-treated
## ---------------------------------------------------------------------------

cat("\n=== NOT-YET-TREATED CONTROL GROUP ===\n")

cs_nyt_violent <- tryCatch(
  att_gt(
    yname = "log_violent_rate",
    tname = "t", idname = "id", gname = "g",
    data = cs_data,
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg",
    allow_unbalanced_panel = TRUE,
    bstrap = TRUE, biters = 1000, pl = FALSE
  ),
  error = function(e) {
    cat("  Not-yet-treated failed:", conditionMessage(e), "\n")
    return(NULL)
  }
)

if (!is.null(cs_nyt_violent)) {
  agg_nyt <- aggte(cs_nyt_violent, type = "simple", na.rm = TRUE)
  cat("ATT (not-yet-treated):", round(agg_nyt$overall.att, 4),
      " SE:", round(agg_nyt$overall.se, 4), "\n")
} else {
  agg_nyt <- list(overall.att = NA, overall.se = NA)
}

## ---------------------------------------------------------------------------
## 4. HonestDiD sensitivity (Rambachan-Roth 2023)
## ---------------------------------------------------------------------------

cat("\n=== HONESTDID SENSITIVITY ===\n")

# Extract event study coefficients for HonestDiD
tryCatch({
  es_obj <- es_violent
  betahat <- es_obj$att.egt
  sigma <- es_obj$se.egt

  # Pre-treatment periods
  pre_idx <- which(es_obj$egt < 0)
  post_idx <- which(es_obj$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Construct V matrix (diagonal of squared SEs)
    V <- diag(sigma^2)

    honest_result <- tryCatch(
      HonestDiD::createSensitivityResults(
        betahat = betahat,
        sigma = V,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mvec = seq(0, 0.05, by = 0.01)
      ),
      error = function(e) {
        cat("  HonestDiD failed:", conditionMessage(e), "\n")
        NULL
      }
    )

    if (!is.null(honest_result)) {
      cat("HonestDiD results (violent crime):\n")
      print(honest_result)
    }
  }
}, error = function(e) cat("  HonestDiD setup error:", conditionMessage(e), "\n"))

## ---------------------------------------------------------------------------
## 5. Save robustness results
## ---------------------------------------------------------------------------

save(es_twfe_property, es_twfe_violent, es_twfe_murder,
     loo_df, agg_nyt,
     file = "data/robustness_results.RData")

cat("\nRobustness results saved.\n")
