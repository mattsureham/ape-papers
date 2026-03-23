## 05_tables.R — Generate all tables for the paper
## apep_0830: VAT Receipt Lotteries and Compliance Gaps

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
lottery_events <- readRDS("../data/lottery_events.rds")

cat("=== Generating Tables ===\n")

# Helper: significance stars
stars <- function(coef, se) {
  z <- abs(coef / se)
  if (z > 2.576) return("$^{***}$")
  if (z > 1.960) return("$^{**}$")
  if (z > 1.645) return("$^{*}$")
  return("")
}

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("--- Table 1: Summary Statistics ---\n")

ever_treated <- unique(panel$geo[panel$first_treat > 0])

calc_stats <- function(df) {
  tibble(
    `VAT/GDP (\\%)` = sprintf("%.2f (%.2f)", mean(df$vat_gdp_pct), sd(df$vat_gdp_pct)),
    `Income Tax/GDP (\\%)` = sprintf("%.2f (%.2f)", mean(df$inc_tax_gdp_pct), sd(df$inc_tax_gdp_pct)),
    `GDP (bn EUR)` = sprintf("%.0f (%.0f)", mean(df$gdp_meur/1000), sd(df$gdp_meur/1000)),
    Observations = as.character(nrow(df)),
    Countries = as.character(n_distinct(df$geo))
  )
}

s_all <- calc_stats(panel)
s_treat <- calc_stats(panel |> filter(geo %in% ever_treated))
s_ctrl <- calc_stats(panel |> filter(!geo %in% ever_treated))

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Full Sample & Lottery Adopters & Never Adopted \\\\",
  "\\midrule"
)

vars <- names(s_all)
for (v in vars) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s \\\\", v, s_all[[v]], s_treat[[v]], s_ctrl[[v]]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Standard deviations in parentheses. Panel of 26 EU member states (Malta excluded), 2005--2022. Lottery adopters: CZ, EL, IT, LT, LV, PL, PT, RO, SK. VAT revenue from Eurostat \\texttt{gov\\_10a\\_taxag} (D211, S13); GDP from \\texttt{nama\\_10\\_gdp}.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Receipt Lottery Programs
# ---------------------------------------------------------------
cat("--- Table 2: Lottery Program Details ---\n")

prog_table <- lottery_events |>
  filter(geo != "MT") |>
  arrange(start_year) |>
  mutate(
    Country = case_when(
      geo == "SK" ~ "Slovakia", geo == "PT" ~ "Portugal",
      geo == "RO" ~ "Romania", geo == "PL" ~ "Poland",
      geo == "CZ" ~ "Czech Republic", geo == "EL" ~ "Greece",
      geo == "LV" ~ "Latvia", geo == "LT" ~ "Lithuania",
      geo == "IT" ~ "Italy"
    ),
    Start = as.character(start_year),
    End = ifelse(is.na(end_year), "Active", as.character(end_year + 1L)),
    Duration = ifelse(is.na(end_year),
      sprintf("%d+", 2022L - start_year + 1L),
      sprintf("%d", end_year - start_year + 1L)),
    Status = ifelse(is.na(end_year), "Active", "Cancelled")
  )

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{VAT Receipt Lottery Programs in the EU}",
  "\\label{tab:programs}",
  "\\begin{tabular}{llccl}",
  "\\toprule",
  "Country & Adopted & Cancelled & Duration (yrs) & Status \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(prog_table))) {
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
      prog_table$Country[i], prog_table$Start[i],
      prog_table$End[i], prog_table$Duration[i],
      prog_table$Status[i]))
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("\\multicolumn{5}{l}{Never-treated controls: %d EU member states} \\\\",
    n_distinct(panel$geo[panel$first_treat == 0])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Malta (1997 adoption) excluded. ``Adopted'' is the first full calendar year of operation. ``Cancelled'' is the first full year without the lottery. Sources: national tax authority announcements and EC reports.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_programs.tex")

# ---------------------------------------------------------------
# Table 3: Main Results
# ---------------------------------------------------------------
cat("--- Table 3: Main Results ---\n")

# TWFE
twfe_b  <- coef(results$twfe)["lottery"]
twfe_se <- sqrt(vcov(results$twfe)["lottery", "lottery"])
twfe_n  <- nobs(results$twfe)

# TWFE + GDP
gdp_b  <- coef(results$twfe_gdp)["lottery"]
gdp_se <- sqrt(vcov(results$twfe_gdp)["lottery", "lottery"])
gdp_n  <- nobs(results$twfe_gdp)

# CS-DiD
cs_b  <- results$att_cs$overall.att
cs_se <- results$att_cs$overall.se

# Placebo
plac_b  <- coef(rob_results$placebo_twfe)["lottery"]
plac_se <- sqrt(vcov(rob_results$placebo_twfe)["lottery", "lottery"])

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Receipt Lotteries on VAT Revenue (\\% of GDP)}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & TWFE & TWFE + GDP & CS-DiD & Placebo \\\\",
  " & VAT/GDP & VAT/GDP & VAT/GDP & Inc.\\ Tax/GDP \\\\",
  "\\midrule",
  sprintf("Receipt Lottery & %s%s & %s%s & %s%s & %s%s \\\\",
    sprintf("%.3f", twfe_b), stars(twfe_b, twfe_se),
    sprintf("%.3f", gdp_b), stars(gdp_b, gdp_se),
    sprintf("%.3f", cs_b), stars(cs_b, cs_se),
    sprintf("%.3f", plac_b), stars(plac_b, plac_se)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
    twfe_se, gdp_se, cs_se, plac_se),
  "\\midrule",
  "Country FE & Yes & Yes & --- & Yes \\\\",
  "Year FE & Yes & Yes & --- & Yes \\\\",
  "GDP growth & No & Yes & No & No \\\\",
  sprintf("Observations & %d & %d & --- & %d \\\\",
    twfe_n, gdp_n, nobs(rob_results$placebo_twfe)),
  sprintf("RI $p$-value & & & & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable in columns (1)--(3): VAT revenue as percentage of GDP. ",
    "Column (4): income tax revenue as percentage of GDP (placebo---receipt lotteries should not affect income taxes). ",
    "Column (1): two-way fixed effects. Column (2): adds GDP growth rate. ",
    "Column (3): Callaway and Sant'Anna (2021), restricted to adoption windows ",
    "(post-cancellation years excluded); ``never-treated'' control group. ",
    sprintf("Randomization inference $p$-value for column (1): %.3f (1,000 permutations). ", rob_results$ri_p),
    "Standard errors clustered at country level in parentheses. ",
    "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")

# ---------------------------------------------------------------
# Table 4: Robustness — Cancellation, Heterogeneity, Alt outcome
# ---------------------------------------------------------------
cat("--- Table 4: Robustness ---\n")

# Cancellation
cancel_b  <- coef(rob_results$cancel_twfe)["post_cancel"]
cancel_se <- sqrt(vcov(rob_results$cancel_twfe)["post_cancel", "post_cancel"])

# Alt outcome
alt_b  <- coef(rob_results$alt_twfe)["lottery"]
alt_se <- sqrt(vcov(rob_results$alt_twfe)["lottery", "lottery"])

# Heterogeneity
het_coefs <- coef(rob_results$het_twfe)
het_ses   <- sqrt(diag(vcov(rob_results$het_twfe)))
# These will be lottery:high_baseline::0 and lottery:high_baseline::1
het_names <- names(het_coefs)
idx_low  <- grep("0$", het_names)
idx_high <- grep("1$", het_names)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Cancellation Reversal, Alternative Outcome, and Heterogeneity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Post-Cancellation & VAT/Prod.\\ Taxes & VAT/GDP \\\\",
  "\\midrule",
  sprintf("Post-Cancellation & %s%s & & \\\\",
    sprintf("%.3f", cancel_b), stars(cancel_b, cancel_se)),
  sprintf(" & (%.3f) & & \\\\", cancel_se),
  sprintf("Receipt Lottery & & %s%s & \\\\",
    sprintf("%.3f", alt_b), stars(alt_b, alt_se)),
  sprintf(" & & (%.3f) & \\\\", alt_se)
)

if (length(idx_low) > 0 && length(idx_high) > 0) {
  tab4_lines <- c(tab4_lines,
    sprintf("Lottery $\\times$ Low baseline & & & %s%s \\\\",
      sprintf("%.3f", het_coefs[idx_low]), stars(het_coefs[idx_low], het_ses[idx_low])),
    sprintf(" & & & (%.3f) \\\\", het_ses[idx_low]),
    sprintf("Lottery $\\times$ High baseline & & & %s%s \\\\",
      sprintf("%.3f", het_coefs[idx_high]), stars(het_coefs[idx_high], het_ses[idx_high])),
    sprintf(" & & & (%.3f) \\\\", het_ses[idx_high])
  )
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "Country FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d \\\\",
    nobs(rob_results$cancel_twfe), nobs(rob_results$alt_twfe), nobs(rob_results$het_twfe)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  paste0("\\item \\textit{Notes:} Column (1): cancellation reversal test. Sample restricted to countries that cancelled ",
    "their lottery (SK, CZ, PL, LV) plus never-treated controls, starting from each country's adoption year. ",
    "A negative coefficient indicates VAT/GDP declines after cancellation. ",
    "Column (2): VAT revenue as share of total taxes on production and imports. ",
    "Column (3): heterogeneity by baseline (2005) VAT/GDP level; ``Low'' and ``High'' split at the country median. ",
    "Standard errors clustered at country level. ",
    "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) — Mandatory Appendix
# ---------------------------------------------------------------
cat("--- Table F1: SDE ---\n")

sd_y_pre <- sd(panel$vat_gdp_pct[panel$lottery == 0 & panel$year < 2013])
sde_main <- twfe_b / sd_y_pre
sde_se_main <- twfe_se / sd_y_pre

sd_y_inc_pre <- sd(panel$inc_tax_gdp_pct[panel$lottery == 0 & panel$year < 2013])
sde_plac <- plac_b / sd_y_inc_pre
sde_se_plac <- plac_se / sd_y_inc_pre

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

class_main <- classify_sde(sde_main)
class_plac <- classify_sde(sde_plac)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (26 member states, excluding Malta). ",
  "\\textbf{Research question:} Do VAT receipt lottery programs, which incentivize consumers to request tax receipts, reduce the VAT compliance gap by leveraging the consumer-as-auditor mechanism? ",
  "\\textbf{Policy mechanism:} Governments hold periodic prize drawings among consumers who register receipts from retail transactions, creating a pecuniary incentive for consumers to demand receipts and thereby generating a third-party paper trail that constrains vendor underreporting of sales to the tax authority. ",
  "\\textbf{Outcome definition:} VAT revenue as percentage of GDP, computed from Eurostat government finance statistics (tax category D211, general government sector S13) divided by GDP at current market prices (B1GQ). ",
  "\\textbf{Treatment:} Binary indicator equal to one in country-years when a national receipt lottery program is actively operating. ",
  "\\textbf{Data:} Eurostat \\texttt{gov\\_10a\\_taxag} and \\texttt{nama\\_10\\_gdp}, 2005--2022, 26 EU member states, ",
  sprintf("%d country-year observations. ", nrow(panel)),
  "\\textbf{Method:} Two-way fixed effects with country and year fixed effects; standard errors clustered at country level; robustness via Callaway and Sant'Anna (2021). ",
  "\\textbf{Sample:} EU-27 excluding Malta (1997 adoption pre-dates panel); 9 treated countries with staggered adoption 2013--2021; 17 never-treated controls; 4 cancellations provide reversal tests. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("VAT/GDP (\\%%) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
    twfe_b, twfe_se, sd_y_pre, sde_main, sde_se_main, class_main),
  sprintf("Inc.\\ Tax/GDP (\\%%, placebo) & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
    plac_b, plac_se, sd_y_inc_pre, sde_plac, sde_se_plac, class_plac),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab_sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
