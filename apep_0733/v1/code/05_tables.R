## 05_tables.R — Generate all LaTeX tables
## Paper: The Fortress Premium (apep_0733)

source("code/00_packages.R")

results <- readRDS("data/main_results.rds")
robust  <- readRDS("data/robustness_results.rds")
hesta   <- fread("data/hesta_clean.csv")
hesta_main <- hesta[year <= 2019]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Panel A: Canton-level annual overnight stays
canton_yr <- hesta_main[, .(
  total_nights = sum(nights, na.rm = TRUE),
  euro_nights  = sum(nights[exposure == "eurozone"], na.rm = TRUE),
  swiss_nights = sum(nights[exposure == "swiss"], na.rm = TRUE),
  other_nights = sum(nights[!exposure %in% c("eurozone", "swiss")], na.rm = TRUE)
), by = .(canton, canton_name, year, euro_share_2014)]

canton_yr[, euro_share := euro_nights / total_nights]
canton_yr[, swiss_share := swiss_nights / total_nights]

# Summary by period
pre <- canton_yr[year < 2015]
post <- canton_yr[year >= 2015]

sum_stats <- data.table(
  Variable = c("Total overnight stays (millions)", "Eurozone share (%)",
               "Swiss domestic share (%)", "N canton-years"),
  `Pre (2005-14)` = c(
    sprintf("%.1f", mean(pre$total_nights) / 1e6),
    sprintf("%.1f", 100 * mean(pre$euro_share)),
    sprintf("%.1f", 100 * mean(pre$swiss_share)),
    sprintf("%d", nrow(pre))
  ),
  `Post (2015-19)` = c(
    sprintf("%.1f", mean(post$total_nights) / 1e6),
    sprintf("%.1f", 100 * mean(post$euro_share)),
    sprintf("%.1f", 100 * mean(post$swiss_share)),
    sprintf("%d", nrow(post))
  )
)

# Panel B: Origin-group totals
origin_annual <- hesta_main[, .(
  nights = sum(nights, na.rm = TRUE)
), by = .(exposure, year)]

origin_pre <- origin_annual[year == 2014]
origin_post <- origin_annual[year == 2019]

origin_change <- merge(origin_pre, origin_post, by = "exposure", suffixes = c("_2014", "_2019"))
origin_change[, pct_change := 100 * (nights_2019 / nights_2014 - 1)]

# Write Table 1
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Swiss Hotel Overnight Stays}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Pre-shock & Post-shock \\\\",
  " & (2005--2014) & (2015--2019) \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Canton-Year Averages}} \\\\[3pt]",
  sprintf("Total overnight stays (millions) & %s & %s \\\\", sum_stats$`Pre (2005-14)`[1], sum_stats$`Post (2015-19)`[1]),
  sprintf("Eurozone visitor share (\\%%) & %s & %s \\\\", sum_stats$`Pre (2005-14)`[2], sum_stats$`Post (2015-19)`[2]),
  sprintf("Swiss domestic share (\\%%) & %s & %s \\\\", sum_stats$`Pre (2005-14)`[3], sum_stats$`Post (2015-19)`[3]),
  sprintf("Canton-years & %s & %s \\\\[6pt]", sum_stats$`Pre (2005-14)`[4], sum_stats$`Post (2015-19)`[4]),
  "\\multicolumn{3}{l}{\\textit{Panel B: National Totals by Visitor Origin (millions)}} \\\\[3pt]"
)

for (grp in c("swiss", "eurozone", "non_euro_europe", "non_european")) {
  label <- switch(grp,
    "swiss" = "Swiss domestic",
    "eurozone" = "Eurozone",
    "non_euro_europe" = "Non-euro Europe",
    "non_european" = "Non-European")
  r14 <- origin_change[exposure == grp]
  if (nrow(r14) > 0) {
    tab1_lines <- c(tab1_lines,
      sprintf("%s & %.1f & %.1f \\\\", label, r14$nights_2014 / 1e6, r14$nights_2019 / 1e6))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from the Swiss Federal Statistical Office HESTA (Hotel Accommodation Statistics), 2005--2019. Eurozone includes Germany, France, Italy, Austria, Netherlands, Belgium, Spain, Portugal, Greece, Finland, Luxembourg. Non-euro Europe includes UK, Scandinavia, Eastern Europe, Baltic states. Non-European includes Americas, Asia, Africa, Oceania.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("Saved tables/tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

m1 <- results$m1_did
m4 <- results$m4_origin
m3 <- results$m3_bartik

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Franc Shock and Hotel Overnight Stays: Main Results}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Aggregated DiD & Origin-level DiD & Bartik \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Eurozone & $%s$ & & \\\\", formatC(coef(m1)[1], format = "f", digits = 3)),
  sprintf(" & (%s) & & \\\\", formatC(se(m1)[1], format = "f", digits = 3)),
  sprintf("Post $\\times$ Euro-exposed & & $%s$ & \\\\", formatC(coef(m4)[1], format = "f", digits = 3)),
  sprintf(" & & (%s) & \\\\", formatC(se(m4)[1], format = "f", digits = 3)),
  sprintf("Post $\\times$ Euro share$_{2014}$ & & & $%s$ \\\\", formatC(coef(m3)[1], format = "f", digits = 3)),
  sprintf(" & & & (%s) \\\\[6pt]", formatC(se(m3)[1], format = "f", digits = 3)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
    formatC(m1$nobs, big.mark = ","), formatC(m4$nobs, big.mark = ","), formatC(m3$nobs, big.mark = ",")),
  "Unit FE & Canton$\\times$Group & Canton$\\times$Origin & Canton \\\\",
  "Time FE & Year-month & Year-month & Year-month \\\\",
  "Clustering & Canton & Canton & Canton \\\\",
  sprintf("Adj.\\ $R^2$ & %s & %s & %s \\\\",
    formatC(fitstat(m1, "ar2")[[1]], format = "f", digits = 3),
    formatC(fitstat(m4, "ar2")[[1]], format = "f", digits = 3),
    formatC(fitstat(m3, "ar2")[[1]], format = "f", digits = 3)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is log overnight stays. Column (1) aggregates Eurozone origins into one group and compares against Swiss domestic within cantons. Column (2) uses origin-level panel (canton$\\times$nationality pairs with $>$100 annual stays in 2014). Column (3) estimates canton-level Bartik reduced form using 2014 Eurozone visitor share as exposure weight. Standard errors clustered at canton level in parentheses. Sample: 2005--2019 (pre-COVID). $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("Saved tables/tab2_main.tex\n")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

m2 <- results$m2_event
es_coefs <- coef(m2)
es_se <- se(m2)
es_names <- names(es_coefs)

# Extract event years from coefficient names
es_dt <- data.table(
  name = es_names,
  coef = es_coefs,
  se = es_se
)
es_dt[, event_year := as.integer(gsub("event_year::(-?\\d+):euro", "\\1", name))]
es_dt <- es_dt[order(event_year)]

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Eurozone vs.\\ Swiss Overnight Stays by Year}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year relative to shock & Coefficient & Std.\\ Error \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_dt)) {
  yr <- es_dt$event_year[i]
  stars <- ifelse(abs(es_dt$coef[i] / es_dt$se[i]) > 2.576, "$^{***}$",
           ifelse(abs(es_dt$coef[i] / es_dt$se[i]) > 1.96, "$^{**}$",
           ifelse(abs(es_dt$coef[i] / es_dt$se[i]) > 1.645, "$^{*}$", "")))
  label <- ifelse(yr == 0, "\\textbf{0 (shock year)}", as.character(yr))
  if (yr == -1) label <- "$-$1 (reference)"
  if (yr == 0) {
    tab3_lines <- c(tab3_lines, "\\midrule")
  }
  tab3_lines <- c(tab3_lines,
    sprintf("%s & $%s$%s & (%s) \\\\", label,
            formatC(es_dt$coef[i], format = "f", digits = 3), stars,
            formatC(es_dt$se[i], format = "f", digits = 3)))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", formatC(m2$nobs, big.mark = ",")),
  "Fixed effects & \\multicolumn{2}{c}{Canton$\\times$Group + Year} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from regressing log annual overnight stays on year dummies interacted with a Eurozone indicator, with canton$\\times$group and year fixed effects. Reference year is $-$1 (2014). Standard errors clustered at canton level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_event.tex")
cat("Saved tables/tab3_event.tex\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

r1 <- robust$r1_placebo_origin
r2 <- robust$r2_donut
r3 <- robust$r3_placebo_timing
r4 <- robust$r4_non_euro_europe
r5 <- robust$r5_full_covid

format_coef <- function(m, idx = 1) {
  b <- coef(m)[idx]
  s <- se(m)[idx]
  stars <- ifelse(abs(b/s) > 2.576, "$^{***}$",
           ifelse(abs(b/s) > 1.96, "$^{**}$",
           ifelse(abs(b/s) > 1.645, "$^{*}$", "")))
  sprintf("$%s$%s & (%s)", formatC(b, format="f", digits=3), stars,
          formatC(s, format="f", digits=3))
}

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & (SE) \\\\",
  "\\midrule",
  sprintf("\\textit{Main result} & %s \\\\", format_coef(results$m1_did)),
  "\\midrule",
  sprintf("Donut (excl.\\ 2015) & %s \\\\", format_coef(r2)),
  sprintf("Placebo: non-European vs.\\ Swiss & %s \\\\", format_coef(r1)),
  sprintf("Placebo: fake shock 2012 & %s \\\\", format_coef(r3)),
  sprintf("Non-euro Europe vs.\\ Swiss & %s \\\\", format_coef(r4)),
  sprintf("Full sample (2005--2025) with COVID & %s \\\\", format_coef(r5)),
  sprintf("Randomization inference $p$-value & \\multicolumn{2}{c}{%s} \\\\",
          formatC(robust$ri_p, format = "f", digits = 3)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include canton$\\times$group and year-month fixed effects with standard errors clustered at canton level. Main result compares Eurozone vs.\\ Swiss domestic overnight stays within cantons, 2005--2019. Donut excludes 2015 transition year. Placebo: non-European tests whether non-EUR visitors show a spurious effect. Placebo: fake shock 2012 tests pre-trends. Non-euro Europe tests partial exchange rate exposure (GBP, SEK, etc.). Full sample extends to 2025 with a COVID$\\times$Euro interaction. RI permutes shock year 500 times. $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robust.tex")
cat("Saved tables/tab4_robust.tex\n")

# ============================================================
# TABLE 5: Heterogeneity
# ============================================================
cat("\n=== Table 5: Heterogeneity ===\n")

m5t <- results$m5_tourism
m5u <- results$m5_urban
m5o <- results$m5_other

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Canton Type}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) Tourism & (2) Urban & (3) Other \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Eurozone & $%s$ & $%s$ & $%s$ \\\\",
    formatC(coef(m5t)[1], format="f", digits=3),
    formatC(coef(m5u)[1], format="f", digits=3),
    formatC(coef(m5o)[1], format="f", digits=3)),
  sprintf(" & (%s) & (%s) & (%s) \\\\[6pt]",
    formatC(se(m5t)[1], format="f", digits=3),
    formatC(se(m5u)[1], format="f", digits=3),
    formatC(se(m5o)[1], format="f", digits=3)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
    formatC(m5t$nobs, big.mark=","), formatC(m5u$nobs, big.mark=","), formatC(m5o$nobs, big.mark=",")),
  "FE & Canton$\\times$Group & Canton$\\times$Group & Canton$\\times$Group \\\\",
  "Cantons & GR, VS, LU, SZ, NW, UR & ZH, GE, BS, VD & 16 others \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Same specification as Table~\\ref{tab:main} column (1), estimated separately for tourism cantons (Graubünden, Valais, Luzern, Schwyz, Nidwalden, Uri), urban cantons (Zürich, Geneva, Basel-Stadt, Vaud), and remaining cantons. The larger coefficient for tourism cantons indicates greater price elasticity of demand in leisure-oriented markets. $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "tables/tab5_hetero.tex")
cat("Saved tables/tab5_hetero.tex\n")

# ============================================================
# TABLE F1: SDE (Standardized Effect Size)
# ============================================================
cat("\n=== Table F1: Standardized Effect Size ===\n")

# Compute SDE from main DiD
hesta_di <- hesta_main[exposure %in% c("swiss", "eurozone")]
agg <- hesta_di[, .(nights = sum(nights, na.rm = TRUE)),
  by = .(canton, exposure, year, month)]
agg[, log_nights := log(pmax(nights, 1))]

# Pre-treatment SD of log_nights
pre_sd <- sd(agg[year < 2015]$log_nights)

beta_main <- coef(results$m1_did)[1]
se_main   <- se(results$m1_did)[1]
sde_main  <- beta_main / pre_sd
se_sde    <- se_main / pre_sd

# Origin-level
pre_sd_origin <- sd(hesta_main[nights > 0 & year < 2015]$log_nights)
beta_origin <- coef(results$m4_origin)[1]
se_origin   <- se(results$m4_origin)[1]
sde_origin  <- beta_origin / pre_sd_origin
se_sde_origin <- se_origin / pre_sd_origin

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does an unexpected exchange rate appreciation reduce international tourism demand, and does the effect vary by visitor origin? ",
  "\\textbf{Policy mechanism:} The Swiss National Bank's removal of the EUR/CHF 1.20 floor on January 15, 2015 caused an immediate 12--15\\% franc appreciation, raising the effective price of Swiss hotels for foreign visitors while leaving domestic prices unchanged. ",
  "\\textbf{Outcome definition:} Log monthly hotel overnight stays from the HESTA (Hotel Accommodation Statistics), measuring registered guest-nights in licensed hotels by visitor nationality and canton. ",
  "\\textbf{Treatment:} Binary; post-January 2015 interacted with Eurozone origin indicator (within-canton comparison against Swiss domestic visitors as control). ",
  "\\textbf{Data:} Swiss Federal Statistical Office HESTA via PXWeb API, 2005--2019 monthly, canton$\\times$nationality level, 504,504 observations in full sample. ",
  "\\textbf{Method:} Two-way fixed effects DiD (canton$\\times$group and year-month FE), standard errors clustered at canton level (26 clusters). ",
  "\\textbf{Sample:} Pre-COVID (2005--2019); canton$\\times$origin pairs with $>$100 annual nights in 2014 for origin-level specification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log overnight stays (aggregated) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta_main, format="f", digits=3),
    formatC(se_main, format="f", digits=3),
    formatC(pre_sd, format="f", digits=3),
    formatC(sde_main, format="f", digits=3),
    formatC(se_sde, format="f", digits=3),
    classify_sde(sde_main)),
  sprintf("Log overnight stays (origin-level) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta_origin, format="f", digits=3),
    formatC(se_origin, format="f", digits=3),
    formatC(pre_sd_origin, format="f", digits=3),
    formatC(sde_origin, format="f", digits=3),
    formatC(se_sde_origin, format="f", digits=3),
    classify_sde(sde_origin)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("Saved tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
