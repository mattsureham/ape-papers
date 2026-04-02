# ==============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# Paper: The Racial Dividend of the Warehouse Boom (apep_1300)
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
panel_placebo <- readRDS("../data/analysis_panel_placebo.rds")

# ---------- 1. Placebo: Professional Services (NAICS 54) ----------------------
# Amazon FCs should NOT affect professional services employment

cat("=== Placebo: Professional Services (NAICS 54) ===\n")

for (rc in c("All", "Black")) {
  df_plac <- panel_placebo %>%
    filter(race_group == rc) %>%
    filter(!is.na(log_emp) & is.finite(log_emp)) %>%
    group_by(county_fips) %>%
    filter(n() >= 15) %>%
    ungroup() %>%
    mutate(
      id = as.integer(factor(county_fips)),
      post = ifelse(first_treat > 0 & year >= first_treat, 1, 0)
    )

  twfe_plac <- feols(log_emp ~ post | county_fips + year,
                     data = df_plac, cluster = ~county_fips)
  cat(sprintf("Placebo TWFE (%s): %.4f (SE: %.4f, p=%.3f)\n",
              rc, coef(twfe_plac)["post"], se(twfe_plac)["post"],
              pvalue(twfe_plac)["post"]))

  # CS DiD for placebo
  cs_plac <- att_gt(
    yname = "log_emp",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_plac,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
  agg_plac <- aggte(cs_plac, type = "simple")
  cat(sprintf("Placebo CS ATT (%s): %.4f (SE: %.4f)\n\n",
              rc, agg_plac$overall.att, agg_plac$overall.se))
}

# ---------- 2. Leave-one-cohort-out -------------------------------------------
# Drop each treatment cohort to check sensitivity

cat("=== Leave-One-Cohort-Out ===\n")

df_all <- panel %>%
  filter(race_group == "All") %>%
  filter(!is.na(log_emp) & is.finite(log_emp)) %>%
  group_by(county_fips) %>%
  filter(n() >= 15) %>%
  ungroup() %>%
  mutate(id = as.integer(factor(county_fips)))

cohorts <- sort(unique(df_all$first_treat[df_all$first_treat > 0]))

loco_results <- data.frame()

for (g in cohorts) {
  df_drop <- df_all %>% filter(first_treat != g)
  df_drop <- df_drop %>% mutate(id = as.integer(factor(county_fips)))

  cs_drop <- tryCatch({
    cs_tmp <- att_gt(
      yname = "log_emp",
      tname = "year",
      idname = "id",
      gname = "first_treat",
      data = df_drop,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "varying"
    )
    aggte(cs_tmp, type = "simple")
  }, error = function(e) NULL)

  if (!is.null(cs_drop)) {
    loco_results <- rbind(loco_results, data.frame(
      dropped_cohort = g,
      att = cs_drop$overall.att,
      se = cs_drop$overall.se,
      n_dropped = sum(df_all$first_treat == g & df_all$year == min(df_all$year))
    ))
    cat(sprintf("Drop cohort %d: ATT = %.4f (SE: %.4f), dropped %d counties\n",
                g, cs_drop$overall.att, cs_drop$overall.se,
                sum(df_all$first_treat == g & df_all$year == min(df_all$year))))
  }
}

# ---------- 3. Not-yet-treated as control group --------------------------------

cat("\n=== Alternative control: Not-yet-treated ===\n")

for (rc in c("All", "Black")) {
  df_nyt <- panel %>%
    filter(race_group == rc) %>%
    filter(!is.na(log_emp) & is.finite(log_emp)) %>%
    group_by(county_fips) %>%
    filter(n() >= 15) %>%
    ungroup() %>%
    mutate(id = as.integer(factor(county_fips)))

  cs_nyt <- att_gt(
    yname = "log_emp",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_nyt,
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )
  agg_nyt <- aggte(cs_nyt, type = "simple")
  cat(sprintf("Not-yet-treated ATT (%s): %.4f (SE: %.4f)\n",
              rc, agg_nyt$overall.att, agg_nyt$overall.se))
}

# ---------- 4. Pre-2010 vs post-2010 treatment heterogeneity ------------------
# Early FCs (pre-2010) vs later FCs

cat("\n=== Early vs Late Cohort Heterogeneity ===\n")

df_early <- df_all %>% filter(first_treat <= 2010 | first_treat == 0)
df_late <- df_all %>% filter(first_treat > 2010 | first_treat == 0)

for (sub_name in c("Early (<=2010)", "Late (>2010)")) {
  df_sub <- if (sub_name == "Early (<=2010)") df_early else df_late
  df_sub <- df_sub %>% mutate(id = as.integer(factor(county_fips)))

  cs_sub <- tryCatch({
    cs_tmp <- att_gt(
      yname = "log_emp",
      tname = "year",
      idname = "id",
      gname = "first_treat",
      data = df_sub,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "varying"
    )
    aggte(cs_tmp, type = "simple")
  }, error = function(e) NULL)

  if (!is.null(cs_sub)) {
    cat(sprintf("%s ATT: %.4f (SE: %.4f)\n", sub_name, cs_sub$overall.att, cs_sub$overall.se))
  }
}

# ---------- 5. Save robustness results ----------------------------------------

saveRDS(list(
  loco_results = loco_results
), "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
