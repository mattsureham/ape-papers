## 05_tables.R — Generate all LaTeX tables
## Paper: The Deterrence Dividend (apep_0984)

source("00_packages.R")

cat("=== GENERATING TABLES ===\n\n")

panel   <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob     <- readRDS("../data/robustness_results.rds")

# -----------------------------------------------------------------------
# TABLE 1: Summary Statistics
# -----------------------------------------------------------------------
cat("Table 1: Summary Statistics\n")

summ <- panel %>%
  summarise(
    across(c(search_index, palladium_price, unemp_rate, treated),
           list(mean = ~mean(., na.rm = TRUE),
                sd   = ~sd(., na.rm = TRUE),
                min  = ~min(., na.rm = TRUE),
                max  = ~max(., na.rm = TRUE)),
           .names = "{.col}__{.fn}")
  ) %>%
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_sep = "__") %>%
  pivot_wider(names_from = stat, values_from = value)

var_labels <- c(
  search_index    = "Search intensity index (0--100)",
  palladium_price = "Palladium price (\\$/oz)",
  unemp_rate      = "Unemployment rate (\\%)",
  treated         = "Anti-theft law in effect"
)

tab1 <- "\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Variable & Mean & Std.\\ Dev. & Min & Max \\\\
\\midrule\n"

for (v in names(var_labels)) {
  row <- summ %>% filter(variable == v)
  if (nrow(row) > 0) {
    tab1 <- paste0(tab1, sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\\n",
                                 var_labels[v], row$mean, row$sd, row$min, row$max))
  }
}

tab1 <- paste0(tab1, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = ", format(nrow(panel), big.mark = ","),
" state-quarter observations covering ", n_distinct(panel$state_abbr),
" states from ", min(panel$yq), " to ", max(panel$yq),
". Search intensity index is the Google Trends relative search interest ",
"for ``catalytic converter theft'' at the state level, normalized 0--100 ",
"within each state. Palladium price is the quarterly average of daily ",
"NYMEX palladium futures (PA=F) from Yahoo Finance. Unemployment rate ",
"is the monthly state-level rate from BLS LAUS, averaged to quarterly. ",
"Anti-theft law indicator equals one from the quarter the law took effect.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}")

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Saved tab1_summary.tex\n")

# -----------------------------------------------------------------------
# TABLE 2: Main TWFE Results
# -----------------------------------------------------------------------
cat("Table 2: Main TWFE Results\n")

m1 <- results$twfe$m1
m2 <- results$twfe$m2
m3 <- results$twfe$m3
m4 <- results$twfe$m4
m5 <- results$twfe$m5

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
fmt_coef <- function(m, var) {
  if (var %in% names(coef(m))) {
    b <- coef(m)[var]; s <- se(m)[var]; p <- pvalue(m)[var]
    paste0(sprintf("%.3f%s", b, stars(p)), " \\\\\n& (",
           sprintf("%.3f", s), ") \\\\")
  } else {
    "& \\\\\n& \\\\"
  }
}

tab2 <- paste0("\\begin{table}[H]
\\centering
\\caption{Effect of Anti-Theft Laws on Catalytic Converter Theft Concern}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l",paste(rep("c",5),collapse=""),"}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& Baseline & +Price & +Interaction & +Controls & IHS \\\\
\\midrule
Anti-theft law ",
paste(sapply(list(m1,m2,m3,m4,m5), function(m) {
  b <- coef(m)["treated"]; s <- se(m)["treated"]; p <- pvalue(m)["treated"]
  sprintf("& %.3f%s", b, stars(p))
}), collapse=" "), " \\\\
",
paste(sapply(list(m1,m2,m3,m4,m5), function(m) {
  sprintf("& (%.3f)", se(m)["treated"])
}), collapse=" "), " \\\\[6pt]
")

# Log palladium row
tab2 <- paste0(tab2, "Log(palladium) ")
for (m in list(m1,m2,m3,m4,m5)) {
  if ("log_palladium" %in% names(coef(m))) {
    b <- coef(m)["log_palladium"]; s <- se(m)["log_palladium"]; p <- pvalue(m)["log_palladium"]
    tab2 <- paste0(tab2, sprintf("& %.3f%s ", b, stars(p)))
  } else {
    tab2 <- paste0(tab2, "& ")
  }
}
tab2 <- paste0(tab2, "\\\\\n")
for (m in list(m1,m2,m3,m4,m5)) {
  if ("log_palladium" %in% names(coef(m))) {
    tab2 <- paste0(tab2, sprintf("& (%.3f) ", se(m)["log_palladium"]))
  } else {
    tab2 <- paste0(tab2, "& ")
  }
}
tab2 <- paste0(tab2, "\\\\[6pt]\n")

# Interaction row
tab2 <- paste0(tab2, "Law $\\times$ Log(palladium) ")
for (m in list(m1,m2,m3,m4,m5)) {
  if ("treated:log_palladium" %in% names(coef(m))) {
    b <- coef(m)["treated:log_palladium"]; s <- se(m)["treated:log_palladium"]
    p <- pvalue(m)["treated:log_palladium"]
    tab2 <- paste0(tab2, sprintf("& %.3f%s ", b, stars(p)))
  } else {
    tab2 <- paste0(tab2, "& ")
  }
}
tab2 <- paste0(tab2, "\\\\\n")
for (m in list(m1,m2,m3,m4,m5)) {
  if ("treated:log_palladium" %in% names(coef(m))) {
    tab2 <- paste0(tab2, sprintf("& (%.3f) ", se(m)["treated:log_palladium"]))
  } else {
    tab2 <- paste0(tab2, "& ")
  }
}
tab2 <- paste0(tab2, "\\\\[6pt]\n")

# Footer
tab2 <- paste0(tab2, "\\midrule
State FE & Yes & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\
Unemployment & No & No & No & Yes & No \\\\
Outcome & Level & Level & Level & Level & IHS \\\\
N ", paste(sapply(list(m1,m2,m3,m4,m5), function(m) {
  sprintf("& %s", format(nobs(m), big.mark=","))
}), collapse=" "), " \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Standard errors clustered at the state level in parentheses. The outcome is the Google Trends search intensity index (0--100) for ``catalytic converter theft'' at the state-quarter level. Anti-theft law is a binary indicator for quarters when a catalytic converter anti-theft law is in effect. Log(palladium) is the log of quarterly average NYMEX palladium futures price. Column (5) uses the inverse hyperbolic sine transformation of the search index as the outcome.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}")

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Saved tab2_main.tex\n")

# -----------------------------------------------------------------------
# TABLE 3: Callaway-Sant'Anna and Robustness
# -----------------------------------------------------------------------
cat("Table 3: C-S Results and Robustness\n")

cs <- results$cs_agg
cs_p <- 2 * pnorm(-abs(cs$overall.att / cs$overall.se))

tab3 <- paste0("\\begin{table}[H]
\\centering
\\caption{Callaway--Sant'Anna Estimates and Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Specification & Coefficient & SE & p-value & N \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\
Aggregate ATT & ", sprintf("%.3f", cs$overall.att),
" & ", sprintf("%.3f", cs$overall.se),
" & ", sprintf("%.3f", cs_p),
" & ", format(nrow(panel), big.mark=","), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Alternative Specifications}} \\\\\n")

spec_names <- c("Log(1+Y) outcome", "Drop 2020 (COVID)",
                "State-specific trends", "Drop TX (earliest adopter)",
                "High-signal states only")

for (i in seq_along(spec_names)) {
  m <- rob$alt_specs[[i]]
  b <- coef(m)["treated"]; s <- se(m)["treated"]; p <- pvalue(m)["treated"]
  tab3 <- paste0(tab3, sprintf("%s & %.3f%s & %.3f & %.3f & %s \\\\\n",
                                spec_names[i], b, stars(p), s, p,
                                format(nobs(m), big.mark=",")))
}

tab3 <- paste0(tab3, "\\midrule
\\multicolumn{5}{l}{\\textit{Panel C: Placebo}} \\\\
Pre-treatment placebo (4Q early) & ",
sprintf("%.3f", coef(results$m_placebo)["placebo_treat"]),
" & ", sprintf("%.3f", se(results$m_placebo)["placebo_treat"]),
" & ", sprintf("%.3f", pvalue(results$m_placebo)["placebo_treat"]),
" & ", format(nobs(results$m_placebo), big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A reports the Callaway--Sant'Anna (2021) aggregate average treatment effect on the treated, using not-yet-treated states as the control group. Panel B presents alternative TWFE specifications; all include state and quarter fixed effects with state-clustered standard errors. Panel C assigns a placebo treatment four quarters before actual adoption to test for pre-existing differential trends. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robust}
\\end{table}")

writeLines(tab3, "../tables/tab3_robust.tex")
cat("  Saved tab3_robust.tex\n")

# -----------------------------------------------------------------------
# TABLE 4: Heterogeneity
# -----------------------------------------------------------------------
cat("Table 4: Heterogeneity\n")

h1 <- rob$het_law_type
h2 <- rob$het_timing

tab4 <- paste0("\\begin{table}[H]
\\centering
\\caption{Heterogeneity by Law Type and Adoption Timing}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& By law type & By timing \\\\
\\midrule\n")

# Law type coefficients
if ("treated_penalty" %in% names(coef(h1))) {
  tab4 <- paste0(tab4, sprintf("Enhanced penalty states & %.3f%s & \\\\\n",
    coef(h1)["treated_penalty"], stars(pvalue(h1)["treated_penalty"])))
  tab4 <- paste0(tab4, sprintf("& (%.3f) & \\\\\n", se(h1)["treated_penalty"]))
}
if ("treated_dealer" %in% names(coef(h1))) {
  tab4 <- paste0(tab4, sprintf("Dealer regulation states & %.3f%s & \\\\\n",
    coef(h1)["treated_dealer"], stars(pvalue(h1)["treated_dealer"])))
  tab4 <- paste0(tab4, sprintf("& (%.3f) & \\\\[6pt]\n", se(h1)["treated_dealer"]))
}

# Timing coefficients
if ("treated_early" %in% names(coef(h2))) {
  tab4 <- paste0(tab4, sprintf("Early adopters (pre-2023) & & %.3f%s \\\\\n",
    coef(h2)["treated_early"], stars(pvalue(h2)["treated_early"])))
  tab4 <- paste0(tab4, sprintf("& & (%.3f) \\\\\n", se(h2)["treated_early"]))
}
if ("treated_late" %in% names(coef(h2))) {
  tab4 <- paste0(tab4, sprintf("Late adopters (2023+) & & %.3f%s \\\\\n",
    coef(h2)["treated_late"], stars(pvalue(h2)["treated_late"])))
  tab4 <- paste0(tab4, sprintf("& & (%.3f) \\\\\n", se(h2)["treated_late"]))
}

tab4 <- paste0(tab4, "\\midrule
State FE & Yes & Yes \\\\
Quarter FE & Yes & Yes \\\\
N & ", format(nobs(h1), big.mark=","), " & ", format(nobs(h2), big.mark=","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Standard errors clustered at the state level. Column (1) decomposes the treatment effect by law type: ``enhanced penalty'' states increased criminal sanctions for converter theft, while ``dealer regulation'' states imposed purchase documentation and holding-period requirements on scrap metal dealers. Column (2) splits by adoption timing: early adopters enacted laws before 2023 (during or near peak palladium prices), while late adopters enacted laws in 2023 or later (after substantial price decline).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:het}
\\end{table}")

writeLines(tab4, "../tables/tab4_heterogeneity.tex")
cat("  Saved tab4_heterogeneity.tex\n")

# -----------------------------------------------------------------------
# TABLE F1: Standardized Effect Sizes (SDE)
# -----------------------------------------------------------------------
cat("Table F1: Standardized Effect Sizes\n")

m_main <- results$twfe$m1
sd_y <- sd(panel$search_index, na.rm = TRUE)
beta_main <- coef(m_main)["treated"]
se_main <- se(m_main)["treated"]

sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# Panel A: Pooled
sde_rows_a <- data.frame(
  outcome = "Search intensity",
  beta = beta_main,
  se = se_main,
  sd_y = sd_y,
  sde = sde_main,
  se_sde = se_sde_main,
  class = classify(sde_main)
)

# Panel B: Heterogeneous (by law type)
sde_rows_b <- list()

# Enhanced penalty subsample
panel_pen <- panel %>% filter(first_treat == 0 |
  (!is.na(law_type) & law_type == "enhanced_penalty"))
if (nrow(panel_pen) > 50) {
  m_pen <- feols(search_index ~ treated | state_id + time_num,
                 data = panel_pen, cluster = ~state_id)
  sd_y_pen <- sd(panel_pen$search_index, na.rm = TRUE)
  sde_rows_b[["penalty"]] <- data.frame(
    outcome = "Search intensity (penalty states)",
    beta = coef(m_pen)["treated"],
    se = se(m_pen)["treated"],
    sd_y = sd_y_pen,
    sde = coef(m_pen)["treated"] / sd_y_pen,
    se_sde = se(m_pen)["treated"] / sd_y_pen,
    class = classify(coef(m_pen)["treated"] / sd_y_pen)
  )
}

# Dealer regulation subsample
panel_deal <- panel %>% filter(first_treat == 0 |
  (!is.na(law_type) & law_type == "dealer_regulation"))
if (nrow(panel_deal) > 50) {
  m_deal <- feols(search_index ~ treated | state_id + time_num,
                  data = panel_deal, cluster = ~state_id)
  sd_y_deal <- sd(panel_deal$search_index, na.rm = TRUE)
  sde_rows_b[["dealer"]] <- data.frame(
    outcome = "Search intensity (dealer reg. states)",
    beta = coef(m_deal)["treated"],
    se = se(m_deal)["treated"],
    sd_y = sd_y_deal,
    sde = coef(m_deal)["treated"] / sd_y_deal,
    se_sde = se(m_deal)["treated"] / sd_y_deal,
    class = classify(coef(m_deal)["treated"] / sd_y_deal)
  )
}

sde_b <- bind_rows(sde_rows_b)

# Build SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level catalytic converter anti-theft laws ",
  "reduce catalytic converter theft, and how does this deterrent effect compare to ",
  "the mechanical reduction in theft driven by declining commodity (palladium) prices? ",
  "\\textbf{Policy mechanism:} State laws target the catalytic converter theft supply chain ",
  "through two channels: enhanced criminal penalties (felony classification, mandatory minimums) ",
  "that raise the expected cost of theft, and scrap metal dealer regulations (purchase documentation, ",
  "holding periods, VIN marking requirements) that disrupt the fence market for stolen converters. ",
  "\\textbf{Outcome definition:} Google Trends search intensity index (0--100 scale) for ",
  "``catalytic converter theft'' at the state level, serving as a revealed community concern ",
  "proxy for local theft incidence. ",
  "\\textbf{Treatment:} Binary indicator equal to one from the quarter a state's catalytic ",
  "converter anti-theft law takes effect. ",
  "\\textbf{Data:} Google Trends state-quarter panel, NYMEX palladium futures, and NCSL ",
  "legislative records, covering 51 state-equivalents from 2017Q1 to 2025Q2. ",
  "\\textbf{Method:} Two-way fixed effects and Callaway--Sant'Anna (2021) staggered DiD, ",
  "with standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 US states plus DC; 34 treated states adopted laws between ",
  "2021 and 2024, with 17 never-treated control states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0("\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
", sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
           sde_rows_a$outcome, sde_rows_a$beta, sde_rows_a$se,
           sde_rows_a$sd_y, sde_rows_a$sde, sde_rows_a$se_sde,
           sde_rows_a$class), "
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n")

for (i in seq_len(nrow(sde_b))) {
  tabF1 <- paste0(tabF1, sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_b$outcome[i], sde_b$beta[i], sde_b$se[i], sde_b$sd_y[i],
    sde_b$sde[i], sde_b$se_sde[i], sde_b$class[i]))
}

tabF1 <- paste0(tabF1, "\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize
\\begin{itemize}[leftmargin=*]
", sde_notes, "
\\end{itemize}}
\\end{table}")

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
