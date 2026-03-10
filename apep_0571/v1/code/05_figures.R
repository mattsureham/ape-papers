## =============================================================================
## 05_figures.R — All figures
## apep_0571: Voting reform and public safety in Chile
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
es_data <- fread(file.path(data_dir, "event_study_data.csv"))
main_results <- fread(file.path(data_dir, "main_results.csv"))
turnout <- fread(file.path(data_dir, "turnout_merged.csv"))
ri_data <- fread(file.path(data_dir, "ri_permutations.csv"))

## ===========================================================================
## Figure 1: Turnout decline distribution
## ===========================================================================
cat("Figure 1: Turnout decline distribution\n")

p1 <- ggplot(turnout, aes(x = turnout_decline_pct)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(xintercept = mean(turnout$turnout_decline_pct),
             linetype = "dashed", color = "red", linewidth = 0.8) +
  annotate("text", x = mean(turnout$turnout_decline_pct) + 1,
           y = Inf, vjust = 2, hjust = 0,
           label = paste0("Mean = ", round(mean(turnout$turnout_decline_pct), 1), "pp"),
           color = "red", size = 3.5) +
  labs(x = "Turnout Decline (Percentage Points, 2008\u21922012)",
       y = "Number of Comunas",
       title = "Distribution of Turnout Decline Across Chilean Comunas") +
  scale_x_continuous(breaks = seq(15, 60, 5))

ggsave(file.path(fig_dir, "fig1_turnout_decline.pdf"), p1,
       width = 7, height = 4.5)

## ===========================================================================
## Figure 2: Event study — total, discretionary, non-discretionary
## ===========================================================================
cat("Figure 2: Event study\n")

es_plot <- es_data %>%
  mutate(outcome = factor(outcome,
    levels = c("Total crime", "Discretionary crime", "Non-discretionary (placebo)")))

p2 <- ggplot(es_plot, aes(x = year, y = beta, color = outcome, shape = outcome)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 2012, linetype = "dotted", color = "grey70") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  position = position_dodge(width = 0.5), size = 0.4) +
  annotate("text", x = 2012, y = Inf, vjust = 2, label = "Reform",
           color = "grey50", size = 3, fontface = "italic") +
  scale_color_manual(values = c("Total crime" = "black",
                                 "Discretionary crime" = "steelblue",
                                 "Non-discretionary (placebo)" = "firebrick")) +
  labs(x = "Year", y = expression(hat(beta)[k] ~ "(Turnout Decline" %*% "Year)"),
       title = "Event Study: Crime Response to Turnout Decline",
       subtitle = "Coefficients relative to 2011 (base year). 95% CIs, clustered at comuna level.",
       color = NULL, shape = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), p2,
       width = 8, height = 5.5)

## ===========================================================================
## Figure 3: Coefficient plot — crime subtypes
## ===========================================================================
cat("Figure 3: Coefficient plot by crime type\n")

coef_plot <- main_results %>%
  mutate(
    outcome = factor(outcome,
      levels = rev(c("Total crime", "Discretionary", "Non-discretionary",
                     "Robbery", "Burglary", "Drugs", "Domestic violence",
                     "Homicide"))),
    crime_type = factor(type,
      levels = c("aggregate", "discretionary", "placebo"),
      labels = c("Aggregate", "Police-detected", "Non-police-dependent"))
  )

p3 <- ggplot(coef_plot, aes(x = beta, y = outcome, color = crime_type)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lo, xmax = ci_hi), size = 0.5) +
  scale_color_manual(values = c("Aggregate" = "black",
                                 "Police-detected" = "steelblue",
                                 "Non-police-dependent" = "firebrick")) +
  labs(x = expression("Effect per pp of Turnout Decline (" * hat(beta) * ")"),
       y = NULL,
       title = "Effect of Turnout Decline on Crime by Type",
       subtitle = "Police-detected crimes fall; homicide (always reported) rises.",
       color = "Crime category") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig3_coefficient_plot.pdf"), p3,
       width = 7, height = 5)

## ===========================================================================
## Figure 4: Randomization inference
## ===========================================================================
cat("Figure 4: Randomization inference\n")

actual_homicide <- main_results[outcome == "Homicide", beta]
actual_drugs <- main_results[outcome == "Drugs", beta]

p4a <- ggplot(ri_data %>% filter(outcome == "Homicide"),
              aes(x = perm_beta)) +
  geom_histogram(bins = 50, fill = "grey70", color = "white") +
  geom_vline(xintercept = actual_homicide, color = "firebrick",
             linewidth = 1, linetype = "dashed") +
  annotate("text", x = actual_homicide, y = Inf, vjust = 2, hjust = -0.1,
           label = paste0("Actual = ", round(actual_homicide, 4)),
           color = "firebrick", size = 3.5) +
  labs(x = expression(hat(beta)), y = "Count",
       title = "A. Homicide") +
  theme(plot.title = element_text(face = "bold"))

p4b <- ggplot(ri_data %>% filter(outcome == "Drugs"),
              aes(x = perm_beta)) +
  geom_histogram(bins = 50, fill = "grey70", color = "white") +
  geom_vline(xintercept = actual_drugs, color = "steelblue",
             linewidth = 1, linetype = "dashed") +
  annotate("text", x = actual_drugs, y = Inf, vjust = 2, hjust = 1.1,
           label = paste0("Actual = ", round(actual_drugs, 4)),
           color = "steelblue", size = 3.5) +
  labs(x = expression(hat(beta)), y = "Count",
       title = "B. Drug Offenses") +
  theme(plot.title = element_text(face = "bold"))

p4 <- p4a + p4b +
  plot_annotation(
    title = "Randomization Inference: Permuted Treatment Assignment",
    subtitle = "1,000 permutations of turnout decline across comunas. Dashed line = actual estimate."
  )

ggsave(file.path(fig_dir, "fig4_randomization_inference.pdf"), p4,
       width = 10, height = 4.5)

## ===========================================================================
## Figure 5: Binscatter — turnout decline vs. crime change
## ===========================================================================
cat("Figure 5: Binscatter\n")

# Compute pre-post change for each comuna
pre_means <- panel %>%
  filter(period == "pre") %>%
  group_by(comuna_clean) %>%
  summarise(pre_homicide = mean(ln_homicide),
            pre_drugs = mean(ln_drugs),
            pre_discretionary = mean(ln_discretionary),
            .groups = "drop")

post_means <- panel %>%
  filter(period == "post") %>%
  group_by(comuna_clean) %>%
  summarise(post_homicide = mean(ln_homicide),
            post_drugs = mean(ln_drugs),
            post_discretionary = mean(ln_discretionary),
            .groups = "drop")

changes <- pre_means %>%
  inner_join(post_means, by = "comuna_clean") %>%
  left_join(panel %>% distinct(comuna_clean, turnout_decline_pct),
            by = "comuna_clean") %>%
  mutate(d_homicide = post_homicide - pre_homicide,
         d_drugs = post_drugs - pre_drugs,
         d_discretionary = post_discretionary - pre_discretionary)

# Create 20 bins
changes <- changes %>%
  mutate(bin = ntile(turnout_decline_pct, 20))

binned <- changes %>%
  group_by(bin) %>%
  summarise(
    x = mean(turnout_decline_pct),
    homicide = mean(d_homicide),
    drugs = mean(d_drugs),
    n = n(),
    .groups = "drop"
  )

p5a <- ggplot(binned, aes(x = x, y = homicide)) +
  geom_point(size = 2, color = "firebrick") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", alpha = 0.2) +
  labs(x = "Turnout Decline (pp)", y = "\u0394 ln(Homicide)",
       title = "A. Homicide (always detected)") +
  theme(plot.title = element_text(face = "bold"))

p5b <- ggplot(binned, aes(x = x, y = drugs)) +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "steelblue", alpha = 0.2) +
  labs(x = "Turnout Decline (pp)", y = "\u0394 ln(Drug Offenses)",
       title = "B. Drug offenses (police-detected)") +
  theme(plot.title = element_text(face = "bold"))

p5 <- p5a + p5b +
  plot_annotation(
    title = "Binscatter: Turnout Decline vs. Pre-Post Crime Change",
    subtitle = "20 equal-sized bins by turnout decline. Line: OLS fit."
  )

ggsave(file.path(fig_dir, "fig5_binscatter.pdf"), p5,
       width = 10, height = 4.5)

cat("\n=== All figures saved ===\n")
