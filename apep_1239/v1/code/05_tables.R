# 05_tables.R — apep_1239: Swiss NFA Reform
# Generate all LaTeX tables for paper

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(paste0(data_dir, "analysis_panel.rds"))
models <- readRDS(paste0(data_dir, "models.rds"))
robustness <- readRDS(paste0(data_dir, "robustness.rds"))
nfa <- readRDS(paste0(data_dir, "nfa_transfers.rds"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("Generating Table 1: Summary Statistics...\n")

# Pre-period (2000-2007) stats by NFA group
pre_stats <- panel %>%
  filter(year < 2008) %>%
  group_by(nfa_status) %>%
  summarise(
    `N canton-years` = n(),
    `Population (mean)` = mean(population, na.rm = TRUE),
    `In-migration rate` = mean(in_migration_rate, na.rm = TRUE),
    `Net migration rate` = mean(net_migration_rate, na.rm = TRUE),
    `Resource index` = mean(resource_index_2008, na.rm = TRUE),
    .groups = "drop"
  )

# Full panel stats
full_vars <- panel %>%
  summarise(
    Variable = "Full sample",
    N = n(),
    Mean = NA_real_,
    SD = NA_real_,
    Min = NA_real_,
    Max = NA_real_
  )

var_list <- c("population", "in_migration", "out_migration", "net_migration",
              "net_migration_rate", "in_migration_rate", "transfer_intensity")
var_labels <- c("Population", "In-migration (count)", "Out-migration (count)",
                "Net migration (count)", "Net migration rate (\\textperthousand)",
                "In-migration rate (\\textperthousand)", "Transfer intensity")

stats_rows <- list()
for (i in seq_along(var_list)) {
  v <- var_list[i]
  vals <- panel[[v]]
  stats_rows[[i]] <- sprintf(
    "%s & %s & %.1f & %.1f & %.1f & %.1f \\\\",
    var_labels[i], format(length(vals), big.mark = ","),
    mean(vals, na.rm = TRUE), sd(vals, na.rm = TRUE),
    min(vals, na.rm = TRUE), max(vals, na.rm = TRUE)
  )
}

# Pre-period balance by group
balance_rows <- list()
groups <- c("recipient", "near_zero", "payer")
group_labels <- c("Recipient", "Near-zero", "Payer")

for (i in seq_along(groups)) {
  g <- groups[i]
  grp_data <- panel %>% filter(year < 2008, nfa_status == g)
  balance_rows[[i]] <- sprintf(
    "%s & %d & %.0f & %.1f & %.1f & %.1f \\\\",
    group_labels[i],
    n_distinct(grp_data$canton_code),
    mean(grp_data$population, na.rm = TRUE),
    mean(grp_data$in_migration_rate, na.rm = TRUE),
    mean(grp_data$net_migration_rate, na.rm = TRUE),
    mean(grp_data$resource_index_2008, na.rm = TRUE)
  )
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{7}{l}{\\textit{Panel A: Full Sample (26 cantons $\\times$ 24 years = 624 canton-years)}} \\\\[3pt]",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\hline",
  paste(stats_rows, collapse = "\n"),
  "\\\\[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Pre-Reform Balance (2000--2007)}} \\\\[3pt]",
  "NFA Group & Cantons & Mean pop. & In-mig. rate & Net mig. rate & Resource index \\\\",
  "\\hline",
  paste(balance_rows, collapse = "\n"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Migration rates are per 1,000 residents. Transfer intensity equals $100 - \\text{Resource Index}_{2008}$; positive values indicate net recipients. Resource index based on 2003--2005 cantonal tax potential (EFV). Recipients: index $\\leq 90$; payers: index $\\geq 110$; near-zero: $90$--$110$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, paste0(tables_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main Results
# ============================================================

cat("Generating Table 2: Main Results...\n")

# Extract coefficients from models
extract_row <- function(model, varname, label) {
  cf <- coef(model)[varname]
  se_val <- se(model)[varname]
  pv <- pvalue(model)[varname]
  stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.10, "^{*}", "")))
  sprintf("%s & $%.4f%s$ & & \\\\", label, cf, stars)
}

extract_se <- function(model, varname) {
  se_val <- se(model)[varname]
  sprintf(" & ($%.4f$) & & \\\\", se_val)
}

m1 <- models$m1  # Baseline
m2 <- models$m2  # Canton trends
m3 <- models$m3  # In-migration
m4 <- models$m4  # Log population
m5 <- models$m5  # Binary treatment

# Build main results table
get_cell <- function(model, varname) {
  cf <- coef(model)[varname]
  se_val <- se(model)[varname]
  pv <- pvalue(model)[varname]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  list(coef = sprintf("$%.4f%s$", cf, paste0("^{", stars, "}")),
       se = sprintf("($%.4f$)", se_val))
}

# Extract all cells
c1 <- get_cell(m1, "treat_cont")
c2 <- get_cell(m2, "treat_cont")
c3 <- get_cell(m3, "treat_cont")
c4 <- get_cell(m4, "treat_cont")

# Binary treatment (m5)
c5_name <- names(coef(m5))[grepl("is_recipient", names(coef(m5)))]
c5 <- get_cell(m5, c5_name[1])

# Model stats
n1 <- nobs(m1); n2 <- nobs(m2); n3 <- nobs(m3); n4 <- nobs(m4); n5 <- nobs(m5)
r1 <- sprintf("%.3f", r2(m1, "ar2")); r2_val <- sprintf("%.3f", r2(m2, "ar2"))
r3 <- sprintf("%.3f", r2(m3, "ar2")); r4 <- sprintf("%.3f", r2(m4, "ar2"))
r5 <- sprintf("%.3f", r2(m5, "ar2"))

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{NFA Transfer Intensity and Inter-Cantonal Migration}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  " & \\multicolumn{4}{c}{Continuous Treatment} & Binary \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-6}",
  " & Net mig. & Net mig. & In-mig. & Log & Net mig. \\\\",
  " & rate & rate & rate & pop. & rate \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline",
  sprintf("Transfer intensity $\\times$ Post & %s & %s & %s & %s & \\\\",
          c1$coef, c2$coef, c3$coef, c4$coef),
  sprintf(" & %s & %s & %s & %s & \\\\", c1$se, c2$se, c3$se, c4$se),
  sprintf("Recipient $\\times$ Post & & & & & %s \\\\", c5$coef),
  sprintf(" & & & & & %s \\\\", c5$se),
  "\\hline",
  "Canton FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Canton trends & No & Yes & No & No & No \\\\"),
  sprintf("Observations & %d & %d & %d & %d & %d \\\\", n1, n2, n3, n4, n5),
  sprintf("Adj.\\ $R^2$ & %s & %s & %s & %s & %s \\\\", r1, r2_val, r3, r4, r5),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a two-way fixed effects regression. Transfer intensity equals $100 - \\text{Resource Index}_{2008}$, interacted with a post-2008 indicator. Migration rates are per 1,000 residents. Standard errors clustered by canton in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, paste0(tables_dir, "tab2_main.tex"))

# ============================================================
# TABLE 3: Robustness
# ============================================================

cat("Generating Table 3: Robustness...\n")

# Collect all robustness coefficients
rob_specs <- tibble(
  Specification = character(),
  Coefficient = character(),
  SE = character(),
  N = integer(),
  stringsAsFactors = FALSE
)

# Main result
main_cf <- coef(models$m1)["treat_cont"]
main_se <- se(models$m1)["treat_cont"]
main_pv <- pvalue(models$m1)["treat_cont"]
main_stars <- ifelse(main_pv < 0.01, "^{***}", ifelse(main_pv < 0.05, "^{**}",
                     ifelse(main_pv < 0.10, "^{*}", "")))

# Placebo results
p04 <- robustness$placebo[["2004"]]
p06 <- robustness$placebo[["2006"]]

# Other robustness
wins_cf <- coef(robustness$m_wins)["treat_cont"]
wins_se <- se(robustness$m_wins)["treat_cont"]
wins_pv <- pvalue(robustness$m_wins)["treat_cont"]

wpop_cf <- coef(robustness$m_wpop)["treat_cont"]
wpop_se <- se(robustness$m_wpop)["treat_cont"]
wpop_pv <- pvalue(robustness$m_wpop)["treat_cont"]

short_cf <- coef(robustness$m_short)["treat_cont"]
short_se <- se(robustness$m_short)["treat_cont"]
short_pv <- pvalue(robustness$m_short)["treat_cont"]

make_stars <- function(p) {
  ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
}

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "Specification & Coefficient & SE & $p$-value & $N$ \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{5}{l}{\\textit{Panel A: Main and Alternative Specifications}} \\\\[3pt]",
  sprintf("Baseline (Table~\\ref{tab:main}, col.\\ 1) & $%.4f%s$ & $%.4f$ & $%.3f$ & %d \\\\",
          main_cf, main_stars, main_se, main_pv, nobs(models$m1)),
  sprintf("Winsorized (1\\%%--99\\%%) & $%.4f%s$ & $%.4f$ & $%.3f$ & %d \\\\",
          wins_cf, make_stars(wins_pv), wins_se, wins_pv, nobs(robustness$m_wins)),
  sprintf("Population-weighted & $%.4f%s$ & $%.4f$ & $%.3f$ & %d \\\\",
          wpop_cf, make_stars(wpop_pv), wpop_se, wpop_pv, nobs(robustness$m_wpop)),
  sprintf("Short post-period (2008--2015) & $%.4f%s$ & $%.4f$ & $%.3f$ & %d \\\\",
          short_cf, make_stars(short_pv), short_se, short_pv, nobs(robustness$m_short)),
  "\\\\[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Placebo Tests}} \\\\[3pt]",
  sprintf("Placebo cutoff: 2004 & $%.4f%s$ & $%.4f$ & $%.3f$ & %d \\\\",
          p04$coef, make_stars(p04$pval), p04$se, p04$pval,
          nrow(panel %>% filter(year < 2008))),
  sprintf("Placebo cutoff: 2006 & $%.4f%s$ & $%.4f$ & $%.3f$ & %d \\\\",
          p06$coef, make_stars(p06$pval), p06$se, p06$pval,
          nrow(panel %>% filter(year < 2008))),
  "\\\\[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel C: Inference}} \\\\[3pt]",
  sprintf("Randomization inference $p$-value & \\multicolumn{4}{c}{$%.3f$ (1{,}000 permutations)} \\\\",
          robustness$ri_pval),
  sprintf("Leave-one-out range & \\multicolumn{4}{c}{$[%.4f,\\, %.4f]$} \\\\",
          min(robustness$loo$coef), max(robustness$loo$coef)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include canton and year fixed effects with standard errors clustered by canton. Placebo tests use pre-reform data only (2000--2007). Randomization inference permutes transfer intensity across cantons 1{,}000 times. Leave-one-out reports the range of coefficients when each canton is dropped in turn. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, paste0(tables_dir, "tab3_robustness.tex"))

# ============================================================
# TABLE 4: Event Study Coefficients
# ============================================================

cat("Generating Table 4: Event Study...\n")

# Parse event study coefficients: names like "event_time::-8:transfer_intensity"
es_names <- names(coef(models$es1))
es_times <- as.integer(gsub("event_time::([-0-9]+):transfer_intensity", "\\1", es_names))

es_coefs <- tibble(
  event_time = es_times,
  coef = as.numeric(coef(models$es1)),
  se = as.numeric(se(models$es1)),
  pval = as.numeric(pvalue(models$es1))
) %>%
  filter(!is.na(event_time)) %>%
  arrange(event_time) %>%
  mutate(stars = make_stars(pval))

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study Coefficients: NFA Transfer Intensity and Net Migration Rate}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "Year relative to NFA & Coefficient & SE & $p$-value \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_coefs))) {
  r <- es_coefs[i, ]
  if (r$event_time == -1) {
    tab4 <- c(tab4, sprintf("$k = %d$ (reference) & --- & --- & --- \\\\", r$event_time))
  } else {
    tab4 <- c(tab4, sprintf("$k = %+d$ & $%.4f%s$ & $%.4f$ & $%.3f$ \\\\",
                            r$event_time, r$coef, r$stars, r$se, r$pval))
  }
}

# Add pre-trend test
pre_test <- wald(models$es1, "event_time::-")
tab4 <- c(tab4,
  "\\hline",
  sprintf("Joint pre-trend $F$-test & \\multicolumn{3}{c}{$F = %.2f$, $p = %.3f$} \\\\",
          pre_test$stat, pre_test$p),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each coefficient is from a regression of net migration rate (per 1{,}000) on interactions of transfer intensity with event-time indicators, with canton and year fixed effects. Reference period: $k = -1$ (2007). Standard errors clustered by canton. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, paste0(tables_dir, "tab4_eventstudy.tex"))

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — APPENDIX
# ============================================================

cat("Generating Table F1: Standardized Effect Sizes...\n")

# Compute pre-treatment SD of outcomes
pre_data <- panel %>% filter(year < 2008)
sd_net_mig <- sd(pre_data$net_migration_rate, na.rm = TRUE)
sd_in_mig <- sd(pre_data$in_migration_rate, na.rm = TRUE)
sd_log_pop <- sd(pre_data$log_pop, na.rm = TRUE)

# SD of treatment (transfer intensity)
sd_treat <- sd(panel$transfer_intensity)

# Main outcomes — continuous treatment: SDE = beta * SD(X) / SD(Y)
beta_net <- coef(models$m1)["treat_cont"]
se_net <- se(models$m1)["treat_cont"]
sde_net <- beta_net * sd_treat / sd_net_mig
se_sde_net <- se_net * sd_treat / sd_net_mig

beta_in <- coef(models$m3)["treat_cont"]
se_in <- se(models$m3)["treat_cont"]
sde_in <- beta_in * sd_treat / sd_in_mig
se_sde_in <- se_in * sd_treat / sd_in_mig

beta_pop <- coef(models$m4)["treat_cont"]
se_pop <- se(models$m4)["treat_cont"]
sde_pop <- beta_pop * sd_treat / sd_log_pop
se_sde_pop <- se_pop * sd_treat / sd_log_pop

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Panel A: Pooled
pooled_rows <- list(
  sprintf("Net migration rate & $%.4f$ & $%.4f$ & $%.2f$ & $%.3f$ & $%.3f$ & %s \\\\",
          beta_net, se_net, sd_net_mig, sde_net, se_sde_net, classify_sde(sde_net)),
  sprintf("In-migration rate & $%.4f$ & $%.4f$ & $%.2f$ & $%.3f$ & $%.3f$ & %s \\\\",
          beta_in, se_in, sd_in_mig, sde_in, se_sde_in, classify_sde(sde_in)),
  sprintf("Log population & $%.6f$ & $%.6f$ & $%.4f$ & $%.3f$ & $%.3f$ & %s \\\\",
          beta_pop, se_pop, sd_log_pop, sde_pop, se_sde_pop, classify_sde(sde_pop))
)

# Panel B: Heterogeneity — by language region
german_cantons <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)
french_cantons <- c(10, 22, 23, 24, 25, 26)  # FR, VD, VS, NE, GE, JU

panel_german <- panel %>% filter(canton_code %in% german_cantons)
panel_french <- panel %>% filter(canton_code %in% french_cantons)

m_german <- feols(net_migration_rate ~ treat_cont | canton_f + year_f,
                  data = panel_german, cluster = ~canton_f)
m_french <- feols(net_migration_rate ~ treat_cont | canton_f + year_f,
                  data = panel_french, cluster = ~canton_f)

sd_german <- sd(panel_german$net_migration_rate[panel_german$year < 2008], na.rm = TRUE)
sd_french <- sd(panel_french$net_migration_rate[panel_french$year < 2008], na.rm = TRUE)

sde_german <- coef(m_german)["treat_cont"] * sd_treat / sd_german
se_sde_german <- se(m_german)["treat_cont"] * sd_treat / sd_german

sde_french <- coef(m_french)["treat_cont"] * sd_treat / sd_french
se_sde_french <- se(m_french)["treat_cont"] * sd_treat / sd_french

het_rows <- list(
  sprintf("German-speaking cantons & $%.4f$ & $%.4f$ & $%.2f$ & $%.3f$ & $%.3f$ & %s \\\\",
          coef(m_german)["treat_cont"], se(m_german)["treat_cont"],
          sd_german, sde_german, se_sde_german, classify_sde(sde_german)),
  sprintf("French-speaking cantons & $%.4f$ & $%.4f$ & $%.2f$ & $%.3f$ & $%.3f$ & %s \\\\",
          coef(m_french)["treat_cont"], se(m_french)["treat_cont"],
          sd_french, sde_french, se_sde_french, classify_sde(sde_french))
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does replacing conditional earmarked federal transfers with unconditional block grants alter inter-cantonal population sorting? ",
  "\\textbf{Policy mechanism:} The 2008 NFA reform abolished the 1959 system of earmarked federal-cantonal cost sharing and replaced it with formula-based unconditional equalization transfers (Ressourcenausgleich and Lastenausgleich), redistributing CHF 3.5--4 billion annually based on standardized cantonal tax potential. ",
  "\\textbf{Outcome definition:} Net inter-cantonal migration rate per 1{,}000 permanent residents, measuring the balance of in-flows from and out-flows to other Swiss cantons within the same calendar year. ",
  "\\textbf{Treatment:} Continuous; transfer intensity defined as $100 - \\text{Resource Index}_{2008}$, measuring each canton's distance from the equalization threshold based on predetermined 2003--2005 tax potential. ",
  "\\textbf{Data:} BFS PXWeb demographic balance (px-x-0102020000\\_101), 26 cantons, 2000--2023, 624 canton-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (canton + year) with continuous treatment intensity interacted with post-2008 indicator; standard errors clustered by canton; robustness via randomization inference (1{,}000 permutations) and leave-one-out. ",
  "\\textbf{Sample:} All 26 Swiss cantons; no exclusions. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the cross-sectional standard deviation of transfer intensity. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  paste(pooled_rows, collapse = "\n"),
  "\\\\[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Language Region)}} \\\\[3pt]",
  paste(het_rows, collapse = "\n"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, paste0(tables_dir, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
for (f in list.files(tables_dir, pattern = "\\.tex$")) {
  cat(sprintf("  %s\n", f))
}
