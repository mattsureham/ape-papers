# 06_tables.R — Generate all LaTeX tables
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

source("00_packages.R")

cat("=== PHASE 6: TABLES ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, date := as.Date(date)]

# ──────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics by Treatment Ring
# ──────────────────────────────────────────────────────────────────

cat("Table 1: Summary statistics...\n")

panel[, ring_group := "Buffer"]
panel[ring_1km == TRUE, ring_group := "Treatment (0-1km)"]
panel[control == TRUE, ring_group := "Control (>2km)"]

summ <- panel[ring_group != "Buffer", .(
  `N transactions` = .N,
  `Price per m2 (EUR)` = sprintf("%.0f", mean(price_m2)),
  `SD price per m2` = sprintf("%.0f", sd(price_m2)),
  `Surface (m2)` = sprintf("%.1f", mean(surface)),
  `Rooms` = sprintf("%.1f", mean(rooms, na.rm = TRUE)),
  `Pct apartment` = sprintf("%.1f", 100 * mean(prop_type == "apartment")),
  `Distance to station (km)` = sprintf("%.2f", mean(dist_nearest_km))
), by = ring_group]

summ_t <- t(as.matrix(summ[, -1]))
colnames(summ_t) <- summ$ring_group

# Write LaTeX table
summ_tex <- kbl(summ_t, format = "latex", booktabs = TRUE,
                caption = "Summary Statistics by Distance to Nearest GPE Station",
                label = "tab:summary") |>
  kable_styling(latex_options = c("hold_position")) |>
  add_header_above(c(" " = 1, "Treatment" = 1, "Control" = 1))

writeLines(summ_tex, file.path(TAB_DIR, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# Also save as CSV for reference
fwrite(summ, file.path(DATA_DIR, "table1_summary_stats.csv"))

# ──────────────────────────────────────────────────────────────────
# Table 2: Main Results
# ──────────────────────────────────────────────────────────────────

cat("Table 2: Main results...\n")

# Re-estimate models for modelsummary
analysis_sample <- panel[ring_1km | control]
analysis_sample[, phase := "pre"]
analysis_sample[ring_1km & post_dup & !post_construction, phase := "post_dup"]
analysis_sample[ring_1km & post_construction & !post_opening, phase := "construction"]
analysis_sample[ring_1km & post_opening, phase := "opened"]
analysis_sample[, phase := factor(phase, levels = c("pre", "post_dup", "construction", "opened"))]

m1 <- feols(log_price_m2 ~ treated_construction | commune + year_quarter,
            data = analysis_sample, cluster = ~commune)

m2 <- feols(log_price_m2 ~ treated_construction +
              surface + I(surface^2) + rooms + i(prop_type) | commune + year_quarter,
            data = analysis_sample, cluster = ~commune)

m3 <- feols(log_price_m2 ~ i(phase, ref = "pre") | commune + year_quarter,
            data = analysis_sample, cluster = ~commune)

m4 <- feols(log_price_m2 ~ i(phase, ref = "pre") +
              surface + I(surface^2) + rooms + i(prop_type) | commune + year_quarter,
            data = analysis_sample, cluster = ~commune)

# Apartments only
apt_sample <- analysis_sample[prop_type == "apartment"]
m5 <- feols(log_price_m2 ~ treated_construction +
              surface + I(surface^2) + rooms | commune + year_quarter,
            data = apt_sample, cluster = ~commune)

models <- list(
  "(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5
)

# Create summary table
cm <- c(
  "treated_constructionTRUE" = "Post-Construction x Within 1km",
  "phase::post_dup" = "Post-DUP x Within 1km",
  "phase::construction" = "Construction x Within 1km",
  "phase::opened" = "Opened x Within 1km"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within R\\textsuperscript{2}", "fmt" = 3),
  list("raw" = "FE: commune", "clean" = "Commune FE", "fmt" = function(x) ifelse(x > 0, "Yes", "No")),
  list("raw" = "FE: year_quarter", "clean" = "Year-Quarter FE", "fmt" = function(x) ifelse(x > 0, "Yes", "No"))
)

options("modelsummary_format_numeric_latex" = "plain")

modelsummary(
  models,
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  output = file.path(TAB_DIR, "tab2_main_results.tex"),
  title = "Effect of GPE Construction on Residential Property Prices \\label{tab:main_results}",
  notes = c("Standard errors clustered at the commune level in parentheses.",
            "Dependent variable: log(price per m2).",
            "Columns (1)-(2): pooled post-construction treatment.",
            "Columns (3)-(4): phase decomposition. Column (5): apartments only.")
)
cat("  Saved tab2_main_results.tex\n")

# ──────────────────────────────────────────────────────────────────
# Table 3: Distance Gradient
# ──────────────────────────────────────────────────────────────────

cat("Table 3: Distance gradient...\n")

dist_grad <- fread(file.path(DATA_DIR, "distance_gradient.csv"))
dist_grad[, stars := fifelse(abs(estimate / se) > 2.576, "***",
                    fifelse(abs(estimate / se) > 1.96, "**",
                    fifelse(abs(estimate / se) > 1.645, "*", "")))]

dist_tex <- kbl(
  dist_grad[, .(
    `Ring` = paste0("0-", ring_km, " km"),
    `Estimate` = sprintf("%.4f%s", estimate, stars),
    `SE` = sprintf("(%.4f)", se),
    `95\\% CI` = sprintf("[%.4f, %.4f]", ci_low, ci_high),
    `N treated` = format(n_treated, big.mark = ","),
    `N control` = format(n_control, big.mark = ",")
  )],
  format = "latex", booktabs = TRUE, escape = FALSE,
  caption = "Construction-Phase Capitalization by Distance Ring",
  label = "tab:distance"
) |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "Standard errors clustered at the commune level.",
           threeparttable = TRUE)

writeLines(dist_tex, file.path(TAB_DIR, "tab3_distance_gradient.tex"))
cat("  Saved tab3_distance_gradient.tex\n")

# ──────────────────────────────────────────────────────────────────
# Table 4: Composition Tests (Balance)
# ──────────────────────────────────────────────────────────────────

cat("Table 4: Composition tests...\n")

comp <- fread(file.path(DATA_DIR, "composition_test.csv"))
comp[, stars := fifelse(pval < 0.01, "***",
               fifelse(pval < 0.05, "**",
               fifelse(pval < 0.1, "*", "")))]

comp_tex <- kbl(
  comp[, .(
    Outcome = outcome,
    Estimate = sprintf("%.4f%s", estimate, stars),
    `SE` = sprintf("(%.4f)", se),
    `p-value` = sprintf("%.3f", pval)
  )],
  format = "latex", booktabs = TRUE, escape = FALSE,
  caption = "Composition Test: Effect of Construction on Property Characteristics",
  label = "tab:composition"
) |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "Regressions include commune and year-quarter fixed effects. Standard errors clustered at commune level.",
           threeparttable = TRUE)

writeLines(comp_tex, file.path(TAB_DIR, "tab4_composition.tex"))
cat("  Saved tab4_composition.tex\n")

# ──────────────────────────────────────────────────────────────────
# Table 5: Heterogeneity by Line
# ──────────────────────────────────────────────────────────────────

cat("Table 5: Heterogeneity by line...\n")

line_het <- fread(file.path(DATA_DIR, "heterogeneity_by_line.csv"))
line_het[, stars := fifelse(abs(estimate / se) > 2.576, "***",
                   fifelse(abs(estimate / se) > 1.96, "**",
                   fifelse(abs(estimate / se) > 1.645, "*", "")))]

line_tex <- kbl(
  line_het[, .(
    Line = line,
    Estimate = sprintf("%.4f%s", estimate, stars),
    SE = sprintf("(%.4f)", se),
    `95\\% CI` = sprintf("[%.4f, %.4f]", ci_low, ci_high),
    N = format(n, big.mark = ",")
  )],
  format = "latex", booktabs = TRUE, escape = FALSE,
  caption = "Construction-Phase Capitalization by GPE Line",
  label = "tab:line_het"
) |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "Each row shows a separate regression with 1km ring around stations of a single line vs. control.",
           threeparttable = TRUE)

writeLines(line_tex, file.path(TAB_DIR, "tab5_heterogeneity_line.tex"))
cat("  Saved tab5_heterogeneity_line.tex\n")

cat("\n=== TABLES COMPLETE ===\n")
