# 04_robustness.R — Robustness checks
# apep_1079: Section 301 tariffs and racial employment effects

source("00_packages.R")

df <- readRDS("../data/analysis_panel_final.rds")
placebo_df <- readRDS("../data/placebo_panel.rds")

cat("Analysis panel:", nrow(df), "rows\n")

# ============================================================
# 1. Service-sector placebo (DDD)
# ============================================================
cat("\n=== Placebo: Service Sectors ===\n")

placebo_df <- placebo_df %>%
  mutate(
    fips = sprintf("%05d", as.integer(geography)),
    state_fips = substr(fips, 1, 2),
    naics3 = substr(industry, 1, 3),
    yrq = year + (quarter - 1) / 4,
    time_id = (year - 2015) * 4 + quarter,
    post = as.integer(yrq >= 2018.5),
    log_emp = log(Emp),
    is_asian = as.integer(race == "A4"),
    is_black = as.integer(race == "A2"),
    cell_id = paste(fips, naics3, race, sep = "_"),
    race_qtr = paste(race, year, quarter, sep = "_"),
    state = state_fips,
    tariff_max = 0,
    high_exposure = 0L
  ) %>%
  filter(race != "A0", !is.na(Emp), Emp > 0)

# Stack mfg + services
stacked <- bind_rows(
  df %>% mutate(is_mfg = 1L) %>%
    select(fips, naics3, race, year, quarter, time_id, post,
           log_emp, is_asian, is_black, cell_id, race_qtr, state, is_mfg),
  placebo_df %>% mutate(is_mfg = 0L) %>%
    select(fips, naics3, race, year, quarter, time_id, post,
           log_emp, is_asian, is_black, cell_id, race_qtr, state, is_mfg)
)

m_ddd <- feols(
  log_emp ~ is_mfg:post + is_mfg:post:is_asian + is_mfg:post:is_black |
    cell_id + race_qtr,
  data = stacked,
  cluster = ~state
)
cat("DDD (Mfg × Post × Race):\n")
summary(m_ddd)

# ============================================================
# 2. Leave-one-industry-out
# ============================================================
cat("\n=== Leave-One-Industry-Out ===\n")

industries <- unique(df$naics3)
loo_results <- list()

for (ind in industries) {
  m_loo <- feols(
    log_emp ~ tariff_max:post + tariff_max:post:is_asian +
      tariff_max:post:is_black | cell_id + race_qtr,
    data = df %>% filter(naics3 != ind),
    cluster = ~state
  )

  loo_results[[ind]] <- tibble(
    dropped = ind,
    beta_base = coef(m_loo)["tariff_max:post"],
    beta_asian = coef(m_loo)["tariff_max:post:is_asian"],
    beta_black = coef(m_loo)["tariff_max:post:is_black"],
    se_asian = se(m_loo)["tariff_max:post:is_asian"]
  )
}

loo_df <- bind_rows(loo_results)
cat("Leave-one-out:\n")
print(loo_df %>% mutate(across(where(is.numeric), ~round(., 4))))

# ============================================================
# 3. Alternative clustering
# ============================================================
cat("\n=== Alternative Clustering ===\n")

# Preferred spec with different clustering
m_base <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr,
  data = df,
  cluster = ~state
)

m_county <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr,
  data = df,
  cluster = ~fips
)

m_twoway <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr,
  data = df,
  cluster = ~state + naics3
)

cat("State-clustered SE(Asian):", round(se(m_base)["tariff_max:post:is_asian"], 4), "\n")
cat("County-clustered SE(Asian):", round(se(m_county)["tariff_max:post:is_asian"], 4), "\n")
cat("Two-way SE(Asian):", round(se(m_twoway)["tariff_max:post:is_asian"], 4), "\n")

# ============================================================
# 4. Pre-treatment placebo timing
# ============================================================
cat("\n=== Placebo Timing ===\n")

pre_only <- df %>%
  filter(post == 0) %>%
  mutate(fake_post = as.integer(yrq >= 2017.0))

m_placebo <- feols(
  log_emp ~ tariff_max:fake_post + tariff_max:fake_post:is_asian +
    tariff_max:fake_post:is_black | cell_id + race_qtr,
  data = pre_only,
  cluster = ~state
)
cat("Placebo timing (fake post = 2017Q1):\n")
summary(m_placebo)

# ============================================================
# 5. Hires and separations
# ============================================================
cat("\n=== Hires and Separations ===\n")

df <- df %>%
  mutate(
    log_hires = ifelse(HirA > 0, log(HirA), NA_real_),
    log_sep = ifelse(Sep > 0, log(Sep), NA_real_)
  )

m_hires <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr,
  data = df %>% mutate(log_emp = log_hires) %>% filter(!is.na(log_emp)),
  cluster = ~state
)

m_sep <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr,
  data = df %>% mutate(log_emp = log_sep) %>% filter(!is.na(log_emp)),
  cluster = ~state
)

cat("Hires:\n"); summary(m_hires)
cat("Separations:\n"); summary(m_sep)

# ============================================================
# Save
# ============================================================
robust <- list(
  m_ddd = m_ddd,
  loo_df = loo_df,
  m_base = m_base, m_county = m_county, m_twoway = m_twoway,
  m_placebo = m_placebo,
  m_hires = m_hires, m_sep = m_sep
)
saveRDS(robust, "../data/robustness_results.rds")

cat("\nRobustness complete.\n")
