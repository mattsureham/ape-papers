# ==============================================================================
# 08_revision_figures.R — Updated figures using CS-DiD subgroup results
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"

# ==============================================================================
# UPDATED FIGURE 5: Partisan + Income + Age heterogeneity (CS-DiD subgroups)
# ==============================================================================

cat("Updating Figure 5: CS-DiD subgroup heterogeneity\n")

# Load CS-DiD subgroup results
party_cs <- fread(file.path(data_dir, "cs_heterogeneity_party.csv"))
age_cs <- fread(file.path(data_dir, "cs_heterogeneity_age.csv"))

# Also load the main CS-DiD ATT for reference
cs_overall <- fread(file.path(data_dir, "cs_overall_att.csv"))

# Combine into one coefficient plot
het_all <- bind_rows(
  cs_overall %>% mutate(subgroup = "Full sample", category = "Overall"),
  party_cs %>% mutate(category = "Party"),
  age_cs %>% mutate(category = "Age")
) %>%
  mutate(
    subgroup = factor(subgroup, levels = rev(c(
      "Full sample",
      "Democrat", "Republican", "Independent",
      "Age 18-29", "Age 30-44", "Age 45-59", "Age 60+"
    ))),
    category = factor(category, levels = c("Overall", "Party", "Age"))
  )

fig5 <- ggplot(het_all, aes(x = att, y = subgroup, color = category)) +
  geom_vline(xintercept = 0, color = "grey50", linetype = "dashed") +
  geom_point(size = 2.5) +
  geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper), height = 0.2, linewidth = 0.5) +
  scale_color_manual(values = c(
    "Overall" = "black",
    "Party" = apep_colors[1],
    "Age" = apep_colors[3]
  )) +
  labs(
    x = "ATT on economic pessimism (1-5 scale)",
    y = "",
    title = "Heterogeneity: CS-DiD Subgroup Estimates",
    subtitle = "Callaway-Sant'Anna ATT estimated separately for each subgroup",
    caption = "Notes: 95% CI. Each estimate from a separate CS-DiD estimation.\nNever-treated control group. Multiplier bootstrap standard errors."
  ) +
  theme_apep() +
  theme(legend.position = "none")

ggsave(file.path(fig_dir, "fig5_heterogeneity_cs.pdf"), fig5, width = 7, height = 5.5)
ggsave(file.path(fig_dir, "fig5_heterogeneity_cs.png"), fig5, width = 7, height = 5.5, dpi = 300)

# Also overwrite the old partisan-only figure for backwards compat
ggsave(file.path(fig_dir, "fig7_partisan_heterogeneity.pdf"), fig5, width = 7, height = 5.5)

cat("Figure 5 updated with CS-DiD subgroup estimates.\n")
cat("=== REVISION FIGURES COMPLETE ===\n")
