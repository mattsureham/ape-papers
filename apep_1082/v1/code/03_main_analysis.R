##############################################################################
# 03_main_analysis.R — Primary DiD regressions
# APEP-1082: The Lottery Channel
##############################################################################

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# Load data
# ===========================================================================

cy <- read_csv(file.path(data_dir, "country_year_panel.csv"),
               show_col_types = FALSE)

# Load recent arrivals if available
recent_file <- file.path(data_dir, "recent_arrivals_panel.csv")
has_recent <- file.exists(recent_file)
if (has_recent) {
  recent <- read_csv(recent_file, show_col_types = FALSE)
}

cat(sprintf("Analysis data: %d country-year cells\n", nrow(cy)))
cat(sprintf("Countries: %d (%d treated, %d control)\n",
            n_distinct(cy$country),
            n_distinct(cy$country[cy$treated_country == 1]),
            n_distinct(cy$country[cy$treated_country == 0])))

# ===========================================================================
# Table 1: Descriptive statistics (pre-treatment means)
# ===========================================================================

cat("\n=== Pre-treatment descriptive statistics ===\n")

# Define pre-period for each country
desc_pre <- cy %>%
  filter(post == 0) %>%
  group_by(treated_country) %>%
  summarise(
    mean_college = weighted.mean(pct_college, w = total_weight, na.rm = TRUE),
    sd_college = sqrt(weighted.mean((pct_college - weighted.mean(pct_college, w = total_weight, na.rm = TRUE))^2,
                                     w = total_weight, na.rm = TRUE)),
    mean_grad = weighted.mean(pct_grad, w = total_weight, na.rm = TRUE),
    mean_ln_wage = weighted.mean(mean_ln_wage, w = total_weight, na.rm = TRUE),
    mean_age = weighted.mean(mean_age, w = total_weight, na.rm = TRUE),
    mean_female = weighted.mean(pct_female, w = total_weight, na.rm = TRUE),
    n_countries = n_distinct(country),
    n_cy = n(),
    .groups = "drop"
  )

print(desc_pre)

# ===========================================================================
# Main specification: TWFE DiD
# ===========================================================================

cat("\n=== Main DiD regressions ===\n")

# Specification 1: College share (all immigrants)
m1 <- feols(pct_college ~ post | country + survey_year,
            data = cy, weights = ~total_weight,
            cluster = ~country)

# Specification 2: Graduate degree share
m2 <- feols(pct_grad ~ post | country + survey_year,
            data = cy, weights = ~total_weight,
            cluster = ~country)

# Specification 3: Log wages
m3 <- feols(mean_ln_wage ~ post | country + survey_year,
            data = cy, weights = ~total_weight,
            cluster = ~country)

cat("\n--- All immigrants ---\n")
cat("College share:\n"); print(summary(m1))
cat("\nGrad degree share:\n"); print(summary(m2))
cat("\nLog wages:\n"); print(summary(m3))

# ===========================================================================
# Recent arrivals (flow margin — key specification)
# ===========================================================================

if (has_recent) {
  cat("\n=== Recent arrivals (entered within 5 years) ===\n")

  # Filter to cells with at least 20 observations for stability
  recent_filt <- recent %>% filter(n_obs >= 20)

  cat(sprintf("Recent arrivals: %d cells (after n>=20 filter)\n", nrow(recent_filt)))

  m4 <- feols(pct_college ~ post | country + survey_year,
              data = recent_filt, weights = ~total_weight,
              cluster = ~country)

  m5 <- feols(pct_grad ~ post | country + survey_year,
              data = recent_filt, weights = ~total_weight,
              cluster = ~country)

  m6 <- feols(mean_ln_wage ~ post | country + survey_year,
              data = recent_filt, weights = ~total_weight,
              cluster = ~country)

  cat("\n--- Recent arrivals ---\n")
  cat("College share:\n"); print(summary(m4))
  cat("\nGrad degree share:\n"); print(summary(m5))
  cat("\nLog wages:\n"); print(summary(m6))
}

# ===========================================================================
# Callaway-Sant'Anna (staggered DiD)
# ===========================================================================

cat("\n=== Callaway-Sant'Anna staggered DiD ===\n")

# Prepare data for CS: need numeric id, time, group (first_treat)
cs_data <- cy %>%
  mutate(
    id = as.numeric(factor(country)),
    time = as.numeric(survey_year)
  )

# CS requires first_treat as integer (0 = never-treated)
cs_out <- tryCatch({
  att_gt(
    yname = "pct_college",
    tname = "time",
    idname = "id",
    gname = "first_treat",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    weightsname = "total_weight",
    bstrap = TRUE,
    biters = 1000,
    clustervars = "id"
  )
}, error = function(e) {
  cat(sprintf("CS estimation error: %s\n", e$message))
  NULL
})

if (!is.null(cs_out)) {
  cat("\nCS ATT(g,t) results:\n")
  print(summary(cs_out))

  # Aggregate to event study
  cs_es <- aggte(cs_out, type = "dynamic")
  cat("\nCS event study:\n")
  print(summary(cs_es))

  # Overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS overall ATT:\n")
  print(summary(cs_agg))

  # Save CS results
  cs_es_df <- data.frame(
    event_time = cs_es$egt,
    att = cs_es$att.egt,
    se = cs_es$se.egt,
    ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
    ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
  )
  write_csv(cs_es_df, file.path(data_dir, "cs_event_study.csv"))
}

# ===========================================================================
# Save diagnostics
# ===========================================================================

n_treated_countries <- n_distinct(cy$country[cy$treated_country == 1])
n_pre <- cy %>%
  filter(treated_country == 1, post == 0) %>%
  pull(survey_year) %>% unique() %>% length()

diag <- list(
  n_treated = n_treated_countries,
  n_pre = n_pre,
  n_obs = nrow(cy),
  n_countries = n_distinct(cy$country),
  n_years = n_distinct(cy$survey_year),
  sd_y_pre = desc_pre$sd_college[desc_pre$treated_country == 0]
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

# ===========================================================================
# Save regression objects
# ===========================================================================

save(m1, m2, m3, file = file.path(data_dir, "main_models.RData"))
if (has_recent) {
  save(m4, m5, m6, file = file.path(data_dir, "recent_models.RData"))
}
if (!is.null(cs_out)) {
  save(cs_out, cs_es, cs_agg, file = file.path(data_dir, "cs_models.RData"))
}

cat("\n=== Main analysis complete ===\n")
