# ==============================================================================
# 05_figures.R — Generate all figures
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ==============================================================================
# FIGURE 1: Map of state gas tax changes (treatment variation)
# ==============================================================================

cat("Figure 1: Treatment map\n")

gas_tax <- fread(file.path(data_dir, "gas_tax_changes.csv")) %>%
  group_by(state_abbr) %>%
  slice(1) %>%
  ungroup()

# State map data
state_map <- map_data("state")
state_xwalk <- tibble(
  state_name = tolower(state.name),
  state_abbr = state.abb
)

map_data_merged <- state_map %>%
  left_join(state_xwalk, by = c("region" = "state_name")) %>%
  left_join(gas_tax %>% select(state_abbr, treat_year, increase_cpg),
            by = "state_abbr") %>%
  mutate(
    treatment_group = case_when(
      is.na(treat_year) ~ "Never treated",
      treat_year <= 2015 ~ "2013-2015",
      treat_year <= 2017 ~ "2016-2017",
      treat_year >= 2018 ~ "2018-2021"
    )
  )

fig1 <- ggplot(map_data_merged, aes(x = long, y = lat, group = group)) +
  geom_polygon(aes(fill = treatment_group), color = "white", linewidth = 0.3) +
  scale_fill_manual(
    values = c("Never treated" = "grey85",
               "2013-2015" = "#0072B2",
               "2016-2017" = "#D55E00",
               "2018-2021" = "#009E73"),
    name = "Treatment cohort",
    na.value = "grey95"
  ) +
  coord_map("albers", lat0 = 30, lat1 = 45) +
  labs(title = "State Gasoline Tax Increases, 2013-2021",
       subtitle = "Discrete legislative increases (excluding automatic indexation)",
       caption = "Sources: Tax Foundation, NCSL, FHWA") +
  theme_apep() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.line = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  )

ggsave(file.path(fig_dir, "fig1_treatment_map.pdf"), fig1, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig1_treatment_map.png"), fig1, width = 8, height = 5, dpi = 300)

# ==============================================================================
# FIGURE 2: Event study — CS-DiD (primary specification)
# ==============================================================================

cat("Figure 2: Event study\n")

es_data <- fread(file.path(data_dir, "cs_event_study.csv"))

fig2 <- ggplot(es_data, aes(x = rel_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey50", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = apep_colors[1], alpha = 0.2) +
  geom_point(color = apep_colors[1], size = 2.5) +
  geom_line(color = apep_colors[1], linewidth = 0.6) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, color = apep_colors[1], linewidth = 0.4) +
  scale_x_continuous(breaks = seq(-7, 7, 1)) +
  labs(
    x = "Years relative to gas tax increase",
    y = "ATT on economic pessimism (1-5 scale)",
    title = "Effect of State Gas Tax Increases on Macroeconomic Beliefs",
    subtitle = "Callaway-Sant'Anna event study, never-treated control group",
    caption = "Notes: 95% confidence intervals. Outcome: CES economy retrospection (1=much better, 5=much worse).\nUnit of observation: state-year. Standard errors clustered by state."
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig2_event_study.png"), fig2, width = 8, height = 5.5, dpi = 300)

# ==============================================================================
# FIGURE 3: Event study comparison — Never-treated vs. Not-yet-treated
# ==============================================================================

cat("Figure 3: Control group comparison\n")

nyt_data <- fread(file.path(data_dir, "cs_event_study_nyt.csv"))

es_combined <- bind_rows(
  es_data %>% mutate(control = "Never-treated"),
  nyt_data %>% mutate(control = "Not-yet-treated")
)

fig3 <- ggplot(es_combined, aes(x = rel_time, y = att, color = control, fill = control)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey50", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.15, color = NA) +
  geom_point(size = 2, position = position_dodge(width = 0.3)) +
  geom_line(linewidth = 0.5, position = position_dodge(width = 0.3)) +
  scale_color_manual(values = apep_colors[1:2], name = "Control group") +
  scale_fill_manual(values = apep_colors[1:2], name = "Control group") +
  scale_x_continuous(breaks = seq(-7, 7, 1)) +
  labs(
    x = "Years relative to gas tax increase",
    y = "ATT on economic pessimism",
    title = "Robustness: Alternative Control Groups",
    subtitle = "Callaway-Sant'Anna with never-treated vs. not-yet-treated controls"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig3_control_comparison.pdf"), fig3, width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig3_control_comparison.png"), fig3, width = 8, height = 5.5, dpi = 300)

# ==============================================================================
# FIGURE 4: Binary outcome event study
# ==============================================================================

cat("Figure 4: Binary outcome\n")

binary_es <- fread(file.path(data_dir, "cs_event_study_binary.csv"))

fig4 <- ggplot(binary_es, aes(x = rel_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey50", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = apep_colors[3], alpha = 0.2) +
  geom_point(color = apep_colors[3], size = 2.5) +
  geom_line(color = apep_colors[3], linewidth = 0.6) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, color = apep_colors[3], linewidth = 0.4) +
  scale_x_continuous(breaks = seq(-7, 7, 1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  labs(
    x = "Years relative to gas tax increase",
    y = "ATT on Pr(economy 'gotten worse')",
    title = "Effect on Probability of Pessimistic Assessment",
    subtitle = "Outcome: indicator for 'somewhat' or 'much' worse",
    caption = "Notes: 95% CI. Callaway-Sant'Anna, never-treated control."
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig4_binary_event_study.pdf"), fig4, width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig4_binary_event_study.png"), fig4, width = 8, height = 5.5, dpi = 300)

# ==============================================================================
# FIGURE 5: Google Trends event study (secondary outcome)
# ==============================================================================

cat("Figure 5: Google Trends\n")

gt_es_file <- file.path(data_dir, "gt_event_study.csv")
if (file.exists(gt_es_file)) {
  gt_es <- fread(gt_es_file)

  fig5 <- ggplot(gt_es, aes(x = rel_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_vline(xintercept = -0.5, color = "grey50", linetype = "dotted") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = apep_colors[2], alpha = 0.2) +
    geom_point(color = apep_colors[2], size = 2.5) +
    geom_line(color = apep_colors[2], linewidth = 0.6) +
    scale_x_continuous(breaks = seq(-5, 5, 1)) +
    labs(
      x = "Years relative to gas tax increase",
      y = "ATT on Google Trends 'inflation' index",
      title = "Effect on Inflation Search Attention",
      subtitle = "Google Trends search intensity (0-100), state-year panel",
      caption = "Notes: 95% CI. CS-DiD, never-treated control."
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig5_gtrends_event_study.pdf"), fig5, width = 8, height = 5.5)
  ggsave(file.path(fig_dir, "fig5_gtrends_event_study.png"), fig5, width = 8, height = 5.5, dpi = 300)
}

# ==============================================================================
# FIGURE 6: Dose-response — Effect by size of gas tax increase
# ==============================================================================

cat("Figure 6: Dose-response\n")

dose_data <- fread(file.path(data_dir, "dose_response.csv"))

if (nrow(dose_data) > 0 && "dose" %in% dose_data$variable) {
  # Create dose-response visualization from the regression coefficient
  dose_coef <- dose_data %>% filter(variable == "dose")

  dose_plot_data <- tibble(
    increase_cpg = seq(2, 25, 1),
    predicted_effect = dose_coef$coef * seq(2, 25, 1),
    ci_lower = (dose_coef$coef - 1.96 * dose_coef$se) * seq(2, 25, 1),
    ci_upper = (dose_coef$coef + 1.96 * dose_coef$se) * seq(2, 25, 1)
  )

  fig6 <- ggplot(dose_plot_data, aes(x = increase_cpg, y = predicted_effect)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = apep_colors[1], alpha = 0.2) +
    geom_line(color = apep_colors[1], linewidth = 0.8) +
    labs(
      x = "Gas tax increase (cents per gallon)",
      y = "Predicted effect on pessimism (1-5 scale)",
      title = "Dose-Response: Effect Scales with Tax Increase Size",
      subtitle = "Linear prediction from TWFE with continuous treatment intensity",
      caption = "Notes: 95% CI. Shading shows confidence band."
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig6_dose_response.pdf"), fig6, width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig6_dose_response.png"), fig6, width = 7, height = 5, dpi = 300)
}

# ==============================================================================
# FIGURE 7: Heterogeneity — Partisan beliefs
# ==============================================================================

cat("Figure 7: Partisan heterogeneity\n")

party_file <- file.path(data_dir, "heterogeneity_party.csv")
if (file.exists(party_file)) {
  party_data <- fread(party_file) %>%
    filter(grepl("post", term))

  # Construct effects for each party
  # The base is Democrat (reference). Republican and Independent are interactions.
  base_effect <- party_data %>% filter(term == "post") %>% pull(estimate)
  base_se <- party_data %>% filter(term == "post") %>% pull(std.error)

  party_effects <- tibble(
    party = c("Democrat", "Republican", "Independent"),
    effect = c(
      base_effect,
      base_effect + party_data %>% filter(grepl("Republican", term)) %>% pull(estimate),
      base_effect + party_data %>% filter(grepl("Independent", term)) %>% pull(estimate)
    ),
    se = c(base_se,
           sqrt(base_se^2 + (party_data %>% filter(grepl("Republican", term)) %>% pull(std.error))^2),
           sqrt(base_se^2 + (party_data %>% filter(grepl("Independent", term)) %>% pull(std.error))^2))
  ) %>%
    mutate(
      ci_lower = effect - 1.96 * se,
      ci_upper = effect + 1.96 * se,
      party = factor(party, levels = c("Democrat", "Independent", "Republican"))
    )

  fig7 <- ggplot(party_effects, aes(x = party, y = effect, color = party)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.15, linewidth = 0.6) +
    scale_color_manual(values = c("Democrat" = "#2166AC", "Independent" = "#808080",
                                   "Republican" = "#B2182B")) +
    labs(
      x = "",
      y = "Effect on pessimism (1-5 scale)",
      title = "Partisan Heterogeneity in Gas Tax Effects",
      subtitle = "Effect of gas tax increase on economic pessimism by party affiliation",
      caption = "Notes: 95% CI. TWFE with party interaction. SE clustered by state."
    ) +
    theme_apep() +
    theme(legend.position = "none")

  ggsave(file.path(fig_dir, "fig7_partisan_heterogeneity.pdf"), fig7, width = 6, height = 5)
  ggsave(file.path(fig_dir, "fig7_partisan_heterogeneity.png"), fig7, width = 6, height = 5, dpi = 300)
}

# ==============================================================================
# FIGURE 8: National context — Gas prices and consumer sentiment
# ==============================================================================

cat("Figure 8: National context\n")

gas_national <- fread(file.path(data_dir, "gas_national.csv"))

# Get Michigan Consumer Sentiment from FRED
umcsent <- tryCatch({
  fredr(series_id = "UMCSENT",
        observation_start = as.Date("2005-01-01"),
        observation_end = as.Date("2024-12-31")) %>%
    select(date, sentiment = value)
}, error = function(e) {
  cat("Could not fetch UMCSENT from FRED\n")
  NULL
})

if (!is.null(umcsent)) {
  # Monthly averages of weekly gas prices
  gas_monthly <- gas_national %>%
    mutate(date = as.Date(date)) %>%
    mutate(month_date = floor_date(date, "month")) %>%
    group_by(month_date) %>%
    summarize(gas_price = mean(gas_price_national, na.rm = TRUE), .groups = "drop")

  context_data <- umcsent %>%
    mutate(month_date = floor_date(date, "month")) %>%
    left_join(gas_monthly, by = "month_date") %>%
    filter(!is.na(gas_price), !is.na(sentiment))

  fig8 <- ggplot(context_data, aes(x = month_date)) +
    geom_line(aes(y = sentiment, color = "Consumer Sentiment"), linewidth = 0.6) +
    geom_line(aes(y = gas_price * 30, color = "Gas Price ($/gal, right)"), linewidth = 0.6) +
    scale_y_continuous(
      name = "Michigan Consumer Sentiment Index",
      sec.axis = sec_axis(~./30, name = "Gas Price ($/gallon)")
    ) +
    scale_color_manual(values = c("Consumer Sentiment" = apep_colors[1],
                                   "Gas Price ($/gal, right)" = apep_colors[2])) +
    labs(
      x = "",
      title = "Gas Prices and Consumer Sentiment, 2005-2024",
      subtitle = "Aggregate time series: Michigan Consumer Sentiment vs. national gas price",
      caption = "Sources: FRED (UMCSENT, GASREGW). Note: correlation is descriptive, not causal.",
      color = ""
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig8_national_context.pdf"), fig8, width = 9, height = 5)
  ggsave(file.path(fig_dir, "fig8_national_context.png"), fig8, width = 9, height = 5, dpi = 300)
}

cat("\n=== ALL FIGURES GENERATED ===\n")
cat("Figures saved to:", fig_dir, "\n")
