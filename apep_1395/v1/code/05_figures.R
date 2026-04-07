## 05_figures.R — Generate figures
## apep_1395: Denmark Renovation Arbitrage Ban

source("00_packages.R")

permits <- readRDS("../data/permits_panel.rds")
dwellings <- readRDS("../data/dwellings_panel.rds")
es_coefs <- readRDS("../data/event_study_coefs.rds")
models <- readRDS("../data/main_models.rds")

# Theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "gray40")
  )

figdir <- "../figures/"

# ---- Figure 1: Event Study — Total Building Permits ----
cat("Figure 1: Event study (total permits)...\n")

# Trim to reasonable window
es_plot <- es_coefs %>%
  filter(rel_q >= -20 & rel_q <= 21) %>%
  mutate(
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  )

p1 <- ggplot(es_plot, aes(x = rel_q, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
  geom_point(size = 1.5, color = "steelblue") +
  geom_line(color = "steelblue", alpha = 0.6) +
  annotate("text", x = 0.5, y = max(es_plot$ci_hi) * 0.9,
           label = "Reform\n(2020Q3)", size = 3, hjust = 0, color = "red3") +
  labs(x = "Quarters Relative to Reform (2020Q3 = 0)",
       y = "Difference in Building Permits\n(Treated − Control)",
       title = "Event Study: Building Permits",
       subtitle = "Municipality fixed effects, quarter fixed effects. 95% CI clustered at municipality level.") +
  theme_apep

ggsave(paste0(figdir, "fig1_event_study.pdf"), p1, width = 8, height = 5)

# ---- Figure 2: Event Study — Multifamily Permits Only ----
cat("Figure 2: Event study (multifamily)...\n")

es_multi <- readRDS("../data/event_study_multi_coefs.rds")
es_multi_plot <- es_multi %>%
  filter(rel_q >= -20 & rel_q <= 21) %>%
  mutate(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)

p2 <- ggplot(es_multi_plot, aes(x = rel_q, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "darkgreen", alpha = 0.2) +
  geom_point(size = 1.5, color = "darkgreen") +
  geom_line(color = "darkgreen", alpha = 0.6) +
  annotate("text", x = 0.5, y = max(es_multi_plot$ci_hi) * 0.9,
           label = "Reform\n(2020Q3)", size = 3, hjust = 0, color = "red3") +
  labs(x = "Quarters Relative to Reform (2020Q3 = 0)",
       y = "Difference in Multifamily Permits\n(Treated − Control)",
       title = "Event Study: Multifamily Building Permits",
       subtitle = "Rental-relevant building categories. 95% CI clustered at municipality level.") +
  theme_apep

ggsave(paste0(figdir, "fig2_event_study_multi.pdf"), p2, width = 8, height = 5)

# ---- Figure 3: Raw Trends — Mean Permits by Treatment Group ----
cat("Figure 3: Raw trends...\n")

trends <- permits %>%
  group_by(treated, year, quarter) %>%
  summarise(mean_permits = mean(total_permits, na.rm = TRUE),
            mean_multi = mean(multifamily_permits, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(time_q = year + (quarter - 1) / 4,
         group = ifelse(treated == 1, "Treated (80 municipalities)", "Control (18 opt-out)"))

p3 <- ggplot(trends %>% filter(year >= 2015), aes(x = time_q, y = mean_permits, color = group)) +
  geom_vline(xintercept = 2020.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1) +
  scale_color_manual(values = c("Treated (80 municipalities)" = "steelblue",
                                "Control (18 opt-out)" = "coral")) +
  labs(x = "Year-Quarter",
       y = "Mean Building Permits per Municipality",
       title = "Building Permits: Treated vs. Control Municipalities",
       subtitle = "Pre-reform parallel trends (2015–2020). Vertical line = reform date (2020Q3).",
       color = NULL) +
  theme_apep

ggsave(paste0(figdir, "fig3_raw_trends.pdf"), p3, width = 8, height = 5)

# ---- Figure 4: Multifamily trends ----
cat("Figure 4: Multifamily trends...\n")

p4 <- ggplot(trends %>% filter(year >= 2015), aes(x = time_q, y = mean_multi, color = group)) +
  geom_vline(xintercept = 2020.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1) +
  scale_color_manual(values = c("Treated (80 municipalities)" = "darkgreen",
                                "Control (18 opt-out)" = "orange")) +
  labs(x = "Year-Quarter",
       y = "Mean Multifamily Permits per Municipality",
       title = "Multifamily Building Permits: Treated vs. Control",
       subtitle = "Rental-relevant construction. Vertical line = reform date (2020Q3).",
       color = NULL) +
  theme_apep

ggsave(paste0(figdir, "fig4_multi_trends.pdf"), p4, width = 8, height = 5)

# ---- Figure 5: Dwelling Stock Evolution ----
cat("Figure 5: Dwelling stock...\n")

names(dwellings) <- make.names(names(dwellings))
rental_col <- grep("tenant|lejer|rental", names(dwellings), value = TRUE, ignore.case = TRUE)
owner_col <- grep("owner|ejer", names(dwellings), value = TRUE, ignore.case = TRUE)

if (length(rental_col) > 0) {
  dw_trends <- dwellings %>%
    mutate(rental = .data[[rental_col[1]]],
           owner_occ = .data[[owner_col[1]]]) %>%
    group_by(treated, year) %>%
    summarise(mean_rental = mean(rental, na.rm = TRUE),
              mean_owner = mean(owner_occ, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(group = ifelse(treated == 1, "Treated", "Control"))

  # Normalize to 2019 = 100
  dw_base <- dw_trends %>%
    filter(year == 2019) %>%
    select(group, base_rental = mean_rental, base_owner = mean_owner)

  dw_norm <- dw_trends %>%
    left_join(dw_base, by = "group") %>%
    mutate(rental_idx = mean_rental / base_rental * 100,
           owner_idx = mean_owner / base_owner * 100)

  dw_long <- dw_norm %>%
    pivot_longer(cols = c(rental_idx, owner_idx),
                 names_to = "type", values_to = "index") %>%
    mutate(type = ifelse(type == "rental_idx", "Rental", "Owner-Occupied"))

  p5 <- ggplot(dw_long, aes(x = year, y = index, color = group, linetype = type)) +
    geom_vline(xintercept = 2020.5, linetype = "dashed", color = "red3", alpha = 0.5) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.5) +
    scale_color_manual(values = c("Treated" = "steelblue", "Control" = "coral")) +
    labs(x = "Year", y = "Index (2019 = 100)",
         title = "Dwelling Stock Evolution by Tenancy Type",
         subtitle = "Rental vs. owner-occupied dwellings, indexed to 2019 = 100.",
         color = "Group", linetype = "Dwelling Type") +
    theme_apep

  ggsave(paste0(figdir, "fig5_dwelling_stock.pdf"), p5, width = 8, height = 5)
}

# ---- Figure 6: Distribution of permits across municipalities (pre vs post) ----
cat("Figure 6: Distribution...\n")

permits_dist <- permits %>%
  filter(year >= 2015) %>%
  mutate(period = ifelse(post == 0, "Pre-Reform (2015–2020Q2)", "Post-Reform (2020Q3–2025)")) %>%
  group_by(muni_name, treated, period) %>%
  summarise(mean_permits = mean(total_permits, na.rm = TRUE), .groups = "drop") %>%
  mutate(group = ifelse(treated == 1, "Treated", "Control"))

p6 <- ggplot(permits_dist, aes(x = mean_permits, fill = group)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~period, ncol = 1) +
  scale_fill_manual(values = c("Treated" = "steelblue", "Control" = "coral")) +
  labs(x = "Mean Quarterly Building Permits per Municipality",
       y = "Density",
       title = "Distribution of Building Permits: Pre vs. Post Reform",
       fill = "Group") +
  theme_apep +
  theme(legend.position = "bottom")

ggsave(paste0(figdir, "fig6_distribution.pdf"), p6, width = 7, height = 7)

# ---- Figure 7: Event study with restricted pre-period (2015+) ----
cat("Figure 7: Event study (2015+ window)...\n")

permits_short <- permits %>% filter(year >= 2015)
permits_short$muni_id <- as.numeric(factor(permits_short$muni_name))
permits_short$time_id <- as.numeric(factor(paste(permits_short$year, permits_short$quarter)))

m_es_short <- feols(total_permits ~ i(rel_q, treated, ref = -1) | muni_id + time_id,
                    data = permits_short, cluster = ~muni_id)

es_short <- as.data.frame(coeftable(m_es_short))
es_short$rel_q <- as.numeric(str_extract(rownames(es_short), "-?\\d+"))
es_short <- es_short[!is.na(es_short$rel_q), ]
names(es_short)[1:4] <- c("estimate", "se", "tstat", "pvalue")

es_short_plot <- es_short %>%
  filter(rel_q >= -20 & rel_q <= 21) %>%
  mutate(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)

p7 <- ggplot(es_short_plot, aes(x = rel_q, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "purple4", alpha = 0.2) +
  geom_point(size = 1.5, color = "purple4") +
  geom_line(color = "purple4", alpha = 0.6) +
  annotate("text", x = 1, y = max(es_short_plot$ci_hi) * 0.85,
           label = "Reform (2020Q3)", size = 3, hjust = 0, color = "red3") +
  labs(x = "Quarters Relative to Reform (2020Q3 = 0)",
       y = "Difference in Building Permits",
       title = "Event Study: Restricted Pre-Period (2015+)",
       subtitle = "Cleaner parallel trends window. 95% CI clustered at municipality level.") +
  theme_apep

ggsave(paste0(figdir, "fig7_event_study_short.pdf"), p7, width = 8, height = 5)

cat("All figures saved.\n")
cat(sprintf("Total figures: %d\n", length(list.files(figdir, pattern = "\\.pdf$"))))
