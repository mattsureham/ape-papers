## 05_tables.R — Generate all tables for paper

source("00_packages.R")

data_dir  <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "all_results.RData"))

# ── Helper: format coefficient with stars ───────────────────────────────────
fmt_coef <- function(fit, varname) {
  b <- coef(fit)[varname]; s <- se(fit)[varname]; p <- pvalue(fit)[varname]
  star <- if (p < 0.01) "^{***}" else if (p < 0.05) "^{**}" else if (p < 0.1) "^{*}" else ""
  list(coef = sprintf("%.2f%s", b, star), se = sprintf("(%.2f)", s))
}

# ── Table 1: Summary Statistics ─────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

vars <- list(
  list("stf_corp", "Corporate Steuerfuss (\\%)"),
  list("stf_nat",  "Natural-Person Steuerfuss (\\%)"),
  list("stf_corp_chg", "Corporate Rate Change (pp)"),
  list("total_exp_pc", "Total Func.\\ Expenditure p.c.\\ (CHF)"),
  list("education_pc", "Education Expenditure p.c.\\ (CHF)"),
  list("social_pc", "Social Security Exp.\\ p.c.\\ (CHF)"),
  list("transport_pc", "Transport/Infra.\\ Exp.\\ p.c.\\ (CHF)"),
  list("tax_revenue_pc", "Tax Revenue p.c.\\ (CHF)"),
  list("establishments", "Establishments"),
  list("employees", "Employees"),
  list("population", "Population")
)

sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics: Zurich Municipalities, 2012--2017}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lrrrrr}\n\\hline\\hline\n")
cat("Variable & Mean & SD & Min & Max & N \\\\\n\\hline\n")
for (v in vars) {
  x <- analysis_full[[v[[1]]]]
  x <- x[!is.na(x)]
  if (length(x) == 0) next
  cat(sprintf("%s & %.1f & %.1f & %.0f & %s & %s \\\\\n",
              v[[2]], mean(x), sd(x), min(x),
              format(max(x), big.mark = ","),
              format(length(x), big.mark = ",")))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Municipality-year panel, Canton Zurich. ")
cat("Corporate and natural-person Steuerfuss are municipal tax multipliers applied to the cantonal base rate (\\%). ")
cat("Functional expenditure categories from Jahresrechnungen (municipal financial accounts). ")
cat("All monetary values in Swiss Francs. Establishments and employees from BFS STATENT.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

# ── Table 2: Main Results ───────────────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

main_ys <- c("total_exp_pc", "education_pc", "social_pc", "transport_pc", "tax_revenue_pc")
main_labs <- c("Total Exp.", "Education", "Social Sec.", "Transport", "Tax Rev.")

sink(file.path(table_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Corporate Tax Multiplier and Municipal Spending}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccccc}\n\\hline\\hline\n")
cat(paste0("& ", paste(sprintf("(%d)", 1:5), collapse = " & "), " \\\\\n"))
cat(paste0("& ", paste(main_labs, collapse = " & "), " \\\\\n"))
cat("\\hline\n")

# Coefficients row
coefs <- sapply(main_ys, function(y) {
  if (y %in% names(results)) fmt_coef(results[[y]], "stf_corp")$coef else "---"
})
ses <- sapply(main_ys, function(y) {
  if (y %in% names(results)) fmt_coef(results[[y]], "stf_corp")$se else ""
})
cat(sprintf("Corporate Steuerfuss & %s \\\\\n", paste(coefs, collapse = " & ")))
cat(sprintf("& %s \\\\\n", paste(ses, collapse = " & ")))
cat("\\hline\n")

# Fixed effects
cat(sprintf("Municipality FE & %s \\\\\n", paste(rep("Yes", 5), collapse = " & ")))
cat(sprintf("Year FE & %s \\\\\n", paste(rep("Yes", 5), collapse = " & ")))
cat(sprintf("Pop.\\ growth control & %s \\\\\n", paste(rep("Yes", 5), collapse = " & ")))

# N, R2, dep mean
ns <- sapply(main_ys, function(y) {
  if (y %in% names(results)) format(results[[y]]$nobs, big.mark = ",") else "---"
})
r2s <- sapply(main_ys, function(y) {
  if (y %in% names(results)) sprintf("%.3f", fitstat(results[[y]], "r2")[[1]]) else "---"
})
means <- sapply(main_ys, function(y) {
  if (y %in% names(analysis_full)) sprintf("%.0f", mean(analysis_full[[y]], na.rm = TRUE)) else "---"
})
mdes <- sapply(main_ys, function(y) {
  if (y %in% names(results)) {
    m <- mean(analysis_full[[y]], na.rm = TRUE)
    sprintf("%.1f\\%%", 100 * 2.8 * se(results[[y]])["stf_corp"] * 10 / m)
  } else "---"
})

cat(sprintf("Observations & %s \\\\\n", paste(ns, collapse = " & ")))
cat(sprintf("$R^2$ & %s \\\\\n", paste(r2s, collapse = " & ")))
cat(sprintf("Dep.\\ var.\\ mean & %s \\\\\n", paste(means, collapse = " & ")))
cat(sprintf("MDE (10pp, \\%% mean) & %s \\\\\n", paste(mdes, collapse = " & ")))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Each column reports a separate regression of per-capita spending (CHF) ")
cat("on the corporate Steuerfuss (tax multiplier, \\%). Municipality and year fixed effects throughout. ")
cat("Standard errors clustered at the municipality level in parentheses. ")
cat("MDE: minimum detectable effect at 80\\% power for a 10 percentage point rate change, ")
cat("expressed as a share of the dependent variable mean. ")
cat("$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

# ── Table 3: Mechanism (Establishments + Employment) ────────────────────────
cat("Generating Table 3: Mechanism...\n")

sink(file.path(table_dir, "tab3_mechanism.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Tax Multiplier and Firm Entry}\n")
cat("\\label{tab:mechanism}\n")
cat("\\begin{tabular}{lcc}\n\\hline\\hline\n")
cat("& (1) & (2) \\\\\n")
cat("& log(Establishments) & log(Employees) \\\\\n\\hline\n")

for (key in c("establishments", "employment")) {
  if (key %in% names(results)) {
    cf <- fmt_coef(results[[key]], "stf_corp")
    lab <- ifelse(key == "establishments", "log(Estab.)", "log(Emp.)")
  }
}

e_cf <- fmt_coef(results[["establishments"]], "stf_corp")
m_cf <- fmt_coef(results[["employment"]], "stf_corp")
cat(sprintf("Corporate Steuerfuss & %s & %s \\\\\n", e_cf$coef, m_cf$coef))
cat(sprintf("& %s & %s \\\\\n", e_cf$se, m_cf$se))
cat("\\hline\n")
cat("Municipality FE & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes \\\\\n")
cat(sprintf("Observations & %s & %s \\\\\n",
            format(results[["establishments"]]$nobs, big.mark = ","),
            format(results[["employment"]]$nobs, big.mark = ",")))
cat(sprintf("$R^2$ & %.3f & %.3f \\\\\n",
            fitstat(results[["establishments"]], "r2")[[1]],
            fitstat(results[["employment"]], "r2")[[1]]))

# MDE for establishments
mde_estab <- 2.8 * se(results[["establishments"]])["stf_corp"] * 10 * 100
mde_emp <- 2.8 * se(results[["employment"]])["stf_corp"] * 10 * 100
cat(sprintf("MDE (10pp, \\%% $\\Delta$) & %.1f\\%% & %.1f\\%% \\\\\n", mde_estab, mde_emp))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Dependent variables are log(establishments$+$1) and log(employees$+$1) from BFS STATENT (2011--2023). ")
cat("Corporate Steuerfuss is the municipal tax multiplier (\\%). ")
cat("MDE: minimum detectable effect at 80\\% power for a 10pp rate change, as approximate percentage change. ")
cat("Standard errors clustered at municipality level. ")
cat("$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

# ── Table 4: Heterogeneity ─────────────────────────────────────────────────
cat("Generating Table 4: Heterogeneity...\n")

sink(file.path(table_dir, "tab4_heterogeneity.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Heterogeneity: Tax Competition Effects by Municipal Characteristics}\n")
cat("\\label{tab:heterogeneity}\n")
cat("\\begin{tabular}{lcccc}\n\\hline\\hline\n")
cat("& \\multicolumn{2}{c}{Total Expenditure p.c.} & \\multicolumn{2}{c}{Education Exp.\\ p.c.} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")

# Panel A: fiscal capacity
cat("& (1) Low & (2) High & (3) Low & (4) High \\\\\n\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: By Initial Tax Revenue per Capita}} \\\\\n")

cap_coefs <- c(); cap_ses <- c(); cap_ns <- c()
for (y in c("total_exp_pc", "education_pc")) {
  for (h in c(0, 1)) {
    key <- paste0(y, "_cap_", h)
    if (key %in% names(het_results)) {
      cf <- fmt_coef(het_results[[key]], "stf_corp")
      cap_coefs <- c(cap_coefs, cf$coef)
      cap_ses <- c(cap_ses, cf$se)
      cap_ns <- c(cap_ns, format(het_results[[key]]$nobs, big.mark = ","))
    } else {
      cap_coefs <- c(cap_coefs, "---"); cap_ses <- c(cap_ses, ""); cap_ns <- c(cap_ns, "---")
    }
  }
}
cat(sprintf("Corp.\\ Steuerfuss & %s \\\\\n", paste(cap_coefs, collapse = " & ")))
cat(sprintf("& %s \\\\\n", paste(cap_ses, collapse = " & ")))
cat(sprintf("Observations & %s \\\\\n", paste(cap_ns, collapse = " & ")))

# Panel B: population size
cat("\\hline\n")
cat("& (5) Small & (6) Large & (7) Small & (8) Large \\\\\n\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: By Population Size}} \\\\\n")

size_coefs <- c(); size_ses <- c(); size_ns <- c()
for (y in c("total_exp_pc", "education_pc")) {
  for (h in c(0, 1)) {
    key <- paste0(y, "_size_", h)
    if (key %in% names(het_results)) {
      cf <- fmt_coef(het_results[[key]], "stf_corp")
      size_coefs <- c(size_coefs, cf$coef)
      size_ses <- c(size_ses, cf$se)
      size_ns <- c(size_ns, format(het_results[[key]]$nobs, big.mark = ","))
    } else {
      size_coefs <- c(size_coefs, "---"); size_ses <- c(size_ses, ""); size_ns <- c(size_ns, "---")
    }
  }
}
cat(sprintf("Corp.\\ Steuerfuss & %s \\\\\n", paste(size_coefs, collapse = " & ")))
cat(sprintf("& %s \\\\\n", paste(size_ses, collapse = " & ")))
cat(sprintf("Observations & %s \\\\\n", paste(size_ns, collapse = " & ")))

cat("\\hline\n")
cat(sprintf("Muni.\\ + Year FE & %s \\\\\n", paste(rep("Yes", 4), collapse = " & ")))
cat(sprintf("Pop.\\ growth & %s \\\\\n", paste(rep("Yes", 4), collapse = " & ")))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Sample split by median initial tax revenue per capita (Panel A) and median population (Panel B). ")
cat("All specifications include municipality and year FE with population growth control. ")
cat("Standard errors clustered at municipality level. ")
cat("$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

# ── SDE Appendix Table ──────────────────────────────────────────────────────
cat("Generating SDE Table...\n")

sd_x <- sd(analysis_full$stf_corp, na.rm = TRUE)

sde_rows <- list()
ys <- c("total_exp_pc", "education_pc", "social_pc", "tax_revenue_pc")
ylabs <- c("Total Expenditure p.c.", "Education Exp.\\ p.c.",
           "Social Security Exp.\\ p.c.", "Tax Revenue p.c.")

for (i in seq_along(ys)) {
  y <- ys[i]; if (!y %in% names(results)) next
  beta <- coef(results[[y]])["stf_corp"]
  se_b <- se(results[[y]])["stf_corp"]
  sd_y <- sd(analysis_full[[y]], na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  bucket <- if (sde < -0.15) "Large neg."
            else if (sde < -0.05) "Mod.\\ neg."
            else if (sde < -0.005) "Small neg."
            else if (sde <= 0.005) "Null"
            else if (sde <= 0.05) "Small pos."
            else if (sde <= 0.15) "Mod.\\ pos."
            else "Large pos."
  sde_rows[[i]] <- c(ylabs[i], sprintf("%.3f", beta), sprintf("%.3f", se_b),
                      sprintf("%.1f", sd_y), sprintf("%.4f", sde),
                      sprintf("%.4f", se_sde), bucket)
}

# Panel B: heterogeneity (total exp by fiscal capacity)
het_sde_rows <- list()
for (h in c(0, 1)) {
  key <- paste0("total_exp_pc_cap_", h)
  if (!key %in% names(het_results)) next
  lab <- paste0("Total Exp.\\ (", ifelse(h==0, "Low", "High"), " cap.)")
  fit <- het_results[[key]]
  beta <- coef(fit)["stf_corp"]
  se_b <- se(fit)["stf_corp"]
  sub <- analysis_full[high_capacity == h]
  sd_y <- sd(sub$total_exp_pc, na.rm = TRUE)
  sde <- beta * sd_x / sd_y; se_sde <- se_b * sd_x / sd_y
  bucket <- if (sde < -0.15) "Large neg."
            else if (sde < -0.05) "Mod.\\ neg."
            else if (sde < -0.005) "Small neg."
            else if (sde <= 0.005) "Null"
            else if (sde <= 0.05) "Small pos."
            else if (sde <= 0.15) "Mod.\\ pos."
            else "Large pos."
  het_sde_rows[[length(het_sde_rows)+1]] <- c(lab, sprintf("%.3f", beta), sprintf("%.3f", se_b),
                                                sprintf("%.1f", sd_y), sprintf("%.4f", sde),
                                                sprintf("%.4f", se_sde), bucket)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does municipal tax competition crowd out public goods provision, ",
  "as predicted by Zodrow and Mieszkowski (1986)? ",
  "\\textbf{Policy mechanism:} Swiss municipalities independently set an annual Steuerfuss (tax multiplier) ",
  "applied to the cantonal base rate; reductions lower effective tax burdens, ",
  "potentially constraining municipal revenue and public expenditure. Corporate and natural-person rates ",
  "move in near-perfect lockstep (correlation 0.995), so variation captures general municipal tax competition. ",
  "\\textbf{Outcome definition:} Per-capita municipal expenditure (CHF) in functional categories ",
  "(total, education, social security) from Canton Zurich Jahresrechnungen (municipal financial accounts). ",
  "\\textbf{Treatment:} Continuous; Steuerfuss as percentage of cantonal base rate (typical range 80--130\\%). ",
  "\\textbf{Data:} Canton Zurich Jahresrechnungen and Steuerfuss panel, municipality-year observations, 2012--2017. ",
  "\\textbf{Method:} Two-way fixed effects (municipality + year FE), standard errors clustered at municipality level. ",
  "\\textbf{Sample:} Canton Zurich political municipalities with non-missing tax multiplier and spending data; ",
  "outliers beyond 1st/99th percentile of per-capita spending trimmed. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-municipality ",
  "standard deviation of the Steuerfuss and SD($Y$) is the standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (r in sde_rows) cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
                                 r[1],r[2],r[3],r[4],r[5],r[6],r[7]))
cat("\\hline\n\\multicolumn{7}{l}{\\textit{Panel B: By Initial Fiscal Capacity}} \\\\\n")
for (r in het_sde_rows) cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
                                     r[1],r[2],r[3],r[4],r[5],r[6],r[7]))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
