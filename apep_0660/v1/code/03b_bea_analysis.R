# 03b_bea_analysis.R — CS DiD on BEA REIS wages/earnings (extended panel)
# Provides parallel trends test with 7 pre-treatment years

source("00_packages.R")

data_dir <- "../data"
ext_panel <- readRDS(file.path(data_dir, "extended_panel.rds"))

cat("=== BEA Extended Analysis ===\n")
cat(sprintf("Panel: %d county-years, %d counties, years %d-%d\n",
            nrow(ext_panel), n_distinct(ext_panel$fips),
            min(ext_panel$year), max(ext_panel$year)))

# Balance panel
ext_bal <- ext_panel %>%
  filter(!is.na(log_wages) & is.finite(log_wages)) %>%
  group_by(fips) %>%
  filter(n() >= 20) %>%  # Require presence in most years
  ungroup()

ext_bal$county_id <- as.integer(factor(ext_bal$fips))

cat(sprintf("Balanced panel: %d obs, %d counties\n",
            nrow(ext_bal), n_distinct(ext_bal$fips)))

# ==============================================================================
# 1. CS DiD: Log Wages & Salaries
# ==============================================================================
cat("\n--- CS DiD: Log Wages ---\n")

cs_wages <- att_gt(
  yname = "log_wages",
  tname = "year",
  idname = "county_id",
  gname = "treat_year",
  data = as.data.frame(ext_bal),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "state_fips"
)

agg_wages <- aggte(cs_wages, type = "simple")
es_wages <- aggte(cs_wages, type = "dynamic", min_e = -7, max_e = 15)

p_wages <- 2 * pnorm(-abs(agg_wages$overall.att / agg_wages$overall.se))
cat(sprintf("CS ATT (log wages): %.4f (SE: %.4f, p=%.4f)\n",
            agg_wages$overall.att, agg_wages$overall.se, p_wages))

# ==============================================================================
# 2. CS DiD: Log Personal Income
# ==============================================================================
cat("\n--- CS DiD: Log Personal Income ---\n")

ext_bal_pi <- ext_bal %>% filter(!is.na(log_pi) & is.finite(log_pi))
ext_bal_pi$county_id <- as.integer(factor(ext_bal_pi$fips))

cs_pi <- att_gt(
  yname = "log_pi",
  tname = "year",
  idname = "county_id",
  gname = "treat_year",
  data = as.data.frame(ext_bal_pi),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "state_fips"
)

agg_pi <- aggte(cs_pi, type = "simple")
es_pi <- aggte(cs_pi, type = "dynamic", min_e = -7, max_e = 15)

p_pi <- 2 * pnorm(-abs(agg_pi$overall.att / agg_pi$overall.se))
cat(sprintf("CS ATT (log PI): %.4f (SE: %.4f, p=%.4f)\n",
            agg_pi$overall.att, agg_pi$overall.se, p_pi))

# ==============================================================================
# 3. TWFE benchmarks
# ==============================================================================
cat("\n--- TWFE Benchmarks ---\n")

twfe_wages <- feols(log_wages ~ treated | fips + year, data = ext_bal, cluster = ~state_fips)
twfe_pi <- feols(log_pi ~ treated | fips + year, data = ext_bal_pi, cluster = ~state_fips)

cat(sprintf("TWFE log wages: %.4f (SE: %.4f, p=%.4f)\n",
            coef(twfe_wages)["treated"], se(twfe_wages)["treated"],
            fixest::pvalue(twfe_wages)["treated"]))
cat(sprintf("TWFE log PI:    %.4f (SE: %.4f, p=%.4f)\n",
            coef(twfe_pi)["treated"], se(twfe_pi)["treated"],
            fixest::pvalue(twfe_pi)["treated"]))

# ==============================================================================
# 4. Event study pre-trends
# ==============================================================================
cat("\n--- Event Study Pre-trends ---\n")
es_df <- data.frame(
  event_time = es_wages$egt,
  att = es_wages$att.egt,
  se = es_wages$se.egt
)
es_df$p <- 2 * pnorm(-abs(es_df$att / es_df$se))
pre_es <- es_df %>% filter(event_time < 0 & !is.na(se))
cat("Pre-treatment event study (wages):\n")
for (i in seq_len(nrow(pre_es))) {
  cat(sprintf("  k=%d: %.4f (SE=%.4f, p=%.3f)\n",
              pre_es$event_time[i], pre_es$att[i], pre_es$se[i], pre_es$p[i]))
}
cat(sprintf("Max |pre-treatment ATT|: %.4f\n", max(abs(pre_es$att))))

# ==============================================================================
# 5. Save
# ==============================================================================
bea_results <- list(
  cs_wages = cs_wages, cs_pi = cs_pi,
  agg_wages = agg_wages, agg_pi = agg_pi,
  es_wages = es_wages, es_pi = es_pi,
  twfe_wages = twfe_wages, twfe_pi = twfe_pi,
  panel_info = list(
    n_obs = nrow(ext_bal), n_counties = n_distinct(ext_bal$fips),
    n_states = n_distinct(ext_bal$state_fips),
    years = range(ext_bal$year),
    n_pre = sum(unique(ext_bal$year) < min(ext_bal$treat_year))
  )
)

saveRDS(bea_results, file.path(data_dir, "bea_results.rds"))

# Update diagnostics
diag <- fromJSON(file.path(data_dir, "diagnostics.json"))
diag$bea_att_wages <- round(agg_wages$overall.att, 4)
diag$bea_se_wages <- round(agg_wages$overall.se, 4)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\n=== BEA analysis complete ===\n")
