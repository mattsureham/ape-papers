# 05_tables.R — Generate LaTeX tables
source("00_packages.R")
load("data/models.RData")

dir.create("tables", showWarnings = FALSE)

s2 <- readRDS("data/secopii_clean.rds")
s2c <- s2[is_competitive == TRUE & !is.na(bidders) & bidders >= 1]
int_raw <- readRDS("data/integrado_raw.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
int <- as.data.table(int_raw)
int[, valor := as.numeric(valor_contrato)]

n_secopi <- sum(int$origen == "SECOPI")
n_secopii <- sum(int$origen == "SECOPII")
n_total <- nrow(int)
mean_val_secopi <- mean(int[origen == "SECOPI"]$valor, na.rm = TRUE) / 1e6
mean_val_secopii <- mean(int[origen == "SECOPII"]$valor, na.rm = TRUE) / 1e6

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & SECOP~I & SECOP~II \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Contract Records (Integrado)}} \\\\[3pt]",
  sprintf("Contracts & %s & %s \\\\",
          format(n_secopi, big.mark = ","), format(n_secopii, big.mark = ",")),
  sprintf("Mean contract value (million COP) & %.1f & %.1f \\\\",
          mean_val_secopi, mean_val_secopii),
  sprintf("Departments & %d & %d \\\\",
          n_distinct(int[origen == "SECOPI"]$departamento_entidad),
          n_distinct(int[origen == "SECOPII"]$departamento_entidad)),
  sprintf("Entities & %s & %s \\\\",
          format(n_distinct(int[origen == "SECOPI"]$codigo_entidad_en_secop), big.mark = ","),
          format(n_distinct(int[origen == "SECOPII"]$codigo_entidad_en_secop), big.mark = ",")),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: SECOP~II Competitive Processes}} \\\\[3pt]",
  sprintf("Processes & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(s2c), big.mark = ",")),
  sprintf("Mean bidders per process & \\multicolumn{2}{c}{%.2f} \\\\",
          process_summary$mean_bidders),
  sprintf("SD bidders & \\multicolumn{2}{c}{%.2f} \\\\",
          process_summary$sd_bidders),
  sprintf("Single-bidder rate & \\multicolumn{2}{c}{%.3f} \\\\",
          process_summary$sb_rate),
  sprintf("Mean award/reserve ratio & \\multicolumn{2}{c}{%.3f} \\\\",
          process_summary$mean_ar),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} Panel~A reports contract-level statistics from the SECOP Integrado dataset (2015--2021). ",
         "Panel~B reports process-level statistics for competitive modalities in SECOP~II (m\\'{i}nima cuant\\'{i}a, ",
         "licitaci\\'{o}n p\\'{u}blica, selecci\\'{o}n abreviada, concurso de m\\'{e}ritos, subasta). ",
         "Single-bidder rate is the share of competitive processes receiving exactly one bid."),
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Department-Level DiD
# ============================================================
tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Department-Level Effects of SECOP~II Adoption}",
  "\\label{tab:main_did}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Competitive & Competitive & Log \\\\",
  " & Share & Share & Contracts \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  sprintf("Post adoption & %s & & %s \\\\",
          sprintf("%.4f", coef(m1_comp)["post_adopt"]),
          sprintf("%.4f", coef(m1_log)["post_adopt"])),
  sprintf(" & (%s) & & (%s) \\\\",
          sprintf("%.4f", se(m1_comp)["post_adopt"]),
          sprintf("%.4f", se(m1_log)["post_adopt"])),
  sprintf("SECOP~II share & & %s & \\\\",
          sprintf("%.4f", coef(m1_int)["secopii_share"])),
  sprintf(" & & (%s) & \\\\",
          sprintf("%.4f", se(m1_int)["secopii_share"])),
  "\\midrule",
  "Department FE & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes \\\\",
  sprintf("Mean dep.\\ var. & %.3f & %.3f & %.2f \\\\",
          mean(dept_qtr$competitive_share, na.rm = TRUE),
          mean(dept_qtr$competitive_share, na.rm = TRUE),
          mean(dept_qtr$log_contracts, na.rm = TRUE)),
  sprintf("Departments & %d & %d & %d \\\\",
          38, 38, 38),
  sprintf("Observations & %s & %s & %s \\\\",
          format(nobs(m1_comp), big.mark = ","),
          format(nobs(m1_int), big.mark = ","),
          format(nobs(m1_log), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} Each column reports department-quarter regressions with department and quarter fixed effects. ",
         "Column~(1) uses a binary indicator for post-SECOP~II adoption (first SECOP~II contract in the department). ",
         "Column~(2) uses the continuous SECOP~II share (fraction of contracts on SECOP~II) as treatment intensity. ",
         "Column~(3) reports effects on total contract volume. ",
         "Standard errors clustered at the department level in parentheses. ",
         "Sample: 38 departments, 2015--2021, quarterly."),
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_main_did.tex")

# ============================================================
# TABLE 3: SECOP II Bidder Analysis
# ============================================================
tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Early Adoption and Competition in SECOP~II}",
  "\\label{tab:bidders}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Number of & Single-Bidder & Award/Reserve \\\\",
  " & Bidders & Rate & Ratio \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  sprintf("Early adopter & %s & %s & %s \\\\",
          sprintf("%.3f", coef(m2_bid)["early_adopter"]),
          sprintf("%.4f", coef(m2_sb)["early_adopter"]),
          sprintf("%.4f", coef(m2_ar)["early_adopter"])),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
          sprintf("%.3f", se(m2_bid)["early_adopter"]),
          sprintf("%.4f", se(m2_sb)["early_adopter"]),
          sprintf("%.4f", se(m2_ar)["early_adopter"])),
  "\\midrule",
  "Quarter FE & Yes & Yes & Yes \\\\",
  "Modality FE & Yes & Yes & Yes \\\\",
  sprintf("Mean dep.\\ var. & %.2f & %.3f & %.3f \\\\",
          process_summary$mean_bidders,
          process_summary$sb_rate,
          process_summary$mean_ar),
  sprintf("Observations & %s & %s & %s \\\\",
          format(nobs(m2_bid), big.mark = ","),
          format(nobs(m2_sb), big.mark = ","),
          format(nobs(m2_ar), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} Each column reports process-level regressions of competitive procurement outcomes ",
         "on an indicator for early SECOP~II adoption (first tercile of adoption dates). ",
         "Sample restricted to competitive modalities with at least one bidder. ",
         "Standard errors clustered at the entity level in parentheses. ",
         "Quarter and modality fixed effects absorb time trends and modality-specific bidding patterns."),
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_bidders.tex")

# ============================================================
# TABLE 4: Robustness
# ============================================================
tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Department DiD} & \\multicolumn{2}{c}{SECOP II Processes} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Baseline & Placebo: & Baseline & Exclude \\\\",
  " & Comp.\\ Share & Direct Share & SB Rate & Bogot\\'{a} \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Post adoption & %s & %s & & %s \\\\",
          sprintf("%.4f", coef(m1_comp)["post_adopt"]),
          sprintf("%.4f", coef(m_placebo)["post_adopt"]),
          sprintf("%.4f", coef(m_no_bog)["post_adopt"])),
  sprintf(" & (%s) & (%s) & & (%s) \\\\",
          sprintf("%.4f", se(m1_comp)["post_adopt"]),
          sprintf("%.4f", se(m_placebo)["post_adopt"]),
          sprintf("%.4f", se(m_no_bog)["post_adopt"])),
  sprintf("Early adopter & & & %s & \\\\",
          sprintf("%.4f", coef(m2_sb)["early_adopter"])),
  sprintf(" & & & (%s) & \\\\",
          sprintf("%.4f", se(m2_sb)["early_adopter"])),
  "\\midrule",
  "Department FE & Yes & Yes & & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Modality FE & & & Yes & \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1_comp), big.mark = ","),
          format(nobs(m_placebo), big.mark = ","),
          format(nobs(m2_sb), big.mark = ","),
          format(nobs(m_no_bog), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} Column~(1) reproduces the baseline department-level estimate. ",
         "Column~(2) reports the placebo: direct contracting share should be unaffected by bidding infrastructure improvements. ",
         "Column~(3) reports the baseline process-level estimate (single-bidder rate for early vs.\\ late adopters). ",
         "Column~(4) excludes Bogot\\'{a}, the largest department and earliest adopter. ",
         "Standard errors clustered at the department level (columns 1--2, 4) or entity level (column 3)."),
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_robustness.tex")

# ============================================================
# TABLE F1: SDE
# ============================================================
# Main outcome: competitive share from dept DiD (intensity specification)
beta_main <- coef(m1_int)["secopii_share"]
se_main   <- se(m1_int)["secopii_share"]
sd_y_main <- sd(dept_qtr$competitive_share, na.rm = TRUE)
sd_x_main <- sd(dept_qtr$secopii_share, na.rm = TRUE)
sde_main  <- beta_main * sd_x_main / sd_y_main
sde_se_main <- se_main * sd_x_main / sd_y_main

# Second outcome: single-bidder rate from cross-sectional
beta_sb <- coef(m2_sb)["early_adopter"]
se_sb   <- se(m2_sb)["early_adopter"]
sd_y_sb <- process_summary$sb_rate * (1 - process_summary$sb_rate)  # approx SD for binary
sd_y_sb_actual <- sd(s2c$single_bidder, na.rm = TRUE)
sde_sb  <- beta_sb / sd_y_sb_actual
sde_se_sb <- se_sb / sd_y_sb_actual

classify <- function(s) {
  if (abs(s) < 0.005) return("Null")
  if (abs(s) < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (abs(s) < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}

# Heterogeneity: by department size
dept_size <- dept_qtr[, .(total = sum(n_total, na.rm = TRUE)), by = department]
med_size <- median(dept_size$total)
large_depts <- dept_size[total >= med_size, department]
small_depts <- dept_size[total < med_size, department]

m_large <- feols(competitive_share ~ secopii_share | department + yq,
                 data = dept_qtr[department %in% large_depts], cluster = ~department)
m_small <- feols(competitive_share ~ secopii_share | department + yq,
                 data = dept_qtr[department %in% small_depts], cluster = ~department)

sd_y_large <- sd(dept_qtr[department %in% large_depts]$competitive_share, na.rm = TRUE)
sd_x_large <- sd(dept_qtr[department %in% large_depts]$secopii_share, na.rm = TRUE)
sd_y_small <- sd(dept_qtr[department %in% small_depts]$competitive_share, na.rm = TRUE)
sd_x_small <- sd(dept_qtr[department %in% small_depts]$secopii_share, na.rm = TRUE)

sde_large <- coef(m_large)["secopii_share"] * sd_x_large / sd_y_large
sde_se_large <- se(m_large)["secopii_share"] * sd_x_large / sd_y_large
sde_small <- coef(m_small)["secopii_share"] * sd_x_small / sd_y_small
sde_se_small <- se(m_small)["secopii_share"] * sd_x_small / sd_y_small

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Does transitioning government procurement from an informational platform ",
  "to a fully transactional e-procurement system increase competitive bidding in public contracts? ",
  "\\textbf{Policy mechanism:} Colombia's SECOP~II platform (staggered rollout 2015--2022) replaced ",
  "SECOP~I, a publication-only portal, with a fully transactional interface where firms submit bids, ",
  "upload documents, and receive awards entirely online, reducing the transaction costs of participating ",
  "in competitive procurement processes. ",
  "\\textbf{Outcome definition:} Competitive share is the fraction of a department's quarterly contracts ",
  "awarded through competitive modalities (licitaci\\'{o}n p\\'{u}blica, selecci\\'{o}n abreviada, ",
  "m\\'{i}nima cuant\\'{i}a, concurso de m\\'{e}ritos) versus direct contracting. ",
  "\\textbf{Treatment:} Continuous --- SECOP~II share is the fraction of department-quarter contracts ",
  "processed on the transactional platform (varies 0 to 1). ",
  "\\textbf{Data:} Colombia Compra Eficiente SECOP Integrado, 2015--2021, department-quarter panel, ",
  format(nrow(dept_qtr), big.mark = ","), " department-quarter observations across 38 departments. ",
  "\\textbf{Method:} Difference-in-differences with department and year-quarter fixed effects; ",
  "standard errors clustered at department level. ",
  "\\textbf{Sample:} All departments with at least 4 quarters of procurement data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Competitive share & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_main, se_main, sd_y_main, sde_main, sde_se_main, classify(sde_main)),
  sprintf("Single-bidder rate & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_sb, se_sb, sd_y_sb_actual, sde_sb, sde_se_sb, classify(sde_sb)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (department size splits)}} \\\\[3pt]",
  sprintf("Comp.\\ share (large depts) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          coef(m_large)["secopii_share"], se(m_large)["secopii_share"],
          sd_y_large, sde_large, sde_se_large, classify(sde_large)),
  sprintf("Comp.\\ share (small depts) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          coef(m_small)["secopii_share"], se(m_small)["secopii_share"],
          sd_y_small, sde_small, sde_se_small, classify(sde_small)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1, "tables/tabF1_sde.tex")

cat("All tables written.\n")
cat("Files:", paste(list.files("tables"), collapse = ", "), "\n")
