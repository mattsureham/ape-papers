## 05_figures.R — All figures for apep_0529

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## Load data
panel_means <- fread(file.path(data_dir, "panel_means.csv"))
es_coefs <- fread(file.path(data_dir, "event_study_coefficients.csv"))
ri_dist <- fread(file.path(data_dir, "ri_permutation_distribution.csv"))
panel <- fread(file.path(data_dir, "circ_election_panel.csv"))
climate_votes <- fread(file.path(data_dir, "national_climate_votes.csv"))

## ============================================================
## Figure 1: Parallel trends — ENP and RN share by treatment group
## ============================================================

panel_means[, group := fifelse(treated_group == 1, "ZFE Constituencies", "Non-ZFE")]

p1a <- ggplot(panel_means, aes(x = year, y = mean_enp, color = group, group = group)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", alpha = 0.5) +
  annotate("text", x = 2020, y = max(panel_means$mean_enp) * 0.95,
           label = "First ZFE\n(Paris 2019)", hjust = 0, size = 3) +
  scale_color_manual(values = c("ZFE Constituencies" = unname(pal_zfe["treated"]),
                                 "Non-ZFE" = unname(pal_zfe["control"]))) +
  labs(x = "Election Year", y = "Effective Number of Parties (ENP)",
       color = NULL,
       title = "Panel A: Electoral Fragmentation") +
  theme(legend.position = "bottom")

p1b <- ggplot(panel_means, aes(x = year, y = mean_rn, color = group, group = group)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", alpha = 0.5) +
  scale_color_manual(values = c("ZFE Constituencies" = unname(pal_zfe["treated"]),
                                 "Non-ZFE" = unname(pal_zfe["control"]))) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Election Year", y = "RN + Far-Right Vote Share",
       color = NULL,
       title = "Panel B: Far-Right Vote Share") +
  theme(legend.position = "bottom")

fig1 <- p1a + p1b + plot_layout(ncol = 2, guides = "collect") &
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig1_parallel_trends.pdf"), fig1,
       width = 10, height = 5, device = pdf)
cat("Figure 1 saved\n")

## ============================================================
## Figure 2: Event study coefficients
## ============================================================

## Parse event study coefficients from fixest output
## The term format is "year::YYYY:treated_group"
es_plot <- copy(es_coefs)
es_plot[, year := as.integer(gsub("year::|:treated_group", "", term))]
setnames(es_plot, c("Estimate", "Std. Error"), c("estimate", "se"), skip_absent = TRUE)
if ("Estimate" %in% names(es_plot)) setnames(es_plot, "Estimate", "estimate")
if ("Std. Error" %in% names(es_plot)) setnames(es_plot, "Std. Error", "se")

## Add reference year (2017, coef = 0)
ref_rows <- data.table(
  term = c("ref_enp", "ref_rn"),
  estimate = c(0, 0), se = c(0, 0),
  outcome = c("ENP", "RN Share"),
  year = c(2017L, 2017L)
)
es_plot <- rbind(es_plot[, .(term, estimate, se, outcome, year)], ref_rows, fill = TRUE)

es_plot[, ci_lo := estimate - 1.96 * se]
es_plot[, ci_hi := estimate + 1.96 * se]

p2a <- ggplot(es_plot[outcome == "ENP"], aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", alpha = 0.3) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = pal_zfe["treated"]) +
  geom_line(color = pal_zfe["treated"], linewidth = 1) +
  geom_point(color = pal_zfe["treated"], size = 3) +
  labs(x = "Election Year", y = "Coefficient (ENP)",
       title = "Panel A: ENP Event Study") +
  annotate("text", x = 2019.5, y = -0.5, label = "ZFE onset", angle = 90, vjust = -0.5, size = 3)

p2b <- ggplot(es_plot[outcome == "RN Share"], aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", alpha = 0.3) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = pal_zfe["treated"]) +
  geom_line(color = pal_zfe["treated"], linewidth = 1) +
  geom_point(color = pal_zfe["treated"], size = 3) +
  labs(x = "Election Year", y = "Coefficient (RN Share)",
       title = "Panel B: RN Share Event Study")

fig2 <- p2a + p2b + plot_layout(ncol = 2)

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2,
       width = 10, height = 5, device = pdf)
cat("Figure 2 saved\n")

## ============================================================
## Figure 3: National vs Local Divisiveness (Scale Mismatch)
## ============================================================

## National: number of climate votes and passage rate over time
## Local: ENP gap between ZFE and non-ZFE constituencies

enp_gap <- panel_means[, .(
  enp_gap = mean_enp[treated_group == 1] - mean_enp[treated_group == 0]
), by = year]

## Scale climate votes to similar axis
climate_scaled <- climate_votes[year >= 2017]

p3 <- ggplot() +
  geom_col(data = climate_scaled,
           aes(x = year, y = n_climate_votes / 50),
           fill = pal_zfe["national"], alpha = 0.4, width = 0.8) +
  geom_line(data = enp_gap, aes(x = year, y = enp_gap),
            color = pal_zfe["treated"], linewidth = 1.5) +
  geom_point(data = enp_gap, aes(x = year, y = enp_gap),
             color = pal_zfe["treated"], size = 4) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3) +
  scale_y_continuous(
    name = "ENP Gap (ZFE - Non-ZFE)",
    sec.axis = sec_axis(~. * 50, name = "National Climate Votes (bars)")
  ) +
  labs(x = "Year",
       title = "Scale Mismatch: Local Electoral Gap vs National Legislative Activity") +
  annotate("text", x = 2019, y = 1.8, label = "LOM\n2019", size = 3) +
  annotate("text", x = 2021, y = 1.5, label = "Climat &\nResilience\n2021", size = 3)

ggsave(file.path(fig_dir, "fig3_scale_mismatch.pdf"), p3,
       width = 8, height = 5, device = pdf)
cat("Figure 3 saved\n")

## ============================================================
## Figure 4: Randomization Inference
## ============================================================

true_coef <- panel[, {
  m <- fixest::feols(enp ~ post | circ_id + year, data = .SD)
  coef(m)["post"]
}]

p4 <- ggplot(ri_dist, aes(x = perm_coef)) +
  geom_histogram(bins = 40, fill = "grey70", color = "grey50") +
  geom_vline(xintercept = true_coef, color = pal_zfe["treated"],
             linewidth = 1.5, linetype = "solid") +
  annotate("text", x = true_coef - 0.05, y = Inf,
           label = paste0("True: ", round(true_coef, 2)),
           hjust = 1, vjust = 2, color = pal_zfe["treated"], fontface = "bold") +
  labs(x = "Permuted Treatment Effect on ENP",
       y = "Count",
       title = "Randomization Inference: ENP DiD Coefficient") +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "fig4_randomization_inference.pdf"), p4,
       width = 7, height = 4.5, device = pdf)
cat("Figure 4 saved\n")

## ============================================================
## Figure 5: CS-DiD dynamic effects (if available)
## ============================================================
cs_enp_file <- file.path(data_dir, "cs_dynamic_enp.csv")
if (file.exists(cs_enp_file)) {
  cs_dyn <- fread(cs_enp_file)
  cs_dyn[, ci_lo := att - 1.96 * se]
  cs_dyn[, ci_hi := att + 1.96 * se]

  p5 <- ggplot(cs_dyn, aes(x = egt, y = att)) +
    geom_hline(yintercept = 0, alpha = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = pal_zfe["treated"]) +
    geom_line(color = pal_zfe["treated"], linewidth = 1) +
    geom_point(color = pal_zfe["treated"], size = 3) +
    labs(x = "Periods Relative to Treatment",
         y = "ATT (ENP)",
         title = "Callaway-Sant'Anna Dynamic Effects: ENP") +
    theme(plot.title = element_text(face = "bold"))

  ggsave(file.path(fig_dir, "fig5_cs_dynamic.pdf"), p5,
         width = 7, height = 4.5, device = pdf)
  cat("Figure 5 saved\n")
}

cat("\n=== ALL FIGURES COMPLETE ===\n")
