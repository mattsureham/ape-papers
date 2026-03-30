## 05_tables.R — Generate all LaTeX tables + SDE appendix
## apep_1143: The Solar Footprint — Utility-Scale PV and Farmland Bird Populations

source("./code/00_packages.R")

DATA_DIR  <- "./data"
TAB_DIR   <- "./tables"
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Helpers
# ============================================================
fmt  <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt0 <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
fmt1 <- function(x) formatC(x, format = "f", digits = 1, big.mark = ",")
fmt2 <- function(x) formatC(x, format = "f", digits = 2)

stars <- function(b, se) {
  t <- abs(b / se)
  p <- 2 * pnorm(-t)
  ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$",
         ifelse(p < 0.1, "$^{*}$", "")))
}

classify_sde <- function(sde) {
  a <- abs(sde)
  if (a >= 0.15) return("Large")
  if (a >= 0.05) return("Moderate")
  if (a >= 0.005) return("Small")
  return("Null")
}

# ============================================================
# Load data
# ============================================================
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, route_num := as.integer(factor(route_id))]
panel[, state_num := as.integer(sub("_.*", "", route_id))]
panel[, ln_farm   := log(total_count_farmland + 1)]
panel[, ln_forest := log(total_count_forest + 1)]

# Solar facility data for Panel B
uspvdb <- fread(file.path(DATA_DIR, "uspvdb_v3_0_20250430.csv"))

# Routes for spatial re-matching
routes <- fread(file.path(DATA_DIR, "Routes.csv"))
routes_us <- routes[CountryNum == 840]
routes_us[, route_id := paste0(StateNum, "_", Route)]

cat("Panel:", nrow(panel), "rows,", uniqueN(panel$route_id), "routes\n")

# ============================================================
# Run (or reload) main regressions
# ============================================================
cat("\n=== Running regressions ===\n")

# TWFE binary (route + year FE)
twfe_farm <- feols(ln_farm ~ post | route_num + year,
                   data = panel, cluster = ~state_num)

# TWFE binary (route + state x year FE)
twfe_sy <- feols(ln_farm ~ post | route_num + state_num^year,
                 data = panel, cluster = ~state_num)

# Forest placebo
twfe_forest <- feols(ln_forest ~ post | route_num + year,
                     data = panel, cluster = ~state_num)

# CS-DiD
panel_cs <- panel[cohort == 0 | cohort >= 2005]
panel_cs[, route_num := as.integer(factor(route_id))]

cs_result <- att_gt(
  yname = "ln_farm", tname = "year", idname = "route_num",
  gname = "cohort", data = as.data.frame(panel_cs),
  control_group = "notyettreated", anticipation = 0,
  est_method = "dr", base_period = "universal",
  print_details = FALSE
)

agg_overall <- aggte(cs_result, type = "simple", na.rm = TRUE)
agg_dyn     <- aggte(cs_result, type = "dynamic", min_e = -5, max_e = 8, na.rm = TRUE)

# Event study data.table
es_df <- data.table(
  event_time = agg_dyn$egt,
  att        = agg_dyn$att.egt,
  se         = agg_dyn$se.egt,
  ci_lower   = agg_dyn$att.egt - 1.96 * agg_dyn$se.egt,
  ci_upper   = agg_dyn$att.egt + 1.96 * agg_dyn$se.egt
)

# Extract coefficients
b1  <- as.numeric(coef(twfe_farm)["post"])
se1 <- sqrt(as.numeric(vcov(twfe_farm)["post", "post"]))
b2  <- as.numeric(coef(twfe_sy)["post"])
se2 <- sqrt(as.numeric(vcov(twfe_sy)["post", "post"]))
b3  <- agg_overall$overall.att
se3 <- agg_overall$overall.se
b_forest  <- as.numeric(coef(twfe_forest)["post"])
se_forest <- sqrt(as.numeric(vcov(twfe_forest)["post", "post"]))

cat(sprintf("TWFE binary: %.4f (%.4f)\n", b1, se1))
cat(sprintf("TWFE S x Y:  %.4f (%.4f)\n", b2, se2))
cat(sprintf("CS-DiD ATT:  %.4f (%.4f)\n", b3, se3))
cat(sprintf("Forest plac: %.4f (%.4f)\n", b_forest, se_forest))

# ============================================================
# Radius variation (5 km and 20 km)
# ============================================================
cat("\n=== Computing radius-specific TWFE ===\n")

routes_sf  <- st_as_sf(routes_us, coords = c("Longitude", "Latitude"), crs = 4326)
solar_sf   <- st_as_sf(uspvdb[!is.na(ylat) & !is.na(xlong)],
                        coords = c("xlong", "ylat"), crs = 4326)
routes_proj <- st_transform(routes_sf, 5070)
solar_proj  <- st_transform(solar_sf, 5070)
route_coords <- st_coordinates(routes_proj)
solar_coords <- st_coordinates(solar_proj)

run_radius_twfe <- function(radius_km) {
  radius_m <- radius_km * 1000
  treated_routes <- character(0)
  for (i in seq_len(nrow(route_coords))) {
    dx <- solar_coords[, 1] - route_coords[i, 1]
    dy <- solar_coords[, 2] - route_coords[i, 2]
    d  <- sqrt(dx^2 + dy^2)
    if (any(d <= radius_m)) {
      treated_routes <- c(treated_routes, routes_us$route_id[i])
    }
  }
  p <- copy(panel)
  p[, treated_r := as.integer(route_id %in% treated_routes)]
  m <- feols(ln_farm ~ treated_r:post | route_num + year,
             data = p, cluster = ~state_num)
  list(
    coef      = as.numeric(coef(m)[1]),
    se        = sqrt(as.numeric(vcov(m)[1, 1])),
    n_treated = length(treated_routes),
    n_obs     = nrow(p)
  )
}

cat("  5 km radius...\n")
r5 <- run_radius_twfe(5)
cat(sprintf("  5 km: %.4f (%.4f), %d treated\n", r5$coef, r5$se, r5$n_treated))

cat("  20 km radius...\n")
r20 <- run_radius_twfe(20)
cat(sprintf("  20 km: %.4f (%.4f), %d treated\n", r20$coef, r20$se, r20$n_treated))

# 10 km baseline
r10 <- list(coef = b1, se = se1,
            n_treated = uniqueN(panel[treated == 1]$route_id),
            n_obs = nrow(panel))

# ============================================================
# Key quantities
# ============================================================
n_treated   <- uniqueN(panel[treated == 1]$route_id)
n_control   <- uniqueN(panel[treated == 0]$route_id)
n_routes    <- n_treated + n_control
n_obs       <- nrow(panel)
n_cs_obs    <- nrow(panel_cs)
n_cs_treat  <- uniqueN(panel_cs[cohort > 0]$route_id)
sd_ln_farm  <- panel[, sd(ln_farm, na.rm = TRUE)]
sd_ln_forest <- panel[, sd(ln_forest, na.rm = TRUE)]
mean_ln_farm <- panel[, mean(ln_farm, na.rm = TRUE)]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== TABLE 1: Summary Statistics ===\n")

summ_treated <- panel[treated == 1, .(
  mean_farm    = mean(total_count_farmland, na.rm = TRUE),
  sd_farm      = sd(total_count_farmland, na.rm = TRUE),
  mean_forest  = mean(total_count_forest, na.rm = TRUE),
  sd_forest    = sd(total_count_forest, na.rm = TRUE),
  mean_sp_farm = mean(n_species_farmland, na.rm = TRUE),
  sd_sp_farm   = sd(n_species_farmland, na.rm = TRUE),
  n_obs = .N
)]

summ_control <- panel[treated == 0, .(
  mean_farm    = mean(total_count_farmland, na.rm = TRUE),
  sd_farm      = sd(total_count_farmland, na.rm = TRUE),
  mean_forest  = mean(total_count_forest, na.rm = TRUE),
  sd_forest    = sd(total_count_forest, na.rm = TRUE),
  mean_sp_farm = mean(n_species_farmland, na.rm = TRUE),
  sd_sp_farm   = sd(n_species_farmland, na.rm = TRUE),
  n_obs = .N
)]

# Balance t-tests
t_farm   <- t.test(panel[treated == 1]$total_count_farmland,
                   panel[treated == 0]$total_count_farmland)
t_forest <- t.test(panel[treated == 1]$total_count_forest,
                   panel[treated == 0]$total_count_forest)
t_sp     <- t.test(panel[treated == 1]$n_species_farmland,
                   panel[treated == 0]$n_species_farmland)

# Solar facility summary (utility-scale >= 1 MW)
solar_util <- uspvdb[!is.na(p_cap_ac) & p_cap_ac >= 1]
solar_summ <- solar_util[, .(
  mean_mw   = mean(p_cap_ac, na.rm = TRUE),
  sd_mw     = sd(p_cap_ac, na.rm = TRUE),
  median_mw = median(p_cap_ac, na.rm = TRUE),
  mean_year = mean(p_year, na.rm = TRUE),
  sd_year   = sd(p_year, na.rm = TRUE),
  greenfield_share = mean(p_type == "greenfield", na.rm = TRUE),
  n_fac     = .N
)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Treated Routes} & \\multicolumn{2}{c}{Control Routes} & Diff. \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD & $p$-value \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: BBS Route Characteristics}} \\\\\n",
  sprintf("Farmland bird count & %s & %s & %s & %s & %s \\\\\n",
          fmt1(summ_treated$mean_farm), fmt1(summ_treated$sd_farm),
          fmt1(summ_control$mean_farm), fmt1(summ_control$sd_farm),
          fmt(t_farm$p.value, 3)),
  sprintf("Forest bird count & %s & %s & %s & %s & %s \\\\\n",
          fmt1(summ_treated$mean_forest), fmt1(summ_treated$sd_forest),
          fmt1(summ_control$mean_forest), fmt1(summ_control$sd_forest),
          fmt(t_forest$p.value, 3)),
  sprintf("Farmland species richness & %s & %s & %s & %s & %s \\\\\n",
          fmt1(summ_treated$mean_sp_farm), fmt1(summ_treated$sd_sp_farm),
          fmt1(summ_control$mean_sp_farm), fmt1(summ_control$sd_sp_farm),
          fmt(t_sp$p.value, 3)),
  "\\\\[4pt]\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Solar Facility Characteristics}} \\\\\n",
  sprintf("Capacity (MW$_{\\text{AC}}$) & \\multicolumn{2}{c}{%s (%s)} & & & \\\\\n",
          fmt1(solar_summ$mean_mw), fmt1(solar_summ$sd_mw)),
  sprintf("Median capacity (MW$_{\\text{AC}}$) & \\multicolumn{2}{c}{%s} & & & \\\\\n",
          fmt1(solar_summ$median_mw)),
  sprintf("Operational year & \\multicolumn{2}{c}{%s (%s)} & & & \\\\\n",
          formatC(solar_summ$mean_year, format = "f", digits = 1),
          formatC(solar_summ$sd_year, format = "f", digits = 1)),
  sprintf("Greenfield share & \\multicolumn{2}{c}{%s} & & & \\\\\n",
          fmt2(solar_summ$greenfield_share)),
  sprintf("Facilities & \\multicolumn{2}{c}{%s} & & & \\\\\n",
          fmt0(solar_summ$n_fac)),
  "\\midrule\n",
  sprintf("Routes & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\\\\n",
          fmt0(n_treated), fmt0(n_control)),
  sprintf("Route $\\times$ year observations & \\multicolumn{4}{c}{%s} & \\\\\n",
          fmt0(n_obs)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel~A reports mean characteristics of BBS routes within 10~km of a utility-scale solar facility (treated) versus all other routes (control). Farmland and forest bird counts are total individuals observed per route-year; species richness is the number of distinct species. Difference $p$-values from two-sample $t$-tests. Panel~B describes the utility-scale solar facilities ($\\geq$1~MW$_{\\text{AC}}$) from USPVDB v3.0. Greenfield share is the fraction sited on previously undeveloped land. Sample period: 2001--2023.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(TAB_DIR, "tab1_summary.tex"))
cat("Wrote: tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("\n=== TABLE 2: Main Results ===\n")

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Effect of Solar Facilities on Farmland Bird Populations}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & TWFE & TWFE & CS-DiD \\\\\n",
  " & Route + Year & Route + State$\\times$Year & Overall ATT \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ Treated & %s%s & %s%s & %s%s \\\\\n",
          fmt(b1), stars(b1, se1),
          fmt(b2), stars(b2, se2),
          fmt(b3), stars(b3, se3)),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          fmt(se1), fmt(se2), fmt(se3)),
  "\\\\[4pt]\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          fmt0(n_obs), fmt0(n_obs), fmt0(n_cs_obs)),
  sprintf("Treated routes & %s & %s & %s \\\\\n",
          fmt0(n_treated), fmt0(n_treated), fmt0(n_cs_treat)),
  sprintf("Mean dep.\\ var.\\ & %s & %s & %s \\\\\n",
          fmt2(mean_ln_farm), fmt2(mean_ln_farm), fmt2(mean_ln_farm)),
  "Route FE & Yes & Yes & --- \\\\\n",
  "Year FE & Yes & --- & --- \\\\\n",
  "State $\\times$ Year FE & No & Yes & --- \\\\\n",
  "Estimator & TWFE & TWFE & DR \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is $\\ln(\\text{farmland bird count} + 1)$. Columns~(1)--(2) report two-way fixed effects estimates with a binary post-treatment indicator. Column~(1) includes route and year fixed effects; column~(2) replaces year FE with state-by-year FE. Column~(3) reports the Callaway and Sant'Anna (2021) overall average treatment effect on the treated, using doubly-robust estimation with not-yet-treated routes as the control group (cohorts with $\\geq$5 pre-treatment years). Standard errors clustered at the state level in parentheses. $^{***}$, $^{**}$, $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(TAB_DIR, "tab2_main.tex"))
cat("Wrote: tab2_main.tex\n")

# ============================================================
# TABLE 3: Robustness — Radius Variation and Forest Placebo
# ============================================================
cat("\n=== TABLE 3: Robustness ===\n")

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Robustness: Radius Variation and Placebo Species}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & 5~km & 10~km & 20~km & Forest \\\\\n",
  " & Radius & Radius & Radius & Placebo \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ Treated & %s%s & %s%s & %s%s & %s%s \\\\\n",
          fmt(r5$coef),  stars(r5$coef, r5$se),
          fmt(r10$coef), stars(r10$coef, r10$se),
          fmt(r20$coef), stars(r20$coef, r20$se),
          fmt(b_forest), stars(b_forest, se_forest)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          fmt(r5$se), fmt(r10$se), fmt(r20$se), fmt(se_forest)),
  "\\\\[4pt]\n",
  "Dep.\\ variable & $\\ln$(farm) & $\\ln$(farm) & $\\ln$(farm) & $\\ln$(forest) \\\\\n",
  sprintf("Treated routes & %s & %s & %s & %s \\\\\n",
          fmt0(r5$n_treated), fmt0(r10$n_treated),
          fmt0(r20$n_treated), fmt0(r10$n_treated)),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          fmt0(r5$n_obs), fmt0(r10$n_obs),
          fmt0(r20$n_obs), fmt0(r10$n_obs)),
  "Route FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns~(1)--(3) vary the treatment radius around solar facilities: a route is treated if any utility-scale solar installation lies within the specified distance. Column~(2) reproduces the baseline 10~km specification from Table~\\ref{tab:main}. Column~(4) replaces the outcome with $\\ln(\\text{forest bird count} + 1)$ as a placebo test; solar installations on open farmland should not affect forest-interior species if the identification is valid. All specifications include route and year fixed effects. Standard errors clustered at the state level. $^{***}$, $^{**}$, $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(TAB_DIR, "tab3_robustness.tex"))
cat("Wrote: tab3_robustness.tex\n")

# ============================================================
# TABLE 4: Event Study Coefficients (CS-DiD)
# ============================================================
cat("\n=== TABLE 4: Event Study Coefficients ===\n")

es_df <- es_df[order(event_time)]

tab4_rows <- ""
for (i in seq_len(nrow(es_df))) {
  e <- es_df[i]
  if (is.na(e$se) || e$se == 0) {
    tab4_rows <- paste0(tab4_rows, sprintf(
      "%+d & --- & --- & --- \\\\\n", as.integer(e$event_time)))
  } else {
    star_str <- stars(e$att, e$se)
    tab4_rows <- paste0(tab4_rows, sprintf(
      "%+d & %s%s & (%s) & [%s, %s] \\\\\n",
      as.integer(e$event_time),
      fmt(e$att), star_str, fmt(e$se),
      fmt(e$ci_lower), fmt(e$ci_upper)
    ))
  }
}

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Event Study Coefficients: Callaway--Sant'Anna Dynamic Aggregation}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Event Time & ATT & SE & 95\\% CI \\\\\n",
  "\\midrule\n",
  tab4_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is $\\ln(\\text{farmland bird count} + 1)$. Event time is years relative to the first operational solar facility within 10~km. Estimates from Callaway and Sant'Anna (2021) dynamic aggregation using doubly-robust estimation with not-yet-treated control group. Confidence intervals are pointwise at the 95\\% level ($\\pm 1.96 \\times \\text{SE}$). Pre-treatment coefficients (event time $< 0$) test the parallel trends assumption.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(TAB_DIR, "tab4_eventstudy.tex"))
cat("Wrote: tab4_eventstudy.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("\n=== TABLE F1: Standardized Effect Sizes ===\n")

# Panel A: Pooled
sde_twfe      <- b1 / sd_ln_farm
se_sde_twfe   <- se1 / sd_ln_farm
sde_sy        <- b2 / sd_ln_farm
se_sde_sy     <- se2 / sd_ln_farm
sde_cs        <- b3 / sd_ln_farm
se_sde_cs     <- se3 / sd_ln_farm
sde_forest    <- b_forest / sd_ln_forest
se_sde_forest <- se_forest / sd_ln_forest

# Panel B: Heterogeneous by proximity
sde_5km    <- r5$coef / sd_ln_farm
se_sde_5   <- r5$se / sd_ln_farm
sde_20km   <- r20$coef / sd_ln_farm
se_sde_20  <- r20$se / sd_ln_farm

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does utility-scale solar photovoltaic expansion reduce farmland bird populations in nearby areas? ",
  "\\textbf{Policy mechanism:} Utility-scale solar installations convert open agricultural land to photovoltaic arrays, potentially displacing grassland-nesting species through habitat loss, fragmentation, and ecological-trap effects. ",
  "\\textbf{Outcome definition:} Panel~A reports effects on $\\ln(\\text{farmland bird count}+1)$ (TWFE and CS-DiD estimators) and $\\ln(\\text{forest bird count}+1)$ (placebo). Panel~B reports TWFE effects at 5~km (proximate exposure) and 20~km (broad exposure) treatment radii. ",
  "\\textbf{Treatment:} Binary; a BBS route is treated in the year the first utility-scale ($\\geq$1~MW) solar facility becomes operational within the specified radius (10~km baseline). ",
  sprintf("\\textbf{Data:} USGS Breeding Bird Survey (2001--2023) merged with USGS United States Photovoltaic Database v3.0; %s routes, %s route-year observations. ",
          fmt0(n_routes), fmt0(n_obs)),
  "\\textbf{Method:} Two-way fixed effects (route and year FE, state-clustered SE) and Callaway--Sant'Anna (2021) staggered DiD with doubly-robust estimation and not-yet-treated control group. ",
  sprintf("\\textbf{Sample:} Continental US BBS routes with $\\geq$5 survey years during 2001--2023; %s treated, %s control. ",
          fmt0(n_treated), fmt0(n_control)),
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the full-sample standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|\\text{SDE}| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("$\\ln$(farmland), TWFE & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b1), fmt(se1), fmt(sd_ln_farm),
          fmt(sde_twfe, 4), fmt(se_sde_twfe, 4), classify_sde(sde_twfe)),
  sprintf("$\\ln$(farmland), TWFE + S$\\times$Y & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b2), fmt(se2), fmt(sd_ln_farm),
          fmt(sde_sy, 4), fmt(se_sde_sy, 4), classify_sde(sde_sy)),
  sprintf("$\\ln$(farmland), CS-DiD & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b3), fmt(se3), fmt(sd_ln_farm),
          fmt(sde_cs, 4), fmt(se_sde_cs, 4), classify_sde(sde_cs)),
  sprintf("$\\ln$(forest), placebo & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(b_forest), fmt(se_forest), fmt(sd_ln_forest),
          fmt(sde_forest, 4), fmt(se_sde_forest, 4), classify_sde(sde_forest)),
  "\\\\[4pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Proximity)}} \\\\\n",
  sprintf("$\\ln$(farmland), 5~km radius & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(r5$coef), fmt(r5$se), fmt(sd_ln_farm),
          fmt(sde_5km, 4), fmt(se_sde_5, 4), classify_sde(sde_5km)),
  sprintf("$\\ln$(farmland), 20~km radius & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(r20$coef), fmt(r20$se), fmt(sd_ln_farm),
          fmt(sde_20km, 4), fmt(se_sde_20, 4), classify_sde(sde_20km)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(TAB_DIR, "tabF1_sde.tex"))
cat("Wrote: tabF1_sde.tex\n")

# ============================================================
# Summary
# ============================================================
cat("\n=== ALL TABLES GENERATED ===\n")
cat("Output directory:", TAB_DIR, "\n")
for (f in list.files(TAB_DIR, pattern = "\\.tex$")) {
  cat("  ", f, "\n")
}
