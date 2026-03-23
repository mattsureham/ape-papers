# 04_robustness.R — Robustness checks and placebo tests
source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")

# ============================================================================
# 1. Placebo treatment: Germany as fake treated country
# ============================================================================
cat("=== PLACEBO: Germany as fake treated ===\n\n")

panel_placebo_de <- panel %>%
  filter(country != "FR") %>%
  mutate(
    germany = as.integer(country == "DE"),
    germany_high_post = germany * high_conn * as.integer(year >= 2017)
  )

m_placebo_de <- feols(long_hours_pct ~ germany_high_post |
                        country_isco + country_year + isco_year,
                      data = panel_placebo_de, cluster = ~country)

cat("Germany placebo DDD:\n")
summary(m_placebo_de)

# ============================================================================
# 2. Spain as positive control (R2D law in 2018)
# ============================================================================
cat("\n=== POSITIVE CONTROL: Spain R2D (2018) ===\n\n")

# Need to fetch Spain data — check if in the raw data
long_hours_raw <- readRDS("../data/long_hours_raw.rds")
usual_hours_raw <- readRDS("../data/usual_hours_raw.rds")

isco_high <- c("OC1", "OC2", "OC3")
isco_low  <- c("OC7", "OC8", "OC9")
isco_mid  <- c("OC5")
isco_all  <- c(isco_high, isco_low, isco_mid)

# Add Spain to control set (without France)
spain_countries <- c("ES", "DE", "NL", "AT", "FI", "DK", "CZ", "PL", "HU")

spain_lh <- long_hours_raw %>%
  mutate(year = as.integer(TIME_PERIOD)) %>%
  filter(geo %in% spain_countries, isco08 %in% isco_all,
         sex == "T", age == "Y15-64", wstatus == "EMP", unit == "PC",
         year >= 2010, year <= 2024) %>%
  rename(country = geo, isco = isco08, long_hours_pct = values) %>%
  select(country, isco, year, long_hours_pct) %>%
  filter(!is.na(long_hours_pct))

if (nrow(spain_lh) > 0 && "ES" %in% unique(spain_lh$country)) {
  spain_panel <- spain_lh %>%
    mutate(
      spain = as.integer(country == "ES"),
      high_conn = as.integer(isco %in% isco_high),
      post = as.integer(year >= 2018),
      spain_high_post = spain * high_conn * post,
      country_isco = paste0(country, "_", isco),
      country_year = paste0(country, "_", year),
      isco_year = paste0(isco, "_", year)
    )

  m_spain <- feols(long_hours_pct ~ spain_high_post |
                     country_isco + country_year + isco_year,
                   data = spain_panel, cluster = ~country)
  cat("Spain DDD (treatment = 2018):\n")
  summary(m_spain)
} else {
  cat("Spain data not available in sample.\n")
  m_spain <- NULL
}

# ============================================================================
# 3. Placebo occupation: Medium-connectivity (ISCO 5) as treatment
# ============================================================================
cat("\n=== PLACEBO OCCUPATION: Medium-connectivity ===\n\n")

panel_mid <- panel %>%
  filter(conn_group %in% c("Medium", "Low")) %>%
  mutate(
    mid_conn = as.integer(conn_group == "Medium"),
    france_mid_post = france * mid_conn * post,
    country_isco = paste0(country, "_", isco),
    country_year = paste0(country, "_", year),
    isco_year = paste0(isco, "_", year)
  )

m_placebo_mid <- feols(long_hours_pct ~ france_mid_post |
                         country_isco + country_year + isco_year,
                       data = panel_mid, cluster = ~country)
cat("Medium-connectivity placebo DDD:\n")
summary(m_placebo_mid)

# ============================================================================
# 4. Permutation inference: randomize treatment across countries
# ============================================================================
cat("\n=== PERMUTATION INFERENCE ===\n\n")

set.seed(42)
n_perms <- 1000
countries <- unique(panel$country)

perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  fake_treated <- sample(countries, 1)
  panel_perm <- panel %>%
    mutate(
      fake_france = as.integer(country == fake_treated),
      fake_ddd = fake_france * high_conn * post
    )

  m_perm <- tryCatch(
    feols(long_hours_pct ~ fake_ddd |
            country_isco + country_year + isco_year,
          data = panel_perm),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["fake_ddd"]
  } else {
    perm_coefs[i] <- NA
  }
}

actual_coef <- coef(models$m1)["france_high_post"]
perm_pval <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)

cat(sprintf("Actual DDD coefficient: %.3f\n", actual_coef))
cat(sprintf("Permutation p-value (two-sided): %.4f\n", perm_pval))
cat(sprintf("Permutation distribution: mean=%.3f, sd=%.3f\n",
            mean(perm_coefs, na.rm = TRUE), sd(perm_coefs, na.rm = TRUE)))

# ============================================================================
# 5. Alternative outcome: usual hours
# ============================================================================
cat("\n=== ALTERNATIVE OUTCOME: Usual weekly hours ===\n\n")
# Already done in m2 — just confirm
cat(sprintf("Usual hours DDD: %.3f (SE=%.3f, p=%.4f)\n",
            coef(models$m2)["france_high_post"],
            se(models$m2)["france_high_post"],
            pvalue(models$m2)["france_high_post"]))

# ============================================================================
# 6. Exclude COVID years (2020-2021)
# ============================================================================
cat("\n=== ROBUSTNESS: Exclude COVID years ===\n\n")

panel_nocovid <- panel %>% filter(!(year %in% c(2020, 2021)))

m_nocovid <- feols(long_hours_pct ~ france_high_post |
                     country_isco + country_year + isco_year,
                   data = panel_nocovid, cluster = ~country)
cat("DDD excluding 2020-2021:\n")
summary(m_nocovid)

# ============================================================================
# 7. Pre-trend test: DDD on pre-period only (2010-2016), fake treatment at 2014
# ============================================================================
cat("\n=== PRE-TREND TEST: Fake treatment at 2014 ===\n\n")

panel_pre <- panel %>%
  filter(year <= 2016) %>%
  mutate(
    fake_post = as.integer(year >= 2014),
    france_high_fakepost = france * high_conn * fake_post,
    country_isco = paste0(country, "_", isco),
    country_year = paste0(country, "_", year),
    isco_year = paste0(isco, "_", year)
  )

m_pretrend <- feols(long_hours_pct ~ france_high_fakepost |
                      country_isco + country_year + isco_year,
                    data = panel_pre, cluster = ~country)
cat("Pre-trend test (fake treatment 2014):\n")
summary(m_pretrend)

# ============================================================================
# Save robustness models
# ============================================================================
robustness <- list(
  placebo_de = m_placebo_de,
  spain = m_spain,
  placebo_mid = m_placebo_mid,
  nocovid = m_nocovid,
  pretrend = m_pretrend,
  perm_coefs = perm_coefs,
  perm_pval = perm_pval,
  actual_coef = actual_coef
)
saveRDS(robustness, "../data/robustness.rds")
cat("\nRobustness models saved.\n")
