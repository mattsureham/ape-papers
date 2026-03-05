## 03_main_analysis.R — Primary DiD estimation
## apep_0513: Welsh 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Load Panels
# ============================================================
cat("=== Loading analysis panels ===\n")

panel <- fread(file.path(data_dir, "panel_pfa_month.csv"))
panel[, ym := as.Date(ym)]

cat(sprintf("  Panel: %d rows, %d PFAs, %d months\n",
            nrow(panel), n_distinct(panel$pfa), n_distinct(panel$ym)))

# ============================================================
# 2. Pre-Trend Visualization (Aggregate)
# ============================================================
cat("\n=== Generating pre-trend check ===\n")

# Aggregate to nation × month for visual
nation_month <- panel[, .(
  collisions = sum(collisions),
  ksi = sum(ksi)
), by = .(nation, ym)]

# Normalize: divide by number of PFAs for comparability
n_welsh_pfa <- n_distinct(panel[welsh == 1]$pfa)
n_eng_pfa <- n_distinct(panel[welsh == 0]$pfa)
nation_month[nation == "Wales", collisions_norm := collisions / n_welsh_pfa]
nation_month[nation == "England", collisions_norm := collisions / n_eng_pfa]
nation_month[nation == "Wales", ksi_norm := ksi / n_welsh_pfa]
nation_month[nation == "England", ksi_norm := ksi / n_eng_pfa]

# ============================================================
# 3. Primary DiD — All 20-30mph Road Collisions
# ============================================================
cat("\n=== Primary DiD: Collisions on 20-30mph roads ===\n")

# Model 1: Basic DiD (log collisions)
m1 <- feols(log_collisions ~ treat | pfa + ym, data = panel, cluster = ~pfa)
cat("Model 1: Basic DiD (log collisions)\n")
print(summary(m1))

# Model 2: Level specification (collision count)
m2 <- feols(collisions ~ treat | pfa + ym, data = panel, cluster = ~pfa)
cat("\nModel 2: Level DiD (collision count)\n")
print(summary(m2))

# Model 3: KSI (killed or seriously injured)
m3 <- feols(log_ksi ~ treat | pfa + ym, data = panel, cluster = ~pfa)
cat("\nModel 3: DiD on KSI (log)\n")
print(summary(m3))

# Model 4: Fatal only
panel[, log_fatal := log(fatal + 1)]
m4 <- feols(log_fatal ~ treat | pfa + ym, data = panel, cluster = ~pfa)
cat("\nModel 4: DiD on fatal collisions (log)\n")
print(summary(m4))

# Model 5: Serious only
panel[, log_serious := log(serious + 1)]
m5 <- feols(log_serious ~ treat | pfa + ym, data = panel, cluster = ~pfa)
cat("\nModel 5: DiD on serious collisions (log)\n")
print(summary(m5))

# Model 6: Slight only
panel[, log_slight := log(slight + 1)]
m6 <- feols(log_slight ~ treat | pfa + ym, data = panel, cluster = ~pfa)
cat("\nModel 6: DiD on slight collisions (log)\n")
print(summary(m6))

# ============================================================
# 4. Wild Cluster Bootstrap (CGM 2008)
# ============================================================
cat("\n=== Wild Cluster Bootstrap (4 Welsh + ~39 English PFAs) ===\n")

# Only run if fwildclusterboot is available
set.seed(2024)
boot_m1 <- tryCatch({
  boottest(m1, param = "treat", clustid = c("pfa"),
           B = 9999, type = "rademacher", nthreads = 1)
}, error = function(e) {
  cat("  Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_m1)) {
  cat("  Wild bootstrap p-value:", boot_m1$p_val, "\n")
  cat("  Bootstrap CI:", boot_m1$conf_int, "\n")
}

set.seed(2024)
boot_m3 <- tryCatch({
  boottest(m3, param = "treat", clustid = c("pfa"),
           B = 9999, type = "rademacher", nthreads = 1)
}, error = function(e) {
  cat("  Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_m3)) {
  cat("  Wild bootstrap p-value (KSI):", boot_m3$p_val, "\n")
}

# ============================================================
# 5. Event Study
# ============================================================
cat("\n=== Event Study ===\n")

# Omit period -1 as reference
panel[, rel_month_bin := as.factor(rel_month_bin)]
panel[, rel_month_bin := relevel(rel_month_bin, ref = "-1")]

es <- feols(log_collisions ~ i(rel_month_bin, welsh, ref = "-1") | pfa + ym,
            data = panel, cluster = ~pfa)
cat("Event study estimated.\n")

# ============================================================
# 6. Save Results
# ============================================================
cat("\n=== Saving results ===\n")

# Save main models
results <- list(
  basic_did = m1,
  level_did = m2,
  ksi_did = m3,
  fatal_did = m4,
  serious_did = m5,
  slight_did = m6,
  event_study = es
)

if (!is.null(boot_m1)) results$boot_collisions <- boot_m1
if (!is.null(boot_m3)) results$boot_ksi <- boot_m3

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Summary table
sink(file.path(tables_dir, "main_results_summary.txt"))
cat("=========================================\n")
cat("MAIN RESULTS: Welsh 20mph DiD\n")
cat("=========================================\n\n")
cat("Dependent variable: log(collisions + 1) on 20-30mph roads\n\n")
cat(sprintf("Treatment effect (log): %.4f (SE: %.4f)\n",
            coef(m1)["treat"], se(m1)["treat"]))
cat(sprintf("Implied percentage change: %.1f%%\n",
            (exp(coef(m1)["treat"]) - 1) * 100))
cat(sprintf("PFA-clustered p-value: %.4f\n", fixest::pvalue(m1)["treat"]))
if (!is.null(boot_m1)) {
  cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_m1$p_val))
}
cat(sprintf("\nKSI effect (log): %.4f (SE: %.4f)\n",
            coef(m3)["treat"], se(m3)["treat"]))
cat(sprintf("Implied KSI percentage change: %.1f%%\n",
            (exp(coef(m3)["treat"]) - 1) * 100))
cat(sprintf("KSI p-value: %.4f\n", fixest::pvalue(m3)["treat"]))
cat(sprintf("\nN observations: %d\n", nobs(m1)))
cat(sprintf("N PFAs: %d (Welsh: %d, English: %d)\n",
            n_distinct(panel$pfa),
            n_distinct(panel[welsh == 1]$pfa),
            n_distinct(panel[welsh == 0]$pfa)))
cat(sprintf("Period: %s to %s\n",
            min(panel$ym), max(panel$ym)))
sink()

cat("  Results saved to main_results.rds and main_results_summary.txt\n")
cat("\n=== Main analysis complete ===\n")
