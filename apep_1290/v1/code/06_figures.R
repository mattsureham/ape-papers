# 06_figures.R — Generate SCM gap plots and placebo figures
# APEP Working Paper apep_1290

source("00_packages.R")

results <- readRDS("../data/results.rds")
time_ids <- readRDS("../data/time_ids.rds")
params <- readRDS("../data/params.rds")

treat_start <- params$treat_start
gap_df <- results$gap_df
placebo_gaps <- results$placebo_gaps

# Event dates
event2_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2020 Q3")]
event3_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2024 Q3")]

# Convert time_ids to dates for plotting
gap_df <- gap_df %>%
  mutate(date = as.Date(yq))

# ---------------------------------------------------------------
# Figure 1: SCM Gap Plot (Tax/GDP) with placebo distribution
# ---------------------------------------------------------------

# Combine placebos
placebo_all <- bind_rows(placebo_gaps) %>%
  left_join(time_ids, by = "time_id") %>%
  mutate(date = as.Date(yq))

fig1 <- ggplot() +
  geom_line(data = placebo_all, aes(x = date, y = gap, group = geo),
            color = "grey75", alpha = 0.5, linewidth = 0.3) +
  geom_line(data = gap_df, aes(x = date, y = gap),
            color = "black", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = as.Date(zoo::as.yearqtr("2016 Q3")),
             linetype = "dashed", color = "red", linewidth = 0.7) +
  geom_vline(xintercept = as.Date(zoo::as.yearqtr("2020 Q3")),
             linetype = "dashed", color = "blue", linewidth = 0.7) +
  geom_vline(xintercept = as.Date(zoo::as.yearqtr("2024 Q3")),
             linetype = "dashed", color = "red", linewidth = 0.7) +
  annotate("text", x = as.Date("2016-10-01"), y = max(gap_df$gap, na.rm = TRUE) * 0.9,
           label = "Ruling", hjust = 0, size = 3, color = "red") +
  annotate("text", x = as.Date("2020-10-01"), y = max(gap_df$gap, na.rm = TRUE) * 0.9,
           label = "Annulment", hjust = 0, size = 3, color = "blue") +
  annotate("text", x = as.Date("2024-10-01"), y = max(gap_df$gap, na.rm = TRUE) * 0.9,
           label = "Reinstate", hjust = 0, size = 3, color = "red") +
  labs(x = NULL,
       y = "Gap: Ireland minus Synthetic Ireland (pp of GDP)",
       title = NULL) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    axis.text = element_text(size = 9),
    axis.title = element_text(size = 10)
  )

ggsave("../figures/fig1_scm_gap.pdf", fig1, width = 7, height = 4.5, device = cairo_pdf)
cat("Saved fig1_scm_gap.pdf\n")

# ---------------------------------------------------------------
# Figure 2: Ireland vs Synthetic Ireland (actual trajectories)
# ---------------------------------------------------------------

# Reconstruct synthetic Ireland path
dp <- results$dp
synth_out <- results$synth_out

actual_y <- as.numeric(dp$Y1plot)
synth_y <- as.numeric(dp$Y0plot %*% synth_out$solution.w)
time_plot <- as.numeric(rownames(dp$Y1plot))

traj_df <- data.frame(
  time_id = time_plot,
  actual = actual_y,
  synthetic = synth_y
) %>%
  left_join(time_ids, by = "time_id") %>%
  mutate(date = as.Date(yq)) %>%
  tidyr::pivot_longer(cols = c(actual, synthetic),
                      names_to = "series", values_to = "value")

fig2 <- ggplot(traj_df, aes(x = date, y = value, color = series, linetype = series)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date(zoo::as.yearqtr("2016 Q3")),
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = as.Date(zoo::as.yearqtr("2020 Q3")),
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = as.Date(zoo::as.yearqtr("2024 Q3")),
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  scale_color_manual(values = c("actual" = "black", "synthetic" = "red"),
                     labels = c("Ireland", "Synthetic Ireland")) +
  scale_linetype_manual(values = c("actual" = "solid", "synthetic" = "dashed"),
                        labels = c("Ireland", "Synthetic Ireland")) +
  labs(x = NULL,
       y = "Income Tax / GDP (%)",
       color = NULL, linetype = NULL) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = c(0.15, 0.85),
    legend.background = element_rect(fill = "white", color = NA),
    axis.text = element_text(size = 9),
    axis.title = element_text(size = 10)
  )

ggsave("../figures/fig2_scm_trajectory.pdf", fig2, width = 7, height = 4.5, device = cairo_pdf)
cat("Saved fig2_scm_trajectory.pdf\n")

# ---------------------------------------------------------------
# Figure 3: MSPE ratio distribution (permutation inference)
# ---------------------------------------------------------------

mspe_ratio_ireland <- results$mspe_ratio_ireland
placebo_ratios <- results$placebo_ratios

ratio_df <- data.frame(
  geo = c("Ireland", names(placebo_ratios)),
  ratio = c(mspe_ratio_ireland, as.numeric(placebo_ratios)),
  is_ireland = c(TRUE, rep(FALSE, length(placebo_ratios)))
)

fig3 <- ggplot(ratio_df, aes(x = reorder(geo, ratio), y = ratio, fill = is_ireland)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = c("TRUE" = "red", "FALSE" = "grey70"), guide = "none") +
  coord_flip() +
  labs(x = NULL, y = "Post/Pre MSPE Ratio") +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    axis.text = element_text(size = 8)
  )

ggsave("../figures/fig3_mspe_ratios.pdf", fig3, width = 6, height = 6, device = cairo_pdf)
cat("Saved fig3_mspe_ratios.pdf\n")

cat("=== All figures generated. ===\n")
