## 03_main_analysis.R — Main regressions: Steuerfuss → spending, establishments
## Uses fixest for municipality + year FE, clustered SEs at municipality level

source("00_packages.R")
library(fixest)     # Two-way FE, clustered SEs
library(data.table) # Panel data operations

data_dir <- "../data"

# ── Load data ───────────────────────────────────────────────────────────────
panel    <- fread(file.path(data_dir, "panel.csv"))
spending <- fread(file.path(data_dir, "spending_panel.csv"))

# ── 1. Classify spending indicators by HRM function ────────────────────────
# Swiss HRM functional classification (Erfolgsrechnung):
# IDs 100-109: aggregate expenditure items (personnel, materials, etc.)
# IDs 111-120: aggregate revenue items (taxes, fees, etc.)
# IDs 132+: functional net expenditure (Nettoaufwendungen)
#
# Key functional groups:
# Education (2xx):  IDs 144-163
# Social (5xx):     IDs 179-194
# Health (4xx):     IDs 171-178
# Transport (6xx):  IDs 195-200
# Environment (7xx): IDs 201-210

spending[, category := fcase(
  indikator_id >= 144 & indikator_id <= 163, "education",
  indikator_id >= 179 & indikator_id <= 194, "social",
  indikator_id >= 171 & indikator_id <= 178, "health",
  indikator_id >= 195 & indikator_id <= 200, "transport",
  indikator_id >= 201 & indikator_id <= 210, "environment",
  indikator_id >= 132 & indikator_id <= 143, "admin_safety",
  indikator_id == 111, "tax_revenue",
  indikator_id == 224, "muni_tax_revenue",
  default = NA_character_
)]

cat("Indicator classification:\n")
print(spending[!is.na(category), .(.N, n_munis = uniqueN(bfsnr)), by = category][order(-N)])

# Aggregate by bfsnr + year + category (sum functional sub-items)
spend_agg <- spending[!is.na(category), .(
  value = sum(as.numeric(value), na.rm = TRUE)
), by = .(bfsnr, year, category)]

# Compute total functional expenditure (all functional categories summed)
total_func <- spending[indikator_id >= 132 & indikator_id <= 235 &
                        !indikator_id %in% c(224:235),  # exclude revenue/balance items
                        .(total_exp = sum(as.numeric(value), na.rm = TRUE)),
                        by = .(bfsnr, year)]

# Pivot wide
spend_wide <- dcast(spend_agg, bfsnr + year ~ category, value.var = "value", fun.aggregate = sum)
spend_wide <- merge(spend_wide, total_func, by = c("bfsnr", "year"), all.x = TRUE)

cat(sprintf("\nSpending panel: %d obs, %d municipalities, years %d-%d\n",
            nrow(spend_wide), uniqueN(spend_wide$bfsnr),
            min(spend_wide$year), max(spend_wide$year)))

# ── 2. Merge spending with main panel ───────────────────────────────────────
analysis <- merge(panel, spend_wide, by = c("bfsnr", "year"), all.x = TRUE)

# Compute per-capita values
pc_cols <- c("education", "social", "health", "transport", "environment",
             "admin_safety", "tax_revenue", "muni_tax_revenue", "total_exp")
for (col in pc_cols) {
  if (!col %in% names(analysis)) next
  pc_name <- paste0(col, "_pc")
  analysis[population > 0, (pc_name) := get(col) / population]
}

# Trim extreme outliers (1st/99th percentile) for per-capita variables
pc_names <- paste0(pc_cols, "_pc")
for (col in pc_names) {
  if (!col %in% names(analysis)) next
  vals <- analysis[[col]]
  vals <- vals[!is.na(vals)]
  if (length(vals) < 10) next
  q01 <- quantile(vals, 0.01, na.rm = TRUE)
  q99 <- quantile(vals, 0.99, na.rm = TRUE)
  analysis[get(col) < q01 | get(col) > q99, (col) := NA]
}

# Analysis sample: years with both Steuerfuss and spending
analysis_full <- analysis[!is.na(stf_corp) & !is.na(total_exp_pc) & total_exp_pc > 0]
cat(sprintf("\nAnalysis sample: %d obs, %d municipalities, years %d-%d\n",
            nrow(analysis_full), uniqueN(analysis_full$bfsnr),
            min(analysis_full$year), max(analysis_full$year)))

fwrite(analysis_full, file.path(data_dir, "analysis_panel.csv"))

# ── 3. Main regressions ────────────────────────────────────────────────────
cat("\n=== MAIN RESULTS ===\n")
cat("Y_pc = α_i + γ_t + β × stf_corp + δ × pop_growth + ε (clustered at municipality)\n\n")

outcomes <- c("total_exp_pc", "education_pc", "social_pc", "transport_pc", "tax_revenue_pc")
outcome_labels <- c("Total Func. Exp.", "Education", "Social Security",
                     "Transport/Infra.", "Tax Revenue")

results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  if (!y %in% names(analysis_full) || sum(!is.na(analysis_full[[y]])) < 50) {
    cat(sprintf("  Skipping %s (insufficient data)\n", y))
    next
  }

  fml <- as.formula(paste0(y, " ~ stf_corp + pop_growth | bfsnr + year"))
  fit <- feols(fml, data = analysis_full, cluster = ~bfsnr)
  results[[y]] <- fit

  sd_y <- sd(analysis_full[[y]], na.rm = TRUE)
  dep_mean <- mean(analysis_full[[y]], na.rm = TRUE)
  beta <- coef(fit)["stf_corp"]

  cat(sprintf("%s:\n", outcome_labels[i]))
  cat(sprintf("  β(stf_corp) = %.2f (SE = %.2f), p = %.4f\n",
              beta, se(fit)["stf_corp"], pvalue(fit)["stf_corp"]))
  cat(sprintf("  → 1pp increase in corporate rate → CHF %.0f p.c. change\n", beta))
  cat(sprintf("  Dep. mean = %.0f, SD = %.0f, N = %d\n\n",
              dep_mean, sd_y, fit$nobs))
}

# ── 4. Event study around large cuts (≥5pp) ────────────────────────────────
cat("\n=== EVENT STUDY ===\n")

first_cuts <- analysis_full[large_cut == 1, .(first_cut_year = min(year)), by = bfsnr]
cat(sprintf("Municipalities with large cuts (≥5pp): %d\n", nrow(first_cuts)))

es_results <- list()
if (nrow(first_cuts) >= 5) {
  es_data <- merge(analysis_full, first_cuts, by = "bfsnr", all.x = TRUE)
  es_data[, event_time := year - first_cut_year]
  es_data[, treated := as.integer(!is.na(first_cut_year))]

  # Keep treated municipalities within event window [-4, +4]
  es_treated <- es_data[treated == 1 & event_time >= -4 & event_time <= 4]

  if (nrow(es_treated) > 30) {
    for (y in c("total_exp_pc", "education_pc", "tax_revenue_pc")) {
      if (!y %in% names(es_treated) || sum(!is.na(es_treated[[y]])) < 20) next

      fml <- as.formula(paste0(y, " ~ i(event_time, ref = -1) | bfsnr + year"))
      es_fit <- tryCatch(
        feols(fml, data = es_treated, cluster = ~bfsnr),
        error = function(e) { cat(sprintf("  ES failed for %s: %s\n", y, e$message)); NULL }
      )
      if (!is.null(es_fit)) {
        es_results[[y]] <- es_fit
        cat(sprintf("\nEvent study for %s:\n", y))
        # Print pre-trend test (coefficients for t < -1)
        cf <- coef(es_fit)
        pre_coefs <- cf[grep("event_time::-[2-4]", names(cf))]
        if (length(pre_coefs) > 0) {
          cat(sprintf("  Pre-trend coefficients: %s\n",
                      paste(sprintf("%.1f", pre_coefs), collapse = ", ")))
        }
        post_coefs <- cf[grep("event_time::[0-4]", names(cf))]
        if (length(post_coefs) > 0) {
          cat(sprintf("  Post-treatment coefficients: %s\n",
                      paste(sprintf("%.1f", post_coefs), collapse = ", ")))
        }
      }
    }
  }
}

# ── 5. Mechanism: Establishment and employment growth ──────────────────────
cat("\n=== MECHANISM: FIRM ENTRY ===\n")

estab_data <- analysis_full[!is.na(log_estab) & !is.na(stf_corp)]
if (nrow(estab_data) > 50) {
  fit_estab <- feols(log_estab ~ stf_corp + pop_growth | bfsnr + year,
                     data = estab_data, cluster = ~bfsnr)
  results[["establishments"]] <- fit_estab
  cat(sprintf("log(establishments): β = %.5f (SE = %.5f), p = %.4f\n",
              coef(fit_estab)["stf_corp"], se(fit_estab)["stf_corp"],
              pvalue(fit_estab)["stf_corp"]))

  fit_emp <- feols(log_emp ~ stf_corp + pop_growth | bfsnr + year,
                   data = estab_data, cluster = ~bfsnr)
  results[["employment"]] <- fit_emp
  cat(sprintf("log(employment): β = %.5f (SE = %.5f), p = %.4f\n",
              coef(fit_emp)["stf_corp"], se(fit_emp)["stf_corp"],
              pvalue(fit_emp)["stf_corp"]))

  # Interpret: A 10pp decrease in corporate rate → X% change in establishments
  cat(sprintf("\n  → 10pp corporate rate decrease → %.2f%% change in establishments\n",
              -10 * coef(fit_estab)["stf_corp"] * 100))
  cat(sprintf("  → 10pp corporate rate decrease → %.2f%% change in employment\n",
              -10 * coef(fit_emp)["stf_corp"] * 100))
}

# ── 6. Save results ────────────────────────────────────────────────────────
save(results, es_results, analysis_full, file = file.path(data_dir, "main_results.RData"))

# Write diagnostics.json for validator
n_treated_muni <- uniqueN(analysis_full[!is.na(stf_corp_chg) & stf_corp_chg != 0, bfsnr])
yr_range <- range(analysis_full$year)
n_pre <- length(unique(analysis_full$year[analysis_full$year <= median(analysis_full$year)]))
n_obs <- nrow(analysis_full)

jsonlite::write_json(list(
  n_treated = n_treated_muni,
  n_pre = n_pre,
  n_obs = n_obs
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_muni, n_pre, n_obs))
cat("Main analysis complete.\n")
