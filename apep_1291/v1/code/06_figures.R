## 06_figures.R — Generate all figures for apep_1291
## Figures: event study plot, border county map, raw trends

source("00_packages.R")

models <- readRDS("../data/models.rds")
border_panel <- readRDS("../data/border_panel.rds")
county_sf <- readRDS("../data/county_sf.rds")
border_counties <- readRDS("../data/border_counties.rds")

bp <- border_panel |>
  mutate(
    log_farms = log(n_farms + 1),
    log_avg_size = log(avg_farm_size + 1)
  )

all_years <- sort(unique(bp$year))

# ---- Figure 1: Event Study Plot ----
cat("Generating Figure 1: Event Study...\n")

es_size <- models$es_size
es_var_names <- names(coef(es_size))
es_years_num <- as.integer(gsub("yr_", "", es_var_names))

es_df <- tibble(
  year = c(es_years_num, 2007),
  coef = c(as.numeric(coef(es_size)[es_var_names]), 0),
  se = c(as.numeric(se(es_size)[es_var_names]), 0)
) |>
  arrange(year) |>
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se
  )

pdf("../figures/fig1_event_study.pdf", width = 6, height = 4)
ggplot(es_df, aes(x = year, y = coef)) +
  geom_hline(yintercept = 0, color = "gray60", linetype = "dashed") +
  geom_vline(xintercept = 2007, color = "firebrick3", linetype = "dotted", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "steelblue", size = 2.5) +
  annotate("text", x = 2008.5, y = max(es_df$ci_hi) * 0.85,
           label = "Jones v. Gale\n(Dec 2006)", size = 3, hjust = 0, color = "firebrick3") +
  labs(x = "Census Year", y = "Coefficient (acres per farm)", title = NULL) +
  scale_x_continuous(breaks = sort(c(es_years_num, 2007))) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.margin = margin(5, 10, 5, 5))
dev.off()

# ---- Figure 2: Raw Trends ----
cat("Generating Figure 2: Raw Trends...\n")

trends <- bp |>
  group_by(year, group = ifelse(in_nebraska, "Nebraska (treated)", "Neighbors (control)")) |>
  summarise(
    mean_size = mean(avg_farm_size, na.rm = TRUE),
    mean_farms = mean(n_farms, na.rm = TRUE),
    mean_share = mean(share_large, na.rm = TRUE),
    .groups = "drop"
  )

pdf("../figures/fig2_trends.pdf", width = 7, height = 8)
p1 <- ggplot(trends, aes(x = year, y = mean_size, color = group, shape = group)) +
  geom_vline(xintercept = 2007, color = "gray50", linetype = "dotted") +
  geom_line(linewidth = 0.8) + geom_point(size = 2.5) +
  labs(x = NULL, y = "Avg farm size (acres)", color = NULL, shape = NULL) +
  scale_x_continuous(breaks = all_years) +
  scale_color_manual(values = c("Nebraska (treated)" = "steelblue", "Neighbors (control)" = "coral3")) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

p2 <- ggplot(trends, aes(x = year, y = mean_farms, color = group, shape = group)) +
  geom_vline(xintercept = 2007, color = "gray50", linetype = "dotted") +
  geom_line(linewidth = 0.8) + geom_point(size = 2.5) +
  labs(x = NULL, y = "Mean farm count", color = NULL, shape = NULL) +
  scale_x_continuous(breaks = all_years) +
  scale_color_manual(values = c("Nebraska (treated)" = "steelblue", "Neighbors (control)" = "coral3")) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

p3 <- ggplot(trends, aes(x = year, y = mean_share, color = group, shape = group)) +
  geom_vline(xintercept = 2007, color = "gray50", linetype = "dotted") +
  geom_line(linewidth = 0.8) + geom_point(size = 2.5) +
  labs(x = "Census Year", y = expression("Share of farms" >= "1,000 ac"), color = NULL, shape = NULL) +
  scale_x_continuous(breaks = all_years) +
  scale_color_manual(values = c("Nebraska (treated)" = "steelblue", "Neighbors (control)" = "coral3")) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

gridExtra::grid.arrange(p1, p2, p3, ncol = 1)
dev.off()

# ---- Figure 3: Border County Map ----
cat("Generating Figure 3: Border County Map...\n")

map_data <- county_sf |>
  mutate(
    group = case_when(
      GEOID %in% border_counties & STUSPS == "NE" ~ "Nebraska (treated)",
      GEOID %in% border_counties & STUSPS != "NE" ~ "Neighbor (control)",
      STUSPS == "NE" ~ "Nebraska (interior)",
      TRUE ~ "Neighbor (interior)"
    )
  )

pdf("../figures/fig3_border_map.pdf", width = 7, height = 4.5)
ggplot(map_data) +
  geom_sf(aes(fill = group), color = "gray70", linewidth = 0.15) +
  scale_fill_manual(values = c(
    "Nebraska (treated)" = "steelblue",
    "Neighbor (control)" = "coral3",
    "Nebraska (interior)" = "lightblue",
    "Neighbor (interior)" = "gray90"
  )) +
  labs(fill = NULL) +
  theme_void(base_size = 10) +
  theme(legend.position = "bottom")
dev.off()

cat("\n=== All figures generated ===\n")
