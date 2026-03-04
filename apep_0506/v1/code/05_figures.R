## =============================================================================
## 05_figures.R — All figures for the paper
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

## =============================================================================
## Load data
## =============================================================================

rdd <- fread(file.path(data_dir, "rdd_analysis.csv"))
rdd[, winner_log_assets := ifelse(rich_won == 1, log_rich_assets, log_poor_assets)]
rdd[, reserved := as.integer(ac_type != "GEN" & ac_type != "")]

cat("Loaded:", nrow(rdd), "constituency-elections\n")

## =============================================================================
## Figure 1: McCrary Density Test
## =============================================================================

cat("Creating Figure 1: McCrary Density Test\n")

density_test <- rddensity(rdd$rich_margin, c = 0)
p_mccrary <- rdplotdensity(density_test, rdd$rich_margin,
                           plotRange = c(-30, 30),
                           title = "",
                           xlabel = "Vote Margin of Wealthier Candidate (%)",
                           ylabel = "Density")

## Save manually since rdplotdensity returns a ggplot object
ggsave(file.path(fig_dir, "fig1_mccrary.pdf"), p_mccrary$Estplot,
       width = 7, height = 5)
ggsave(file.path(fig_dir, "fig1_mccrary.png"), p_mccrary$Estplot,
       width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 2: RDD Plot — Winner's Log Assets
## =============================================================================

cat("Creating Figure 2: RDD Plot — Winner's Log Assets\n")

## Create binned scatter plot
rdd[, margin_bin := cut(rich_margin, breaks = seq(-50, 50, by = 2),
                         labels = seq(-49, 49, by = 2))]
rdd[, margin_bin_num := as.numeric(as.character(margin_bin))]

bin_means <- rdd[!is.na(margin_bin_num),
                 .(mean_assets = mean(winner_log_assets, na.rm = TRUE),
                   se_assets = sd(winner_log_assets, na.rm = TRUE) / sqrt(.N),
                   n = .N),
                 by = margin_bin_num][order(margin_bin_num)]

## Fit local polynomials on each side
rdd_left  <- rdd[rich_margin < 0 & rich_margin > -30]
rdd_right <- rdd[rich_margin >= 0 & rich_margin < 30]

p2 <- ggplot() +
  ## Binned means with confidence intervals
  geom_point(data = bin_means[abs(margin_bin_num) <= 30],
             aes(x = margin_bin_num, y = mean_assets),
             color = "gray30", size = 1.5) +
  ## Local polynomial fit (left of cutoff)
  geom_smooth(data = rdd_left,
              aes(x = rich_margin, y = winner_log_assets),
              method = "loess", span = 0.5, se = TRUE,
              color = "#E41A1C", fill = "#E41A1C", alpha = 0.2) +
  ## Local polynomial fit (right of cutoff)
  geom_smooth(data = rdd_right,
              aes(x = rich_margin, y = winner_log_assets),
              method = "loess", span = 0.5, se = TRUE,
              color = "#377EB8", fill = "#377EB8", alpha = 0.2) +
  ## Vertical line at cutoff
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  ## Labels
  labs(x = "Vote Margin of Wealthier Candidate (%)",
       y = "Winner's Log Total Assets (Rs)",
       title = "") +
  scale_x_continuous(limits = c(-30, 30), breaks = seq(-30, 30, 10)) +
  annotate("text", x = -15, y = max(bin_means$mean_assets, na.rm = TRUE) - 0.3,
           label = "Poorer candidate\nwon", color = "#E41A1C", size = 3.5) +
  annotate("text", x = 15, y = max(bin_means$mean_assets, na.rm = TRUE) - 0.3,
           label = "Wealthier candidate\nwon", color = "#377EB8", size = 3.5)

ggsave(file.path(fig_dir, "fig2_rdd_assets.pdf"), p2, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig2_rdd_assets.png"), p2, width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 3: Histogram of Running Variable
## =============================================================================

cat("Creating Figure 3: Distribution of Running Variable\n")

p3 <- ggplot(rdd, aes(x = rich_margin)) +
  geom_histogram(aes(fill = factor(rich_won)),
                 binwidth = 2, boundary = 0, color = "white", alpha = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.8) +
  scale_fill_manual(values = c("#E41A1C", "#377EB8"),
                    labels = c("Poorer candidate won", "Wealthier candidate won"),
                    name = "") +
  labs(x = "Vote Margin of Wealthier Candidate (%)",
       y = "Number of Constituency-Elections",
       title = "") +
  scale_x_continuous(limits = c(-50, 50), breaks = seq(-50, 50, 10)) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig3_histogram.pdf"), p3, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig3_histogram.png"), p3, width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 4: Wealth Distribution of Candidates
## =============================================================================

cat("Creating Figure 4: Wealth Distribution\n")

wealth_long <- rbind(
  data.table(type = "Wealthier Candidate", log_assets = rdd$log_rich_assets),
  data.table(type = "Poorer Candidate", log_assets = rdd$log_poor_assets)
)

p4 <- ggplot(wealth_long, aes(x = log_assets, fill = type)) +
  geom_density(alpha = 0.5, color = NA) +
  scale_fill_manual(values = c("#377EB8", "#E41A1C"), name = "") +
  labs(x = "Log Total Assets (Rs)",
       y = "Density",
       title = "") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig4_wealth_dist.pdf"), p4, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig4_wealth_dist.png"), p4, width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 5: Covariate Balance Plots
## =============================================================================

cat("Creating Figure 5: Covariate Balance\n")

balance <- fread(file.path(data_dir, "balance_tests.csv"))

p5 <- ggplot(balance, aes(x = reorder(variable, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                width = 0.2) +
  coord_flip() +
  labs(x = "", y = "RDD Estimate (Robust)",
       title = "") +
  theme(axis.text.y = element_text(size = 10))

ggsave(file.path(fig_dir, "fig5_balance.pdf"), p5, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig5_balance.png"), p5, width = 7, height = 4.5, dpi = 300)

## =============================================================================
## Figure 6: Bandwidth Sensitivity
## =============================================================================

cat("Creating Figure 6: Bandwidth Sensitivity\n")

bw_data <- fread(file.path(data_dir, "bandwidth_sensitivity.csv"))

p6 <- ggplot(bw_data, aes(x = bandwidth, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_point(size = 3, color = "#377EB8") +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                width = 0.5, color = "#377EB8") +
  geom_text(aes(label = paste0("N=", n)), vjust = -1.5, size = 2.8, color = "gray40") +
  labs(x = "Bandwidth (Percentage Points)",
       y = "RDD Estimate: Winner's Log Assets",
       title = "") +
  scale_x_continuous(breaks = bw_data$bandwidth,
                     labels = as.integer(bw_data$bandwidth))

ggsave(file.path(fig_dir, "fig6_bandwidth.pdf"), p6, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig6_bandwidth.png"), p6, width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 7: Wealth Premium by Margin Proximity
## =============================================================================

cat("Creating Figure 7: Wealth Premium\n")

bins <- c(1, 2, 3, 5, 10, 15, 20, 30, 50)
wp_data <- rbindlist(lapply(bins, function(b) {
  sub <- rdd[abs(rich_margin) <= b]
  if (nrow(sub) < 10) return(NULL)
  bt <- binom.test(sum(sub$rich_won), nrow(sub), p = 0.5)
  data.table(bandwidth = b,
             win_rate = mean(sub$rich_won) * 100,
             ci_lo = bt$conf.int[1] * 100,
             ci_hi = bt$conf.int[2] * 100,
             n = nrow(sub),
             p_value = bt$p.value)
}))

p7 <- ggplot(wp_data, aes(x = bandwidth, y = win_rate)) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "gray60") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#377EB8") +
  geom_line(color = "#377EB8", linewidth = 0.8) +
  geom_point(color = "#377EB8", size = 2.5) +
  geom_text(aes(label = paste0("N=", n)), vjust = -1.5, size = 2.5, color = "gray40") +
  labs(x = "Maximum Absolute Margin (%)",
       y = "Wealthier Candidate Win Rate (%)",
       title = "") +
  scale_y_continuous(limits = c(45, 65), breaks = seq(45, 65, 5)) +
  scale_x_continuous(breaks = bins)

ggsave(file.path(fig_dir, "fig7_wealth_premium.pdf"), p7, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig7_wealth_premium.png"), p7, width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 8: Placebo Cutoffs
## =============================================================================

cat("Creating Figure 8: Placebo Cutoffs\n")

placebo <- fread(file.path(data_dir, "placebo_cutoffs.csv"))

p8 <- ggplot(placebo, aes(x = cutoff, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_point(aes(color = cutoff == 0, size = cutoff == 0)) +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se,
                    color = cutoff == 0), width = 0.5) +
  scale_color_manual(values = c("gray50", "#E41A1C"), guide = "none") +
  scale_size_manual(values = c(2, 4), guide = "none") +
  labs(x = "Cutoff Location (%)",
       y = "RDD Estimate",
       title = "") +
  annotate("text", x = 0, y = max(placebo$estimate + 1.96 * placebo$se) + 0.2,
           label = "True cutoff", color = "#E41A1C", size = 3.5)

ggsave(file.path(fig_dir, "fig8_placebo.pdf"), p8, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig8_placebo.png"), p8, width = 7, height = 5, dpi = 300)

## =============================================================================
## Figure 9: State-Level Heterogeneity
## =============================================================================

cat("Creating Figure 9: State Heterogeneity\n")

state_data <- fread(file.path(data_dir, "state_subsample.csv"))

p9 <- ggplot(state_data, aes(x = reorder(state, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_point(aes(size = n), color = "#377EB8") +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                width = 0.3, color = "#377EB8") +
  coord_flip() +
  labs(x = "", y = "RDD Estimate: Winner's Log Assets",
       title = "",
       size = "N") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig9_states.pdf"), p9, width = 7, height = 7)
ggsave(file.path(fig_dir, "fig9_states.png"), p9, width = 7, height = 7, dpi = 300)

## =============================================================================
## List generated figures
## =============================================================================

cat("\n=== All figures generated ===\n")
figs <- list.files(fig_dir, pattern = "\\.pdf$")
for (f in figs) {
  cat("  ", f, "\n")
}
