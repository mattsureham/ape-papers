## 05_tables.R — Generate all LaTeX tables
## APEP-1112: The Alliance Ratchet
##
## Tables:
##   tab1_summary.tex — Summary statistics
##   tab2_main.tex — Main DiD results
##   tab3_event_study.tex — Event study coefficients
##   tab4_mechanisms.tex — Market structure mechanisms
##   tab5_robustness.tex — Robustness checks
##   tabF1_sde.tex — Standardized effect sizes (appendix)

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## Helper: format number with significance stars
fmt_coef <- function(b, se, digits = 3) {
  p <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.${digits}f%s", b, stars)
}

fmt_se <- function(se, digits = 3) {
  sprintf("(%.${digits}f)", se)
}

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("Writing Table 1: Summary Statistics\n")

## Compute stats by treatment group
stats_fn <- function(dt, label) {
  data.frame(
    Group = label,
    N = format(nrow(dt), big.mark = ","),
    Routes = uniqueN(dt$route),
    MeanFare = sprintf("%.0f", mean(dt$avg_fare)),
    SDFare = sprintf("%.0f", sd(dt$avg_fare)),
    MedFare = sprintf("%.0f", median(dt$avg_fare)),
    MeanPax = sprintf("%.0f", mean(dt$total_pax)),
    MeanHHI = sprintf("%.0f", mean(dt$hhi)),
    MeanCarriers = sprintf("%.1f", mean(dt$n_carriers)),
    MeanDist = sprintf("%.0f", mean(dt$avg_distance))
  )
}

pre_treated <- panel[treated == 1 & period == "pre"]
pre_control <- panel[treated == 0 & period == "pre"]
form_treated <- panel[treated == 1 & period == "formation"]
diss_treated <- panel[treated == 1 & period == "dissolution"]

s1 <- stats_fn(pre_treated, "Treated, Pre-NEA")
s2 <- stats_fn(pre_control, "Control, Pre-NEA")
s3 <- stats_fn(form_treated, "Treated, Formation")
s4 <- stats_fn(diss_treated, "Treated, Dissolution")

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Treatment Status and Period}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrrrr}\n",
  "\\toprule\n",
  " & Obs. & Routes & Mean Fare & SD Fare & Median Fare & Mean Pax & HHI & Carriers \\\\\n",
  "\\midrule\n",
  sprintf("\\multicolumn{9}{l}{\\textit{Panel A: Pre-NEA Period (Q1 2018--Q4 2020)}} \\\\\n"),
  sprintf("Treated routes & %s & %s & \\$%s & \\$%s & \\$%s & %s & %s & %s \\\\\n",
          s1$N, s1$Routes, s1$MeanFare, s1$SDFare, s1$MedFare, s1$MeanPax, s1$MeanHHI, s1$MeanCarriers),
  sprintf("Control routes & %s & %s & \\$%s & \\$%s & \\$%s & %s & %s & %s \\\\\n",
          s2$N, s2$Routes, s2$MeanFare, s2$SDFare, s2$MedFare, s2$MeanPax, s2$MeanHHI, s2$MeanCarriers),
  "\\midrule\n",
  sprintf("\\multicolumn{9}{l}{\\textit{Panel B: NEA Formation Period (Q1 2021--Q2 2023)}} \\\\\n"),
  sprintf("Treated routes & %s & %s & \\$%s & \\$%s & \\$%s & %s & %s & %s \\\\\n",
          s3$N, s3$Routes, s3$MeanFare, s3$SDFare, s3$MedFare, s3$MeanPax, s3$MeanHHI, s3$MeanCarriers),
  "\\midrule\n",
  sprintf("\\multicolumn{9}{l}{\\textit{Panel C: Post-Dissolution Period (Q3 2023--Q4 2024)}} \\\\\n"),
  sprintf("Treated routes & %s & %s & \\$%s & \\$%s & \\$%s & %s & %s & %s \\\\\n",
          s4$N, s4$Routes, s4$MeanFare, s4$SDFare, s4$MedFare, s4$MeanPax, s4$MeanHHI, s4$MeanCarriers),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\begin{flushleft}\n",
  "\\textit{Notes:} Data from BTS DB1B 10\\% ticket sample. Treated routes are directional ",
  "airport-pair ",
  "markets at JFK, LGA, BOS, or EWR where both JetBlue (B6) and American Airlines (AA) operated pre-NEA. ",
  "Control routes are at the same airports served by carriers not party to the NEA. ",
  "Fares are nominal itinerary-level market fares (\\texttt{MktFare}). HHI is calculated from ",
  "operating-carrier passenger shares ($\\times 10{,}000$). ",
  "Pax is total quarterly passengers on the route.\n",
  "\\end{flushleft}}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

## ============================================================
## Table 2: Main DiD Results
## ============================================================
cat("Writing Table 2: Main DiD Results\n")

main <- results$main_did
weighted <- results$weighted_did

## Extract coefficients
b1 <- coef(main)["treated:formation"]
b2 <- coef(main)["treated:dissolution"]
s1_se <- se(main)["treated:formation"]
s2_se <- se(main)["treated:dissolution"]

bw1 <- coef(weighted)["treated:formation"]
bw2 <- coef(weighted)["treated:dissolution"]
sw1 <- se(weighted)["treated:formation"]
sw2 <- se(weighted)["treated:dissolution"]

## Ratchet = formation + dissolution effect (net permanent shift)
ratchet <- b1 + b2
ratchet_se <- sqrt(vcov(main)["treated:formation", "treated:formation"] +
                     vcov(main)["treated:dissolution", "treated:dissolution"] +
                     2 * vcov(main)["treated:formation", "treated:dissolution"])

ratchet_w <- bw1 + bw2
ratchet_w_se <- sqrt(vcov(weighted)["treated:formation", "treated:formation"] +
                       vcov(weighted)["treated:dissolution", "treated:dissolution"] +
                       2 * vcov(weighted)["treated:formation", "treated:dissolution"])

stars <- function(b, se) {
  p <- 2 * pnorm(-abs(b / se))
  ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
}

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of the Northeast Alliance on Route-Level Fares}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Unweighted & Passenger-Weighted \\\\\n",
  "\\midrule\n",
  sprintf("Treated $\\times$ Formation & $%.4f%s$ & $%.4f%s$ \\\\\n",
          b1, stars(b1, s1_se), bw1, stars(bw1, sw1)),
  sprintf(" & $(%.4f)$ & $(%.4f)$ \\\\\n", s1_se, sw1),
  "",
  sprintf("Treated $\\times$ Dissolution & $%.4f%s$ & $%.4f%s$ \\\\\n",
          b2, stars(b2, s2_se), bw2, stars(bw2, sw2)),
  sprintf(" & $(%.4f)$ & $(%.4f)$ \\\\\n", s2_se, sw2),
  "",
  "\\midrule\n",
  sprintf("Persistence ($\\hat{\\beta}_2 / \\hat{\\beta}_1$) & --- & %.1f\\%% \\\\\n",
          100 * bw2 / bw1),
  sprintf("$p$-value: $\\hat{\\beta}_2 = 0$ & %.3f & %.3f \\\\\n",
          2 * pnorm(-abs(b2 / s2_se)),
          2 * pnorm(-abs(bw2 / sw2))),
  "\\midrule\n",
  sprintf("Route FE & Yes & Yes \\\\\n"),
  sprintf("Quarter FE & Yes & Yes \\\\\n"),
  sprintf("Observations & %s & %s \\\\\n",
          format(nobs(main), big.mark = ","),
          format(nobs(weighted), big.mark = ",")),
  sprintf("Routes & %d & %d \\\\\n",
          uniqueN(panel$route), uniqueN(panel$route)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log average fare. ",
  "``Treated $\\times$ Formation'' captures the fare effect during the NEA period (Q1 2021--Q2 2023). ",
  "``Treated $\\times$ Dissolution'' captures the fare level after court-ordered dissolution (Q3 2023--Q4 2024), relative to the pre-NEA baseline. ",
  "Persistence is $\\hat{\\beta}_2 / \\hat{\\beta}_1$: the fraction of the formation effect that survived dissolution (shown only when both coefficients have the same sign). ",
  "The $p$-value tests $\\hat{\\beta}_2 = 0$ (full reversion to pre-NEA fares). ",
  "Standard errors in parentheses, two-way clustered by route and quarter. ",
  "$^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

## ============================================================
## Table 3: Event Study Coefficients
## ============================================================
cat("Writing Table 3: Event Study\n")

es <- results$es_did
es_coefs <- coef(es)
es_ses <- se(es)

## Extract event-time coefficients
es_names <- names(es_coefs)
es_df <- data.frame(
  name = es_names,
  coef = es_coefs,
  se = es_ses,
  stringsAsFactors = FALSE
)
## Parse q_index from names like "q_index::-11:treated"
es_df$q <- as.integer(gsub(".*::([-0-9]+):.*", "\\1", es_df$name))
es_df <- es_df[order(es_df$q), ]

## Map q_index to calendar quarter
es_df$yq <- sapply(es_df$q, function(qi) {
  yr <- 2020 + (qi + 4 - 1) %/% 4
  qq <- ((qi + 4 - 1) %% 4) + 1
  sprintf("%dQ%d", yr, qq)
})

## Build table rows
es_rows <- paste(sapply(1:nrow(es_df), function(i) {
  p <- 2 * pnorm(-abs(es_df$coef[i] / es_df$se[i]))
  s <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  period_label <- ifelse(es_df$q[i] < 1, "Pre", ifelse(es_df$q[i] <= 10, "Form.", "Diss."))
  sprintf("%s & %s & $%.4f%s$ & $(%.4f)$ \\\\", es_df$yq[i], period_label, es_df$coef[i], s, es_df$se[i])
}), collapse = "\n")

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Quarter-by-Quarter Fare Effects}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcc}\n",
  "\\toprule\n",
  "Quarter & Period & Coefficient & SE \\\\\n",
  "\\midrule\n",
  es_rows, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from event-study specification with route and quarter fixed effects. ",
  "Baseline period is Q4 2020 (last pre-NEA quarter, normalized to zero). ",
  "``Pre'' = pre-formation; ``Form.'' = NEA active; ``Diss.'' = post-dissolution. ",
  "Two-way clustered SEs (route, quarter). ",
  "$^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(tables_dir, "tab3_event_study.tex"))

## ============================================================
## Table 4: Mechanisms (Market Structure)
## ============================================================
cat("Writing Table 4: Mechanisms\n")

hhi <- results$hhi_did
ncar <- results$ncarrier_did
pax <- results$pax_did

mech_row <- function(model, label) {
  cf <- coef(model)
  ses <- se(model)
  b_f <- cf["treated:formation"]
  b_d <- cf["treated:dissolution"]
  s_f <- ses["treated:formation"]
  s_d <- ses["treated:dissolution"]
  p_f <- 2 * pnorm(-abs(b_f / s_f))
  p_d <- 2 * pnorm(-abs(b_d / s_d))
  st_f <- ifelse(p_f < 0.01, "^{***}", ifelse(p_f < 0.05, "^{**}", ifelse(p_f < 0.1, "^{*}", "")))
  st_d <- ifelse(p_d < 0.01, "^{***}", ifelse(p_d < 0.05, "^{**}", ifelse(p_d < 0.1, "^{*}", "")))
  paste0(
    sprintf("%s & $%.3f%s$ & $%.3f%s$ & %s \\\\\n", label, b_f, st_f, b_d, st_d,
            format(nobs(model), big.mark = ",")),
    sprintf(" & $(%.3f)$ & $(%.3f)$ & \\\\\n", s_f, s_d)
  )
}

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Mechanism Tests: Market Structure Responses}\n",
  "\\label{tab:mechanisms}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Formation & Dissolution & Obs. \\\\\n",
  "\\midrule\n",
  mech_row(hhi, "HHI ($\\times 10{,}000$)"),
  "",
  mech_row(ncar, "Number of carriers"),
  "",
  mech_row(pax, "Log passengers"),
  "\\midrule\n",
  "Route FE & Yes & Yes & \\\\\n",
  "Quarter FE & Yes & Yes & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row is a separate regression of the outcome on Treated $\\times$ Formation and ",
  "Treated $\\times$ Dissolution with route and quarter FE. Two-way clustered SEs (route, quarter). ",
  "$^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(tables_dir, "tab4_mechanisms.tex"))

## ============================================================
## Table 5: Robustness Checks
## ============================================================
cat("Writing Table 5: Robustness\n")

rob_row <- function(model, label) {
  cf <- coef(model)
  ses <- se(model)
  # Handle different coefficient names
  form_name <- grep("formation", names(cf), value = TRUE)[1]
  diss_name <- grep("dissolution", names(cf), value = TRUE)[1]

  if (is.na(form_name) || is.na(diss_name)) return("")

  b_f <- cf[form_name]
  b_d <- cf[diss_name]
  s_f <- ses[form_name]
  s_d <- ses[diss_name]
  p_f <- 2 * pnorm(-abs(b_f / s_f))
  p_d <- 2 * pnorm(-abs(b_d / s_d))
  st_f <- ifelse(p_f < 0.01, "^{***}", ifelse(p_f < 0.05, "^{**}", ifelse(p_f < 0.1, "^{*}", "")))
  st_d <- ifelse(p_d < 0.01, "^{***}", ifelse(p_d < 0.05, "^{**}", ifelse(p_d < 0.1, "^{*}", "")))

  ratchet <- b_f + b_d
  ratchet_se <- tryCatch({
    v <- vcov(model)
    sqrt(v[form_name, form_name] + v[diss_name, diss_name] + 2 * v[form_name, diss_name])
  }, error = function(e) NA)
  p_r <- if (!is.na(ratchet_se)) 2 * pnorm(-abs(ratchet / ratchet_se)) else NA
  st_r <- if (!is.na(p_r)) ifelse(p_r < 0.01, "^{***}", ifelse(p_r < 0.05, "^{**}", ifelse(p_r < 0.1, "^{*}", ""))) else ""

  paste0(
    sprintf("%s & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & %s \\\\\n",
            label, b_f, st_f, b_d, st_d, ratchet, st_r,
            format(nobs(model), big.mark = ",")),
    sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ & \\\\\n", s_f, s_d,
            ifelse(!is.na(ratchet_se), ratchet_se, 0))
  )
}

tab5 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Formation & Dissolution & Ratchet & Obs. \\\\\n",
  "\\midrule\n",
  rob_row(results$main_did, "(1) Baseline"),
  "",
  rob_row(rob_results$rob_median, "(2) Median fare"),
  "",
  rob_row(rob_results$rob_fpm, "(3) Fare per mile"),
  "",
  rob_row(rob_results$rob_placebo, "(4) Placebo"),
  "",
  rob_row(rob_results$rob_nocovid, "(5) Excl.\\ COVID"),
  "",
  rob_row(rob_results$rob_trends, "(6) Route trends"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Row (1) reproduces the baseline from Table~\\ref{tab:main}. ",
  "(2) uses log median fare. (3) uses log fare per mile. ",
  "(4) is a placebo test on control routes never served by JetBlue or American, split at median HHI. ",
  "(5) excludes Q2 2020--Q1 2021 (COVID disruption). ",
  "(6) adds route-specific linear time trends. ",
  "``Ratchet'' = Formation + Dissolution. ",
  "All specifications include route and quarter FE. Two-way clustered SEs (route, quarter) except row (4). ",
  "$^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab5, file.path(tables_dir, "tab5_robustness.tex"))

## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================
cat("Writing Table F1: Standardized Effect Sizes\n")

## Main specification: formation and dissolution effects on log fare
sd_y <- sd(panel$log_fare)
sd_y_pre <- sd(panel$log_fare[panel$period == "pre"])

## Use pre-treatment SD(Y) for SDE
beta_form <- coef(results$main_did)["treated:formation"]
se_form <- se(results$main_did)["treated:formation"]
beta_diss <- coef(results$main_did)["treated:dissolution"]
se_diss <- se(results$main_did)["treated:dissolution"]

## Ratchet (net permanent effect)
ratchet_beta <- beta_form + beta_diss
ratchet_se_val <- sqrt(
  vcov(results$main_did)["treated:formation", "treated:formation"] +
    vcov(results$main_did)["treated:dissolution", "treated:dissolution"] +
    2 * vcov(results$main_did)["treated:formation", "treated:dissolution"]
)

## SDE = beta / SD(Y) (binary treatment)
sde_form <- beta_form / sd_y_pre
sde_se_form <- se_form / sd_y_pre
sde_diss <- beta_diss / sd_y_pre
sde_se_diss <- se_diss / sd_y_pre
sde_ratchet <- ratchet_beta / sd_y_pre
sde_se_ratchet <- ratchet_se_val / sd_y_pre

## Classification function
classify <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

## Heterogeneity: high-volume vs low-volume treated routes
pre_pax <- panel[period == "pre" & treated == 1, .(avg_pax = mean(total_pax)), by = route]
med_pax <- median(pre_pax$avg_pax)
high_vol_routes <- pre_pax[avg_pax >= med_pax, route]
panel[, high_volume := as.integer(route %in% high_vol_routes)]

## Subset to treated + control routes, split treated by volume
het_high <- feols(
  log_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel[high_volume == 1 | treated == 0],
  cluster = ~route + yq
)
het_low <- feols(
  log_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel[high_volume == 0 | treated == 0],
  cluster = ~route + yq
)

sd_y_pre_high <- sd(panel$log_fare[panel$period == "pre" & (panel$high_volume == 1 | panel$treated == 0)])
sd_y_pre_low <- sd(panel$log_fare[panel$period == "pre" & (panel$high_volume == 0 | panel$treated == 0)])

## Use ratchet (net effect) for heterogeneity
ratchet_high <- coef(het_high)["treated:formation"] + coef(het_high)["treated:dissolution"]
ratchet_high_se <- sqrt(
  vcov(het_high)["treated:formation", "treated:formation"] +
    vcov(het_high)["treated:dissolution", "treated:dissolution"] +
    2 * vcov(het_high)["treated:formation", "treated:dissolution"]
)
ratchet_low <- coef(het_low)["treated:formation"] + coef(het_low)["treated:dissolution"]
ratchet_low_se <- sqrt(
  vcov(het_low)["treated:formation", "treated:formation"] +
    vcov(het_low)["treated:dissolution", "treated:dissolution"] +
    2 * vcov(het_low)["treated:formation", "treated:dissolution"]
)

sde_high <- ratchet_high / sd_y_pre_high
sde_se_high <- ratchet_high_se / sd_y_pre_high
sde_low <- ratchet_low / sd_y_pre_low
sde_se_low <- ratchet_low_se / sd_y_pre_low

## Build SDE notes string
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the court-ordered dissolution of the JetBlue--American Northeast Alliance ",
  "fully reverse fare increases on affected routes, or do coordination-induced pricing norms persist---creating ",
  "an ``alliance ratchet'' that limits antitrust effectiveness? ",
  "\\textbf{Policy mechanism:} The Northeast Alliance (NEA) allowed JetBlue and American Airlines to pool revenue, ",
  "jointly schedule flights, codeshare on 175+ routes, and swap slots at JFK, LGA, BOS, and EWR---effectively ",
  "coordinating pricing and capacity on overlapping routes in the northeastern United States. A federal court ",
  "ordered dissolution for violating antitrust law, unwinding the coordination. ",
  "\\textbf{Outcome definition:} Log average itinerary-level market fare (\\texttt{MktFare}) from the BTS DB1B ",
  "10\\% ticket sample, aggregated to the directional airport-pair route by quarter. ",
  "\\textbf{Treatment:} Binary---routes at NEA airports (JFK, LGA, BOS, EWR) where both JetBlue and American ",
  "Airlines operated pre-alliance vs.\\ control routes at the same airports served by non-NEA carriers. ",
  "\\textbf{Data:} BTS DB1B Market data (10\\% domestic ticket sample), Q1 2018--Q4 2024, directional route-quarter ",
  "panel; ", format(nrow(panel), big.mark = ","), " observations across ", uniqueN(panel$route), " routes. ",
  "\\textbf{Method:} Two-way fixed effects DiD (route + quarter FE) with two treatment indicators (formation and dissolution); ",
  "the ``ratchet'' is the sum of both coefficients, measuring the net permanent fare effect; two-way clustered SEs by route and quarter. ",
  "\\textbf{Sample:} Routes with at least one NEA airport endpoint and at least three pre-NEA quarters of data; ",
  "bulk fares, fares below \\$20 or above \\$5{,}000 excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log average fare. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log fare & Formation & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_form, se_form, sd_y_pre, sde_form, sde_se_form, classify(sde_form)),
  sprintf("Log fare & Dissolution & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          beta_diss, se_diss, sd_y_pre, sde_diss, sde_se_diss, classify(sde_diss)),
  sprintf("Log fare & Ratchet (net) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          ratchet_beta, ratchet_se_val, sd_y_pre, sde_ratchet, sde_se_ratchet, classify(sde_ratchet)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (Ratchet by Route Volume)}} \\\\\n",
  sprintf("Log fare & High-volume routes & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          ratchet_high, ratchet_high_se, sd_y_pre_high, sde_high, sde_se_high, classify(sde_high)),
  sprintf("Log fare & Low-volume routes & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
          ratchet_low, ratchet_low_se, sd_y_pre_low, sde_low, sde_se_low, classify(sde_low)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\begin{flushleft}\n",
  sde_notes, "\n",
  "\\end{flushleft}}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables written to tables/ ===\n")
cat(list.files(tables_dir, pattern = "\\.tex$"), sep = "\n")
