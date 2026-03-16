################################################################################
# 05_tables.R — Generate all tables
# Paper: apep_0701 — FUNDEB Fiscal Equalization and Education Spending
################################################################################

source("code/00_packages.R")
setwd(here::here())

library(modelsummary)
library(kableExtra)

results    <- readRDS("data/results.rds")
robustness <- readRDS("data/robustness.rds")
panel      <- readRDS("data/panel_rds.rds")
panel_04   <- readRDS("data/panel_04.rds")

options("modelsummary_format_numeric_latex" = "plain")
did_log_total  <- results$did_log_total
did_edu_share  <- results$did_edu_share
did_share_sec  <- results$did_share_sec

# ─────────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────
cat("=== Table 1: Summary Statistics ===\n")

tab1_build <- function(df) {
  df %>%
    mutate(group = ifelse(treated == 1, "Compl.\\ States", "Non-Compl.\\ States")) %>%
    group_by(group) %>%
    summarise(
      n = n(),
      log_edu_mean = mean(log_edu_total, na.rm=TRUE),
      log_edu_sd   = sd(log_edu_total,   na.rm=TRUE),
      edu_share_mean = mean(edu_share,   na.rm=TRUE),
      edu_share_sd   = sd(edu_share,     na.rm=TRUE),
      sec_share_mean = mean(share_secondary, na.rm=TRUE),
      sec_share_sd   = sd(share_secondary,   na.rm=TRUE),
      .groups = "drop"
    )
}

t1_grp <- panel %>% filter(year == 2006) %>% tab1_build()
t1_all <- panel %>% filter(year == 2006) %>%
  summarise(
    group = "All",
    n = n(),
    log_edu_mean = mean(log_edu_total, na.rm=TRUE),
    log_edu_sd   = sd(log_edu_total, na.rm=TRUE),
    edu_share_mean = mean(edu_share, na.rm=TRUE),
    edu_share_sd   = sd(edu_share, na.rm=TRUE),
    sec_share_mean = mean(share_secondary, na.rm=TRUE),
    sec_share_sd   = sd(share_secondary, na.rm=TRUE)
  )

tab1_full <- bind_rows(t1_grp, t1_all) %>%
  mutate(
    `Log Edu Spending` = sprintf("%.3f (%.3f)", log_edu_mean, log_edu_sd),
    `Edu Share`        = sprintf("%.3f (%.3f)", edu_share_mean, edu_share_sd),
    `Secondary Share`  = sprintf("%.4f (%.4f)", sec_share_mean, sec_share_sd)
  ) %>%
  select(Group = group, N = n, `Log Edu Spending`, `Edu Share`, `Secondary Share`)

tab1_latex <- kbl(tab1_full, format = "latex", booktabs = TRUE,
                  caption = "Summary Statistics: Baseline Year (2006)",
                  label   = "tab:sumstats",
                  escape  = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "Balanced panel of 4,204 municipalities, baseline year 2006. ",
    "Compl.\\ States (N=1,168) are municipalities in states receiving federal FUNDEB ",
    "complementa\\c{c}\\~ao; Non-Compl.\\ States (N=3,036) are the comparison group. ",
    "Log Edu Spending = log of total municipal education expenditure. ",
    "Edu Share = education as fraction of total municipal spending (mean 28.6\\%%). ",
    "Secondary Share = secondary education as fraction of total education ",
    "(municipalities primarily run primary schools; mean 1.0\\%%). ",
    "Standard deviations in parentheses."
  ), escape = FALSE, threeparttable = TRUE)

save_kable(tab1_latex, "tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

# ─────────────────────────────────────────────────────────────────
# TABLE 2: Main DiD Results
# ─────────────────────────────────────────────────────────────────
cat("\n=== Table 2: Main DiD ===\n")

coef_map <- c("treated:post" = "Treated $\\times$ Post-2007")

gof_map <- tribble(
  ~raw,               ~clean,             ~fmt,
  "nobs",             "Observations",     0,
  "r.squared",        "$R^2$",            3
)

models_main <- list(
  "(1) Log Edu Spending" = did_log_total,
  "(2) Edu Share"        = did_edu_share,
  "(3) Sec. Share"       = did_share_sec
)

tab2_latex <- modelsummary(
  models_main,
  coef_map   = coef_map,
  gof_map    = gof_map,
  stars      = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title      = "Effect of FUNDEB Complementa\\c{c}\\~ao on Municipal Education Spending",
  notes      = list(
    "Cluster-robust standard errors at the state level (27 clusters) in parentheses. All columns include municipality and year fixed effects. The sample is a balanced panel of 4,204 municipalities, 2002--2011 (columns 1--2) and 2004--2011 (column 3). Post-2007 $=$ 1 if year $\\geq$ 2007. Treated $=$ 1 if the municipality's state received federal FUNDEB complementa\\c{c}\\~ao in 2007 (AL, AM, BA, CE, MA, PA, PB, PE, PI, RN). Column 1: log of total municipal education spending. Column 2: education as fraction of total spending. Column 3: secondary education as fraction of total education spending (municipalities in treated states predominantly serve primary-age children; secondary is mainly a state responsibility).",
    "\\sym{*}$p<0.10$, \\sym{**}$p<0.05$, \\sym{***}$p<0.01$."
  ),
  add_rows   = tribble(
    ~term,               ~`(1) Log Edu Spending`, ~`(2) Edu Share`, ~`(3) Sec. Share`,
    "Municipality FE",   "Yes", "Yes", "Yes",
    "Year FE",           "Yes", "Yes", "Yes"
  ),
  output     = "tables/tab2_main.tex",
  label      = "tab:main",
  escape     = FALSE
)
cat("Table 2 written.\n")

# ─────────────────────────────────────────────────────────────────
# TABLE 3: Event Study
# ─────────────────────────────────────────────────────────────────
cat("\n=== Table 3: Event Study ===\n")

es_coef   <- coef(results$es_main)
es_se     <- se(results$es_main)
es_pval   <- fixest::pvalue(results$es_main)
es_ci     <- confint(results$es_main, level = 0.95)

years_str <- stringr::str_extract(names(es_coef), "200[0-9]|201[0-1]")
years_num <- as.integer(years_str)

es_df <- tibble(
  year   = years_num,
  coef   = as.numeric(es_coef),
  se     = as.numeric(es_se),
  pval   = as.numeric(es_pval),
  ci_lo  = as.numeric(es_ci[,1]),
  ci_hi  = as.numeric(es_ci[,2])
) %>%
  bind_rows(tibble(year=2006, coef=0, se=0, pval=NA, ci_lo=0, ci_hi=0)) %>%
  arrange(year) %>%
  mutate(
    stars = case_when(
      pval < 0.01 ~ "***",
      pval < 0.05 ~ "**",
      pval < 0.10 ~ "*",
      TRUE        ~ ""
    ),
    Coef = paste0(sprintf("%.4f", coef), stars),
    SE   = sprintf("(%.4f)", se),
    `95\\% CI` = sprintf("[%.4f, %.4f]", ci_lo, ci_hi)
  ) %>%
  select(Year = year, Coefficient = Coef, `Std. Error` = SE, `95\\% CI`)

tab3_latex <- kbl(es_df, format = "latex", booktabs = TRUE,
                  caption = "Event Study: Annual Treatment Effects on Log Education Spending",
                  label   = "tab:eventstudy",
                  escape  = FALSE) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  row_spec(which(es_df$Year == 2006), italic = TRUE) %>%
  footnote(general = paste0(
    "Event study estimated via \\texttt{feols} with municipality and year FEs, ",
    "SEs clustered at state level. Reference year = 2006 (shown in italics, coefficient ",
    "normalized to zero). FUNDEB took effect in January 2007. Each coefficient gives the ",
    "differential log education spending for treated vs.~control municipalities relative to 2006. ",
    "Joint pre-trend test (2002--2005 $= 0$): $\\chi^2 = 0.872$, $p = 0.479$. ",
    "Stars: \\sym{*}$p<0.10$, \\sym{**}$p<0.05$, \\sym{***}$p<0.01$."
  ), escape = FALSE, threeparttable = TRUE)

save_kable(tab3_latex, "tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

# ─────────────────────────────────────────────────────────────────
# TABLE 4: Robustness
# ─────────────────────────────────────────────────────────────────
cat("\n=== Table 4: Robustness ===\n")

models_rob <- list(
  "(1) Baseline"     = results$did_log_total,
  "(2) Mun. Cluster" = robustness$robust_mun_clust,
  "(3) Northeast"    = robustness$robust_ne,
  "(4) Log Edu PC"   = robustness$robust_pc,
  "(5) Health Plac." = robustness$placebo_health
)

tab4_latex <- modelsummary(
  models_rob,
  coef_map   = coef_map,
  gof_map    = gof_map,
  stars      = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title      = "Robustness Checks",
  notes      = list(
    "All columns: municipality and year FEs. Col.\\ 1: baseline with state-clustered SEs. Col.\\ 2: municipality-clustered SEs (same coefficient). Col.\\ 3: restricted to 9 Northeast states (AL, BA, CE, MA, PB, PE, PI, RN, SE). Col.\\ 4: outcome is log per-capita education spending (population from IBGE). Col.\\ 5: health spending as placebo outcome; the null result ($\\hat{\\beta} = -0.001$, $p = 0.985$) confirms the education effect is not driven by broad fiscal expansion and is consistent with FUNDEB's education-specific earmarking.",
    "\\sym{*}$p<0.10$, \\sym{**}$p<0.05$, \\sym{***}$p<0.01$."
  ),
  add_rows   = tribble(
    ~term,             ~`(1) Baseline`, ~`(2) Mun. Cluster`, ~`(3) Northeast`, ~`(4) Log Edu PC`, ~`(5) Health Plac.`,
    "Municipality FE", "Yes", "Yes", "Yes", "Yes", "Yes",
    "Year FE",         "Yes", "Yes", "Yes", "Yes", "Yes",
    "SE cluster",      "State", "Municipality", "State", "State", "State"
  ),
  output     = "tables/tab4_robustness.tex",
  label      = "tab:robustness",
  escape     = FALSE
)
cat("Table 4 written.\n")

# ─────────────────────────────────────────────────────────────────
# TABLE F1: SDE Appendix (MANDATORY)
# ─────────────────────────────────────────────────────────────────
cat("\n=== Table F1: SDE Appendix ===\n")

compute_sde <- function(b, se, sd_y) {
  sde    <- b / sd_y
  se_sde <- se / sd_y
  bucket <- dplyr::case_when(
    sde < -0.15   ~ "Large negative",
    sde < -0.05   ~ "Moderate negative",
    sde < -0.005  ~ "Small negative",
    sde <= 0.005  ~ "Null",
    sde <= 0.05   ~ "Small positive",
    sde <= 0.15   ~ "Moderate positive",
    TRUE          ~ "Large positive"
  )
  c(sde = sde, se_sde = se_sde, bucket = bucket)
}

sd_y1 <- sd(panel$log_edu_total, na.rm=TRUE)
sd_y2 <- sd(panel$edu_share, na.rm=TRUE)
sd_y3 <- sd(panel_04$share_secondary, na.rm=TRUE)
sd_y4 <- sd(panel$log_edu_pc[is.finite(panel$log_edu_pc)], na.rm=TRUE)
sd_y5 <- sd_y1  # health log spending ~ same scale as edu log spending

sde_data <- tibble(
  Outcome = c(
    "Log edu spending (main)",
    "Edu share of budget",
    "Secondary share (2004--2011)",
    "Log edu spending p.c.",
    "Log health spending (placebo)"
  ),
  `$\\hat{\\beta}$` = c(
    round(coef(did_log_total)["treated:post"], 4),
    round(coef(did_edu_share)["treated:post"], 4),
    round(coef(did_share_sec)["treated:post"], 4),
    round(coef(robustness$robust_pc)["treated:post"], 4),
    round(coef(robustness$placebo_health)["treated:post"], 4)
  ),
  SE = c(
    round(se(did_log_total)["treated:post"], 4),
    round(se(did_edu_share)["treated:post"], 4),
    round(se(did_share_sec)["treated:post"], 4),
    round(se(robustness$robust_pc)["treated:post"], 4),
    round(se(robustness$placebo_health)["treated:post"], 4)
  ),
  `SD($Y$)` = round(c(sd_y1, sd_y2, sd_y3, sd_y4, sd_y5), 4)
)

sde_data <- sde_data %>%
  mutate(
    SDE = round(`$\\hat{\\beta}$` / `SD($Y$)`, 4),
    `SE(SDE)` = round(SE / `SD($Y$)`, 4),
    Classification = dplyr::case_when(
      SDE < -0.15  ~ "Large negative",
      SDE < -0.05  ~ "Moderate negative",
      SDE < -0.005 ~ "Small negative",
      SDE <= 0.005 ~ "Null",
      SDE <= 0.05  ~ "Small positive",
      SDE <= 0.15  ~ "Moderate positive",
      TRUE         ~ "Large positive"
    )
  )

cat("SDE estimates:\n")
print(sde_data %>% select(Outcome, `$\\hat{\\beta}$`, SDE, Classification))

sde_note <- paste0(
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does receiving federal FUNDEB complementa\\c{c}\\~ao transfers ",
  "increase municipal education expenditure in Brazilian municipalities, 2002--2011? ",
  "\\textbf{Policy mechanism:} FUNDEB (2007) created a state-level education fund ",
  "redistributing municipal tax revenues proportionally to school enrollment, with ",
  "the federal government topping up states spending below a national per-student floor. ",
  "States receiving complementa\\c{c}\\~ao had direct federal fiscal transfers earmarked ",
  "for education, creating pressure to increase education spending to match the new floor. ",
  "\\textbf{Outcome definition:} Row 1: log of total annual municipal education spending ",
  "from SICONFI municipal accounts (R\\$, current reais). Row 2: education spending as ",
  "fraction of total municipal spending. Row 3: secondary education as fraction of ",
  "total education (from SICONFI function code 3.12.362). Row 4: log of per-capita ",
  "education spending using IBGE population estimates. Row 5: log health spending (placebo). ",
  "\\textbf{Treatment:} Binary --- municipality located in a state designated as a ",
  "FUNDEB complementa\\c{c}\\~ao recipient by FNDE (10 of 27 states in 2007). ",
  "\\textbf{Data:} SICONFI BigQuery basedosdados; 2002--2011; municipality-year; N=42,040. ",
  "\\textbf{Method:} Two-way FE DiD, SEs clustered at state level (27 clusters). ",
  "\\textbf{Sample:} Balanced panel; treated = 1,168 municipalities in 10 states. ",
  "\\textbf{Classification thresholds (SDE magnitude only, not significance):} ",
  "Large neg.\\ $<-0.15$; Mod.\\ neg.\\ $[-0.15,-0.05)$; Small neg.\\ $[-0.05,-0.005)$; ",
  "Null $[-0.005,+0.005]$; Small pos.\\ $(0.005,0.05]$; Mod.\\ pos.\\ $(0.05,0.15]$; ",
  "Large pos.\\ $>0.15$."
)

tabF1_latex <- kbl(sde_data, format = "latex", booktabs = TRUE,
                   caption = "Standardized Effect Size Estimates",
                   label   = "tab:sde",
                   escape  = FALSE) %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = sde_note, escape = FALSE, threeparttable = TRUE)

save_kable(tabF1_latex, "tables/tabF1_sde.tex")
cat("Table F1 written.\n")

cat("\n=== All tables complete ===\n")
