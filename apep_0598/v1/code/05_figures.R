# 05_figures.R — All figure generation
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# LOAD DATA
# ============================================================

turnover <- fread(file.path(data_dir, "retail_turnover.csv"))
scm_as <- fread(file.path(data_dir, "scm_actual_synthetic.csv"))
gaps_df <- fread(file.path(data_dir, "scm_gaps.csv"))
weights_df <- fread(file.path(data_dir, "scm_weights.csv"))
sector_panel <- fread(file.path(data_dir, "sector_panel.csv"))
sector_summary <- fread(file.path(data_dir, "sector_summary.csv"))
vat_panel <- fread(file.path(data_dir, "vat_panel.csv"))

# Treatment date
treatment_date <- as.Date("2015-07-01")

# ============================================================
# FIGURE 1: Greece vs Synthetic Greece (Main SCM Result)
# ============================================================

scm_as <- scm_as %>% mutate(date = as.Date(date))

fig1 <- ggplot(scm_as, aes(x = date)) +
  geom_line(aes(y = actual, color = "Greece"), linewidth = 0.9) +
  geom_line(aes(y = synthetic, color = "Synthetic Greece"),
            linewidth = 0.9, linetype = "dashed") +
  geom_vline(xintercept = treatment_date, linetype = "dotted",
             color = "grey30", linewidth = 0.5) +
  annotate("text", x = treatment_date + 60, y = max(scm_as$actual, na.rm = TRUE) * 0.98,
           label = "Capital controls\n(June 28, 2015)", hjust = 0, size = 3,
           color = "grey30") +
  scale_color_manual(values = c("Greece" = "#1b4f72",
                                "Synthetic Greece" = "#e74c3c"),
                     name = NULL) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    x = NULL,
    y = "Retail Trade Turnover Index (2015 = 100)",
    title = "Greece vs. Synthetic Greece: Retail Trade Turnover",
    subtitle = "Monthly, seasonally adjusted. Synthetic Greece constructed from 14 EU donor countries."
  ) +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig1_scm_main.pdf"), fig1,
       width = 8, height = 5.5, device = cairo_pdf)

cat("Figure 1 saved.\n")

# ============================================================
# FIGURE 2: SCM Gap (Treatment Effect Over Time)
# ============================================================

gaps_df <- gaps_df %>% mutate(date = as.Date(date))

fig2 <- ggplot(gaps_df, aes(x = date, y = gap)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
  geom_line(color = "#1b4f72", linewidth = 0.7) +
  geom_vline(xintercept = treatment_date, linetype = "dotted",
             color = "grey30", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2019-09-01"), linetype = "dotted",
             color = "grey30", linewidth = 0.5) +
  annotate("text", x = treatment_date + 60, y = min(gaps_df$gap, na.rm = TRUE) * 0.9,
           label = "Controls imposed", hjust = 0, size = 3, color = "grey30") +
  annotate("text", x = as.Date("2019-09-01") + 30,
           y = min(gaps_df$gap, na.rm = TRUE) * 0.7,
           label = "Controls fully\nremoved", hjust = 0, size = 3, color = "grey30") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    x = NULL,
    y = "Gap (Greece \u2212 Synthetic Greece)",
    title = "Treatment Effect: Gap Between Greece and Synthetic Greece",
    subtitle = "Negative values indicate Greece underperforming synthetic counterfactual."
  )

ggsave(file.path(fig_dir, "fig2_scm_gap.pdf"), fig2,
       width = 8, height = 5, device = cairo_pdf)

cat("Figure 2 saved.\n")

# ============================================================
# FIGURE 3: Placebo-in-Space (Permutation Tests)
# ============================================================

if (file.exists(file.path(data_dir, "placebo_gaps.csv"))) {
  placebo <- fread(file.path(data_dir, "placebo_gaps.csv"))
  placebo <- placebo %>%
    mutate(
      year = 2010 + (time_index - 1) %/% 12,
      month = ((time_index - 1) %% 12) + 1,
      date = as.Date(paste(year, month, "01", sep = "-"))
    )

  fig3 <- ggplot() +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    geom_line(data = placebo, aes(x = date, y = gap, group = country),
              color = "grey75", linewidth = 0.3, alpha = 0.7) +
    geom_line(data = gaps_df, aes(x = date, y = gap),
              color = "#1b4f72", linewidth = 0.9) +
    geom_vline(xintercept = treatment_date, linetype = "dotted",
               color = "grey30", linewidth = 0.5) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(
      x = NULL,
      y = "Gap (Actual \u2212 Synthetic)",
      title = "Placebo Tests: Greece (dark) vs. Donor Countries (grey)",
      subtitle = "Each grey line: SCM for a donor country treated as if it received capital controls."
    )

  ggsave(file.path(fig_dir, "fig3_placebo_space.pdf"), fig3,
         width = 8, height = 5, device = cairo_pdf)

  cat("Figure 3 saved.\n")
}

# ============================================================
# FIGURE 4: Sector-Level Heterogeneity (Cash Intensity)
# ============================================================

# Normalize each sector to June 2015 = 100
sector_norm <- sector_panel %>%
  mutate(date = as.Date(paste(year, month, "01", sep = "-"))) %>%
  group_by(nace) %>%
  mutate(
    base_val = value[date == as.Date("2015-06-01")][1],
    norm_value = value / base_val * 100
  ) %>%
  ungroup() %>%
  filter(date >= as.Date("2014-01-01"), date <= as.Date("2017-12-01"))

sector_colors <- c("G471" = "#27ae60", "G472" = "#f39c12", "G473" = "#e74c3c")
sector_labels_map <- c(
  "G471" = "Non-specialized (55% cash)",
  "G472" = "Food/beverages (75% cash)",
  "G473" = "Automotive fuel (90% cash)"
)

fig4 <- ggplot(sector_norm, aes(x = date, y = norm_value, color = nace)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = treatment_date, linetype = "dotted",
             color = "grey30", linewidth = 0.5) +
  scale_color_manual(values = sector_colors, labels = sector_labels_map,
                     name = "Sector (cash intensity)") +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(
    x = NULL,
    y = "Turnover Index (June 2015 = 100)",
    title = "Retail Turnover by Sector Cash Intensity",
    subtitle = "Sectors with higher pre-2015 cash dependence suffered larger drops."
  ) +
  theme(legend.position = c(0.25, 0.2))

ggsave(file.path(fig_dir, "fig4_sector_heterogeneity.pdf"), fig4,
       width = 8, height = 5.5, device = cairo_pdf)

cat("Figure 4 saved.\n")

# ============================================================
# FIGURE 5: Leave-One-Out Robustness
# ============================================================

if (file.exists(file.path(data_dir, "loo_results.csv"))) {
  loo <- fread(file.path(data_dir, "loo_results.csv"))
  loo <- loo %>%
    mutate(
      year = 2010 + (time_index - 1) %/% 12,
      month = ((time_index - 1) %% 12) + 1,
      date = as.Date(paste(year, month, "01", sep = "-"))
    )

  fig5 <- ggplot() +
    geom_line(data = loo, aes(x = date, y = synthetic, group = dropped),
              color = "grey70", linewidth = 0.3, alpha = 0.7) +
    geom_line(data = scm_as, aes(x = date, y = synthetic),
              color = "#e74c3c", linewidth = 0.8, linetype = "dashed") +
    geom_line(data = scm_as, aes(x = date, y = actual),
              color = "#1b4f72", linewidth = 0.8) +
    geom_vline(xintercept = treatment_date, linetype = "dotted",
               color = "grey30", linewidth = 0.5) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(
      x = NULL,
      y = "Retail Trade Turnover Index",
      title = "Leave-One-Out Robustness",
      subtitle = "Grey lines: synthetic Greece dropping each donor. Red dashed: baseline synthetic. Blue: actual Greece."
    )

  ggsave(file.path(fig_dir, "fig5_loo.pdf"), fig5,
         width = 8, height = 5, device = cairo_pdf)

  cat("Figure 5 saved.\n")
}

# ============================================================
# FIGURE 6: VAT Revenue (Greece vs Donors)
# ============================================================

vat_norm <- vat_panel %>%
  filter(!is.na(vat_index)) %>%
  mutate(
    group = ifelse(country == "EL", "Greece", "Donor average")
  )

vat_donor_avg <- vat_norm %>%
  filter(group == "Donor average") %>%
  group_by(year) %>%
  summarise(vat_index = mean(vat_index, na.rm = TRUE), .groups = "drop") %>%
  mutate(group = "Donor average")

vat_greece <- vat_norm %>%
  filter(group == "Greece") %>%
  select(year, vat_index, group)

vat_plot <- bind_rows(vat_greece, vat_donor_avg)

fig6 <- ggplot(vat_plot, aes(x = year, y = vat_index, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2015, linetype = "dotted", color = "grey30") +
  scale_color_manual(values = c("Greece" = "#1b4f72", "Donor average" = "#e74c3c"),
                     name = NULL) +
  labs(
    x = NULL,
    y = "VAT Revenue Index (2014 = 100)",
    title = "VAT Revenue Trajectory: Greece vs. Donor Average",
    subtitle = "Normalized to 2014. Faster Greek recovery consistent with formalization mechanism."
  ) +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig6_vat_mechanism.pdf"), fig6,
       width = 7, height = 5, device = cairo_pdf)

cat("Figure 6 saved.\n")

# ============================================================
# FIGURE 7: RMSPE Ratio Distribution
# ============================================================

if (file.exists(file.path(data_dir, "rmspe_ratios.csv"))) {
  rmspe <- fread(file.path(data_dir, "rmspe_ratios.csv"))

  rmspe <- rmspe %>%
    mutate(is_greece = country == "EL") %>%
    arrange(desc(rmspe_ratio)) %>%
    mutate(rank = row_number())

  fig7 <- ggplot(rmspe, aes(x = reorder(country, -rmspe_ratio), y = rmspe_ratio,
                            fill = is_greece)) +
    geom_col(width = 0.7) +
    scale_fill_manual(values = c("TRUE" = "#1b4f72", "FALSE" = "grey70"),
                      guide = "none") +
    labs(
      x = "Country",
      y = "Post/Pre RMSPE Ratio",
      title = "Placebo Inference: RMSPE Ratios",
      subtitle = "Greece (dark) vs. all placebo countries. Higher ratio = larger effect relative to pre-treatment fit."
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(file.path(fig_dir, "fig7_rmspe_ratios.pdf"), fig7,
         width = 7, height = 5, device = cairo_pdf)

  cat("Figure 7 saved.\n")
}

cat("\n=== ALL FIGURES SAVED ===\n")
