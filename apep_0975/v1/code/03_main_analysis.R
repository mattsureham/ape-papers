## 03_main_analysis.R — Staggered DiD with Callaway-Sant'Anna
## apep_0975: European Investigation Order and Crime Deterrence

source("00_packages.R")
setwd(file.path(dirname(getwd())))

panel <- fread("data/analysis_panel.csv")

cat("=== Main Analysis: Callaway-Sant'Anna Staggered DiD ===\n\n")

# ===========================================================================
# 1. Callaway-Sant'Anna by crime category
# ===========================================================================

# Categories to analyze
categories <- c("ICCS0701", "ICCS0601", "ICCS0502",  # Cross-border
                "ICCS0101", "ICCS020111")              # Domestic (placebo)

cs_results <- list()

for (cat_code in categories) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]
  cat(sprintf("\n--- %s (%s) ---\n", cat_label, cat_code))

  # Subset and balance panel
  sub <- panel[iccs == cat_code & !is.na(rate)]

  # Check balance: need all years for all countries
  year_counts <- sub[, .N, by = geo]
  max_years <- max(year_counts$N)
  balanced_geos <- year_counts[N == max_years, geo]

  if (length(balanced_geos) < 10) {
    # Relax: keep countries with at least 80% of years
    min_years <- floor(0.8 * max_years)
    balanced_geos <- year_counts[N >= min_years, geo]
    cat(sprintf("  Using %d countries with >= %d years (80%% threshold)\n",
                length(balanced_geos), min_years))
  }

  sub <- sub[geo %in% balanced_geos]

  # Fill missing years with NA for balanced panel
  full_grid <- CJ(geo = unique(sub$geo), year = min(sub$year):max(sub$year))
  sub <- merge(full_grid, sub, by = c("geo", "year"), all.x = TRUE)

  # Fill treatment info for missing rows
  treat_map <- unique(panel[, .(geo, first_treat, country_id)])
  sub <- merge(sub[, !c("first_treat", "country_id"), with = FALSE],
               treat_map, by = "geo", all.x = TRUE)

  # Interpolate missing rates (linear)
  sub <- sub[order(geo, year)]
  sub[, rate := approx(year, rate, year, rule = 2)$y, by = geo]
  sub[, log_rate := log(rate + 0.01)]

  n_treated <- sum(sub[, .(ft = first_treat[1]), by = geo]$ft > 0)
  n_never   <- sum(sub[, .(ft = first_treat[1]), by = geo]$ft == 0)
  cat(sprintf("  Balanced panel: %d countries (%d treated, %d never-treated), %d years\n",
              length(unique(sub$geo)), n_treated, n_never,
              length(unique(sub$year))))

  # Run Callaway-Sant'Anna
  tryCatch({
    cs_out <- att_gt(
      yname       = "log_rate",
      tname       = "year",
      idname      = "country_id",
      gname       = "first_treat",
      data        = as.data.frame(sub),
      control_group = "notyettreated",
      anticipation  = 0,
      est_method    = "dr",  # doubly-robust
      base_period   = "universal"
    )

    cat(sprintf("  ATT(g,t) estimates: %d\n", length(cs_out$att)))

    # Aggregate: simple (overall ATT)
    agg_simple <- aggte(cs_out, type = "simple")
    cat(sprintf("  Overall ATT: %.4f (SE: %.4f, p: %.4f)\n",
                agg_simple$overall.att, agg_simple$overall.se,
                2 * pnorm(-abs(agg_simple$overall.att / agg_simple$overall.se))))

    # Aggregate: dynamic (event study)
    agg_dynamic <- aggte(cs_out, type = "dynamic")

    cs_results[[cat_code]] <- list(
      att_gt  = cs_out,
      simple  = agg_simple,
      dynamic = agg_dynamic,
      label   = cat_label,
      n_countries = length(unique(sub$geo)),
      n_obs   = nrow(sub)
    )
  }, error = function(e) {
    cat(sprintf("  ERROR in C-S: %s\n", e$message))
    cat("  Falling back to TWFE...\n")

    # TWFE fallback
    twfe <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)
    cat(sprintf("  TWFE ATT: %.4f (SE: %.4f)\n",
                coef(twfe)["treated"], se(twfe)["treated"]))

    cs_results[[cat_code]] <<- list(
      twfe    = twfe,
      label   = cat_label,
      n_countries = length(unique(sub$geo)),
      n_obs   = nrow(sub),
      fallback = TRUE
    )
  })
}

# ===========================================================================
# 2. TWFE for comparison (all categories)
# ===========================================================================
cat("\n\n=== TWFE Regressions (for comparison) ===\n")

twfe_results <- list()
for (cat_code in categories) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]
  sub <- panel[iccs == cat_code & !is.na(rate)]

  twfe <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)
  twfe_results[[cat_code]] <- twfe

  cat(sprintf("  %s: β = %.4f (SE = %.4f, p = %.4f)\n",
              cat_label, coef(twfe)["treated"], se(twfe)["treated"],
              pvalue(twfe)["treated"]))
}

# ===========================================================================
# 3. Triple-difference: cross-border × post × treated
# ===========================================================================
cat("\n\n=== Triple-Difference ===\n")

# Stack cross-border and domestic categories
ddd_cats <- c("ICCS0701", "ICCS0601", "ICCS0502",   # cross-border
              "ICCS0101", "ICCS020111")               # domestic
ddd_panel <- panel[iccs %in% ddd_cats & !is.na(rate)]

# Post = any year >= 2017 (conservative: deadline year)
ddd_panel[, post := fifelse(year >= 2017, 1L, 0L)]

# Ever-treated indicator
ddd_panel[, ever_treated := fifelse(first_treat > 0, 1L, 0L)]

# DDD: cross_border × post × ever_treated
ddd_reg <- feols(
  log_rate ~ cross_border:post:ever_treated +
    cross_border:post + cross_border:ever_treated + post:ever_treated |
    geo + year + iccs,
  data = ddd_panel,
  cluster = ~geo
)
cat("DDD result:\n")
summary(ddd_reg)

# ===========================================================================
# 4. Save results
# ===========================================================================
saveRDS(cs_results, "data/cs_results.rds")
saveRDS(twfe_results, "data/twfe_results.rds")
saveRDS(ddd_reg, "data/ddd_results.rds")

# Diagnostics for validator
n_treated_countries <- sum(unique(panel[, .(geo, first_treat)])$first_treat > 0)
n_pre <- length(unique(panel[year < 2017, year]))
n_obs <- nrow(panel[!is.na(rate)])

jsonlite::write_json(list(
  n_treated = n_treated_countries,
  n_pre     = n_pre,
  n_obs     = n_obs
), "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_countries, n_pre, n_obs))
cat("Main analysis complete.\n")
