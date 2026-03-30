# 03_main_analysis.R — Main DiD and triple-difference analysis
# apep_1162: Belgium SSC Cut and Employment

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel <- readRDS("panel.rds")
lci   <- readRDS("lci.rds")
comp  <- readRDS("comp.rds")

# ─────────────────────────────────────────────────────────────
# 1. FIRST STAGE: Non-wage cost divergence
#    Confirm Belgium's non-wage costs fell relative to controls
# ─────────────────────────────────────────────────────────────

cat("=== First Stage: Non-wage Cost Index ===\n")

# Normalize to 2015-Q4 = 100 for each country
lci_norm <- lci |>
  group_by(geo) |>
  mutate(
    base_nw = nonwage_index[which.min(abs(yq - 2015.75))],
    base_w  = wage_index[which.min(abs(yq - 2015.75))],
    nw_norm = nonwage_index / base_nw * 100,
    w_norm  = wage_index / base_w * 100
  ) |>
  ungroup()

# DiD on non-wage cost index
lci_did <- lci_norm |>
  mutate(belgium = as.integer(geo == "BE"),
         post = as.integer(yq >= 2016.25))

fs_model <- feols(nw_norm ~ belgium:post | geo + yq, data = lci_did)
cat("First stage (non-wage costs, BE vs controls):\n")
print(summary(fs_model))

# ─────────────────────────────────────────────────────────────
# 2. MAIN RESULT: Cross-country DiD on employment
#    Belgium vs NL, DE, LU
# ─────────────────────────────────────────────────────────────

cat("\n=== Main Results: Employment DiD ===\n")

# Primary sample: BE, NL, DE, LU (close economic peers)
primary <- panel |> filter(geo %in% c("BE", "NL", "DE", "LU"))

# Model 1: Simple DiD (no sector heterogeneity)
m1 <- feols(log_emp ~ belgium:post | cs_id + time_id,
            data = primary, cluster = ~geo)

# Model 2: Full treatment (post-2018 only)
m2 <- feols(log_emp ~ belgium:full_post | cs_id + time_id,
            data = primary, cluster = ~geo)

# Model 3: Phase-in — separate early and full treatment
m3 <- feols(log_emp ~ belgium:i(post, ref = 0) + belgium:i(full_post, ref = 0) |
              cs_id + time_id,
            data = primary |> mutate(
              early_post = as.integer(yq >= 2016.25 & yq < 2018.0)
            ),
            cluster = ~geo)

# Model 3 rewrite: early vs full treatment properly
primary <- primary |>
  mutate(
    phase1 = as.integer(yq >= 2016.25 & yq < 2018.0),  # Partial cut (30%)
    phase2 = as.integer(yq >= 2018.0)                    # Full cut (25%)
  )
m3 <- feols(log_emp ~ belgium:phase1 + belgium:phase2 | cs_id + time_id,
            data = primary, cluster = ~geo)

cat("Model 1: Simple DiD (any post)\n")
print(summary(m1))
cat("\nModel 2: Full treatment (post-2018)\n")
print(summary(m2))
cat("\nModel 3: Phase-in (partial vs full)\n")
print(summary(m3))

# ─────────────────────────────────────────────────────────────
# 3. TRIPLE-DIFFERENCE: Country × Labor Intensity × Post
#    Higher labor_share sectors should benefit more
# ─────────────────────────────────────────────────────────────

cat("\n=== Triple-Difference: Sector Labor Intensity ===\n")

# Model 4: Triple-diff with labor intensity interaction
m4 <- feols(log_emp ~ belgium:post:labor_intensity_z + belgium:post |
              cs_id + time_id,
            data = primary, cluster = ~geo)

cat("Model 4: Triple-diff (labor intensity interaction)\n")
print(summary(m4))

# ─────────────────────────────────────────────────────────────
# 4. EVENT STUDY: Pre-trend check
#    Relative time dummies for Belgium × quarter
# ─────────────────────────────────────────────────────────────

cat("\n=== Event Study: Pre-trend Check ===\n")

# Create relative time to treatment (2016-Q2 = 0)
primary <- primary |>
  mutate(
    rel_time = round((yq - 2016.25) * 4),  # Quarters since treatment
    rel_time_f = factor(rel_time)
  )

# Event study with 2016-Q1 (rel_time = -1) as reference
m_es <- feols(log_emp ~ i(rel_time, belgium, ref = -1) | cs_id + time_id,
              data = primary, cluster = ~geo)

cat("Event study coefficients:\n")
print(coeftable(m_es))

# ─────────────────────────────────────────────────────────────
# 5. EMPLOYER SSC SHARE: Confirm mechanism
#    Belgium's employer SSC share should decline
# ─────────────────────────────────────────────────────────────

cat("\n=== Mechanism: Employer SSC Share ===\n")

comp_panel <- comp |>
  filter(geo %in% c("BE", "NL", "DE", "LU"), !is.na(ssc_share)) |>
  mutate(
    belgium = as.integer(geo == "BE"),
    post = as.integer(yq >= 2016.25),
    cs_id = paste(geo, nace, sep = "_"),
    time_id = as.integer(factor(yq))
  )

m_ssc <- feols(ssc_share ~ belgium:post | cs_id + time_id,
               data = comp_panel, cluster = ~geo)

cat("SSC share DiD:\n")
print(summary(m_ssc))

# ─────────────────────────────────────────────────────────────
# 6. WAGE CHECK: Wages should NOT respond (rigidity mechanism)
# ─────────────────────────────────────────────────────────────

cat("\n=== Wage Rigidity Check ===\n")

lci_wage <- lci_norm |>
  mutate(belgium = as.integer(geo == "BE"),
         post = as.integer(yq >= 2016.25))

m_wage <- feols(w_norm ~ belgium:post | geo + yq, data = lci_wage)

cat("Wage index DiD:\n")
print(summary(m_wage))

# ─────────────────────────────────────────────────────────────
# Save results
# ─────────────────────────────────────────────────────────────

results <- list(
  fs = fs_model,
  m1 = m1,
  m2 = m2,
  m3 = m3,
  m4 = m4,
  m_es = m_es,
  m_ssc = m_ssc,
  m_wage = m_wage
)
saveRDS(results, "results.rds")

# Write diagnostics.json for validator
# Use A*21 LFS panel for treated unit count (finer sector detail)
lfs_a21 <- readRDS("lfs_a21.rds")
lfs_primary <- lfs_a21 |> filter(geo %in% c("BE", "NL", "DE", "LU")) |>
  mutate(belgium = as.integer(geo == "BE"),
         cs_id = paste(geo, nace1, sep = "_"))
n_treated <- n_distinct(lfs_primary$cs_id[lfs_primary$belgium == 1])
n_pre <- sum(sort(unique(primary$yq)) < 2016.25)
n_obs <- nrow(primary) + nrow(lfs_primary)
jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "diagnostics.json", auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Results saved to results.rds\n")
