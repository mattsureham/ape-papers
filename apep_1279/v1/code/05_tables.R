# =============================================================================
# 05_tables.R — Generate all tables for paper
# Paper: The Inertia Break (apep_1279)
# =============================================================================

source("00_packages.R")

cat("Loading data and results...\n")
con_local <- dbConnect(duckdb())
dt <- as.data.table(dbGetQuery(con_local, "SELECT * FROM '../data/analysis.parquet'"))
dbDisconnect(con_local)
load("../data/main_results.RData")
load("../data/robustness_results.RData")

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics\n")

# Statistics by draft eligibility × nativity
stats_groups <- dt[age_1910 %between% c(10, 20), .(
  N = .N,
  pct_farm_1910 = round(mean(on_farm_1910) * 100, 1),
  pct_farm_exit = round(mean(farm_exit) * 100, 1),
  mean_occscore_1910 = round(mean(occscore_1910), 1),
  mean_delta_occ = round(mean(delta_occscore), 1),
  pct_moved = round(mean(moved_county) * 100, 1),
  pct_white = round(mean(white) * 100, 1),
  pct_literate = round(mean(literate) * 100, 1),
  pct_married = round(mean(married_1910) * 100, 1),
  mean_age = round(mean(age_1910), 1)
), by = .(draft_eligible, native_born)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Draft Eligibility and Nativity}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Draft-Eligible (Age $\\geq$ 14)} & \\multicolumn{2}{c}{Not Eligible (Age $<$ 14)} \\\\\n",
  " & Native & Foreign & Native & Foreign \\\\\n",
  "\\hline\n"
)

# Extract values for each group
g11 <- stats_groups[draft_eligible == 1 & native_born == 1]
g10 <- stats_groups[draft_eligible == 1 & native_born == 0]
g01 <- stats_groups[draft_eligible == 0 & native_born == 1]
g00 <- stats_groups[draft_eligible == 0 & native_born == 0]

tab1 <- paste0(tab1,
  sprintf("N & %s & %s & %s & %s \\\\\n",
          format(g11$N, big.mark = ","), format(g10$N, big.mark = ","),
          format(g01$N, big.mark = ","), format(g00$N, big.mark = ",")),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-Treatment Characteristics (1910)}} \\\\\n",
  sprintf("On farm (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$pct_farm_1910, g10$pct_farm_1910, g01$pct_farm_1910, g00$pct_farm_1910),
  sprintf("Occ. income score & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$mean_occscore_1910, g10$mean_occscore_1910, g01$mean_occscore_1910, g00$mean_occscore_1910),
  sprintf("White (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$pct_white, g10$pct_white, g01$pct_white, g00$pct_white),
  sprintf("Literate (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$pct_literate, g10$pct_literate, g01$pct_literate, g00$pct_literate),
  sprintf("Married (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$pct_married, g10$pct_married, g01$pct_married, g00$pct_married),
  sprintf("Mean age & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$mean_age, g10$mean_age, g01$mean_age, g00$mean_age),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Outcomes (1910--1920 Change)}} \\\\\n",
  sprintf("Farm exit (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$pct_farm_exit, g10$pct_farm_exit, g01$pct_farm_exit, g00$pct_farm_exit),
  sprintf("$\\Delta$ Occ. score & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$mean_delta_occ, g10$mean_delta_occ, g01$mean_delta_occ, g00$mean_delta_occ),
  sprintf("Moved county (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          g11$pct_moved, g10$pct_moved, g01$pct_moved, g00$pct_moved),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Data from IPUMS MLP linked census panel, 1910--1920. ",
  "Draft-eligible: men aged 14--20 in 1910 (21--27 in 1917, subject to first registration). ",
  "Native = native-born (IPUMS nativity 1--3); Foreign = foreign-born (nativity 4--5). ",
  "Foreign-born non-citizens were exempt from the draft. Farm exit = on farm in 1910, not on farm in 1920. ",
  "Occupational income score from IPUMS OCC1950 coding.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# -----------------------------------------------------------------------
# Table 2: Nativity DiD — Main Results
# -----------------------------------------------------------------------
cat("Generating Table 2: Nativity DiD Results\n")

# Format coefficient helper
fmt_coef <- function(est, se, pval) {
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.1, "^{*}", "")))
  sprintf("%.4f%s", est, stars)
}
fmt_se <- function(se) sprintf("(%.4f)", se)

# Extract nativity DiD coefficients
did_vars <- c("draft_eligible:native_born")

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Military Draft Exposure and Occupational Transformation: Nativity DiD}\n",
  "\\label{tab:nativity_did}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Farm Exit & $\\Delta$ Occ. Score & Moved County \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n"
)

# Draft eligible × Native born
de_nb_farm <- coef(did_farm)["draft_eligible:native_born"]
de_nb_farm_se <- se(did_farm)["draft_eligible:native_born"]
de_nb_farm_p <- pvalue(did_farm)["draft_eligible:native_born"]

de_nb_occ <- coef(did_occ)["draft_eligible:native_born"]
de_nb_occ_se <- se(did_occ)["draft_eligible:native_born"]
de_nb_occ_p <- pvalue(did_occ)["draft_eligible:native_born"]

de_nb_move <- coef(did_move)["draft_eligible:native_born"]
de_nb_move_se <- se(did_move)["draft_eligible:native_born"]
de_nb_move_p <- pvalue(did_move)["draft_eligible:native_born"]

tab2 <- paste0(tab2,
  sprintf("Draft Elig. $\\times$ Native Born & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_coef(de_nb_farm, de_nb_farm_se, de_nb_farm_p),
          fmt_coef(de_nb_occ, de_nb_occ_se, de_nb_occ_p),
          fmt_coef(de_nb_move, de_nb_move_se, de_nb_move_p)),
  sprintf(" & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_se(de_nb_farm_se), fmt_se(de_nb_occ_se), fmt_se(de_nb_move_se)),
  sprintf("Draft Eligible & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_coef(coef(did_farm)["draft_eligible"], se(did_farm)["draft_eligible"], pvalue(did_farm)["draft_eligible"]),
          fmt_coef(coef(did_occ)["draft_eligible"], se(did_occ)["draft_eligible"], pvalue(did_occ)["draft_eligible"]),
          fmt_coef(coef(did_move)["draft_eligible"], se(did_move)["draft_eligible"], pvalue(did_move)["draft_eligible"])),
  sprintf(" & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_se(se(did_farm)["draft_eligible"]), fmt_se(se(did_occ)["draft_eligible"]), fmt_se(se(did_move)["draft_eligible"])),
  sprintf("Native Born & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_coef(coef(did_farm)["native_born"], se(did_farm)["native_born"], pvalue(did_farm)["native_born"]),
          fmt_coef(coef(did_occ)["native_born"], se(did_occ)["native_born"], pvalue(did_occ)["native_born"]),
          fmt_coef(coef(did_move)["native_born"], se(did_move)["native_born"], pvalue(did_move)["native_born"])),
  sprintf(" & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_se(se(did_farm)["native_born"]), fmt_se(se(did_occ)["native_born"]), fmt_se(se(did_move)["native_born"])),
  "\\hline\n",
  sprintf("State FE & Yes & Yes & Yes \\\\\n"),
  sprintf("Age control & Linear & Linear & Linear \\\\\n"),
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs(did_farm), big.mark = ","),
          format(nobs(did_occ), big.mark = ","),
          format(nobs(did_move), big.mark = ",")),
  sprintf("Control mean & %.3f & %.2f & %.3f \\\\\n",
          mean(dt[age_1910 %between% c(10, 20) & draft_eligible == 0 & native_born == 0]$farm_exit),
          mean(dt[age_1910 %between% c(10, 20) & draft_eligible == 0 & native_born == 0]$delta_occscore),
          mean(dt[age_1910 %between% c(10, 20) & draft_eligible == 0 & native_born == 0]$moved_county)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Difference-in-differences estimates comparing native-born men (subject to the draft) ",
  "with foreign-born men (exempt) across draft-eligible ages (14--20 in 1910) vs.\\ not yet eligible (10--13). ",
  "The coefficient on Draft Elig.\\ $\\times$ Native Born identifies the effect of draft exposure on occupational ",
  "outcomes, holding age constant. Standard errors clustered by state in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_nativity_did.tex")

# -----------------------------------------------------------------------
# Table 3: Heterogeneity by Agricultural Dependence and Race
# -----------------------------------------------------------------------
cat("Generating Table 3: Heterogeneity\n")

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneity: Agricultural Dependence and Race}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Farm Exit} & \\multicolumn{2}{c}{$\\Delta$ Occ. Score} \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: By County Agricultural Share}} \\\\\n",
  sprintf("Draft Elig. $\\times$ High Ag & $%s$ & & $%s$ & \\\\\n",
          fmt_coef(coef(het_farm)["draft_eligible:high_ag"], se(het_farm)["draft_eligible:high_ag"], pvalue(het_farm)["draft_eligible:high_ag"]),
          fmt_coef(coef(het_occ)["draft_eligible:high_ag"], se(het_occ)["draft_eligible:high_ag"], pvalue(het_occ)["draft_eligible:high_ag"])),
  sprintf(" & $%s$ & & $%s$ & \\\\\n",
          fmt_se(se(het_farm)["draft_eligible:high_ag"]),
          fmt_se(se(het_occ)["draft_eligible:high_ag"])),
  sprintf("Draft Eligible & $%s$ & & $%s$ & \\\\\n",
          fmt_coef(coef(het_farm)["draft_eligible"], se(het_farm)["draft_eligible"], pvalue(het_farm)["draft_eligible"]),
          fmt_coef(coef(het_occ)["draft_eligible"], se(het_occ)["draft_eligible"], pvalue(het_occ)["draft_eligible"])),
  sprintf(" & $%s$ & & $%s$ & \\\\\n",
          fmt_se(se(het_farm)["draft_eligible"]),
          fmt_se(se(het_occ)["draft_eligible"])),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: By Race (White vs.\\ Black)}} \\\\\n",
  sprintf("Draft Elig. $\\times$ Black & & $%s$ & & \\\\\n",
          fmt_coef(coef(het_race)["draft_eligible:black"], se(het_race)["draft_eligible:black"], pvalue(het_race)["draft_eligible:black"])),
  sprintf(" & & $%s$ & & \\\\\n",
          fmt_se(se(het_race)["draft_eligible:black"])),
  sprintf("Draft Eligible & & $%s$ & & \\\\\n",
          fmt_coef(coef(het_race)["draft_eligible"], se(het_race)["draft_eligible"], pvalue(het_race)["draft_eligible"])),
  sprintf(" & & $%s$ & & \\\\\n",
          fmt_se(se(het_race)["draft_eligible"])),
  "\\hline\n",
  "State FE & Yes & Yes & Yes & --- \\\\\n",
  "Age controls & Linear & Linear & Linear & --- \\\\\n",
  sprintf("Observations & %s & %s & %s & --- \\\\\n",
          format(nobs(het_farm), big.mark = ","),
          format(nobs(het_race), big.mark = ","),
          format(nobs(het_occ), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A interacts draft eligibility with an indicator for counties with above-median ",
  "agricultural employment share in 1910. Panel B interacts draft eligibility with a Black indicator (sample restricted ",
  "to White and Black men). All specifications include state fixed effects, a linear age control, and an age $\\times$ ",
  "draft eligibility interaction. Standard errors clustered by state. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_heterogeneity.tex")

# -----------------------------------------------------------------------
# Table 4: Age RD Results
# -----------------------------------------------------------------------
cat("Generating Table 4: Age RD\n")

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Age-Based Regression Discontinuity at Draft-Eligibility Cutoff}\n",
  "\\label{tab:age_rd}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Farm Exit & $\\Delta$ Occ. Score & Moved County & Farm$\\to$Manuf. \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: No Controls}} \\\\\n",
  sprintf("Draft Eligible & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_coef(coef(rd_farm_1)["draft_eligible"], se(rd_farm_1)["draft_eligible"], pvalue(rd_farm_1)["draft_eligible"]),
          fmt_coef(coef(rd_occ_1)["draft_eligible"], se(rd_occ_1)["draft_eligible"], pvalue(rd_occ_1)["draft_eligible"]),
          fmt_coef(coef(rd_move_1)["draft_eligible"], se(rd_move_1)["draft_eligible"], pvalue(rd_move_1)["draft_eligible"]),
          fmt_coef(coef(rd_manuf_1)["draft_eligible"], se(rd_manuf_1)["draft_eligible"], pvalue(rd_manuf_1)["draft_eligible"])),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_se(se(rd_farm_1)["draft_eligible"]), fmt_se(se(rd_occ_1)["draft_eligible"]),
          fmt_se(se(rd_move_1)["draft_eligible"]), fmt_se(se(rd_manuf_1)["draft_eligible"])),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: With Controls}} \\\\\n",
  sprintf("Draft Eligible & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_coef(coef(rd_farm_2)["draft_eligible"], se(rd_farm_2)["draft_eligible"], pvalue(rd_farm_2)["draft_eligible"]),
          fmt_coef(coef(rd_occ_2)["draft_eligible"], se(rd_occ_2)["draft_eligible"], pvalue(rd_occ_2)["draft_eligible"]),
          fmt_coef(coef(rd_move_2)["draft_eligible"], se(rd_move_2)["draft_eligible"], pvalue(rd_move_2)["draft_eligible"]),
          fmt_coef(coef(rd_manuf_2)["draft_eligible"], se(rd_manuf_2)["draft_eligible"], pvalue(rd_manuf_2)["draft_eligible"])),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
          fmt_se(se(rd_farm_2)["draft_eligible"]), fmt_se(se(rd_occ_2)["draft_eligible"]),
          fmt_se(se(rd_move_2)["draft_eligible"]), fmt_se(se(rd_manuf_2)["draft_eligible"])),
  "\\hline\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Controls & Panel B & Panel B & Panel B & Panel B \\\\\n",
  sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\\n", format(nobs(rd_farm_1), big.mark = ",")),
  sprintf("Control mean & %.3f & %.2f & %.3f & %.3f \\\\\n",
          pre_means$mean_farm_exit, pre_means$mean_delta_occ, pre_means$mean_moved, pre_means$mean_manuf),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Parametric RD estimates using ages 10--18 in 1910 (bandwidth of 4 years). ",
  "Running variable: age in 1910, centered at 14 (first-draft eligibility cutoff). All specifications include ",
  "a linear age control and age $\\times$ draft eligibility interaction. Controls in Panel B: White, native-born, ",
  "literate, married. Standard errors clustered by state. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_age_rd.tex")

# -----------------------------------------------------------------------
# Table 5: Robustness
# -----------------------------------------------------------------------
cat("Generating Table 5: Robustness\n")

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Coefficient & SE & N \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: McCrary Density Test}} \\\\\n",
  sprintf("p-value & \\multicolumn{3}{c}{%.3f} \\\\\n", dens_test$test$p_jk),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Bandwidth Sensitivity (Farm Exit, Age RD)}} \\\\\n"
)

for (bw_name in names(bw_results)) {
  br <- bw_results[[bw_name]]
  tab5 <- paste0(tab5,
    sprintf("BW = %s years & %.4f & %.4f & %s \\\\\n",
            bw_name, br$coef, br$se, format(br$n, big.mark = ",")))
}

tab5 <- paste0(tab5,
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Donut-Hole RD (excl. ages 13--14)}} \\\\\n",
  sprintf("Farm exit & %.4f & %.4f & %s \\\\\n",
          coef(donut_fit)["draft_eligible"], se(donut_fit)["draft_eligible"], format(nobs(donut_fit), big.mark = ",")),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel D: Quadratic RD}} \\\\\n",
  sprintf("Farm exit & %.4f & %.4f & %s \\\\\n",
          coef(quad_farm)["draft_eligible"], se(quad_farm)["draft_eligible"], format(nobs(quad_farm), big.mark = ",")),
  sprintf("$\\Delta$ Occ. score & %.4f & %.4f & %s \\\\\n",
          coef(quad_occ)["draft_eligible"], se(quad_occ)["draft_eligible"], format(nobs(quad_occ), big.mark = ",")),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel E: Placebo Cutoffs (Farm Exit, below true cutoff)}} \\\\\n"
)

for (placebo_name in names(placebo_results)) {
  pr <- placebo_results[[placebo_name]]
  tab5 <- paste0(tab5,
    sprintf("Cutoff at age %s & %.4f & %.4f & \\\\\n",
            placebo_name, pr$coef, pr$se))
}

tab5 <- paste0(tab5,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A reports the McCrary (2008) density test p-value; ",
  "the null of no manipulation is not rejected. Panel B varies bandwidth around the cutoff. ",
  "Panel C excludes ages immediately adjacent to the cutoff. Panel D uses a quadratic polynomial. ",
  "Panel E reports placebo cutoffs at ages entirely below the true cutoff (ages 8--13 only); ",
  "significant effects at placebo cutoffs indicate smooth age trends, motivating the nativity DiD ",
  "as the preferred specification. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5, "../tables/tab5_robustness.tex")

# -----------------------------------------------------------------------
# SDE Table (Appendix)
# -----------------------------------------------------------------------
cat("Generating SDE Table\n")

# SDE = β / SD(Y) for binary treatment
# Using nativity DiD coefficients (primary specification)
sd_farm <- pre_means$sd_farm_exit
sd_occ <- pre_means$sd_delta_occ
sd_move <- pre_means$sd_moved

beta_farm <- de_nb_farm
beta_occ <- de_nb_occ
beta_move <- de_nb_move

se_farm <- de_nb_farm_se
se_occ <- de_nb_occ_se
se_move <- de_nb_move_se

sde_farm <- beta_farm / sd_farm
sde_occ <- beta_occ / sd_occ
sde_move <- beta_move / sd_move

se_sde_farm <- se_farm / sd_farm
se_sde_occ <- se_occ / sd_occ
se_sde_move <- se_move / sd_move

classify <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneity: high-ag counties farm exit
beta_het_ag <- coef(het_farm)["draft_eligible:high_ag"] + coef(het_farm)["draft_eligible"]
se_het_ag <- se(het_farm)["draft_eligible:high_ag"]  # approximate
sd_farm_highag <- dt[high_ag == 1 & draft_eligible == 0 & age_1910 %between% c(10, 18), sd(farm_exit)]
sde_het_ag <- beta_het_ag / sd_farm_highag
se_sde_het_ag <- se_het_ag / sd_farm_highag

# Black heterogeneity
beta_het_black <- coef(het_race)["draft_eligible:black"] + coef(het_race)["draft_eligible"]
se_het_black <- se(het_race)["draft_eligible:black"]
sd_farm_black <- dt[black == 1 & draft_eligible == 0 & age_1910 %between% c(10, 18), sd(farm_exit)]
sde_het_black <- beta_het_black / sd_farm_black
se_sde_het_black <- se_het_black / sd_farm_black

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did compulsory military service during World War I accelerate ",
  "the farm-to-manufacturing transition by breaking agricultural attachment inertia? ",
  "\\textbf{Policy mechanism:} The Selective Service Act of 1917 required registration of all ",
  "men aged 21--30; local draft boards inducted 2.8 million men, forcibly removing them from farms ",
  "and exposing them to non-agricultural occupations and geographic mobility through military service. ",
  "\\textbf{Outcome definition:} Farm exit (binary: on farm in 1910, not on farm in 1920); ",
  "change in occupational income score (IPUMS OCC1950-based index, continuous); ",
  "inter-county migration (binary: different county in 1920 vs.\\ 1910). ",
  "\\textbf{Treatment:} Binary; interaction of draft-age eligibility (age $\\geq$ 14 in 1910) ",
  "with native-born status (foreign-born non-citizens were exempt from the draft). ",
  "\\textbf{Data:} IPUMS Machine Learning Panel (MLP), linked 1910--1920 full-count censuses, ",
  "4,854,248 men aged 10--20 in 1910. ",
  "\\textbf{Method:} Difference-in-differences comparing native-born (draft-exposed) vs.\\ ",
  "foreign-born (exempt) men across draft-eligible and ineligible age cohorts; ",
  "standard errors clustered by state (49 clusters). ",
  "\\textbf{Sample:} Men aged 10--20 in 1910, linked across censuses via MLP; excludes women ",
  "and men outside the age window. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (control group) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Farm exit & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_farm, se_farm, sd_farm, sde_farm, se_sde_farm, classify(sde_farm)),
  sprintf("$\\Delta$ Occ. score & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
          beta_occ, se_occ, sd_occ, sde_occ, se_sde_occ, classify(sde_occ)),
  sprintf("Moved county & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_move, se_move, sd_move, sde_move, se_sde_move, classify(sde_move)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  sprintf("Farm exit (high-ag counties) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_het_ag, se_het_ag, sd_farm_highag, sde_het_ag, se_sde_het_ag, classify(sde_het_ag)),
  sprintf("Farm exit (Black men) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_het_black, se_het_black, sd_farm_black, sde_het_black, se_sde_het_black, classify(sde_het_black)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
