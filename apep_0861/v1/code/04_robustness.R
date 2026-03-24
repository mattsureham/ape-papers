## 04_robustness.R — Robustness checks
## APEP-0861: Austerity Triage and Domestic Abuse Justice

source("00_packages.R")
setwd("..")

panel <- readRDS("data/analysis_panel.rds")
panel <- panel %>%
  mutate(
    austerity_intensity = -officer_change_pct,
    post_uplift = as.integer(year >= 2020),
    log_officers = log(officer_fte),
    charge_rate = charge_rate_pct * 100,
    no_suspect = no_suspect_pct * 100,
    victim_nosupport = victim_nosupport_pct * 100,
    success_rate = success_rate_pct * 100
  )

# Classify austerity
median_cut <- panel %>%
  filter(year == 2018) %>% pull(officer_change_pct) %>% median(na.rm = TRUE)
austerity_class <- panel %>%
  filter(year == 2018) %>%
  mutate(high_austerity = as.integer(officer_change_pct < median_cut)) %>%
  select(force_std, high_austerity)
panel <- panel %>% left_join(austerity_class, by = "force_std")

cat("=== ROBUSTNESS CHECKS ===\n")

# ===============================================================
# 1. Exclude Metropolitan Police (London dominates sample)
# ===============================================================
panel_no_met <- panel %>% filter(force_std != "Metropolitan Police")

r1 <- feols(charge_rate ~ log_officers | force_std + year,
            data = panel_no_met, cluster = ~force_std)
cat("1. Excl. Met Police: coef =", coef(r1)[1], ", SE =", se(r1)[1],
    ", p =", pvalue(r1)[1], "\n")

# ===============================================================
# 2. Placebo: non-victim-based offenses
# ===============================================================
# Read non-victim charge rate
outcomes_raw <- read_excel("data/crime_outcomes_supplementary.xlsx", sheet = "Outcomes")
outcomes_raw <- janitor::clean_names(outcomes_raw)

nonvictim_charge <- outcomes_raw %>%
  filter(
    offence_level == "All crime",
    geographic_granularity == "Police force area",
    annual_or_quarterly == "Rolling annual",
    quarter == "Q4",
    grepl("charge outcome.*no specific victims", metric_full_name, ignore.case = TRUE)
  ) %>%
  select(force = geographic_area_name, year,
         nonvictim_charge_pct = percent) %>%
  mutate(
    nonvictim_charge_pct = as.numeric(nonvictim_charge_pct),
    force_std = trimws(force),
    force_std = gsub("^Hampshire and Isle of Wight$", "Hampshire", force_std)
  )

panel_nv <- panel %>%
  left_join(nonvictim_charge %>% select(force_std, year, nonvictim_charge_pct),
            by = c("force_std", "year")) %>%
  mutate(nonvictim_charge = nonvictim_charge_pct * 100)

r2 <- feols(nonvictim_charge ~ log_officers | force_std + year,
            data = panel_nv, cluster = ~force_std)
cat("2. Placebo (non-victim charge): coef =", coef(r2)[1], ", SE =", se(r2)[1],
    ", p =", pvalue(r2)[1], "\n")

# ===============================================================
# 3. Include PCSOs (total policing capacity)
# ===============================================================
panel <- panel %>% mutate(log_total = log(officer_fte + pcso_fte))

r3 <- feols(charge_rate ~ log_total | force_std + year,
            data = panel, cluster = ~force_std)
cat("3. Total FTE (officers + PCSOs): coef =", coef(r3)[1], ", SE =", se(r3)[1],
    ", p =", pvalue(r3)[1], "\n")

# ===============================================================
# 4. Alternative functional form: level instead of log
# ===============================================================
panel <- panel %>% mutate(officers_1000 = officer_fte / 1000)

r4 <- feols(charge_rate ~ officers_1000 | force_std + year,
            data = panel, cluster = ~force_std)
cat("4. Officer FTE/1000 (level): coef =", coef(r4)[1], ", SE =", se(r4)[1],
    ", p =", pvalue(r4)[1], "\n")

# ===============================================================
# 5. Adult rape charge rate (more resource-intensive)
# ===============================================================
rape_charge <- outcomes_raw %>%
  filter(
    offence_level == "Adult rape",
    geographic_granularity == "Police force area",
    annual_or_quarterly == "Rolling annual",
    quarter == "Q4",
    grepl("charge outcome.*victim-based", metric_full_name, ignore.case = TRUE)
  ) %>%
  select(force = geographic_area_name, year,
         rape_charge_pct = percent) %>%
  mutate(
    rape_charge_pct = as.numeric(rape_charge_pct),
    force_std = trimws(force),
    force_std = gsub("^Hampshire and Isle of Wight$", "Hampshire", force_std)
  )

panel_rape <- panel %>%
  left_join(rape_charge %>% select(force_std, year, rape_charge_pct),
            by = c("force_std", "year")) %>%
  mutate(rape_charge = rape_charge_pct * 100)

if (sum(!is.na(panel_rape$rape_charge)) > 50) {
  r5 <- feols(rape_charge ~ log_officers | force_std + year,
              data = panel_rape, cluster = ~force_std)
  cat("5. Adult rape charge rate: coef =", coef(r5)[1], ", SE =", se(r5)[1],
      ", p =", pvalue(r5)[1], "\n")
} else {
  r5 <- NULL
  cat("5. Adult rape charge rate: insufficient data (", sum(!is.na(panel_rape$rape_charge)), " obs)\n")
}

# ===============================================================
# 6. Leave-one-out: drop each force and check stability
# ===============================================================
forces <- unique(panel$force_std)
loo_coefs <- numeric(length(forces))
for (i in seq_along(forces)) {
  m <- feols(charge_rate ~ log_officers | force_std + year,
             data = filter(panel, force_std != forces[i]),
             cluster = ~force_std)
  loo_coefs[i] <- coef(m)[1]
}
cat("6. Leave-one-out: min =", round(min(loo_coefs), 2),
    ", max =", round(max(loo_coefs), 2),
    ", range =", round(max(loo_coefs) - min(loo_coefs), 2), "\n")

# ===============================================================
# 7. Pre-trend test: workforce trends before 2016
# ===============================================================
wf <- readRDS("data/workforce_panel.rds") %>%
  filter(!is.na(officer_change_pct), year >= 2007, year <= 2015)

austerity_pre <- austerity_class
wf <- wf %>% left_join(austerity_pre, by = "force_std") %>% filter(!is.na(high_austerity))

r7 <- feols(officer_fte ~ i(year, high_austerity, ref = 2010) | force_std + year,
            data = wf, cluster = ~force_std)
cat("7. Pre-trend test (officer FTE before austerity):\n")
cat("   Pre-2010 coefficients (should be ~0 if parallel pre-trends):\n")
for (yr in c(2007, 2008, 2009)) {
  nm <- paste0("year::", yr, ":high_austerity")
  if (nm %in% names(coef(r7))) {
    cat("   ", yr, ": coef =", round(coef(r7)[nm], 1),
        ", SE =", round(se(r7)[nm], 1), "\n")
  }
}

# ===============================================================
# SAVE ROBUSTNESS MODELS
# ===============================================================
robustness <- list(
  r1_no_met = r1, r2_placebo = r2, r3_total_fte = r3,
  r4_level = r4, r5_rape = r5, r7_pretrend = r7,
  loo_coefs = loo_coefs, loo_forces = forces
)
saveRDS(robustness, "data/robustness_models.rds")
saveRDS(panel_nv, "data/panel_with_nonvictim.rds")
saveRDS(panel_rape, "data/panel_with_rape.rds")

cat("\nRobustness models saved.\n")
