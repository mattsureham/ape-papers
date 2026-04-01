# 05_figures.R — Generate figures for Pakistan 2022 Floods paper

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ============================================================================
# Load data
# ============================================================================
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
flood_intensity <- readRDS(file.path(data_dir, "flood_intensity.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

panel[, tehsil_id := as.factor(tehsil_id)]
panel[, season_year := as.factor(season_year)]
panel[, district := as.factor(district)]

# ============================================================================
# Figure 1: Flood intensity distribution (histogram)
# ============================================================================
cat("=== Figure 1: Flood intensity distribution ===\n")

pdf(file.path(fig_dir, "fig1_flood_distribution.pdf"), width = 7, height = 5)
ggplot(flood_intensity, aes(x = pct_flooded)) +
  geom_histogram(binwidth = 5, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "red", linewidth = 0.7) +
  annotate("text", x = 7, y = Inf, label = "Treatment threshold (5%)",
           hjust = 0, vjust = 2, color = "red", size = 3.5) +
  labs(x = "Percent of Tehsil Area Flooded (%)",
       y = "Number of Tehsils",
       title = "") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank())
dev.off()

# ============================================================================
# Figure 2: Season-specific event study
# ============================================================================
cat("=== Figure 2: Event study by season ===\n")

# Run separate event studies for kharif and rabi
panel[, rel_time := fcase(
  season_id == "kharif_2019", -6L,
  season_id == "rabi_20192020", -5L,
  season_id == "kharif_2020", -4L,
  season_id == "rabi_20202021", -3L,
  season_id == "kharif_2021", -2L,
  season_id == "rabi_20212022", -1L,
  season_id == "kharif_2022", 0L,
  season_id == "rabi_20222023", 1L,
  season_id == "kharif_2023", 2L,
  season_id == "rabi_20232024", 3L,
  default = NA_integer_
)]
panel[, rel_time_f := factor(rel_time)]

# Kharif event study: use kharif-only relative time
kharif <- panel[season_type == "kharif" & !is.na(rel_time)]
kharif[, kharif_rel := fcase(
  season_id == "kharif_2019", -3L,
  season_id == "kharif_2020", -2L,
  season_id == "kharif_2021", -1L,
  season_id == "kharif_2022", 0L,
  season_id == "kharif_2023", 1L,
  default = NA_integer_
)]
kharif[, kharif_rel_f := factor(kharif_rel)]

es_kharif <- fixest::feols(
  ndvi_mean ~ i(kharif_rel_f, pct_flooded, ref = "-1") | tehsil_id + season_year,
  data = kharif, cluster = ~district
)

# Rabi event study
rabi <- panel[season_type == "rabi" & !is.na(rel_time)]
rabi[, rabi_rel := fcase(
  season_id == "rabi_20192020", -3L,
  season_id == "rabi_20202021", -2L,
  season_id == "rabi_20212022", -1L,
  season_id == "rabi_20222023", 0L,
  season_id == "rabi_20232024", 1L,
  default = NA_integer_
)]
rabi[, rabi_rel_f := factor(rabi_rel)]

es_rabi <- fixest::feols(
  ndvi_mean ~ i(rabi_rel_f, pct_flooded, ref = "-1") | tehsil_id + season_year,
  data = rabi, cluster = ~district
)

# Extract coefficients for plotting
extract_es <- function(model, season_label) {
  cf <- summary(model)$coeftable
  periods <- as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(cf)))
  data.table(
    period = periods,
    estimate = cf[, 1],
    se = cf[, 2],
    ci_lo = cf[, 1] - 1.96 * cf[, 2],
    ci_hi = cf[, 1] + 1.96 * cf[, 2],
    season = season_label
  )
}

es_k_dt <- extract_es(es_kharif, "Kharif (Summer)")
es_r_dt <- extract_es(es_rabi, "Rabi (Winter)")

# Add reference period
es_k_dt <- rbind(es_k_dt, data.table(period = -1L, estimate = 0, se = 0,
                                       ci_lo = 0, ci_hi = 0, season = "Kharif (Summer)"))
es_r_dt <- rbind(es_r_dt, data.table(period = -1L, estimate = 0, se = 0,
                                       ci_lo = 0, ci_hi = 0, season = "Rabi (Winter)"))
es_all <- rbind(es_k_dt, es_r_dt)

pdf(file.path(fig_dir, "fig2_event_study.pdf"), width = 8, height = 5)
ggplot(es_all, aes(x = period, y = estimate, color = season, shape = season)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.15, alpha = 0.5,
                position = position_dodge(width = 0.3)) +
  geom_point(size = 3, position = position_dodge(width = 0.3)) +
  scale_color_manual(values = c("Kharif (Summer)" = "#D55E00", "Rabi (Winter)" = "#0072B2")) +
  scale_x_continuous(breaks = -3:1,
                     labels = c("-3", "-2", "-1\n(ref)", "0\n(flood)", "+1")) +
  labs(x = "Seasons Relative to 2022 Flood",
       y = expression("Coefficient on Flood Intensity " * times * " Period"),
       color = "", shape = "") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom",
        panel.grid.minor = element_blank())
dev.off()

# ============================================================================
# Figure 3: Binned dose-response by season
# ============================================================================
cat("=== Figure 3: Binned dose-response ===\n")

# Extract binned coefficients
bin_labels <- c("Low\n(5-20%)", "Moderate\n(20-50%)", "Severe\n(>50%)")

extract_binned <- function(model, season_label) {
  cf <- summary(model)$coeftable
  data.table(
    group = bin_labels,
    group_num = 1:3,
    estimate = cf[1:3, 1],
    se = cf[1:3, 2],
    ci_lo = cf[1:3, 1] - 1.96 * cf[1:3, 2],
    ci_hi = cf[1:3, 1] + 1.96 * cf[1:3, 2],
    season = season_label
  )
}

# Need binned variables
panel[, flood_low_post := as.integer(flood_group == "low") * post]
panel[, flood_mod_post := as.integer(flood_group == "moderate") * post]
panel[, flood_sev_post := as.integer(flood_group == "severe") * post]

kharif_full <- panel[season_type == "kharif"]
rabi_full <- panel[season_type == "rabi"]

m_k_bin <- fixest::feols(
  ndvi_mean ~ flood_low_post + flood_mod_post + flood_sev_post | tehsil_id + season_year,
  data = kharif_full, cluster = ~district
)
m_r_bin <- fixest::feols(
  ndvi_mean ~ flood_low_post + flood_mod_post + flood_sev_post | tehsil_id + season_year,
  data = rabi_full, cluster = ~district
)

bin_k <- extract_binned(m_k_bin, "Kharif (Summer)")
bin_r <- extract_binned(m_r_bin, "Rabi (Winter)")
bin_all <- rbind(bin_k, bin_r)
bin_all[, group := factor(group, levels = bin_labels)]

pdf(file.path(fig_dir, "fig3_binned_dose_response.pdf"), width = 7, height = 5)
ggplot(bin_all, aes(x = group, y = estimate, fill = season)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                position = position_dodge(width = 0.7), width = 0.25) +
  scale_fill_manual(values = c("Kharif (Summer)" = "#D55E00", "Rabi (Winter)" = "#0072B2")) +
  labs(x = "Flood Intensity Group",
       y = "Effect on Mean NDVI",
       fill = "") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom",
        panel.grid.minor = element_blank())
dev.off()

# ============================================================================
# Figure 4: Continuous dose-response curve by season
# ============================================================================
cat("=== Figure 4: Continuous dose-response ===\n")

# Get quadratic model coefficients for each season
cf_k <- coef(results$m2_kharif_quad)
cf_r <- coef(results$m2_rabi_quad)

flood_seq <- seq(0, 100, by = 1)
dose_dt <- rbind(
  data.table(
    pct_flooded = flood_seq,
    effect = cf_k["flood_x_post"] * flood_seq + cf_k["flood_sq_x_post"] * flood_seq^2,
    season = "Kharif (Summer)"
  ),
  data.table(
    pct_flooded = flood_seq,
    effect = cf_r["flood_x_post"] * flood_seq + cf_r["flood_sq_x_post"] * flood_seq^2,
    season = "Rabi (Winter)"
  )
)

pdf(file.path(fig_dir, "fig4_dose_response_curve.pdf"), width = 7, height = 5)
ggplot(dose_dt, aes(x = pct_flooded, y = effect, color = season)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 1.2) +
  geom_rug(data = flood_intensity[pct_flooded > 0],
           aes(x = pct_flooded), inherit.aes = FALSE, alpha = 0.3, sides = "b") +
  scale_color_manual(values = c("Kharif (Summer)" = "#D55E00", "Rabi (Winter)" = "#0072B2")) +
  labs(x = "Percent of Tehsil Area Flooded (%)",
       y = "Predicted Effect on Mean NDVI",
       color = "") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom",
        panel.grid.minor = element_blank())
dev.off()

# ============================================================================
# Figure 5: Leave-one-province-out stability
# ============================================================================
cat("=== Figure 5: LOPO stability ===\n")

robust <- readRDS(file.path(data_dir, "robustness_results.rds"))
lopo <- robust$lopo_results

pdf(file.path(fig_dir, "fig5_lopo.pdf"), width = 7, height = 5)
ggplot(lopo, aes(x = reorder(dropped_province, beta_linear), y = beta_linear * 1000)) +
  geom_hline(yintercept = coef(results$m1_quad)["flood_x_post"] * 1000,
             linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_point(size = 3, color = "steelblue") +
  geom_errorbar(aes(ymin = (beta_linear - 1.96 * se_linear) * 1000,
                    ymax = (beta_linear + 1.96 * se_linear) * 1000),
                width = 0.2, color = "steelblue") +
  coord_flip() +
  labs(x = "",
       y = expression("Linear Coefficient (" %*% 10^3 * ")"),
       title = "") +
  annotate("text", x = 0.7, y = coef(results$m1_quad)["flood_x_post"] * 1000,
           label = "Full sample", color = "red", hjust = -0.1, size = 3.5) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank())
dev.off()

cat("\n=== All figures generated ===\n")
