## 04_robustness.R — Robustness checks for apep_0529

source("00_packages.R")

data_dir <- "../data"

panel <- fread(file.path(data_dir, "circ_election_panel.csv"))

## ============================================================
## 1. Alternative estimator: Callaway-Sant'Anna
## ============================================================
cat("=== Callaway-Sant'Anna DiD ===\n")

## Prepare data for did package
## Need: id, time, treatment_group (cohort year, 0 for never-treated)
panel_did <- copy(panel)
panel_did[, id_num := as.integer(as.factor(circ_id))]
panel_did[is.na(cohort), cohort := 0L]

## CS-DiD
cs_enp <- tryCatch({
  did::att_gt(
    yname = "enp",
    tname = "year",
    idname = "id_num",
    gname = "cohort",
    data = as.data.frame(panel_did),
    control_group = "notyettreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_enp)) {
  cat("\nCS-DiD group-time ATTs for ENP:\n")
  print(summary(cs_enp))

  ## Aggregate to simple ATT
  cs_agg_enp <- did::aggte(cs_enp, type = "simple")
  cat("\nAggregate ATT (ENP):", round(cs_agg_enp$overall.att, 3),
      "SE:", round(cs_agg_enp$overall.se, 3), "\n")

  ## Dynamic effects
  cs_dyn_enp <- did::aggte(cs_enp, type = "dynamic")

  ## Save
  dyn_dt <- data.table(
    egt = cs_dyn_enp$egt,
    att = cs_dyn_enp$att.egt,
    se = cs_dyn_enp$se.egt
  )
  fwrite(dyn_dt, file.path(data_dir, "cs_dynamic_enp.csv"))
}

## CS-DiD for RN share
cs_rn <- tryCatch({
  did::att_gt(
    yname = "rn_share",
    tname = "year",
    idname = "id_num",
    gname = "cohort",
    data = as.data.frame(panel_did),
    control_group = "notyettreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD RN failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_rn)) {
  cs_agg_rn <- did::aggte(cs_rn, type = "simple")
  cat("\nAggregate ATT (RN share):", round(cs_agg_rn$overall.att, 4),
      "SE:", round(cs_agg_rn$overall.se, 4), "\n")

  cs_dyn_rn <- did::aggte(cs_rn, type = "dynamic")
  dyn_rn <- data.table(
    egt = cs_dyn_rn$egt,
    att = cs_dyn_rn$att.egt,
    se = cs_dyn_rn$se.egt
  )
  fwrite(dyn_rn, file.path(data_dir, "cs_dynamic_rn.csv"))
}

## ============================================================
## 2. Placebo outcomes
## ============================================================
cat("\n=== Placebo: Turnout ===\n")

## Turnout should not change differentially (or if anything, increase)
m_placebo <- fixest::feols(turnout_rate ~ post | circ_id + year,
                           data = panel, cluster = ~circ_id)
cat("Placebo (turnout):\n")
print(summary(m_placebo))

## ============================================================
## 3. Donut specification: exclude commuting belt
## ============================================================
cat("\n=== Donut: Exclude partial ZFE overlap ===\n")

## Exclude constituencies with 0 < ZFE share < 0.5 (commuting belt)
panel_donut <- panel[zfe_area_share == 0 | zfe_area_share >= 0.5]
m_donut <- fixest::feols(enp ~ post | circ_id + year,
                         data = panel_donut, cluster = ~circ_id)
cat("Donut ENP:\n")
print(summary(m_donut))

## ============================================================
## 4. Wave-specific pre-trends
## ============================================================
cat("\n=== Wave-specific pre-trend tests ===\n")

## Only Wave 1 (treated by 2022)
panel_w1 <- panel[wave == 1 | treated_group == 0]
m_w1 <- fixest::feols(enp ~ i(year, treated_group, ref = 2017) | circ_id + year,
                       data = panel_w1, cluster = ~circ_id)
cat("Wave 1 event study:\n")
print(summary(m_w1))

## Save all robustness coefficients
rob_w1 <- as.data.table(fixest::coeftable(m_w1), keep.rownames = "term")
rob_w1[, spec := "Wave 1 only"]
fwrite(rob_w1, file.path(data_dir, "robustness_wave1_es.csv"))

## ============================================================
## 5. Randomization Inference
## ============================================================
cat("\n=== Randomization Inference ===\n")

## Permute treatment assignment 500 times
set.seed(42)
n_perms <- 500
true_coef <- coef(fixest::feols(enp ~ post | circ_id + year, data = panel))["post"]

perm_coefs <- numeric(n_perms)
circ_ids <- unique(panel$circ_id)
n_treated <- sum(unique(panel[treated_group == 1, circ_id]) %in% circ_ids)

for (i in seq_len(n_perms)) {
  ## Randomly assign treatment to same number of constituencies
  fake_treated <- sample(circ_ids, n_treated)
  panel_perm <- copy(panel)
  panel_perm[, fake_treat := as.integer(circ_id %in% fake_treated)]
  panel_perm[, fake_post := fake_treat * as.integer(year >= 2022)]

  m_perm <- tryCatch(
    fixest::feols(enp ~ fake_post | circ_id + year, data = panel_perm),
    error = function(e) NULL
  )
  perm_coefs[i] <- if (!is.null(m_perm)) coef(m_perm)["fake_post"] else NA
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(true_coef), na.rm = TRUE)
cat("RI p-value for ENP:", ri_pvalue, "\n")
cat("True coefficient:", round(true_coef, 3), "\n")
cat("Permutation 95th percentile:", round(quantile(perm_coefs, 0.975, na.rm = TRUE), 3), "\n")

ri_dt <- data.table(perm_coef = perm_coefs)
ri_dt <- ri_dt[!is.na(perm_coef)]
fwrite(ri_dt, file.path(data_dir, "ri_permutation_distribution.csv"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
