# 06_tables.R — Generate all LaTeX tables for Egypt devaluation paper
# APEP-0569: Egypt Devaluation Import Compression

source("00_packages.R")
DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

# Use kableExtra backend for modelsummary (avoids tinytable dependency)
options("modelsummary_format_numeric_latex" = "plain")

# Load models
load(file.path(DATA_DIR, "models.RData"))

# Load panel for summary stats
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, bec3 := factor(bec3, levels = c("intermediate", "capital", "final"))]
panel_nf <- panel[bec_category != "fuels"]

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Table 1: Summary statistics...\n")

summ <- panel_nf[, .(
  Products = uniqueN(hs6),
  Obs = .N,
  `Mean Import (\\$M)` = round(mean(import_value, na.rm = TRUE) / 1e6, 2),
  `Median Import (\\$M)` = round(median(import_value, na.rm = TRUE) / 1e6, 2),
  `SD Import (\\$M)` = round(sd(import_value, na.rm = TRUE) / 1e6, 2),
  `Total (\\$B)` = round(sum(import_value, na.rm = TRUE) / 1e9, 1)
), by = .(Category = fifelse(bec3 == "intermediate", "Intermediate",
  fifelse(bec3 == "capital", "Capital", "Final consumption")))]

# Add pre/post breakdown
summ_period <- panel_nf[, .(
  `Mean Pre (\\$M)` = round(mean(import_value[year <= 2016], na.rm = TRUE) / 1e6, 2),
  `Mean Post (\\$M)` = round(mean(import_value[year >= 2017], na.rm = TRUE) / 1e6, 2),
  `\\% Change` = round(
    (mean(import_value[year >= 2017], na.rm = TRUE) /
      mean(import_value[year <= 2016], na.rm = TRUE) - 1) * 100, 1)
), by = .(Category = fifelse(bec3 == "intermediate", "Intermediate",
  fifelse(bec3 == "capital", "Capital", "Final consumption")))]

summ_full <- merge(summ, summ_period, by = "Category")

# Write LaTeX
tex1 <- kbl(summ_full, format = "latex", booktabs = TRUE, escape = FALSE,
  caption = "Summary Statistics: Egyptian Imports by BEC End-Use Category, 2010--2023",
  label = "tab:summary") |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = "Data from UN Comtrade. Products classified by Broad Economic Categories (BEC). Fuels (HS~27) excluded. Pre-period: 2010--2016; post-period: 2017--2023.",
    threeparttable = TRUE, escape = FALSE)

writeLines(tex1, file.path(TABLE_DIR, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Table 2: Main results...\n")

# Model labels
model_names <- c(
  "(1)" = "m1b",
  "(2)" = "m3",
  "(3)" = "m4"
)

cm <- c(
  "post:is_intermediate" = "Post $\\times$ Intermediate",
  "post:is_capital" = "Post $\\times$ Capital",
  "post:is_industrial" = "Post $\\times$ Industrial",
  "post:is_intermediate:log_pre_import" = "Post $\\times$ Interm. $\\times$ Pre-Import",
  "post:is_capital:log_pre_import" = "Post $\\times$ Capital $\\times$ Pre-Import",
  "post:log_pre_import" = "Post $\\times$ Pre-Import"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: product_id", "clean" = "Product FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

tex2 <- modelsummary(
  list("Log Imports" = m1b, "Log Imports" = m3, "Imported (0/1)" = m4),
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = "kableExtra",
  escape = FALSE,
  title = "Effect of the 2016 Devaluation on Egyptian Imports by End-Use Category"
) |> kable_styling(latex_options = c("hold_position")) |>
  footnote(general = paste(
    "Standard errors clustered at HS2 chapter level in parentheses.",
    "Final consumption goods are the omitted category.",
    "Post = 1 for years 2017--2023. Product and year fixed effects in all specifications.",
    "Column (2) interacts treatment with pre-devaluation import level.",
    "Column (3): extensive margin (indicator for positive imports)."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tex2, file.path(TABLE_DIR, "tab2_main_results.tex"))

# ============================================================
# Table 3: Value vs. Weight Decomposition
# ============================================================
cat("Table 3: Value vs. weight decomposition...\n")

if (!is.null(m5_weight) && !is.null(m5_uv)) {
  tex3 <- modelsummary(
    list("Log Weight" = m5_weight, "Log Unit Value" = m5_uv, "Log Total Value" = m1b),
    coef_map = cm,
    gof_map = gm,
    stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
    output = "kableExtra",
    escape = FALSE,
    title = "Decomposition: Quantity vs. Unit Value Response"
  ) |> kable_styling(latex_options = c("hold_position")) |>
    footnote(general = paste(
      "Standard errors clustered at HS2 chapter level in parentheses.",
      "Sample restricted to products with positive net weight data.",
      "Log unit value = log(import value / net weight in kg)."
    ), threeparttable = TRUE, escape = FALSE)
  writeLines(tex3, file.path(TABLE_DIR, "tab3_decomposition.tex"))
}

# ============================================================
# Table C.1: Robustness — Alternative specifications
# ============================================================
cat("Table C.1: Robustness specifications...\n")

load(file.path(DATA_DIR, "robustness_models.RData"))

tex_c1 <- modelsummary(
  list(
    "Baseline" = m1b,
    "Asinh" = m_asinh,
    "Incl. Fuels" = m_full,
    "2-Way BEC" = m_2way,
    "Placebo (2013)" = m_placebo
  ),
  coef_map = c(cm, c(
    "post_placebo:is_intermediate" = "Placebo $\\times$ Intermediate",
    "post_placebo:is_capital" = "Placebo $\\times$ Capital",
    "post:is_fuels" = "Post $\\times$ Fuels"
  )),
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = "kableExtra",
  escape = FALSE,
  title = "Robustness: Alternative Specifications and Placebo Tests"
) |> kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = paste(
    "Standard errors clustered at HS2 chapter level in parentheses.",
    "Col. (1): baseline. (2): asinh. (3): including fuels. (4): two-way BEC. (5): placebo 2013."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tex_c1, file.path(TABLE_DIR, "tabC1_robustness.tex"))

# ============================================================
# Table F.1: Standardized Effect Sizes
# ============================================================
cat("Table F.1: Standardized effect sizes...\n")

sde <- fread(file.path(DATA_DIR, "sde_table.csv"))
sde[, Classification := fifelse(abs(sde) < 0.05, "Null",
  fifelse(sde > 0.10, "Large positive",
    fifelse(sde > 0.05, "Small positive",
      fifelse(sde > -0.05, "Null",
        fifelse(sde > -0.10, "Small negative", "Large negative")))))]

tex_f1 <- kbl(sde[, .(Outcome = outcome, Specification = specification,
  `$\\hat{\\beta}$` = round(beta, 4),
  `SD(Y)` = round(sd_y, 4),
  SDE = round(sde, 4),
  Classification)],
format = "latex", booktabs = TRUE, escape = FALSE,
caption = "Standardized Effect Sizes",
label = "tab:sde") |>
  kable_styling(latex_options = c("hold_position")) |>
  footnote(general = paste(
    "This table reports standardized effect sizes (SDE = $\\hat{\\beta}$/SD(Y)) for the main causal estimates.",
    "The research question is whether Egypt's November 2016 devaluation compressed imports of final consumption goods",
    "more than intermediate inputs. Data: UN Comtrade HS6-level annual import values for Egypt, 2010--2023.",
    "Unit of observation: HS6 product-year. Estimation: OLS with product and year fixed effects, standard errors",
    "clustered at HS2 chapter level. The treatment is binary (post-devaluation indicator interacted with BEC category).",
    "SD(Y) is the unconditional standard deviation of log import values across all product-years.",
    "Classification: large ($|$SDE$|$ $>$ 0.10), small (0.05--0.10), null ($<$ 0.05)."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tex_f1, file.path(TABLE_DIR, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
