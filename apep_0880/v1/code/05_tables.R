## 05_tables.R — Generate all LaTeX tables for paper
## APEP paper apep_0880

source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ===============================================================
# Table 1: Summary Statistics
# ===============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

sumstats <- panel %>%
  summarize(
    across(c(hhi, top_share, n_sources, total_value, pre_hhi),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  )

# Format summary stats table
tab1 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Summary Statistics: CRMA Mineral Import Concentration}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & Std.~Dev. & Min & Max \\\\
\\midrule
HHI (import concentration) & %.3f & %.3f & %.3f & %.3f \\\\
Top-country share & %.3f & %.3f & %.3f & %.3f \\\\
Number of sources ($>$1\\%%) & %.1f & %.1f & %.0f & %.0f \\\\
Pre-CRMA HHI (2022) & %.3f & %.3f & %.3f & %.3f \\\\
Total import value (USD M) & %.1f & %.1f & %.1f & %.1f \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel B: By Concentration Group}} \\\\
\\midrule
High ($>$65\\%%) & \\multicolumn{4}{c}{N = %d mineral-years (pre-CRMA top share $>$ 0.65)} \\\\
Medium (50--65\\%%) & \\multicolumn{4}{c}{N = %d mineral-years} \\\\
Low ($<$50\\%%) & \\multicolumn{4}{c}{N = %d mineral-years} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = %d mineral-year observations across %d minerals and %d years (2018--2024). HHI is the Herfindahl--Hirschman Index of import source concentration, calculated from bilateral trade values as $\\sum_i s_i^2$ where $s_i$ is country $i$'s share of EU imports. Top-country share is the largest single-country import share. Number of sources counts partner countries with $>$1\\%% of EU imports.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  sumstats$hhi_mean, sumstats$hhi_sd, sumstats$hhi_min, sumstats$hhi_max,
  sumstats$top_share_mean, sumstats$top_share_sd, sumstats$top_share_min, sumstats$top_share_max,
  sumstats$n_sources_mean, sumstats$n_sources_sd, sumstats$n_sources_min, sumstats$n_sources_max,
  sumstats$pre_hhi_mean, sumstats$pre_hhi_sd, sumstats$pre_hhi_min, sumstats$pre_hhi_max,
  sumstats$total_value_mean / 1e6, sumstats$total_value_sd / 1e6,
  sumstats$total_value_min / 1e6, sumstats$total_value_max / 1e6,
  sum(panel$concentration_bin == "High (>65%)"),
  sum(panel$concentration_bin == "Medium (50-65%)"),
  sum(panel$concentration_bin == "Low (<50%)"),
  nrow(panel), n_distinct(panel$mineral), n_distinct(panel$year)
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Written tab1_summary.tex\n")

# ===============================================================
# Table 2: Main DiD Results
# ===============================================================
cat("\n--- Table 2: Main Results ---\n")

m1 <- results$m1_continuous
m2 <- results$m2_binary
m3a <- results$m3a_topshare
m3b <- results$m3b_nsources

# Extract coefficients
get_coef <- function(fit, varname) {
  idx <- grep(varname, names(coef(fit)), fixed = TRUE)
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA))
  list(
    b = coef(fit)[idx],
    se = se(fit)[idx],
    p = fixest::pvalue(fit)[idx]
  )
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

c1 <- get_coef(m1, "treat_continuous")
c2 <- get_coef(m2, "treat_binary")
c3a <- get_coef(m3a, "treat_continuous")
c3b <- get_coef(m3b, "treat_continuous")

tab2 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Effect of CRMA on Import Source Diversification}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
& HHI & HHI & Top Share & N Sources \\\\
\\midrule
PreHHI $\\times$ Post & %.4f%s & & %.4f%s & %.3f%s \\\\
& (%.4f) & & (%.4f) & (%.3f) \\\\[6pt]
High ($>$65\\%%) $\\times$ Post & & %.4f%s & & \\\\
& & (%.4f) & & \\\\[6pt]
\\midrule
Mineral FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Observations & %d & %d & %d & %d \\\\
R$^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\
Minerals & %d & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the mineral level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1) reports the continuous-treatment DiD: the interaction of pre-CRMA HHI (2022) with a post-proposal indicator (2023--2024). A negative coefficient means minerals with higher pre-CRMA concentration experienced larger HHI declines. Column (2) uses a binary treatment indicator for minerals above the 65\\%% statutory threshold. Columns (3) and (4) use alternative outcomes. All specifications include mineral and year fixed effects.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  c1$b, stars(c1$p), c3a$b, stars(c3a$p), c3b$b, stars(c3b$p),
  c1$se, c3a$se, c3b$se,
  c2$b, stars(c2$p),
  c2$se,
  nobs(m1), nobs(m2), nobs(m3a), nobs(m3b),
  fitstat(m1, "wr2")$wr2, fitstat(m2, "wr2")$wr2, fitstat(m3a, "wr2")$wr2, fitstat(m3b, "wr2")$wr2,
  n_distinct(panel$mineral), n_distinct(panel$mineral),
  n_distinct(panel$mineral), n_distinct(panel$mineral)
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Written tab2_main.tex\n")

# ===============================================================
# Table 3: Event Study Coefficients
# ===============================================================
cat("\n--- Table 3: Event Study ---\n")

m5 <- results$m5_event
event_vars <- c("yr_2018", "yr_2019", "yr_2020", "yr_2022", "yr_2023", "yr_2024")
event_labels <- c("2018 (t-5)", "2019 (t-4)", "2020 (t-3)", "2022 (t-1)", "2023 (t+1)", "2024 (t+2)")

rows <- ""
for (j in seq_along(event_vars)) {
  v <- event_vars[j]
  if (v %in% names(coef(m5))) {
    b <- coef(m5)[v]
    s <- se(m5)[v]
    p <- fixest::pvalue(m5)[v]
    rows <- paste0(rows, sprintf("%s & %.4f%s \\\\\n& (%.4f) \\\\[3pt]\n",
                                  event_labels[j], b, stars(p), s))
  } else {
    rows <- paste0(rows, sprintf("%s & --- \\\\\n& --- \\\\[3pt]\n", event_labels[j]))
  }
}

tab3 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Event Study: Pre-CRMA HHI $\\times$ Year Interactions}
\\label{tab:event}
\\begin{threeparttable}
\\begin{tabular}{lc}
\\toprule
Year (relative to 2021) & HHI \\\\
\\midrule
%s
\\midrule
Omitted: 2021 (t-2) & --- \\\\
Mineral FE & Yes \\\\
Year FE & Yes \\\\
Observations & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each coefficient is the interaction of pre-CRMA HHI (2022 level) with a year indicator. The reference year is 2021 (two years before CRMA proposal). Standard errors clustered at the mineral level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Pre-treatment coefficients near zero support parallel trends.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}", rows, nobs(m5))

writeLines(tab3, "../tables/tab3_event.tex")
cat("Written tab3_event.tex\n")

# ===============================================================
# Table 4: Dual-Shock Decomposition
# ===============================================================
cat("\n--- Table 4: Dual-Shock ---\n")

m4 <- results$m4_china
m4_names <- names(coef(m4))

tab4 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Demand-Pull vs.~Supply-Push: CRMA and China Export Controls}
\\label{tab:china}
\\begin{threeparttable}
\\begin{tabular}{lc}
\\toprule
& HHI \\\\
\\midrule")

for (nm in m4_names) {
  b <- coef(m4)[nm]
  s <- se(m4)[nm]
  p <- fixest::pvalue(m4)[nm]
  label <- gsub("_", "\\\\_", nm)
  label <- gsub(":", " $\\\\times$ ", label)
  tab4 <- paste0(tab4, sprintf("\n%s & %.4f%s \\\\", label, b, stars(p)))
  tab4 <- paste0(tab4, sprintf("\n& (%.4f) \\\\[3pt]", s))
}

tab4 <- paste0(tab4, sprintf("\n\\midrule
Mineral FE & Yes \\\\
Year FE & Yes \\\\
Observations & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Decomposes the diversification effect into CRMA demand-pull (pre-HHI $\\times$ post) and China supply-push (China-dependent $\\times$ post). The triple interaction captures whether China-dependent minerals diversified differentially. Standard errors clustered at the mineral level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}", nobs(m4)))

writeLines(tab4, "../tables/tab4_china.tex")
cat("Written tab4_china.tex\n")

# ===============================================================
# Table 5: Robustness
# ===============================================================
cat("\n--- Table 5: Robustness ---\n")

r1 <- rob_results$r1_no_medium
r2 <- rob_results$r2_no_rareearth
r3 <- rob_results$r3_post_force
r4 <- rob_results$r4_placebo
r5 <- rob_results$r5_topshare
r6 <- rob_results$r6_weighted

rob_specs <- list(
  list(name = "Baseline", fit = results$m1_continuous, var = "treat_continuous"),
  list(name = "Drop 50--65\\% band", fit = r1, var = "treat_continuous"),
  list(name = "Drop rare earths", fit = r2, var = "treat_continuous"),
  list(name = "Post = 2024+ (force)", fit = r3, var = "treat_force"),
  list(name = "Placebo (2020)", fit = r4, var = "placebo_treat"),
  list(name = "Value-weighted", fit = r6, var = "treat_continuous")
)

rob_rows <- ""
for (spec in rob_specs) {
  b <- coef(spec$fit)[spec$var]
  s <- se(spec$fit)[spec$var]
  p <- fixest::pvalue(spec$fit)[spec$var]
  rob_rows <- paste0(rob_rows, sprintf("%s & %.4f%s & (%.4f) & %d \\\\\n",
                                        spec$name, b, stars(p), s, nobs(spec$fit)))
}

tab5 <- sprintf("\\begin{table}[H]
\\centering
\\caption{Robustness: Alternative Specifications}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
Specification & Coefficient & SE & N \\\\
\\midrule
%s\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications include mineral and year fixed effects with standard errors clustered at the mineral level. The dependent variable is HHI (import source concentration). The coefficient is the interaction of pre-CRMA concentration with the post indicator. ``Placebo (2020)'' restricts to pre-CRMA years and uses 2020 as a fake treatment date. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}", rob_rows)

writeLines(tab5, "../tables/tab5_robustness.tex")
cat("Written tab5_robustness.tex\n")

# ===============================================================
# SDE Table (Appendix F)
# ===============================================================
cat("\n--- SDE Table ---\n")

# Main outcome: HHI
m1_fit <- results$m1_continuous
beta_hhi <- coef(m1_fit)["treat_continuous"]
se_hhi <- se(m1_fit)["treat_continuous"]
sd_y_hhi <- sd(panel$hhi, na.rm = TRUE)
sd_x_hhi <- sd(panel$pre_hhi * panel$post_crma, na.rm = TRUE)

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_hhi <- beta_hhi * sd_x_hhi / sd_y_hhi
se_sde_hhi <- se_hhi * sd_x_hhi / sd_y_hhi

# Top share outcome
m3a_fit <- results$m3a_topshare
beta_ts <- coef(m3a_fit)["treat_continuous"]
se_ts <- se(m3a_fit)["treat_continuous"]
sd_y_ts <- sd(panel$top_share, na.rm = TRUE)
sde_ts <- beta_ts * sd_x_hhi / sd_y_ts
se_sde_ts <- se_ts * sd_x_hhi / sd_y_ts

# N sources outcome
m3b_fit <- results$m3b_nsources
beta_ns <- coef(m3b_fit)["treat_continuous"]
se_ns <- se(m3b_fit)["treat_continuous"]
sd_y_ns <- sd(panel$n_sources, na.rm = TRUE)
sde_ns <- beta_ns * sd_x_hhi / sd_y_ns
se_sde_ns <- se_ns * sd_x_hhi / sd_y_ns

# Classification function
classify <- function(s) {
  case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Heterogeneous: China-dependent vs not
panel_china <- panel %>% filter(china_dep == 1)
panel_nochina <- panel %>% filter(china_dep == 0)

fit_china <- feols(hhi ~ treat_continuous | hs_code + year,
                   data = panel_china, cluster = ~hs_code)
fit_nochina <- feols(hhi ~ treat_continuous | hs_code + year,
                     data = panel_nochina, cluster = ~hs_code)

beta_ch <- coef(fit_china)["treat_continuous"]
se_ch <- se(fit_china)["treat_continuous"]
sd_y_ch <- sd(panel_china$hhi, na.rm = TRUE)
sd_x_ch <- sd(panel_china$pre_hhi * panel_china$post_crma, na.rm = TRUE)
sde_ch <- beta_ch * sd_x_ch / sd_y_ch
se_sde_ch <- se_ch * sd_x_ch / sd_y_ch

beta_nc <- coef(fit_nochina)["treat_continuous"]
se_nc <- se(fit_nochina)["treat_continuous"]
sd_y_nc <- sd(panel_nochina$hhi, na.rm = TRUE)
sd_x_nc <- sd(panel_nochina$pre_hhi * panel_nochina$post_crma, na.rm = TRUE)
sde_nc <- beta_nc * sd_x_nc / sd_y_nc
se_sde_nc <- se_nc * sd_x_nc / sd_y_nc

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (EU-27). ",
  "\\textbf{Research question:} Whether the EU Critical Raw Materials Act (2024/1252), ",
  "which imposes a 65\\% single-country import concentration ceiling for strategic minerals, ",
  "caused more-concentrated minerals to diversify their import sources. ",
  "\\textbf{Policy mechanism:} The CRMA mandates that no single third country may supply ",
  "more than 65\\% of EU consumption for 17 strategic minerals by 2030, creating regulatory ",
  "pressure on firms to find alternative suppliers for heavily concentrated materials. ",
  "\\textbf{Outcome definition:} Herfindahl--Hirschman Index (HHI) of import source concentration, ",
  "calculated from bilateral trade values as $\\sum_i s_i^2$ where $s_i$ is a partner country's share. ",
  "\\textbf{Treatment:} Continuous --- pre-CRMA (2022) HHI interacted with post-proposal indicator (2023--2024). ",
  "\\textbf{Data:} UN Comtrade bilateral trade flows (HS4--HS6), 2018--2024 annual, EU-27 imports from all partners. ",
  "\\textbf{Method:} Continuous-treatment DiD with mineral and year fixed effects, mineral-clustered standard errors. ",
  "\\textbf{Sample:} 20 mineral commodities (16 CRMA strategic + 4 controls) across 7 years. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the ",
  "treatment variable and SD($Y$) is the pre-treatment standard deviation of HHI. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_table <- sprintf("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
HHI & %.4f & %.3f & %.3f & %.3f & %.3f & %s \\\\
Top-country share & %.4f & %.3f & %.3f & %.3f & %.3f & %s \\\\
N sources ($>$1\\%%) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (China-dependent vs.~not)}} \\\\
HHI (China-dep.) & %.4f & %.3f & %.3f & %.3f & %.3f & %s \\\\
HHI (Non-China) & %.4f & %.3f & %.3f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
  beta_hhi, sd_x_hhi, sd_y_hhi, sde_hhi, se_sde_hhi, classify(sde_hhi),
  beta_ts, sd_x_hhi, sd_y_ts, sde_ts, se_sde_ts, classify(sde_ts),
  beta_ns, sd_x_hhi, sd_y_ns, sde_ns, se_sde_ns, classify(sde_ns),
  beta_ch, sd_x_ch, sd_y_ch, sde_ch, se_sde_ch, classify(sde_ch),
  beta_nc, sd_x_nc, sd_y_nc, sde_nc, se_sde_nc, classify(sde_nc),
  sde_notes
)

writeLines(sde_table, "../tables/tabF1_sde.tex")
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
