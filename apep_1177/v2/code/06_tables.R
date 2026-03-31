## 06_tables.R — Generate all LaTeX tables
## apep_1177 v2: The Conviction Lottery

source("./code/00_packages.R")

vara <- fread("./data/vara_three_way.csv")
results <- readRDS("./data/main_results_v2.rds")

tables_dir <- "./tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Table 1: Summary Statistics (three offenses) ----
# Load raw data for case-level stats
traff <- as.data.table(arrow::read_parquet("./data/smoke_trafficking.parquet"))
traff[, filing_year := as.integer(substr(filing_date, 1, 4))]
traff <- traff[filing_year >= 2015 & filing_year <= 2019]

rob <- as.data.table(arrow::read_parquet("./data/smoke_robbery_corrected.parquet"))
rob <- rob[resolved == TRUE]

theft <- as.data.table(arrow::read_parquet("./data/smoke_theft_corrected.parquet"))
theft <- theft[resolved == TRUE]

summ <- data.table(
  Statistic = c("Cases", "Varas", "Mean conviction rate", "SD conviction rate",
                "P10 conviction rate", "P90 conviction rate", "P90-P10 spread",
                "Mean cases per vara"),
  `Drug Trafficking` = c(
    nrow(traff), uniqueN(traff$vara_codigo),
    sprintf("%.3f", mean(vara$rate_traff)),
    sprintf("%.3f", sd(vara$rate_traff)),
    sprintf("%.3f", quantile(vara$rate_traff, 0.10)),
    sprintf("%.3f", quantile(vara$rate_traff, 0.90)),
    sprintf("%.3f", quantile(vara$rate_traff, 0.90) - quantile(vara$rate_traff, 0.10)),
    sprintf("%.0f", mean(vara$n_traff))
  ),
  Robbery = c(
    nrow(rob), uniqueN(rob$vara_codigo),
    sprintf("%.3f", mean(vara$rate_rob)),
    sprintf("%.3f", sd(vara$rate_rob)),
    sprintf("%.3f", quantile(vara$rate_rob, 0.10)),
    sprintf("%.3f", quantile(vara$rate_rob, 0.90)),
    sprintf("%.3f", quantile(vara$rate_rob, 0.90) - quantile(vara$rate_rob, 0.10)),
    sprintf("%.0f", mean(vara$n_rob))
  ),
  Theft = c(
    nrow(theft), uniqueN(theft$vara_codigo),
    sprintf("%.3f", mean(vara$rate_theft)),
    sprintf("%.3f", sd(vara$rate_theft)),
    sprintf("%.3f", quantile(vara$rate_theft, 0.10)),
    sprintf("%.3f", quantile(vara$rate_theft, 0.90)),
    sprintf("%.3f", quantile(vara$rate_theft, 0.90) - quantile(vara$rate_theft, 0.10)),
    sprintf("%.0f", mean(vara$n_theft))
  )
)

tab1 <- kbl(summ, format = "latex", booktabs = TRUE,
            caption = "Summary Statistics: Three Offense Types in S\\~ao Paulo Central",
            label = "summary") |>
  kable_styling(latex_options = "hold_position")

tab1_notes <- paste0(tab1, "\n\\begin{flushleft}\\small\n",
                     "\\textit{Notes:} All statistics computed for the 31 criminal varas in S\\~ao Paulo Central ",
                     "handling all three offense types. Conviction rates are the share of resolved cases ",
                     "ending in \\textit{Proced\\^encia} (code 219) or \\textit{Proced\\^encia em Parte} (code 221). ",
                     "Cases filed 2015--2019. Robbery and theft restricted to resolved cases. ",
                     "Drug trafficking: \\textit{assunto} 3608; Robbery: 3419; Theft: 3416.\n\\end{flushleft}")

writeLines(tab1_notes, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written\n")

## ---- Table 2: Cross-Offense Correlation Matrix ----
cor_mat <- data.table(
  ` ` = c("Drug Trafficking", "Robbery", "Theft"),
  `Drug Trafficking` = c("1.000",
                          sprintf("%.3f", cor(vara$rate_traff, vara$rate_rob)),
                          sprintf("%.3f", cor(vara$rate_traff, vara$rate_theft))),
  Robbery = c("",
              "1.000",
              sprintf("%.3f", cor(vara$rate_rob, vara$rate_theft))),
  Theft = c("", "", "1.000")
)

tab2 <- kbl(cor_mat, format = "latex", booktabs = TRUE,
            caption = "Cross-Offense Correlation of Vara Conviction Rates",
            label = "correlations") |>
  kable_styling(latex_options = "hold_position")

tab2_notes <- paste0(tab2, "\n\\begin{flushleft}\\small\n",
                     "\\textit{Notes:} Pearson correlations of vara-level conviction rates across ",
                     "offense types. Each observation is one of 31 criminal varas in S\\~ao Paulo Central. ",
                     "Conviction rates computed from resolved cases filed 2015--2019. ",
                     "The low trafficking-theft correlation (0.102) contrasts sharply with the ",
                     "robbery-theft correlation (0.669), indicating that drug trafficking conviction ",
                     "patterns operate on a largely independent judicial dimension. ",
                     "Steiger test for difference: $z = 3.65$, $p = 0.0003$.\n\\end{flushleft}")

writeLines(tab2_notes, file.path(tables_dir, "tab2_correlations.tex"))
cat("Table 2 written\n")

## ---- Table 3: Common Severity Factor Loadings ----
# PCA from robbery + theft
rates_rt <- cbind(vara$rate_rob, vara$rate_theft)
pca <- prcomp(rates_rt, scale. = TRUE)
vara[, common_severity := pca$x[, 1]]

loadings_tab <- data.table(
  Offense = c("Drug Trafficking", "Robbery", "Theft"),
  `Loading on Common Factor` = c(
    sprintf("%.3f", cor(vara$rate_traff, vara$common_severity)),
    sprintf("%.3f", cor(vara$rate_rob, vara$common_severity)),
    sprintf("%.3f", cor(vara$rate_theft, vara$common_severity))
  ),
  `R-squared` = c(
    sprintf("%.3f", cor(vara$rate_traff, vara$common_severity)^2),
    sprintf("%.3f", cor(vara$rate_rob, vara$common_severity)^2),
    sprintf("%.3f", cor(vara$rate_theft, vara$common_severity)^2)
  )
)

tab3 <- kbl(loadings_tab, format = "latex", booktabs = TRUE,
            caption = "Offense Loadings on Common Courtroom Severity Factor",
            label = "loadings") |>
  kable_styling(latex_options = "hold_position")

tab3_notes <- paste0(tab3, "\n\\begin{flushleft}\\small\n",
                     "\\textit{Notes:} The common severity factor is the first principal component ",
                     "of robbery and theft conviction rates across 31 varas. Loading is the Pearson ",
                     "correlation between each offense's vara conviction rate and the common factor. ",
                     "$R^2$ is the share of between-vara variance explained by common severity. ",
                     "Drug trafficking loads weakly (0.316), implying that 90\\% of its between-vara ",
                     "variation is offense-specific---i.e., driven by the vague drug standard rather ",
                     "than generic courtroom severity.\n\\end{flushleft}")

writeLines(tab3_notes, file.path(tables_dir, "tab3_loadings.tex"))
cat("Table 3 written\n")

## ---- Table 4: First Stage and Balance ----
fs <- results$first_stage
bal <- results$balance

models <- list(
  "Conviction" = fs,
  "Filing Month" = bal
)

tab4_tex <- capture.output(
  msummary(models,
           stars = c('*' = .1, '**' = .05, '***' = .01),
           coef_map = c("vara_leniency" = "Vara Leniency (LOO)"),
           gof_map = c("nobs", "r.squared"),
           output = "latex",
           title = "First Stage and Balance: Drug Trafficking Cases",
           notes = c("\\\\textit{Notes:} Column 1: first stage. Column 2: balance test. ",
                     "Both include filing-year fixed effects. Standard errors clustered at vara level. ",
                     "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."))
)
# Add label manually since modelsummary doesn't do it
tab4_tex <- sub("\\\\begin\\{table\\}", "\\\\begin{table}\n\\\\label{tab:first_stage}", tab4_tex)
writeLines(tab4_tex, file.path(tables_dir, "tab4_first_stage.tex"))
cat("Table 4 written\n")

## ---- Table F1: SDE Appendix ----
# Compute SDE for the first-stage effect
beta <- coef(fs)["vara_leniency"]
se_beta <- sqrt(vcov(fs)["vara_leniency", "vara_leniency"])
sd_y <- sd(traff$convicted, na.rm = TRUE)
sde <- beta / sd_y
se_sde <- se_beta / sd_y
class_sde <- ifelse(abs(sde) > 0.15, "Large",
                    ifelse(abs(sde) > 0.05, "Moderate", "Small"))

sde_rows <- data.table(
  Outcome = "Convicted (Drug Trafficking)",
  Beta = round(beta, 4),
  SE = round(se_beta, 4),
  SD_Y = round(sd_y, 4),
  SDE = round(sde, 4),
  SE_SDE = round(se_sde, 4),
  Classification = class_sde
)

sde_tab <- kbl(sde_rows, format = "latex", booktabs = TRUE,
               col.names = c("Outcome", "$\\hat{\\beta}$", "SE",
                             "SD($Y$)", "SDE", "SE(SDE)", "Classification"),
               escape = FALSE,
               caption = "Standardized Distributional Effects",
               label = "sde") |>
  kable_styling(latex_options = "hold_position")

sde_notes <- paste0(
  "\\begin{flushleft}\\small\n",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does legal indeterminacy amplify arbitrary punishment under random case assignment? ",
  "\\textbf{Policy mechanism:} Lei 11.343/2006 provides no objective quantity thresholds for distinguishing ",
  "drug users from traffickers, granting judges broad discretion over a 5-year minimum sentence. ",
  "\\textbf{Outcome:} Binary conviction (\\textit{Proced\\^encia}) from judicial movement records. ",
  "\\textbf{Treatment:} Assignment to a more vs.\\ less severe criminal vara via electronic lottery (\\textit{sorteio}). ",
  "\\textbf{Data:} CNJ DataJud public API, TJSP first-instance cases (2015--2019), three offense types. ",
  "\\textbf{Method:} Cross-offense comparison of between-vara conviction rate variance; vara leniency IV; ",
  "common severity factor decomposition. ",
  "\\textbf{Sample:} 31 criminal varas in S\\~ao Paulo Central handling drug trafficking, robbery, and theft. ",
  "\\textbf{Key finding:} Drug trafficking conviction rates are uncorrelated ($r = 0.10$) with theft rates ",
  "but robbery-theft correlation is $r = 0.67$, indicating trafficking operates on a separate judicial dimension. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
  "Classification: Large: $|\\text{SDE}| > 0.15$; Moderate: 0.05--0.15; Small: 0.005--0.05; Null: $< 0.005$.\n",
  "\\end{flushleft}"
)

writeLines(c(sde_tab, sde_notes), file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written\n")

cat("\nAll tables generated.\n")
