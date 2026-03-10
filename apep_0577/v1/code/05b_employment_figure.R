#' 05b_employment_figure.R — Employment event study figure

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"

es_emp <- fread(paste0(data_dir, "event_study_employment.csv"))
es_emp <- es_emp[!is.na(year)]

p_emp <- ggplot(es_emp, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = apep_colors["treated"],
             linewidth = 0.8) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15,
              fill = apep_colors["dark"]) +
  geom_point(size = 2.5, color = apep_colors["dark"]) +
  geom_line(color = apep_colors["dark"], linewidth = 0.7) +
  annotate("text", x = 2018.5, y = min(es_emp$ci_lower, na.rm = TRUE) * 0.7,
           label = "2018 deadline", color = apep_colors["treated"],
           size = 3, hjust = 0) +
  scale_x_continuous(breaks = seq(2008, 2020, 1)) +
  labs(
    title = "Event Study: Employment Triple-Difference Coefficients",
    subtitle = expression(paste("Year-by-year ", hat(beta), " for C20 ", times,
                                " micro-share interaction (2017 = reference)")),
    x = "Year",
    y = "Coefficient estimate",
    caption = "Source: Eurostat SBS. 95% confidence intervals from country-clustered standard errors."
  )

ggsave(paste0(fig_dir, "fig_es_employment.pdf"), p_emp, width = 9, height = 5.5)
ggsave(paste0(fig_dir, "fig_es_employment.png"), p_emp, width = 9, height = 5.5, dpi = 300)

cat("Employment event study figure saved.\n")
