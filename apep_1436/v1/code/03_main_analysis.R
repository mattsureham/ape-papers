#!/usr/bin/env Rscript
# 03_main_analysis.R — TWFE + IV estimation
suppressPackageStartupMessages({
  library(arrow); library(data.table); library(fixest); library(jsonlite)
})
setFixest_notes(FALSE)

panel <- as.data.table(read_parquet("../data/panel.parquet"))
panel[, topic := factor(topic)]

## Main TWFE: contemporaneous
m1 <- feols(avg_tone ~ n_fc_false | topic + date, panel, cluster = ~topic_week)
m2 <- feols(avg_tone ~ n_fc_false + log_n_articles | topic + date, panel, cluster = ~topic_week)
m3 <- feols(avg_tone ~ n_fc_false + log_n_articles + log_total | topic + date, panel, cluster = ~topic_week)

## With 7d lag (moving average of last 7 days of false fact-checks)
setkey(panel, topic, date)
panel[, fc_false_7d := frollsum(n_fc_false, 7, align="right"), by = topic]
panel[, fc_false_14d := frollsum(n_fc_false, 14, align="right"), by = topic]
m4 <- feols(avg_tone ~ fc_false_7d | topic + date, panel, cluster = ~topic_week)
m5 <- feols(avg_tone ~ fc_false_14d + log_n_articles | topic + date, panel, cluster = ~topic_week)

## IV: instrument n_fc_false with competing-news pressure
## First stage: comp_news -> n_fc_false
fs <- feols(n_fc_false ~ comp_news + log_total | topic + topic^month, panel, cluster = ~topic_week)
iv1 <- feols(avg_tone ~ log_total | topic + topic^month | n_fc_false ~ comp_news,
             panel, cluster = ~topic_week)
iv2 <- feols(avg_tone ~ log_n_articles + log_total | topic + topic^month | n_fc_false ~ comp_news,
             panel, cluster = ~topic_week)

## Event study: leads/lags -7 to +7 of n_fc_false
el_vars <- c(paste0("fc_false_lm", 7:1), "n_fc_false", paste0("fc_false_l", 1:7))
el_present <- el_vars[el_vars %in% names(panel)]
fml_es <- as.formula(paste("avg_tone ~", paste(el_present, collapse=" + "), "| topic + date"))
es <- feols(fml_es, panel, cluster = ~topic_week)

## Placebo: true-rated fact-checks (no correction expected)
pla1 <- feols(avg_tone ~ n_fc_true | topic + date, panel, cluster = ~topic_week)
pla2 <- feols(avg_tone ~ n_fc_true + log_n_articles + log_total | topic + date, panel, cluster = ~topic_week)

## Save models
saveRDS(list(m1=m1,m2=m2,m3=m3,m4=m4,m5=m5,fs=fs,iv1=iv1,iv2=iv2,es=es,pla1=pla1,pla2=pla2),
        "../data/models_main.rds")

cat("=== MAIN TWFE ===\n"); print(etable(m1,m2,m3,m4,m5))
cat("=== FIRST STAGE ===\n"); print(summary(fs))
cat("=== IV ===\n"); print(etable(iv1,iv2))
cat("=== EVENT STUDY ===\n"); print(summary(es))
cat("=== PLACEBO (TRUE) ===\n"); print(etable(pla1,pla2))

## Extract key stats for diagnostics
main_coef <- as.numeric(coef(m3)["n_fc_false"])
main_se   <- as.numeric(se(m3)["n_fc_false"])
iv_coef   <- as.numeric(coef(iv2)["fit_n_fc_false"])
iv_se     <- as.numeric(se(iv2)["fit_n_fc_false"])
f_first   <- tryCatch(fitstat(iv2, "ivf1")[[1]]$stat, error = function(e) NA_real_)

diag <- fromJSON("../data/diagnostics.json")
diag$main_coef_tone_per_falseFC <- main_coef
diag$main_se <- main_se
diag$iv_coef <- iv_coef
diag$iv_se <- iv_se
diag$iv_first_stage_F <- f_first
diag$placebo_true_coef <- as.numeric(coef(pla2)["n_fc_true"])
diag$placebo_true_se   <- as.numeric(se(pla2)["n_fc_true"])
writeLines(toJSON(diag, auto_unbox = TRUE, pretty = TRUE),
           "../data/diagnostics.json")
cat("\nDiagnostics written. main_coef=", main_coef, " iv_coef=", iv_coef, " F=", f_first, "\n")
