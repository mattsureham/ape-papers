## 05_figures.R — Generate all figures
## apep_1177 v2: The Conviction Lottery

source("./code/00_packages.R")

fig_dir <- "./figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Load data ----
vara <- fread("./data/vara_three_way.csv")
results <- readRDS("./data/main_results_v2.rds")

## ---- Figure 1: Distribution of vara conviction rates by offense ----
# Overlaid density plot showing wider spread for trafficking
vara_long <- melt(vara, id.vars = "vara_codigo",
                  measure.vars = c("rate_traff", "rate_rob", "rate_theft"),
                  variable.name = "offense", value.name = "conv_rate")
vara_long[, offense := factor(offense,
                              levels = c("rate_traff", "rate_rob", "rate_theft"),
                              labels = c("Drug Trafficking", "Robbery", "Theft"))]

fig1 <- ggplot(vara_long, aes(x = conv_rate, fill = offense)) +
  geom_histogram(aes(y = after_stat(density)), bins = 12,
                 position = "identity", alpha = 0.5, color = "white") +
  scale_fill_manual(values = c("#E41A1C", "#377EB8", "#4DAF4A"),
                    name = "Offense Type") +
  scale_x_continuous(labels = percent_format(),
                     breaks = seq(0, 1, 0.2)) +
  labs(x = "Vara Conviction Rate",
       y = "Density",
       title = "Distribution of Courtroom Conviction Rates by Offense Type",
       subtitle = "São Paulo Central, 31 varas, filed 2015-2019") +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig1_distributions.pdf"), fig1,
       width = 7, height = 5)
cat("Figure 1 saved\n")

## ---- Figure 2: Scatter of trafficking vs robbery/theft rates ----
# The money figure: shows decoupling
fig2a <- ggplot(vara, aes(x = rate_rob, y = rate_traff)) +
  geom_point(size = 3, alpha = 0.7, color = "#E41A1C") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(method = "lm", se = TRUE, color = "#E41A1C", alpha = 0.2) +
  scale_x_continuous(labels = percent_format(), limits = c(0.3, 1)) +
  scale_y_continuous(labels = percent_format(), limits = c(0.3, 1)) +
  labs(x = "Robbery Conviction Rate",
       y = "Drug Trafficking Conviction Rate",
       title = "Trafficking vs. Robbery: Partial Decoupling",
       subtitle = paste0("r = ", round(cor(vara$rate_traff, vara$rate_rob), 2))) +
  coord_equal()

fig2b <- ggplot(vara, aes(x = rate_theft, y = rate_traff)) +
  geom_point(size = 3, alpha = 0.7, color = "#E41A1C") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(method = "lm", se = TRUE, color = "#E41A1C", alpha = 0.2) +
  scale_x_continuous(labels = percent_format(), limits = c(0.1, 1)) +
  scale_y_continuous(labels = percent_format(), limits = c(0.1, 1)) +
  labs(x = "Theft Conviction Rate",
       y = "Drug Trafficking Conviction Rate",
       title = "Trafficking vs. Theft: Full Decoupling",
       subtitle = paste0("r = ", round(cor(vara$rate_traff, vara$rate_theft), 2))) +
  coord_equal()

fig2c <- ggplot(vara, aes(x = rate_theft, y = rate_rob)) +
  geom_point(size = 3, alpha = 0.7, color = "#377EB8") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(method = "lm", se = TRUE, color = "#377EB8", alpha = 0.2) +
  scale_x_continuous(labels = percent_format(), limits = c(0.1, 1)) +
  scale_y_continuous(labels = percent_format(), limits = c(0.1, 1)) +
  labs(x = "Theft Conviction Rate",
       y = "Robbery Conviction Rate",
       title = "Robbery vs. Theft: Strong Coupling",
       subtitle = paste0("r = ", round(cor(vara$rate_rob, vara$rate_theft), 2))) +
  coord_equal()

# Combine panels
library(patchwork)
fig2 <- fig2a + fig2b + fig2c +
  plot_layout(ncol = 3) +
  plot_annotation(
    title = "Cross-Offense Conviction Rate Correlations",
    subtitle = "Same 31 courtrooms, same assignment pool, same period",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(fig_dir, "fig2_scatters.pdf"), fig2,
       width = 14, height = 5)
cat("Figure 2 saved\n")

## ---- Figure 3: Trafficking residuals (drug-specific discretion) ----
vara[, traff_resid_rank := rank(traff_residual)]

fig3 <- ggplot(vara, aes(x = reorder(as.factor(vara_codigo), traff_residual),
                         y = traff_residual)) +
  geom_col(aes(fill = traff_residual < -0.05),
           show.legend = FALSE) +
  scale_fill_manual(values = c("FALSE" = "grey60", "TRUE" = "#E41A1C")) +
  scale_y_continuous(labels = percent_format()) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  labs(x = "Courtroom (ordered by drug-specific leniency)",
       y = "Drug-Specific Conviction Rate Residual",
       title = "Drug-Specific Judicial Discretion",
       subtitle = "Residual trafficking conviction rate after removing common severity factor") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 7))

ggsave(file.path(fig_dir, "fig3_residuals.pdf"), fig3,
       width = 8, height = 5)
cat("Figure 3 saved\n")

## ---- Figure 4: Correlation matrix heatmap ----
cor_mat <- cor(vara[, .(rate_traff, rate_rob, rate_theft)])
rownames(cor_mat) <- colnames(cor_mat) <- c("Drug Trafficking", "Robbery", "Theft")

cor_long <- as.data.table(reshape2::melt(cor_mat))
names(cor_long) <- c("Offense1", "Offense2", "Correlation")

fig4 <- ggplot(cor_long, aes(x = Offense1, y = Offense2, fill = Correlation)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = sprintf("%.2f", Correlation)),
            size = 6, fontface = "bold") +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0.5, limits = c(0, 1)) +
  labs(title = "Cross-Offense Correlation of Vara Conviction Rates",
       subtitle = "31 courtrooms in São Paulo Central") +
  theme(axis.title = element_blank(),
        axis.text = element_text(size = 12, face = "bold"))

ggsave(file.path(fig_dir, "fig4_correlation_matrix.pdf"), fig4,
       width = 6, height = 5)
cat("Figure 4 saved\n")

## ---- Figure 5: First-stage binscatter (trafficking) ----
if (file.exists("./data/analysis_data_v2.csv")) {
  traff <- fread("./data/analysis_data_v2.csv")
} else {
  traff <- NULL
}
if (is.null(traff) || !"vara_leniency" %in% names(traff)) {
  traff_raw <- as.data.table(arrow::read_parquet("./data/smoke_trafficking.parquet"))
  traff_raw[, filing_year := as.integer(substr(filing_date, 1, 4))]
  traff_raw <- traff_raw[filing_year >= 2015 & filing_year <= 2019]
  traff_raw[, convicted := as.integer(convicted)]
  traff_raw[, vara_total_conv := sum(convicted, na.rm = TRUE), by = vara_codigo]
  traff_raw[, vara_total_n := .N, by = vara_codigo]
  traff_raw[, vara_leniency := (vara_total_conv - convicted) / (vara_total_n - 1)]
  traff <- traff_raw[vara_total_n >= 20]
}

# Create leniency quintile bins
traff[, leniency_bin := cut(vara_leniency,
                            breaks = quantile(vara_leniency,
                                              probs = seq(0, 1, 0.1),
                                              na.rm = TRUE),
                            include.lowest = TRUE)]

bin_means <- traff[!is.na(leniency_bin),
                   .(conv_rate = mean(convicted, na.rm = TRUE),
                     leniency = mean(vara_leniency, na.rm = TRUE),
                     n = .N),
                   by = leniency_bin]

fig5 <- ggplot(bin_means, aes(x = leniency, y = conv_rate)) +
  geom_point(size = 3, color = "#E41A1C") +
  geom_smooth(method = "lm", se = TRUE, color = "#E41A1C", alpha = 0.2) +
  scale_x_continuous(labels = percent_format()) +
  scale_y_continuous(labels = percent_format()) +
  labs(x = "Leave-One-Out Vara Leniency (decile mean)",
       y = "Individual Conviction Rate",
       title = "First Stage: Vara Leniency Predicts Conviction",
       subtitle = "Drug trafficking cases, São Paulo Central") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "grey50", alpha = 0.5)

ggsave(file.path(fig_dir, "fig5_first_stage.pdf"), fig5,
       width = 7, height = 5)
cat("Figure 5 saved\n")

cat("\nAll figures generated.\n")
