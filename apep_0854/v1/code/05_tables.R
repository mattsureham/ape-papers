# 05_tables.R — Generate all tables for the paper

source("00_packages.R")

cat("=== Loading Results ===\n")
df <- readRDS("../data/analysis_data.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
pa <- readRDS("../data/pa_ethnic.rds")

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

summ <- df %>%
  summarise(
    `Resale Price (S\\$)_mean` = mean(resale_price),
    `Resale Price (S\\$)_sd` = sd(resale_price),
    `Resale Price (S\\$)_min` = min(resale_price),
    `Resale Price (S\\$)_max` = max(resale_price),
    `Floor Area (sqm)_mean` = mean(floor_area_sqm),
    `Floor Area (sqm)_sd` = sd(floor_area_sqm),
    `Storey (midpoint)_mean` = mean(storey_mid, na.rm = TRUE),
    `Storey (midpoint)_sd` = sd(storey_mid, na.rm = TRUE),
    `Remaining Lease (years)_mean` = mean(remaining_lease_years, na.rm = TRUE),
    `Remaining Lease (years)_sd` = sd(remaining_lease_years, na.rm = TRUE),
    `Minority Share_mean` = mean(minority_share),
    `Minority Share_sd` = sd(minority_share),
    `Chinese Share_mean` = mean(chinese_share),
    `Chinese Share_sd` = sd(chinese_share),
    `Indian Share_mean` = mean(indian_share),
    `Indian Share_sd` = sd(indian_share),
    `Malay Share_mean` = mean(malay_share),
    `Malay Share_sd` = sd(malay_share)
  )

# Reshape
vars <- c("Resale Price (S\\$)", "Floor Area (sqm)", "Storey (midpoint)",
           "Remaining Lease (years)", "Minority Share", "Chinese Share",
           "Indian Share", "Malay Share")

tab1_rows <- lapply(vars, function(v) {
  data.frame(
    Variable = v,
    Mean = summ[[paste0(v, "_mean")]],
    SD = summ[[paste0(v, "_sd")]],
    Min = ifelse(v == "Resale Price (S\\$)", summ[[paste0(v, "_min")]], NA),
    Max = ifelse(v == "Resale Price (S\\$)", summ[[paste0(v, "_max")]], NA)
  )
})

tab1 <- bind_rows(tab1_rows)

# Write LaTeX
n_obs <- scales::comma(nrow(df))
n_towns <- n_distinct(df$town)

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: HDB Resale Transactions, 2017--2026}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & Min & Max \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(tab1))) {
  v <- tab1$Variable[i]
  if (grepl("Price", v)) {
    tab1_tex <- paste0(tab1_tex,
      v, " & ", scales::comma(round(tab1$Mean[i])),
      " & ", scales::comma(round(tab1$SD[i])),
      " & ", scales::comma(round(tab1$Min[i])),
      " & ", scales::comma(round(tab1$Max[i])), " \\\\\n")
  } else if (grepl("Share", v)) {
    tab1_tex <- paste0(tab1_tex,
      v, " & ", sprintf("%.3f", tab1$Mean[i]),
      " & ", sprintf("%.3f", tab1$SD[i]),
      " & & \\\\\n")
  } else {
    tab1_tex <- paste0(tab1_tex,
      v, " & ", sprintf("%.1f", tab1$Mean[i]),
      " & ", sprintf("%.1f", tab1$SD[i]),
      " & & \\\\\n")
  }
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\n",
  "Observations & \\multicolumn{4}{c}{", n_obs, "} \\\\\n",
  "Planning Areas & \\multicolumn{4}{c}{", n_towns, "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} HDB resale transactions from data.gov.sg. ",
  "Ethnic shares from Singapore Census 2020 (SingStat Table 17561). ",
  "Minority share is the combined Malay, Indian, and Others population share ",
  "at the planning area level. Sample covers all resale transactions from ",
  "January 2017 to the most recent available month.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Hedonic Regressions
# ============================================================
cat("\n=== Table 2: Hedonic Regressions ===\n")

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3

# Extract key coefficients
get_coef_row <- function(model, var, label) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- 2 * pnorm(-abs(b/s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(label = label, coef = b, se = s, stars = stars)
}

r1 <- get_coef_row(m1, "minority_share", "Minority Share")
r2 <- get_coef_row(m2, "minority_share", "Minority Share")
r3 <- get_coef_row(m3, "minority_share", "Minority Share")

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Minority Share and HDB Resale Prices}\n",
  "\\label{tab:hedonic}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  "Minority Share & ", sprintf("%.4f%s", r1$coef, r1$stars),
  " & ", sprintf("%.4f%s", r2$coef, r2$stars),
  " & ", sprintf("%.4f%s", r3$coef, r3$stars), " \\\\\n",
  " & (", sprintf("%.4f", r1$se), ")",
  " & (", sprintf("%.4f", r2$se), ")",
  " & (", sprintf("%.4f", r3$se), ") \\\\\n",
  "\\hline\n",
  "Flat characteristics & Yes & Yes & Yes \\\\\n",
  "Flat model FE & No & Yes & Yes \\\\\n",
  "Year-quarter FE & Yes & Yes & Yes \\\\\n",
  "Town population & No & No & Yes \\\\\n",
  "\\hline\n",
  "Observations & ", scales::comma(nobs(m1)),
  " & ", scales::comma(nobs(m2)),
  " & ", scales::comma(nobs(m3)), " \\\\\n",
  "$R^2$ & ", sprintf("%.3f", r2(m1, "r2")),
  " & ", sprintf("%.3f", r2(m2, "r2")),
  " & ", sprintf("%.3f", r2(m3, "r2")), " \\\\\n",
  "Clusters & 24",
  " & 24",
  " & 24 \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log resale price. ",
  "Minority share is the combined Malay, Indian, and Others population share ",
  "from Census 2020. Flat characteristics include floor area, storey midpoint, ",
  "remaining lease, and flat type fixed effects. Standard errors clustered by ",
  "planning area in parentheses. ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_hedonic.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Year-Specific Minority Gradients (Convergence Test)
# ============================================================
cat("\n=== Table 3: Convergence Test ===\n")

yc <- results$year_coefs
trend <- results$trend_test

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Year-Specific Minority Share Gradients: Testing for Convergence}\n",
  "\\label{tab:convergence}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Year & Minority Gradient & SE & 95\\% CI \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(yc))) {
  if (!is.na(yc$coef[i])) {
    tab3_tex <- paste0(tab3_tex,
      yc$year[i], " & ",
      sprintf("%.4f", yc$coef[i]), " & ",
      sprintf("%.4f", yc$se[i]), " & [",
      sprintf("%.4f", yc$ci_lo[i]), ", ",
      sprintf("%.4f", yc$ci_hi[i]), "] \\\\\n")
  }
}

trend_slope <- coef(trend)[2]
trend_se <- summary(trend)$coefficients[2, 2]
trend_p <- summary(trend)$coefficients[2, 4]

tab3_tex <- paste0(tab3_tex,
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Linear trend in gradient:}} \\\\\n",
  "Slope & ", sprintf("%.6f", trend_slope),
  " & (", sprintf("%.6f", trend_se), ")",
  " & $p = ", sprintf("%.3f", trend_p), "$ \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on minority share from ",
  "a year-specific hedonic regression including floor area, storey, remaining lease, ",
  "flat type FE, flat model FE, and year-quarter FE. The trend line is estimated by ",
  "WLS with inverse-variance weights. A positive slope indicates the minority discount ",
  "is shrinking (convergence toward zero). Standard errors clustered by planning area.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_convergence.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Robustness — Sample Splits
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

splits <- list(
  list("Small flats (1--3 room)", rob$m_small),
  list("Large flats (4+ room)", rob$m_large),
  list("Early period (2017--2018)", rob$m_early),
  list("Late period (2019--2020)", rob$m_late),
  list("New lease ($\\geq$60 years)", rob$m_new),
  list("Old lease ($<$60 years)", rob$m_old)
)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Minority Share Gradient by Subsample}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Subsample & Minority Gradient & SE & N \\\\\n",
  "\\hline\n"
)

for (s in splits) {
  label <- s[[1]]
  mod <- s[[2]]
  b <- coef(mod)["minority_share"]
  se_val <- se(mod)["minority_share"]
  p <- 2 * pnorm(-abs(b/se_val))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  tab4_tex <- paste0(tab4_tex,
    label, " & ", sprintf("%.4f%s", b, stars),
    " & (", sprintf("%.4f", se_val), ")",
    " & ", scales::comma(nobs(mod)), " \\\\\n")
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on minority share from ",
  "a hedonic regression estimated on the indicated subsample. All specifications include ",
  "floor area, storey, remaining lease, flat type FE, flat model FE, and year-quarter FE. ",
  "Standard errors clustered by planning area in parentheses. ",
  "$^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ============================================================
# Table F1: SDE Appendix (MANDATORY)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Main specification (Model 2) — pooled
b_pooled <- coef(results$m2)["minority_share"]
se_pooled <- se(results$m2)["minority_share"]
sd_y <- sd(df$log_price)
sde_pooled <- b_pooled / sd_y
se_sde_pooled <- se_pooled / sd_y

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde < 0) return("Large negative") else return("Large positive")
}

# Heterogeneous: small vs large flats
b_small <- coef(rob$m_small)["minority_share"]
se_small <- se(rob$m_small)["minority_share"]
sd_y_small <- sd(df$log_price[df$large_flat == FALSE])
sde_small <- b_small / sd_y_small
se_sde_small <- se_small / sd_y_small

b_large <- coef(rob$m_large)["minority_share"]
se_large <- se(rob$m_large)["minority_share"]
sd_y_large <- sd(df$log_price[df$large_flat == TRUE])
sde_large <- b_large / sd_y_large
se_sde_large <- se_large / sd_y_large

sde_rows <- data.frame(
  outcome = c("Log resale price (pooled)",
              "Log resale price (small flats)",
              "Log resale price (large flats)"),
  beta = c(b_pooled, b_small, b_large),
  se_beta = c(se_pooled, se_small, se_large),
  sd_y = c(sd_y, sd_y_small, sd_y_large),
  sde = c(sde_pooled, sde_small, sde_large),
  se_sde = c(se_sde_pooled, se_sde_small, se_sde_large),
  classification = c(classify_sde(sde_pooled),
                     classify_sde(sde_small),
                     classify_sde(sde_large))
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Singapore. ",
  "\\textbf{Research question:} Does the neighbourhood ethnic composition price gradient in Singapore's HDB resale market reflect persistent ethnic preferences or convergence under 35 years of mandated residential integration? ",
  "\\textbf{Policy mechanism:} Singapore's Ethnic Integration Policy (1989) caps each ethnic group's share per HDB block and neighbourhood, creating binding sale constraints that restrict the buyer pool when blocks hit quota limits, thereby directly affecting transaction prices through demand-side channel rationing. ",
  "\\textbf{Outcome definition:} Log of HDB resale transaction price in Singapore dollars, capturing the price per flat unit in Singapore's public housing market. ",
  "\\textbf{Treatment:} Continuous: minority population share (Malay + Indian + Others) at the planning area level, ranging from approximately 0.16 to 0.40 across 26 planning areas. ",
  "\\textbf{Data:} Singapore HDB Resale Flat Prices via data.gov.sg and Census 2020 via SingStat Table Builder, 2017--2026, transaction-level, approximately 227,000 observations. ",
  "\\textbf{Method:} OLS hedonic regression with flat type, flat model, and year-quarter fixed effects; standard errors clustered by planning area (26 clusters). ",
  "\\textbf{Sample:} All HDB resale transactions from January 2017 to latest available month; heterogeneity split by flat size (1--3 room vs.\\ 4+ room). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the sample standard deviation of log resale price. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

# Panel A row
r <- sde_rows[1, ]
tabF1_tex <- paste0(tabF1_tex,
  r$outcome, " & ",
  sprintf("%.4f", r$beta), " & ",
  sprintf("%.4f", r$se_beta), " & ",
  sprintf("%.4f", r$sd_y), " & ",
  sprintf("%.4f", r$sde), " & ",
  sprintf("%.4f", r$se_sde), " & ",
  r$classification, " \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by flat size)}} \\\\\n"
)

# Panel B rows
for (i in 2:3) {
  r <- sde_rows[i, ]
  tabF1_tex <- paste0(tabF1_tex,
    r$outcome, " & ",
    sprintf("%.4f", r$beta), " & ",
    sprintf("%.4f", r$se_beta), " & ",
    sprintf("%.4f", r$sd_y), " & ",
    sprintf("%.4f", r$sde), " & ",
    sprintf("%.4f", r$se_sde), " & ",
    r$classification, " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
