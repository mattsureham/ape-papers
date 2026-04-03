## 02_clean_data.R — Construct analysis datasets
## APEP-1349: Dutch BPM Multi-Cutoff Bunching

source("00_packages.R")

# --- Load raw data ---
df <- readRDS("../data/co2_distributions.rds")
fuel_df <- readRDS("../data/fuel_type_breakdown.rds")

# --- BPM tax schedule (July 2020 onwards, WLTP) ---
# Source: Wet op de belasting van personenauto's en motorrijwielen 1992
# The BPM is a kink (not a notch): the per-gram rate changes at each threshold
# but the tax level is continuous across boundaries

bpm_schedule <- data.frame(
  band = 1:5,
  co2_min = c(0, 80, 102, 142, 158),     # Bands: [0,79], [80,101], [102,141], [142,157], [158+]
  co2_max = c(79, 101, 141, 157, 999),
  base_eur = c(667, 825, 2563, 9483, 14027),
  rate_per_g = c(2, 79, 173, 284, 568)
)

# Verify tax continuity at boundaries
# At 79: band 1 = 667 + 79*2 = 825; band 2 base = 825 → continuous
# At 101: band 2 = 825 + (101-79)*79 = 825 + 1738 = 2563; band 3 base = 2563 → continuous
# At 141: band 3 = 2563 + (141-101)*173 = 2563 + 6920 = 9483; band 4 base = 9483 → continuous
# At 157: band 4 = 9483 + (157-141)*284 = 9483 + 4544 = 14027; band 5 base = 14027 → continuous

cat("=== BPM Tax Schedule Verification ===\n")
calc_bpm <- function(co2) {
  if (co2 <= 0) return(0)
  if (co2 <= 79) return(667 + co2 * 2)
  if (co2 <= 101) return(825 + (co2 - 79) * 79)
  if (co2 <= 141) return(2563 + (co2 - 101) * 173)
  if (co2 <= 157) return(9483 + (co2 - 141) * 284)
  return(14027 + (co2 - 157) * 568)
}

# Show tax at each kink
for (co2 in c(79, 80, 101, 102, 141, 142, 157, 158)) {
  tax <- calc_bpm(co2)
  cat(sprintf("  CO2=%d: BPM=€%s\n", co2, format(tax, big.mark = ",")))
}

# Calculate marginal rate change at each kink
kinks <- data.frame(
  kink_co2 = c(79, 101, 141, 157),
  rate_below = c(2, 79, 173, 284),
  rate_above = c(79, 173, 284, 568),
  label = c("K1: 79 g/km", "K2: 101 g/km", "K3: 141 g/km", "K4: 157 g/km")
)
kinks$rate_ratio <- kinks$rate_above / kinks$rate_below
kinks$rate_jump <- kinks$rate_above - kinks$rate_below

cat("\n=== Kink Structure ===\n")
print(kinks)

# --- Construct pooled NL distribution ---
nl_pooled <- df %>%
  filter(country == "NL") %>%
  group_by(co2) %>%
  summarise(count = sum(count), .groups = "drop") %>%
  arrange(co2)

# Fill in zeros for missing CO2 values
full_range <- data.frame(co2 = 1:250)
nl_pooled <- full_range %>%
  left_join(nl_pooled, by = "co2") %>%
  mutate(count = replace_na(count, 0))

# --- Construct pooled DE distribution ---
de_pooled <- df %>%
  filter(country == "DE") %>%
  group_by(co2) %>%
  summarise(count = sum(count), .groups = "drop") %>%
  arrange(co2)

de_pooled <- full_range %>%
  left_join(de_pooled, by = "co2") %>%
  mutate(count = replace_na(count, 0))

# --- Normalize distributions for NL-DE comparison ---
nl_total <- sum(nl_pooled$count)
de_total <- sum(de_pooled$count)

nl_pooled$density <- nl_pooled$count / nl_total
de_pooled$density <- de_pooled$count / de_total

comparison <- nl_pooled %>%
  select(co2, nl_count = count, nl_density = density) %>%
  left_join(
    de_pooled %>% select(co2, de_count = count, de_density = density),
    by = "co2"
  )

# --- PHEV vs ICE decomposition (from fuel type data) ---
fuel_near79 <- fuel_df %>%
  filter(region == "n79") %>%
  mutate(
    powertrain = case_when(
      grepl("ELECTRIC", fuel_type) ~ "PHEV",
      TRUE ~ "ICE"
    )
  ) %>%
  group_by(co2, powertrain) %>%
  summarise(count = sum(count), .groups = "drop")

cat("\n=== PHEV vs ICE near 79 g/km (NL pooled 2020-2022) ===\n")
fuel_wide <- fuel_near79 %>%
  pivot_wider(names_from = powertrain, values_from = count, values_fill = 0) %>%
  filter(co2 >= 70, co2 <= 95) %>%
  mutate(total = ICE + PHEV, phev_share = PHEV / total)
print(fuel_wide, n = 30)

# --- Save analysis datasets ---
saveRDS(nl_pooled, "../data/nl_pooled.rds")
saveRDS(de_pooled, "../data/de_pooled.rds")
saveRDS(comparison, "../data/nl_de_comparison.rds")
saveRDS(kinks, "../data/kinks.rds")
saveRDS(fuel_near79, "../data/fuel_near79.rds")

cat("\n02_clean_data.R complete.\n")
