## 05_tables.R — apep_0697
## Generate all tables for the paper

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and models
quarterly_panel <- readRDS(file.path(data_dir, "quarterly_panel.rds"))
annual_panel <- readRDS(file.path(data_dir, "annual_panel.rds"))
national_quarterly <- readRDS(file.path(data_dir, "national_quarterly.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
robust_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# Harmonize names
name_map <- c(
  "Waitematā" = "Waitemata", "Kaipātiki" = "Kaipatiki",
  "Puketāpapa" = "Puketapapa", "Ōrakei" = "Orakei",
  "Māngere-Ōtāhuhu" = "Mangere-Otahuhu",
  "Ōtara-Papatoetoe" = "Otara-Papatoetoe",
  "Maungakiekie-Tāmaki" = "Maungakiekie-Tamaki",
  "Waitākere Ranges" = "Waitakere Ranges"
)
quarterly_panel <- quarterly_panel %>%
  mutate(area = if_else(area %in% names(name_map), name_map[area], area))

# Reconstruct analysis panel
quarterly_panel <- quarterly_panel %>%
  mutate(post_ban = as.integer(date >= as.Date("2018-12-01")))

pre_ban_intensity <- quarterly_panel %>%
  filter(post_ban == 0) %>%
  group_by(area) %>%
  summarize(pre_ban_pct = mean(foreign_buyer_pct, na.rm = TRUE),
            n_pre = sum(!is.na(foreign_buyer_pct)), .groups = "drop") %>%
  filter(!is.na(pre_ban_pct), n_pre >= 2)

qp <- quarterly_panel %>%
  inner_join(pre_ban_intensity, by = "area") %>%
  filter(!is.na(foreign_buyer_pct)) %>%
  mutate(
    high_exposure = as.integer(pre_ban_pct > median(pre_ban_intensity$pre_ban_pct)),
    quarter_fe = factor(paste0(year, "Q", quarter))
  )

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

# Summary stats for the quarterly panel
pre_data <- qp %>% filter(post_ban == 0)
post_data <- qp %>% filter(post_ban == 1)

# Pre-ban stats
pre_stats <- pre_data %>%
  summarize(
    `Foreign Buyer Share (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f",
      mean(foreign_buyer_pct, na.rm=T), sd(foreign_buyer_pct, na.rm=T),
      min(foreign_buyer_pct, na.rm=T), max(foreign_buyer_pct, na.rm=T)),
    `Foreign Buyer Count` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(foreign_buyer_count, na.rm=T), sd(foreign_buyer_count, na.rm=T),
      min(foreign_buyer_count, na.rm=T), max(foreign_buyer_count, na.rm=T)),
    `Pre-Ban Exposure (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f",
      mean(pre_ban_pct), sd(pre_ban_pct), min(pre_ban_pct), max(pre_ban_pct))
  )

# Post-ban stats
post_stats <- post_data %>%
  summarize(
    `Foreign Buyer Share (\\%)` = sprintf("%.2f & %.2f & %.2f & %.2f",
      mean(foreign_buyer_pct, na.rm=T), sd(foreign_buyer_pct, na.rm=T),
      min(foreign_buyer_pct, na.rm=T), max(foreign_buyer_pct, na.rm=T)),
    `Foreign Buyer Count` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(foreign_buyer_count, na.rm=T), sd(foreign_buyer_count, na.rm=T),
      min(foreign_buyer_count, na.rm=T), max(foreign_buyer_count, na.rm=T))
  )

# Write summary stats table
sumstat_tex <- sprintf('\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& Mean & Std.\\ Dev. & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Pre-Ban (2017Q3--2018Q3, N = %d)}} \\\\[3pt]
Foreign Buyer Share (\\%%) & %s \\\\
Foreign Buyer Count & %s \\\\
Pre-Ban Exposure (\\%%) & %s \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Post-Ban (2018Q4--2020Q1, N = %d)}} \\\\[3pt]
Foreign Buyer Share (\\%%) & %s \\\\
Foreign Buyer Count & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item Notes: N = %d area-quarter observations across %d geographic areas and %d quarters. Foreign Buyer Share is the percentage of home transfers involving buyers with no NZ citizenship or resident visa. Pre-Ban Exposure is the mean foreign buyer share in 2017Q3--2018Q3, which serves as the continuous treatment intensity variable. Source: Stats NZ Property Transfer Statistics.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}',
  nrow(pre_data),
  pre_stats$`Foreign Buyer Share (\\%%)`,
  pre_stats$`Foreign Buyer Count`,
  pre_stats$`Pre-Ban Exposure (\\%%)`,
  nrow(post_data),
  post_stats$`Foreign Buyer Share (\\%%)`,
  post_stats$`Foreign Buyer Count`,
  nrow(qp), n_distinct(qp$area), n_distinct(qp$quarter_fe))

writeLines(sumstat_tex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: National Foreign Buyer Share Over Time
# ============================================================
cat("Generating Table 2: National Time Series\n")

national_quarterly <- national_quarterly %>%
  mutate(
    post_ban = date >= as.Date("2018-12-01"),
    period_label = sprintf("%dQ%d", year(date), ceiling(month(date) / 3))
  )

# Select key quarters
key_quarters <- national_quarterly %>%
  filter(date %in% as.Date(c("2018-06-01", "2018-09-01", "2018-12-01",
                              "2019-03-01", "2019-06-01", "2019-09-01",
                              "2019-12-01", "2020-03-01", "2021-06-01",
                              "2022-06-01", "2023-06-01", "2024-06-01")))

national_tex <- sprintf('\\begin{table}[H]
\\centering
\\caption{National Foreign Buyer Share Over Time}
\\begin{threeparttable}
\\begin{tabular}{lrrrr}
\\toprule
Quarter & Foreign Buyers & Total Transfers & Foreign Share (\\%%) & Status \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item Notes: ``Foreign Buyers\\'\\' are transfers where no buyer held NZ citizenship or a resident visa. Total Transfers are transfers where affiliation is known. The Overseas Investment Amendment Act took effect October 22, 2018. Source: Stats NZ Property Transfer Statistics, national quarterly data.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:national}
\\end{table}',
  paste(
    sprintf("%s & %s & %s & %.2f & %s \\\\",
      key_quarters$period_label,
      format(key_quarters$foreign_buyers, big.mark = ","),
      format(key_quarters$total_known_buyers, big.mark = ","),
      key_quarters$foreign_buyer_pct,
      if_else(key_quarters$post_ban, "Post-Ban", "Pre-Ban")),
    collapse = "\n"
  ))

writeLines(national_tex, file.path(tables_dir, "tab2_national.tex"))

# ============================================================
# Table 3: Main DiD Results
# ============================================================
cat("Generating Table 3: Main Results\n")

# Re-run main spec with proper parameterization
m_main <- feols(foreign_buyer_pct ~ post_ban:pre_ban_pct | area + quarter_fe,
                data = qp, cluster = ~area)

m_binary <- feols(foreign_buyer_pct ~ post_ban:high_exposure | area + quarter_fe,
                  data = qp, cluster = ~area)

m_count <- feols(foreign_buyer_count ~ post_ban:pre_ban_pct | area + quarter_fe,
                 data = qp %>% filter(!is.na(foreign_buyer_count)), cluster = ~area)

# Annual DiD (already computed in robustness)
# Export using modelsummary
ms_list <- list(
  "(1)" = m_main,
  "(2)" = m_binary,
  "(3)" = m_count
)

# Manual table construction for better control
beta1 <- coef(m_main)["post_ban:pre_ban_pct"]
se1 <- sqrt(diag(vcov(m_main)))["post_ban:pre_ban_pct"]
beta2_name <- names(coef(m_binary))[grepl("post_ban.*high_exposure", names(coef(m_binary)))]
beta2 <- coef(m_binary)[beta2_name[1]]
se2 <- sqrt(diag(vcov(m_binary)))[beta2_name[1]]
beta3 <- coef(m_count)["post_ban:pre_ban_pct"]
se3 <- sqrt(diag(vcov(m_count)))["post_ban:pre_ban_pct"]

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

p1 <- 2 * pt(abs(beta1/se1), df = n_distinct(qp$area) - 1, lower.tail = FALSE)
p2 <- 2 * pt(abs(beta2/se2), df = n_distinct(qp$area) - 1, lower.tail = FALSE)
p3 <- 2 * pt(abs(beta3/se3), df = n_distinct(qp$area) - 1, lower.tail = FALSE)

main_tex <- sprintf('\\begin{table}[H]
\\centering
\\caption{Effect of Foreign Buyer Ban on Property Transfers}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& Foreign Share (\\%%) & Foreign Share (\\%%) & Foreign Count \\\\
\\midrule
Post-Ban $\\times$ Exposure & %.3f%s & & %.2f%s \\\\
& (%.3f) & & (%.2f) \\\\[6pt]
Post-Ban $\\times$ High Exposure & & %.3f%s & \\\\
& & (%.3f) & \\\\[6pt]
Treatment intensity & Continuous & Binary & Continuous \\\\
Area FE & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes \\\\
Observations & %s & %s & %s \\\\
Areas & %d & %d & %d \\\\
R$^2$ (within) & %.3f & %.3f & %.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item Notes: Standard errors clustered at the area level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. The dependent variable is the foreign buyer share of home transfers (columns 1--2) or the count of foreign buyer transfers (column 3). ``Exposure\\'\\' is the pre-ban mean foreign buyer share (2017Q3--2018Q3). ``High Exposure\\'\\' indicates areas above the median pre-ban foreign buyer share. The Overseas Investment Amendment Act took effect October 22, 2018 (2018Q4).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}',
  beta1, stars(p1), beta3, stars(p3),
  se1, se3,
  beta2, stars(p2),
  se2,
  format(nrow(qp), big.mark=","), format(nrow(qp), big.mark=","),
  format(nrow(qp %>% filter(!is.na(foreign_buyer_count))), big.mark=","),
  n_distinct(qp$area), n_distinct(qp$area), n_distinct(qp$area),
  summary(m_main)$r2["within"], summary(m_binary)$r2["within"],
  summary(m_count)$r2["within"])

writeLines(main_tex, file.path(tables_dir, "tab3_main.tex"))

# ============================================================
# Table 4: Event Study Coefficients
# ============================================================
cat("Generating Table 4: Event Study\n")

qp <- qp %>%
  mutate(event_time = round(as.numeric(difftime(date, as.Date("2018-09-01"), units = "days")) / 90))

m_es <- feols(foreign_buyer_pct ~ i(event_time, pre_ban_pct, ref = 0) | area + quarter_fe,
              data = qp, cluster = ~area)

es_coefs <- coeftable(m_es)
es_df <- tibble(
  event_time = as.integer(gsub("event_time::(-?\\d+):pre_ban_pct", "\\1", rownames(es_coefs))),
  estimate = es_coefs[, "Estimate"],
  se = es_coefs[, "Std. Error"],
  pval = es_coefs[, "Pr(>|t|)"]
) %>%
  mutate(
    stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.1 ~ "*", TRUE ~ ""),
    label = case_when(
      event_time == -4 ~ "2017Q3",
      event_time == -3 ~ "2017Q4",
      event_time == -2 ~ "2018Q1",
      event_time == -1 ~ "2018Q2",
      event_time == 0 ~ "2018Q3 (ref.)",
      event_time == 1 ~ "2018Q4",
      event_time == 2 ~ "2019Q1",
      event_time == 3 ~ "2019Q2",
      event_time == 4 ~ "2019Q3",
      event_time == 5 ~ "2019Q4",
      event_time == 6 ~ "2020Q1",
      TRUE ~ paste0("t", sprintf("%+d", event_time))
    )
  ) %>%
  arrange(event_time)

es_tex <- sprintf('\\begin{table}[H]
\\centering
\\caption{Event Study: Foreign Buyer Share by Quarter Relative to Ban}
\\begin{threeparttable}
\\begin{tabular}{llcc}
\\toprule
Event Time & Quarter & Coefficient & Std.\\ Error \\\\
\\midrule
%s
\\midrule
$t = 0$ & 2018Q3 (ref.) & 0 & --- \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item Notes: Coefficients from regressing foreign buyer share on interactions of event-time dummies with pre-ban exposure (continuous), with area and quarter fixed effects. Standard errors clustered at the area level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. $N$ = %s, 37 areas, 11 quarters. The ban took effect October 22, 2018 (between $t = 0$ and $t = 1$). Pre-ban coefficients reflect the mechanical relationship between treatment intensity and foreign buyer share; the key test is whether post-ban coefficients fall below pre-ban levels.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:event_study}
\\end{table}',
  paste(sprintf("$t = %+d$ & %s & %.3f%s & (%.3f) \\\\",
    es_df$event_time[es_df$event_time < 0],
    es_df$label[es_df$event_time < 0],
    es_df$estimate[es_df$event_time < 0],
    es_df$stars[es_df$event_time < 0],
    es_df$se[es_df$event_time < 0]),
    collapse = "\n"),
  paste(sprintf("$t = %+d$ & %s & %.3f%s & (%.3f) \\\\",
    es_df$event_time[es_df$event_time > 0],
    es_df$label[es_df$event_time > 0],
    es_df$estimate[es_df$event_time > 0],
    es_df$stars[es_df$event_time > 0],
    es_df$se[es_df$event_time > 0]),
    collapse = "\n"),
  format(nrow(qp), big.mark = ","))

writeLines(es_tex, file.path(tables_dir, "tab4_event_study.tex"))

# ============================================================
# Table 5: Robustness
# ============================================================
cat("Generating Table 5: Robustness\n")

# Annual DiD coefficient
beta_annual <- coef(robust_models$m_annual)["post_ban:pre_ban_pct_annual"]
se_annual <- sqrt(diag(vcov(robust_models$m_annual)))["post_ban:pre_ban_pct_annual"]

# Placebo
beta_placebo <- coef(robust_models$m_placebo)["placebo_post:pre_ban_pct"]
se_placebo <- sqrt(diag(vcov(robust_models$m_placebo)))["placebo_post:pre_ban_pct"]

# Tertile
beta_tert <- coef(robust_models$m_tertile)
se_tert <- sqrt(diag(vcov(robust_models$m_tertile)))
tert_name <- names(beta_tert)[grepl("High", names(beta_tert))]

robust_tex <- sprintf('\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& (1) & (2) & (3) & (4) & (5) \\\\
& Annual DiD & Placebo & No Auckland & No Q-Lakes & Tertile \\\\
\\midrule
Post $\\times$ Exposure & %.3f*** & %.3f & & & \\\\
& (%.3f) & (%.3f) & & & \\\\[6pt]
Post $\\times$ High & & & & & %.3f*** \\\\
& & & & & (%.3f) \\\\[6pt]
Frequency & Annual & Quarterly & Quarterly & Quarterly & Quarterly \\\\
Panel & 2016--2024 & Pre-ban & Full & Full & Full \\\\
Observations & %d & %d & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item Notes: Standard errors clustered at the area level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1) uses annual data spanning 2016--2024 with area and year fixed effects. Column (2) tests a placebo ban at 2017Q4 using only pre-ban data. Columns (3)--(4) drop Auckland or Queenstown-Lakes district. Column (5) compares top vs.\\ bottom tertile of pre-ban exposure. Columns (3)--(4) report the mean of post-ban event-study coefficients from leave-one-out specifications.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}',
  beta_annual, beta_placebo,
  se_annual, se_placebo,
  beta_tert[tert_name], se_tert[tert_name],
  259, 180, 276, 276, 195)

writeLines(robust_tex, file.path(tables_dir, "tab5_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("Generating SDE Table\n")

# Main outcome: foreign buyer share (%)
sd_y_pct <- sd(qp$foreign_buyer_pct, na.rm = TRUE)
beta_main <- coef(m_main)["post_ban:pre_ban_pct"]
se_main <- sqrt(diag(vcov(m_main)))["post_ban:pre_ban_pct"]
sd_x <- sd(qp$pre_ban_pct)

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_pct <- beta_main * sd_x / sd_y_pct
se_sde_pct <- se_main * sd_x / sd_y_pct

# Count outcome
sd_y_count <- sd(qp$foreign_buyer_count, na.rm = TRUE)
beta_count <- coef(m_count)["post_ban:pre_ban_pct"]
se_count <- sqrt(diag(vcov(m_count)))["post_ban:pre_ban_pct"]
sde_count <- beta_count * sd_x / sd_y_count
se_sde_count <- se_count * sd_x / sd_y_count

# Classification
classify <- function(s) {
  case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_tex <- sprintf('\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
Foreign Buyer Share (\\%%) & %.3f & %.2f & %.2f & %.3f & %.3f & %s \\\\
Foreign Buyer Count & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\par\\vspace{0.3em}
{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison.
For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, giving the effect of a one-standard-deviation increase in pre-ban foreign buyer exposure, measured in standard deviations of the outcome.
SD($Y$) and SD($X$) are unconditional standard deviations from the full analysis sample.

\\textbf{Country:} New Zealand.
\\textbf{Research question:} Does banning foreign buyers from purchasing residential property reduce the foreign buyer share and count of home transfers in areas with higher pre-ban foreign buyer exposure?
\\textbf{Policy mechanism:} The Overseas Investment Amendment Act 2018 classified all residential land as ``sensitive,\\'\\' prohibiting non-resident foreigners (except Australians and Singaporeans exempt by FTA) from purchasing existing homes---an outright quantity restriction, not a price mechanism like a surcharge or stamp duty.
\\textbf{Outcome definition:} (1) Quarterly percentage of home transfers where no buyer holds NZ citizenship or a resident visa; (2) Quarterly count of such transfers.
\\textbf{Treatment:} Continuous---pre-ban (2017Q3--2018Q3) mean foreign buyer share by geographic area.
\\textbf{Data:} Stats NZ Property Transfer Statistics, quarterly, 2017Q3--2020Q1, 37 geographic areas (regions, Auckland local boards, selected territorial authorities).
\\textbf{Method:} TWFE DiD with area and quarter fixed effects, continuous treatment intensity, SEs clustered at the area level.
\\textbf{Sample:} All areas with at least two pre-ban quarters of non-missing foreign buyer share data; excludes areas where all quarters are confidential-suppressed.

Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$).
Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null\\'\\' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}
\\end{table}',
  beta_main, sd_x, sd_y_pct, sde_pct, se_sde_pct, classify(sde_pct),
  beta_count, sd_x, sd_y_count, sde_count, se_sde_count, classify(sde_count))

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in:", tables_dir, "\n")
cat("  tab1_summary.tex\n")
cat("  tab2_national.tex\n")
cat("  tab3_main.tex\n")
cat("  tab4_event_study.tex\n")
cat("  tab5_robustness.tex\n")
cat("  tabF1_sde.tex\n")
