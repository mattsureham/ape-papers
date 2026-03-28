## ============================================================
## Italian Bar Exam Sorteggio: Main Analysis
## ============================================================

library(data.table)
library(fixest)
library(ggplot2)

OUT <- "output/paper_italy_sorteggio/v1"

## ----------------------------------------------------------
## 1. Load and Clean Panel
## ----------------------------------------------------------
dt <- fread(file.path(OUT, "data/panel.csv"))

# Fix fascia assignments using 2021 documented tiers (stable across years)
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
dt[is.na(fascia_correct), fascia_correct := fascia]  # fallback
dt[, fascia := fascia_correct]
dt[, fascia_correct := NULL]

# COVID format indicator
dt[, covid_oral := as.integer(exam_year %in% c(2020, 2021, 2022))]

# Create numeric IDs
dt[, court_id := as.integer(factor(candidate_court))]
dt[, grading_id := as.integer(factor(grading_court))]

cat("Panel dimensions:", nrow(dt), "obs,", uniqueN(dt$candidate_court), "candidate courts,",
    uniqueN(dt$exam_year), "years\n")
cat("Years:", paste(sort(unique(dt$exam_year)), collapse=", "), "\n")
cat("COVID oral obs:", sum(dt$covid_oral), "\n")
cat("Written exam obs:", sum(!dt$covid_oral), "\n\n")

## ----------------------------------------------------------
## 2. Summary Statistics
## ----------------------------------------------------------
cat("=== Pass Rate Summary ===\n")
cat("Overall:  mean =", round(mean(dt$pass_rate), 3),
    " sd =", round(sd(dt$pass_rate), 3),
    " min =", round(min(dt$pass_rate), 3),
    " max =", round(max(dt$pass_rate), 3), "\n")

# By year
cat("\nBy year:\n")
print(dt[, .(N = .N, mean_pr = round(mean(pass_rate), 3),
             sd_pr = round(sd(pass_rate), 3),
             min_pr = round(min(pass_rate), 3),
             max_pr = round(max(pass_rate), 3)), by = exam_year][order(exam_year)])

# By fascia
cat("\nBy fascia:\n")
print(dt[, .(N = .N, mean_pr = round(mean(pass_rate), 3),
             sd_pr = round(sd(pass_rate), 3)), by = fascia][order(fascia)])

## ----------------------------------------------------------
## 3. Variance Decomposition
## ----------------------------------------------------------
# Total variance
total_var <- var(dt$pass_rate)

# Between-court variance (persistent candidate quality)
court_means <- dt[, .(mean_pr = mean(pass_rate)), by = candidate_court]
between_var <- var(court_means$mean_pr)

# Within-court variance (changes when grading court changes)
dt[, court_mean := mean(pass_rate), by = candidate_court]
within_var <- var(dt$pass_rate - dt$court_mean)

cat("=== Variance Decomposition ===\n")
cat("Total variance:   ", round(total_var, 6), "\n")
cat("Between-court:    ", round(between_var, 6), " (", round(between_var/total_var*100, 1), "%)\n")
cat("Within-court:     ", round(within_var, 6), " (", round(within_var/total_var*100, 1), "%)\n")
cat("Within/Total ratio:", round(within_var/total_var, 3), "\n\n")

## ----------------------------------------------------------
## 4. Compute Grading Court Leniency (Leave-One-Out)
## ----------------------------------------------------------
# For each grading court, compute LOO leniency = mean pass rate when
# this court grades OTHERS, excluding the focal observation
dt[, grading_leniency := {
  loo <- numeric(.N)
  for (i in seq_len(.N)) {
    others <- dt[grading_court == .SD$grading_court[i] &
                   !(candidate_court == .SD$candidate_court[i] &
                       exam_year == .SD$exam_year[i])]
    if (nrow(others) > 0) {
      loo[i] <- mean(others$pass_rate)
    } else {
      loo[i] <- NA_real_
    }
  }
  loo
}]

cat("Grading leniency: N non-missing =", sum(!is.na(dt$grading_leniency)),
    ", mean =", round(mean(dt$grading_leniency, na.rm=TRUE), 3),
    ", sd =", round(sd(dt$grading_leniency, na.rm=TRUE), 3), "\n\n")

## ----------------------------------------------------------
## 5. Main Regression: Pass Rate ~ Grading Leniency + Court FE + Year FE
## ----------------------------------------------------------
cat("=== Main Regressions ===\n\n")

# Model 1: Pooled OLS (no FE)
m1 <- feols(pass_rate ~ grading_leniency, data = dt, vcov = "hetero")
cat("Model 1 (Pooled OLS):\n")
print(summary(m1))

# Model 2: Year FE only
m2 <- feols(pass_rate ~ grading_leniency | exam_year, data = dt, vcov = "hetero")
cat("\nModel 2 (Year FE):\n")
print(summary(m2))

# Model 3: Candidate court FE + Year FE (preferred)
m3 <- feols(pass_rate ~ grading_leniency | candidate_court + exam_year, data = dt, vcov = "hetero")
cat("\nModel 3 (Court FE + Year FE) — PREFERRED:\n")
print(summary(m3))

# Model 4: Court FE + Year FE + COVID indicator
m4 <- feols(pass_rate ~ grading_leniency + covid_oral | candidate_court + exam_year, data = dt, vcov = "hetero")
cat("\nModel 4 (Court FE + Year FE + COVID):\n")
print(summary(m4))

# Model 5: Written exams only (exclude COVID oral)
dt_written <- dt[covid_oral == 0]
m5 <- feols(pass_rate ~ grading_leniency | candidate_court + exam_year,
            data = dt_written, vcov = "hetero")
cat("\nModel 5 (Written exams only):\n")
print(summary(m5))

## ----------------------------------------------------------
## 6. Export Regression Table
## ----------------------------------------------------------
dir.create(file.path(OUT, "tables"), showWarnings = FALSE)
etable(m1, m2, m3, m4, m5,
       headers = c("Pooled", "Year FE", "Court+Year FE", "+COVID", "Written Only"),
       tex = TRUE,
       file = file.path(OUT, "tables/tab1_main_regressions.tex"),
       replace = TRUE,
       title = "Grading Court Leniency and Bar Exam Pass Rates",
       notes = "Dependent variable: candidate court pass rate. Grading court leniency is leave-one-out mean pass rate when the assigned grading court evaluates other courts' papers. Heteroskedasticity-robust SEs in parentheses.",
       label = "tab:main")

cat("\nTable written to", file.path(OUT, "tables/tab1_main_regressions.tex"), "\n")

## ----------------------------------------------------------
## 7. Balance Test: Do Candidate Characteristics Predict Grading Court?
## ----------------------------------------------------------
cat("\n=== Balance Test ===\n")
# Within fascia-year, test whether candidate court size predicts grading leniency
# If sorteggio is random, it should not.
dt_bal <- dt[!is.na(grading_leniency)]
if ("candidates" %in% names(dt_bal) && any(!is.na(as.numeric(dt_bal$candidates)) & dt_bal$candidates != "")) {
  dt_bal[, n_cand := as.numeric(candidates)]
  bal1 <- feols(grading_leniency ~ n_cand | fascia + exam_year, data = dt_bal[!is.na(n_cand)], vcov = "hetero")
  cat("Balance: candidate count → grading leniency (fascia + year FE):\n")
  print(summary(bal1))
} else {
  cat("No candidate count data available for balance test.\n")
  # Use court mean pass rate as proxy for "quality"
  bal2 <- feols(grading_leniency ~ court_mean | fascia + exam_year, data = dt_bal, vcov = "hetero")
  cat("Balance: court mean pass rate → grading leniency (fascia + year FE):\n")
  print(summary(bal2))
}

## ----------------------------------------------------------
## 8. Figures
## ----------------------------------------------------------
dir.create(file.path(OUT, "figures"), showWarnings = FALSE)

# Figure 1: Pass rate distribution with grading court variation highlighted
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
       subtitle = "Vertical lines show within-court range across years (different grading courts)",
       color = "Exam Year") +
  theme_minimal(base_size = 11) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))

ggsave(file.path(OUT, "figures/fig1_pass_rates.pdf"), fig1, width = 8, height = 7)
cat("Figure 1 saved.\n")

# Figure 2: Grading leniency vs pass rate (binscatter-style)
fig2_data <- dt[!is.na(grading_leniency)]
fig2 <- ggplot(fig2_data, aes(x = grading_leniency, y = pass_rate)) +
  geom_point(aes(color = fascia), size = 2, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
  labs(x = "Grading Court Leniency (Leave-One-Out)",
       y = "Candidate Court Pass Rate",
       title = "Pass Rates Rise When Assigned a Lenient Grading Court",
       color = "Fascia") +
  theme_minimal(base_size = 11) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))

ggsave(file.path(OUT, "figures/fig2_leniency_scatter.pdf"), fig2, width = 7, height = 5.5)
cat("Figure 2 saved.\n")

## ----------------------------------------------------------
## 9. Summary Output
## ----------------------------------------------------------
cat("\n=== KEY RESULTS ===\n")
cat("N observations:", nrow(dt), "\n")
cat("N courts:", uniqueN(dt$candidate_court), "\n")
cat("N years:", uniqueN(dt$exam_year), "\n")
cat("Pass rate range:", round(min(dt$pass_rate), 3), "to", round(max(dt$pass_rate), 3), "\n")
cat("Within-court variance share:", round(within_var/total_var*100, 1), "%\n")
cat("Preferred model (M3) coefficient:", round(coef(m3)["grading_leniency"], 3), "\n")
cat("Preferred model (M3) SE:", round(se(m3)["grading_leniency"], 3), "\n")
cat("Preferred model (M3) t-stat:", round(tstat(m3)["grading_leniency"], 2), "\n")
cat("Preferred model (M3) R2:", round(r2(m3, type = "ar2"), 3), "\n")
