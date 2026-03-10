#' 05_figures.R — All figure generation
#' REACH 2018 Deadline and Chemical Industry Restructuring

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
micro_intensity <- fread(paste0(data_dir, "micro_intensity.csv"))

# ===========================================================================
# Figure 1: Micro-firm share distribution across countries
# ===========================================================================
cat("Figure 1: Micro-firm share distribution...\n")

fig1_data <- copy(micro_intensity)
fig1_data <- merge(fig1_data,
  data.table(
    geo = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
            "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
            "PL","PT","RO","SK","SI","ES","SE"),
    country_name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
                     "Denmark","Estonia","Finland","France","Germany","Greece",
                     "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
                     "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
                     "Slovenia","Spain","Sweden")
  ), by = "geo")

fig1_data <- fig1_data[order(micro_share_pre)]
fig1_data[, country_name := factor(country_name, levels = country_name)]

p1 <- ggplot(fig1_data, aes(x = country_name, y = micro_share_pre)) +
  geom_col(aes(fill = micro_share_pre), width = 0.7) +
  scale_fill_gradient(low = apep_colors["control"], high = apep_colors["treated"],
                      guide = "none") +
  scale_y_continuous(labels = scales::percent_format(), expand = c(0, 0),
                     limits = c(0, 1)) +
  geom_hline(yintercept = median(fig1_data$micro_share_pre, na.rm = TRUE),
             linetype = "dashed", color = "grey40") +
  annotate("text", x = 3, y = median(fig1_data$micro_share_pre) + 0.03,
           label = "Median", color = "grey40", size = 3) +
  coord_flip() +
  labs(
    title = "Pre-Treatment Micro-Firm Share in Chemical Manufacturing (C20)",
    subtitle = "Average share of enterprises with <10 employees, 2014-2017",
    x = NULL,
    y = "Share of micro-firms (<10 employees)",
    caption = "Source: Eurostat SBS by size class (sbs_sc_ind_r2). EU member states with available data."
  )

ggsave(paste0(fig_dir, "fig1_micro_share.pdf"), p1, width = 8, height = 7)
ggsave(paste0(fig_dir, "fig1_micro_share.png"), p1, width = 8, height = 7, dpi = 300)

# ===========================================================================
# Figure 2: Event study — DDD coefficients
# ===========================================================================
cat("Figure 2: Event study...\n")

es_data <- fread(paste0(data_dir, "event_study_ddd.csv"))
es_data <- es_data[!is.na(year)]

p2 <- ggplot(es_data, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = apep_colors["treated"],
             linewidth = 0.8) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15,
              fill = apep_colors["dark"]) +
  geom_point(size = 2.5, color = apep_colors["dark"]) +
  geom_line(color = apep_colors["dark"], linewidth = 0.7) +
  annotate("text", x = 2012, y = max(es_data$ci_upper, na.rm = TRUE) * 0.9,
           label = "2013 deadline\n(large firms)", color = "grey50", size = 2.8,
           hjust = 0) +
  annotate("segment", x = 2013, xend = 2013,
           y = min(es_data$ci_lower, na.rm = TRUE) * 0.5,
           yend = max(es_data$ci_upper, na.rm = TRUE) * 0.5,
           linetype = "dotted", color = "grey50") +
  annotate("text", x = 2018.5, y = min(es_data$ci_lower, na.rm = TRUE) * 0.9,
           label = "2018 deadline\n(all substances \u22651t)", color = apep_colors["treated"],
           size = 2.8, hjust = 0) +
  scale_x_continuous(breaks = seq(2008, 2021, 1)) +
  labs(
    title = "Event Study: Triple-Difference Coefficients",
    subtitle = expression(paste("Year-by-year ", hat(beta), " for C20 ", times, " micro-share interaction (2017 = reference)")),
    x = "Year",
    y = "Coefficient estimate",
    caption = "Source: Eurostat SBS. 95% confidence intervals from country-clustered standard errors."
  )

ggsave(paste0(fig_dir, "fig2_event_study.pdf"), p2, width = 9, height = 5.5)
ggsave(paste0(fig_dir, "fig2_event_study.png"), p2, width = 9, height = 5.5, dpi = 300)

# ===========================================================================
# Figure 3: Raw trends — chemicals vs controls by micro-share group
# ===========================================================================
cat("Figure 3: Raw trends...\n")

fig3_data <- panel[, .(
  mean_ent = mean(enterprises, na.rm = TRUE)
), by = .(year, chem, high_micro)]

fig3_data[, `:=`(
  sector = ifelse(chem == 1, "Chemicals (C20)", "Controls (C22-C25)"),
  intensity = ifelse(high_micro == 1, "High micro-share", "Low micro-share")
)]

p3 <- ggplot(fig3_data, aes(x = year, y = mean_ent, color = sector, linetype = intensity)) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey70") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  scale_color_manual(values = c("Chemicals (C20)" = apep_colors["treated"],
                                "Controls (C22-C25)" = apep_colors["control"])) +
  scale_linetype_manual(values = c("High micro-share" = "solid",
                                    "Low micro-share" = "dashed")) +
  scale_x_continuous(breaks = seq(2008, 2021, 2)) +
  labs(
    title = "Average Enterprise Counts by Sector and Micro-Firm Intensity",
    subtitle = "Countries split at median pre-treatment micro-firm share in C20",
    x = "Year",
    y = "Average number of enterprises",
    color = "Sector",
    linetype = "Country group",
    caption = "Source: Eurostat SBS (sbs_na_ind_r2). Vertical line marks REACH 2018 deadline."
  )

ggsave(paste0(fig_dir, "fig3_raw_trends.pdf"), p3, width = 9, height = 5.5)
ggsave(paste0(fig_dir, "fig3_raw_trends.png"), p3, width = 9, height = 5.5, dpi = 300)

# ===========================================================================
# Figure 4: Leave-one-out stability
# ===========================================================================
cat("Figure 4: Leave-one-out...\n")

loo_data <- fread(paste0(data_dir, "robustness_loo.csv"))
baseline_coef <- fread(paste0(data_dir, "main_results.csv"))[
  model == "DDD (continuous)" & outcome == "Log Enterprises", coef]

loo_data <- loo_data[order(coef)]
loo_data[, dropped := factor(dropped, levels = dropped)]

p4 <- ggplot(loo_data, aes(x = dropped, y = coef)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_hline(yintercept = baseline_coef, linetype = "dashed",
             color = apep_colors["highlight"]) +
  geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  color = apep_colors["dark"], size = 0.4) +
  coord_flip() +
  labs(
    title = "Leave-One-Country-Out: DDD Coefficient Stability",
    subtitle = "Each point drops one country; dashed line = baseline estimate",
    x = "Country dropped",
    y = "DDD coefficient (log enterprises)",
    caption = "Source: Eurostat SBS. 95% CIs from country-clustered SEs."
  )

ggsave(paste0(fig_dir, "fig4_loo.pdf"), p4, width = 8, height = 6)
ggsave(paste0(fig_dir, "fig4_loo.png"), p4, width = 8, height = 6, dpi = 300)

# ===========================================================================
# Figure 5: Randomization inference distribution
# ===========================================================================
cat("Figure 5: RI distribution...\n")

ri_dist <- fread(paste0(data_dir, "ri_distribution.csv"))

p5 <- ggplot(ri_dist, aes(x = coef)) +
  geom_histogram(bins = 40, fill = "grey70", color = "white") +
  geom_vline(xintercept = baseline_coef, color = apep_colors["treated"],
             linewidth = 1.2) +
  annotate("text", x = baseline_coef, y = Inf, label = "Observed",
           color = apep_colors["treated"], vjust = 2, hjust = -0.1, size = 3.5) +
  labs(
    title = "Randomization Inference: Distribution of Placebo DDD Coefficients",
    subtitle = "1,000 permutations of country-level micro-firm shares",
    x = "Placebo DDD coefficient",
    y = "Count",
    caption = "Source: Eurostat SBS. Red line = observed coefficient from main specification."
  )

ggsave(paste0(fig_dir, "fig5_ri.pdf"), p5, width = 7, height = 4.5)
ggsave(paste0(fig_dir, "fig5_ri.png"), p5, width = 7, height = 4.5, dpi = 300)

# ===========================================================================
# Figure 6: Size-class heterogeneity
# ===========================================================================
cat("Figure 6: Size-class heterogeneity...\n")

sc_data <- fread(paste0(data_dir, "robustness_size_class.csv"))
sc_data <- sc_data[!is.na(coef)]

# Clean up size class labels
sc_labels <- c(
  "0-9" = "<10 employees",
  "10-19" = "10-19",
  "20-49" = "20-49",
  "50-249" = "50-249",
  "GE250" = "250+"
)
sc_data[, size_label := sc_labels[size_class]]
sc_data <- sc_data[!is.na(size_label)]
sc_data[, size_label := factor(size_label, levels = rev(sc_labels))]

p6 <- ggplot(sc_data, aes(x = size_label, y = coef)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  color = apep_colors["dark"], size = 0.6) +
  coord_flip() +
  labs(
    title = "DDD Coefficients by Firm Size Class",
    subtitle = "Effect of REACH 2018 by pre-treatment micro-firm intensity",
    x = "Firm size class",
    y = "DDD coefficient",
    caption = "Source: Eurostat SBS by size class (sbs_sc_ind_r2)."
  )

ggsave(paste0(fig_dir, "fig6_size_class.pdf"), p6, width = 7, height = 4.5)
ggsave(paste0(fig_dir, "fig6_size_class.png"), p6, width = 7, height = 4.5, dpi = 300)

cat("\nAll figures saved to", fig_dir, "\n")
