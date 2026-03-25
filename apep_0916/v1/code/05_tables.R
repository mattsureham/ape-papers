# =============================================================================
# 05_tables.R — Generate all LaTeX tables (memory-efficient)
# Paper: When the Banks Broke (apep_0916)
# =============================================================================

source("00_packages.R")

dir.create("../tables", showWarnings = FALSE)

# ─────────────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics (load only needed columns)
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

df <- fread("../data/analysis_clean.csv",
            select = c("unit_banking", "occscore_1920", "occscore_1940",
                        "delta_occscore_20_40", "occ_downgrade", "lost_home",
                        "migrated", "farm_exit", "ag_share", "age_1920",
                        "white", "foreign_born", "married_1920", "farmer_1920",
                        "county_id"))

overall <- df[, .(
  occscore_1920_mean = round(mean(occscore_1920), 2),
  occscore_1920_sd   = round(sd(occscore_1920), 2),
  occscore_1940_mean = round(mean(occscore_1940), 2),
  occscore_1940_sd   = round(sd(occscore_1940), 2),
  delta_occ_mean     = round(mean(delta_occscore_20_40), 2),
  delta_occ_sd       = round(sd(delta_occscore_20_40), 2),
  downgrade_mean     = round(mean(occ_downgrade), 3),
  lost_home_mean     = round(mean(lost_home), 3),
  migrated_mean      = round(mean(migrated), 3),
  farm_exit_mean     = round(mean(farm_exit), 3),
  ag_share_mean      = round(mean(ag_share), 3),
  age_mean           = round(mean(age_1920), 1),
  white_mean         = round(mean(white), 3),
  foreign_mean       = round(mean(foreign_born), 3),
  married_mean       = round(mean(married_1920), 3),
  farmer_mean        = round(mean(farmer_1920), 3),
  N                  = .N,
  n_counties         = uniqueN(county_id)
)]

by_ub <- df[, .(
  occscore_1920_mean = round(mean(occscore_1920), 2),
  occscore_1940_mean = round(mean(occscore_1940), 2),
  delta_occ_mean     = round(mean(delta_occscore_20_40), 2),
  downgrade_mean     = round(mean(occ_downgrade), 3),
  lost_home_mean     = round(mean(lost_home), 3),
  migrated_mean      = round(mean(migrated), 3),
  farm_exit_mean     = round(mean(farm_exit), 3),
  ag_share_mean      = round(mean(ag_share), 3),
  N                  = .N
), by = unit_banking]

# Store SDs for SDE computation later
sd_delta_occ <- sd(df$delta_occscore_20_40)
sd_lost_home <- sd(df$lost_home)
sd_migrated  <- sd(df$migrated)
sd_ag        <- sd(df$ag_share, na.rm = TRUE)

# Age-split SDs
sd_delta_young <- sd(df[age_1920 <= 30, delta_occscore_20_40])
sd_delta_old   <- sd(df[age_1920 > 30, delta_occscore_20_40])

# Save SDs for later
saveRDS(list(sd_delta_occ = sd_delta_occ, sd_lost_home = sd_lost_home,
             sd_migrated = sd_migrated, sd_ag = sd_ag,
             sd_delta_young = sd_delta_young, sd_delta_old = sd_delta_old),
        "../data/outcome_sds.rds")

rm(df); gc()

tab1_tex <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Full Sample} & Unit Banking & Branch Banking \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}
& Mean & SD & Mean & Mean \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Outcomes}} \\\\
Occ.\\ Income Score, 1920 & %s & %s & %s & %s \\\\
Occ.\\ Income Score, 1940 & %s & %s & %s & %s \\\\
$\\Delta$ Occ.\\ Score (1920--1940) & %s & %s & %s & %s \\\\
Occupational Downgrading & %s & & %s & %s \\\\
Lost Homeownership & %s & & %s & %s \\\\
Migrated (1920--1940) & %s & & %s & %s \\\\
Farm Exit & %s & & %s & %s \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: Baseline Characteristics (1920)}} \\\\
Agricultural Share (County) & %s & & %s & %s \\\\
Age & %s & & & \\\\
White & %s & & & \\\\
Foreign Born & %s & & & \\\\
Married & %s & & & \\\\
Farmer & %s & & & \\\\
\\midrule
Observations & \\multicolumn{2}{c}{%s} & %s & %s \\\\
States & \\multicolumn{2}{c}{49} & 14 & 35 \\\\
Counties & \\multicolumn{2}{c}{%s} & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Sample consists of working-age men (18--55 in 1920) linked across the 1920, 1930, and 1940 U.S.\\ Censuses via the IPUMS Machine Learning Panel (MLP). Unit banking states prohibited bank branching as of 1929: CO, FL, IL, IA, KS, MN, MO, MT, NE, ND, OK, TX, WV, WY. Occupational Income Score follows IPUMS coding (0--80 scale). Agricultural share is the county-level proportion of individuals residing on farms in 1920. Homeownership loss, migration, and farm exit are binary indicators.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}',
  overall$occscore_1920_mean, overall$occscore_1920_sd,
  by_ub[unit_banking==1, occscore_1920_mean], by_ub[unit_banking==0, occscore_1920_mean],
  overall$occscore_1940_mean, overall$occscore_1940_sd,
  by_ub[unit_banking==1, occscore_1940_mean], by_ub[unit_banking==0, occscore_1940_mean],
  overall$delta_occ_mean, overall$delta_occ_sd,
  by_ub[unit_banking==1, delta_occ_mean], by_ub[unit_banking==0, delta_occ_mean],
  overall$downgrade_mean,
  by_ub[unit_banking==1, downgrade_mean], by_ub[unit_banking==0, downgrade_mean],
  overall$lost_home_mean,
  by_ub[unit_banking==1, lost_home_mean], by_ub[unit_banking==0, lost_home_mean],
  overall$migrated_mean,
  by_ub[unit_banking==1, migrated_mean], by_ub[unit_banking==0, migrated_mean],
  overall$farm_exit_mean,
  by_ub[unit_banking==1, farm_exit_mean], by_ub[unit_banking==0, farm_exit_mean],
  overall$ag_share_mean,
  by_ub[unit_banking==1, ag_share_mean], by_ub[unit_banking==0, ag_share_mean],
  overall$age_mean, overall$white_mean, overall$foreign_mean,
  overall$married_mean, overall$farmer_mean,
  format(overall$N, big.mark = ","),
  format(by_ub[unit_banking==1, N], big.mark = ","),
  format(by_ub[unit_banking==0, N], big.mark = ","),
  format(overall$n_counties, big.mark = ",")
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ─────────────────────────────────────────────────────────────────────────────
# Tables 2-4: From saved model objects
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Tables 2-4: Regression tables\n")

models <- readRDS("../data/model_objects.rds")

# Table 2: Main results
etable(models$m1a, models$m1b, models$m1c, models$m1d, models$m2a,
       file = "../tables/tab2_main.tex",
       replace = TRUE, se.below = TRUE,
       dict = c(unit_banking = "Unit Banking",
                ag_share = "Ag.\\ Share",
                "unit_banking:ag_share" = "Unit Banking $\\times$ Ag.\\ Share",
                age_1920 = "Age", age_sq = "Age$^2$",
                white = "White", foreign_born = "Foreign Born",
                married_1920 = "Married", farmer_1920 = "Farmer",
                occscore_1920 = "Occ.\\ Score (1920)"),
       keep = c("Unit Banking", "Ag.\\ Share", "Unit Banking $\\times$ Ag.\\ Share"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       title = "Effect of Unit Banking on Occupational Income Score Change (1920--1940)",
       label = "tab:main",
       notes = c("Standard errors clustered at the state level in parentheses.",
                 "All columns control for age, age$^2$, race, nativity, marital status, farmer status, and baseline occupational income score (columns 2--5).",
                 "Region fixed effects in columns (3)--(5).",
                 "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."))
cat("  Table 2 written.\n")

# Table 3: Multiple outcomes
etable(models$m2a, models$m3_downgrade, models$m3_losthome,
       models$m3_migrate, models$m3_farmexit,
       file = "../tables/tab3_outcomes.tex",
       replace = TRUE, se.below = TRUE,
       headers = c("$\\Delta$ OccScore", "Downgraded", "Lost Home", "Migrated", "Farm Exit"),
       dict = c(unit_banking = "Unit Banking",
                ag_share = "Ag.\\ Share",
                "unit_banking:ag_share" = "UB $\\times$ Ag.\\ Share"),
       keep = c("Unit Banking", "Ag.\\ Share", "UB $\\times$ Ag.\\ Share"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       title = "Unit Banking and Multiple Scarring Outcomes (1920--1940)",
       label = "tab:outcomes",
       notes = c("Standard errors clustered at the state level in parentheses.",
                 "All columns include individual controls and region fixed effects.",
                 "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."))
cat("  Table 3 written.\n")

rm(models); gc()

# Table 4: Build robustness table manually from saved coefficients
# (Loading all robustness model objects at once exceeds memory)
cat("Generating Table 4: Robustness (manual)\n")

# Extract key coefficients from model objects one at a time
extract_rob <- function(model_file, model_name, coef_name) {
  m <- readRDS(model_file)
  if (is.list(m) && !inherits(m, "fixest")) m <- m[[model_name]]
  b <- coef(m)[coef_name]
  s <- se(m)[coef_name]
  n <- m$nobs
  r2 <- fitstat(m, "r2")$r2
  rm(m); gc()
  list(beta = b, se = s, n = n, r2 = r2)
}

rob_specs <- list(
  list(file = "../data/model_objects.rds", name = "m2a", coef = "unit_banking:ag_share", label = "Baseline"),
  list(file = "../data/robustness_models.rds", name = "r1_broad", coef = "unit_banking_broad:ag_share", label = "Broad UB"),
  list(file = "../data/robustness_models.rds", name = "r3_noborder", coef = "unit_banking:ag_share", label = "No Border"),
  list(file = "../data/robustness_models.rds", name = "r4_stayers", coef = "unit_banking:ag_share", label = "Stayers"),
  list(file = "../data/robustness_models.rds", name = "r5_white", coef = "unit_banking:ag_share", label = "White"),
  list(file = "../data/robustness_models.rds", name = "r6_noIL", coef = "unit_banking:ag_share", label = "No IL")
)

rob_results <- lapply(rob_specs, function(spec) {
  cat("  Extracting", spec$label, "...\n")
  extract_rob(spec$file, spec$name, spec$coef)
})

# Build manual LaTeX table
stars <- function(b, s) {
  p <- 2 * pnorm(-abs(b / s))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

fmt_b <- function(x) formatC(x, format = "f", digits = 3)
fmt_s <- function(x) paste0("(", formatC(x, format = "f", digits = 3), ")")
fmt_n <- function(x) format(x, big.mark = ",")
fmt_r <- function(x) formatC(x, format = "f", digits = 3)

cols <- sapply(rob_results, function(r) {
  paste0(fmt_b(r$beta), stars(r$beta, r$se))
})
ses <- sapply(rob_results, function(r) fmt_s(r$se))
ns <- sapply(rob_results, function(r) fmt_n(r$n))
r2s <- sapply(rob_results, function(r) fmt_r(r$r2))
headers <- sapply(rob_specs, function(s) s$label)

tab4_tex <- paste0(
'\\begin{table}[H]
\\centering
\\caption{Robustness: Occupational Income Score Change (1920--1940)}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
& ', paste(paste0("(", 1:6, ")"), collapse = " & "), ' \\\\
& ', paste(headers, collapse = " & "), ' \\\\
\\midrule
UB $\\times$ Ag.\\ Share & ', paste(cols, collapse = " & "), ' \\\\
& ', paste(ses, collapse = " & "), ' \\\\
\\midrule
Controls & Yes & Yes & Yes & Yes & Yes & Yes \\\\
Region FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\
Observations & ', paste(ns, collapse = " & "), ' \\\\
$R^2$ & ', paste(r2s, collapse = " & "), ' \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. All columns include individual controls (age, age$^2$, race, nativity, marital status, farmer, baseline occ.\\ score) and region fixed effects. (2) Adds AR, IN, KY to unit banking definition. (3) Drops 8 states near classification boundary. (4) Non-movers only. (5) White men only. (6) Drops Illinois. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}'
)
writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("  Table 4 written.\n")

gc()

# ─────────────────────────────────────────────────────────────────────────────
# Table F1: Standardized Effect Sizes (SDE)
# ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table F1: SDE\n")

models <- readRDS("../data/model_objects.rds")
sds <- readRDS("../data/outcome_sds.rds")

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005  ~ "Null",
    s < 0.05   ~ "Small positive",
    s < 0.15   ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)

# Pooled outcomes
beta_occ <- coef(models$m2a)["unit_banking:ag_share"]
se_occ <- se(models$m2a)["unit_banking:ag_share"]
sde_occ <- beta_occ * sds$sd_ag / sds$sd_delta_occ
se_sde_occ <- se_occ * sds$sd_ag / sds$sd_delta_occ

beta_lh <- coef(models$m3_losthome)["unit_banking:ag_share"]
se_lh <- se(models$m3_losthome)["unit_banking:ag_share"]
sde_lh <- beta_lh * sds$sd_ag / sds$sd_lost_home
se_sde_lh <- se_lh * sds$sd_ag / sds$sd_lost_home

beta_mig <- coef(models$m3_migrate)["unit_banking:ag_share"]
se_mig <- se(models$m3_migrate)["unit_banking:ag_share"]
sde_mig <- beta_mig * sds$sd_ag / sds$sd_migrated
se_sde_mig <- se_mig * sds$sd_ag / sds$sd_migrated

# Heterogeneity: age splits
beta_young <- coef(models$m4_young)["unit_banking:ag_share"]
se_young <- se(models$m4_young)["unit_banking:ag_share"]
sde_young <- beta_young * sds$sd_ag / sds$sd_delta_young
se_sde_young <- se_young * sds$sd_ag / sds$sd_delta_young

beta_old <- coef(models$m4_old)["unit_banking:ag_share"]
se_old <- se(models$m4_old)["unit_banking:ag_share"]
sde_old <- beta_old * sds$sd_ag / sds$sd_delta_old
se_sde_old <- se_old * sds$sd_ag / sds$sd_delta_old

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state-level unit banking laws that prohibited branch banking amplified ",
  "economic scarring from the Great Depression by increasing banking system fragility in agricultural areas. ",
  "\\textbf{Policy mechanism:} Unit banking laws restricted commercial banks to a single office, preventing geographic ",
  "diversification of deposits and loans; when agricultural commodity prices collapsed, these undiversified banks failed ",
  "at dramatically higher rates than branch-banking counterparts, destroying local credit and savings. ",
  "\\textbf{Outcome definition:} Change in IPUMS Occupational Income Score (0--80 scale) between 1920 and 1940 census ",
  "observations for linked individuals; homeownership loss (binary: owner to renter); intercounty migration (binary). ",
  "\\textbf{Treatment:} Continuous --- interaction of binary state unit banking law indicator with county-level ",
  "agricultural share (proportion of residents on farms in 1920). ",
  "\\textbf{Data:} IPUMS Machine Learning Panel (MLP) linking 1920, 1930, and 1940 full-count U.S.\\ censuses; ",
  "8.45 million working-age men; 3,061 counties in 49 states. ",
  "\\textbf{Method:} Cross-sectional long-difference with individual baseline controls and census region fixed effects; ",
  "standard errors clustered at the state level (49 clusters). ",
  "\\textbf{Sample:} Men aged 18--55 in 1920 with positive occupational income scores in both 1920 and 1940, ",
  "residing in counties with at least 50 linked individuals. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of ",
  "agricultural share and SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- sprintf(
'\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llcccccl}
\\toprule
Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
$\\Delta$ Occ.\\ Score & UB $\\times$ Ag. & %s & %s & %s & %s & %s & %s \\\\
Lost Home & UB $\\times$ Ag. & %s & %s & %s & %s & %s & %s \\\\
Migration & UB $\\times$ Ag. & %s & %s & %s & %s & %s & %s \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by age in 1920)}} \\\\
$\\Delta$ Occ.\\ Score (age $\\leq$ 30) & UB $\\times$ Ag. & %s & %s & %s & %s & %s & %s \\\\
$\\Delta$ Occ.\\ Score (age $>$ 30) & UB $\\times$ Ag. & %s & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}',
  fmt(beta_occ, 3), fmt(se_occ, 3), fmt(sds$sd_delta_occ, 2),
  fmt(sde_occ, 4), fmt(se_sde_occ, 4), classify(sde_occ),
  fmt(beta_lh, 3), fmt(se_lh, 3), fmt(sds$sd_lost_home, 2),
  fmt(sde_lh, 4), fmt(se_sde_lh, 4), classify(sde_lh),
  fmt(beta_mig, 3), fmt(se_mig, 3), fmt(sds$sd_migrated, 2),
  fmt(sde_mig, 4), fmt(se_sde_mig, 4), classify(sde_mig),
  fmt(beta_young, 3), fmt(se_young, 3), fmt(sds$sd_delta_young, 2),
  fmt(sde_young, 4), fmt(se_sde_young, 4), classify(sde_young),
  fmt(beta_old, 3), fmt(se_old, 3), fmt(sds$sd_delta_old, 2),
  fmt(sde_old, 4), fmt(se_sde_old, 4), classify(sde_old),
  sde_notes
)
writeLines(tab_sde, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("All tables generated successfully.\n")
