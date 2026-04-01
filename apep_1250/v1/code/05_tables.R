source("code/00_packages.R")

ensure_dir("tables")

panel <- read_csv("data/derived/analysis_panel.csv", show_col_types = FALSE)
summary_stats <- read_csv("data/derived/summary_stats.csv", show_col_types = FALSE)
main_results <- read_csv("data/results/main_results.csv", show_col_types = FALSE)
event_study <- read_csv("data/results/event_study.csv", show_col_types = FALSE)
main_models <- readRDS("data/results/main_models.rds")
robustness <- readRDS("data/results/robustness_results.rds")

exposure_stats <- distinct(panel, region, loans_per_1000) |>
  arrange(desc(loans_per_1000))

n_las <- n_distinct(panel$la_code)
n_regions <- n_distinct(panel$region)
n_obs <- nrow(panel)

main_gap <- max(exposure_stats$loans_per_1000) - min(exposure_stats$loans_per_1000)
main_beta <- coef(main_models$main_ddd)[1]
main_gap_effect <- exp(main_beta * main_gap) - 1

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Panel Overview and Exposure Variation}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrr}",
  "\\toprule",
  "Statistic & Value \\\\",
  "\\midrule",
  glue("Local authorities & {fmt_int(summary_stats$value[summary_stats$metric == 'Local authorities'])} \\\\"),
  glue("Regions & {fmt_int(summary_stats$value[summary_stats$metric == 'Regions'])} \\\\"),
  glue("Quarter observations & {fmt_int(summary_stats$value[summary_stats$metric == 'Quarters'])} \\\\"),
  glue("Pre-treatment quarters & {fmt_int(summary_stats$value[summary_stats$metric == 'Pre-treatment quarters'])} \\\\"),
  glue("Mean private landlord claims (pre) & {fmt_num(summary_stats$value[summary_stats$metric == 'Mean private claims (pre)'], 2)} \\\\"),
  glue("Mean mortgage claims (pre) & {fmt_num(summary_stats$value[summary_stats$metric == 'Mean mortgage claims (pre)'], 2)} \\\\"),
  glue("Mean HCSTC loans per 1,000 adults & {fmt_num(summary_stats$value[summary_stats$metric == 'Mean exposure (loans per 1,000 adults)'], 2)} \\\\"),
  glue("SD HCSTC loans per 1,000 adults & {fmt_num(summary_stats$value[summary_stats$metric == 'SD exposure (loans per 1,000 adults)'], 2)} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}",
  glue("\\small Notes: The estimation sample covers {fmt_int(n_las)} local authorities in England and Wales from 2003Q1 to 2019Q4. Treatment intensity is the FCA's published number of high-cost short-term credit loans per 1,000 adults in each region, measured over July 2017 to June 2018. The highest-exposure region in the England-and-Wales sample is the North West ({fmt_num(max(exposure_stats$loans_per_1000), 1)} loans per 1,000 adults) and the lowest is the South West ({fmt_num(min(exposure_stats$loans_per_1000), 1)})."),
  "\\end{flushleft}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)
write_text("tables/tab1_summary.tex", tab1)

main_tab <- tibble(
  row = c("HCSTC exposure $\\times$ post-cap", "", "Local-authority FE", "Quarter FE", "Observations", "$R^2$"),
  diff = c(
    paste0(fmt_num(coef(main_models$main_ddd)[1], 4), add_stars(pvalue(main_models$main_ddd)[1])),
    paste0("(", fmt_num(se(main_models$main_ddd)[1], 4), ")"),
    "Yes",
    "Yes",
    fmt_int(nobs(main_models$main_ddd)),
    fmt_num(unname(r2(main_models$main_ddd)[1]), 4)
  ),
  private = c(
    paste0(fmt_num(coef(main_models$private_did)[1], 4), add_stars(pvalue(main_models$private_did)[1])),
    paste0("(", fmt_num(se(main_models$private_did)[1], 4), ")"),
    "Yes",
    "Yes",
    fmt_int(nobs(main_models$private_did)),
    fmt_num(unname(r2(main_models$private_did)[1]), 4)
  ),
  mortgage = c(
    paste0(fmt_num(coef(main_models$mortgage_did)[1], 4), add_stars(pvalue(main_models$mortgage_did)[1])),
    paste0("(", fmt_num(se(main_models$mortgage_did)[1], 4), ")"),
    "Yes",
    "Yes",
    fmt_int(nobs(main_models$mortgage_did)),
    fmt_num(unname(r2(main_models$mortgage_did)[1]), 4)
  )
)

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Difference-in-Differences Estimates}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Private $-$ Mortgage & Private & Mortgage \\\\",
  "\\midrule",
  unlist(map(seq_len(nrow(main_tab)), function(i) {
    glue("{main_tab$row[i]} & {main_tab$diff[i]} & {main_tab$private[i]} & {main_tab$mortgage[i]} \\\\")
  })),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}",
  "\\small Notes: Column 1 reports the preferred private-minus-mortgage specification. Columns 2 and 3 report separate continuous-treatment difference-in-differences estimates for private landlord claims and mortgage claims. All models include local-authority and quarter fixed effects and cluster standard errors by region.",
  "\\end{flushleft}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)
write_text("tables/tab2_main.tex", tab2)

event_rows <- event_study |>
  filter(rel_year %in% c(-4, -3, -2, 0, 1, 2, 3, 4, 5)) |>
  arrange(rel_year) |>
  mutate(
    label = case_when(
      rel_year < 0 ~ glue("$t{rel_year}$"),
      rel_year == 0 ~ "$t$",
      TRUE ~ glue("$t+{rel_year}$")
    ),
    est = paste0(fmt_num(estimate, 4), add_stars(p_value)),
    se = paste0("(", fmt_num(std.error, 4), ")")
  )

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event-Study Coefficients for the Private-Minus-Mortgage Differential}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Relative year & Coefficient & Standard error \\\\",
  "\\midrule",
  unlist(map2(event_rows$label, seq_len(nrow(event_rows)), function(lbl, i) {
    c(
      glue("{lbl} & {event_rows$est[i]} & {event_rows$se[i]} \\\\")
    )
  })),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}",
  "\\small Notes: Coefficients come from a local-authority and quarter fixed-effects event study of the log difference between private landlord claims and mortgage claims. Exposure is interacted with annual relative time, with 2013 ($t-1$) omitted as the reference year. Standard errors are clustered by region.",
  "\\end{flushleft}",
  "\\end{threeparttable}",
  "\\label{tab:eventstudy}",
  "\\end{table}"
)
write_text("tables/tab3_eventstudy.tex", tab3)

robust_tab <- tibble(
  spec = c(
    "Baseline DDD",
    "Region-specific trends",
    "Short window: 2010--2019"
  ),
  beta = c(
    coef(main_models$main_ddd)[1],
    coef(robustness$region_trends)[1],
    coef(robustness$short_window)[1]
  ),
  se = c(
    se(main_models$main_ddd)[1],
    se(robustness$region_trends)[1],
    se(robustness$short_window)[1]
  ),
  p = c(
    pvalue(main_models$main_ddd)[1],
    pvalue(robustness$region_trends)[1],
    pvalue(robustness$short_window)[1]
  )
) |>
  mutate(est = paste0(fmt_num(beta, 4), add_stars(p)), se_txt = paste0("(", fmt_num(se, 4), ")"))

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness and Few-Cluster Inference}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & Standard error & p-value \\\\",
  "\\midrule",
  unlist(map2(robust_tab$spec, seq_len(nrow(robust_tab)), function(lbl, i) {
    c(glue("{lbl} & {robust_tab$est[i]} & {robust_tab$se_txt[i]} & {fmt_p(robust_tab$p[i])} \\\\"))
  })),
  "\\midrule",
  glue("Permutation p-value & \\multicolumn{{3}}{{c}}{{{fmt_p(robustness$perm_results$p_perm[1])}}} \\\\"),
  glue("Leave-one-region-out range & \\multicolumn{{3}}{{c}}{{[{fmt_num(min(robustness$leave_one_out$estimate), 4)}, {fmt_num(max(robustness$leave_one_out$estimate), 4)}]}} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{flushleft}",
  glue("\\small Notes: Every row reports the coefficient on HCSTC exposure interacted with the post-2015 period in the private-minus-mortgage specification. The permutation p-value is based on 1,000 random reassignment draws of the {fmt_int(n_regions)} regional exposure values. The leave-one-region-out range reports the minimum and maximum coefficient obtained when dropping one region at a time."),
  "\\end{flushleft}",
  "\\end{threeparttable}",
  "\\label{tab:robustness}",
  "\\end{table}"
)
write_text("tables/tab4_robustness.tex", tab4)

estimate_sde <- function(model, outcome_sd, exposure_sd) {
  beta <- coef(model)[1]
  se_beta <- se(model)[1]
  sde <- beta * exposure_sd / outcome_sd
  se_sde <- se_beta * exposure_sd / outcome_sd
  classification <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  tibble(beta = beta, se = se_beta, sdy = outcome_sd, sde = sde, se_sde = se_sde, classification = classification)
}

exposure_sd <- sd(distinct(panel, la_code, loans_per_1000)$loans_per_1000)

high_panel <- filter(panel, high_baseline == 1)
low_panel <- filter(panel, high_baseline == 0)

high_model <- feols(diff_y ~ loans_per_1000:post | la_code + quarter_id, data = high_panel, cluster = ~region)
low_model <- feols(diff_y ~ loans_per_1000:post | la_code + quarter_id, data = low_panel, cluster = ~region)

sde_rows <- bind_rows(
  estimate_sde(main_models$main_ddd, sd(panel$diff_y[panel$post == 0]), exposure_sd) |>
    mutate(panel = "Panel A", outcome = "Private minus mortgage claims"),
  estimate_sde(main_models$private_did, sd(panel$log_private[panel$post == 0]), exposure_sd) |>
    mutate(panel = "Panel A", outcome = "Private landlord claims"),
  estimate_sde(main_models$mortgage_did, sd(panel$log_mortgage[panel$post == 0]), exposure_sd) |>
    mutate(panel = "Panel A", outcome = "Mortgage claims"),
  estimate_sde(high_model, sd(high_panel$diff_y[high_panel$post == 0]), exposure_sd) |>
    mutate(panel = "Panel B", outcome = "High-baseline private-claim LAs"),
  estimate_sde(low_model, sd(low_panel$diff_y[low_panel$post == 0]), exposure_sd) |>
    mutate(panel = "Panel B", outcome = "Low-baseline private-claim LAs")
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lrrrrrl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (panel_name in c("Panel A", "Panel B")) {
  sde_lines <- c(sde_lines, glue("\\multicolumn{{7}}{{l}}{{\\textit{{{panel_name}}}}} \\\\"))
  rows <- filter(sde_rows, panel == panel_name)
  for (i in seq_len(nrow(rows))) {
    sde_lines <- c(
      sde_lines,
      glue(
        "{rows$outcome[i]} & {fmt_num(rows$beta[i], 4)} & {fmt_num(rows$se[i], 4)} & {fmt_num(rows$sdy[i], 4)} & {fmt_num(rows$sde[i], 4)} & {fmt_num(rows$se_sde[i], 4)} & {rows$classification[i]} \\\\"
      )
    )
  }
}

sde_lines <- c(
  sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{flushleft}",
  "\\small",
  glue("Notes: \\textbf{{Country:}} United Kingdom. \\textbf{{Research question:}} Did the January 2015 UK high-cost short-term credit price cap increase housing distress, measured by possession claims, in higher-payday-exposure areas of England and Wales? \\textbf{{Policy mechanism:}} The cap limited HCSTC interest and fees to 0.8\\% per day, imposed a \\pounds 15 default-fee cap, and capped total repayment at 100\\% of principal, sharply compressing access to payday credit. If those loans had mainly smoothed short-run rent shocks, removing them should have raised landlord possession claims more than mortgage claims in high-exposure areas. \\textbf{{Outcome definition:}} Quarterly local-authority possession claims from HM Courts and Tribunals Service, aggregated into private landlord claims (including accelerated claims), mortgage claims, and their log difference. \\textbf{{Treatment:}} Continuous; FCA-reported HCSTC loans per 1,000 adults at the regional level, proxying persistent payday-market exposure. \\textbf{{Data:}} Ministry of Justice local-authority possession claims, 2003Q1--2019Q4, merged to FCA regional HCSTC exposure from the July 2017--June 2018 Product Sales Data release; estimation sample contains {fmt_int(n_obs)} local-authority-quarter observations across {fmt_int(n_las)} local authorities and {fmt_int(n_regions)} effective regions. \\textbf{{Method:}} Continuous-treatment DiD with local-authority and quarter fixed effects; standard errors clustered by region; robustness adds region-specific trends and permutation inference. \\textbf{{Sample:}} England and Wales only; observations with unidentified local authorities or unmatched region exposure are excluded. SDE $= \\hat{{\\beta}} \\times \\text{{SD}}(X) / \\text{{SD}}(Y)$ where SD($X$) is the cross-local-authority standard deviation of regional HCSTC exposure and SD($Y$) is the pre-treatment standard deviation of the outcome. Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."),
  "\\end{flushleft}",
  "\\end{threeparttable}",
  "\\label{tab:sde}",
  "\\end{table}"
)
write_text("tables/tabF1_sde.tex", sde_lines)

macros <- c(
  glue("\\newcommand{{\\mainbeta}}{{{fmt_num(main_beta, 4)}}}"),
  glue("\\newcommand{{\\mainse}}{{{fmt_num(se(main_models$main_ddd)[1], 4)}}}"),
  glue("\\newcommand{{\\trendbeta}}{{{fmt_num(coef(robustness$region_trends)[1], 4)}}}"),
  glue("\\newcommand{{\\trendse}}{{{fmt_num(se(robustness$region_trends)[1], 4)}}}"),
  glue("\\newcommand{{\\permp}}{{{fmt_p(robustness$perm_results$p_perm[1])}}}"),
  glue("\\newcommand{{\\nlas}}{{{fmt_int(n_las)}}}"),
  glue("\\newcommand{{\\nregions}}{{{fmt_int(n_regions)}}}"),
  glue("\\newcommand{{\\mainrange}}{{{fmt_num(main_gap, 1)}}}"),
  glue("\\newcommand{{\\maineffect}}{{{fmt_pct(main_gap_effect, 1)}}}")
)
write_text("tables/result_macros.tex", macros)

cat("Tables written to tables/.\n")
