## ===========================================================
## 05_figures.R — All figures
## APEP-0500: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

source("00_packages.R")

state_panel <- read_csv(file.path(data_dir, "state_panel.csv"),
                        show_col_types = FALSE)
lga_panel <- read_csv(file.path(data_dir, "lga_panel.csv"),
                      show_col_types = FALSE)
results <- readRDS(file.path(data_dir, "main_results.rds"))

# -----------------------------------------------------------
# Figure 1: Map of Nigeria with treatment status and violence
# -----------------------------------------------------------
cat("Figure 1: Treatment map...\n")

nga_states <- st_read(file.path(data_dir, "nga_states.gpkg"),
                      layer = "states", quiet = TRUE)

treatment <- read_csv(file.path(data_dir, "treatment_assignment.csv"),
                      show_col_types = FALSE)

map_data <- nga_states %>%
  left_join(treatment %>% select(state, first_treat), by = c("NAME_1" = "state")) %>%
  mutate(
    treat_group = case_when(
      is.na(first_treat) | first_treat == 0 ~ "No law",
      first_treat <= 2019 ~ "Early adopter (2016-2019)",
      first_treat >= 2020 ~ "SGF wave (2021)"
    ),
    treat_group = factor(treat_group,
                         levels = c("Early adopter (2016-2019)",
                                    "SGF wave (2021)", "No law"))
  )

# Violence overlay: total non-state events 2015-2024 by state
violence_by_state <- state_panel %>%
  filter(year >= 2015) %>%
  group_by(state) %>%
  summarise(total_nonstate = sum(events_nonstate), .groups = "drop")

map_data <- map_data %>%
  left_join(violence_by_state, by = c("NAME_1" = "state"))

fig1 <- ggplot(map_data) +
  geom_sf(aes(fill = treat_group), color = "white", linewidth = 0.3) +
  geom_sf_text(aes(label = ifelse(total_nonstate > 20,
                                  paste0(NAME_1, "\n(", total_nonstate, ")"),
                                  "")),
               size = 2, color = "black") +
  scale_fill_manual(
    values = c("Early adopter (2016-2019)" = "#2166AC",
               "SGF wave (2021)" = "#67A9CF",
               "No law" = "#F4A582"),
    name = "Anti-Grazing Law Status"
  ) +
  labs(
    title = "Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria",
    subtitle = "State adoption status with total non-state conflict events (2015-2024)",
    caption = "Source: Anti-grazing law dates from legislative records. Violence from UCDP GED v25.1."
  ) +
  theme_void(base_size = 10) +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 11))

ggsave(file.path(fig_dir, "fig1_treatment_map.pdf"), fig1,
       width = 8, height = 7, device = cairo_pdf)

# -----------------------------------------------------------
# Figure 2: Violence trends by treatment group
# -----------------------------------------------------------
cat("Figure 2: Violence trends...\n")

trends <- state_panel %>%
  filter(year >= 2010) %>%
  mutate(group = case_when(
    first_treat > 0 & first_treat <= 2019 ~ "Early adopter",
    first_treat >= 2020 ~ "SGF wave (2021)",
    TRUE ~ "Never treated"
  )) %>%
  group_by(group, year) %>%
  summarise(
    mean_nonstate = mean(events_nonstate),
    se = sd(events_nonstate) / sqrt(n()),
    .groups = "drop"
  )

fig2 <- ggplot(trends, aes(x = year, y = mean_nonstate, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_ribbon(aes(ymin = mean_nonstate - 1.96 * se,
                  ymax = mean_nonstate + 1.96 * se,
                  fill = group),
              alpha = 0.15, color = NA) +
  geom_vline(xintercept = 2017, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  annotate("text", x = 2017.2, y = max(trends$mean_nonstate) * 0.95,
           label = "Benue law\n(Nov 2017)", size = 2.5, hjust = 0) +
  annotate("text", x = 2021.2, y = max(trends$mean_nonstate) * 0.85,
           label = "SGF wave\n(Aug-Sep 2021)", size = 2.5, hjust = 0) +
  scale_color_manual(values = c("Early adopter" = "#2166AC",
                                "SGF wave (2021)" = "#67A9CF",
                                "Never treated" = "#B2182B")) +
  scale_fill_manual(values = c("Early adopter" = "#2166AC",
                               "SGF wave (2021)" = "#67A9CF",
                               "Never treated" = "#B2182B")) +
  labs(
    x = "Year", y = "Mean non-state violence events per state",
    title = "Non-State Violence Trends by Anti-Grazing Law Adoption Group",
    subtitle = "Mean events per state with 95% confidence intervals",
    color = NULL, fill = NULL
  ) +
  scale_x_continuous(breaks = seq(2010, 2024, 2)) +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig2_trends.pdf"), fig2,
       width = 8, height = 5, device = cairo_pdf)

# -----------------------------------------------------------
# Figure 3: Callaway-Sant'Anna Event Study
# -----------------------------------------------------------
cat("Figure 3: Event study...\n")

es_data <- data.frame(
  e = results$es_nonstate$egt,
  att = results$es_nonstate$att.egt,
  se = results$es_nonstate$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    significant = ci_lo > 0 | ci_hi < 0
  )

fig3 <- ggplot(es_data, aes(x = e, y = att)) +
  geom_hline(yintercept = 0, color = "gray30", linewidth = 0.8) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                width = 0.2, color = "gray40", linewidth = 0.6) +
  geom_point(aes(color = e >= 0), size = 2.5) +
  scale_color_manual(values = c("TRUE" = "#2166AC", "FALSE" = "gray40"),
                     guide = "none") +
  labs(
    x = "Periods relative to law adoption",
    y = "ATT (non-state violence events)",
    title = "Dynamic Treatment Effects: Anti-Grazing Laws on Non-State Violence",
    subtitle = "Callaway-Sant'Anna (2021) estimator, 95% CIs"
  ) +
  annotate("text", x = -3, y = min(es_data$ci_lo) * 0.9,
           label = "Pre-treatment\n(should be ≈ 0)", size = 3,
           color = "gray50") +
  annotate("text", x = 2.5, y = max(es_data$ci_hi) * 0.9,
           label = "Post-treatment", size = 3, color = "#2166AC") +
  theme(axis.title = element_text(size = 11),
        plot.subtitle = element_text(size = 9))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), fig3,
       width = 8, height = 5, device = cairo_pdf)

# -----------------------------------------------------------
# Figure 4: Placebo Event Study (state-based violence)
# -----------------------------------------------------------
cat("Figure 4: Placebo event study...\n")

es_placebo <- data.frame(
  e = results$es_statebased$egt,
  att = results$es_statebased$att.egt,
  se = results$es_statebased$se.egt
) %>%
  mutate(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)

fig4 <- ggplot(es_placebo, aes(x = e, y = att)) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.5) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2, color = "gray40") +
  geom_point(size = 2, color = "#D6604D") +
  labs(
    x = "Periods relative to law adoption",
    y = "ATT (state-based violence events)",
    title = "Placebo Test: Anti-Grazing Laws on State-Based Violence (Boko Haram)",
    subtitle = "Should show null effects — anti-grazing laws target pastoral conflict, not insurgency"
  )

ggsave(file.path(fig_dir, "fig4_placebo_event_study.pdf"), fig4,
       width = 8, height = 5, device = cairo_pdf)

# -----------------------------------------------------------
# Figure 5: Randomization Inference Distribution
# -----------------------------------------------------------
cat("Figure 5: RI distribution...\n")

ri_results <- readRDS(file.path(data_dir, "ri_results.rds"))

fig5 <- ggplot(data.frame(coef = ri_results$perm_coefs), aes(x = coef)) +
  geom_histogram(bins = 50, fill = "gray70", color = "white") +
  geom_vline(xintercept = ri_results$obs_coef, color = "red",
             linewidth = 1, linetype = "dashed") +
  labs(
    x = "Permuted DDD coefficient",
    y = "Count",
    title = "Randomization Inference: Distribution of Permuted Coefficients",
    subtitle = sprintf("Observed = %.4f (red). RI p-value = %.4f (%d permutations)",
                       ri_results$obs_coef, ri_results$ri_pval, length(ri_results$perm_coefs))
  )

ggsave(file.path(fig_dir, "fig5_ri_distribution.pdf"), fig5,
       width = 7, height = 4.5, device = cairo_pdf)

# -----------------------------------------------------------
# Figure 6: Leave-One-Out Sensitivity
# -----------------------------------------------------------
cat("Figure 6: Leave-one-out...\n")

loo <- readRDS(file.path(data_dir, "loo_results.rds"))

fig6 <- ggplot(data.frame(state = names(loo), coef = loo),
               aes(x = reorder(state, coef), y = coef)) +
  geom_point(size = 2) +
  geom_hline(yintercept = ri_results$obs_coef, color = "red",
             linewidth = 0.8, linetype = "dashed") +
  coord_flip() +
  labs(
    x = "Excluded state", y = "DDD coefficient",
    title = "Leave-One-State-Out: DDD Coefficient Stability",
    subtitle = sprintf("Full-sample estimate = %.4f (red dashed)", ri_results$obs_coef)
  )

ggsave(file.path(fig_dir, "fig6_loo.pdf"), fig6,
       width = 7, height = 5, device = cairo_pdf)

# -----------------------------------------------------------
# Figure 7: DDD Event Study (leads/lags of D_st × P_i)
# -----------------------------------------------------------
cat("Figure 7: DDD event study...\n")

ddd_es_df <- tryCatch(
  readRDS(file.path(data_dir, "ddd_event_study.rds")),
  error = function(e) NULL
)

if (!is.null(ddd_es_df) && nrow(ddd_es_df) > 0) {
  fig7 <- ggplot(ddd_es_df, aes(x = e, y = att)) +
    geom_hline(yintercept = 0, color = "gray30", linewidth = 0.8) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", linewidth = 0.5) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                  width = 0.2, color = "gray40", linewidth = 0.6) +
    geom_point(aes(color = e >= 0), size = 2.5) +
    scale_color_manual(values = c("TRUE" = "#2166AC", "FALSE" = "gray40"),
                       guide = "none") +
    labs(
      x = "Periods relative to law adoption",
      y = expression(beta[k] ~ "(DDD: Post × Pastoral interaction)"),
      title = "DDD Event Study: Leads and Lags of Treatment × Pastoral",
      subtitle = "LGA FE + State×Year FE, 95% CIs, reference period k = -1"
    ) +
    theme(axis.title = element_text(size = 11),
          plot.subtitle = element_text(size = 9))

  ggsave(file.path(fig_dir, "fig7_ddd_event_study.pdf"), fig7,
         width = 8, height = 5, device = cairo_pdf)
  cat("Figure 7 saved.\n")
} else {
  cat("No DDD event study data available, skipping Figure 7.\n")
}

cat("\nAll figures saved.\n")
