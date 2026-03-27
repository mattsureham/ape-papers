## 03_main_analysis.R — Primary DiD analysis
## apep_1036: Tax Office Closures and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

## Load analysis panel
df <- fread(file.path(data_dir, "analysis_panel.csv"))

## Ensure proper types
df[, commune := as.character(commune)]
df[, dep := as.character(dep)]
df[, year := as.integer(year)]
df[, treated := as.integer(treated)]

## Create numeric election period (ordinal for event study)
elec_map <- data.table(
  id_election = c("2002_pres_t1", "2007_pres_t1", "2012_pres_t1",
                   "2014_euro_t1", "2017_pres_t1", "2019_euro_t1",
                   "2022_pres_t1", "2024_euro_t1"),
  period = c(1, 2, 3, 4, 5, 6, 7, 8),
  year_num = c(2002, 2007, 2012, 2014, 2017, 2019, 2022, 2024)
)
df <- merge(df, elec_map[, .(id_election, period)], by = "id_election")

## Closure indicator (ever treated)
df[, ever_closed := as.integer(treatment_group %in% c("early_closure", "late_closure"))]

## =================================================================
## TABLE 1: Summary Statistics
## =================================================================

cat("=== SUMMARY STATISTICS ===\n")
cat("\nSample sizes by treatment group:\n")
print(df[, .(n_communes = uniqueN(commune),
             n_elections = uniqueN(id_election),
             n_obs = .N,
             mean_rn = round(mean(rn_share, na.rm = TRUE), 1),
             mean_turnout = round(mean(turnout, na.rm = TRUE), 1)),
         by = treatment_group])

## =================================================================
## MODEL 1: Simple TWFE DiD
## =================================================================

cat("\n=== MODEL 1: TWFE DiD ===\n")
m1 <- feols(rn_share ~ treated | commune + id_election,
            data = df, cluster = ~dep)
summary(m1)

## =================================================================
## MODEL 2: TWFE with election-type interaction
## =================================================================

cat("\n=== MODEL 2: TWFE with election type ===\n")
m2 <- feols(rn_share ~ treated + i(election_type) | commune + year,
            data = df, cluster = ~dep)
summary(m2)

## =================================================================
## MODEL 3: Event Study (relative to last pre-treatment period)
## =================================================================

cat("\n=== MODEL 3: Event Study ===\n")

## For early closures: treatment at period 7 (2022), so periods 1-6 are pre
## For late closures: treatment at period 8 (2024), so periods 1-7 are pre
## Use 2017 (period 5) as reference (last pre-reform election)

df[, rel_period := fcase(
  treatment_group == "early_closure", as.numeric(period - 7L),
  treatment_group == "late_closure", as.numeric(period - 8L),
  default = NA_real_
)]

## For the event study, focus on closure communes vs retained
## Use sunab() for staggered treatment
df[, first_treated_period := fcase(
  treatment_group == "early_closure", 7L,
  treatment_group == "late_closure", 8L,
  default = 10000L  # never treated (set to large value)
)]

m3 <- feols(rn_share ~ sunab(first_treated_period, period, ref.p = -1) |
              commune + id_election,
            data = df, cluster = ~dep)
cat("\nSun-Abraham event study coefficients:\n")
summary(m3)

## =================================================================
## MODEL 4: Callaway-Sant'Anna
## =================================================================

cat("\n=== MODEL 4: Callaway-Sant'Anna ===\n")

## CS-DiD requires numeric idname
cs_df <- copy(df)
cs_df[, commune_id := as.integer(as.factor(commune))]
cs_df[, gvar := fcase(
  treatment_group == "early_closure", 7L,
  treatment_group == "late_closure", 8L,
  default = 0L  # never treated
)]

## Drop the 1 NA observation
cs_df <- cs_df[!is.na(rn_share)]

## CS-DiD
cs_out <- att_gt(
  yname = "rn_share",
  tname = "period",
  idname = "commune_id",
  gname = "gvar",
  data = cs_df,
  control_group = "nevertreated",
  anticipation = 0,
  bstrap = TRUE,
  cband = TRUE,
  clustervars = "dep"
)

cat("\nCS-DiD group-time ATTs:\n")
summary(cs_out)

## Aggregate to simple ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS-DiD simple ATT:\n")
summary(cs_agg)

## Dynamic aggregation
cs_dyn <- aggte(cs_out, type = "dynamic")
cat("\nCS-DiD dynamic effects:\n")
summary(cs_dyn)

## =================================================================
## DIAGNOSTICS
## =================================================================

cat("\n=== DIAGNOSTICS ===\n")

## Pre-trend test: F-test of pre-treatment event study coefficients
pre_coefs <- coeftable(m3)
pre_rows <- grepl(":-[2-9]|:-1[0-9]", rownames(pre_coefs))
if (sum(pre_rows) > 0) {
  cat("Pre-treatment coefficients:\n")
  print(pre_coefs[pre_rows, , drop = FALSE])
}

## Sample size info for diagnostics.json
n_treated <- uniqueN(df[ever_closed == 1]$commune)
n_control <- uniqueN(df[ever_closed == 0]$commune)
n_pre <- sum(elec_map$year_num < 2022)  # elections before first treatment
n_obs <- nrow(df)

cat("\nSample: ", n_treated, "treated communes, ",
    n_control, "control communes, ",
    n_pre, "pre-treatment elections, ",
    n_obs, "total observations\n")

## Write diagnostics.json
diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control,
  n_elections = length(unique(df$id_election)),
  twfe_coef = round(coef(m1)["treated"], 3),
  twfe_se = round(se(m1)["treated"], 3),
  cs_att = round(cs_agg$overall.att, 3),
  cs_se = round(cs_agg$overall.se, 3)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("diagnostics.json written.\n")

## Save key objects
save(m1, m2, m3, cs_out, cs_agg, cs_dyn, df,
     file = file.path(data_dir, "analysis_results.RData"))

cat("\n03_main_analysis.R complete.\n")
