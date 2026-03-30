## 03_main_analysis.R — Main DiD estimation
## APEP-1123: The Registration Effect

source("00_packages.R")

cat("=== Main Analysis ===\n")

df <- read_csv("data/trials_analysis.csv", show_col_types = FALSE)
df_comp <- read_csv("data/trials_completed.csv", show_col_types = FALSE)

cat(sprintf("Full analysis sample: %d\n", nrow(df)))
cat(sprintf("Completed trials sample: %d\n", nrow(df_comp)))

# ============================================================
# 1. RESULTS REPORTING RATE (completed trials only)
# ============================================================
cat("\n--- Results Reporting Rate ---\n")

# Basic DiD
m1_base <- feols(has_results_posted ~ treat_post + treated + post,
                 data = df_comp)

# With year FE
m1_yfe <- feols(has_results_posted ~ treat_post + treated | start_year,
                data = df_comp)

# With controls
m1_ctrl <- feols(has_results_posted ~ treat_post + treated + is_industry +
                   log_enrollment | start_year,
                 data = df_comp,
                 cluster = ~start_year)

# Fully saturated: year FE + sponsor type + purpose
m1_full <- feols(has_results_posted ~ treat_post + treated + is_industry +
                   log_enrollment | start_year + primary_purpose,
                 data = df_comp,
                 cluster = ~start_year)

cat("Results reporting DiD coefficients:\n")
cat(sprintf("  Basic:     %.4f (SE: %.4f)\n", coef(m1_base)["treat_post"], se(m1_base)["treat_post"]))
cat(sprintf("  Year FE:   %.4f (SE: %.4f)\n", coef(m1_yfe)["treat_post"], se(m1_yfe)["treat_post"]))
cat(sprintf("  Controls:  %.4f (SE: %.4f)\n", coef(m1_ctrl)["treat_post"], se(m1_ctrl)["treat_post"]))
cat(sprintf("  Full:      %.4f (SE: %.4f)\n", coef(m1_full)["treat_post"], se(m1_full)["treat_post"]))

# ============================================================
# 2. NUMBER OF PRIMARY OUTCOMES (all trials)
# ============================================================
cat("\n--- Primary Outcome Count ---\n")

m2_base <- feols(n_primary ~ treat_post + treated | start_year,
                 data = df)

m2_ctrl <- feols(n_primary ~ treat_post + treated + is_industry +
                   log_enrollment | start_year,
                 data = df,
                 cluster = ~start_year)

m2_full <- feols(n_primary ~ treat_post + treated + is_industry +
                   log_enrollment | start_year + primary_purpose,
                 data = df,
                 cluster = ~start_year)

cat(sprintf("  Year FE:   %.4f (SE: %.4f)\n", coef(m2_base)["treat_post"], se(m2_base)["treat_post"]))
cat(sprintf("  Controls:  %.4f (SE: %.4f)\n", coef(m2_ctrl)["treat_post"], se(m2_ctrl)["treat_post"]))
cat(sprintf("  Full:      %.4f (SE: %.4f)\n", coef(m2_full)["treat_post"], se(m2_full)["treat_post"]))

# ============================================================
# 3. EVENT STUDY (pre-trend check)
# ============================================================
cat("\n--- Event Study ---\n")

# Create year-relative-to-2008 interactions
df_comp <- df_comp |>
  mutate(
    event_year = start_year,
    year_x_treat = interaction(start_year, treated, drop = TRUE)
  )

# Event study: year × treated interactions
m_event <- feols(has_results_posted ~ i(start_year, treated, ref = 2007) |
                   start_year + treated,
                 data = df_comp,
                 cluster = ~start_year)

cat("Event study coefficients:\n")
print(summary(m_event))

# ============================================================
# 4. HETEROGENEITY BY SPONSOR TYPE
# ============================================================
cat("\n--- Heterogeneity: Industry vs Non-Industry ---\n")

# Industry subsample
m_industry <- feols(has_results_posted ~ treat_post + treated +
                      log_enrollment | start_year,
                    data = df_comp |> filter(is_industry == 1),
                    cluster = ~start_year)

# Non-industry subsample
m_nonindustry <- feols(has_results_posted ~ treat_post + treated +
                         log_enrollment | start_year,
                       data = df_comp |> filter(is_industry == 0),
                       cluster = ~start_year)

cat(sprintf("  Industry:     %.4f (SE: %.4f, N=%d)\n",
            coef(m_industry)["treat_post"], se(m_industry)["treat_post"],
            nrow(df_comp |> filter(is_industry == 1))))
cat(sprintf("  Non-industry: %.4f (SE: %.4f, N=%d)\n",
            coef(m_nonindustry)["treat_post"], se(m_nonindustry)["treat_post"],
            nrow(df_comp |> filter(is_industry == 0))))

# ============================================================
# 5. US vs NON-US
# ============================================================
cat("\n--- Heterogeneity: US vs Non-US ---\n")

m_us <- feols(has_results_posted ~ treat_post + treated +
                is_industry + log_enrollment | start_year,
              data = df_comp |> filter(has_us_site == TRUE),
              cluster = ~start_year)

m_nonus <- feols(has_results_posted ~ treat_post + treated +
                   is_industry + log_enrollment | start_year,
                 data = df_comp |> filter(has_us_site == FALSE),
                 cluster = ~start_year)

cat(sprintf("  US sites:     %.4f (SE: %.4f, N=%d)\n",
            coef(m_us)["treat_post"], se(m_us)["treat_post"],
            nrow(df_comp |> filter(has_us_site == TRUE))))
cat(sprintf("  Non-US only:  %.4f (SE: %.4f, N=%d)\n",
            coef(m_nonus)["treat_post"], se(m_nonus)["treat_post"],
            nrow(df_comp |> filter(has_us_site == FALSE))))

# ============================================================
# SAVE RESULTS
# ============================================================

# Save key models for table generation
save(m1_base, m1_yfe, m1_ctrl, m1_full,
     m2_base, m2_ctrl, m2_full,
     m_event,
     m_industry, m_nonindustry,
     m_us, m_nonus,
     file = "data/main_models.RData")

# Diagnostics for validator
diag <- list(
  n_treated = sum(df$treated == 1),
  n_control = sum(df$treated == 0),
  n_pre = length(unique(df$start_year[df$post == 0])),
  n_post = length(unique(df$start_year[df$post == 1])),
  n_obs = nrow(df),
  n_completed = nrow(df_comp)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: %d treated, %d control, %d pre-periods, %d obs\n",
            diag$n_treated, diag$n_control, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
