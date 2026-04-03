## 05_tables.R — Generate all tables
## apep_1345: The Inspector Lottery

source("00_packages.R")
setwd(here::here("output", "apep_1345", "v1"))

dir.create("tables", showWarnings = FALSE)

## ── Load data and models ─────────────────────────────────────────────────────

panel <- fread("data/analysis_panel.csv")
ofsted <- fread("data/ofsted_clean.csv")
load("data/models.RData")

panel[, event_month := as.integer(event_month)]
panel[, bad_rating := as.integer(rating >= 3)]
panel[, post := as.integer(event_month >= 0)]
panel_est <- panel[!is.na(log_mean_price)]

# Merge phase info
if (!"phase" %in% names(panel_est)) {
  panel_est <- merge(panel_est, ofsted[, .(urn, phase)], by = "urn", all.x = TRUE)
}
# Resolve any duplicate columns
if ("phase.x" %in% names(panel_est)) {
  panel_est[, phase := phase.x]
  panel_est[, c("phase.x", "phase.y") := NULL]
}

# Load robustness if available
if (file.exists("data/robustness.RData")) {
  load("data/robustness.RData")
}

## ── Table 1: Summary Statistics ──────────────────────────────────────────────

cat("=== Table 1: Summary Statistics ===\n")

# School-level stats
school_stats <- ofsted[urn %in% unique(panel_est$urn)]

# Mean house price in school's postcode district (pre-inspection)
pre_prices <- panel_est[event_month %in% -12:-1, .(
  pre_mean_price = mean(exp(log_mean_price), na.rm = TRUE)
), by = urn]
school_stats <- merge(school_stats, pre_prices, by = "urn", all.x = TRUE)

# By rating group
good_schools <- school_stats[rating_num <= 2]
bad_schools <- school_stats[rating_num >= 3]

make_row <- function(var, label, data_good, data_bad) {
  g <- as.numeric(data_good[[var]])
  b <- as.numeric(data_bad[[var]])
  g <- g[!is.na(g)]
  b <- b[!is.na(b)]
  sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          label,
          mean(g), sd(g), mean(b), sd(b),
          mean(c(g,b)), sd(c(g,b)))
}

tab1_rows <- c(
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Good/Outstanding} & \\multicolumn{2}{c}{RI/Inadequate} & \\multicolumn{2}{c}{All Schools} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: School Characteristics}} \\\\[3pt]",
  make_row("n_pupils", "Number of pupils", good_schools, bad_schools),
  sprintf("Outstanding (\\%%) & %.1f & & %.1f & & %.1f & \\\\",
          mean(good_schools$rating_num == 1) * 100, 0,
          mean(c(good_schools$rating_num, bad_schools$rating_num) == 1) * 100),
  sprintf("Good (\\%%) & %.1f & & %.1f & & %.1f & \\\\",
          mean(good_schools$rating_num == 2) * 100, 0,
          mean(c(good_schools$rating_num, bad_schools$rating_num) == 2) * 100),
  sprintf("Requires Improvement (\\%%) & & & %.1f & & %.1f & \\\\",
          mean(bad_schools$rating_num == 3) * 100,
          mean(c(good_schools$rating_num, bad_schools$rating_num) == 3) * 100),
  sprintf("Inadequate (\\%%) & & & %.1f & & %.1f & \\\\",
          mean(bad_schools$rating_num == 4) * 100,
          mean(c(good_schools$rating_num, bad_schools$rating_num) == 4) * 100),
  sprintf("Primary school (\\%%) & %.1f & & %.1f & & %.1f & \\\\",
          mean(good_schools$phase == "Primary", na.rm=TRUE) * 100,
          mean(bad_schools$phase == "Primary", na.rm=TRUE) * 100,
          mean(school_stats$phase == "Primary", na.rm=TRUE) * 100),
  make_row("idaci", "IDACI deprivation quintile", good_schools, bad_schools),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: House Prices (pre-inspection)}} \\\\[3pt]",
  sprintf("Mean house price (\\pounds) & %s & %s & %s & %s & %s & %s \\\\",
          formatC(mean(good_schools$pre_mean_price, na.rm=TRUE), format="f", digits=0, big.mark=","),
          formatC(sd(good_schools$pre_mean_price, na.rm=TRUE), format="f", digits=0, big.mark=","),
          formatC(mean(bad_schools$pre_mean_price, na.rm=TRUE), format="f", digits=0, big.mark=","),
          formatC(sd(bad_schools$pre_mean_price, na.rm=TRUE), format="f", digits=0, big.mark=","),
          formatC(mean(school_stats$pre_mean_price, na.rm=TRUE), format="f", digits=0, big.mark=","),
          formatC(sd(school_stats$pre_mean_price, na.rm=TRUE), format="f", digits=0, big.mark=",")),
  "\\midrule",
  sprintf("Schools & %s & & %s & & %s & \\\\",
          formatC(nrow(good_schools), big.mark=","),
          formatC(nrow(bad_schools), big.mark=","),
          formatC(nrow(school_stats), big.mark=",")),
  sprintf("School-month observations & %s & & %s & & %s & \\\\",
          formatC(nrow(panel_est[good_rating == 1]), big.mark=","),
          formatC(nrow(panel_est[bad_rating == 1]), big.mark=","),
          formatC(nrow(panel_est), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}"
)

writeLines(tab1_rows, "tables/tab1_summary.tex")
cat("Table 1 saved.\n")

## ── Table 2: Main DiD Results ────────────────────────────────────────────────

cat("\n=== Table 2: Main DiD Results ===\n")

# Re-estimate models for consistent table
# Column 1: Simple DiD (24 months)
m1 <- did_model

# Column 2: DiD (12 months)
m2 <- did_narrow

# Column 3: By rating category
m3 <- het_model

# Column 4: Deprivation interaction
m4 <- did_deprived

# Build Table 2 manually from model objects
star <- function(pv) {
  if (is.na(pv)) return("")
  if (pv < 0.01) return("***")
  if (pv < 0.05) return("**")
  if (pv < 0.10) return("*")
  return("")
}

fmt_coef <- function(model, var) {
  if (var %in% names(coef(model))) {
    b <- coef(model)[var]
    s <- se(model)[var]
    p <- pvalue(model)[var]
    return(list(
      est = sprintf("%.4f%s", b, star(p)),
      se = sprintf("(%.4f)", s)
    ))
  }
  return(list(est = "", se = ""))
}

# Extract coefficients
m1_br <- fmt_coef(m1, "post:bad_rating")
m2_br <- fmt_coef(m2, "post:bad_rating")
m3_out <- fmt_coef(m3, "post:outstanding")
m3_ri <- fmt_coef(m3, "post:ri")
m3_inad <- fmt_coef(m3, "post:inadequate")
m4_br <- fmt_coef(m4, "post:bad_rating")
m4_dep <- fmt_coef(m4, "post:bad_rating:high_deprivation")

tab2_rows <- c(
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Full Window & Narrow Window & By Rating & Deprivation \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Bad Rating & %s & %s & & %s \\\\", m1_br$est, m2_br$est, m4_br$est),
  sprintf(" & %s & %s & & %s \\\\", m1_br$se, m2_br$se, m4_br$se),
  sprintf("Post $\\times$ Outstanding & & & %s & \\\\", m3_out$est),
  sprintf(" & & & %s & \\\\", m3_out$se),
  sprintf("Post $\\times$ Requires Improvement & & & %s & \\\\", m3_ri$est),
  sprintf(" & & & %s & \\\\", m3_ri$se),
  sprintf("Post $\\times$ Inadequate & & & %s & \\\\", m3_inad$est),
  sprintf(" & & & %s & \\\\", m3_inad$se),
  sprintf("Post $\\times$ Bad Rating $\\times$ High Deprivation & & & & %s \\\\", m4_dep$est),
  sprintf(" & & & & %s \\\\", m4_dep$se),
  "\\midrule",
  "School FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(m1), big.mark=","),
          formatC(nobs(m2), big.mark=","),
          formatC(nobs(m3), big.mark=","),
          formatC(nobs(m4), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}"
)
writeLines(tab2_rows, "tables/tab2_main.tex")
cat("Table 2 saved.\n")

## ── Table 3: Window Robustness ───────────────────────────────────────────────

cat("\n=== Table 3: Window Robustness ===\n")

if (exists("window_dt")) {
  tab3_rows <- c(
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Window & Coefficient & SE & $p$-value & Observations \\\\",
    "\\midrule"
  )

  for (i in 1:nrow(window_dt)) {
    r <- window_dt[i]
    tab3_rows <- c(tab3_rows,
      sprintf("$\\pm$ %d months & %.4f%s & (%.4f) & %.3f & %s \\\\",
              r$window,
              r$coef,
              ifelse(r$pval < 0.01, "***", ifelse(r$pval < 0.05, "**", ifelse(r$pval < 0.1, "*", ""))),
              r$se,
              r$pval,
              formatC(r$n_obs, big.mark=",")))
  }

  tab3_rows <- c(tab3_rows,
    "\\midrule",
    sprintf("RI $p$-value & \\multicolumn{4}{c}{%.3f} \\\\", ri_pvalue),
    "\\bottomrule",
    "\\end{tabular}"
  )

  writeLines(tab3_rows, "tables/tab3_robustness.tex")
  cat("Table 3 saved.\n")
} else {
  cat("Window results not yet available. Run 04_robustness.R first.\n")
}

## ── Table 4: Phase Heterogeneity ─────────────────────────────────────────────

cat("\n=== Table 4: Phase Heterogeneity ===\n")

# Primary vs Secondary schools
panel_est[, bad_rating := as.integer(rating >= 3)]
panel_est[, post := as.integer(event_month >= 0)]
panel_est[, high_deprivation := as.integer(idaci %in% c(1, 2))]

m_primary <- feols(
  log_mean_price ~ post:bad_rating + post:bad_rating:high_deprivation |
    urn + txn_month,
  data = panel_est[phase == "Primary" & !is.na(idaci)],
  cluster = ~pc_district
)

m_secondary <- feols(
  log_mean_price ~ post:bad_rating + post:bad_rating:high_deprivation |
    urn + txn_month,
  data = panel_est[phase == "Secondary" & !is.na(idaci)],
  cluster = ~pc_district
)

mp_br <- fmt_coef(m_primary, "post:bad_rating")
mp_dep <- fmt_coef(m_primary, "post:bad_rating:high_deprivation")
ms_br <- fmt_coef(m_secondary, "post:bad_rating")
ms_dep <- fmt_coef(m_secondary, "post:bad_rating:high_deprivation")

tab4_rows <- c(
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Primary & Secondary \\\\",
  "\\midrule",
  sprintf("Post $\\times$ Bad Rating & %s & %s \\\\", mp_br$est, ms_br$est),
  sprintf(" & %s & %s \\\\", mp_br$se, ms_br$se),
  sprintf("Post $\\times$ Bad Rating $\\times$ High Deprivation & %s & %s \\\\", mp_dep$est, ms_dep$est),
  sprintf(" & %s & %s \\\\", mp_dep$se, ms_dep$se),
  "\\midrule",
  "School FE & Yes & Yes \\\\",
  "Month FE & Yes & Yes \\\\",
  sprintf("Observations & %s & %s \\\\",
          formatC(nobs(m_primary), big.mark=","),
          formatC(nobs(m_secondary), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}"
)
writeLines(tab4_rows, "tables/tab4_phase.tex")
cat("Table 4 saved.\n")

## ── SDE Table (Appendix) ─────────────────────────────────────────────────────

cat("\n=== SDE Table ===\n")

# Compute SDE for main outcomes
# Main spec: post x bad_rating
beta_main <- coef(did_model)["post:bad_rating"]
se_main <- se(did_model)["post:bad_rating"]
sd_y_pre <- sd(panel_est$log_mean_price[panel_est$event_month < 0], na.rm = TRUE)

sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

# Deprivation interaction: deprived areas
beta_dep <- coef(did_deprived)["post:bad_rating"] +
            coef(did_deprived)["post:bad_rating:high_deprivation"]
se_dep <- sqrt(se(did_deprived)["post:bad_rating"]^2 +
               se(did_deprived)["post:bad_rating:high_deprivation"]^2 +
               2 * vcov(did_deprived)["post:bad_rating", "post:bad_rating:high_deprivation"])
sd_y_dep <- sd(panel_est$log_mean_price[panel_est$event_month < 0 &
               panel_est$idaci %in% c(1, 2)], na.rm = TRUE)
sde_dep <- beta_dep / sd_y_dep
se_sde_dep <- se_dep / sd_y_dep

# Non-deprived
beta_nondep <- coef(did_deprived)["post:bad_rating"]
se_nondep <- se(did_deprived)["post:bad_rating"]
sd_y_nondep <- sd(panel_est$log_mean_price[panel_est$event_month < 0 &
                  !(panel_est$idaci %in% c(1, 2))], na.rm = TRUE)
sde_nondep <- beta_nondep / sd_y_nondep
se_sde_nondep <- se_nondep / sd_y_nondep

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does receiving a negative Ofsted school inspection rating (Requires Improvement or Inadequate) cause residential property values in the school's postcode district to decline relative to areas near schools receiving positive ratings (Outstanding or Good)? ",
  "\\textbf{Policy mechanism:} Ofsted inspects all state-funded schools in England on a rolling cycle and publishes Overall Effectiveness ratings on a 1--4 scale; these ratings are publicly available and widely consulted by parents and homebuyers, creating an information channel through which school quality labels are capitalized into local house prices. ",
  "\\textbf{Outcome definition:} Log mean residential transaction price per postcode district per month, computed from HM Land Registry Price Paid Data standard transactions. ",
  "\\textbf{Treatment:} Binary indicator for receiving a rating of 3 (Requires Improvement) or 4 (Inadequate) versus 1 (Outstanding) or 2 (Good). ",
  "\\textbf{Data:} Ofsted Management Information (9,780 graded inspections, 2019--2024) linked to HM Land Registry Price Paid Data (8.7 million transactions, 2015--2024) via postcode district; school-month panel with 24 months pre/post inspection. ",
  "\\textbf{Method:} Difference-in-differences around inspection publication dates; school and calendar-month fixed effects; standard errors clustered at the postcode district level. ",
  "\\textbf{Sample:} State-funded schools in England with graded Ofsted inspections (2019--2024); restricted to schools with at least 12 months of house price data in their postcode district. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log house prices. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_rows <- c(
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Log house price (all areas) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by deprivation)}} \\\\[3pt]",
  sprintf("Log house price (deprived areas) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_dep, se_dep, sd_y_dep, sde_dep, se_sde_dep, classify_sde(sde_dep)),
  sprintf("Log house price (non-deprived areas) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_nondep, se_nondep, sd_y_nondep, sde_nondep, se_sde_nondep, classify_sde(sde_nondep)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize ", sde_notes, "}")
)

writeLines(sde_rows, "tables/tabF1_sde.tex")
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
print(list.files("tables/"))
