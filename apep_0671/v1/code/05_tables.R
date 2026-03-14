# =============================================================================
# 05_tables.R — Generate all LaTeX tables (including SDE table)
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
main <- fread("../data/analysis_main.csv")

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

# ─────────────────────────────────────────────────────────────────────────────
# Table 2: Main Results — Effect on OCCSCORE Change
# ─────────────────────────────────────────────────────────────────────────────

models <- list(results$main_specs$m1, results$main_specs$m2, results$main_specs$m3,
               results$main_specs$m4, results$main_specs$m5)

betas <- sapply(models, function(m) coef(m)["restricted_share"])
ses <- sapply(models, function(m) se(m)["restricted_share"])
pvals <- sapply(models, function(m) pvalue(m)["restricted_share"])
ns <- sapply(models, function(m) m$nobs)

sink("../tables/tab2_main.tex")
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Effect of 1924 Quota Exposure on Occupational Score Change, 1920--1930}\n")
cat("\\begin{threeparttable}\n\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat("& (1) & (2) & (3) & (4) & (5) \\\\\n\\midrule\n")
cat(sprintf("Restricted FB Share & %s & %s & %s & %s & %s \\\\\n",
            paste0(sprintf("%.3f", betas[1]), stars(pvals[1])),
            paste0(sprintf("%.3f", betas[2]), stars(pvals[2])),
            paste0(sprintf("%.3f", betas[3]), stars(pvals[3])),
            paste0(sprintf("%.3f", betas[4]), stars(pvals[4])),
            paste0(sprintf("%.3f", betas[5]), stars(pvals[5]))))
cat(sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            ses[1], ses[2], ses[3], ses[4], ses[5]))
cat("\\midrule\n")
cat("Demographics & No & Yes & Yes & Yes & Yes \\\\\n")
cat("State FE & No & No & Yes & Yes & --- \\\\\n")
cat("Initial Occupation FE & No & No & No & Yes & --- \\\\\n")
cat("State $\\times$ Occ.\\ FE & No & No & No & No & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
            format(ns[1], big.mark=","), format(ns[2], big.mark=","),
            format(ns[3], big.mark=","), format(ns[4], big.mark=","),
            format(ns[5], big.mark=",")))
cat("Clustering & County & County & County & County & County \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Standard errors clustered at the county level in parentheses. ")
cat("Dependent variable is the change in occupational income score (OCCSCORE) between 1920 and 1930. ")
cat("Restricted FB Share is the county-level share of 1920 population born in countries targeted by the 1924 Johnson-Reed Act. ")
cat("Sample: native-born men aged 18--55 in 1920, linked to 1930 via IPUMS MLP. ")
cat("Demographics: age, age$^2$, white, literate.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:main}\n\\end{table}\n")
sink()

# ─────────────────────────────────────────────────────────────────────────────
# Table 3: Additional Outcomes
# ─────────────────────────────────────────────────────────────────────────────

b_models <- list(results$binary$m_up, results$binary$m_down, results$binary$m_move,
                 results$binary$m_farm, results$binary$m_ind)
b_betas <- sapply(b_models, function(m) coef(m)["restricted_share"])
b_ses <- sapply(b_models, function(m) se(m)["restricted_share"])
b_pvals <- sapply(b_models, function(m) pvalue(m)["restricted_share"])
b_ns <- sapply(b_models, function(m) m$nobs)
b_means <- c(mean(main$upgraded), mean(main$downgraded), mean(main$moved),
             mean(main[farm_1920 == 2]$left_farm), mean(main$switched_industry))

sink("../tables/tab3_outcomes.tex")
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Effect of 1924 Quota Exposure on Occupational Transitions}\n")
cat("\\begin{threeparttable}\n\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat("& (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("& Upgraded & Downgraded & Moved & Left Farm & Switched Ind. \\\\\n\\midrule\n")
cat(sprintf("Restricted FB Share & %s & %s & %s & %s & %s \\\\\n",
            paste0(sprintf("%.4f", b_betas[1]), stars(b_pvals[1])),
            paste0(sprintf("%.4f", b_betas[2]), stars(b_pvals[2])),
            paste0(sprintf("%.4f", b_betas[3]), stars(b_pvals[3])),
            paste0(sprintf("%.4f", b_betas[4]), stars(b_pvals[4])),
            paste0(sprintf("%.4f", b_betas[5]), stars(b_pvals[5]))))
cat(sprintf("& (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            b_ses[1], b_ses[2], b_ses[3], b_ses[4], b_ses[5]))
cat("\\midrule\n")
cat(sprintf("Dep.\\ Var.\\ Mean & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
            b_means[1], b_means[2], b_means[3], b_means[4], b_means[5]))
cat(sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
            format(b_ns[1], big.mark=","), format(b_ns[2], big.mark=","),
            format(b_ns[3], big.mark=","), format(b_ns[4], big.mark=","),
            format(b_ns[5], big.mark=",")))
cat("State + Occ.\\ FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Clustering & County & County & County & County & County \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Standard errors clustered at the county level. ")
cat("All specifications include age, age$^2$, white, literate, state FE, and initial occupation FE. ")
cat("Upgraded: OCCSCORE increase $>$5 points. Downgraded: decrease $>$5 points. ")
cat("Moved: changed county. Left Farm: farm workers who moved to non-farm occupation. ")
cat("Switched Industry: changed 1950 industry code.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:outcomes}\n\\end{table}\n")
sink()

# ─────────────────────────────────────────────────────────────────────────────
# Table 4: Heterogeneity by Initial Skill Level
# ─────────────────────────────────────────────────────────────────────────────

h_models <- list(robustness$by_skill$low, robustness$by_skill$mid, robustness$by_skill$high)
h_betas <- sapply(h_models, function(m) coef(m)["restricted_share"])
h_ses <- sapply(h_models, function(m) se(m)["restricted_share"])
h_pvals <- sapply(h_models, function(m) pvalue(m)["restricted_share"])
h_ns <- sapply(h_models, function(m) m$nobs)

sink("../tables/tab4_heterogeneity.tex")
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Heterogeneity by Initial Skill Level}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat("& (1) & (2) & (3) \\\\\n")
cat("& Low-Skill & Mid-Skill & High-Skill \\\\\n")
cat("& OCCSCORE $\\leq$ 15 & 16--25 & $>$ 25 \\\\\n\\midrule\n")
cat(sprintf("Restricted FB Share & %s & %s & %s \\\\\n",
            paste0(sprintf("%.3f", h_betas[1]), stars(h_pvals[1])),
            paste0(sprintf("%.3f", h_betas[2]), stars(h_pvals[2])),
            paste0(sprintf("%.3f", h_betas[3]), stars(h_pvals[3]))))
cat(sprintf("& (%.3f) & (%.3f) & (%.3f) \\\\\n", h_ses[1], h_ses[2], h_ses[3]))
cat("\\midrule\n")
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            format(h_ns[1], big.mark=","), format(h_ns[2], big.mark=","),
            format(h_ns[3], big.mark=",")))
cat("State + Occ.\\ FE & Yes & Yes & Yes \\\\\n")
cat("Clustering & County & County & County \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Standard errors clustered at the county level. ")
cat("All specifications include age, age$^2$, white, literate, state FE, and initial occupation FE. ")
cat("Skill groups defined by 1920 OCCSCORE: Low ($\\leq$15, e.g., laborers, farm workers), ")
cat("Mid (16--25, e.g., operatives, service workers), High ($>$25, e.g., clerical, professional). ")
cat("Dependent variable: OCCSCORE change 1920--1930.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:heterogeneity}\n\\end{table}\n")
sink()

# ─────────────────────────────────────────────────────────────────────────────
# Table 5: Placebo Test (1910-1920)
# ─────────────────────────────────────────────────────────────────────────────

m4_main <- results$main_specs$m4
m_pl <- results$placebo$m_placebo
m_up_pl <- results$placebo$m_up_placebo

pl_models <- list(m4_main, m_pl, m_up_pl)
pl_betas <- sapply(pl_models, function(m) coef(m)["restricted_share"])
pl_ses <- sapply(pl_models, function(m) se(m)["restricted_share"])
pl_pvals <- sapply(pl_models, function(m) pvalue(m)["restricted_share"])
pl_ns <- sapply(pl_models, function(m) m$nobs)

sink("../tables/tab5_placebo.tex")
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Placebo Test: 1910--1920 Panel (Pre-Quota Period)}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat("& (1) & (2) & (3) \\\\\n")
cat("& 1920--1930 & 1910--1920 & 1910--1920 \\\\\n")
cat("& $\\Delta$ OCCSCORE & $\\Delta$ OCCSCORE & Upgraded \\\\\n\\midrule\n")
cat(sprintf("Restricted FB Share & %s & %s & %s \\\\\n",
            paste0(sprintf("%.3f", pl_betas[1]), stars(pl_pvals[1])),
            paste0(sprintf("%.3f", pl_betas[2]), stars(pl_pvals[2])),
            paste0(sprintf("%.3f", pl_betas[3]), stars(pl_pvals[3]))))
cat(sprintf("& (%.3f) & (%.3f) & (%.3f) \\\\\n", pl_ses[1], pl_ses[2], pl_ses[3]))
cat("\\midrule\n")
cat(sprintf("Observations & %s & %s & %s \\\\\n",
            format(pl_ns[1], big.mark=","), format(pl_ns[2], big.mark=","),
            format(pl_ns[3], big.mark=",")))
cat("Period & Post-Quota & Pre-Quota & Pre-Quota \\\\\n")
cat("State + Occ.\\ FE & Yes & Yes & Yes \\\\\n")
cat("Clustering & County & County & County \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Standard errors clustered at the county level. ")
cat("Column (1) reproduces the preferred specification from \\Cref{tab:main}. ")
cat("Columns (2)--(3) apply the identical specification to the pre-quota 1910--1920 linked panel. ")
cat("Treatment intensity is the same 1920 county-level restricted-origin foreign-born share. ")
cat("Finding no significant effect in 1910--1920 supports the parallel trends assumption.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:placebo}\n\\end{table}\n")
sink()

# ─────────────────────────────────────────────────────────────────────────────
# SDE Table (Mandatory)
# ─────────────────────────────────────────────────────────────────────────────

classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_data <- data.frame(
  Outcome = c("OCCSCORE Change", "Upgraded ($>$5 pts)", "Downgraded ($>$5 pts)",
              "Geographic Mobility", "Industry Switching"),
  beta = c(coef(m4_main)["restricted_share"],
           coef(results$binary$m_up)["restricted_share"],
           coef(results$binary$m_down)["restricted_share"],
           coef(results$binary$m_move)["restricted_share"],
           coef(results$binary$m_ind)["restricted_share"]),
  se = c(se(m4_main)["restricted_share"],
         se(results$binary$m_up)["restricted_share"],
         se(results$binary$m_down)["restricted_share"],
         se(results$binary$m_move)["restricted_share"],
         se(results$binary$m_ind)["restricted_share"]),
  sd_y = c(sd(main$d_occscore), sd(main$upgraded), sd(main$downgraded),
           sd(main$moved), sd(main$switched_industry)),
  sd_x = sd(main$restricted_share),
  stringsAsFactors = FALSE
)

sde_data$sde <- sde_data$beta * sde_data$sd_x / sde_data$sd_y
sde_data$se_sde <- sde_data$se * sde_data$sd_x / sde_data$sd_y
sde_data$classification <- classify_sde(sde_data$sde)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n\\label{tab:sde}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{llcccccl}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
for (i in 1:nrow(sde_data)) {
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              sde_data$Outcome[i], sde_data$beta[i], sde_data$se[i],
              sde_data$sd_x[i], sde_data$sd_y[i],
              sde_data$sde[i], sde_data$se_sde[i], sde_data$classification[i]))
}
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\par\\vspace{0.3em}\n")
cat("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ")
cat("to facilitate cross-study comparison of treatment effect magnitudes. ")
cat("For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ")
cat("which gives the effect of a one-standard-deviation increase in county-level restricted-origin ")
cat("foreign-born share, measured in standard deviations of the outcome. ")
cat("SD($X$) and SD($Y$) are unconditional standard deviations (Table~\\ref{tab:summary}). ")
cat("\\textbf{Research question:} Does exposure to the 1924 Immigration Act's labor supply shock ")
cat("cause native workers to upgrade occupationally? ")
cat("\\textbf{Treatment:} Continuous; county-level share of 1920 population born in restricted-origin countries. ")
cat(sprintf("\\textbf{Data:} IPUMS MLP linked 1920--1930 census, %s native-born men aged 18--55. ",
            format(nrow(main), big.mark=",")))
cat("\\textbf{Method:} Continuous-treatment cross-sectional design with state and initial occupation FE, county-clustered SEs. ")
cat("Classification labels refer to the magnitude of the standardized point estimate, ")
cat("not to statistical significance. ``Null'' denotes a near-zero effect size ")
cat("($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n")
cat("\\end{table}\n")
sink()

cat("All tables generated.\n")
