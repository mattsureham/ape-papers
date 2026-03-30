## ── 03_main_analysis.R ────────────────────────────────────────────────────
## Main DiD analysis: RTW effects on Black-White earnings gap
## ───────────────────────────────────────────────────────────────────────────

source("00_packages.R")

panel <- readRDS("../data/panel_all.rds")
panel_mfg <- readRDS("../data/panel_mfg.rds")

## ══════════════════════════════════════════════════════════════════════════
## 1. TWFE DDD: State × Race × Post
## ══════════════════════════════════════════════════════════════════════════

cat("=== Model 1: TWFE DDD ===\n")

# Main DDD specification
# Outcome: log earnings
# Key coefficient: treated_state:post:black (triple interaction)
# Create explicit triple interaction (lower-order terms absorbed by FE)
panel$ddd <- as.integer(panel$treated_state & panel$post == 1 & panel$black == 1)

m1_ddd <- feols(
  log_earn ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel,
  cluster = ~state_fips
)

cat("\nDDD coefficient (RTW × Post × Black):\n")
print(summary(m1_ddd))

## ══════════════════════════════════════════════════════════════════════════
## 2. Callaway-Sant'Anna by race
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== Model 2: CS DiD by race ===\n")

# Separate CS DiD for Black workers
panel_black <- panel %>%
  filter(race == "A2") %>%
  # Aggregate to county level (one obs per county-time)
  group_by(county_fips, time, state_fips, first_treat) %>%
  summarise(
    log_earn = weighted.mean(log_earn, w = Emp, na.rm = TRUE),
    emp = sum(Emp, na.rm = TRUE),
    earn = weighted.mean(EarnS, w = Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(unit_num = as.integer(factor(county_fips)))

panel_white <- panel %>%
  filter(race == "A1") %>%
  group_by(county_fips, time, state_fips, first_treat) %>%
  summarise(
    log_earn = weighted.mean(log_earn, w = Emp, na.rm = TRUE),
    emp = sum(Emp, na.rm = TRUE),
    earn = weighted.mean(EarnS, w = Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(unit_num = as.integer(factor(county_fips)))

# CS DiD for Black workers
cat("  Running CS DiD for Black workers...\n")
cs_black <- tryCatch(
  att_gt(
    yname = "log_earn",
    tname = "time",
    idname = "unit_num",
    gname = "first_treat",
    data = as.data.frame(panel_black),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  ),
  error = function(e) {
    cat(sprintf("  CS DiD Black error: %s\n", e$message))
    NULL
  }
)

# CS DiD for White workers
cat("  Running CS DiD for White workers...\n")
cs_white <- tryCatch(
  att_gt(
    yname = "log_earn",
    tname = "time",
    idname = "unit_num",
    gname = "first_treat",
    data = as.data.frame(panel_white),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  ),
  error = function(e) {
    cat(sprintf("  CS DiD White error: %s\n", e$message))
    NULL
  }
)

# Aggregate ATTs
if (!is.null(cs_black)) {
  agg_black <- aggte(cs_black, type = "simple")
  cat(sprintf("\nCS DiD Black ATT: %.4f (SE: %.4f)\n",
              agg_black$overall.att, agg_black$overall.se))

  es_black <- aggte(cs_black, type = "dynamic", min_e = -12, max_e = 20)
  cat("  Event study aggregated (Black).\n")
}

if (!is.null(cs_white)) {
  agg_white <- aggte(cs_white, type = "simple")
  cat(sprintf("CS DiD White ATT: %.4f (SE: %.4f)\n",
              agg_white$overall.att, agg_white$overall.se))

  es_white <- aggte(cs_white, type = "dynamic", min_e = -12, max_e = 20)
  cat("  Event study aggregated (White).\n")
}

## ══════════════════════════════════════════════════════════════════════════
## 3. Sun-Abraham heterogeneity-robust estimator
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== Model 3: Sun-Abraham event study ===\n")

# Create relative time variable for sunab
panel <- panel %>%
  mutate(
    rel_time = ifelse(first_treat > 0, time - first_treat, NA_real_)
  )

# Sun-Abraham for Black workers
m3_black <- feols(
  log_earn ~ sunab(first_treat, time) | county_fips + time,
  data = panel %>% filter(race == "A2"),
  cluster = ~state_fips
)

m3_white <- feols(
  log_earn ~ sunab(first_treat, time) | county_fips + time,
  data = panel %>% filter(race == "A1"),
  cluster = ~state_fips
)

cat("Sun-Abraham Black ATT:\n")
summary(m3_black, agg = "ATT")
cat("\nSun-Abraham White ATT:\n")
summary(m3_white, agg = "ATT")

## ══════════════════════════════════════════════════════════════════════════
## 4. Manufacturing mechanism
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== Model 4: Manufacturing subsector ===\n")

panel_mfg$ddd <- as.integer(panel_mfg$treated_state & panel_mfg$post == 1 & panel_mfg$black == 1)

m4_mfg_ddd <- feols(
  log_earn ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel_mfg,
  cluster = ~state_fips
)

cat("\nManufacturing DDD coefficient:\n")
print(coeftable(m4_mfg_ddd))

## ══════════════════════════════════════════════════════════════════════════
## 5. Employment and separation margins
## ══════════════════════════════════════════════════════════════════════════

cat("\n=== Model 5: Employment margin ===\n")

m5_emp <- feols(
  log(Emp) ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel,
  cluster = ~state_fips
)

cat("\nEmployment DDD coefficient:\n")
print(coeftable(m5_emp))

cat("\n=== Model 6: Separation rate ===\n")

panel_sep <- panel %>% filter(!is.na(sep_rate))
panel_sep$ddd <- as.integer(panel_sep$treated_state & panel_sep$post == 1 & panel_sep$black == 1)

m6_sep <- feols(
  sep_rate ~ ddd |
    county_fips^race + time^race + state_fips^time,
  data = panel_sep,
  cluster = ~state_fips
)

cat("\nSeparation rate DDD coefficient:\n")
print(coeftable(m6_sep))

## ── Save results ─────────────────────────────────────────────────────────
results <- list(
  m1_ddd = m1_ddd,
  cs_black = cs_black,
  cs_white = cs_white,
  es_black = if (exists("es_black")) es_black else NULL,
  es_white = if (exists("es_white")) es_white else NULL,
  m3_black = m3_black,
  m3_white = m3_white,
  m4_mfg_ddd = m4_mfg_ddd,
  m5_emp = m5_emp,
  m6_sep = m6_sep
)

saveRDS(results, "../data/main_results.rds")

## ── Write diagnostics.json ───────────────────────────────────────────────
n_treated_counties <- panel %>%
  filter(treated_state) %>%
  pull(county_fips) %>%
  n_distinct()

n_pre <- panel %>%
  filter(treated_state & time < min(panel$first_treat[panel$first_treat > 0])) %>%
  pull(time) %>%
  n_distinct()

diag <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = nrow(panel)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\nMain analysis complete.\n")
