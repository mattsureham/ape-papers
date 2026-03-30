## 04_robustness.R — Robustness checks and mechanism analysis
## apep_1164: The Formalization Dividend
source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
panel_nc <- readRDS(file.path(data_dir, "panel_no_covid.rds"))
treatment <- readRDS(file.path(data_dir, "treatment_intensity.rds"))

# ============================================================
# 1. Pre-trend tests
# ============================================================
cat("=== Pre-trend Tests ===\n\n")

# Formal test: interaction of ven_share with linear pre-trend (2015-2019)
pre_panel <- panel_nc %>% filter(year < 2021)
pre_trend_to <- feols(to ~ ven_share:year | dept_fe + year_fe,
                      data = pre_panel, cluster = ~department)
pre_trend_td <- feols(td ~ ven_share:year | dept_fe + year_fe,
                      data = pre_panel, cluster = ~department)

cat("Pre-trend test (ven_share × year, 2015-2019):\n")
cat("  TO: coef =", round(coef(pre_trend_to), 4),
    ", p =", round(pvalue(pre_trend_to), 3), "\n")
cat("  TD: coef =", round(coef(pre_trend_td), 4),
    ", p =", round(pvalue(pre_trend_td), 3), "\n")

# ============================================================
# 2. Alternative treatment measures
# ============================================================
cat("\n=== Alternative Treatment Measures ===\n\n")

# (a) Binary treatment: above-median Venezuelan share
panel_nc <- panel_nc %>%
  mutate(
    high_ven_post = high_ven * post,
    treat_quartile = as.integer(ven_quartile == "Q4_High") * post
  )

m_binary <- feols(to ~ high_ven_post | dept_fe + year_fe,
                  data = panel_nc, cluster = ~department)
cat("Binary treatment (above-median):\n")
cat("  TO: coef =", round(coef(m_binary), 3),
    ", SE =", round(se(m_binary), 3),
    ", p =", round(pvalue(m_binary), 3), "\n")

# (b) Top quartile vs rest
m_q4 <- feols(to ~ treat_quartile | dept_fe + year_fe,
              data = panel_nc, cluster = ~department)
cat("Top quartile treatment:\n")
cat("  TO: coef =", round(coef(m_q4), 3),
    ", SE =", round(se(m_q4), 3),
    ", p =", round(pvalue(m_q4), 3), "\n")

# ============================================================
# 3. Placebo tests
# ============================================================
cat("\n=== Placebo Tests ===\n\n")

# (a) Placebo treatment date: 2018 instead of 2021
panel_placebo <- panel_nc %>%
  filter(year < 2021) %>%
  mutate(
    post_placebo = as.integer(year >= 2018),
    treat_placebo = ven_share * post_placebo
  )

m_placebo_to <- feols(to ~ treat_placebo | dept_fe + year_fe,
                      data = panel_placebo, cluster = ~department)
m_placebo_td <- feols(td ~ treat_placebo | dept_fe + year_fe,
                      data = panel_placebo, cluster = ~department)

cat("Placebo (2018 treatment date, pre-period only):\n")
cat("  TO: coef =", round(coef(m_placebo_to), 4),
    ", p =", round(pvalue(m_placebo_to), 3), "\n")
cat("  TD: coef =", round(coef(m_placebo_td), 4),
    ", p =", round(pvalue(m_placebo_td), 3), "\n")

# (b) Placebo outcome: population outside labor force (should not change)
panel_nc <- panel_nc %>%
  mutate(pct_out_lf = out_labor_force / pet * 100)

m_placebo_out <- feols(pct_out_lf ~ treat_intensity | dept_fe + year_fe,
                       data = panel_nc, cluster = ~department)
cat("Placebo outcome (% outside labor force):\n")
cat("  coef =", round(coef(m_placebo_out), 4),
    ", p =", round(pvalue(m_placebo_out), 3), "\n")

# ============================================================
# 4. Department-specific trends
# ============================================================
cat("\n=== Department-Specific Trends ===\n\n")

panel_nc <- panel_nc %>%
  mutate(dept_trend = dept_id * year)

m_trends_to <- feols(to ~ treat_intensity | dept_fe + year_fe + dept_fe[year],
                     data = panel_nc, cluster = ~department)
m_trends_td <- feols(td ~ treat_intensity | dept_fe + year_fe + dept_fe[year],
                     data = panel_nc, cluster = ~department)

cat("With department-specific linear trends:\n")
cat("  TO: coef =", round(coef(m_trends_to), 4),
    ", SE =", round(se(m_trends_to), 4),
    ", p =", round(pvalue(m_trends_to), 3), "\n")
cat("  TD: coef =", round(coef(m_trends_td), 4),
    ", SE =", round(se(m_trends_td), 4),
    ", p =", round(pvalue(m_trends_td), 3), "\n")

# ============================================================
# 5. Leave-one-out: Exclude Norte de Santander (highest treatment)
# ============================================================
cat("\n=== Leave-One-Out ===\n\n")

m_loo_to <- feols(to ~ treat_intensity | dept_fe + year_fe,
                  data = panel_nc %>% filter(department != "Norte de Santander"),
                  cluster = ~department)
m_loo_td <- feols(td ~ treat_intensity | dept_fe + year_fe,
                  data = panel_nc %>% filter(department != "Norte de Santander"),
                  cluster = ~department)

cat("Excluding Norte de Santander:\n")
cat("  TO: coef =", round(coef(m_loo_to), 4),
    ", SE =", round(se(m_loo_to), 4),
    ", p =", round(pvalue(m_loo_to), 3), "\n")
cat("  TD: coef =", round(coef(m_loo_td), 4),
    ", SE =", round(se(m_loo_td), 4),
    ", p =", round(pvalue(m_loo_td), 3), "\n")

# Exclude La Guajira (second highest)
m_loo2_to <- feols(to ~ treat_intensity | dept_fe + year_fe,
                   data = panel_nc %>% filter(!department %in% c("Norte de Santander", "La Guajira")),
                   cluster = ~department)
cat("Excluding Norte de Santander + La Guajira:\n")
cat("  TO: coef =", round(coef(m_loo2_to), 4),
    ", SE =", round(se(m_loo2_to), 4),
    ", p =", round(pvalue(m_loo2_to), 3), "\n")

# ============================================================
# 6. Heterogeneity: by baseline informality
# ============================================================
cat("\n=== Heterogeneity ===\n\n")

# Departments with above-median underemployment (TS) in 2019 as proxy for informality
ts_2019 <- panel %>% filter(year == 2019) %>% select(department, ts_2019 = ts)
panel_nc <- panel_nc %>% left_join(ts_2019, by = "department") %>%
  mutate(high_informal = as.integer(ts_2019 > median(ts_2019, na.rm=TRUE)))

m_het_to <- feols(to ~ treat_intensity + treat_intensity:high_informal | dept_fe + year_fe,
                  data = panel_nc, cluster = ~department)
cat("Heterogeneity by baseline underemployment:\n")
etable(m_het_to, se.below = TRUE)

# By baseline employment rate
to_2019 <- panel %>% filter(year == 2019) %>% select(department, to_2019 = to)
panel_nc <- panel_nc %>% left_join(to_2019, by = "department") %>%
  mutate(high_emp = as.integer(to_2019 > median(to_2019, na.rm=TRUE)))

m_het_emp <- feols(to ~ treat_intensity + treat_intensity:high_emp | dept_fe + year_fe,
                   data = panel_nc, cluster = ~department)
cat("Heterogeneity by baseline employment rate:\n")
etable(m_het_emp, se.below = TRUE)

# ============================================================
# 7. Sectoral composition (mechanism)
# ============================================================
cat("\n=== Sectoral Composition ===\n\n")

# Sectoral analysis deferred to tables script (complex parsing)
cat("Sectoral composition analysis deferred to 05_tables.R\n")

# ============================================================
# 8. Power calculation
# ============================================================
cat("\n=== Ex-Post Power ===\n\n")

# Minimum detectable effect (MDE) at 80% power
# With our SE of ~0.40 for employment rate:
mde <- 2.8 * se(m2_to <- feols(to ~ treat_intensity | dept_fe + year_fe,
                                data = panel_nc, cluster = ~department))["treat_intensity"]
cat("Minimum detectable effect (80% power):", round(mde, 2), "pp per 1pp Venezuelan share\n")
cat("For Norte de Santander (17.4% share): MDE =", round(mde * 17.4, 1), "pp\n")
cat("For median department (3.9% share): MDE =", round(mde * 3.9, 1), "pp\n")

# ============================================================
# 9. Save robustness models
# ============================================================
saveRDS(list(
  pre_trend_to = pre_trend_to, pre_trend_td = pre_trend_td,
  m_binary = m_binary, m_q4 = m_q4,
  m_placebo_to = m_placebo_to, m_placebo_td = m_placebo_td,
  m_placebo_out = m_placebo_out,
  m_trends_to = m_trends_to, m_trends_td = m_trends_td,
  m_loo_to = m_loo_to, m_loo_td = m_loo_td,
  m_het_to = m_het_to, m_het_emp = m_het_emp
), file.path(data_dir, "robustness_models.rds"))

cat("\n=== Robustness checks complete ===\n")
