# ==============================================================================
# 05_figures.R — All Figure Generation
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "panel_combined.csv"))

# ─── Figure 1: ERPO Adoption Timeline ───────────────────────────────────────

cat("=== Figure 1: ERPO Adoption Timeline ===\n")

erpo <- fread(file.path(data_dir, "erpo_adoption_dates.csv"))
erpo <- erpo[order(erpo_year, state)]
erpo[, state_short := state.abb[match(state, state.name)]]
erpo[state == "District of Columbia", state_short := "DC"]

# Count cumulative states
erpo_cumul <- erpo[, .(n_states = .N), by = erpo_year]
erpo_cumul[, cumulative := cumsum(n_states)]

p1 <- ggplot(erpo_cumul, aes(x = erpo_year, y = cumulative)) +
  geom_step(size = 1.2, color = "#2166AC") +
  geom_point(size = 3, color = "#2166AC") +
  geom_vline(xintercept = 2018, linetype = "dashed", color = "red", alpha = 0.7) +
  annotate("text", x = 2018.3, y = 3, label = "Parkland\n(Feb 2018)",
           color = "red", size = 3, hjust = 0) +
  annotate("text", x = 2004, y = 18,
           label = "Pre-Parkland:\n5 states (1999-2017)",
           size = 3, color = "grey40") +
  annotate("text", x = 2021, y = 15,
           label = "Post-Parkland:\n17 states (2018-2024)",
           size = 3, color = "grey40") +
  scale_x_continuous(breaks = seq(2000, 2024, 4)) +
  scale_y_continuous(breaks = seq(0, 25, 5)) +
  labs(
    title = "Staggered Adoption of ERPO Laws",
    x = "Year of Adoption",
    y = "Cumulative Number of States"
  )

ggsave(file.path(fig_dir, "fig1_adoption_timeline.pdf"), p1,
       width = 8, height = 5)
ggsave(file.path(fig_dir, "fig1_adoption_timeline.png"), p1,
       width = 8, height = 5, dpi = 300)

# ─── Figure 2: Event Study — Total Suicide Rate ─────────────────────────────

cat("=== Figure 2: Event Study — Total Suicide ===\n")

es_total <- readRDS(file.path(data_dir, "es_total_suicide.rds"))

es_dt <- data.table(
  e = es_total$egt,
  att = es_total$att.egt,
  se = es_total$se.egt
)
es_dt[, `:=`(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)]

p2 <- ggplot(es_dt, aes(x = e, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#2166AC") +
  geom_line(color = "#2166AC", size = 0.8) +
  geom_point(color = "#2166AC", size = 2.5) +
  labs(
    title = "Effect of ERPO Laws on Total Suicide Rate",
    subtitle = "Callaway-Sant'Anna event study, 1999-2024 panel",
    x = "Years Relative to ERPO Adoption",
    y = "ATT (Age-Adjusted Rate per 100K)"
  ) +
  annotate("text", x = min(es_dt$e) + 0.5, y = max(es_dt$ci_hi) * 0.9,
           label = "Pre-treatment", color = "grey40", size = 3) +
  annotate("text", x = max(es_dt$e) - 0.5, y = max(es_dt$ci_hi) * 0.9,
           label = "Post-treatment", color = "grey40", size = 3)

ggsave(file.path(fig_dir, "fig2_es_total_suicide.pdf"), p2,
       width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig2_es_total_suicide.png"), p2,
       width = 8, height = 5.5, dpi = 300)

# ─── Figure 3: Mechanism Decomposition ──────────────────────────────────────

cat("=== Figure 3: Mechanism Decomposition ===\n")

es_fa <- readRDS(file.path(data_dir, "es_fa_suicide.rds"))
es_nf <- readRDS(file.path(data_dir, "es_nf_suicide.rds"))

es_fa_dt <- data.table(e = es_fa$egt, att = es_fa$att.egt,
                        se = es_fa$se.egt, outcome = "Firearm Suicide")
es_nf_dt <- data.table(e = es_nf$egt, att = es_nf$att.egt,
                        se = es_nf$se.egt, outcome = "Non-Firearm Suicide")

es_mech <- rbindlist(list(es_fa_dt, es_nf_dt))
es_mech[, `:=`(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)]

p3 <- ggplot(es_mech, aes(x = e, y = att, color = outcome, fill = outcome)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, color = NA) +
  geom_line(size = 0.8) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("Firearm Suicide" = "#B2182B",
                                 "Non-Firearm Suicide" = "#4393C3")) +
  scale_fill_manual(values = c("Firearm Suicide" = "#B2182B",
                                "Non-Firearm Suicide" = "#4393C3")) +
  labs(
    title = NULL,
    subtitle = NULL,
    x = "Years Relative to ERPO Adoption",
    y = "ATT (Age-Adjusted Rate per 100K)",
    color = "", fill = ""
  )

ggsave(file.path(fig_dir, "fig3_mechanism_decomposition.pdf"), p3,
       width = 9, height = 5.5)
ggsave(file.path(fig_dir, "fig3_mechanism_decomposition.png"), p3,
       width = 9, height = 5.5, dpi = 300)

# ─── Figure 4: Placebo Test — Drug Overdose ─────────────────────────────────

cat("=== Figure 4: Placebo — Drug OD ===\n")

es_drug <- readRDS(file.path(data_dir, "es_drug_od.rds"))

es_drug_dt <- data.table(e = es_drug$egt, att = es_drug$att.egt,
                          se = es_drug$se.egt)
es_drug_dt[, `:=`(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)]

p4 <- ggplot(es_drug_dt, aes(x = e, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#7570B3") +
  geom_line(color = "#7570B3", size = 0.8) +
  geom_point(color = "#7570B3", size = 2.5) +
  labs(
    title = NULL,
    subtitle = NULL,
    x = "Years Relative to ERPO Adoption",
    y = "ATT (Age-Adjusted Rate per 100K)"
  )

ggsave(file.path(fig_dir, "fig4_placebo_drug_od.pdf"), p4,
       width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig4_placebo_drug_od.png"), p4,
       width = 8, height = 5.5, dpi = 300)

# ─── Figure 5: Average Suicide Rates by Treatment Group ─────────────────────

cat("=== Figure 5: Average Rates by Treatment Group ===\n")

avg_rates <- panel[, .(
  mean_rate = mean(rate_All_Suicide, na.rm = TRUE),
  se_rate = sd(rate_All_Suicide, na.rm = TRUE) / sqrt(.N)
), by = .(year, erpo_status)]

avg_rates <- avg_rates[erpo_status %in% c("ERPO adopted", "Never treated")]

p5 <- ggplot(avg_rates, aes(x = year, y = mean_rate,
                              color = erpo_status, group = erpo_status)) +
  geom_line(size = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("ERPO adopted" = "#B2182B",
                                 "Never treated" = "#2166AC")) +
  labs(
    title = "Average Total Suicide Rate by ERPO Status",
    subtitle = "Age-adjusted rate per 100,000 population",
    x = "Year",
    y = "Suicide Rate (per 100K)",
    color = ""
  ) +
  scale_x_continuous(breaks = seq(2000, 2024, 4))

ggsave(file.path(fig_dir, "fig5_avg_rates_by_group.pdf"), p5,
       width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig5_avg_rates_by_group.png"), p5,
       width = 8, height = 5.5, dpi = 300)

# ─── Figure 6: Leave-One-Out Sensitivity ────────────────────────────────────

cat("=== Figure 6: Leave-One-Out ===\n")

loo <- fread(file.path(data_dir, "leave_one_out.csv"))
loo <- loo[!is.na(att)]

# Add full-sample result
agg_total <- readRDS(file.path(data_dir, "agg_total_suicide.rds"))
loo_full <- rbind(
  data.table(dropped_state = "None (full sample)",
             att = agg_total$overall.att,
             se = agg_total$overall.se,
             p_value = 2 * pnorm(-abs(agg_total$overall.att / agg_total$overall.se))),
  loo
)
loo_full[, `:=`(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)]

p6 <- ggplot(loo_full, aes(x = reorder(dropped_state, att), y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_hline(yintercept = agg_total$overall.att,
             linetype = "dotted", color = "#B2182B") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#2166AC", size = 0.5) +
  coord_flip() +
  labs(
    title = "Leave-One-Out Sensitivity",
    subtitle = "ATT on total suicide rate, dropping each treated state",
    x = "",
    y = "ATT (Age-Adjusted Rate per 100K)"
  )

ggsave(file.path(fig_dir, "fig6_leave_one_out.pdf"), p6,
       width = 8, height = 6)
ggsave(file.path(fig_dir, "fig6_leave_one_out.png"), p6,
       width = 8, height = 6, dpi = 300)

# ─── Figure 7: ERPO Adoption Map ────────────────────────────────────────────

cat("=== Figure 7: State Map ===\n")

# Create map data
erpo_all <- fread(file.path(data_dir, "erpo_adoption_dates.csv"))
anti <- fread(file.path(data_dir, "anti_erpo_states.csv"))

all_states_map <- data.table(state = state.name)
all_states_map[state == "District of Columbia", state := "District of Columbia"]
all_states_map <- merge(all_states_map, erpo_all[, .(state, erpo_year, wave)],
                         by = "state", all.x = TRUE)
all_states_map <- merge(all_states_map, anti, by = "state", all.x = TRUE)
all_states_map[is.na(anti_erpo), anti_erpo := FALSE]

all_states_map[, status := fifelse(
  !is.na(erpo_year) & wave == "Pre-Parkland", "Pre-Parkland ERPO",
  fifelse(!is.na(erpo_year) & wave == "Post-Parkland", "Post-Parkland ERPO",
  fifelse(anti_erpo, "Anti-ERPO", "No ERPO law"))
)]

all_states_map[, region := tolower(state)]

# Merge with map data
us_map <- map_data("state")
map_merged <- merge(us_map, all_states_map, by = "region", all.x = TRUE)
map_merged <- map_merged[order(map_merged$order), ]

p7 <- ggplot(map_merged, aes(x = long, y = lat, group = group, fill = status)) +
  geom_polygon(color = "white", size = 0.2) +
  scale_fill_manual(
    values = c(
      "Pre-Parkland ERPO" = "#B2182B",
      "Post-Parkland ERPO" = "#EF8A62",
      "Anti-ERPO" = "#2166AC",
      "No ERPO law" = "#D9D9D9"
    ),
    na.value = "#D9D9D9"
  ) +
  coord_map("polyconic") +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom") +
  labs(
    title = "ERPO Law Status Across US States",
    fill = ""
  )

ggsave(file.path(fig_dir, "fig7_erpo_map.pdf"), p7,
       width = 10, height = 6)
ggsave(file.path(fig_dir, "fig7_erpo_map.png"), p7,
       width = 10, height = 6, dpi = 300)

cat("\nAll figures saved to ", fig_dir, "\n")
cat("DONE.\n")
