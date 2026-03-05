# ==============================================================================
# 05_figures.R — Generate all figures
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

source("00_packages.R")

# Load data and results
dvf <- fread(file.path(data_dir, "dvf_analysis.csv"))
commune <- fread(file.path(data_dir, "commune_panel.csv"))
treat <- fread(file.path(data_dir, "treatment_intensity.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

commune_clean <- commune[!is.na(th_share_pre) & !is.na(taux_tfb)]

# ==============================================================================
# FIGURE 1: Pre-reform TH rate distribution across communes
# ==============================================================================

cat("Figure 1: TH rate distribution\n")

fig1 <- ggplot(treat, aes(x = th_rate_pre)) +
  geom_histogram(bins = 50, fill = "#2166AC", alpha = 0.8, color = "white") +
  geom_vline(xintercept = median(treat$th_rate_pre, na.rm = TRUE),
             linetype = "dashed", color = "red", linewidth = 0.8) +
  labs(
    title = "Distribution of Pre-Reform Taxe d'Habitation Rates",
    subtitle = "Average commune-level TH rate, 2014-2017",
    x = "Taxe d'Habitation Rate (%)",
    y = "Number of Communes"
  ) +
  annotate("text", x = median(treat$th_rate_pre, na.rm = TRUE) + 1,
           y = Inf, vjust = 2, hjust = 0, color = "red", size = 3.5,
           label = paste0("Median: ", round(median(treat$th_rate_pre, na.rm = TRUE), 1), "%"))

ggsave(file.path(fig_dir, "fig1_th_rate_distribution.pdf"), fig1,
       width = 7, height = 4.5)

# ==============================================================================
# FIGURE 2: Event study — Tax capitalization
# ==============================================================================

cat("Figure 2: Event study (capitalization)\n")

es <- results$es_model
es_df <- as.data.frame(coeftable(es))
es_df$year <- as.integer(gsub("year::|:th_rate_pre", "", rownames(es_df)))

ref_row <- data.frame(Estimate = 0, `Std. Error` = 0,
                       `t value` = 0, `Pr(>|t|)` = 1,
                       year = 2017, check.names = FALSE)
names(ref_row) <- names(es_df)
es_df <- rbind(es_df, ref_row)
es_df <- es_df[order(es_df$year), ]

es_df$ci_lo <- es_df$Estimate - 1.96 * es_df$`Std. Error`
es_df$ci_hi <- es_df$Estimate + 1.96 * es_df$`Std. Error`

fig2 <- ggplot(es_df, aes(x = year, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 2017.5, linetype = "dotted", color = "red", linewidth = 0.6) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2166AC", alpha = 0.2) +
  geom_point(size = 2.5, color = "#2166AC") +
  geom_line(color = "#2166AC", linewidth = 0.8) +
  labs(
    title = "Event Study: Tax Capitalization into Property Prices",
    subtitle = "Interaction of year with pre-reform TH rate (ref: 2017)",
    x = "Year",
    y = expression(beta[t] ~ "(log price/m"^2 * ")")
  ) +
  annotate("text", x = 2017.5, y = Inf, vjust = 2, hjust = -0.1,
           label = "Reform onset", color = "red", size = 3)

ggsave(file.path(fig_dir, "fig2_event_study_capitalization.pdf"), fig2,
       width = 7, height = 4.5)

# ==============================================================================
# FIGURE 3: Event study — Fiscal displacement
# ==============================================================================

cat("Figure 3: Event study (fiscal displacement)\n")

fes <- results$fiscal_es
fes_df <- as.data.frame(coeftable(fes))
fes_df$year <- as.integer(gsub("year::|:th_share_pre", "", rownames(fes_df)))

ref_row_f <- data.frame(Estimate = 0, `Std. Error` = 0,
                          `t value` = 0, `Pr(>|t|)` = 1,
                          year = 2017, check.names = FALSE)
names(ref_row_f) <- names(fes_df)
fes_df <- rbind(fes_df, ref_row_f)
fes_df <- fes_df[order(fes_df$year), ]

fes_df$ci_lo <- fes_df$Estimate - 1.96 * fes_df$`Std. Error`
fes_df$ci_hi <- fes_df$Estimate + 1.96 * fes_df$`Std. Error`

fig3 <- ggplot(fes_df, aes(x = year, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 2017.5, linetype = "dotted", color = "red", linewidth = 0.6) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#B2182B", alpha = 0.2) +
  geom_point(size = 2.5, color = "#B2182B") +
  geom_line(color = "#B2182B", linewidth = 0.8) +
  labs(
    title = "Event Study: Fiscal Displacement onto Property Owners",
    subtitle = "Interaction of year with pre-reform TH revenue dependence (ref: 2017)",
    x = "Year",
    y = expression(phi[t] ~ "(Taxe Fonciere rate)")
  ) +
  annotate("text", x = 2017.5, y = Inf, vjust = 2, hjust = -0.1,
           label = "Reform onset", color = "red", size = 3)

ggsave(file.path(fig_dir, "fig3_event_study_fiscal.pdf"), fig3,
       width = 7, height = 4.5)

# ==============================================================================
# FIGURE 4: Price trends by TH rate quartile
# ==============================================================================

cat("Figure 4: Price trends by TH quartile\n")

quartile_trends <- dvf[!is.na(th_quartile), .(
  mean_price = weighted.mean(exp(log_price_m2), w = n_total_sales, na.rm = TRUE),
  n = sum(n_total_sales, na.rm = TRUE)
), by = .(year, th_quartile)]

fig4 <- ggplot(quartile_trends, aes(x = year, y = mean_price, color = th_quartile)) +
  geom_vline(xintercept = 2017.5, linetype = "dotted", color = "red", linewidth = 0.6) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  scale_color_brewer(palette = "RdBu", direction = -1,
                     name = "Pre-Reform TH\nRate Quartile") +
  labs(
    title = "Property Price Trends by Pre-Reform Tax Rate Quartile",
    subtitle = "Weighted mean price per m2 by commune TH rate quartile",
    x = "Year",
    y = "Mean Price per m2 (EUR)"
  ) +
  scale_y_continuous(labels = comma) +
  annotate("text", x = 2017.5, y = Inf, vjust = 2, hjust = -0.1,
           label = "Reform onset", color = "red", size = 3)

ggsave(file.path(fig_dir, "fig4_price_trends_quartile.pdf"), fig4,
       width = 7, height = 4.5)

# ==============================================================================
# FIGURE 5: TF rate trends by TH dependence quartile
# ==============================================================================

cat("Figure 5: TF rate trends by TH dependence\n")

commune_clean[, th_depend_q := cut(th_share_pre,
                                     breaks = quantile(th_share_pre, 0:4/4, na.rm = TRUE),
                                     labels = paste0("Q", 1:4), include.lowest = TRUE)]

tf_trends <- commune_clean[!is.na(th_depend_q), .(
  mean_tfb = mean(taux_tfb, na.rm = TRUE),
  n = .N
), by = .(year, th_depend_q)]

fig5 <- ggplot(tf_trends, aes(x = year, y = mean_tfb, color = th_depend_q)) +
  geom_vline(xintercept = 2017.5, linetype = "dotted", color = "red", linewidth = 0.6) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2) +
  scale_color_brewer(palette = "OrRd",
                     name = "Pre-Reform TH\nDependence Quartile") +
  labs(
    title = "Taxe Fonciere Rate Trends by Pre-Reform TH Revenue Dependence",
    subtitle = "Mean commune TF rate by quartile of TH revenue share",
    x = "Year",
    y = "Taxe Fonciere Rate (%)"
  ) +
  annotate("text", x = 2017.5, y = Inf, vjust = 2, hjust = -0.1,
           label = "Reform onset", color = "red", size = 3)

ggsave(file.path(fig_dir, "fig5_tf_trends_dependence.pdf"), fig5,
       width = 7, height = 4.5)

# ==============================================================================
# FIGURE 6: Net incidence decomposition
# ==============================================================================

cat("Figure 6: Net incidence decomposition\n")

beta_A <- coef(results$main_model)["treat_post"]
beta_B <- coef(results$fiscal_model)["th_depend_post"]
gamma_TF <- coef(results$tfb_cap)["taux_tfb_annual"]

avg_th <- mean(dvf$th_rate_pre, na.rm = TRUE)
avg_share <- mean(commune_clean$th_share_pre, na.rm = TRUE)

gross <- beta_A * avg_th
offset <- gamma_TF * beta_B * avg_share
net <- gross - offset

decomp_df <- data.frame(
  component = c("Gross TH\nCapitalization", "TF Fiscal\nOffset", "Net\nCapitalization"),
  value = c(gross, offset, net),
  type = c("gross", "offset", "net")
)
decomp_df$component <- factor(decomp_df$component,
  levels = c("Gross TH\nCapitalization", "TF Fiscal\nOffset", "Net\nCapitalization"))

fig6 <- ggplot(decomp_df, aes(x = component, y = value, fill = type)) +
  geom_col(width = 0.6) +
  geom_hline(yintercept = 0, linewidth = 0.5) +
  scale_fill_manual(values = c("gross" = "#2166AC", "offset" = "#B2182B", "net" = "#4DAF4A"),
                    guide = "none") +
  labs(
    title = "Net Incidence Decomposition",
    subtitle = "Effect on log(price/m2) at mean treatment intensity",
    x = "",
    y = expression(Delta ~ "log(price/m"^2 * ")")
  ) +
  geom_text(aes(label = round(value, 4)), vjust = -0.5, size = 3.5)

ggsave(file.path(fig_dir, "fig6_net_incidence.pdf"), fig6,
       width = 6, height = 4.5)

# ==============================================================================
# FIGURE 7: Transaction volume over time
# ==============================================================================

cat("Figure 7: Transaction volume\n")

vol_trends <- dvf[, .(
  total_sales = sum(n_total_sales, na.rm = TRUE),
  house_sales = sum(n_house_sales, na.rm = TRUE),
  apt_sales = sum(n_apt_sales, na.rm = TRUE)
), by = year]

vol_long <- melt(vol_trends, id.vars = "year",
                  measure.vars = c("house_sales", "apt_sales"),
                  variable.name = "type", value.name = "sales")
vol_long[, type := fifelse(type == "house_sales", "Houses", "Apartments")]

fig7 <- ggplot(vol_long, aes(x = year, y = sales / 1000, fill = type)) +
  geom_col(position = "stack", width = 0.7) +
  geom_vline(xintercept = 2017.5, linetype = "dotted", color = "red", linewidth = 0.6) +
  scale_fill_brewer(palette = "Set2", name = "Property Type") +
  labs(
    title = "Property Transaction Volume, 2014-2024",
    subtitle = "Residential sales by property type",
    x = "Year",
    y = "Transactions (thousands)"
  ) +
  annotate("text", x = 2017.5, y = Inf, vjust = 2, hjust = -0.1,
           label = "Reform onset", color = "red", size = 3)

ggsave(file.path(fig_dir, "fig7_transaction_volume.pdf"), fig7,
       width = 7, height = 4.5)

cat("\n=== All figures saved to", fig_dir, "===\n")
