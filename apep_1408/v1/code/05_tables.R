## 05_tables.R — Generate all tables including SDE appendix
## apep_1408: PNIS coca substitution in Colombia

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>%
  mutate(
    cohort = if_else(first_treat == 0, Inf, as.numeric(first_treat)),
    post_2017 = as.integer(year >= 2017)
  )

sunab_est <- readRDS(file.path(data_dir, "sunab_results.rds"))
twfe_est <- readRDS(file.path(data_dir, "twfe_results.rds"))

## ─────────────────────────────────────────────────
## Table 1: Summary Statistics
## ─────────────────────────────────────────────────

cat("=== Table 1: Summary Statistics ===\n")

sum_stats <- panel %>%
  mutate(group = if_else(pnis_enrolled == 1, "PNIS", "Non-PNIS")) %>%
  group_by(group) %>%
  summarize(
    `Municipalities` = n_distinct(codmpio),
    `Mean Coca (ha)` = round(mean(coca_ha, na.rm = TRUE), 1),
    `SD Coca (ha)` = round(sd(coca_ha, na.rm = TRUE), 1),
    `Median Coca (ha)` = round(median(coca_ha, na.rm = TRUE), 1),
    `Mean Coca 2016` = round(mean(coca_2016, na.rm = TRUE), 1),
    `Mean Erad. Events/yr` = round(mean(erad_events, na.rm = TRUE), 1),
    .groups = "drop"
  )

print(sum_stats)

# LaTeX output
sum_tex <- kable(sum_stats, format = "latex", booktabs = TRUE,
                 caption = "Summary Statistics: PNIS vs. Non-PNIS Municipalities") %>%
  kable_styling(latex_options = "hold_position")
writeLines(sum_tex, file.path(tab_dir, "tab1_summary.tex"))

## ─────────────────────────────────────────────────
## Table 2: Main results
## ─────────────────────────────────────────────────

cat("\n=== Table 2: Main Results ===\n")

# Additional specifications for the table
twfe_dept <- feols(
  ihs_coca ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel,
  cluster = ~coddepto
)

twfe_level <- feols(
  coca_ha ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel,
  cluster = ~codmpio
)

models <- list(
  "IHS Coca (TWFE)" = twfe_est,
  "IHS Coca (SA)" = sunab_est,
  "IHS Coca (Dept. Cl.)" = twfe_dept,
  "Coca Ha (Level)" = twfe_level
)

# Using modelsummary
options("modelsummary_format_numeric_latex" = "plain")
tab2 <- modelsummary(
  models,
  output = file.path(tab_dir, "tab2_main.tex"),
  stars = c('*' = .1, '**' = .05, '***' = .01),
  gof_map = c("nobs", "r.squared.within"),
  title = "Effect of PNIS Enrollment on Coca Cultivation"
)

## ─────────────────────────────────────────────────
## Table 3: Robustness
## ─────────────────────────────────────────────────

cat("\n=== Table 3: Robustness ===\n")

ddd_est <- readRDS(file.path(data_dir, "ddd_results.rds"))
sunab_no2019 <- readRDS(file.path(data_dir, "sunab_no2019_results.rds"))

# Pre-period only
twfe_pre <- feols(
  ihs_coca ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel %>% filter(year <= 2020),
  cluster = ~codmpio
)

rob_models <- list(
  "Baseline" = twfe_est,
  "DDD" = ddd_est,
  "Excl. 2019" = sunab_no2019,
  "Through 2020" = twfe_pre
)

tab3 <- modelsummary(
  rob_models,
  output = file.path(tab_dir, "tab3_robustness.tex"),
  stars = c('*' = .1, '**' = .05, '***' = .01),
  gof_map = c("nobs", "r.squared.within"),
  title = "Robustness: Alternative Specifications"
)

## ─────────────────────────────────────────────────
## Table 4: Pre-trend test
## ─────────────────────────────────────────────────

cat("\n=== Table 4: Pre-trend coefficients ===\n")

es_df <- broom::tidy(sunab_est) %>%
  mutate(rel_time = as.integer(gsub("year::", "", term))) %>%
  filter(rel_time >= -5, rel_time <= 0) %>%
  select(rel_time, estimate, std.error, p.value)

print(es_df)

## ─────────────────────────────────────────────────
## Table F1: SDE (Mandatory)
## ─────────────────────────────────────────────────

cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Pre-treatment SD of outcomes
pre_panel <- panel %>% filter(year < 2017)

sd_ihs_coca <- sd(pre_panel$ihs_coca[pre_panel$pnis_enrolled == 1], na.rm = TRUE)
sd_coca_ha <- sd(pre_panel$coca_ha[pre_panel$pnis_enrolled == 1], na.rm = TRUE)
sd_ihs_erad <- sd(pre_panel$ihs_erad[pre_panel$pnis_enrolled == 1], na.rm = TRUE)

cat("Pre-treatment SDs — IHS coca:", sd_ihs_coca, ", Coca ha:", sd_coca_ha,
    ", IHS erad:", sd_ihs_erad, "\n")

# Main TWFE estimates for SDE
twfe_erad <- feols(
  ihs_erad ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel,
  cluster = ~codmpio
)

# Panel A: Pooled
beta_coca <- coef(twfe_est)["post"]
se_coca <- summary(twfe_est)$se["post"]

beta_coca_level <- coef(twfe_level)["post_2017:pnis_enrolled"]
se_coca_level <- summary(twfe_level)$se["post_2017:pnis_enrolled"]

beta_erad <- coef(twfe_erad)["post_2017:pnis_enrolled"]
se_erad <- summary(twfe_erad)$se["post_2017:pnis_enrolled"]

sde_coca <- beta_coca / sd_ihs_coca
se_sde_coca <- se_coca / sd_ihs_coca

sde_level <- beta_coca_level / sd_coca_ha
se_sde_level <- se_coca_level / sd_coca_ha

sde_erad <- beta_erad / sd_ihs_erad
se_sde_erad <- se_erad / sd_ihs_erad

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Panel B: Heterogeneity — Wave 1 vs Wave 2
twfe_w1 <- feols(
  ihs_coca ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel %>% filter(first_treat %in% c(0, 2017)),
  cluster = ~codmpio
)
twfe_w2 <- feols(
  ihs_coca ~ post_2017:pnis_enrolled | codmpio + year,
  data = panel %>% filter(first_treat %in% c(0, 2018)),
  cluster = ~codmpio
)

beta_w1 <- coef(twfe_w1)["post_2017:pnis_enrolled"]
se_w1 <- summary(twfe_w1)$se["post_2017:pnis_enrolled"]
sde_w1 <- beta_w1 / sd_ihs_coca
se_sde_w1 <- se_w1 / sd_ihs_coca

beta_w2 <- coef(twfe_w2)["post_2017:pnis_enrolled"]
se_w2 <- summary(twfe_w2)$se["post_2017:pnis_enrolled"]
sde_w2 <- beta_w2 / sd_ihs_coca
se_sde_w2 <- se_w2 / sd_ihs_coca

# Build SDE table
sde_rows <- tribble(
  ~Panel, ~Outcome, ~Beta, ~SE, ~SD_Y, ~SDE, ~SE_SDE, ~Classification,
  "A", "Coca area (IHS)", round(beta_coca, 3), round(se_coca, 3), round(sd_ihs_coca, 3),
    round(sde_coca, 3), round(se_sde_coca, 3), classify_sde(sde_coca),
  "A", "Coca area (ha)", round(beta_coca_level, 1), round(se_coca_level, 1), round(sd_coca_ha, 1),
    round(sde_level, 3), round(se_sde_level, 3), classify_sde(sde_level),
  "A", "Eradication (IHS)", round(beta_erad, 3), round(se_erad, 3), round(sd_ihs_erad, 3),
    round(sde_erad, 3), round(se_sde_erad, 3), classify_sde(sde_erad),
  "B", "Coca (Wave 1, 2017)", round(beta_w1, 3), round(se_w1, 3), round(sd_ihs_coca, 3),
    round(sde_w1, 3), round(se_sde_w1, 3), classify_sde(sde_w1),
  "B", "Coca (Wave 2, 2018)", round(beta_w2, 3), round(se_w2, 3), round(sd_ihs_coca, 3),
    round(sde_w2, 3), round(se_sde_w2, 3), classify_sde(sde_w2)
)

cat("\nSDE Table:\n")
print(sde_rows)

# LaTeX SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Did PNIS voluntary coca substitution reduce coca cultivation in enrolled municipalities? ",
  "\\textbf{Policy mechanism:} PNIS paid coca-farming families COP 36 million over 12 months to voluntarily eradicate coca and transition to legal agriculture, conditioned on verified eradication, with technical assistance and productive project financing. ",
  "\\textbf{Outcome definition:} Annual coca hectares detected by satellite (SIMCI) at the municipality level; IHS transformation for main specification, levels as robustness. ",
  "\\textbf{Treatment:} Binary indicator for municipality enrollment in PNIS, with staggered rollout across two waves (2017 and 2018). ",
  "\\textbf{Data:} SIMCI coca cultivation panel from datos.gov.co (resource acs4-3wgp), 319 municipalities, 2001--2023; PNIS enrollment from datos.gov.co (resource v4pt-rnn9), 56 municipalities; eradication events from datos.gov.co (resource p72f-qcvk), 145,398 events. Total panel: 7,337 municipality-year observations. ",
  "\\textbf{Method:} Sun-Abraham (2021) heterogeneity-robust estimator with municipality and year fixed effects; standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} All municipalities with any coca detection in the SIMCI panel (2001--2023); 55 PNIS-enrolled and 264 never-enrolled comparison municipalities. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

sde_latex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llrrrrrl}",
  "\\toprule",
  " & Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textbf{Panel A: Pooled}} \\\\",
  paste0(" & ", sde_rows$Outcome[1], " & ", sde_rows$Beta[1], " & ", sde_rows$SE[1], " & ",
         sde_rows$SD_Y[1], " & ", sde_rows$SDE[1], " & ", sde_rows$SE_SDE[1], " & ",
         sde_rows$Classification[1], " \\\\"),
  paste0(" & ", sde_rows$Outcome[2], " & ", sde_rows$Beta[2], " & ", sde_rows$SE[2], " & ",
         sde_rows$SD_Y[2], " & ", sde_rows$SDE[2], " & ", sde_rows$SE_SDE[2], " & ",
         sde_rows$Classification[2], " \\\\"),
  paste0(" & ", sde_rows$Outcome[3], " & ", sde_rows$Beta[3], " & ", sde_rows$SE[3], " & ",
         sde_rows$SD_Y[3], " & ", sde_rows$SDE[3], " & ", sde_rows$SE_SDE[3], " & ",
         sde_rows$Classification[3], " \\\\"),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textbf{Panel B: Heterogeneous (by wave)}} \\\\",
  paste0(" & ", sde_rows$Outcome[4], " & ", sde_rows$Beta[4], " & ", sde_rows$SE[4], " & ",
         sde_rows$SD_Y[4], " & ", sde_rows$SDE[4], " & ", sde_rows$SE_SDE[4], " & ",
         sde_rows$Classification[4], " \\\\"),
  paste0(" & ", sde_rows$Outcome[5], " & ", sde_rows$Beta[5], " & ", sde_rows$SE[5], " & ",
         sde_rows$SD_Y[5], " & ", sde_rows$SDE[5], " & ", sde_rows$SE_SDE[5], " & ",
         sde_rows$Classification[5], " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{tablenotes}[flushleft]\\small"),
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_latex, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
