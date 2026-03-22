# ============================================================
# 05_tables.R — Generate all LaTeX tables
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------
# Load all results
# ----------------------------------------------------------
panel <- readRDS(file.path(data_dir, "panel_by_type.rds"))
agg_panel <- readRDS(file.path(data_dir, "panel_aggregate.rds"))
cs_att <- readRDS(file.path(data_dir, "cs_att_results.rds"))
cs_es <- readRDS(file.path(data_dir, "cs_es_results.rds"))
twfe_conv <- readRDS(file.path(data_dir, "twfe_conv.rds"))
ddd_results <- readRDS(file.path(data_dir, "ddd_results.rds"))
type_results <- readRDS(file.path(data_dir, "type_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Helper: format with stars
fmt_coef <- function(est, se, digits = 3) {
  pval <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(pval < 0.01, "***",
           ifelse(pval < 0.05, "**",
           ifelse(pval < 0.10, "*", "")))
  paste0(formatC(est, digits = digits, format = "f"), stars)
}

fmt_se <- function(se, digits = 3) {
  paste0("(", formatC(se, digits = digits, format = "f"), ")")
}

# ===========================================================
# TABLE 1: Summary Statistics
# ===========================================================
cat("=== Table 1: Summary Statistics ===\n")

conv <- panel[store_type == "convenience"]
smgr <- panel[store_type == "small_grocery"]
supe <- panel[store_type == "supermarket"]

# Pre-treatment stats
pre <- panel[panel$treated == 0 | is.na(panel$treated)]

sum_stats <- data.frame(
  Variable = c(
    "\\textbf{Panel A: Convenience Stores}",
    "\\quad Exit rate (per 1,000)",
    "\\quad Active stores",
    "\\quad Quarterly exits",
    "\\textbf{Panel B: Small Grocery Stores}",
    "\\quad Exit rate (per 1,000)",
    "\\quad Active stores",
    "\\quad Quarterly exits",
    "\\textbf{Panel C: Supermarkets}",
    "\\quad Exit rate (per 1,000)",
    "\\quad Active stores",
    "\\quad Quarterly exits"
  ),
  Mean = c(
    "", formatC(mean(pre[store_type == "convenience"]$exit_rate, na.rm = TRUE), digits = 1, format = "f"),
    formatC(mean(pre[store_type == "convenience"]$n_active, na.rm = TRUE), digits = 0, format = "f"),
    formatC(mean(pre[store_type == "convenience"]$n_exits, na.rm = TRUE), digits = 1, format = "f"),
    "", formatC(mean(pre[store_type == "small_grocery"]$exit_rate, na.rm = TRUE), digits = 1, format = "f"),
    formatC(mean(pre[store_type == "small_grocery"]$n_active, na.rm = TRUE), digits = 0, format = "f"),
    formatC(mean(pre[store_type == "small_grocery"]$n_exits, na.rm = TRUE), digits = 1, format = "f"),
    "", formatC(mean(pre[store_type == "supermarket"]$exit_rate, na.rm = TRUE), digits = 1, format = "f"),
    formatC(mean(pre[store_type == "supermarket"]$n_active, na.rm = TRUE), digits = 0, format = "f"),
    formatC(mean(pre[store_type == "supermarket"]$n_exits, na.rm = TRUE), digits = 1, format = "f")
  ),
  SD = c(
    "", formatC(sd(pre[store_type == "convenience"]$exit_rate, na.rm = TRUE), digits = 1, format = "f"),
    formatC(sd(pre[store_type == "convenience"]$n_active, na.rm = TRUE), digits = 0, format = "f"),
    formatC(sd(pre[store_type == "convenience"]$n_exits, na.rm = TRUE), digits = 1, format = "f"),
    "", formatC(sd(pre[store_type == "small_grocery"]$exit_rate, na.rm = TRUE), digits = 1, format = "f"),
    formatC(sd(pre[store_type == "small_grocery"]$n_active, na.rm = TRUE), digits = 0, format = "f"),
    formatC(sd(pre[store_type == "small_grocery"]$n_exits, na.rm = TRUE), digits = 1, format = "f"),
    "", formatC(sd(pre[store_type == "supermarket"]$exit_rate, na.rm = TRUE), digits = 1, format = "f"),
    formatC(sd(pre[store_type == "supermarket"]$n_active, na.rm = TRUE), digits = 0, format = "f"),
    formatC(sd(pre[store_type == "supermarket"]$n_exits, na.rm = TRUE), digits = 1, format = "f")
  ),
  N = c(
    "", nrow(pre[store_type == "convenience"]), "", "",
    "", nrow(pre[store_type == "small_grocery"]), "", "",
    "", nrow(pre[store_type == "supermarket"]), "", ""
  ),
  stringsAsFactors = FALSE
)

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: SNAP Retailer Panel, 2019Q1--2024Q4}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lrrr}",
  "\\toprule",
  " & Mean & SD & N (state-quarters) \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sum_stats))) {
  row <- sum_stats[i, ]
  if (grepl("Panel", row$Variable)) {
    tab1_lines <- c(tab1_lines, paste0(row$Variable, " & & & \\\\"))
  } else {
    tab1_lines <- c(tab1_lines,
                    paste0(row$Variable, " & ", row$Mean, " & ", row$SD,
                           " & ", row$N, " \\\\"))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment (before EA expiration) statistics for SNAP-authorized retailers.",
  "Exit rate is quarterly deauthorizations per 1,000 active stores. Active stores counted at start of quarter.",
  "Data from USDA FNS SNAP Retailer Historical Database, 2005--2025.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_sumstats.tex"))
cat("  Written tab1_sumstats.tex\n")

# ===========================================================
# TABLE 2: Main Results
# ===========================================================
cat("=== Table 2: Main Results ===\n")

# Collect estimates
cs_est <- cs_att$overall.att
cs_se_val <- cs_att$overall.se
cs_n <- nrow(conv)

twfe_est <- coef(twfe_conv)["treated"]
twfe_se_val <- sqrt(vcov(twfe_conv)["treated", "treated"])
twfe_n <- nobs(twfe_conv)

ddd_est_treat <- coef(ddd_results)["treated"]
ddd_se_treat <- sqrt(vcov(ddd_results)["treated", "treated"])
ddd_est_inter <- coef(ddd_results)["treated:snap_dependent"]
ddd_se_inter <- sqrt(vcov(ddd_results)["treated:snap_dependent", "treated:snap_dependent"])
ddd_n <- nobs(ddd_results)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of SNAP Emergency Allotment Expiration on Convenience Store Exit Rates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & CS ATT & TWFE & DDD \\\\",
  "\\midrule",
  paste0("EA Expired & ", fmt_coef(cs_est, cs_se_val), " & ",
         fmt_coef(twfe_est, twfe_se_val), " & ",
         fmt_coef(ddd_est_treat, ddd_se_treat), " \\\\"),
  paste0(" & ", fmt_se(cs_se_val), " & ", fmt_se(twfe_se_val), " & ",
         fmt_se(ddd_se_treat), " \\\\"),
  paste0(" & [", formatC(cs_att$overall.att - 1.96 * cs_att$overall.se, digits = 3, format = "f"),
         ", ", formatC(cs_att$overall.att + 1.96 * cs_att$overall.se, digits = 3, format = "f"),
         "] & & \\\\"),
  "\\addlinespace",
  paste0("EA Expired $\\times$ Convenience & & & ", fmt_coef(ddd_est_inter, ddd_se_inter), " \\\\"),
  paste0(" & & & ", fmt_se(ddd_se_inter), " \\\\"),
  "\\addlinespace",
  "\\midrule",
  paste0("Observations & ", format(cs_n, big.mark = ","), " & ", format(twfe_n, big.mark = ","),
         " & ", format(ddd_n, big.mark = ","), " \\\\"),
  paste0("States & 51 & 51 & 51 \\\\"),
  paste0("Quarters & 24 & 24 & 24 \\\\"),
  "Estimator & Callaway-Sant'Anna & TWFE & TWFE \\\\",
  "Control group & Not-yet-treated & --- & --- \\\\",
  "Clustering & State & State & State \\\\",
  "State FE & Yes & Yes & Yes \\\\",
  "Time FE & Yes & Yes & Yes \\\\",
  "Store-type FE & No & No & Yes \\\\",
  paste0("Pre-treatment mean & ", formatC(mean(conv$exit_rate[conv$treated == 0], na.rm = TRUE),
                                          digits = 2, format = "f"), " & & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is quarterly exit rate (deauthorizations per 1,000 active stores).",
  "Column (1) estimates the average treatment effect on the treated using Callaway and Sant'Anna (2021)",
  "with doubly-robust estimation and not-yet-treated states as controls.",
  "Column (2) reports two-way fixed effects.",
  "Column (3) is a triple-difference comparing convenience stores (high SNAP revenue share)",
  "to supermarkets (low share); the interaction term captures the differential effect.",
  "Standard errors clustered at the state level in parentheses.",
  "95\\% confidence interval in brackets (Column 1).",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

# ===========================================================
# TABLE 3: Robustness
# ===========================================================
cat("=== Table 3: Robustness ===\n")

# Early-only TWFE
early_est <- coef(robustness$twfe_early)["treated"]
early_se <- sqrt(vcov(robustness$twfe_early)["treated", "treated"])

# Heterogeneity interaction
hetero_est <- coef(robustness$twfe_hetero)["treated:early"]
hetero_se <- sqrt(vcov(robustness$twfe_hetero)["treated:early", "treated:early"])

# Entry rate
entry_est <- coef(robustness$twfe_entry)["treated"]
entry_se <- sqrt(vcov(robustness$twfe_entry)["treated", "treated"])

# Net rate
net_est <- coef(robustness$twfe_net)["treated"]
net_se <- sqrt(vcov(robustness$twfe_net)["treated", "treated"])

# Level exits
level_est <- coef(robustness$twfe_level)["treated"]
level_se <- sqrt(vcov(robustness$twfe_level)["treated", "treated"])

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Estimate & SE \\\\",
  "\\midrule",
  "\\textbf{Panel A: Subsample} & & \\\\",
  paste0("\\quad Early opt-out states only (18 states) & ", fmt_coef(early_est, early_se), " & ", fmt_se(early_se), " \\\\"),
  paste0("\\quad Treated $\\times$ Early interaction & ", fmt_coef(hetero_est, hetero_se), " & ", fmt_se(hetero_se), " \\\\"),
  "\\addlinespace",
  "\\textbf{Panel B: Alternative Outcomes} & & \\\\",
  paste0("\\quad Entry rate (new authorizations per 1,000) & ", fmt_coef(entry_est, entry_se), " & ", fmt_se(entry_se), " \\\\"),
  paste0("\\quad Net change rate (entries $-$ exits) & ", fmt_coef(net_est, net_se), " & ", fmt_se(net_se), " \\\\"),
  paste0("\\quad Exit count (level) & ", fmt_coef(level_est, level_se), " & ", fmt_se(level_se), " \\\\"),
  "\\addlinespace",
  "\\textbf{Panel C: Bacon Decomposition} & & \\\\",
  paste0("\\quad Earlier vs.~later treated (weight: ",
         formatC(robustness$bacon$total_weight[1], digits = 3, format = "f"), ") & ",
         formatC(robustness$bacon$avg_estimate[1], digits = 3, format = "f"), " & \\\\"),
  paste0("\\quad Later vs.~earlier treated (weight: ",
         formatC(robustness$bacon$total_weight[2], digits = 3, format = "f"), ") & ",
         formatC(robustness$bacon$avg_estimate[2], digits = 3, format = "f"), " & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include state and quarter fixed effects with standard errors",
  "clustered at the state level. Panel A restricts to 18 early opt-out states (Column 1) and tests for",
  "differential effects between early and late opt-outs (Column 2). Panel B uses alternative outcomes",
  "for convenience stores. Panel C reports the Goodman-Bacon (2021) decomposition of the TWFE estimate.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_robust.tex"))
cat("  Written tab3_robust.tex\n")

# ===========================================================
# TABLE 4: Store-Type Heterogeneity
# ===========================================================
cat("=== Table 4: Store-Type Heterogeneity ===\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effects by Store Type}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Convenience & Small Grocery & Supermarket \\\\",
  "\\midrule"
)

for (stype in c("convenience", "small_grocery", "supermarket")) {
  att <- type_results[[stype]]$att
  est <- att$overall.att
  se_val <- att$overall.se
  tab4_lines <- c(tab4_lines,
    paste0("CS ATT & ", fmt_coef(est, se_val), " & ")[1]
  )
}

# Build row manually
conv_att <- type_results[["convenience"]]$att
sg_att <- type_results[["small_grocery"]]$att
sup_att <- type_results[["supermarket"]]$att

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effects by Store Type: Callaway-Sant'Anna ATT Estimates}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Convenience & Small Grocery & Supermarket \\\\",
  "\\midrule",
  paste0("EA Expired (CS ATT) & ", fmt_coef(conv_att$overall.att, conv_att$overall.se),
         " & ", fmt_coef(sg_att$overall.att, sg_att$overall.se),
         " & ", fmt_coef(sup_att$overall.att, sup_att$overall.se), " \\\\"),
  paste0(" & ", fmt_se(conv_att$overall.se),
         " & ", fmt_se(sg_att$overall.se),
         " & ", fmt_se(sup_att$overall.se), " \\\\"),
  paste0(" & [", formatC(conv_att$overall.att - 1.96 * conv_att$overall.se, digits = 2, format = "f"),
         ", ", formatC(conv_att$overall.att + 1.96 * conv_att$overall.se, digits = 2, format = "f"),
         "] & [", formatC(sg_att$overall.att - 1.96 * sg_att$overall.se, digits = 2, format = "f"),
         ", ", formatC(sg_att$overall.att + 1.96 * sg_att$overall.se, digits = 2, format = "f"),
         "] & [", formatC(sup_att$overall.att - 1.96 * sup_att$overall.se, digits = 2, format = "f"),
         ", ", formatC(sup_att$overall.att + 1.96 * sup_att$overall.se, digits = 2, format = "f"),
         "] \\\\"),
  "\\addlinespace",
  paste0("Pre-treatment mean & ", formatC(mean(panel[store_type == "convenience" & treated == 0]$exit_rate, na.rm = TRUE), digits = 2, format = "f"),
         " & ", formatC(mean(panel[store_type == "small_grocery" & treated == 0]$exit_rate, na.rm = TRUE), digits = 2, format = "f"),
         " & ", formatC(mean(panel[store_type == "supermarket" & treated == 0]$exit_rate, na.rm = TRUE), digits = 2, format = "f"), " \\\\"),
  paste0("Pre-treatment SD & ", formatC(sd(panel[store_type == "convenience" & treated == 0]$exit_rate, na.rm = TRUE), digits = 2, format = "f"),
         " & ", formatC(sd(panel[store_type == "small_grocery" & treated == 0]$exit_rate, na.rm = TRUE), digits = 2, format = "f"),
         " & ", formatC(sd(panel[store_type == "supermarket" & treated == 0]$exit_rate, na.rm = TRUE), digits = 2, format = "f"), " \\\\"),
  "Observations & 1,224 & 1,224 & 1,224 \\\\",
  "States & 51 & 51 & 51 \\\\",
  "Control group & Not-yet-treated & Not-yet-treated & Not-yet-treated \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) ATT estimates with doubly-robust estimation.",
  "Dependent variable is quarterly exit rate (deauthorizations per 1,000 active stores) by store type.",
  "Standard errors (in parentheses) and 95\\% confidence intervals (in brackets).",
  "Convenience stores have the highest SNAP revenue dependence; supermarkets the lowest.",
  "$^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_heterogeneity.tex"))
cat("  Written tab4_heterogeneity.tex\n")

# ===========================================================
# TABLE F1: Standardized Effect Size (SDE) — APPENDIX
# ===========================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Calculate SDEs
outcomes <- data.frame(
  Outcome = c("Conv.~store exit rate", "Small grocery exit rate",
              "Supermarket exit rate", "All SNAP exit rate"),
  stringsAsFactors = FALSE
)

conv_sd_pre <- sd(panel[store_type == "convenience" & treated == 0]$exit_rate, na.rm = TRUE)
sg_sd_pre <- sd(panel[store_type == "small_grocery" & treated == 0]$exit_rate, na.rm = TRUE)
sup_sd_pre <- sd(panel[store_type == "supermarket" & treated == 0]$exit_rate, na.rm = TRUE)
agg_sd_pre <- sd(agg_panel[agg_panel$treated == 0, ]$exit_rate, na.rm = TRUE)

cs_agg_att <- readRDS(file.path(data_dir, "cs_agg_att.rds"))

est_vec <- c(conv_att$overall.att, sg_att$overall.att,
             sup_att$overall.att, cs_agg_att$overall.att)
se_vec <- c(conv_att$overall.se, sg_att$overall.se,
            sup_att$overall.se, cs_agg_att$overall.se)
sd_vec <- c(conv_sd_pre, sg_sd_pre, sup_sd_pre, agg_sd_pre)

sde_vec <- est_vec / sd_vec
sde_se_vec <- se_vec / sd_vec

classify_sde <- function(sde) {
  ifelse(sde < -0.15, "Large negative",
  ifelse(sde < -0.05, "Moderate negative",
  ifelse(sde < -0.005, "Small negative",
  ifelse(sde <= 0.005, "Null",
  ifelse(sde <= 0.05, "Small positive",
  ifelse(sde <= 0.15, "Moderate positive",
         "Large positive"))))))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the expiration of SNAP Emergency Allotments cause ",
  "SNAP-authorized food retailers to exit the market? ",
  "\\textbf{Policy mechanism:} Emergency Allotments provided an additional \\$95/month per ",
  "household to approximately 41 million SNAP participants during the COVID-19 pandemic. ",
  "Eighteen states ended EA early (April 2021--January 2023) through gubernatorial decisions; ",
  "remaining states lost EA in March 2023. Expiration reduced SNAP benefits by 30--40\\%, ",
  "removing approximately \\$46 billion in annual food purchasing power routed through ",
  "authorized retailers. ",
  "\\textbf{Outcome definition:} Quarterly deauthorization rate per 1,000 SNAP-authorized ",
  "retailers, measuring the rate at which stores lose their authorization to accept SNAP ",
  "benefits (exit the SNAP market). ",
  "\\textbf{Treatment:} Binary; equals one in the first quarter after a state's EA expires ",
  "and all subsequent quarters. ",
  "\\textbf{Data:} USDA FNS SNAP Retailer Historical Database (703,441 retailers, 2005--2025), ",
  "state-quarter panel, 51 states $\\times$ 24 quarters (2019Q1--2024Q4), 1,224 observations per store type. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly-robust staggered DiD with ",
  "not-yet-treated states as controls. Standard errors clustered at the state level. ",
  "\\textbf{Sample:} All SNAP-authorized retailers in 50 states plus DC; convenience stores ",
  "are the primary outcome given their dominant share (53\\%) of SNAP-authorized locations ",
  "and high SNAP revenue dependence. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_along(est_vec)) {
  tabF1_lines <- c(tabF1_lines,
    paste0(outcomes$Outcome[i], " & ",
           formatC(est_vec[i], digits = 3, format = "f"), " & ",
           formatC(se_vec[i], digits = 3, format = "f"), " & ",
           formatC(sd_vec[i], digits = 2, format = "f"), " & ",
           formatC(sde_vec[i], digits = 3, format = "f"), " & ",
           formatC(sde_se_vec[i], digits = 3, format = "f"), " & ",
           classify_sde(sde_vec[i]), " \\\\")
  )
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
