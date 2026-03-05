## ============================================================================
## 05_figures.R — All Figures
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel_clean <- panel[!is.na(bite_kaitz) & !is.na(closure_rate)]
panel_clean[, la_id := as.integer(factor(la_name))]

## ---- Figure 1: NLW Schedule ----
cat("=== Figure 1: NLW Schedule ===\n")

nlw <- fread(file.path(data_dir, "nlw_schedule.csv"))
nlw_plot <- nlw[year >= 2012 & year <= 2019 & !is.na(nlw_rate)]

fig1 <- ggplot(nlw_plot, aes(x = year, y = nlw_rate)) +
  geom_line(linewidth = 1.2, color = "#2166AC") +
  geom_point(size = 3, color = "#2166AC") +
  geom_vline(xintercept = 2015.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2015.3, y = max(nlw_plot$nlw_rate) * 0.95,
           label = "NLW\nintroduced", hjust = 1, size = 3.5, color = "grey40") +
  scale_y_continuous(labels = scales::dollar_format(prefix = "\u00A3")) +
  labs(x = "Year", y = "National Living Wage (\u00A3/hour)",
       title = "National Living Wage Rate, 2016-2019") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "fig1_nlw_schedule.pdf"), fig1, width = 7, height = 4)

## ---- Figure 2: Bite Distribution ----
cat("=== Figure 2: Bite Distribution ===\n")

bite_data <- unique(panel_clean[year == 2015, .(la_name, bite_kaitz, median_wage_2015)])

fig2 <- ggplot(bite_data, aes(x = bite_kaitz)) +
  geom_histogram(bins = 25, fill = "#4393C3", color = "white", alpha = 0.8) +
  geom_vline(xintercept = median(bite_data$bite_kaitz), linetype = "dashed", color = "#B2182B") +
  annotate("text", x = median(bite_data$bite_kaitz) + 0.02, y = Inf,
           label = "Median", vjust = 2, hjust = 0, color = "#B2182B", size = 3.5) +
  labs(x = "Kaitz Index (NLW / Median Hourly Wage, 2015)",
       y = "Number of Local Authorities",
       title = "Distribution of NLW Bite Across English Local Authorities") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "fig2_bite_distribution.pdf"), fig2, width = 7, height = 4.5)

## ---- Figure 3: Event Study — Closure Rate ----
cat("=== Figure 3: Event Study ===\n")

es_model <- feols(closure_rate ~ i(year, bite_kaitz, ref = 2015) | la_id + year,
                  data = panel_clean, cluster = ~la_id)

es_df <- data.table(
  year = as.integer(gsub("year::(\\d+):bite_kaitz", "\\1", names(coef(es_model)))),
  coef = coef(es_model),
  se = se(es_model)
)
# Add reference year
es_df <- rbind(es_df, data.table(year = 2015, coef = 0, se = 0))
es_df <- es_df[order(year)]
es_df[, ci_lo := coef - 1.96 * se]
es_df[, ci_hi := coef + 1.96 * se]

fig3 <- ggplot(es_df, aes(x = year, y = coef)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = 2015.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#2166AC") +
  geom_line(linewidth = 0.8, color = "#2166AC") +
  geom_point(size = 2.5, color = "#2166AC") +
  annotate("text", x = 2015.3, y = max(es_df$ci_hi) * 0.9,
           label = "NLW\nintroduced", hjust = 1, size = 3, color = "grey40") +
  scale_x_continuous(breaks = 2012:2019) +
  labs(x = "Year", y = "Coefficient (Bite \u00D7 Year)",
       title = "Event Study: NLW Bite and Care Home Closure Rate",
       subtitle = "Reference year: 2015. 95% CIs with LA-clustered standard errors.") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "fig3_event_study_closures.pdf"), fig3, width = 8, height = 5)

## ---- Figure 4: First Stage Event Study ----
cat("=== Figure 4: First Stage ===\n")

fs_event <- tryCatch(readRDS(file.path(data_dir, "first_stage_event.rds")), error = function(e) NULL)

if (!is.null(fs_event)) {
  fs_df <- data.table(
    year = as.integer(gsub("year::(\\d+):bite_kaitz", "\\1", names(coef(fs_event)))),
    coef = coef(fs_event),
    se = se(fs_event)
  )
  fs_df <- rbind(fs_df, data.table(year = 2015, coef = 0, se = 0))
  fs_df <- fs_df[order(year)]
  fs_df[, ci_lo := coef - 1.96 * se]
  fs_df[, ci_hi := coef + 1.96 * se]

  fig4 <- ggplot(fs_df, aes(x = year, y = coef)) +
    geom_hline(yintercept = 0, color = "grey60") +
    geom_vline(xintercept = 2015.5, linetype = "dashed", color = "grey40") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#B2182B") +
    geom_line(linewidth = 0.8, color = "#B2182B") +
    geom_point(size = 2.5, color = "#B2182B") +
    scale_x_continuous(breaks = 2012:2019) +
    labs(x = "Year", y = "Coefficient (Bite \u00D7 Year)",
         title = "First Stage: NLW Bite and Log Median Hourly Wages",
         subtitle = "Reference year: 2015. Higher bite \u2192 larger wage growth post-2016.") +
    theme(plot.title = element_text(face = "bold"))

  ggsave(file.path(fig_dir, "fig4_first_stage_event.pdf"), fig4, width = 8, height = 5)
}

## ---- Figure 5: Closure Trends by Bite Tercile ----
cat("=== Figure 5: Trends by Bite Tercile ===\n")

bite_terciles <- quantile(panel_clean[year == 2015]$bite_kaitz, probs = c(1/3, 2/3), na.rm = TRUE)
panel_clean[, bite_group := factor(
  findInterval(bite_kaitz, bite_terciles) + 1L,
  levels = 1:3,
  labels = c("Low bite", "Medium bite", "High bite")
)]

trends <- panel_clean[, .(
  mean_closure = mean(closure_rate, na.rm = TRUE),
  se_closure = sd(closure_rate, na.rm = TRUE) / sqrt(.N)
), by = .(year, bite_group)]

fig5 <- ggplot(trends, aes(x = year, y = mean_closure, color = bite_group, shape = bite_group)) +
  geom_vline(xintercept = 2015.5, linetype = "dashed", color = "grey40") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  geom_ribbon(aes(ymin = mean_closure - 1.96 * se_closure,
                  ymax = mean_closure + 1.96 * se_closure, fill = bite_group),
              alpha = 0.1, color = NA) +
  scale_color_manual(values = c("#4393C3", "#999999", "#D6604D")) +
  scale_fill_manual(values = c("#4393C3", "#999999", "#D6604D")) +
  scale_x_continuous(breaks = 2012:2019) +
  labs(x = "Year", y = "Closure Rate (%)",
       color = "NLW Bite", fill = "NLW Bite", shape = "NLW Bite",
       title = "Care Home Closure Rates by NLW Bite Tercile",
       subtitle = "Closure rate = closures / (stock + closures) \u00D7 100.") +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

ggsave(file.path(fig_dir, "fig5_trends_by_tercile.pdf"), fig5, width = 8, height = 5.5)

## ---- Figure 6: Scatter — Bite vs Closure Change ----
cat("=== Figure 6: Bite vs Closure Change ===\n")

pre_mean <- panel_clean[year < 2016, .(pre_closure = mean(closure_rate, na.rm = TRUE)), by = la_name]
post_mean <- panel_clean[year >= 2016, .(post_closure = mean(closure_rate, na.rm = TRUE)), by = la_name]
change_data <- merge(pre_mean, post_mean, by = "la_name")
change_data[, closure_change := post_closure - pre_closure]

bite_info <- unique(panel_clean[, .(la_name, bite_kaitz)])
change_data <- merge(change_data, bite_info, by = "la_name")

fig6 <- ggplot(change_data, aes(x = bite_kaitz, y = closure_change)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_point(alpha = 0.6, color = "#2166AC", size = 2) +
  geom_smooth(method = "lm", color = "#B2182B", se = TRUE, alpha = 0.15) +
  labs(x = "Kaitz Index (NLW / Median Hourly Wage, 2015)",
       y = "Change in Closure Rate (Post - Pre, pp)",
       title = "NLW Bite and Change in Care Home Closure Rates",
       subtitle = "Each point is one Local Authority. Line: OLS fit with 95% CI.") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "fig6_scatter_bite_closure.pdf"), fig6, width = 7, height = 5)

## ---- Figure 7: Additional Outcomes Event Study ----
cat("=== Figure 7: Net Change Event Study ===\n")

es_net <- feols(net_change ~ i(year, bite_kaitz, ref = 2015) | la_id + year,
                data = panel_clean, cluster = ~la_id)

net_df <- data.table(
  year = as.integer(gsub("year::(\\d+):bite_kaitz", "\\1", names(coef(es_net)))),
  coef = coef(es_net),
  se = se(es_net)
)
net_df <- rbind(net_df, data.table(year = 2015, coef = 0, se = 0))
net_df <- net_df[order(year)]
net_df[, ci_lo := coef - 1.96 * se]
net_df[, ci_hi := coef + 1.96 * se]

fig7 <- ggplot(net_df, aes(x = year, y = coef)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = 2015.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#D6604D") +
  geom_line(linewidth = 0.8, color = "#D6604D") +
  geom_point(size = 2.5, color = "#D6604D") +
  scale_x_continuous(breaks = 2012:2019) +
  labs(x = "Year", y = "Coefficient (Bite \u00D7 Year)",
       title = "Event Study: NLW Bite and Net Change in Care Homes",
       subtitle = "Net change = entries - exits. Reference year: 2015.") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "fig7_event_study_net.pdf"), fig7, width = 8, height = 5)

cat("\nAll figures saved to", fig_dir, "\n")
