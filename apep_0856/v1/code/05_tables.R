# 05_tables.R — Generate all LaTeX tables
# apep_0856: Tipped MW Stability Paradox

source("code/00_packages.R")

# ============================================================
# 1. Load results
# ============================================================
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")
county <- fread("data/county_panel.csv")
placebo <- fread("data/placebo_panel.csv")
state_panel <- fread("data/state_year_race.csv")

# Helper: extract coefficient
extract_coef <- function(model, var_pattern) {
  ct <- coeftable(model)
  idx <- grep(var_pattern, rownames(ct), fixed = TRUE)
  if (length(idx) == 0) idx <- grep(var_pattern, rownames(ct))
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA))
  list(b = ct[idx[1], 1], se = ct[idx[1], 2], p = ct[idx[1], 4])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  ""
}

# ============================================================
# Table 1: Summary Statistics — The Stability Paradox
# ============================================================

ofw_stats <- state_panel[ofw == 1, .(
  earn = weighted.mean(earn_avg, total_emp, na.rm = TRUE),
  sep = weighted.mean(sep_rate, total_emp, na.rm = TRUE),
  emp = sum(total_emp, na.rm = TRUE) / uniqueN(year)
), by = race_label]

tc_stats <- state_panel[ofw == 0, .(
  earn = weighted.mean(earn_avg, total_emp, na.rm = TRUE),
  sep = weighted.mean(sep_rate, total_emp, na.rm = TRUE),
  emp = sum(total_emp, na.rm = TRUE) / uniqueN(year)
), by = race_label]

ofw_b <- ofw_stats[race_label == "Black"]
ofw_w <- ofw_stats[race_label == "White"]
tc_b <- tc_stats[race_label == "Black"]
tc_w <- tc_stats[race_label == "White"]

tab1 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{The Stability Paradox: Racial Gaps in Restaurants by Wage Regime}
\\label{tab:paradox}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{One Fair Wage} & \\multicolumn{2}{c}{Tip-Credit} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Black & White & Black & White \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Quarterly Earnings (\\$)}} \\\\[3pt]
Mean & %s & %s & %s & %s \\\\
B--W gap & \\multicolumn{2}{c}{\\$%s (%s\\%%)} & \\multicolumn{2}{c}{\\$%s (%s\\%%)} \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Quarterly Separation Rate}} \\\\[3pt]
Mean & %s & %s & %s & %s \\\\
B--W gap (pp) & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\[6pt]
\\midrule
States & \\multicolumn{2}{c}{7} & \\multicolumn{2}{c}{%d} \\\\
Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} QWI administrative data, NAICS 722 (restaurants), 2010--2023. One Fair Wage (OFW) states: AK, CA, MN, MT, NV, OR, WA. Employment-weighted means. Separation rate $=$ quarterly separations / beginning-of-quarter employment. B--W earnings gap $=$ White $-$ Black. Separation gap $=$ Black rate $-$ White rate (percentage points).
\\end{tablenotes}
\\end{table}",
  formatC(ofw_b$earn, format="f", digits=0, big.mark=","),
  formatC(ofw_w$earn, format="f", digits=0, big.mark=","),
  formatC(tc_b$earn, format="f", digits=0, big.mark=","),
  formatC(tc_w$earn, format="f", digits=0, big.mark=","),
  formatC(abs(ofw_w$earn - ofw_b$earn), format="f", digits=0),
  formatC((ofw_w$earn - ofw_b$earn) / ofw_w$earn * 100, format="f", digits=1),
  formatC(abs(tc_w$earn - tc_b$earn), format="f", digits=0),
  formatC((tc_w$earn - tc_b$earn) / tc_w$earn * 100, format="f", digits=1),
  formatC(ofw_b$sep, format="f", digits=3),
  formatC(ofw_w$sep, format="f", digits=3),
  formatC(tc_b$sep, format="f", digits=3),
  formatC(tc_w$sep, format="f", digits=3),
  formatC((ofw_b$sep - ofw_w$sep) * 100, format="f", digits=1),
  formatC((tc_b$sep - tc_w$sep) * 100, format="f", digits=1),
  uniqueN(state_panel[ofw==0]$statefip),
  formatC(nrow(state_panel[ofw==1]), format="d", big.mark=","),
  formatC(nrow(state_panel[ofw==0]), format="d", big.mark=",")
)

writeLines(tab1, "tables/tab1_paradox.tex")

# ============================================================
# Table 2: Main DDD Results
# ============================================================

# Extract DDD triple interaction
m1e <- extract_coef(results$m1_earn, "tipped_ratio:black:restaurant")
m1s <- extract_coef(results$m1_sep, "tipped_ratio:black:restaurant")
m2e <- extract_coef(results$m2_earn, "tipped_ratio:black:restaurant")
m2s <- extract_coef(results$m2_sep, "tipped_ratio:black:restaurant")
# Restaurant-only
m3e <- extract_coef(results$m3_earn, "tipped_ratio:black")
m3s <- extract_coef(results$m3_sep, "tipped_ratio:black")

tab2 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Tipped Minimum Wages and Racial Gaps: Difference-in-Difference-in-Differences}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Earnings (\\$/qtr)} & \\multicolumn{2}{c}{Separation Rate} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & (1) & (2) & (3) & (4) \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: DDD (Restaurant vs.\\ Insurance $\\times$ Black $\\times$ Tipped Ratio)}} \\\\[3pt]
Tipped Ratio $\\times$ Black $\\times$ Restaurant & %s%s & %s%s & %s%s & %s%s \\\\
 & (%s) & (%s) & (%s) & (%s) \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Restaurant Only (Black $\\times$ Tipped Ratio)}} \\\\[3pt]
Tipped Ratio $\\times$ Black & & %s%s & & %s%s \\\\
 & & (%s) & & (%s) \\\\[6pt]
\\midrule
State + Year + Race FE & Yes & & Yes & \\\\
County$\\times$Race$\\times$Ind + Year$\\times$Race$\\times$Ind FE & & Yes & & Yes \\\\
Observations & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Panel A stacks restaurant (NAICS 722) and insurance (NAICS 524) employment. The triple interaction isolates the restaurant-specific (tipping-channel) effect of the tipped minimum wage ratio on the Black--White gap. Tipped Ratio $=$ state tipped MW / state regular MW (1.0 in OFW states, $\\approx$0.29 at federal tipped floor). All regressions employment-weighted, SEs clustered by state. Panel B restricts to restaurants only. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.
\\end{tablenotes}
\\end{table}",
  formatC(m1e$b, format="f", digits=0, big.mark=","), stars(m1e$p),
  formatC(m2e$b, format="f", digits=0, big.mark=","), stars(m2e$p),
  formatC(m1s$b, format="f", digits=3), stars(m1s$p),
  formatC(m2s$b, format="f", digits=3), stars(m2s$p),
  formatC(m1e$se, format="f", digits=0, big.mark=","),
  formatC(m2e$se, format="f", digits=0, big.mark=","),
  formatC(m1s$se, format="f", digits=3),
  formatC(m2s$se, format="f", digits=3),
  formatC(m3e$b, format="f", digits=0, big.mark=","), stars(m3e$p),
  formatC(m3s$b, format="f", digits=3), stars(m3s$p),
  formatC(m3e$se, format="f", digits=0, big.mark=","),
  formatC(m3s$se, format="f", digits=3),
  formatC(nobs(results$m1_earn), format="d", big.mark=","),
  formatC(nobs(results$m2_earn), format="d", big.mark=","),
  formatC(nobs(results$m1_sep), format="d", big.mark=","),
  formatC(nobs(results$m2_sep), format="d", big.mark=",")
)

writeLines(tab2, "tables/tab2_main.tex")

# ============================================================
# Table 3: Event Study Summary (NY tipped MW increase)
# ============================================================

# Extract event study pre/post coefficients for the Black interaction
es_earn_ct <- coeftable(results$es_earn)
es_sep_ct <- coeftable(results$es_sep)

# Black interaction coefficients
earn_rows <- grep("treated:black", rownames(es_earn_ct))
sep_rows <- grep("treated:black", rownames(es_sep_ct))

earn_es <- data.table(
  period = as.integer(gsub(".*::([-0-9]+).*", "\\1", rownames(es_earn_ct)[earn_rows])),
  coef = es_earn_ct[earn_rows, 1],
  se = es_earn_ct[earn_rows, 2],
  p = es_earn_ct[earn_rows, 4]
)

sep_es <- data.table(
  period = as.integer(gsub(".*::([-0-9]+).*", "\\1", rownames(es_sep_ct)[sep_rows])),
  coef = sep_sep_ct <- es_sep_ct[sep_rows, 1],
  se = es_sep_ct[sep_rows, 2],
  p = es_sep_ct[sep_rows, 4]
)
sep_es[, coef := es_sep_ct[sep_rows, 1]]

# Build table rows
es_rows_earn <- paste(sapply(1:nrow(earn_es), function(i) {
  sprintf("$t%s%d$ & %s%s & (%s)",
          ifelse(earn_es$period[i] >= 0, "+", ""), earn_es$period[i],
          formatC(earn_es$coef[i], format="f", digits=1), stars(earn_es$p[i]),
          formatC(earn_es$se[i], format="f", digits=1))
}), collapse = " \\\\\n")

es_rows_sep <- paste(sapply(1:nrow(sep_es), function(i) {
  sprintf("$t%s%d$ & %s%s & (%s)",
          ifelse(sep_es$period[i] >= 0, "+", ""), sep_es$period[i],
          formatC(sep_es$coef[i], format="f", digits=4), stars(sep_es$p[i]),
          formatC(sep_es$se[i], format="f", digits=4))
}), collapse = " \\\\\n")

tab3 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Event Study: New York Tipped Minimum Wage Increase (2016)}
\\label{tab:eventstudy}
\\begin{tabular}{lcc}
\\toprule
Period & Coefficient & SE \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Earnings $\\times$ Black interaction}} \\\\[3pt]
%s \\\\[6pt]
\\multicolumn{3}{l}{\\textit{Panel B: Separation Rate $\\times$ Black interaction}} \\\\[3pt]
%s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Event study around New York's 2016 tipped MW increase (\\$5.00$\\to$\\$7.50). Reference period: $t-1$. Controls: PA, TX, IN, KS, MS, NC, OK, TN (stable tipped MW near federal \\$2.13). Restaurant employment only (NAICS 722). County and year FEs, employment-weighted, SEs clustered by state. The interaction with Black captures the differential effect on the racial gap. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.
\\end{tablenotes}
\\end{table}",
  es_rows_earn, es_rows_sep
)

writeLines(tab3, "tables/tab3_eventstudy.tex")

# ============================================================
# Table 4: Robustness
# ============================================================

re <- extract_coef(rob$loo_earn, "tipped_ratio:black:restaurant")
rs <- extract_coef(rob$loo_sep, "tipped_ratio:black:restaurant")
ae <- extract_coef(rob$alt_earn, "tipped_ratio:black:restaurant")
as_ <- extract_coef(rob$alt_sep, "tipped_ratio:black:restaurant")
ce <- extract_coef(rob$cov_earn, "tipped_ratio:black:restaurant")
cs <- extract_coef(rob$cov_sep, "tipped_ratio:black:restaurant")
ue <- extract_coef(rob$uw_earn, "tipped_ratio:black:restaurant")
us <- extract_coef(rob$uw_sep, "tipped_ratio:black:restaurant")

tab4 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Robustness of DDD Estimates}
\\label{tab:robustness}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Earnings} & \\multicolumn{2}{c}{Separation Rate} \\\\
 \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & Coeff. & SE & Coeff. & SE \\\\
\\midrule
Baseline & %s%s & (%s) & %s%s & (%s) \\\\
Drop California & %s%s & (%s) & %s%s & (%s) \\\\
State$\\times$Year clustering & %s%s & (%s) & %s%s & (%s) \\\\
Drop COVID (2020--21) & %s%s & (%s) & %s%s & (%s) \\\\
Unweighted & %s%s & (%s) & %s%s & (%s) \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} All specifications include county$\\times$race$\\times$industry and year$\\times$race$\\times$industry fixed effects. Coefficient is Tipped Ratio $\\times$ Black $\\times$ Restaurant. Baseline uses employment weights and state-level clustering. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.
\\end{tablenotes}
\\end{table}",
  formatC(m2e$b, format="f", digits=0), stars(m2e$p), formatC(m2e$se, format="f", digits=0),
  formatC(m2s$b, format="f", digits=3), stars(m2s$p), formatC(m2s$se, format="f", digits=3),
  formatC(re$b, format="f", digits=0), stars(re$p), formatC(re$se, format="f", digits=0),
  formatC(rs$b, format="f", digits=3), stars(rs$p), formatC(rs$se, format="f", digits=3),
  formatC(ae$b, format="f", digits=0), stars(ae$p), formatC(ae$se, format="f", digits=0),
  formatC(as_$b, format="f", digits=3), stars(as_$p), formatC(as_$se, format="f", digits=3),
  formatC(ce$b, format="f", digits=0), stars(ce$p), formatC(ce$se, format="f", digits=0),
  formatC(cs$b, format="f", digits=3), stars(cs$p), formatC(cs$se, format="f", digits=3),
  formatC(ue$b, format="f", digits=0), stars(ue$p), formatC(ue$se, format="f", digits=0),
  formatC(us$b, format="f", digits=3), stars(us$p), formatC(us$se, format="f", digits=3)
)

writeLines(tab4, "tables/tab4_robustness.tex")

# ============================================================
# Table F1: SDE Appendix
# ============================================================

# Use DDD saturated model
m <- results$m2_earn
ms <- results$m2_sep

# DDD coefficient for earnings
b_earn <- m2e$b
se_earn <- m2e$se

# DDD coefficient for separation
b_sep <- m2s$b
se_sep <- m2s$se

# SD of treatment (tipped_ratio in restaurants for Black workers)
county[, restaurant := 1L]
placebo[, restaurant := 0L]
stack2 <- rbind(county[, .(tipped_ratio, black, restaurant, Emp, earn_avg, sep_rate, ofw, year)],
                placebo[, .(tipped_ratio, black, restaurant, Emp, earn_avg, sep_rate, ofw, year)])
rest_black <- stack2[restaurant == 1 & black == 1]

sd_treatment <- sd(rest_black$tipped_ratio, na.rm = TRUE)

# Pre-treatment SDs (tip-credit restaurants, pre-2016)
pre_rest <- county[ofw == 0 & year <= 2015]
sd_earn_pre <- sd(pre_rest$earn_avg, na.rm = TRUE)
sd_sep_pre <- sd(pre_rest$sep_rate, na.rm = TRUE)

# SDE = beta * SD(treatment × black × restaurant) / SD(Y)
# For DDD, the "treatment" is the interaction tipped_ratio × black × restaurant
# SD of this interaction is approximately SD(tipped_ratio) for the relevant subpopulation
sde_earn <- b_earn * sd_treatment / sd_earn_pre
se_sde_earn <- se_earn * sd_treatment / sd_earn_pre

sde_sep <- b_sep * sd_treatment / sd_sep_pre
se_sde_sep <- se_sep * sd_treatment / sd_sep_pre

classify_sde <- function(sde) {
  if (is.na(sde)) return("NA")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_earn <- classify_sde(sde_earn)
class_sep <- classify_sde(sde_sep)

# Heterogeneity: states with large tipped MW changes (NY, IL, AZ) vs others
event_states <- c(36L, 17L, 4L)
county[, event_state := as.integer(statefip %in% event_states)]

event_rest <- county[event_state == 1]
other_rest <- county[event_state == 0]

event_rest[, county_race := paste0(fips_county, "_", race)]
event_rest[, year_race := paste0(year, "_", race)]
other_rest[, county_race := paste0(fips_county, "_", race)]
other_rest[, year_race := paste0(year, "_", race)]

m_event <- feols(earn_avg ~ tipped_ratio:black | county_race + year_race,
                 data = event_rest, weights = ~Emp, cluster = ~statefip)
m_other <- feols(earn_avg ~ tipped_ratio:black | county_race + year_race,
                 data = other_rest, weights = ~Emp, cluster = ~statefip)

he <- extract_coef(m_event, "tipped_ratio:black")
lo <- extract_coef(m_other, "tipped_ratio:black")

sd_earn_event <- sd(event_rest[year <= 2015]$earn_avg, na.rm = TRUE)
sd_earn_other <- sd(other_rest[year <= 2015]$earn_avg, na.rm = TRUE)
sd_tr_event <- sd(event_rest$tipped_ratio, na.rm = TRUE)
sd_tr_other <- sd(other_rest$tipped_ratio, na.rm = TRUE)

sde_event <- he$b * sd_tr_event / sd_earn_event
se_sde_event <- he$se * sd_tr_event / sd_earn_event
sde_other <- lo$b * sd_tr_other / sd_earn_other
se_sde_other <- lo$se * sd_tr_other / sd_earn_other

class_event <- classify_sde(sde_event)
class_other <- classify_sde(sde_other)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does eliminating the tipped subminimum wage reduce the Black--White earnings gap and the Black--White employment stability gap in restaurants? ",
  "\\textbf{Policy mechanism:} One Fair Wage laws require employers to pay tipped workers the full standard minimum wage, removing the tip credit that allows employers to pay as low as \\$2.13/hour federally; this eliminates the channel through which customer tipping discrimination maps into racial earnings disparities but leaves employer-side hiring and retention discrimination unchanged. ",
  "\\textbf{Outcome definition:} Quarterly earnings (EarnS) and quarterly separation rate (Sep/Emp) from QWI administrative records; Panel B heterogeneity splits by states with large tipped MW changes (NY, IL, AZ) vs.~stable states. ",
  "\\textbf{Treatment:} Continuous; state tipped minimum wage ratio (tipped MW / regular MW), ranging from 0.29 at federal floor to 1.0 in OFW states. ",
  "\\textbf{Data:} QWI Race$\\times$Ethnicity panel (NAICS 722 restaurants stacked with NAICS 524 insurance), county$\\times$quarter$\\times$race$\\times$industry, 2010--2023, ",
  formatC(nobs(results$m2_earn), format="d", big.mark=","), " observations. ",
  "\\textbf{Method:} Difference-in-difference-in-differences (restaurant vs.~insurance $\\times$ Black $\\times$ tipped ratio) with county$\\times$race$\\times$industry and year$\\times$race$\\times$industry fixed effects, employment-weighted, clustered at state level. ",
  "\\textbf{Sample:} Counties with $\\geq$25 employees per race$\\times$industry cell; 7 OFW states plus 46 tip-credit states. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
Earnings (DDD) & %s & %s & %s & %s & %s & %s \\\\
Separation rate (DDD) & %s & %s & %s & %s & %s & %s \\\\[6pt]
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (event states vs.\\ stable states)}} \\\\[3pt]
Earnings: NY/IL/AZ & %s & %s & %s & %s & %s & %s \\\\
Earnings: other states & %s & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
%s
\\end{tablenotes}
\\end{table}",
  formatC(b_earn, format="f", digits=1), formatC(se_earn, format="f", digits=1),
  formatC(sd_earn_pre, format="f", digits=1),
  formatC(sde_earn, format="f", digits=3), formatC(se_sde_earn, format="f", digits=3), class_earn,
  formatC(b_sep, format="f", digits=4), formatC(se_sep, format="f", digits=4),
  formatC(sd_sep_pre, format="f", digits=3),
  formatC(sde_sep, format="f", digits=3), formatC(se_sde_sep, format="f", digits=3), class_sep,
  formatC(he$b, format="f", digits=1), formatC(he$se, format="f", digits=1),
  formatC(sd_earn_event, format="f", digits=1),
  formatC(sde_event, format="f", digits=3), formatC(se_sde_event, format="f", digits=3), class_event,
  formatC(lo$b, format="f", digits=1), formatC(lo$se, format="f", digits=1),
  formatC(sd_earn_other, format="f", digits=1),
  formatC(sde_other, format="f", digits=3), formatC(se_sde_other, format="f", digits=3), class_other,
  sde_notes
)

writeLines(tabF1, "tables/tabF1_sde.tex")

cat("\nAll tables written.\n")
cat(sprintf("SDE earnings: %.3f (%s)\n", sde_earn, class_earn))
cat(sprintf("SDE separation: %.3f (%s)\n", sde_sep, class_sep))
