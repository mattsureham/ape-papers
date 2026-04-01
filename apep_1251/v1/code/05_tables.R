source("code/00_packages.R")

dir.create("tables", showWarnings = FALSE)

panel <- fread("data/clean/airport_year_panel.csv.gz")
sample_airports <- fread("data/clean/sample_airports.csv")
summary_cells <- fread("data/clean/summary_cells.csv")
main_models <- readRDS("data/clean/main_models.rds")
robust_models <- readRDS("data/clean/robust_models.rds")
panel <- panel[transition == FALSE]
panel[, airport_fe := factor(Airport_ID)]
panel[, year_fe := factor(year)]

summary_table <- data.table(
  Group = c("Treated airports", "Control airports"),
  Airports = c(
    sample_airports[treated == TRUE, uniqueN(Airport_ID)],
    sample_airports[treated == FALSE, uniqueN(Airport_ID)]
  ),
  `Mean annual strikes, pre` = c(
    panel[treated == TRUE & year <= 2003, mean(total_strikes)],
    panel[treated == FALSE & year <= 2003, mean(total_strikes)]
  ),
  `Mean annual damaging strikes, pre` = c(
    panel[treated == TRUE & year <= 2003, mean(damaging_strikes)],
    panel[treated == FALSE & year <= 2003, mean(damaging_strikes)]
  ),
  `Mean damage share, pre` = c(
    panel[treated == TRUE & year <= 2003, mean(damage_share)],
    panel[treated == FALSE & year <= 2003, mean(damage_share)]
  )
)
fwrite(summary_table, "tables/tab1_summary.csv")

tab1_tex <- c(
  "\\begin{table}[!htbp]\\centering",
  "\\caption{Sample composition and pre-period strike rates}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Group & Airports & Pre total strikes & Pre damaging strikes & Pre damage share \\\\",
  "\\midrule",
  sprintf(
    "Treated airports & %d & %.3f & %.3f & %.3f \\\\",
    summary_table$Airports[1], summary_table$`Mean annual strikes, pre`[1],
    summary_table$`Mean annual damaging strikes, pre`[1], summary_table$`Mean damage share, pre`[1]
  ),
  sprintf(
    "Control airports & %d & %.3f & %.3f & %.3f \\\\",
    summary_table$Airports[2], summary_table$`Mean annual strikes, pre`[2],
    summary_table$`Mean annual damaging strikes, pre`[2], summary_table$`Mean damage share, pre`[2]
  ),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab1_tex, "tables/tab1_summary.tex")

etable(
  main_models$ppml_total,
  main_models$ppml_damage,
  main_models$ppml_severe,
  main_models$ols_share,
  tex = TRUE,
  file = "tables/tab2_main.tex",
  digits = 3,
  fitstat = ~ n + r2,
  keep = "treated_postTRUE",
  headers = c(
    "Total strikes",
    "Damaging strikes",
    "Severe strikes",
    "Damage share"
  ),
  replace = TRUE
)

decomp_table <- dcast(
  summary_cells,
  treated + post ~ .,
  value.var = c("mean_total", "mean_damage", "mean_damage_share")
)
decomp_tex <- c(
  "\\begin{table}[!htbp]\\centering",
  "\\caption{Outcome decomposition by group and period}",
  "\\label{tab:decomp}",
  "\\begin{tabular}{lrrr}",
  "\\toprule",
  "Group-period & Mean total strikes & Mean damaging strikes & Mean damage share \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(summary_cells))) {
  label <- if (summary_cells$treated[i]) "Treated" else "Control"
  label <- sprintf("%s, %s", label, if (summary_cells$post[i]) "post-2007" else "pre-2004")
  decomp_tex <- c(
    decomp_tex,
    sprintf(
      "%s & %.3f & %.3f & %.3f \\\\",
      label,
      summary_cells$mean_total[i],
      summary_cells$mean_damage[i],
      summary_cells$mean_damage_share[i]
    )
  )
}
decomp_tex <- c(decomp_tex, "\\bottomrule", "\\end{tabular}", "\\end{table}")
writeLines(decomp_tex, "tables/tab3_decomposition.tex")

etable(
  robust_models$ppml_severe_restricted,
  robust_models$ppml_damage_restricted,
  robust_models$ols_severe_trends,
  robust_models$ols_share_trends,
  tex = TRUE,
  file = "tables/tab4_robustness.tex",
  digits = 3,
  fitstat = ~ n + r2,
  keep = "treated_postTRUE",
  headers = c(
    "Severe, restricted",
    "Damaging, restricted",
    "Severe + trend",
    "Share + trend"
  ),
  replace = TRUE
)

sde_total_ols <- feols(total_strikes ~ treated_post | airport_fe + year_fe, cluster = ~ airport_fe, data = panel)
sde_damage_ols <- feols(damaging_strikes ~ treated_post | airport_fe + year_fe, cluster = ~ airport_fe, data = panel)
sde_severe_ols <- feols(severe_strikes ~ treated_post | airport_fe + year_fe, cluster = ~ airport_fe, data = panel)
sde_share_ols <- feols(damage_share ~ treated_post | airport_fe + year_fe, cluster = ~ airport_fe, weights = ~ pmax(total_strikes, 1), data = panel)

restricted_panel <- copy(panel)
pre_cut <- restricted_panel[treated == TRUE & year <= 2003, quantile(total_strikes, 0.95)]
restricted_panel <- restricted_panel[
  treated == TRUE |
    Airport_ID %in% restricted_panel[treated == FALSE & year <= 2003 & total_strikes <= pre_cut, unique(Airport_ID)]
]
restricted_panel[, airport_fe := factor(Airport_ID)]
restricted_panel[, year_fe := factor(year)]
sde_damage_restricted_ols <- feols(
  damaging_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = restricted_panel
)

sde_rows <- data.table(
  Outcome = c(
    "Total strikes",
    "Damaging strikes",
    "Severe strikes",
    "Damage share",
    "Damaging strikes (restricted)",
    "Damage share with trend"
  ),
  beta = c(
    coef(sde_total_ols)[["treated_postTRUE"]],
    coef(sde_damage_ols)[["treated_postTRUE"]],
    coef(sde_severe_ols)[["treated_postTRUE"]],
    coef(sde_share_ols)[["treated_postTRUE"]],
    coef(sde_damage_restricted_ols)[["treated_postTRUE"]],
    coef(robust_models$ols_share_trends)[["treated_postTRUE"]]
  ),
  se = c(
    se(sde_total_ols)[["treated_postTRUE"]],
    se(sde_damage_ols)[["treated_postTRUE"]],
    se(sde_severe_ols)[["treated_postTRUE"]],
    se(sde_share_ols)[["treated_postTRUE"]],
    se(sde_damage_restricted_ols)[["treated_postTRUE"]],
    se(robust_models$ols_share_trends)[["treated_postTRUE"]]
  ),
  sd_y = c(
    sd(panel$total_strikes[panel$year <= 2003]),
    sd(panel$damaging_strikes[panel$year <= 2003]),
    sd(panel$severe_strikes[panel$year <= 2003]),
    sd(panel$damage_share[panel$year <= 2003]),
    sd(panel$damaging_strikes[panel$year <= 2003]),
    sd(panel$damage_share[panel$year <= 2003])
  )
)
sde_rows[, sde := beta / sd_y]
sde_rows[, se_sde := se / sd_y]
sde_rows[, classification := fifelse(
  sde < -0.15, "Large negative",
  fifelse(
    sde < -0.05, "Moderate negative",
    fifelse(
      sde < -0.005, "Small negative",
      fifelse(
        sde <= 0.005, "Null",
        fifelse(
          sde <= 0.05, "Small positive",
          fifelse(sde <= 0.15, "Moderate positive", "Large positive")
        )
      )
    )
  )
)]

sde_panel_a <- paste(
  apply(
    sde_rows[1:4],
    1,
    function(x) sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
      x[["Outcome"]], as.numeric(x[["beta"]]), as.numeric(x[["se"]]),
      as.numeric(x[["sd_y"]]), as.numeric(x[["sde"]]),
      as.numeric(x[["se_sde"]]), x[["classification"]]
    )
  ),
  collapse = "\n"
)
sde_panel_b <- paste(
  apply(
    sde_rows[5:6],
    1,
    function(x) sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
      x[["Outcome"]], as.numeric(x[["beta"]]), as.numeric(x[["se"]]),
      as.numeric(x[["sd_y"]]), as.numeric(x[["sde"]]),
      as.numeric(x[["se_sde"]]), x[["classification"]]
    )
  ),
  collapse = "\n"
)

sde_notes <- paste0(
  "\\begin{table}[!htbp]\\centering\n",
  "\\caption{Standardized effect sizes}\\label{tab:F1}\n",
  "\\begin{tabular}{lrrrrrl}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sde_panel_a, "\n\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sde_panel_b, "\n\\bottomrule\n\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\\footnotesize\n",
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 2004-2007 expansion of FAA Part 139 certification to newly regulated Class III commuter airports change wildlife-strike incidence and severity at treated airports relative to never-certificated airports. ",
  "\\textbf{Policy mechanism:} The rule required newly certificated airports serving 10--30 seat scheduled service to adopt Part 139 compliance systems, including wildlife hazard management, self-inspections, training, and related safety procedures. The key empirical question is whether those new compliance obligations reduced damaging strikes or instead mostly changed reporting intensity. ",
  "\\textbf{Outcome definition:} Airport-year counts of total reported strikes, damaging strikes, severe strikes, and damage shares from the FAA Wildlife Strike Database public search extract. ",
  "\\textbf{Treatment:} Binary indicator equal to one for airports listed in the FAA's historical Class III appendix and years 2007 onward after the compliance transition. ",
  "\\textbf{Data:} FAA Wildlife Strike Database public API, 1990--2024, merged to FAA airport metadata; airport-year panel with treated and never-certificated control airports. ",
  "\\textbf{Method:} Airport and year fixed-effects models estimated with Poisson or linear estimators; standard errors clustered by airport. ",
  "\\textbf{Sample:} U.S. airports observed in the FAA strike database, using the historical Class III roster as treated units and never-certificated airports with pre-period strike history as controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).",
  "\\end{minipage}\n\\end{table}\n"
)
writeLines(sde_notes, "tables/tabF1_sde.tex")

headline <- fread("data/clean/headline_estimates.csv")
damage_coef <- headline[model == "ppml_damage", estimate]
share_coef <- headline[model == "ols_share", estimate]
macros <- c(
  sprintf("\\newcommand{\\MainDamageCoef}{%.3f}", damage_coef),
  sprintf("\\newcommand{\\MainShareCoef}{%.3f}", share_coef),
  sprintf("\\newcommand{\\TreatedAirports}{%d}", sample_airports[treated == TRUE, uniqueN(Airport_ID)])
)
writeLines(macros, "tables/result_macros.tex")
