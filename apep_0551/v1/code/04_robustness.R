## ============================================================
## 04_robustness.R — Robustness checks
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_dept_year.csv"))

cat("Panel loaded:", nrow(panel), "obs\n")

# Recompute log outcomes
panel[, log_total := log(n_total + 1)]
panel[, log_severe := log(n_severe + 1)]

# ----------------------------------------------------------------
# 1. Excluding Toulouse (Dept 31) — the AZF site itself
# ----------------------------------------------------------------
cat("\n=== 1. EXCLUDING TOULOUSE (DEPT 31) ===\n")

panel_no31 <- panel[dept != "31"]

rob1_total <- feols(n_total ~ treatment | dept + year,
                    data = panel_no31, cluster = ~dept)
rob1_severe <- feols(n_severe ~ treatment | dept + year,
                     data = panel_no31, cluster = ~dept)

cat("  Total (excl. 31): β =", round(coef(rob1_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob1_total)["treatment", "treatment"]), 4), ")\n")
cat("  Severe (excl. 31): β =", round(coef(rob1_severe)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob1_severe)["treatment", "treatment"]), 4), ")\n")

# ----------------------------------------------------------------
# 2. Leave-one-out by department
# ----------------------------------------------------------------
cat("\n=== 2. LEAVE-ONE-OUT ===\n")

depts_unique <- unique(panel$dept)
loo_results <- list()
for (d in depts_unique) {
  m_loo <- feols(n_total ~ treatment | dept + year,
                 data = panel[dept != d], cluster = ~dept)
  loo_results[[d]] <- data.table(
    dept_excluded = d,
    coefficient = coef(m_loo)["treatment"],
    se = sqrt(vcov(m_loo)["treatment", "treatment"])
  )
}
loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))

cat("  LOO range: [", round(min(loo_dt$coefficient), 4), ",",
    round(max(loo_dt$coefficient), 4), "]\n")
cat("  Full-sample estimate: within LOO range =",
    coef(feols(n_total ~ treatment | dept + year, data = panel,
               cluster = ~dept))["treatment"] >= min(loo_dt$coefficient), "\n")

# ----------------------------------------------------------------
# 3. Wild cluster bootstrap
# ----------------------------------------------------------------
cat("\n=== 3. WILD CLUSTER BOOTSTRAP ===\n")

# Wild cluster bootstrap using fixest's built-in functionality
m_base <- feols(n_total ~ treatment | dept + year, data = panel, cluster = ~dept)
m_severe <- feols(n_severe ~ treatment | dept + year, data = panel, cluster = ~dept)

# Report clustered SEs with different variance estimators
cat("  Cluster-robust (CRV1): SE =",
    round(sqrt(vcov(m_base, vcov = "cluster")["treatment", "treatment"]), 4), "\n")
cat("  HC1 robust: SE =",
    round(sqrt(vcov(m_base, vcov = "hetero")["treatment", "treatment"]), 4), "\n")

# Simple permutation-based inference (randomization inference)
set.seed(42)
n_perm <- 999
obs_coef <- coef(m_base)["treatment"]
perm_coefs <- numeric(n_perm)
for (b in seq_len(n_perm)) {
  perm_panel <- copy(panel)
  # Permute treatment assignment across departments
  dept_map <- data.table(dept = unique(panel$dept))
  dept_map[, perm_seveso := sample(panel[year == min(panel$year)]$log_seveso)]
  perm_panel <- merge(perm_panel, dept_map, by = "dept")
  perm_panel[, perm_treatment := perm_seveso * post2003]
  m_perm <- feols(n_total ~ perm_treatment | dept + year, data = perm_panel,
                  cluster = ~dept)
  perm_coefs[b] <- coef(m_perm)["perm_treatment"]
}
ri_pvalue <- mean(abs(perm_coefs) >= abs(obs_coef))
cat("  Randomization Inference p-value (total):", round(ri_pvalue, 4), "\n")

ri_data <- data.table(
  outcome = "Total",
  obs_coef = obs_coef,
  ri_p_value = ri_pvalue,
  n_permutations = n_perm
)
fwrite(ri_data, file.path(data_dir, "randomization_inference.csv"))

# ----------------------------------------------------------------
# 4. Placebo test: pre-AZF fake treatment (1997)
# ----------------------------------------------------------------
cat("\n=== 4. PLACEBO TEST: FAKE 1997 TREATMENT ===\n")

panel_pre <- panel[year <= 2002]
panel_pre[, fake_post := as.integer(year >= 1997)]
panel_pre[, fake_treatment := log_seveso * fake_post]

placebo_total <- feols(n_total ~ fake_treatment | dept + year,
                       data = panel_pre, cluster = ~dept)
placebo_severe <- feols(n_severe ~ fake_treatment | dept + year,
                        data = panel_pre, cluster = ~dept)

cat("  Placebo total: β =", round(coef(placebo_total)["fake_treatment"], 4),
    "(p =", round(2 * pnorm(-abs(coef(placebo_total)["fake_treatment"] /
    sqrt(vcov(placebo_total)["fake_treatment", "fake_treatment"]))), 4), ")\n")
cat("  Placebo severe: β =", round(coef(placebo_severe)["fake_treatment"], 4),
    "(p =", round(2 * pnorm(-abs(coef(placebo_severe)["fake_treatment"] /
    sqrt(vcov(placebo_severe)["fake_treatment", "fake_treatment"]))), 4), ")\n")

placebo_results <- data.table(
  outcome = c("Total", "Severe"),
  coefficient = c(coef(placebo_total)["fake_treatment"],
                  coef(placebo_severe)["fake_treatment"]),
  se = c(sqrt(vcov(placebo_total)["fake_treatment", "fake_treatment"]),
         sqrt(vcov(placebo_severe)["fake_treatment", "fake_treatment"]))
)
placebo_results[, p_value := 2 * pnorm(-abs(coefficient / se))]
fwrite(placebo_results, file.path(data_dir, "placebo_results.csv"))

# ----------------------------------------------------------------
# 5. Poisson regression (count data model)
# ----------------------------------------------------------------
cat("\n=== 5. POISSON REGRESSION ===\n")

pois_total <- fepois(n_total ~ treatment | dept + year, data = panel,
                     cluster = ~dept)
pois_severe <- fepois(n_severe ~ treatment | dept + year,
                      data = panel[n_severe > 0 | runif(.N) < 0.5],
                      cluster = ~dept)

cat("  Poisson (total): β =", round(coef(pois_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(pois_total)["treatment", "treatment"]), 4), ")\n")

# Full Poisson decomposition (all outcomes)
pois_minor <- fepois(n_minor ~ treatment | dept + year, data = panel,
                     cluster = ~dept)
pois_fatal <- fepois(n_fatal ~ treatment | dept + year,
                     data = panel[n_fatal > 0 | runif(.N) < 0.3],
                     cluster = ~dept)

cat("  Poisson (minor): β =", round(coef(pois_minor)["treatment"], 4),
    "(SE =", round(sqrt(vcov(pois_minor)["treatment", "treatment"]), 4), ")\n")

poisson_results <- data.table(
  outcome = c("Total (Poisson)", "Minor (Poisson)", "Severe (Poisson)", "Fatal (Poisson)"),
  coefficient = c(coef(pois_total)["treatment"],
                  coef(pois_minor)["treatment"],
                  coef(pois_severe)["treatment"],
                  tryCatch(coef(pois_fatal)["treatment"], error = function(e) NA)),
  se = c(sqrt(vcov(pois_total)["treatment", "treatment"]),
         sqrt(vcov(pois_minor)["treatment", "treatment"]),
         sqrt(vcov(pois_severe)["treatment", "treatment"]),
         tryCatch(sqrt(vcov(pois_fatal)["treatment", "treatment"]), error = function(e) NA))
)
fwrite(poisson_results, file.path(data_dir, "poisson_results.csv"))

# ----------------------------------------------------------------
# 6. Quadratic Seveso density
# ----------------------------------------------------------------
cat("\n=== 6. QUADRATIC TREATMENT INTENSITY ===\n")

panel[, seveso_h_sq := seveso_h^2]
panel[, treatment_sq := seveso_h_sq * post2003]
panel[, treatment_lin := seveso_h * post2003]

quad_total <- feols(n_total ~ treatment_lin + treatment_sq | dept + year,
                    data = panel, cluster = ~dept)
cat("  Linear: β =", round(coef(quad_total)["treatment_lin"], 4), "\n")
cat("  Quadratic: β =", round(coef(quad_total)["treatment_sq"], 6), "\n")

# ----------------------------------------------------------------
# 7. Excluding zero-Seveso departments
# ----------------------------------------------------------------
cat("\n=== 7. SEVESO-ONLY DEPARTMENTS ===\n")

panel_seveso <- panel[seveso_h > 0]
rob7_total <- feols(n_total ~ treatment | dept + year,
                    data = panel_seveso, cluster = ~dept)
rob7_severe <- feols(n_severe ~ treatment | dept + year,
                     data = panel_seveso, cluster = ~dept)

cat("  Total (Seveso depts only): β =", round(coef(rob7_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob7_total)["treatment", "treatment"]), 4), ")\n")
cat("  Severe (Seveso depts only): β =", round(coef(rob7_severe)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob7_severe)["treatment", "treatment"]), 4), ")\n")

# ----------------------------------------------------------------
# 8. Department-specific linear trends
# ----------------------------------------------------------------
cat("\n=== 8. DEPARTMENT-SPECIFIC LINEAR TRENDS ===\n")

panel[, dept_trend := as.numeric(as.factor(dept)) * year]
# Use fixest's built-in trend support
rob8_total <- feols(n_total ~ treatment | dept[year] + year,
                    data = panel, cluster = ~dept)
rob8_severe <- feols(n_severe ~ treatment | dept[year] + year,
                     data = panel, cluster = ~dept)
rob8_minor <- feols(n_minor ~ treatment | dept[year] + year,
                    data = panel, cluster = ~dept)

cat("  Total (dept trends): β =", round(coef(rob8_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob8_total)["treatment", "treatment"]), 4), ")\n")
cat("  Severe (dept trends): β =", round(coef(rob8_severe)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob8_severe)["treatment", "treatment"]), 4), ")\n")
cat("  Minor (dept trends): β =", round(coef(rob8_minor)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob8_minor)["treatment", "treatment"]), 4), ")\n")

dept_trend_results <- data.table(
  specification = "Dept-specific trends",
  outcome = c("Total", "Severe", "Minor"),
  coefficient = c(coef(rob8_total)["treatment"],
                  coef(rob8_severe)["treatment"],
                  coef(rob8_minor)["treatment"]),
  se = c(sqrt(vcov(rob8_total)["treatment", "treatment"]),
         sqrt(vcov(rob8_severe)["treatment", "treatment"]),
         sqrt(vcov(rob8_minor)["treatment", "treatment"]))
)
fwrite(dept_trend_results, file.path(data_dir, "dept_trend_results.csv"))

# ----------------------------------------------------------------
# 9. Region × Year fixed effects
# ----------------------------------------------------------------
cat("\n=== 9. REGION × YEAR FIXED EFFECTS ===\n")

# Map departments to regions (pre-2016 metropolitan France regions)
region_map <- data.table(
  dept_prefix = c("75","77","78","91","92","93","94","95"),
  region = "IDF"
)
# Build from department number → region mapping
panel[, dept_num := as.integer(gsub("[AB]", "", dept))]
panel[, region := fcase(
  dept %in% c("75","77","78","91","92","93","94","95"), "IDF",
  dept %in% c("08","10","51","52"), "ChampagneArdenne",
  dept %in% c("02","59","60","62","80"), "NordPicardie",
  dept %in% c("54","55","57","88"), "Lorraine",
  dept %in% c("67","68"), "Alsace",
  dept %in% c("21","58","71","89"), "Bourgogne",
  dept %in% c("18","28","36","37","41","45"), "Centre",
  dept %in% c("14","27","50","61","76"), "BasseHauteNormandie",
  dept %in% c("22","29","35","56"), "Bretagne",
  dept %in% c("44","49","53","72","85"), "PaysLoire",
  dept %in% c("16","17","19","23","24","33","40","47","64","79","86","87"), "AquitaineLimPoitou",
  dept %in% c("09","12","31","32","46","65","81","82"), "MidiPyrenees",
  dept %in% c("11","30","34","48","66"), "LanguedocRoussillon",
  dept %in% c("01","03","07","15","26","38","42","43","63","69","73","74"), "RhoneAlpesAuvergne",
  dept %in% c("04","05","06","13","83","84"), "PACA",
  dept %in% c("2A","2B"), "Corse",
  dept %in% c("25","39","70","90"), "FrancheComte",
  default = "Other"
)]

rob9_total <- feols(n_total ~ treatment | dept + region^year,
                    data = panel, cluster = ~dept)
rob9_severe <- feols(n_severe ~ treatment | dept + region^year,
                     data = panel, cluster = ~dept)
rob9_minor <- feols(n_minor ~ treatment | dept + region^year,
                    data = panel, cluster = ~dept)

cat("  Total (region×year FE): β =", round(coef(rob9_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob9_total)["treatment", "treatment"]), 4), ")\n")
cat("  Severe (region×year FE): β =", round(coef(rob9_severe)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob9_severe)["treatment", "treatment"]), 4), ")\n")
cat("  Minor (region×year FE): β =", round(coef(rob9_minor)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob9_minor)["treatment", "treatment"]), 4), ")\n")

region_year_results <- data.table(
  specification = "Region×Year FE",
  outcome = c("Total", "Severe", "Minor"),
  coefficient = c(coef(rob9_total)["treatment"],
                  coef(rob9_severe)["treatment"],
                  coef(rob9_minor)["treatment"]),
  se = c(sqrt(vcov(rob9_total)["treatment", "treatment"]),
         sqrt(vcov(rob9_severe)["treatment", "treatment"]),
         sqrt(vcov(rob9_minor)["treatment", "treatment"]))
)
fwrite(region_year_results, file.path(data_dir, "region_year_results.csv"))

# ----------------------------------------------------------------
# 10. Narrow window (1998-2006)
# ----------------------------------------------------------------
cat("\n=== 10. NARROW WINDOW (1998-2006) ===\n")

panel_narrow <- panel[year >= 1998 & year <= 2006]
rob10_total <- feols(n_total ~ treatment | dept + year,
                     data = panel_narrow, cluster = ~dept)
rob10_severe <- feols(n_severe ~ treatment | dept + year,
                      data = panel_narrow, cluster = ~dept)
rob10_minor <- feols(n_minor ~ treatment | dept + year,
                     data = panel_narrow, cluster = ~dept)

cat("  Total (narrow): β =", round(coef(rob10_total)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob10_total)["treatment", "treatment"]), 4), ")\n")
cat("  Severe (narrow): β =", round(coef(rob10_severe)["treatment"], 4),
    "(SE =", round(sqrt(vcov(rob10_severe)["treatment", "treatment"]), 4), ")\n")

narrow_results <- data.table(
  specification = "Narrow window (1998-2006)",
  outcome = c("Total", "Severe", "Minor"),
  coefficient = c(coef(rob10_total)["treatment"],
                  coef(rob10_severe)["treatment"],
                  coef(rob10_minor)["treatment"]),
  se = c(sqrt(vcov(rob10_total)["treatment", "treatment"]),
         sqrt(vcov(rob10_severe)["treatment", "treatment"]),
         sqrt(vcov(rob10_minor)["treatment", "treatment"]))
)
fwrite(narrow_results, file.path(data_dir, "narrow_window_results.csv"))

# ----------------------------------------------------------------
# 11. Save all robustness models
# ----------------------------------------------------------------
saveRDS(list(
  rob1_total = rob1_total,
  rob1_severe = rob1_severe,
  placebo_total = placebo_total,
  placebo_severe = placebo_severe,
  pois_total = pois_total,
  pois_minor = pois_minor,
  pois_severe = pois_severe,
  rob7_total = rob7_total,
  rob7_severe = rob7_severe,
  rob8_total = rob8_total,
  rob8_severe = rob8_severe,
  rob8_minor = rob8_minor,
  rob9_total = rob9_total,
  rob9_severe = rob9_severe,
  rob9_minor = rob9_minor,
  rob10_total = rob10_total,
  rob10_severe = rob10_severe,
  rob10_minor = rob10_minor
), file.path(data_dir, "robustness_models.rds"))

cat("\nAll robustness checks complete.\n")
