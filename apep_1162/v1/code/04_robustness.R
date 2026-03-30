# 04_robustness.R — Robustness checks and synthetic control
# apep_1162: Belgium SSC Cut and Employment

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel   <- readRDS("panel.rds")
results <- readRDS("results.rds")

# ─────────────────────────────────────────────────────────────
# 1. EXPANDED CONTROL GROUP
#    Add AT, FR, DK, FI, SE as additional controls
# ─────────────────────────────────────────────────────────────

cat("=== Robustness: Expanded control group ===\n")

expanded <- panel |> filter(geo %in% c("BE", "NL", "DE", "LU", "AT", "FR", "DK", "FI", "SE"))

m_expanded <- feols(log_emp ~ belgium:post | cs_id + time_id,
                    data = expanded, cluster = ~geo)
cat("Expanded controls:\n")
print(summary(m_expanded))

# ─────────────────────────────────────────────────────────────
# 2. PERMUTATION TEST (placebo countries)
#    Assign treatment to each control country, estimate DiD
#    Belgium's coefficient should be extreme in distribution
# ─────────────────────────────────────────────────────────────

cat("\n=== Permutation Test ===\n")

control_countries <- setdiff(unique(expanded$geo), "BE")
perm_coefs <- numeric(length(control_countries))
names(perm_coefs) <- control_countries

for (cc in control_countries) {
  perm_data <- expanded |>
    filter(geo %in% c(cc, setdiff(control_countries, cc))) |>
    mutate(placebo_treat = as.integer(geo == cc))

  perm_fit <- tryCatch(
    feols(log_emp ~ placebo_treat:post | cs_id + time_id,
          data = perm_data, cluster = ~geo),
    error = function(e) NULL
  )

  if (!is.null(perm_fit)) {
    coef_name <- grep("placebo_treat.*post", names(coef(perm_fit)), value = TRUE)
    if (length(coef_name) > 0) {
      perm_coefs[cc] <- coef(perm_fit)[coef_name[1]]
    }
  }
}

# Belgium's actual coefficient
be_coef <- coef(results$m1)[grep("belgium.*post", names(coef(results$m1)))[1]]

cat(sprintf("Belgium coefficient: %.4f\n", be_coef))
cat("Permutation distribution:\n")
print(sort(perm_coefs))
perm_pval <- mean(abs(perm_coefs) >= abs(be_coef))
cat(sprintf("Permutation p-value (two-sided): %.3f\n", perm_pval))

# ─────────────────────────────────────────────────────────────
# 3. AUGMENTED SYNTHETIC CONTROL (SCM)
# ─────────────────────────────────────────────────────────────

cat("\n=== Augmented Synthetic Control ===\n")

# Aggregate to country-quarter level for SCM
scm_data <- panel |>
  filter(geo %in% c("BE", "NL", "DE", "LU", "AT", "FR", "DK", "FI", "SE")) |>
  group_by(geo, time_id, yq) |>
  summarise(log_emp = log(sum(emp, na.rm = TRUE)), .groups = "drop") |>
  mutate(belgium = as.integer(geo == "BE"),
         post = as.integer(yq >= 2016.25))

# Ridge-augmented SCM
scm_fit <- tryCatch({
  augsynth(
    log_emp ~ belgium,
    unit = geo,
    time = time_id,
    data = scm_data,
    progfunc = "Ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat(sprintf("  SCM failed: %s\n", e$message))
  NULL
})

if (!is.null(scm_fit)) {
  scm_summ <- summary(scm_fit)
  cat("SCM ATT estimate:\n")
  print(scm_summ)
  saveRDS(scm_fit, "scm_fit.rds")
} else {
  cat("  SCM estimation failed — proceeding without.\n")
}

# ─────────────────────────────────────────────────────────────
# 4. PLACEBO OUTCOME: Public sector employment (O-Q)
#    Public sector should NOT respond to employer SSC cuts
#    (government is not profit-maximizing)
# ─────────────────────────────────────────────────────────────

cat("\n=== Placebo: Public Sector Employment ===\n")

primary <- panel |> filter(geo %in% c("BE", "NL", "DE", "LU"))

m_placebo_pub <- feols(
  log_emp ~ belgium:post | cs_id + time_id,
  data = primary |> filter(nace == "O-Q"),
  cluster = ~geo
)
cat("Public sector (O-Q) placebo:\n")
print(summary(m_placebo_pub))

# ─────────────────────────────────────────────────────────────
# 5. PLACEBO OUTCOME: Real estate (L)
#    Capital-intensive sector — minimal labor cost channel
# ─────────────────────────────────────────────────────────────

cat("\n=== Placebo: Real Estate ===\n")

m_placebo_re <- feols(
  log_emp ~ belgium:post | cs_id + time_id,
  data = primary |> filter(nace == "L"),
  cluster = ~geo
)
cat("Real estate (L) placebo:\n")
print(summary(m_placebo_re))

# ─────────────────────────────────────────────────────────────
# 6. EXCLUDING SECTORS ONE AT A TIME (leave-one-out)
# ─────────────────────────────────────────────────────────────

cat("\n=== Leave-One-Sector-Out ===\n")

sectors <- unique(primary$nace)
loo_coefs <- numeric(length(sectors))
names(loo_coefs) <- sectors

for (s in sectors) {
  loo_fit <- feols(log_emp ~ belgium:post | cs_id + time_id,
                   data = primary |> filter(nace != s),
                   cluster = ~geo)
  coef_name <- grep("belgium.*post", names(coef(loo_fit)), value = TRUE)
  if (length(coef_name) > 0) loo_coefs[s] <- coef(loo_fit)[coef_name[1]]
}

cat("Leave-one-sector-out coefficients:\n")
print(round(loo_coefs, 4))

# ─────────────────────────────────────────────────────────────
# Save robustness results
# ─────────────────────────────────────────────────────────────

robustness <- list(
  m_expanded = m_expanded,
  perm_coefs = perm_coefs,
  perm_pval = perm_pval,
  be_coef = be_coef,
  scm_fit = if (exists("scm_fit") && !is.null(scm_fit)) scm_fit else NULL,
  m_placebo_pub = m_placebo_pub,
  m_placebo_re = m_placebo_re,
  loo_coefs = loo_coefs
)
saveRDS(robustness, "robustness.rds")

cat("\nRobustness results saved.\n")
