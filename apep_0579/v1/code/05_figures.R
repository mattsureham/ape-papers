## ==============================================================
## 05_figures.R — All figures for the paper
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

source("00_packages.R")
data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

results <- readRDS(file.path(data_dir, "all_models.rds"))
rr_table <- fread(file.path(data_dir, "reversal_ratios.csv"))

## ---------------------------------------------------------------
## FIGURE 1: Reversal Ratio Forest Plot (main result)
## ---------------------------------------------------------------
cat("=== Figure 1: Reversal Ratio Forest Plot ===\n")

rr_plot <- rr_table[!is.na(reversal_ratio)]
rr_plot[, reform_label := paste0(reform, "\n(", duration_months, " months, ", domain, ")")]
rr_plot[, reform_label := factor(reform_label, levels = reform_label[order(reversal_ratio)])]

fig1 <- ggplot(rr_plot, aes(x = reversal_ratio, y = reform_label)) +
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey60", linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "solid", color = "grey80", linewidth = 0.3) +
  geom_point(size = 3, color = "#2c3e50") +
  geom_errorbarh(aes(xmin = reversal_ratio - 1.96 * rr_se,
                      xmax = reversal_ratio + 1.96 * rr_se),
                  height = 0.2, color = "#2c3e50") +
  annotate("text", x = -1, y = 0.3, label = "Full reversal\n(RR = −1)",
           size = 2.8, color = "grey50", hjust = 0.5) +
  annotate("text", x = 0, y = 0.3, label = "Complete\nhysteresis\n(RR = 0)",
           size = 2.8, color = "grey50", hjust = 0.5) +
  labs(x = "Reversal Ratio (β_OFF / β_ON)",
       y = NULL,
       title = NULL) +
  scale_x_continuous(breaks = seq(-3, 2, 0.5)) +
  theme(axis.text.y = element_text(size = 9))

ggsave(file.path(fig_dir, "fig1_reversal_ratios.pdf"), fig1,
       width = 7, height = 4, device = cairo_pdf)
fwrite(rr_plot, file.path(data_dir, "fig1_data.csv"))
cat("  Saved fig1_reversal_ratios.pdf\n")

## ---------------------------------------------------------------
## FIGURE 2: Event Studies — Switch-ON (five panels)
## ---------------------------------------------------------------
cat("=== Figure 2: Switch-ON Event Studies ===\n")

# Extract event study coefficients for each reform
extract_es <- function(model, reform_name, phase = "on") {
  coefs <- coeftable(model)
  dt <- as.data.table(coefs, keep.rownames = TRUE)
  setnames(dt, c("term", "estimate", "se", "tstat", "pvalue"))
  # Extract event time from term name
  dt[, event_time := as.numeric(str_extract(term, "-?\\d+"))]
  dt[, reform := reform_name]
  dt[, ci_lo := estimate - 1.96 * se]
  dt[, ci_hi := estimate + 1.96 * se]
  dt
}

es_list <- list()

# Denmark
if (!is.null(results$dk$model_es)) {
  es_list$dk <- extract_es(results$dk$model_es, "Denmark fat tax")
}

# Czech Republic
if (!is.null(results$cz$model_es)) {
  es_list$cz <- extract_es(results$cz$model_es, "Czech healthcare\nco-payments")
}

# Italy
if (!is.null(results$it$model_es)) {
  es_list$it <- extract_es(results$it$model_es, "Italy Reddito\ndi Cittadinanza")
}

# Poland
if (!is.null(results$pl$model_es)) {
  es_list$pl <- extract_es(results$pl$model_es, "Poland retirement\nage reform")
}

# France
if (!is.null(results$fr$model_es)) {
  es_list$fr <- extract_es(results$fr$model_es, "France 75%\nsupertax")
}

es_all <- rbindlist(es_list, fill = TRUE)
es_all <- es_all[!is.na(event_time)]

fig2 <- ggplot(es_all, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey70") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "firebrick", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#3498db", alpha = 0.15) +
  geom_line(color = "#2c3e50", linewidth = 0.6) +
  geom_point(size = 1.5, color = "#2c3e50") +
  facet_wrap(~reform, scales = "free", ncol = 3) +
  labs(x = "Event Time (periods relative to policy introduction)",
       y = "Estimated Coefficient",
       title = NULL) +
  theme(strip.text = element_text(size = 8))

ggsave(file.path(fig_dir, "fig2_event_studies_on.pdf"), fig2,
       width = 10, height = 6, device = cairo_pdf)
fwrite(es_all, file.path(data_dir, "fig2_data.csv"))
cat("  Saved fig2_event_studies_on.pdf\n")

## ---------------------------------------------------------------
## FIGURE 3: Raw Outcome Time Series (five panels)
## ---------------------------------------------------------------
cat("=== Figure 3: Raw Outcome Time Series ===\n")

# Denmark raw series
dk <- fread(file.path(data_dir, "dk_clean.csv"))
dk[, date := as.Date(date)]
dk_avg <- dk[, .(mean_val = mean(values, na.rm = TRUE)), by = .(date, treated)]
dk_avg[, treated_label := fifelse(treated == 1, "Food (treated)", "Non-food (control)")]
dk_avg[, reform := "Denmark fat tax"]

p_dk <- ggplot(dk_avg, aes(x = date, y = mean_val, color = treated_label)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2011-10-01"), linetype = "dashed", color = "firebrick") +
  geom_vline(xintercept = as.Date("2013-01-01"), linetype = "dashed", color = "steelblue") +
  annotate("text", x = as.Date("2011-10-01"), y = Inf, label = "ON", vjust = 1.5,
           color = "firebrick", size = 3) +
  annotate("text", x = as.Date("2013-01-01"), y = Inf, label = "OFF", vjust = 1.5,
           color = "steelblue", size = 3) +
  labs(x = NULL, y = "HICP Index (2015=100)", color = NULL,
       subtitle = "Denmark fat tax") +
  scale_color_manual(values = c("Food (treated)" = "#e74c3c", "Non-food (control)" = "#3498db"))

# Poland raw series
pl <- fread(file.path(data_dir, "pl_clean.csv"))
pl[, date := as.Date(date)]
pl[, group := paste(sex, age, sep = "_")]
pl_plot <- pl[, .(mean_val = mean(values, na.rm = TRUE)), by = .(date, treated)]
pl_plot[, treated_label := fifelse(treated == 1, "Women 60-64 (treated)", "Others (control)")]

p_pl <- ggplot(pl_plot, aes(x = date, y = mean_val, color = treated_label)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2013-01-01"), linetype = "dashed", color = "firebrick") +
  geom_vline(xintercept = as.Date("2017-10-01"), linetype = "dashed", color = "steelblue") +
  annotate("text", x = as.Date("2013-01-01"), y = Inf, label = "ON", vjust = 1.5,
           color = "firebrick", size = 3) +
  annotate("text", x = as.Date("2017-10-01"), y = Inf, label = "OFF", vjust = 1.5,
           color = "steelblue", size = 3) +
  labs(x = NULL, y = "Employment Rate (%)", color = NULL,
       subtitle = "Poland retirement age reform") +
  scale_color_manual(values = c("Women 60-64 (treated)" = "#e74c3c", "Others (control)" = "#3498db"))

# Italy raw series
it <- fread(file.path(data_dir, "it_clean.csv"))
it_plot <- it[, .(mean_val = mean(values, na.rm = TRUE)), by = .(year, treated)]
it_plot[, treated_label := fifelse(treated == 1, "High-poverty regions (treated)",
                                    "Low-poverty regions (control)")]

p_it <- ggplot(it_plot, aes(x = year, y = mean_val, color = treated_label)) +
  geom_line(linewidth = 0.6) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2019, linetype = "dashed", color = "firebrick") +
  geom_vline(xintercept = 2024, linetype = "dashed", color = "steelblue") +
  annotate("text", x = 2019, y = Inf, label = "ON", vjust = 1.5,
           color = "firebrick", size = 3) +
  annotate("text", x = 2024, y = Inf, label = "OFF", vjust = 1.5,
           color = "steelblue", size = 3) +
  labs(x = NULL, y = "At-Risk-of-Poverty Rate (%)", color = NULL,
       subtitle = "Italy Reddito di Cittadinanza") +
  scale_color_manual(values = c("High-poverty regions (treated)" = "#e74c3c",
                                 "Low-poverty regions (control)" = "#3498db"))

# France raw series
fr <- fread(file.path(data_dir, "fr_clean.csv"))
fr[, date := as.Date(date)]
fr_total <- fr[nace_r2 %in% c("B-S", "B-S_X_O") & lcstruct %in% c("D1_D4_MD5", "D1")]
if (nrow(fr_total) == 0) fr_total <- fr[, .SD[1], by = .(geo, date)]
fr_plot <- fr_total[, .(mean_val = mean(values, na.rm = TRUE)), by = .(date, treated)]
fr_plot[, treated_label := fifelse(treated == 1, "France (treated)", "DE/NL/BE/AT (control)")]

p_fr <- ggplot(fr_plot, aes(x = date, y = mean_val, color = treated_label)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2013-01-01"), linetype = "dashed", color = "firebrick") +
  geom_vline(xintercept = as.Date("2015-01-01"), linetype = "dashed", color = "steelblue") +
  annotate("text", x = as.Date("2013-01-01"), y = Inf, label = "ON", vjust = 1.5,
           color = "firebrick", size = 3) +
  annotate("text", x = as.Date("2015-01-01"), y = Inf, label = "OFF", vjust = 1.5,
           color = "steelblue", size = 3) +
  labs(x = NULL, y = "Labor Cost Index", color = NULL,
       subtitle = "France 75% supertax") +
  scale_color_manual(values = c("France (treated)" = "#e74c3c", "DE/NL/BE/AT (control)" = "#3498db"))

# Combine
library(patchwork)
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")
library(patchwork)

fig3 <- (p_dk + p_pl) / (p_it + p_fr) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom", legend.text = element_text(size = 8))

ggsave(file.path(fig_dir, "fig3_raw_time_series.pdf"), fig3,
       width = 10, height = 8, device = cairo_pdf)
cat("  Saved fig3_raw_time_series.pdf\n")

## ---------------------------------------------------------------
## FIGURE 4: Duration vs Reversal Ratio (meta-regression visual)
## ---------------------------------------------------------------
cat("=== Figure 4: Duration vs Reversal Ratio ===\n")

rr_plot2 <- rr_table[!is.na(reversal_ratio)]
rr_plot2[, duration_label := paste0(reform, "\n(", duration_months, "m)")]

fig4 <- ggplot(rr_plot2, aes(x = log(duration_months), y = reversal_ratio)) +
  geom_hline(yintercept = -1, linetype = "dashed", color = "grey60") +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey80") +
  geom_point(aes(color = domain), size = 4) +
  geom_errorbar(aes(ymin = reversal_ratio - 1.96 * rr_se,
                     ymax = reversal_ratio + 1.96 * rr_se,
                     color = domain), width = 0.08) +
  geom_text(aes(label = reform), nudge_y = 0.15, size = 2.8, check_overlap = TRUE) +
  geom_smooth(method = "lm", se = TRUE, color = "grey40", linetype = "dashed",
              linewidth = 0.5, alpha = 0.1) +
  labs(x = "Log(Policy Duration in Months)",
       y = "Reversal Ratio (β_OFF / β_ON)",
       color = "Policy Domain",
       title = NULL) +
  annotate("text", x = min(log(rr_plot2$duration_months)) - 0.1, y = -1,
           label = "← Full reversal", size = 2.5, color = "grey50", hjust = 1) +
  annotate("text", x = min(log(rr_plot2$duration_months)) - 0.1, y = 0,
           label = "← Complete hysteresis", size = 2.5, color = "grey50", hjust = 1) +
  scale_color_brewer(palette = "Set2")

ggsave(file.path(fig_dir, "fig4_duration_vs_rr.pdf"), fig4,
       width = 7, height = 5, device = cairo_pdf)
fwrite(rr_plot2, file.path(data_dir, "fig4_data.csv"))
cat("  Saved fig4_duration_vs_rr.pdf\n")

## ---------------------------------------------------------------
## FIGURE 5: Symmetric Event Studies (ON and OFF side by side)
## ---------------------------------------------------------------
cat("=== Figure 5: Symmetric Event Studies ===\n")

# For Denmark (best powered), create symmetric ON/OFF event studies
dk <- fread(file.path(data_dir, "dk_clean.csv"))
dk[, date := as.Date(date)]

# ON window: 12 months before to 15 months after ON date
dk_on_window <- dk[event_time_on >= -12 & event_time_on <= 15]
dk_on_avg <- dk_on_window[, .(y = mean(values, na.rm = TRUE)),
                           by = .(event_time_on, treated)]
dk_on_avg[, treated_label := fifelse(treated == 1, "Food", "Non-food")]
dk_on_avg[, phase := "Switch ON"]

# OFF window: 12 months before to 15 months after OFF date
dk_off_window <- dk[event_time_off >= -15 & event_time_off <= 12]
dk_off_avg <- dk_off_window[, .(y = mean(values, na.rm = TRUE)),
                             by = .(event_time_off, treated)]
dk_off_avg[, treated_label := fifelse(treated == 1, "Food", "Non-food")]
dk_off_avg[, phase := "Switch OFF"]

setnames(dk_on_avg, "event_time_on", "event_time")
setnames(dk_off_avg, "event_time_off", "event_time")
dk_sym <- rbind(dk_on_avg, dk_off_avg)

fig5 <- ggplot(dk_sym, aes(x = event_time, y = y, color = treated_label)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  facet_wrap(~phase) +
  labs(x = "Months Relative to Policy Change",
       y = "HICP Index (2015=100)",
       color = NULL,
       title = NULL) +
  scale_color_manual(values = c("Food" = "#e74c3c", "Non-food" = "#3498db"))

ggsave(file.path(fig_dir, "fig5_symmetric_denmark.pdf"), fig5,
       width = 8, height = 4, device = cairo_pdf)
fwrite(dk_sym, file.path(data_dir, "fig5_data.csv"))
cat("  Saved fig5_symmetric_denmark.pdf\n")

## ---------------------------------------------------------------
## FIGURE 6: Leave-One-Out Meta-Regression Stability
## ---------------------------------------------------------------
cat("=== Figure 6: Leave-One-Out Stability ===\n")

loo_file <- file.path(data_dir, "leave_one_out.csv")
if (file.exists(loo_file)) {
  loo <- fread(loo_file)
  meta_file <- file.path(data_dir, "meta_regression.csv")
  if (file.exists(meta_file)) {
    meta <- fread(meta_file)
    full_b_dur <- meta[term == "log_duration"]$estimate

    fig6 <- ggplot(loo, aes(x = dropped, y = b_duration)) +
      geom_hline(yintercept = full_b_dur, linetype = "dashed", color = "firebrick") +
      geom_point(size = 3, color = "#2c3e50") +
      labs(x = "Reform Dropped",
           y = "Duration Coefficient",
           title = NULL) +
      coord_flip() +
      annotate("text", x = 0.5, y = full_b_dur, label = "Full-sample estimate",
               color = "firebrick", size = 3, hjust = 0)

    ggsave(file.path(fig_dir, "fig6_leave_one_out.pdf"), fig6,
           width = 7, height = 4, device = cairo_pdf)
    fwrite(loo, file.path(data_dir, "fig6_data.csv"))
    cat("  Saved fig6_leave_one_out.pdf\n")
  }
}

cat("\nAll figures generated.\n")
