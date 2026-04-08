## 05_figures.R — Generate all figures
## apep_1407: The Insurance Denominator

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "fema_analysis.rds"))
models <- readRDS(file.path(data_dir, "model_objects.rds"))

## ---- APEP Theme ----
theme_apep <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "gray30"),
      legend.position = "bottom",
      axis.title = element_text(size = 10),
      plot.caption = element_text(size = 8, color = "gray50")
    )
}

## ============================================================
## Figure 1: Average Premium Over Time by Grandfathering Status
## ============================================================

prem_ts <- df |>
  group_by(yq_num, grandfathered) |>
  summarise(mean_prem = mean(premium, na.rm = TRUE),
            median_prem = median(premium, na.rm = TRUE),
            n = n(), .groups = "drop") |>
  mutate(group = ifelse(grandfathered == 1, "Grandfathered", "Non-Grandfathered"))

p1 <- ggplot(prem_ts, aes(x = yq_num, y = mean_prem, color = group, shape = group)) +
  geom_point(size = 2) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2021.75, linetype = "dashed", color = "gray40") +
  annotate("text", x = 2021.85, y = max(prem_ts$mean_prem, na.rm = TRUE) * 0.95,
           label = "RR2.0\n(Oct 2021)", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = c("Grandfathered" = "#E41A1C", "Non-Grandfathered" = "#377EB8")) +
  scale_y_continuous(labels = dollar_format()) +
  labs(title = "Average Annual Premium by Grandfathering Status",
       x = "Year-Quarter", y = "Mean Premium ($)",
       color = NULL, shape = NULL) +
  theme_apep()

ggsave(file.path(fig_dir, "fig1_premium_trends.pdf"), p1, width = 8, height = 5)
cat("Figure 1 saved.\n")

## ============================================================
## Figure 2: Event Study — Premium (First Stage)
## ============================================================

es_prem <- models$event_study$premium
es_prem_df <- broom::tidy(es_prem, conf.int = TRUE) |>
  filter(grepl("event_q_binned", term)) |>
  mutate(event_q = as.numeric(gsub(".*::([-0-9]+):.*", "\\1", term)))

p2 <- ggplot(es_prem_df, aes(x = event_q, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, fill = "#E41A1C") +
  geom_point(color = "#E41A1C", size = 2) +
  geom_line(color = "#E41A1C", linewidth = 0.6) +
  labs(title = "Event Study: Log Premium Differential (Grandfathered vs Non-Grandfathered)",
       subtitle = "Coefficients relative to q = -1 (2021Q3)",
       x = "Quarters Relative to RR2.0 Implementation",
       y = "Estimated Coefficient (log points)") +
  theme_apep()

ggsave(file.path(fig_dir, "fig2_event_study_premium.pdf"), p2, width = 8, height = 5)
cat("Figure 2 saved.\n")

## ============================================================
## Figure 3: Event Study — Lapse Rate
## ============================================================

es_lapse <- models$event_study$lapse
es_lapse_df <- broom::tidy(es_lapse, conf.int = TRUE) |>
  filter(grepl("event_q_binned", term)) |>
  mutate(event_q = as.numeric(gsub(".*::([-0-9]+):.*", "\\1", term)))

p3 <- ggplot(es_lapse_df, aes(x = event_q, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, fill = "#377EB8") +
  geom_point(color = "#377EB8", size = 2) +
  geom_line(color = "#377EB8", linewidth = 0.6) +
  labs(title = "Event Study: Policy Lapse Rate Differential",
       subtitle = "Grandfathered vs Non-Grandfathered, relative to q = -1",
       x = "Quarters Relative to RR2.0 Implementation",
       y = "Estimated Coefficient (percentage points)") +
  theme_apep()

ggsave(file.path(fig_dir, "fig3_event_study_lapse.pdf"), p3, width = 8, height = 5)
cat("Figure 3 saved.\n")

## ============================================================
## Figure 4: Premium Distribution Before/After RR2.0 by Group
## ============================================================

df_dens <- df |>
  filter(premium > 0, premium < 10000) |>
  mutate(
    period = ifelse(post_rr2 == 1, "Post-RR2.0", "Pre-RR2.0"),
    group = ifelse(grandfathered == 1, "Grandfathered", "Non-Grandfathered")
  )

p4 <- ggplot(df_dens, aes(x = premium, fill = period)) +
  geom_density(alpha = 0.4) +
  facet_wrap(~group) +
  scale_fill_manual(values = c("Pre-RR2.0" = "#377EB8", "Post-RR2.0" = "#E41A1C")) +
  scale_x_continuous(labels = dollar_format(), limits = c(0, 8000)) +
  labs(title = "Premium Distribution Before and After Risk Rating 2.0",
       x = "Annual Premium ($)", y = "Density", fill = NULL) +
  theme_apep()

ggsave(file.path(fig_dir, "fig4_premium_density.pdf"), p4, width = 9, height = 5)
cat("Figure 4 saved.\n")

## ============================================================
## Figure 5: Heterogeneity — Lapse Rate by Mandatory vs Voluntary
## ============================================================

het_ts <- df |>
  mutate(purchase_type = ifelse(mandatory == 1, "Mandatory Purchase", "Voluntary")) |>
  group_by(yq_num, grandfathered, purchase_type) |>
  summarise(lapse_rate = mean(lapsed, na.rm = TRUE), n = n(), .groups = "drop") |>
  mutate(group = ifelse(grandfathered == 1, "Grandfathered", "Non-Grandfathered"))

p5 <- ggplot(het_ts, aes(x = yq_num, y = lapse_rate, color = group, linetype = group)) +
  geom_point(size = 1.5) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = 2021.75, linetype = "dashed", color = "gray40") +
  facet_wrap(~purchase_type) +
  scale_color_manual(values = c("Grandfathered" = "#E41A1C", "Non-Grandfathered" = "#377EB8")) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Lapse Rates by Purchase Mandate and Grandfathering Status",
       x = "Year-Quarter", y = "Lapse Rate",
       color = NULL, linetype = NULL) +
  theme_apep()

ggsave(file.path(fig_dir, "fig5_heterogeneity_lapse.pdf"), p5, width = 9, height = 5)
cat("Figure 5 saved.\n")

## ============================================================
## Figure 6: Map of Grandfathered Policy Share by State
## ============================================================

state_shares <- df |>
  group_by(propertyState) |>
  summarise(
    n_total = n(),
    n_gf = sum(grandfathered),
    pct_gf = mean(grandfathered),
    .groups = "drop"
  )

p6 <- ggplot(state_shares, aes(x = reorder(propertyState, pct_gf), y = pct_gf)) +
  geom_col(fill = "#E41A1C", alpha = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", pct_gf * 100)), hjust = -0.1, size = 3) +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Share of Grandfathered Policies by State",
       x = NULL, y = "Percent Grandfathered") +
  theme_apep()

ggsave(file.path(fig_dir, "fig6_state_shares.pdf"), p6, width = 7, height = 5)
cat("Figure 6 saved.\n")

## ============================================================
## Figure 7: Dose-Response — Lapse Rate by Premium Change Quintile
## ============================================================

df_dose <- df |>
  filter(grandfathered == 1, post_rr2 == 1, !is.na(prem_change_pct)) |>
  mutate(dose_q = ntile(prem_change_pct, 5))

dose_plot <- df_dose |>
  group_by(dose_q) |>
  summarise(
    lapse_rate = mean(lapsed, na.rm = TRUE),
    mean_change = mean(prem_change_pct, na.rm = TRUE),
    n = n(),
    se = sqrt(lapse_rate * (1 - lapse_rate) / n),
    .groups = "drop"
  )

p7 <- ggplot(dose_plot, aes(x = dose_q, y = lapse_rate)) +
  geom_col(fill = "#377EB8", alpha = 0.7, width = 0.7) +
  geom_errorbar(aes(ymin = lapse_rate - 1.96 * se, ymax = lapse_rate + 1.96 * se),
                width = 0.2) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Lapse Rate by Premium Change Quintile (Grandfathered Policies)",
       subtitle = "Quintile 1 = smallest premium increase, Quintile 5 = largest",
       x = "Premium Change Quintile", y = "Post-RR2.0 Lapse Rate") +
  theme_apep()

ggsave(file.path(fig_dir, "fig7_dose_response.pdf"), p7, width = 7, height = 5)
cat("Figure 7 saved.\n")

cat("\n=== All 7 figures saved to figures/ ===\n")
