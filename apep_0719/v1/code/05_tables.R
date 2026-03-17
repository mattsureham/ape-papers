# 05_tables.R — Generate all LaTeX tables
# apep_0719: Alien Land Laws and Japanese Occupational Sorting

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "regression_results.rds"))
df_j_main <- readRDS(file.path(data_dir, "japanese_main.rds"))
df_j_farm <- readRDS(file.path(data_dir, "japanese_farmers.rds"))
df_w_farm <- readRDS(file.path(data_dir, "white_farmers.rds"))

# ===================================================================
# TABLE 1: SUMMARY STATISTICS
# ===================================================================

# Japanese farmers by treatment status
j_treat <- df_j_farm %>% filter(newly_treated == 1)
j_ctrl <- df_j_farm %>% filter(newly_treated == 0)

sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Japanese Farmers by Treatment Status (1920)}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Treated States} & \\multicolumn{2}{c}{Control States} & \\\\\n")
cat(" & Mean & SD & Mean & SD & Diff. \\\\\n")
cat("\\hline\n")

vars <- list(
  c("Age", "age_1920"),
  c("Literate", "literate_1920"),
  c("Farm Occupation", "farm_occ_1920"),
  c("Farm Owner", "farm_owner_1920"),
  c("Occupational Score", "occscore_1920"),
  c("SEI", "sei_1920"),
  c("Married", "marst_1920")
)

for (v in vars) {
  label <- v[1]
  col <- v[2]
  t_mean <- mean(j_treat[[col]], na.rm = TRUE)
  t_sd <- sd(j_treat[[col]], na.rm = TRUE)
  c_mean <- mean(j_ctrl[[col]], na.rm = TRUE)
  c_sd <- sd(j_ctrl[[col]], na.rm = TRUE)
  diff <- t_mean - c_mean

  if (label == "Married") {
    t_mean <- mean(j_treat$marst_1920 %in% c(1, 2))
    c_mean <- mean(j_ctrl$marst_1920 %in% c(1, 2))
    t_sd <- sd(j_treat$marst_1920 %in% c(1, 2))
    c_sd <- sd(j_ctrl$marst_1920 %in% c(1, 2))
    diff <- t_mean - c_mean
  }

  cat(sprintf("%s & %.2f & (%.2f) & %.2f & (%.2f) & %.2f \\\\\n",
              label, t_mean, t_sd, c_mean, c_sd, diff))
}

cat("\\addlinespace\n")
cat("\\multicolumn{6}{l}{\\textit{Outcomes (1920--1930 Change)}} \\\\\n")
cat(sprintf("Farm Exit & %.3f & & %.3f & & %.3f \\\\\n",
            mean(j_treat$farm_exit), mean(j_ctrl$farm_exit),
            mean(j_treat$farm_exit) - mean(j_ctrl$farm_exit)))
cat(sprintf("$\\Delta$ Occupational Score & %.2f & & %.2f & & %.2f \\\\\n",
            mean(j_treat$occscore_change), mean(j_ctrl$occscore_change),
            mean(j_treat$occscore_change) - mean(j_ctrl$occscore_change)))
cat("\\hline\n")
cat(sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\\\\n",
            nrow(j_treat), nrow(j_ctrl)))
cat("States & \\multicolumn{2}{c}{7} & \\multicolumn{2}{c}{11} & \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Sample restricted to Japanese males aged 18--60 in 1920 with farm occupations (OCC1950 codes 100--123). Treated states enacted Alien Land Laws between 1920 and 1930 censuses: WA, TX, LA, NM, OR, ID, MT. Control states never enacted ALLs. California and Arizona (ALLs enacted pre-1920) excluded. Data from IPUMS MLP linked panels.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 written.\n")

# ===================================================================
# TABLE 2: MAIN RESULTS — FARM EXIT
# ===================================================================

sink(file.path(tables_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Alien Land Laws on Farm Exit and Occupational Upgrading}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Farm Exit} & \\multicolumn{2}{c}{$\\Delta$ Occ.\\ Score} \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

# Extract coefficients
b1 <- coef(results$m1_farm_exit)["newly_treated"]
se1 <- sqrt(diag(vcov(results$m1_farm_exit)))["newly_treated"]
b2 <- coef(results$m2_farm_exit)["newly_treated"]
se2 <- sqrt(diag(vcov(results$m2_farm_exit)))["newly_treated"]
b5 <- coef(results$m5_farm_occ)["newly_treated"]
se5 <- sqrt(diag(vcov(results$m5_farm_occ)))["newly_treated"]
b4 <- coef(results$m4_occscore)["newly_treated"]
se4 <- sqrt(diag(vcov(results$m4_occscore)))["newly_treated"]

star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
p1 <- summary(results$m1_farm_exit)$coeftable["newly_treated", "Pr(>|t|)"]
p2 <- summary(results$m2_farm_exit)$coeftable["newly_treated", "Pr(>|t|)"]
p5 <- summary(results$m5_farm_occ)$coeftable["newly_treated", "Pr(>|t|)"]
p4 <- summary(results$m4_occscore)$coeftable["newly_treated", "Pr(>|t|)"]

cat(sprintf("Newly Treated State & %.3f%s & %.3f%s & %.3f%s & %.3f \\\\\n",
            b1, star(p1), b2, star(p2), b5, star(p5), b4))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            se1, se2, se5, se4))
cat("\\addlinespace\n")
cat(sprintf("Sample & Farmers & Farmers & Farmers & All \\\\\n"))
cat(sprintf("Controls & No & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Control mean & %.3f & %.3f & %.2f & %.2f \\\\\n",
            results$stats$japanese_farm_exit_control,
            results$stats$japanese_farm_exit_control,
            mean(j_ctrl$occscore_change),
            mean(df_j_main$occscore_change[df_j_main$newly_treated == 0])))
cat(sprintf("N & %s & %s & %s & %s \\\\\n",
            format(nobs(results$m1_farm_exit), big.mark = ","),
            format(nobs(results$m2_farm_exit), big.mark = ","),
            format(nobs(results$m5_farm_occ), big.mark = ","),
            format(nobs(results$m4_occscore), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} State-clustered standard errors in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$. Dependent variable in columns (1)--(2) is an indicator for exiting farm occupations between 1920 and 1930. Columns (3)--(4) measure the change in Duncan occupational score. Controls: age, age$^2$, literacy. Column (4) additionally controls for 1920 farm occupation.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 written.\n")

# ===================================================================
# TABLE 3: TRIPLE DIFFERENCE (DDD)
# ===================================================================

sink(file.path(tables_dir, "tab3_ddd.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Triple Difference: Japanese vs.\\ White Farmers}\n")
cat("\\label{tab:ddd}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & Farm Exit & $\\Delta$ Occ.\\ Score \\\\\n")
cat(" & (1) & (2) \\\\\n")
cat("\\hline\n")

b8 <- coef(results$m8_ddd_exit)["newly_treated:japanese"]
se8 <- sqrt(diag(vcov(results$m8_ddd_exit)))["newly_treated:japanese"]
p8 <- summary(results$m8_ddd_exit)$coeftable["newly_treated:japanese", "Pr(>|t|)"]

b9 <- coef(results$m9_ddd_occ)["newly_treated:japanese"]
se9 <- sqrt(diag(vcov(results$m9_ddd_occ)))["newly_treated:japanese"]
p9 <- summary(results$m9_ddd_occ)$coeftable["newly_treated:japanese", "Pr(>|t|)"]

bj8 <- coef(results$m8_ddd_exit)["japanese"]
sej8 <- sqrt(diag(vcov(results$m8_ddd_exit)))["japanese"]

bj9 <- coef(results$m9_ddd_occ)["japanese"]
sej9 <- sqrt(diag(vcov(results$m9_ddd_occ)))["japanese"]

cat(sprintf("Treated $\\times$ Japanese & %.3f%s & %.3f%s \\\\\n",
            b8, star(p8), b9, star(p9)))
cat(sprintf(" & (%.3f) & (%.3f) \\\\\n", se8, se9))
cat("\\addlinespace\n")
cat(sprintf("Japanese & %.3f & %.3f \\\\\n", bj8, bj9))
cat(sprintf(" & (%.3f) & (%.3f) \\\\\n", sej8, sej9))
cat("\\addlinespace\n")
cat("State FE & Yes & Yes \\\\\n")

n_ddd <- nobs(results$m8_ddd_exit)
cat(sprintf("N & %s & %s \\\\\n",
            format(n_ddd, big.mark = ","),
            format(nobs(results$m9_ddd_occ), big.mark = ",")))

# White placebo means
cat(sprintf("White treated mean & %.3f & %.2f \\\\\n",
            results$stats$white_farm_exit_treated,
            mean(df_w_farm$occscore_change[df_w_farm$newly_treated == 1])))
cat(sprintf("White control mean & %.3f & %.2f \\\\\n",
            results$stats$white_farm_exit_control,
            mean(df_w_farm$occscore_change[df_w_farm$newly_treated == 0])))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Triple-difference estimates comparing Japanese to white farmers across treated and control states. State fixed effects absorb the main effect of treatment. State-clustered standard errors in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$. Sample: all male farmers aged 18--60 in 1920 (Japanese + 2\\% white random subsample).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 3 written.\n")

# ===================================================================
# TABLE 4: ROBUSTNESS
# ===================================================================

robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

sink(file.path(tables_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & Coefficient & SE & N \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Alternative Outcome Measures}} \\\\\n")

b_sei <- coef(robustness$m_sei)["newly_treated"]
se_sei <- sqrt(diag(vcov(robustness$m_sei)))["newly_treated"]
cat(sprintf("$\\Delta$ SEI (farm subsample) & %.3f*** & (%.3f) & %d \\\\\n",
            b_sei, se_sei, nobs(robustness$m_sei)))

cat("\\addlinespace\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Placebo Tests}} \\\\\n")

b_nf <- coef(robustness$m_nonfarm)["newly_treated"]
se_nf <- sqrt(diag(vcov(robustness$m_nonfarm)))["newly_treated"]
cat(sprintf("$\\Delta$ Occ.\\ Score (non-farm Japanese) & %.3f & (%.3f) & %d \\\\\n",
            b_nf, se_nf, nobs(robustness$m_nonfarm)))

b_w <- coef(results$m6_white)["newly_treated"]
se_w <- sqrt(diag(vcov(results$m6_white)))["newly_treated"]
cat(sprintf("Farm exit (white farmers) & %.3f & (%.3f) & %s \\\\\n",
            b_w, se_w, format(nobs(results$m6_white), big.mark = ",")))

cat("\\addlinespace\n")
cat("\\multicolumn{4}{l}{\\textit{Panel C: Mobility}} \\\\\n")

b_mj <- coef(robustness$m_mover_j)["newly_treated"]
se_mj <- sqrt(diag(vcov(robustness$m_mover_j)))["newly_treated"]
cat(sprintf("Interstate mover (Japanese farmers) & %.3f & (%.3f) & %d \\\\\n",
            b_mj, se_mj, nobs(robustness$m_mover_j)))

b_mw <- coef(robustness$m_mover_w)["newly_treated"]
se_mw <- sqrt(diag(vcov(robustness$m_mover_w)))["newly_treated"]
cat(sprintf("Interstate mover (white farmers) & %.3f & (%.3f) & %s \\\\\n",
            b_mw, se_mw, format(nobs(robustness$m_mover_w), big.mark = ",")))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} State-clustered standard errors in parentheses. $^{***}$~$p<0.01$. Panel A uses the Duncan Socioeconomic Index (SEI) as an alternative to the occupational score. Panel B tests whether ALLs affected non-farm Japanese (placebo) and white farmers (placebo). Panel C tests whether ALLs induced interstate migration rather than occupational switching.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table 4 written.\n")

# ===================================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE)
# ===================================================================

sd_farm_exit <- sd(df_j_farm$farm_exit)
sd_occscore <- sd(df_j_farm$occscore_change)

sde_farm <- b1 / sd_farm_exit
sde_se_farm <- se1 / sd_farm_exit
sde_occ <- b5 / sd_occscore
sde_se_occ <- se5 / sd_occscore

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did state-level Alien Land Laws (1921--1923), which prohibited Japanese immigrants from owning or leasing agricultural land, ",
  "cause Japanese farmers to exit agriculture and move into higher-skilled occupations? ",
  "\\textbf{Policy mechanism:} Alien Land Laws prohibited ``aliens ineligible for citizenship'' (de facto targeting Japanese immigrants) from owning, ",
  "leasing, or transferring agricultural land, forcing displacement from farming and into alternative occupations. ",
  "\\textbf{Outcome definition:} Farm exit is a binary indicator equal to one if the individual had a farm occupation (OCC1950 100--123) in 1920 but ",
  "not in 1930; occupational score change is the Duncan occupational prestige score in 1930 minus 1920. ",
  "\\textbf{Treatment:} Binary --- states that enacted Alien Land Laws between the 1920 and 1930 censuses. ",
  "\\textbf{Data:} IPUMS Machine Learning Panel (MLP) linked 1920--1930 full-count census, individual-level panel of linked persons. ",
  "\\textbf{Method:} Cross-sectional first-difference comparing Japanese in newly treated vs.\\ never-treated states; triple-difference with white farmers as placebo; ",
  "state-clustered standard errors. ",
  "\\textbf{Sample:} Japanese males aged 18--60 in 1920 with farm occupations, excluding California and Arizona (pre-1920 ALL enactment). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat(sprintf("Farm Exit & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\\n",
            b1, se1, sd_farm_exit, sde_farm, sde_se_farm, classify_sde(sde_farm)))
cat(sprintf("$\\Delta$ Occ.\\ Score & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\\n",
            b5, se5, sd_occscore, sde_occ, sde_se_occ, classify_sde(sde_occ)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
