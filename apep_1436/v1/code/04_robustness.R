#!/usr/bin/env Rscript
# 04_robustness.R
suppressPackageStartupMessages({
  library(arrow); library(data.table); library(fixest); library(jsonlite)
})
setFixest_notes(FALSE)

panel <- as.data.table(read_parquet("../data/panel.parquet"))

## 1. Weighted by article volume
r1 <- feols(avg_tone ~ n_fc_false + log_n_articles + log_total | topic + date,
            panel, cluster = ~topic_week, weights = ~n_articles)

## 2. Drop COVID topic (heavy fact-check volume, possibly confounding)
p2 <- panel[topic != "covid"]
r2 <- feols(avg_tone ~ n_fc_false + log_n_articles + log_total | topic + date,
            p2, cluster = ~topic_week)

## 3. Pre-pandemic only
p3 <- panel[date < as.Date("2020-03-01")]
r3 <- feols(avg_tone ~ n_fc_false + log_n_articles + log_total | topic + date,
            p3, cluster = ~topic_week)

## 4. Binary treatment (any false fact-check)
panel[, fc_any := as.integer(n_fc_false > 0)]
r4 <- feols(avg_tone ~ fc_any + log_n_articles + log_total | topic + date,
            panel, cluster = ~topic_week)

## 5. log-transform treatment
panel[, log_fc_false := log1p(n_fc_false)]
r5 <- feols(avg_tone ~ log_fc_false + log_n_articles + log_total | topic + date,
            panel, cluster = ~topic_week)

## 6. 7-day window cumulative
panel[, fc_false_7d := frollsum(n_fc_false, 7, align="right"), by = topic]
r6 <- feols(avg_tone ~ fc_false_7d + log_n_articles + log_total | topic + date,
            panel, cluster = ~topic_week)

## 7. Alternative clustering (topic + date two-way)
r7 <- feols(avg_tone ~ n_fc_false + log_n_articles + log_total | topic + date,
            panel, cluster = ~topic + date)

## 8. HC1 SE
r8 <- feols(avg_tone ~ n_fc_false + log_n_articles + log_total | topic + date,
            panel, vcov = "HC1")

saveRDS(list(r1=r1,r2=r2,r3=r3,r4=r4,r5=r5,r6=r6,r7=r7,r8=r8),
        "../data/models_robust.rds")
print(etable(r1,r2,r3,r4,r5,r6,r7,r8))
