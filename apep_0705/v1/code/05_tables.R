## 05_tables.R — Generate all tables for the paper
## APEP-0705: Sweden's RUT Household Services Deduction

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"

## Load results
results    <- readRDS(file.path(data_dir, "main_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel      <- readRDS(file.path(data_dir, "panel_income.rds")) %>%
  filter(!is.na(mean_income), mean_income > 0)
treatment  <- readRDS(file.path(data_dir, "treatment_intensity.rds"))
emp_panel  <- readRDS(file.path(data_dir, "panel_employment.rds"))
emprate    <- readRDS(file.path(data_dir, "panel_emprate.rds"))

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================
cat("Generating Table 1: Summary Statistics\n")

mn_label <- unique(emp_panel$sector)[grepl("professional", unique(emp_panel$sector))]
mfg_label <- unique(emp_panel$sector)[grepl("mining", unique(emp_panel$sector))]

# Compute summary stats
sumstats <- tribble(
  ~Variable, ~Mean, ~SD, ~Min, ~Max, ~N,
  "Mean earned income (SEK 000s)",
    round(mean(panel$mean_income, na.rm=TRUE), 1),
    round(sd(panel$mean_income, na.rm=TRUE), 1),
    round(min(panel$mean_income, na.rm=TRUE), 1),
    round(max(panel$mean_income, na.rm=TRUE), 1),
    sum(!is.na(panel$mean_income)),
  "Treatment intensity (2006 mean income, SEK 000s)",
    round(mean(treatment$mean_income_2006), 1),
    round(sd(treatment$mean_income_2006), 1),
    round(min(treatment$mean_income_2006), 1),
    round(max(treatment$mean_income_2006), 1),
    nrow(treatment),
  "M+N employment (persons)",
    round(mean(emp_panel$emp[emp_panel$sector == mn_label], na.rm=TRUE), 0),
    round(sd(emp_panel$emp[emp_panel$sector == mn_label], na.rm=TRUE), 0),
    round(min(emp_panel$emp[emp_panel$sector == mn_label], na.rm=TRUE), 0),
    round(max(emp_panel$emp[emp_panel$sector == mn_label], na.rm=TRUE), 0),
    sum(!is.na(emp_panel$emp[emp_panel$sector == mn_label])),
  "Manufacturing employment (persons)",
    round(mean(emp_panel$emp[emp_panel$sector == mfg_label], na.rm=TRUE), 0),
    round(sd(emp_panel$emp[emp_panel$sector == mfg_label], na.rm=TRUE), 0),
    round(min(emp_panel$emp[emp_panel$sector == mfg_label], na.rm=TRUE), 0),
    round(max(emp_panel$emp[emp_panel$sector == mfg_label], na.rm=TRUE), 0),
    sum(!is.na(emp_panel$emp[emp_panel$sector == mfg_label])),
  "Employment rate, native-born (\\%)",
    round(mean(emprate$emp_rate[emprate$foreign_born == 0], na.rm=TRUE), 1),
    round(sd(emprate$emp_rate[emprate$foreign_born == 0], na.rm=TRUE), 1),
    round(min(emprate$emp_rate[emprate$foreign_born == 0], na.rm=TRUE), 1),
    round(max(emprate$emp_rate[emprate$foreign_born == 0], na.rm=TRUE), 1),
    sum(!is.na(emprate$emp_rate[emprate$foreign_born == 0])),
  "Employment rate, foreign-born (\\%)",
    round(mean(emprate$emp_rate[emprate$foreign_born == 1], na.rm=TRUE), 1),
    round(sd(emprate$emp_rate[emprate$foreign_born == 1], na.rm=TRUE), 1),
    round(min(emprate$emp_rate[emprate$foreign_born == 1], na.rm=TRUE), 1),
    round(max(emprate$emp_rate[emprate$foreign_born == 1], na.rm=TRUE), 1),
    sum(!is.na(emprate$emp_rate[emprate$foreign_born == 1]))
)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\hline\n",
  paste(apply(sumstats, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\\footnotesize\n",
  "\\textit{Notes:} Income data cover 290 Swedish municipalities, 1999--2024 (7,540 obs). ",
  "Treatment intensity is the mean earned income of persons aged 20--64 in each municipality in 2006, ",
  "the last pre-reform year. Employment data cover 2008--2018 (RAMS). ",
  "Employment rates cover 2004--2018 for persons aged 20--64.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_sumstats.tex"))

## ============================================================
## TABLE 2: Main Results — Income DiD
## ============================================================
cat("Generating Table 2: Main DiD Results\n")

# Build table manually for maximum control
fmt_coef <- function(x) formatC(x, format = "f", digits = 4)
fmt_se <- function(x) paste0("(", formatC(x, format = "f", digits = 4), ")")
fmt_star <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

# Extract results
m1 <- results$did_aggregate
m2 <- results$did_early_late
m3 <- robustness$trends
m4 <- robustness$no_stockholm

get_row <- function(mod, varname) {
  ct <- coeftable(mod)
  idx <- grep(varname, rownames(ct), fixed = TRUE)
  if (length(idx) == 0) return(c("", ""))
  b <- ct[idx[1], "Estimate"]
  se <- ct[idx[1], "Std. Error"]
  p <- ct[idx[1], "Pr(>|t|)"]
  c(paste0(fmt_coef(b), fmt_star(p)), fmt_se(se))
}

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of RUT Treatment Intensity on Log Mean Earned Income}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & Early/Late & Linear Trends & Excl.\\ Stockholm \\\\\n",
  "\\hline\n",
  "Treat.\\ Intens.\\ $\\times$ Post & ", get_row(m1, "treat_x_post")[1],
  " & & ", get_row(m3, "treat_x_post")[1],
  " & ", get_row(m4, "treat_x_post")[1], " \\\\\n",
  " & ", get_row(m1, "treat_x_post")[2],
  " & & ", get_row(m3, "treat_x_post")[2],
  " & ", get_row(m4, "treat_x_post")[2], " \\\\\n",
  "Treat.\\ Intens.\\ $\\times$ Early & & ", get_row(m2, "treat_x_early")[1], " & & \\\\\n",
  " & & ", get_row(m2, "treat_x_early")[2], " & & \\\\\n",
  "Treat.\\ Intens.\\ $\\times$ Late & & ", get_row(m2, "treat_x_late")[1], " & & \\\\\n",
  " & & ", get_row(m2, "treat_x_late")[2], " & & \\\\\n",
  "\\hline\n",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Muni.\\ linear trends & No & No & Yes & No \\\\\n",
  "N & ", format(nobs(m1), big.mark = ","), " & ",
  format(nobs(m2), big.mark = ","), " & ",
  format(nobs(m3), big.mark = ","), " & ",
  format(nobs(m4), big.mark = ","), " \\\\\n",
  "Municipalities & 290 & 290 & 290 & 264 \\\\\n",
  "RI $p$-value & ", round(robustness$ri_pvalue, 3), " & & & \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\\footnotesize\n",
  "\\textit{Notes:} The dependent variable is log mean earned income (ages 20--64) at the municipality-year level. ",
  "Treatment intensity is the standardized (mean zero, unit variance) 2006 mean income. ",
  "Post equals one from 2007 onward. Early covers 2007--2012; Late covers 2013--2024. ",
  "Column (3) includes municipality-specific linear time trends. ",
  "Column (4) excludes Stockholm county (26 municipalities). ",
  "Standard errors clustered at the municipality level in parentheses. ",
  "RI $p$-value from Fisher randomization inference (999 permutations). ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))

## ============================================================
## TABLE 3: Sector Employment
## ============================================================
cat("Generating Table 3: Sector Employment Results\n")

mn_data <- emp_panel %>% filter(sector == mn_label, emp > 0) %>%
  mutate(post_2012 = as.integer(year >= 2012))
mfg_data <- emp_panel %>% filter(sector == mfg_label, emp > 0) %>%
  mutate(post_2012 = as.integer(year >= 2012))
hotel_label <- unique(emp_panel$sector)[grepl("hotels", unique(emp_panel$sector))]
hotel_data <- emp_panel %>% filter(sector == hotel_label, emp > 0) %>%
  mutate(post_2012 = as.integer(year >= 2012))

s_mn  <- feols(log_emp ~ treat_intensity:post_2012 | region + year, data = mn_data, cluster = ~region)
s_mfg <- feols(log_emp ~ treat_intensity:post_2012 | region + year, data = mfg_data, cluster = ~region)
s_hot <- feols(log_emp ~ treat_intensity:post_2012 | region + year, data = hotel_data, cluster = ~region)

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Sector Employment Responses to Treatment Intensity}\n",
  "\\label{tab:sectors}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Services (M+N) & Manufacturing (B+C) & Hospitality (I) \\\\\n",
  "\\hline\n",
  "Treat.\\ Intens.\\ $\\times$ Post-2012 & ",
  get_row(s_mn, "treat_intensity")[1], " & ",
  get_row(s_mfg, "treat_intensity")[1], " & ",
  get_row(s_hot, "treat_intensity")[1], " \\\\\n",
  " & ",
  get_row(s_mn, "treat_intensity")[2], " & ",
  get_row(s_mfg, "treat_intensity")[2], " & ",
  get_row(s_hot, "treat_intensity")[2], " \\\\\n",
  "\\hline\n",
  "Municipality FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "N & ", format(nobs(s_mn), big.mark=","), " & ",
  format(nobs(s_mfg), big.mark=","), " & ",
  format(nobs(s_hot), big.mark=","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\\footnotesize\n",
  "\\textit{Notes:} Dependent variable is log employment by sector at the municipality-year level (2008--2018). ",
  "Services (M+N) includes professional, scientific, technical, administrative, and support services (NACE Rev.\\ 2 sections M--N). ",
  "Manufacturing includes mining, quarrying, and manufacturing (NACE B--C). ",
  "Hospitality includes hotels and restaurants (NACE I). ",
  "Post-2012 equals one for 2012--2018 to capture medium-run effects. ",
  "Standard errors clustered at the municipality level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_sectors.tex"))

## ============================================================
## TABLE 4: Immigration Channel
## ============================================================
cat("Generating Table 4: Immigration and Gender Mechanisms\n")

imm <- results$immigration
gen <- results$gender

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Mechanism Tests: Immigration and Gender Channels}\n",
  "\\label{tab:mechanisms}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) \\\\\n",
  " & Employment Rate & Log M+N Employment \\\\\n",
  " & (Immigration DDD) & (Gender Interaction) \\\\\n",
  "\\hline\n",
  "Treat.\\ $\\times$ Post $\\times$ Foreign-born & ",
  get_row(imm, "treat_x_post_x_fb")[1], " & \\\\\n",
  " & ", get_row(imm, "treat_x_post_x_fb")[2], " & \\\\\n",
  "Treat.\\ $\\times$ Post & ",
  get_row(imm, "treat_x_post")[1], " & \\\\\n",
  " & ", get_row(imm, "treat_x_post")[2], " & \\\\\n",
  "Treat.\\ Intens.\\ $\\times$ Female & & ",
  get_row(gen, "treat_intensity:female")[1], " \\\\\n",
  " & & ", get_row(gen, "treat_intensity:female")[2], " \\\\\n",
  "\\hline\n",
  "Municipality FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "N & ", format(nobs(imm), big.mark=","), " & ",
  format(nobs(gen), big.mark=","), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\\footnotesize\n",
  "\\textit{Notes:} Column (1) reports a triple-difference of employment rates (ages 20--64) on treatment intensity $\\times$ post-reform $\\times$ foreign-born status, 2004--2018. ",
  "Column (2) reports the differential effect of treatment intensity on female vs.\\ male M+N sector employment, 2008--2018. ",
  "Standard errors clustered at the municipality level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_mechanisms.tex"))

## ============================================================
## TABLE F1: Standardized Effect Sizes (SDE)
## ============================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Main coefficients and SDs
inc_beta <- coef(results$did_aggregate)["treat_x_post"]
inc_se <- se(results$did_aggregate)["treat_x_post"]
inc_sd_y <- sd(panel$log_mean_income, na.rm = TRUE)
inc_sd_x <- 1  # Already standardized
inc_sde <- inc_beta * inc_sd_x / inc_sd_y
inc_sde_se <- inc_se * inc_sd_x / inc_sd_y

# Trends-adjusted
tr_beta <- coef(robustness$trends)["treat_x_post"]
tr_se <- se(robustness$trends)["treat_x_post"]
tr_sde <- tr_beta * inc_sd_x / inc_sd_y
tr_sde_se <- tr_se * inc_sd_x / inc_sd_y

# M+N employment
mn_d <- emp_panel %>% filter(sector == mn_label, emp > 0) %>%
  mutate(post_2012 = as.integer(year >= 2012))
mn_mod <- feols(log_emp ~ treat_intensity:post_2012 | region + year,
                data = mn_d, cluster = ~region)
mn_beta <- coef(mn_mod)
mn_se_val <- se(mn_mod)
mn_sd_y <- sd(mn_d$log_emp, na.rm = TRUE)
mn_sde <- mn_beta / mn_sd_y
mn_sde_se <- mn_se_val / mn_sd_y

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  sign <- ifelse(sde >= 0, "positive", "negative")
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(paste0("Small ", sign))
  if (abs_sde < 0.15) return(paste0("Moderate ", sign))
  return(paste0("Large ", sign))
}

sde_rows <- tribble(
  ~Outcome, ~Beta, ~SE, ~SD_Y, ~SDE, ~SDE_SE, ~Classification,
  "Log mean income (baseline)",
    round(inc_beta, 4), round(inc_se, 4), round(inc_sd_y, 3),
    round(inc_sde, 4), round(inc_sde_se, 4), classify_sde(inc_sde),
  "Log mean income (with trends)",
    round(tr_beta, 4), round(tr_se, 4), round(inc_sd_y, 3),
    round(tr_sde, 4), round(tr_sde_se, 4), classify_sde(tr_sde),
  "Log M+N employment (post-2012)",
    round(mn_beta, 4), round(mn_se_val, 4), round(mn_sd_y, 3),
    round(mn_sde, 4), round(mn_sde_se, 4), classify_sde(mn_sde)
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste(apply(sde_rows, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\\footnotesize\n",
  "\\textit{Notes:} SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
  "Treatment intensity is standardized (SD = 1) so SDE = $\\hat{\\beta} / \\text{SD}(Y)$. ",
  "Classification based on SDE magnitude: Null ($|\\text{SDE}| < 0.005$), ",
  "Small ($0.005$--$0.05$), Moderate ($0.05$--$0.15$), Large ($> 0.15$). ",
  "Classification refers to effect magnitude, not statistical significance. ",
  "Research question: did Sweden's 2007 RUT household services tax deduction increase formal-sector income and employment ",
  "in municipalities with higher pre-reform demand? Data: SCB municipality-year panels. Method: continuous-treatment DiD. ",
  "Sample: 290 municipalities, 1999--2024 (income) and 2008--2018 (employment). Treatment: standardized 2006 mean income.\n",
  "\\end{minipage}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Tables saved in", table_dir, "\n")
