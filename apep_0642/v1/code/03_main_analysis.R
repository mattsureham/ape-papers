## 03_main_analysis.R — Main regressions
## APEP-0642: Regulatory Whack-a-Mole

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================
# 1. Load analysis panel
# ============================================================
cat("=== Loading analysis panel ===\n")
df <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Rows:", nrow(df), "\n")
cat("Facilities:", uniqueN(df$frs_id), "\n")
cat("Facility-chemicals:", uniqueN(df$fc_id), "\n")

# Create log releases (with +1 for zeros)
df[, log_releases := log(releases + 1)]

# Create facility-chemical-medium FE identifier
df[, fcm_id := paste(fc_id, medium, sep = "_")]

# Create year factor
df[, year_f := factor(YEAR)]

# Winsorize releases at 99th percentile by medium to handle outliers
for (m in unique(df$medium_cat)) {
  p99 <- quantile(df[medium_cat == m, releases], 0.99, na.rm = TRUE)
  df[medium_cat == m & releases > p99, releases_w := p99]
  df[medium_cat == m & releases <= p99, releases_w := releases]
}
df[, log_releases_w := log(releases_w + 1)]

# ============================================================
# 2. Main specification: Triple-difference
# ============================================================
cat("\n=== Main specification: Triple-difference ===\n")

# Specification 1: Post × Air vs Post × NonAir
# Y_{i,c,m,t} = α_{fcm} + γ_t + β₁(Post × Air) + β₂(Post × NonAir) + ε

cat("Running main triple-diff (log releases, winsorized)...\n")
m1_log <- feols(log_releases_w ~ post_air + post_nonair |
                  fcm_id + year_f,
                data = df,
                cluster = ~frs_id)

cat("\nMain triple-diff results:\n")
print(summary(m1_log))

# Specification 2: Difference-in-differences-in-differences
# Key interaction: Post × Air (the triple-diff coefficient)
# Reference: Non-air media in post-period
cat("\nRunning DDD specification...\n")
m2_ddd <- feols(log_releases_w ~ post:is_air + post:I(1 - is_air) |
                  fcm_id + year_f,
                data = df,
                cluster = ~frs_id)
print(summary(m2_ddd))

# ============================================================
# 3. Event study specification
# ============================================================
cat("\n=== Event study ===\n")

# Create event-time dummies interacted with air indicator
# Reference: t = -1
df[, et := factor(event_time)]

# Event study for air releases only
df_air <- df[medium_cat == "Air"]
df_nonair <- df[medium_cat != "Air"]

# Event study: Air releases
cat("Running event study: Air releases...\n")
es_air <- feols(log_releases_w ~ i(event_time, ref = -1) |
                  fc_id + year_f,
                data = df_air,
                cluster = ~frs_id)
cat("Air event study:\n")
print(summary(es_air))

# Event study: Non-air releases (pooled water + land + POTW)
cat("Running event study: Non-air releases...\n")
es_nonair <- feols(log_releases_w ~ i(event_time, ref = -1) |
                     fcm_id + year_f,
                   data = df_nonair,
                   cluster = ~frs_id)
cat("Non-air event study:\n")
print(summary(es_nonair))

# Event study: Water only
df_water <- df[medium_cat == "Water"]
es_water <- feols(log_releases_w ~ i(event_time, ref = -1) |
                    fc_id + year_f,
                  data = df_water,
                  cluster = ~frs_id)

# Event study: Land only
df_land <- df[medium_cat == "Land"]
es_land <- feols(log_releases_w ~ i(event_time, ref = -1) |
                   fc_id + year_f,
                 data = df_land,
                 cluster = ~frs_id)

# Event study: POTW only
df_potw <- df[medium_cat == "POTW"]
es_potw <- feols(log_releases_w ~ i(event_time, ref = -1) |
                   fc_id + year_f,
                 data = df_potw,
                 cluster = ~frs_id)

# ============================================================
# 4. Decomposition: Effect on each non-air medium separately
# ============================================================
cat("\n=== Medium-specific effects ===\n")

# Simple pre/post DiD for each medium
medium_results <- list()
for (m in c("Air", "Water", "Land", "POTW")) {
  cat("  Running DiD for:", m, "\n")
  d <- df[medium_cat == m]
  mod <- feols(log_releases_w ~ post | fc_id + year_f,
               data = d, cluster = ~frs_id)
  medium_results[[m]] <- mod
  cat("    Post coefficient:", round(coef(mod)["post"], 4),
      "  SE:", round(se(mod)["post"], 4),
      "  p:", round(pvalue(mod)["post"], 4), "\n")
}

# ============================================================
# 5. CAA chemicals vs non-CAA chemicals (mechanism test)
# ============================================================
cat("\n=== CAA vs non-CAA chemicals ===\n")

# Substitution should be stronger for CAA-regulated chemicals
# (inspectors specifically look for CAA compliance)
df_caa <- df[caa_chemical == "YES"]
df_noncaa <- df[caa_chemical == "NO"]

cat("CAA chemical sample:", nrow(df_caa), "rows,",
    uniqueN(df_caa$frs_id), "facilities\n")
cat("Non-CAA chemical sample:", nrow(df_noncaa), "rows,",
    uniqueN(df_noncaa$frs_id), "facilities\n")

m_caa <- feols(log_releases_w ~ post_air + post_nonair |
                 fcm_id + year_f,
               data = df_caa, cluster = ~frs_id)

m_noncaa <- feols(log_releases_w ~ post_air + post_nonair |
                    fcm_id + year_f,
                  data = df_noncaa, cluster = ~frs_id)

cat("\nCAA chemicals:\n")
print(coeftable(m_caa))
cat("\nNon-CAA chemicals:\n")
print(coeftable(m_noncaa))

# ============================================================
# 6. Save event study coefficients for tables
# ============================================================
cat("\n=== Saving results ===\n")

# Extract event study coefficients
extract_es <- function(mod, label) {
  ct <- coeftable(mod)
  data.table(
    medium = label,
    event_time = as.integer(gsub("event_time::", "", rownames(ct))),
    estimate = ct[, "Estimate"],
    se = ct[, "Std. Error"],
    pvalue = ct[, "Pr(>|t|)"]
  )
}

es_coefs <- rbind(
  extract_es(es_air, "Air"),
  extract_es(es_water, "Water"),
  extract_es(es_land, "Land"),
  extract_es(es_potw, "POTW")
)
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# ============================================================
# 7. Write diagnostics.json for validation
# ============================================================
diag <- list(
  n_treated = uniqueN(df$frs_id[df$post == 1]),
  n_pre = length(unique(df$event_time[df$event_time < 0])),
  n_obs = nrow(df),
  n_facilities = uniqueN(df$frs_id),
  n_chemicals = uniqueN(df$cas),
  n_fc = uniqueN(df$fc_id),
  years = paste(range(df$YEAR), collapse = "-"),
  main_coef_post_air = round(coef(m1_log)["post_air"], 4),
  main_coef_post_nonair = round(coef(m1_log)["post_nonair"], 4),
  main_se_post_air = round(se(m1_log)["post_air"], 4),
  main_se_post_nonair = round(se(m1_log)["post_nonair"], 4)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

# Save model objects for table generation
saveRDS(list(
  m1_log = m1_log,
  m2_ddd = m2_ddd,
  es_air = es_air,
  es_nonair = es_nonair,
  es_water = es_water,
  es_land = es_land,
  es_potw = es_potw,
  medium_results = medium_results,
  m_caa = m_caa,
  m_noncaa = m_noncaa
), file.path(data_dir, "models.rds"))

cat("\n=== Analysis complete ===\n")
cat("Main result: Post × Air =", round(coef(m1_log)["post_air"], 4), "\n")
cat("Main result: Post × NonAir =", round(coef(m1_log)["post_nonair"], 4), "\n")
