# 03_main_analysis.R — Primary regressions
# apep_1282: The Double Squeeze

source("00_packages.R")
load("../data/analysis_panel.RData")

cat("=== Main Analysis ===\n")

# ------------------------------------------------------------------
# Phase 1: Fornero effect on youth employment (2005-2018)
# ------------------------------------------------------------------
cat("\n--- Phase 1: Fornero continuous DiD (2005-2018) ---\n")

panel_p1 <- panel |> filter(year <= 2018)

# NEET rate
m1_neet <- feols(neet_rate ~ fornero_x_post_sd | region + year,
                 data = panel_p1, cluster = ~region)

# Youth employment
m1_emp <- feols(emp_youth ~ fornero_x_post_sd | region + year,
                data = panel_p1, cluster = ~region)

cat("Phase 1 — Fornero bite × Post on NEET:\n")
summary(m1_neet)
cat("Phase 1 — Fornero bite × Post on Youth Employment:\n")
summary(m1_emp)

# ------------------------------------------------------------------
# Phase 2: Full triple-difference (2005-2023)
# ------------------------------------------------------------------
cat("\n--- Phase 2: Triple-difference (2005-2023) ---\n")

# Main spec: NEET rate
m2_neet <- feols(neet_rate ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                 | region + year,
                 data = panel, cluster = ~region)

# Main spec: Youth employment
m2_emp <- feols(emp_youth ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                | region + year,
                data = panel, cluster = ~region)

# Young adult employment (25-34)
m2_ya <- feols(emp_young_adult ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
               | region + year,
               data = panel, cluster = ~region)

cat("Phase 2 — Triple on NEET:\n")
summary(m2_neet)
cat("Phase 2 — Triple on Youth Employment:\n")
summary(m2_emp)
cat("Phase 2 — Triple on Young Adult Employment (25-34):\n")
summary(m2_ya)

# ------------------------------------------------------------------
# Event study: Fornero bite interaction with year dummies
# ------------------------------------------------------------------
cat("\n--- Event study: Fornero bite × year ---\n")

panel <- panel |>
  mutate(
    year_factor = factor(year),
    # Exclude 2011 as reference year (pre-Fornero)
    year_factor = relevel(year_factor, ref = "2011")
  )

# Event study for Fornero effect on NEET
es_fornero <- feols(neet_rate ~ i(year, fornero_bite_sd, ref = 2011) | region + year,
                    data = panel, cluster = ~region)

cat("Event study — Fornero bite × year on NEET:\n")
summary(es_fornero)

# ------------------------------------------------------------------
# Wild cluster bootstrap for main coefficients
# ------------------------------------------------------------------
cat("\n--- Wild cluster bootstrap (main spec) ---\n")

# Bootstrap the triple interaction coefficient
set.seed(42)
boot_neet <- tryCatch({
  boottest(m2_neet, param = "triple_sd", clustid = "region",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_neet)) {
  cat(sprintf("Triple (NEET) — WCB p-value: %.4f, CI: [%.3f, %.3f]\n",
              boot_neet$p_val, boot_neet$conf_int[1], boot_neet$conf_int[2]))
}

boot_emp <- tryCatch({
  boottest(m2_emp, param = "triple_sd", clustid = "region",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_emp)) {
  cat(sprintf("Triple (Youth Emp) — WCB p-value: %.4f, CI: [%.3f, %.3f]\n",
              boot_emp$p_val, boot_emp$conf_int[1], boot_emp$conf_int[2]))
}

# ------------------------------------------------------------------
# Save results
# ------------------------------------------------------------------
results <- list(
  phase1_neet = m1_neet,
  phase1_emp = m1_emp,
  phase2_neet = m2_neet,
  phase2_emp = m2_emp,
  phase2_ya = m2_ya,
  event_study = es_fornero,
  boot_neet = boot_neet,
  boot_emp = boot_emp
)

save(results, panel, file = "../data/results.RData")

# ------------------------------------------------------------------
# Write diagnostics.json
# ------------------------------------------------------------------
n_treated_fornero <- sum(panel$fornero_bite[!duplicated(panel$region)] >
                         median(panel$fornero_bite[!duplicated(panel$region)]))
n_pre_fornero <- sum(unique(panel$year) < 2012)

diagnostics <- list(
  n_treated = as.integer(n_distinct(panel$region)),  # All regions have continuous treatment
  n_pre = as.integer(n_pre_fornero),
  n_obs = as.integer(nrow(panel)),
  n_regions = as.integer(n_distinct(panel$region)),
  n_years = as.integer(n_distinct(panel$year)),
  method = "Continuous DiD with triple interaction",
  outcomes = c("NEET rate 18-24", "Employment rate 15-24", "Employment rate 25-34")
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")
cat("All results saved.\n")
