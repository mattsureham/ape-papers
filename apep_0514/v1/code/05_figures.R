##########################################################################
# 05_figures.R — Generate all figures
# Paper: The Price of Pork — France's Dual-Mandate Ban
# apep_0514
##########################################################################

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(paste0(data_dir, "main_results.rds"))
circo <- readRDS(paste0(data_dir, "analysis_panel.rds"))

# ============================================================================
# FIGURE 1: EVENT STUDY — INVESTMENT PER CAPITA
# ============================================================================
cat("=== Figure 1: Event Study — Investment ===\n")

es_data <- iplot(results$es_invest, plot = FALSE)
es_df <- es_data$prms[, c("x", "estimate", "ci_low", "ci_high")]
names(es_df)[1] <- "event_time"

p1 <- ggplot(es_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = apep_colors[1]) +
  geom_point(color = apep_colors[1], size = 2.5) +
  geom_line(color = apep_colors[1], linewidth = 0.6) +
  annotate("text", x = -0.5, y = max(es_df$ci_high) * 0.9,
           label = "Ban effective", hjust = -0.1, size = 3, color = "red") +
  labs(
    title = "Effect of Dual-Mandate Ban on Investment Spending",
    subtitle = "Event study: Cumulard vs non-cumulard constituencies (base year: 2017)",
    x = "Years relative to ban (2018 = 0)",
    y = "Investment per capita (thousands of euros)",
    caption = "Notes: 95% confidence intervals shown. Clustered at constituency level."
  )

ggsave(paste0(fig_dir, "fig1_event_study_investment.pdf"), p1, width = 8, height = 5)
ggsave(paste0(fig_dir, "fig1_event_study_investment.png"), p1, width = 8, height = 5, dpi = 300)
cat("  Saved fig1_event_study_investment\n")

# ============================================================================
# FIGURE 2: EVENT STUDY — EQUIPMENT EXPENDITURE
# ============================================================================
cat("=== Figure 2: Event Study — Equipment ===\n")

es_data2 <- iplot(results$es_equip, plot = FALSE)
es_df2 <- es_data2$prms[, c("x", "estimate", "ci_low", "ci_high")]
names(es_df2)[1] <- "event_time"

p2 <- ggplot(es_df2, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = apep_colors[2]) +
  geom_point(color = apep_colors[2], size = 2.5) +
  geom_line(color = apep_colors[2], linewidth = 0.6) +
  labs(
    title = "Effect of Dual-Mandate Ban on Equipment Expenditure",
    subtitle = "Event study: Cumulard vs non-cumulard constituencies (base year: 2017)",
    x = "Years relative to ban (2018 = 0)",
    y = "Equipment spending per capita (thousands of euros)",
    caption = "Notes: 95% confidence intervals shown. Clustered at constituency level."
  )

ggsave(paste0(fig_dir, "fig2_event_study_equipment.pdf"), p2, width = 8, height = 5)
ggsave(paste0(fig_dir, "fig2_event_study_equipment.png"), p2, width = 8, height = 5, dpi = 300)
cat("  Saved fig2_event_study_equipment\n")

# ============================================================================
# FIGURE 3: EVENT STUDY — STATE GRANTS
# ============================================================================
cat("=== Figure 3: Event Study — Grants ===\n")

es_data3 <- iplot(results$es_grants, plot = FALSE)
es_df3 <- es_data3$prms[, c("x", "estimate", "ci_low", "ci_high")]
names(es_df3)[1] <- "event_time"

p3 <- ggplot(es_df3, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = apep_colors[3]) +
  geom_point(color = apep_colors[3], size = 2.5) +
  geom_line(color = apep_colors[3], linewidth = 0.6) +
  labs(
    title = "Effect of Dual-Mandate Ban on State Grants",
    subtitle = "Event study: Cumulard vs non-cumulard constituencies (base year: 2017)",
    x = "Years relative to ban (2018 = 0)",
    y = "State grants per capita (thousands of euros)",
    caption = "Notes: 95% confidence intervals shown. Clustered at constituency level."
  )

ggsave(paste0(fig_dir, "fig3_event_study_grants.pdf"), p3, width = 8, height = 5)
ggsave(paste0(fig_dir, "fig3_event_study_grants.png"), p3, width = 8, height = 5, dpi = 300)
cat("  Saved fig3_event_study_grants\n")

# ============================================================================
# FIGURE 4: EVENT STUDY — OPERATING EXPENDITURE
# ============================================================================
cat("=== Figure 4: Event Study — Operating Expenditure ===\n")

es_data4 <- iplot(results$es_opex, plot = FALSE)
es_df4 <- es_data4$prms[, c("x", "estimate", "ci_low", "ci_high")]
names(es_df4)[1] <- "event_time"

p4 <- ggplot(es_df4, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = apep_colors[4]) +
  geom_point(color = apep_colors[4], size = 2.5) +
  geom_line(color = apep_colors[4], linewidth = 0.6) +
  labs(
    title = "Effect of Dual-Mandate Ban on Operating Expenditure",
    subtitle = "Event study: Cumulard vs non-cumulard constituencies (base year: 2017)",
    x = "Years relative to ban (2018 = 0)",
    y = "Operating expenditure per capita (thousands of euros)",
    caption = "Notes: 95% confidence intervals shown. Clustered at constituency level."
  )

ggsave(paste0(fig_dir, "fig4_event_study_opex.pdf"), p4, width = 8, height = 5)
ggsave(paste0(fig_dir, "fig4_event_study_opex.png"), p4, width = 8, height = 5, dpi = 300)
cat("  Saved fig4_event_study_opex\n")

# ============================================================================
# FIGURE 5: PARALLEL TRENDS — RAW MEANS
# ============================================================================
cat("=== Figure 5: Parallel Trends ===\n")

trends <- circo %>%
  group_by(year, is_cumulard_maire) %>%
  summarize(
    mean_invest = mean(invest_pc, na.rm = TRUE),
    mean_equip = mean(equip_pc, na.rm = TRUE),
    mean_dotation = mean(dotation_pc, na.rm = TRUE),
    mean_charges = mean(charges_pc, na.rm = TRUE),
    se_invest = sd(invest_pc, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(group = ifelse(is_cumulard_maire == 1, "Cumulard", "Non-cumulard"))

p5a <- ggplot(trends, aes(x = year, y = mean_invest, color = group, linetype = group)) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey50", alpha = 0.6) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Cumulard" = apep_colors[1], "Non-cumulard" = apep_colors[2])) +
  labs(
    title = "Investment Spending per Capita: Raw Trends",
    x = "Year", y = "Investment per capita (thousands of euros)",
    color = "Group", linetype = "Group",
    caption = "Notes: Vertical dashed line marks the 2017 ban. Constituency-level averages."
  )

p5b <- ggplot(trends, aes(x = year, y = mean_equip, color = group, linetype = group)) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey50", alpha = 0.6) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Cumulard" = apep_colors[1], "Non-cumulard" = apep_colors[2])) +
  labs(
    title = "Equipment Spending per Capita: Raw Trends",
    x = "Year", y = "Equipment per capita (thousands of euros)",
    color = "Group", linetype = "Group"
  )

p5c <- ggplot(trends, aes(x = year, y = mean_dotation, color = group, linetype = group)) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey50", alpha = 0.6) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Cumulard" = apep_colors[1], "Non-cumulard" = apep_colors[2])) +
  labs(
    title = "State Grants per Capita: Raw Trends",
    x = "Year", y = "State grants per capita (thousands of euros)",
    color = "Group", linetype = "Group"
  )

p5 <- (p5a + p5b) / (p5c + plot_spacer()) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(paste0(fig_dir, "fig5_parallel_trends.pdf"), p5, width = 12, height = 8)
ggsave(paste0(fig_dir, "fig5_parallel_trends.png"), p5, width = 12, height = 8, dpi = 300)
cat("  Saved fig5_parallel_trends\n")

# ============================================================================
# FIGURE 6: TREATMENT MAP — CUMULARD CONSTITUENCIES
# ============================================================================
cat("=== Figure 6: Treatment Distribution ===\n")

treat <- fread(paste0(data_dir, "constituency_treatment.csv"), encoding = "UTF-8")
dept_treat <- treat %>%
  mutate(code_dep = sprintf("%02s", num_deptmt)) %>%
  group_by(code_dep) %>%
  summarize(
    n_circos = n(),
    n_cumulard = sum(is_cumulard_maire),
    pct_cumulard = n_cumulard / n_circos * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(pct_cumulard))

p6 <- ggplot(dept_treat, aes(x = reorder(code_dep, pct_cumulard), y = pct_cumulard)) +
  geom_col(fill = apep_colors[1], alpha = 0.7) +
  geom_hline(yintercept = mean(dept_treat$pct_cumulard), linetype = "dashed", color = "red") +
  coord_flip() +
  labs(
    title = "Share of Cumulard Deputies by Département",
    x = "Département code", y = "% of constituencies with cumulard deputy",
    caption = "Notes: Red line = national average. Based on XIV legislature (2012-2017)."
  ) +
  theme(axis.text.y = element_text(size = 5))

ggsave(paste0(fig_dir, "fig6_treatment_distribution.pdf"), p6, width = 7, height = 12)
ggsave(paste0(fig_dir, "fig6_treatment_distribution.png"), p6, width = 7, height = 12, dpi = 300)
cat("  Saved fig6_treatment_distribution\n")

# ============================================================================
# FIGURE 7: COMBINED EVENT STUDY PANEL
# ============================================================================
cat("=== Figure 7: Combined Event Study Panel ===\n")

all_es <- bind_rows(
  es_df %>% mutate(outcome = "Investment"),
  es_df2 %>% mutate(outcome = "Equipment"),
  es_df3 %>% mutate(outcome = "State Grants"),
  es_df4 %>% mutate(outcome = "Operating Expenditure")
)

p7 <- ggplot(all_es, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.4) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = apep_colors[1]) +
  geom_point(color = apep_colors[1], size = 2) +
  geom_line(color = apep_colors[1], linewidth = 0.5) +
  facet_wrap(~outcome, scales = "free_y", ncol = 2) +
  labs(
    title = "Effect of Dual-Mandate Ban on Commune Fiscal Outcomes",
    subtitle = "Event study estimates (base year: 2017)",
    x = "Years relative to ban (2018 = 0)",
    y = "Thousands of euros per capita",
    caption = "Notes: 95% confidence intervals. Standard errors clustered at constituency level."
  )

ggsave(paste0(fig_dir, "fig7_combined_event_study.pdf"), p7, width = 10, height = 7)
ggsave(paste0(fig_dir, "fig7_combined_event_study.png"), p7, width = 10, height = 7, dpi = 300)
cat("  Saved fig7_combined_event_study\n")

cat("\n=== 05_figures.R complete ===\n")
