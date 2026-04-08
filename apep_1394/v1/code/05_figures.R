## 05_figures.R — Generate all figures (≥5 required)
## apep_1394: PFL × Healthcare Workforce Retention

source("00_packages.R")

cat("=== GENERATING FIGURES ===\n")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/main_results.rds")
pfl_states <- readRDS("../data/pfl_states.rds")

fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Figure 1: Raw turnover trends by sex (healthcare)
# -----------------------------------------------------------------------

fig1_data <- panel |>
  filter(!is.na(turnover)) |>
  group_by(date_q, sex_label) |>
  summarise(mean_turnover = mean(turnover, na.rm = TRUE), .groups = "drop")

p1 <- ggplot(fig1_data, aes(x = date_q, y = mean_turnover, color = sex_label)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = pfl_states$pfl_date, linetype = "dashed", alpha = 0.3) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Quarterly Healthcare Turnover by Sex",
    subtitle = "All states, NAICS 62. Dashed lines = PFL adoption dates.",
    x = NULL, y = "Turnover Rate", color = "Sex"
  )
ggsave(file.path(fig_dir, "fig1_turnover_trends.pdf"), p1, width = 10, height = 6)
cat("Figure 1 saved\n")

# -----------------------------------------------------------------------
# Figure 2: Turnover gender gap over time (PFL vs non-PFL states)
# -----------------------------------------------------------------------

gap_by_group <- panel |>
  filter(!is.na(turnover)) |>
  group_by(date_q, pfl_state, sex_label) |>
  summarise(mean_turnover = mean(turnover, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = sex_label, values_from = mean_turnover) |>
  mutate(
    gap = Female - Male,
    group = ifelse(pfl_state, "PFL States", "Non-PFL States")
  )

p2 <- ggplot(gap_by_group, aes(x = date_q, y = gap, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_smooth(method = "loess", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  geom_hline(yintercept = 0, linetype = "dotted") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Female-Male Turnover Gap: PFL vs. Non-PFL States",
    subtitle = "Healthcare sector (NAICS 62). Gap = female turnover − male turnover.",
    x = NULL, y = "Turnover Gap (F − M)", color = NULL
  )
ggsave(file.path(fig_dir, "fig2_turnover_gap.pdf"), p2, width = 10, height = 6)
cat("Figure 2 saved\n")

# -----------------------------------------------------------------------
# Figure 3: CS Event Study
# -----------------------------------------------------------------------

cs_out <- results$cs_out

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 12)

  es_data <- data.frame(
    event_time = cs_agg$egt,
    att = cs_agg$att.egt,
    se = cs_agg$se.egt
  ) |>
    mutate(
      ci_lo = att - 1.96 * se,
      ci_hi = att + 1.96 * se
    )

  p3 <- ggplot(es_data, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "steelblue") +
    geom_point(size = 2, color = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.6) +
    labs(
      title = "Event Study: PFL Effect on Female-Male Turnover Gap",
      subtitle = "Callaway-Sant'Anna (2021). Unit = quarters relative to PFL adoption.",
      x = "Quarters Relative to PFL Adoption", y = "ATT (Turnover Gap)"
    )
  ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 10, height = 6)
  cat("Figure 3 saved\n")
} else {
  cat("Figure 3 skipped (CS estimation failed)\n")
  # Create a simple pre-post comparison instead
  prepost <- panel |>
    filter(!is.na(turnover), pfl_state) |>
    mutate(period = ifelse(post_pfl == 1, "Post-PFL", "Pre-PFL")) |>
    group_by(period, sex_label) |>
    summarise(mean_t = mean(turnover, na.rm = TRUE),
              se_t = sd(turnover, na.rm = TRUE) / sqrt(n()),
              .groups = "drop")

  p3 <- ggplot(prepost, aes(x = period, y = mean_t, fill = sex_label)) +
    geom_col(position = position_dodge(width = 0.7), width = 0.6) +
    geom_errorbar(aes(ymin = mean_t - 1.96*se_t, ymax = mean_t + 1.96*se_t),
                  position = position_dodge(width = 0.7), width = 0.2) +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(title = "Pre vs. Post PFL Turnover by Sex",
         subtitle = "PFL-adopting states, healthcare sector",
         x = NULL, y = "Mean Turnover Rate", fill = "Sex")
  ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 8, height = 6)
  cat("Figure 3 (fallback) saved\n")
}

# -----------------------------------------------------------------------
# Figure 4: State-level treatment effects (coefficient plot)
# -----------------------------------------------------------------------

# Run state-by-state DDD
state_coefs <- map_dfr(unique(panel$state_fips[panel$pfl_state]), function(s) {
  d <- panel |> filter(state_fips == s | !pfl_state, !is.na(turnover))
  m <- tryCatch(
    feols(turnover ~ treated_ddd | state_fips^female + time_id^female,
          data = d, cluster = ~state_fips),
    error = function(e) NULL
  )
  if (is.null(m)) return(NULL)
  abbr <- pfl_states$state_abbr[pfl_states$state_fips == s]
  yr <- pfl_states$pfl_year[pfl_states$state_fips == s]
  tibble(
    state = paste0(abbr, " (", yr, ")"),
    coef = coef(m)["treated_ddd"],
    se = se(m)["treated_ddd"]
  )
})

if (nrow(state_coefs) > 0) {
  state_coefs <- state_coefs |>
    mutate(
      ci_lo = coef - 1.96 * se,
      ci_hi = coef + 1.96 * se,
      state = fct_reorder(state, coef)
    )

  p4 <- ggplot(state_coefs, aes(x = coef, y = state)) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_point(size = 3, color = "steelblue") +
    geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2, color = "steelblue") +
    labs(
      title = "State-Level DDD Estimates: PFL Effect on Turnover Gap",
      subtitle = "Each state estimated separately against never-treated controls",
      x = "DDD Coefficient (Turnover)", y = NULL
    )
  ggsave(file.path(fig_dir, "fig4_state_coefs.pdf"), p4, width = 9, height = 6)
  cat("Figure 4 saved\n")
}

# -----------------------------------------------------------------------
# Figure 5: Placebo — Finance sector turnover gap
# -----------------------------------------------------------------------

panel_finance <- readRDS("../data/panel_finance.rds") |>
  mutate(
    turnover = as.numeric(TurnOvrS),
    sex_label = ifelse(female == 1, "Female", "Male")
  )

fin_gap <- panel_finance |>
  filter(!is.na(turnover)) |>
  group_by(date_q, pfl_state, sex_label) |>
  summarise(mean_turnover = mean(turnover, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = sex_label, values_from = mean_turnover) |>
  mutate(
    gap = Female - Male,
    group = ifelse(pfl_state, "PFL States", "Non-PFL States")
  )

p5 <- ggplot(fin_gap, aes(x = date_q, y = gap, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_smooth(method = "loess", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  geom_hline(yintercept = 0, linetype = "dotted") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title = "Placebo: Female-Male Turnover Gap in Finance (NAICS 52)",
    subtitle = "No PFL effect expected in finance sector",
    x = NULL, y = "Turnover Gap (F − M)", color = NULL
  )
ggsave(file.path(fig_dir, "fig5_finance_placebo.pdf"), p5, width = 10, height = 6)
cat("Figure 5 saved\n")

# -----------------------------------------------------------------------
# Figure 6: Distribution of turnover by sex and PFL status
# -----------------------------------------------------------------------

p6 <- panel |>
  filter(!is.na(turnover)) |>
  mutate(group = interaction(sex_label, ifelse(pfl_state, "PFL State", "Non-PFL"))) |>
  ggplot(aes(x = turnover, fill = sex_label)) +
  geom_density(alpha = 0.4) +
  facet_wrap(~ifelse(pfl_state, "PFL States", "Non-PFL States")) +
  scale_x_continuous(labels = scales::percent_format()) +
  labs(
    title = "Distribution of Quarterly Turnover by Sex and PFL Status",
    subtitle = "Healthcare sector (NAICS 62), all quarters",
    x = "Turnover Rate", y = "Density", fill = "Sex"
  )
ggsave(file.path(fig_dir, "fig6_turnover_density.pdf"), p6, width = 10, height = 5)
cat("Figure 6 saved\n")

# -----------------------------------------------------------------------
# Figure 7: Map of PFL adoption timing
# -----------------------------------------------------------------------

# Simple bar chart of adoption timing (map requires additional packages)
adopt_data <- pfl_states |>
  mutate(state = fct_reorder(state_abbr, pfl_year))

p7 <- ggplot(adopt_data, aes(x = state, y = pfl_year)) +
  geom_col(fill = "steelblue", width = 0.6) +
  geom_text(aes(label = pfl_year), vjust = -0.5, size = 3.5) +
  coord_cartesian(ylim = c(2000, 2026)) +
  labs(
    title = "Staggered Adoption of Paid Family Leave",
    subtitle = "Year of first PFL benefits by state",
    x = NULL, y = "Year of Adoption"
  )
ggsave(file.path(fig_dir, "fig7_adoption_timeline.pdf"), p7, width = 9, height = 5)
cat("Figure 7 saved\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
