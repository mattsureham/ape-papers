# 05_tables.R — Generate all LaTeX tables
# apep_0961: Swiss tobacco billboard bans and healthcare costs

source("00_packages.R")

panel_total <- readRDS("../data/panel_total.rds")
panel_cat   <- readRDS("../data/panel_cat.rds")
results     <- readRDS("../data/main_results.rds")
robustness  <- readRDS("../data/robustness_results.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

dir.create("../tables", showWarnings = FALSE)

# ============================================================================
# Helper: format numbers
# ============================================================================
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics\n")

# Pre-ban summary stats
pre_total <- panel_total[year < 1997]
if (nrow(pre_total) == 0) {
  # If no pre-1997 data, use earliest available
  pre_total <- panel_total[year == min(year)]
}

# Full panel summary
summ_treat <- panel_total[treated_ever == 1, .(
  mean_cost = mean(cost_pc), sd_cost = sd(cost_pc),
  min_cost = min(cost_pc), max_cost = max(cost_pc),
  n_obs = .N, n_cantons = uniqueN(canton_iso)
)]
summ_ctrl <- panel_total[treated_ever == 0, .(
  mean_cost = mean(cost_pc), sd_cost = sd(cost_pc),
  min_cost = min(cost_pc), max_cost = max(cost_pc),
  n_obs = .N, n_cantons = uniqueN(canton_iso)
)]

# Pre-ban means (before median treatment year ~2007)
pre_treat <- panel_total[treated_ever == 1 & year < 2007, .(
  mean_cost = mean(cost_pc), sd_cost = sd(cost_pc)
)]
pre_ctrl <- panel_total[treated_ever == 0 & year < 2007, .(
  mean_cost = mean(cost_pc), sd_cost = sd(cost_pc)
)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Per-Capita Healthcare Costs by Treatment Status}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Billboard Ban Cantons} & \\multicolumn{2}{c}{No Ban Cantons} \\\\\n",
  " & \\multicolumn{2}{c}{(N = ", summ_treat$n_cantons, ")} & \\multicolumn{2}{c}{(N = ", summ_ctrl$n_cantons, ")} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Full panel (1997--2024)}} \\\\\n",
  "Total cost per insured (CHF) & ", fmt(summ_treat$mean_cost, 0), " & ", fmt(summ_treat$sd_cost, 0),
  " & ", fmt(summ_ctrl$mean_cost, 0), " & ", fmt(summ_ctrl$sd_cost, 0), " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Pre-ban period (1997--2006)}} \\\\\n",
  "Total cost per insured (CHF) & ", fmt(pre_treat$mean_cost, 0), " & ", fmt(pre_treat$sd_cost, 0),
  " & ", fmt(pre_ctrl$mean_cost, 0), " & ", fmt(pre_ctrl$sd_cost, 0), " \\\\\n",
  "\\addlinespace\n",
  "Canton-years & \\multicolumn{2}{c}{", fmt_int(summ_treat$n_obs), "} & \\multicolumn{2}{c}{", fmt_int(summ_ctrl$n_obs), "} \\\\\n",
  "Years & \\multicolumn{4}{c}{1997--2024} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Data from the FOPH OKP Dashboard (mandatory health insurance). ",
  "Billboard ban cantons adopted tobacco billboard advertising restrictions between 1997 and 2017. ",
  "Per-capita costs are gross benefits per insured person in Swiss francs.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: Main Results — CS-DiD and TWFE
# ============================================================================
cat("Generating Table 2: Main Results\n")

agg_simple <- results$agg_simple
agg_smoke  <- results$agg_smoke
agg_placebo <- results$agg_placebo
twfe_total <- results$twfe_total
agg_levels <- robustness$agg_levels

# P-values
p_cs <- 2 * pnorm(-abs(agg_simple$overall.att / agg_simple$overall.se))
p_smoke <- 2 * pnorm(-abs(agg_smoke$overall.att / agg_smoke$overall.se))
p_placebo <- 2 * pnorm(-abs(agg_placebo$overall.att / agg_placebo$overall.se))
p_twfe <- 2 * pnorm(-abs(coef(twfe_total)["treated_post"] / sqrt(vcov(twfe_total)["treated_post", "treated_post"])))
p_levels <- 2 * pnorm(-abs(agg_levels$overall.att / agg_levels$overall.se))

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Tobacco Billboard Bans on Per-Capita Healthcare Costs}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & CS-DiD & CS-DiD & CS-DiD & TWFE & CS-DiD \\\\\n",
  " & Total & Smoking & Placebo & Total & Total \\\\\n",
  " & (log) & (log) & (log) & (log) & (CHF) \\\\\n",
  "\\hline\n",
  "Billboard ban & ", fmt(agg_simple$overall.att, 4), stars(p_cs),
  " & ", fmt(agg_smoke$overall.att, 4), stars(p_smoke),
  " & ", fmt(agg_placebo$overall.att, 4), stars(p_placebo),
  " & ", fmt(coef(twfe_total)["treated_post"], 4), stars(p_twfe),
  " & ", fmt(agg_levels$overall.att, 1), stars(p_levels), " \\\\\n",
  " & (", fmt(agg_simple$overall.se, 4), ")",
  " & (", fmt(agg_smoke$overall.se, 4), ")",
  " & (", fmt(agg_placebo$overall.se, 4), ")",
  " & (", fmt(sqrt(vcov(twfe_total)["treated_post", "treated_post"]), 4), ")",
  " & (", fmt(agg_levels$overall.se, 1), ") \\\\\n",
  "\\addlinespace\n",
  "Estimator & CS-DiD & CS-DiD & CS-DiD & TWFE & CS-DiD \\\\\n",
  "Outcome & Total & Smoking & Placebo & Total & Total \\\\\n",
  "Canton FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Cantons & 26 & 26 & 26 & 26 & 26 \\\\\n",
  "Canton-years & ", fmt_int(nrow(panel_total)),
  " & ", fmt_int(nrow(panel_total)),
  " & ", fmt_int(nrow(panel_total)),
  " & ", fmt_int(nrow(panel_total)),
  " & ", fmt_int(nrow(panel_total)), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Columns 1--3 and 5 report Callaway and Sant'Anna (2021) ATT estimates using never-treated cantons as the comparison group. ",
  "Column 4 reports standard TWFE for comparison. ",
  "``Smoking'' aggregates hospital (inpatient/outpatient), pharmacy, and physician treatment costs. ",
  "``Placebo'' aggregates physiotherapy, SPITEX home care, and laboratory costs. ",
  "Standard errors clustered at the canton level in parentheses. ",
  "$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Cost Category Decomposition
# ============================================================================
cat("Generating Table 3: Category Decomposition\n")

cat_results <- robustness$cat_results

tab3_rows <- ""
for (i in seq_len(nrow(cat_results))) {
  row <- cat_results[i]
  tab3_rows <- paste0(tab3_rows,
    row$category, " & ", row$type,
    " & ", fmt(row$att, 4), stars(row$pval),
    " & (", fmt(row$se, 4), ") \\\\\n"
  )
}

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Billboard Ban Effects by Cost Category}\n",
  "\\label{tab:categories}\n",
  "\\begin{tabular}{llrl}\n",
  "\\hline\\hline\n",
  "Cost Category & Type & ATT & SE \\\\\n",
  "\\hline\n",
  tab3_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports a separate CS-DiD estimate for per-capita costs (log) in that category. ",
  "``Smoking-related'' categories are expected to respond to billboard bans; ``placebo'' categories serve as falsification tests. ",
  "Standard errors clustered at the canton level. ",
  "$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_categories.tex")

# ============================================================================
# Table 4: Leave-One-Out Robustness
# ============================================================================
cat("Generating Table 4: Leave-One-Out\n")

loo <- robustness$loo_results

tab4_rows <- ""
for (i in seq_len(nrow(loo))) {
  row <- loo[i]
  p_loo <- 2 * pnorm(-abs(row$att / row$se))
  tab4_rows <- paste0(tab4_rows,
    gsub("CH-", "", row$dropped_canton),
    " & ", fmt(row$att, 4), stars(p_loo),
    " & (", fmt(row$se, 4), ") \\\\\n"
  )
}

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Leave-One-Out Robustness: Dropping Each Treated Canton}\n",
  "\\label{tab:loo}\n",
  "\\begin{tabular}{lrl}\n",
  "\\hline\\hline\n",
  "Dropped Canton & ATT & SE \\\\\n",
  "\\hline\n",
  "\\textit{Baseline (none dropped)} & ", fmt(agg_simple$overall.att, 4), stars(p_cs),
  " & (", fmt(agg_simple$overall.se, 4), ") \\\\\n",
  "\\addlinespace\n",
  tab4_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row drops one treated canton and re-estimates the CS-DiD ATT on log total per-capita costs. ",
  "Standard errors clustered at the canton level. ",
  "$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_loo.tex")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Pre-treatment SD(Y) for each outcome
sd_total_pre <- panel_total[treated_ever == 1 & year < ban_year, sd(cost_pc)]
if (is.na(sd_total_pre) || sd_total_pre == 0) {
  sd_total_pre <- panel_total[year < 2007, sd(cost_pc)]
}

# For log specs, SDE = ATT (already in log points ~ percentage)
# For levels spec, SDE = beta / SD(Y)
sde_total_levels <- agg_levels$overall.att / sd_total_pre
se_sde_total <- agg_levels$overall.se / sd_total_pre

# Smoking-related
smoke_agg_data <- panel_cat[category_type == "smoking_related",
                            .(cost_pc = sum(cost_pc)),
                            by = .(canton_iso, year, ban_year, treated_ever)]
sd_smoke_pre <- smoke_agg_data[treated_ever == 1 & year < ban_year, sd(cost_pc)]
if (is.na(sd_smoke_pre) || sd_smoke_pre == 0) {
  sd_smoke_pre <- smoke_agg_data[year < 2007, sd(cost_pc)]
}

# Create levels estimate for smoking
smoke_levels_agg <- panel_cat[category_type == "smoking_related",
                              .(cost_pc = sum(cost_pc)),
                              by = .(canton_iso, year, ban_year, treated_ever,
                                     treated_post, years_since_ban, canton_name)]
smoke_levels_agg[, canton_id := as.integer(as.factor(canton_iso))]
cs_smoke_lev <- att_gt(
  yname = "cost_pc", tname = "year", idname = "canton_id", gname = "ban_year",
  data = as.data.frame(smoke_levels_agg), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_smoke_lev <- aggte(cs_smoke_lev, type = "simple")

sde_smoke <- agg_smoke_lev$overall.att / sd_smoke_pre
se_sde_smoke <- agg_smoke_lev$overall.se / sd_smoke_pre

# Placebo
placebo_levels_data <- panel_cat[category_type == "placebo",
                                 .(cost_pc = sum(cost_pc)),
                                 by = .(canton_iso, year, ban_year, treated_ever,
                                        treated_post, years_since_ban, canton_name)]
sd_placebo_pre <- placebo_levels_data[treated_ever == 1 & year < ban_year, sd(cost_pc)]
if (is.na(sd_placebo_pre) || sd_placebo_pre == 0) {
  sd_placebo_pre <- placebo_levels_data[year < 2007, sd(cost_pc)]
}
placebo_levels_data[, canton_id := as.integer(as.factor(canton_iso))]
cs_placebo_lev <- att_gt(
  yname = "cost_pc", tname = "year", idname = "canton_id", gname = "ban_year",
  data = as.data.frame(placebo_levels_data), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_placebo_lev <- aggte(cs_placebo_lev, type = "simple")

sde_placebo <- agg_placebo_lev$overall.att / sd_placebo_pre
se_sde_placebo <- agg_placebo_lev$overall.se / sd_placebo_pre

# SDE classification
classify_sde <- function(sde) {
  if (is.na(sde)) return("Indeterminate")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE data
sde_rows <- data.table(
  outcome = c("Total healthcare costs", "Smoking-related costs", "Placebo costs (non-smoking)"),
  beta = c(agg_levels$overall.att, agg_smoke_lev$overall.att, agg_placebo_lev$overall.att),
  se = c(agg_levels$overall.se, agg_smoke_lev$overall.se, agg_placebo_lev$overall.se),
  sd_y = c(sd_total_pre, sd_smoke_pre, sd_placebo_pre),
  sde = c(sde_total_levels, sde_smoke, sde_placebo),
  se_sde = c(se_sde_total, se_sde_smoke, se_sde_placebo)
)
sde_rows[, classification := sapply(sde, classify_sde)]

# Panel B: heterogeneity by early vs late adopters
# Early adopters: ban_year <= 2007 (8 cantons)
# Late adopters: ban_year > 2007 (8 cantons)
panel_early <- panel_total[ban_year <= 2007 & ban_year > 0 | ban_year == 0]
panel_late  <- panel_total[ban_year > 2007 | ban_year == 0]
panel_early[, canton_id_sub := as.integer(as.factor(canton_iso))]
panel_late[, canton_id_sub := as.integer(as.factor(canton_iso))]

cs_early <- att_gt(
  yname = "cost_pc", tname = "year", idname = "canton_id_sub", gname = "ban_year",
  data = as.data.frame(panel_early), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_early <- aggte(cs_early, type = "simple")

cs_late <- att_gt(
  yname = "cost_pc", tname = "year", idname = "canton_id_sub", gname = "ban_year",
  data = as.data.frame(panel_late), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_late <- aggte(cs_late, type = "simple")

sd_early_pre <- panel_early[treated_ever == 1 & year < ban_year, sd(cost_pc)]
if (is.na(sd_early_pre) || sd_early_pre == 0) sd_early_pre <- panel_early[year < 2007, sd(cost_pc)]
sd_late_pre <- panel_late[treated_ever == 1 & year < ban_year, sd(cost_pc)]
if (is.na(sd_late_pre) || sd_late_pre == 0) sd_late_pre <- panel_late[year < 2012, sd(cost_pc)]

sde_early <- agg_early$overall.att / sd_early_pre
se_sde_early <- agg_early$overall.se / sd_early_pre
sde_late <- agg_late$overall.att / sd_late_pre
se_sde_late <- agg_late$overall.se / sd_late_pre

het_rows <- data.table(
  outcome = c("Total costs — early adopters ($\\leq$2007)", "Total costs — late adopters ($>$2007)"),
  beta = c(agg_early$overall.att, agg_late$overall.att),
  se = c(agg_early$overall.se, agg_late$overall.se),
  sd_y = c(sd_early_pre, sd_late_pre),
  sde = c(sde_early, sde_late),
  se_sde = c(se_sde_early, se_sde_late)
)
het_rows[, classification := sapply(sde, classify_sde)]

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does banning tobacco billboard advertising reduce per-capita mandatory health insurance costs? ",
  "\\textbf{Policy mechanism:} Cantonal billboard advertising bans prohibit outdoor tobacco advertising on public billboards, ",
  "reducing consumer exposure to smoking cues and potentially lowering smoking initiation and prevalence over time. ",
  "\\textbf{Outcome definition:} Annual gross benefits per insured person (Bruttoleistungen pro Versicherten) ",
  "from the FOPH OKP mandatory health insurance dashboard, measured in Swiss francs. ",
  "\\textbf{Treatment:} Binary --- canton adopted a tobacco billboard advertising ban (16 treated cantons, staggered 1997--2017). ",
  "\\textbf{Data:} FOPH OKP Dashboard, 1997--2024, canton-year level, 26 cantons, ", fmt_int(nrow(panel_total)), " canton-year observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly robust DiD with never-treated comparison group; standard errors clustered at canton level. ",
  "\\textbf{Sample:} All 26 Swiss cantons; 16 adopted billboard bans at different dates, 10 never adopted. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of per-capita costs among treated cantons. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build table
make_sde_row <- function(row) {
  paste0(
    row$outcome, " & ", fmt(row$beta, 1),
    " & (", fmt(row$se, 1), ")",
    " & ", fmt(row$sd_y, 1),
    " & ", fmt(row$sde, 3),
    " & (", fmt(row$se_sde, 3), ")",
    " & ", row$classification, " \\\\\n"
  )
}

panel_a_rows <- paste0(sapply(seq_len(nrow(sde_rows)), function(i) make_sde_row(sde_rows[i])), collapse = "")
panel_b_rows <- paste0(sapply(seq_len(nrow(het_rows)), function(i) make_sde_row(het_rows[i])), collapse = "")

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lrrrrrr}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  panel_a_rows,
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  panel_b_rows,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
