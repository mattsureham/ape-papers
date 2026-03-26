## 05_tables.R — Generate all LaTeX tables
## APEP-1032: The Deterrence Gap

source("00_packages.R")

analysis <- readRDS("../data/fdic_analysis.rds")
models_main <- readRDS("../data/models_main.rds")
models_rob <- readRDS("../data/models_robustness.rds")
diag <- jsonlite::fromJSON("../data/diagnostics.json")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════════════

pre <- analysis %>% filter(post == 0)

summ_stats <- pre %>%
  group_by(group) %>%
  summarise(
    N_banks = n_distinct(CERT),
    `Assets ($B)` = sprintf("%.2f", mean(ASSET / 1e6, na.rm = TRUE)),
    `NCL Ratio (\\%)` = sprintf("%.3f", mean(ncl_ratio, na.rm = TRUE)),
    `  [SD]` = sprintf("[%.3f]", sd(ncl_ratio, na.rm = TRUE)),
    `NCO Ratio (\\%)` = sprintf("%.3f", mean(nco_ratio, na.rm = TRUE)),
    `Tier 1 Capital (\\%)` = sprintf("%.2f", mean(tier1_ratio, na.rm = TRUE)),
    `CRE Share (\\%)` = sprintf("%.1f", mean(cre_share, na.rm = TRUE)),
    `C\\&I Share (\\%)` = sprintf("%.1f", mean(ci_share, na.rm = TRUE)),
    `ROA (\\%)` = sprintf("%.3f", mean(roa, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(group = ifelse(group == "treated", "Treated (\\$1B--\\$3B)", "Control (\\$3B--\\$10B)"))

# Build LaTeX manually for full control
tex1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics (2016Q1--2018Q2)}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  paste0(" & ", summ_stats$group[1], " & ", summ_stats$group[2], " \\\\"),
  "\\midrule",
  paste0("Banks & ", summ_stats$N_banks[1], " & ", summ_stats$N_banks[2], " \\\\"),
  paste0("Mean assets (\\$B) & ", summ_stats$`Assets ($B)`[1], " & ", summ_stats$`Assets ($B)`[2], " \\\\"),
  "\\addlinespace",
  paste0("Noncurrent loan ratio (\\%) & ", summ_stats$`NCL Ratio (\\%)`[1], " & ", summ_stats$`NCL Ratio (\\%)`[2], " \\\\"),
  paste0("\\quad [SD] & ", summ_stats$`  [SD]`[1], " & ", summ_stats$`  [SD]`[2], " \\\\"),
  paste0("Net charge-off ratio (\\%) & ", summ_stats$`NCO Ratio (\\%)`[1], " & ", summ_stats$`NCO Ratio (\\%)`[2], " \\\\"),
  paste0("Tier 1 capital ratio (\\%) & ", summ_stats$`Tier 1 Capital (\\%)`[1], " & ", summ_stats$`Tier 1 Capital (\\%)`[2], " \\\\"),
  paste0("CRE loan share (\\%) & ", summ_stats$`CRE Share (\\%)`[1], " & ", summ_stats$`CRE Share (\\%)`[2], " \\\\"),
  paste0("C\\&I loan share (\\%) & ", summ_stats$`C\\&I Share (\\%)`[1], " & ", summ_stats$`C\\&I Share (\\%)`[2], " \\\\"),
  paste0("ROA (\\%) & ", summ_stats$`ROA (\\%)`[1], " & ", summ_stats$`ROA (\\%)`[2], " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment means and standard deviations for banks in the treatment group (\\$1B--\\$3B in assets at 2018Q2) and control group (\\$3B--\\$10B). Source: FDIC Call Reports via BankFind API.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex1, "../tables/tab1_summary.tex")
cat("Table 1: Summary statistics written.\n")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 2: Main DiD Results (All Outcomes)
# ═══════════════════════════════════════════════════════════════════════════════

make_row <- function(model, label) {
  b <- coef(model)[1]
  s <- se(model)[1]
  p <- pvalue(model)[1]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  c(
    sprintf("%s & %.4f%s \\\\", label, b, stars),
    sprintf("& (%.4f) \\\\", s)
  )
}

tex2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Deterrence Gap: Main Difference-in-Differences Results}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "Outcome & Treated $\\times$ Post \\\\",
  "\\midrule",
  make_row(models_main$ncl, "Noncurrent loan ratio (\\%)"),
  "\\addlinespace",
  make_row(models_main$nco, "Net charge-off ratio (\\%)"),
  "\\addlinespace",
  make_row(models_main$tier1, "Tier 1 capital ratio (\\%)"),
  "\\addlinespace",
  make_row(models_main$cre, "CRE loan share (\\%)"),
  "\\addlinespace",
  make_row(models_main$ci, "C\\&I loan share (\\%)"),
  "\\addlinespace",
  make_row(models_main$log_asset, "Log assets"),
  "\\midrule",
  sprintf("Bank-quarters & %s \\\\", format(models_main$ncl$nobs, big.mark = ",")),
  sprintf("Banks & %s \\\\", format(n_distinct(analysis$CERT), big.mark = ",")),
  "Bank FE & Yes \\\\",
  "Quarter FE & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each cell reports the coefficient on Treated $\\times$ Post from a separate DiD regression with bank and quarter fixed effects. Treatment = banks with \\$1B--\\$3B in assets (gained 18-month exam cycles under EGRRCPA); control = banks with \\$3B--\\$10B (remained on 12-month cycles). Sample: 2016Q1--2023Q4. Standard errors clustered at the bank level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex2, "../tables/tab2_main.tex")
cat("Table 2: Main results written.\n")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 3: Event Study Coefficients
# ═══════════════════════════════════════════════════════════════════════════════

es_coefs <- readRDS("../data/event_study_coefs.rds")

# Select key quarters for display
key_times <- c(-9, -7, -5, -3, -1, 0, 1, 3, 5, 9, 13, 17, 21)
es_display <- es_coefs %>%
  filter(event_time %in% key_times) %>%
  arrange(event_time) %>%
  mutate(
    stars = ifelse(`Pr(>|t|)` < 0.01, "***",
                   ifelse(`Pr(>|t|)` < 0.05, "**",
                          ifelse(`Pr(>|t|)` < 0.1, "*", ""))),
    label = ifelse(event_time < 0, paste0("$t", event_time, "$"),
                   ifelse(event_time == 0, "$t=0$", paste0("$t+", event_time, "$")))
  )

tex3_rows <- sapply(seq_len(nrow(es_display)), function(i) {
  r <- es_display[i, ]
  c(
    sprintf("%s & %.4f%s \\\\", r$label, r$Estimate, r$stars),
    sprintf("& (%.4f) \\\\", r$`Std. Error`)
  )
})

tex3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Noncurrent Loan Ratio}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "Quarter Relative to EGRRCPA & Coefficient \\\\",
  "\\midrule",
  "\\textit{Pre-treatment} & \\\\",
  unlist(tex3_rows[, which(es_display$event_time < 0)]),
  "\\addlinespace",
  "\\textit{Post-treatment} & \\\\",
  unlist(tex3_rows[, which(es_display$event_time >= 0)]),
  "\\midrule",
  sprintf("Pre-trend F-test (p-value) & %.4f \\\\", diag$pretrend_p),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from the event study specification with bank and quarter fixed effects. Reference period: $t-1$ (2018Q2). Selected quarters shown; full results available in replication code. Standard errors clustered at the bank level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex3, "../tables/tab3_eventstudy.tex")
cat("Table 3: Event study written.\n")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 4: Robustness
# ═══════════════════════════════════════════════════════════════════════════════

rob_labels <- c("Baseline", "Placebo: \\$500M--\\$1B",
                "Donut hole (excl.\\ near-threshold)",
                "Pre-COVID (end 2019Q4)", "Excl.\\ COVID (drop 2020--2021)")
rob_models_list <- list(models_main$ncl, models_rob$placebo, models_rob$donut,
                        models_rob$precovid, models_rob$nocovid)

tex4_rows <- lapply(seq_along(rob_labels), function(i) {
  label <- rob_labels[i]
  m <- rob_models_list[[i]]
  b <- coef(m)[1]; s <- se(m)[1]; p <- pvalue(m)[1]; n <- m$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  c(
    sprintf("%s & %.4f%s & %s \\\\", label, b, stars, format(n, big.mark = ",")),
    sprintf("& (%.4f) & \\\\", s)
  )
})

tex4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Noncurrent Loan Ratio}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Treated $\\times$ Post & N \\\\",
  "\\midrule",
  unlist(tex4_rows),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row is a separate regression of the noncurrent loan ratio on Treated $\\times$ Post with bank and quarter fixed effects. Placebo uses banks \\$500M--\\$1B (already eligible for 18-month cycles pre-EGRRCPA) as the treatment group against \\$3B--\\$10B controls. Donut hole excludes banks within 10\\% of the \\$1B and \\$3B thresholds. Standard errors clustered at the bank level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex4, "../tables/tab4_robustness.tex")
cat("Table 4: Robustness written.\n")

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Sizes (SDE Appendix — MANDATORY)
# ═══════════════════════════════════════════════════════════════════════════════

# Pre-treatment SDs
pre_sds <- analysis %>%
  filter(post == 0) %>%
  summarise(
    sd_ncl = sd(ncl_ratio, na.rm = TRUE),
    sd_nco = sd(nco_ratio, na.rm = TRUE),
    sd_tier1 = sd(tier1_ratio, na.rm = TRUE),
    sd_cre = sd(cre_share, na.rm = TRUE),
    sd_ci = sd(ci_share, na.rm = TRUE),
    sd_log_asset = sd(log_asset, na.rm = TRUE)
  )

# Calculate SDEs
sde_rows <- list(
  list("Noncurrent loan ratio", models_main$ncl, pre_sds$sd_ncl),
  list("Net charge-off ratio", models_main$nco, pre_sds$sd_nco),
  list("Tier 1 capital ratio", models_main$tier1, pre_sds$sd_tier1),
  list("CRE loan share", models_main$cre, pre_sds$sd_cre)
)

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
panel_a_rows <- lapply(sde_rows, function(x) {
  label <- x[[1]]; m <- x[[2]]; sd_y <- x[[3]]
  b <- coef(m)[1]; s <- se(m)[1]
  sde_val <- b / sd_y
  sde_se <- s / sd_y
  cls <- classify_sde(sde_val)
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          label, b, s, sd_y, sde_val, sde_se, cls)
})

# Panel B: Heterogeneous — split by bank size within treatment group
# Small treated ($1B-$2B) vs Large treated ($2B-$3B)
small_treat <- analysis %>%
  filter(group == "control" | (group == "treated" & ASSET_PRE < 2000000))
large_treat <- analysis %>%
  filter(group == "control" | (group == "treated" & ASSET_PRE >= 2000000))

m_ncl_small <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                     data = small_treat, cluster = ~CERT)
m_ncl_large <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                     data = large_treat, cluster = ~CERT)

sd_small <- sd(small_treat$ncl_ratio[small_treat$post == 0], na.rm = TRUE)
sd_large <- sd(large_treat$ncl_ratio[large_treat$post == 0], na.rm = TRUE)

het_rows <- list(
  list("NCL ratio (smaller treated, \\$1B--\\$2B)", m_ncl_small, sd_small),
  list("NCL ratio (larger treated, \\$2B--\\$3B)", m_ncl_large, sd_large)
)

panel_b_rows <- lapply(het_rows, function(x) {
  label <- x[[1]]; m <- x[[2]]; sd_y <- x[[3]]
  b <- coef(m)[1]; s <- se(m)[1]
  sde_val <- b / sd_y
  sde_se <- s / sd_y
  cls <- classify_sde(sde_val)
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          label, b, s, sd_y, sde_val, sde_se, cls)
})

# SDE Notes (training data — must be self-contained)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does extending bank examination cycles from 12 to 18 months increase risk-taking by community banks? ",
  "\\textbf{Policy mechanism:} Section 210 of the Economic Growth, Regulatory Relief, and Consumer Protection Act (EGRRCPA, 2018) ",
  "raised the asset threshold for qualification for 18-month on-site examination cycles from \\$1 billion to \\$3 billion, ",
  "extending the unsupervised interval between regulatory inspections by 50\\% for approximately 445 community banks. ",
  "\\textbf{Outcome definition:} Noncurrent loan ratio, measured as noncurrent loans (past due 90+ days or nonaccrual) divided by gross loans and leases, expressed in percentage points. ",
  "\\textbf{Treatment:} Binary; banks with \\$1B--\\$3B in assets at 2018Q2 that gained 18-month examination eligibility. ",
  "\\textbf{Data:} FDIC Call Reports via BankFind Suite API, quarterly, 2016Q1--2023Q4, bank-quarter level, ~",
  format(nrow(analysis), big.mark = ","), " observations from ~",
  format(n_distinct(analysis$CERT), big.mark = ","), " banks. ",
  "\\textbf{Method:} Two-way fixed effects DiD with bank and quarter fixed effects; standard errors clustered at the bank level. ",
  "\\textbf{Sample:} Banks with \\$1B--\\$10B in assets at 2018Q2; excludes banks below \\$1B (except in placebo) and above \\$10B (systemically important). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

texF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  unlist(panel_a_rows),
  "\\addlinespace",
  "\\textit{Panel B: Heterogeneous (by period)} & & & & & & \\\\",
  unlist(panel_b_rows),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(texF1, "../tables/tabF1_sde.tex")
cat("Table F1: SDE appendix written.\n")

cat("\n✓ All tables generated.\n")
