# 05_tables.R — Generate all LaTeX tables for Alice Corp paper

library(data.table)
library(fixest)
library(dplyr)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))

results <- readRDS("data/results.rds")
rob <- readRDS("data/robustness.rds")
panel <- readRDS("data/analysis_panel.rds")
shock <- readRDS("data/alice_shock.rds")

dir.create("tables", showWarnings = FALSE)

tc36 <- panel %>% filter(tc == "TC3600", total_actions > 0) %>%
  mutate(log_total = log(as.numeric(total_actions) + 1))

# Ensure numeric types
shock <- shock %>%
  mutate(across(c(alice_shock, pre_s101_rate, post_s101_rate, pre_s103_rate,
                  post_s103_rate, s103_shock), as.numeric))

# ============================================================
# Helper
# ============================================================
extract_coef <- function(model, var) {
  b <- coef(model)[var]
  se <- sqrt(vcov(model)[var, var])
  p <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  n <- nobs(model)
  list(b = b, se = se, p = p, stars = stars, n = n)
}
fmt_b <- function(c) sprintf("%.4f%s", c$b, c$stars)
fmt_se <- function(c) sprintf("(%.4f)", c$se)

classify <- function(s) {
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

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

tc36_shock <- shock %>% filter(tc == "TC3600", !is.na(alice_shock))
n_au <- nrow(tc36_shock)
n_obs <- nrow(tc36)

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Technology Center 3600, 2012--2016}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule",
  sprintf("\\multicolumn{5}{l}{\\textit{Panel A: Art-unit level (N = %d art units)}} \\\\", n_au),
  sprintf("  Alice shock ($\\Delta$ \\S101 rate) & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(tc36_shock$alice_shock), sd(tc36_shock$alice_shock),
          min(tc36_shock$alice_shock), max(tc36_shock$alice_shock)),
  sprintf("  Pre-Alice \\S101 rate & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(tc36_shock$pre_s101_rate, na.rm=T), sd(tc36_shock$pre_s101_rate, na.rm=T),
          min(tc36_shock$pre_s101_rate, na.rm=T), max(tc36_shock$pre_s101_rate, na.rm=T)),
  sprintf("  Post-Alice \\S101 rate & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(tc36_shock$post_s101_rate, na.rm=T), sd(tc36_shock$post_s101_rate, na.rm=T),
          min(tc36_shock$post_s101_rate, na.rm=T), max(tc36_shock$post_s101_rate, na.rm=T)),
  sprintf("  Pre-Alice \\S103 rate & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(tc36_shock$pre_s103_rate, na.rm=T), sd(tc36_shock$pre_s103_rate, na.rm=T),
          min(tc36_shock$pre_s103_rate, na.rm=T), max(tc36_shock$pre_s103_rate, na.rm=T)),
  sprintf("  Pre-period total actions & %s & %s & %s & %s \\\\",
          formatC(mean(as.numeric(tc36_shock$pre_total)), format="f", digits=0, big.mark=","),
          formatC(sd(as.numeric(tc36_shock$pre_total)), format="f", digits=0, big.mark=","),
          formatC(min(as.numeric(tc36_shock$pre_total)), format="d", big.mark=","),
          formatC(max(as.numeric(tc36_shock$pre_total)), format="d", big.mark=",")),
  sprintf("  High-shock indicator (>20pp) & %.3f & %.3f & 0 & 1 \\\\",
          mean(tc36_shock$high_shock), sd(tc36_shock$high_shock)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Data from USPTO Office Action Research Dataset, 2012Q1--2016Q4. ",
         "Technology Center 3600 covers business methods, software, and financial instruments. ",
         "The Alice shock is the change in art-unit \\S101 rejection rate from pre-Alice ",
         "(2012Q1--2014Q2) to post-Alice (2014Q3--2016Q4)."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")
cat("  Saved tables/tab1_summary.tex\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results\n")

# Extract key coefficients
m3c <- extract_coef(results$m3, "shock_x_post")  # Log actions
m4c <- extract_coef(results$m4, "shock_x_post")  # §103 placebo
m5c <- extract_coef(results$m5, "tc36_x_post")   # Cross-TC
r1c <- extract_coef(rob$r1_binary, "treat_x_post") # Binary treatment

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Alice Shock on Patent Examination Outcomes}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & \\S101 rate & \\S103 rate & Log actions & \\S101 rate \\\\",
  " & Binary DiD & Placebo & Volume & Cross-TC \\\\",
  "\\midrule",
  sprintf("High shock $\\times$ Post & %s & & & \\\\", fmt_b(r1c)),
  sprintf(" & %s & & & \\\\", fmt_se(r1c)),
  sprintf("Alice shock $\\times$ Post & & %s & %s & \\\\",
          fmt_b(m4c), fmt_b(m3c)),
  sprintf(" & & %s & %s & \\\\", fmt_se(m4c), fmt_se(m3c)),
  sprintf("TC3600 $\\times$ Post & & & & %s \\\\", fmt_b(m5c)),
  sprintf(" & & & & %s \\\\", fmt_se(m5c)),
  "\\\\",
  "Art unit FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(r1c$n, format="d", big.mark=","),
          formatC(m4c$n, format="d", big.mark=","),
          formatC(m3c$n, format="d", big.mark=","),
          formatC(m5c$n, format="d", big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the art-unit level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "Column (1) compares art units with Alice shock $>$20pp to those $<$5pp. ",
         "Column (2) is a placebo: \\S103 (obviousness) rejections should not respond to an eligibility ruling. ",
         "The significant negative coefficient suggests partial substitution from \\S103 to \\S101 rejections. ",
         "Column (3) tests whether Alice affected prosecution volume. ",
         "Column (4) uses a cross-TC design comparing TC 3600 to TC 1600 (chemistry). ",
         "All specifications use art-unit and period fixed effects."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")
cat("  Saved tables/tab2_main.tex\n")

# ============================================================
# Table 3: Alice Shock Distribution
# ============================================================
cat("Generating Table 3: Shock Distribution\n")

# Show selected art units with their shocks
top10 <- tc36_shock %>% arrange(desc(alice_shock)) %>% head(10)
bot5 <- tc36_shock %>% arrange(alice_shock) %>% head(5)
showcase <- bind_rows(top10, bot5) %>% arrange(desc(alice_shock))

tab3_rows <- sapply(1:nrow(showcase), function(i) {
  r <- showcase[i,]
  sprintf("  %s & %.3f & %.3f & %+.3f \\\\",
          r$art_unit, r$pre_s101_rate, r$post_s101_rate, r$alice_shock)
})

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Within-TC Heterogeneity: Selected Art Unit Alice Shocks}",
  "\\label{tab:heterogeneity}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Art Unit & Pre-Alice \\S101 & Post-Alice \\S101 & $\\Delta$ \\S101 \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Highest Alice exposure}} \\\\",
  tab3_rows[1:10],
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Lowest Alice exposure}} \\\\",
  tab3_rows[11:15],
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Pre-Alice is the average \\S101 rejection rate 2012Q1--2014Q2; ",
         "post-Alice is 2014Q3--2016Q4. $\\Delta$\\S101 is the change. ",
         "All art units are within Technology Center 3600. ",
         "The range from near-zero to $+$55pp demonstrates the massive within-TC heterogeneity ",
         "created by the \\textit{Alice} decision."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_heterogeneity.tex")
cat("  Saved tables/tab3_heterogeneity.tex\n")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness\n")

r2c <- extract_coef(rob$r2_notrans, "shock_x_post")
r5c <- extract_coef(rob$r5_weighted, "shock_x_post")
r6c <- extract_coef(rob$r6_placebo, "shock_x_post")

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks: Cross-TC and Placebo Specifications}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Cross-TC & Weighted & \\S103 \\\\",
  " & DiD & by volume & placebo \\\\",
  "\\midrule",
  sprintf("TC3600 $\\times$ Post & %s & & \\\\", fmt_b(m5c)),
  sprintf(" & %s & & \\\\", fmt_se(m5c)),
  sprintf("Alice shock $\\times$ Post & & %s & %s \\\\",
          fmt_b(r5c), fmt_b(r6c)),
  sprintf(" & & %s & %s \\\\", fmt_se(r5c), fmt_se(r6c)),
  "\\\\",
  "Art unit FE & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          formatC(m5c$n, format="d", big.mark=","),
          formatC(r5c$n, format="d", big.mark=","),
          formatC(r6c$n, format="d", big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the art-unit level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "(1) Cross-TC comparison: TC 3600 (treated) vs.\\ TC 1600 chemistry (control). ",
         "(2) Weighted by pre-period action volume to downweight small art units. ",
         "(3) \\S103 (obviousness) placebo: significant negative coefficient consistent with ",
         "substitution from \\S103 to \\S101 rejections in high-exposure art units."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_robustness.tex")
cat("  Saved tables/tab4_robustness.tex\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating Table F1: SDE\n")

# Cross-TC DiD: genuine causal estimate
beta_xtc <- coef(results$m5)["tc36_x_post"]
se_xtc <- sqrt(vcov(results$m5)["tc36_x_post", "tc36_x_post"])
full_panel <- panel %>% filter(total_actions > 0)
sd_y_s101 <- sd(as.numeric(full_panel$s101_rate), na.rm = TRUE)
sde_xtc <- beta_xtc / sd_y_s101  # Binary treatment (TC36 = 1/0)
se_sde_xtc <- se_xtc / sd_y_s101

# Log actions: continuous treatment
beta_log <- coef(results$m3)["shock_x_post"]
se_log <- sqrt(vcov(results$m3)["shock_x_post", "shock_x_post"])
sd_y_log <- sd(log(as.numeric(tc36$total_actions) + 1), na.rm = TRUE)
sd_x_shock <- sd(tc36_shock$alice_shock)
sde_log <- beta_log * sd_x_shock / sd_y_log
se_sde_log <- se_log * sd_x_shock / sd_y_log

# Binary treatment: high-shock DiD
beta_bin <- coef(rob$r1_binary)["treat_x_post"]
se_bin <- sqrt(vcov(rob$r1_binary)["treat_x_post", "treat_x_post"])
tc36_binary <- panel %>% filter(tc == "TC3600", total_actions > 0,
                                 alice_shock > 0.20 | alice_shock < 0.05)
sd_y_bin <- sd(as.numeric(tc36_binary$s101_rate), na.rm = TRUE)
sde_bin <- beta_bin / sd_y_bin
se_sde_bin <- se_bin / sd_y_bin

# §103 substitution
beta_s103 <- coef(results$m4)["shock_x_post"]
se_s103 <- sqrt(vcov(results$m4)["shock_x_post", "shock_x_post"])
sd_y_s103 <- sd(as.numeric(tc36$s103_rate), na.rm = TRUE)
sde_s103 <- beta_s103 * sd_x_shock / sd_y_s103
se_sde_s103 <- se_s103 * sd_x_shock / sd_y_s103

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} How does the Supreme Court's \\textit{Alice Corp v.\\ CLS Bank} decision ",
  "affect patent examination outcomes across technology areas with differential exposure to the new ",
  "eligibility standard within the USPTO? ",
  "\\textbf{Policy mechanism:} The June 2014 \\textit{Alice} decision invalidated patents on ``abstract ideas'' ",
  "under 35 U.S.C.\\ \\S101, creating a two-step doctrinal test that patent examiners applied with highly ",
  "heterogeneous intensity across art units---financial data processing art units saw \\S101 rejection rates ",
  "rise by over 50 percentage points while database structure and agriculture art units were unaffected, ",
  "depending on the technology's proximity to the ``abstract idea'' concept. ",
  "\\textbf{Outcome definition:} (1) Art-unit \\S101 rejection rate: share of office actions containing a ",
  "\\S101 rejection. (2) Log total office actions per art unit. (3) \\S103 rejection rate (placebo). ",
  "\\textbf{Treatment:} Binary (TC 3600 vs.\\ TC 1600) for the cross-TC estimate; continuous (art-unit ",
  "Alice shock in pp) for within-TC estimates. ",
  "\\textbf{Data:} USPTO Office Action Research Dataset via the USPTO DS-API, art-unit level, 2012--2016, ",
  nrow(panel), " art-unit--period observations across ", uniqueN(panel$art_unit), " art units. ",
  "\\textbf{Method:} Difference-in-differences with art-unit and period fixed effects, standard errors ",
  "clustered at the art-unit level. ",
  "\\textbf{Sample:} Technology Center 3600 (business methods, software, financial instruments) for ",
  "within-TC analysis; TC 3600 vs.\\ TC 1600 (chemistry) for cross-TC comparison. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatments; ",
  "$= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatments. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\adjustbox{max width=\\textwidth}{",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Treatment & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("\\S101 rate & Binary (cross-TC) & %.4f & --- & %.3f & %.3f & %.3f & %s \\\\",
          beta_xtc, sd_y_s101, sde_xtc, se_sde_xtc, classify(sde_xtc)),
  sprintf("Log actions & Continuous & %.4f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_log, sd_x_shock, sd_y_log, sde_log, se_sde_log, classify(sde_log)),
  sprintf("\\S103 rate (placebo) & Continuous & %.4f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_s103, sd_x_shock, sd_y_s103, sde_s103, se_sde_s103, classify(sde_s103)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (high-shock vs.\\ low-shock art units)}} \\\\",
  sprintf("\\S101 rate & Binary ($>$20pp) & %.4f & --- & %.3f & %.3f & %.3f & %s \\\\",
          beta_bin, sd_y_bin, sde_bin, se_sde_bin, classify(sde_bin)),
  "\\bottomrule",
  "\\end{tabular}}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1, "tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
