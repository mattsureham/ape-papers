# 05_tables.R — Generate all LaTeX tables
# APEP-1441: Swiss cantonal minimum wages

source("00_packages.R")

panel <- read_csv("../data/panel.csv", show_col_types = FALSE)
udemo <- read_csv("../data/udemo_panel.csv", show_col_types = FALSE)
results <- readRDS("../data/results.rds")
rob_results <- readRDS("../data/robustness.rds")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

# High-bite sectors, pre-treatment (2011-2016)
high_bite_pre <- panel %>%
  filter(high_bite, year <= 2016) %>%
  group_by(canton, year, treated_canton) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE),
    establishments = sum(establishments, na.rm = TRUE),
    fte = sum(fte, na.rm = TRUE),
    .groups = "drop"
  )

# Summary by treated/control
make_summ <- function(df, var) {
  df %>%
    group_by(treated_canton) %>%
    summarise(
      mean = mean(.data[[var]], na.rm = TRUE),
      sd = sd(.data[[var]], na.rm = TRUE),
      .groups = "drop"
    )
}

vars <- c("employment", "establishments", "fte")
var_labels <- c("Employment (high-bite sectors)", "Establishments (high-bite sectors)",
                "Full-time equivalents (high-bite sectors)")

# Total employment pre-treatment
total_pre <- panel %>%
  filter(noga == "total", year <= 2016)

summ_rows <- list()
for (i in seq_along(vars)) {
  s <- make_summ(high_bite_pre, vars[i])
  summ_rows[[i]] <- data.frame(
    Variable = var_labels[i],
    Treated_Mean = round(s$mean[s$treated_canton == TRUE], 0),
    Treated_SD = round(s$sd[s$treated_canton == TRUE], 0),
    Control_Mean = round(s$mean[s$treated_canton == FALSE], 0),
    Control_SD = round(s$sd[s$treated_canton == FALSE], 0)
  )
}

# Add total employment
s_total <- make_summ(total_pre, "employment")
summ_rows[[4]] <- data.frame(
  Variable = "Total employment (all sectors)",
  Treated_Mean = round(s_total$mean[s_total$treated_canton == TRUE], 0),
  Treated_SD = round(s_total$sd[s_total$treated_canton == TRUE], 0),
  Control_Mean = round(s_total$mean[s_total$treated_canton == FALSE], 0),
  Control_SD = round(s_total$sd[s_total$treated_canton == FALSE], 0)
)

# UDEMO: firm births pre-treatment
udemo_pre <- udemo %>% filter(year <= 2016)
s_births <- make_summ(udemo_pre, "births")
summ_rows[[5]] <- data.frame(
  Variable = "Firm births (annual)",
  Treated_Mean = round(s_births$mean[s_births$treated_canton == TRUE], 0),
  Treated_SD = round(s_births$sd[s_births$treated_canton == TRUE], 0),
  Control_Mean = round(s_births$mean[s_births$treated_canton == FALSE], 0),
  Control_SD = round(s_births$sd[s_births$treated_canton == FALSE], 0)
)

summ_df <- do.call(rbind, summ_rows)

# Write LaTeX
n_treated <- 5
n_control <- 21

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Means (2011--2016)}\n",
  "\\label{tab:summ}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated ($N=", n_treated, "$)} & \\multicolumn{2}{c}{Control ($N=", n_control, "$)} \\\\\n",
  "\\cline{2-3} \\cline{4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(summ_df)) {
  tab1 <- paste0(tab1,
    summ_df$Variable[i], " & ",
    format(summ_df$Treated_Mean[i], big.mark = ","), " & ",
    format(summ_df$Treated_SD[i], big.mark = ","), " & ",
    format(summ_df$Control_Mean[i], big.mark = ","), " & ",
    format(summ_df$Control_SD[i], big.mark = ","), " \\\\\n")
}

tab1 <- paste0(tab1,
  "\\hline\n",
  "\\multicolumn{5}{l}{\\footnotesize \\textit{Notes:} Treated cantons: Neuch\\^{a}tel (2017), Jura (2018), Geneva (2020),} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize Ticino (2021), Basel-Stadt (2022). High-bite sectors: retail (NOGA 47),} \\\\\n",
  "\\multicolumn{5}{l}{\\footnotesize accommodation (55), food/beverage (56), building services (81). Source: BFS STATENT.} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: Main Results — Callaway & Sant'Anna
# ============================================================================
cat("Generating Table 2: Main Results\n")

# Extract results
get_att <- function(agg) {
  list(att = agg$overall.att, se = agg$overall.se,
       stars = ifelse(abs(agg$overall.att/agg$overall.se) > 2.576, "***",
                      ifelse(abs(agg$overall.att/agg$overall.se) > 1.96, "**",
                             ifelse(abs(agg$overall.att/agg$overall.se) > 1.645, "*", ""))))
}

r_emp <- get_att(results$agg_emp)
r_est <- get_att(results$agg_est)
r_fte <- get_att(results$agg_fte)
r_total <- get_att(results$agg_total)
r_births <- get_att(results$agg_births)

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Cantonal Minimum Wages: Callaway--Sant'Anna Estimates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{High-Bite Sectors} & All Sectors \\\\\n",
  "\\cline{2-3}\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Log Empl. & Log Estab. & Log Empl. \\\\\n",
  "\\hline\n",
  "\\textit{Panel A: Employment \\& Establishments} & & & \\\\\n",
  "\\\\[6pt]\n",
  "ATT & ", sprintf("%.4f%s", r_emp$att, r_emp$stars), " & ",
  sprintf("%.4f%s", r_est$att, r_est$stars), " & ",
  sprintf("%.4f%s", r_total$att, r_total$stars), " \\\\\n",
  " & (", sprintf("%.4f", r_emp$se), ") & (",
  sprintf("%.4f", r_est$se), ") & (",
  sprintf("%.4f", r_total$se), ") \\\\\n",
  "\\\\[6pt]\n",
  " & (4) & (5) & \\\\\n",
  " & Log FTE & Log Births & \\\\\n",
  "\\hline\n",
  "\\textit{Panel B: Intensive Margin \\& Firm Entry} & & & \\\\\n",
  "\\\\[6pt]\n",
  "ATT & ", sprintf("%.4f%s", r_fte$att, r_fte$stars), " & ",
  sprintf("%.4f%s", r_births$att, r_births$stars), " & \\\\\n",
  " & (", sprintf("%.4f", r_fte$se), ") & (",
  sprintf("%.4f", r_births$se), ") & \\\\\n",
  "\\\\[6pt]\n",
  "\\hline\n",
  "Estimator & \\multicolumn{3}{c}{Callaway \\& Sant'Anna (2021)} \\\\\n",
  "Control group & \\multicolumn{3}{c}{Never-treated cantons ($N=21$)} \\\\\n",
  "Treated cantons & \\multicolumn{3}{c}{5 (staggered adoption 2017--2022)} \\\\\n",
  "Years & \\multicolumn{3}{c}{2011--2023} \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{4}{l}{\\footnotesize \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Standard errors in parentheses,} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize computed using the multiplier bootstrap (999 draws). High-bite sectors: retail (47),} \\\\\n",
  "\\multicolumn{4}{l}{\\footnotesize accommodation (55), food/beverage (56), building services (81). Source: BFS STATENT/UDEMO.} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Robustness
# ============================================================================
cat("Generating Table 3: Robustness\n")

# Placebo
r_placebo <- get_att(rob_results$placebo$agg)
# No-COVID
r_nocovid <- get_att(rob_results$nocovid$agg)
# TWFE
twfe_coef <- coef(results$twfe_emp)
twfe_se <- summary(results$twfe_emp)$coeftable[1, 2]
twfe_stars <- ifelse(abs(twfe_coef/twfe_se) > 2.576, "***",
                     ifelse(abs(twfe_coef/twfe_se) > 1.96, "**",
                            ifelse(abs(twfe_coef/twfe_se) > 1.645, "*", "")))
# Sun-Abraham
sa_coef <- summary(results$sa_emp)$coeftable[1, 1]
sa_se <- summary(results$sa_emp)$coeftable[1, 2]
sa_stars <- ifelse(abs(sa_coef/sa_se) > 2.576, "***",
                   ifelse(abs(sa_coef/sa_se) > 1.96, "**",
                          ifelse(abs(sa_coef/sa_se) > 1.645, "*", "")))

# By sector
sector_rows <- ""
for (sec_name in names(rob_results$by_sector)) {
  sec_res <- rob_results$by_sector[[sec_name]]
  r <- get_att(sec_res$agg)
  label <- gsub("_", " ", gsub("^[0-9]+_", "", sec_name))
  label <- paste0(toupper(substr(label, 1, 1)), substr(label, 2, nchar(label)))
  sector_rows <- paste0(sector_rows,
    "\\quad ", label, " & ", sprintf("%.4f%s", r$att, r$stars),
    " & (", sprintf("%.4f", r$se), ") \\\\\n")
}

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & ATT & SE \\\\\n",
  "\\hline\n",
  "\\textit{Panel A: Alternative estimators} & & \\\\\n",
  "\\quad Callaway--Sant'Anna (baseline) & ", sprintf("%.4f%s", r_emp$att, r_emp$stars),
  " & (", sprintf("%.4f", r_emp$se), ") \\\\\n",
  "\\quad Sun--Abraham & ", sprintf("%.4f%s", sa_coef, sa_stars),
  " & (", sprintf("%.4f", sa_se), ") \\\\\n",
  "\\quad TWFE & ", sprintf("%.4f%s", twfe_coef, twfe_stars),
  " & (", sprintf("%.4f", twfe_se), ") \\\\\n",
  "\\\\[6pt]\n",
  "\\textit{Panel B: Specification checks} & & \\\\\n",
  "\\quad Placebo (low-bite sectors) & ", sprintf("%.4f%s", r_placebo$att, r_placebo$stars),
  " & (", sprintf("%.4f", r_placebo$se), ") \\\\\n",
  "\\quad Excluding COVID years & ", sprintf("%.4f%s", r_nocovid$att, r_nocovid$stars),
  " & (", sprintf("%.4f", r_nocovid$se), ") \\\\\n",
  "\\\\[6pt]\n",
  "\\textit{Panel C: By sector} & & \\\\\n",
  sector_rows,
  "\\hline\\hline\n",
  "\\multicolumn{3}{l}{\\footnotesize \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Dependent variable: log employment.} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize All specifications use never-treated cantons as control group. TWFE standard errors} \\\\\n",
  "\\multicolumn{3}{l}{\\footnotesize clustered at canton level. Source: BFS STATENT (2011--2023).} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robust.tex")

# ============================================================================
# Table 4: Triple-Difference
# ============================================================================
cat("Generating Table 4: Triple-Difference\n")

ddd <- results$ddd_emp
ddd_coef <- coef(ddd)["ddd"]
ddd_se <- summary(ddd)$coeftable["ddd", 2]
ddd_stars <- ifelse(abs(ddd_coef/ddd_se) > 2.576, "***",
                    ifelse(abs(ddd_coef/ddd_se) > 1.96, "**",
                           ifelse(abs(ddd_coef/ddd_se) > 1.645, "*", "")))

# Get other DDD coefficients
ddd_ct <- summary(ddd)$coeftable

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Triple-Difference: High-Bite vs.\\ Low-Bite Sectors}\n",
  "\\label{tab:ddd}\n",
  "\\begin{tabular}{lc}\n",
  "\\hline\\hline\n",
  " & Log Employment \\\\\n",
  "\\hline\n",
  "Treated $\\times$ Post $\\times$ High-Bite & ", sprintf("%.4f%s", ddd_coef, ddd_stars), " \\\\\n",
  " & (", sprintf("%.4f", ddd_se), ") \\\\\n",
  "\\\\[6pt]\n",
  "\\hline\n",
  "Canton FE & Yes \\\\\n",
  "Year FE & Yes \\\\\n",
  "Sector type FE & Yes \\\\\n",
  "Observations & ", format(nobs(ddd), big.mark = ","), " \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{2}{l}{\\footnotesize \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Standard errors clustered} \\\\\n",
  "\\multicolumn{2}{l}{\\footnotesize at canton level. High-bite sectors: retail (47), accommodation (55), food/beverage (56),} \\\\\n",
  "\\multicolumn{2}{l}{\\footnotesize building services (81). Low-bite sectors: pharma (21), IT (62), financial services (64).} \\\\\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_ddd.tex")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================
cat("Generating Table F1: SDE\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y) where SD(Y) is pre-treatment SD

high_bite_all <- panel %>%
  filter(high_bite) %>%
  group_by(canton, year, treated_canton, first_treat) %>%
  summarise(employment = sum(employment, na.rm = TRUE),
            establishments = sum(establishments, na.rm = TRUE),
            fte = sum(fte, na.rm = TRUE), .groups = "drop") %>%
  mutate(log_emp = log(employment + 1),
         log_est = log(establishments + 1),
         log_fte = log(fte + 1))

# Pre-treatment SD (before any treatment, i.e., before 2017)
pre_data <- high_bite_all %>% filter(year < 2017)
sd_log_emp <- sd(pre_data$log_emp, na.rm = TRUE)
sd_log_est <- sd(pre_data$log_est, na.rm = TRUE)
sd_log_fte <- sd(pre_data$log_fte, na.rm = TRUE)

# Total employment
total_pre <- panel %>% filter(noga == "total", year < 2017)
sd_log_total <- sd(log(total_pre$employment + 1), na.rm = TRUE)

# Firm births
udemo_pre <- udemo %>% filter(year < 2017)
sd_log_births <- sd(udemo$log_births, na.rm = TRUE)

# SDE calculations (binary treatment: SDE = beta / SD(Y))
sde_data <- tibble(
  outcome = c("Employment (high-bite)", "Establishments (high-bite)",
              "FTE (high-bite)", "Employment (all sectors)", "Firm births"),
  beta = c(results$agg_emp$overall.att, results$agg_est$overall.att,
           results$agg_fte$overall.att, results$agg_total$overall.att,
           results$agg_births$overall.att),
  se = c(results$agg_emp$overall.se, results$agg_est$overall.se,
         results$agg_fte$overall.se, results$agg_total$overall.se,
         results$agg_births$overall.se),
  sd_y = c(sd_log_emp, sd_log_est, sd_log_fte, sd_log_total, sd_log_births)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Panel B: Heterogeneity (sample splits)
# Split by whether canton adopted pre-COVID vs during/post-COVID
pre_covid_cantons <- c("NE", "JU")  # 2017-2018
covid_cantons <- c("GE", "TI", "BS")  # 2020-2022

het_pre_covid <- high_bite_all %>%
  filter(canton %in% c(pre_covid_cantons, setdiff(unique(high_bite_all$canton), c("GE", "TI", "BS")))) %>%
  mutate(canton_id = as.integer(factor(canton)),
         first_treat_adj = ifelse(canton %in% pre_covid_cantons, first_treat, 0))

het_covid <- high_bite_all %>%
  filter(canton %in% c(covid_cantons, setdiff(unique(high_bite_all$canton), c("NE", "JU")))) %>%
  mutate(canton_id = as.integer(factor(canton)),
         first_treat_adj = ifelse(canton %in% covid_cantons, first_treat, 0))

cs_pre_covid <- tryCatch(
  att_gt(yname = "log_emp", tname = "year", idname = "canton_id",
         gname = "first_treat_adj", data = het_pre_covid,
         control_group = "nevertreated", base_period = "universal"),
  error = function(e) NULL
)

cs_covid <- tryCatch(
  att_gt(yname = "log_emp", tname = "year", idname = "canton_id",
         gname = "first_treat_adj", data = het_covid,
         control_group = "nevertreated", base_period = "universal"),
  error = function(e) NULL
)

het_rows <- tibble(
  outcome = character(), beta = numeric(), se = numeric(),
  sd_y = numeric(), sde = numeric(), se_sde = numeric(),
  classification = character()
)

if (!is.null(cs_pre_covid)) {
  agg_pre <- aggte(cs_pre_covid, type = "simple")
  het_rows <- bind_rows(het_rows, tibble(
    outcome = "Employment: pre-COVID adopters",
    beta = agg_pre$overall.att, se = agg_pre$overall.se,
    sd_y = sd_log_emp, sde = agg_pre$overall.att / sd_log_emp,
    se_sde = agg_pre$overall.se / sd_log_emp,
    classification = case_when(
      agg_pre$overall.att / sd_log_emp < -0.15 ~ "Large negative",
      agg_pre$overall.att / sd_log_emp < -0.05 ~ "Moderate negative",
      agg_pre$overall.att / sd_log_emp < -0.005 ~ "Small negative",
      agg_pre$overall.att / sd_log_emp <= 0.005 ~ "Null",
      agg_pre$overall.att / sd_log_emp <= 0.05 ~ "Small positive",
      agg_pre$overall.att / sd_log_emp <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  ))
}

if (!is.null(cs_covid)) {
  agg_cov <- aggte(cs_covid, type = "simple")
  het_rows <- bind_rows(het_rows, tibble(
    outcome = "Employment: COVID-era adopters",
    beta = agg_cov$overall.att, se = agg_cov$overall.se,
    sd_y = sd_log_emp, sde = agg_cov$overall.att / sd_log_emp,
    se_sde = agg_cov$overall.se / sd_log_emp,
    classification = case_when(
      agg_cov$overall.att / sd_log_emp < -0.15 ~ "Large negative",
      agg_cov$overall.att / sd_log_emp < -0.05 ~ "Moderate negative",
      agg_cov$overall.att / sd_log_emp < -0.005 ~ "Small negative",
      agg_cov$overall.att / sd_log_emp <= 0.005 ~ "Null",
      agg_cov$overall.att / sd_log_emp <= 0.05 ~ "Small positive",
      agg_cov$overall.att / sd_log_emp <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  ))
}

# Build SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Do the world's highest cantonal minimum wages (CHF 19--24/hr) reduce employment in low-wage sectors? ",
  "\\textbf{Policy mechanism:} Five Swiss cantons adopted cantonal minimum wages via popular referendum between 2017 and 2022, imposing binding wage floors on employers in sectors with substantial shares of workers earning below the new minimum. ",
  "\\textbf{Outcome definition:} Log employment (total headcount) in high-bite sectors (retail, accommodation, food/beverage, building services) from BFS STATENT administrative data. ",
  "\\textbf{Treatment:} Binary; canton-year indicator equal to one in the first full year a cantonal minimum wage is in force. ",
  "\\textbf{Data:} BFS STATENT (2011--2023), 26 cantons $\\times$ 13 years $\\times$ 4 high-bite NOGA divisions; 26 canton-year observations per year. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated control group and multiplier bootstrap inference. ",
  "\\textbf{Sample:} 26 Swiss cantons; 5 treated, 21 never-treated controls. Restricted to NOGA 2-digit sectors with substantial low-wage employment. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\textit{Panel A: Pooled} & & & & & & \\\\\n"
)

for (i in 1:nrow(sde_data)) {
  tabF1 <- paste0(tabF1,
    sde_data$outcome[i], " & ",
    sprintf("%.4f", sde_data$beta[i]), " & ",
    sprintf("%.4f", sde_data$se[i]), " & ",
    sprintf("%.4f", sde_data$sd_y[i]), " & ",
    sprintf("%.4f", sde_data$sde[i]), " & ",
    sprintf("%.4f", sde_data$se_sde[i]), " & ",
    sde_data$classification[i], " \\\\\n")
}

tabF1 <- paste0(tabF1, "[6pt]\n\\textit{Panel B: Heterogeneous} & & & & & & \\\\\n")

for (i in 1:nrow(het_rows)) {
  tabF1 <- paste0(tabF1,
    het_rows$outcome[i], " & ",
    sprintf("%.4f", het_rows$beta[i]), " & ",
    sprintf("%.4f", het_rows$se[i]), " & ",
    sprintf("%.4f", het_rows$sd_y[i]), " & ",
    sprintf("%.4f", het_rows$sde[i]), " & ",
    sprintf("%.4f", het_rows$se_sde[i]), " & ",
    het_rows$classification[i], " \\\\\n")
}

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n",
  "\\begin{minipage}{\\textwidth}\n",
  "\\begin{enumerate}[label={},leftmargin=0pt]\n",
  sde_notes, "\n",
  "\\end{enumerate}\n",
  "\\end{minipage}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("Files:\n")
list.files("../tables/", pattern = "\\.tex$")
