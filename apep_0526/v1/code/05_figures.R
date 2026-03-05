# =============================================================================
# 05_figures.R — All figures for the paper
# =============================================================================
source("00_packages.R")

# ---------------------------------------------------------------------------
# Figure 1: Right-to-Try Law Adoption Timeline Map
# ---------------------------------------------------------------------------
rtt_laws <- fread(file.path(DATA_DIR, "rtt_law_dates.csv"))
rtt_laws[, rtt_date := as.Date(rtt_date)]
rtt_laws[, adoption_year := year(rtt_date)]

# State-level data for map
library(maps)
state_map <- as.data.table(map_data("state"))
state_map[, state_name := tools::toTitleCase(region)]

# Merge adoption years
rtt_map <- merge(rtt_laws, data.table(state = state.name, state_lower = tolower(state.name)),
                 by = "state", all.x = TRUE)
state_map <- merge(state_map, rtt_map[, .(state_lower, adoption_year)],
                   by.x = "region", by.y = "state_lower", all.x = TRUE)
state_map[is.na(adoption_year), adoption_year := 2018]  # Federal law

p_map <- ggplot(state_map, aes(x = long, y = lat, group = group, fill = factor(adoption_year))) +
  geom_polygon(color = "white", linewidth = 0.2) +
  scale_fill_viridis_d(name = "Year Enacted", option = "D",
                        labels = c("2014", "2015", "2016", "2017", "2018\n(Federal)")) +
  coord_map("polyconic") +
  labs(title = "Staggered Adoption of State Right-to-Try Laws") +
  theme_void(base_size = 10) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", hjust = 0.5))

ggsave(file.path(FIG_DIR, "fig1_adoption_map.pdf"), p_map, width = 8, height = 5)
cat("Figure 1 saved.\n")

# ---------------------------------------------------------------------------
# Figure 2: Raw Trends in Trial Activity
# ---------------------------------------------------------------------------
panel <- fread(file.path(DATA_DIR, "panel_state_quarter.csv"))

# Aggregate to quarter level by treatment status (pre/post adoption)
panel[, ever_treated := fifelse(cohort_yq > 0, "Eventually Treated", "Never Treated (State Law)")]

trends <- panel[, .(
  mean_trials = mean(n_trials),
  mean_enrollment = mean(total_enrollment),
  mean_terminal = mean(n_terminal)
), by = .(year, quarter, ever_treated)]
trends[, date := as.Date(paste0(year, "-", (quarter - 1) * 3 + 1, "-01"))]

p_trends <- ggplot(trends, aes(x = date, y = mean_trials, color = ever_treated)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2014-05-01"), linetype = "dashed", alpha = 0.5) +
  annotate("text", x = as.Date("2014-05-01"), y = Inf, label = "First RTT law\n(CO, May 2014)",
           hjust = -0.1, vjust = 1.5, size = 3) +
  scale_color_manual(values = c("Eventually Treated" = "#2c7bb6", "Never Treated (State Law)" = "#d7191c"),
                     name = NULL) +
  labs(x = NULL, y = "Mean Phase II/III Trial Sites per State-Quarter",
       title = "Clinical Trial Activity by Right-to-Try Treatment Status") +
  theme(legend.position = c(0.25, 0.85))

ggsave(file.path(FIG_DIR, "fig2_raw_trends.pdf"), p_trends, width = 8, height = 5)
cat("Figure 2 saved.\n")

# ---------------------------------------------------------------------------
# Figure 3: CS Event Study — Main Outcomes
# ---------------------------------------------------------------------------
es_trials <- fread(file.path(DATA_DIR, "es_trials.csv"))
es_enrollment <- fread(file.path(DATA_DIR, "es_enrollment.csv"))
es_terminal <- fread(file.path(DATA_DIR, "es_terminal.csv"))

es_all <- rbindlist(list(es_trials, es_enrollment, es_terminal))
es_all[, outcome_label := fcase(
  outcome == "ln_trials", "A. Trial Sites (Phase II/III)",
  outcome == "ln_enrollment", "B. Total Enrollment",
  outcome == "ln_terminal", "C. Terminal Condition Trials"
)]

p_es <- ggplot(es_all, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "gray50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "gray50", linetype = "dashed") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#2c7bb6", alpha = 0.2) +
  geom_point(color = "#2c7bb6", size = 1.5) +
  geom_line(color = "#2c7bb6", linewidth = 0.5) +
  facet_wrap(~outcome_label, scales = "free_y", ncol = 1) +
  labs(x = "Quarters Relative to Right-to-Try Adoption",
       y = "ATT (log points)",
       title = "Dynamic Treatment Effects of Right-to-Try Laws on Clinical Trials") +
  scale_x_continuous(breaks = seq(-8, 8, 2))

ggsave(file.path(FIG_DIR, "fig3_event_study.pdf"), p_es, width = 7, height = 9)
cat("Figure 3 saved.\n")

# ---------------------------------------------------------------------------
# Figure 4: Placebo Tests
# ---------------------------------------------------------------------------
placebo_files <- list.files(DATA_DIR, pattern = "es_placebo_", full.names = TRUE)
placebo_data <- rbindlist(lapply(placebo_files, fread))
placebo_data[, outcome_label := fcase(
  outcome == "placebo_nonterminal", "A. Non-Terminal Conditions\n(Placebo)",
  outcome == "placebo_phase1", "B. Phase I Trials\n(Placebo)",
  outcome == "placebo_observational", "C. Observational Studies\n(Placebo)"
)]

p_placebo <- ggplot(placebo_data, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "gray50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "gray50", linetype = "dashed") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#fdae61", alpha = 0.3) +
  geom_point(color = "#d73027", size = 1.5) +
  geom_line(color = "#d73027", linewidth = 0.5) +
  facet_wrap(~outcome_label, scales = "free_y", ncol = 1) +
  labs(x = "Quarters Relative to Right-to-Try Adoption",
       y = "ATT (log points)",
       title = "Placebo Tests: Outcomes Unaffected by Right-to-Try Laws") +
  scale_x_continuous(breaks = seq(-8, 8, 2))

ggsave(file.path(FIG_DIR, "fig4_placebo_tests.pdf"), p_placebo, width = 7, height = 9)
cat("Figure 4 saved.\n")

# ---------------------------------------------------------------------------
# Figure 5: Randomization Inference Distribution
# ---------------------------------------------------------------------------
ri_perms <- fread(file.path(DATA_DIR, "ri_permutations.csv"))
ri_summary <- fread(file.path(DATA_DIR, "ri_summary.csv"))

p_ri <- ggplot(ri_perms, aes(x = perm_coefs)) +
  geom_histogram(fill = "gray70", color = "white", bins = 50) +
  geom_vline(xintercept = ri_summary$observed, color = "#d73027", linewidth = 1) +
  geom_vline(xintercept = -ri_summary$observed, color = "#d73027", linewidth = 1, linetype = "dashed") +
  annotate("text", x = ri_summary$observed, y = Inf,
           label = paste0("Observed\n(p = ", round(ri_summary$ri_pval, 3), ")"),
           hjust = -0.1, vjust = 1.5, color = "#d73027", size = 3.5) +
  labs(x = "Permuted Treatment Effect",
       y = "Count",
       title = "Randomization Inference: Distribution of Placebo Treatment Effects") +
  theme(plot.title = element_text(size = 11))

ggsave(file.path(FIG_DIR, "fig5_ri_distribution.pdf"), p_ri, width = 7, height = 4.5)
cat("Figure 5 saved.\n")

# ---------------------------------------------------------------------------
# Figure 6: Robustness — Leave-One-State-Out
# ---------------------------------------------------------------------------
loo <- fread(file.path(DATA_DIR, "loo_results.csv"))
cs_main <- fread(file.path(DATA_DIR, "cs_summary.csv"))
main_att <- cs_main[outcome == "Trial Sites (Phase II/III)", att]
main_se <- cs_main[outcome == "Trial Sites (Phase II/III)", se]

loo[, ci_lower := att - 1.96 * se]
loo[, ci_upper := att + 1.96 * se]

p_loo <- ggplot(loo, aes(x = reorder(dropped, att), y = att)) +
  geom_hline(yintercept = main_att, color = "#2c7bb6", linewidth = 0.8) +
  geom_hline(yintercept = main_att + 1.96 * main_se, color = "#2c7bb6",
             linewidth = 0.5, linetype = "dashed") +
  geom_hline(yintercept = main_att - 1.96 * main_se, color = "#2c7bb6",
             linewidth = 0.5, linetype = "dashed") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper), color = "#d73027") +
  coord_flip() +
  labs(x = "State Dropped", y = "CS-DiD ATT (log points)",
       title = "Leave-One-State-Out: Sensitivity to Major Biotech Hubs") +
  annotate("text", x = 0.5, y = main_att,
           label = "Full sample estimate", color = "#2c7bb6", hjust = -0.1, size = 3)

ggsave(file.path(FIG_DIR, "fig6_loo_robustness.pdf"), p_loo, width = 7, height = 4.5)
cat("Figure 6 saved.\n")

# ---------------------------------------------------------------------------
# Figure 7: Bacon Decomposition (if available)
# ---------------------------------------------------------------------------
bacon_file <- file.path(DATA_DIR, "bacon_decomp.csv")
if (file.exists(bacon_file)) {
  bacon <- fread(bacon_file)

  p_bacon <- ggplot(bacon, aes(x = weight, y = estimate, color = type)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_point(size = 2, alpha = 0.7) +
    scale_color_brewer(palette = "Set1", name = "Comparison Type") +
    labs(x = "Weight", y = "2×2 DiD Estimate",
         title = "Bacon Decomposition of TWFE Estimator") +
    theme(legend.position = "bottom")

  ggsave(file.path(FIG_DIR, "fig7_bacon_decomp.pdf"), p_bacon, width = 7, height = 5)
  cat("Figure 7 saved.\n")
}

cat("\nAll figures complete.\n")
