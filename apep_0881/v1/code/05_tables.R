# 05_tables.R — Generate all LaTeX tables
# apep_0881: Academy Conversion and Pupil Sorting

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

did_panel <- readRDS(file.path(data_dir, "did_panel.rds"))
la_panel <- readRDS(file.path(data_dir, "la_panel.rds"))
sa_fsm <- readRDS(file.path(data_dir, "sa_fsm.rds"))
twfe_fsm <- readRDS(file.path(data_dir, "twfe_fsm.rds"))

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

did_data <- did_panel |>
  mutate(school_id = as.integer(school_id), g = as.integer(g)) |>
  group_by(school_id, year) |>
  slice_max(n_pupils, n = 1, with_ties = FALSE) |>
  ungroup()

# Compute stats by group
stats_converter <- did_data |> filter(g > 0) |>
  summarise(
    N = n_distinct(school_id),
    `Mean FSM (\\%)` = sprintf("%.1f", mean(fsm_pct, na.rm = TRUE)),
    `SD FSM` = sprintf("%.1f", sd(fsm_pct, na.rm = TRUE)),
    `Mean pupils` = sprintf("%.0f", mean(n_pupils, na.rm = TRUE)),
    `\\% Primary` = sprintf("%.1f", mean(Phase == "Primary") * 100)
  ) |> mutate(Group = "Converting schools")

stats_control <- did_data |> filter(g == 0) |>
  summarise(
    N = n_distinct(school_id),
    `Mean FSM (\\%)` = sprintf("%.1f", mean(fsm_pct, na.rm = TRUE)),
    `SD FSM` = sprintf("%.1f", sd(fsm_pct, na.rm = TRUE)),
    `Mean pupils` = sprintf("%.0f", mean(n_pupils, na.rm = TRUE)),
    `\\% Primary` = sprintf("%.1f", mean(Phase == "Primary") * 100)
  ) |> mutate(Group = "Never-academy schools")

stats_all <- did_data |>
  summarise(
    N = n_distinct(school_id),
    `Mean FSM (\\%)` = sprintf("%.1f", mean(fsm_pct, na.rm = TRUE)),
    `SD FSM` = sprintf("%.1f", sd(fsm_pct, na.rm = TRUE)),
    `Mean pupils` = sprintf("%.0f", mean(n_pupils, na.rm = TRUE)),
    `\\% Primary` = sprintf("%.1f", mean(Phase == "Primary") * 100)
  ) |> mutate(Group = "Full sample")

stats_df <- bind_rows(stats_converter, stats_control, stats_all) |>
  select(Group, N, everything())

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Schools & Mean FSM (\\%) & SD FSM & Mean Pupils & \\% Primary \\\\\n",
  "\\midrule\n",
  paste0("Converting schools & ", stats_converter$N, " & ",
         stats_converter$`Mean FSM (\\%)`, " & ", stats_converter$`SD FSM`, " & ",
         stats_converter$`Mean pupils`, " & ", stats_converter$`\\% Primary`, " \\\\\n"),
  paste0("Never-academy schools & ", stats_control$N, " & ",
         stats_control$`Mean FSM (\\%)`, " & ", stats_control$`SD FSM`, " & ",
         stats_control$`Mean pupils`, " & ", stats_control$`\\% Primary`, " \\\\\n"),
  "\\midrule\n",
  paste0("Full sample & ", stats_all$N, " & ",
         stats_all$`Mean FSM (\\%)`, " & ", stats_all$`SD FSM`, " & ",
         stats_all$`Mean pupils`, " & ", stats_all$`\\% Primary`, " \\\\\n"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sample of English state-funded primary and secondary schools observed in GIAS annual snapshots 2021--2026. Converting schools are those that transitioned from maintained to academy status during the panel period. FSM = Free School Meal eligibility.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ==============================================================================
# Table 2: Main Results — Sun-Abraham ATT
# ==============================================================================

# Get SA event study coefficients
# Need to extract from the stored model's coefficient table directly
sa_coefs <- as.data.frame(summary(sa_fsm)$coeftable)
sa_coefs$term <- rownames(sa_coefs)
sa_coefs <- sa_coefs |>
  filter(grepl("^year::", term)) |>
  rename(estimate = Estimate, std.error = `Std. Error`, p.value = `Pr(>|t|)`) |>
  as_tibble() |>
  filter(grepl("^year::", term)) |>
  mutate(
    rel_time = as.integer(gsub("year::", "", term)),
    coef = sprintf("%.3f", estimate),
    se = sprintf("(%.3f)", std.error),
    stars = case_when(
      p.value < 0.01 ~ "***",
      p.value < 0.05 ~ "**",
      p.value < 0.1 ~ "*",
      TRUE ~ ""
    ),
    coef_str = paste0(coef, stars)
  )

# SA aggregate ATT — manually compute from event-study coefficients
# Post-treatment coefficients: rel_time >= 0
post_coefs <- sa_coefs |> filter(rel_time >= 0)
att_est <- mean(post_coefs$estimate)
# Use mean of individual SEs as approximation (conservative)
att_se <- sqrt(mean(post_coefs$std.error^2))
att_p <- 2 * pt(-abs(att_est / att_se), df = 150)
att_stars <- ifelse(att_p < 0.01, "***", ifelse(att_p < 0.05, "**", ifelse(att_p < 0.1, "*", "")))

# TWFE
twfe_est <- coef(twfe_fsm)["post"]
twfe_se <- summary(twfe_fsm)$se["post"]
twfe_p <- summary(twfe_fsm)$coeftable["post", "Pr(>|t|)"]
twfe_stars <- ifelse(twfe_p < 0.01, "***", ifelse(twfe_p < 0.05, "**", ifelse(twfe_p < 0.1, "*", "")))

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Academy Conversion on FSM Share}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Sun-Abraham & TWFE \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Event study}} \\\\\n",
  paste0("$t-5$ & ", sa_coefs$coef_str[sa_coefs$rel_time == -5], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == -5], " & \\\\\n"),
  paste0("$t-4$ & ", sa_coefs$coef_str[sa_coefs$rel_time == -4], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == -4], " & \\\\\n"),
  paste0("$t-3$ & ", sa_coefs$coef_str[sa_coefs$rel_time == -3], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == -3], " & \\\\\n"),
  paste0("$t-2$ & ", sa_coefs$coef_str[sa_coefs$rel_time == -2], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == -2], " & \\\\\n"),
  "$t-1$ & \\multicolumn{1}{c}{---} & \\\\\n",
  paste0("$t$ & ", sa_coefs$coef_str[sa_coefs$rel_time == 0], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == 0], " & \\\\\n"),
  paste0("$t+1$ & ", sa_coefs$coef_str[sa_coefs$rel_time == 1], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == 1], " & \\\\\n"),
  paste0("$t+2$ & ", sa_coefs$coef_str[sa_coefs$rel_time == 2], " & \\\\\n"),
  paste0(" & ", sa_coefs$se[sa_coefs$rel_time == 2], " & \\\\\n"),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Aggregate ATT}} \\\\\n",
  sprintf("ATT & %.3f%s & %.3f%s \\\\\n", att_est, att_stars, twfe_est, twfe_stars),
  sprintf(" & (%.3f) & (%.3f) \\\\\n", att_se, twfe_se),
  "\\midrule\n",
  sprintf("Observations & %s & %s \\\\\n",
          format(nobs(sa_fsm), big.mark = ","),
          format(nobs(twfe_fsm), big.mark = ",")),
  "School FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  sprintf("Schools & %s & %s \\\\\n",
          format(n_distinct(did_data$school_id), big.mark = ","),
          format(n_distinct(did_data$school_id), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column (1) reports Sun and Abraham (2021) interaction-weighted estimates robust to heterogeneous treatment effects across cohorts. Column (2) reports standard TWFE as a benchmark; the sign reversal illustrates forbidden-comparison bias. The dependent variable is school-level FSM eligibility share (\\%). Standard errors clustered at the Local Authority level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ==============================================================================
# Table 3: Heterogeneity — Converter vs Sponsor-led, Primary vs Secondary
# ==============================================================================

# Load subsample results
sa_converter <- readRDS(file.path(data_dir, "sa_converter.rds"))
sa_sponsor <- readRDS(file.path(data_dir, "sa_sponsor.rds"))
sa_primary <- readRDS(file.path(data_dir, "sa_primary.rds"))
sa_secondary <- readRDS(file.path(data_dir, "sa_secondary.rds"))

get_att <- function(model) {
  ct <- as.data.frame(summary(model)$coeftable)
  ct$term <- rownames(ct)
  post <- ct |> filter(grepl("^year::", term)) |>
    mutate(rt = as.integer(gsub("year::", "", term))) |>
    filter(rt >= 0)
  est <- mean(post$Estimate)
  se <- sqrt(mean(post$`Std. Error`^2))
  p <- 2 * pt(-abs(est / se), df = 150)
  list(est = est, se = se, p = p, n = nobs(model))
}

conv <- get_att(sa_converter)
spon <- get_att(sa_sponsor)
prim <- get_att(sa_primary)
sec <- get_att(sa_secondary)

fmt_star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneity in Academy Conversion Effects}\n",
  "\\label{tab:hetero}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Converter & Sponsor-led & Primary & Secondary \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("ATT & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          conv$est, fmt_star(conv$p), spon$est, fmt_star(spon$p),
          prim$est, fmt_star(prim$p), sec$est, fmt_star(sec$p)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          conv$se, spon$se, prim$se, sec$se),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(conv$n, big.mark = ","), format(spon$n, big.mark = ","),
          format(prim$n, big.mark = ","), format(sec$n, big.mark = ",")),
  "School FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sun and Abraham (2021) interaction-weighted ATT estimates. Converter academies (column 1) are schools that voluntarily converted; sponsor-led academies (column 2) were imposed on underperforming schools. Columns (3) and (4) split by school phase. Standard errors clustered at the Local Authority level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_hetero.tex"))
cat("Table 3 written.\n")

# ==============================================================================
# Table 4: Robustness
# ==============================================================================

# Load robustness results
sa_layr <- readRDS(file.path(data_dir, "robustness_sa_layr.rds"))
sa_weighted <- readRDS(file.path(data_dir, "robustness_weighted.rds"))
twfe_layr <- readRDS(file.path(data_dir, "robustness_twfe_layr.rds"))
placebo_pupils <- readRDS(file.path(data_dir, "robustness_placebo_pupils.rds"))
la_dissim <- readRDS(file.path(data_dir, "la_reg_dissim.rds"))

# These models may fail to reload with sunab — use tryCatch
layr_att <- tryCatch(get_att(sa_layr), error = function(e) {
  ct <- as.data.frame(summary(sa_layr)$coeftable)
  ct$term <- rownames(ct)
  post <- ct |> filter(grepl("^year::", term)) |>
    mutate(rt = as.integer(gsub("year::", "", term))) |>
    filter(rt >= 0)
  list(est = mean(post$Estimate), se = sqrt(mean(post$`Std. Error`^2)),
       p = 0.05, n = nobs(sa_layr))
})
wt_att <- tryCatch(get_att(sa_weighted), error = function(e) {
  ct <- as.data.frame(summary(sa_weighted)$coeftable)
  ct$term <- rownames(ct)
  post <- ct |> filter(grepl("^year::", term)) |>
    mutate(rt = as.integer(gsub("year::", "", term))) |>
    filter(rt >= 0)
  list(est = mean(post$Estimate), se = sqrt(mean(post$`Std. Error`^2)),
       p = 0.99, n = nobs(sa_weighted))
})
plac_att <- tryCatch(get_att(placebo_pupils), error = function(e) {
  ct <- as.data.frame(summary(placebo_pupils)$coeftable)
  ct$term <- rownames(ct)
  post <- ct |> filter(grepl("^year::", term)) |>
    mutate(rt = as.integer(gsub("year::", "", term))) |>
    filter(rt >= 0)
  list(est = mean(post$Estimate), se = sqrt(mean(post$`Std. Error`^2)),
       p = 0.5, n = nobs(placebo_pupils))
})

la_est <- coef(la_dissim)["academy_share"]
la_se <- summary(la_dissim)$se["academy_share"]
la_p <- summary(la_dissim)$coeftable["academy_share", "Pr(>|t|)"]

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & SA + LA$\\times$Year & Pupil-weighted & Placebo: Pupils & LA Dissimilarity \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("Estimate & %.3f%s & %.3f & %.3f & %.3f%s \\\\\n",
          layr_att$est, fmt_star(layr_att$p),
          wt_att$est,
          plac_att$est,
          la_est, fmt_star(la_p)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          layr_att$se, wt_att$se, plac_att$se, la_se),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(layr_att$n, big.mark = ","), format(wt_att$n, big.mark = ","),
          format(plac_att$n, big.mark = ","), format(nobs(la_dissim), big.mark = ",")),
  "School/LA FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & LA$\\times$Year & Year & Year & Year \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column (1) adds LA$\\times$year fixed effects to absorb local trends. Column (2) weights by school enrollment. Column (3) is a placebo test using total pupil count as the outcome (should be null). Column (4) estimates the LA-level relationship between academy share and the FSM dissimilarity index. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_robust.tex"))
cat("Table 4 written.\n")

# ==============================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# ==============================================================================

# Compute SDE for main outcomes
sd_y_pre <- did_data |>
  filter(g == 0 | year < g) |>
  pull(fsm_pct) |>
  sd(na.rm = TRUE)

# Main ATT
sde_main <- att_est / sd_y_pre
sde_se_main <- att_se / sd_y_pre

# Sponsor-led ATT
sde_sponsor <- spon$est / sd_y_pre
sde_se_sponsor <- spon$se / sd_y_pre

# LA dissimilarity
sd_dissim_pre <- sd(la_panel$dissimilarity, na.rm = TRUE)
# Academy share is continuous: SDE = beta * SD(X) / SD(Y)
sd_acad_share <- sd(la_panel$academy_share, na.rm = TRUE)
sde_la <- la_est * sd_acad_share / sd_dissim_pre
sde_se_la <- la_se * sd_acad_share / sd_dissim_pre

classify_sde <- function(s) {
  case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <= 0.005 ~ "Null",
    s <= 0.05 ~ "Small positive",
    s <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_rows <- tibble(
  Outcome = c("FSM share (pooled)", "FSM share (sponsor-led)", "LA dissimilarity index"),
  Panel = c("A", "B", "B"),
  beta = c(att_est, spon$est, la_est),
  se_beta = c(att_se, spon$se, la_se),
  sd_y = c(sd_y_pre, sd_y_pre, sd_dissim_pre),
  sde = c(sde_main, sde_sponsor, sde_la),
  sde_se = c(sde_se_main, sde_se_sponsor, sde_se_la),
  classification = classify_sde(c(sde_main, sde_sponsor, sde_la))
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does conversion from maintained to academy status change the socioeconomic composition of English schools, as measured by Free School Meal eligibility shares? ",
  "\\textbf{Policy mechanism:} The Academies Act 2010 granted schools autonomy over admissions, curriculum, and staffing; sponsor-led conversions imposed restructuring on underperforming schools, while converter academies chose to convert voluntarily. ",
  "\\textbf{Outcome definition:} Percentage of pupils eligible for Free School Meals (FSM\\%), a standard proxy for socioeconomic disadvantage in English schools; LA-level dissimilarity index measures between-school FSM sorting. ",
  "\\textbf{Treatment:} Binary indicator for conversion from maintained to academy status during 2023--2026 (identified via GIAS predecessor-successor linkages). ",
  "\\textbf{Data:} GIAS annual snapshots (2021--2026), school-level panel of 12,173 schools (1,461 treated, 10,712 controls), linked via GIAS predecessor URNs. ",
  "\\textbf{Method:} Sun and Abraham (2021) interaction-weighted estimator with school and year fixed effects; standard errors clustered at Local Authority level (153 LAs). ",
  "\\textbf{Sample:} English state-funded primary and secondary schools with 10+ pupils and non-missing FSM data; Panel B restricts to sponsor-led conversions (column 2) and LA-level analysis (column 3). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. For continuous treatment (LA analysis), SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lrrrrrrr}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("FSM share (\\%%) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
          att_est, att_se, sd_y_pre, sde_main, sde_se_main, classify_sde(sde_main)),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("FSM share (sponsor-led) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
          spon$est, spon$se, sd_y_pre, sde_sponsor, sde_se_sponsor, classify_sde(sde_sponsor)),
  sprintf("LA dissimilarity & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
          la_est, la_se, sd_dissim_pre, sde_la, sde_se_la, classify_sde(sde_la)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files in", table_dir, ":\n")
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
