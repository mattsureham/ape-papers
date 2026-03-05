## 06_tables.R — All tables (read from CSV/RDS)

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# ── Table 1: Summary statistics ──────────────────────────────────────────────
cat("Table 1: Summary statistics...\n")
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

overall <- panel[dist_to_boundary <= 500, .(
  N = .N,
  mean_price_sqm = mean(price_sqm, na.rm = TRUE),
  sd_price_sqm = sd(price_sqm, na.rm = TRUE),
  mean_surface = mean(surface, na.rm = TRUE),
  mean_rooms = mean(rooms, na.rm = TRUE),
  pct_apartment = mean(is_apartment, na.rm = TRUE) * 100,
  mean_dist = mean(dist_to_boundary, na.rm = TRUE)
), by = .(nearest_group, inside)]

overall[, group_label := paste0(
  ifelse(nearest_group == "gained", "Gained QPV", "Retained"),
  ifelse(inside, " (Inside)", " (Outside)")
)]

fwrite(overall, file.path(tab_dir, "summary_stats.csv"))

tab1_tex <- kbl(overall[, .(group_label, N, mean_price_sqm, sd_price_sqm,
                             mean_surface, mean_rooms, pct_apartment)],
  col.names = c("Group", "N", "Mean Price/sqm", "SD Price/sqm",
                "Mean Surface", "Mean Rooms", "\\% Apartment"),
  digits = c(0, 0, 0, 0, 1, 1, 1),
  format = "latex", booktabs = TRUE,
  caption = "Summary Statistics by Designation Group and Location (500m bandwidth)")

writeLines(tab1_tex, file.path(tab_dir, "tab_summary.tex"))
cat("  Saved tab_summary.tex\n")

# ── Table 2: Main regression results ────────────────────────────────────────
cat("Table 2: Main results...\n")
models <- readRDS(file.path(data_dir, "main_models.rds"))

if (!is.null(models)) {
  cm <- c(
    "inside_int" = "Inside Zone",
    "inside_x_gained" = "Inside $\\times$ Gained",
    "inside_x_retained" = "Inside $\\times$ Retained",
    "log(surface)" = "Log(Surface)",
    "rooms" = "Rooms",
    "is_apartment" = "Apartment"
  )

  gm <- list(
    list("raw" = "nobs", "clean" = "N", "fmt" = function(x) format(x, big.mark = ",")),
    list("raw" = "r.squared", "clean" = "R$^2$", "fmt" = 3),
    list("raw" = "adj.r.squared", "clean" = "Adj. R$^2$", "fmt" = 3)
  )

  options("modelsummary_format_numeric_latex" = "plain")
  options("modelsummary_factory_latex" = "kableExtra")
  tab2 <- modelsummary(
    list("(1)" = models$m1, "(2)" = models$m2,
         "(3)" = models$m3, "(4)" = models$m4),
    coef_map = cm,
    gof_map = gm,
    stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
    output = file.path(tab_dir, "tab_main.tex")
  )
  # Fix LaTeX escaping in modelsummary output
  tex <- readLines(file.path(tab_dir, "tab_main.tex"))
  tex <- gsub("\\$\\textbackslash{}times\\$", "$\\times$", tex, fixed = TRUE)
  tex <- gsub("R\\$\\textasciicircum{}2\\$", "$R^2$", tex, fixed = TRUE)
  tex <- gsub("Adj. R\\$\\textasciicircum{}2\\$", "Adj. $R^2$", tex, fixed = TRUE)
  # Add caption and label
  tex <- gsub("\\begin{table}", "\\begin{table}\n\\caption{Main Regression Results}\\label{tab:main}", tex, fixed = TRUE)
  writeLines(tex, file.path(tab_dir, "tab_main.tex"))
  cat("  Saved tab_main.tex\n")
}

# ── Table 3: RDD results ────────────────────────────────────────────────────
cat("Table 3: RDD results...\n")
rdd <- fread(file.path(data_dir, "rdd_results.csv"))

if (nrow(rdd) > 0) {
  rdd[, group_label := factor(group,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained QPV")
  )]
  rdd[, ci_lower := estimate - 1.96 * se]
  rdd[, ci_upper := estimate + 1.96 * se]
  rdd[, stars := ifelse(abs(estimate / se) > 2.576, "***",
                 ifelse(abs(estimate / se) > 1.96, "**",
                 ifelse(abs(estimate / se) > 1.645, "*", "")))]

  tab3_tex <- kbl(rdd[, .(group_label, estimate, se, bw, n_left, n_right, stars)],
    col.names = c("Group", "Estimate", "SE", "Optimal BW", "N (Inside)", "N (Outside)", ""),
    digits = c(0, 4, 4, 0, 0, 0, 0),
    format = "latex", booktabs = TRUE,
    caption = "RDD Estimates at Zone Boundaries",
    label = "rdd")

  writeLines(tab3_tex, file.path(tab_dir, "tab_rdd.tex"))
  cat("  Saved tab_rdd.tex\n")
}

# ── Table 4: Covariate balance ───────────────────────────────────────────────
cat("Table 4: Covariate balance...\n")
balance <- fread(file.path(data_dir, "covariate_balance.csv"))

if (nrow(balance) > 0) {
  balance[, stars := ifelse(abs(diff / se) > 2.576, "***",
                    ifelse(abs(diff / se) > 1.96, "**",
                    ifelse(abs(diff / se) > 1.645, "*", "")))]

  tab4_tex <- kbl(balance[, .(group, covariate, diff, se, mean_outside, pct_diff, n, stars)],
    col.names = c("Group", "Covariate", "Diff", "SE", "Mean Outside", "Pct Diff", "N", ""),
    digits = c(0, 0, 3, 3, 1, 1, 0, 0),
    format = "latex", booktabs = TRUE,
    caption = "Covariate Balance at Zone Boundaries (500m bandwidth)",
    label = "balance")

  writeLines(tab4_tex, file.path(tab_dir, "tab_balance.tex"))
  cat("  Saved tab_balance.tex\n")
}

# ── Table 5: Property type heterogeneity ─────────────────────────────────────
cat("Table 5: Type heterogeneity...\n")
type_het <- fread(file.path(data_dir, "type_heterogeneity.csv"))

if (nrow(type_het) > 0) {
  type_het[, group := gsub("inside_x_", "", coefficient)]
  type_het[, stars := ifelse(abs(estimate / se) > 2.576, "***",
                     ifelse(abs(estimate / se) > 1.96, "**",
                     ifelse(abs(estimate / se) > 1.645, "*", "")))]

  tab5_tex <- kbl(type_het[, .(property_type, group, estimate, se, n, stars)],
    col.names = c("Property Type", "Group", "Estimate", "SE", "N", ""),
    digits = c(0, 0, 4, 4, 0, 0),
    format = "latex", booktabs = TRUE,
    caption = "Designation Effects by Property Type (Mechanism Test)",
    label = "type_het")

  writeLines(tab5_tex, file.path(tab_dir, "tab_type_het.tex"))
  cat("  Saved tab_type_het.tex\n")
}

# ── Table 6: Donut RDD results ───────────────────────────────────────────────
cat("Table 6: Donut RDD...\n")
donut <- fread(file.path(data_dir, "donut_rdd.csv"))
if (nrow(donut) > 0) {
  donut[, group_label := factor(coefficient,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained QPV")
  )]
  donut[, stars := ifelse(abs(estimate / se) > 2.576, "***",
                  ifelse(abs(estimate / se) > 1.96, "**",
                  ifelse(abs(estimate / se) > 1.645, "*", "")))]

  tab6_tex <- kbl(donut[, .(donut_size, group_label, estimate, se, n, stars)],
    col.names = c("Donut (m)", "Group", "Estimate", "SE", "N", ""),
    digits = c(0, 0, 4, 4, 0, 0),
    format = "latex", booktabs = TRUE,
    caption = "Donut RDD Estimates",
    label = "donut")
  writeLines(tab6_tex, file.path(tab_dir, "tab_donut.tex"))
  cat("  Saved tab_donut.tex\n")
}

# ── Table 7: Transaction volume regression ──────────────────────────────────
cat("Table 6: Transaction volume....\n")
vol_reg <- fread(file.path(data_dir, "volume_regression.csv"))
if (nrow(vol_reg) > 0) {
  vol_reg[, group_label := factor(group,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained QPV")
  )]
  vol_reg[, stars := ifelse(abs(estimate / se) > 2.576, "***",
                    ifelse(abs(estimate / se) > 1.96, "**",
                    ifelse(abs(estimate / se) > 1.645, "*", "")))]

  tab6_tex <- kbl(vol_reg[, .(group_label, estimate, se, n, stars)],
    col.names = c("Group", "Estimate", "SE", "N", ""),
    digits = c(0, 4, 4, 0, 0),
    format = "latex", booktabs = TRUE,
    caption = "Transaction Volume at Zone Boundaries")
  writeLines(tab6_tex, file.path(tab_dir, "tab_volume.tex"))
  cat("  Saved tab_volume.tex\n")
}

cat("\n=== All tables generated ===\n")
