## 05_figures.R — Generate all figures
## apep_0550: India Farm Laws Symmetric Natural Experiment

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
FIG_DIR  <- file.path(dirname(getwd()), "figures")
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

monthly <- fread(file.path(DATA_DIR, "monthly_panel.csv"))
monthly[, ym := as.Date(ym)]
apmc    <- fread(file.path(DATA_DIR, "apmc_stringency.csv"))

## Key dates
ENACT <- as.Date("2020-06-05")
STAY  <- as.Date("2021-01-12")
REPEAL <- as.Date("2021-12-01")

## ================================================================
## FIGURE 1: RAW PRICE TRENDS — HIGH VS LOW APMC STATES
## ================================================================
## Show parallel pre-trends and divergence during ON phase

monthly[, apmc_group := fifelse(apmc_stringency > median(apmc_stringency, na.rm = TRUE),
                                 "High APMC\n(regulated)", "Low APMC\n(deregulated)")]

## Median across commodities and states within each group (robust to outliers)
trends <- monthly[, .(
  median_price = median(mean_price, na.rm = TRUE),
  q25 = quantile(mean_price, 0.25, na.rm = TRUE),
  q75 = quantile(mean_price, 0.75, na.rm = TRUE)
), by = .(ym, apmc_group)]

fig1 <- ggplot(trends, aes(x = ym, y = median_price, color = apmc_group)) +
  geom_line(linewidth = 0.8) +
  geom_ribbon(aes(ymin = q25, ymax = q75,
                  fill = apmc_group), alpha = 0.15, color = NA) +
  geom_vline(xintercept = ENACT, linetype = "dashed", color = "red", linewidth = 0.6) +
  geom_vline(xintercept = STAY, linetype = "dashed", color = "blue", linewidth = 0.6) +
  geom_vline(xintercept = REPEAL, linetype = "dotted", color = "blue", linewidth = 0.5) +
  annotate("text", x = ENACT + 10, y = max(trends$median_price, na.rm = TRUE) * 1.05,
           label = "Laws\nenacted", hjust = 0, size = 3, color = "red") +
  annotate("text", x = STAY + 10, y = max(trends$median_price, na.rm = TRUE),
           label = "SC\nstay", hjust = 0, size = 3, color = "blue") +
  annotate("rect", xmin = ENACT, xmax = STAY,
           ymin = -Inf, ymax = Inf, alpha = 0.05, fill = "red") +
  scale_color_manual(values = c("High APMC\n(regulated)" = "#E41A1C",
                                 "Low APMC\n(deregulated)" = "#377EB8")) +
  scale_fill_manual(values = c("High APMC\n(regulated)" = "#E41A1C",
                                "Low APMC\n(deregulated)" = "#377EB8")) +
  labs(
    x = NULL, y = "Median retail price (INR/kg)",
    color = NULL, fill = NULL,
    title = "Agricultural commodity prices by APMC regulation intensity",
    subtitle = "Median across rice, wheat, onion, potato, and tomato (IQR shaded)"
  ) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  scale_y_continuous(labels = comma)

ggsave(file.path(FIG_DIR, "fig1_price_trends.pdf"), fig1,
       width = 8, height = 5.5, device = cairo_pdf)
cat("Figure 1 saved\n")

## ================================================================
## FIGURE 2: EVENT STUDY — MONTHLY COEFFICIENTS
## ================================================================
## Estimate monthly interaction coefficients relative to May 2020

## Create relative time (months since enactment)
ref_month <- as.Date("2020-05-01")  # last pre-treatment month
monthly[, rel_month := as.integer(round(difftime(ym, ref_month, units = "days") / 30.44))]

## Keep a balanced window: -24 to +30 months
es_data <- monthly[rel_month >= -24 & rel_month <= 30]
es_data[, rel_month_f := factor(rel_month)]

## Drop reference period (rel_month = 0)
fit_es <- feols(
  log_mean_price ~ i(rel_month_f, apmc_stringency, ref = "0") |
    state_commodity + commodity_month,
  data = es_data,
  cluster = ~state
)

## Extract coefficients
es_coefs <- as.data.table(coeftable(fit_es), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tval", "pval"))
es_coefs[, rel_month := as.integer(gsub("rel_month_f::(-?\\d+):apmc_stringency", "\\1", term))]
es_coefs <- es_coefs[!is.na(rel_month)]
es_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

## Add reference period
es_coefs <- rbind(es_coefs,
  data.table(term = "ref", estimate = 0, se = 0, tval = 0, pval = 1,
             rel_month = 0, ci_lo = 0, ci_hi = 0))
es_coefs <- es_coefs[order(rel_month)]

fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))

fig2 <- ggplot(es_coefs, aes(x = rel_month, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.6) +
  geom_vline(xintercept = 7, linetype = "dashed", color = "blue", linewidth = 0.6) +
  annotate("rect", xmin = 0, xmax = 7, ymin = -Inf, ymax = Inf,
           alpha = 0.05, fill = "red") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#377EB8") +
  geom_point(size = 1.5, color = "#377EB8") +
  geom_line(linewidth = 0.5, color = "#377EB8") +
  annotate("text", x = 3.5, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "ON phase", size = 3, fontface = "italic") +
  annotate("text", x = -12, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", size = 3, fontface = "italic") +
  annotate("text", x = 18, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "OFF phase", size = 3, fontface = "italic") +
  labs(
    x = "Months relative to farm law enactment (June 2020)",
    y = expression(hat(beta)[t] ~ "(APMC stringency × month)"),
    title = "Event study: Price effect of farm laws by APMC regulation intensity",
    subtitle = "Coefficients on interaction of APMC stringency index × monthly dummies"
  )

ggsave(file.path(FIG_DIR, "fig2_event_study.pdf"), fig2,
       width = 8, height = 5, device = cairo_pdf)
cat("Figure 2 saved\n")

## ================================================================
## FIGURE 3: COEFFICIENT COMPARISON — SYMMETRIC DESIGN
## ================================================================

main_results <- fread(file.path(DATA_DIR, "main_results.csv"))

fig3 <- ggplot(main_results[model == "Continuous APMC" | model == "Binary APMC"],
               aes(x = phase, y = estimate, color = model)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  position = position_dodge(width = 0.3), size = 0.6) +
  scale_color_manual(values = c("Continuous APMC" = "#E41A1C",
                                 "Binary APMC" = "#377EB8")) +
  labs(
    x = NULL, y = "Coefficient estimate",
    color = "Treatment measure",
    title = "Symmetric test: ON-phase effect vs OFF-phase reversal",
    subtitle = "Point estimates and 95% CI from main DiD specifications"
  )

ggsave(file.path(FIG_DIR, "fig3_symmetric_test.pdf"), fig3,
       width = 6, height = 4.5, device = cairo_pdf)
cat("Figure 3 saved\n")

## ================================================================
## FIGURE 4: HETEROGENEITY BY COMMODITY
## ================================================================

het_dt <- fread(file.path(DATA_DIR, "heterogeneity_commodity.csv"))

fig4 <- ggplot(het_dt, aes(x = reorder(commodity, -estimate), y = estimate,
                            color = phase)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  position = position_dodge(width = 0.4), size = 0.5) +
  scale_color_manual(values = c("ON" = "#E41A1C", "OFF" = "#377EB8")) +
  labs(
    x = NULL, y = "Coefficient (APMC stringency × phase)",
    color = "Phase",
    title = "Heterogeneous price effects by commodity",
    subtitle = "ON phase (deregulation) vs OFF phase (re-regulation)"
  ) +
  coord_flip()

ggsave(file.path(FIG_DIR, "fig4_commodity_heterogeneity.pdf"), fig4,
       width = 7, height = 5, device = cairo_pdf)
cat("Figure 4 saved\n")

## ================================================================
## FIGURE 5: LEAVE-ONE-STATE-OUT
## ================================================================

loso <- fread(file.path(DATA_DIR, "loso_results.csv"))

fig5a <- ggplot(loso, aes(x = reorder(dropped_state, on_estimate),
                           y = on_estimate)) +
  geom_hline(yintercept = loso[1, on_estimate], linetype = "dashed",
             color = "red", linewidth = 0.5) +
  geom_pointrange(aes(ymin = on_estimate - 1.96 * on_se,
                      ymax = on_estimate + 1.96 * on_se),
                  size = 0.3) +
  geom_hline(yintercept = 0, color = "grey50") +
  labs(
    x = NULL, y = "ON-phase coefficient",
    title = "Leave-one-state-out: ON-phase estimates"
  ) +
  coord_flip()

ggsave(file.path(FIG_DIR, "fig5_loso.pdf"), fig5a,
       width = 6.5, height = 5, device = cairo_pdf)
cat("Figure 5 saved\n")

## ================================================================
## FIGURE 6: RANDOMIZATION INFERENCE
## ================================================================

ri_perms <- fread(file.path(DATA_DIR, "ri_permutations.csv"))
ri_summary <- fread(file.path(DATA_DIR, "ri_summary.csv"))

actual_on <- ri_summary[coefficient == "ON", actual]

## Use absolute values for clearer visual interpretation
fig6 <- ggplot(ri_perms, aes(x = abs(perm_on))) +
  geom_histogram(bins = 50, fill = "grey70", color = "grey50") +
  geom_vline(xintercept = abs(actual_on), color = "red", linewidth = 1) +
  annotate("text", x = abs(actual_on), y = Inf,
           label = paste("|Actual| =", round(abs(actual_on), 4)),
           hjust = -0.1, vjust = 2, color = "red", size = 3.5) +
  labs(
    x = "|Permuted ON-phase coefficient|",
    y = "Count",
    title = "Randomization inference: Distribution under sharp null",
    subtitle = paste0("Two-sided RI p-value = ",
                      round(ri_summary[coefficient == "ON", ri_p_value], 3),
                      " (1,000 permutations, fraction with |coef| >= |actual|)")
  )

ggsave(file.path(FIG_DIR, "fig6_ri_distribution.pdf"), fig6,
       width = 6, height = 4.5, device = cairo_pdf)
cat("Figure 6 saved\n")

## ================================================================
## FIGURE 7: APMC STRINGENCY MAP (cross-sectional)
## ================================================================

fig7 <- ggplot(apmc, aes(x = reorder(state, apmc_stringency),
                          y = apmc_stringency, fill = factor(blocked_farm_laws))) +
  geom_col() +
  scale_fill_manual(values = c("0" = "#377EB8", "1" = "#E41A1C"),
                    labels = c("Implemented", "Blocked")) +
  labs(
    x = NULL, y = "APMC stringency index",
    fill = "Farm law status",
    title = "State-level APMC regulation intensity",
    subtitle = "Composite index: market fees (40%), regulated commodities (30%), private market restrictions (30%)"
  ) +
  coord_flip() +
  theme(legend.position = c(0.8, 0.3))

ggsave(file.path(FIG_DIR, "fig7_apmc_stringency.pdf"), fig7,
       width = 7, height = 5.5, device = cairo_pdf)
cat("Figure 7 saved\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
