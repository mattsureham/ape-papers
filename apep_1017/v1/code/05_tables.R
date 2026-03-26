# 05_tables.R — Generate all tables for paper
# apep_1017: EU Fourth Railway Package and Rail Fares

source("00_packages.R")

cat("=== Loading results ===\n")
df <- readRDS("data/monthly_panel.rds")
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")
pre_stats <- readRDS("data/pre_treatment_stats.rds")

dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

# ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics\n")

pre <- df[date < as.Date("2019-01-01") & !is.na(rail_fare)]
post <- df[date >= as.Date("2019-01-01") & !is.na(rail_fare)]

make_sumstat_row <- function(x, label) {
  sprintf("%s & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          label, mean(x, na.rm = TRUE), sd(x, na.rm = TRUE),
          min(x, na.rm = TRUE), max(x, na.rm = TRUE),
          sum(!is.na(x)))
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly Transport Fare Indices (2015=100)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & N \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Pre-Treatment (Jan 2015 -- Dec 2018)}} \\\\[3pt]",
  make_sumstat_row(pre$rail_fare, "Rail fares (CP0731)"),
  make_sumstat_row(pre$road_fare, "Road fares (CP0732)"),
  make_sumstat_row(pre$air_fare, "Air fares (CP0733)"),
  "",
  "\\multicolumn{6}{l}{\\textit{Panel B: Post-Treatment (Jan 2019 -- Latest)}} \\\\[3pt]",
  make_sumstat_row(post$rail_fare, "Rail fares (CP0731)"),
  make_sumstat_row(post$road_fare, "Road fares (CP0732)"),
  make_sumstat_row(post$air_fare, "Air fares (CP0733)"),
  "\\hline",
  sprintf("Countries & \\multicolumn{5}{c}{%d} \\\\", uniqueN(df$geo)),
  sprintf("Early transposers & \\multicolumn{5}{c}{%d (BG, FI, FR, EL, IT, NL, RO, SI)} \\\\",
          uniqueN(df[cohort == "early"]$geo)),
  sprintf("Late transposers & \\multicolumn{5}{c}{%d} \\\\",
          uniqueN(df[cohort == "late"]$geo)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} HICP monthly index values (2015=100) from Eurostat (prc\\_hicp\\_midx). Rail fares correspond to COICOP category CP0731, road to CP0732, and air to CP0733. Pre-treatment period ends December 2018 (before earliest transposition in January 2019).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ---- Table 2: Main Results ----
cat("Generating Table 2: Main Results\n")

# Extract coefficients
get_coef <- function(model, var = "post") {
  cf <- coeftable(model)
  idx <- which(rownames(cf) == var)
  if (length(idx) == 0) return(c(NA, NA, NA))
  c(cf[idx, "Estimate"], cf[idx, "Std. Error"], cf[idx, "Pr(>|t|)"])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  ""
}

format_coef <- function(est, se, p) {
  if (is.na(est)) return("& ")
  sprintf("& %.4f%s", est, stars(p))
}
format_se <- function(se) {
  if (is.na(se)) return("& ")
  sprintf("& (%.4f)", se)
}

# Main results
twfe_r <- get_coef(results$twfe_rail)
twfe_rd <- get_coef(results$twfe_road)
twfe_a <- get_coef(results$twfe_air)
ddd_r <- get_coef(results$ddd_reg, "rail_post")
ddd_a <- get_coef(results$ddd_air_reg, "rail_post")
cs_att <- c(results$cs_simple$overall.att, results$cs_simple$overall.se,
            2 * pnorm(-abs(results$cs_simple$overall.att / results$cs_simple$overall.se)))

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Fourth Railway Package on Transport Fares}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{TWFE} & CS & \\multicolumn{2}{c}{Triple-Diff} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-5} \\cmidrule(lr){6-7}",
  " & Rail & Road & Air & Rail & Rail vs & Rail vs \\\\",
  " & (1) & (2) & (3) & (4) & Road (5) & Air (6) \\\\",
  "\\hline",
  paste("Post $\\times$ Treated",
        format_coef(twfe_r[1], twfe_r[2], twfe_r[3]),
        format_coef(twfe_rd[1], twfe_rd[2], twfe_rd[3]),
        format_coef(twfe_a[1], twfe_a[2], twfe_a[3]),
        format_coef(cs_att[1], cs_att[2], cs_att[3]),
        format_coef(ddd_r[1], ddd_r[2], ddd_r[3]),
        format_coef(ddd_a[1], ddd_a[2], ddd_a[3]),
        "\\\\"),
  paste(" ",
        format_se(twfe_r[2]),
        format_se(twfe_rd[2]),
        format_se(twfe_a[2]),
        format_se(cs_att[2]),
        format_se(ddd_r[2]),
        format_se(ddd_a[2]),
        "\\\\"),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(nobs(results$twfe_rail), big.mark = ","),
          format(nobs(results$twfe_road), big.mark = ","),
          format(nobs(results$twfe_air), big.mark = ","),
          format(nrow(df[!is.na(rail_fare)]), big.mark = ","),
          format(nobs(results$ddd_reg), big.mark = ","),
          format(nobs(results$ddd_air_reg), big.mark = ",")),
  sprintf("Countries & %d & %d & %d & %d & %d & %d \\\\",
          uniqueN(df[!is.na(rail_fare)]$geo),
          uniqueN(df[!is.na(road_fare)]$geo),
          uniqueN(df[!is.na(air_fare)]$geo),
          uniqueN(df[!is.na(rail_fare)]$geo),
          uniqueN(df[!is.na(rail_fare)]$geo),
          uniqueN(df[!is.na(rail_fare)]$geo)),
  "Country FE & Yes & Yes & Yes & --- & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & --- & Yes & Yes \\\\",
  "Estimator & TWFE & TWFE & TWFE & CS & TWFE & TWFE \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log HICP fare index (2015=100). Columns (1)--(3) report two-way fixed effects estimates for rail, road (placebo), and air (placebo) fares. Column (4) reports the Callaway and Sant'Anna (2021) aggregate ATT using not-yet-treated controls. Columns (5)--(6) report triple-difference estimates comparing rail fares to road and air fares within country-months. Standard errors clustered at the country level in parentheses. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ---- Table 3: Heterogeneity (Early vs Late) ----
cat("Generating Table 3: Heterogeneity\n")

het_e <- get_coef(results$het_early)
het_l <- get_coef(results$het_late)

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Transposition Cohort}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Early (2019) & Late (2020) & Full Sample \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\hline",
  paste("Post",
        format_coef(het_e[1], het_e[2], het_e[3]),
        format_coef(het_l[1], het_l[2], het_l[3]),
        format_coef(twfe_r[1], twfe_r[2], twfe_r[3]),
        "\\\\"),
  paste(" ",
        format_se(het_e[2]),
        format_se(het_l[2]),
        format_se(twfe_r[2]),
        "\\\\"),
  "\\hline",
  sprintf("Countries & %d & %d & %d \\\\",
          uniqueN(df[cohort == "early"]$geo),
          uniqueN(df[cohort == "late"]$geo),
          uniqueN(df$geo)),
  sprintf("Observations & %s & %s & %s \\\\",
          format(nrow(df[cohort == "early" & !is.na(rail_fare)]), big.mark = ","),
          format(nrow(df[cohort == "late" & !is.na(rail_fare)]), big.mark = ","),
          format(nrow(df[!is.na(rail_fare)]), big.mark = ",")),
  "Country FE & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log HICP rail fare index. Column (1) restricts to the 8 early-transposing countries (BG, FI, FR, EL, IT, NL, RO, SI; transposed by June 2019). Column (2) restricts to the 19 late-transposing countries (transposed June--October 2020). Standard errors clustered at the country level. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_heterogeneity.tex")

# ---- Table 4: Robustness ----
cat("Generating Table 4: Robustness\n")

rob_pc <- get_coef(rob$precovid)
rob_np <- get_coef(rob$no_preopen)
rob_gd <- get_coef(rob$gdp_control)
rob_lv <- get_coef(rob$levels)
rob_sw <- get_coef(rob$short_window)

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Pre-COVID & Excl. SE/CZ & GDP Control & Levels & 12-Month \\\\",
  " & Early Only & & & & Window \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline",
  paste("Post",
        format_coef(rob_pc[1], rob_pc[2], rob_pc[3]),
        format_coef(rob_np[1], rob_np[2], rob_np[3]),
        format_coef(rob_gd[1], rob_gd[2], rob_gd[3]),
        format_coef(rob_lv[1], rob_lv[2], rob_lv[3]),
        format_coef(rob_sw[1], rob_sw[2], rob_sw[3]),
        "\\\\"),
  paste(" ",
        format_se(rob_pc[2]),
        format_se(rob_np[2]),
        format_se(rob_gd[2]),
        format_se(rob_lv[2]),
        format_se(rob_sw[2]),
        "\\\\"),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(rob$precovid), big.mark = ","),
          format(nobs(rob$no_preopen), big.mark = ","),
          format(nobs(rob$gdp_control), big.mark = ","),
          format(nobs(rob$levels), big.mark = ","),
          format(nobs(rob$short_window), big.mark = ",")),
  "Country FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Column (1) restricts to early transposers with post-period ending February 2020 (pre-COVID). Column (2) excludes Sweden and Czechia, which had open rail markets before the Fourth Railway Package. Column (3) adds log GDP per capita as a time-varying control. Column (4) uses fare index levels instead of logs. Column (5) restricts to a symmetric 12-month window around transposition. Standard errors clustered at the country level. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ---- Table F1: Standardized Effect Sizes (SDE) ----
cat("Generating Table F1: SDE Appendix\n")

# Main estimate: CS ATT
beta_rail <- results$cs_simple$overall.att
se_rail <- results$cs_simple$overall.se
sd_y_rail <- pre_stats$sd_log_rail

# DDD estimates
beta_ddd_road <- coef(results$ddd_reg)["rail_post"]
se_ddd_road <- coeftable(results$ddd_reg)["rail_post", "Std. Error"]

beta_ddd_air <- coef(results$ddd_air_reg)["rail_post"]
se_ddd_air <- coeftable(results$ddd_air_reg)["rail_post", "Std. Error"]

# Heterogeneity: early vs late
beta_early <- coef(results$het_early)["post"]
se_early <- coeftable(results$het_early)["post", "Std. Error"]

beta_late <- coef(results$het_late)["post"]
se_late <- coeftable(results$het_late)["post", "Std. Error"]

# SDE calculations (binary treatment: SDE = beta / SD(Y))
sde_calc <- function(b, se_b, sd_y) {
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  bucket <- cut(sde,
                breaks = c(-Inf, -0.15, -0.05, -0.005, 0.005, 0.05, 0.15, Inf),
                labels = c("Large neg.", "Mod. neg.", "Small neg.", "Null",
                           "Small pos.", "Mod. pos.", "Large pos."))
  list(sde = sde, se_sde = se_sde, bucket = as.character(bucket))
}

outcomes <- list(
  list(name = "Rail fares (CS ATT)", beta = beta_rail, se = se_rail),
  list(name = "Rail vs. road (DDD)", beta = beta_ddd_road, se = se_ddd_road),
  list(name = "Rail vs. air (DDD)", beta = beta_ddd_air, se = se_ddd_air)
)

het_outcomes <- list(
  list(name = "Early transposers", beta = beta_early, se = se_early),
  list(name = "Late transposers", beta = beta_late, se = se_late)
)

make_sde_row <- function(o, sd_y) {
  s <- sde_calc(o$beta, o$se, sd_y)
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          o$name, o$beta, o$se, sd_y, s$sde, s$se_sde, s$bucket)
}

# SDE table notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (25 member states). ",
  "\\textbf{Research question:} Does the EU's Fourth Railway Package, which forced open domestic rail passenger markets, reduce rail fares for consumers? ",
  "\\textbf{Policy mechanism:} Directive 2016/2370 grants any EU-licensed railway undertaking the right to operate domestic passenger services in any member state, while Regulation 2016/2338 mandates competitive tendering for public service obligation rail contracts---breaking incumbent monopolies through both open-access entry and contestable procurement. ",
  "\\textbf{Outcome definition:} Log HICP monthly rail transport fare index (COICOP CP0731, base 2015=100), measuring the average price change of rail passenger services in each country. ",
  "\\textbf{Treatment:} Binary indicator for post-transposition of Directive 2016/2370 into national law; 8 countries transposed by June 2019, 19 by October 2020. ",
  "\\textbf{Data:} Eurostat prc\\_hicp\\_midx, January 2015--December 2024, country-month panel, approximately 2,700 observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with not-yet-treated controls for Panel A; TWFE with country and month fixed effects for Panel B; standard errors clustered at country level. ",
  "\\textbf{Sample:} 25 EU member states with available HICP rail fare data; Cyprus and Malta excluded due to no rail network. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log rail fare index. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  paste(sapply(outcomes, make_sde_row, sd_y = sd_y_rail), collapse = "\n"),
  "",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by transposition cohort)}} \\\\[3pt]",
  paste(sapply(het_outcomes, make_sde_row, sd_y = sd_y_rail), collapse = "\n"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated in tables/ directory.\n")
