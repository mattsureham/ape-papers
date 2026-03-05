## ==========================================================================
## 03_main_analysis.R — Main DiD Estimation for Constitutional Carry
## ==========================================================================

source("00_packages.R")
data_dir <- "../data"

panel_a <- fread(file.path(data_dir, "panel_a_suicide.csv"))
panel_b <- fread(file.path(data_dir, "panel_b_firearm.csv"))
panel_c <- fread(file.path(data_dir, "panel_c_nics.csv"))
state_treat <- fread(file.path(data_dir, "state_treatment.csv"))

# State numeric ID for fixest
panel_a[, state_id := as.integer(as.factor(state))]
panel_b[, state_id := as.integer(as.factor(state))]
panel_c[, state_id := as.integer(as.factor(state))]

## ==========================================================================
## 1. TWFE BASELINE — Panel A (Suicide, 1999-2017)
## ==========================================================================

cat("=== TWFE: Panel A (Suicide, 1999-2017) ===\n")

# Primary: Suicide rate
twfe_suicide <- feols(suicide_rate ~ treated | state_id + year,
                      data = panel_a, cluster = ~state_id)

# Placebo: Unintentional injury rate
twfe_uninj <- feols(uninj_rate ~ treated | state_id + year,
                    data = panel_a, cluster = ~state_id)

# Placebo: Heart disease rate
twfe_heart <- feols(heart_rate ~ treated | state_id + year,
                    data = panel_a, cluster = ~state_id)

# Placebo: Cancer rate
twfe_cancer <- feols(cancer_rate ~ treated | state_id + year,
                     data = panel_a, cluster = ~state_id)

# With covariates
twfe_suicide_cov <- feols(suicide_rate ~ treated + poverty_rate + pct_black +
                            log_pop + median_income |
                            state_id + year,
                          data = panel_a, cluster = ~state_id)

cat("\n--- TWFE Suicide (no covariates) ---\n")
print(summary(twfe_suicide))
cat("\n--- TWFE Suicide (with covariates) ---\n")
print(summary(twfe_suicide_cov))
cat("\n--- TWFE Unintentional Injury (placebo) ---\n")
print(summary(twfe_uninj))

## ==========================================================================
## 2. TWFE BASELINE — Panel B (Firearm-Specific, 2019-2024)
## ==========================================================================

cat("\n=== TWFE: Panel B (Firearm-Specific, 2019-2024) ===\n")

# Firearm deaths
twfe_fa_deaths <- feols(rate_fa_deaths ~ treated | state_id + year,
                        data = panel_b, cluster = ~state_id)

# Firearm homicide
twfe_fa_hom <- feols(rate_fa_homicide ~ treated | state_id + year,
                     data = panel_b, cluster = ~state_id)

# Firearm suicide
twfe_fa_sui <- feols(rate_fa_suicide ~ treated | state_id + year,
                     data = panel_b, cluster = ~state_id)

# All-cause homicide
twfe_all_hom <- feols(rate_all_homicide ~ treated | state_id + year,
                      data = panel_b, cluster = ~state_id)

# All-cause suicide
twfe_all_sui <- feols(rate_all_suicide ~ treated | state_id + year,
                      data = panel_b, cluster = ~state_id)

# Placebo: non-firearm homicide
twfe_nf_hom <- feols(nf_homicide_rate ~ treated | state_id + year,
                     data = panel_b, cluster = ~state_id)

# Placebo: non-firearm suicide
twfe_nf_sui <- feols(nf_suicide_rate ~ treated | state_id + year,
                     data = panel_b, cluster = ~state_id)

cat("\n--- TWFE Firearm Deaths ---\n")
print(summary(twfe_fa_deaths))
cat("\n--- TWFE Firearm Homicide ---\n")
print(summary(twfe_fa_hom))
cat("\n--- TWFE Firearm Suicide ---\n")
print(summary(twfe_fa_sui))
cat("\n--- TWFE Non-Firearm Homicide (placebo) ---\n")
print(summary(twfe_nf_hom))

## ==========================================================================
## 3. TWFE BASELINE — Panel C (NICS Background Checks)
## ==========================================================================

cat("\n=== TWFE: Panel C (NICS, 2000-2023) ===\n")

twfe_nics <- feols(nics_pc ~ treated | state_id + year,
                   data = panel_c, cluster = ~state_id)

cat("\n--- TWFE NICS per capita ---\n")
print(summary(twfe_nics))

## ==========================================================================
## 4. CALLAWAY-SANT'ANNA — Panel A (Suicide)
## ==========================================================================

cat("\n=== Callaway-Sant'Anna: Panel A ===\n")

# CS-DiD requires: yname, tname, idname, gname, data
# first_treat = 0 for never-treated

cs_suicide <- tryCatch({
  att_gt(yname = "suicide_rate",
         tname = "year",
         idname = "state_id",
         gname = "first_treat",
         data = as.data.frame(panel_a),
         control_group = "nevertreated",
         anticipation = 0,
         base_period = "universal",
         clustervars = "state_id",
         print_details = FALSE)
}, error = function(e) { cat("CS suicide error:", e$message, "\n"); NULL })

if (!is.null(cs_suicide)) {
  cs_suicide_agg <- aggte(cs_suicide, type = "simple")
  cs_suicide_es <- aggte(cs_suicide, type = "dynamic", min_e = -8, max_e = 8)

  cat("\n--- CS-DiD Suicide: Overall ATT ---\n")
  print(summary(cs_suicide_agg))
  cat("\n--- CS-DiD Suicide: Event Study ---\n")
  print(summary(cs_suicide_es))

  # Save event study data
  es_data_a <- data.table(
    event_time = cs_suicide_es$egt,
    att = cs_suicide_es$att.egt,
    se = cs_suicide_es$se.egt,
    ci_lower = cs_suicide_es$att.egt - 1.96 * cs_suicide_es$se.egt,
    ci_upper = cs_suicide_es$att.egt + 1.96 * cs_suicide_es$se.egt,
    outcome = "Suicide Rate",
    panel = "A"
  )
}

## ==========================================================================
## 5. CALLAWAY-SANT'ANNA — Panel B (Firearm Outcomes)
## ==========================================================================

cat("\n=== Callaway-Sant'Anna: Panel B ===\n")

run_cs_panelb <- function(yname, label) {
  tryCatch({
    out <- att_gt(yname = yname,
                  tname = "year",
                  idname = "state_id",
                  gname = "first_treat",
                  data = as.data.frame(panel_b[!is.na(get(yname))]),
                  control_group = "nevertreated",
                  anticipation = 0,
                  base_period = "universal",
                  clustervars = "state_id",
                  print_details = FALSE)
    agg <- aggte(out, type = "simple")
    es <- aggte(out, type = "dynamic", min_e = -3, max_e = 3)
    cat("\n---", label, ": Overall ATT ---\n")
    print(summary(agg))

    es_dt <- data.table(
      event_time = es$egt,
      att = es$att.egt,
      se = es$se.egt,
      ci_lower = es$att.egt - 1.96 * es$se.egt,
      ci_upper = es$att.egt + 1.96 * es$se.egt,
      outcome = label,
      panel = "B"
    )
    list(gt = out, agg = agg, es = es, es_data = es_dt)
  }, error = function(e) {
    cat(label, "CS error:", e$message, "\n")
    NULL
  })
}

cs_fa_deaths <- run_cs_panelb("rate_fa_deaths", "FA Deaths")
cs_fa_hom <- run_cs_panelb("rate_fa_homicide", "FA Homicide")
cs_fa_sui <- run_cs_panelb("rate_fa_suicide", "FA Suicide")
cs_all_hom <- run_cs_panelb("rate_all_homicide", "All Homicide")
cs_all_sui <- run_cs_panelb("rate_all_suicide", "All Suicide")
cs_nf_hom <- run_cs_panelb("nf_homicide_rate", "NF Homicide (placebo)")
cs_nf_sui <- run_cs_panelb("nf_suicide_rate", "NF Suicide (placebo)")

## ==========================================================================
## 6. CALLAWAY-SANT'ANNA — Panel C (NICS)
## ==========================================================================

cat("\n=== Callaway-Sant'Anna: Panel C (NICS) ===\n")

cs_nics <- tryCatch({
  att_gt(yname = "nics_pc",
         tname = "year",
         idname = "state_id",
         gname = "first_treat",
         data = as.data.frame(panel_c[!is.na(nics_pc)]),
         control_group = "nevertreated",
         anticipation = 0,
         base_period = "universal",
         clustervars = "state_id",
         print_details = FALSE)
}, error = function(e) { cat("CS NICS error:", e$message, "\n"); NULL })

if (!is.null(cs_nics)) {
  cs_nics_agg <- aggte(cs_nics, type = "simple")
  cs_nics_es <- aggte(cs_nics, type = "dynamic", min_e = -8, max_e = 8)

  cat("\n--- CS-DiD NICS: Overall ATT ---\n")
  print(summary(cs_nics_agg))

  es_data_c <- data.table(
    event_time = cs_nics_es$egt,
    att = cs_nics_es$att.egt,
    se = cs_nics_es$se.egt,
    ci_lower = cs_nics_es$att.egt - 1.96 * cs_nics_es$se.egt,
    ci_upper = cs_nics_es$att.egt + 1.96 * cs_nics_es$se.egt,
    outcome = "NICS per 100K",
    panel = "C"
  )
}

## ==========================================================================
## 7. SUN-ABRAHAM EVENT STUDY (fixest)
## ==========================================================================

cat("\n=== Sun-Abraham Event Study ===\n")

# Create event time variable
panel_a[, event_time := ifelse(first_treat > 0, year - first_treat, -1000)]
panel_b[, event_time := ifelse(first_treat > 0, year - first_treat, -1000)]
panel_c[, event_time := ifelse(first_treat > 0, year - first_treat, -1000)]

# Sun-Abraham IW estimator via fixest
sa_suicide <- feols(suicide_rate ~ sunab(first_treat, year) | state_id + year,
                    data = panel_a[first_treat != 0 | ever_treated == FALSE],
                    cluster = ~state_id)

sa_fa_deaths <- feols(rate_fa_deaths ~ sunab(first_treat, year) | state_id + year,
                      data = panel_b[first_treat != 0 | ever_treated == FALSE],
                      cluster = ~state_id)

sa_nics <- feols(nics_pc ~ sunab(first_treat, year) | state_id + year,
                 data = panel_c[(first_treat != 0 | ever_treated == FALSE) & !is.na(nics_pc)],
                 cluster = ~state_id)

cat("\n--- Sun-Abraham: Suicide ---\n")
print(summary(sa_suicide, agg = "ATT"))
cat("\n--- Sun-Abraham: FA Deaths ---\n")
print(summary(sa_fa_deaths, agg = "ATT"))
cat("\n--- Sun-Abraham: NICS ---\n")
print(summary(sa_nics, agg = "ATT"))

## ==========================================================================
## 8. SAVE ALL RESULTS
## ==========================================================================

cat("\n=== Saving results ===\n")

# Collect TWFE results
twfe_results <- data.table(
  outcome = c("Suicide Rate", "Uninj Rate (placebo)", "Heart Rate (placebo)",
              "Cancer Rate (placebo)", "Suicide Rate (covs)",
              "FA Deaths", "FA Homicide", "FA Suicide",
              "All Homicide", "All Suicide",
              "NF Homicide (placebo)", "NF Suicide (placebo)",
              "NICS per 100K"),
  panel = c(rep("A", 5), rep("B", 7), "C"),
  coef = c(coef(twfe_suicide), coef(twfe_uninj), coef(twfe_heart),
           coef(twfe_cancer), coef(twfe_suicide_cov)["treated"],
           coef(twfe_fa_deaths), coef(twfe_fa_hom), coef(twfe_fa_sui),
           coef(twfe_all_hom), coef(twfe_all_sui),
           coef(twfe_nf_hom), coef(twfe_nf_sui),
           coef(twfe_nics)),
  se = c(se(twfe_suicide), se(twfe_uninj), se(twfe_heart),
         se(twfe_cancer), se(twfe_suicide_cov)["treated"],
         se(twfe_fa_deaths), se(twfe_fa_hom), se(twfe_fa_sui),
         se(twfe_all_hom), se(twfe_all_sui),
         se(twfe_nf_hom), se(twfe_nf_sui),
         se(twfe_nics)),
  pval = c(fixest::pvalue(twfe_suicide), fixest::pvalue(twfe_uninj), fixest::pvalue(twfe_heart),
           fixest::pvalue(twfe_cancer), fixest::pvalue(twfe_suicide_cov)["treated"],
           fixest::pvalue(twfe_fa_deaths), fixest::pvalue(twfe_fa_hom), fixest::pvalue(twfe_fa_sui),
           fixest::pvalue(twfe_all_hom), fixest::pvalue(twfe_all_sui),
           fixest::pvalue(twfe_nf_hom), fixest::pvalue(twfe_nf_sui),
           fixest::pvalue(twfe_nics)),
  n_obs = c(nobs(twfe_suicide), nobs(twfe_uninj), nobs(twfe_heart),
            nobs(twfe_cancer), nobs(twfe_suicide_cov),
            nobs(twfe_fa_deaths), nobs(twfe_fa_hom), nobs(twfe_fa_sui),
            nobs(twfe_all_hom), nobs(twfe_all_sui),
            nobs(twfe_nf_hom), nobs(twfe_nf_sui),
            nobs(twfe_nics)),
  method = "TWFE"
)
fwrite(twfe_results, file.path(data_dir, "twfe_results.csv"))

# Collect CS-DiD aggregate results
cs_results <- list()
if (!is.null(cs_suicide)) {
  cs_results[["Suicide Rate"]] <- data.table(
    outcome = "Suicide Rate", panel = "A",
    coef = cs_suicide_agg$overall.att, se = cs_suicide_agg$overall.se,
    method = "CS-DiD"
  )
}
for (nm in c("cs_fa_deaths", "cs_fa_hom", "cs_fa_sui",
             "cs_all_hom", "cs_all_sui", "cs_nf_hom", "cs_nf_sui")) {
  obj <- get(nm)
  if (!is.null(obj)) {
    cs_results[[obj$es_data$outcome[1]]] <- data.table(
      outcome = obj$es_data$outcome[1], panel = "B",
      coef = obj$agg$overall.att, se = obj$agg$overall.se,
      method = "CS-DiD"
    )
  }
}
if (!is.null(cs_nics)) {
  cs_results[["NICS per 100K"]] <- data.table(
    outcome = "NICS per 100K", panel = "C",
    coef = cs_nics_agg$overall.att, se = cs_nics_agg$overall.se,
    method = "CS-DiD"
  )
}
cs_results_dt <- rbindlist(cs_results)
fwrite(cs_results_dt, file.path(data_dir, "cs_results.csv"))

# Collect all event study data
es_all <- list()
if (exists("es_data_a")) es_all[["A"]] <- es_data_a
for (nm in c("cs_fa_deaths", "cs_fa_hom", "cs_fa_sui",
             "cs_all_hom", "cs_all_sui", "cs_nf_hom", "cs_nf_sui")) {
  obj <- get(nm)
  if (!is.null(obj)) es_all[[nm]] <- obj$es_data
}
if (exists("es_data_c")) es_all[["C"]] <- es_data_c
es_all_dt <- rbindlist(es_all)
fwrite(es_all_dt, file.path(data_dir, "event_study_data.csv"))

# Save Sun-Abraham event study coefficients
sa_save <- function(mod, label, panel_name) {
  ct <- as.data.table(coeftable(mod))
  ct$outcome <- label
  ct$panel <- panel_name
  ct
}
sa_all <- rbind(
  sa_save(sa_suicide, "Suicide Rate", "A"),
  sa_save(sa_fa_deaths, "FA Deaths", "B"),
  sa_save(sa_nics, "NICS per 100K", "C")
)
fwrite(sa_all, file.path(data_dir, "sun_abraham_results.csv"))

cat("\nAll main analysis results saved.\n")
cat("=== Main analysis complete ===\n")
