# 03_main_analysis.R — Main DiD and event-study analysis
# APEP-0678: Price Floors and Poison — MUP and Alcohol-Specific Mortality
#
# Identification strategy:
#   Primary:   Country-level TWFE DiD (3 countries; staggered adoption)
#   Secondary: Regional-level panel DiD using English regions as donors
#   Event study: Scotland vs England, year-by-year relative to 2017
#   Inference:  Permutation tests (fisherian) given small N at country level

source("00_packages.R")

cat("\n=== MAIN ANALYSIS FOR APEP-0678 ===\n\n")

DATA_DIR    <- "../data"
TABLE_DIR   <- "../tables"
FIGURE_DIR  <- "../figures"
for (d in c(TABLE_DIR, FIGURE_DIR)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# ============================================================================
# LOAD DATA
# ============================================================================
country_panel <- readRDS(file.path(DATA_DIR, "country_panel.rds"))
region_panel  <- readRDS(file.path(DATA_DIR, "region_panel.rds"))

# ============================================================================
# SECTION A: Pre-trend descriptive table
# ============================================================================
cat("--- Section A: Pre-treatment trends ---\n")

pretend_summary <- country_panel %>%
  filter(year <= 2017) %>%
  group_by(country) %>%
  summarise(
    n_years    = n(),
    mean_rate  = round(mean(rate, na.rm = TRUE), 2),
    sd_rate    = round(sd(rate, na.rm = TRUE), 2),
    trend      = round(coef(lm(rate ~ year))[["year"]], 3),
    .groups    = "drop"
  )

cat("  Pre-treatment summary (2013-2017):\n")
print(pretend_summary)

# ============================================================================
# SECTION B: Country-level TWFE DiD
#   With only 3 units, standard SEs are not reliable.
#   We use permutation (randomisation inference) to get p-values.
# ============================================================================
cat("\n--- Section B: Country-level TWFE DiD ---\n")

# Main TWFE estimate: rate ~ treated + country_FE + year_FE
# 'treated' = 1 if country has MUP and year >= first_treat_year
twfe_country <- feols(
  rate ~ treated | country + year,
  data    = country_panel,
  cluster = ~country
)

cat("  TWFE country-level estimate:\n")
print(summary(twfe_country))

twfe_coef <- coef(twfe_country)["treated"]
twfe_se   <- se(twfe_country)["treated"]

cat("  Coef:", round(twfe_coef, 3), "| SE:", round(twfe_se, 3), "\n")

# ----  Permutation inference (Fisherian randomisation inference) ----
# Randomise treatment assignment across countries 10,000 times;
# compare observed ATT to distribution of placebo ATTs.

set.seed(20180501)   # Scotland MUP date

countries <- unique(country_panel$country)
obs_coef  <- twfe_coef

perm_coefs <- replicate(10000, {
  # Randomly reassign which countries are "treated" keeping treatment years the same
  perm_countries <- sample(countries, 2, replace = FALSE)
  perm_data <- country_panel %>%
    mutate(
      treated_perm = as.integer(
        (country %in% perm_countries[1] & year >= 2018) |
        (country %in% perm_countries[2] & year >= 2020)
      )
    )
  m <- tryCatch(
    feols(rate ~ treated_perm | country + year, data = perm_data, warn = FALSE),
    error = function(e) NULL
  )
  if (is.null(m)) return(NA_real_)
  coef(m)["treated_perm"]
})

perm_coefs <- na.omit(perm_coefs)
pval_perm  <- mean(abs(perm_coefs) >= abs(obs_coef))

cat("  Permutation p-value (10,000 draws):", round(pval_perm, 4), "\n")
cat("  Observed coef:", round(obs_coef, 3),
    "| 5th pctile:", round(quantile(perm_coefs, 0.05), 3),
    "| 95th pctile:", round(quantile(perm_coefs, 0.95), 3), "\n")

# ============================================================================
# SECTION C: Regional-level DiD (11 units)
#   Scotland and Wales as treated vs 9 English regions as controls
# ============================================================================
cat("\n--- Section C: Regional-level DiD ---\n")

# TWFE with cluster-robust SEs
twfe_region <- feols(
  rate ~ treated | unit_id + year,
  data    = region_panel,
  cluster = ~unit_id
)

cat("  TWFE regional estimate:\n")
print(summary(twfe_region))

# Staggered DiD: Callaway-Sant'Anna (accounts for staggered adoption)
# Map unit_id and first_treat properly
# For CS did: never-treated units need first_treat = 0
cs_data <- region_panel %>%
  mutate(
    gvar = if_else(first_treat > 0, as.integer(first_treat), 0L)
  ) %>%
  arrange(unit_id, year)

cs_att <- att_gt(
  yname         = "rate",
  tname         = "year",
  idname        = "unit_id",
  gname         = "gvar",
  data          = cs_data,
  control_group = "nevertreated",
  est_method    = "reg",
  allow_unbalanced_panel = TRUE
)

cat("  Callaway-Sant'Anna ATT(g,t) estimates:\n")
print(summary(cs_att))

cs_overall <- aggte(cs_att, type = "simple")
cat("  CS overall ATT:", round(cs_overall$overall.att, 3),
    "| SE:", round(cs_overall$overall.se, 3), "\n")

# Dynamic/event-study aggregation
cs_dynamic <- aggte(cs_att, type = "dynamic", min_e = -5, max_e = 5)
cat("  CS dynamic ATT (event study):\n")
print(summary(cs_dynamic))

# ============================================================================
# SECTION D: Scotland event study vs England (year-by-year coefficients)
# ============================================================================
cat("\n--- Section D: Scotland event study ---\n")
# With only 2 countries the 2-country TWFE is exactly identified and SEs are
# undefined. We therefore use the 11-unit regional panel, restricting to
# Scotland and the 9 English regions, which provides valid cluster-robust SEs.

scot_regions <- region_panel %>%
  filter(country %in% c("Scotland", "England")) %>%
  mutate(scotland = as.integer(country == "Scotland"))

# Event study via feols on regional panel
event_study <- feols(
  rate ~ i(year, scotland, ref = 2017) | unit_id + year,
  data    = scot_regions,
  cluster = ~unit_id
)

cat("  Scotland event study (vs English regions, 2017 base):\n")
print(summary(event_study))

# Extract event study coefficients and CIs
es_df <- as.data.frame(coeftable(event_study)) %>%
  rownames_to_column("term") %>%
  filter(grepl("year::", term)) %>%
  mutate(
    year  = as.integer(gsub("year::(\\d+):.*", "\\1", term)),
    coef  = Estimate,
    se    = `Std. Error`,
    ci_lo = Estimate - 1.96 * `Std. Error`,
    ci_hi = Estimate + 1.96 * `Std. Error`
  ) %>%
  bind_rows(
    tibble(year = 2017L, coef = 0, se = 0, ci_lo = 0, ci_hi = 0)
  ) %>%
  arrange(year) %>%
  select(year, coef, se, ci_lo, ci_hi)

cat("  Event-study coefficients:\n")
print(es_df)

# Wales vs England event study (using regional panel)
wal_regions <- region_panel %>%
  filter(country %in% c("Wales", "England")) %>%
  mutate(wales = as.integer(country == "Wales"))

event_study_wales <- feols(
  rate ~ i(year, wales, ref = 2019) | unit_id + year,
  data    = wal_regions,
  cluster = ~unit_id
)

cat("\n  Wales event study (vs English regions, 2019 base):\n")
print(summary(event_study_wales))

wales_es_df <- as.data.frame(coeftable(event_study_wales)) %>%
  rownames_to_column("term") %>%
  filter(grepl("year::", term)) %>%
  mutate(
    year  = as.integer(gsub("year::(\\d+):.*", "\\1", term)),
    coef  = Estimate,
    se    = `Std. Error`,
    ci_lo = Estimate - 1.96 * `Std. Error`,
    ci_hi = Estimate + 1.96 * `Std. Error`
  ) %>%
  bind_rows(tibble(year = 2019L, coef = 0, se = 0, ci_lo = 0, ci_hi = 0)) %>%
  arrange(year) %>%
  select(year, coef, se, ci_lo, ci_hi)

# ============================================================================
# SECTION E: Simple DiD — pre/post means
# ============================================================================
cat("\n--- Section E: Simple pre/post DiD ---\n")

did_simple <- country_panel %>%
  filter(country %in% c("Scotland", "England")) %>%
  mutate(post = as.integer(year >= 2018)) %>%
  group_by(country, post) %>%
  summarise(mean_rate = mean(rate, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = post, values_from = mean_rate,
              names_prefix = "post_") %>%
  mutate(change = post_1 - post_0)

cat("  Simple DiD (Scotland-England, break at 2018):\n")
print(did_simple)

did_att_scotland <- (did_simple$change[did_simple$country == "Scotland"] -
                     did_simple$change[did_simple$country == "England"])
cat("  Simple DiD ATT (Scotland):", round(did_att_scotland, 2), "\n")

# Wales (break at 2020)
did_wales <- country_panel %>%
  filter(country %in% c("Wales", "England")) %>%
  mutate(post = as.integer(year >= 2020)) %>%
  group_by(country, post) %>%
  summarise(mean_rate = mean(rate, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = post, values_from = mean_rate,
              names_prefix = "post_") %>%
  mutate(change = post_1 - post_0)

did_att_wales <- (did_wales$change[did_wales$country == "Wales"] -
                  did_wales$change[did_wales$country == "England"])
cat("  Simple DiD ATT (Wales):", round(did_att_wales, 2), "\n")

# ============================================================================
# SECTION F: Figures — event study plot + raw time series
# ============================================================================
cat("\n--- Section F: Generating figures ---\n")

# Figure 1: Raw time series (3 countries)
fig1_data <- country_panel %>%
  mutate(
    treat_label = case_when(
      country == "Scotland" ~ "Scotland (MUP May 2018)",
      country == "Wales"    ~ "Wales (MUP Mar 2020)",
      TRUE                  ~ "England (no MUP)"
    )
  )

p_ts <- ggplot(fig1_data, aes(x = year, y = rate, colour = treat_label,
                               shape = treat_label, linetype = treat_label)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.2) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", colour = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = 2019.5, linetype = "dotted", colour = "grey60", linewidth = 0.5) +
  annotate("text", x = 2017.7, y = 24, label = "Scotland\nMUP", size = 2.8,
           hjust = 0, colour = "grey40") +
  annotate("text", x = 2019.7, y = 22, label = "Wales\nMUP", size = 2.8,
           hjust = 0, colour = "grey40") +
  scale_colour_manual(values = c("Scotland (MUP May 2018)" = "#1b7837",
                                  "Wales (MUP Mar 2020)"    = "#762a83",
                                  "England (no MUP)"        = "#d95f02"),
                      name = NULL) +
  scale_shape_manual(values = c(16, 17, 15), name = NULL) +
  scale_linetype_manual(values = c("solid", "dashed", "longdash"), name = NULL) +
  scale_x_continuous(breaks = 2013:2023) +
  labs(
    x     = "Year",
    y     = "Alcohol-specific mortality (age-standardised, per 100,000)",
    title = "Alcohol-Specific Mortality Rates by Country, 2013-2023"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position  = c(0.02, 0.98),
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = alpha("white", 0.8)),
    legend.key.size   = unit(0.9, "lines"),
    axis.text.x       = element_text(angle = 45, hjust = 1),
    panel.grid.minor  = element_blank()
  )

ggsave(file.path(FIGURE_DIR, "fig1_time_series.pdf"), p_ts,
       width = 7, height = 4.5, device = "pdf")
ggsave(file.path(FIGURE_DIR, "fig1_time_series.png"), p_ts,
       width = 7, height = 4.5, dpi = 200)
cat("  Saved fig1_time_series\n")

# Figure 2: Scotland event study
es_plot_data <- es_df %>%
  mutate(
    mup_treat = as.integer(year >= 2018),
    col_group = if_else(year >= 2018, "Post-MUP", "Pre-MUP")
  )

p_es <- ggplot(es_plot_data, aes(x = year, y = coef,
                                   ymin = ci_lo, ymax = ci_hi,
                                   colour = col_group, fill = col_group)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = 2017.5, linetype = "dotted", colour = "#1b7837", linewidth = 0.7) +
  geom_ribbon(alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  scale_colour_manual(values = c("Pre-MUP" = "#636363", "Post-MUP" = "#1b7837"), name = NULL) +
  scale_fill_manual(  values = c("Pre-MUP" = "#636363", "Post-MUP" = "#1b7837"), name = NULL) +
  scale_x_continuous(breaks = 2013:2023) +
  annotate("text", x = 2017.7, y = max(es_plot_data$ci_hi, na.rm = TRUE) * 0.95,
           label = "MUP\nMay 2018", size = 2.8, hjust = 0, colour = "#1b7837") +
  labs(
    x     = "Year",
    y     = "Scotland vs England difference in mortality rate\n(per 100,000; relative to 2017)",
    title = "Scotland Event Study: Mortality Rate Differential vs England"
  ) +
  theme_bw(base_size = 11) +
  theme(
    legend.position = c(0.02, 0.98),
    legend.justification = c(0, 1),
    axis.text.x     = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(FIGURE_DIR, "fig2_event_study.pdf"), p_es,
       width = 7, height = 4.5, device = "pdf")
ggsave(file.path(FIGURE_DIR, "fig2_event_study.png"), p_es,
       width = 7, height = 4.5, dpi = 200)
cat("  Saved fig2_event_study\n")

# ============================================================================
# SECTION G: Save results
# ============================================================================
cat("\n--- Section G: Saving results ---\n")

results <- list(
  twfe_country_coef    = round(twfe_coef, 4),
  twfe_country_se      = round(twfe_se, 4),
  perm_pval            = round(pval_perm, 4),
  cs_overall_att       = round(cs_overall$overall.att, 4),
  cs_overall_se        = round(cs_overall$overall.se, 4),
  did_att_scotland     = round(did_att_scotland, 4),
  did_att_wales        = round(did_att_wales, 4),
  twfe_region_coef     = round(coef(twfe_region)["treated"], 4),
  twfe_region_se       = round(se(twfe_region)["treated"], 4),
  event_study_scotland = es_df,
  event_study_wales    = wales_es_df
)

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# Update diagnostics
diag <- jsonlite::read_json(file.path(DATA_DIR, "diagnostics.json"))
diag$twfe_country_coef <- results$twfe_country_coef
diag$perm_pval         <- results$perm_pval
diag$cs_overall_att    <- results$cs_overall_att
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("  main_results.rds saved\n")
cat("  TWFE ATT:", round(twfe_coef, 3),
    " | Perm p:", round(pval_perm, 4),
    " | CS ATT:", round(cs_overall$overall.att, 3), "\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
