# 03_main_analysis.R — Main DiD analysis (state-level)
# apep_1399: The Bedrock Dose

source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "analysis_panel.csv"),
            colClasses = c(state_fips = "character"))

cat("Panel: ", nrow(df), "rows,", length(unique(df$state_fips)), "states,",
    length(unique(df$year)), "years\n")
cat("Treated states:", sum(df$treated_state[df$year == 2010]), "\n")
cat("Post-RRNC obs:", sum(df$post_rrnc), "\n")

# ============================================================================
# 1. Main Specification: TWFE DiD
# ============================================================================
cat("\n=== Main TWFE Specifications ===\n")

# Spec 1: Simple TWFE with state + year FE
m1 <- feols(cancer_aadr ~ post_rrnc | state_fips + year, data = df,
            cluster = ~state_fips)
cat("\nSpec 1: Post-RRNC → Cancer AADR\n")
print(summary(m1))

# Spec 2: Post-RRNC × High GRP interaction (triple-diff)
m2 <- feols(cancer_aadr ~ post_rrnc + treat_x_grp | state_fips + year, data = df,
            cluster = ~state_fips)
cat("\nSpec 2: Post-RRNC + Post-RRNC × High GRP\n")
print(summary(m2))

# Spec 3: Continuous GRP treatment intensity
m3 <- feols(cancer_aadr ~ treat_x_grp_cont | state_fips + year, data = df,
            cluster = ~state_fips)
cat("\nSpec 3: Continuous GRP intensity\n")
print(summary(m3))

# Spec 4: Add population weight
m4 <- feols(cancer_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
            data = df, cluster = ~state_fips, weights = ~population)
cat("\nSpec 4: Population-weighted\n")
print(summary(m4))

# ============================================================================
# 2. Event Study
# ============================================================================
cat("\n=== Event Study ===\n")

df_es <- df[treated_state == 1]
df_es[, event_bin := fcase(
  years_since < -10, "-10+",
  years_since >= -10 & years_since < -5, "[-10,-5)",
  years_since >= -5  & years_since < -1, "[-5,-1)",
  years_since == -1, "-1",
  years_since == 0, "0",
  years_since >= 1 & years_since < 5, "[1,5)",
  years_since >= 5 & years_since < 10, "[5,10)",
  years_since >= 10, "10+"
)]
df_es[, event_bin := factor(event_bin,
  levels = c("-10+", "[-10,-5)", "[-5,-1)", "-1", "0", "[1,5)", "[5,10)", "10+"))]

# Reference bin = -1
m_es <- feols(cancer_aadr ~ i(event_bin, ref = "-1") | state_fips + year,
              data = df_es, cluster = ~state_fips)
cat("Event study:\n")
print(summary(m_es))

# ============================================================================
# 3. Placebo Tests: Non-Cancer Causes
# ============================================================================
cat("\n=== Placebo Tests ===\n")

m_heart <- feols(heart_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
                 data = df, cluster = ~state_fips)
cat("Heart disease:\n")
print(summary(m_heart))

m_clrd <- feols(clrd_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
                data = df, cluster = ~state_fips)
cat("CLRD:\n")
print(summary(m_clrd))

m_stroke <- feols(stroke_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
                  data = df, cluster = ~state_fips)
cat("Stroke:\n")
print(summary(m_stroke))

m_diabetes <- feols(diabetes_aadr ~ post_rrnc + treat_x_grp | state_fips + year,
                    data = df, cluster = ~state_fips)
cat("Diabetes:\n")
print(summary(m_diabetes))

# ============================================================================
# 4. Callaway-Sant'Anna Estimator
# ============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

df_cs <- copy(df)
df_cs[, g := ifelse(treated_state == 1, rrnc_year, 0)]
df_cs[, id := as.integer(factor(state_fips))]

cs_out <- tryCatch({
  att_gt(yname = "cancer_aadr", tname = "year", idname = "id", gname = "g",
         data = as.data.frame(df_cs),
         control_group = "nevertreated",
         est_method = "reg")
}, error = function(e) {
  cat("CS estimator error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("CS group-time ATTs:\n")
  print(summary(cs_out))
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS aggregate ATT:", cs_agg$overall.att, "SE:", cs_agg$overall.se, "\n")
  cs_dyn <- aggte(cs_out, type = "dynamic")
  cat("CS dynamic ATTs:\n")
  print(summary(cs_dyn))
}

# ============================================================================
# 5. Save Results
# ============================================================================
cat("\n=== Saving models ===\n")

models <- list(
  main = m1,
  triple_diff = m2,
  continuous = m3,
  weighted = m4,
  event_study = m_es,
  placebo_heart = m_heart,
  placebo_clrd = m_clrd,
  placebo_stroke = m_stroke,
  placebo_diabetes = m_diabetes
)
if (!is.null(cs_out)) {
  models$cs_out <- cs_out
  models$cs_agg <- cs_agg
  models$cs_dyn <- cs_dyn
}

saveRDS(models, file.path(data_dir, "models.rds"))

# Diagnostics
diag <- list(
  n_obs = nrow(df),
  n_states = length(unique(df$state_fips)),
  n_years = length(unique(df$year)),
  n_treated = sum(df$treated_state[df$year == 2010]),
  n_post = sum(df$post_rrnc),
  main_coef = coef(m1)["post_rrnc"],
  main_se = se(m1)["post_rrnc"],
  triple_diff_coef = coef(m2)["treat_x_grp"],
  triple_diff_se = se(m2)["treat_x_grp"]
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
