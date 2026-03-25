# 04_robustness.R — Robustness checks for 5AMLD analysis
# apep_0895: Does AML Regulation Actually Detect Money Laundering?

source("00_packages.R")

panel <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")

# ===========================================================================
# 1. Placebo outcomes: property crimes and assault
# ===========================================================================
message("=== Placebo Tests ===")

# Property crimes (should NOT respond to AML regulation)
cs_property_data <- panel[!is.na(log_property)]
if (nrow(cs_property_data) > 0 && uniqueN(cs_property_data$geo) >= 10) {
  cs_property <- att_gt(
    yname = "log_property",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(cs_property_data),
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg"
  )
  agg_property <- aggte(cs_property, type = "simple")
  message("Placebo (property crimes) ATT:")
  summary(agg_property)
} else {
  agg_property <- NULL
  message("Insufficient property crime data for placebo")
}

# Assault (should NOT respond to AML regulation)
cs_assault_data <- panel[!is.na(log_assault)]
if (nrow(cs_assault_data) > 0 && uniqueN(cs_assault_data$geo) >= 10) {
  cs_assault <- att_gt(
    yname = "log_assault",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(cs_assault_data),
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg"
  )
  agg_assault <- aggte(cs_assault, type = "simple")
  message("Placebo (assault) ATT:")
  summary(agg_assault)
} else {
  agg_assault <- NULL
  message("Insufficient assault data for placebo")
}

# ===========================================================================
# 2. Leave-one-out analysis
# ===========================================================================
message("\n=== Leave-One-Out ===")

loo_results <- list()
countries <- unique(panel[treat_year > 0, geo])

for (drop_geo in countries) {
  loo_data <- panel[geo != drop_geo & !is.na(log_ml)]

  # Recompute country_id
  loo_data[, country_id := as.integer(factor(geo))]

  # Check we still have enough treated units
  n_treat <- uniqueN(loo_data[treat_year > 0, geo])
  if (n_treat < 5) next

  loo_cs <- tryCatch({
    att_gt(
      yname = "log_ml",
      tname = "year",
      idname = "country_id",
      gname = "treat_year",
      data = as.data.frame(loo_data),
      control_group = "notyettreated",
      base_period = "universal",
      est_method = "reg"
    )
  }, error = function(e) NULL)

  if (!is.null(loo_cs)) {
    loo_agg <- aggte(loo_cs, type = "simple")
    loo_results[[drop_geo]] <- data.table(
      dropped = drop_geo,
      att = loo_agg$overall.att,
      se = loo_agg$overall.se
    )
  }
}

loo_dt <- rbindlist(loo_results)
if (nrow(loo_dt) > 0) {
  message("Leave-one-out results:")
  print(loo_dt[order(att)])
  message("\nATT range: [", round(min(loo_dt$att), 4), ", ", round(max(loo_dt$att), 4), "]")
  message("Full-sample ATT: ", round(results$agg_main$overall.att, 4))
}

# ===========================================================================
# 3. Never-treated as comparison group (alternative to not-yet-treated)
# ===========================================================================
message("\n=== Never-Treated Comparison ===")

cs_never <- tryCatch({
  att_gt(
    yname = "log_ml",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(panel[!is.na(log_ml)]),
    control_group = "nevertreated",
    base_period = "universal",
    est_method = "reg"
  )
}, error = function(e) {
  message("Never-treated comparison failed: ", e$message)
  NULL
})

if (!is.null(cs_never)) {
  agg_never <- aggte(cs_never, type = "simple")
  message("ATT (never-treated comparison):")
  summary(agg_never)
} else {
  agg_never <- NULL
}

# ===========================================================================
# 4. Continuous treatment: months of delay
# ===========================================================================
message("\n=== Continuous Treatment: Transposition Delay ===")

# 5AMLD deadline: January 10, 2020
deadline <- as.Date("2020-01-10")
transposition <- fread("data/transposition_5amld.csv")
transposition[, transposition_date := as.Date(transposition_date)]

delay_map <- transposition[!is.na(iso2) & !is.na(transposition_date),
                            .(geo = iso2,
                              delay_months = as.numeric(difftime(transposition_date,
                                                                  deadline, units = "days")) / 30.44)]

panel_delay <- merge(panel, delay_map, by = "geo", all.x = TRUE)
panel_delay[is.na(delay_months), delay_months := 0]

# TWFE with continuous treatment (delay intensity)
panel_delay[, post_delay := fifelse(treated == 1, delay_months, 0)]

twfe_delay <- feols(log_ml ~ post_delay | geo + year,
                    data = panel_delay[!is.na(log_ml)], cluster = ~geo)
message("TWFE continuous treatment (delay months):")
print(summary(twfe_delay))

# ===========================================================================
# 5. ML share of total crime (addresses relabeling concern)
# ===========================================================================
message("\n=== ML Share of Total Crime ===")

cs_share_data <- panel[!is.na(ml_share)]
if (nrow(cs_share_data) > 0 && uniqueN(cs_share_data$geo) >= 10) {
  cs_share <- att_gt(
    yname = "ml_share",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(cs_share_data),
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg"
  )
  agg_share <- aggte(cs_share, type = "simple")
  message("ML share ATT:")
  summary(agg_share)
} else {
  agg_share <- NULL
  message("Insufficient data for ML share analysis")
}

# ===========================================================================
# 6. Save robustness results
# ===========================================================================
robust <- list(
  agg_property = agg_property,
  agg_assault = agg_assault,
  loo_dt = loo_dt,
  agg_never = agg_never,
  twfe_delay = twfe_delay,
  agg_share = agg_share
)

saveRDS(robust, "data/robustness_results.rds")
message("\n=== Robustness checks complete ===")
