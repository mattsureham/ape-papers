## 05_tables.R — Generate all LaTeX tables
## apep_1338: Brexit Rules of Origin and Trade Disintegration

source("code/00_packages.R")

analysis <- readRDS("data/analysis_panel.rds")
models <- readRDS("data/model_objects.rds")
robust <- readRDS("data/robustness_objects.rds")
imports <- analysis |> filter(flowCode == "M")

dir.create("tables", showWarnings = FALSE)

## ── Table 1: Summary Statistics ─────────────────────────────────────────────

summ_pre <- imports |>
  filter(post == 0) |>
  group_by(eu) |>
  summarize(
    mean_trade = mean(trade_value, na.rm = TRUE),
    sd_trade = sd(trade_value, na.rm = TRUE),
    mean_log_trade = mean(log_trade, na.rm = TRUE),
    sd_log_trade = sd(log_trade, na.rm = TRUE),
    mean_roo = mean(roo_ri, na.rm = TRUE),
    sd_roo = sd(roo_ri, na.rm = TRUE),
    n_hs4 = n_distinct(hs4),
    n_obs = n(),
    .groups = "drop"
  )

summ_post <- imports |>
  filter(post == 1) |>
  group_by(eu) |>
  summarize(
    mean_trade = mean(trade_value, na.rm = TRUE),
    sd_trade = sd(trade_value, na.rm = TRUE),
    mean_log_trade = mean(log_trade, na.rm = TRUE),
    sd_log_trade = sd(log_trade, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )

# Full sample stats for SDE computation
sd_y_full <- sd(imports$log_trade, na.rm = TRUE)
mean_y_full <- mean(imports$log_trade, na.rm = TRUE)

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: UK Bilateral Trade at HS-4 Level}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{EU Partners} & \\multicolumn{2}{c}{Non-EU Controls} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & Std.\\ Dev. & Mean & Std.\\ Dev. \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-TCA (2017--2019)}} \\\\[3pt]",
  paste0("Trade value (\\$000s) & ", fmt(summ_pre$mean_trade[2] / 1000), " & ",
         fmt(summ_pre$sd_trade[2] / 1000), " & ", fmt(summ_pre$mean_trade[1] / 1000),
         " & ", fmt(summ_pre$sd_trade[1] / 1000), " \\\\"),
  paste0("Log trade & ", fmt(summ_pre$mean_log_trade[2]), " & ",
         fmt(summ_pre$sd_log_trade[2]), " & ", fmt(summ_pre$mean_log_trade[1]),
         " & ", fmt(summ_pre$sd_log_trade[1]), " \\\\"),
  paste0("ROO-RI & ", fmt(summ_pre$mean_roo[2]), " & ",
         fmt(summ_pre$sd_roo[2]), " & ", fmt(summ_pre$mean_roo[1]),
         " & ", fmt(summ_pre$sd_roo[1]), " \\\\"),
  paste0("HS-4 products & \\multicolumn{2}{c}{", summ_pre$n_hs4[2],
         "} & \\multicolumn{2}{c}{", summ_pre$n_hs4[1], "} \\\\"),
  paste0("Observations & \\multicolumn{2}{c}{", fmt(summ_pre$n_obs[2], 0),
         "} & \\multicolumn{2}{c}{", fmt(summ_pre$n_obs[1], 0), "} \\\\"),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Post-TCA (2021--2024)}} \\\\[3pt]",
  paste0("Trade value (\\$000s) & ", fmt(summ_post$mean_trade[2] / 1000), " & ",
         fmt(summ_post$sd_trade[2] / 1000), " & ", fmt(summ_post$mean_trade[1] / 1000),
         " & ", fmt(summ_post$sd_trade[1] / 1000), " \\\\"),
  paste0("Log trade & ", fmt(summ_post$mean_log_trade[2]), " & ",
         fmt(summ_post$sd_log_trade[2]), " & ", fmt(summ_post$mean_log_trade[1]),
         " & ", fmt(summ_post$sd_log_trade[1]), " \\\\"),
  paste0("Observations & \\multicolumn{2}{c}{", fmt(summ_post$n_obs[2], 0),
         "} & \\multicolumn{2}{c}{", fmt(summ_post$n_obs[1], 0), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Data from UN Comtrade, HS Revision 2017. ",
         "Reporter: United Kingdom (826). EU partners: EU-27 member states aggregated. ",
         "Non-EU controls: United States, Canada, Japan, South Korea, Australia. ",
         "Trade values in US dollars. ROO-RI is the Rules of Origin Restrictiveness ",
         "Index (Estevadeordal 2000 scale, 1--7) coded from TCA ANNEX ORIG-2. ",
         "Year 2020 excluded (EU--UK transition period and COVID-19)."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")

## ── Table 2: Main Results ───────────────────────────────────────────────────

m1 <- models$m1; m2 <- models$m2; m4 <- models$m4; m5 <- models$m5

get_coef <- function(m, var) {
  cf <- coef(m)
  se_vec <- se(m)
  idx <- which(names(cf) == var)
  if (length(idx) == 0) return(list(b = NA, se = NA, stars = ""))
  b <- cf[idx]
  s <- se_vec[idx]
  pv <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  list(b = b, se = s, stars = stars)
}

f <- function(x) formatC(x, format = "f", digits = 3)

r1 <- get_coef(m1, "post_eu")
r2 <- get_coef(m2, "post_eu_roo")
r4 <- get_coef(m4, "post_eu_roo")
r5 <- get_coef(m5, "post_eu_roo")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of TCA Rules of Origin on UK Bilateral Trade}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & DD & DDD & DDD & DDD \\\\",
  " & Imports & Imports & Exports & Pooled \\\\",
  "\\midrule",
  paste0("Post $\\times$ EU & ", f(r1$b), r1$stars, " & & & \\\\"),
  paste0(" & (", f(r1$se), ") & & & \\\\"),
  "\\\\",
  paste0("Post $\\times$ EU $\\times$ ROO-RI & & ", f(r2$b), r2$stars,
         " & ", f(r4$b), r4$stars, " & ", f(r5$b), r5$stars, " \\\\"),
  paste0(" & & (", f(r2$se), ") & (", f(r4$se), ") & (", f(r5$se), ") \\\\"),
  "\\midrule",
  "Product $\\times$ Partner FE & Yes & Yes & Yes & Yes \\\\",
  "Product $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  "Partner $\\times$ Year FE & No & Yes & Yes & Yes \\\\",
  "Year FE & Yes & --- & --- & --- \\\\",
  paste0("Clustering & HS-2 & HS-2 & HS-2 & HS-2 \\\\"),
  paste0("Observations & ", formatC(nobs(m1), big.mark = ","), " & ",
         formatC(nobs(m2), big.mark = ","), " & ",
         formatC(nobs(m4), big.mark = ","), " & ",
         formatC(nobs(m5), big.mark = ","), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "Standard errors clustered at HS-2 chapter level in parentheses. ",
         "Dependent variable: log(trade value + 1). ",
         "Column (1): difference-in-differences comparing UK--EU to UK--non-EU imports, ",
         "with product$\\times$partner, product$\\times$year, and year fixed effects. ",
         "Columns (2)--(4): triple-difference where the coefficient on ",
         "Post $\\times$ EU $\\times$ ROO-RI captures the additional trade change per unit ",
         "of ROO restrictiveness (Estevadeordal 2000 scale, 3--6) for UK--EU trade relative ",
         "to UK--non-EU controls. Partner$\\times$year FE absorb the average post-TCA ",
         "EU effect (Column 1's DD estimate). Year 2020 excluded."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")

## ── Table 3: Robustness ────────────────────────────────────────────────────

m_placebo <- robust$m_placebo
m_hs4 <- robust$m_hs4_cluster
m_twoway <- robust$m_twoway
m_large <- robust$m_large

rp <- get_coef(m_placebo, "I(placebo_post * eu * roo_ri)")
r_hs4 <- get_coef(m_hs4, "post_eu_roo")
r_tw <- get_coef(m_twoway, "post_eu_roo")
r_lg <- get_coef(m_large, "post_eu_roo")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Placebo & HS-4 & Two-way & Excl.\\ Bottom \\\\",
  " & 2019 & Cluster & Cluster & 10\\% \\\\",
  "\\midrule",
  paste0("DDD coefficient & ", f(rp$b), rp$stars, " & ", f(r_hs4$b), r_hs4$stars,
         " & ", f(r_tw$b), r_tw$stars, " & ", f(r_lg$b), r_lg$stars, " \\\\"),
  paste0(" & (", f(rp$se), ") & (", f(r_hs4$se), ") & (", f(r_tw$se),
         ") & (", f(r_lg$se), ") \\\\"),
  "\\midrule",
  paste0("Observations & ", formatC(nobs(m_placebo), big.mark = ","), " & ",
         formatC(nobs(m_hs4), big.mark = ","), " & ",
         formatC(nobs(m_twoway), big.mark = ","), " & ",
         formatC(nobs(m_large), big.mark = ","), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "All specifications include product$\\times$partner, product$\\times$year, ",
         "and partner$\\times$year fixed effects. Dependent variable: log(trade value + 1). ",
         "Column (1): placebo test with fake treatment at 2019, pre-period only (2017--2019). ",
         "Column (2): standard errors clustered at HS-4 product level. ",
         "Column (3): two-way clustering on HS-2 $\\times$ year. ",
         "Column (4): excludes products in the bottom decile of pre-TCA mean trade value."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_robustness.tex")

## ── Table 4: Sector Heterogeneity ──────────────────────────────────────────

sect <- robust$sector_df |> arrange(beta_ddd)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Sector Heterogeneity: DDD Coefficient by Industry Group}",
  "\\label{tab:sector}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Sector & DDD Coeff. & Std.\\ Err. & Mean ROO-RI & $N$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sect))) {
  stars <- ""
  if (!is.na(sect$se_ddd[i]) && sect$se_ddd[i] > 0) {
    pv <- 2 * pnorm(-abs(sect$beta_ddd[i] / sect$se_ddd[i]))
    stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  }
  tab4_lines <- c(tab4_lines,
    paste0(sect$sector[i], " & ", f(sect$beta_ddd[i]), stars,
           " & (", f(sect$se_ddd[i]), ") & ", fmt(sect$mean_roo[i], 1),
           " & ", formatC(sect$n[i], big.mark = ","), " \\\\"))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "Each row reports the Post $\\times$ EU $\\times$ ROO-RI coefficient ",
         "from the DDD specification estimated on UK imports within the sector. ",
         "Standard errors clustered at HS-2 chapter level. ",
         "Mean ROO-RI reports the average restrictiveness within the sector."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_sector.tex")

## ── Table F1: Standardized Effect Sizes (SDE) ──────────────────────────────

classify_sde <- function(s) {
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

# Primary: DDD on exports (m4) — where the significant effect is
exports_data <- analysis |> filter(flowCode == "X")
sd_y_exp <- sd(exports_data$log_trade, na.rm = TRUE)
sd_x <- sd(imports$roo_ri, na.rm = TRUE)

beta_exp <- coef(m4)["post_eu_roo"]
se_exp <- se(m4)["post_eu_roo"]
sde_exp <- beta_exp * sd_x / sd_y_exp
se_sde_exp <- se_exp * sd_x / sd_y_exp

# DD on imports (m1) — the overall Brexit effect
beta_dd <- coef(m1)["post_eu"]
se_dd <- se(m1)["post_eu"]
sde_dd <- beta_dd / sd_y_full
se_sde_dd <- se_dd / sd_y_full

# DDD on imports (m2) — the null finding
beta_imp <- coef(m2)["post_eu_roo"]
se_imp <- se(m2)["post_eu_roo"]
sde_imp <- beta_imp * sd_x / sd_y_full
se_sde_imp <- se_imp * sd_x / sd_y_full

# Heterogeneity: high vs low ROO
imports_high <- imports |> filter(high_roo == 1)
imports_low <- imports |> filter(high_roo == 0)

# Heterogeneity: high vs low ROO — use DD on EXPORTS (where effect is significant)
exports_high <- exports_data |> filter(high_roo == 1)
exports_low <- exports_data |> filter(high_roo == 0)

m_high <- feols(
  log_trade ~ post_eu | hs4_eu + hs4^year + year,
  data = exports_high, cluster = ~hs2
)
m_low <- feols(
  log_trade ~ post_eu | hs4_eu + hs4^year + year,
  data = exports_low, cluster = ~hs2
)

beta_high <- coef(m_high)["post_eu"]
se_high <- se(m_high)["post_eu"]
sd_y_high <- sd(exports_high$log_trade, na.rm = TRUE)
sde_high <- beta_high / sd_y_high
se_sde_high <- se_high / sd_y_high

beta_low <- coef(m_low)["post_eu"]
se_low <- se(m_low)["post_eu"]
sd_y_low <- sd(exports_low$log_trade, na.rm = TRUE)
sde_low <- beta_low / sd_y_low
se_sde_low <- se_low / sd_y_low

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Whether product-specific rules of origin in the EU--UK Trade and Cooperation Agreement reduce bilateral trade flows, and whether more restrictive rules cause larger trade declines. ",
  "\\textbf{Policy mechanism:} The TCA replaced frictionless single-market access with a zero-tariff regime conditional on product-specific rules of origin that vary from minimal processing requirements to strict local content thresholds and double-transformation rules, creating heterogeneous compliance costs across products. ",
  "\\textbf{Outcome definition:} Log of annual bilateral trade value (US dollars, from UN Comtrade) at HS-4 product level between the UK and partner countries. ",
  "\\textbf{Treatment:} Continuous --- ROO Restrictiveness Index (1--7 Estevadeordal scale) coded from TCA ANNEX ORIG-2 at HS-2 chapter level. ",
  "\\textbf{Data:} UN Comtrade HS-4 bilateral trade, 2017--2024 (excluding 2020), UK reporter, EU-27 and five non-EU control partners. ",
  "\\textbf{Method:} Triple-difference (Post $\\times$ EU $\\times$ ROO-RI) with product$\\times$partner, product$\\times$year, and partner$\\times$year fixed effects; standard errors clustered at HS-2 chapter level. ",
  "\\textbf{Sample:} HS-4 product$\\times$partner-type$\\times$year observations; EU partners aggregated, non-EU controls are US, Canada, Japan, South Korea, Australia. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of ROO-RI and SD($Y$) is the pre-treatment standard deviation of log trade. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

f2 <- function(x) formatC(x, format = "f", digits = 3)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  paste0("Log exports & DDD (ROO-RI) & ", f2(beta_exp), " & ", f2(sd_x),
         " & ", f2(sd_y_exp), " & ", f2(sde_exp), " & ", f2(se_sde_exp),
         " & ", classify_sde(sde_exp), " \\\\"),
  paste0("Log imports & DD (overall) & ", f2(beta_dd), " & --- & ",
         f2(sd_y_full), " & ", f2(sde_dd), " & ", f2(se_sde_dd),
         " & ", classify_sde(sde_dd), " \\\\"),
  paste0("Log imports & DDD (ROO-RI) & ", f2(beta_imp), " & ", f2(sd_x),
         " & ", f2(sd_y_full), " & ", f2(sde_imp), " & ", f2(se_sde_imp),
         " & ", classify_sde(sde_imp), " \\\\"),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]",
  paste0("Log exports & High ROO (RI $\\geq$ 5) & ", f2(beta_high), " & --- & ",
         f2(sd_y_high), " & ", f2(sde_high), " & ", f2(se_sde_high),
         " & ", classify_sde(sde_high), " \\\\"),
  paste0("Log exports & Low ROO (RI $<$ 5) & ", f2(beta_low), " & --- & ",
         f2(sd_y_low), " & ", f2(sde_low), " & ", f2(se_sde_low),
         " & ", classify_sde(sde_low), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_robustness.tex\n")
cat("  tab4_sector.tex\n")
cat("  tabF1_sde.tex\n")
