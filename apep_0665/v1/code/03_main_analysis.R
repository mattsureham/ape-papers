## 03_main_analysis.R — Main DiD analysis
## apep_0665: Fornero pension reform

source("code/00_packages.R")
panel <- readRDS("data/panel.rds")

cat("=== Main Analysis ===\n")

## ---- 1. Main DiD: GFCF response to Fornero bite ----
# Continuous treatment: bite × post
m1 <- feols(ln_gfcf ~ treat_intensity | region + year,
            data = panel, cluster = ~region)
cat("M1 (GFCF ~ bite × post):\n"); print(summary(m1))

# Standardized bite
m1s <- feols(ln_gfcf ~ treat_std | region + year,
             data = panel, cluster = ~region)
cat("\nM1s (standardized bite):\n"); print(summary(m1s))

## ---- 2. Manufacturing vs services ----
m2_mfg <- feols(ln_gfcf_mfg ~ treat_intensity | region + year,
                data = panel, cluster = ~region)
cat("\nM2 (Manufacturing GFCF):\n"); print(summary(m2_mfg))

m2_svc <- NULL
if ("ln_gfcf_svc" %in% names(panel) && any(!is.na(panel$ln_gfcf_svc))) {
  m2_svc <- feols(ln_gfcf_svc ~ treat_intensity | region + year,
                  data = panel %>% filter(!is.na(ln_gfcf_svc)), cluster = ~region)
  cat("\nM3 (Services GFCF):\n"); print(summary(m2_svc))
} else {
  cat("\nM3 (Services GFCF): Not available\n")
}

## ---- 3. R&D response ----
m3_rd <- feols(ln_rd ~ treat_intensity | region + year,
               data = panel %>% filter(!is.na(ln_rd)), cluster = ~region)
cat("\nM4 (R&D spending):\n"); print(summary(m3_rd))

## ---- 4. Event study ----
es <- feols(ln_gfcf ~ i(rel_year, fornero_bite, ref = -1) | region + year,
            data = panel, cluster = ~region)
cat("\nEvent study:\n"); print(summary(es))

## ---- 5. Youth employment (mechanism) ----
if ("emprate_15_24" %in% names(panel)) {
  m5 <- feols(emprate_15_24 ~ treat_intensity | region + year,
              data = panel, cluster = ~region)
  cat("\nM5 (Youth employment rate):\n"); print(summary(m5))
} else {
  cat("\nYouth employment column not found. Columns:", paste(names(panel), collapse=", "), "\n")
  m5 <- NULL
}

## ---- Save ----
results <- list(m1 = m1, m1s = m1s, m2_mfg = m2_mfg, m2_svc = m2_svc,
                m3_rd = m3_rd, es = es, m5 = m5)
saveRDS(results, "data/results_main.rds")

## Diagnostics
diag <- list(
  n_treated = length(unique(panel$region[panel$fornero_bite > median(panel$fornero_bite, na.rm=TRUE)])),
  n_pre = length(unique(panel$year[panel$year < 2012])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", paste(names(diag), "=", diag, collapse=", "), "\n")
