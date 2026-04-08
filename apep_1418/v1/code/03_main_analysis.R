## 03_main_analysis.R — IV estimates of state disinvestment effects
source("00_packages.R")

cat("=== Main Analysis ===\n")
df <- readRDS("../data/analysis_panel.rds")

cat(sprintf("Panel: %d obs, %d institutions, %d states, years %d-%d\n",
            nrow(df), n_distinct(df$unitid), n_distinct(df$state),
            min(df$year), max(df$year)))

# ---------------------------------------------------------------
# 1. First Stage: Bartik shock → state appropriations per FTE
# ---------------------------------------------------------------
cat("\n--- First Stage ---\n")

# OLS reduced form: Bartik → appropriations
fs_ols <- feols(approp_per_fte ~ bartik_unemp | unitid + year,
                data = df, cluster = ~state)
cat("First stage (Bartik unemployment):\n")
summary(fs_ols)

# F-statistic for instrument strength
fs_fstat <- fitstat(fs_ols, "ivf")
cat(sprintf("\nFirst-stage coefficient: %.2f (SE: %.2f)\n",
            coef(fs_ols)["bartik_unemp"], se(fs_ols)["bartik_unemp"]))

# Alternative: state unemployment × initial share
fs_alt <- feols(approp_per_fte ~ I(state_unemp * he_share_init) | unitid + year,
                data = df, cluster = ~state)
cat("\nAlternative first stage (state unemp × initial share):\n")
summary(fs_alt)

# ---------------------------------------------------------------
# 2. IV: State appropriations → Tuition (passthrough rate)
# ---------------------------------------------------------------
cat("\n--- IV: Appropriations → Tuition ---\n")

# 2SLS: tuition = f(appropriations per FTE, instrumented by Bartik)
iv_tuition <- feols(tuition_in_state ~ 1 | unitid + year |
                      approp_per_fte ~ bartik_unemp,
                    data = df, cluster = ~state)
cat("IV: Appropriations → In-state tuition:\n")
summary(iv_tuition)

# OLS comparison
ols_tuition <- feols(tuition_in_state ~ approp_per_fte | unitid + year,
                     data = df, cluster = ~state)
cat("\nOLS comparison:\n")
summary(ols_tuition)

# ---------------------------------------------------------------
# 3. IV: State appropriations → Pell share (composition)
# ---------------------------------------------------------------
cat("\n--- IV: Appropriations → Pell Share ---\n")

# Restrict to observations with non-missing Pell data
df_pell <- df |> filter(!is.na(pell_share))
cat(sprintf("Pell sample: %d obs (%d institutions)\n",
            nrow(df_pell), n_distinct(df_pell$unitid)))

iv_pell <- feols(pell_share ~ 1 | unitid + year |
                   approp_per_fte ~ bartik_unemp,
                 data = df_pell, cluster = ~state)
cat("IV: Appropriations → Pell share:\n")
summary(iv_pell)

ols_pell <- feols(pell_share ~ approp_per_fte | unitid + year,
                  data = df_pell, cluster = ~state)

# ---------------------------------------------------------------
# 4. IV: State appropriations → Minority enrollment share
# ---------------------------------------------------------------
cat("\n--- IV: Appropriations → Minority Share ---\n")

df_race <- df |> filter(!is.na(minority_share))

iv_minority <- feols(minority_share ~ 1 | unitid + year |
                       approp_per_fte ~ bartik_unemp,
                     data = df_race, cluster = ~state)
cat("IV: Appropriations → Minority share:\n")
summary(iv_minority)

ols_minority <- feols(minority_share ~ approp_per_fte | unitid + year,
                      data = df_race, cluster = ~state)

# Black share separately
iv_black <- feols(black_share ~ 1 | unitid + year |
                    approp_per_fte ~ bartik_unemp,
                  data = df_race, cluster = ~state)

# Hispanic share separately
iv_hispanic <- feols(hispanic_share ~ 1 | unitid + year |
                       approp_per_fte ~ bartik_unemp,
                     data = df_race, cluster = ~state)

# ---------------------------------------------------------------
# 5. IV: State appropriations → Log enrollment
# ---------------------------------------------------------------
cat("\n--- IV: Appropriations → Log Enrollment ---\n")

df_enr <- df |> filter(!is.na(log_enroll))

iv_enroll <- feols(log_enroll ~ 1 | unitid + year |
                     approp_per_fte ~ bartik_unemp,
                   data = df_enr, cluster = ~state)
cat("IV: Appropriations → Log enrollment:\n")
summary(iv_enroll)

ols_enroll <- feols(log_enroll ~ approp_per_fte | unitid + year,
                    data = df_enr, cluster = ~state)

# ---------------------------------------------------------------
# 6. Save results
# ---------------------------------------------------------------
results <- list(
  fs_ols = fs_ols,
  fs_alt = fs_alt,
  iv_tuition = iv_tuition,
  ols_tuition = ols_tuition,
  iv_pell = iv_pell,
  ols_pell = ols_pell,
  iv_minority = iv_minority,
  ols_minority = ols_minority,
  iv_black = iv_black,
  iv_hispanic = iv_hispanic,
  iv_enroll = iv_enroll,
  ols_enroll = ols_enroll
)
saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------
# 7. Diagnostics for validator
# ---------------------------------------------------------------
diag <- list(
  n_treated = n_distinct(df$state),  # All states receive treatment (continuous)
  n_pre = length(unique(df$year[df$year <= 2008])),  # Pre-recession years (2004-2008)
  n_obs = nrow(df)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Analysis complete ===\n")
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
