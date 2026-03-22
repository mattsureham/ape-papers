## 04_robustness.R — Robustness checks and heterogeneity
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")
analysis <- analysis %>%
  mutate(
    state_fips = substr(fips, 1, 2),
    treat      = conv_share_pre * post
  )

# ---- Heterogeneity: Rural vs Urban ----
cat("=== Heterogeneity: Rural vs Urban ===\n")
analysis <- analysis %>%
  mutate(rural_safe = ifelse(is.na(rural), 0L, rural))

het_rural <- feols(log(1 + convenience) ~
                     treat + I(treat * rural_safe) | fips + year,
                   data = analysis, cluster = ~state_fips)
print(summary(het_rural))

# ---- Heterogeneity: High vs Low Poverty ----
cat("\n=== Heterogeneity: High vs Low Poverty ===\n")
analysis <- analysis %>%
  mutate(high_pov = as.integer(poverty_rate >= median(poverty_rate, na.rm = TRUE)))

het_pov <- feols(log(1 + convenience) ~
                   treat + I(treat * high_pov) | fips + year,
                 data = analysis, cluster = ~state_fips)
print(summary(het_pov))

# ---- Placebo: Pre-period fake treatment (2014) ----
cat("\n=== Placebo: Fake treatment at 2014 ===\n")
pre_data <- analysis %>% filter(year <= 2017)
pre_data <- pre_data %>%
  mutate(fake_post = as.integer(year >= 2014),
         fake_treat = conv_share_pre * fake_post)

placebo_m <- feols(log(1 + convenience) ~ fake_treat | fips + year,
                   data = pre_data, cluster = ~state_fips)
print(summary(placebo_m))

# ---- Alternative: Level specification ----
cat("\n=== Alternative: Levels (no log) ===\n")
m_level <- feols(convenience ~ treat | fips + year,
                 data = analysis, cluster = ~state_fips)
print(summary(m_level))

# ---- Alternative: State × Year FE ----
cat("\n=== State × Year FE ===\n")
m_styr <- feols(log(1 + convenience) ~ treat | fips + state_fips^year,
                data = analysis, cluster = ~state_fips)
print(summary(m_styr))

# ---- Save robustness results ----
rob_results <- list(
  het_rural = het_rural,
  het_pov   = het_pov,
  placebo   = placebo_m,
  m_level   = m_level,
  m_styr    = m_styr
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("Robustness analysis complete.\n")
