## 05_tables.R — Generate all LaTeX tables
## APEP apep_1331: The No-Advice Trap

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

sumstats <- panel %>%
  group_by(product_category, period = ifelse(post, "Post-ban", "Pre-ban")) %>%
  summarise(
    mean_complaints = round(mean(new_complaints)),
    sd_complaints = round(sd(new_complaints)),
    mean_uphold = round(mean(uphold_rate, na.rm = TRUE), 3),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(period), product_category)

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: FOS Pension Complaints by Product Category}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "& \\multicolumn{2}{c}{New Complaints} & Uphold & \\\\",
  "Product Category & Mean & SD & Rate & Quarters \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-ban (Q2 2014 -- Q3 2020)}} \\\\"
)

for (i in which(sumstats$period == "Pre-ban")) {
  r <- sumstats[i, ]
  treated_mark <- ifelse(r$product_category == "DB Transfer", "$^{\\dagger}$", "")
  tab1_lines <- c(tab1_lines, sprintf(
    "%s%s & %d & %d & %.3f & %d \\\\",
    r$product_category, treated_mark, r$mean_complaints, r$sd_complaints, r$mean_uphold, r$n
  ))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel B: Post-ban (Q4 2020 -- Q2 2026)}} \\\\"
)

for (i in which(sumstats$period == "Post-ban")) {
  r <- sumstats[i, ]
  treated_mark <- ifelse(r$product_category == "DB Transfer", "$^{\\dagger}$", "")
  tab1_lines <- c(tab1_lines, sprintf(
    "%s%s & %d & %d & %.3f & %d \\\\",
    r$product_category, treated_mark, r$mean_complaints, r$sd_complaints, r$mean_uphold, r$n
  ))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} New Complaints is the count of new cases referred to the Financial Ombudsman Service per product category per quarter. Uphold Rate is the fraction of ombudsman decisions in the consumer's favour. $^{\\dagger}$Treated product category (subject to FCA PS20/6 contingent charging ban from October 2020). The pre-ban period spans Q2 2014 through Q3 2020 (21 quarters); the post-ban period spans Q4 2020 through Q2 2026 (17 quarters). Values censored as $<$10 by FOS are imputed at 5.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_sumstats.tex"))
cat("Table 1 saved.\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================

cat("=== Generating Table 2: Main DiD Results ===\n")

# Re-run with HC1 (heteroskedasticity-robust) SEs for comparison
panel_uphold <- panel %>% filter(!is.na(uphold_rate))

m1_level <- feols(new_complaints ~ did | product_category + time_index, data = panel)
m1_log <- feols(ln_complaints ~ did | product_category + time_index, data = panel)
m1_uphold <- feols(uphold_rate ~ did | product_category + time_index, data = panel_uphold)

m1_level_hc <- feols(new_complaints ~ did | product_category + time_index,
                     data = panel, vcov = "HC1")
m1_log_hc <- feols(ln_complaints ~ did | product_category + time_index,
                   data = panel, vcov = "HC1")
m1_uphold_hc <- feols(uphold_rate ~ did | product_category + time_index,
                      data = panel_uphold, vcov = "HC1")

# Extract results
get_row <- function(model, label) {
  b <- coef(model)["did"]
  se <- sqrt(diag(vcov(model)))["did"]
  p <- pvalue(model)["did"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(label = label, b = b, se = se, p = p, stars = stars,
       n = model$nobs, r2 = fitstat(model, "wr2")[[1]])
}

rows <- list(
  get_row(m1_level, "Level"),
  get_row(m1_log, "Log"),
  get_row(m1_uphold, "Uphold rate")
)

rows_hc <- list(
  get_row(m1_level_hc, "Level (HC1)"),
  get_row(m1_log_hc, "Log (HC1)"),
  get_row(m1_uphold_hc, "Uphold rate (HC1)")
)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Contingent Charging Ban and Pension Transfer Complaints}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) \\\\",
  "& New Cases & ln(New Cases) & Uphold Rate \\\\",
  "\\hline",
  sprintf("\\textit{Panel A: Clustered SEs} & & & \\\\"),
  sprintf("Treated $\\times$ Post & %.1f%s & %.3f%s & %.3f%s \\\\",
          rows[[1]]$b, rows[[1]]$stars, rows[[2]]$b, rows[[2]]$stars, rows[[3]]$b, rows[[3]]$stars),
  sprintf("& (%.1f) & (%.3f) & (%.3f) \\\\",
          rows[[1]]$se, rows[[2]]$se, rows[[3]]$se),
  sprintf("[%.3f] & [%.3f] & [%.3f] \\\\",
          rows[[1]]$p, rows[[2]]$p, rows[[3]]$p),
  "\\hline",
  sprintf("\\textit{Panel B: HC1 SEs} & & & \\\\"),
  sprintf("Treated $\\times$ Post & %.1f%s & %.3f%s & %.3f%s \\\\",
          rows_hc[[1]]$b, rows_hc[[1]]$stars, rows_hc[[2]]$b, rows_hc[[2]]$stars, rows_hc[[3]]$b, rows_hc[[3]]$stars),
  sprintf("& (%.1f) & (%.3f) & (%.3f) \\\\",
          rows_hc[[1]]$se, rows_hc[[2]]$se, rows_hc[[3]]$se),
  "\\hline",
  sprintf("Observations & %d & %d & %d \\\\", rows[[1]]$n, rows[[2]]$n, rows[[3]]$n),
  "Product FE & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes \\\\",
  sprintf("Permutation $p$-value & %.3f & & \\\\", results$perm_pvalue),
  sprintf("Within $R^2$ & %.3f & %.3f & %.3f \\\\",
          rows[[1]]$r2, rows[[2]]$r2, rows[[3]]$r2),
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Each column reports the coefficient on $\\text{Treated} \\times \\text{Post}$ from a two-way fixed effects regression with product category and quarter fixed effects. Treated is an indicator for defined benefit pension transfer complaints; Post is an indicator for quarters on or after Q4 2020. Panel~A reports standard errors clustered at the product level (4 clusters) in parentheses and $p$-values in brackets; Panel~B reports heteroskedasticity-robust (HC1) standard errors. The permutation $p$-value in column~(1) tests whether the absolute coefficient exceeds that obtained when each of the four products is permuted as treated. Stars: $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

# ============================================================
# Table 3: Robustness — Pairwise DiD with HC1 SEs
# ============================================================

cat("=== Generating Table 3: Pairwise DiD ===\n")

controls <- c("Annuities", "Personal Pensions", "SIPP")

tab3_body <- character()
for (ctrl in controls) {
  pair_data <- panel %>%
    filter(product_category %in% c("DB Transfer", ctrl))

  # Use HC1 for pairwise (only 2 clusters, cluster SEs degenerate)
  m_pair_l <- feols(new_complaints ~ did | product_category + time_index,
                    data = pair_data, vcov = "HC1")
  m_pair_u <- feols(uphold_rate ~ did | product_category + time_index,
                    data = pair_data %>% filter(!is.na(uphold_rate)), vcov = "HC1")

  bl <- coef(m_pair_l)["did"]
  sel <- sqrt(diag(vcov(m_pair_l)))["did"]
  pl <- pvalue(m_pair_l)["did"]
  sl <- ifelse(pl < 0.01, "***", ifelse(pl < 0.05, "**", ifelse(pl < 0.1, "*", "")))

  bu <- coef(m_pair_u)["did"]
  seu <- sqrt(diag(vcov(m_pair_u)))["did"]
  pu <- pvalue(m_pair_u)["did"]
  su <- ifelse(pu < 0.01, "***", ifelse(pu < 0.05, "**", ifelse(pu < 0.1, "*", "")))

  tab3_body <- c(tab3_body,
    sprintf("vs.\\ %s & %.1f%s & %.3f%s \\\\", ctrl, bl, sl, bu, su),
    sprintf("& (%.1f) & (%.3f) \\\\", sel, seu)
  )
}

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Pairwise DiD: DB Transfers vs.\\ Each Control Product}",
  "\\label{tab:pairwise}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Control product & New Cases & Uphold Rate \\\\",
  "\\hline",
  tab3_body,
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.75\\textwidth}}{\\footnotesize \\textit{Notes:} Each row reports the $\\text{Treated} \\times \\text{Post}$ coefficient from a two-way FE regression using only DB Transfer and the indicated control product. HC1 standard errors in parentheses. Stars: $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_pairwise.tex"))
cat("Table 3 saved.\n")

# ============================================================
# Table 4: Robustness — COVID exclusion, placebo, pre-post
# ============================================================

cat("=== Generating Table 4: Robustness ===\n")

# Reconstruct models with consistent specs
# (a) Exclude COVID
nocovid <- panel %>% filter(!(time_index >= 2020.0 & time_index <= 2020.5))
m_nc_l <- feols(new_complaints ~ did | product_category + time_index,
                data = nocovid, vcov = "HC1")
m_nc_u <- feols(uphold_rate ~ did | product_category + time_index,
                data = nocovid %>% filter(!is.na(uphold_rate)), vcov = "HC1")

# (b) Placebo: Annuities as treated (among controls only)
placebo_data <- panel %>%
  filter(product_category != "DB Transfer") %>%
  mutate(placebo_treated = as.integer(product_category == "Annuities"),
         placebo_did = placebo_treated * post)
m_plac <- feols(uphold_rate ~ placebo_did | product_category + time_index,
                data = placebo_data %>% filter(!is.na(uphold_rate)), vcov = "HC1")

# (c) Pre-post (treated only)
db_only <- panel %>% filter(product_category == "DB Transfer")
m_pp_l <- lm(new_complaints ~ post, data = db_only)
m_pp_u <- lm(uphold_rate ~ post, data = db_only %>% filter(!is.na(uphold_rate)))

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & New Cases & Uphold Rate \\\\",
  "\\hline",
  sprintf("\\textit{A. Baseline DiD} & %.1f & %.3f%s \\\\",
          coef(results$m1_level)["did"],
          coef(results$m1_uphold)["did"],
          ifelse(pvalue(results$m1_uphold)["did"] < 0.01, "***",
                 ifelse(pvalue(results$m1_uphold)["did"] < 0.05, "**", ""))),
  sprintf("& (%.1f) & (%.3f) \\\\",
          sqrt(diag(vcov(results$m1_level)))["did"],
          sqrt(diag(vcov(results$m1_uphold)))["did"]),
  sprintf("\\textit{B. Excl.\\ COVID quarters} & %.1f & %.3f%s \\\\",
          coef(m_nc_l)["did"],
          coef(m_nc_u)["did"],
          ifelse(pvalue(m_nc_u)["did"] < 0.01, "***",
                 ifelse(pvalue(m_nc_u)["did"] < 0.05, "**", ""))),
  sprintf("& (%.1f) & (%.3f) \\\\",
          sqrt(diag(vcov(m_nc_l)))["did"],
          sqrt(diag(vcov(m_nc_u)))["did"]),
  sprintf("\\textit{C. DB Transfer pre-post only} & %.1f%s & %.3f \\\\",
          coef(m_pp_l)["post"],
          ifelse(summary(m_pp_l)$coefficients["post", "Pr(>|t|)"] < 0.01, "***", ""),
          coef(m_pp_u)["post"]),
  sprintf("& (%.1f) & (%.3f) \\\\",
          summary(m_pp_l)$coefficients["post", "Std. Error"],
          summary(m_pp_u)$coefficients["post", "Std. Error"]),
  sprintf("\\textit{D. Placebo (Annuities treated)} & --- & %.3f \\\\",
          coef(m_plac)["placebo_did"]),
  sprintf("& & (%.3f) \\\\",
          sqrt(diag(vcov(m_plac)))["placebo_did"]),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.8\\textwidth}}{\\footnotesize \\textit{Notes:} Row~A reproduces the baseline (clustered SEs). Row~B drops Q1--Q2 calendar 2020 (COVID disruption). Row~C uses only DB Transfer with a post-ban indicator (no control group). Row~D tests a placebo where Annuities are assigned treatment among the three untreated products. Stars: $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))
cat("Table 4 saved.\n")

# ============================================================
# Table F1: SDE table (Appendix)
# ============================================================

cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Pre-treatment SDs
pre_sd_complaints <- sd(panel$new_complaints[panel$post == 0])
pre_sd_uphold <- sd(panel$uphold_rate[panel$post == 0], na.rm = TRUE)
pre_sd_complaints_treated <- sd(panel$new_complaints[panel$post == 0 & panel$treated == 1])
pre_sd_uphold_treated <- sd(panel$uphold_rate[panel$post == 0 & panel$treated == 1], na.rm = TRUE)

# Coefficients and SEs
b_level <- coef(results$m1_level)["did"]
se_level <- sqrt(diag(vcov(results$m1_level)))["did"]
b_uphold <- coef(results$m1_uphold)["did"]
se_uphold <- sqrt(diag(vcov(results$m1_uphold)))["did"]

# SDE = beta / SD(Y)
sde_level <- b_level / pre_sd_complaints
se_sde_level <- se_level / pre_sd_complaints
sde_uphold <- b_uphold / pre_sd_uphold
se_sde_uphold <- se_uphold / pre_sd_uphold

classify <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneity: pairwise splits
# Split 1: DB Transfer vs Annuities only
pair_ann <- panel %>% filter(product_category %in% c("DB Transfer", "Annuities"))
m_ann <- feols(uphold_rate ~ did | product_category + time_index,
               data = pair_ann %>% filter(!is.na(uphold_rate)), vcov = "HC1")
b_ann <- coef(m_ann)["did"]
se_ann <- sqrt(diag(vcov(m_ann)))["did"]
sde_ann <- b_ann / pre_sd_uphold
se_sde_ann <- se_ann / pre_sd_uphold

# Split 2: DB Transfer vs SIPP only
pair_sipp <- panel %>% filter(product_category %in% c("DB Transfer", "SIPP"))
m_sipp <- feols(uphold_rate ~ did | product_category + time_index,
                data = pair_sipp %>% filter(!is.na(uphold_rate)), vcov = "HC1")
b_sipp <- coef(m_sipp)["did"]
se_sipp <- sqrt(diag(vcov(m_sipp)))["did"]
sde_sipp <- b_sipp / pre_sd_uphold
se_sde_sipp <- se_sipp / pre_sd_uphold

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does banning contingent charging for defined benefit pension transfer advice reduce consumer harm as measured by Financial Ombudsman Service complaint outcomes? ",
  "\\textbf{Policy mechanism:} FCA PS20/6 prohibited financial advisers from charging fees contingent on clients completing a DB pension transfer, eliminating the incentive to recommend unsuitable transfers that generated a 68\\% conversion rate under the conflicted model versus 28\\% under non-contingent charging. ",
  "\\textbf{Outcome definition:} FOS uphold rate --- the fraction of ombudsman final decisions ruled in favour of the consumer --- for pension product complaints by category per quarter. ",
  "\\textbf{Treatment:} Binary; the ban took effect 1 October 2020 and applied exclusively to DB pension transfer advice. ",
  "\\textbf{Data:} Financial Ombudsman Service quarterly product complaints data, Q2 2014 through Q2 2026, 4 pension product categories observed quarterly (152 product-quarter observations). ",
  "\\textbf{Method:} Two-way fixed effects DiD with product category and quarter fixed effects; standard errors clustered at the product level (4 clusters); permutation inference and HC1 SEs reported as robustness. ",
  "\\textbf{Sample:} Restricted to pension and annuity product categories at FOS; DB transfers (treated), annuities, personal pensions, and SIPPs (controls). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("New complaints & %.1f & %.1f & %.1f & %.3f & %.3f & %s \\\\",
          b_level, se_level, pre_sd_complaints, sde_level, se_sde_level, classify(sde_level)),
  sprintf("Uphold rate & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_uphold, se_uphold, pre_sd_uphold, sde_uphold, se_sde_uphold, classify(sde_uphold)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\",
  sprintf("Uphold rate (vs.\\ Annuities) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_ann, se_ann, pre_sd_uphold, sde_ann, se_sde_ann, classify(sde_ann)),
  sprintf("Uphold rate (vs.\\ SIPP) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_sipp, se_sipp, pre_sd_uphold, sde_sipp, se_sde_sipp, classify(sde_sipp)),
  "\\hline\\hline",
  sprintf("\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\begin{itemize}[leftmargin=*,nosep] %s \\end{itemize}}", sde_notes),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
cat(sprintf("SDE (new complaints): %.3f [%s]\n", sde_level, classify(sde_level)))
cat(sprintf("SDE (uphold rate): %.3f [%s]\n", sde_uphold, classify(sde_uphold)))
