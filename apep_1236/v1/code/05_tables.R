# 05_tables.R — Generate all tables for paper

library(tidyverse)
library(fixest)
library(modelsummary)
library(kableExtra)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

panel <- readRDS("data/panel.rds")
panel$province[panel$province == "Fryslân"] <- "Friesland"
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")

dir.create("tables", showWarnings = FALSE)
options("modelsummary_format_numeric_latex" = "plain")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

pre <- panel %>% filter(date < as.Date("2019-07-01") & year >= 2015)
post <- panel %>% filter(date >= as.Date("2019-07-01"))

summ <- bind_rows(
  pre %>% group_by(Group = ifelse(high_pfas, "High PFAS", "Low PFAS")) %>%
    summarise(
      Period = "Pre-freeze (2015--2019:6)",
      N_muni = n_distinct(region),
      Mean = round(mean(new_construction, na.rm = TRUE), 2),
      SD = round(sd(new_construction, na.rm = TRUE), 2),
      Median = median(new_construction, na.rm = TRUE),
      Pct_Zero = round(100 * mean(new_construction == 0, na.rm = TRUE), 1),
      .groups = "drop"
    ),
  post %>% group_by(Group = ifelse(high_pfas, "High PFAS", "Low PFAS")) %>%
    summarise(
      Period = "Post-freeze (2019:7--2023:12)",
      N_muni = n_distinct(region),
      Mean = round(mean(new_construction, na.rm = TRUE), 2),
      SD = round(sd(new_construction, na.rm = TRUE), 2),
      Median = median(new_construction, na.rm = TRUE),
      Pct_Zero = round(100 * mean(new_construction == 0, na.rm = TRUE), 1),
      .groups = "drop"
    )
) %>%
  arrange(Group, Period)

# Generate LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Monthly New Housing Construction by PFAS Exposure}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\hline\\hline\n",
  "Group & Period & Municipalities & Mean & SD & Median & \\% Zero \\\\\n",
  "\\hline\n"
)
for (i in seq_len(nrow(summ))) {
  tab1_tex <- paste0(tab1_tex,
    summ$Group[i], " & ", summ$Period[i], " & ",
    summ$N_muni[i], " & ", summ$Mean[i], " & ", summ$SD[i], " & ",
    summ$Median[i], " & ", summ$Pct_Zero[i], " \\\\\n"
  )
  if (i == 2) tab1_tex <- paste0(tab1_tex, "\\hline\n")
}
tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Unit of observation is municipality-month. ",
  "New housing construction is the count of newly completed dwellings (Nieuwbouw) ",
  "from CBS Statline table 81955NED. High PFAS municipalities are those in ",
  "Zuid-Holland and Noord-Brabant provinces (containing the Chemours factory and ",
  "downstream Rhine-Maas delta). The PFAS soil movement freeze was imposed ",
  "nationally on July 3, 2019, with partial relaxation on November 29, 2019.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Generating Table 2: Main Results...\n")

tab2_models <- list(
  "Levels" = results$m1_levels,
  "Log" = results$m2_log,
  "Combined" = results$m3_combined,
  "Poisson" = results$m4_poisson
)

cm <- c(
  "treat_freeze" = "High PFAS $\\times$ Freeze",
  "treat_postrelax" = "High PFAS $\\times$ Post-relax",
  "treat_post" = "High PFAS $\\times$ Post"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "FE: region", "clean" = "Municipality FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: ym_factor", "clean" = "Year-Month FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

modelsummary(
  tab2_models,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = cm,
  gof_map = gm,
  output = "tables/tab2_main.tex",
  escape = FALSE,
  title = "Effect of PFAS Soil Movement Freeze on New Housing Construction\\label{tab:main}",
  notes = list(
    paste0("Unit of observation: municipality-month, 2012--2023. ",
           "Dependent variable: new housing completions (Columns 1--3) or log(completions + 1) (Column 2). ",
           "Column 4 uses Poisson QMLE. ",
           "High PFAS municipalities are in Zuid-Holland and Noord-Brabant (119 of 406). ",
           "Freeze: July--November 2019. Post-relax: December 2019 onward. ",
           "Standard errors clustered at the municipality level in parentheses.")
  )
)

# ============================================================
# Table 3: Event Study Selected Coefficients
# ============================================================
cat("Generating Table 3: Event Study...\n")

es_coefs <- results$es_coefs
# Select key event times: -12, -6, -3, -1, 0, 3, 6, 12, 24, 48
key_times <- c(-24, -12, -6, -3, 0, 3, 6, 12, 24, 48)
es_select <- es_coefs %>%
  filter(event_time %in% key_times) %>%
  mutate(
    est_str = sprintf("%.2f", Estimate),
    se_str = sprintf("(%.2f)", `Std. Error`),
    sig = case_when(
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.1 ~ "*",
      TRUE ~ ""
    )
  )

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Selected Coefficients}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Months since & Estimate & SE & Period \\\\\n",
  "freeze (July 2019) & & & \\\\\n",
  "\\hline\n"
)
for (i in seq_len(nrow(es_select))) {
  period_label <- ifelse(es_select$event_time[i] < 0, "Pre", "Post")
  tab3_tex <- paste0(tab3_tex,
    es_select$event_time[i], " & ",
    es_select$est_str[i], es_select$sig[i], " & ",
    es_select$se_str[i], " & ",
    period_label, " \\\\\n"
  )
  if (es_select$event_time[i] == -3 || es_select$event_time[i] == 0) {
    # No extra line needed
  }
}
tab3_tex <- paste0(tab3_tex,
  "\\hline\n",
  "Municipalities & \\multicolumn{3}{c}{406} \\\\\n",
  "Observations & \\multicolumn{3}{c}{", format(nobs(results$es), big.mark = ","), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from an event study regression of new housing ",
  "construction on High PFAS $\\times$ event-time indicators, with municipality and ",
  "year-month fixed effects. Reference period: $t = -1$ (June 2019). ",
  "Standard errors clustered at the municipality level. ",
  "$^{*}p < 0.10$, $^{**}p < 0.05$, $^{***}p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "tables/tab3_eventstudy.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4: Robustness...\n")

rob_models <- list(
  "Pre-COVID" = rob$r1_precovid,
  "Prov trends" = rob$r2_prov_trends,
  "ZH only" = rob$r3_zh_only,
  "Placebo 2017" = rob$r4_placebo,
  "Winsorized" = rob$r5_winsorized
)

cm_rob <- c(
  "treat_freeze" = "High PFAS $\\times$ Freeze",
  "treat_postrelax" = "High PFAS $\\times$ Post-relax",
  "treat_zh_freeze" = "Zuid-Holland $\\times$ Freeze",
  "treat_zh_postrelax" = "Zuid-Holland $\\times$ Post-relax",
  "treat_placebo_freeze" = "High PFAS $\\times$ Placebo freeze",
  "treat_placebo_post" = "High PFAS $\\times$ Placebo post"
)

modelsummary(
  rob_models,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  coef_map = cm_rob,
  gof_map = gm,
  output = "tables/tab4_robustness.tex",
  escape = FALSE,
  title = "Robustness Checks\\label{tab:robustness}",
  notes = list(
    paste0("All specifications include municipality and year-month fixed effects. ",
           "Column 1 restricts to pre-COVID months (through February 2020). ",
           "Column 2 adds province-specific linear time trends. ",
           "Column 3 redefines treatment as Zuid-Holland only. ",
           "Column 4 applies a placebo freeze at July 2017, using only pre-freeze data. ",
           "Column 5 winsorizes the outcome at the 99th percentile. ",
           "Standard errors clustered at the municipality level.")
  )
)

# ============================================================
# Table F1: Standardized Effect Size (SDE) — Appendix
# ============================================================
cat("Generating Table F1: SDE...\n")

# Get estimates and SDs
beta_freeze <- coef(results$m1_levels)["treat_freeze"]
se_freeze <- sqrt(vcov(results$m1_levels)["treat_freeze", "treat_freeze"])
beta_postrelax <- coef(results$m1_levels)["treat_postrelax"]
se_postrelax <- sqrt(vcov(results$m1_levels)["treat_postrelax", "treat_postrelax"])

# Pre-treatment SD of outcome
pre_data <- panel %>% filter(date < as.Date("2019-07-01"))
sd_y <- sd(pre_data$new_construction, na.rm = TRUE)

# SDEs
sde_freeze <- beta_freeze / sd_y
se_sde_freeze <- se_freeze / sd_y
sde_postrelax <- beta_postrelax / sd_y
se_sde_postrelax <- se_postrelax / sd_y

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  return("Small positive")
}

# Log specification SDEs
beta_log_freeze <- coef(results$m2_log)["treat_freeze"]
se_log_freeze <- sqrt(vcov(results$m2_log)["treat_freeze", "treat_freeze"])
beta_log_postrelax <- coef(results$m2_log)["treat_postrelax"]
se_log_postrelax <- sqrt(vcov(results$m2_log)["treat_postrelax", "treat_postrelax"])

sd_log_y <- sd(pre_data$log_new, na.rm = TRUE)
pre_data$log_new <- log(pre_data$new_construction + 1)
sd_log_y <- sd(pre_data$log_new, na.rm = TRUE)

sde_log_freeze <- beta_log_freeze / sd_log_y
se_sde_log_freeze <- se_log_freeze / sd_log_y
sde_log_postrelax <- beta_log_postrelax / sd_log_y
se_sde_log_postrelax <- se_log_postrelax / sd_log_y

# Net addition SDE
beta_net_freeze <- coef(results$m_net)["treat_freeze"]
se_net_freeze <- sqrt(vcov(results$m_net)["treat_freeze", "treat_freeze"])
beta_net_postrelax <- coef(results$m_net)["treat_postrelax"]
se_net_postrelax <- sqrt(vcov(results$m_net)["treat_postrelax", "treat_postrelax"])

sd_net <- sd(pre_data$new_construction - panel$demolition[panel$date < as.Date("2019-07-01")], na.rm = TRUE)

sde_net_freeze <- beta_net_freeze / sd_net
se_sde_net_freeze <- se_net_freeze / sd_net

# Extensive margin
beta_ext_freeze <- coef(results$m_ext)["treat_freeze"]
se_ext_freeze <- sqrt(vcov(results$m_ext)["treat_freeze", "treat_freeze"])
sd_zero <- sd(pre_data$new_construction == 0, na.rm = TRUE)
sde_ext_freeze <- beta_ext_freeze / sd_zero
se_sde_ext_freeze <- se_ext_freeze / sd_zero

# Build SDE table
sde_rows <- data.frame(
  Outcome = c(
    "New construction (levels)",
    "New construction (levels)",
    "New construction (log)",
    "New construction (log)",
    "Net additions",
    "Zero construction (LPM)"
  ),
  Period = c("Freeze", "Post-relax", "Freeze", "Post-relax", "Freeze", "Freeze"),
  Beta = c(beta_freeze, beta_postrelax, beta_log_freeze, beta_log_postrelax,
           beta_net_freeze, beta_ext_freeze),
  SE = c(se_freeze, se_postrelax, se_log_freeze, se_log_postrelax,
         se_net_freeze, se_ext_freeze),
  SD_Y = c(sd_y, sd_y, sd_log_y, sd_log_y, sd_net, sd_zero),
  SDE = c(sde_freeze, sde_postrelax, sde_log_freeze, sde_log_postrelax,
          sde_net_freeze, sde_ext_freeze),
  SE_SDE = c(se_sde_freeze, se_sde_postrelax, se_sde_log_freeze, se_sde_log_postrelax,
             se_sde_net_freeze, se_sde_ext_freeze)
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# Panel B: Heterogeneity (Zuid-Holland vs Noord-Brabant)
beta_zh <- coef(rob$r3_zh_only)["treat_zh_postrelax"]
se_zh <- sqrt(vcov(rob$r3_zh_only)["treat_zh_postrelax", "treat_zh_postrelax"])
sde_zh <- beta_zh / sd_y
se_sde_zh <- se_zh / sd_y

beta_nb_postrelax <- coef(results$m_nb)["treat_postrelax"]
se_nb_postrelax <- sqrt(vcov(results$m_nb)["treat_postrelax", "treat_postrelax"])
sde_nb <- beta_nb_postrelax / sd_y
se_sde_nb <- se_nb_postrelax / sd_y

het_rows <- data.frame(
  Outcome = c("New construction (Zuid-Holland)", "New construction (Noord-Brabant)"),
  Period = c("Post-relax", "Post-relax"),
  Beta = c(beta_zh, beta_nb_postrelax),
  SE = c(se_zh, se_nb_postrelax),
  SD_Y = c(sd_y, sd_y),
  SDE = c(sde_zh, sde_nb),
  SE_SDE = c(se_sde_zh, se_sde_nb),
  Classification = c(classify_sde(sde_zh), classify_sde(sde_nb))
)

# Generate LaTeX
fmt <- function(x) sprintf("%.3f", x)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Netherlands. ",
  "\\textbf{Research question:} Did the July 2019 PFAS soil movement freeze, ",
  "which set contamination thresholds so low that virtually all soil became immovable, ",
  "differentially reduce new housing construction in high-contamination municipalities ",
  "near the Chemours factory in Dordrecht? ",
  "\\textbf{Policy mechanism:} The RIVM set provisional PFAS standards at 0.1 $\\mu$g/kg, ",
  "effectively banning all soil movement for construction. In November 2019, thresholds were ",
  "raised to 0.3--0.8 $\\mu$g/kg, partially restoring construction activity. ",
  "\\textbf{Outcome definition:} Monthly count of newly completed dwellings (Nieuwbouw) ",
  "per municipality from CBS Statline table 81955NED. ",
  "\\textbf{Treatment:} Binary indicator for municipalities in Zuid-Holland and Noord-Brabant ",
  "(high PFAS exposure due to Chemours factory proximity and Rhine-Maas river system). ",
  "\\textbf{Data:} CBS Statline 81955NED, 2012--2023, municipality-month, 58,464 observations ",
  "across 406 municipalities. ",
  "\\textbf{Method:} Two-way fixed effects DiD with municipality and year-month fixed effects; ",
  "standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} All Dutch municipalities with complete housing stock data; 119 treated ",
  "(high PFAS) and 287 control (low PFAS). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\hline\\hline\n",
  "Outcome & Period & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)
for (i in seq_len(nrow(sde_rows))) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_rows$Outcome[i], " & ",
    sde_rows$Period[i], " & ",
    fmt(sde_rows$Beta[i]), " & ",
    fmt(sde_rows$SE[i]), " & ",
    fmt(sde_rows$SD_Y[i]), " & ",
    fmt(sde_rows$SDE[i]), " & ",
    fmt(sde_rows$SE_SDE[i]), " & ",
    sde_rows$Classification[i], " \\\\\n"
  )
}
tabF1_tex <- paste0(tabF1_tex,
  "\\hline\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (Province-level splits)}} \\\\\n"
)
for (i in seq_len(nrow(het_rows))) {
  tabF1_tex <- paste0(tabF1_tex,
    het_rows$Outcome[i], " & ",
    het_rows$Period[i], " & ",
    fmt(het_rows$Beta[i]), " & ",
    fmt(het_rows$SE[i]), " & ",
    fmt(het_rows$SD_Y[i]), " & ",
    fmt(het_rows$SDE[i]), " & ",
    fmt(het_rows$SE_SDE[i]), " & ",
    het_rows$Classification[i], " \\\\\n"
  )
}
tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, "tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
cat("Files:", paste(list.files("tables"), collapse = ", "), "\n")
