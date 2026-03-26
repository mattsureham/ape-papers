## 05_tables.R — Generate all LaTeX tables
## APEP-0973: Plastic Bag Charges and Beach Litter

source("00_packages.R")
setwd(file.path(here::here(), "output", "apep_0973", "v1"))

panel <- as.data.frame(readRDS("data/analysis_panel.rds"))
names(panel)[names(panel) == "gname"] <- "first_treat"
names(panel)[names(panel) == "tname"] <- "time_var"
names(panel)[names(panel) == "idname"] <- "unit_var"

results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")

make_stars <- function(est, se) {
  if (is.na(est) | is.na(se) | se == 0) return("")
  p <- 2 * pnorm(-abs(est / se))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Re-run TWFE with beach-level clustering for tables
twfe_bags <- feols(log_bags ~ post | unit_var + time_var, data = panel, cluster = ~unit_var)
twfe_total <- feols(log_total ~ post | unit_var + time_var, data = panel, cluster = ~unit_var)
twfe_nonbag <- feols(log_nonbag ~ post | unit_var + time_var, data = panel, cluster = ~unit_var)
twfe_share <- feols(bag_share ~ post | unit_var + time_var, data = panel, cluster = ~unit_var)

# CS results
cs_bags <- results$cs_bags_att
cs_nonbag <- results$cs_nonbag_att
cs_total <- results$cs_total_att
cs_share <- results$cs_share_att

# ==========================================================================
# Table 1: Summary Statistics
# ==========================================================================

cat("=== Table 1 ===\n")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: Beach Litter by Nation and Treatment Status}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Bag Items} & \\multicolumn{2}{c}{Total Litter} & Bag & \\\\",
  " & Mean & SD & Mean & SD & Share & N \\\\",
  "\\midrule"
)

for (nat in c("Wales", "Northern Ireland", "Scotland", "England")) {
  for (period in c("Pre", "Post")) {
    sub <- panel[panel$nation == nat & ((period == "Pre" & panel$time_var < panel$first_treat) |
                                         (period == "Post" & panel$time_var >= panel$first_treat)), ]
    if (nrow(sub) > 0) {
      label <- ifelse(period == "Pre",
                       sprintf("\\quad %s (pre-charge)", nat),
                       sprintf("\\quad %s (post-charge)", nat))
      tab1_lines <- c(tab1_lines, sprintf(
        "%s & %.1f & %.1f & %.0f & %.0f & %.3f & %d \\\\",
        label,
        mean(sub$bags, na.rm = TRUE), sd(sub$bags, na.rm = TRUE),
        mean(sub$total_litter, na.rm = TRUE), sd(sub$total_litter, na.rm = TRUE),
        mean(sub$bag_share, na.rm = TRUE), nrow(sub)
      ))
    }
  }
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Full sample & %.1f & %.1f & %.0f & %.0f & %.3f & %d \\\\",
          mean(panel$bags, na.rm = TRUE), sd(panel$bags, na.rm = TRUE),
          mean(panel$total_litter, na.rm = TRUE), sd(panel$total_litter, na.rm = TRUE),
          mean(panel$bag_share, na.rm = TRUE), nrow(panel)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Beach-year level observations from OSPAR 100m transect surveys, 2001--2020. ",
         "Bag items include carrier bags, small bags, and bag fragments (OSPAR codes 2, 3, 112). ",
         "Total litter counts all 112 OSPAR item categories. Bag share is the ratio of bag items to total litter. ",
         "Charge introduction dates: Wales (October 2011), Northern Ireland (April 2013), Scotland (October 2014), ",
         "England (October 2015). N = 47 monitoring beaches across four UK nations."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1_lines, "tables/tab1_sumstats.tex")

# ==========================================================================
# Table 2: Main Results
# ==========================================================================

cat("=== Table 2 ===\n")

fmt <- function(est, se) {
  stars <- make_stars(est, se)
  sprintf("%.3f%s", est, stars)
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Effect of Plastic Bag Charges on Beach Litter Composition}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Log Bag & Log Total & Log Non-Bag & Bag \\\\",
  " & Items & Litter & Litter & Share \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: TWFE}} \\\\[3pt]",
  sprintf("Post-charge & %s & %s & %s & %s \\\\",
          fmt(coef(twfe_bags)["post"], se(twfe_bags)["post"]),
          fmt(coef(twfe_total)["post"], se(twfe_total)["post"]),
          fmt(coef(twfe_nonbag)["post"], se(twfe_nonbag)["post"]),
          fmt(coef(twfe_share)["post"], se(twfe_share)["post"])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.4f) \\\\",
          se(twfe_bags)["post"], se(twfe_total)["post"],
          se(twfe_nonbag)["post"], se(twfe_share)["post"]),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(twfe_bags), nobs(twfe_total), nobs(twfe_nonbag), nobs(twfe_share)),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Callaway-Sant'Anna}} \\\\[3pt]",
  sprintf("ATT & %s & %s & %s & %s \\\\",
          fmt(cs_bags$overall.att, cs_bags$overall.se),
          fmt(cs_total$overall.att, cs_total$overall.se),
          fmt(cs_nonbag$overall.att, cs_nonbag$overall.se),
          fmt(cs_share$overall.att, cs_share$overall.se)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.4f) \\\\",
          cs_bags$overall.se, cs_total$overall.se,
          cs_nonbag$overall.se, cs_share$overall.se),
  "\\midrule",
  "Beach FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Beaches & %d & %d & %d & %d \\\\",
          n_distinct(panel$unit_var), n_distinct(panel$unit_var),
          n_distinct(panel$unit_var), n_distinct(panel$unit_var)),
  "Clustering & Beach & Beach & Beach & Beach \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the beach level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. Panel A reports two-way fixed effects estimates. ",
         "Panel B reports Callaway-Sant'Anna (2021) staggered DiD using not-yet-treated beaches as controls. ",
         "The dependent variable in column (1) is log(bag items + 1); columns (2)--(3) are log(total litter + 1) ",
         "and log(non-bag litter + 1); column (4) is the bag share of total litter. ",
         "Sample: 47 OSPAR monitoring beaches across Wales, Northern Ireland, Scotland, and England, 2001--2020."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2_lines, "tables/tab2_main.tex")

# ==========================================================================
# Table 3: Robustness
# ==========================================================================

cat("=== Table 3 ===\n")

rob_data <- list(
  list("Baseline (not-yet-treated)", cs_bags$overall.att, cs_bags$overall.se),
  list("IHS transformation", robust$cs_ihs_att$overall.att, robust$cs_ihs_att$overall.se),
  list("Raw bag counts", robust$cs_levels_att$overall.att, robust$cs_levels_att$overall.se),
  list("Excl.\\ 2020 (COVID)", robust$cs_no2020_att$overall.att, robust$cs_no2020_att$overall.se),
  list("Drop England", robust$cs_no_eng_att$overall.att, robust$cs_no_eng_att$overall.se),
  list("Drop Wales", robust$cs_no_wales_att$overall.att, robust$cs_no_wales_att$overall.se)
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness: Alternative Specifications for Bag Litter}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & CS ATT & SE \\\\",
  "\\midrule"
)

for (r in rob_data) {
  est <- r[[2]]; se_val <- r[[3]]
  stars <- make_stars(est, se_val)
  tab3_lines <- c(tab3_lines, sprintf("%s & %s & (%.3f) \\\\",
                                       r[[1]], sprintf("%.3f%s", est, stars), se_val))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Placebo: plastic bottles & %s & (%.3f) \\\\",
          sprintf("%.3f%s", robust$cs_bottles$overall.att,
                  make_stars(robust$cs_bottles$overall.att, robust$cs_bottles$overall.se)),
          robust$cs_bottles$overall.se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each row reports the Callaway-Sant'Anna simple ATT. ",
         "Row 1 is the baseline from Table~\\ref{tab:main}. The placebo outcome (plastic bottles) ",
         "was not subject to the carrier bag charge and tests whether the design captures bag-specific effects."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3_lines, "tables/tab3_robust.tex")

# ==========================================================================
# Table 4: Event Study
# ==========================================================================

cat("=== Table 4 ===\n")

es <- results$cs_bags_es
es_df <- data.frame(
  egt = es$egt,
  att = es$att.egt,
  se = es$se.egt
)
es_df <- es_df[!is.na(es_df$att), ]

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Event Study: Dynamic Effects on Log Bag Items}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{cccc}",
  "\\toprule",
  "Event Time & ATT & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_df)) {
  stars <- make_stars(es_df$att[i], es_df$se[i])
  tab4_lines <- c(tab4_lines, sprintf(
    "%+d & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\",
    es_df$egt[i], es_df$att[i], stars, es_df$se[i],
    es_df$att[i] - 1.96 * es_df$se[i],
    es_df$att[i] + 1.96 * es_df$se[i]
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Callaway-Sant'Anna dynamic aggregation with not-yet-treated control. ",
         "Event time 0 is the first full year after the bag charge was introduced. ",
         "Pre-treatment coefficients test parallel trends."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4_lines, "tables/tab4_eventstudy.tex")

# ==========================================================================
# Table F1: SDE Appendix
# ==========================================================================

cat("=== Table F1: SDE ===\n")

pre <- panel[panel$time_var < panel$first_treat, ]
sd_log_bags <- sd(pre$log_bags, na.rm = TRUE)
sd_bag_share <- sd(pre$bag_share, na.rm = TRUE)
sd_log_total <- sd(pre$log_total, na.rm = TRUE)

sde_bags <- cs_bags$overall.att / sd_log_bags
sde_bags_se <- cs_bags$overall.se / sd_log_bags
sde_share <- cs_share$overall.att / sd_bag_share
sde_share_se <- cs_share$overall.se / sd_bag_share
sde_total <- cs_total$overall.att / sd_log_total
sde_total_se <- cs_total$overall.se / sd_log_total

classify <- function(s) {
  if (is.na(s)) return("N/A")
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s <= 0.005) "Null"
  else if (s <= 0.05) "Small positive"
  else if (s <= 0.15) "Moderate positive"
  else "Large positive"
}

f3 <- function(x) ifelse(is.na(x), "---", sprintf("%.3f", x))
f4 <- function(x) ifelse(is.na(x), "---", sprintf("%.4f", x))

# Panel B: heterogeneity by rural vs urban (we approximate by pre-treatment total litter level)
med_litter <- median(pre$total_litter, na.rm = TRUE)
high <- panel[panel$beach_id %in% unique(pre$beach_id[pre$total_litter >= med_litter]), ]
low <- panel[panel$beach_id %in% unique(pre$beach_id[pre$total_litter < med_litter]), ]

names(high)[names(high) == "gname"] <- "first_treat"
names(high)[names(high) == "tname"] <- "time_var"
names(high)[names(high) == "idname"] <- "unit_var"
names(low)[names(low) == "gname"] <- "first_treat"
names(low)[names(low) == "tname"] <- "time_var"
names(low)[names(low) == "idname"] <- "unit_var"

cs_high <- tryCatch({
  o <- att_gt(yname="log_bags", tname="time_var", idname="unit_var", gname="first_treat",
              data=high, control_group="notyettreated", allow_unbalanced_panel=TRUE, base_period="universal")
  aggte(o, type="simple", na.rm=TRUE)
}, error = function(e) list(overall.att = NA, overall.se = NA))

cs_low <- tryCatch({
  o <- att_gt(yname="log_bags", tname="time_var", idname="unit_var", gname="first_treat",
              data=low, control_group="notyettreated", allow_unbalanced_panel=TRUE, base_period="universal")
  aggte(o, type="simple", na.rm=TRUE)
}, error = function(e) list(overall.att = NA, overall.se = NA))

sde_high <- ifelse(is.na(cs_high$overall.att), NA, cs_high$overall.att / sd_log_bags)
sde_high_se <- ifelse(is.na(cs_high$overall.se), NA, cs_high$overall.se / sd_log_bags)
sde_low <- ifelse(is.na(cs_low$overall.att), NA, cs_low$overall.att / sd_log_bags)
sde_low_se <- ifelse(is.na(cs_low$overall.se), NA, cs_low$overall.se / sd_log_bags)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Do mandatory plastic bag charges reduce actual environmental pollution, ",
  "as measured by carrier bag counts in standardized beach litter surveys? ",
  "\\textbf{Policy mechanism:} Four UK nations sequentially introduced mandatory 5p charges on single-use ",
  "carrier bags at retail point of sale, requiring retailers to charge consumers per bag and raising the ",
  "relative price of disposable bags to induce substitution toward reusable alternatives. ",
  "\\textbf{Outcome definition:} Count of carrier bags (OSPAR litter category 2), small bags (category 3), ",
  "and bag fragments (category 112) per standardized 100-meter beach transect survey. ",
  "\\textbf{Treatment:} Binary; equals one after the mandatory bag charge takes effect in that beach's nation. ",
  "\\textbf{Data:} OSPAR Beach Litter Database, 2001--2020, 47 UK monitoring beaches across four nations, ",
  sprintf("%d beach-year observations. ", nrow(panel)),
  "\\textbf{Method:} Callaway-Sant'Anna (2021) staggered DiD with not-yet-treated beaches as control; ",
  "standard errors clustered at beach level. ",
  "\\textbf{Sample:} All OSPAR 100m transect monitoring beaches in England, Wales, Scotland, and Northern Ireland ",
  "with at least one survey during 2001--2020; Channel Islands excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Log bag items & %s & %s & %s & %s & %s & %s \\\\",
          f3(cs_bags$overall.att), f3(cs_bags$overall.se), f3(sd_log_bags),
          f3(sde_bags), f3(sde_bags_se), classify(sde_bags)),
  sprintf("Bag share & %s & %s & %s & %s & %s & %s \\\\",
          f4(cs_share$overall.att), f4(cs_share$overall.se), f4(sd_bag_share),
          f3(sde_share), f3(sde_share_se), classify(sde_share)),
  sprintf("Log total litter & %s & %s & %s & %s & %s & %s \\\\",
          f3(cs_total$overall.att), f3(cs_total$overall.se), f3(sd_log_total),
          f3(sde_total), f3(sde_total_se), classify(sde_total)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-treatment litter intensity)}} \\\\[3pt]",
  sprintf("Log bag items (high-litter beaches) & %s & %s & %s & %s & %s & %s \\\\",
          f3(cs_high$overall.att), f3(cs_high$overall.se), f3(sd_log_bags),
          f3(sde_high), f3(sde_high_se), classify(sde_high)),
  sprintf("Log bag items (low-litter beaches) & %s & %s & %s & %s & %s & %s \\\\",
          f3(cs_low$overall.att), f3(cs_low$overall.se), f3(sd_log_bags),
          f3(sde_low), f3(sde_low_se), classify(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1_lines, "tables/tabF1_sde.tex")

cat("=== All Tables Generated ===\n")
