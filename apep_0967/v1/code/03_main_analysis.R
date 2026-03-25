# 03_main_analysis.R — Main DiD estimation
# apep_0967: CSE Reform and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data"
panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)

cat("Panel dimensions:", nrow(panel), "obs x", ncol(panel), "vars\n")
cat("N communes:", n_distinct(panel$code_commune), "\n")
cat("N départements:", n_distinct(panel$dep_code), "\n")

# ============================================================================
# MAIN SPECIFICATION: Continuous treatment intensity DiD
# ============================================================================
# Y_{ct} = α_c + δ_t + β(share_50plus_c × post_t) + ε_{ct}
# β: effect of 1pp increase in share of 50+ employee establishments
# on Le Pen vote share, comparing pre (2012/2017) to post (2022)

# Replace NA share_50plus with 0 (communes not in Sirene = no establishments)
panel <- panel |>
  mutate(
    share_50plus = replace_na(share_50plus, 0),
    share_50_99 = replace_na(share_50_99, 0),
    n_50plus = replace_na(n_50plus, 0),
    # Create interaction
    treat_post = share_50plus * post,
    # Binary treatment: any 50+ firm
    any_50plus = as.integer(n_50plus > 0),
    any_50plus_post = any_50plus * post,
    # Tercile treatment (among communes with positive treatment)
    treat_tercile = case_when(
      share_50plus == 0 ~ 0L,
      share_50plus <= quantile(share_50plus[share_50plus > 0], 1/3) ~ 1L,
      share_50plus <= quantile(share_50plus[share_50plus > 0], 2/3) ~ 2L,
      TRUE ~ 3L
    )
  )

# Rescale share_50plus to percentage points for readability
panel <- panel |>
  mutate(
    share_50plus_pct = share_50plus * 100,
    treat_post_pct = share_50plus_pct * post
  )

cat("\n=== MAIN RESULTS ===\n")

# Model 1: Basic DiD (commune + year FE)
m1 <- feols(lepen_share ~ treat_post_pct | code_commune + year,
            data = panel, cluster = ~dep_code)
cat("\nModel 1: Basic DiD\n")
summary(m1)

# Model 2: Add population control (inscrits as proxy)
m2 <- feols(lepen_share ~ treat_post_pct + log(inscrits) | code_commune + year,
            data = panel, cluster = ~dep_code)
cat("\nModel 2: With population control\n")
summary(m2)

# Model 3: Binary treatment (any 50+ firm)
m3 <- feols(lepen_share ~ any_50plus_post | code_commune + year,
            data = panel, cluster = ~dep_code)
cat("\nModel 3: Binary treatment\n")
summary(m3)

# Model 4: 50-99 employee bracket only (most affected)
panel <- panel |>
  mutate(
    share_50_99_pct = share_50_99 * 100,
    treat_50_99_post = share_50_99_pct * post
  )
m4 <- feols(lepen_share ~ treat_50_99_post | code_commune + year,
            data = panel, cluster = ~dep_code)
cat("\nModel 4: 50-99 bracket only\n")
summary(m4)

# Model 5: Tercile dummies
panel <- panel |>
  mutate(
    terc1_post = as.integer(treat_tercile == 1) * post,
    terc2_post = as.integer(treat_tercile == 2) * post,
    terc3_post = as.integer(treat_tercile == 3) * post
  )
m5 <- feols(lepen_share ~ terc1_post + terc2_post + terc3_post |
              code_commune + year,
            data = panel, cluster = ~dep_code)
cat("\nModel 5: Tercile dummies\n")
summary(m5)

# ============================================================================
# EVENT STUDY: Separate coefficients for each year
# ============================================================================
cat("\n=== EVENT STUDY ===\n")

# Make 2017 the reference year (last pre-period)
panel <- panel |>
  mutate(
    year_fac = factor(year),
    interact_2012 = share_50plus_pct * as.integer(year == 2012),
    interact_2022 = share_50plus_pct * as.integer(year == 2022)
  )

m_es <- feols(lepen_share ~ interact_2012 + interact_2022 |
                code_commune + year,
              data = panel, cluster = ~dep_code)
cat("\nEvent study (ref = 2017):\n")
summary(m_es)

# ============================================================================
# PLACEBO OUTCOMES
# ============================================================================
cat("\n=== PLACEBO OUTCOMES ===\n")

# Mélenchon vote share (far-left) — should not be affected similarly
m_melenchon <- feols(melenchon_share ~ treat_post_pct | code_commune + year,
                     data = panel |> filter(!is.na(melenchon_share)),
                     cluster = ~dep_code)
cat("\nPlacebo: Mélenchon vote share\n")
summary(m_melenchon)

# Turnout
m_turnout <- feols(turnout ~ treat_post_pct | code_commune + year,
                   data = panel, cluster = ~dep_code)
cat("\nPlacebo: Turnout\n")
summary(m_turnout)

# ============================================================================
# SAVE RESULTS FOR TABLES
# ============================================================================

# Save key model objects
save(m1, m2, m3, m4, m5, m_es, m_melenchon, m_turnout, panel,
     file = file.path(data_dir, "main_results.RData"))

# Write diagnostics.json
n_treated <- n_distinct(panel$code_commune[panel$any_50plus == 1])
n_pre <- length(unique(panel$year[panel$year < 2022]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_communes = n_distinct(panel$code_commune),
  n_dep = n_distinct(panel$dep_code),
  main_coef = coef(m1)["treat_post_pct"],
  main_se = se(m1)["treat_post_pct"]
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved. n_treated =", n_treated, "n_pre =", n_pre,
    "n_obs =", n_obs, "\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
