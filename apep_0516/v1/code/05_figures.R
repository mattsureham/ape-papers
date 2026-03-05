## ============================================================
## 05_figures.R — Generate all figures from saved data
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE)

# ============================================================
# Load data outputs (NOT models — read CSVs)
# ============================================================

panel <- fread(file.path(DATA_DIR, "panel_main.csv"))
first_stage_agg <- fread(file.path(DATA_DIR, "first_stage_agg.csv"))

# Event study coefficient files
es_main_coefs <- fread(file.path(DATA_DIR, "event_study_main_coefs.csv"))
es_vefa_coefs <- fread(file.path(DATA_DIR, "event_study_vefa_coefs.csv"))
es_existing_coefs <- fread(file.path(DATA_DIR, "event_study_existing_coefs.csv"))
es_volume_coefs <- fread(file.path(DATA_DIR, "event_study_volume_coefs.csv"))
es_border_coefs <- fread(file.path(DATA_DIR, "event_study_border_coefs.csv"))
fs_event_coefs <- fread(file.path(DATA_DIR, "first_stage_event_coefs.csv"))
es_placebo_coefs <- fread(file.path(DATA_DIR, "event_study_placebo_coefs.csv"))
es_nocovid_coefs <- fread(file.path(DATA_DIR, "event_study_nocovid_coefs.csv"))

# Helper: parse event time from fixest coefficient names
parse_event_coefs <- function(dt) {
  dt <- copy(dt)
  # Extract event time from term like "event_time::3:treated"
  dt[, event_time := as.integer(gsub(".*::([-0-9]+).*", "\\1", term))]
  setnames(dt, c("Estimate", "Std. Error"), c("estimate", "se"), skip_absent = TRUE)
  if (!"estimate" %in% names(dt)) {
    # Try alternative column names
    est_col <- grep("estimate|Estimate|coef", names(dt), value = TRUE, ignore.case = TRUE)[1]
    se_col <- grep("std|se|Std", names(dt), value = TRUE, ignore.case = TRUE)[1]
    if (!is.na(est_col)) setnames(dt, est_col, "estimate")
    if (!is.na(se_col)) setnames(dt, se_col, "se")
  }
  dt[, ci_lo := estimate - 1.96 * se]
  dt[, ci_hi := estimate + 1.96 * se]
  # Add reference period
  ref <- data.table(event_time = -1L, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
  dt <- rbind(dt[, .(event_time, estimate, se, ci_lo, ci_hi)], ref, fill = TRUE)
  dt[order(event_time)]
}

# ============================================================
# Figure 1: Raw price trends by zone group
# ============================================================

trends <- panel[zone_group %in% c("B1", "B2/C"),
  .(price_m2 = median(price_m2, na.rm = TRUE),
    n_transactions = sum(n_transactions, na.rm = TRUE)),
  by = .(year, zone_group)
]

fwrite(trends, file.path(DATA_DIR, "fig1_trends.csv"))

fig1 <- ggplot(trends, aes(x = year, y = price_m2,
                            color = zone_group, group = zone_group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = 2019.5, linetype = "dotted", color = "grey60") +
  annotate("text", x = 2017.5, y = Inf, label = "PTZ halved",
           vjust = 2, hjust = 1.1, size = 3, color = "grey40") +
  annotate("text", x = 2019.5, y = Inf, label = "PTZ eliminated",
           vjust = 2, hjust = -0.1, size = 3, color = "grey60") +
  scale_color_manual(values = c("B1" = "#2166AC", "B2/C" = "#B2182B")) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Median Housing Price per m\u00b2 by Zone",
    subtitle = "B1 (retained subsidies) vs. B2/C (lost PTZ and Pinel)",
    x = "Year", y = "Median price per m\u00b2 (\u20ac)",
    color = "Zone"
  )

ggsave(file.path(FIG_DIR, "fig1_price_trends.pdf"), fig1,
       width = 7, height = 5)

# ============================================================
# Figure 2: Event study — All residential prices
# ============================================================

es_df <- parse_event_coefs(es_main_coefs)

fig2 <- ggplot(es_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#2166AC") +
  geom_point(size = 2, color = "#2166AC") +
  geom_line(color = "#2166AC") +
  labs(
    title = "Event Study: Housing Prices in B2/C vs. B1",
    subtitle = "Relative to 2017 (year before PTZ halving)",
    x = "Years relative to 2018 reform",
    y = "Coefficient (log price per m\u00b2)"
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

ggsave(file.path(FIG_DIR, "fig2_event_study_main.pdf"), fig2,
       width = 7, height = 5)

# ============================================================
# Figure 3: First stage — VEFA (new-build) volumes
# ============================================================

# Raw trends
vefa_trends <- first_stage_agg[zone_group %in% c("B1", "B2/C")]
fwrite(vefa_trends, file.path(DATA_DIR, "fig3_vefa_trends.csv"))

fig3a <- ggplot(vefa_trends, aes(x = year, y = n_vefa,
                                  color = zone_group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("B1" = "#2166AC", "B2/C" = "#B2182B")) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "New-Build (VEFA) Transactions by Zone",
    x = "Year", y = "Number of VEFA transactions",
    color = "Zone"
  )

# Event study for first stage
fs_df <- parse_event_coefs(fs_event_coefs)

fig3b <- ggplot(fs_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#D6604D") +
  geom_point(size = 2, color = "#D6604D") +
  geom_line(color = "#D6604D") +
  labs(
    title = "First Stage: New-Build Transactions",
    subtitle = "B2/C vs. B1, relative to 2017",
    x = "Years relative to 2018",
    y = "Coefficient (log VEFA count)"
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

fig3 <- fig3a / fig3b + plot_annotation(tag_levels = "A")
ggsave(file.path(FIG_DIR, "fig3_first_stage.pdf"), fig3,
       width = 7, height = 8)

# ============================================================
# Figure 4: Mechanism — New-build vs existing prices
# ============================================================

es_vefa_df <- parse_event_coefs(es_vefa_coefs)
es_exist_df <- parse_event_coefs(es_existing_coefs)
es_vefa_df[, type := "New-build (VEFA)"]
es_exist_df[, type := "Existing housing"]
mech_df <- rbind(es_vefa_df, es_exist_df)

fig4 <- ggplot(mech_df, aes(x = event_time, y = estimate,
                              color = type, fill = type)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15) +
  geom_point(size = 2) +
  geom_line() +
  scale_color_manual(values = c("New-build (VEFA)" = "#D6604D",
                                 "Existing housing" = "#4393C3")) +
  scale_fill_manual(values = c("New-build (VEFA)" = "#D6604D",
                                "Existing housing" = "#4393C3")) +
  labs(
    title = "Price Effects by Housing Type",
    subtitle = "B2/C vs. B1, relative to 2017",
    x = "Years relative to 2018",
    y = "Coefficient (log price per m\u00b2)",
    color = NULL, fill = NULL
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

ggsave(file.path(FIG_DIR, "fig4_mechanism_newvold.pdf"), fig4,
       width = 7, height = 5)

# ============================================================
# Figure 5: Placebo — Commercial property
# ============================================================

es_plac_df <- parse_event_coefs(es_placebo_coefs)

fig5 <- ggplot(es_plac_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#7F7F7F") +
  geom_point(size = 2, color = "#7F7F7F") +
  geom_line(color = "#7F7F7F") +
  labs(
    title = "Placebo: Commercial Property Prices",
    subtitle = "B2/C vs. B1 (commercial not eligible for PTZ)",
    x = "Years relative to 2018",
    y = "Coefficient (log price)"
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

ggsave(file.path(FIG_DIR, "fig5_placebo_commercial.pdf"), fig5,
       width = 7, height = 5)

# ============================================================
# Figure 6: Border sample event study
# ============================================================

es_bord_df <- parse_event_coefs(es_border_coefs)

fig6 <- ggplot(es_bord_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#4DAF4A") +
  geom_point(size = 2, color = "#4DAF4A") +
  geom_line(color = "#4DAF4A") +
  labs(
    title = "Border Sample: Same-D\u00e9partement B1/B2 Communes",
    subtitle = "Communes sharing a d\u00e9partement with both B1 and B2/C zones",
    x = "Years relative to 2018",
    y = "Coefficient (log price per m\u00b2)"
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

ggsave(file.path(FIG_DIR, "fig6_border_event_study.pdf"), fig6,
       width = 7, height = 5)

# ============================================================
# Figure 7: COVID robustness — Excluding 2020-2021
# ============================================================

es_nc_df <- parse_event_coefs(es_nocovid_coefs)

fig7 <- ggplot(es_nc_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#984EA3") +
  geom_point(size = 2, color = "#984EA3") +
  geom_line(color = "#984EA3") +
  labs(
    title = "Robustness: Excluding COVID Years (2020-2021)",
    subtitle = "B2/C vs. B1, relative to 2017",
    x = "Years relative to 2018",
    y = "Coefficient (log price per m\u00b2)"
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

ggsave(file.path(FIG_DIR, "fig7_nocovid.pdf"), fig7,
       width = 7, height = 5)

# ============================================================
# Figure 8: Transaction volume event study
# ============================================================

es_vol_df <- parse_event_coefs(es_volume_coefs)

fig8 <- ggplot(es_vol_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#FF7F00") +
  geom_point(size = 2, color = "#FF7F00") +
  geom_line(color = "#FF7F00") +
  labs(
    title = "Transaction Volume Effects",
    subtitle = "B2/C vs. B1, relative to 2017",
    x = "Years relative to 2018",
    y = "Coefficient (log transactions)"
  ) +
  scale_x_continuous(breaks = seq(-4, 6, 1))

ggsave(file.path(FIG_DIR, "fig8_volume.pdf"), fig8,
       width = 7, height = 5)

cat("All figures saved to", FIG_DIR, "\n")
