## ============================================================
## 05_figures.R — All figure generation
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

source("00_packages.R")

## --- Load Cleaned Data ---
tier_panel   <- fread(file.path(DATA_DIR, "tier_panel_clean.csv"))
cc_all       <- fread(file.path(DATA_DIR, "cross_country_clean.csv"))
monthly      <- fread(file.path(DATA_DIR, "monthly_clean.csv"))
es_tier      <- fread(file.path(DATA_DIR, "event_study_tier.csv"))
es_cc        <- fread(file.path(DATA_DIR, "event_study_cc.csv"))
symmetry     <- fread(file.path(DATA_DIR, "symmetry_test.csv"))

## ============================================================
## FIGURE 1: Treatment Timing — Lending Rate Event Study
## ============================================================

fig1 <- monthly |>
  mutate(date = as.Date(date)) |>
  ggplot(aes(x = date)) +
  # Shaded regions
  annotate("rect",
           xmin = as.Date("2016-09-01"), xmax = as.Date("2019-11-01"),
           ymin = -Inf, ymax = Inf,
           fill = apep_colors["cap_on"], alpha = 0.1) +
  annotate("rect",
           xmin = as.Date("2020-03-01"), xmax = as.Date("2023-12-01"),
           ymin = -Inf, ymax = Inf,
           fill = "grey70", alpha = 0.15) +
  # Cap rate
  geom_line(aes(y = cap_rate), color = apep_colors["cap_on"],
            linetype = "dashed", linewidth = 0.7) +
  # CBR
  geom_line(aes(y = cbr), color = "grey50", linewidth = 0.6) +
  # Vertical lines
  geom_vline(xintercept = as.Date("2016-09-01"),
             color = apep_colors["cap_on"], linetype = "dashed") +
  geom_vline(xintercept = as.Date("2019-11-01"),
             color = apep_colors["cap_off"], linetype = "dashed") +
  # Labels
  annotate("text", x = as.Date("2018-03-01"), y = 16.5,
           label = "Cap Period\n(CBR + 4%)", color = apep_colors["cap_on"],
           size = 3.5, fontface = "bold") +
  annotate("text", x = as.Date("2021-06-01"), y = 16.5,
           label = "COVID", color = "grey50",
           size = 3, fontface = "italic") +
  annotate("text", x = as.Date("2016-09-01"), y = 6.5,
           label = "Cap\nIntroduced", hjust = 1.1, size = 2.8) +
  annotate("text", x = as.Date("2019-11-01"), y = 6.5,
           label = "Cap\nRepealed", hjust = -0.1, size = 2.8) +
  labs(
    x = NULL,
    y = "Interest Rate (%)",
    title = "Kenya's Interest Rate Cap: Policy Timeline",
    subtitle = "Central Bank Rate (solid) and implied cap rate CBR+4% (dashed), 2014-2023"
  ) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y",
               limits = c(as.Date("2014-01-01"), as.Date("2023-12-01")),
               expand = expansion(mult = c(0.02, 0.02))) +
  coord_cartesian(ylim = c(5, 18))

ggsave(file.path(FIG_DIR, "fig1_treatment_timing.pdf"),
       fig1, width = 8, height = 5)
cat("Saved: fig1_treatment_timing.pdf\n")

## ============================================================
## FIGURE 3: Portfolio Trends — Multi-Panel (A, B, C)
##   Panel A: Loan/Asset Ratio by Tier
##   Panel B: Government Securities / Total Assets by Tier
##   Panel C: NPL Ratio by Tier
## ============================================================

## --- Shared panel elements ---
tier_color_scale <- scale_color_manual(
  values = c("Tier1" = unname(apep_colors["tier1"]),
             "Tier2" = unname(apep_colors["tier2"]),
             "Tier3" = unname(apep_colors["tier3"])),
  labels = c("Tier 1 (Large)", "Tier 2 (Medium)", "Tier 3 (Small)")
)

cap_shading <- annotate("rect",
                         xmin = 2016.7, xmax = 2019.85,
                         ymin = -Inf, ymax = Inf,
                         fill = apep_colors["cap_on"], alpha = 0.08)

cap_vlines <- list(
  geom_vline(xintercept = 2016.7, linetype = "dashed", color = "grey50"),
  geom_vline(xintercept = 2019.85, linetype = "dashed", color = "grey50")
)

panel_x_scale <- scale_x_continuous(breaks = seq(2010, 2023, 2))

panel_theme <- theme(
  axis.text.x   = element_text(angle = 45, hjust = 1, size = 8),
  plot.title     = element_text(size = 11, face = "bold"),
  plot.subtitle  = element_blank(),
  legend.position = "none",
  axis.title     = element_text(size = 9)
)

## Panel A: Loan/Asset Ratio
panel_a <- tier_panel |>
  ggplot(aes(x = year, y = loan_asset_ratio, color = tier)) +
  cap_shading +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  cap_vlines +
  tier_color_scale +
  panel_x_scale +
  labs(
    x = NULL,
    y = "Loans / Total Assets",
    title = "A: Credit Allocation"
  ) +
  panel_theme

## Panel B: Government Securities
panel_b <- tier_panel |>
  ggplot(aes(x = year, y = govt_sec_ratio, color = tier)) +
  cap_shading +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  cap_vlines +
  tier_color_scale +
  panel_x_scale +
  labs(
    x = NULL,
    y = "Govt Securities / Total Assets",
    title = "B: Portfolio Substitution"
  ) +
  panel_theme

## Panel C: NPL Ratio
panel_c <- tier_panel |>
  ggplot(aes(x = year, y = npl_ratio, color = tier)) +
  cap_shading +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  cap_vlines +
  tier_color_scale +
  panel_x_scale +
  labs(
    x = NULL,
    y = "NPL Ratio (%)",
    title = "C: Credit Quality"
  ) +
  panel_theme

## --- Extract shared legend ---
legend_plot <- tier_panel |>
  ggplot(aes(x = year, y = loan_asset_ratio, color = tier)) +
  geom_line() +
  scale_color_manual(
    values = c("Tier1" = unname(apep_colors["tier1"]),
               "Tier2" = unname(apep_colors["tier2"]),
               "Tier3" = unname(apep_colors["tier3"])),
    labels = c("Tier 1 (Large, n=6)", "Tier 2 (Medium, n=15)", "Tier 3 (Small, n=21)")
  ) +
  labs(color = NULL) +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 9))

shared_legend <- cowplot::get_legend(legend_plot)

## --- Combine with patchwork ---
fig3_combined <- (panel_a | panel_b | panel_c) +
  plot_annotation(
    title    = "Portfolio Trends by Bank Tier",
    subtitle = "Shaded region indicates cap period (Sep 2016 -- Nov 2019)",
    theme = theme(
      plot.title    = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40", size = 10)
    )
  )

## Stack the panels + shared legend using cowplot
fig3_final <- cowplot::plot_grid(
  fig3_combined,
  shared_legend,
  ncol = 1,
  rel_heights = c(1, 0.06)
)

ggsave(file.path(FIG_DIR, "fig3_portfolio_trends.pdf"),
       fig3_final, width = 12, height = 5)
cat("Saved: fig3_portfolio_trends.pdf\n")

## ============================================================
## FIGURE 4: Event Study — Tier 3 vs Tier 1 Differential
## (previously Figure 5)
## ============================================================

# Event study for loan/asset ratio
es_loan <- es_tier |> filter(outcome == "Loan/Asset Ratio")

# Add the omitted reference point
es_loan_plot <- bind_rows(
  es_loan,
  tibble(outcome = "Loan/Asset Ratio", event_time = -1,
         estimate = 0, se = 0, ci_lower = 0, ci_upper = 0, p_value = NA)
) |> arrange(event_time)

fig4 <- es_loan_plot |>
  ggplot(aes(x = event_time, y = estimate)) +
  annotate("rect",
           xmin = 0.5, xmax = 3.5,
           ymin = -Inf, ymax = Inf,
           fill = apep_colors["cap_on"], alpha = 0.08) +
  annotate("rect",
           xmin = 3.5, xmax = max(es_loan_plot$event_time) + 0.5,
           ymin = -Inf, ymax = Inf,
           fill = apep_colors["cap_off"], alpha = 0.05) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = "steelblue", alpha = 0.2) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "steelblue", size = 3) +
  annotate("text", x = 2, y = max(es_loan_plot$ci_upper, na.rm = TRUE) * 0.8,
           label = "Cap On", color = apep_colors["cap_on"],
           size = 3.5, fontface = "bold") +
  annotate("text", x = 5.5, y = max(es_loan_plot$ci_upper, na.rm = TRUE) * 0.8,
           label = "Post-Repeal", color = apep_colors["cap_off"],
           size = 3.5, fontface = "bold") +
  labs(
    x = "Years Relative to Cap Introduction (2016)",
    y = "Tier 3 vs Tier 1 Differential\n(Loan/Asset Ratio)",
    title = "Event Study: Differential Credit Allocation",
    subtitle = "Tier 3 banks reduced lending relative to Tier 1 during cap; no recovery after repeal"
  )

ggsave(file.path(FIG_DIR, "fig4_event_study.pdf"),
       fig4, width = 8, height = 5.5)
cat("Saved: fig4_event_study.pdf\n")

## ============================================================
## FIGURE 5: Cross-Country Credit/GDP
## (previously Figure 6)
## ============================================================

fig5 <- cc_all |>
  filter(!is.na(credit_gdp)) |>
  ggplot(aes(x = year, y = credit_gdp, color = country_name)) +
  annotate("rect",
           xmin = 2016.7, xmax = 2019.85,
           ymin = -Inf, ymax = Inf,
           fill = apep_colors["cap_on"], alpha = 0.08) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2016.7, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 2019.85, linetype = "dashed", color = "grey50") +
  scale_color_manual(values = c("Kenya" = unname(apep_colors["kenya"]),
                                "Uganda" = unname(apep_colors["uganda"]),
                                "Tanzania" = unname(apep_colors["tanzania"]),
                                "Rwanda" = unname(apep_colors["rwanda"]))) +
  scale_x_continuous(breaks = seq(2010, 2023, 2)) +
  labs(
    x = NULL,
    y = "Domestic Credit to Private Sector (% GDP)",
    color = "Country",
    title = "Kenya's Credit Contraction in Regional Context",
    subtitle = "Kenya's credit/GDP diverged from East African peers during the cap period"
  )

ggsave(file.path(FIG_DIR, "fig5_cross_country_credit.pdf"),
       fig5, width = 8, height = 5.5)
cat("Saved: fig5_cross_country_credit.pdf\n")

## ============================================================
## FIGURE 6: Cross-Country Event Study
## (previously Figure 8)
## ============================================================

es_cc_credit <- es_cc |> filter(outcome == "Credit/GDP (Cross-Country)")

es_cc_plot <- bind_rows(
  es_cc_credit,
  tibble(outcome = "Credit/GDP (Cross-Country)", event_time = -1,
         estimate = 0, se = 0, ci_lower = 0, ci_upper = 0, p_value = NA)
) |> arrange(event_time)

fig6 <- es_cc_plot |>
  ggplot(aes(x = event_time, y = estimate)) +
  annotate("rect",
           xmin = -0.5, xmax = 2.5,
           ymin = -Inf, ymax = Inf,
           fill = apep_colors["cap_on"], alpha = 0.08) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = "darkred", alpha = 0.2) +
  geom_line(color = "darkred", linewidth = 0.8) +
  geom_point(color = "darkred", size = 3) +
  labs(
    x = "Years Relative to Cap (2017 = first full year)",
    y = "Kenya vs East Africa Differential\n(Credit/GDP, pp)",
    title = "Cross-Country Event Study: Kenya vs East African Peers",
    subtitle = "Kenya's credit/GDP declined relative to Uganda, Tanzania, and Rwanda"
  )

ggsave(file.path(FIG_DIR, "fig6_cc_event_study.pdf"),
       fig6, width = 8, height = 5.5)
cat("Saved: fig6_cc_event_study.pdf\n")

## ============================================================
## APPENDIX FIGURE A1: Symmetry / Hysteresis Visualization
## (previously Figure 7, moved to appendix)
## ============================================================

# Create the hysteresis visualization
sym_data <- tier_panel |>
  filter(tier %in% c("Tier1", "Tier3")) |>
  select(year, tier, loan_asset_ratio) |>
  pivot_wider(names_from = tier, values_from = loan_asset_ratio) |>
  mutate(
    gap = Tier3 - Tier1,
    period = case_when(
      year < 2017 ~ "Pre-cap",
      year <= 2019 ~ "Cap-on",
      TRUE ~ "Post-repeal"
    )
  )

figA1 <- sym_data |>
  ggplot(aes(x = year, y = gap, fill = period)) +
  geom_col(alpha = 0.7, width = 0.8) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_vline(xintercept = 2016.5, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 2019.5, linetype = "dashed", color = "grey50") +
  scale_fill_manual(values = c("Pre-cap" = unname(apep_colors["pre_cap"]),
                               "Cap-on" = unname(apep_colors["cap_on"]),
                               "Post-repeal" = unname(apep_colors["cap_off"]))) +
  scale_x_continuous(breaks = 2010:2023) +
  labs(
    x = NULL,
    y = "Tier 3 - Tier 1 Gap\n(Loan/Asset Ratio)",
    fill = "Period",
    title = "Credit Rationing Hysteresis",
    subtitle = "The Tier 3-Tier 1 lending gap widened during cap and did not fully close after repeal"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(FIG_DIR, "figA1_hysteresis.pdf"),
       figA1, width = 9, height = 5.5)
cat("Saved: figA1_hysteresis.pdf\n")

cat("\n=== All figures generated ===\n")
