## ============================================================
## Italian Bar Exam Sorteggio: Revised Analysis
## Addresses Codex structural review: FE-purged leniency,
## drop 2024, honest presentation
## ============================================================

library(data.table)
library(fixest)
library(ggplot2)

OUT <- "output/paper_italy_sorteggio/v1"

## ----------------------------------------------------------
## 1. Load and Clean Panel (drop 2024)
## ----------------------------------------------------------
dt <- fread(file.path(OUT, "data/panel.csv"))

# Fix fascia assignments
fascia_map <- data.table(
  candidate_court = c(
    "Milano", "Roma", "Napoli",
    "Bologna", "Palermo", "Catania", "Catanzaro", "Venezia",
    "Firenze", "Salerno", "Torino", "Bari",
    "Ancona", "Messina", "Reggio Calabria", "Brescia", "Cagliari",
    "L'Aquila", "Genova", "Lecce",
    "Potenza", "Trieste", "Perugia", "Trento", "Caltanissetta", "Campobasso"
  ),
  fascia_correct = c(
    rep("A", 3), rep("B", 5), rep("C", 4), rep("D", 8), rep("E", 6)
  )
)
dt <- merge(dt, fascia_map, by = "candidate_court", all.x = TRUE)
dt[is.na(fascia_correct), fascia_correct := fascia]
dt[, fascia := fascia_correct][, fascia_correct := NULL]

# DROP 2024 (only 3 courts — effectively anecdotal)
dt <- dt[exam_year != 2024]

# COVID format
dt[, covid_oral := as.integer(exam_year %in% c(2020, 2021, 2022))]
dt[, written := 1L - covid_oral]

cat("Panel: ", nrow(dt), "obs,", uniqueN(dt$candidate_court), "courts,",
    uniqueN(dt$exam_year), "years\n")
cat("Years:", paste(sort(unique(dt$exam_year)), collapse=", "), "\n")
cat("Written:", sum(dt$written), "| Oral:", sum(dt$covid_oral), "\n\n")

## ----------------------------------------------------------
## 2. Summary Statistics
## ----------------------------------------------------------
cat("=== Summary ===\n")
print(dt[, .(N = .N, mean = round(mean(pass_rate), 3),
             sd = round(sd(pass_rate), 3),
             min = round(min(pass_rate), 3),
             max = round(max(pass_rate), 3)), by = exam_year][order(exam_year)])

## ----------------------------------------------------------
## 3. Variance Decomposition
## ----------------------------------------------------------
total_var <- var(dt$pass_rate)
court_means <- dt[, .(mean_pr = mean(pass_rate)), by = candidate_court]
between_var <- var(court_means$mean_pr)
dt[, court_mean := mean(pass_rate), by = candidate_court]
within_var <- var(dt$pass_rate - dt$court_mean)

cat("\n=== Variance Decomposition ===\n")
cat("Total:  ", round(total_var, 6), "\n")
cat("Between:", round(between_var, 6), "(", round(between_var/total_var*100, 1), "%)\n")
cat("Within: ", round(within_var, 6), "(", round(within_var/total_var*100, 1), "%)\n\n")

# Written-only decomposition
dt_w <- dt[written == 1]
tv_w <- var(dt_w$pass_rate)
cm_w <- dt_w[, .(m = mean(pass_rate)), by = candidate_court]
bv_w <- var(cm_w$m)
dt_w[, cm := mean(pass_rate), by = candidate_court]
wv_w <- var(dt_w$pass_rate - dt_w$cm)
cat("Written only: total=", round(tv_w, 6),
    " between=", round(bv_w/tv_w*100, 1), "%",
    " within=", round(wv_w/tv_w*100, 1), "%\n\n")

## ----------------------------------------------------------
## 4. RAW Leniency (for comparison — this is the contaminated measure)
## ----------------------------------------------------------
dt[, raw_leniency := {
  loo <- numeric(.N)
  for (i in seq_len(.N)) {
    gc <- grading_court[i]
    others <- dt[grading_court == gc &
                   !(candidate_court == .SD$candidate_court[i] &
                       exam_year == .SD$exam_year[i])]
    loo[i] <- if (nrow(others) > 0) mean(others$pass_rate) else NA_real_
  }
  loo
}]

## ----------------------------------------------------------
## 5. FE-PURGED Leniency (Codex-recommended fix)
## ----------------------------------------------------------
# Step 1: Regress pass_rate on court + year FE, get residuals
fe_mod <- feols(pass_rate ~ 1 | candidate_court + exam_year, data = dt)
dt[, resid_pr := residuals(fe_mod)]

# Step 2: Build LOO leniency from residuals
dt[, purged_leniency := {
  loo <- numeric(.N)
  for (i in seq_len(.N)) {
    gc <- grading_court[i]
    others <- dt[grading_court == gc &
                   !(candidate_court == .SD$candidate_court[i] &
                       exam_year == .SD$exam_year[i])]
    loo[i] <- if (nrow(others) > 0) mean(others$resid_pr) else NA_real_
  }
  loo
}]

cat("=== Leniency Measures ===\n")
cat("Raw:    N=", sum(!is.na(dt$raw_leniency)), " sd=", round(sd(dt$raw_leniency, na.rm=TRUE), 4), "\n")
cat("Purged: N=", sum(!is.na(dt$purged_leniency)), " sd=", round(sd(dt$purged_leniency, na.rm=TRUE), 4), "\n")
cat("Correlation:", round(cor(dt$raw_leniency, dt$purged_leniency, use="complete"), 3), "\n\n")

## ----------------------------------------------------------
## 6. Main Regressions (both measures)
## ----------------------------------------------------------
cat("=== Main Regressions ===\n\n")

# Model 1: Raw leniency, court + year FE (full sample)
m1 <- feols(pass_rate ~ raw_leniency | candidate_court + exam_year, data = dt, vcov = "hetero")
cat("M1 (Raw leniency, all years):\n")
cat("  coef =", round(coef(m1), 3), " se =", round(se(m1), 3),
    " t =", round(tstat(m1), 2), " p =", round(pvalue(m1), 4), "\n")

# Model 2: Purged leniency, court + year FE (full sample)
m2 <- feols(pass_rate ~ purged_leniency | candidate_court + exam_year, data = dt, vcov = "hetero")
cat("M2 (Purged leniency, all years):\n")
cat("  coef =", round(coef(m2), 3), " se =", round(se(m2), 3),
    " t =", round(tstat(m2), 2), " p =", round(pvalue(m2), 4), "\n")

# Model 3: Raw leniency, written only
m3 <- feols(pass_rate ~ raw_leniency | candidate_court + exam_year,
            data = dt[written == 1], vcov = "hetero")
cat("M3 (Raw leniency, written only):\n")
cat("  coef =", round(coef(m3), 3), " se =", round(se(m3), 3),
    " t =", round(tstat(m3), 2), " p =", round(pvalue(m3), 4), "\n")

# Model 4: Purged leniency, written only
m4 <- feols(pass_rate ~ purged_leniency | candidate_court + exam_year,
            data = dt[written == 1], vcov = "hetero")
cat("M4 (Purged leniency, written only):\n")
cat("  coef =", round(coef(m4), 3), " se =", round(se(m4), 3),
    " t =", round(tstat(m4), 2), " p =", round(pvalue(m4), 4), "\n")

# Model 5: Pooled raw (no FE, for context)
m5 <- feols(pass_rate ~ raw_leniency, data = dt, vcov = "hetero")
cat("M5 (Pooled raw, no FE):\n")
cat("  coef =", round(coef(m5)[2], 3), " se =", round(se(m5)[2], 3),
    " t =", round(tstat(m5)[2], 2), "\n\n")

## ----------------------------------------------------------
## 7. Export Revised Table
## ----------------------------------------------------------
etable(m5, m1, m2, m3, m4,
       headers = c("Pooled", "Raw+FE", "Purged+FE", "Raw+FE(W)", "Purged+FE(W)"),
       tex = TRUE,
       file = file.path(OUT, "tables/tab1_main_regressions.tex"),
       replace = TRUE,
       title = "Grading Court Leniency and Bar Exam Pass Rates",
       notes = "Dependent variable: candidate court pass rate. Columns 1-2 use raw leave-one-out leniency. Columns 3 and 5 use residualized leave-one-out leniency (purged of candidate-court and year effects). (W) = written exams only (excludes 2022 oral session). Heteroskedasticity-robust SEs in parentheses.",
       label = "tab:main")

cat("Revised table written.\n")

## ----------------------------------------------------------
## 8. Revised Figures
## ----------------------------------------------------------
# Figure 1: Pass rate ranges (same as before but no 2024)
fig1 <- ggplot(dt, aes(x = reorder(candidate_court, pass_rate), y = pass_rate)) +
  geom_point(aes(color = factor(exam_year)), size = 2.5, alpha = 0.8) +
  geom_segment(data = dt[, .(min_pr = min(pass_rate), max_pr = max(pass_rate)),
                          by = candidate_court],
               aes(x = reorder(candidate_court, (min_pr+max_pr)/2),
                   xend = reorder(candidate_court, (min_pr+max_pr)/2),
                   y = min_pr, yend = max_pr),
               linewidth = 0.5, alpha = 0.4) +
  coord_flip() +
  labs(x = NULL, y = "Pass Rate",
       title = "Italian Bar Exam Pass Rates by Court of Appeal",
       subtitle = "Vertical lines show within-court range (different randomly assigned grading courts)",
       color = "Year") +
  theme_minimal(base_size = 11) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))

ggsave(file.path(OUT, "figures/fig1_pass_rates.pdf"), fig1, width = 8, height = 7)

# Figure 2: Purged leniency scatter
fig2_data <- dt[!is.na(purged_leniency)]
fig2 <- ggplot(fig2_data, aes(x = purged_leniency, y = resid_pr)) +
  geom_point(aes(color = fascia), size = 2.5, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
  labs(x = "Grading Court Leniency (FE-Purged, LOO)",
       y = "Pass Rate Residual (Court + Year FE Removed)",
       title = "Residualized Pass Rates and Grading Court Leniency",
       color = "Fascia") +
  theme_minimal(base_size = 11)

ggsave(file.path(OUT, "figures/fig2_leniency_scatter.pdf"), fig2, width = 7, height = 5.5)

cat("Figures updated.\n")

## ----------------------------------------------------------
## 9. Key Results Summary
## ----------------------------------------------------------
cat("\n=== REVISED KEY RESULTS ===\n")
cat("N observations:", nrow(dt), "(dropped 2024)\n")
cat("N courts:", uniqueN(dt$candidate_court), "\n")
cat("N sessions:", uniqueN(dt$exam_year), ":", paste(sort(unique(dt$exam_year)), collapse=", "), "\n")
cat("Pass rate range:", round(min(dt$pass_rate), 3), "to", round(max(dt$pass_rate), 3), "\n")
cat("Within-court variance share:", round(within_var/total_var*100, 1), "%\n")
cat("\nRaw leniency (Court+Year FE):  coef=", round(coef(m1), 3), " t=", round(tstat(m1), 2), "\n")
cat("Purged leniency (Court+Year FE): coef=", round(coef(m2), 3), " t=", round(tstat(m2), 2), "\n")
cat("Raw leniency (written only):    coef=", round(coef(m3), 3), " t=", round(tstat(m3), 2), "\n")
cat("Purged leniency (written only):  coef=", round(coef(m4), 3), " t=", round(tstat(m4), 2), "\n")
