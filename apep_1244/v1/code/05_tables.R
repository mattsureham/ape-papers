# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_1244: The Upgrading Dividend
# =============================================================================

source("00_packages.R")

results     <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ---- Table 1: Summary Statistics --------------------------------------------
cat("Generating Table 1: Summary Statistics\n")

summ <- results$summary_stats

tab1_tex <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics by Treatment Status and Period}
\\label{tab:summary}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{@{}lcccc@{}}
\\toprule
& \\multicolumn{2}{c}{Pre-period (1900--1910)} & \\multicolumn{2}{c}{Treatment (1910--1920)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
& WC states & Never-treated & WC states & Never-treated \\\\
\\midrule\n"

# Row helper
fmt <- function(x, digits = 3) format(round(x, digits), nsmall = digits)

# Extract by group: cohort 1 treated, cohort 1 control, cohort 2 treated, cohort 2 control
s1t <- summ[cohort == 1 & treated == 1]
s1c <- summ[cohort == 1 & treated == 0]
s2t <- summ[cohort == 2 & treated == 1]
s2c <- summ[cohort == 2 & treated == 0]

rows <- list(
  c("$N$", format(s1t$N, big.mark=","), format(s1c$N, big.mark=","),
    format(s2t$N, big.mark=","), format(s2c$N, big.mark=",")),
  c("$\\Delta$ Hazardous", fmt(s1t$d_hazardous,4), fmt(s1c$d_hazardous,4),
    fmt(s2t$d_hazardous,4), fmt(s2c$d_hazardous,4)),
  c("$\\Delta$ OCCSCORE", fmt(s1t$d_occscore,2), fmt(s1c$d_occscore,2),
    fmt(s2t$d_occscore,2), fmt(s2c$d_occscore,2)),
  c("Mover", fmt(s1t$mover,3), fmt(s1c$mover,3), fmt(s2t$mover,3), fmt(s2c$mover,3)),
  c("Young ($\\leq$ 30)", fmt(s1t$young,3), fmt(s1c$young,3), fmt(s2t$young,3), fmt(s2c$young,3)),
  c("Black", fmt(s1t$black,3), fmt(s1c$black,3), fmt(s2t$black,3), fmt(s2c$black,3)),
  c("Foreign-born", fmt(s1t$foreign,3), fmt(s1c$foreign,3), fmt(s2t$foreign,3), fmt(s2c$foreign,3)),
  c("Literate", fmt(s1t$literate,3), fmt(s1c$literate,3), fmt(s2t$literate,3), fmt(s2c$literate,3)),
  c("Farm origin", fmt(s1t$farm,3), fmt(s1c$farm,3), fmt(s2t$farm,3), fmt(s2c$farm,3))
)

for (r in rows) {
  tab1_tex <- paste0(tab1_tex, paste(r, collapse = " & "), " \\\\\n")
}

tab1_tex <- paste0(tab1_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Sample is men aged 18--50, wage-employed at baseline census. WC states adopted workers' compensation by 1920 (43 states); never-treated states are AR, FL, MS, NC, SC. $\\Delta$ Hazardous is the change in an indicator for manufacturing or mining employment. OCCSCORE is the IPUMS occupational income score. Farm origin indicates baseline farm residence. Data: IPUMS MLP linked census panels.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---- Table 2: Main Results --------------------------------------------------
cat("Generating Table 2: Main Results\n")

setFixest_dict(c(did = "WC $\\times$ Post",
                 post = "Post (1910--1920)",
                 treated = "WC state",
                 dose_did = "WC years $\\times$ Post",
                 wc_exposure = "WC years",
                 young = "Young ($\\leq$ 30)",
                 black = "Black",
                 foreign = "Foreign-born",
                 literate = "Literate",
                 farm_origin = "Farm origin"))

etable(results$m1, results$m2, results$m3, results$m4,
       headers = c("(1)", "(2)", "(3)", "(4)"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       tex = TRUE,
       file = "../tables/tab2_main.tex",
       replace = TRUE,
       title = "Workers' Compensation and Hazardous Industry Entry",
       label = "tab:main",
       notes = paste0("\\textit{Notes:} Dependent variable is the individual-level change in ",
                      "a binary indicator for manufacturing or mining employment between linked ",
                      "census rounds. The sample stacks individuals linked across 1900--1910 (pre-period) and ",
                      "1910--1920 (treatment period). WC states adopted workers' compensation ",
                      "between 1911 and 1920; never-treated states (AR, FL, MS, NC, SC) did not. ",
                      "Column (4) replaces binary treatment with years of WC exposure by 1920. ",
                      "Standard errors clustered at the state level in parentheses. ",
                      "Data: IPUMS MLP. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."))

# ---- Table 3: Secondary Outcomes and Pre-trend Test -------------------------
cat("Generating Table 3: Secondary Outcomes\n")

etable(results$m2, results$m_occ, results$m_mover, results$m_pre_haz, results$m_pre_occ,
       headers = c("$\\Delta$ Hazardous", "$\\Delta$ OCCSCORE",
                    "Mover", "Pre: $\\Delta$ Haz.", "Pre: $\\Delta$ OCC"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       keep = c("%did", "%treated"),
       tex = TRUE,
       file = "../tables/tab3_outcomes.tex",
       replace = TRUE,
       title = "Secondary Outcomes and Pre-trend Validation",
       label = "tab:outcomes",
       notes = paste0("\\textit{Notes:} Columns (1)--(3) report DiD estimates from the stacked ",
                      "cohort specification with controls. Columns (4)--(5) test for pre-existing ",
                      "differential trends using the 1900--1910 cohort only: the coefficient on ",
                      "``WC state'' captures whether future WC-adopting states already had different ",
                      "occupational trajectories before any WC laws existed. All specifications include ",
                      "controls for age, race, nativity, literacy, and farm origin. Standard errors ",
                      "clustered at the state level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."))

# ---- Table 4: Robustness Checks ---------------------------------------------
cat("Generating Table 4: Robustness\n")

etable(results$m2, rob_results$m_south, rob_results$m_no1911,
       rob_results$m_late, rob_results$m_nonmover,
       headers = c("Baseline", "South only", "Excl.\\ 1911", "Late adopters", "Non-movers"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       keep = c("%did"),
       tex = TRUE,
       file = "../tables/tab4_robustness.tex",
       replace = TRUE,
       title = "Robustness Checks",
       label = "tab:robustness",
       notes = paste0("\\textit{Notes:} Column (1) reproduces the baseline from Table \\ref{tab:main}. ",
                      "Column (2) restricts to Southern states for geographic comparability. ",
                      "Column (3) drops the 10 earliest WC adopters (1911). ",
                      "Column (4) uses only late adopters (1915+) vs.\\ never-treated. ",
                      "Column (5) restricts to individuals who did not change state between censuses. ",
                      "Columns (2)--(5) use weighted state-cohort cell regressions. ",
                      "Standard errors clustered at the state level. ",
                      "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."))

# ---- Table 5: Heterogeneity -------------------------------------------------
cat("Generating Table 5: Heterogeneity\n")

etable(results$m_young, results$m_old, results$m_white, results$m_black,
       results$m_farm, results$m_nonfarm,
       headers = c("Young", "Old", "White", "Black", "Farm", "Non-farm"),
       se.below = TRUE,
       fitstat = ~ n + r2,
       keep = "%did",
       tex = TRUE,
       file = "../tables/tab5_heterogeneity.tex",
       replace = TRUE,
       title = "Heterogeneity in the Effect of Workers' Compensation",
       label = "tab:hetero",
       notes = paste0("\\textit{Notes:} Each column reports the DiD estimate from a sample split. ",
                      "Young $\\leq$ 30 at baseline; Black = race coded Black in census; ",
                      "Farm = baseline farm residence. Controls include available demographics ",
                      "not used for splitting. Standard errors clustered at the state level. ",
                      "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."))

# ---- Table F1: Standardized Effect Sizes (SDE) ------------------------------
cat("Generating SDE Appendix Table\n")

# Load stacked for SD calculations
stacked <- readRDS("../data/stacked.rds")
pre_data <- stacked[cohort == 1]

classify_sde <- function(sde) {
  a <- abs(sde)
  if (a < 0.005) return("Null")
  if (a < 0.05) { if (sde > 0) return("Small positive") else return("Small negative") }
  if (a < 0.15) { if (sde > 0) return("Moderate positive") else return("Moderate negative") }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Panel A: Main outcomes
outcomes <- list(
  list(name = "Hazardous industry entry", m = results$m2, cn = "did", yv = "d_hazardous"),
  list(name = "Occupational income (OCCSCORE)", m = results$m_occ, cn = "did", yv = "d_occscore"),
  list(name = "Interstate mobility", m = results$m_mover, cn = "did", yv = "mover")
)

panel_a <- lapply(outcomes, function(o) {
  b <- coef(o$m)[o$cn]; s <- se(o$m)[o$cn]
  sdy <- sd(pre_data[[o$yv]], na.rm = TRUE)
  sde <- b / sdy; se_sde <- s / sdy
  data.frame(Outcome = o$name, Beta = round(b, 5), SE = round(s, 5),
             SD_Y = round(sdy, 4), SDE = round(sde, 4), SE_SDE = round(se_sde, 4),
             Classification = classify_sde(sde), stringsAsFactors = FALSE)
})
panel_a <- do.call(rbind, panel_a)

# Panel B: Heterogeneity by age (sample splits)
pre_young <- stacked[cohort == 1 & young == 1]
pre_old   <- stacked[cohort == 1 & young == 0]

het_list <- list(
  list(name = "Hazardous entry (young $\\leq$ 30)", m = results$m_young, cn = "did",
       sub = pre_young, yv = "d_hazardous"),
  list(name = "Hazardous entry (age $>$ 30)", m = results$m_old, cn = "did",
       sub = pre_old, yv = "d_hazardous")
)

panel_b <- lapply(het_list, function(h) {
  b <- coef(h$m)[h$cn]; s <- se(h$m)[h$cn]
  sdy <- sd(h$sub[[h$yv]], na.rm = TRUE)
  sde <- b / sdy; se_sde <- s / sdy
  data.frame(Outcome = h$name, Beta = round(b, 5), SE = round(s, 5),
             SD_Y = round(sdy, 4), SDE = round(sde, 4), SE_SDE = round(se_sde, 4),
             Classification = classify_sde(sde), stringsAsFactors = FALSE)
})
panel_b <- do.call(rbind, panel_b)

rm(stacked, pre_data, pre_young, pre_old); gc()

# Build SDE notes
n_obs_total <- results$summary_stats[, sum(N)]
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did state-level adoption of workers' compensation laws (1911--1920) cause wage workers to sort into higher-risk manufacturing and mining occupations? ",
  "\\textbf{Policy mechanism:} Workers' compensation replaced negligence-based tort liability with no-fault insurance providing 50--66\\% wage replacement for workplace injuries, reducing the individual financial cost of occupational hazard exposure. ",
  "\\textbf{Outcome definition:} Change in a binary indicator for employment in manufacturing (ind1950 306--499) or mining (206--299) between linked census rounds; OCCSCORE is the IPUMS occupational income score; interstate mobility is a binary indicator for changing state of residence. ",
  "\\textbf{Treatment:} Binary indicator for state adoption of workers' compensation by 1920 (43 treated states vs.\\ 5 never-treated: AR, FL, MS, NC, SC). ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel (MLP) linking individuals across the 1900, 1910, and 1920 decennial censuses; stacked cohort design with ",
  format(n_obs_total, big.mark = ","), " individual-decade observations across 47 states. ",
  "\\textbf{Method:} Stacked cohort difference-in-differences comparing occupational transitions in WC-adopting vs.\\ never-treated states, with standard errors clustered at the state level. ",
  "\\textbf{Sample:} Men aged 18--50, wage-employed at baseline census, successfully linked across consecutive censuses by the MLP algorithm. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

# Build LaTeX
sde_tex <- "\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{@{}lcccccc@{}}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\addlinespace\n"

for (i in seq_len(nrow(panel_a))) {
  r <- panel_a[i, ]
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

sde_tex <- paste0(sde_tex, "\\addlinespace
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by age)}} \\\\
\\addlinespace\n")

for (i in seq_len(nrow(panel_b))) {
  r <- panel_b[i, ]
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

sde_tex <- paste0(sde_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
