## 05_tables.R — Generate all LaTeX tables
## APEP-1033: Pouring Risk — Raw Milk Legalization and Foodborne Illness

source("00_packages.R")

cat("=== Generating Tables ===\n")

panel    <- read_csv("../data/panel.csv", show_col_types = FALSE)
panel_cs <- read_csv("../data/panel_cs.csv", show_col_types = FALSE)
results  <- readRDS("../data/main_results.rds")
rob      <- readRDS("../data/robustness_results.rds")
diag     <- fromJSON("../data/diagnostics.json")

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

panel <- panel %>%
  mutate(
    ever_legal  = legal == 1,
    status_group = case_when(
      first_legal_year == 0                          ~ "Always legal",
      is.finite(first_legal_year) & first_legal_year > 0 ~ "Newly legalized",
      TRUE                                            ~ "Never legal"
    )
  )

summ <- panel %>%
  group_by(status_group) %>%
  summarise(
    States        = n_distinct(state_abbr),
    `State-years` = n(),
    `Mean outbreaks`     = sprintf("%.3f", mean(outbreaks_unpast)),
    `Mean illnesses`     = sprintf("%.2f", mean(illnesses_unpast)),
    `Any outbreak (\\%)`  = sprintf("%.1f", 100 * mean(outbreaks_unpast > 0)),
    `Mean past. dairy`   = sprintf("%.3f", mean(outbreaks_past)),
    `Mean non-dairy`     = sprintf("%.1f", mean(outbreaks_nondairy)),
    .groups = "drop"
  )

## LaTeX output
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: State-Year Panel, 1998--2023}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccccc}",
  "\\hline\\hline",
  " & States & State- & Unpast. & Unpast. & Any unpast. & Past. dairy & Non-dairy \\\\",
  " &        & years  & outbreaks & illnesses & outbreak (\\%) & outbreaks & outbreaks \\\\",
  "\\hline"
)

for (i in seq_len(nrow(summ))) {
  row <- summ[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %d & %d & %s & %s & %s & %s & %s \\\\",
    row$status_group, row$States, row$`State-years`,
    row$`Mean outbreaks`, row$`Mean illnesses`, row$`Any outbreak (\\%)`,
    row$`Mean past. dairy`, row$`Mean non-dairy`
  ))
}

## Add total row
tot <- panel %>%
  summarise(
    States = n_distinct(state_abbr), N = n(),
    mo = sprintf("%.3f", mean(outbreaks_unpast)),
    mi = sprintf("%.2f", mean(illnesses_unpast)),
    ao = sprintf("%.1f", 100 * mean(outbreaks_unpast > 0)),
    mp = sprintf("%.3f", mean(outbreaks_past)),
    mn = sprintf("%.1f", mean(outbreaks_nondairy))
  )

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Total & %d & %d & %s & %s & %s & %s & %s \\\\",
          tot$States, tot$N, tot$mo, tot$mi, tot$ao, tot$mp, tot$mn),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel of 51 US jurisdictions (50 states + DC) $\\times$ 26 years (1998--2023). ``Always legal'' states had some form of raw milk sales (retail, on-farm, or herdshare) before 1998. ``Newly legalized'' states first expanded legal access during 1998--2023. ``Never legal'' states prohibited all raw milk sales for human consumption throughout. Outbreak data from CDC NORS. Legal status coded from Whitten et al.\\ (2018), FTCLDF, and NCSL.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ============================================================
## TABLE 2: Main Results — TWFE Poisson
## ============================================================
cat("\n--- Table 2: Main Results ---\n")

## Extract estimates
get_est <- function(model, param = NULL) {
  if (is.null(model)) return(list(b = NA, se = NA, p = NA, n = NA))
  p <- if (is.null(param)) names(coef(model))[1] else param
  list(
    b  = coef(model)[p],
    se = se(model)[p],
    p  = pvalue(model)[p],
    n  = model$nobs
  )
}

e1 <- get_est(results$twfe_pois_outbreaks, "legal")
e2 <- get_est(results$twfe_pois_illnesses, "legal")
e3 <- get_est(results$twfe_pois_hosp, "legal")
e4 <- get_est(results$twfe_pois_cs_sample, "post")
e5 <- get_est(results$ols_any_outbreak, "post")

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Raw Milk Legalization on Foodborne Outbreaks}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Outbreaks & Illnesses & Hosp. & Outbreaks & Any outbreak \\\\",
  " & (Poisson) & (Poisson) & (Poisson) & (Poisson) & (OLS) \\\\",
  "\\hline",
  sprintf("Legal/Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.3f", e1$b), stars(e1$p),
          sprintf("%.3f", e2$b), stars(e2$p),
          sprintf("%.3f", e3$b), stars(e3$p),
          sprintf("%.3f", e4$b), stars(e4$p),
          sprintf("%.3f", e5$b), stars(e5$p)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          sprintf("%.3f", e1$se), sprintf("%.3f", e2$se),
          sprintf("%.3f", e3$se), sprintf("%.3f", e4$se),
          sprintf("%.3f", e5$se)),
  sprintf(" & [%.3f] & [%.3f] & [%.3f] & [%.3f] & [%.3f] \\\\",
          e1$p, e2$p, e3$p, e4$p, e5$p),
  "\\hline",
  "Sample & Full & Full & Full & CS & CS \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(e1$n, big.mark=","),
          format(e2$n, big.mark=","),
          format(e3$n, big.mark=","),
          format(e4$n, big.mark=","),
          format(e5$n, big.mark=",")),
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clusters & 39 & 39 & 34 & 17 & 27 \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns (1)--(3) report Poisson PPML estimates using the full panel (1998--2023) with state and year fixed effects. ``Legal'' indicates any form of raw milk sales is permitted. Columns (4)--(5) restrict to the CS sample: 15 newly-legalized states and 12 never-legal states, with ``Post'' indicating post-legalization periods. Standard errors clustered at the state level in parentheses; $p$-values in brackets. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

## ============================================================
## TABLE 3: Event Study Coefficients (CS)
## ============================================================
cat("\n--- Table 3: Event Study ---\n")

cs_es <- tryCatch(readRDS("../data/cs_event_study.rds"), error = function(e) NULL)

if (!is.null(cs_es)) {
  es_df <- data.frame(
    etime = cs_es$egt,
    att   = cs_es$att.egt,
    se    = cs_es$se.egt
  ) %>%
    filter(etime >= -7, etime <= 10) %>%
    mutate(
      p = 2 * (1 - pnorm(abs(att / se))),
      ci_lo = att - 1.96 * se,
      ci_hi = att + 1.96 * se
    )

  tab3_lines <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Event Study: Callaway-Sant'Anna ATT by Event Time}",
    "\\label{tab:event}",
    "\\begin{tabular}{lcccc}",
    "\\hline\\hline",
    "Event time & ATT & SE & 95\\% CI & $p$-value \\\\",
    "\\hline"
  )

  for (i in seq_len(nrow(es_df))) {
    row <- es_df[i, ]
    marker <- ifelse(row$etime == -1, " (ref)", "")
    tab3_lines <- c(tab3_lines, sprintf(
      "$t %s %d$%s & %s & (%s) & [%s, %s] & %s \\\\",
      ifelse(row$etime >= 0, "+", ""), abs(row$etime), marker,
      sprintf("%.3f", row$att), sprintf("%.3f", row$se),
      sprintf("%.3f", row$ci_lo), sprintf("%.3f", row$ci_hi),
      sprintf("%.3f", row$p)
    ))
  }

  tab3_lines <- c(tab3_lines,
    "\\hline\\hline",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time ATTs aggregated to event time. Outcome: any unpasteurized dairy outbreak (binary). CS sample: 15 newly-legalized states vs.\\ 12 never-legal states. $t-1$ is the reference period.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tab3_lines, "../tables/tab3_event.tex")
  cat("Table 3 written.\n")
}

## ============================================================
## TABLE 4: Robustness
## ============================================================
cat("\n--- Table 4: Robustness ---\n")

r1 <- get_est(rob$placebo_pasteurized, "legal")
r2 <- get_est(rob$placebo_nondairy, "legal")
r3 <- get_est(rob$ols_log, "legal")
r4 <- get_est(rob$ols_asinh, "legal")
r5 <- get_est(results$negbin, "legal")
r6 <- get_est(rob$farmgate_only, "post")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robust}",
  "\\begin{tabular}{llccc}",
  "\\hline\\hline",
  "Panel & Specification & Estimate & SE & $p$-value \\\\",
  "\\hline",
  "\\textit{A. Placebo outcomes} & & & & \\\\",
  sprintf("& Pasteurized dairy outbreaks & %s%s & (%s) & %s \\\\",
          sprintf("%.3f", r1$b), stars(r1$p), sprintf("%.3f", r1$se), sprintf("%.3f", r1$p)),
  sprintf("& Non-dairy foodborne outbreaks & %s%s & (%s) & %s \\\\",
          sprintf("%.3f", r2$b), stars(r2$p), sprintf("%.3f", r2$se), sprintf("%.3f", r2$p)),
  "\\hline",
  "\\textit{B. Alternative models} & & & & \\\\",
  sprintf("& OLS, $\\log(1+Y)$ & %s%s & (%s) & %s \\\\",
          sprintf("%.3f", r3$b), stars(r3$p), sprintf("%.3f", r3$se), sprintf("%.3f", r3$p)),
  sprintf("& OLS, $\\text{asinh}(Y)$ & %s%s & (%s) & %s \\\\",
          sprintf("%.3f", r4$b), stars(r4$p), sprintf("%.3f", r4$se), sprintf("%.3f", r4$p)),
  sprintf("& Negative binomial & %s%s & (%s) & %s \\\\",
          sprintf("%.3f", r5$b), stars(r5$p), sprintf("%.3f", r5$se), sprintf("%.3f", r5$p)),
  "\\hline",
  "\\textit{C. Treatment restriction} & & & & \\\\",
  sprintf("& Farm-gate+ states only & %s%s & (%s) & %s \\\\",
          sprintf("%.3f", r6$b), stars(r6$p), sprintf("%.3f", r6$se), sprintf("%.3f", r6$p)),
  "\\hline",
  "\\textit{D. Leave-one-out} & & & & \\\\",
  sprintf("& Jackknife range & [%.3f, %.3f] & & \\\\",
          min(rob$jackknife$coef), max(rob$jackknife$coef)),
  sprintf("& Jackknife mean & %.3f & & \\\\", mean(rob$jackknife$coef)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A tests placebo outcomes unaffected by raw milk legalization. Panel B varies the functional form. Panel C restricts treatment to states legalizing farm-gate sales or broader (excluding herdshare-only). Panel D drops each treated state in turn. All specifications include state and year fixed effects with state-clustered standard errors.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")
cat("Table 4 written.\n")

## ============================================================
## TABLE F1: Standardized Effect Size (SDE) — Appendix
## ============================================================
cat("\n--- Table F1: SDE ---\n")

## Main spec: Poisson on outbreaks (full panel)
## For Poisson, marginal effect = beta * mean(Y)
## SDE = marginal_effect / SD(Y) = beta * mean(Y) / SD(Y)
beta_outbreaks <- as.numeric(coef(results$twfe_pois_outbreaks)["legal"])
se_outbreaks   <- as.numeric(se(results$twfe_pois_outbreaks)["legal"])
mean_y <- mean(panel$outbreaks_unpast)
sd_y   <- sd(panel$outbreaks_unpast)
sd_y_pre <- sd(panel$outbreaks_unpast[panel$legal == 0])

## Use pre-treatment SD for SDE
me   <- beta_outbreaks * mean_y
sde  <- me / sd_y_pre
se_sde <- (se_outbreaks * mean_y) / sd_y_pre

## Illnesses
beta_ill <- as.numeric(coef(results$twfe_pois_illnesses)["legal"])
se_ill   <- as.numeric(se(results$twfe_pois_illnesses)["legal"])
mean_ill <- mean(panel$illnesses_unpast)
sd_ill_pre <- sd(panel$illnesses_unpast[panel$legal == 0])
me_ill   <- beta_ill * mean_ill
sde_ill  <- me_ill / sd_ill_pre
se_sde_ill <- (se_ill * mean_ill) / sd_ill_pre

## Hospitalizations
beta_hosp <- as.numeric(coef(results$twfe_pois_hosp)["legal"])
se_hosp   <- as.numeric(se(results$twfe_pois_hosp)["legal"])
mean_hosp <- mean(panel$hosp_unpast)
sd_hosp_pre <- sd(panel$hosp_unpast[panel$legal == 0])
me_hosp   <- beta_hosp * mean_hosp
sde_hosp  <- me_hosp / sd_hosp_pre
se_sde_hosp <- (se_hosp * mean_hosp) / sd_hosp_pre

## Extensive margin (OLS)
beta_ext <- as.numeric(coef(results$ols_any_outbreak)["post"])
se_ext   <- as.numeric(se(results$ols_any_outbreak)["post"])
any_var  <- panel_cs %>% mutate(a = as.integer(outbreaks_unpast > 0))
sd_ext_pre <- sd(any_var$a[any_var$post == 0 | any_var$first_treat_cs == 0])
sde_ext  <- beta_ext / sd_ext_pre
se_sde_ext <- se_ext / sd_ext_pre

## Classification function
classify_sde <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

## Build SDE rows — ensure all inputs are plain scalars
sde_vec    <- c(sde, sde_ill, sde_hosp, sde_ext)
class_vec  <- character(4)
for (j in 1:4) class_vec[j] <- classify_sde(sde_vec[j])

sde_rows <- data.frame(
  outcome = c("Unpast. dairy outbreaks", "Unpast. dairy illnesses",
              "Unpast. dairy hospitalizations", "Any unpast. outbreak (extensive)"),
  beta    = c(beta_outbreaks, beta_ill, beta_hosp, beta_ext),
  se_beta = c(se_outbreaks, se_ill, se_hosp, se_ext),
  sd_y    = c(sd_y_pre, sd_ill_pre, sd_hosp_pre, sd_ext_pre),
  sde     = sde_vec,
  se_sde  = c(se_sde, se_sde_ill, se_sde_hosp, se_sde_ext),
  class   = class_vec,
  stringsAsFactors = FALSE
)

cat("SDE Results:\n")
print(sde_rows)

## ---- Heterogeneous SDE (Panel B): by access type ----
## Split: herdshare-only vs farm-gate+ legalization
treatment <- read_csv("../data/treatment_coding.csv", show_col_types = FALSE)
herdshare_states <- treatment %>%
  filter(category == "H" & is.finite(first_legal_year) & first_legal_year > 0) %>%
  pull(state_abbr)

fg_states <- treatment %>%
  filter(category %in% c("R", "F") & is.finite(first_legal_year) & first_legal_year > 0) %>%
  pull(state_abbr)

## Herdshare-only subsample
panel_hs <- panel_cs %>%
  filter(first_treat_cs == 0 | state_abbr %in% herdshare_states)

m_hs <- tryCatch({
  fepois(outbreaks_unpast ~ post | state_abbr + year,
         data = panel_hs, cluster = ~state_abbr)
}, error = function(e) NULL)

if (!is.null(m_hs)) {
  beta_hs <- coef(m_hs)["post"]
  se_hs <- se(m_hs)["post"]
  mean_hs <- mean(panel_hs$outbreaks_unpast)
  sd_hs_pre <- sd(panel_hs$outbreaks_unpast[panel_hs$post == 0])
  me_hs <- beta_hs * mean_hs
  sde_hs <- me_hs / sd_hs_pre
  se_sde_hs <- (se_hs * mean_hs) / sd_hs_pre
} else {
  beta_hs <- NA; se_hs <- NA; sde_hs <- NA; se_sde_hs <- NA; sd_hs_pre <- NA
}

## Farm-gate+ subsample
panel_fg <- panel_cs %>%
  filter(first_treat_cs == 0 | state_abbr %in% fg_states)

m_fg <- tryCatch({
  fepois(outbreaks_unpast ~ post | state_abbr + year,
         data = panel_fg, cluster = ~state_abbr)
}, error = function(e) NULL)

if (!is.null(m_fg)) {
  beta_fg <- coef(m_fg)["post"]
  se_fg <- se(m_fg)["post"]
  mean_fg <- mean(panel_fg$outbreaks_unpast)
  sd_fg_pre <- sd(panel_fg$outbreaks_unpast[panel_fg$post == 0])
  me_fg <- beta_fg * mean_fg
  sde_fg <- me_fg / sd_fg_pre
  se_sde_fg <- (se_fg * mean_fg) / sd_fg_pre
} else {
  beta_fg <- NA; se_fg <- NA; sde_fg <- NA; se_sde_fg <- NA; sd_fg_pre <- NA
}

## ---- Write SDE table ----
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level legalization of raw (unpasteurized) milk sales increase foodborne illness outbreaks linked to unpasteurized dairy products? ",
  "\\textbf{Policy mechanism:} State legislation authorizing previously prohibited sales channels for unpasteurized milk (retail stores, on-farm direct sales, or herdshare/cowshare arrangements), expanding consumer access to products that bypass pasteurization and carry elevated pathogen risk from Campylobacter, E.\\ coli O157, Salmonella, and Listeria. ",
  "\\textbf{Outcome definition:} Annual count of foodborne disease outbreaks reported to CDC NORS where the implicated food vehicle is an unpasteurized dairy product (milk or cheese). ",
  "\\textbf{Treatment:} Binary indicator equal to one in state-years where any form of raw milk sales for human consumption is legally permitted. ",
  "\\textbf{Data:} CDC National Outbreak Reporting System (NORS) via Socrata API, 1998--2023, state-year panel; 51 jurisdictions $\\times$ 26 years $=$ 1,326 observations; 258 unpasteurized dairy outbreaks total. ",
  "\\textbf{Method:} Poisson PPML with two-way fixed effects (state + year), standard errors clustered at the state level. Marginal effect $= \\hat{\\beta} \\times \\bar{Y}$; SDE $= (\\hat{\\beta} \\times \\bar{Y}) / \\text{SD}(Y_{\\text{pre}})$ where SD($Y_{\\text{pre}}$) is the pre-treatment standard deviation. ",
  "\\textbf{Sample:} Panel A pools all 51 jurisdictions; states with pre-1998 legalization contribute to the full-panel TWFE but not to the event study. Panel B splits by access breadth: herdshare-only states vs.\\ states legalizing farm-gate or retail sales. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    r$outcome,
    sprintf("%.3f", r$beta), sprintf("%.3f", r$se_beta),
    sprintf("%.3f", r$sd_y), sprintf("%.3f", r$sde),
    sprintf("%.3f", r$se_sde), r$class
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\"
)

## Herdshare row
if (!is.na(sde_hs)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "Outbreaks (herdshare only) & %s & %s & %s & %s & %s & %s \\\\",
    sprintf("%.3f", beta_hs), sprintf("%.3f", se_hs),
    sprintf("%.3f", sd_hs_pre), sprintf("%.3f", sde_hs),
    sprintf("%.3f", se_sde_hs), classify_sde(sde_hs)
  ))
}

## Farm-gate+ row
if (!is.na(sde_fg)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "Outbreaks (farm-gate+) & %s & %s & %s & %s & %s & %s \\\\",
    sprintf("%.3f", beta_fg), sprintf("%.3f", se_fg),
    sprintf("%.3f", sd_fg_pre), sprintf("%.3f", sde_fg),
    sprintf("%.3f", se_sde_fg), classify_sde(sde_fg)
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
