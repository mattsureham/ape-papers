## 05_tables.R — Generate all tables (including SDE appendix)
## apep_1254: Portugal Golden Visa Geographic Restriction

source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
load("../data/main_models.RData")
load("../data/robustness_models.RData")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")
robustness <- jsonlite::fromJSON("../data/robustness_results.json")

pre_data <- df %>% filter(date < as.Date("2022-01-01"))
post_data <- df %>% filter(date >= as.Date("2022-01-01"))

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

get_pval <- function(model, param) {
  pvalue(model)[[param]]
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Compute stats
pre_t <- pre_data %>% filter(treated == 1) %>% pull(value)
pre_c <- pre_data %>% filter(treated == 0) %>% pull(value)
post_t <- post_data %>% filter(treated == 1) %>% pull(value)
post_c <- post_data %>% filter(treated == 0) %>% pull(value)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  
  "\\caption{Summary Statistics: Bank Housing Appraisal Values}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  " & Group & Mean & SD & Median & $N$ & Regions \\\\",
  " & & (\\euro/m$^2$) & & (\\euro/m$^2$) & & \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pre-treatment (January 2015--December 2021)}} \\\\",
  sprintf(" & Restricted & %s & %s & %s & %s & %d \\\\",
          format(round(mean(pre_t)), big.mark = ","),
          format(round(sd(pre_t)), big.mark = ","),
          format(round(median(pre_t)), big.mark = ","),
          format(length(pre_t), big.mark = ","),
          n_distinct(pre_data$geocod[pre_data$treated == 1])),
  sprintf(" & Eligible & %s & %s & %s & %s & %d \\\\",
          format(round(mean(pre_c)), big.mark = ","),
          format(round(sd(pre_c)), big.mark = ","),
          format(round(median(pre_c)), big.mark = ","),
          format(length(pre_c), big.mark = ","),
          n_distinct(pre_data$geocod[pre_data$treated == 0])),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Post-treatment (January 2022--December 2024)}} \\\\",
  sprintf(" & Restricted & %s & %s & %s & %s & %d \\\\",
          format(round(mean(post_t)), big.mark = ","),
          format(round(sd(post_t)), big.mark = ","),
          format(round(median(post_t)), big.mark = ","),
          format(length(post_t), big.mark = ","),
          n_distinct(post_data$geocod[post_data$treated == 1])),
  sprintf(" & Eligible & %s & %s & %s & %s & %d \\\\",
          format(round(mean(post_c)), big.mark = ","),
          format(round(sd(post_c)), big.mark = ","),
          format(round(median(post_c)), big.mark = ","),
          format(length(post_c), big.mark = ","),
          n_distinct(post_data$geocod[post_data$treated == 0])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}\\emergencystretch=3em",
  "\\footnotesize",
  "\\textit{Notes:} Median bank housing appraisal values (EUR/m$^2$) from INE Portugal's BPIHE survey, covering all dwelling types. ``Restricted'' regions are NUTS3 areas where golden visa real estate investment was banned under Decreto-Lei 14/2021 effective January 2022: \\'Area Metropolitana de Lisboa (Grande Lisboa and Pen\\'{\\i}nsula de Set\\'ubal), \\'Area Metropolitana do Porto, and Algarve. ``Eligible'' regions retained golden visa real estate eligibility. $N$ counts region-month observations.",
  "\\end{minipage}",
  
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

# Extract coefficients from all main specifications
# Col 1: Naive TWFE (log)
c1 <- coef(did_log)[["treated:post"]]
s1 <- sqrt(vcov(did_log)[["treated:post", "treated:post"]])
p1 <- get_pval(did_log, "treated:post")

# Col 2: Region-specific linear trends (PREFERRED)
c2 <- coef(did_trend)[["treated:post"]]
s2 <- sqrt(vcov(did_trend)[["treated:post", "treated:post"]])
p2 <- get_pval(did_trend, "treated:post")

# Col 3: Region trends, excl. COVID
c3 <- coef(did_trend_nocovid)[["treated:post"]]
s3 <- sqrt(vcov(did_trend_nocovid)[["treated:post", "treated:post"]])
p3 <- get_pval(did_trend_nocovid, "treated:post")

# Col 4: Levels (EUR/m2) with trends
df_with_trend <- df %>%
  mutate(time_index = as.integer(difftime(date, min(date), units = "days")) / 30)
did_levels_trend <- feols(
  value ~ treated:post | geocod[time_index] + ym,
  data = df_with_trend,
  cluster = ~nuts3_approx
)
c4 <- coef(did_levels_trend)[["treated:post"]]
s4 <- sqrt(vcov(did_levels_trend)[["treated:post", "treated:post"]])
p4 <- pvalue(did_levels_trend)[["treated:post"]]

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Golden Visa Geographic Restriction on Housing Appraisal Values}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Na\\\"ive TWFE & Region trends & Trends, no COVID & Levels \\\\",
  "\\midrule",
  sprintf("Restricted $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.1f%s \\\\",
          c1, stars(p1), c2, stars(p2), c3, stars(p3), c4, stars(p4)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.1f) \\\\",
          s1, s2, s3, s4),
  "\\addlinespace",
  "Region FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  "Region $\\times$ trend & No & Yes & Yes & Yes \\\\",
  "Outcome & Log & Log & Log & EUR/m$^2$ \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(did_log), big.mark = ","),
          format(nobs(did_trend), big.mark = ","),
          format(nobs(did_trend_nocovid), big.mark = ","),
          format(nobs(did_levels_trend), big.mark = ",")),
  sprintf("Regions & %d & %d & %d & %d \\\\",
          diagnostics$n_regions, diagnostics$n_regions,
          diagnostics$n_regions, diagnostics$n_regions),
  sprintf("Clusters (NUTS3) & %d & %d & %d & %d \\\\",
          diagnostics$n_clusters, diagnostics$n_clusters,
          diagnostics$n_clusters, diagnostics$n_clusters),
  sprintf("Pre-treatment mean (restricted) & %s & %s & %s & %s \\\\",
          format(round(mean(pre_t)), big.mark = ","),
          format(round(mean(pre_t)), big.mark = ","),
          format(round(mean(pre_t)), big.mark = ","),
          format(round(mean(pre_t)), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}\\emergencystretch=3em",
  "\\footnotesize",
  "\\textit{Notes:} Difference-in-differences estimates. The dependent variable is the log (columns 1--3) or level (column 4) of median bank housing appraisal values (EUR/m$^2$) at the NUTS3$\\times$month level. ``Restricted'' regions lost golden visa real estate eligibility in January 2022. Column (1) is a na\\\"ive two-way fixed effects specification that assumes parallel trends; the event study (",
  "\\Cref{tab:event_study}) reveals significant pre-trends, making this estimate unreliable. Columns (2)--(4) add region-specific linear time trends to absorb differential pre-existing appreciation. Column (3) excludes 2020--2021 to address concerns about COVID-driven differential recovery. Standard errors clustered at the NUTS3 level ($G = 27$) in parentheses. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{minipage}",
  
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ============================================================
# Table 3: Robustness and Placebo Tests
# ============================================================
cat("=== Table 3: Robustness ===\n")

# Placebo with region trends
df_pre <- df %>%
  filter(date < as.Date("2022-01-01")) %>%
  mutate(
    time_index = as.integer(difftime(date, min(date), units = "days")) / 30,
    post_2018 = as.integer(date >= as.Date("2018-01-01")),
    post_2019 = as.integer(date >= as.Date("2019-01-01"))
  )

placebo_2018_trend <- feols(
  log_value ~ treated:post_2018 | geocod[time_index] + ym,
  data = df_pre, cluster = ~nuts3_approx
)

placebo_2019_trend <- feols(
  log_value ~ treated:post_2019 | geocod[time_index] + ym,
  data = df_pre, cluster = ~nuts3_approx
)

# Short post period with trends
df_short_trend <- df_with_trend %>% filter(year <= 2022)
did_short_trend <- feols(
  log_value ~ treated:post | geocod[time_index] + ym,
  data = df_short_trend, cluster = ~nuts3_approx
)

# Anticipation with trends
did_antic_trend <- feols(
  log_value ~ treated:anticipation + treated:post | geocod[time_index] + ym,
  data = df_with_trend, cluster = ~nuts3_approx
)

cr2 <- coef(did_trend)[["treated:post"]]
sr2 <- sqrt(vcov(did_trend)[["treated:post", "treated:post"]])
pr2 <- get_pval(did_trend, "treated:post")

cr3 <- coef(did_short_trend)[["treated:post"]]
sr3 <- sqrt(vcov(did_short_trend)[["treated:post", "treated:post"]])
pr3 <- pvalue(did_short_trend)[["treated:post"]]

cr4 <- coef(placebo_2018_trend)[["treated:post_2018"]]
sr4 <- sqrt(vcov(placebo_2018_trend)[["treated:post_2018", "treated:post_2018"]])
pr4 <- pvalue(placebo_2018_trend)[["treated:post_2018"]]

cr5 <- coef(placebo_2019_trend)[["treated:post_2019"]]
sr5 <- sqrt(vcov(placebo_2019_trend)[["treated:post_2019", "treated:post_2019"]])
pr5 <- pvalue(placebo_2019_trend)[["treated:post_2019"]]

antic_c <- coef(did_antic_trend)[["treated:anticipation"]]
antic_s <- sqrt(vcov(did_antic_trend)[["treated:anticipation", "treated:anticipation"]])
antic_p <- pvalue(did_antic_trend)[["treated:anticipation"]]
antic_post_c <- coef(did_antic_trend)[["treated:post"]]
antic_post_s <- sqrt(vcov(did_antic_trend)[["treated:post", "treated:post"]])
antic_post_p <- pvalue(did_antic_trend)[["treated:post"]]

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Baseline & 2022 only & Placebo 2018 & Placebo 2019 & Anticipation \\\\",
  "\\midrule",
  sprintf("Restricted $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          cr2, stars(pr2), cr3, stars(pr3), cr4, stars(pr4), cr5, stars(pr5),
          antic_post_c, stars(antic_post_p)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          sr2, sr3, sr4, sr5, antic_post_s),
  "\\addlinespace",
  sprintf("Restricted $\\times$ Anticipation & & & & & %.3f%s \\\\",
          antic_c, stars(antic_p)),
  sprintf(" & & & & & (%.3f) \\\\", antic_s),
  "\\addlinespace",
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Region $\\times$ trend & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(did_trend), big.mark = ","),
          format(nobs(did_short_trend), big.mark = ","),
          format(nobs(placebo_2018_trend), big.mark = ","),
          format(nobs(placebo_2019_trend), big.mark = ","),
          format(nobs(did_antic_trend), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}\\emergencystretch=3em",
  "\\footnotesize",
  "\\textit{Notes:} All specifications include NUTS3 and year-month fixed effects with region-specific linear time trends. Column (1) reproduces the preferred specification from \\Cref{tab:main}. Column (2) restricts the post-period to January--December 2022 (before Portugal's Mais Habita\\c{c}\\~{a}o program). Columns (3)--(4) are placebo tests using only pre-treatment data, assigning fictitious treatment dates. Column (5) adds a separate indicator for the announcement period (April--December 2021). Standard errors clustered at the NUTS3 level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{minipage}",
  
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ============================================================
# Table 4: Event Study Coefficients
# ============================================================
cat("=== Table 4: Event Study ===\n")

es_coefs <- read_csv("../data/event_study_coefs.csv", show_col_types = FALSE)

# Select key periods
key_periods <- c(-24, -18, -12, -6, -3, 0, 3, 6, 12, 18, 24)
es_display <- es_coefs %>%
  filter(event_time %in% key_periods) %>%
  arrange(event_time) %>%
  mutate(
    period_label = case_when(
      event_time < 0 ~ paste0("$t", event_time, "$"),
      event_time == 0 ~ "$t = 0$ (Jan 2022)",
      TRUE ~ paste0("$t+", event_time, "$")
    )
  )

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  
  "\\caption{Event Study Estimates: Selected Periods Relative to January 2022}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Period & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\"
)

for (i in seq_len(nrow(es_display))) {
  row <- es_display[i, ]
  p_val <- 2 * pnorm(-abs(row$estimate / row$std.error))
  if (row$event_time == 0) {
    tab4_lines <- c(tab4_lines,
      "$t-1$ (ref., Dec 2021) & 0 & --- \\\\",
      "\\addlinespace",
      "\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\")
  }
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.4f%s & (%.4f) \\\\",
            row$period_label, row$estimate, stars(p_val), row$std.error))
}

tab4_lines <- c(tab4_lines,
  "\\addlinespace",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(df), big.mark = ",")),
  sprintf("Regions & \\multicolumn{2}{c}{%d} \\\\", diagnostics$n_regions),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}\\emergencystretch=3em",
  "\\footnotesize",
  "\\textit{Notes:} Coefficients from regressing log bank appraisal values on interactions of restricted-region indicators with monthly event-time dummies. Includes NUTS3 and year-month fixed effects (no region-specific trends). The reference period is $t-1$ (December 2021). Endpoints binned at $\\pm 24$ months. Pre-treatment coefficients are significantly negative, indicating that restricted regions were appreciating faster than eligible regions prior to the reform. Standard errors clustered at the NUTS3 level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{minipage}",
  
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_event_study.tex")
cat("Table 4 written.\n")

# ============================================================
# Table F1: SDE Appendix (MANDATORY)
# ============================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Use the PREFERRED specification (region-specific trends)
pre_sd_log <- sd(pre_data$log_value[pre_data$treated == 1], na.rm = TRUE)
pre_sd_value <- sd(pre_data$value[pre_data$treated == 1], na.rm = TRUE)

# Panel A: Pooled — preferred spec (region trends)
beta_trend <- coef(did_trend)[["treated:post"]]
se_trend <- sqrt(vcov(did_trend)[["treated:post", "treated:post"]])
sde_trend <- beta_trend / pre_sd_log
se_sde_trend <- se_trend / pre_sd_log

beta_levels_t <- coef(did_levels_trend)[["treated:post"]]
se_levels_t <- sqrt(vcov(did_levels_trend)[["treated:post", "treated:post"]])
sde_levels_t <- beta_levels_t / pre_sd_value
se_sde_levels_t <- se_levels_t / pre_sd_value

classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Panel B: Heterogeneity — Lisbon metro vs. Porto/Algarve
# Match by geocod prefix: 1A0=Grande Lisboa prefix, 1B0=Setúbal prefix
df_lisbon <- df_with_trend %>% filter(grepl("^1A0|^1B0", geocod))
df_porto_alg <- df_with_trend %>% filter(grepl("^11A|^1500", geocod))

het_rows <- list()

if (nrow(df_lisbon) > 0) {
  df_het_lisbon <- bind_rows(df_lisbon, df_with_trend %>% filter(treated == 0))
  het_lisbon <- tryCatch({
    feols(log_value ~ treated:post | geocod[time_index] + ym,
          data = df_het_lisbon, cluster = ~nuts3_approx)
  }, error = function(e) NULL)

  if (!is.null(het_lisbon)) {
    pre_sd_lisbon <- sd(df_lisbon$log_value[df_lisbon$date < as.Date("2022-01-01")], na.rm = TRUE)
    b_l <- coef(het_lisbon)[["treated:post"]]
    s_l <- sqrt(vcov(het_lisbon)[["treated:post", "treated:post"]])
    het_rows[["Lisbon"]] <- list(
      outcome = "Log appraisal (Lisbon metro)",
      beta = b_l, se = s_l, sd_y = pre_sd_lisbon,
      sde = b_l / pre_sd_lisbon, se_sde = s_l / pre_sd_lisbon
    )
  }
}

if (nrow(df_porto_alg) > 0) {
  df_het_other <- bind_rows(df_porto_alg, df_with_trend %>% filter(treated == 0))
  het_other <- tryCatch({
    feols(log_value ~ treated:post | geocod[time_index] + ym,
          data = df_het_other, cluster = ~nuts3_approx)
  }, error = function(e) NULL)

  if (!is.null(het_other)) {
    pre_sd_other <- sd(df_porto_alg$log_value[df_porto_alg$date < as.Date("2022-01-01")], na.rm = TRUE)
    b_o <- coef(het_other)[["treated:post"]]
    s_o <- sqrt(vcov(het_other)[["treated:post", "treated:post"]])
    het_rows[["Porto/Algarve"]] <- list(
      outcome = "Log appraisal (Porto/Algarve)",
      beta = b_o, se = s_o, sd_y = pre_sd_other,
      sde = b_o / pre_sd_other, se_sde = s_o / pre_sd_other
    )
  }
}

# Build SDE table
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} Portugal. ",
  "\\textbf{Research question:} Does restricting golden visa real estate investment in prime urban areas reduce housing prices in restricted regions and divert capital to eligible interior regions? ",
  "\\textbf{Policy mechanism:} Decreto-Lei 14/2021 (effective January 2022) barred golden visa applicants from purchasing residential property in the Metropolitan Areas of Lisbon and Porto and in the Algarve, while retaining eligibility in interior and island NUTS3 regions, thereby eliminating a demand channel from approximately 1,000 annual foreign investor-visa property transactions in high-demand coastal markets. ",
  "\\textbf{Outcome definition:} Median bank housing appraisal value in EUR per square meter from INE Portugal's monthly BPIHE survey of bank property valuations. ",
  "\\textbf{Treatment:} Binary; NUTS3 regions classified as restricted if they lost golden visa real estate eligibility in January 2022. ",
  sprintf("\\textbf{Data:} INE BPIHE monthly bank appraisal survey, January 2015--December 2024, %d municipalities, %s municipality-month observations. ",
          diagnostics$n_regions, format(diagnostics$n_obs, big.mark = ",")),
  sprintf("\\textbf{Method:} Two-way fixed effects DiD with municipality and year-month fixed effects plus municipality-specific linear time trends; standard errors clustered at NUTS3 level (%d clusters). ",
          diagnostics$n_clusters),
  "\\textbf{Sample:} All NUTS3 regions in mainland Portugal plus Azores and Madeira with at least 80\\% monthly coverage in the BPIHE survey. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the restricted group. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log appraisal value & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_trend, se_trend, pre_sd_log, sde_trend, se_sde_trend, classify_sde(sde_trend)),
  sprintf("Appraisal value (\\euro/m$^2$) & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\",
          beta_levels_t, se_levels_t, pre_sd_value, sde_levels_t, se_sde_levels_t, classify_sde(sde_levels_t)),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\"
)

for (name in names(het_rows)) {
  r <- het_rows[[name]]
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, classify_sde(r$sde)))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}\\emergencystretch=3em",
  "\\footnotesize",
  sde_notes,
  "\\end{minipage}",
  
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
