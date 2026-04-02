# 05_tables.R — Generate all LaTeX tables for apep_1333
# V1 format: max 5 tables + 1 SDE appendix table

setwd(here::here())
source("code/00_packages.R")

panel <- readRDS("data/panel_main.rds")
sumstats <- readRDS("data/sumstats.rds")
models <- readRDS("data/main_models.rds")
es_models <- readRDS("data/event_study_models.rds")
loo <- readRDS("data/loo_results.rds")
boot <- readRDS("data/bootstrap_results.rds")
ri <- readRDS("data/ri_results.rds")
diag <- fromJSON("data/diagnostics.json")

# ========================================================================
# TABLE 1: Summary Statistics
# ========================================================================
tab1 <- data.table(
  Variable = rep(c("Fish density (per 60m$^2$)", "Species richness",
                   "Targeted fish density", "Non-targeted fish density",
                   "Site-years"), 2),
  Group = c(rep("MPA Sites", 5), rep("Control Sites", 5))
)

# Fill in from sumstats
mpa_pre <- sumstats[period == "Pre-MPA" & group == "MPA sites"]
mpa_post <- sumstats[period == "Post-MPA" & group == "MPA sites"]
ctrl_pre <- sumstats[period == "Pre-MPA" & group == "Control sites"]
ctrl_post <- sumstats[period == "Post-MPA" & group == "Control sites"]

make_cell <- function(mean_val, sd_val) {
  sprintf("%.1f (%.1f)", mean_val, sd_val)
}

# Build table manually for LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Kelp Forest Fish Assemblages}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{MPA Sites (N=2)} & \\multicolumn{2}{c}{Control Sites (N=7)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Pre-MPA & Post-MPA & Pre-MPA & Post-MPA \\\\",
  "\\midrule",
  sprintf("Fish density (per 60m$^2$) & %s & %s & %s & %s \\\\",
          make_cell(mpa_pre$mean_density, mpa_pre$sd_density),
          make_cell(mpa_post$mean_density, mpa_post$sd_density),
          make_cell(ctrl_pre$mean_density, ctrl_pre$sd_density),
          make_cell(ctrl_post$mean_density, ctrl_post$sd_density)),
  sprintf("Species richness & %s & %s & %s & %s \\\\",
          make_cell(mpa_pre$mean_richness, mpa_pre$sd_richness),
          make_cell(mpa_post$mean_richness, mpa_post$sd_richness),
          make_cell(ctrl_pre$mean_richness, ctrl_pre$sd_richness),
          make_cell(ctrl_post$mean_richness, ctrl_post$sd_richness)),
  sprintf("Targeted fish density & %s & %s & %s & %s \\\\",
          make_cell(mpa_pre$mean_targeted, mpa_pre$sd_targeted),
          make_cell(mpa_post$mean_targeted, mpa_post$sd_targeted),
          make_cell(ctrl_pre$mean_targeted, ctrl_pre$sd_targeted),
          make_cell(ctrl_post$mean_targeted, ctrl_post$sd_targeted)),
  sprintf("Non-targeted fish density & %s & %s & %s & %s \\\\",
          make_cell(mpa_pre$mean_nontargeted, mpa_pre$sd_nontargeted),
          make_cell(mpa_post$mean_nontargeted, mpa_post$sd_nontargeted),
          make_cell(ctrl_pre$mean_nontargeted, ctrl_pre$sd_nontargeted),
          make_cell(ctrl_post$mean_nontargeted, ctrl_post$sd_nontargeted)),
  "\\midrule",
  sprintf("Site-years & %d & %d & %d & %d \\\\",
          mpa_pre$n, mpa_post$n, ctrl_pre$n, ctrl_post$n),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Standard deviations in parentheses. Fish density is the total count of fish per 60m$^2$ transect area, averaged across transects within each site-year. MPA sites are Naples Reef (Naples SMCA) and Isla Vista Reef (Campus Point SMCA, no-take), designated September 2007 under the Central Coast MLPA. Control sites are seven mainland kelp forest reefs in the Santa Barbara Channel not inside any MPA. Pre-MPA period: 2001--2007. Post-MPA period: 2008--2025. Data from SBC LTER KFCD annual surveys (knb-lter-sbc.17).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_sumstats.tex")

# ========================================================================
# TABLE 2: Main DiD Results
# ========================================================================
m1 <- models$m1; m2 <- models$m2; m3 <- models$m3; m4 <- models$m4

# Extract coefficients
get_row <- function(model, varname = "treated") {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.3f%s", b, stars),
       se = sprintf("(%.3f)", s),
       b = b, s = s, p = p)
}

r1 <- get_row(m1); r2 <- get_row(m2); r3 <- get_row(m3); r4 <- get_row(m4)

# Permutation p-values
perm_p_targeted <- sprintf("%.3f", boot$perm_p_targeted)
perm_p_all <- sprintf("%.3f", boot$perm_p_all)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Marine Protected Areas on Kelp Forest Fish Assemblages}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log All Fish & Log Targeted & Log Non-Targeted & Species \\\\",
  " & Density & Fish Density & Fish Density & Richness \\\\",
  "\\midrule",
  sprintf("MPA $\\times$ Post & %s & %s & %s & %s \\\\", r1$coef, r2$coef, r3$coef, r4$coef),
  sprintf(" & %s & %s & %s & %s \\\\", r1$se, r2$se, r3$se, r4$se),
  "\\addlinespace",
  sprintf("Permutation $p$-value & %s & %s & --- & --- \\\\", perm_p_all, perm_p_targeted),
  "\\addlinespace",
  sprintf("Site FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Sites & %d & %d & %d & %d \\\\", diag$n_treated + diag$n_control,
          diag$n_treated + diag$n_control, diag$n_treated + diag$n_control,
          diag$n_treated + diag$n_control),
  sprintf("Site-years & %d & %d & %d & %d \\\\", nrow(panel), nrow(panel),
          nrow(panel), nrow(panel)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a two-way fixed effects regression of the indicated outcome on an indicator for MPA site $\\times$ post-2007. Standard errors clustered at the site level in parentheses. Permutation $p$-value from 5,000 random reassignments of two sites as ``treated'' among nine mainland sites. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Column (3) is a placebo test: non-targeted species (not harvested recreationally or commercially) should show no MPA effect if the mechanism operates through reduced fishing mortality.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")

# ========================================================================
# TABLE 3: Event Study Coefficients
# ========================================================================
es <- es_models$es_targeted

# Extract event study coefficients
es_coefs <- data.table(
  rel_year = as.integer(gsub("rel_year_binned::(-?[0-9]+):mpa", "\\1",
                             names(coef(es)))),
  coef = coef(es),
  se = se(es)
)
es_coefs[, p := 2 * pnorm(-abs(coef / se))]
es_coefs[, stars := ifelse(p < 0.01, "***", ifelse(p < 0.05, "**",
                   ifelse(p < 0.1, "*", "")))]

# Split into pre and post
es_pre <- es_coefs[rel_year < 0]
es_post <- es_coefs[rel_year > 0]

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Targeted Fish Density Around MPA Designation}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Years Relative to MPA & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Pre-Trend Coefficients}} \\\\"
)

for (i in seq_len(nrow(es_pre))) {
  tab3_lines <- c(tab3_lines, sprintf("$t = %d$ & %.3f%s & (%.3f) \\\\",
                                       es_pre$rel_year[i], es_pre$coef[i],
                                       es_pre$stars[i], es_pre$se[i]))
}

tab3_lines <- c(tab3_lines,
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Post-Treatment Coefficients (selected)}} \\\\"
)

# Show selected post-treatment coefficients
post_show <- es_post[rel_year %in% c(1, 2, 3, 5, 8, 10, 15, 17)]
for (i in seq_len(nrow(post_show))) {
  tab3_lines <- c(tab3_lines, sprintf("$t = +%d$ & %.3f%s & (%.3f) \\\\",
                                       post_show$rel_year[i], post_show$coef[i],
                                       post_show$stars[i], post_show$se[i]))
}

# Pre-trend F-test
pre_coef_names <- grep("rel_year_binned::-[0-9]", names(coef(es)), value = TRUE)
if (length(pre_coef_names) > 0) {
  pre_ftest <- wald(es, pre_coef_names)
  tab3_lines <- c(tab3_lines,
    "\\midrule",
    sprintf("Pre-trend $F$-test & \\multicolumn{2}{c}{$F = %.2f$, $p = %.3f$} \\\\",
            pre_ftest$stat, pre_ftest$p))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Event study coefficients from a regression of log targeted fish density on interactions between MPA site indicator and year-relative-to-treatment dummies, with site and year fixed effects. Reference period: $t = 0$ (2007). Standard errors clustered at the site level. The pre-trend $F$-test is a joint test that all pre-treatment coefficients equal zero.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_eventstudy.tex")

# ========================================================================
# TABLE 4: Robustness (Leave-One-Out + Channel Islands)
# ========================================================================
m_full <- readRDS("data/model_full_islands.rds")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out and Channel Islands Dose-Response}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-Out (Targeted Fish Density)}} \\\\",
  "\\midrule",
  "Dropped Site & Coefficient & SE \\\\"
)

for (i in seq_len(nrow(loo))) {
  tab4_lines <- c(tab4_lines, sprintf("%s & %.3f & (%.3f) \\\\",
                                       loo$dropped_site[i], loo$coef[i], loo$se[i]))
}

# Channel Islands results
ci_mainland <- coef(m_full)["treated_mainland"]
ci_mainland_se <- se(m_full)["treated_mainland"]
ci_island <- coef(m_full)["treated_island"]
ci_island_se <- se(m_full)["treated_island"]

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Channel Islands Dose-Response}} \\\\",
  "\\midrule",
  sprintf("Mainland MPA $\\times$ Post-2007 & %.3f & (%.3f) \\\\", ci_mainland, ci_mainland_se),
  sprintf("Channel Islands $\\times$ Post-2003 & %.3f & (%.3f) \\\\", ci_island, ci_island_se),
  sprintf("Sites & \\multicolumn{2}{c}{%d} \\\\", 11),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Panel A shows the main DiD coefficient for log targeted fish density when each site is dropped from the sample. Panel B includes Channel Islands sites (Santa Cruz Island), which received federal marine reserve designation in 2003 and state MPA designation in 2007. Standard errors clustered at the site level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robust.tex")

# ========================================================================
# TABLE 5: Species-Level DDD
# ========================================================================
m_ddd <- readRDS("data/model_ddd.rds")

# Get the DDD interaction coefficient
ddd_coef <- coef(m_ddd)["treated_spp:targeted"]
ddd_se <- se(m_ddd)["treated_spp:targeted"]
ddd_p <- pvalue(m_ddd)["treated_spp:targeted"]
ddd_stars <- ifelse(ddd_p < 0.01, "***", ifelse(ddd_p < 0.05, "**",
             ifelse(ddd_p < 0.1, "*", "")))

# Also get the main treated coefficient
ddd_main_coef <- coef(m_ddd)["treated_spp"]
ddd_main_se <- se(m_ddd)["treated_spp"]

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Species-Level Mechanism Test: Targeted vs.\\ Non-Targeted Fish}",
  "\\label{tab:ddd}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  " & Log Fish Density \\\\",
  "\\midrule",
  sprintf("MPA $\\times$ Post & %.3f \\\\", ddd_main_coef),
  sprintf(" & (%.3f) \\\\", ddd_main_se),
  "\\addlinespace",
  sprintf("MPA $\\times$ Post $\\times$ Targeted & %.3f%s \\\\", ddd_coef, ddd_stars),
  sprintf(" & (%.3f) \\\\", ddd_se),
  "\\addlinespace",
  "Site $\\times$ Species FE & Yes \\\\",
  "Year $\\times$ Species FE & Yes \\\\",
  "Site $\\times$ Year FE & Yes \\\\",
  sprintf("Observations & %s \\\\", format(nrow(readRDS("data/panel_spp_main.rds")), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Triple-difference specification at the site $\\times$ year $\\times$ species level. The dependent variable is log fish density (count per 60m$^2$ + 1). ``Targeted'' indicates species commonly taken by recreational or commercial fishing in California kelp forests (genera \\textit{Semicossyphus}, \\textit{Paralabrax}, \\textit{Sebastes}, \\textit{Scorpaena}, \\textit{Caulolatilus}, \\textit{Rhacochilus}, plus surfperch, cabezon, and lingcod). The triple interaction captures whether targeted species differentially recover in MPA sites after designation, controlling for site-specific species baselines, common species trends, and site-level shocks. Standard errors clustered at the site level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "tables/tab5_ddd.tex")

# ========================================================================
# SDE APPENDIX TABLE (tabF1_sde.tex)
# ========================================================================
# Compute SDEs for main outcomes
pre_panel <- panel[YEAR < 2008]
sd_y_density <- sd(pre_panel$log_density)
sd_y_targeted <- sd(pre_panel$log_targeted)
sd_y_nontargeted <- sd(pre_panel$log_nontargeted)
sd_y_richness <- sd(pre_panel$species_richness)

# Main coefficients
b1 <- coef(m1)["treated"]; se1 <- se(m1)["treated"]
b2 <- coef(m2)["treated"]; se2 <- se(m2)["treated"]
b3 <- coef(m3)["treated"]; se3 <- se(m3)["treated"]
b4 <- coef(m4)["treated"]; se4 <- se(m4)["treated"]

sde1 <- b1 / sd_y_density; se_sde1 <- se1 / sd_y_density
sde2 <- b2 / sd_y_targeted; se_sde2 <- se2 / sd_y_targeted
sde3 <- b3 / sd_y_nontargeted; se_sde3 <- se3 / sd_y_nontargeted
sde4 <- b4 / sd_y_richness; se_sde4 <- se4 / sd_y_richness

classify <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneity: split MPA sites by protection type
# NAPL is Naples SMCA (limited-take), IVEE is Campus Point SMCA (no-take)
panel_notake <- panel[SITE %in% c("IVEE", unique(panel[mpa == 0]$SITE))]
panel_notake[, treated := as.integer(SITE == "IVEE") * as.integer(YEAR >= 2008)]
m_notake <- feols(log_targeted ~ treated | SITE + YEAR, data = panel_notake)
b_notake <- coef(m_notake)["treated"]; se_notake <- se(m_notake)["treated"]
sd_notake <- sd(panel_notake[YEAR < 2008]$log_targeted)
sde_notake <- b_notake / sd_notake; se_sde_notake <- se_notake / sd_notake

panel_limited <- panel[SITE %in% c("NAPL", unique(panel[mpa == 0]$SITE))]
panel_limited[, treated := as.integer(SITE == "NAPL") * as.integer(YEAR >= 2008)]
m_limited <- feols(log_targeted ~ treated | SITE + YEAR, data = panel_limited)
b_limited <- coef(m_limited)["treated"]; se_limited <- se(m_limited)["treated"]
sd_limited <- sd(panel_limited[YEAR < 2008]$log_targeted)
sde_limited <- b_limited / sd_limited; se_sde_limited <- se_limited / sd_limited

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States (California). ",
  "\\textbf{Research question:} Does marine protected area designation increase kelp forest fish abundance, ",
  "and do strict no-take reserves produce larger recovery than limited-take areas? ",
  "\\textbf{Policy mechanism:} The Central Coast Marine Life Protection Act (MLPA, September 2007) designated ",
  "marine protected areas that restrict or prohibit fishing, reducing fishing mortality on resident reef fish and ",
  "allowing recovery of depleted populations through reduced harvest pressure. ",
  "\\textbf{Outcome definition:} Log fish density (count per 60m$^2$ transect area + 1) from standardized annual SCUBA surveys. ",
  "\\textbf{Treatment:} Binary---site inside vs.\\ outside MPA boundary after September 2007 designation. ",
  "\\textbf{Data:} SBC LTER KFCD annual kelp forest surveys (knb-lter-sbc.17), 2001--2025, 9 mainland reef sites. ",
  "\\textbf{Method:} Two-way fixed effects DiD with site and year FE, standard errors clustered at site level; ",
  "wild cluster bootstrap and randomization inference for few-cluster robustness. ",
  "\\textbf{Sample:} 9 mainland Santa Barbara Channel kelp forest reefs; Channel Islands excluded (always treated). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("All fish density & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b1, se1, sd_y_density, sde1, se_sde1, classify(sde1)),
  sprintf("Targeted fish density & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b2, se2, sd_y_targeted, sde2, se_sde2, classify(sde2)),
  sprintf("Non-targeted density & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b3, se3, sd_y_nontargeted, sde3, se_sde3, classify(sde3)),
  sprintf("Species richness & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b4, se4, sd_y_richness, sde4, se_sde4, classify(sde4)),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by protection type)}} \\\\",
  sprintf("No-take reserve (IVEE) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_notake, se_notake, sd_notake, sde_notake, se_sde_notake, classify(sde_notake)),
  sprintf("Limited-take area (NAPL) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          b_limited, se_limited, sd_limited, sde_limited, se_sde_limited, classify(sde_limited)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")

cat("All tables generated.\n")
