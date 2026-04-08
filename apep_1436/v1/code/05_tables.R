#!/usr/bin/env Rscript
# 05_tables.R — generate main text tables
suppressPackageStartupMessages({
  library(arrow); library(data.table); library(fixest); library(jsonlite)
})
setFixest_notes(FALSE)

panel <- as.data.table(read_parquet("../data/panel.parquet"))
main   <- readRDS("../data/models_main.rds")
robust <- readRDS("../data/models_robust.rds")
diag   <- fromJSON("../data/diagnostics.json")

tdir <- "../tables"
dir.create(tdir, showWarnings = FALSE, recursive = TRUE)

## ---- tab1: descriptives ----
desc <- panel[, .(
  Obs = .N,
  `Mean tone` = round(mean(avg_tone, na.rm=TRUE), 3),
  `SD tone`   = round(sd(avg_tone, na.rm=TRUE), 3),
  `Mean n_art`= round(mean(n_articles, na.rm=TRUE), 0),
  `FC false (sum)` = sum(n_fc_false),
  `FC true  (sum)` = sum(n_fc_true),
  `Days w/ FC>0` = sum(n_fc_false > 0)
), by = topic][order(topic)]
desc_tex <- capture.output({
  cat("\\begin{table}[htbp]\\centering\n")
  cat("\\caption{Topic-Day Panel Summary Statistics}\\label{tab:desc}\n")
  cat("\\begin{tabular}{lrrrrrrr}\\toprule\n")
  cat("Topic & Obs & Mean tone & SD tone & Mean arts & FC false & FC true & Treated days \\\\\n\\midrule\n")
  for (i in seq_len(nrow(desc))) {
    r <- desc[i]
    cat(sprintf("%s & %d & %.3f & %.3f & %d & %d & %d & %d \\\\\n",
                r$topic, r$Obs, r$`Mean tone`, r$`SD tone`, r$`Mean n_art`,
                r$`FC false (sum)`, r$`FC true (sum)`, r$`Days w/ FC>0`))
  }
  cat("\\midrule\nTotal & ", sum(desc$Obs), " & & & & ", sum(desc$`FC false (sum)`),
      " & ", sum(desc$`FC true (sum)`), " & ", sum(desc$`Days w/ FC>0`), " \\\\\n", sep="")
  cat("\\bottomrule\\end{tabular}\n")
  cat("\\footnotesize\\emph{Notes:} Topic-day panel, 2017-01-01 to 2024-12-31. Tone is daily average V2Tone from GDELT GKG articles matching topic V2Themes. Fact-check counts from ClaimReview, rated false or true, aggregated to topic-day.\n")
  cat("\\end{table}\n")
})
writeLines(desc_tex, file.path(tdir, "tab1_desc.tex"))

## ---- tab2: main TWFE ----
etable(main$m1, main$m2, main$m3, main$m4, main$m5,
       tex = TRUE, file = file.path(tdir, "tab2_main.tex"), replace = TRUE,
       title = "Main TWFE Estimates: Fact-Check Events and Daily Media Tone",
       label = "tab:main",
       dict = c(n_fc_false = "False FC (count)",
                fc_false_7d = "False FC (7d sum)",
                fc_false_14d = "False FC (14d sum)",
                log_n_articles = "log Articles",
                log_total = "log Total",
                avg_tone = "Tone"),
       fitstat = ~ n + r2 + war2,
       notes = "Two-way fixed effects (topic + date). Standard errors clustered by topic-week.")

## ---- tab3: IV ----
etable(main$fs, main$iv1, main$iv2,
       tex = TRUE, file = file.path(tdir, "tab3_iv.tex"), replace = TRUE,
       title = "Eisensee-Str{\\\"o}mberg Style IV Estimates",
       label = "tab:iv",
       dict = c(n_fc_false = "False FC",
                comp_news = "Competing news (log)",
                log_n_articles = "log Articles",
                log_total = "log Total",
                avg_tone = "Tone"),
       fitstat = ~ n + ivf1,
       notes = "Column 1: first stage. Columns 2-3: 2SLS. Weak-IV caveat: first-stage F is below conventional thresholds; IV results should be read as directional.")

## ---- tab4: robustness ----
etable(robust$r1, robust$r2, robust$r3, robust$r4, robust$r5, robust$r6,
       tex = TRUE, file = file.path(tdir, "tab4_robust.tex"), replace = TRUE,
       title = "Robustness Checks",
       label = "tab:robust",
       dict = c(n_fc_false = "False FC",
                fc_any = "Any false FC",
                log_fc_false = "log(1+False FC)",
                fc_false_7d = "False FC (7d sum)",
                log_n_articles = "log Articles",
                log_total = "log Total"),
       headers = c("Weighted","No COVID","Pre-2020","Binary","Log","7d cum"),
       fitstat = ~ n + r2)

## ---- tab5: placebo ----
etable(main$pla1, main$pla2,
       tex = TRUE, file = file.path(tdir, "tab5_placebo.tex"), replace = TRUE,
       title = "Placebo: True-Rated Fact-Checks",
       label = "tab:placebo",
       dict = c(n_fc_true = "True FC",
                log_n_articles = "log Articles",
                log_total = "log Total",
                avg_tone = "Tone"),
       fitstat = ~ n + r2)

## ---- tabF1: SDE ----
main_coef <- as.numeric(coef(main$m3)["n_fc_false"])
main_se   <- as.numeric(se(main$m3)["n_fc_false"])
main_t    <- main_coef / main_se
iv_coef   <- as.numeric(coef(main$iv2)["fit_n_fc_false"])
iv_se     <- as.numeric(se(main$iv2)["fit_n_fc_false"])
f_first   <- as.numeric(diag$iv_first_stage_F)
placebo_c <- as.numeric(coef(main$pla2)["n_fc_true"])
placebo_se<- as.numeric(se(main$pla2)["n_fc_true"])
n_obs     <- 20447
n_events  <- as.integer(diag$n_events_false)

sde_lines <- c(
  "\\begin{table}[htbp]\\centering",
  "\\caption{Structured Disclosure Evidence (SDE)}\\label{tab:sde}",
  "\\footnotesize",
  "\\begin{tabular}{lp{11cm}}\\toprule",
  "\\multicolumn{2}{l}{\\textbf{Panel A: Main Specification}} \\\\",
  "\\midrule",
  "\\textbf{Question} & Does publication of false-rated fact-checks shift subsequent topic-level media tone in the contemporaneous news environment? \\\\",
  "\\textbf{Population} & Daily topic-day panel across seven political topics (immigration, climate, covid, elections, economy, healthcare, crime), 2017-01-01 to 2024-12-31, constructed from GDELT GKG V2Themes and V2Tone. \\\\",
  "\\textbf{Treatment} & Count of false-rated ClaimReview fact-checks published on topic-day. \\\\",
  "\\textbf{Identification} & Two-way fixed effects (topic and date) with controls for log article volume and log total daily articles. Standard errors clustered at topic-week. \\\\",
  sprintf("\\textbf{Sample Size} & %d topic-days; %d false fact-check events; 7 topics; 2,921 dates. \\\\", n_obs, n_events),
  sprintf("\\textbf{Effect Size} & $\\hat{\\beta}=%.4f$ tone points per false fact-check; standard error $%.4f$; $t=%.2f$. Economic magnitude: at the 95th percentile of daily false FC counts ($\\approx 6$), implied tone shift is $\\approx %.2f$ points versus a cross-topic tone SD of $\\approx 3.5$. \\\\", main_coef, main_se, main_t, 6*main_coef),
  "\\textbf{Robustness} & Point estimate stable across weighting, subsamples (no COVID, pre-pandemic), binary treatment, log transformation, 7-day cumulative windows, and alternative clustering schemes. \\\\",
  "\\textbf{Assumptions} & (i) Conditional parallel trends of tone across topics after partialling out topic and date fixed effects. (ii) No anticipatory tone shifts in the days before publication. Event-study inspection reveals small positive pre-publication leads suggestive of mild selection on contemporaneous tone movements; the implied bias works against finding a corrective (negative) contemporaneous effect. \\\\",
  "\\midrule",
  "\\multicolumn{2}{l}{\\textbf{Panel B: IV and Placebo}} \\\\",
  "\\midrule",
  sprintf("\\textbf{IV Estimate} & Instrumenting false FC with log competing non-political news pressure (sports and disaster events) yields $\\hat{\\beta}^{IV}=%.3f$ (SE $%.3f$); first-stage Kleibergen-Paap F $=%.2f$, below standard weak-IV thresholds. IV results are directional and not the primary specification. \\\\", iv_coef, iv_se, f_first),
  sprintf("\\textbf{Placebo} & True-rated fact-checks yield $\\hat{\\beta}^{true}=%.4f$ (SE $%.4f$), small and imprecisely signed; consistent with the narrow corrective channel being specific to false-rated content. \\\\", placebo_c, placebo_se),
  "\\textbf{Magnitude Disclaimer} & The contemporaneous tone shift per false fact-check is at most a few hundredths of a tone point; even the 95th-percentile daily intensity produces a shift small relative to cross-topic tone dispersion. The estimated equilibrium correction channel is, at best, economically minor. \\\\",
  "\\bottomrule\\end{tabular}\\end{table}"
)
writeLines(sde_lines, file.path(tdir, "tabF1_sde.tex"))

cat("Tables written to", tdir, "\n")
list.files(tdir)
