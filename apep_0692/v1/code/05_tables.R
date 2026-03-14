# =============================================================================
# 05_tables.R — Generate all tables for E-Verify DDD paper
# =============================================================================

source("00_packages.R")

county_panel <- readRDS("../data/county_panel.rds")
main_results <- readRDS("../data/main_results.rds")
ind_results <- readRDS("../data/ind_results.rds")

table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

# Helper: extract coefficient, SE, stars
fmt_coef <- function(mod, varname) {
  ct <- coeftable(mod)
  idx <- grep(varname, rownames(ct))
  if (length(idx) == 0) return(c("", ""))
  beta <- ct[idx[1], "Estimate"]
  se <- ct[idx[1], "Std. Error"]
  pval <- ct[idx[1], "Pr(>|t|)"]
  stars <- if (pval < 0.01) "***" else if (pval < 0.05) "**" else if (pval < 0.1) "*" else ""
  c(sprintf("%.4f%s", beta, stars), sprintf("(%.4f)", se))
}

# ── Table 1: Summary Statistics ──────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

pre_data <- county_panel[year < 2008]

summ_fn <- function(dt) {
  c(format(round(mean(dt$Emp, na.rm = TRUE)), big.mark = ","),
    format(round(sd(dt$Emp, na.rm = TRUE)), big.mark = ","),
    format(round(mean(dt$EarnS_wtd, na.rm = TRUE)), big.mark = ","),
    format(round(mean(dt$HirA, na.rm = TRUE)), big.mark = ","),
    as.character(length(unique(dt$county_fips))),
    format(nrow(dt), big.mark = ","))
}

s1 <- summ_fn(pre_data[border == TRUE & hispanic == 1])
s2 <- summ_fn(pre_data[border == TRUE & hispanic == 0])
s3 <- summ_fn(pre_data[border == FALSE & hispanic == 1])
s4 <- summ_fn(pre_data[border == FALSE & hispanic == 0])

tab1_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Period County-Quarter Means (2004--2007)}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  " & Mean & SD & Mean & Mean & & \\\\",
  "Group & Emp. & Emp. & Earn. & Hires & Counties & Obs. \\\\",
  "\\midrule",
  sprintf("Border, Hispanic & %s & %s & %s & %s & %s & %s \\\\", s1[1], s1[2], s1[3], s1[4], s1[5], s1[6]),
  sprintf("Border, Non-Hispanic & %s & %s & %s & %s & %s & %s \\\\", s2[1], s2[2], s2[3], s2[4], s2[5], s2[6]),
  sprintf("Interior, Hispanic & %s & %s & %s & %s & %s & %s \\\\", s3[1], s3[2], s3[3], s3[4], s3[5], s3[6]),
  sprintf("Interior, Non-Hispanic & %s & %s & %s & %s & %s & %s \\\\", s4[1], s4[2], s4[3], s4[4], s4[5], s4[6]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Pre-period (2004--2007) means. Employment is beginning-of-quarter ",
         "count. Earnings are average monthly earnings (\\$). Border counties are in non-E-Verify states ",
         "adjacent to an E-Verify state. Interior counties are in non-E-Verify states with no border adjacency."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ── Table 2: Main DDD Results ────────────────────────────────────────────────
cat("Generating Table 2: Main DDD Results\n")

c1 <- fmt_coef(main_results$m1, "post:hispanic")
c1b <- fmt_coef(main_results$m1, "^post$")
c2 <- fmt_coef(main_results$m2, "post:hispanic")
c2b <- fmt_coef(main_results$m2, "^post$")
c3 <- fmt_coef(main_results$m3, "post:hispanic")
c3b <- fmt_coef(main_results$m3, "^post$")
c4 <- fmt_coef(main_results$m4, "post:hispanic")
c4b <- fmt_coef(main_results$m4, "^post$")

n1 <- format(nobs(main_results$m1), big.mark = ",")
n2 <- format(nobs(main_results$m2), big.mark = ",")
n3 <- format(nobs(main_results$m3), big.mark = ",")
n4 <- format(nobs(main_results$m4), big.mark = ",")

tab2_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Adjacent E-Verify Mandates on Border County Outcomes}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Emp. & Log Emp. & Log Earn. & Log Hires \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Hispanic & %s & %s & %s & %s \\\\", c1[1], c2[1], c3[1], c4[1]),
  sprintf(" & %s & %s & %s & %s \\\\[3pt]", c1[2], c2[2], c3[2], c4[2]),
  sprintf("Post & %s & %s & %s & %s \\\\", c1b[1], c2b[1], c3b[1], c4b[1]),
  sprintf(" & %s & %s & %s & %s \\\\[6pt]", c1b[2], c2b[2], c3b[2], c4b[2]),
  sprintf("Observations & %s & %s & %s & %s \\\\", n1, n2, n3, n4),
  "County-Ethnicity FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter $\\times$ Ethnicity FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Quarter FE & No & Yes & No & No \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
         "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
         "Post equals one for border counties after the adjacent state adopted E-Verify. ",
         "Post $\\times$ Hispanic is the triple-difference coefficient: the differential change ",
         "in Hispanic (vs.\\ Non-Hispanic) outcomes in border (vs.\\ interior) counties after ",
         "adjacent E-Verify adoption. Sample: counties in non-E-Verify states, 2004--2024."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main_ddd.tex"))

# ── Table 3: Industry Heterogeneity ──────────────────────────────────────────
cat("Generating Table 3: Industry Heterogeneity\n")

ic1 <- fmt_coef(ind_results$constr, "post:hispanic")
ic1b <- fmt_coef(ind_results$constr, "^post$")
ic2 <- fmt_coef(ind_results$food, "post:hispanic")
ic2b <- fmt_coef(ind_results$food, "^post$")
ic3 <- fmt_coef(ind_results$mfg, "post:hispanic")
ic3b <- fmt_coef(ind_results$mfg, "^post$")
ic4 <- fmt_coef(ind_results$prof, "post:hispanic")
ic4b <- fmt_coef(ind_results$prof, "^post$")

tab3_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Industry Heterogeneity: DDD by Sector}",
  "\\label{tab:industry}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Construction & Accomm./Food & Manufact. & Prof.\\ Svc. \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Hispanic & %s & %s & %s & %s \\\\", ic1[1], ic2[1], ic3[1], ic4[1]),
  sprintf(" & %s & %s & %s & %s \\\\[3pt]", ic1[2], ic2[2], ic3[2], ic4[2]),
  sprintf("Post & %s & %s & %s & %s \\\\", ic1b[1], ic2b[1], ic3b[1], ic4b[1]),
  sprintf(" & %s & %s & %s & %s \\\\[6pt]", ic1b[2], ic2b[2], ic3b[2], ic4b[2]),
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(nobs(ind_results$constr), big.mark = ","),
    format(nobs(ind_results$food), big.mark = ","),
    format(nobs(ind_results$mfg), big.mark = ","),
    format(nobs(ind_results$prof), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the state level. ",
         "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. ",
         "Dependent variable: log employment. All specifications include county-ethnicity-industry ",
         "and quarter $\\times$ ethnicity fixed effects. ",
         "Professional services (NAICS 54) serves as a placebo industry with low Hispanic employment share."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_industry.tex"))

# ── Table 4: Robustness ─────────────────────────────────────────────────────
cat("Generating Table 4: Robustness\n")

ring_results <- readRDS("../data/ring_results.rds")
m_placebo <- readRDS("../data/placebo_results.rds")
m_early <- readRDS("../data/early_results.rds")

rc1 <- fmt_coef(ring_results$ring1, "post:hispanic")
rc1b <- fmt_coef(ring_results$ring1, "^post$")
rc2 <- fmt_coef(ring_results$ring2, "post_r2:hispanic")
rc2b <- fmt_coef(ring_results$ring2, "^post_r2$")
rc3 <- fmt_coef(m_placebo, "fake_post:hispanic")
rc3b <- fmt_coef(m_placebo, "^fake_post$")
rc4 <- fmt_coef(m_early, "post:hispanic")
rc4b <- fmt_coef(m_early, "^post$")

tab4_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Distance, Placebo, and Sample Restrictions}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Ring 1 & Ring 2 & Placebo & Pre-2020 \\\\",
  "\\midrule",
  sprintf("DDD & %s & %s & %s & %s \\\\", rc1[1], rc2[1], rc3[1], rc4[1]),
  sprintf(" & %s & %s & %s & %s \\\\[3pt]", rc1[2], rc2[2], rc3[2], rc4[2]),
  sprintf("Post & %s & %s & %s & %s \\\\", rc1b[1], rc2b[1], rc3b[1], rc4b[1]),
  sprintf(" & %s & %s & %s & %s \\\\[6pt]", rc1b[2], rc2b[2], rc3b[2], rc4b[2]),
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(nobs(ring_results$ring1), big.mark = ","),
    format(nobs(ring_results$ring2), big.mark = ","),
    format(nobs(m_placebo), big.mark = ","),
    format(nobs(m_early), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the state level. ",
         "* p$<$0.10, ** p$<$0.05, *** p$<$0.01. DDD is Post $\\times$ Hispanic. ",
         "Column (1): Ring 1 counties (directly adjacent) vs.\\ interior. ",
         "Column (2): Ring 2 counties (adjacent to Ring 1) vs.\\ interior. ",
         "Column (3): Fake post at 2006Q1 on pre-2008 data (placebo). ",
         "Column (4): Pre-2020 sample."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

# ── Table F1: Standardized Effect Sizes ──────────────────────────────────────
cat("Generating Table F1: SDE\n")

sd_y_emp <- sd(county_panel$log_emp, na.rm = TRUE)
sd_y_earn <- sd(county_panel$log_earn, na.rm = TRUE)
sd_y_hir <- sd(county_panel$log_hir, na.rm = TRUE)

get_ddd <- function(mod) {
  ct <- coeftable(mod)
  idx <- grep("post:hispanic", rownames(ct), fixed = TRUE)
  if (length(idx) == 0) idx <- grep("hispanic", rownames(ct))
  list(beta = ct[idx[1], "Estimate"], se = ct[idx[1], "Std. Error"])
}

r1 <- get_ddd(main_results$m1)
r2 <- get_ddd(main_results$m2)
r3 <- get_ddd(main_results$m3)
r4 <- get_ddd(main_results$m4)

classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_data <- data.frame(
  Outcome = c("Log Employment (base)", "Log Employment (state FE)",
              "Log Earnings", "Log Hires"),
  Beta = c(r1$beta, r2$beta, r3$beta, r4$beta),
  SE = c(r1$se, r2$se, r3$se, r4$se),
  SD_Y = c(sd_y_emp, sd_y_emp, sd_y_earn, sd_y_hir),
  stringsAsFactors = FALSE
)
sde_data$SDE <- sde_data$Beta / sde_data$SD_Y
sde_data$SE_SDE <- sde_data$SE / sde_data$SD_Y
sde_data$Class <- sapply(sde_data$SDE, classify_sde)

sde_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: E-Verify Border Spillovers}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(sde_data))) {
  sde_tex <- c(sde_tex, sprintf(
    "%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    sde_data$Outcome[i], sde_data$Beta[i], sde_data$SE[i],
    sde_data$SD_Y[i], sde_data$SDE[i], sde_data$SE_SDE[i],
    sde_data$Class[i]
  ))
}
sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} \\textbf{Research question:} Do adjacent E-Verify mandates ",
         "create chilling effects on Hispanic employment in border counties of untreated states? ",
         "\\textbf{Treatment:} Binary (adjacent state adopted E-Verify). ",
         "\\textbf{Data:} QWI county-quarter panel, 2004--2024, ",
         format(nrow(county_panel), big.mark = ","), " observations from ",
         length(unique(county_panel$county_fips)), " counties. ",
         "\\textbf{Method:} Triple-difference with county-ethnicity and quarter$\\times$ethnicity FE, ",
         "state-clustered SEs. ",
         "Classification labels refer to the magnitude of the standardized point estimate, ",
         "not to statistical significance. ``Null'' denotes $|$SDE$| < 0.005$, not a failure to reject."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
