## 05_tables.R — Generate all LaTeX tables

source("00_packages.R")

panel      <- readRDS("../data/panel_clean.rds")
baltic     <- readRDS("../data/baltic_clean.rds")
est_dec    <- readRDS("../data/estonia_decomp.rds")
decomp     <- readRDS("../data/decomposition.rds")
did_main   <- readRDS("../data/did_main.rds")
did_log    <- readRDS("../data/did_log.rds")
did_full   <- readRDS("../data/did_full.rds")
did_full_cov <- readRDS("../data/did_full_cov.rds")
did_event  <- readRDS("../data/did_event.rds")
placebo_df <- readRDS("../data/placebo_time.rds")
loo_df     <- readRDS("../data/loo_results.rds")
did_gdp    <- readRDS("../data/did_gdp.rds")
did_trade  <- readRDS("../data/did_trade.rds")
did_internet <- readRDS("../data/did_internet.rds")
placebo_scm  <- readRDS("../data/placebo_scm.rds")

# Try to load ASCM
ascm_summ <- tryCatch(readRDS("../data/ascm_summary.rds"), error = function(e) NULL)

outdir <- "../tables"
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# ──────────────────────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ──────────────────────────────────────────────────────────────────────────────

cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment (2006-2014) and post-treatment (2015-2022) summary
summ_fn <- function(df, period_label) {
  df %>%
    summarise(
      across(c(biz_density, biz_nreg, gdp_pc, trade_open, internet),
             list(mean = ~mean(.x, na.rm = TRUE),
                  sd = ~sd(.x, na.rm = TRUE)),
             .names = "{.col}_{.fn}"),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(period = period_label)
}

# By country group and period
baltic_pre  <- baltic %>% filter(year < 2015) %>% group_by(iso3, country) %>% summ_fn("Pre (2006-2014)")
baltic_post <- baltic %>% filter(year >= 2015) %>% group_by(iso3, country) %>% summ_fn("Post (2015-2022)")

summ_all <- bind_rows(baltic_pre, baltic_post) %>% arrange(iso3, period)

# Write LaTeX table
sink(file.path(outdir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Baltic States, Pre- and Post-e-Residency}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\footnotesize\n")
cat("\\begin{tabular}{llrrrrr}\n")
cat("\\toprule\n")
cat("Country & Period & Biz Density & Registrations & GDP p.c. & Trade (\\%GDP) & Internet (\\%) \\\\\n")
cat("\\midrule\n")

for (i in seq_len(nrow(summ_all))) {
  r <- summ_all[i, ]
  cat(sprintf("%s & %s & %.1f & %s & %s & %.1f & %.1f \\\\\n",
              r$country, r$period,
              r$biz_density_mean,
              scales::comma(round(r$biz_nreg_mean)),
              scales::comma(round(r$gdp_pc_mean)),
              r$trade_open_mean,
              r$internet_mean))
  # Add SD in parentheses
  cat(sprintf(" & & (%.1f) & (%s) & (%s) & (%.1f) & (%.1f) \\\\\n",
              r$biz_density_sd,
              scales::comma(round(r$biz_nreg_sd)),
              scales::comma(round(r$gdp_pc_sd)),
              r$trade_open_sd,
              r$internet_sd))
  if (i %% 2 == 0 && i < nrow(summ_all)) cat("\\midrule\n")
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\sloppy\n")
cat("\\scriptsize\n")
cat("\\item \\textit{Notes:} Means with standard deviations in parentheses. Business density is new registrations per 1,000 working-age population (World Bank). GDP per capita in constant 2015 USD. Pre-period: 2006--2014; post-period: 2015--2022.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ──────────────────────────────────────────────────────────────────────────────
# TABLE 2: Main DiD Results
# ──────────────────────────────────────────────────────────────────────────────

cat("Generating Table 2: Main DiD Results\n")

sink(file.path(outdir, "tab2_main_did.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of e-Residency on Business Formation}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Baltic & Baltic & Full Panel & Full Panel \\\\\n")
cat(" & Level & Log & Level & w/Covariates \\\\\n")
cat("\\midrule\n")

# Extract coefficients
b1 <- coef(did_main)["treat_post"]
s1 <- sqrt(diag(vcov(did_main)))["treat_post"]
b2 <- coef(did_log)["treat_post"]
s2 <- sqrt(diag(vcov(did_log)))["treat_post"]
b3 <- coef(did_full)["treat_post"]
s3 <- sqrt(diag(vcov(did_full)))["treat_post"]
b4 <- coef(did_full_cov)["treat_post"]
s4 <- sqrt(diag(vcov(did_full_cov)))["treat_post"]

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

p1 <- fixest::pvalue(did_main)["treat_post"]
p2 <- fixest::pvalue(did_log)["treat_post"]
p3 <- fixest::pvalue(did_full)["treat_post"]
p4 <- fixest::pvalue(did_full_cov)["treat_post"]

cat(sprintf("Estonia $\\times$ Post & %.2f%s & %.3f%s & %.2f%s & %.2f%s \\\\\n",
            b1, stars(p1), b2, stars(p2), b3, stars(p3), b4, stars(p4)))
cat(sprintf(" & (%.2f) & (%.3f) & (%.2f) & (%.2f) \\\\\n",
            s1, s2, s3, s4))
cat("\\\\[0.5em]\n")
cat(sprintf("Country FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Covariates & No & No & No & Yes \\\\\n"))

n1 <- nobs(did_main)
n2 <- nobs(did_log)
n3 <- nobs(did_full)
n4 <- nobs(did_full_cov)

cat(sprintf("Countries & 3 & 3 & %d & %d \\\\\n",
            n_distinct(panel$iso3[!is.na(panel$biz_density)]),
            n_distinct(panel$iso3[!is.na(panel$biz_density) & !is.na(panel$ln_gdp_pc)])))
cat(sprintf("N & %d & %d & %d & %d \\\\\n", n1, n2, n3, n4))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\sloppy\n")
cat("\\footnotesize\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The dependent variable in columns (1), (3), and (4) is new business density (registrations per 1,000 working-age population); in column (2) it is the log of business density. ``Post'' equals one from 2015 onward. Columns (1)--(2) use only the three Baltic states; columns (3)--(4) use all nine European countries. Covariates in column (4) include log GDP per capita, trade openness, and internet penetration.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ──────────────────────────────────────────────────────────────────────────────
# TABLE 3: Decomposition of Estonian Firm Registrations
# ──────────────────────────────────────────────────────────────────────────────

cat("Generating Table 3: Decomposition\n")

sink(file.path(outdir, "tab3_decomposition.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Decomposition of Estonian New Business Registrations}\n")
cat("\\label{tab:decomp}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lrrrr}\n")
cat("\\toprule\n")
cat("Year & Total & e-Resident & Non-e-Resident & e-Resident Share (\\%) \\\\\n")
cat("\\midrule\n")

for (i in seq_len(nrow(decomp))) {
  r <- decomp[i, ]
  cat(sprintf("%d & %s & %s & %s & %.1f \\\\\n",
              r$year,
              scales::comma(r$biz_nreg),
              scales::comma(r$new_e_firms),
              scales::comma(r$domestic_nreg),
              r$e_share_pct))
}

# Pre-treatment average
pre_avg <- est_dec %>%
  filter(year >= 2006, year <= 2014, !is.na(biz_nreg)) %>%
  summarise(mean_nreg = mean(biz_nreg, na.rm = TRUE))

cat("\\midrule\n")
cat(sprintf("Pre-avg (2006--14) & %s & --- & --- & --- \\\\\n",
            scales::comma(round(pre_avg$mean_nreg))))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\sloppy\n")
cat("\\footnotesize\n")
cat("\\item \\textit{Notes:} Total registrations from World Bank (IC.BUS.NREG). e-Resident firm counts from the official e-Residency Dashboard (\\url{https://e-resident.gov.ee/dashboard/}). Non-e-Resident registrations computed as total minus e-Resident firms; these include both Estonian-owned and foreign-owned firms registered through traditional (non-e-Residency) channels. e-Resident share is the percentage of total new registrations attributable to e-Residents. Pre-treatment average covers 2006--2014, before the December 2014 e-Residency launch.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ──────────────────────────────────────────────────────────────────────────────
# TABLE 4: Robustness — Placebo dates + alternative outcomes
# ──────────────────────────────────────────────────────────────────────────────

cat("Generating Table 4: Robustness\n")

sink(file.path(outdir, "tab4_robustness.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & Coefficient & SE & $p$-value \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel A: Placebo Treatment Dates (pre-2015 only)}} \\\\\n")

for (i in seq_len(nrow(placebo_df))) {
  r <- placebo_df[i, ]
  cat(sprintf("Placebo at %d & %.2f & (%.2f) & %.3f \\\\\n",
              r$placebo_year, r$coef, r$se, r$pval))
}

cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel B: Alternative Outcomes (Baltic DiD, 2006--2022)}} \\\\\n")

# GDP
b_g <- coef(did_gdp)["treat_post"]
s_g <- sqrt(diag(vcov(did_gdp)))["treat_post"]
p_g <- fixest::pvalue(did_gdp)["treat_post"]
cat(sprintf("Log GDP per capita & %.3f%s & (%.3f) & %.3f \\\\\n", b_g, stars(p_g), s_g, p_g))

# Trade
b_t <- coef(did_trade)["treat_post"]
s_t <- sqrt(diag(vcov(did_trade)))["treat_post"]
p_t <- fixest::pvalue(did_trade)["treat_post"]
cat(sprintf("Trade openness & %.2f%s & (%.2f) & %.3f \\\\\n", b_t, stars(p_t), s_t, p_t))

# Internet
b_i <- coef(did_internet)["treat_post"]
s_i <- sqrt(diag(vcov(did_internet)))["treat_post"]
p_i <- fixest::pvalue(did_internet)["treat_post"]
cat(sprintf("Internet users & %.2f%s & (%.2f) & %.3f \\\\\n", b_i, stars(p_i), s_i, p_i))

cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Panel C: In-Space Placebo (each country as ``treated'')}} \\\\\n")

for (i in seq_len(nrow(placebo_scm))) {
  r <- placebo_scm[i, ]
  cat(sprintf("%s & %.2f%s & (%.2f) & %.3f \\\\\n",
              r$country, r$coef, stars(r$pval), r$se, r$pval))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\sloppy\n")
cat("\\footnotesize\n")
cat("\\item \\textit{Notes:} Panel A runs the Baltic DiD specification using only pre-treatment data (2006--2014) with artificial treatment dates. Panel B replaces the dependent variable with alternative outcomes that should be less affected by e-Residency. Panel C assigns placebo treatment to each country in the 9-country panel; Estonia should have the largest absolute coefficient. All specifications include country and year fixed effects with standard errors clustered at the country level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ──────────────────────────────────────────────────────────────────────────────
# TABLE 5 (Appendix F1): Standardized Effect Sizes
# ──────────────────────────────────────────────────────────────────────────────

cat("Generating SDE table\n")

# SDE function
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

# Main outcome: business density (binary treatment)
sd_y_biz <- sd(baltic$biz_density[baltic$year < 2015], na.rm = TRUE)
beta_main <- coef(did_main)["treat_post"]
se_main   <- sqrt(diag(vcov(did_main)))["treat_post"]
sde_main  <- beta_main / sd_y_biz
se_sde_main <- se_main / sd_y_biz

# Full panel
sd_y_full <- sd(panel$biz_density[panel$year < 2015], na.rm = TRUE)
beta_full <- coef(did_full)["treat_post"]
se_full   <- sqrt(diag(vcov(did_full)))["treat_post"]
sde_full  <- beta_full / sd_y_full
se_sde_full <- se_full / sd_y_full

# Heterogeneity: GDP (as proxy for mechanism — shell firms vs real GDP)
sd_y_gdp <- sd(baltic$ln_gdp_pc[baltic$year < 2015], na.rm = TRUE)
beta_gdp <- coef(did_gdp)["treat_post"]
se_gdp   <- sqrt(diag(vcov(did_gdp)))["treat_post"]
sde_gdp  <- beta_gdp / sd_y_gdp
se_sde_gdp <- se_gdp / sd_y_gdp

# Trade openness
sd_y_trade <- sd(baltic$trade_open[baltic$year < 2015], na.rm = TRUE)
beta_trade <- coef(did_trade)["treat_post"]
se_trade   <- sqrt(diag(vcov(did_trade)))["treat_post"]
sde_trade  <- beta_trade / sd_y_trade
se_sde_trade <- se_trade / sd_y_trade

# Build SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Estonia (treated), Latvia and Lithuania (primary controls), ",
  "plus Finland, Czech Republic, Poland, Denmark, Sweden, and Norway (extended donor pool). ",
  "\\textbf{Research question:} Does eliminating administrative border costs through a digital governance ",
  "program---allowing non-citizens to register and manage firms fully online---causally increase ",
  "business formation in the host country? ",
  "\\textbf{Policy mechanism:} Estonia's e-Residency program (launched December 2014) issues digital ",
  "identity cards to non-citizens for EUR~100, enabling them to incorporate Estonian companies, open ",
  "bank accounts, sign documents, and file taxes entirely online without physical presence; this ",
  "eliminates the administrative border cost of cross-border firm creation. ",
  "\\textbf{Outcome definition:} New business registration density from the World Bank Doing Business / ",
  "Entrepreneurship Survey (IC.BUS.NDNS.ZS), measuring the number of newly registered limited-liability ",
  "companies per 1,000 working-age (15--64) population per year. ",
  "\\textbf{Treatment:} Binary (Estonia post-2014 vs pre-2014 and control countries). ",
  "\\textbf{Data:} World Bank World Development Indicators, 2006--2022, country-year panel ",
  "with 9 European countries and up to 153 country-year observations. ",
  "\\textbf{Method:} Difference-in-differences with country and year fixed effects; standard errors ",
  "clustered at the country level. Augmented synthetic control method as primary specification. ",
  "\\textbf{Sample:} Nine European small open economies; restricted to 2006--2022 for consistent ",
  "business density coverage. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(outdir, "tabF1_sde.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\footnotesize\n")
cat("\\begin{tabular}{llcccccc}\n")
cat("\\toprule\n")
cat("Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Business density & Baltic DiD & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_main, se_main, sd_y_biz, sde_main, se_sde_main, classify_sde(sde_main)))
cat(sprintf("Business density & Full panel DiD & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_full, se_full, sd_y_full, sde_full, se_sde_full, classify_sde(sde_full)))
cat("\\midrule\n")
cat("\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (alternative outcomes)}} \\\\\n")
cat(sprintf("Log GDP per capita & Baltic DiD & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_gdp, se_gdp, sd_y_gdp, sde_gdp, se_sde_gdp, classify_sde(sde_gdp)))
cat(sprintf("Trade openness & Baltic DiD & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_trade, se_trade, sd_y_trade, sde_trade, se_sde_trade, classify_sde(sde_trade)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\sloppy\n")
cat("\\scriptsize\\sloppy\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables written to tables/\n")
