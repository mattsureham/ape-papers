## 03_main_analysis.R — Spatial RDD and Event Study
## APEP-0528: Do Administrative Borders Tax Electricity?

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
tab_dir <- "../tables"
dir.create(fig_dir, showWarnings = FALSE)
dir.create(tab_dir, showWarnings = FALSE)

# ===========================================================================
# 1. Load panel
# ===========================================================================
cat("=== Loading analysis panel ===\n")

panel <- fread(file.path(data_dir, "panel.csv"))
cat("  Panel:", nrow(panel), "rows,", uniqueN(panel$mun_id), "municipalities\n")

# Analysis sample: within 15km of cantonal border (main specification)
BW <- 15  # km
sample <- panel[dist_to_border_km <= BW & !is.na(border_pair)]
cat("  Analysis sample (", BW, "km):", nrow(sample), "rows,",
    uniqueN(sample$mun_id), "municipalities\n")

# ===========================================================================
# 2. Descriptive statistics
# ===========================================================================
cat("=== Descriptive statistics ===\n")

# Summary of tariff components
tariff_summary <- sample[, .(
  mean_total = mean(total, na.rm = TRUE),
  sd_total = sd(total, na.rm = TRUE),
  mean_energy = mean(energy, na.rm = TRUE),
  mean_grid = mean(gridusage, na.rm = TRUE),
  mean_aidfee = mean(aidfee, na.rm = TRUE),
  mean_charge = mean(charge, na.rm = TRUE),
  n_obs = .N,
  n_mun = uniqueN(mun_id),
  n_years = uniqueN(year)
), by = .(reformed)]

cat("\nTariff summary by reform status:\n")
print(tariff_summary)

# Save descriptive stats
fwrite(tariff_summary, file.path(data_dir, "desc_stats_reform.csv"))

# Summary by year
yearly_summary <- sample[, .(
  mean_total = mean(total, na.rm = TRUE),
  mean_charge = mean(charge, na.rm = TRUE),
  mean_aidfee = mean(aidfee, na.rm = TRUE),
  n_mun = uniqueN(mun_id)
), by = .(year, reformed)]

fwrite(yearly_summary, file.path(data_dir, "yearly_summary.csv"))

# ===========================================================================
# 3. Cross-sectional Spatial RDD — All border pairs pooled
# ===========================================================================
cat("\n=== Cross-sectional Spatial RDD ===\n")

# Signed distance: positive = reform canton, negative = non-reform canton
# For each border pair involving a reform canton, assign sign
sample[, signed_dist := fifelse(reformed, dist_to_border_km, -dist_to_border_km)]

# Pooled RDD for each tariff component
components <- c("total", "energy", "gridusage", "aidfee", "charge")
rdd_results <- list()

for (comp in components) {
  cat("  RDD for", comp, "...\n")

  # Only use border pairs where one side is reformed and one is not
  # Identify mixed border pairs
  bp_reform_status <- sample[, .(
    has_reformed = any(reformed),
    has_unreformed = any(!reformed)
  ), by = border_pair]
  mixed_bps <- bp_reform_status[has_reformed & has_unreformed]$border_pair

  rdd_sample <- sample[border_pair %in% mixed_bps]
  cat("    Mixed border pairs:", length(mixed_bps), "\n")
  cat("    Observations:", nrow(rdd_sample), "\n")

  if (nrow(rdd_sample) > 100) {
    # Use fixest for the parametric version with border-pair FE
    form <- as.formula(paste0(comp, " ~ reformed + dist_to_border_km + I(dist_to_border_km^2) | border_pair + year"))
    est <- feols(form, data = rdd_sample, cluster = ~canton)

    rdd_results[[comp]] <- list(
      component = comp,
      coef = coef(est)["reformedTRUE"],
      se = se(est)["reformedTRUE"],
      n = nobs(est),
      n_bp = length(mixed_bps)
    )

    cat("    Coefficient:", round(coef(est)["reformedTRUE"], 3),
        " (SE:", round(se(est)["reformedTRUE"], 3), ")\n")
  }
}

rdd_table <- rbindlist(lapply(rdd_results, as.data.table))
cat("\n  Cross-sectional RDD results:\n")
print(rdd_table)
fwrite(rdd_table, file.path(data_dir, "rdd_cross_section.csv"))

# Note: Wild cluster bootstrap (Cameron, Gelbach & Miller 2008) was attempted
# but fwildclusterboot has compatibility issues with feols + multi-way FE.
# Canton-level clustering with 26 cantons (8 treated) is standard in Swiss
# spatial RDD studies (Eugster et al. 2011, Egger & Lassmann 2015).

# ===========================================================================
# 4. Spatial DiD — Event Study
# ===========================================================================
cat("\n=== Event Study (Spatial DiD) ===\n")

# Restrict to reformed canton municipalities and matched control municipalities
# in adjacent cantons
es_sample <- sample[border_pair %in% mixed_bps & !is.na(event_time)]

# Also need to assign event_time to control municipalities
# Control municipalities get their nearest reform canton's event_time
# First, for each non-reformed municipality near a reform canton border,
# assign the reform year of the nearest reform canton
reform_cantons <- unique(sample[reformed == TRUE]$canton)

# For non-reformed municipalities, find which reform canton they border
# Take earliest reform year per border pair to avoid duplicates
border_pair_to_reform <- sample[reformed == TRUE,
  .(bp_reform_canton = first(canton), bp_reform_year = min(reform_year)),
  by = border_pair]
border_pair_to_reform <- unique(border_pair_to_reform, by = "border_pair")

# Merge back
sample_with_ref <- merge(sample, border_pair_to_reform, by = "border_pair", all.x = TRUE)
sample_with_ref[, ref_event_time := year - bp_reform_year]

# Event study sample: all municipalities in mixed border pairs
es_data <- sample_with_ref[border_pair %in% mixed_bps & !is.na(ref_event_time)]

# Bin event time at endpoints
es_data[, et_binned := pmax(pmin(ref_event_time, 10L), -5L)]

# Drop event_time = -1 (reference period)
es_data[, et_factor := factor(et_binned)]

cat("  Event study sample:", nrow(es_data), "observations\n")
cat("  Event time range:", min(es_data$et_binned), "to", max(es_data$et_binned), "\n")

# Run event study for each component
es_results <- list()

for (comp in components) {
  cat("  Event study for", comp, "...\n")

  # Use Sun & Abraham (2021) interaction-weighted estimator for staggered adoption
  form <- as.formula(paste0(comp,
    " ~ sunab(bp_reform_year, year) + dist_to_border_km | mun_id + year"))

  est <- tryCatch({
    feols(form, data = es_data, cluster = ~canton)
  }, error = function(e) {
    cat("    sunab() error:", e$message, "\n")
    cat("    Falling back to standard TWFE event study\n")
    form_twfe <- as.formula(paste0(comp,
      " ~ i(et_binned, reformed, ref = -1) + dist_to_border_km | mun_id + year"))
    tryCatch(feols(form_twfe, data = es_data, cluster = ~canton),
             error = function(e2) { cat("    TWFE also failed:", e2$message, "\n"); NULL })
  })

  if (!is.null(est)) {
    # Extract coefficients for plotting — handle both sunab and i() formats
    cf <- coeftable(est)
    rn <- rownames(cf)

    if (any(grepl("^year::", rn))) {
      # sunab format: "year::-5", "year::0", "year::3", etc.
      es_rows <- grepl("^year::", rn)
      event_times <- as.integer(gsub("^year::", "", rn[es_rows]))
    } else {
      # i() format: "et_binned::-5::reformedTRUE", etc.
      es_rows <- grepl("et_binned", rn)
      event_times <- as.integer(gsub(".*::([-0-9]+):.*", "\\1", rn[es_rows]))
    }

    if (sum(es_rows) > 0) {
      es_cf <- data.table(
        component = comp,
        event_time = event_times,
        estimate = cf[es_rows, "Estimate"],
        se = cf[es_rows, "Std. Error"]
      )
      es_cf <- es_cf[!is.na(event_time)]
      # Bin to [-5, 10] range for plotting consistency
      es_cf <- es_cf[event_time >= -5 & event_time <= 10]
      es_cf[, ci_lo := estimate - 1.96 * se]
      es_cf[, ci_hi := estimate + 1.96 * se]
      es_results[[comp]] <- es_cf

      post_cf <- es_cf[event_time >= 0]
      if (nrow(post_cf) > 0) {
        cat("    Post-reform avg effect:", round(mean(post_cf$estimate), 3), "\n")
      }
    }
  }
}

es_all <- rbindlist(es_results)
fwrite(es_all, file.path(data_dir, "event_study_results.csv"))
cat("\n  Event study results saved.\n")

# ===========================================================================
# 5. Border-pair-specific estimates
# ===========================================================================
cat("\n=== Border-pair-specific estimates ===\n")

bp_estimates <- list()
for (bp in mixed_bps) {
  bp_data <- sample_with_ref[border_pair == bp & !is.na(ref_event_time)]
  if (nrow(bp_data) < 20) next

  est <- tryCatch({
    feols(charge ~ reformed * post_reform + dist_to_border_km | year,
          data = bp_data[, post_reform := as.integer(year >= bp_reform_year)],
          cluster = ~mun_id)
  }, error = function(e) NULL)

  if (!is.null(est) && "reformedTRUE:post_reform" %in% names(coef(est))) {
    bp_estimates[[bp]] <- data.table(
      border_pair = bp,
      did_coef = coef(est)["reformedTRUE:post_reform"],
      did_se = se(est)["reformedTRUE:post_reform"],
      n = nobs(est),
      n_mun = uniqueN(bp_data$mun_id)
    )
  }
}

if (length(bp_estimates) > 0) {
  bp_table <- rbindlist(bp_estimates)
  bp_table[, significant := abs(did_coef / did_se) > 1.96]
  cat("  Border pairs estimated:", nrow(bp_table), "\n")
  cat("  Significant (5%):", sum(bp_table$significant), "\n")
  cat("  Mean DiD coefficient:", round(mean(bp_table$did_coef), 3), "\n")
  fwrite(bp_table, file.path(data_dir, "border_pair_estimates.csv"))
}

# ===========================================================================
# 6. Variance decomposition
# ===========================================================================
cat("\n=== Variance decomposition ===\n")

# What share of total tariff variance is explained by cantonal policy (charges)
# vs. cost fundamentals (energy, grid)?
var_decomp <- sample[, .(
  var_total = var(total, na.rm = TRUE),
  var_energy = var(energy, na.rm = TRUE),
  var_grid = var(gridusage, na.rm = TRUE),
  var_aidfee = var(aidfee, na.rm = TRUE),
  var_charge = var(charge, na.rm = TRUE)
)]

var_decomp[, share_energy := var_energy / var_total]
var_decomp[, share_grid := var_grid / var_total]
var_decomp[, share_aidfee := var_aidfee / var_total]
var_decomp[, share_charge := var_charge / var_total]

cat("  Variance shares of total tariff:\n")
cat("    Energy:", round(var_decomp$share_energy * 100, 1), "%\n")
cat("    Grid:", round(var_decomp$share_grid * 100, 1), "%\n")
cat("    Aid fee:", round(var_decomp$share_aidfee * 100, 1), "%\n")
cat("    Charges:", round(var_decomp$share_charge * 100, 1), "%\n")

fwrite(var_decomp, file.path(data_dir, "variance_decomposition.csv"))

# ===========================================================================
# 7. Consumer cost counterfactual
# ===========================================================================
cat("\n=== Consumer cost counterfactual ===\n")

# How much more do reform-canton consumers near borders pay?
near_border <- sample[dist_to_border_km <= 10 & border_pair %in% mixed_bps]
cost_diff <- near_border[year == max(year), .(
  mean_total = mean(total, na.rm = TRUE),
  mean_charge = mean(charge, na.rm = TRUE),
  n_mun = uniqueN(mun_id)
), by = reformed]

cat("  Near-border municipalities (≤10km), latest year:\n")
print(cost_diff)

if (nrow(cost_diff) == 2) {
  charge_gap <- cost_diff[reformed == TRUE]$mean_charge - cost_diff[reformed == FALSE]$mean_charge
  cat("  Charges gap:", round(charge_gap, 2), "Rp/kWh\n")
  cat("  For 4,500 kWh/year household:", round(charge_gap * 45, 0), "CHF/year\n")
}

# Save
fwrite(cost_diff, file.path(data_dir, "cost_counterfactual.csv"))

cat("\n=== Main analysis complete ===\n")
