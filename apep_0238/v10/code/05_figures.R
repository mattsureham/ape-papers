# ── apep_0238 v10: Figures ─────────────────────────────────────────────────
# 5 main figures + appendix figures

# Source packages - detect script dir robustly
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
if (length(.file_arg) > 0) {
  .script_dir <- dirname(normalizePath(sub("^--file=", "", .file_arg)))
} else {
  .script_dir <- getwd()
}
source(file.path(.script_dir, "00_packages.R"))
library(lubridate)

dat <- readRDS(file.path(DATA_DIR, "analysis_data.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
mech <- readRDS(file.path(DATA_DIR, "mechanism_results.rds"))
rob <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))
raw <- readRDS(file.path(DATA_DIR, "raw_data.rds"))

BLUE <- "#2166AC"
RED  <- "#B2182B"

# ══════════════════════════════════════════════════════════════════════════
# Figure 1: Two Recession Templates (national paths)
# ══════════════════════════════════════════════════════════════════════════

cat("Figure 1: National recession templates...\n")

panel <- dat$panel
nat <- panel[, .(emp = sum(nonfarm_emp, na.rm = TRUE),
                 ur = mean(ur, na.rm = TRUE),
                 lfpr = mean(lfpr, na.rm = TRUE)), by = date]

# Normalize employment to peak
gr_peak_emp <- nat[date == GR_PEAK]$emp
covid_peak_emp <- nat[date == COVID_PEAK]$emp

# GR window
nat_gr <- nat[date >= "2006-01-01" & date <= "2018-01-01"]
nat_gr[, emp_idx := emp / gr_peak_emp * 100]
nat_gr[, months_from_peak := as.numeric(difftime(date, GR_PEAK, units = "days")) / 30.44]

# COVID window
nat_covid <- nat[date >= "2018-06-01" & date <= "2024-06-01"]
nat_covid[, emp_idx := emp / covid_peak_emp * 100]
nat_covid[, months_from_peak := as.numeric(difftime(date, COVID_PEAK, units = "days")) / 30.44]

# Combined for plotting
nat_gr[, episode := "Great Recession"]
nat_covid[, episode := "COVID-19"]
combined <- rbind(
  nat_gr[, .(months_from_peak, emp_idx, ur, episode)],
  nat_covid[, .(months_from_peak, emp_idx, ur, episode)]
)
combined <- combined[months_from_peak >= -12 & months_from_peak <= 60]

p1a <- ggplot(combined, aes(x = months_from_peak, y = emp_idx, color = episode)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 100, linetype = "dashed", alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dotted", alpha = 0.5) +
  scale_color_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
  labs(x = "Months from Peak", y = "Employment Index (Peak = 100)",
       title = "A. Employment Recovery") +
  theme(legend.title = element_blank())

# National LTU share
if (!is.null(mech$ltu_national)) {
  ltu <- mech$ltu_national
  ltu_gr <- ltu[date >= "2006-01-01" & date <= "2018-01-01"]
  ltu_gr[, months_from_peak := as.numeric(difftime(date, GR_PEAK, units = "days")) / 30.44]
  ltu_gr[, episode := "Great Recession"]

  ltu_covid <- ltu[date >= "2018-06-01" & date <= "2024-06-01"]
  ltu_covid[, months_from_peak := as.numeric(difftime(date, COVID_PEAK, units = "days")) / 30.44]
  ltu_covid[, episode := "COVID-19"]

  ltu_combined <- rbind(
    ltu_gr[, .(months_from_peak, ltu_share, episode)],
    ltu_covid[, .(months_from_peak, ltu_share, episode)]
  )
  ltu_combined <- ltu_combined[months_from_peak >= -12 & months_from_peak <= 60]

  p1b <- ggplot(ltu_combined, aes(x = months_from_peak, y = ltu_share * 100, color = episode)) +
    geom_line(linewidth = 1) +
    geom_vline(xintercept = 0, linetype = "dotted", alpha = 0.5) +
    scale_color_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
    labs(x = "Months from Peak", y = "Share (%)",
         title = "B. Long-Term Unemployment (27+ Weeks)") +
    theme(legend.title = element_blank())
} else {
  p1b <- ggplot() + annotate("text", x = 0.5, y = 0.5, label = "LTU data not available") + theme_void()
}

# Temp layoff share
if (!is.null(mech$temp_national)) {
  temp <- mech$temp_national
  temp_gr <- temp[date >= "2006-01-01" & date <= "2018-01-01"]
  temp_gr[, months_from_peak := as.numeric(difftime(date, GR_PEAK, units = "days")) / 30.44]
  temp_gr[, episode := "Great Recession"]

  temp_covid <- temp[date >= "2018-06-01" & date <= "2024-06-01"]
  temp_covid[, months_from_peak := as.numeric(difftime(date, COVID_PEAK, units = "days")) / 30.44]
  temp_covid[, episode := "COVID-19"]

  temp_combined <- rbind(
    temp_gr[, .(months_from_peak, temp_layoff_share, episode)],
    temp_covid[, .(months_from_peak, temp_layoff_share, episode)]
  )
  temp_combined <- temp_combined[months_from_peak >= -12 & months_from_peak <= 60]

  p1c <- ggplot(temp_combined, aes(x = months_from_peak, y = temp_layoff_share * 100, color = episode)) +
    geom_line(linewidth = 1) +
    geom_vline(xintercept = 0, linetype = "dotted", alpha = 0.5) +
    scale_color_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
    labs(x = "Months from Peak", y = "Share (%)",
         title = "C. Temporary Layoff Share") +
    theme(legend.title = element_blank())
} else {
  p1c <- ggplot() + annotate("text", x = 0.5, y = 0.5, label = "Temp layoff data not available") + theme_void()
}

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  fig1 <- p1a / (p1b + p1c) + plot_layout(heights = c(1, 1))
} else {
  fig1 <- p1a  # fallback
}

ggsave(file.path(FIG_DIR, "fig1_recession_templates.pdf"), fig1, width = 10, height = 8)
cat("  Saved fig1_recession_templates.pdf\n")

# ══════════════════════════════════════════════════════════════════════════
# Figure 2: Main scatter — exposure vs long-run EPOP
# ══════════════════════════════════════════════════════════════════════════

cat("Figure 2: Main scatter...\n")

gr <- results$analysis_gr
covid <- results$analysis_covid

if ("avg_d_log_emp" %in% names(gr)) {
  p2a <- ggplot(gr, aes(x = hpi_boom, y = avg_d_log_emp)) +
    geom_point(color = BLUE, size = 2, alpha = 0.7) +
    geom_smooth(method = "lm", color = BLUE, se = TRUE, alpha = 0.2) +
    geom_text(aes(label = state), size = 2, vjust = -0.5, alpha = 0.6) +
    labs(x = "Housing Price Boom (log, 2003-2006)",
         y = "Avg. Log Employment Change (months 48-120)",
         title = "A. Great Recession: Persistent Scarring")

  p2b <- ggplot(covid, aes(x = bartik_covid_sd, y = avg_d_log_emp)) +
    geom_point(color = RED, size = 2, alpha = 0.7) +
    geom_smooth(method = "lm", color = RED, se = TRUE, alpha = 0.2) +
    geom_text(aes(label = state), size = 2, vjust = -0.5, alpha = 0.6) +
    labs(x = "COVID Bartik Exposure (SD units)",
         y = "Avg. Log Employment Change (months 24-48)",
         title = "B. COVID-19: Full Recovery")

  if (requireNamespace("patchwork", quietly = TRUE)) {
    fig2 <- p2a + p2b
  } else {
    fig2 <- p2a
  }
  ggsave(file.path(FIG_DIR, "fig2_main_scatter.pdf"), fig2, width = 12, height = 5)
  cat("  Saved fig2_main_scatter.pdf\n")
}

# ══════════════════════════════════════════════════════════════════════════
# Figure 3: Dynamic IRF (supporting, not the estimand)
# ══════════════════════════════════════════════════════════════════════════

cat("Figure 3: Dynamic IRF...\n")

lp_gr <- results$lp_gr
lp_covid <- results$lp_covid

lp_gr[, episode := "Great Recession"]
lp_covid[, episode := "COVID-19"]
lp_all <- rbind(lp_gr[, .(horizon, coef, se, episode)],
                lp_covid[, .(horizon, coef, se, episode)])

fig3 <- ggplot(lp_all, aes(x = horizon, y = coef, color = episode)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_ribbon(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se, fill = episode),
              alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
  scale_fill_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
  labs(x = "Months from Recession Peak",
       y = expression(hat(pi)[h] ~ "(log employment change per unit exposure)"),
       title = "Local Projection Impulse Response Functions") +
  theme(legend.title = element_blank())

ggsave(file.path(FIG_DIR, "fig3_lp_irfs.pdf"), fig3, width = 8, height = 5)
cat("  Saved fig3_lp_irfs.pdf\n")

# ══════════════════════════════════════════════════════════════════════════
# Figure 4: CPS Mechanism Panels
# ══════════════════════════════════════════════════════════════════════════

cat("Figure 4: Mechanism panels...\n")

# UR LP coefficients by episode
if (!is.null(mech$ur_lp_gr) && !is.null(mech$ur_lp_covid)) {
  ur_gr_plot <- mech$ur_lp_gr[, .(horizon, coef, se, episode = "Great Recession")]
  ur_covid_plot <- mech$ur_lp_covid[, .(horizon, coef, se, episode = "COVID-19")]
  ur_all <- rbind(ur_gr_plot, ur_covid_plot)

  fig4 <- ggplot(ur_all, aes(x = horizon, y = coef, color = episode)) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_ribbon(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se, fill = episode),
                alpha = 0.15, color = NA) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_color_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
    scale_fill_manual(values = c("Great Recession" = BLUE, "COVID-19" = RED)) +
    labs(x = "Months from Peak", y = "UR Change (pp per unit exposure)",
         title = "Unemployment Rate Response by Recession Exposure") +
    theme(legend.title = element_blank())

  ggsave(file.path(FIG_DIR, "fig4_mechanism_ur.pdf"), fig4, width = 8, height = 5)
  cat("  Saved fig4_mechanism_ur.pdf\n")
}

# ══════════════════════════════════════════════════════════════════════════
# Figure 5: Duration-Trap Attenuation
# ══════════════════════════════════════════════════════════════════════════

cat("Figure 5: Duration-trap attenuation...\n")

if (!is.null(mech$coef_base) && !is.null(mech$coef_med)) {
  atten_dt <- data.table(
    spec = c("Baseline", "+ UR(24) mediator", "+ UR(48) mediator"),
    coef = c(mech$coef_base, mech$coef_med,
             if (!is.null(mech$attenuation48)) mech$coef_base * (1 - mech$attenuation48) else NA),
    order = 1:3
  )
  atten_dt <- atten_dt[!is.na(coef)]
  atten_dt[, spec := factor(spec, levels = spec)]

  fig5 <- ggplot(atten_dt, aes(x = spec, y = coef)) +
    geom_col(fill = BLUE, alpha = 0.7, width = 0.6) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(x = "", y = "HPI Coefficient on Long-Run Employment",
         title = "Duration-Trap Attenuation:\nHow Much Does Unemployment Duration Explain?") +
    coord_flip()

  ggsave(file.path(FIG_DIR, "fig5_attenuation.pdf"), fig5, width = 8, height = 4)
  cat("  Saved fig5_attenuation.pdf\n")
}

# ══════════════════════════════════════════════════════════════════════════
# Appendix Figures
# ══════════════════════════════════════════════════════════════════════════

cat("Appendix figures...\n")

# Pre-trend event study
# (placeholder — will be filled from pre-trend results)

# Permutation distribution
if (!is.null(results$perm_p_gr_main)) {
  cat("  Permutation figure: would plot distribution here\n")
}

# Window robustness coefficient plot
if (!is.null(rob$window_dt)) {
  figA_window <- ggplot(rob$window_dt, aes(x = window, y = coef)) +
    geom_point(size = 3, color = BLUE) +
    geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  width = 0.2, color = BLUE) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(x = "Averaging Window (months)", y = "HPI Coefficient",
         title = "Window Robustness: GR Scarring Coefficient") +
    coord_flip()

  ggsave(file.path(FIG_DIR, "figA_window_robustness.pdf"), figA_window, width = 7, height = 4)
  cat("  Saved figA_window_robustness.pdf\n")
}

cat("Figures complete.\n")
