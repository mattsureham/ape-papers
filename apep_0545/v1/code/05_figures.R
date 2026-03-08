## 05_figures.R
## All figures for the regulatory ratchet paper

# Set working directory to the project root (the project root directory (papers/apep_XXXX/vN/)).
# Replicators: set this to the directory containing data/, code/, figures/, tables/.
if (interactive()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  setwd(normalizePath(".."))  # go up from code/ to v1/
} else {
  # Command-line: run from the project root directory (papers/apep_XXXX/vN/), e.g., Rscript code/05_figures.R
}
source("code/00_packages.R")
library(data.table); library(ggplot2); library(patchwork); library(scales)
library(fixest); library(dplyr)

DATA_DIR   <- "data/"
FIGURES_DIR <- "figures/"
dir.create(FIGURES_DIR, showWarnings=FALSE)

panel <- fread(file.path(DATA_DIR, "panel_with_iv.csv"))
panel[, agency_fe := factor(agency_id)]
panel[, quarter_fe := factor(paste(year, quarter, sep="Q"))]
panel[, trump_era := as.integer(year %in% 2017:2020)]
panel[, biden_era := as.integer(year %in% 2021:2024)]
panel[, log_agency_burden := log(agency_burden_neg + 1)]
setorder(panel, agency_id, year, quarter)
panel[, log_agency_burden_L1 := shift(log_agency_burden, 1, type="lag"), by=agency_id]

# ============================================================
# FIGURE 1: Time series of significant rulemaking by agency
# ============================================================
fig1_data <- panel[!agency_id %in% c("CPSC","CFTC"), .(
  year, quarter,
  agency_id,
  n_significant
)]
fig1_data[, date := as.Date(sprintf("%d-%02d-01", year, (quarter-1)*3+1))]
fig1_data[, admin := case_when(year <= 2016 ~ "Obama", year <= 2020 ~ "Trump (EO 13771)", TRUE ~ "Biden")]

p1 <- ggplot(fig1_data[!agency_id %in% c("FRA","PHMSA","FMCSA","NRC")],
             aes(x=date, y=n_significant, color=agency_id)) +
  geom_line(size=0.8) +
  geom_vline(xintercept=as.Date("2017-01-30"), linetype="dashed", color="gray40", size=0.6) +
  annotate("text", x=as.Date("2017-06-01"), y=27, label="EO 13771\n('2-for-1')", size=2.5, hjust=0) +
  geom_vline(xintercept=as.Date("2021-01-20"), linetype="dashed", color="gray40", size=0.6) +
  annotate("text", x=as.Date("2021-05-01"), y=27, label="Biden\ninauguration", size=2.5, hjust=0) +
  facet_wrap(~agency_id, scales="free_y", ncol=3) +
  scale_x_date(date_breaks="2 years", date_labels="%Y") +
  scale_color_manual(values=AGENCY_COLORS) +
  labs(title="Quarterly Economically Significant Federal Rules by Agency, 2015-2024",
       x="Quarter", y="Significant rules issued", caption="Note: Dashed lines mark Trump EO 13771 (Jan 2017) and Biden's first day (Jan 2021).") +
  theme_apep() +
  theme(legend.position="none", axis.text.x=element_text(size=7))

ggsave(file.path(FIGURES_DIR, "fig1_rulemaking_time_series.pdf"), p1, width=10, height=7)
ggsave(file.path(FIGURES_DIR, "fig1_rulemaking_time_series.png"), p1, width=10, height=7, dpi=150)
cat("Figure 1 saved\n")

# ============================================================
# FIGURE 2: Incident vs. burden coverage over time
# ============================================================
fig2_data <- panel[agency_id == "EPA"]  # EPA is most prominent
fig2_data[, date := as.Date(sprintf("%d-%02d-01", year, (quarter-1)*3+1))]

p2a <- ggplot(fig2_data, aes(x=date)) +
  geom_line(aes(y=log(incident_articles+1), color="Incident coverage"), size=0.9) +
  geom_line(aes(y=log(agency_burden_neg+1), color="Burden coverage (neg-tone)"), size=0.9, linetype="dashed") +
  geom_vline(xintercept=as.Date("2017-01-30"), linetype="dotted", color="gray50") +
  scale_color_manual(values=c("Incident coverage"="#d73027", "Burden coverage (neg-tone)"="#4575b4"),
                     name="Coverage type") +
  labs(title="EPA: News Coverage by Type, 2015-2024",
       x="Quarter", y="Log articles (quarterly)", subtitle="Incident = environmental disasters/pollution; Burden = sector-specific, negative-tone regulatory coverage") +
  theme_apep()

p2b <- ggplot(fig2_data, aes(x=date)) +
  geom_line(aes(y=n_significant, color="Significant rules"), size=0.9) +
  geom_vline(xintercept=as.Date("2017-01-30"), linetype="dotted", color="gray50") +
  scale_color_manual(values=c("Significant rules"="#1b7837")) +
  labs(x="Quarter", y="Significant rules (quarterly)", title="EPA: Significant Rulemaking Activity") +
  theme_apep() + theme(legend.position="none")

p2 <- p2a / p2b + plot_annotation(tag_levels="A")
ggsave(file.path(FIGURES_DIR, "fig2_epa_coverage_rulemaking.pdf"), p2, width=10, height=7)
ggsave(file.path(FIGURES_DIR, "fig2_epa_coverage_rulemaking.png"), p2, width=10, height=7, dpi=150)
cat("Figure 2 saved\n")

# ============================================================
# FIGURE 3: Main result - binned scatter (incident vs. outcome)
# ============================================================
# Residualize both variables on agency and quarter FEs
m_resid1 <- feols(log_n_significant ~ 1 | agency_fe + quarter_fe, data=panel[!agency_id %in% c("CPSC")])
m_resid2 <- feols(log_incident_L1 ~ 1 | agency_fe + quarter_fe, data=panel[!agency_id %in% c("CPSC")])
m_resid3 <- feols(log_agency_burden_L1 ~ 1 | agency_fe + quarter_fe,
                  data=panel[!agency_id %in% c("CPSC") & !is.na(panel$log_agency_burden_L1)])

panel_resid <- panel[!agency_id %in% c("CPSC") & !is.na(log_agency_burden_L1)]
panel_resid[, resid_outcome  := residuals(m_resid1)]
panel_resid[, resid_incident := residuals(m_resid2)]

# Bin scatter (20 bins)
n_bins <- 20
panel_resid[, bin_inc := ntile(resid_incident, n_bins)]
bin_scatter_inc <- panel_resid[, .(
  x = mean(resid_incident, na.rm=TRUE),
  y = mean(resid_outcome, na.rm=TRUE),
  n = .N
), by=bin_inc]

p3a <- ggplot(bin_scatter_inc, aes(x=x, y=y)) +
  geom_point(size=3, color="#d73027") +
  geom_smooth(method="lm", color="#d73027", fill="#f1a340", alpha=0.2, se=TRUE) +
  labs(title="A. Incident Coverage → Significant Rules",
       x="Incident coverage (residualized, log)", y="Significant rules (residualized, log)",
       caption="Agency and quarter FEs removed. Each dot = 1/20 of observations.") +
  theme_apep()

# Burden scatter
panel_resid[, bin_burd := ntile(log_agency_burden_L1, n_bins)]
bin_scatter_burd <- panel_resid[, .(
  x = mean(log_agency_burden_L1, na.rm=TRUE),
  y = mean(log_n_significant, na.rm=TRUE)
), by=bin_burd]

m_resid_burd <- feols(log_agency_burden_L1 ~ 1 | agency_fe + quarter_fe, data=panel_resid)
panel_resid[, resid_burden := residuals(m_resid_burd)]
bin_scatter_burd2 <- panel_resid[, .(
  x = mean(resid_burden, na.rm=TRUE),
  y = mean(resid_outcome, na.rm=TRUE)
), by=ntile(resid_burden, n_bins)]

p3b <- ggplot(bin_scatter_burd2, aes(x=x, y=y)) +
  geom_point(size=3, color="#4575b4") +
  geom_smooth(method="lm", color="#4575b4", fill="#91bfdb", alpha=0.2, se=TRUE) +
  labs(title="B. Burden Coverage → Significant Rules",
       x="Burden coverage (residualized, log)", y="Significant rules (residualized, log)",
       caption="Agency and quarter FEs removed. Each dot = 1/20 of observations.") +
  theme_apep()

p3 <- p3a | p3b
ggsave(file.path(FIGURES_DIR, "fig3_binned_scatter.pdf"), p3, width=12, height=5)
ggsave(file.path(FIGURES_DIR, "fig3_binned_scatter.png"), p3, width=12, height=5, dpi=150)
cat("Figure 3 saved\n")

# ============================================================
# FIGURE 4: Local projections (impulse response)
# ============================================================
lp_df <- fread(file.path("tables/", "local_projections.csv"))
lp_df[, `:=`(
  ci_inc_lo = coef_incident - 1.96 * se_incident,
  ci_inc_hi = coef_incident + 1.96 * se_incident,
  ci_burd_lo = coef_burden - 1.96 * se_burden,
  ci_burd_hi = coef_burden + 1.96 * se_burden
)]

p4a <- ggplot(lp_df, aes(x=horizon, y=coef_incident)) +
  geom_hline(yintercept=0, linetype="dashed", color="gray50") +
  geom_ribbon(aes(ymin=ci_inc_lo, ymax=ci_inc_hi), alpha=0.2, fill="#d73027") +
  geom_line(color="#d73027", size=1) +
  geom_point(color="#d73027", size=3) +
  scale_x_continuous(breaks=0:6, labels=paste0("h=", 0:6)) +
  labs(title="A. Dynamic Effect: Incident Coverage → Rules",
       x="Quarters ahead (h)", y="Coefficient estimate", subtitle="95% confidence interval; agency+quarter FEs") +
  theme_apep()

p4b <- ggplot(lp_df, aes(x=horizon, y=coef_burden)) +
  geom_hline(yintercept=0, linetype="dashed", color="gray50") +
  geom_ribbon(aes(ymin=ci_burd_lo, ymax=ci_burd_hi), alpha=0.2, fill="#4575b4") +
  geom_line(color="#4575b4", size=1) +
  geom_point(color="#4575b4", size=3) +
  scale_x_continuous(breaks=0:6, labels=paste0("h=", 0:6)) +
  labs(title="B. Dynamic Effect: Burden Coverage → Rules",
       x="Quarters ahead (h)", y="Coefficient estimate", subtitle="Persistent positive effect at all horizons") +
  theme_apep()

p4 <- p4a | p4b
ggsave(file.path(FIGURES_DIR, "fig4_local_projections.pdf"), p4, width=12, height=5)
ggsave(file.path(FIGURES_DIR, "fig4_local_projections.png"), p4, width=12, height=5, dpi=150)
cat("Figure 4 saved\n")

# ============================================================
# FIGURE 5: Administration heterogeneity
# ============================================================
admin_dt <- fread(file.path("tables/", "admin_heterogeneity.csv"))
admin_dt[, `:=`(
  ci_inc_lo = coef_incident - 1.96 * se_incident,
  ci_inc_hi = coef_incident + 1.96 * se_incident,
  ci_burd_lo = coef_burden - 1.96 * se_burden,
  ci_burd_hi = coef_burden + 1.96 * se_burden,
  period_f = factor(period, levels=c("Obama/Pre-Trump","Trump (EO 13771 period)","Biden"))
)]

p5a <- ggplot(admin_dt, aes(x=period_f, y=coef_incident, color=period_f)) +
  geom_hline(yintercept=0, linetype="dashed", color="gray50") +
  geom_pointrange(aes(ymin=ci_inc_lo, ymax=ci_inc_hi), size=1.2, linewidth=1.5) +
  scale_color_manual(values=c("Obama/Pre-Trump"="#2166ac","Trump (EO 13771 period)"="#d73027","Biden"="#4dac26")) +
  labs(title="A. Incident Coverage → Rules (by Administration)",
       x="", y="Coefficient estimate", subtitle="95% CI; agency + quarter FEs") +
  theme_apep() + theme(legend.position="none", axis.text.x=element_text(size=8))

p5b <- ggplot(admin_dt, aes(x=period_f, y=coef_burden, color=period_f)) +
  geom_hline(yintercept=0, linetype="dashed", color="gray50") +
  geom_pointrange(aes(ymin=ci_burd_lo, ymax=ci_burd_hi), size=1.2, linewidth=1.5) +
  scale_color_manual(values=c("Obama/Pre-Trump"="#2166ac","Trump (EO 13771 period)"="#d73027","Biden"="#4dac26")) +
  labs(title="B. Burden Coverage → Rules (by Administration)",
       x="", y="Coefficient estimate", subtitle="Burden effect flips negative under Trump EO 13771") +
  theme_apep() + theme(legend.position="none", axis.text.x=element_text(size=8))

p5 <- p5a | p5b
ggsave(file.path(FIGURES_DIR, "fig5_admin_heterogeneity.pdf"), p5, width=12, height=5)
ggsave(file.path(FIGURES_DIR, "fig5_admin_heterogeneity.png"), p5, width=12, height=5, dpi=150)
cat("Figure 5 saved\n")

# ============================================================
# FIGURE 6: Proposed vs. Final rules
# ============================================================
pf_dt <- fread(file.path("tables/", "proposed_vs_final.csv"))
pf_dt[, `:=`(
  ci_inc_lo = coef_incident - 1.96 * se_incident,
  ci_inc_hi = coef_incident + 1.96 * se_incident,
  ci_burd_lo = coef_burden - 1.96 * se_burden,
  ci_burd_hi = coef_burden + 1.96 * se_burden,
  outcome_f = factor(outcome, levels=c("proposed","final"), labels=c("Proposed rules","Final rules"))
)]

fig6_long <- melt(pf_dt, id.vars=c("outcome_f"),
                   measure.vars=list(coef=c("coef_incident","coef_burden"),
                                     lo=c("ci_inc_lo","ci_burd_lo"),
                                     hi=c("ci_inc_hi","ci_burd_hi")))
fig6_long[, coverage_type := ifelse(variable==1, "Incident coverage", "Burden coverage")]

p6 <- ggplot(fig6_long, aes(x=outcome_f, y=coef, color=coverage_type, group=coverage_type)) +
  geom_hline(yintercept=0, linetype="dashed", color="gray50") +
  geom_pointrange(aes(ymin=lo, ymax=hi), size=1, linewidth=1.5,
                  position=position_dodge(width=0.3)) +
  scale_color_manual(values=c("Incident coverage"="#d73027", "Burden coverage"="#4575b4"),
                     name="Coverage type") +
  labs(title="Coverage Effects: Proposed vs. Final Rules",
       x="Rule type", y="Coefficient estimate", subtitle="95% CI; agency + quarter FEs") +
  theme_apep()

ggsave(file.path(FIGURES_DIR, "fig6_proposed_vs_final.pdf"), p6, width=8, height=5)
ggsave(file.path(FIGURES_DIR, "fig6_proposed_vs_final.png"), p6, width=8, height=5, dpi=150)
cat("Figure 6 saved\n")

message("05_figures.R complete.")
