##============================================================
## 05_figures.R — Generate all figures
## APEP-0543: Rent Control and Property Values in France
##============================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE)

## ─── Load data ───────────────────────────────────────────
analysis <- as.data.table(read_parquet(file.path(data_dir, "dvf_analysis.parquet")))
analysis[, log_price := log(valeur_fonciere)]
panel <- as.data.table(read_parquet(file.path(data_dir, "dvf_panel.parquet")))

main_models <- readRDS(file.path(data_dir, "main_models.rds"))
es_invest <- readRDS(file.path(data_dir, "es_invest_model.rds"))
es_owner <- readRDS(file.path(data_dir, "es_owner_model.rds"))

city_results <- fread(file.path(data_dir, "city_by_city_results.csv"))
loo_results <- fread(file.path(data_dir, "robustness_loo.csv"))
ri_dist <- fread(file.path(data_dir, "ri_distribution.csv"))
ri_results <- fread(file.path(data_dir, "ri_results.csv"))

## ──────────────────────────────────────────────────────────
## FIGURE 1: Price trends by property type and treatment
## ──────────────────────────────────────────────────────────

cat("Figure 1: Price trends...\n")

## Aggregate annual price indices
trends <- analysis[, .(
  median_price = median(valeur_fonciere),
  mean_log_price = mean(log_price),
  n = .N
), by = .(year, treated_commune, investment_type)]

trends[, group := paste0(
  fifelse(treated_commune, "Treated", "Control"), " - ",
  fifelse(investment_type, "Investment", "Owner-Occupier")
)]

## Normalize to 2021 = 100 (first full year in DVF data)
trends[, base := mean_log_price[year == 2021], by = group]
trends[, price_index := exp(mean_log_price - base) * 100]

fig1 <- ggplot(trends, aes(x = year, y = price_index,
                            color = group, linetype = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2021.5, linetype = "dashed", color = "gray40",
             linewidth = 0.5) +
  annotate("text", x = 2021.7, y = max(trends$price_index, na.rm = TRUE) * 0.98,
           label = "First identified\ncity adoption", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = c(
    "Treated - Investment" = "#E63946",
    "Treated - Owner-Occupier" = "#E9A8AE",
    "Control - Investment" = "#457B9D",
    "Control - Owner-Occupier" = "#A8C9DD"
  )) +
  scale_linetype_manual(values = c(
    "Treated - Investment" = "solid",
    "Treated - Owner-Occupier" = "dashed",
    "Control - Investment" = "solid",
    "Control - Owner-Occupier" = "dashed"
  )) +
  labs(
    x = "Year", y = "Price Index (2021 = 100)",
    color = NULL, linetype = NULL,
    title = "Property Price Trends by Treatment Status and Property Type",
    subtitle = "Investment = studios and 1-2 room apartments; Owner-Occupier = houses and 3+ room apartments"
  ) +
  theme(legend.position = "bottom",
        legend.key.width = unit(2, "cm"))

ggsave(file.path(fig_dir, "fig1_price_trends.pdf"), fig1,
       width = 10, height = 7)

## ──────────────────────────────────────────────────────────
## FIGURE 2: Event study — Investment vs Owner-Occupier
## ──────────────────────────────────────────────────────────

cat("Figure 2: Event study...\n")

## Read pre-computed event study data from 03_main_analysis.R
es_plot_data <- fread(file.path(data_dir, "event_study_plot_data.csv"))

if (nrow(es_plot_data) > 0) {
  fig2 <- ggplot(es_plot_data, aes(x = rel_period, y = estimate,
                                    color = type, fill = type)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray40") +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15,
                color = NA) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2.5) +
    scale_color_manual(values = c(
      "Investment Properties" = "#E63946",
      "Owner-Occupier Properties" = "#457B9D"
    )) +
    scale_fill_manual(values = c(
      "Investment Properties" = "#E63946",
      "Owner-Occupier Properties" = "#457B9D"
    )) +
    labs(
      x = "Years Relative to Rent Control Adoption",
      y = "Estimated Effect on Log Price",
      color = NULL, fill = NULL,
      title = "Event Study: Effect of Rent Control on Property Prices",
      subtitle = "Identified sample (excl. Paris & Lille); 95% CI; reference period = -1"
    ) +
    theme(legend.position = "bottom")

  ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2,
         width = 10, height = 7)
  cat("  Event study figure saved.\n")
} else {
  cat("  WARNING: No event study data to plot.\n")
}

## ──────────────────────────────────────────────────────────
## FIGURE 3: City-by-city DDD estimates
## ──────────────────────────────────────────────────────────

cat("Figure 3: City-by-city estimates...\n")

city_results[, city := factor(city, levels = city[order(ddd_coef)])]

fig3 <- ggplot(city_results, aes(x = city, y = ddd_coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ddd_coef - 1.96 * ddd_se,
                      ymax = ddd_coef + 1.96 * ddd_se),
                  color = "#E63946", size = 0.8) +
  coord_flip() +
  labs(
    x = NULL, y = "DDD Coefficient (log price)",
    title = "Triple-Difference Estimates by City",
    subtitle = "Effect of rent control on investment-type property prices; 95% CI"
  )

ggsave(file.path(fig_dir, "fig3_city_estimates.pdf"), fig3,
       width = 8, height = 6)

## ──────────────────────────────────────────────────────────
## FIGURE 4: Leave-one-out stability
## ──────────────────────────────────────────────────────────

cat("Figure 4: Leave-one-out...\n")

## Add full-sample estimate
full_coef <- coef(main_models[["DDD"]])["post_treatmentTRUE:investment_typeTRUE"]

loo_results[, dropped_city := factor(dropped_city,
                                      levels = dropped_city[order(ddd_coef)])]

fig4 <- ggplot(loo_results, aes(x = dropped_city, y = ddd_coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_hline(yintercept = full_coef, linetype = "solid",
             color = "#457B9D", linewidth = 0.5) +
  geom_pointrange(aes(ymin = ddd_coef - 1.96 * ddd_se,
                      ymax = ddd_coef + 1.96 * ddd_se),
                  color = "#E63946", size = 0.8) +
  coord_flip() +
  labs(
    x = "Dropped City", y = "DDD Coefficient",
    title = "Leave-One-Out Stability of Triple-Difference Estimate",
    subtitle = "Blue line = full-sample estimate; each point drops one treated city"
  )

ggsave(file.path(fig_dir, "fig4_leave_one_out.pdf"), fig4,
       width = 8, height = 6)

## ──────────────────────────────────────────────────────────
## FIGURE 5: Randomization inference
## ──────────────────────────────────────────────────────────

cat("Figure 5: Randomization inference...\n")

fig5 <- ggplot(ri_dist, aes(x = perm_coef)) +
  geom_histogram(bins = 50, fill = "#457B9D", color = "white", alpha = 0.7) +
  geom_vline(xintercept = ri_results$actual_coef, color = "#E63946",
             linewidth = 1.2, linetype = "solid") +
  annotate("text", x = ri_results$actual_coef, y = Inf,
           label = paste0("Actual = ", round(ri_results$actual_coef, 4),
                         "\nRI p = ", round(ri_results$ri_pval, 3)),
           hjust = -0.1, vjust = 1.5, size = 4, color = "#E63946") +
  labs(
    x = "Permuted DDD Coefficient",
    y = "Frequency",
    title = "Randomization Inference: Distribution of Placebo Estimates",
    subtitle = paste0(ri_results$n_permutations,
                     " permutations of treatment timing; red line = actual estimate")
  )

ggsave(file.path(fig_dir, "fig5_randomization_inference.pdf"), fig5,
       width = 9, height = 6)

## ──────────────────────────────────────────────────────────
## FIGURE 6: Transaction volume effects
## ──────────────────────────────────────────────────────────

cat("Figure 6: Transaction volumes...\n")

## Track investment-type transaction share over time
vol_trends <- analysis[, .(
  n_total = .N,
  n_invest = sum(investment_type),
  pct_invest = mean(investment_type) * 100
), by = .(year, treated_commune)]

vol_trends[, group := fifelse(treated_commune, "Treated Cities", "Control Cities")]

fig6 <- ggplot(vol_trends, aes(x = year, y = pct_invest, color = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", color = "gray40") +
  scale_color_manual(values = c(
    "Treated Cities" = "#E63946",
    "Control Cities" = "#457B9D"
  )) +
  labs(
    x = "Year",
    y = "Investment-Type Share of Transactions (%)",
    color = NULL,
    title = "Composition Effect: Investment Property Transaction Share",
    subtitle = "Share of sales that are studios/1-2 room apartments"
  ) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig6_volume_composition.pdf"), fig6,
       width = 9, height = 6)

cat("\n05_figures.R complete. All figures saved to figures/\n")
cat("Generated:", length(list.files(fig_dir, pattern = "\\.pdf$")), "PDF figures\n")
