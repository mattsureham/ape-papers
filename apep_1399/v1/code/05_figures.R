# 05_figures.R — Generate all figures (≥5 required)
# apep_1399: The Bedrock Dose

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# Load analysis data
df <- fread(file.path(data_dir, "analysis_panel.csv"),
            colClasses = c(state_fips = "character"))

# Load saved models
models <- readRDS(file.path(data_dir, "models.rds"))

# ============================================================================
# Figure 1: Map of Geological Radon Potential across the US
# ============================================================================
cat("Figure 1: GRP Map\n")

grp_shp <- st_read(file.path(data_dir, "usradon", "conusgrp_NAD83.shp"), quiet = TRUE)
sf_use_s2(FALSE)

fig1 <- ggplot(grp_shp) +
  geom_sf(aes(fill = factor(GRP)), color = NA, linewidth = 0.05) +
  scale_fill_manual(
    values = c("1" = "#2166ac", "2" = "#f4a582", "3" = "#b2182b"),
    labels = c("1" = "Low", "2" = "Moderate", "3" = "High"),
    name = "Geologic Radon\nPotential"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank()
  ) +
  labs(title = "Geological Radon Potential of the Contiguous United States",
       subtitle = "Source: USGS Open-File Report 93-292 (926 geological provinces)")

ggsave(file.path(fig_dir, "fig1_grp_map.pdf"), fig1, width = 10, height = 6)

# ============================================================================
# Figure 2: Event Study — Cancer AADR (CS Dynamic ATTs)
# ============================================================================
cat("Figure 2: Event Study\n")

if (!is.null(models$cs_dyn)) {
  cs_dyn <- models$cs_dyn
  es_data <- data.table(
    event_time = cs_dyn$egt,
    att = cs_dyn$att.egt,
    se = cs_dyn$se.egt
  )
  es_data[, `:=`(lower = att - 1.96 * se, upper = att + 1.96 * se)]
  es_data <- es_data[event_time >= -12 & event_time <= 10]

  fig2 <- ggplot(es_data, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_vline(xintercept = -0.5, linetype = "dashed", alpha = 0.4) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, fill = "#b2182b") +
    geom_line(color = "#b2182b", linewidth = 0.8) +
    geom_point(color = "#b2182b", size = 2) +
    labs(x = "Years Since RRNC Adoption",
         y = "ATT: Cancer Mortality (AADR)",
         title = "Dynamic Treatment Effects of RRNC Adoption",
         subtitle = "Callaway-Sant'Anna estimator, never-treated control group") +
    annotate("text", x = -6, y = max(es_data$upper) * 0.9,
             label = "Pre-treatment", hjust = 0.5, size = 3, color = "gray50") +
    annotate("text", x = 4, y = max(es_data$upper) * 0.9,
             label = "Post-treatment", hjust = 0.5, size = 3, color = "gray50")
} else {
  # Fallback: TWFE event study
  m_es <- models$event_study
  es_data <- data.table(
    bin = names(coef(m_es)),
    coef = coef(m_es),
    se = se(m_es)
  )
  es_data[, `:=`(lower = coef - 1.96 * se, upper = coef + 1.96 * se)]
  es_data[, event_time := as.numeric(gsub(".*::", "", bin))]

  fig2 <- ggplot(es_data, aes(x = event_time, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2) +
    geom_line() + geom_point()
}

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 5.5)

# ============================================================================
# Figure 3: Raw Trends — Cancer AADR by Treatment Status
# ============================================================================
cat("Figure 3: Raw Trends\n")

trends <- df[, .(
  cancer_aadr = weighted.mean(cancer_aadr, population, na.rm = TRUE)
), by = .(year, group = fcase(
  treated_state == 1 & high_grp_state == 1, "RRNC × High GRP",
  treated_state == 1 & high_grp_state == 0, "RRNC × Low GRP",
  treated_state == 0, "Non-RRNC States"
))]

fig3 <- ggplot(trends[!is.na(group)], aes(x = year, y = cancer_aadr, color = group)) +
  geom_point(size = 2) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c(
    "RRNC × High GRP" = "#b2182b",
    "RRNC × Low GRP" = "#f4a582",
    "Non-RRNC States" = "#2166ac"
  )) +
  labs(x = "Year", y = "Age-Adjusted Cancer Death Rate\n(per 100,000)",
       title = "Cancer Mortality Trends by RRNC Status and Geology",
       color = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig3_raw_trends.pdf"), fig3, width = 8, height = 5.5)

# ============================================================================
# Figure 4: Placebo Outcomes — Non-Cancer Causes
# ============================================================================
cat("Figure 4: Placebo Outcomes\n")

placebo_data <- df[, .(
  Cancer = weighted.mean(cancer_aadr, population, na.rm = TRUE),
  `Heart Disease` = weighted.mean(heart_aadr, population, na.rm = TRUE),
  CLRD = weighted.mean(clrd_aadr, population, na.rm = TRUE),
  Stroke = weighted.mean(stroke_aadr, population, na.rm = TRUE)
), by = .(year, treated = factor(treated_state, labels = c("Non-RRNC", "RRNC")))]

placebo_long <- melt(placebo_data, id.vars = c("year", "treated"),
                      variable.name = "cause", value.name = "aadr")

fig4 <- ggplot(placebo_long[!is.na(aadr)],
               aes(x = year, y = aadr, color = treated, linetype = treated)) +
  geom_point(size = 1.5) +
  geom_line(linewidth = 0.6) +
  facet_wrap(~cause, scales = "free_y", ncol = 2) +
  scale_color_manual(values = c("Non-RRNC" = "#2166ac", "RRNC" = "#b2182b")) +
  scale_linetype_manual(values = c("Non-RRNC" = "solid", "RRNC" = "dashed")) +
  labs(x = "Year", y = "Age-Adjusted Death Rate (per 100,000)",
       title = "Mortality Trends: Cancer vs. Placebo Causes",
       subtitle = "RRNC should affect cancer only; similar trends for placebo causes support identification",
       color = NULL, linetype = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig4_placebo_outcomes.pdf"), fig4, width = 9, height = 6)

# ============================================================================
# Figure 5: State GRP Distribution
# ============================================================================
cat("Figure 5: GRP Distribution\n")

state_grp <- fread(file.path(data_dir, "state_grp.csv"),
                   colClasses = c(state_fips = "character"))
rrnc <- fread(file.path(data_dir, "rrnc_adoption.csv"))
rrnc[, state_fips := sprintf("%02d", as.integer(state_fips))]

state_grp <- merge(state_grp, rrnc[, .(state_fips, rrnc_year)],
                   by = "state_fips", all.x = TRUE)
state_grp[is.na(rrnc_year), rrnc_year := 9999]
state_grp[, treated := factor(ifelse(rrnc_year < 9999, "RRNC State", "Non-RRNC State"))]

fig5 <- ggplot(state_grp, aes(x = high_grp_share, fill = treated)) +
  geom_histogram(bins = 20, alpha = 0.7, position = "identity") +
  scale_fill_manual(values = c("RRNC State" = "#b2182b", "Non-RRNC State" = "#2166ac")) +
  geom_vline(xintercept = 0.5, linetype = "dashed", alpha = 0.5) +
  labs(x = "Share of Counties with Moderate/High Radon Potential",
       y = "Number of States",
       title = "Distribution of Geological Radon Exposure by RRNC Status",
       subtitle = "Dashed line: threshold for 'High GRP State' classification",
       fill = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig5_grp_distribution.pdf"), fig5, width = 7, height = 5)

# ============================================================================
# Figure 6: Coefficient Plot — Main vs Placebo
# ============================================================================
cat("Figure 6: Coefficient Plot\n")

coef_data <- data.table(
  outcome = c("Cancer", "Heart Disease", "CLRD", "Stroke", "Diabetes"),
  estimate = c(
    coef(models$triple_diff)["treat_x_grp"],
    coef(models$placebo_heart)["treat_x_grp"],
    coef(models$placebo_clrd)["treat_x_grp"],
    coef(models$placebo_stroke)["treat_x_grp"],
    coef(models$placebo_diabetes)["treat_x_grp"]
  ),
  se = c(
    se(models$triple_diff)["treat_x_grp"],
    se(models$placebo_heart)["treat_x_grp"],
    se(models$placebo_clrd)["treat_x_grp"],
    se(models$placebo_stroke)["treat_x_grp"],
    se(models$placebo_diabetes)["treat_x_grp"]
  )
)
coef_data[, `:=`(lower = estimate - 1.96 * se, upper = estimate + 1.96 * se)]
coef_data[, outcome := factor(outcome, levels = rev(outcome))]
coef_data[, is_primary := outcome == "Cancer"]

fig6 <- ggplot(coef_data, aes(x = estimate, y = outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_point(aes(color = is_primary), size = 3) +
  geom_errorbarh(aes(xmin = lower, xmax = upper, color = is_primary), height = 0.2) +
  scale_color_manual(values = c("TRUE" = "#b2182b", "FALSE" = "#2166ac"), guide = "none") +
  labs(x = "Coefficient on Post-RRNC × High GRP",
       y = NULL,
       title = "Triple-Difference Estimates: Cancer vs. Placebo Outcomes",
       subtitle = "Cancer (red) should show negative effect; placebos (blue) should show null") +
  theme(panel.grid.major.y = element_blank())

ggsave(file.path(fig_dir, "fig6_coef_plot.pdf"), fig6, width = 8, height = 4.5)

# ============================================================================
# Figure 7: RRNC Adoption Timeline
# ============================================================================
cat("Figure 7: Adoption Timeline\n")

rrnc_full <- fread(file.path(data_dir, "rrnc_adoption.csv"))
rrnc_full[, state_fips := sprintf("%02d", as.integer(state_fips))]
rrnc_full <- merge(rrnc_full, state_grp[, .(state_fips, high_grp_share)],
                   by = "state_fips", all.x = TRUE)

fig7 <- ggplot(rrnc_full, aes(x = rrnc_year, y = reorder(state_name, -rrnc_year))) +
  geom_segment(aes(xend = 2017, yend = state_name), alpha = 0.3, linewidth = 3,
               color = "#f4a582") +
  geom_point(aes(size = high_grp_share), color = "#b2182b") +
  scale_size_continuous(range = c(2, 6), name = "High GRP\nShare") +
  labs(x = "Year of RRNC Adoption", y = NULL,
       title = "Timeline of Radon-Resistant New Construction Code Adoption",
       subtitle = "Point size proportional to state's geological radon potential") +
  scale_x_continuous(breaks = seq(1995, 2021, by = 2)) +
  theme(panel.grid.major.y = element_blank())

ggsave(file.path(fig_dir, "fig7_adoption_timeline.pdf"), fig7, width = 8, height = 5)

# ============================================================================
# Figure 8: Permutation Distribution (if available)
# ============================================================================
cat("Figure 8: Permutation Distribution\n")

perm_file <- file.path(data_dir, "permutation_coeffs.csv")
if (file.exists(perm_file)) {
  perm_coeffs <- fread(perm_file)
  actual_coef <- coef(models$main)["post_rrnc"]
  p_val <- mean(abs(perm_coeffs$coef) >= abs(actual_coef))

  fig8 <- ggplot(perm_coeffs, aes(x = coef)) +
    geom_histogram(bins = 50, fill = "gray70", color = "white") +
    geom_vline(xintercept = actual_coef, color = "#b2182b", linewidth = 1.2) +
    labs(x = "Permuted Coefficient on Post-RRNC",
         y = "Count",
         title = "Permutation Test: Distribution Under the Null",
         subtitle = paste0("Red line = actual estimate. Permutation p-value = ",
                           round(p_val, 3)))

  ggsave(file.path(fig_dir, "fig8_permutation.pdf"), fig8, width = 7, height = 5)
}

cat("\n=== All figures generated ===\n")
cat("Files in figures/:\n")
print(list.files(fig_dir))
