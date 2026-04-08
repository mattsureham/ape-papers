# 05_figures.R — Generate all figures (≥5 required)
# BVG Conversion Rate and Capital Withdrawal Choice

source("00_packages.R")

cat("=== Generating Figures ===\n")

# ---------------------------------------------------------------
# Load data
# ---------------------------------------------------------------
panel_agg <- readRDS("../data/panel_aggregate.rds")
gender_panel <- readRDS("../data/panel_gender.rds")
risk_panel <- readRDS("../data/panel_risk_type.rds")
results <- readRDS("../data/main_results.rds")

# Theme
theme_paper <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    axis.title = element_text(size = 11)
  )

# Reform step shading
reform_steps <- data.frame(
  xmin = c(2004.5, 2006.5, 2009.5, 2013.5),
  xmax = c(2006.5, 2009.5, 2013.5, 2024.5),
  label = c("7.1%", "7.0%", "6.9%", "6.8%")
)

add_reform_bands <- function(p) {
  p +
    annotate("rect", xmin = 2004.5, xmax = 2024.5,
             ymin = -Inf, ymax = Inf, fill = "gray90", alpha = 0.3) +
    geom_vline(xintercept = c(2004.5, 2006.5, 2009.5, 2013.5),
               linetype = "dashed", color = "gray60", linewidth = 0.4)
}

# ---------------------------------------------------------------
# Figure 1: Capital withdrawal share over time
# ---------------------------------------------------------------
cat("Figure 1: Capital share time series...\n")

fig1 <- ggplot(panel_agg, aes(x = year, y = capital_share * 100)) +
  geom_vline(xintercept = c(2004.5, 2006.5, 2009.5, 2013.5),
             linetype = "dashed", color = "gray60", linewidth = 0.4) +
  geom_point(size = 2.5, color = "#2166AC") +
  geom_line(linewidth = 0.8, color = "#2166AC") +
  annotate("text", x = 2005.5, y = max(panel_agg$capital_share * 100) + 1,
           label = "7.1%", size = 3, color = "gray40") +
  annotate("text", x = 2008, y = max(panel_agg$capital_share * 100) + 1,
           label = "7.0%", size = 3, color = "gray40") +
  annotate("text", x = 2011.5, y = max(panel_agg$capital_share * 100) + 1,
           label = "6.9%", size = 3, color = "gray40") +
  annotate("text", x = 2019, y = max(panel_agg$capital_share * 100) + 1,
           label = "6.8%", size = 3, color = "gray40") +
  annotate("text", x = 2004, y = max(panel_agg$capital_share * 100) + 1,
           label = "7.2%", size = 3, color = "gray40") +
  labs(
    x = "Year",
    y = "Capital Withdrawal Share (%)",
    title = "Capital Withdrawal Share Among Pension Beneficiaries",
    subtitle = "Dashed lines mark BVG conversion rate reductions"
  ) +
  scale_x_continuous(breaks = seq(2004, 2024, 2)) +
  theme_paper

ggsave("../figures/fig1_capital_share_timeseries.pdf", fig1,
       width = 8, height = 5)

# ---------------------------------------------------------------
# Figure 2: Event study — step dummies
# ---------------------------------------------------------------
cat("Figure 2: Event study (step dummies)...\n")

m2 <- results$m2
coefs <- data.table(
  step = c("Pre-reform\n(7.2%)", "Step 1\n(7.1%)", "Step 2\n(7.0%)",
           "Step 3\n(6.9%)", "Step 4\n(6.8%)"),
  estimate = c(0, coef(m2)[-1]),
  se = c(0, sqrt(diag(vcov(m2)))[-1]),
  step_num = 0:4
)
coefs[, ci_lo := estimate - 1.96 * se]
coefs[, ci_hi := estimate + 1.96 * se]
coefs[, step := factor(step, levels = step)]

fig2 <- ggplot(coefs, aes(x = step, y = estimate * 100)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbar(aes(ymin = ci_lo * 100, ymax = ci_hi * 100),
                width = 0.2, color = "#B2182B") +
  geom_point(size = 3, color = "#B2182B") +
  labs(
    x = "Reform Step (Conversion Rate)",
    y = "Change in Capital Share (pp)",
    title = "Effect of Each Conversion Rate Step on Capital Withdrawal",
    subtitle = "Relative to pre-reform period (7.2%), with 95% CI"
  ) +
  theme_paper

ggsave("../figures/fig2_event_study_steps.pdf", fig2,
       width = 7, height = 5)

# ---------------------------------------------------------------
# Figure 3: Gender comparison (capital beneficiaries at retirement)
# ---------------------------------------------------------------
cat("Figure 3: Gender trends...\n")

gp_plot <- gender_panel[, .(year,
                             Men = cap_ret_men,
                             Women = cap_ret_women)]
gp_long <- melt(gp_plot, id.vars = "year", variable.name = "gender",
                value.name = "capital_beneficiaries")

fig3 <- ggplot(gp_long, aes(x = year, y = capital_beneficiaries / 1000,
                              color = gender, shape = gender)) +
  geom_vline(xintercept = c(2004.5, 2006.5, 2009.5, 2013.5),
             linetype = "dashed", color = "gray60", linewidth = 0.4) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("Men" = "#2166AC", "Women" = "#B2182B")) +
  labs(
    x = "Year",
    y = "Capital Payment Beneficiaries (thousands)",
    color = "Gender", shape = "Gender",
    title = "Lump-Sum Capital Withdrawals at Retirement by Gender",
    subtitle = "Dashed lines mark conversion rate reductions"
  ) +
  scale_x_continuous(breaks = seq(2004, 2024, 2)) +
  theme_paper

ggsave("../figures/fig3_gender_capital_beneficiaries.pdf", fig3,
       width = 8, height = 5)

# ---------------------------------------------------------------
# Figure 4: Placebo — disability capital share
# ---------------------------------------------------------------
cat("Figure 4: Placebo (disability vs retirement capital share)...\n")

placebo_dt <- gender_panel[!is.na(disab_capital_share) & !is.na(capital_share),
                            .(year,
                              `Retirement (treatment)` = capital_share,
                              `Disability (placebo)` = disab_capital_share)]
placebo_long <- melt(placebo_dt, id.vars = "year",
                     variable.name = "type", value.name = "capital_share")

fig4 <- ggplot(placebo_long, aes(x = year, y = capital_share * 100,
                                  color = type, shape = type)) +
  geom_vline(xintercept = c(2004.5, 2006.5, 2009.5, 2013.5),
             linetype = "dashed", color = "gray60", linewidth = 0.4) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("Retirement (treatment)" = "#2166AC",
                                "Disability (placebo)" = "#B2182B")) +
  labs(
    x = "Year",
    y = "Capital Withdrawal Share (%)",
    color = "", shape = "",
    title = "Capital Share: Retirement vs. Disability Pensions",
    subtitle = "Disability pensions are unaffected by the BVG conversion rate"
  ) +
  scale_x_continuous(breaks = seq(2004, 2024, 2)) +
  theme_paper

ggsave("../figures/fig4_placebo_disability.pdf", fig4,
       width = 8, height = 5)

# ---------------------------------------------------------------
# Figure 5: Binscatter — rate cut vs capital share
# ---------------------------------------------------------------
cat("Figure 5: Binscatter (rate cut vs capital share)...\n")

fig5 <- ggplot(panel_agg, aes(x = rate_cut, y = capital_share * 100)) +
  geom_point(size = 3, color = "#2166AC") +
  geom_smooth(method = "lm", se = TRUE, color = "#B2182B",
              fill = "#B2182B", alpha = 0.15) +
  labs(
    x = "Cumulative Conversion Rate Cut (pp from 7.2%)",
    y = "Capital Withdrawal Share (%)",
    title = "Capital Withdrawal Share vs. Conversion Rate Cut",
    subtitle = paste0("Slope = ", round(coef(results$m1)["rate_cut"] * 100, 2),
                      " pp per pp rate cut")
  ) +
  theme_paper

ggsave("../figures/fig5_binscatter_ratecut.pdf", fig5,
       width = 7, height = 5)

# ---------------------------------------------------------------
# Figure 6: Fund type heterogeneity
# ---------------------------------------------------------------
cat("Figure 6: Fund type heterogeneity...\n")

risk_agg <- risk_panel[autonomy %in% c("Autonomous", "Semi-autonomous", "Collective") &
                          !is.na(capital_share),
                        .(year, autonomy, capital_share)]

fig6 <- ggplot(risk_agg, aes(x = year, y = capital_share * 100,
                               color = autonomy, shape = autonomy)) +
  geom_vline(xintercept = c(2004.5, 2006.5, 2009.5, 2013.5),
             linetype = "dashed", color = "gray60", linewidth = 0.4) +
  geom_point(size = 2) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = c("Autonomous" = "#2166AC",
                                "Semi-autonomous" = "#4393C3",
                                "Collective" = "#B2182B")) +
  labs(
    x = "Year",
    y = "Capital Withdrawal Share (%)",
    color = "Fund Type", shape = "Fund Type",
    title = "Capital Share by Pension Fund Autonomy Type",
    subtitle = "Collective funds are most exposed to BVG minimum conversion rate"
  ) +
  scale_x_continuous(breaks = seq(2004, 2024, 2)) +
  theme_paper

ggsave("../figures/fig6_fund_type_heterogeneity.pdf", fig6,
       width = 8, height = 5)

# ---------------------------------------------------------------
# Figure 7: Average capital per beneficiary at retirement
# ---------------------------------------------------------------
cat("Figure 7: Intensive margin...\n")

int_dt <- gender_panel[!is.na(avg_cap_ret_all),
                        .(year,
                          `All` = avg_cap_ret_all / 1000,
                          `Men` = avg_cap_ret_men / 1000,
                          `Women` = avg_cap_ret_women / 1000)]
int_long <- melt(int_dt, id.vars = "year",
                 variable.name = "group", value.name = "avg_capital")

fig7 <- ggplot(int_long, aes(x = year, y = avg_capital,
                               color = group, shape = group)) +
  geom_vline(xintercept = c(2004.5, 2006.5, 2009.5, 2013.5),
             linetype = "dashed", color = "gray60", linewidth = 0.4) +
  geom_point(size = 2) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = c("All" = "black",
                                "Men" = "#2166AC",
                                "Women" = "#B2182B")) +
  labs(
    x = "Year",
    y = "Average Capital Withdrawal (CHF thousands)",
    color = "", shape = "",
    title = "Average Lump-Sum Capital at Retirement",
    subtitle = "Per beneficiary, by gender"
  ) +
  scale_x_continuous(breaks = seq(2004, 2024, 2)) +
  scale_y_continuous(labels = scales::comma) +
  theme_paper

ggsave("../figures/fig7_intensive_margin.pdf", fig7,
       width = 8, height = 5)

cat("\n=== All 7 figures saved to figures/ ===\n")
