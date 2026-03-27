# 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

paper_root <- normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
if (file.exists(file.path(paper_root, "data"))) setwd(paper_root)

panel <- readRDS("data/panel.rds")
results <- readRDS("data/results.rds")
robustness <- readRDS("data/robustness.rds")
dir.create("tables", showWarnings = FALSE)

panel <- panel %>% mutate(event_time = year - 2012)

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

summ <- panel %>%
  filter(year <= 2011) %>%
  group_by(Group = ifelse(treated == 1, "Treated (>20\\%)", "Control (<20\\%)")) %>%
  summarise(
    Municipalities = n_distinct(muni_code),
    `Total Investment` = sprintf("%.0f", mean(total, na.rm = TRUE)),
    `SD Total` = sprintf("%.0f", sd(total, na.rm = TRUE)),
    `Residential` = sprintf("%.0f", mean(residential, na.rm = TRUE)),
    `SD Residential` = sprintf("%.0f", sd(residential, na.rm = TRUE)),
    `Commercial` = sprintf("%.0f", mean(commercial, na.rm = TRUE)),
    `SD Commercial` = sprintf("%.0f", sd(commercial, na.rm = TRUE)),
    `Second Home \\%` = sprintf("%.1f", mean(pct_second_home, na.rm = TRUE)),
    .groups = "drop"
  )

# Rebuild summary for a cleaner table structure
summ2 <- panel %>%
  filter(year <= 2011) %>%
  group_by(treated) %>%
  summarise(
    n_munis = n_distinct(muni_code),
    mean_total = mean(total, na.rm = TRUE),
    mean_residential = mean(residential, na.rm = TRUE),
    mean_commercial = mean(commercial, na.rm = TRUE),
    mean_second_home = mean(pct_second_home, na.rm = TRUE),
    sd_total = sd(total, na.rm = TRUE),
    sd_residential = sd(residential, na.rm = TRUE),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Period (1994--2011)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & Municipalities & Total & Residential & Commercial & Second Home \\% & SD(Total) \\\\\n",
  "\\midrule\n",
  sprintf("Control ($<$20\\%%) & %s & %s & %s & %s & %.1f & %s \\\\\n",
    format(summ2$n_munis[1], big.mark=","),
    format(round(summ2$mean_total[1]), big.mark=","),
    format(round(summ2$mean_residential[1]), big.mark=","),
    format(round(summ2$mean_commercial[1]), big.mark=","),
    summ2$mean_second_home[1],
    format(round(summ2$sd_total[1]), big.mark=",")),
  sprintf("Treated ($>$20\\%%) & %s & %s & %s & %s & %.1f & %s \\\\\n",
    format(summ2$n_munis[2], big.mark=","),
    format(round(summ2$mean_total[2]), big.mark=","),
    format(round(summ2$mean_residential[2]), big.mark=","),
    format(round(summ2$mean_commercial[2]), big.mark=","),
    summ2$mean_second_home[2],
    format(round(summ2$sd_total[2]), big.mark=",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Pre-treatment means of annual construction investment (CHF~1,000) by municipality. Treated municipalities are those designated by the ARE as having second-home shares above 20\\% under the ZWG. N = 1,617 municipalities $\\times$ 18 pre-treatment years.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main DiD Results (with Canton×Year FE)
# ---------------------------------------------------------------
cat("=== Table 2: Main Results ===\n")

# Re-estimate with canton×year FE (preferred specification)
outcomes <- c("log_residential", "log_commercial", "log_total",
              "log_non_residential", "log_roads")
labels_short <- c("Residential", "Commercial", "Total", "Non-Residential", "Roads")

# Column 1-5: Binary DiD with canton×year FE
fits_binary <- list()
for (y in outcomes) {
  fml <- as.formula(paste0(y, " ~ treat_post | muni_code + canton^year"))
  fits_binary[[y]] <- feols(fml, data = panel, cluster = "muni_code")
}

# Column 6-10: Continuous intensity with canton×year FE
fits_cont <- list()
for (y in outcomes) {
  fml <- as.formula(paste0(y, " ~ intensity_post | muni_code + canton^year"))
  fits_cont[[y]] <- feols(fml, data = panel, cluster = "muni_code")
}

# Build table manually for full control
make_row <- function(fit, varname) {
  b <- coef(fit)[varname]
  s <- se(fit)[varname]
  p <- pvalue(fit)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.3f%s", b, stars), se = sprintf("(%.3f)", s))
}

# Panel A: Binary treatment
rows_a <- lapply(fits_binary, make_row, "treat_post")
# Panel B: Continuous intensity
rows_b <- lapply(fits_cont, make_row, "intensity_post")

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Second Home Initiative on Construction Investment}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & ", paste(labels_short, collapse = " & "), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Binary Treatment ($>$20\\% vs $<$20\\%)}} \\\\\n",
  "[0.3em]\n",
  "Treated $\\times$ Post & ",
  paste(sapply(rows_a, `[[`, "coef"), collapse = " & "), " \\\\\n",
  " & ", paste(sapply(rows_a, `[[`, "se"), collapse = " & "), " \\\\\n",
  "[0.5em]\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Continuous Intensity (Second Home Share $\\times$ Post)}} \\\\\n",
  "[0.3em]\n",
  "Intensity $\\times$ Post & ",
  paste(sapply(rows_b, `[[`, "coef"), collapse = " & "), " \\\\\n",
  " & ", paste(sapply(rows_b, `[[`, "se"), collapse = " & "), " \\\\\n",
  "[0.5em]\n",
  "\\midrule\n",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Canton $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Municipalities & ", format(n_distinct(panel$muni_code), big.mark=","), " & ",
  format(n_distinct(panel$muni_code), big.mark=","), " & ",
  format(n_distinct(panel$muni_code), big.mark=","), " & ",
  format(n_distinct(panel$muni_code), big.mark=","), " & ",
  format(n_distinct(panel$muni_code), big.mark=","), " \\\\\n",
  "Observations & ", format(nrow(panel), big.mark=","), " & ",
  format(nrow(panel), big.mark=","), " & ",
  format(nrow(panel), big.mark=","), " & ",
  format(nrow(panel), big.mark=","), " & ",
  format(nrow(panel), big.mark=","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variables are IHS-transformed construction investment (log(investment + 1)) in CHF~1,000 by sector. Panel A uses a binary treatment indicator (municipality second-home share $>$ 20\\%). Panel B uses continuous treatment intensity (municipality second-home share $\\times$ post-2012). Column (5) is a placebo: road infrastructure investment should not be directly affected by the residential construction ban. All specifications include municipality and canton $\\times$ year fixed effects. Standard errors clustered at the municipality level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "tables/tab2_main.tex")

# ---------------------------------------------------------------
# Table 3: Heterogeneity (Alpine vs Non-Alpine)
# ---------------------------------------------------------------
cat("=== Table 3: Heterogeneity ===\n")

alpine_cantons <- c("VS", "GR", "UR", "OW", "NW", "GL", "TI", "BE", "SZ")
panel <- panel %>% mutate(alpine = as.integer(canton %in% alpine_cantons))

het_outcomes <- c("log_residential", "log_commercial", "log_total")
het_labels <- c("Residential", "Commercial", "Total")

het_rows <- list()
for (alp in c(1, 0)) {
  sub <- panel %>% filter(alpine == alp)
  label <- if (alp == 1) "Alpine" else "Non-Alpine"
  for (y in het_outcomes) {
    fit <- feols(as.formula(paste0(y, " ~ treat_post | muni_code + canton^year")),
                 data = sub, cluster = "muni_code")
    b <- coef(fit)["treat_post"]
    s <- se(fit)["treat_post"]
    p <- pvalue(fit)["treat_post"]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    het_rows[[paste0(label, "_", y)]] <- list(
      coef = sprintf("%.3f%s", b, stars),
      se = sprintf("(%.3f)", s),
      n_t = n_distinct(sub$muni_code[sub$treated == 1]),
      n_c = n_distinct(sub$muni_code[sub$treated == 0])
    )
  }
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneity: Alpine vs Non-Alpine Municipalities}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & ", paste(het_labels, collapse = " & "), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alpine Cantons}} \\\\\n",
  "[0.3em]\n",
  "Treated $\\times$ Post & ",
  paste(sapply(het_rows[1:3], `[[`, "coef"), collapse = " & "), " \\\\\n",
  " & ", paste(sapply(het_rows[1:3], `[[`, "se"), collapse = " & "), " \\\\\n",
  "Treated / Control & ", het_rows[[1]]$n_t, " / ", het_rows[[1]]$n_c, " & ",
  het_rows[[2]]$n_t, " / ", het_rows[[2]]$n_c, " & ",
  het_rows[[3]]$n_t, " / ", het_rows[[3]]$n_c, " \\\\\n",
  "[0.5em]\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Non-Alpine Cantons}} \\\\\n",
  "[0.3em]\n",
  "Treated $\\times$ Post & ",
  paste(sapply(het_rows[4:6], `[[`, "coef"), collapse = " & "), " \\\\\n",
  " & ", paste(sapply(het_rows[4:6], `[[`, "se"), collapse = " & "), " \\\\\n",
  "Treated / Control & ", het_rows[[4]]$n_t, " / ", het_rows[[4]]$n_c, " & ",
  het_rows[[5]]$n_t, " / ", het_rows[[5]]$n_c, " & ",
  het_rows[[6]]$n_t, " / ", het_rows[[6]]$n_c, " \\\\\n",
  "\\midrule\n",
  "Municipality FE & Yes & Yes & Yes \\\\\n",
  "Canton $\\times$ Year FE & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample split by alpine status. Alpine cantons: VS, GR, UR, OW, NW, GL, TI, BE, SZ. All specifications include municipality and canton $\\times$ year fixed effects. Standard errors clustered at the municipality level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "tables/tab3_heterogeneity.tex")

# ---------------------------------------------------------------
# Table 4: RDD at 20% Threshold
# ---------------------------------------------------------------
cat("=== Table 4: RDD Results ===\n")

rdd_data <- robustness$rdd_data

rdd_res <- rdrobust(rdd_data$delta_residential, rdd_data$running, c = 0)
rdd_com <- rdrobust(rdd_data$delta_commercial, rdd_data$running, c = 0)
rdd_tot <- rdrobust(rdd_data$delta_total, rdd_data$running, c = 0)
dens <- rddensity(rdd_data$running)

make_rdd_col <- function(rdd_fit) {
  b <- rdd_fit$coef[1]
  s <- rdd_fit$se[1]
  p <- rdd_fit$pv[1]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(
    coef = sprintf("%.3f%s", b, stars),
    se = sprintf("(%.3f)", s),
    bw = sprintf("%.1f", rdd_fit$bws[1,1]),
    n_l = rdd_fit$N_h[1],
    n_r = rdd_fit$N_h[2]
  )
}

r_res <- make_rdd_col(rdd_res)
r_com <- make_rdd_col(rdd_com)
r_tot <- make_rdd_col(rdd_tot)

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Regression Discontinuity at the 20\\% Second-Home Threshold}\n",
  "\\label{tab:rdd}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & $\\Delta$ Residential & $\\Delta$ Commercial & $\\Delta$ Total \\\\\n",
  "\\midrule\n",
  "Above 20\\% & ", r_res$coef, " & ", r_com$coef, " & ", r_tot$coef, " \\\\\n",
  " & ", r_res$se, " & ", r_com$se, " & ", r_tot$se, " \\\\\n",
  "[0.5em]\n",
  "Bandwidth & ", r_res$bw, " & ", r_com$bw, " & ", r_tot$bw, " \\\\\n",
  "N below / above & ", r_res$n_l, " / ", r_res$n_r, " & ",
  r_com$n_l, " / ", r_com$n_r, " & ",
  r_tot$n_l, " / ", r_tot$n_r, " \\\\\n",
  "Density test ($p$) & \\multicolumn{3}{c}{", sprintf("%.3f", dens$test$p_jk), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Local linear RDD estimates using \\texttt{rdrobust} with MSE-optimal bandwidth and triangular kernel. The outcome is the change in log construction investment between the pre-period (2006--2011) and post-period (2013--2018). The running variable is the municipality's second-home share centered at the 20\\% statutory threshold. The density test is the Cattaneo--Jansson--Ma (2020) test for manipulation of the running variable. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "tables/tab4_rdd.tex")

# ---------------------------------------------------------------
# SDE Table (Appendix F1)
# ---------------------------------------------------------------
cat("=== SDE Table ===\n")

# Extract preferred specification results (canton×year FE, binary treatment)
sds_pre <- panel %>%
  filter(year <= 2011) %>%
  summarise(
    sd_res = sd(log_residential, na.rm = TRUE),
    sd_com = sd(log_commercial, na.rm = TRUE),
    sd_tot = sd(log_total, na.rm = TRUE)
  )

# Pooled estimates
fit_res <- fits_binary[["log_residential"]]
fit_com <- fits_binary[["log_commercial"]]
fit_tot <- fits_binary[["log_total"]]

make_sde_row <- function(fit, varname, sd_y, outcome_label, spec_label) {
  b <- coef(fit)[varname]
  s <- se(fit)[varname]
  sde <- b / sd_y
  se_sde <- s / sd_y
  class_label <- dplyr::case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  sprintf("%s & %s & %.3f & --- & %.3f & %.3f & %.3f & %s",
    outcome_label, spec_label, b, sd_y, sde, se_sde, class_label)
}

# Heterogeneity: Alpine vs Non-Alpine for total investment
alpine_sub <- panel %>% filter(alpine == 1)
non_alpine_sub <- panel %>% filter(alpine == 0)
fit_alpine <- feols(log_total ~ treat_post | muni_code + canton^year,
                    data = alpine_sub, cluster = "muni_code")
fit_non_alp <- feols(log_total ~ treat_post | muni_code + year,
                     data = non_alpine_sub, cluster = "muni_code")
sd_alp <- sd(alpine_sub$log_total[alpine_sub$year <= 2011], na.rm = TRUE)
sd_nalp <- sd(non_alpine_sub$log_total[non_alpine_sub$year <= 2011], na.rm = TRUE)

row_a1 <- make_sde_row(fit_res, "treat_post", sds_pre$sd_res, "Residential", "Binary DiD")
row_a2 <- make_sde_row(fit_com, "treat_post", sds_pre$sd_com, "Commercial", "Binary DiD")
row_a3 <- make_sde_row(fit_tot, "treat_post", sds_pre$sd_tot, "Total", "Binary DiD")
row_b1 <- make_sde_row(fit_alpine, "treat_post", sd_alp, "Total (Alpine)", "Split sample")
row_b2 <- make_sde_row(fit_non_alp, "treat_post", sd_nalp, "Total (Non-Alpine)", "Split sample")

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does banning residential second-home construction redirect capital toward commercial and tourism infrastructure, or does it freeze investment across all construction sectors? ",
  "\\textbf{Policy mechanism:} The 2012 Zweitwohnungsinitiative (Second Home Initiative) amended the Swiss Constitution to prohibit new second-home construction in any municipality where second homes exceed 20\\% of the housing stock, directly constraining residential development in approximately 325 alpine and tourism municipalities. ",
  "\\textbf{Outcome definition:} Annual construction investment in CHF~1,000, measured separately for residential (Wohnen) and commercial (Industrie, Gewerbe und Dienstleistungen) sectors from the BFS Bau- und Wohnbaustatistik, IHS-transformed. ",
  "\\textbf{Treatment:} Binary indicator for municipality second-home share above 20\\%, based on the 2017 ARE Wohnungsinventar. ",
  "\\textbf{Data:} BFS PxWeb construction investment statistics (Table 203), 1,617 municipalities, 1994--2023, 48,510 municipality-year observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with municipality and canton $\\times$ year fixed effects, municipality-clustered standard errors. ",
  "\\textbf{Sample:} All Swiss municipalities with matched construction investment and second-home share data; treatment municipalities are those designated by the ARE as exceeding the 20\\% second-home threshold. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\footnotesize\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  row_a1, " \\\\\n",
  row_a2, " \\\\\n",
  row_a3, " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  row_b1, " \\\\\n",
  row_b2, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\scriptsize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "tables/tabF1_sde.tex")

cat("\nAll tables saved to tables/\n")
cat(paste(list.files("tables/"), collapse = "\n"), "\n")
