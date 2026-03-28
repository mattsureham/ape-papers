## 03_main_analysis.R — Reparameterized main regressions with composition outcomes
## APEP-0642 v3: From Substitution to Composition Bias

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================
# 1. Load and prepare analysis panel
# ============================================================
cat("=== Loading analysis panel ===\n")
df <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Rows:", nrow(df), "| Facilities:", uniqueN(df$frs_id),
    "| Chemicals:", uniqueN(df$cas), "| Years:", length(unique(df$YEAR)), "\n")

df[, log_releases := log(releases + 1)]
df[, fcm_id := paste(fc_id, medium, sep = "_")]
df[, year_f := factor(YEAR)]

for (m in unique(df$medium_cat)) {
  p99 <- quantile(df[medium_cat == m, releases], 0.99, na.rm = TRUE)
  df[medium_cat == m, releases_w := pmin(releases, p99)]
}
df[, log_releases_w := log(releases_w + 1)]

if (!"cwa_inspected" %in% names(df)) df[, cwa_inspected := 0L]
if (!"pre_land_ever" %in% names(df)) df[, pre_land_ever := 0L]

# ============================================================
# 2. REPARAMETERIZED MAIN MODEL [V3 KEY]
# ============================================================
cat("\n=== Reparameterized specification ===\n")

# Y = α_fcm + γ_t + θ(Post) + τ(Post×Air) + ε
# θ = common post effect (non-air baseline)
# τ = air-vs-nonair differential (THE key parameter)

m_reparam <- feols(log_releases_w ~ post + post_air | fcm_id + year_f,
                   data = df, cluster = ~frs_id)
cat("  θ (common post):", round(coef(m_reparam)["post"], 4),
    " SE:", round(se(m_reparam)["post"], 4),
    " p:", round(pvalue(m_reparam)["post"], 4), "\n")
cat("  τ (air differential):", round(coef(m_reparam)["post_air"], 4),
    " SE:", round(se(m_reparam)["post_air"], 4),
    " p:", round(pvalue(m_reparam)["post_air"], 4), "\n")

m_reparam_cwa <- feols(log_releases_w ~ post + post_air + cwa_inspected |
                         fcm_id + year_f,
                       data = df, cluster = ~frs_id)
cat("With CWA:\n")
cat("  θ:", round(coef(m_reparam_cwa)["post"], 4),
    " τ:", round(coef(m_reparam_cwa)["post_air"], 4),
    " p(τ):", round(pvalue(m_reparam_cwa)["post_air"], 4), "\n")

# ============================================================
# 3. COMPOSITION OUTCOMES [V3 NEW]
# ============================================================
cat("\n=== Composition outcomes ===\n")

ext_panel <- dcast(df[, .(fc_id, frs_id, YEAR, medium_cat, releases_w, post,
                          event_time, first_insp_year, caa_chemical, ST, naics,
                          cwa_inspected, pre_land_ever, cohort_year)],
                   fc_id + frs_id + YEAR + post + event_time + first_insp_year +
                     caa_chemical + ST + naics + cwa_inspected +
                     pre_land_ever + cohort_year ~ medium_cat,
                   value.var = "releases_w", fun.aggregate = sum)

ext_panel[, year_f := factor(YEAR)]
ext_panel[, total := Air + Water + Land + POTW]
ext_panel[total > 0, air_share := Air / total]
ext_panel[, log_total := log(total + 1)]
ext_panel[, log_air := log(Air + 1)]

m_airshare <- feols(air_share ~ post + cwa_inspected | fc_id + year_f,
                    data = ext_panel[!is.na(air_share)], cluster = ~frs_id)
m_total <- feols(log_total ~ post + cwa_inspected | fc_id + year_f,
                 data = ext_panel, cluster = ~frs_id)
m_air_only <- feols(log_air ~ post + cwa_inspected | fc_id + year_f,
                    data = ext_panel, cluster = ~frs_id)

cat("Air share: Post=", round(coef(m_airshare)["post"], 4),
    " p:", round(pvalue(m_airshare)["post"], 4), "\n")
cat("Log total: Post=", round(coef(m_total)["post"], 4),
    " p:", round(pvalue(m_total)["post"], 4), "\n")
cat("Log air: Post=", round(coef(m_air_only)["post"], 4),
    " p:", round(pvalue(m_air_only)["post"], 4), "\n")
cat("** Measurement bias:", round(coef(m_air_only)["post"] - coef(m_total)["post"], 4), "\n")

# ============================================================
# 4. MEDIUM-SPECIFIC DECOMPOSITION
# ============================================================
cat("\n=== Medium-specific decomposition ===\n")

medium_results <- list()
for (m in c("Air", "Water", "Land", "POTW")) {
  d <- df[medium_cat == m]
  mod <- feols(log_releases_w ~ post + cwa_inspected | fc_id + year_f,
               data = d, cluster = ~frs_id)
  medium_results[[m]] <- mod
  cat(sprintf("  %s: Post=%.4f (SE=%.4f, p=%.4f)\n",
              m, coef(mod)["post"], se(mod)["post"], pvalue(mod)["post"]))
}

# ============================================================
# 5. EVENT STUDIES
# ============================================================
cat("\n=== Event studies ===\n")

df_air <- df[medium_cat == "Air"]
df_water <- df[medium_cat == "Water"]
df_land <- df[medium_cat == "Land"]
df_potw <- df[medium_cat == "POTW"]

es_air <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                data = df_air, cluster = ~frs_id)
es_nonair <- feols(log_releases_w ~ i(event_time, ref = -1) | fcm_id + year_f,
                   data = df[medium_cat != "Air"], cluster = ~frs_id)
es_water <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                  data = df_water, cluster = ~frs_id)
es_land <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                 data = df_land, cluster = ~frs_id)
es_potw <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id + year_f,
                 data = df_potw, cluster = ~frs_id)
es_airshare <- feols(air_share ~ i(event_time, ref = -1) | fc_id + year_f,
                     data = ext_panel[!is.na(air_share)], cluster = ~frs_id)

extract_es <- function(mod, label) {
  ct <- coeftable(mod)
  data.table(medium = label,
             event_time = as.integer(gsub("event_time::", "", rownames(ct))),
             estimate = ct[, "Estimate"], se = ct[, "Std. Error"],
             pvalue = ct[, "Pr(>|t|)"])
}

es_coefs <- rbind(extract_es(es_air, "Air"), extract_es(es_nonair, "NonAir"),
                  extract_es(es_water, "Water"), extract_es(es_land, "Land"),
                  extract_es(es_potw, "POTW"), extract_es(es_airshare, "AirShare"))
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# ============================================================
# 6. MECHANISM (harmonized)
# ============================================================
cat("\n=== Mechanism (harmonized) ===\n")

df[, caa_dummy := as.integer(caa_chemical == "YES")]

# Split with SAME reparameterized spec + CWA controls
m_caa <- feols(log_releases_w ~ post + post_air + cwa_inspected | fcm_id + year_f,
               data = df[caa_dummy == 1], cluster = ~frs_id)
m_noncaa <- feols(log_releases_w ~ post + post_air + cwa_inspected | fcm_id + year_f,
                  data = df[caa_dummy == 0], cluster = ~frs_id)

cat("CAA: θ=", round(coef(m_caa)["post"], 4),
    " τ=", round(coef(m_caa)["post_air"], 4), "\n")
cat("NonCAA: θ=", round(coef(m_noncaa)["post"], 4),
    " τ=", round(coef(m_noncaa)["post_air"], 4), "\n")

m_mech_int <- feols(log_releases_w ~ post + post_air +
                      post:caa_dummy + post_air:caa_dummy +
                      cwa_inspected | fcm_id + year_f,
                    data = df, cluster = ~frs_id)
cat("Interaction:\n")
print(coeftable(m_mech_int))

# ============================================================
# 7. STACKED EVENT STUDY [V3 NEW]
# ============================================================
cat("\n=== Stacked event study ===\n")

cohort_years <- sort(unique(df$first_insp_year[!is.na(df$first_insp_year)]))
stacked_list <- list()
stack_id <- 0

for (g in cohort_years) {
  treated_frs <- unique(df$frs_id[df$first_insp_year == g])
  nyt_frs <- unique(df$frs_id[!is.na(df$first_insp_year) & df$first_insp_year > g])
  if (length(treated_frs) < 10 || length(nyt_frs) < 10) next

  sub_t <- df[frs_id %in% treated_frs & event_time >= -4 & event_time <= 4]
  sub_n <- df[frs_id %in% nyt_frs]
  sub_n[, stack_et := YEAR - g]
  sub_n <- sub_n[stack_et >= -4 & stack_et <= 4]
  sub_n[, post := 0L]; sub_n[, post_air := 0L]; sub_n[, post_nonair := 0L]
  sub_t[, stack_et := event_time]

  sub <- rbind(sub_t, sub_n, fill = TRUE)
  stack_id <- stack_id + 1
  sub[, stack_id := stack_id]
  sub[, stack_fcm := paste(fcm_id, stack_id, sep = "_S")]
  stacked_list[[as.character(g)]] <- sub
}

if (length(stacked_list) > 0) {
  stacked <- rbindlist(stacked_list, fill = TRUE)
  stacked[, year_f := factor(YEAR)]
  cat("Stacked:", nrow(stacked), "rows,", length(stacked_list), "cohorts\n")

  m_stacked <- feols(log_releases_w ~ post + post_air | stack_fcm + year_f,
                     data = stacked, cluster = ~frs_id)
  cat("Stacked τ:", round(coef(m_stacked)["post_air"], 4),
      " p:", round(pvalue(m_stacked)["post_air"], 4), "\n")
  cat("Stacked θ:", round(coef(m_stacked)["post"], 4),
      " p:", round(pvalue(m_stacked)["post"], 4), "\n")
} else {
  m_stacked <- NULL
}

# ============================================================
# 8. EXTENSIVE MARGIN
# ============================================================
cat("\n=== Extensive margin ===\n")

ext_panel[, any_land := as.integer(Land > 0)]
ext_panel[, any_water := as.integer(Water > 0)]

m_ext_land <- feols(any_land ~ post + cwa_inspected | fc_id + year_f,
                    data = ext_panel, cluster = ~frs_id)
m_ext_water <- feols(any_water ~ post + cwa_inspected | fc_id + year_f,
                     data = ext_panel, cluster = ~frs_id)

cat("Pr(any land): Post=", round(coef(m_ext_land)["post"], 4),
    " p:", round(pvalue(m_ext_land)["post"], 4), "\n")

# ============================================================
# 9. Save
# ============================================================
cat("\n=== Saving ===\n")

diag <- list(
  n_obs = nrow(df), n_facilities = uniqueN(df$frs_id),
  n_chemicals = uniqueN(df$cas), n_fc = uniqueN(df$fc_id),
  n_tri_years = length(unique(df$YEAR)),
  years = paste(sort(unique(df$YEAR)), collapse = ","),
  tau = round(coef(m_reparam_cwa)["post_air"], 4),
  theta = round(coef(m_reparam_cwa)["post"], 4),
  air_share_shift = round(coef(m_airshare)["post"], 4),
  measurement_bias = round(coef(m_air_only)["post"] - coef(m_total)["post"], 4),
  n_cwa = uniqueN(df$frs_id[df$cwa_inspected == 1])
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

models <- list(
  m_reparam = m_reparam, m_reparam_cwa = m_reparam_cwa,
  m_airshare = m_airshare, m_total = m_total, m_air_only = m_air_only,
  medium_results = medium_results,
  es_air = es_air, es_nonair = es_nonair, es_water = es_water,
  es_land = es_land, es_potw = es_potw, es_airshare = es_airshare,
  m_caa = m_caa, m_noncaa = m_noncaa, m_mech_int = m_mech_int,
  m_stacked = m_stacked,
  m_ext_land = m_ext_land, m_ext_water = m_ext_water
)

fwrite(ext_panel, file.path(data_dir, "ext_panel.csv"))
saveRDS(models, file.path(data_dir, "models.rds"))

cat("\n=== V3 Analysis complete ===\n")
cat("τ (air differential):", round(coef(m_reparam_cwa)["post_air"], 4), "\n")
cat("Air share shift:", round(coef(m_airshare)["post"], 4), "\n")
cat("Measurement bias:", round(coef(m_air_only)["post"] - coef(m_total)["post"], 4), "\n")
