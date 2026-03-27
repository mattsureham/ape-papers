## 04_robustness.R — Robustness checks
## apep_1036: Tax Office Closures and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

## Load data and results
df <- fread(file.path(data_dir, "analysis_panel.csv"))
df_exp <- fread(file.path(data_dir, "analysis_panel_expanded.csv"))
load(file.path(data_dir, "analysis_results.RData"))

## Ensure types
df[, commune := as.character(commune)]
df[, dep := as.character(dep)]

## Period mapping
elec_map <- data.table(
  id_election = c("2002_pres_t1", "2007_pres_t1", "2012_pres_t1",
                   "2014_euro_t1", "2017_pres_t1", "2019_euro_t1",
                   "2022_pres_t1", "2024_euro_t1"),
  period = c(1, 2, 3, 4, 5, 6, 7, 8)
)
if (!"period" %in% names(df)) df <- merge(df, elec_map, by = "id_election")
df[, ever_closed := as.integer(treatment_group %in% c("early_closure", "late_closure"))]
df[, first_treated_period := fcase(
  treatment_group == "early_closure", 7L,
  treatment_group == "late_closure", 8L,
  default = 10000L
)]

## =================================================================
## ROBUSTNESS 1: Presidential elections only (cleaner identification)
## =================================================================

cat("=== ROB 1: Presidential elections only ===\n")
pres <- df[election_type == "presidential"]
m_pres <- feols(rn_share ~ treated | commune + id_election,
                data = pres, cluster = ~dep)
summary(m_pres)

## =================================================================
## ROBUSTNESS 2: TWFE with commune-specific linear trends
## =================================================================

cat("\n=== ROB 2: Commune-specific linear trends ===\n")
df[, year_num := as.numeric(year)]
m_trend <- feols(rn_share ~ treated | commune[year_num] + id_election,
                 data = df, cluster = ~dep)
summary(m_trend)

## =================================================================
## ROBUSTNESS 3: CS-DiD with retained as never-treated (properly)
## =================================================================

cat("\n=== ROB 3: CS-DiD (retained as never-treated) ===\n")
cs_df2 <- copy(df)
cs_df2[, commune_id := as.integer(as.factor(commune))]
cs_df2[, gvar := as.numeric(fcase(
  treatment_group == "early_closure", 7,
  treatment_group == "late_closure", 8,
  default = 0  # retained = never-treated
))]
cs_df2 <- cs_df2[!is.na(rn_share)]

cs_out2 <- tryCatch({
  att_gt(
    yname = "rn_share",
    tname = "period",
    idname = "commune_id",
    gname = "gvar",
    data = cs_df2,
    control_group = "nevertreated",
    anticipation = 0,
    bstrap = TRUE,
    cband = TRUE,
    clustervars = "dep"
  )
}, error = function(e) {
  cat("CS-DiD with retained failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out2)) {
  cs_agg2 <- aggte(cs_out2, type = "simple")
  cat("\nCS-DiD (retained control) simple ATT:\n")
  summary(cs_agg2)
  cat("\nPre-test p-value:", cs_out2$Wpval, "\n")
}

## =================================================================
## ROBUSTNESS 4: Placebo outcome — turnout
## =================================================================

cat("\n=== ROB 4: Placebo — Turnout ===\n")
m_turnout <- feols(turnout ~ treated | commune + id_election,
                   data = df, cluster = ~dep)
summary(m_turnout)

## =================================================================
## ROBUSTNESS 5: Placebo — left-wing vote share
## =================================================================

cat("\n=== ROB 5: Left-wing vote share ===\n")
## Re-read candidate data to build left-wing share
cand <- as.data.table(arrow::read_parquet(file.path(data_dir, "candidats_results.parquet")))

elections <- c("2002_pres_t1", "2007_pres_t1", "2012_pres_t1", "2017_pres_t1", "2022_pres_t1",
               "2014_euro_t1", "2019_euro_t1", "2024_euro_t1")
cand_sub <- cand[id_election %in% elections]
cand_sub[, commune := code_commune]

## Left-wing: PS, LFI, PCF, EELV nuances
left_nuances <- c("SOC", "FI", "COM", "VEC", "ECO", "EXG", "DVG",
                   "LSOC", "LFI", "LCOM", "LVEC", "LECO", "LEXG", "LDVG",
                   "RDG", "UG", "LUG")
cand_sub[, is_left := toupper(nuance) %in% left_nuances]

## For presidential: identify by name
cand_sub[id_election == "2002_pres_t1" & toupper(nom) == "JOSPIN", is_left := TRUE]
cand_sub[id_election == "2007_pres_t1" & toupper(nom) == "ROYAL", is_left := TRUE]
cand_sub[id_election == "2012_pres_t1" & toupper(nom) == "HOLLANDE", is_left := TRUE]
cand_sub[id_election == "2017_pres_t1" & toupper(nom) %in% c("HAMON", "MELENCHON"), is_left := TRUE]
cand_sub[id_election == "2022_pres_t1" & toupper(nom) == "MELENCHON", is_left := TRUE]

left_votes <- cand_sub[is_left == TRUE,
                        .(left_voix = sum(voix, na.rm = TRUE)),
                        by = .(id_election, commune)]

gen <- as.data.table(arrow::read_parquet(file.path(data_dir, "general_results.parquet")))
gen_sub <- gen[id_election %in% elections]
gen_sub[, commune := code_commune]
total <- gen_sub[, .(exprimes = sum(exprimes, na.rm = TRUE)), by = .(id_election, commune)]

left_df <- merge(total, left_votes, by = c("id_election", "commune"), all.x = TRUE)
left_df[is.na(left_voix), left_voix := 0]
left_df[, left_share := left_voix / exprimes * 100]

## Merge with treatment
left_df <- merge(left_df, unique(df[, .(commune, treatment_group, dep, treated, year, id_election)]),
                 by = c("id_election", "commune"))

m_left <- feols(left_share ~ treated | commune + id_election,
                data = left_df, cluster = ~dep)
cat("Left-wing vote share (TWFE):\n")
summary(m_left)

## =================================================================
## ROBUSTNESS 6: Expanded sample with never-had-office communes
## =================================================================

cat("\n=== ROB 6: Expanded sample ===\n")
df_exp[, commune := as.character(commune)]
df_exp[, dep := as.character(dep)]

m_exp <- feols(rn_share ~ treated | commune + id_election,
               data = df_exp, cluster = ~dep)
summary(m_exp)

## =================================================================
## ROBUSTNESS 7: Leave-one-département-out
## =================================================================

cat("\n=== ROB 7: Leave-one-département-out ===\n")
deps <- unique(df$dep)
loo_coefs <- numeric(length(deps))
names(loo_coefs) <- deps
for (d in deps) {
  m_loo <- feols(rn_share ~ treated | commune + id_election,
                 data = df[dep != d], cluster = ~dep)
  loo_coefs[d] <- coef(m_loo)["treated"]
}
cat("LOO coefficient range:", round(range(loo_coefs), 3), "\n")
cat("LOO mean:", round(mean(loo_coefs), 3), "\n")

## =================================================================
## Save robustness results
## =================================================================

rob_results <- list(
  pres_only = list(coef = coef(m_pres)["treated"], se = se(m_pres)["treated"]),
  trend_adjusted = list(coef = coef(m_trend)["treated"], se = se(m_trend)["treated"]),
  turnout_placebo = list(coef = coef(m_turnout)["treated"], se = se(m_turnout)["treated"]),
  left_placebo = list(coef = coef(m_left)["treated"], se = se(m_left)["treated"]),
  expanded = list(coef = coef(m_exp)["treated"], se = se(m_exp)["treated"]),
  loo_range = range(loo_coefs)
)

if (!is.null(cs_out2)) {
  rob_results$cs_retained <- list(att = cs_agg2$overall.att, se = cs_agg2$overall.se,
                                   pretest_p = cs_out2$Wpval)
}

save(rob_results, m_pres, m_trend, m_turnout, m_left, m_exp, cs_out2,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n04_robustness.R complete.\n")
