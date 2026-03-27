## 03_main_analysis.R — Main regressions with CWA/RCRA controls
## APEP-0642 v2: Regulatory Whack-a-Mole

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
  df[medium_cat == m, releases_w := pmin(releases, p99)]
}
df[, log_releases_w := log(releases_w + 1)]

# Ensure CWA/RCRA columns exist (may not if data was unavailable)
if (!"cwa_inspected" %in% names(df)) df[, cwa_inspected := 0L]
if (!"rcra_inspected" %in% names(df)) df[, rcra_inspected := 0L]
if (!"cwa_post" %in% names(df)) df[, cwa_post := 0L]
if (!"rcra_post" %in% names(df)) df[, rcra_post := 0L]
if (!"pre_land_ever" %in% names(df)) df[, pre_land_ever := 0L]

# ============================================================
# 2. BASELINE: Triple-difference (reproduce V1)
# ============================================================
cat("\n=== Baseline triple-diff (V1 reproduction) ===\n")

m1_baseline <- feols(log_releases_w ~ post_air + post_nonair |
                       fcm_id + year_f,
                     data = df, cluster = ~frs_id)
cat("Baseline (V1 reproduction):\n")
print(coeftable(m1_baseline))

# ============================================================
# 3. TRIPLE-DIFF WITH CWA/RCRA CONTROLS [V2 KEY]
# ============================================================
cat("\n=== Triple-diff with CWA/RCRA controls ===\n")

# CWA control interacted with non-air indicator
df[, cwa_insp_nonair := cwa_inspected * (1L - is_air)]
df[, rcra_insp_nonair := rcra_inspected * (1L - is_air)]

m2_cwa <- feols(log_releases_w ~ post_air + post_nonair +
                  cwa_inspected + cwa_insp_nonair |
                  fcm_id + year_f,
                data = df, cluster = ~frs_id)
cat("With CWA controls:\n")
print(coeftable(m2_cwa))

m3_cwa_rcra <- feols(log_releases_w ~ post_air + post_nonair +
                       cwa_inspected + cwa_insp_nonair +
                       rcra_inspected + rcra_insp_nonair |
                       fcm_id + year_f,
                     data = df, cluster = ~frs_id)
cat("With CWA + RCRA controls:\n")
print(coeftable(m3_cwa_rcra))

# ============================================================
# 4. MEDIUM-SPECIFIC DECOMPOSITION [V2 CENTRAL TABLE]
# ============================================================
cat("\n=== Medium-specific decomposition ===\n")

df_air   <- df[medium_cat == "Air"]
df_water <- df[medium_cat == "Water"]
df_land  <- df[medium_cat == "Land"]
df_potw  <- df[medium_cat == "POTW"]

# 4a. Without CWA/RCRA controls (V1 specification)
medium_results_noctl <- list()
for (m in c("Air", "Water", "Land", "POTW")) {
  d <- df[medium_cat == m]
  mod <- feols(log_releases_w ~ post | fc_id + year_f,
               data = d, cluster = ~frs_id)
  medium_results_noctl[[m]] <- mod
  cat(sprintf("  %s (no controls): Post=%.4f (SE=%.4f, p=%.4f)\n",
              m, coef(mod)["post"], se(mod)["post"], pvalue(mod)["post"]))
}

# 4b. With CWA/RCRA controls [V2 KEY]
medium_results_ctl <- list()
for (m in c("Air", "Water", "Land", "POTW")) {
  d <- df[medium_cat == m]
  mod <- feols(log_releases_w ~ post + cwa_inspected + rcra_inspected |
                 fc_id + year_f,
               data = d, cluster = ~frs_id)
  medium_results_ctl[[m]] <- mod
  cat(sprintf("  %s (CWA+RCRA): Post=%.4f (SE=%.4f, p=%.4f)\n",
              m, coef(mod)["post"], se(mod)["post"], pvalue(mod)["post"]))
}

# ============================================================
# 5. EVENT STUDIES (medium-specific)
# ============================================================
cat("\n=== Event studies ===\n")

# 5a. Air event study (with year FE)
es_air <- feols(log_releases_w ~ i(event_time, ref = -1) |
                  fc_id + year_f,
                data = df_air, cluster = ~frs_id)

# 5b. Non-air event study (pooled)
es_nonair <- feols(log_releases_w ~ i(event_time, ref = -1) |
                     fcm_id + year_f,
                   data = df[medium_cat != "Air"],
                   cluster = ~frs_id)

# 5c. Medium-specific event studies
es_water <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                  data = df_water, cluster = ~frs_id)
es_land  <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                  data = df_land, cluster = ~frs_id)
es_potw  <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                  data = df_potw, cluster = ~frs_id)

cat("Event study coefficients at t=0:\n")
for (nm in c("Air", "Water", "Land", "POTW")) {
  es <- get(paste0("es_", tolower(nm)))
  ct <- coeftable(es)
  t0_idx <- grep("event_time::0$", rownames(ct))
  if (length(t0_idx) > 0) {
    cat(sprintf("  %s t=0: %.4f (%.4f)\n", nm, ct[t0_idx[1], 1], ct[t0_idx[1], 2]))
  } else {
    cat(sprintf("  %s t=0: not available\n", nm))
  }
}

# ============================================================
# 6. CAA vs NON-CAA MECHANISM TEST
# ============================================================
cat("\n=== CAA vs non-CAA mechanism ===\n")

df_caa    <- df[caa_chemical == "YES"]
df_noncaa <- df[caa_chemical == "NO"]

# 6a. Without CWA controls
m_caa_noctl <- feols(log_releases_w ~ post_air + post_nonair |
                       fcm_id + year_f,
                     data = df_caa, cluster = ~frs_id)

m_noncaa_noctl <- feols(log_releases_w ~ post_air + post_nonair |
                          fcm_id + year_f,
                        data = df_noncaa, cluster = ~frs_id)

# 6b. With CWA/RCRA controls [V2]
m_caa_ctl <- feols(log_releases_w ~ post_air + post_nonair +
                     cwa_inspected + cwa_insp_nonair +
                     rcra_inspected + rcra_insp_nonair |
                     fcm_id + year_f,
                   data = df_caa, cluster = ~frs_id)

m_noncaa_ctl <- feols(log_releases_w ~ post_air + post_nonair +
                        cwa_inspected + cwa_insp_nonair +
                        rcra_inspected + rcra_insp_nonair |
                        fcm_id + year_f,
                      data = df_noncaa, cluster = ~frs_id)

cat("CAA (no ctl): PostAir=", round(coef(m_caa_noctl)["post_air"], 4),
    " PostNonAir=", round(coef(m_caa_noctl)["post_nonair"], 4), "\n")
cat("CAA (CWA+RCRA): PostAir=", round(coef(m_caa_ctl)["post_air"], 4),
    " PostNonAir=", round(coef(m_caa_ctl)["post_nonair"], 4), "\n")
cat("Non-CAA (no ctl): PostAir=", round(coef(m_noncaa_noctl)["post_air"], 4),
    " PostNonAir=", round(coef(m_noncaa_noctl)["post_nonair"], 4), "\n")
cat("Non-CAA (CWA+RCRA): PostAir=", round(coef(m_noncaa_ctl)["post_air"], 4),
    " PostNonAir=", round(coef(m_noncaa_ctl)["post_nonair"], 4), "\n")

# 6c. Triple interaction (full sample, more efficient than split)
df[, caa_dummy := as.integer(caa_chemical == "YES")]
m_triple_int <- feols(log_releases_w ~ post_air + post_nonair +
                        post_air:caa_dummy + post_nonair:caa_dummy |
                        fcm_id + year_f,
                      data = df, cluster = ~frs_id)
cat("\nTriple interaction:\n")
print(coeftable(m_triple_int))

# ============================================================
# 7. EXTENSIVE-MARGIN OUTCOMES [V2 NEW — Codex suggestion]
# ============================================================
cat("\n=== Extensive-margin outcomes ===\n")

# Binary: any positive release to land?
# Use facility-chemical-year panel (wide format, not long)
panel_wide <- fread(file.path(data_dir, "analysis_panel.csv"))
# Need to reconstruct wide panel from long
# Actually use the analysis_sample in wide: one row per fc-year
# Pivot back from long
ext_panel <- dcast(df[, .(fc_id, frs_id, YEAR, medium_cat, releases, post,
                          event_time, first_insp_year, caa_chemical, ST, naics,
                          cwa_inspected, rcra_inspected, pre_land_ever, cohort_year)],
                   fc_id + frs_id + YEAR + post + event_time + first_insp_year +
                     caa_chemical + ST + naics + cwa_inspected + rcra_inspected +
                     pre_land_ever + cohort_year ~ medium_cat,
                   value.var = "releases",
                   fun.aggregate = sum)

ext_panel[, any_land := as.integer(Land > 0)]
ext_panel[, any_water := as.integer(Water > 0)]
ext_panel[, any_potw := as.integer(POTW > 0)]
ext_panel[, year_f := factor(YEAR)]

# Extensive margin: probability of any land release
m_ext_land <- feols(any_land ~ post + cwa_inspected + rcra_inspected |
                      fc_id + year_f,
                    data = ext_panel, cluster = ~frs_id)
cat("Extensive margin — Pr(any land release):\n")
cat("  Post:", round(coef(m_ext_land)["post"], 4),
    " SE:", round(se(m_ext_land)["post"], 4),
    " p:", round(pvalue(m_ext_land)["post"], 4), "\n")

m_ext_water <- feols(any_water ~ post + cwa_inspected + rcra_inspected |
                       fc_id + year_f,
                     data = ext_panel, cluster = ~frs_id)
cat("Extensive margin — Pr(any water release):\n")
cat("  Post:", round(coef(m_ext_water)["post"], 4),
    " SE:", round(se(m_ext_water)["post"], 4),
    " p:", round(pvalue(m_ext_water)["post"], 4), "\n")

# ============================================================
# 8. SWITCHING-CAPACITY MECHANISM [V2 NEW — Codex suggestion]
# ============================================================
cat("\n=== Switching-capacity mechanism ===\n")

# Split by pre-inspection land disposal capability
df_hasland  <- df[pre_land_ever == 1]
df_noland   <- df[pre_land_ever == 0]

if (nrow(df_hasland) > 1000 && nrow(df_noland) > 1000) {
  m_switch_has <- feols(log_releases_w ~ post_air + post_nonair |
                          fcm_id + year_f,
                        data = df_hasland, cluster = ~frs_id)
  m_switch_no  <- feols(log_releases_w ~ post_air + post_nonair |
                          fcm_id + year_f,
                        data = df_noland, cluster = ~frs_id)

  cat("Pre-existing land pathway:\n")
  cat("  PostNonAir:", round(coef(m_switch_has)["post_nonair"], 4),
      " SE:", round(se(m_switch_has)["post_nonair"], 4), "\n")
  cat("No pre-existing land pathway:\n")
  cat("  PostNonAir:", round(coef(m_switch_no)["post_nonair"], 4),
      " SE:", round(se(m_switch_no)["post_nonair"], 4), "\n")
} else {
  cat("  Insufficient observations for switching-capacity split.\n")
  m_switch_has <- m_switch_no <- NULL
}

# ============================================================
# 9. CALLAWAY-SANT'ANNA [DISABLED — fastglm segfault bug]
# ============================================================
cat("\n=== Callaway-Sant'Anna: SKIPPED (fastglm segfault) ===\n")
cat("  The did package crashes R via fastglm segfault with this panel.\n")
cat("  CS robustness will be noted as unavailable in the paper.\n")
cs_air <- NULL; es_air_cs <- NULL; att_air_cs <- NULL
cs_land <- NULL; es_land_cs <- NULL; att_land_cs <- NULL

if (FALSE) {  # Disabled block

# Run CS on FACILITY-level aggregated air releases (chemical-level is too large)
cs_air_data <- df_air[, .(log_releases_w = mean(log_releases_w, na.rm = TRUE)),
                      by = .(frs_id, YEAR, cohort_year)]
cs_air_data[, fac_numeric := as.integer(factor(frs_id))]
cs_air_data <- cs_air_data[cohort_year >= 0]

cat("CS air data (facility-level): ", nrow(cs_air_data), "rows,",
    uniqueN(cs_air_data$fac_numeric), "units\n")

tryCatch({
  cs_air <- att_gt(
    yname = "log_releases_w",
    tname = "YEAR",
    idname = "fac_numeric",
    gname = "cohort_year",
    data = as.data.frame(cs_air_data),
    control_group = "notyettreated",
    anticipation = 0,
    allow_unbalanced_panel = TRUE
  )

  es_air_cs <- aggte(cs_air, type = "dynamic", min_e = -5, max_e = 5, na.rm = TRUE)
  att_air_cs <- aggte(cs_air, type = "simple", na.rm = TRUE)

  cat("CS ATT (air):", round(att_air_cs$overall.att, 4),
      " SE:", round(att_air_cs$overall.se, 4), "\n")
}, error = function(e) {
  cat("CS air estimation failed:", conditionMessage(e), "\n")
  cs_air <<- NULL; es_air_cs <<- NULL; att_air_cs <<- NULL
})

# CS on facility-level land releases
cs_land_data <- df_land[, .(log_releases_w = mean(log_releases_w, na.rm = TRUE)),
                        by = .(frs_id, YEAR, cohort_year)]
cs_land_data[, fac_numeric := as.integer(factor(frs_id))]
cs_land_data <- cs_land_data[cohort_year >= 0]

cat("CS land data (facility-level): ", nrow(cs_land_data), "rows,",
    uniqueN(cs_land_data$fac_numeric), "units\n")

tryCatch({
  cs_land <- att_gt(
    yname = "log_releases_w",
    tname = "YEAR",
    idname = "fac_numeric",
    gname = "cohort_year",
    data = as.data.frame(cs_land_data),
    control_group = "notyettreated",
    anticipation = 0,
    allow_unbalanced_panel = TRUE
  )

  es_land_cs <- aggte(cs_land, type = "dynamic", min_e = -5, max_e = 5, na.rm = TRUE)
  att_land_cs <- aggte(cs_land, type = "simple", na.rm = TRUE)

  cat("CS ATT (land):", round(att_land_cs$overall.att, 4),
      " SE:", round(att_land_cs$overall.se, 4), "\n")
}, error = function(e) {
  cat("CS land estimation failed:", conditionMessage(e), "\n")
  cs_land <<- NULL; es_land_cs <<- NULL; att_land_cs <<- NULL
})
}  # End disabled CS block

# ============================================================
# 10. Save results
# ============================================================
cat("\n=== Saving results ===\n")

# Extract event study coefficients for figures
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
  extract_es(es_nonair, "NonAir"),
  extract_es(es_water, "Water"),
  extract_es(es_land, "Land"),
  extract_es(es_potw, "POTW")
)
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# Diagnostics
diag <- list(
  n_treated = uniqueN(df$frs_id[df$post == 1]),
  n_pre = length(unique(df$event_time[df$event_time < 0])),
  n_obs = nrow(df),
  n_facilities = uniqueN(df$frs_id),
  n_chemicals = uniqueN(df$cas),
  n_fc = uniqueN(df$fc_id),
  years = paste(range(df$YEAR), collapse = "-"),
  # Baseline
  baseline_post_air = round(coef(m1_baseline)["post_air"], 4),
  baseline_post_nonair = round(coef(m1_baseline)["post_nonair"], 4),
  # With CWA+RCRA controls
  cwa_post_air = round(coef(m3_cwa_rcra)["post_air"], 4),
  cwa_post_nonair = round(coef(m3_cwa_rcra)["post_nonair"], 4),
  # CWA overlap
  n_cwa_inspected = uniqueN(df$frs_id[df$cwa_inspected == 1]),
  n_rcra_inspected = uniqueN(df$frs_id[df$rcra_inspected == 1])
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

# Save all model objects
models <- list(
  # Baseline
  m1_baseline = m1_baseline,
  # CWA controls
  m2_cwa = m2_cwa,
  m3_cwa_rcra = m3_cwa_rcra,
  # Medium decomposition
  medium_results_noctl = medium_results_noctl,
  medium_results_ctl = medium_results_ctl,
  # Event studies
  es_air = es_air, es_nonair = es_nonair,
  es_water = es_water, es_land = es_land, es_potw = es_potw,
  # Mechanism
  m_caa_noctl = m_caa_noctl, m_noncaa_noctl = m_noncaa_noctl,
  m_caa_ctl = m_caa_ctl, m_noncaa_ctl = m_noncaa_ctl,
  m_triple_int = m_triple_int,
  # Extensive margin
  m_ext_land = m_ext_land, m_ext_water = m_ext_water,
  # Switching capacity
  m_switch_has = m_switch_has, m_switch_no = m_switch_no
)

# Add CS results if available
if (exists("cs_air") && !is.null(cs_air)) {
  models$cs_air <- cs_air
  models$es_air_cs <- es_air_cs
  models$att_air_cs <- att_air_cs
}
if (exists("cs_land") && !is.null(cs_land)) {
  models$cs_land <- cs_land
  models$es_land_cs <- es_land_cs
  models$att_land_cs <- att_land_cs
}

# Save wide panel for extensive margin (needed by tables/figures)
fwrite(ext_panel, file.path(data_dir, "ext_panel.csv"))

saveRDS(models, file.path(data_dir, "models.rds"))

cat("\n=== Analysis complete ===\n")
cat("Baseline: PostAir =", round(coef(m1_baseline)["post_air"], 4), "\n")
cat("Baseline: PostNonAir =", round(coef(m1_baseline)["post_nonair"], 4), "\n")
cat("CWA+RCRA: PostAir =", round(coef(m3_cwa_rcra)["post_air"], 4), "\n")
cat("CWA+RCRA: PostNonAir =", round(coef(m3_cwa_rcra)["post_nonair"], 4), "\n")
