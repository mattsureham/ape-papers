## 05_tables.R — Generate all tables for the paper (booktabs format)
## apep_0862: Civilian Service Expansion and Healthcare Employment in Switzerland

source("00_packages.R")

df <- read_csv("../data/analysis_besta.csv", show_col_types = FALSE)
zivi_adm <- read_csv("../data/zivi_admissions.csv", show_col_types = FALSE)
zivi_days <- read_csv("../data/zivi_service_days.csv", show_col_types = FALSE)
robustness <- readRDS("../data/robustness_models.rds")

# Create standard variables
df <- df |>
  mutate(
    did = as.numeric(treated & post),
    rel_year = year - 2009,
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4L,
      rel_year >= 5 ~ 5L,
      TRUE ~ as.integer(rel_year)
    ),
    sector_id = as.integer(factor(sector)),
    period = case_when(
      !post ~ "pre",
      year >= 2009 & year <= 2010 ~ "early_post",
      year >= 2011 ~ "late_post"
    ),
    did_early = as.numeric(treated & period == "early_post"),
    did_late = as.numeric(treated & period == "late_post")
  )

stars_fn <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

# ==============================================================================
# Table 1: ZIVI Reform Summary
# ==============================================================================
cat("=== Generating Table 1: Reform Summary ===\n")

tab1_days <- zivi_days |>
  filter(year >= 2005, year <= 2015) |>
  mutate(health_social_days = round(total_days * 0.664),
         health_social_fte = round(health_social_days / 220))

sink("../tables/tab1_reform.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{The 2009 Tatbeweis Reform: Civilian Service Expansion}\n")
cat("\\label{tab:reform}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat(" & Admissions & Total Days & Health/Social FTE \\\\\n\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Pre-Reform}} \\\\\n")
for (yr in 2005:2008) {
  row <- tab1_days |> filter(year == yr)
  adm <- zivi_adm |> filter(year == yr)
  cat(sprintf("%d & %s & %s & %s \\\\\n", yr,
              formatC(adm$admissions, format = "d", big.mark = ","),
              formatC(row$total_days, format = "d", big.mark = ","),
              formatC(row$health_social_fte, format = "d", big.mark = ",")))
}
cat("\\midrule\n\\multicolumn{4}{l}{\\textit{Panel B: Post-Reform}} \\\\\n")
for (yr in 2009:2015) {
  row <- tab1_days |> filter(year == yr)
  adm <- zivi_adm |> filter(year == yr)
  cat(sprintf("%d & %s & %s & %s \\\\\n", yr,
              formatC(adm$admissions, format = "d", big.mark = ","),
              formatC(row$total_days, format = "d", big.mark = ","),
              formatC(row$health_social_fte, format = "d", big.mark = ",")))
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Data from ZIVI annual reports (T\\\"atigkeitsbericht). ")
cat("Admissions are new entrants per year. Total Days are service days performed. ")
cat("Health/Social FTE assumes 66.4\\% sector share and 220 working days per year. ")
cat("The Tatbeweis reform took effect April 1, 2009.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 1 saved.\n")

# ==============================================================================
# Table 2: Summary Statistics
# ==============================================================================
cat("=== Generating Table 2: Summary Statistics ===\n")

sumstats <- df |>
  group_by(treated, post) |>
  summarise(n = n(), mean_fte = mean(emp_fte, na.rm = TRUE),
            sd_fte = sd(emp_fte, na.rm = TRUE), .groups = "drop") |>
  mutate(group = ifelse(treated, "Health/Social (Treated)", "Other Services (Control)"),
         period = ifelse(post, "Post-Reform", "Pre-Reform"))

sink("../tables/tab2_sumstats.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics: Quarterly Employment by Sector Group}\n")
cat("\\label{tab:sumstats}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{llccc}\n\\toprule\n")
cat("Group & Period & Obs & Mean FTE & SD \\\\\n\\midrule\n")
for (i in seq_len(nrow(sumstats))) {
  r <- sumstats[i, ]
  cat(sprintf("%s & %s & %d & %s & %s \\\\\n",
              r$group, r$period, r$n,
              formatC(round(r$mean_fte), format = "d", big.mark = ","),
              formatC(round(r$sd_fte), format = "d", big.mark = ",")))
}
cat("\\midrule\n\\multicolumn{5}{l}{\\textit{Treatment sectors (pre-reform mean FTE):}} \\\\\n")
sect_means <- df |> filter(treated, !post) |>
  group_by(sector, sector_label) |>
  summarise(mean_fte = mean(emp_fte, na.rm = TRUE), .groups = "drop")
for (i in seq_len(nrow(sect_means))) {
  cat(sprintf("\\quad %s & & & %s & \\\\\n",
              sect_means$sector_label[i],
              formatC(round(sect_means$mean_fte[i]), format = "d", big.mark = ",")))
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} BFS BESTA quarterly employment statistics (2003Q1--2016Q4). ")
cat("Treatment: NOGA 86 (Health), 87 (Residential care), 88 (Social work). ")
cat("Control: NOGA 47, 55--56, 68, 69--75, 77--82, 84, 85, 90--93, 94--96. ")
cat("FTE = Vollzeit\\\"aquivalente.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 2 saved.\n")

# ==============================================================================
# Table 3: Main DiD Results (manual booktabs)
# ==============================================================================
cat("=== Generating Table 3: Main Results ===\n")

m1 <- feols(log_emp_fte ~ did | sector + quarter, data = df, cluster = "sector")
m2 <- feols(log_emp_fte ~ did | sector + quarter + sector[time_idx],
            data = df, cluster = "sector")
m3 <- feols(log_emp_total ~ did | sector + quarter, data = df, cluster = "sector")
m4 <- feols(log_emp_fte ~ did | sector + quarter,
            data = df |> filter(sector %in% c("86","87","88","85","84")), cluster = "sector")
m5 <- feols(log_emp_fte ~ did_early + did_late | sector + quarter,
            data = df, cluster = "sector")

sink("../tables/tab3_main.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Effect of Civilian Service Expansion on Sectoral Employment}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccccc}\n\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & Baseline & Trends & Headcount & Narrow & Split \\\\\n\\midrule\n")
# Row 1: Treated x Post
cat(sprintf("Treated $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & \\\\\n",
    coef(m1)["did"], stars_fn(pvalue(m1)["did"]),
    coef(m2)["did"], stars_fn(pvalue(m2)["did"]),
    coef(m3)["did"], stars_fn(pvalue(m3)["did"]),
    coef(m4)["did"], stars_fn(pvalue(m4)["did"])))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & \\\\\n",
    se(m1)["did"], se(m2)["did"], se(m3)["did"], se(m4)["did"]))
# Row 2: Early post
cat(sprintf("Treated $\\times$ Early Post & & & & & %.3f%s \\\\\n",
    coef(m5)["did_early"], stars_fn(pvalue(m5)["did_early"])))
cat(sprintf(" & & & & & (%.3f) \\\\\n", se(m5)["did_early"]))
# Row 3: Late post
cat(sprintf("Treated $\\times$ Late Post & & & & & %.3f%s \\\\\n",
    coef(m5)["did_late"], stars_fn(pvalue(m5)["did_late"])))
cat(sprintf(" & & & & & (%.3f) \\\\\n", se(m5)["did_late"]))
cat("\\midrule\n")
cat(sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
    nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5)))
cat("Sector FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Sector trends & No & Yes & No & No & No \\\\\n")
cat(sprintf("Within $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
    fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
    fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]], fitstat(m5, "wr2")[[1]]))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Clustered standard errors (sector) in parentheses. ")
cat("Treatment: NOGA 86, 87, 88. (1) Baseline. (2) Sector-specific linear trends. ")
cat("(3) Headcount instead of FTE. (4) Narrow controls: education + public admin only. ")
cat("(5) Post-period split at 2011. ")
cat("$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 3 saved.\n")

# ==============================================================================
# Table 4: Event Study
# ==============================================================================
cat("=== Generating Table 4: Event Study ===\n")

m_es <- feols(log_emp_fte ~ i(rel_year_binned, treated, ref = -1) | sector + quarter,
              data = df, cluster = "sector")
es_ct <- as.data.frame(coeftable(m_es))
es_ct$rel_year <- as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_ct)))
es_ct <- es_ct |> arrange(rel_year)

sink("../tables/tab4_eventstudy.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Event Study: Relative-Year Coefficients}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n\\toprule\n")
cat("Years Relative to Reform & Coefficient & SE \\\\\n\\midrule\n")
for (i in seq_len(nrow(es_ct))) {
  yr <- es_ct$rel_year[i]
  yr_lab <- ifelse(yr <= -4, "$\\leq -4$",
            ifelse(yr >= 5, "$\\geq 5$", as.character(yr)))
  cat(sprintf("%s & %.4f%s & (%.4f) \\\\\n",
              yr_lab, es_ct[i,1], stars_fn(es_ct[i,4]), es_ct[i,2]))
}
cat("$-1$ (ref.) & --- & --- \\\\\n")
cat("\\midrule\n")
cat(sprintf("Observations & \\multicolumn{2}{c}{%d} \\\\\n", nobs(m_es)))
cat("Sector FE & \\multicolumn{2}{c}{Yes} \\\\\n")
cat("Quarter FE & \\multicolumn{2}{c}{Yes} \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Event study from equation (\\ref{eq:eventstudy}). ")
cat("Reference: $k=-1$ (2008). Endpoints binned at $k\\leq -4$ and $k\\geq 5$. ")
cat("Clustered SEs (sector) in parentheses. ")
cat("$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 4 saved.\n")

# ==============================================================================
# Table 5: Robustness
# ==============================================================================
cat("=== Generating Table 5: Robustness ===\n")

perm_coefs <- robustness$perm_coefs
actual_coef <- coef(m1)["did"]
ri_p <- mean(abs(perm_coefs) >= abs(actual_coef))
m_placebo <- robustness$m_placebo
loo <- robustness$loo_results

sink("../tables/tab5_robustness.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Robustness and Inference}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n\\toprule\n")
cat("Specification & Coefficient & $p$-value \\\\\n\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Main Specifications}} \\\\\n")
cat(sprintf("Baseline & %.3f%s & [%.3f] \\\\\n",
    coef(m1)["did"], stars_fn(pvalue(m1)["did"]), pvalue(m1)["did"]))
cat(sprintf(" & (%.3f) & \\\\\n", se(m1)["did"]))
cat(sprintf("Sector-specific trends & %.3f & [%.3f] \\\\\n",
    coef(m2)["did"], pvalue(m2)["did"]))
cat(sprintf(" & (%.3f) & \\\\\n", se(m2)["did"]))
cat(sprintf("Headcount & %.3f%s & [%.3f] \\\\\n",
    coef(m3)["did"], stars_fn(pvalue(m3)["did"]), pvalue(m3)["did"]))
cat(sprintf(" & (%.3f) & \\\\\n", se(m3)["did"]))
cat("\\midrule\n\\multicolumn{3}{l}{\\textit{Panel B: Inference}} \\\\\n")
cat(sprintf("Permutation ($N=2{,}000$) & %.3f & [%.3f] \\\\\n", actual_coef, ri_p))
cat(sprintf("Placebo (2006) & %.3f & [%.3f] \\\\\n",
    coef(m_placebo)["fake_did"], pvalue(m_placebo)["fake_did"]))
cat("\\midrule\n\\multicolumn{3}{l}{\\textit{Panel C: Leave-One-Out}} \\\\\n")
cat(sprintf("Range & [%.3f, %.3f] & \\\\\n", min(loo$coef), max(loo$coef)))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Panel A: clustered SEs (sector) in parentheses. ")
cat("Panel B: permutation assigns treatment to 3 of 12 sectors (2,000 draws); ")
cat("placebo uses pre-reform data (2003--2008) with fake reform in 2006. ")
cat("Panel C: re-estimate dropping each sector.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 5 saved.\n")

# ==============================================================================
# SDE Table (MANDATORY)
# ==============================================================================
cat("=== Generating SDE Table ===\n")

pre_sd_fte <- df |> filter(!post) |> pull(log_emp_fte) |> sd(na.rm = TRUE)
pre_sd_total <- df |> filter(!post) |> pull(log_emp_total) |> sd(na.rm = TRUE)

b1 <- coef(m1)["did"]; s1 <- se(m1)["did"]
b3 <- coef(m3)["did"]; s3 <- se(m3)["did"]
be <- coef(m5)["did_early"]; se_e <- se(m5)["did_early"]
bl <- coef(m5)["did_late"]; se_l <- se(m5)["did_late"]

sde1 <- b1/pre_sd_fte; se_sde1 <- s1/pre_sd_fte
sde3 <- b3/pre_sd_total; se_sde3 <- s3/pre_sd_total
sde_e <- be/pre_sd_fte; se_sde_e <- se_e/pre_sd_fte
sde_l <- bl/pre_sd_fte; se_sde_l <- se_l/pre_sd_fte

classify <- function(s) {
  a <- abs(s)
  if (a < 0.005) return("Null")
  if (a < 0.05) return(ifelse(s>0,"Small positive","Small negative"))
  if (a < 0.15) return(ifelse(s>0,"Moderate positive","Moderate negative"))
  return(ifelse(s>0,"Large positive","Large negative"))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Did the 2009 abolition of the conscience test for civilian service, which quadrupled admissions and flooded health and social care sectors with near-free labor, crowd out or complement paid employment? ",
  "\\textbf{Policy mechanism:} The Tatbeweis reform replaced the conscience examination with a simple willingness requirement for civilian service, causing admissions to surge from under two thousand to nearly seven thousand in one year; two-thirds of service days are deployed to health and social care facilities at zero marginal wage cost to employers. ",
  "\\textbf{Outcome definition:} Log full-time equivalent employment (Vollzeit\\\"aquivalente) by NOGA 2-digit sector, measuring paid workers in the formal labor market. ",
  "\\textbf{Treatment:} Binary; NOGA sectors 86 (health), 87 (residential care), 88 (social work) receiving civilian service deployment versus comparable service sectors that do not. ",
  "\\textbf{Data:} BFS BESTA quarterly employment statistics, 2003Q1--2016Q4, sector-quarter panel with 12 NOGA sectors and 56 quarters ($N=672$). ",
  "\\textbf{Method:} Difference-in-differences with sector and quarter fixed effects; standard errors clustered at sector level; robustness via permutation inference (2,000 draws), placebo test, and leave-one-out. ",
  "\\textbf{Sample:} All NOGA 2-digit service sectors in the BESTA quarterly series; excludes manufacturing and agriculture; treatment sectors defined by ZIVI deployment statistics. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation of log FTE across all sector-quarters. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("FTE employment & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    b1, s1, pre_sd_fte, sde1, se_sde1, classify(sde1)))
cat(sprintf("Headcount & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    b3, s3, pre_sd_total, sde3, se_sde3, classify(sde3)))
cat("\\midrule\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by timing)}} \\\\\n")
cat(sprintf("FTE, early (2009--10) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    be, se_e, pre_sd_fte, sde_e, se_sde_e, classify(sde_e)))
cat(sprintf("FTE, late (2011--16) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    bl, se_l, pre_sd_fte, sde_l, se_sde_l, classify(sde_l)))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat(sde_notes)
cat("\n\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
