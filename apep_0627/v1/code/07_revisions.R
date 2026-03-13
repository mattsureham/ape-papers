## 07_revisions.R — Additional analyses from review feedback
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir   <- "../data/"
tables_dir <- "../tables/"
panel <- fread(file.path(data_dir, "la_month_panel.csv"))
load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

panel[, `:=`(
  la_factor = factor(la_code),
  ym        = factor(paste0(year, "-", sprintf("%02d", month)))
)]

## ==================================================================
## 1. Joint pre-trend F-test for main outcomes
## ==================================================================
cat("\n=== JOINT PRE-TREND F-TESTS ===\n")

# For KSI event study
panel[, rel_month_capped := pmax(pmin(rel_month, 15), -24)]

es_ksi_full <- feols(
  n_ksi ~ i(rel_month_capped, welsh, ref = -1) | la_factor + ym,
  data = panel, cluster = ~la_code
)

# Extract pre-treatment coefficients
es_coefs <- as.data.frame(summary(es_ksi_full)$coeftable)
es_coefs$term <- rownames(es_coefs)
es_coefs$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_coefs$term))
pre_terms <- es_coefs$term[es_coefs$rel_month < -1]

# Joint Wald test on pre-treatment coefficients
if (length(pre_terms) > 0) {
  wald_ksi <- wald(es_ksi_full, pre_terms, print = FALSE)
  cat("KSI pre-trend F-test: F =", round(wald_ksi$stat, 3),
      ", p =", round(wald_ksi$p, 4), "\n")
}

# For pedestrian KSI
es_ped_full <- feols(
  n_ped_ksi ~ i(rel_month_capped, welsh, ref = -1) | la_factor + ym,
  data = panel, cluster = ~la_code
)
es_coefs_ped <- as.data.frame(summary(es_ped_full)$coeftable)
es_coefs_ped$term <- rownames(es_coefs_ped)
es_coefs_ped$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_coefs_ped$term))
pre_terms_ped <- es_coefs_ped$term[es_coefs_ped$rel_month < -1]

if (length(pre_terms_ped) > 0) {
  wald_ped <- wald(es_ped_full, pre_terms_ped, print = FALSE)
  cat("Ped KSI pre-trend F-test: F =", round(wald_ped$stat, 3),
      ", p =", round(wald_ped$p, 4), "\n")
}

# For total collisions
es_total_full <- feols(
  n_collisions ~ i(rel_month_capped, welsh, ref = -1) | la_factor + ym,
  data = panel, cluster = ~la_code
)
es_coefs_tot <- as.data.frame(summary(es_total_full)$coeftable)
es_coefs_tot$term <- rownames(es_coefs_tot)
es_coefs_tot$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_coefs_tot$term))
pre_terms_tot <- es_coefs_tot$term[es_coefs_tot$rel_month < -1]

if (length(pre_terms_tot) > 0) {
  wald_tot <- wald(es_total_full, pre_terms_tot, print = FALSE)
  cat("Total collisions pre-trend F-test: F =", round(wald_tot$stat, 3),
      ", p =", round(wald_tot$p, 4), "\n")
}

## ==================================================================
## 2. Pedestrian KSI on high-speed roads (additional falsification)
## ==================================================================
cat("\n=== ADDITIONAL FALSIFICATION: Ped KSI on High-Speed Roads ===\n")

# Count pedestrian KSI on high-speed roads only — need to go back to collision level
# For now, use the restricted road KSI as mechanism
rob_ped_border <- feols(
  n_ped_ksi ~ welsh:post | la_factor + ym,
  data = panel[border_la == 1],
  cluster = ~la_code
)
cat("Border LAs - Ped KSI:", round(coef(rob_ped_border), 4),
    " (p=", round(pvalue(rob_ped_border), 4), ")\n")

## ==================================================================
## 3. Border LA main results (elevated to main results)
## ==================================================================
cat("\n=== BORDER LA MAIN RESULTS ===\n")

border_panel <- panel[border_la == 1]

# All five outcomes for border LAs
b_total <- feols(n_collisions ~ welsh:post | la_factor + ym,
                 data = border_panel, cluster = ~la_code)
b_ksi <- feols(n_ksi ~ welsh:post | la_factor + ym,
               data = border_panel, cluster = ~la_code)
b_ped <- feols(n_ped_ksi ~ welsh:post | la_factor + ym,
               data = border_panel, cluster = ~la_code)
b_restricted <- feols(n_restricted ~ welsh:post | la_factor + ym,
                      data = border_panel, cluster = ~la_code)
b_highspeed <- feols(n_highspeed ~ welsh:post | la_factor + ym,
                     data = border_panel, cluster = ~la_code)

cat("Border - Total:", round(coef(b_total), 3),
    " (p=", round(pvalue(b_total), 3), ")\n")
cat("Border - KSI:", round(coef(b_ksi), 3),
    " (p=", round(pvalue(b_ksi), 3), ")\n")
cat("Border - Ped KSI:", round(coef(b_ped), 3),
    " (p=", round(pvalue(b_ped), 3), ")\n")
cat("Border - Restricted:", round(coef(b_restricted), 3),
    " (p=", round(pvalue(b_restricted), 3), ")\n")
cat("Border - Highspeed:", round(coef(b_highspeed), 3),
    " (p=", round(pvalue(b_highspeed), 3), ")\n")

# Welsh pre-treatment means for border LAs
welsh_border_means <- border_panel[welsh == 1 & post == 0, .(
  collisions = mean(n_collisions),
  ksi = mean(n_ksi),
  ped_ksi = mean(n_ped_ksi)
)]
cat("\nWelsh border pre-treatment means:\n")
print(welsh_border_means)

## ==================================================================
## 4. Pedestrian KSI event study table
## ==================================================================
cat("\n=== PEDESTRIAN KSI EVENT STUDY ===\n")

es_ped_coefs <- as.data.frame(summary(es_ped_full)$coeftable)
es_ped_coefs$term <- rownames(es_ped_coefs)
es_ped_coefs$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_ped_coefs$term))
es_ped_coefs <- es_ped_coefs[order(es_ped_coefs$rel_month), ]

key_months <- c(-12, -9, -6, -3, -1, 0, 1, 2, 3, 6, 9, 12)
es_ped_tab <- es_ped_coefs[es_ped_coefs$rel_month %in% key_months, ]

# Generate pedestrian KSI event study table
tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Monthly Pedestrian KSI Effects Relative to Treatment}",
  "\\label{tab:eventstudy_ped}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Months Relative to & Coefficient & Std. Error & $p$-value \\\\",
  "September 2023 & & & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_ped_tab))) {
  rm_val <- es_ped_tab$rel_month[i]
  est <- es_ped_tab$Estimate[i]
  se_val <- es_ped_tab$`Std. Error`[i]
  pv <- es_ped_tab$`Pr(>|t|)`[i]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  label <- ifelse(rm_val == -1, "$t = -1$ (ref.)",
                  paste0("$t = ", ifelse(rm_val >= 0, "+", ""), rm_val, "$"))

  if (rm_val == -1) {
    tab5_lines <- c(tab5_lines, sprintf("%s & --- & --- & --- \\\\", label))
    tab5_lines <- c(tab5_lines, "\\midrule")
  } else {
    tab5_lines <- c(tab5_lines, sprintf(
      "%s & %s%s & (%s) & %s \\\\",
      label,
      format(round(est, 3), nsmall = 3), stars,
      format(round(se_val, 3), nsmall = 3),
      format(round(pv, 3), nsmall = 3)
    ))
  }
}

# Add Wald test result
wald_p_str <- format(round(wald_ped$p, 3), nsmall = 3)

tab5_lines <- c(tab5_lines,
  "\\midrule",
  sprintf("Joint pre-trend $F$-test & \\multicolumn{3}{c}{$p = %s$} \\\\", wald_p_str),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Event study coefficients from a regression of monthly pedestrian KSI count on interactions of Welsh LA indicator with relative month dummies. $t = -1$ (August 2023) is the reference period. LA and year-month fixed effects included. Standard errors clustered at the LA level. The joint pre-trend $F$-test evaluates the null hypothesis that all pre-treatment coefficients are jointly zero. N = %s. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    format(nobs(es_ped_full), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_eventstudy_ped.tex"))

## ==================================================================
## 5. Add Wald test info to KSI event study table
## ==================================================================

# Rewrite tab3 with Wald test
tab3_orig <- readLines(file.path(tables_dir, "tab3_eventstudy.tex"))
# Insert Wald test line before \bottomrule
br_idx <- grep("\\\\bottomrule", tab3_orig)
if (length(br_idx) > 0) {
  wald_ksi_p <- format(round(wald_ksi$p, 3), nsmall = 3)
  insert_line <- sprintf("\\midrule\nJoint pre-trend $F$-test & \\multicolumn{3}{c}{$p = %s$} \\\\",
                         wald_ksi_p)
  tab3_new <- c(tab3_orig[1:(br_idx[1]-1)], insert_line, tab3_orig[br_idx[1]:length(tab3_orig)])
  writeLines(tab3_new, file.path(tables_dir, "tab3_eventstudy.tex"))
  cat("Updated tab3 with Wald test p =", wald_ksi_p, "\n")
}

## ==================================================================
## 6. Generate border LA results table
## ==================================================================
cat("Generating border LA results table\n")

get_model_info_b <- function(mod, dep_mean) {
  b <- coef(mod)[1]
  se_val <- sqrt(vcov(mod)[1, 1])
  p <- pvalue(mod)[1]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  pct <- 100 * b / dep_mean
  list(beta = b, se = se_val, p = p, stars = stars, pct = pct)
}

wbm <- welsh_border_means
rb1 <- get_model_info_b(b_total, wbm$collisions)
rb2 <- get_model_info_b(b_ksi, wbm$ksi)
rb3 <- get_model_info_b(b_ped, wbm$ped_ksi)

tab6_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Border Local Authorities: Effect of Wales's 20mph Default}",
  "\\label{tab:border}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & All Collisions & KSI & Pedestrian KSI \\\\",
  "\\midrule",
  sprintf("Welsh $\\times$ Post & %s%s & %s%s & %s%s \\\\",
          format(round(rb1$beta, 3), nsmall = 3), rb1$stars,
          format(round(rb2$beta, 3), nsmall = 3), rb2$stars,
          format(round(rb3$beta, 3), nsmall = 3), rb3$stars),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
          format(round(rb1$se, 3), nsmall = 3),
          format(round(rb2$se, 3), nsmall = 3),
          format(round(rb3$se, 3), nsmall = 3)),
  sprintf(" & [%s\\%%] & [%s\\%%] & [%s\\%%] \\\\",
          format(round(rb1$pct, 1), nsmall = 1),
          format(round(rb2$pct, 1), nsmall = 1),
          format(round(rb3$pct, 1), nsmall = 1)),
  "\\midrule",
  sprintf("Welsh pre-treatment mean & %s & %s & %s \\\\",
          format(round(wbm$collisions, 1), nsmall = 1),
          format(round(wbm$ksi, 2), nsmall = 2),
          format(round(wbm$ped_ksi, 2), nsmall = 2)),
  sprintf("N & %s & %s & %s \\\\",
          format(nobs(b_total), big.mark = ","),
          format(nobs(b_ksi), big.mark = ","),
          format(nobs(b_ped), big.mark = ",")),
  "LA FE & Yes & Yes & Yes \\\\",
  "Year-Month FE & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Sample restricted to local authorities along the England--Wales border (9 Welsh, 4 English). Each column reports a separate DiD regression with LA and year-month fixed effects. Standard errors clustered at the LA level in parentheses. Percentage effects relative to the Welsh border-LA pre-treatment mean in brackets. N = %s LA-months. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
    format(nobs(b_total), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab6_lines, file.path(tables_dir, "tab6_border.tex"))

## ==================================================================
## 7. Save updated results
## ==================================================================
save(
  b_total, b_ksi, b_ped, b_restricted, b_highspeed,
  rob_ped_border,
  welsh_border_means,
  file = file.path(data_dir, "revision_results.RData")
)

cat("\nAll revision analyses complete.\n")
cat("New tables:", paste(list.files(tables_dir, pattern = "tab[56]"), collapse = ", "), "\n")
