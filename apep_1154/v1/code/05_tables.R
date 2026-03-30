## 05_tables.R — Generate all tables
## apep_1154: EU Transposition Delay and Firm Entry

source("00_packages.R")

cat("\n=== Generating Tables ===\n")

df <- readRDS("../data/analysis_df.rds")
results <- readRDS("../data/results.rds")
rob_results <- readRDS("../data/rob_results.rds")
sector_summary <- readRDS("../data/sector_summary.rds")
late_by_country <- readRDS("../data/late_by_country.rds")

# Helper: format significance stars
stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

# ===================================================================
# TABLE 1: Summary Statistics
# ===================================================================
cat("\n--- Table 1: Summary Statistics ---\n")

summ <- df %>%
  summarise(
    across(
      c(births, active_ent, birth_rate, any_limbo, n_limbo, limbo_share),
      list(
        mean = ~mean(., na.rm = TRUE),
        sd = ~sd(., na.rm = TRUE),
        min = ~min(., na.rm = TRUE),
        max = ~max(., na.rm = TRUE)
      )
    )
  )

var_labels <- c(
  "Firm births" = "births",
  "Active enterprises" = "active_ent",
  "Birth rate (\\%)" = "birth_rate",
  "Any directive in limbo" = "any_limbo",
  "Directives in limbo (count)" = "n_limbo",
  "Limbo share" = "limbo_share"
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Outcome variables}} \\\\",
  "\\addlinespace"
)

for (i in 1:3) {
  lab <- names(var_labels)[i]
  v <- var_labels[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.1f & %.1f & %.0f & %.0f \\\\",
    lab,
    summ[[paste0(v, "_mean")]],
    summ[[paste0(v, "_sd")]],
    summ[[paste0(v, "_min")]],
    summ[[paste0(v, "_max")]]
  ))
}

tab1_lines <- c(tab1_lines,
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treatment variables}} \\\\",
  "\\addlinespace"
)

for (i in 4:6) {
  lab <- names(var_labels)[i]
  v <- var_labels[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.3f & %.3f & %.0f & %.3f \\\\",
    lab,
    summ[[paste0(v, "_mean")]],
    summ[[paste0(v, "_sd")]],
    summ[[paste0(v, "_min")]],
    summ[[paste0(v, "_max")]]
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} Panel of %d EU member states $\\times$ %d NACE sectors $\\times$ %d years (%d--%d). Firm births and active enterprises from Eurostat Business Demography (bd\\_enace2\\_r3). Birth rate is firm births per 100 active enterprises. Treatment variables constructed from CELLAR transposition records: ``limbo'' is the period after a directive's transposition deadline has passed but a member state has not yet notified national implementation measures. $N = %s$.}",
    results$n_countries, results$n_sectors,
    length(unique(df$year)), min(df$year), max(df$year),
    format(results$n_obs, big.mark = ",")),
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ===================================================================
# TABLE 2: Late Transposition by Country
# ===================================================================
cat("\n--- Table 2: Transposition delay by country ---\n")

top_late <- late_by_country %>%
  filter(pct_late > 0) %>%
  arrange(desc(pct_late)) %>%
  head(15)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Transposition Delay Across EU Member States}",
  "\\label{tab:delay}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Country & Directives & Late (\\%) & Avg.\\ delay (days) \\\\",
  "\\midrule"
)

for (i in 1:nrow(top_late)) {
  row <- top_late[i, ]
  tab2_lines <- c(tab2_lines, sprintf(
    "%s & %d & %.1f & %d \\\\",
    row$country2, row$n_directives, row$pct_late,
    ifelse(is.na(row$avg_delay_days), 0, row$avg_delay_days)
  ))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize",
  "\\textit{Notes:} Shows the 15 EU member states with the highest share of late transpositions. ``Late'' means the national implementation measure was notified to the Commission after the directive's transposition deadline. Average delay conditional on being late. Data: CELLAR SPARQL, directives with deadlines 2008--2022.",
  "}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_delay.tex")
cat("Table 2 written.\n")

# ===================================================================
# TABLE 3: Main Results
# ===================================================================
cat("\n--- Table 3: Main regression results ---\n")

m1 <- results$m1; m2 <- results$m2; m3 <- results$m3
m4 <- results$m4; m5 <- results$m5

extract_row <- function(model, var_name) {
  b <- coef(model)[var_name]
  s <- se(model)[var_name]
  p <- pvalue(model)[var_name]
  list(b = b, se = s, p = p, star = stars(p))
}

r1 <- extract_row(m1, "any_limbo")
r2 <- extract_row(m2, "any_limbo")
r3 <- extract_row(m3, "limbo_share")
r4 <- extract_row(m4, "any_limbo")
r5 <- extract_row(m5, "any_limbo")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Transposition Delay and Firm Entry: Main Results}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Log births & Log births & Log births & Birth rate & Log active \\\\",
  "\\midrule",
  sprintf("Any limbo & %s%s & %s%s & & %s%s & %s%s \\\\",
    formatC(r1$b, format = "f", digits = 4), r1$star,
    formatC(r2$b, format = "f", digits = 4), r2$star,
    formatC(r4$b, format = "f", digits = 4), r4$star,
    formatC(r5$b, format = "f", digits = 4), r5$star),
  sprintf(" & (%s) & (%s) & & (%s) & (%s) \\\\",
    formatC(r1$se, format = "f", digits = 4),
    formatC(r2$se, format = "f", digits = 4),
    formatC(r4$se, format = "f", digits = 4),
    formatC(r5$se, format = "f", digits = 4)),
  sprintf("Limbo share & & & %s%s & & \\\\",
    formatC(r3$b, format = "f", digits = 4), r3$star),
  sprintf(" & & & (%s) & & \\\\",
    formatC(r3$se, format = "f", digits = 4)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
    format(nobs(m1), big.mark = ","),
    format(nobs(m2), big.mark = ","),
    format(nobs(m3), big.mark = ","),
    format(nobs(m4), big.mark = ","),
    format(nobs(m5), big.mark = ",")),
  "Country $\\times$ sector FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & & Yes & Yes & Yes \\\\",
  "Sector $\\times$ year FE & & Yes & & & \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize",
  sprintf("\\textit{Notes:} Each column reports a separate regression. The unit of observation is country $\\times$ NACE sector $\\times$ year. ``Any limbo'' equals one if at least one directive affecting that sector has passed its transposition deadline without the member state notifying national measures. ``Limbo share'' is the fraction of applicable directives currently in limbo. Standard errors clustered at the country level in parentheses. %s p $<$ 0.01, %s p $<$ 0.05, %s p $<$ 0.1.",
    "***", "**", "*"),
  "}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")
cat("Table 3 written.\n")

# ===================================================================
# TABLE 4: Robustness
# ===================================================================
cat("\n--- Table 4: Robustness ---\n")

rob_rows <- list()

# Row 1: Baseline (from m1)
rob_rows[[1]] <- list(
  label = "Baseline",
  b = coef(m1)["any_limbo"],
  se = se(m1)["any_limbo"],
  p = pvalue(m1)["any_limbo"],
  n = nobs(m1)
)

# Row 2: Drop chronic late transposers
rob_rows[[2]] <- list(
  label = "Drop IT, FR, ES, DE",
  b = coef(rob_results$m_no_chronic)["any_limbo"],
  se = se(rob_results$m_no_chronic)["any_limbo"],
  p = pvalue(rob_results$m_no_chronic)["any_limbo"],
  n = nobs(rob_results$m_no_chronic)
)

# Row 3: Callaway-Sant'Anna
if (!is.null(rob_results$cs_agg)) {
  rob_rows[[3]] <- list(
    label = "Callaway--Sant'Anna",
    b = rob_results$cs_agg$overall.att,
    se = rob_results$cs_agg$overall.se,
    p = 2 * pnorm(-abs(rob_results$cs_agg$overall.att / rob_results$cs_agg$overall.se)),
    n = results$n_obs
  )
} else {
  rob_rows[[3]] <- list(
    label = "Callaway--Sant'Anna",
    b = NA, se = NA, p = NA, n = NA
  )
}

# Row 4: Placebo (non-targeted sectors)
if (!is.null(rob_results$m_placebo)) {
  rob_rows[[4]] <- list(
    label = "Placebo: non-targeted sectors",
    b = coef(rob_results$m_placebo)["placebo_treat"],
    se = se(rob_results$m_placebo)["placebo_treat"],
    p = pvalue(rob_results$m_placebo)["placebo_treat"],
    n = nobs(rob_results$m_placebo)
  )
} else {
  rob_rows[[4]] <- list(
    label = "Placebo: non-targeted sectors",
    b = NA, se = NA, p = NA, n = NA
  )
}

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule"
)

for (row in rob_rows) {
  if (is.na(row$b)) {
    tab4_lines <- c(tab4_lines, sprintf(
      "%s & --- & --- & --- \\\\", row$label))
  } else {
    tab4_lines <- c(tab4_lines, sprintf(
      "%s & %s%s & (%s) & %s \\\\",
      row$label,
      formatC(row$b, format = "f", digits = 4),
      stars(row$p),
      formatC(row$se, format = "f", digits = 4),
      format(row$n, big.mark = ",")
    ))
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize",
  "\\textit{Notes:} Dependent variable: log firm births. All specifications include country $\\times$ sector and year fixed effects. ``Drop IT, FR, ES, DE'' removes the four largest chronic late transposers. Callaway--Sant'Anna uses the \\texttt{did} R package with never-treated as the control group. Placebo tests whether non-targeted sectors in countries experiencing limbo in other sectors show spillover effects. Standard errors clustered at the country level.",
  "}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")
cat("Table 4 written.\n")

# ===================================================================
# TABLE 5: Heterogeneity
# ===================================================================
cat("\n--- Table 5: Heterogeneity ---\n")

m_het <- rob_results$m_het

# Also run by new vs old member states
old_ms <- c("AT","BE","DE","DK","EL","ES","FI","FR","IE","IT","LU","NL","PT","SE")
df$old_ms <- as.integer(df$country2 %in% old_ms)

m_old <- feols(
  log_births ~ any_limbo | cs_id + year,
  data = df %>% filter(old_ms == 1),
  cluster = ~country2
)

m_new <- feols(
  log_births ~ any_limbo | cs_id + year,
  data = df %>% filter(old_ms == 0),
  cluster = ~country2
)

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity in the Effect of Transposition Delay}",
  "\\label{tab:het}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Interaction & Old EU-15 & New MS \\\\",
  "\\midrule",
  sprintf("Any limbo & %s%s & %s%s & %s%s \\\\",
    formatC(coef(m_het)["any_limbo"], format = "f", digits = 4),
    stars(pvalue(m_het)["any_limbo"]),
    formatC(coef(m_old)["any_limbo"], format = "f", digits = 4),
    stars(pvalue(m_old)["any_limbo"]),
    formatC(coef(m_new)["any_limbo"], format = "f", digits = 4),
    stars(pvalue(m_new)["any_limbo"])),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
    formatC(se(m_het)["any_limbo"], format = "f", digits = 4),
    formatC(se(m_old)["any_limbo"], format = "f", digits = 4),
    formatC(se(m_new)["any_limbo"], format = "f", digits = 4))
)

# Add interaction term if present
if ("any_limbo:reg_intensive" %in% names(coef(m_het))) {
  tab5_lines <- c(tab5_lines,
    sprintf("Limbo $\\times$ regulated sector & %s%s & & \\\\",
      formatC(coef(m_het)["any_limbo:reg_intensive"], format = "f", digits = 4),
      stars(pvalue(m_het)["any_limbo:reg_intensive"])),
    sprintf(" & (%s) & & \\\\",
      formatC(se(m_het)["any_limbo:reg_intensive"], format = "f", digits = 4))
  )
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  sprintf("Observations & %s & %s & %s \\\\",
    format(nobs(m_het), big.mark = ","),
    format(nobs(m_old), big.mark = ","),
    format(nobs(m_new), big.mark = ",")),
  "Full FE set & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize",
  "\\textit{Notes:} Dependent variable: log firm births. Column (1) interacts the limbo indicator with a dummy for regulated sectors (Finance, Energy, Health, Transport). Columns (2)--(3) split the sample into EU-15 founding/early members and newer accession states. All specifications include country $\\times$ sector and year fixed effects. Standard errors clustered at the country level.",
  "}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_het.tex")
cat("Table 5 written.\n")

# ===================================================================
# TABLE F1: Standardized Effect Sizes (SDE — Mandatory Appendix)
# ===================================================================
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

pre_sd <- results$pre_sd_log_births

# Compute SDE for main outcomes
sde_rows <- list()

# Row 1: Log firm births (binary treatment)
b1 <- coef(results$m1)["any_limbo"]
se1 <- se(results$m1)["any_limbo"]
sde1 <- b1 / pre_sd
se_sde1 <- se1 / pre_sd
class1 <- case_when(
  sde1 < -0.15 ~ "Large negative",
  sde1 < -0.05 ~ "Moderate negative",
  sde1 < -0.005 ~ "Small negative",
  sde1 <= 0.005 ~ "Null",
  sde1 <= 0.05 ~ "Small positive",
  sde1 <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rows[[1]] <- list(
  outcome = "Log firm births",
  b = b1, se = se1, sd_y = pre_sd,
  sde = sde1, se_sde = se_sde1, class = class1
)

# Row 2: Birth rate (levels)
pre_sd_br <- results$pre_sd_birth_rate
b4 <- coef(results$m4)["any_limbo"]
se4 <- se(results$m4)["any_limbo"]
sde4 <- b4 / pre_sd_br
se_sde4 <- se4 / pre_sd_br
class4 <- case_when(
  sde4 < -0.15 ~ "Large negative",
  sde4 < -0.05 ~ "Moderate negative",
  sde4 < -0.005 ~ "Small negative",
  sde4 <= 0.005 ~ "Null",
  sde4 <= 0.05 ~ "Small positive",
  sde4 <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rows[[2]] <- list(
  outcome = "Birth rate (\\%)",
  b = b4, se = se4, sd_y = pre_sd_br,
  sde = sde4, se_sde = se_sde4, class = class4
)

# Row 3: Log active enterprises
pre_sd_active <- sd(df$log_active[df$any_limbo == 0], na.rm = TRUE)
b5 <- coef(results$m5)["any_limbo"]
se5 <- se(results$m5)["any_limbo"]
sde5 <- b5 / pre_sd_active
se_sde5 <- se5 / pre_sd_active
class5 <- case_when(
  sde5 < -0.15 ~ "Large negative",
  sde5 < -0.05 ~ "Moderate negative",
  sde5 < -0.005 ~ "Small negative",
  sde5 <= 0.005 ~ "Null",
  sde5 <= 0.05 ~ "Small positive",
  sde5 <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rows[[3]] <- list(
  outcome = "Log active enterprises",
  b = b5, se = se5, sd_y = pre_sd_active,
  sde = sde5, se_sde = se_sde5, class = class5
)

# ---- Panel B: Heterogeneity (sample splits) ----
# Split: Regulated vs non-regulated sectors
df$reg_intensive <- as.integer(df$nace_section %in% c("K", "D", "Q", "H"))

m_reg <- feols(
  log_births ~ any_limbo | cs_id + year,
  data = df %>% filter(reg_intensive == 1),
  cluster = ~country2
)

m_nonreg <- feols(
  log_births ~ any_limbo | cs_id + year,
  data = df %>% filter(reg_intensive == 0),
  cluster = ~country2
)

pre_sd_reg <- sd(df$log_births[df$any_limbo == 0 & df$reg_intensive == 1], na.rm = TRUE)
pre_sd_nonreg <- sd(df$log_births[df$any_limbo == 0 & df$reg_intensive == 0], na.rm = TRUE)

b_reg <- coef(m_reg)["any_limbo"]
se_reg_val <- se(m_reg)["any_limbo"]
sde_reg <- b_reg / pre_sd_reg
se_sde_reg <- se_reg_val / pre_sd_reg
class_reg <- case_when(
  sde_reg < -0.15 ~ "Large negative",
  sde_reg < -0.05 ~ "Moderate negative",
  sde_reg < -0.005 ~ "Small negative",
  sde_reg <= 0.005 ~ "Null",
  sde_reg <= 0.05 ~ "Small positive",
  sde_reg <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

b_nonreg <- coef(m_nonreg)["any_limbo"]
se_nonreg_val <- se(m_nonreg)["any_limbo"]
sde_nonreg <- b_nonreg / pre_sd_nonreg
se_sde_nonreg <- se_nonreg_val / pre_sd_nonreg
class_nonreg <- case_when(
  sde_nonreg < -0.15 ~ "Large negative",
  sde_nonreg < -0.05 ~ "Moderate negative",
  sde_nonreg < -0.005 ~ "Small negative",
  sde_nonreg <= 0.005 ~ "Null",
  sde_nonreg <= 0.05 ~ "Small positive",
  sde_nonreg <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rows[[4]] <- list(
  outcome = "Log births (regulated sectors)",
  b = b_reg, se = se_reg_val, sd_y = pre_sd_reg,
  sde = sde_reg, se_sde = se_sde_reg, class = class_reg
)

sde_rows[[5]] <- list(
  outcome = "Log births (non-regulated sectors)",
  b = b_nonreg, se = se_nonreg_val, sd_y = pre_sd_nonreg,
  sde = sde_nonreg, se_sde = se_sde_nonreg, class = class_nonreg
)

# Build SDE table
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Does late transposition of EU directives into national law suppress firm entry in affected sectors? ",
  "\\textbf{Policy mechanism:} EU directives set a transposition deadline by which member states must enact national legislation; ",
  "when the deadline passes without transposition, firms face regulatory uncertainty about which rules apply, raising the option value of delaying entry. ",
  "\\textbf{Outcome definition:} Log of firm births (new enterprise registrations) from Eurostat Business Demography, measured at the country--NACE-section--year level; birth rate is births per 100 active enterprises. ",
  "\\textbf{Treatment:} Binary indicator equal to one when at least one directive affecting a sector has passed its transposition deadline without the member state notifying national measures. ",
  "\\textbf{Data:} CELLAR SPARQL (directive transposition records) and Eurostat bd\\_enace2\\_r3 (business demography), 2008--2022, country $\\times$ NACE section $\\times$ year. ",
  "\\textbf{Method:} Two-way fixed effects with country $\\times$ sector and year fixed effects; standard errors clustered at the country level; wild cluster bootstrap (Webb weights, 9,999 iterations). ",
  "\\textbf{Sample:} EU-27 member states, NACE sections mapped to directive subject areas via keyword classification of EUR-Lex titles. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (i in 1:3) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome,
    formatC(r$b, format = "f", digits = 4),
    formatC(r$se, format = "f", digits = 4),
    formatC(r$sd_y, format = "f", digits = 3),
    formatC(r$sde, format = "f", digits = 4),
    formatC(r$se_sde, format = "f", digits = 4),
    r$class
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\",
  "\\addlinespace"
)

for (i in 4:5) {
  r <- sde_rows[[i]]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome,
    formatC(r$b, format = "f", digits = 4),
    formatC(r$se, format = "f", digits = 4),
    formatC(r$sd_y, format = "f", digits = 3),
    formatC(r$sde, format = "f", digits = 4),
    formatC(r$se_sde, format = "f", digits = 4),
    r$class
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize",
  sde_notes,
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
