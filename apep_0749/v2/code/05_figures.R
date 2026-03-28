## 05_figures.R — Generate figures for V2 paper
## apep_0749 v2: Beyond Game Day

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

results <- readRDS(file.path(data_dir, "main_results.rds"))
panel_q <- fread(file.path(data_dir, "panel_state_quarter.csv"))
panel_q[, cohort_idx := as.numeric(cohort_idx)]
loo     <- fread(file.path(data_dir, "loo_results.csv"))

# Theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12)
  )

# ============================================================
# FIGURE 1: EVENT STUDY (CS-DiD Dynamic ATT)
# ============================================================
es <- results$cs_alc_es
es_dt <- data.table(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt
)
es_dt[, ci_lo := att - 1.96 * se]
es_dt[, ci_hi := att + 1.96 * se]

fig1 <- ggplot(es_dt, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.5) +
  labs(
    x = "Quarters Relative to OSB Legalization",
    y = "ATT: Alcohol-Involved Fatal Crashes per 100K"
  ) +
  theme_apep +
  annotate("text", x = -4, y = max(es_dt$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", hjust = 1, size = 3, color = "gray40") +
  annotate("text", x = 4, y = max(es_dt$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-treatment", hjust = 0, size = 3, color = "gray40")

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), fig1, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig1_event_study.png"), fig1, width = 7, height = 4.5, dpi = 300)
cat("Figure 1: Event study saved\n")

# ============================================================
# FIGURE 2: HOUR-OF-DAY DECOMPOSITION
# ============================================================
# Run CS-DiD for each hour bin
fars <- fread(file.path(data_dir, "fars_crashes.csv"))
fars[, date := as.Date(date)]
fars[, alcohol_involved := as.integer(DRUNK_DR > 0)]
fars[, hour_bin := fcase(
  HOUR %in% 6:11, "Morning\n(6am-12pm)",
  HOUR %in% 12:17, "Afternoon\n(12pm-6pm)",
  HOUR %in% 18:23, "Evening\n(6pm-12am)",
  HOUR %in% 0:5, "Late Night\n(12am-6am)",
  default = NA_character_
)]

hbin_q <- fars[!is.na(hour_bin) & alcohol_involved == 1, .(
  count = .N
), by = .(state_fips = STATE, year = YEAR, quarter = quarter(date), hour_bin)]

hbin_wide <- dcast(hbin_q, state_fips + year + quarter ~ hour_bin,
                   value.var = "count", fill = 0)

panel_hb <- merge(panel_q[, .(state_fips, year, quarter, time_idx, cohort_idx,
                                population)],
                  hbin_wide, by = c("state_fips", "year", "quarter"), all.x = TRUE)

# Fill NAs
for (col in setdiff(names(panel_hb), c("state_fips","year","quarter","time_idx",
                                         "cohort_idx","population"))) {
  panel_hb[is.na(get(col)), (col) := 0]
}

days_q <- 365.25 / 4
hour_results <- list()
for (hb in c("Morning\n(6am-12pm)", "Afternoon\n(12pm-6pm)",
             "Evening\n(6pm-12am)", "Late Night\n(12am-6am)")) {
  rate_col <- "hb_rate"
  panel_hb[, (rate_col) := get(hb) / (population / 100000) / days_q * 365.25]
  cs <- tryCatch(suppressWarnings(att_gt(
    yname = rate_col, tname = "time_idx", idname = "state_fips", gname = "cohort_idx",
    data = as.data.frame(panel_hb), control_group = "nevertreated",
    anticipation = 0, est_method = "dr", base_period = "universal"
  )), error = function(e) NULL)
  if (!is.null(cs)) {
    agg <- aggte(cs, type = "simple")
    hour_results[[hb]] <- data.table(
      hour_bin = hb,
      att = agg$overall.att,
      se = agg$overall.se
    )
  }
}

hour_dt <- rbindlist(hour_results)
hour_dt[, ci_lo := att - 1.96 * se]
hour_dt[, ci_hi := att + 1.96 * se]
hour_dt[, hour_bin := factor(hour_bin,
  levels = c("Morning\n(6am-12pm)", "Afternoon\n(12pm-6pm)",
             "Evening\n(6pm-12am)", "Late Night\n(12am-6am)"))]

fig2 <- ggplot(hour_dt, aes(x = hour_bin, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "steelblue", size = 0.8) +
  labs(
    x = "Time of Day",
    y = "ATT: Alcohol-Involved Fatal Crashes per 100K"
  ) +
  theme_apep

ggsave(file.path(fig_dir, "fig2_hour_decomposition.pdf"), fig2, width = 6, height = 4)
ggsave(file.path(fig_dir, "fig2_hour_decomposition.png"), fig2, width = 6, height = 4, dpi = 300)
cat("Figure 2: Hour decomposition saved\n")

# ============================================================
# FIGURE 3: GAME-DAY DDD (THE NULL)
# ============================================================
# Extract coefficients from saved model objects (not hard-coded)
ddd_rate <- results$ddd_rate
ddd_pois <- results$ddd_pois
week_ddd <- results$week_ddd

gd_dt <- data.table(
  spec = c("Per-Day Rate\n(TWFE)", "Poisson\n(Count)", "Game Week\n(Weekly)"),
  coef = c(coef(ddd_rate)["treated:game_day"],
           coef(ddd_pois)["treated:game_day"],
           coef(week_ddd)["treated:game_week"]),
  se = c(se(ddd_rate)["treated:game_day"],
         se(ddd_pois)["treated:game_day"],
         se(week_ddd)["treated:game_week"])
)
gd_dt[, ci_lo := coef - 1.96 * se]
gd_dt[, ci_hi := coef + 1.96 * se]
gd_dt[, spec := factor(spec, levels = spec)]

fig3 <- ggplot(gd_dt, aes(x = spec, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "coral3", size = 0.8) +
  labs(
    x = "Game-Day Specification",
    y = "Treated x Game Day Coefficient"
  ) +
  theme_apep

ggsave(file.path(fig_dir, "fig3_gameday_null.pdf"), fig3, width = 5, height = 4)
ggsave(file.path(fig_dir, "fig3_gameday_null.png"), fig3, width = 5, height = 4, dpi = 300)
cat("Figure 3: Game-day null saved\n")

# ============================================================
# FIGURE 4: LEAVE-ONE-OUT
# ============================================================
loo[, dropped_state := as.factor(dropped_state)]
setorder(loo, att)
loo[, rank := 1:.N]

fig4 <- ggplot(loo, aes(x = rank, y = att)) +
  geom_hline(yintercept = results$cs_alc_att$overall.att, linetype = "dashed",
             color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray50") +
  geom_pointrange(aes(ymin = att - 1.96 * se, ymax = att + 1.96 * se),
                  size = 0.4) +
  labs(
    x = "Treated State Dropped (ranked)",
    y = "ATT: Alcohol-Involved Fatal Crashes per 100K"
  ) +
  theme_apep

ggsave(file.path(fig_dir, "fig4_leave_one_out.pdf"), fig4, width = 6, height = 4)
ggsave(file.path(fig_dir, "fig4_leave_one_out.png"), fig4, width = 6, height = 4, dpi = 300)
cat("Figure 4: Leave-one-out saved\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
