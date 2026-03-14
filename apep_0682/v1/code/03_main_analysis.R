## 03_main_analysis.R — Staggered DiD: EDM Information Revelation → House Prices
## apep_0682: Sewage EDM Information Revelation and House Prices

library(data.table)
library(fixest)
library(did)

DATA_DIR <- "data"

## ── 1. Load panel ─────────────────────────────────────────────────────────
cat("=== Loading analysis panel ===\n")
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat("Panel:", nrow(panel), "rows,", uniqueN(panel$postcode_district), "postcode districts\n")
cat("Treatment groups:\n")
print(table(panel$gname))

# Create numeric ID for postcode district
panel[, pd_id := as.integer(factor(postcode_district))]

## ── 2. Summary statistics ─────────────────────────────────────────────────
cat("\n=== Summary Statistics ===\n")
summ <- panel[, .(
  mean_price = mean(exp(mean_log_price)),
  sd_log_price = sd(mean_log_price),
  mean_n_tx = mean(n_transactions),
  n_districts = uniqueN(postcode_district),
  n_overflows = sum(n_overflows > 0) / .N
), by = .(has_overflow = gname > 0)]
print(summ)

## ── 3. TWFE Baseline ──────────────────────────────────────────────────────
cat("\n=== TWFE Regressions ===\n")

# Model 1: Simple TWFE
m1 <- feols(mean_log_price ~ treated | postcode_district + year,
            data = panel, cluster = ~postcode_district)
cat("Model 1 (TWFE):\n")
summary(m1)

# Model 2: TWFE with controls
m2 <- feols(mean_log_price ~ treated + pct_detached + pct_flat + pct_new |
              postcode_district + year,
            data = panel, cluster = ~postcode_district)
cat("\nModel 2 (TWFE + controls):\n")
summary(m2)

# Model 3: Dose-response — interact with spill intensity
panel[, treated_x_spills := treated * log1p(mean_spill_count)]
m3 <- feols(mean_log_price ~ treated + treated_x_spills |
              postcode_district + year,
            data = panel, cluster = ~postcode_district)
cat("\nModel 3 (Dose-response):\n")
summary(m3)

# Model 4: High-spill vs low-spill overflows
panel[, treated_high := treated * high_spill]
panel[, treated_low := treated * (1L - high_spill)]
m4 <- feols(mean_log_price ~ treated_high + treated_low |
              postcode_district + year,
            data = panel, cluster = ~postcode_district)
cat("\nModel 4 (High vs Low spill):\n")
summary(m4)

## ── 4. Callaway & Sant'Anna (2021) ───────────────────────────────────────
cat("\n=== Callaway & Sant'Anna ===\n")

# Need a balanced or at least well-structured panel
# gname: 0 = never treated, year of first treatment otherwise
# Keep treatment years in range 2017-2025 (data_start 2016-2024 + 1)
cs_data <- panel[gname == 0 | (gname >= 2017 & gname <= 2025)]
cs_data[, gname_cs := fifelse(gname == 0, 0L, gname)]

cat("C&S data:", nrow(cs_data), "rows\n")
cat("C&S groups:\n")
print(table(cs_data$gname_cs))

cs_out <- tryCatch({
  att_gt(
    yname = "mean_log_price",
    tname = "year",
    idname = "pd_id",
    gname = "gname_cs",
    data = as.data.frame(cs_data),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) {
  cat("C&S error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\nC&S group-time ATTs:\n")
  print(summary(cs_out))

  # Aggregate: simple ATT
  cs_simple <- aggte(cs_out, type = "simple")
  cat("\nC&S Simple ATT:\n")
  print(summary(cs_simple))

  # Aggregate: event study
  cs_es <- aggte(cs_out, type = "dynamic", min_e = -4, max_e = 5)
  cat("\nC&S Event Study:\n")
  print(summary(cs_es))

  # Save C&S results
  saveRDS(cs_out, file.path(DATA_DIR, "cs_results.rds"))
  saveRDS(cs_es, file.path(DATA_DIR, "cs_event_study.rds"))
}

## ── 5. Event Study (TWFE) ────────────────────────────────────────────────
cat("\n=== TWFE Event Study ===\n")

# Create event time variable
panel[, event_time := fifelse(gname > 0, year - gname, NA_integer_)]

# Restrict to ±5 years and bin endpoints
panel[, et_bin := fcase(
  is.na(event_time), NA_integer_,
  event_time < -4, -4L,
  event_time > 5, 5L,
  default = event_time
)]

# Event study regression (omit t=-1)
es_twfe <- feols(mean_log_price ~ i(et_bin, ref = -1) | postcode_district + year,
                 data = panel[!is.na(et_bin)], cluster = ~postcode_district)
cat("TWFE Event Study:\n")
summary(es_twfe)

## ── 6. Save diagnostics for validator ─────────────────────────────────────
diagnostics <- list(
  n_treated = uniqueN(panel[gname > 0, postcode_district]),
  n_pre = length(2016:(min(panel[gname > 0, gname]) - 1)),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")

## ── 7. Save regression objects ────────────────────────────────────────────
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, es_twfe = es_twfe),
        file.path(DATA_DIR, "twfe_models.rds"))

cat("\n=== Main analysis complete ===\n")
