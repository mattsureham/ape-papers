# 06_tables.R — Generate LaTeX tables for Pakistan 2022 Floods paper

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# ============================================================================
# Load data and results
# ============================================================================
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
flood_intensity <- readRDS(file.path(data_dir, "flood_intensity.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

panel[, tehsil_id := as.factor(tehsil_id)]
panel[, season_year := as.factor(season_year)]
panel[, district := as.factor(district)]

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Treatment group stats
flood_intensity[, flood_group := fcase(
  pct_flooded < 5, "Control (<5\\%)",
  pct_flooded >= 5 & pct_flooded < 20, "Low (5--20\\%)",
  pct_flooded >= 20 & pct_flooded < 50, "Moderate (20--50\\%)",
  pct_flooded >= 50, "Severe (>50\\%)"
)]

group_stats <- flood_intensity[, .(
  N = .N,
  `Mean Flood (\\%)` = sprintf("%.1f", mean(pct_flooded)),
  `SD Flood (\\%)` = sprintf("%.1f", sd(pct_flooded)),
  `Mean Area (km\\textsuperscript{2})` = sprintf("%.0f", mean(total_area_km2))
), by = .(Group = flood_group)]

# NDVI stats by season and period
ndvi_stats <- panel[, .(
  `Mean NDVI` = sprintf("%.3f", mean(ndvi_mean, na.rm = TRUE)),
  `SD NDVI` = sprintf("%.3f", sd(ndvi_mean, na.rm = TRUE)),
  N = .N
), by = .(Season = ifelse(season_type == "kharif", "Kharif", "Rabi"),
          Period = ifelse(post == 1, "Post-Flood", "Pre-Flood"))]

# Write Table 1
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("\\\\[-1.8ex]\n")

# Panel A: Treatment groups
cat("\\multicolumn{5}{l}{\\textit{Panel A: Flood Exposure Groups}} \\\\\n")
cat("\\hline\n")
cat("Group & Tehsils & Mean Flood (\\%) & SD Flood (\\%) & Mean Area (km$^2$) \\\\\n")
cat("\\hline\n")
for (i in seq_len(nrow(group_stats))) {
  cat(sprintf("%s & %d & %s & %s & %s \\\\\n",
              group_stats$Group[i], group_stats$N[i],
              group_stats$`Mean Flood (\\%)`[i],
              group_stats$`SD Flood (\\%)`[i],
              group_stats$`Mean Area (km\\textsuperscript{2})`[i]))
}

# Panel B: NDVI by season
cat("\\\\[-1.8ex]\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: NDVI by Season and Period}} \\\\\n")
cat("\\hline\n")
cat("Season $\\times$ Period & Obs. & Mean NDVI & SD NDVI & \\\\\n")
cat("\\hline\n")
ndvi_stats <- ndvi_stats[order(Season, Period)]
for (i in seq_len(nrow(ndvi_stats))) {
  cat(sprintf("%s, %s & %d & %s & %s & \\\\\n",
              ndvi_stats$Season[i], ndvi_stats$Period[i],
              ndvi_stats$N[i], ndvi_stats$`Mean NDVI`[i],
              ndvi_stats$`SD NDVI`[i]))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Panel A reports flood exposure statistics across 141 tehsils. ")
cat("Treatment is defined as $\\geq$5\\% of tehsil area flooded. ")
cat("Panel B reports NDVI statistics by crop season and pre/post-flood period. ")
cat("Kharif is the summer crop season (June--October); Rabi is the winter crop season (November--March).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("=== Table 2: Main Results ===\n")

sink(file.path(tab_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Flood Intensity on Agricultural Productivity (NDVI)}\n")
cat("\\label{tab:main}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("\\\\[-1.8ex]\n")
cat(" & \\multicolumn{2}{c}{Pooled} & \\multicolumn{2}{c}{Kharif (Summer)} & \\multicolumn{2}{c}{Rabi (Winter)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat("\\hline\n")

# Helper function
fmt_coef <- function(model, var) {
  cf <- summary(model)$coeftable
  est <- cf[var, 1]
  se <- cf[var, 2]
  pval <- cf[var, 4]
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  list(est = sprintf("%.6f%s", est, stars), se = sprintf("(%.6f)", se))
}

# Flood × Post (linear)
cat("Flood $\\times$ Post")
for (m in list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
               results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad)) {
  fc <- fmt_coef(m, "flood_x_post")
  cat(sprintf(" & %s", fc$est))
}
cat(" \\\\\n")

# SEs
cat("")
for (m in list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
               results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad)) {
  fc <- fmt_coef(m, "flood_x_post")
  cat(sprintf(" & %s", fc$se))
}
cat(" \\\\\n")

# Flood² × Post (quadratic)
cat("Flood$^2$ $\\times$ Post & ")
for (i in seq_along(list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
               results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad))) {
  m <- list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
            results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad)[[i]]
  if ("flood_sq_x_post" %in% rownames(summary(m)$coeftable)) {
    fc <- fmt_coef(m, "flood_sq_x_post")
    cat(sprintf("%s", fc$est))
  }
  if (i < 6) cat(" & ")
}
cat(" \\\\\n")

# SEs for quadratic
cat("")
for (i in seq_along(list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
               results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad))) {
  m <- list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
            results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad)[[i]]
  if ("flood_sq_x_post" %in% rownames(summary(m)$coeftable)) {
    fc <- fmt_coef(m, "flood_sq_x_post")
    cat(sprintf(" & %s", fc$se))
  } else {
    cat(" & ")
  }
}
cat(" \\\\\n")

cat("\\hline\n")
cat("Tehsil FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Season-Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Quadratic & No & Yes & No & Yes & No & Yes \\\\\n")

# Obs and R2
for (i in seq_along(list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
               results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad))) {
  if (i == 1) cat("Observations")
  m <- list(results$m1_linear, results$m1_quad, results$m2_kharif_lin,
            results$m2_kharif_quad, results$m2_rabi_lin, results$m2_rabi_quad)[[i]]
  cat(sprintf(" & %s", format(summary(m)$nobs, big.mark = ",")))
}
cat(" \\\\\n")

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} OLS estimates with tehsil and season-year fixed effects. ")
cat("Dependent variable is mean seasonal NDVI (normalized difference vegetation index). ")
cat("Flood intensity is the percentage of tehsil area inundated during the 2022 Pakistan floods (0--100). ")
cat("Standard errors clustered at the district level in parentheses. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 3: Binned Treatment Effects
# ============================================================================
cat("=== Table 3: Binned Treatment ===\n")

# Create binned variables
panel[, flood_low_post := as.integer(flood_group == "low") * post]
panel[, flood_mod_post := as.integer(flood_group == "moderate") * post]
panel[, flood_sev_post := as.integer(flood_group == "severe") * post]

sink(file.path(tab_dir, "tab3_binned.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Binned Flood Treatment Effects by Season}\n")
cat("\\label{tab:binned}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("\\\\[-1.8ex]\n")
cat(" & Pooled & Kharif & Rabi \\\\\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat("\\hline\n")

bins <- c("flood_low_post", "flood_mod_post", "flood_sev_post")
bin_names <- c("Low (5--20\\%) $\\times$ Post", "Moderate (20--50\\%) $\\times$ Post",
               "Severe ($>$50\\%) $\\times$ Post")

for (b in seq_along(bins)) {
  var <- bins[b]
  cat(bin_names[b])
  for (m in list(results$m3_binned, results$m3_kharif_bin, results$m3_rabi_bin)) {
    fc <- fmt_coef(m, var)
    cat(sprintf(" & %s", fc$est))
  }
  cat(" \\\\\n")
  # SEs
  cat("")
  for (m in list(results$m3_binned, results$m3_kharif_bin, results$m3_rabi_bin)) {
    fc <- fmt_coef(m, var)
    cat(sprintf(" & %s", fc$se))
  }
  cat(" \\\\\n")
}

cat("\\hline\n")
cat("Tehsil FE & Yes & Yes & Yes \\\\\n")
cat("Season-Year FE & Yes & Yes & Yes \\\\\n")
cat("Observations & 1,409 & 705 & 704 \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} OLS estimates with tehsil and season-year fixed effects. ")
cat("Dependent variable is mean seasonal NDVI. ")
cat("Omitted category: control tehsils ($<$5\\% flooded). ")
cat("Standard errors clustered at the district level in parentheses. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# Table 4: Robustness Checks
# ============================================================================
cat("=== Table 4: Robustness ===\n")

sink(file.path(tab_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat("\\\\[-1.8ex]\n")
cat(" & Baseline & Placebo & Prov. Trends & Trimmed & Prov. Cluster \\\\\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("\\hline\n")

models_rob <- list(results$m1_quad, robust$placebo_quad, robust$trend_model,
                   robust$trim_model, robust$alt_cluster)
vars_lin <- c("flood_x_post", "placebo_flood_x_post", "flood_x_post",
              "flood_x_post", "flood_x_post")
vars_sq <- c("flood_sq_x_post", "placebo_flood_sq_x_post", "flood_sq_x_post",
             "flood_sq_x_post", "flood_sq_x_post")

cat("Flood $\\times$ Post")
for (i in seq_along(models_rob)) {
  fc <- fmt_coef(models_rob[[i]], vars_lin[i])
  cat(sprintf(" & %s", fc$est))
}
cat(" \\\\\n")
cat("")
for (i in seq_along(models_rob)) {
  fc <- fmt_coef(models_rob[[i]], vars_lin[i])
  cat(sprintf(" & %s", fc$se))
}
cat(" \\\\\n")

cat("Flood$^2$ $\\times$ Post")
for (i in seq_along(models_rob)) {
  fc <- fmt_coef(models_rob[[i]], vars_sq[i])
  cat(sprintf(" & %s", fc$est))
}
cat(" \\\\\n")
cat("")
for (i in seq_along(models_rob)) {
  fc <- fmt_coef(models_rob[[i]], vars_sq[i])
  cat(sprintf(" & %s", fc$se))
}
cat(" \\\\\n")

cat("\\hline\n")
cat("Tehsil FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Season-Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Province trends & No & No & Yes & No & No \\\\\n")
cat("Sample & Full & Pre-2022 & Full & $\\leq$95\\% & Full \\\\\n")
cat("Clustering & District & District & District & District & Province \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column 1 repeats the baseline quadratic specification. ")
cat("Column 2 uses 2020 as a placebo treatment year (pre-2022 data only). ")
cat("Column 3 adds province-specific linear time trends. ")
cat("Column 4 drops tehsils with $>$95\\% area flooded. ")
cat("Column 5 clusters standard errors at the province level. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables generated ===\n")
