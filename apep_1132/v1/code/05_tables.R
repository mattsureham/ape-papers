# 05_tables.R — Generate all LaTeX tables for apep_1132
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

fca <- readRDS(file.path(data_dir, "fca_panel.rds"))
boe <- readRDS(file.path(data_dir, "boe_panel.rds"))
load(file.path(data_dir, "regression_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

fca$product_fe <- factor(fca$Product)
fca$time_fe    <- factor(fca$Semester)

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Build summary stats by group and period
make_summ <- function(df, group_name) {
  pre  <- df %>% filter(post == 0)
  post <- df %>% filter(post == 1)
  data.frame(
    Group = group_name,
    `Pre Mean` = sprintf("%.2f", mean(pre$complaint_rate, na.rm = TRUE)),
    `Pre SD` = sprintf("(%.2f)", sd(pre$complaint_rate, na.rm = TRUE)),
    `Post Mean` = sprintf("%.2f", mean(post$complaint_rate, na.rm = TRUE)),
    `Post SD` = sprintf("(%.2f)", sd(post$complaint_rate, na.rm = TRUE)),
    `Pre Complaints` = format(round(mean(pre$complaints)), big.mark = ","),
    `Post Complaints` = format(round(mean(post$complaints)), big.mark = ","),
    Semesters = length(unique(df$Semester)),
    check.names = FALSE
  )
}

products_list <- sort(unique(fca$Product))
summ_rows <- lapply(products_list, function(p) {
  make_summ(fca %>% filter(Product == p), p)
})
summ_rows <- c(summ_rows, list(
  make_summ(fca %>% filter(treated == 1), "\\textit{Treated (Motor, Property)}"),
  make_summ(fca %>% filter(treated == 0), "\\textit{Control (other lines)}")
))
tab1 <- bind_rows(summ_rows)

# Write LaTeX
tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Insurance Complaints per 1,000 Policies}",
  "\\label{tab:summ}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-Ban} & \\multicolumn{2}{c}{Post-Ban} & \\multicolumn{2}{c}{Mean Complaints} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Product & Mean & SD & Mean & SD & Pre & Post \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(tab1))) {
  row <- tab1[i, ]
  if (i == nrow(tab1) - 1) tab1_tex <- c(tab1_tex, "\\midrule")
  tab1_tex <- c(tab1_tex, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    row$Group, row$`Pre Mean`, row$`Pre SD`, row$`Post Mean`, row$`Post SD`,
    row$`Pre Complaints`, row$`Post Complaints`))
}

tab1_tex <- c(tab1_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Complaint rate is complaints opened per 1,000 policies in force, half-yearly. ",
  "Pre-ban period: 2016 H2--2021 H2 (11 semesters). Post-ban period: 2022 H1--2025 H1 (7 semesters). ",
  "Treated products (Motor \\& transport, Property) are subject to the FCA's pricing remedy (PS21/5) effective January 1, 2022. ",
  "Control products (Assistance, Medical/health, Pet, Travel, Warranty) are not subject to the pricing remedy. ",
  "Source: FCA Aggregate Complaints Data.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ==============================================================================
# Table 2: Main DiD Results
# ==============================================================================
cat("=== Table 2: Main DiD ===\n")

# Re-run preferred spec (exclude travel) for the table
fca_no_travel <- fca %>% filter(Product != "Travel")
fca_no_travel$product_fe <- droplevels(factor(fca_no_travel$Product))
fca_no_travel$time_fe    <- factor(fca_no_travel$Semester)

m_pref <- feols(complaint_rate ~ treated:post | product_fe + time_fe,
                data = fca_no_travel, cluster = ~product_fe)
m_pref_log <- feols(log_complaints ~ treated:post | product_fe + time_fe,
                    data = fca_no_travel, cluster = ~product_fe)
m_pref_prov <- feols(log_provision ~ treated:post | product_fe + time_fe,
                     data = fca_no_travel, cluster = ~product_fe)

# BoE
boe$line_fe <- factor(boe$line)
boe$qtr_fe  <- factor(boe$quarter)
m_nwp <- feols(log_nwp ~ treated:post | line_fe + qtr_fe,
               data = boe, cluster = ~line_fe)
m_lr  <- feols(loss_ratio ~ treated:post | line_fe + qtr_fe,
               data = boe, cluster = ~line_fe)

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Price-Walking Ban on Insurance Outcomes}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{FCA Complaints} & \\multicolumn{2}{c}{BoE Underwriting} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}",
  " & Complaint & Log & Log & Log Net Written & Loss \\\\",
  " & Rate & Complaints & Provision & Premium & Ratio \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule"
)

add_row <- function(label, models, param = "treated:post") {
  coefs <- sapply(models, function(m) {
    c <- coef(m)[[param]]
    s <- se(m)[[param]]
    p <- pvalue(m)[[param]]
    stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
    list(coef = sprintf("%.3f%s", c, stars), se = sprintf("(%.3f)", s))
  })
  coef_line <- paste0(label, " & ", paste(coefs["coef",], collapse = " & "), " \\\\")
  se_line   <- paste0(" & ", paste(coefs["se",], collapse = " & "), " \\\\")
  c(coef_line, se_line)
}

tab2_tex <- c(tab2_tex,
  add_row("Treated $\\times$ Post", list(m_pref, m_pref_log, m_pref_prov, m_nwp, m_lr)),
  "\\midrule",
  sprintf("Product/Line FE & Yes & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Time FE & Yes & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
    nrow(fca_no_travel), nrow(fca_no_travel), nrow(fca_no_travel), nrow(boe), nrow(boe)),
  sprintf("Products/Lines & %d & %d & %d & %d & %d \\\\",
    length(unique(fca_no_travel$Product)), length(unique(fca_no_travel$Product)),
    length(unique(fca_no_travel$Product)), length(unique(boe$line)), length(unique(boe$line))),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
    fitstat(m_pref, "wr2")$wr2, fitstat(m_pref_log, "wr2")$wr2,
    fitstat(m_pref_prov, "wr2")$wr2, fitstat(m_nwp, "wr2")$wr2, fitstat(m_lr, "wr2")$wr2),
  sprintf("Pre-ban mean (treated) & %.2f & %.2f & %.2f & %.2f & %.1f \\\\",
    mean(fca_no_travel$complaint_rate[fca_no_travel$treated == 1 & fca_no_travel$post == 0]),
    mean(fca_no_travel$log_complaints[fca_no_travel$treated == 1 & fca_no_travel$post == 0]),
    mean(fca_no_travel$log_provision[fca_no_travel$treated == 1 & fca_no_travel$post == 0]),
    mean(boe$log_nwp[boe$treated == 1 & boe$post == 0], na.rm = TRUE),
    mean(boe$loss_ratio[boe$treated == 1 & boe$post == 0], na.rm = TRUE)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each column reports the coefficient from a two-way fixed effects regression of the outcome on Treated $\\times$ Post. ",
  "Columns (1)--(3) use FCA Aggregate Complaints Data (half-yearly, 2016 H2--2025 H1) excluding travel insurance, which is COVID-confounded. ",
  "Columns (4)--(5) use Bank of England Insurance Aggregate Data (quarterly, 2017 Q1--2025 Q3). ",
  "Treated products: Motor \\& transport and Property (columns 1--3); Motor liability, Motor other, and Property (columns 4--5). ",
  "Standard errors clustered at the product/line level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))

# ==============================================================================
# Table 3: Robustness
# ==============================================================================
cat("=== Table 3: Robustness ===\n")

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness of the Complaint-Rate Estimate}",
  "\\label{tab:robust}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $p$-value & $N$ \\\\",
  "\\midrule"
)

robust_rows <- list(
  c("Baseline (all products)", coef(m1_rate)[["treated:post"]], se(m1_rate)[["treated:post"]],
    pvalue(m1_rate)[["treated:post"]], nrow(fca)),
  c("Preferred: excl.\\ travel", coef(r1)[["treated:post"]], se(r1)[["treated:post"]],
    pvalue(r1)[["treated:post"]], nrow(fca %>% filter(Product != "Travel"))),
  c("Drop COVID (2020)", coef(r2)[["treated:post"]], se(r2)[["treated:post"]],
    pvalue(r2)[["treated:post"]], nrow(fca %>% filter(!Semester %in% c("2020 H1","2020 H2")))),
  c("Excl.\\ travel + drop COVID", coef(r3)[["treated:post"]], se(r3)[["treated:post"]],
    pvalue(r3)[["treated:post"]], nrow(fca %>%
      filter(Product != "Travel", !Semester %in% c("2020 H1","2020 H2")))),
  c("Placebo (2020 H1)", coef(r4)[["treated:placebo_post"]], se(r4)[["treated:placebo_post"]],
    pvalue(r4)[["treated:placebo_post"]], nrow(fca %>% filter(Semester < "2022 H1")))
)

for (rr in robust_rows) {
  stars <- ifelse(as.numeric(rr[4]) < 0.01, "^{***}",
           ifelse(as.numeric(rr[4]) < 0.05, "^{**}",
           ifelse(as.numeric(rr[4]) < 0.1, "^{*}", "")))
  tab3_tex <- c(tab3_tex,
    sprintf("%s & $%.3f%s$ & (%.3f) & %.3f & %d \\\\",
      rr[1], as.numeric(rr[2]), stars, as.numeric(rr[3]), as.numeric(rr[4]), as.integer(rr[5])))
}

tab3_tex <- c(tab3_tex,
  "\\midrule",
  sprintf("Randomization inference $p$-value & \\multicolumn{4}{c}{%.3f} \\\\", ri_pval),
  sprintf("Wild cluster bootstrap $p$-value & \\multicolumn{4}{c}{%.3f} \\\\",
    ifelse(!is.null(boot_m1), summary(boot_m1)$p.value, NA)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each row reports the Treated $\\times$ Post coefficient from a TWFE regression of complaint rate (per 1,000 policies). ",
  "Standard errors clustered at the product level. The placebo test applies a fictitious treatment date of 2020 H1 using only pre-reform data. ",
  "Randomization inference (1,000 permutations) randomly assigns 2 of 7 products as treated and computes two-sided $p$-values. ",
  "Wild cluster bootstrap uses Mammen weights with 9,999 iterations. ",
  "Both non-parametric methods account for the small number of product-level clusters (7 baseline, 6 excl.\\ travel). ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))

# ==============================================================================
# Table 4: Event Study Coefficients
# ==============================================================================
cat("=== Table 4: Event Study ===\n")

# Re-run event study on preferred spec (no travel)
fca_no_travel$rel_time <- fca_no_travel$time_idx - 13
fca_no_travel$rel_time_binned <- pmin(pmax(fca_no_travel$rel_time, -6), 5)

m_es_pref <- feols(complaint_rate ~ i(rel_time_binned, treated, ref = -1) |
                     product_fe + time_fe,
                   data = fca_no_travel, cluster = ~product_fe)

es_coefs <- data.frame(
  rel_time = as.integer(gsub("rel_time_binned::|:treated", "",
    names(coef(m_es_pref)))),
  coef = coef(m_es_pref),
  se = se(m_es_pref),
  pval = pvalue(m_es_pref)
)
es_coefs <- es_coefs[order(es_coefs$rel_time), ]

# Map rel_time to semester labels
sem_map <- c("-6" = "$\\leq$2019 H1", "-5" = "2019 H2", "-4" = "2020 H1",
             "-3" = "2020 H2", "-2" = "2021 H1", "-1" = "2021 H2 (ref.)",
             "0" = "2022 H1", "1" = "2022 H2", "2" = "2023 H1",
             "3" = "2023 H2", "4" = "2024 H1", "5" = "$\\geq$2024 H2")

tab4_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Complaint Rate Relative to 2021 H2}",
  "\\label{tab:event}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Period & Coefficient & SE & $p$-value \\\\",
  "\\midrule",
  "\\textit{Pre-ban} & & & \\\\"
)

for (i in seq_len(nrow(es_coefs))) {
  rt <- as.character(es_coefs$rel_time[i])
  sem <- sem_map[rt]
  stars <- ifelse(es_coefs$pval[i] < 0.01, "^{***}",
           ifelse(es_coefs$pval[i] < 0.05, "^{**}",
           ifelse(es_coefs$pval[i] < 0.1, "^{*}", "")))
  if (es_coefs$rel_time[i] == 0 && i > 1) {
    tab4_tex <- c(tab4_tex,
      "2021 H2 (ref.) & 0 & --- & --- \\\\",
      "\\midrule",
      "\\textit{Post-ban} & & & \\\\")
  }
  tab4_tex <- c(tab4_tex,
    sprintf("\\quad %s & $%.3f%s$ & (%.3f) & %.3f \\\\",
      sem, es_coefs$coef[i], stars, es_coefs$se[i], es_coefs$pval[i]))
}

tab4_tex <- c(tab4_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Coefficients from interacting Treated with half-year indicators, ",
  "relative to 2021 H2 (the semester before the ban). Travel insurance excluded. ",
  "Standard errors clustered at the product level. Endpoints are binned ($\\leq$2019 H1, $\\geq$2024 H2). ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_event_study.tex"))

# ==============================================================================
# Table F1: SDE Table (Appendix)
# ==============================================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y_pre) for binary treatment
fca_pref <- fca %>% filter(Product != "Travel")
sd_rate_pre <- sd(fca_pref$complaint_rate[fca_pref$post == 0])
sd_logcomp_pre <- sd(fca_pref$log_complaints[fca_pref$post == 0])

sde_rate <- coef(m_pref)[["treated:post"]] / sd_rate_pre
sde_rate_se <- se(m_pref)[["treated:post"]] / sd_rate_pre
sde_logcomp <- coef(m_pref_log)[["treated:post"]] / sd_logcomp_pre
sde_logcomp_se <- se(m_pref_log)[["treated:post"]] / sd_logcomp_pre

# BoE outcomes
sd_nwp_pre <- sd(boe$log_nwp[boe$post == 0])
sd_lr_pre <- sd(boe$loss_ratio[boe$post == 0])
sde_nwp <- coef(m_nwp)[["treated:post"]] / sd_nwp_pre
sde_nwp_se <- se(m_nwp)[["treated:post"]] / sd_nwp_pre
sde_lr <- coef(m_lr)[["treated:post"]] / sd_lr_pre
sde_lr_se <- se(m_lr)[["treated:post"]] / sd_lr_pre

classify_sde <- function(x) {
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x <= 0.005) return("Null")
  if (x <= 0.05) return("Small positive")
  if (x <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_data <- data.frame(
  Outcome = c("Complaint rate", "Log complaints", "Log net written premium", "Loss ratio"),
  Beta = c(coef(m_pref)[["treated:post"]], coef(m_pref_log)[["treated:post"]],
           coef(m_nwp)[["treated:post"]], coef(m_lr)[["treated:post"]]),
  SE = c(se(m_pref)[["treated:post"]], se(m_pref_log)[["treated:post"]],
         se(m_nwp)[["treated:post"]], se(m_lr)[["treated:post"]]),
  SD_Y = c(sd_rate_pre, sd_logcomp_pre, sd_nwp_pre, sd_lr_pre),
  SDE = c(sde_rate, sde_logcomp, sde_nwp, sde_lr),
  SDE_SE = c(sde_rate_se, sde_logcomp_se, sde_nwp_se, sde_lr_se),
  Classification = c(classify_sde(sde_rate), classify_sde(sde_logcomp),
                     classify_sde(sde_nwp), classify_sde(sde_lr))
)

# Heterogeneous panel: Motor vs Property
fca_motor <- fca_pref %>% filter(Product == "Motor & transport")
fca_prop  <- fca_pref %>% filter(Product == "Property")
sd_motor_pre <- sd(fca_motor$complaint_rate[fca_motor$post == 0])
sd_prop_pre  <- sd(fca_prop$complaint_rate[fca_prop$post == 0])

# Simple pre/post differences for each treated product vs control mean
pre_ctrl_mean <- mean(fca_pref$complaint_rate[fca_pref$treated == 0 & fca_pref$post == 0])
post_ctrl_mean <- mean(fca_pref$complaint_rate[fca_pref$treated == 0 & fca_pref$post == 1])
ctrl_change <- post_ctrl_mean - pre_ctrl_mean

motor_did <- (mean(fca_motor$complaint_rate[fca_motor$post == 1]) -
              mean(fca_motor$complaint_rate[fca_motor$post == 0])) - ctrl_change
prop_did <- (mean(fca_prop$complaint_rate[fca_prop$post == 1]) -
             mean(fca_prop$complaint_rate[fca_prop$post == 0])) - ctrl_change

sde_motor <- motor_did / sd_motor_pre
sde_prop  <- prop_did / sd_prop_pre

het_data <- data.frame(
  Outcome = c("Complaint rate (Motor)", "Complaint rate (Property)"),
  Beta = c(motor_did, prop_did),
  SE = c(NA, NA),
  SD_Y = c(sd_motor_pre, sd_prop_pre),
  SDE = c(sde_motor, sde_prop),
  SDE_SE = c(NA, NA),
  Classification = c(classify_sde(sde_motor), classify_sde(sde_prop))
)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does banning price-walking (loyalty penalties) in motor and home insurance reduce consumer complaints? ",
  "\\textbf{Policy mechanism:} The FCA's General Insurance Pricing Practices reform (PS21/5) prohibits insurers from charging renewal ",
  "customers more than the equivalent new-business price, eliminating the practice of gradually increasing premiums for loyal customers ",
  "who do not shop around. ",
  "\\textbf{Outcome definition:} Complaints opened per 1,000 policies in force, measured half-yearly from FCA Aggregate Complaints Data. ",
  "\\textbf{Treatment:} Binary; motor and home insurance subject to pricing remedy from January 1, 2022; other insurance lines are not. ",
  "\\textbf{Data:} FCA Aggregate Complaints Data (half-yearly, 2016 H2--2025 H1, 6 products $\\times$ 18 semesters = 108 observations, excluding travel) ",
  "and Bank of England Insurance Aggregate Data (quarterly, 2017 Q1--2025 Q3, 6 lines $\\times$ 35 quarters = 210 observations). ",
  "\\textbf{Method:} Two-way fixed effects with product and time fixed effects; standard errors clustered at product level; ",
  "wild cluster bootstrap and randomization inference for few-cluster robustness. ",
  "\\textbf{Sample:} UK-regulated general insurers; all firms reporting to FCA/BoE. Travel insurance excluded due to COVID confounding. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in seq_len(nrow(sde_data))) {
  tabF1_tex <- c(tabF1_tex,
    sprintf("\\quad %s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
      sde_data$Outcome[i], sde_data$Beta[i], sde_data$SE[i], sde_data$SD_Y[i],
      sde_data$SDE[i], sde_data$SDE_SE[i], sde_data$Classification[i]))
}

tabF1_tex <- c(tabF1_tex,
  "\\midrule",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\"
)

for (i in seq_len(nrow(het_data))) {
  se_str <- ifelse(is.na(het_data$SE[i]), "---", sprintf("%.3f", het_data$SE[i]))
  sde_se_str <- ifelse(is.na(het_data$SDE_SE[i]), "---", sprintf("%.3f", het_data$SDE_SE[i]))
  tabF1_tex <- c(tabF1_tex,
    sprintf("\\quad %s & %.3f & %s & %.3f & %.3f & %s & %s \\\\",
      het_data$Outcome[i], het_data$Beta[i], se_str, het_data$SD_Y[i],
      het_data$SDE[i], sde_se_str, het_data$Classification[i]))
}

tabF1_tex <- c(tabF1_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("=== All tables written ===\n")
