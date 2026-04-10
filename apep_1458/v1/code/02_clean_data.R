source("00_packages.R")

cat("=== Building analysis dataset ===\n")

systems <- readRDS("../data/water_systems.rds")
viol_health <- readRDS("../data/violations_health.rds")
viol_mon <- readRDS("../data/violations_mon.rds")
viol_mcl <- readRDS("../data/violations_mcl.rds")

# --- Monitoring schedule: 40 CFR 141.21(a)(2) ---
thresholds <- tibble(
  cutoff = c(1000, 2500, 3300, 4100, 4900, 5800, 6700, 7600, 8500),
  samples_below = c(1, 2, 3, 4, 5, 6, 7, 8, 9),
  samples_above = c(2, 3, 4, 5, 6, 7, 8, 9, 10),
  pct_increase = round((samples_above - samples_below) / samples_below * 100)
)
cat("Monitoring thresholds:\n")
print(thresholds)

# --- Clean systems ---
names(systems) <- tolower(names(systems))
names(viol_health) <- tolower(names(viol_health))
names(viol_mon) <- tolower(names(viol_mon))
names(viol_mcl) <- tolower(names(viol_mcl))

sys <- systems %>%
  transmute(
    pwsid,
    pop = as.numeric(population_served_count),
    source_type = case_when(
      gw_sw_code == "GW" ~ "Groundwater",
      gw_sw_code == "SW" ~ "Surface water",
      gw_sw_code == "GU" ~ "GW under influence",
      TRUE ~ "Other"
    ),
    state = state_code,
    owner_type = owner_type_code,
    connections = as.numeric(service_connections_count)
  ) %>%
  filter(!is.na(pop), pop > 0)

cat("Active CWS with valid population:", nrow(sys), "\n")
cat("Population distribution:\n")
print(summary(sys$pop))

# --- Required monitoring ---
assign_monitoring <- function(pop) {
  case_when(
    pop <= 1000   ~ 1L, pop <= 2500   ~ 2L, pop <= 3300   ~ 3L,
    pop <= 4100   ~ 4L, pop <= 4900   ~ 5L, pop <= 5800   ~ 6L,
    pop <= 6700   ~ 7L, pop <= 7600   ~ 8L, pop <= 8500   ~ 9L,
    pop <= 12900  ~ 10L, pop <= 17200  ~ 15L, pop <= 21500  ~ 20L,
    pop <= 25000  ~ 25L, pop <= 33000  ~ 30L, TRUE ~ 40L
  )
}
sys <- sys %>% mutate(required_samples = assign_monitoring(pop))

# --- Nearest threshold ---
sys <- sys %>%
  rowwise() %>%
  mutate(
    nearest_cutoff = {
      dists <- abs(pop - thresholds$cutoff)
      thresholds$cutoff[which.min(dists)]
    },
    dist_to_cutoff = pop - nearest_cutoff,
    above = as.integer(pop > nearest_cutoff)
  ) %>%
  ungroup()

# --- Aggregate violations to system level ---
cat("\n--- Processing violations ---\n")

# Coliform-related MCL violations (contaminant 2950 = total coliform, 3100 = E. coli)
coliform_mcl <- viol_mcl %>%
  filter(contaminant_code %in% c("2950", "3100")) %>%
  distinct(pwsid, violation_id) %>%
  count(pwsid, name = "n_coliform_mcl")
cat("Systems with coliform MCL violations:", nrow(coliform_mcl), "\n")

# All health-based violations
health_viol <- viol_health %>%
  distinct(pwsid, violation_id) %>%
  count(pwsid, name = "n_health")
cat("Systems with health violations:", nrow(health_viol), "\n")

# Monitoring violations (coliform-related)
coliform_mon <- viol_mon %>%
  filter(contaminant_code %in% c("2950", "3100")) %>%
  distinct(pwsid, violation_id) %>%
  count(pwsid, name = "n_coliform_mon")
cat("Systems with coliform monitoring violations:", nrow(coliform_mon), "\n")

# Non-coliform MCL violations (for placebo outcome)
noncoliform_mcl <- viol_mcl %>%
  filter(!(contaminant_code %in% c("2950", "3100"))) %>%
  distinct(pwsid, violation_id) %>%
  count(pwsid, name = "n_noncoliform_mcl")
cat("Systems with non-coliform MCL violations:", nrow(noncoliform_mcl), "\n")

# --- Merge ---
df <- sys %>%
  left_join(coliform_mcl, by = "pwsid") %>%
  left_join(health_viol, by = "pwsid") %>%
  left_join(coliform_mon, by = "pwsid") %>%
  left_join(noncoliform_mcl, by = "pwsid") %>%
  mutate(
    across(starts_with("n_"), ~replace_na(.x, 0L)),
    any_coliform_mcl = as.integer(n_coliform_mcl > 0),
    any_health = as.integer(n_health > 0),
    any_monitoring = as.integer(n_coliform_mon > 0),
    any_noncoliform = as.integer(n_noncoliform_mcl > 0)
  )

# --- RDD analysis sample ---
df_rdd <- df %>% filter(abs(dist_to_cutoff) <= 5000)
cat("\n--- RDD sample (|dist| <= 5000):", nrow(df_rdd), "systems ---\n")

cat("\nSystems near each threshold (|dist| <= 2000):\n")
df_rdd %>%
  filter(abs(dist_to_cutoff) <= 2000) %>%
  count(nearest_cutoff, above) %>%
  pivot_wider(names_from = above, values_from = n, names_prefix = "above_") %>%
  print()

cat("\nViolation rates by monitoring band:\n")
df %>%
  group_by(required_samples) %>%
  summarise(
    n = n(),
    coliform_rate = mean(any_coliform_mcl) * 100,
    health_rate = mean(any_health) * 100,
    monitoring_rate = mean(any_monitoring) * 100,
    .groups = "drop"
  ) %>%
  print(n = 20)

# --- Save ---
saveRDS(df, "../data/analysis_full.rds")
saveRDS(df_rdd, "../data/analysis_rdd.rds")
saveRDS(thresholds, "../data/thresholds.rds")

cat("\n=== Data cleaning complete ===\n")
