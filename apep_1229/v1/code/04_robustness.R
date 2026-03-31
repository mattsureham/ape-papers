# 04_robustness.R — Robustness checks
# apep_1229: GIPP and Insurance Market Competition

source("00_packages.R")

data_dir <- "../data/"
load(paste0(data_dir, "models.RData"))

# ============================================================================
# 1. Alternative DiD: Transport vs House Insurance
# ============================================================================
cat("=== 1. Alternative control: House Insurance ===\n")

cpih_long2 <- cpih_est %>%
  select(date, year, month, event_time, post_gipp, log_cpih,
         log_transport_ins, log_house_ins) %>%
  pivot_longer(
    cols = c(log_transport_ins, log_house_ins),
    names_to = "series",
    values_to = "log_index"
  ) %>%
  mutate(
    is_transport = as.integer(series == "log_transport_ins"),
    treat_post = is_transport * post_gipp
  )

m_rob1 <- feols(log_index ~ treat_post + is_transport + post_gipp + log_cpih,
                data = cpih_long2, vcov = "hetero")
cat("Transport vs House DiD:", round(coef(m_rob1)["treat_post"], 4),
    "(", round(se(m_rob1)["treat_post"], 4), ")\n")

# ============================================================================
# 2. Pre-GIPP placebo test (fake treatment at Jan 2020)
# ============================================================================
cat("\n=== 2. Placebo test: fake GIPP at Jan 2020 ===\n")

cpih_placebo <- cpih_est %>%
  filter(date < as.Date("2022-01-01")) %>%
  mutate(
    placebo_post = as.integer(date >= as.Date("2020-01-01")),
    log_transport_ins2 = log(transport_ins),
    log_health_ins2 = log(health_ins)
  ) %>%
  select(date, year, month, placebo_post, log_cpih,
         log_transport_ins2, log_health_ins2) %>%
  pivot_longer(
    cols = c(log_transport_ins2, log_health_ins2),
    names_to = "series",
    values_to = "log_index"
  ) %>%
  mutate(
    is_transport = as.integer(series == "log_transport_ins2"),
    treat_post = is_transport * placebo_post
  )

m_placebo <- feols(log_index ~ treat_post + is_transport + placebo_post + log_cpih,
                   data = cpih_placebo, vcov = "hetero")
cat("Placebo DiD (Jan 2020):", round(coef(m_placebo)["treat_post"], 4),
    "(", round(se(m_placebo)["treat_post"], 4), ")\n")

# ============================================================================
# 3. Shorter pre-period (2019-2025)
# ============================================================================
cat("\n=== 3. Shorter window: 2019-2025 ===\n")

cpih_short <- cpih_est %>%
  filter(year >= 2019) %>%
  select(date, year, month, event_time, post_gipp, log_cpih,
         log_transport_ins, log_health_ins) %>%
  pivot_longer(
    cols = c(log_transport_ins, log_health_ins),
    names_to = "series",
    values_to = "log_index"
  ) %>%
  mutate(
    is_transport = as.integer(series == "log_transport_ins"),
    treat_post = is_transport * post_gipp
  )

m_short <- feols(log_index ~ treat_post + is_transport + post_gipp + log_cpih,
                 data = cpih_short, vcov = "hetero")
cat("Short-window DiD:", round(coef(m_short)["treat_post"], 4),
    "(", round(se(m_short)["treat_post"], 4), ")\n")

# ============================================================================
# 4. Annual CPI growth rates (reduces autocorrelation)
# ============================================================================
cat("\n=== 4. YoY growth rate DiD ===\n")

cpih_yoy <- cpih_est %>%
  filter(!is.na(transport_ins_yoy), !is.na(health_ins_yoy)) %>%
  select(date, year, month, event_time, post_gipp,
         transport_ins_yoy, health_ins_yoy) %>%
  pivot_longer(
    cols = c(transport_ins_yoy, health_ins_yoy),
    names_to = "series",
    values_to = "yoy_change"
  ) %>%
  mutate(
    is_transport = as.integer(series == "transport_ins_yoy"),
    treat_post = is_transport * post_gipp
  )

m_yoy <- feols(yoy_change ~ treat_post + is_transport + post_gipp,
               data = cpih_yoy, vcov = "hetero")
cat("YoY growth DiD:", round(coef(m_yoy)["treat_post"], 4),
    "(", round(se(m_yoy)["treat_post"], 4), ")\n")

# ============================================================================
# 5. Save robustness models
# ============================================================================

save(m_rob1, m_placebo, m_short, m_yoy,
     cpih_long2, cpih_placebo, cpih_short, cpih_yoy,
     file = paste0(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
