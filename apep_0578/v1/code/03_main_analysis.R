## ============================================================================
## 03_main_analysis.R — Main DiD estimation
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel_balanced.csv"))

cat("=== Main Analysis ===\n")
cat("Panel:", nrow(panel), "obs,", length(unique(panel$nuts3)), "regions\n")

## ---------------------------------------------------------------------------
## 1. Summary Statistics
## ---------------------------------------------------------------------------
cat("\n--- Summary Statistics ---\n")

# Pre-treatment means by region type
pre <- panel[year < 2015]
sum_stats <- pre[, .(
  mean_gdp_pc = mean(gdp_pc, na.rm = TRUE),
  sd_gdp_pc = sd(gdp_pc, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  sd_emp = sd(employment, na.rm = TRUE),
  n_regions = uniqueN(nuts3),
  n_obs = .N
), by = region_type]

cat("Pre-treatment summary (2003-2014):\n")
print(sum_stats)

fwrite(sum_stats, file.path(tables_dir, "tab1_summary_stats.csv"))

## ---------------------------------------------------------------------------
## 2. TWFE Event Study (baseline)
## ---------------------------------------------------------------------------
cat("\n--- TWFE Event Study ---\n")

# Create event-time variable
panel[, event_time := fifelse(first_treat > 0, year - first_treat, NA_integer_)]

# For TWFE, set never-treated event_time to a reference
panel[, rel_year := fifelse(first_treat > 0, year - first_treat, -1000L)]

# sunab() from fixest — Sun & Abraham (2021) interaction-weighted estimator
es_twfe <- feols(log_gdp_pc ~ sunab(first_treat, year) | nuts3 + year,
                 data = panel[first_treat != 0 | region_type != "interior"],
                 cluster = ~nuts3)

cat("TWFE Event Study (Sun-Abraham):\n")
summary(es_twfe)

# Extract event-study coefficients
es_coefs <- as.data.table(coeftable(es_twfe), keep.rownames = TRUE)
names(es_coefs)[1] <- "term"

# Parse event time from coefficient names
es_coefs[, event_time := as.integer(gsub(".*year::", "", term))]
es_coefs <- es_coefs[!is.na(event_time)]
names(es_coefs) <- c("term", "estimate", "se", "t_stat", "p_value", "event_time")

fwrite(es_coefs, file.path(tables_dir, "tab3_event_study.csv"))

## ---------------------------------------------------------------------------
## 3. Callaway-Sant'Anna (2021) — Heterogeneity-robust DiD
## ---------------------------------------------------------------------------
cat("\n--- Callaway-Sant'Anna ---\n")

# Prepare data for did package
# CS needs complete data. First, restrict year range to where most regions have data.
cs_data <- copy(panel)
cs_data <- cs_data[!is.na(log_gdp_pc)]

# Find year range where we have good coverage
year_coverage <- cs_data[, .N, by = year][order(year)]
cat("Year coverage:\n")
print(year_coverage)

# Use 2003-2022 for best balance
cs_data <- cs_data[year >= 2003 & year <= 2022]

# Find regions with data for ALL years in range
n_target_years <- length(2003:2022)
region_counts <- cs_data[, .N, by = nuts3]
balanced_ids <- region_counts[N == n_target_years, nuts3]
cat("CS: ", length(balanced_ids), "strictly balanced regions (2003-2022)\n")

# If too few, relax to 2005-2021
if (length(balanced_ids) < 100) {
  cs_data <- panel[!is.na(log_gdp_pc) & year >= 2005 & year <= 2021]
  n_target_years <- length(2005:2021)
  region_counts <- cs_data[, .N, by = nuts3]
  balanced_ids <- region_counts[N == n_target_years, nuts3]
  cat("CS (relaxed 2005-2021):", length(balanced_ids), "regions\n")
}

# If still too few, use repeated cross-sections mode
if (length(balanced_ids) < 50) {
  cat("CS: too few balanced regions, using panel=FALSE (repeated cross-sections)\n")
  cs_data <- panel[!is.na(log_gdp_pc) & year >= 2005 & year <= 2021]
  cs_data[, id := as.integer(as.factor(nuts3))]
  cs_panel_mode <- FALSE
} else {
  cs_data <- cs_data[nuts3 %in% balanced_ids]
  cs_data[, id := as.integer(as.factor(nuts3))]
  cs_panel_mode <- TRUE
}

cat("CS panel:", nrow(cs_data), "obs,", uniqueN(cs_data$nuts3), "regions,",
    uniqueN(cs_data$year), "years\n")
cat("  Treated:", uniqueN(cs_data[region_type == "treated_border", nuts3]), "\n")
cat("  Never-treated:", uniqueN(cs_data[first_treat == 0, nuts3]), "\n")

# Create country indicator for CS covariates
cs_data[, country_num := as.integer(as.factor(country))]

# Run CS estimator (baseline: no covariates)
cs_out <- att_gt(
  yname = "log_gdp_pc",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = as.data.frame(cs_data),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal",
  clustervars = "id",
  panel = cs_panel_mode
)

# Run CS with country covariates (addresses reviewer concern about country confounding)
cat("\nCS with country covariates:\n")
cs_out_country <- tryCatch({
  att_gt(
    yname = "log_gdp_pc",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    xformla = ~ country_num,
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal",
    clustervars = "id",
    panel = cs_panel_mode
  )
}, error = function(e) { cat("CS with country covariates failed:", e$message, "\n"); NULL })

if (!is.null(cs_out_country)) {
  cs_agg_country <- aggte(cs_out_country, type = "simple")
  cat("CS with country covariate ATT:", round(cs_agg_country$overall.att, 4),
      "SE:", round(cs_agg_country$overall.se, 4), "\n")
  fwrite(data.table(
    estimator = "CS_country",
    att = cs_agg_country$overall.att,
    se = cs_agg_country$overall.se
  ), file.path(tables_dir, "cs_country_covariate.csv"))
}

cat("\nCS Group-Time ATTs:\n")
summary(cs_out)

# Aggregate: simple average
cs_agg_simple <- aggte(cs_out, type = "simple")
cat("\nCS Simple Aggregate ATT:\n")
summary(cs_agg_simple)

# Aggregate: dynamic (event-study style)
cs_agg_dynamic <- aggte(cs_out, type = "dynamic")
cat("\nCS Dynamic ATT:\n")
summary(cs_agg_dynamic)

# Aggregate: by group (cohort)
cs_agg_group <- aggte(cs_out, type = "group")
cat("\nCS Group-level ATTs:\n")
summary(cs_agg_group)

# Save CS results
cs_simple_dt <- data.table(
  estimator = "CS_simple",
  att = cs_agg_simple$overall.att,
  se = cs_agg_simple$overall.se,
  ci_lower = cs_agg_simple$overall.att - 1.96 * cs_agg_simple$overall.se,
  ci_upper = cs_agg_simple$overall.att + 1.96 * cs_agg_simple$overall.se
)

# Dynamic coefficients
cs_dynamic_dt <- data.table(
  event_time = cs_agg_dynamic$egt,
  att = cs_agg_dynamic$att.egt,
  se = cs_agg_dynamic$se.egt,
  ci_lower = cs_agg_dynamic$att.egt - 1.96 * cs_agg_dynamic$se.egt,
  ci_upper = cs_agg_dynamic$att.egt + 1.96 * cs_agg_dynamic$se.egt
)

# Group-level
cs_group_dt <- data.table(
  cohort = cs_agg_group$egt,
  att = cs_agg_group$att.egt,
  se = cs_agg_group$se.egt,
  ci_lower = cs_agg_group$att.egt - 1.96 * cs_agg_group$se.egt,
  ci_upper = cs_agg_group$att.egt + 1.96 * cs_agg_group$se.egt
)

fwrite(cs_dynamic_dt, file.path(tables_dir, "cs_dynamic_coefs.csv"))
fwrite(cs_group_dt, file.path(tables_dir, "cs_group_atts.csv"))

## ---------------------------------------------------------------------------
## 4. Main results table: multiple outcomes
## ---------------------------------------------------------------------------
cat("\n--- Multi-outcome TWFE ---\n")

# GDP per capita
m1 <- feols(log_gdp_pc ~ treated | nuts3 + year,
            data = panel, cluster = ~nuts3)

# Employment (if available)
m2 <- tryCatch(
  feols(log_emp ~ treated | nuts3 + year,
        data = panel[!is.na(log_emp)], cluster = ~nuts3),
  error = function(e) NULL
)

# GVA total
m3 <- tryCatch(
  feols(log_gva_total ~ treated | nuts3 + year,
        data = panel[!is.na(log_gva_total)], cluster = ~nuts3),
  error = function(e) NULL
)

# GVA trade/transport (mechanism)
m4 <- tryCatch(
  feols(log_gva_trade ~ treated | nuts3 + year,
        data = panel[!is.na(log_gva_trade)], cluster = ~nuts3),
  error = function(e) NULL
)

# GVA manufacturing (mechanism)
m5 <- tryCatch(
  feols(log_gva_manuf ~ treated | nuts3 + year,
        data = panel[!is.na(log_gva_manuf)], cluster = ~nuts3),
  error = function(e) NULL
)

# Collect results
models <- list(m1)
model_names <- c("Log GDP pc")
if (!is.null(m2)) { models <- c(models, list(m2)); model_names <- c(model_names, "Log Employment") }
if (!is.null(m3)) { models <- c(models, list(m3)); model_names <- c(model_names, "Log GVA Total") }
if (!is.null(m4)) { models <- c(models, list(m4)); model_names <- c(model_names, "Log GVA Trade") }
if (!is.null(m5)) { models <- c(models, list(m5)); model_names <- c(model_names, "Log GVA Manuf") }

# Main results table
main_results <- data.table(
  outcome = model_names,
  estimate = sapply(models, function(m) coef(m)["treated"]),
  se = sapply(models, function(m) fixest::se(m)["treated"]),
  p_value = sapply(models, function(m) fixest::pvalue(m)["treated"]),
  n_obs = sapply(models, function(m) nobs(m)),
  n_regions = sapply(models, function(m) length(unique(m$fixef_id$nuts3)))
)
main_results[, ci_lower := estimate - 1.96 * se]
main_results[, ci_upper := estimate + 1.96 * se]
main_results[, stars := fifelse(p_value < 0.01, "***",
                        fifelse(p_value < 0.05, "**",
                        fifelse(p_value < 0.1, "*", "")))]

cat("\nMain Results:\n")
print(main_results)

fwrite(main_results, file.path(tables_dir, "tab2_main_results.csv"))

# Add CS simple estimate to the main table
cs_main <- data.table(
  outcome = "Log GDP pc (CS)",
  estimate = cs_agg_simple$overall.att,
  se = cs_agg_simple$overall.se,
  p_value = 2 * pnorm(-abs(cs_agg_simple$overall.att / cs_agg_simple$overall.se)),
  n_obs = nrow(cs_data),
  n_regions = uniqueN(cs_data$nuts3)
)
cs_main[, ci_lower := estimate - 1.96 * se]
cs_main[, ci_upper := estimate + 1.96 * se]
cs_main[, stars := fifelse(p_value < 0.01, "***",
                   fifelse(p_value < 0.05, "**",
                   fifelse(p_value < 0.1, "*", "")))]

main_results_full <- rbind(main_results, cs_main, fill = TRUE)
fwrite(main_results_full, file.path(tables_dir, "tab2_main_results.csv"))

## ---------------------------------------------------------------------------
## 5. Heterogeneity by border segment
## ---------------------------------------------------------------------------
cat("\n--- Heterogeneity by Border Segment ---\n")

# Only treated regions
treated_panel <- panel[region_type == "treated_border"]
treated_panel[, segment := border_segment]

# Interact treatment with segment
het_models <- list()
segments <- unique(treated_panel$border_segment)
segments <- segments[!is.na(segments)]

# Add control regions back for each segment
for (seg in segments) {
  seg_data <- rbind(
    treated_panel[border_segment == seg],
    panel[region_type %in% c("control_border", "interior")],
    fill = TRUE
  )
  seg_data[, seg_treated := as.integer(region_type == "treated_border" & year >= cohort)]

  m <- tryCatch(
    feols(log_gdp_pc ~ seg_treated | nuts3 + year,
          data = seg_data, cluster = ~nuts3),
    error = function(e) NULL
  )
  if (!is.null(m)) het_models[[seg]] <- m
}

het_results <- data.table(
  segment = names(het_models),
  estimate = sapply(het_models, function(m) coef(m)["seg_treated"]),
  se = sapply(het_models, function(m) fixest::se(m)["seg_treated"]),
  p_value = sapply(het_models, function(m) fixest::pvalue(m)["seg_treated"]),
  n_treated = sapply(names(het_models), function(seg) {
    uniqueN(treated_panel[border_segment == seg, nuts3])
  })
)
het_results[, ci_lower := estimate - 1.96 * se]
het_results[, ci_upper := estimate + 1.96 * se]

cat("Heterogeneity by border segment:\n")
print(het_results)

fwrite(het_results, file.path(tables_dir, "tab4_heterogeneity.csv"))

## ---------------------------------------------------------------------------
## 6. Save key objects for downstream scripts
## ---------------------------------------------------------------------------
save(cs_out, cs_agg_simple, cs_agg_dynamic, cs_agg_group,
     es_twfe, m1,
     file = file.path(data_dir, "main_results.RData"))

cat("\n03_main_analysis.R complete.\n")
