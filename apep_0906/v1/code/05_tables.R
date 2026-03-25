## 05_tables.R — Generate all tables including SDE appendix
## apep_0906: Panama Canal Expansion and Port Labor Markets

library(tidyverse)
library(fixest)
library(modelsummary)
library(kableExtra)

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE)

load(file.path(data_dir, "models.RData"))
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
diagnostics <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

# Load robustness if available
rob_exists <- file.exists(file.path(data_dir, "robustness_models.RData"))
if (rob_exists) load(file.path(data_dir, "robustness_models.RData"))
placebo_exists <- file.exists(file.path(data_dir, "robustness_placebo.RData"))
if (placebo_exists) load(file.path(data_dir, "robustness_placebo.RData"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

transport <- panel %>% filter(industry == "48-49", Emp > 0)

summ_stats <- transport %>%
  group_by(Region = ifelse(treated == 1, "East/Gulf Coast", "West Coast"),
           Period = ifelse(post == 0, "Pre-expansion", "Post-expansion")) %>%
  summarise(
    Counties = n_distinct(county_id),
    `Mean Emp` = round(mean(Emp, na.rm = TRUE)),
    `SD Emp` = round(sd(Emp, na.rm = TRUE)),
    `Mean Earnings` = round(mean(EarnBeg, na.rm = TRUE)),
    `Mean Hires` = round(mean(HirN, na.rm = TRUE)),
    Observations = n(),
    .groups = "drop"
  )

# LaTeX table
tab1_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Transport and Warehousing Employment}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\hline\\hline\n",
  "Region & Period & Counties & Mean Emp & SD Emp & Mean Earnings & Obs \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i, ]
  tab1_latex <- paste0(tab1_latex,
    row$Region, " & ", row$Period, " & ",
    row$Counties, " & ",
    format(row$`Mean Emp`, big.mark = ","), " & ",
    format(row$`SD Emp`, big.mark = ","), " & ",
    format(row$`Mean Earnings`, big.mark = ","), " & ",
    format(row$Observations, big.mark = ","), " \\\\\n"
  )
}

tab1_latex <- paste0(tab1_latex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Data from Census QWI, NAICS 48--49 (Transportation and Warehousing). ",
  "Pre-expansion: 2010 Q1 -- 2016 Q2. Post-expansion: 2016 Q3 -- 2023 Q4. ",
  "Employment is beginning-of-quarter count. Earnings are average beginning-of-quarter earnings. ",
  "East/Gulf Coast ports gained Neo-Panamax vessel access after June 2016 canal expansion.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_latex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================

# Model dictionary for clean labels
cm <- c("treated:post" = "East/Gulf $\\times$ Post",
        "intensity:post" = "Intensity $\\times$ Post")

tab2 <- etable(m1, m2, m4, m5, m6,
               dict = cm,
               se.below = TRUE,
               digits = 4,
               fitstat = ~ n + r2 + wr2,
               headers = c("log(Emp)", "log(Emp)", "log(Emp)", "log(Hires)", "log(Earn)"),
               notes = paste0("Notes: All models include county and quarter FEs. ",
                              "Standard errors clustered at county level in parentheses. ",
                              "Columns 1-2: NAICS 48-49 (Transport). Column 3: NAICS 42 (Wholesale). ",
                              "Column 4: New hires (HirN). Column 5: Average earnings (EarnBeg). ",
                              "Post = 1 for quarters after June 2016 canal expansion."),
               tex = TRUE,
               file = file.path(tables_dir, "tab2_main_results.tex"),
               replace = TRUE,
               label = "tab:main",
               title = "Panama Canal Expansion and Port Employment")

# ============================================================
# TABLE 3: Robustness
# ============================================================

if (rob_exists && placebo_exists) {
  tab3 <- etable(m1, m_no_la, m_health, m_prof,
                 dict = cm,
                 se.below = TRUE,
                 digits = 4,
                 fitstat = ~ n + r2 + wr2,
                 headers = c("Transport", "No LA", "Healthcare", "Prof. Svc."),
                 notes = paste0("Notes: Column 1 replicates the baseline. Column 2 excludes LA County. ",
                                "Columns 3-4 are placebo tests on industries with no canal exposure. ",
                                "All models include county and quarter FEs with county-clustered SEs."),
                 tex = TRUE,
                 file = file.path(tables_dir, "tab3_robustness.tex"),
                 replace = TRUE,
                 label = "tab:robust",
                 title = "Robustness and Placebo Tests")
}

# ============================================================
# TABLE 4: Leave-One-Out
# ============================================================

if (rob_exists) {
  loo_latex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Leave-One-Out Sensitivity}\n",
    "\\label{tab:loo}\n",
    "\\begin{tabular}{lcc}\n",
    "\\hline\\hline\n",
    "Dropped Port & Coefficient & SE \\\\\n",
    "\\hline\n"
  )

  for (i in 1:nrow(loo_results)) {
    row <- loo_results[i, ]
    sig <- ifelse(abs(row$coef / row$se) > 2.576, "***",
           ifelse(abs(row$coef / row$se) > 1.96, "**",
           ifelse(abs(row$coef / row$se) > 1.645, "*", "")))
    loo_latex <- paste0(loo_latex,
      gsub("_", "\\\\_", row$dropped), " & ",
      sprintf("%.4f%s", row$coef, sig), " & (",
      sprintf("%.4f", row$se), ") \\\\\n"
    )
  }

  baseline_se <- sqrt(vcov(m1)["treated:post", "treated:post"])
  loo_latex <- paste0(loo_latex,
    "\\hline\n",
    "Baseline (all ports) & ", sprintf("%.4f", coef(m1)["treated:post"]),
    " & (", sprintf("%.4f", baseline_se), ") \\\\\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} Each row drops one treated (East/Gulf Coast) port county and re-estimates the baseline DiD. ",
    "Dependent variable: log(Transport Employment). County and quarter FEs. County-clustered SEs. ",
    "*** p$<$0.01, ** p$<$0.05, * p$<$0.1.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )

  writeLines(loo_latex, file.path(tables_dir, "tab4_loo.tex"))
}

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) Appendix
# ============================================================

# Compute SDE for main outcomes
transport_pre <- transport %>% filter(post == 0)
wholesale_pre <- panel %>% filter(industry == "42", Emp > 0, post == 0)

sd_log_emp_t <- sd(transport_pre$log_emp, na.rm = TRUE)
sd_log_emp_w <- sd(wholesale_pre$log_emp[wholesale_pre$log_emp > 0], na.rm = TRUE)
sd_log_hire <- sd(log(transport_pre$HirN[transport_pre$HirN > 0]), na.rm = TRUE)
sd_log_earn <- sd(transport_pre$log_earn, na.rm = TRUE)

beta1 <- coef(m1)["treated:post"]
se1 <- sqrt(vcov(m1)["treated:post", "treated:post"])
beta4 <- coef(m4)["treated:post"]
se4 <- sqrt(vcov(m4)["treated:post", "treated:post"])
beta5 <- coef(m5)["treated:post"]
se5 <- sqrt(vcov(m5)["treated:post", "treated:post"])
beta6 <- coef(m6)["treated:post"]
se6 <- sqrt(vcov(m6)["treated:post", "treated:post"])

sde_data <- tribble(
  ~outcome, ~beta, ~se_beta, ~sd_y, ~panel,
  "Transport employment (log)", beta1, se1, sd_log_emp_t, "A",
  "Wholesale employment (log)", beta4, se4, sd_log_emp_w, "A",
  "New hires (log)", beta5, se5, sd_log_hire, "A",
  "Earnings (log)", beta6, se6, sd_log_earn, "A"
)

sde_data <- sde_data %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Add heterogeneity panel (East vs Gulf)
east_only <- transport %>%
  filter(region == "East" | region == "West") %>%
  mutate(treated_east = as.integer(region == "East"))

gulf_only <- transport %>%
  filter(region == "Gulf" | region == "West") %>%
  mutate(treated_gulf = as.integer(region == "Gulf"))

m_east <- feols(log_emp ~ treated_east:post | county_id + time_q,
                data = east_only, cluster = "county_id")
m_gulf <- feols(log_emp ~ treated_gulf:post | county_id + time_q,
                data = gulf_only, cluster = "county_id")

beta_east <- coef(m_east)[grep("treated_east:post", names(coef(m_east)))]
se_east <- sqrt(vcov(m_east)[grep("treated_east", rownames(vcov(m_east))),
                              grep("treated_east", colnames(vcov(m_east)))])
beta_gulf <- coef(m_gulf)[grep("treated_gulf:post", names(coef(m_gulf)))]
se_gulf <- sqrt(vcov(m_gulf)[grep("treated_gulf", rownames(vcov(m_gulf))),
                              grep("treated_gulf", colnames(vcov(m_gulf)))])

het_data <- tribble(
  ~outcome, ~beta, ~se_beta, ~sd_y, ~panel,
  "Transport emp --- East Coast", beta_east, se_east, sd_log_emp_t, "B",
  "Transport emp --- Gulf Coast", beta_gulf, se_gulf, sd_log_emp_t, "B"
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

all_sde <- bind_rows(sde_data, het_data)

# Generate LaTeX SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the June 2016 Panama Canal expansion, which enabled Neo-Panamax ",
  "vessels to transit directly to East and Gulf Coast ports, reallocate transport and warehousing ",
  "employment across US port counties? ",
  "\\textbf{Policy mechanism:} The \\$5.25 billion Third Set of Locks expansion doubled the canal's ",
  "maximum vessel beam from 32.3m to 55m, allowing 14,000 TEU container ships to bypass West Coast ",
  "ports and reach East/Gulf ports directly on trans-Pacific routes. ",
  "\\textbf{Outcome definition:} Quarterly beginning-of-quarter employment in NAICS 48--49 ",
  "(Transportation and Warehousing) from Census QWI, measured at county level. ",
  "\\textbf{Treatment:} Binary (East/Gulf Coast port county = 1, West Coast port county = 0). ",
  "\\textbf{Data:} Census QWI, 2010 Q1--2023 Q4, 19 port counties, ", diagnostics$n_obs, " county-quarter observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with county and quarter FEs; SEs clustered at county level. ",
  "\\textbf{Sample:} Major US container port counties; LA/Long Beach share one county (LA County). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2010--2016 Q2) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(all_sde)) {
  row <- all_sde[i, ]
  if (row$panel == "B" && i == nrow(sde_data) + 1) {
    sde_latex <- paste0(sde_latex,
      "\\hline\n",
      "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by coast)}} \\\\\n"
    )
  }
  sde_latex <- paste0(sde_latex,
    row$outcome, " & ",
    sprintf("%.4f", row$beta), " & ",
    sprintf("%.4f", row$se_beta), " & ",
    sprintf("%.4f", row$sd_y), " & ",
    sprintf("%.4f", row$sde), " & ",
    sprintf("%.4f", row$se_sde), " & ",
    row$classification, " \\\\\n"
  )
}

sde_latex <- paste0(sde_latex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_latex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== Tables generated ===\n")
cat("Tables saved:", paste(list.files(tables_dir), collapse = ", "), "\n")
