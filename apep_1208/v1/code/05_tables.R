## 05_tables.R — Generate all LaTeX tables
## apep_1208: Ghana DDEP and Private Sector Credit

source("00_packages.R")

analysis <- readRDS("../data/balanced_panel.rds")
scm_results <- readRDS("../data/scm_results.rds")
placebo_results <- readRDS("../data/placebo_results.rds")
did_results <- readRDS("../data/did_results.rds")
npl_results <- tryCatch(readRDS("../data/npl_results.rds"), error = function(e) NULL)

treatment_year <- 2023
gap_df <- scm_results$gap_df

## =========================================
## TABLE 1: Summary Statistics
## =========================================

cat("Generating Table 1: Summary Statistics\n")

pre_data <- analysis %>%
  filter(year >= 2010, year < treatment_year)

ghana_stats <- pre_data %>%
  filter(iso3c == "GHA") %>%
  summarise(across(c(credit_gdp, npl_ratio, gdp_growth, inflation, trade_gdp, gdp_pc),
                   list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)),
                   .names = "{.col}_{.fn}"))

donor_stats <- pre_data %>%
  filter(iso3c != "GHA") %>%
  summarise(across(c(credit_gdp, npl_ratio, gdp_growth, inflation, trade_gdp, gdp_pc),
                   list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)),
                   .names = "{.col}_{.fn}"))

var_labels <- c("Domestic credit to private sector (\\% GDP)",
                "Non-performing loans (\\% total)",
                "GDP growth (\\%)",
                "Inflation (\\%)",
                "Trade (\\% GDP)",
                "GDP per capita (constant 2015 US\\$)")

vars <- c("credit_gdp", "npl_ratio", "gdp_growth", "inflation", "trade_gdp", "gdp_pc")

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics, Pre-DDEP Period (2010--2022)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Ghana} & \\multicolumn{2}{c}{SSA Donors} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in seq_along(vars)) {
  v <- vars[i]
  gm <- ghana_stats[[paste0(v, "_mean")]]
  gs <- ghana_stats[[paste0(v, "_sd")]]
  dm <- donor_stats[[paste0(v, "_mean")]]
  ds <- donor_stats[[paste0(v, "_sd")]]

  if (v == "gdp_pc") {
    line <- sprintf("%s & %s & %s & %s & %s \\\\",
                    var_labels[i],
                    format(round(gm, 0), big.mark = ","),
                    format(round(gs, 0), big.mark = ","),
                    format(round(dm, 0), big.mark = ","),
                    format(round(ds, 0), big.mark = ","))
  } else {
    line <- sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
                    var_labels[i], gm, gs, dm, ds)
  }
  tab1_lines <- c(tab1_lines, line)
}

n_ghana <- pre_data %>% filter(iso3c == "GHA") %>% nrow()
n_donors <- n_distinct(pre_data$iso3c[pre_data$iso3c != "GHA"])

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Country-years & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          n_ghana, nrow(pre_data) - n_ghana),
  sprintf("Countries & \\multicolumn{2}{c}{1} & \\multicolumn{2}{c}{%d} \\\\", n_donors),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment summary statistics for Ghana and the SSA donor pool (2010--2022). Data from World Bank World Development Indicators. GDP per capita in constant 2015 US dollars.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Saved tables/tab1_summary.tex\n")

## =========================================
## TABLE 2: SCM Donor Weights and Predictor Balance
## =========================================

cat("Generating Table 2: SCM Weights and Balance\n")

synth_tables <- scm_results$synth_tables
weights_df <- as.data.frame(synth_tables$tab.w)
weights_df$country <- rownames(weights_df)

# Only show donors with weight > 0.01
sig_weights <- weights_df %>%
  filter(w.weights > 0.01) %>%
  arrange(desc(w.weights))

# Predictor balance
pred_bal <- as.data.frame(synth_tables$tab.pred)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Synthetic Control: Donor Weights and Predictor Balance}",
  "\\label{tab:scm_weights}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "\\multicolumn{2}{l}{\\textit{Panel A: Donor Weights}} \\\\",
  "\\midrule",
  "Country & Weight \\\\"
)

for (r in 1:nrow(sig_weights)) {
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %.3f \\\\", sig_weights$country[r], sig_weights$w.weights[r]))
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Panel B: Predictor Balance}} \\\\",
  "\\midrule",
  "Predictor & Ghana \\quad Synthetic \\\\"
)

for (r in 1:nrow(pred_bal)) {
  pname <- rownames(pred_bal)[r]
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %.2f \\quad %.2f \\\\", pname, pred_bal[r, 1], pred_bal[r, 2]))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A shows synthetic control donor weights (only countries with weight $>$ 0.01). Panel B shows predictor balance between Ghana and synthetic Ghana. Pre-treatment period: 2010--2022.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_scm_weights.tex")
cat("  Saved tables/tab2_scm_weights.tex\n")

## =========================================
## TABLE 3: Main Results — SCM Gap Estimates
## =========================================

cat("Generating Table 3: SCM Gap Estimates\n")

# Post-treatment gaps
post_gaps <- gap_df %>% filter(year >= treatment_year)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of DDEP on Domestic Credit to Private Sector (\\% GDP)}",
  "\\label{tab:main_results}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{SCM} & & \\multicolumn{2}{c}{DiD} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){5-6}",
  " & Gap & \\textit{p}-value & & Estimate & SE \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Main Outcome --- Credit/GDP}} \\\\"
)

# SCM results
did_base <- did_results$did_base
did_controls <- did_results$did_controls

for (r in 1:nrow(post_gaps)) {
  yr <- post_gaps$year[r]
  gp <- post_gaps$gap[r]
  # Only report p-value for pooled post period
  if (r == 1) {
    tab3_lines <- c(tab3_lines,
      sprintf("%d & %.2f & [%.3f] & & %.2f & (%.2f) \\\\",
              yr, gp, placebo_results$p_value,
              coef(did_base)["treat_post"], se(did_base)["treat_post"]))
  } else {
    tab3_lines <- c(tab3_lines,
      sprintf("%d & %.2f & & & & \\\\", yr, gp))
  }
}

# Add DiD with controls
tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("DiD with controls & & & & %.2f & (%.2f) \\\\",
          coef(did_controls)["treat_post"], se(did_controls)["treat_post"])
)

# NPL mechanism
if (!is.null(npl_results)) {
  tab3_lines <- c(tab3_lines,
    "\\midrule",
    "\\multicolumn{6}{l}{\\textit{Panel B: Mechanism --- Non-Performing Loans (\\% total)}} \\\\",
    sprintf("Post-DDEP & & & & %.2f & (%.2f) \\\\",
            coef(npl_results)["treat_post"], se(npl_results)["treat_post"])
  )
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Pre-treatment MSPE & \\multicolumn{2}{c}{%.4f} & & & \\\\", scm_results$pre_mspe),
  sprintf("Countries & \\multicolumn{2}{c}{%d} & & \\multicolumn{2}{c}{%d} \\\\",
          n_distinct(analysis$iso3c), n_distinct(analysis$iso3c)),
  sprintf("Years & \\multicolumn{2}{c}{2010--2024} & & \\multicolumn{2}{c}{2010--2024} \\\\"),
  "Country FE & & & & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & & & & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports the effect of Ghana's 2022 DDEP on domestic credit to the private sector (\\% GDP). SCM columns show the gap between Ghana and synthetic Ghana; \\textit{p}-value from in-space placebo tests. DiD columns show two-way fixed effects estimates with standard errors clustered at the country level. Panel B shows the NPL mechanism channel. Pre-treatment period: 2010--2022. Post-treatment: 2023--2024.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main_results.tex")
cat("  Saved tables/tab3_main_results.tex\n")

## =========================================
## TABLE 4: Event Study Coefficients
## =========================================

cat("Generating Table 4: Event Study\n")

es_model <- did_results$es_model
es_coefs <- coef(es_model)
es_ses <- se(es_model)
es_names <- names(es_coefs)

# Map coefficient names to event times
event_times <- c(-5, -4, -3, -2, 0, 1, 2)
event_labels <- c("$t-5$", "$t-4$", "$t-3$", "$t-2$", "$t$ (DDEP)", "$t+1$", "$t+2$")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Credit/GDP Around the DDEP}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Time & Estimate & SE \\\\",
  "\\midrule"
)

for (i in seq_along(es_names)) {
  stars <- ""
  pval <- 2 * pt(abs(es_coefs[i] / es_ses[i]), df = n_distinct(analysis$iso3c) - 2, lower.tail = FALSE)
  if (pval < 0.01) stars <- "***"
  else if (pval < 0.05) stars <- "**"
  else if (pval < 0.10) stars <- "*"

  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.2f%s & (%.2f) \\\\", event_labels[i], es_coefs[i], stars, es_ses[i]))
}

# Add omitted period
tab4_lines <- c(tab4_lines,
  "$t-1$ (ref.) & \\multicolumn{2}{c}{---} \\\\")

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "Country FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(analysis %>% filter(!is.na(credit_gdp))), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event study estimates for Ghana's credit-to-GDP ratio relative to SSA comparators. Event time 0 corresponds to 2023 (first full year of DDEP). Omitted category: $t-1$ (2022). Standard errors clustered at the country level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_event_study.tex")
cat("  Saved tables/tab4_event_study.tex\n")

## =========================================
## TABLE 5: Robustness
## =========================================

cat("Generating Table 5: Robustness\n")

loo_results <- tryCatch(readRDS("../data/loo_results.rds"), error = function(e) list())
scm_short <- tryCatch(readRDS("../data/scm_short_window.rds"), error = function(e) NULL)
placebo_time <- tryCatch(readRDS("../data/placebo_time_results.rds"), error = function(e) NULL)
did_twoway <- tryCatch(readRDS("../data/did_twoway.rds"), error = function(e) NULL)

# Main SCM gap at 2023
main_gap <- gap_df$gap[gap_df$year == 2023]

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Estimate & Notes \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: SCM Specifications}} \\\\",
  sprintf("Baseline (2010--2022 donors) & %.2f & Main result \\\\", main_gap)
)

# LOO results
if (length(loo_results) > 0) {
  loo_gaps <- sapply(loo_results, function(x) x$gap_2023)
  tab5_lines <- c(tab5_lines,
    sprintf("Leave-one-out range & [%.2f, %.2f] & %d donors dropped \\\\",
            min(loo_gaps), max(loo_gaps), length(loo_gaps)))
}

# Short window
if (!is.null(scm_short)) {
  short_gap_2023 <- scm_short$gap[scm_short$year == 2023]
  if (length(short_gap_2023) > 0) {
    tab5_lines <- c(tab5_lines,
      sprintf("Short pre-period (2015--2022) & %.2f & \\\\", short_gap_2023))
  }
}

# Placebo in time
if (!is.null(placebo_time)) {
  fake_gaps <- placebo_time$gap[placebo_time$year >= 2019 & placebo_time$year <= 2022]
  tab5_lines <- c(tab5_lines,
    sprintf("Placebo-in-time (fake 2019) & [%.2f, %.2f] & Pre-DDEP period \\\\",
            min(fake_gaps), max(fake_gaps)))
}

# DiD robustness
tab5_lines <- c(tab5_lines,
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: DiD Specifications}} \\\\",
  sprintf("Baseline (country cluster) & %.2f (%.2f) & \\\\",
          coef(did_results$did_base)["treat_post"], se(did_results$did_base)["treat_post"]),
  sprintf("With controls & %.2f (%.2f) & \\\\",
          coef(did_results$did_controls)["treat_post"], se(did_results$did_controls)["treat_post"])
)

if (!is.null(did_twoway)) {
  tab5_lines <- c(tab5_lines,
    sprintf("Two-way clustering & %.2f (%.2f) & \\\\",
            coef(did_twoway)["treat_post"], se(did_twoway)["treat_post"]))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A shows SCM gap estimates (percentage points of GDP) under alternative specifications. Panel B shows DiD estimates with standard errors in parentheses, clustered as indicated. Leave-one-out drops each top-weighted donor country individually. Placebo-in-time assigns treatment to 2019 using only pre-DDEP data (2010--2022).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")
cat("  Saved tables/tab5_robustness.tex\n")

## =========================================
## TABLE F1: Standardized Effect Sizes (SDE)
## =========================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE from DiD estimates
# SDE = beta_hat / SD(Y) where SD(Y) is pre-treatment SD of credit/GDP
pre_sd_credit <- sd(analysis$credit_gdp[analysis$iso3c == "GHA" & analysis$year < treatment_year],
                    na.rm = TRUE)

did_coef <- coef(did_results$did_base)["treat_post"]
did_se <- se(did_results$did_base)["treat_post"]

sde_credit <- did_coef / pre_sd_credit
se_sde_credit <- did_se / pre_sd_credit

# NPL mechanism
if (!is.null(npl_results)) {
  pre_sd_npl <- sd(analysis$npl_ratio[analysis$iso3c == "GHA" & analysis$year < treatment_year],
                   na.rm = TRUE)
  npl_coef <- coef(npl_results)["treat_post"]
  npl_se <- se(npl_results)["treat_post"]

  if (!is.na(pre_sd_npl) && pre_sd_npl > 0) {
    sde_npl <- npl_coef / pre_sd_npl
    se_sde_npl <- npl_se / pre_sd_npl
  } else {
    sde_npl <- NA; se_sde_npl <- NA
  }
} else {
  sde_npl <- NA; se_sde_npl <- NA
  npl_coef <- NA; npl_se <- NA
  pre_sd_npl <- NA
}

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneity by income group
# Split donors into low-income vs middle-income, compare Ghana's gap
# We use GDP per capita median split
pre_gdp_pc <- analysis %>%
  filter(year < treatment_year, iso3c != "GHA") %>%
  group_by(iso3c) %>%
  summarise(gdp_pc_mean = mean(gdp_pc, na.rm = TRUE), .groups = "drop")

median_gdp <- median(pre_gdp_pc$gdp_pc_mean, na.rm = TRUE)

low_income_donors <- pre_gdp_pc$iso3c[pre_gdp_pc$gdp_pc_mean < median_gdp]
mid_income_donors <- pre_gdp_pc$iso3c[pre_gdp_pc$gdp_pc_mean >= median_gdp]

# DiD vs low-income donors only
did_low <- feols(credit_gdp ~ treat_post | iso3c + year,
                 data = analysis %>% filter(iso3c %in% c("GHA", low_income_donors), !is.na(credit_gdp)),
                 cluster = ~iso3c)

did_mid <- feols(credit_gdp ~ treat_post | iso3c + year,
                 data = analysis %>% filter(iso3c %in% c("GHA", mid_income_donors), !is.na(credit_gdp)),
                 cluster = ~iso3c)

sde_low <- coef(did_low)["treat_post"] / pre_sd_credit
se_sde_low <- se(did_low)["treat_post"] / pre_sd_credit

sde_mid <- coef(did_mid)["treat_post"] / pre_sd_credit
se_sde_mid <- se(did_mid)["treat_post"] / pre_sd_credit

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Ghana. ",
  "\\textbf{Research question:} Did Ghana's 2022 Domestic Debt Exchange Programme, which forced banks to accept a 30\\% NPV haircut on sovereign bonds, cause a collapse in domestic credit to the private sector? ",
  "\\textbf{Policy mechanism:} The DDEP required all 22 universal banks to exchange GHS 137 billion in government bonds for new instruments with zero coupons in 2023, imparing bank balance sheets by GHS 16.3 billion and reducing the capital adequacy ratio threshold from 13\\% to 10\\%, creating a binding credit supply constraint. ",
  "\\textbf{Outcome definition:} Domestic credit to private sector as a share of GDP (WDI indicator FD.AST.PRVT.GD.ZS), measuring the financial resources provided to the private sector through loans, purchases of non-equity securities, and trade credits. ",
  "\\textbf{Treatment:} Binary; Ghana in the post-DDEP period (2023--) versus pre-DDEP period and 13 SSA comparator countries. ",
  "\\textbf{Data:} World Bank World Development Indicators, 2010--2023, country-year panel, 14 SSA countries. ",
  "\\textbf{Method:} Synthetic control method (primary) with in-space placebo inference; two-way fixed effects DiD (secondary) with standard errors clustered at the country level. ",
  "\\textbf{Sample:} 14 Sub-Saharan African countries (Ghana plus 13 donors); donor pool excludes countries with concurrent sovereign restructuring or incomplete credit data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for Ghana. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Credit/GDP & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          did_coef, did_se, pre_sd_credit, sde_credit, se_sde_credit, classify_sde(sde_credit))
)

if (!is.na(sde_npl)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("NPL ratio & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
            npl_coef, npl_se, pre_sd_npl, sde_npl, se_sde_npl, classify_sde(sde_npl)))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by comparator income)}} \\\\",
  sprintf("Credit/GDP (low-income donors) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          coef(did_low)["treat_post"], se(did_low)["treat_post"], pre_sd_credit,
          sde_low, se_sde_low, classify_sde(sde_low)),
  sprintf("Credit/GDP (middle-income donors) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          coef(did_mid)["treat_post"], se(did_mid)["treat_post"], pre_sd_credit,
          sde_mid, se_sde_mid, classify_sde(sde_mid)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize",
  sde_notes,
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\nDONE: 05_tables.R\n")
