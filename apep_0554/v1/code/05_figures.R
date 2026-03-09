## ============================================================
## 05_figures.R — All figure generation
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

source("00_packages.R")

## Load results from CSV (data-first rule)
scm_hours  <- fread(file.path(data_dir, "scm_hours_results.csv"))
scm_tfr    <- fread(file.path(data_dir, "scm_tfr_results.csv"))
kor_vs     <- fread(file.path(data_dir, "korea_vs_oecd.csv"))
kor_ind    <- fread(file.path(data_dir, "korea_industry_panel.csv"))
panel      <- fread(file.path(data_dir, "scm_panel.csv"))

T0 <- 2018

## ============================================================
## Figure 1: Treatment Timing & Policy Design
## ============================================================

treatment_df <- data.table(
  wave = c("Wave 1", "Wave 2", "Wave 3"),
  firm_size = c("300+ employees", "50-299 employees", "5-49 employees"),
  start = as.Date(c("2018-07-01", "2020-01-01", "2021-07-01")),
  enforcement = as.Date(c("2019-03-01", "2020-12-31", "2021-07-01"))
)
treatment_df[, ypos := 3:1]

fig1 <- ggplot(treatment_df) +
  geom_segment(aes(x = start, xend = enforcement, y = ypos, yend = ypos),
               linewidth = 3, color = "#E41A1C") +
  geom_point(aes(x = start, y = ypos), size = 4, color = "#E41A1C") +
  geom_vline(xintercept = as.Date("2020-01-20"), linetype = "dashed",
             color = "grey50", linewidth = 0.5) +
  annotate("text", x = as.Date("2020-02-15"), y = 3.4,
           label = "COVID-19\nfirst case", hjust = 0, size = 3, color = "grey50") +
  scale_y_continuous(breaks = 1:3, labels = rev(treatment_df$firm_size)) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(title = "Staggered Implementation of the 52-Hour Workweek Cap",
       subtitle = "South Korea's 2018 Amendment to the Labor Standards Act",
       x = "", y = "") +
  theme(axis.text.y = element_text(size = 11))

ggsave(file.path(fig_dir, "fig1_treatment_timing.pdf"), fig1,
       width = 8, height = 4)
cat("Figure 1 saved\n")

## ============================================================
## Figure 2: SCM — Average Weekly Hours (First Stage)
## ============================================================

fig2 <- ggplot(scm_hours, aes(x = year)) +
  geom_line(aes(y = actual, color = "South Korea"), linewidth = 1.2) +
  geom_line(aes(y = synthetic, color = "Synthetic Korea"),
            linewidth = 1.2, linetype = "dashed") +
  geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = T0 - 0.3, y = max(scm_hours$actual) + 0.5,
           label = "52-hour cap", hjust = 0, size = 3.5) +
  scale_color_manual(values = c("South Korea" = "#E41A1C",
                                "Synthetic Korea" = "#377EB8")) +
  labs(title = "Average Weekly Hours Worked: South Korea vs. Synthetic Korea",
       subtitle = "First stage: The reform reduced working hours",
       x = "", y = "Average weekly hours", color = "") +
  theme(legend.position = c(0.8, 0.85))

ggsave(file.path(fig_dir, "fig2_scm_hours.pdf"), fig2,
       width = 8, height = 5.5)
cat("Figure 2 saved\n")

## ============================================================
## Figure 3: SCM — Total Fertility Rate (Main Result)
## ============================================================

fig3 <- ggplot(scm_tfr, aes(x = year)) +
  geom_line(aes(y = actual, color = "South Korea"), linewidth = 1.2) +
  geom_line(aes(y = synthetic, color = "Synthetic Korea"),
            linewidth = 1.2, linetype = "dashed") +
  geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = T0 - 0.3, y = max(scm_tfr$actual) + 0.05,
           label = "52-hour cap", hjust = 0, size = 3.5) +
  scale_color_manual(values = c("South Korea" = "#E41A1C",
                                "Synthetic Korea" = "#377EB8")) +
  labs(title = "Total Fertility Rate: South Korea vs. Synthetic Korea",
       subtitle = "Fertility continued to decline despite shorter work hours",
       x = "", y = "Total fertility rate (children per woman)", color = "") +
  theme(legend.position = c(0.8, 0.85))

ggsave(file.path(fig_dir, "fig3_scm_tfr.pdf"), fig3,
       width = 8, height = 5.5)
cat("Figure 3 saved\n")

## ============================================================
## Figure 4: Industry-Level Event Study
## ============================================================

## Recompute event study coefficients from saved data
kor_ind[, event_time := year - T0]
kor_ind[, post := as.integer(year >= T0)]

## Run event study
kor_ind_sub <- kor_ind[!is.na(hours) & !is.na(treatment_intensity) &
                        abs(event_time) <= 5]
kor_ind_sub[, event_time_f := factor(event_time)]
kor_ind_sub[, event_time_f := relevel(event_time_f, ref = "-1")]

es_mod <- fixest::feols(hours ~ i(event_time_f, treatment_intensity, ref = "-1") |
                          industry + year,
                        data = kor_ind_sub, cluster = ~industry)

## Extract coefficients
es_coefs <- data.table(
  event_time = as.integer(levels(kor_ind_sub$event_time_f)),
  coef = 0,
  ci_lo = 0,
  ci_hi = 0
)
es_coefs <- es_coefs[event_time != -1]
nm <- names(coef(es_mod))
for (i in seq_along(nm)) {
  et <- as.integer(sub("event_time_f::(-?\\d+):treatment_intensity", "\\1", nm[i]))
  es_coefs[event_time == et, `:=`(
    coef = coef(es_mod)[i],
    ci_lo = coef(es_mod)[i] - 1.96 * se(es_mod)[i],
    ci_hi = coef(es_mod)[i] + 1.96 * se(es_mod)[i]
  )]
}
## Add reference period
es_coefs <- rbind(data.table(event_time = -1, coef = 0, ci_lo = 0, ci_hi = 0),
                  es_coefs)

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

fig4 <- ggplot(es_coefs, aes(x = event_time, y = coef)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#E41A1C") +
  geom_point(size = 2.5, color = "#E41A1C") +
  geom_line(color = "#E41A1C", linewidth = 0.8) +
  annotate("text", x = -0.3, y = max(es_coefs$ci_hi) + 0.05,
           label = "Wave 1\nenforcement", hjust = 0, size = 3) +
  labs(title = "Industry-Level Event Study: Hours Reduction",
       subtitle = "Effect of baseline overtime intensity on weekly hours (ref: t = -1)",
       x = "Years relative to 52-hour cap (2018)", y = "Coefficient",
       caption = "Notes: Each point shows the interaction of treatment intensity (baseline hours - 40)\nwith year indicators. 95% CIs from industry-clustered SEs.") +
  scale_x_continuous(breaks = -5:5)

ggsave(file.path(fig_dir, "fig4_event_study.pdf"), fig4,
       width = 8, height = 5.5)
cat("Figure 4 saved\n")

## ============================================================
## Figure 5: Korea vs OECD Mean — Dual Panel
## ============================================================

fig5a <- ggplot(kor_vs, aes(x = year)) +
  geom_line(aes(y = kor_hours, color = "South Korea"), linewidth = 1) +
  geom_line(aes(y = oecd_hours, color = "OECD average"), linewidth = 1) +
  geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("South Korea" = "#E41A1C", "OECD average" = "#377EB8")) +
  labs(title = "A. Average Weekly Hours", x = "", y = "Hours/week", color = "") +
  theme(legend.position = c(0.75, 0.85))

fig5b <- ggplot(kor_vs, aes(x = year)) +
  geom_line(aes(y = kor_tfr, color = "South Korea"), linewidth = 1) +
  geom_line(aes(y = oecd_tfr, color = "OECD average"), linewidth = 1) +
  geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("South Korea" = "#E41A1C", "OECD average" = "#377EB8")) +
  labs(title = "B. Total Fertility Rate", x = "", y = "Children per woman", color = "") +
  theme(legend.position = c(0.75, 0.85))

fig5 <- cowplot::plot_grid(fig5a, fig5b, ncol = 2)
ggsave(file.path(fig_dir, "fig5_korea_vs_oecd.pdf"), fig5,
       width = 12, height = 5)
cat("Figure 5 saved\n")

## ============================================================
## Figure 6: Industry Hours Pre vs Post
## ============================================================

ind_pre_post <- kor_ind[, .(pre_hours = mean(hours[year >= 2015 & year <= 2017], na.rm = TRUE),
                             post_hours = mean(hours[year >= 2018 & year <= 2020], na.rm = TRUE)),
                         by = .(industry, industry_name)]
ind_pre_post[, change := post_hours - pre_hours]
ind_pre_post <- ind_pre_post[!is.na(industry_name)]

fig6 <- ggplot(ind_pre_post, aes(x = pre_hours, y = change)) +
  geom_point(size = 3, color = "#E41A1C") +
  geom_smooth(method = "lm", se = TRUE, color = "#377EB8", fill = "#377EB8",
              alpha = 0.2) +
  geom_hline(yintercept = 0, color = "grey60") +
  ggrepel::geom_text_repel(aes(label = industry_name), size = 2.8,
                            max.overlaps = 15) +
  labs(title = "Industries with More Overtime Saw Larger Hours Reductions",
       subtitle = "First stage: Baseline hours (2015-2017) vs. change in hours (2018-2020)",
       x = "Mean weekly hours (2015-2017)", y = "Change in weekly hours (2018-2020 vs. 2015-2017)") +
  theme(plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig6_industry_hours.pdf"), fig6,
       width = 8, height = 6)
cat("Figure 6 saved\n")

## ============================================================
## Figure 7: Hours Bands Over Time (if available)
## ============================================================

if (file.exists(file.path(data_dir, "kor_hours_bands.csv"))) {
  hb <- fread(file.path(data_dir, "kor_hours_bands.csv"))
  if (nrow(hb) > 0) {
    hb_total <- hb[sex == "SEX_T" & classif1 != "HOW_BANDS_TOTAL",
                   .(year = as.integer(time),
                     band = sub("HOW_BANDS_", "", classif1),
                     value = as.numeric(obs_value))]
    hb_total <- hb_total[!is.na(value)]

    ## Compute shares
    hb_total[, total := sum(value), by = year]
    hb_total[, share := value / total * 100]

    ## Focus on excessive hours (49+)
    excessive <- hb_total[band == "HGE49"]

    fig7 <- ggplot(excessive, aes(x = year, y = share)) +
      geom_line(color = "#E41A1C", linewidth = 1.2) +
      geom_point(color = "#E41A1C", size = 2.5) +
      geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
      annotate("text", x = T0 + 0.2, y = max(excessive$share) * 0.95,
               label = "52-hour cap", hjust = 0, size = 3.5) +
      labs(title = "Share of Workers Exceeding 49 Hours per Week",
           subtitle = "South Korea, 2005-2023",
           x = "", y = "Share of total employment (%)") +
      scale_x_continuous(breaks = seq(2005, 2023, 2))

    ggsave(file.path(fig_dir, "fig7_excessive_hours.pdf"), fig7,
           width = 8, height = 5)

    fwrite(excessive, file.path(data_dir, "excessive_hours_share.csv"))
    cat("Figure 7 saved\n")
  }
}

## ============================================================
## Figure 8: SCM Gap Plot (TFR)
## ============================================================

fig8 <- ggplot(scm_tfr, aes(x = year, y = gap)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
  geom_line(color = "#E41A1C", linewidth = 1.2) +
  geom_point(color = "#E41A1C", size = 2) +
  annotate("text", x = T0 + 0.2, y = min(scm_tfr$gap) * 0.9,
           label = "Fertility falls BELOW\nsynthetic control", hjust = 0,
           size = 3.5, color = "#E41A1C") +
  labs(title = "TFR Gap: South Korea Minus Synthetic Korea",
       subtitle = "Negative values = Korea's fertility fell more than expected",
       x = "", y = "Gap (actual - synthetic TFR)")

ggsave(file.path(fig_dir, "fig8_scm_tfr_gap.pdf"), fig8,
       width = 8, height = 5)
cat("Figure 8 saved\n")

## ============================================================
## Figure 9: Placebo tests (if available)
## ============================================================

if (file.exists(file.path(data_dir, "placebo_tfr_results.csv"))) {
  placebo <- fread(file.path(data_dir, "placebo_tfr_results.csv"))

  ## Filter out countries with very high pre-MSPE (> 5x Korea's)
  kor_pre <- placebo[iso3 == "KOR" & year < T0, mean(gap^2)]
  placebo_filtered <- placebo[pre_mspe < 5 * kor_pre | iso3 == "KOR"]

  fig9 <- ggplot() +
    geom_line(data = placebo_filtered[iso3 != "KOR"],
              aes(x = year, y = gap, group = iso3), color = "grey70", alpha = 0.5) +
    geom_line(data = placebo_filtered[iso3 == "KOR"],
              aes(x = year, y = gap), color = "#E41A1C", linewidth = 1.5) +
    geom_hline(yintercept = 0, color = "grey40") +
    geom_vline(xintercept = T0 - 0.5, linetype = "dashed", color = "grey40") +
    labs(title = "Placebo-in-Space: TFR Gaps for All OECD Countries",
         subtitle = paste0("Red = South Korea; grey = donor countries ",
                           "(excluding those with pre-MSPE > 5× Korea's)"),
         x = "", y = "TFR gap (actual - synthetic)")

  ggsave(file.path(fig_dir, "fig9_placebo_tfr.pdf"), fig9,
         width = 8, height = 5.5)
  cat("Figure 9 saved\n")
}

cat("\n=== ALL FIGURES SAVED ===\n")
cat("Directory:", fig_dir, "\n")
cat("Files:", paste(list.files(fig_dir, pattern = "\\.pdf$"), collapse = ", "), "\n")
