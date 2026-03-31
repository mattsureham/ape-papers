## 03c_monthly_event_study.R — Formal Monthly Event Study (V4)
## apep_0727 v4: Monthly bunching with bootstrap CIs around policy breaks
## Uses unified estimator from 00_bunching_estimator.R (integer bins, degree 7)
##
## Three policy transitions:
##   1. August 2014: surcharge introduction
##   2. January 2021: threshold expansion (10 → 30 kWp)
##   3. July 2022: surcharge abolition

source("00_packages.R")
source("00_bunching_estimator.R")

cat("Loading data for monthly event study...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
dt_10[, ym := year * 100L + month]
all_bins <- data.table(bin_int = 30L:199L)

set.seed(20260331)

# ============================================================
# 1. MONTHLY BUNCHING ESTIMATES WITH BOOTSTRAP CIs (2013-2024)
# ============================================================

cat("\n=== Monthly Bunching Estimates with Bootstrap CIs ===\n")
monthly_results <- list()

for (yr in 2013:2024) {
  for (mo in 1:12) {
    ym_val <- yr * 100L + mo
    dt_ym <- dt_10[ym == ym_val & capacity_kwp >= 3 & capacity_kwp < 20]
    N <- nrow(dt_ym)
    if (N < 500) next

    # Point estimate using UNIFIED estimator (degree 7, integer bins)
    ym_bins <- make_bins_int(dt_ym, all_bins)
    est <- tryCatch(
      bunching_estimate_int(ym_bins),
      error = function(e) list(bunching_ratio = NA, excess_mass = NA,
                                missing_mass = NA, mass_balance = NA)
    )

    n99 <- ym_bins[bin_int == 99L, count]
    n101 <- ym_bins[bin_int == 101L, count]

    # Bootstrap CIs (500 reps)
    boot <- bootstrap_bunching_int(dt_10, n_boot = 500L,
                                    subset_expr = substitute(ym == YM,
                                                              list(YM = ym_val)),
                                    all_bins = all_bins)

    monthly_results[[length(monthly_results) + 1]] <- data.frame(
      year = yr, month = mo,
      date = as.Date(sprintf("%d-%02d-01", yr, mo)),
      bunching_ratio = round(est$bunching_ratio, 2),
      se = round(ifelse(is.na(boot$se_bunching), NA, boot$se_bunching), 2),
      ci_lower = round(ifelse(is.na(boot$ci_lower), NA, boot$ci_lower), 2),
      ci_upper = round(ifelse(is.na(boot$ci_upper), NA, boot$ci_upper), 2),
      excess_mass = round(est$excess_mass),
      n_99 = n99, n_101 = n101, n_total = N,
      raw_ratio = round(n99 / max(n101, 1), 1),
      stringsAsFactors = FALSE)

    if (mo %% 6 == 0 || yr %in% c(2014, 2021, 2022)) {
      cat(sprintf("  %d-%02d: b = %.1f (SE = %.1f) [%.1f, %.1f] N=%s\n",
          yr, mo, est$bunching_ratio,
          ifelse(is.na(boot$se_bunching), NA, boot$se_bunching),
          ifelse(is.na(boot$ci_lower), NA, boot$ci_lower),
          ifelse(is.na(boot$ci_upper), NA, boot$ci_upper),
          format(N, big.mark = ",")))
    }
  }
}

monthly_dt <- as.data.table(do.call(rbind, monthly_results))
fwrite(monthly_dt, "../data/bunching_10_monthly.csv")
cat(sprintf("\nMonthly estimates saved: %d months\n", nrow(monthly_dt)))

# ============================================================
# 2. FORMAL EVENT STUDY TABLES AROUND POLICY BREAKS
# ============================================================

# Transition 1: Aug 2014
cat("\n=== Transition 1: Around Aug 2014 (Surcharge Introduction) ===\n")
t1 <- monthly_dt[year == 2014 | (year == 2013 & month >= 7) |
                   (year == 2015 & month <= 6)]
t1[, event_month := (year - 2014) * 12 + month - 8]  # 0 = Aug 2014
print(t1[order(year, month),
          .(year, month, event_month, bunching_ratio, se, ci_lower, ci_upper, n_total)])

# Pre-trend test: linear trend in bunching before Aug 2014
pre_aug14 <- monthly_dt[(year == 2014 & month < 8) |
                          (year == 2013 & month >= 1)]
if (nrow(pre_aug14) >= 6) {
  pre_aug14 <- pre_aug14[order(year, month)]
  pre_aug14[, t := seq_len(.N)]
  pre_trend <- lm(bunching_ratio ~ t, data = pre_aug14)
  cat(sprintf("Pre-Aug 2014 trend slope: %.2f (p = %.3f) — %s\n",
      coef(pre_trend)["t"],
      summary(pre_trend)$coefficients["t", "Pr(>|t|)"],
      ifelse(summary(pre_trend)$coefficients["t", "Pr(>|t|)"] > 0.05,
             "NO anticipation detected", "Possible anticipation")))
}

# Transition 2: Jan 2021
cat("\n=== Transition 2: Around Jan 2021 (Threshold Expansion) ===\n")
t2 <- monthly_dt[(year == 2020 & month >= 7) |
                   (year == 2021 & month <= 12)]
t2[, event_month := (year - 2021) * 12 + month - 1]  # 0 = Jan 2021
print(t2[order(year, month),
          .(year, month, event_month, bunching_ratio, se, ci_lower, ci_upper, n_total)])

# Pre-trend before Jan 2021
pre_jan21 <- monthly_dt[year == 2020 & month >= 1]
if (nrow(pre_jan21) >= 6) {
  pre_jan21 <- pre_jan21[order(year, month)]
  pre_jan21[, t := seq_len(.N)]
  pre_trend2 <- lm(bunching_ratio ~ t, data = pre_jan21)
  cat(sprintf("Pre-Jan 2021 trend slope: %.2f (p = %.3f) — %s\n",
      coef(pre_trend2)["t"],
      summary(pre_trend2)$coefficients["t", "Pr(>|t|)"],
      ifelse(summary(pre_trend2)$coefficients["t", "Pr(>|t|)"] > 0.05,
             "NO anticipation detected", "Possible anticipation")))
}

# Transition 3: Jul 2022
cat("\n=== Transition 3: Around Jul 2022 (Surcharge Abolition) ===\n")
t3 <- monthly_dt[(year == 2022) |
                   (year == 2021 & month >= 7) |
                   (year == 2023 & month <= 6)]
t3[, event_month := (year - 2022) * 12 + month - 7]  # 0 = Jul 2022
print(t3[order(year, month),
          .(year, month, event_month, bunching_ratio, se, ci_lower, ci_upper, n_total)])

# ============================================================
# 3. SAVE EVENT STUDY TABLE FOR LATEX
# ============================================================

event_study_table <- rbind(
  t1[event_month >= -6 & event_month <= 6,
     .(break_name = "Surcharge Introduction (Aug 2014)",
       year, month, event_month, bunching_ratio, se, ci_lower, ci_upper, n_total)],
  t2[event_month >= -6 & event_month <= 6,
     .(break_name = "Threshold Expansion (Jan 2021)",
       year, month, event_month, bunching_ratio, se, ci_lower, ci_upper, n_total)],
  t3[event_month >= -6 & event_month <= 6,
     .(break_name = "Surcharge Abolition (Jul 2022)",
       year, month, event_month, bunching_ratio, se, ci_lower, ci_upper, n_total)]
)

fwrite(event_study_table, "../data/monthly_event_study.csv")
cat(sprintf("\nEvent study table saved: %d rows across 3 transitions\n",
    nrow(event_study_table)))

# ============================================================
# 4. MONTHLY EVENT STUDY FIGURE WITH CI BANDS
# ============================================================

library(ggplot2)

theme_apep <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        legend.position = "none")

p_monthly <- ggplot(monthly_dt, aes(x = date, y = bunching_ratio)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = "grey80", alpha = 0.5) +
  geom_line(color = "#333333", linewidth = 0.5) +
  geom_point(size = 0.8, color = "#333333") +
  geom_vline(xintercept = as.Date("2014-08-01"), linetype = "dashed",
             color = "#D55E00", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2021-01-01"), linetype = "dashed",
             color = "#009E73", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2022-07-01"), linetype = "dashed",
             color = "#56B4E9", linewidth = 0.5) +
  annotate("text", x = as.Date("2014-08-01"),
           y = max(monthly_dt$bunching_ratio, na.rm = TRUE) * 0.95,
           label = "Surcharge\n(Aug 2014)", hjust = -0.1, size = 2.8,
           color = "#D55E00") +
  annotate("text", x = as.Date("2021-01-01"),
           y = max(monthly_dt$bunching_ratio, na.rm = TRUE) * 0.85,
           label = "Threshold\nraised\n(Jan 2021)", hjust = -0.1, size = 2.8,
           color = "#009E73") +
  annotate("text", x = as.Date("2022-07-01"),
           y = max(monthly_dt$bunching_ratio, na.rm = TRUE) * 0.75,
           label = "Surcharge\nabolished\n(Jul 2022)", hjust = -0.1, size = 2.8,
           color = "#56B4E9") +
  labs(
    title = "Monthly Bunching Ratio at 10 kWp, 2013-2024",
    subtitle = "Kleven-Waseem estimate with 95% bootstrap confidence interval",
    x = NULL,
    y = "Bunching Ratio (b)"
  ) +
  theme_apep

ggsave("../figures/fig8_monthly_event_study.pdf", p_monthly,
       width = 10, height = 5)
ggsave("../figures/fig8_monthly_event_study.png", p_monthly,
       width = 10, height = 5, dpi = 300)

cat("\nMonthly event study complete.\n")
