## 06_figures.R — Generate all figures
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir   <- "../data/"
fig_dir    <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "la_month_panel.csv"))
load(file.path(data_dir, "main_results.RData"))

# Theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position  = "bottom",
    plot.title       = element_text(face = "bold", size = 12),
    plot.caption     = element_text(size = 8, hjust = 0, color = "grey50")
  )

## ==================================================================
## FIGURE 1: Parallel Trends — Mean Monthly Collisions by Country
## ==================================================================
cat("Generating Figure 1: Parallel Trends\n")

# Aggregate monthly means by country
country_means <- panel[, .(
  mean_collisions = mean(n_collisions),
  mean_ksi        = mean(n_ksi),
  mean_ped_ksi    = mean(n_ped_ksi)
), by = .(year, month, welsh)]

country_means[, date := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]
country_means[, Country := ifelse(welsh == 1, "Wales", "England")]

treatment_date <- as.Date("2023-09-01")

# Panel A: Total Collisions
p1a <- ggplot(country_means, aes(x = date, y = mean_collisions, color = Country)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = treatment_date, linetype = "dashed", color = "grey40") +
  annotate("text", x = treatment_date + 30, y = max(country_means$mean_collisions) * 0.95,
           label = "20mph\ndefault", hjust = 0, size = 3, color = "grey40") +
  scale_color_manual(values = c("England" = "#2166AC", "Wales" = "#B2182B")) +
  labs(x = NULL, y = "Mean Collisions per LA-Month",
       title = "A. Total Collisions") +
  theme_apep

# Panel B: KSI
p1b <- ggplot(country_means, aes(x = date, y = mean_ksi, color = Country)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = treatment_date, linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("England" = "#2166AC", "Wales" = "#B2182B")) +
  labs(x = NULL, y = "Mean KSI per LA-Month",
       title = "B. Killed or Seriously Injured") +
  theme_apep

# Panel C: Pedestrian KSI
p1c <- ggplot(country_means, aes(x = date, y = mean_ped_ksi, color = Country)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = treatment_date, linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("England" = "#2166AC", "Wales" = "#B2182B")) +
  labs(x = NULL, y = "Mean Pedestrian KSI per LA-Month",
       title = "C. Pedestrian KSI") +
  theme_apep

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  fig1 <- p1a / p1b / p1c + plot_layout(guides = "collect") &
    theme(legend.position = "bottom")
  ggsave(file.path(fig_dir, "fig1_parallel_trends.pdf"), fig1,
         width = 7, height = 9)
} else {
  ggsave(file.path(fig_dir, "fig1a_parallel_trends_collisions.pdf"), p1a,
         width = 7, height = 3.5)
  ggsave(file.path(fig_dir, "fig1b_parallel_trends_ksi.pdf"), p1b,
         width = 7, height = 3.5)
  ggsave(file.path(fig_dir, "fig1c_parallel_trends_pedksi.pdf"), p1c,
         width = 7, height = 3.5)
}

## ==================================================================
## FIGURE 2: Event Study — KSI
## ==================================================================
cat("Generating Figure 2: Event Study KSI\n")

es_coefs_ksi <- as.data.frame(summary(es_ksi)$coeftable)
es_coefs_ksi$term <- rownames(es_coefs_ksi)
es_coefs_ksi$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_coefs_ksi$term))

# Add reference period
ref_row <- data.frame(Estimate = 0, `Std. Error` = 0, `t value` = NA,
                      `Pr(>|t|)` = NA, term = "ref", rel_month = -1,
                      check.names = FALSE)
es_coefs_ksi <- rbind(es_coefs_ksi, ref_row)
es_coefs_ksi <- es_coefs_ksi[order(es_coefs_ksi$rel_month), ]
es_coefs_ksi$ci_lo <- es_coefs_ksi$Estimate - 1.96 * es_coefs_ksi$`Std. Error`
es_coefs_ksi$ci_hi <- es_coefs_ksi$Estimate + 1.96 * es_coefs_ksi$`Std. Error`

p2 <- ggplot(es_coefs_ksi, aes(x = rel_month, y = Estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#2166AC") +
  geom_point(size = 1.5, color = "#2166AC") +
  geom_line(color = "#2166AC", linewidth = 0.5) +
  labs(x = "Months Relative to September 2023",
       y = "Coefficient (KSI per LA-Month)",
       title = "Event Study: KSI (Killed or Seriously Injured)") +
  theme_apep +
  annotate("text", x = -12, y = max(es_coefs_ksi$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", hjust = 0.5, size = 3, color = "grey50") +
  annotate("text", x = 8, y = max(es_coefs_ksi$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-treatment", hjust = 0.5, size = 3, color = "grey50")

ggsave(file.path(fig_dir, "fig2_eventstudy_ksi.pdf"), p2,
       width = 7, height = 4.5, )

## ==================================================================
## FIGURE 3: Event Study — Pedestrian KSI
## ==================================================================
cat("Generating Figure 3: Event Study Pedestrian KSI\n")

es_coefs_ped <- as.data.frame(summary(es_ped)$coeftable)
es_coefs_ped$term <- rownames(es_coefs_ped)
es_coefs_ped$rel_month <- as.integer(gsub(".*::(-?\\d+):.*", "\\1", es_coefs_ped$term))

ref_row_ped <- data.frame(Estimate = 0, `Std. Error` = 0, `t value` = NA,
                          `Pr(>|t|)` = NA, term = "ref", rel_month = -1,
                          check.names = FALSE)
es_coefs_ped <- rbind(es_coefs_ped, ref_row_ped)
es_coefs_ped <- es_coefs_ped[order(es_coefs_ped$rel_month), ]
es_coefs_ped$ci_lo <- es_coefs_ped$Estimate - 1.96 * es_coefs_ped$`Std. Error`
es_coefs_ped$ci_hi <- es_coefs_ped$Estimate + 1.96 * es_coefs_ped$`Std. Error`

p3 <- ggplot(es_coefs_ped, aes(x = rel_month, y = Estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#B2182B") +
  geom_point(size = 1.5, color = "#B2182B") +
  geom_line(color = "#B2182B", linewidth = 0.5) +
  labs(x = "Months Relative to September 2023",
       y = "Coefficient (Pedestrian KSI per LA-Month)",
       title = "Event Study: Pedestrian KSI") +
  theme_apep +
  annotate("text", x = -12, y = max(es_coefs_ped$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", hjust = 0.5, size = 3, color = "grey50") +
  annotate("text", x = 8, y = max(es_coefs_ped$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-treatment", hjust = 0.5, size = 3, color = "grey50")

ggsave(file.path(fig_dir, "fig3_eventstudy_pedksi.pdf"), p3,
       width = 7, height = 4.5, )

cat("\nAll figures generated successfully.\n")
cat("Files:", paste(list.files(fig_dir), collapse = ", "), "\n")
