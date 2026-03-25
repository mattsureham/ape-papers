## 03_main_analysis.R — Main DiD estimation
## apep_0939: Employment Costs of Seismicity Regulation

library(tidyverse)
library(fixest)
library(did)
library(jsonlite)

data_dir <- "data"
if (!dir.exists(data_dir)) data_dir <- "../data"

# ===========================================================================
# 1. Load panels
# ===========================================================================
cat("=== Loading analysis panels ===\n")
panel_total <- read_csv(file.path(data_dir, "panel_total.csv"), show_col_types = FALSE)
panel_213   <- read_csv(file.path(data_dir, "panel_213.csv"), show_col_types = FALSE)
panel_211   <- read_csv(file.path(data_dir, "panel_211.csv"), show_col_types = FALSE)
panel_retail <- read_csv(file.path(data_dir, "panel_retail.csv"), show_col_types = FALSE)
panel_food   <- read_csv(file.path(data_dir, "panel_food.csv"), show_col_types = FALSE)

cat(sprintf("Total panel: %d obs, %d counties\n",
            nrow(panel_total), n_distinct(panel_total$county_fips)))

# ===========================================================================
# 2. TWFE Baseline — fixest
# ===========================================================================
cat("\n=== TWFE Baseline Regressions ===\n")

# Specification: log(emp) ~ post | county + year-quarter FE
# Cluster at county level

# Total employment
twfe_total <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_total,
  cluster = ~county_fips
)
cat("TWFE Total Employment:\n")
print(summary(twfe_total))

# NAICS 213 — Support Activities for Mining
twfe_213 <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_213,
  cluster = ~county_fips
)
cat("\nTWFE NAICS 213 (Mining Support):\n")
print(summary(twfe_213))

# NAICS 211 — Oil and Gas Extraction
twfe_211 <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_211,
  cluster = ~county_fips
)
cat("\nTWFE NAICS 211 (Extraction):\n")
print(summary(twfe_211))

# Retail (placebo)
twfe_retail <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_retail,
  cluster = ~county_fips
)
cat("\nTWFE Retail (Placebo):\n")
print(summary(twfe_retail))

# Food services (placebo)
twfe_food <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_food,
  cluster = ~county_fips
)
cat("\nTWFE Food Services (Placebo):\n")
print(summary(twfe_food))


# ===========================================================================
# 3. Callaway-Sant'Anna DiD — Heterogeneity-Robust
# ===========================================================================
cat("\n=== Callaway-Sant'Anna Estimation ===\n")

# Prepare data for CS-DiD
# Need: outcome, time, id, group (first_treat period, 0 for never-treated)

run_cs_did <- function(panel, outcome_var = "log_emp", label = "") {
  # Remove rows with NA or infinite values
  df <- panel %>%
    filter(is.finite(.data[[outcome_var]])) %>%
    mutate(
      id = county_id,
      time = yq,
      group = first_treat_yq
    )

  n_treated <- n_distinct(df$county_fips[df$group > 0])
  n_control <- n_distinct(df$county_fips[df$group == 0])
  cat(sprintf("\n%s: %d treated counties, %d control counties, %d obs\n",
              label, n_treated, n_control, nrow(df)))

  if (n_treated < 2 || n_control < 2) {
    cat("  Skipping: too few treated or control units\n")
    return(NULL)
  }

  out <- tryCatch(
    att_gt(
      yname = outcome_var,
      tname = "time",
      idname = "id",
      gname = "group",
      data = as.data.frame(df),
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal"
    ),
    error = function(e) {
      cat(sprintf("  CS-DiD error: %s\n", e$message))
      return(NULL)
    }
  )

  if (!is.null(out)) {
    # Overall ATT
    agg_overall <- aggte(out, type = "simple")
    cat(sprintf("  Overall ATT: %.4f (SE: %.4f)\n",
                agg_overall$overall.att, agg_overall$overall.se))

    # Dynamic (event study)
    agg_dynamic <- tryCatch(
      aggte(out, type = "dynamic"),
      error = function(e) {
        cat(sprintf("  Dynamic aggregation error: %s\n", e$message))
        NULL
      }
    )
  }

  return(out)
}

cs_total <- run_cs_did(panel_total, "log_emp", "Total Employment")
cs_213   <- run_cs_did(panel_213, "log_emp", "NAICS 213")
cs_211   <- run_cs_did(panel_211, "log_emp", "NAICS 211")
cs_retail <- run_cs_did(panel_retail, "log_emp", "Retail (Placebo)")
cs_food   <- run_cs_did(panel_food, "log_emp", "Food (Placebo)")


# ===========================================================================
# 4. Event Study — TWFE with leads and lags
# ===========================================================================
cat("\n=== Event Study (TWFE) ===\n")

# Create event time variable
make_event_time <- function(panel) {
  panel %>%
    mutate(
      event_time = if_else(treated_county == 1,
                           yq - first_treat_yq,
                           NA_real_)
    )
}

panel_total_es <- make_event_time(panel_total) %>%
  filter(treated_county == 0 | (event_time >= -12 & event_time <= 16))

# Sun-Abraham event study via fixest
es_total <- feols(
  log_emp ~ sunab(first_treat_yq, yq) | county_fips + yq,
  data = panel_total %>% filter(first_treat_yq > 0 | treated_county == 0),
  cluster = ~county_fips
)
cat("Event study (Sun-Abraham) — Total Employment:\n")
print(summary(es_total))

es_213 <- feols(
  log_emp ~ sunab(first_treat_yq, yq) | county_fips + yq,
  data = panel_213 %>% filter(first_treat_yq > 0 | treated_county == 0),
  cluster = ~county_fips
)
cat("\nEvent study (Sun-Abraham) — NAICS 213:\n")
print(summary(es_213))


# ===========================================================================
# 5. Wages analysis
# ===========================================================================
cat("\n=== Wage Effects ===\n")

panel_total <- panel_total %>%
  mutate(log_wage = log(avg_wkly_wage))

twfe_wage <- feols(
  log_wage ~ post | county_fips + yq,
  data = panel_total %>% filter(is.finite(log_wage)),
  cluster = ~county_fips
)
cat("TWFE Wage Effect (Total):\n")
print(summary(twfe_wage))

if (nrow(panel_213) > 0) {
  panel_213 <- panel_213 %>%
    mutate(log_wage = log(avg_wkly_wage))

  twfe_wage_213 <- feols(
    log_wage ~ post | county_fips + yq,
    data = panel_213 %>% filter(is.finite(log_wage)),
    cluster = ~county_fips
  )
  cat("\nTWFE Wage Effect (NAICS 213):\n")
  print(summary(twfe_wage_213))
}


# ===========================================================================
# 6. Diagnostics — save for validator
# ===========================================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(panel_total$county_fips[panel_total$treated_county == 1]),
  n_pre = length(unique(panel_total$yq[panel_total$yq < min(panel_total$first_treat_yq[panel_total$first_treat_yq > 0])])),
  n_obs = nrow(panel_total),
  n_control = n_distinct(panel_total$county_fips[panel_total$treated_county == 0]),
  n_industries = 5,
  panel_years = paste(range(panel_total$year), collapse = "-")
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Saved diagnostics.json\n")

# Save key results for table generation
results <- list(
  twfe_total = list(
    coef = coef(twfe_total)["post"],
    se = se(twfe_total)["post"],
    pval = pvalue(twfe_total)["post"],
    n = twfe_total$nobs,
    n_clusters = twfe_total$nparams
  ),
  twfe_213 = list(
    coef = coef(twfe_213)["post"],
    se = se(twfe_213)["post"],
    pval = pvalue(twfe_213)["post"],
    n = twfe_213$nobs
  ),
  twfe_211 = list(
    coef = coef(twfe_211)["post"],
    se = se(twfe_211)["post"],
    pval = pvalue(twfe_211)["post"],
    n = twfe_211$nobs
  ),
  twfe_retail = list(
    coef = coef(twfe_retail)["post"],
    se = se(twfe_retail)["post"],
    pval = pvalue(twfe_retail)["post"],
    n = twfe_retail$nobs
  ),
  twfe_food = list(
    coef = coef(twfe_food)["post"],
    se = se(twfe_food)["post"],
    pval = pvalue(twfe_food)["post"],
    n = twfe_food$nobs
  ),
  twfe_wage = list(
    coef = coef(twfe_wage)["post"],
    se = se(twfe_wage)["post"],
    pval = pvalue(twfe_wage)["post"],
    n = twfe_wage$nobs
  )
)

# Add CS-DiD results if available
if (!is.null(cs_total)) {
  agg <- aggte(cs_total, type = "simple")
  results$cs_total <- list(att = agg$overall.att, se = agg$overall.se)
}
if (!is.null(cs_213)) {
  agg <- aggte(cs_213, type = "simple")
  results$cs_213 <- list(att = agg$overall.att, se = agg$overall.se)
}

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("Saved main_results.rds\n")

# Save models for table generation
saveRDS(
  list(
    twfe_total = twfe_total,
    twfe_213 = twfe_213,
    twfe_211 = twfe_211,
    twfe_retail = twfe_retail,
    twfe_food = twfe_food,
    twfe_wage = twfe_wage,
    es_total = es_total,
    es_213 = es_213
  ),
  file.path(data_dir, "models.rds")
)
cat("Saved models.rds\n")

cat("\nMain analysis complete.\n")
