## 04_robustness.R — apep_0697
## Robustness checks for NZ foreign buyer ban

source("00_packages.R")

data_dir <- "../data"

quarterly_panel <- readRDS(file.path(data_dir, "quarterly_panel.rds"))
annual_panel <- readRDS(file.path(data_dir, "annual_panel.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))

# Harmonize names
name_map <- c(
  "Waitematā" = "Waitemata", "Kaipātiki" = "Kaipatiki",
  "Puketāpapa" = "Puketapapa", "Ōrakei" = "Orakei",
  "Māngere-Ōtāhuhu" = "Mangere-Otahuhu",
  "Ōtara-Papatoetoe" = "Otara-Papatoetoe",
  "Maungakiekie-Tāmaki" = "Maungakiekie-Tamaki",
  "Waitākere Ranges" = "Waitakere Ranges"
)
quarterly_panel <- quarterly_panel %>%
  mutate(area = if_else(area %in% names(name_map), name_map[area], area))
annual_panel <- annual_panel %>%
  mutate(area = if_else(area %in% names(name_map), name_map[area], area))

# Reconstruct analysis panel
quarterly_panel <- quarterly_panel %>%
  mutate(post_ban = as.integer(date >= as.Date("2018-12-01")))

pre_ban_intensity <- quarterly_panel %>%
  filter(post_ban == 0) %>%
  group_by(area) %>%
  summarize(pre_ban_pct = mean(foreign_buyer_pct, na.rm = TRUE),
            n_pre = sum(!is.na(foreign_buyer_pct)), .groups = "drop") %>%
  filter(!is.na(pre_ban_pct), n_pre >= 2)

qp <- quarterly_panel %>%
  inner_join(pre_ban_intensity, by = "area") %>%
  filter(!is.na(foreign_buyer_pct)) %>%
  mutate(
    high_exposure = as.integer(pre_ban_pct > median(pre_ban_intensity$pre_ban_pct)),
    quarter_fe = factor(paste0(year, "Q", quarter)),
    event_time = round(as.numeric(difftime(date, as.Date("2018-09-01"), units = "days")) / 90)
  )

# ============================================================
# 1. Leave-one-out: Drop Auckland region
# ============================================================
cat("=== Robustness: Leave-one-out ===\n")

# Drop Auckland (the dominant market)
qp_no_auckland <- qp %>%
  filter(!grepl("Auckland region", area))

m_no_auck <- feols(foreign_buyer_pct ~ i(event_time, pre_ban_pct, ref = 0) | area + quarter_fe,
                   data = qp_no_auckland, cluster = ~area)
cat("\nLeave-one-out (drop Auckland region):\n")
print(coeftable(m_no_auck))

# Drop Queenstown-Lakes
qp_no_qt <- qp %>%
  filter(!grepl("Queenstown", area))

m_no_qt <- feols(foreign_buyer_pct ~ i(event_time, pre_ban_pct, ref = 0) | area + quarter_fe,
                 data = qp_no_qt, cluster = ~area)
cat("\nLeave-one-out (drop Queenstown-Lakes):\n")
print(coeftable(m_no_qt))

# ============================================================
# 2. Placebo treatment date: 2017 Q4 (1 year before actual ban)
# ============================================================
cat("\n=== Robustness: Placebo treatment date (2017Q4) ===\n")

qp_placebo <- qp %>%
  filter(date < as.Date("2018-12-01")) %>%  # Only pre-ban data
  mutate(
    placebo_post = as.integer(date >= as.Date("2017-12-01")),
    event_time_placebo = round(as.numeric(difftime(date, as.Date("2017-09-01"), units = "days")) / 90)
  )

m_placebo <- feols(foreign_buyer_pct ~ placebo_post:pre_ban_pct | area + quarter_fe,
                   data = qp_placebo, cluster = ~area)
cat("Placebo test (fake ban at 2017Q4, pre-ban data only):\n")
print(summary(m_placebo))

# ============================================================
# 3. Annual panel DiD (longer time horizon)
# ============================================================
cat("\n=== Robustness: Annual panel (2016-2024) ===\n")

# Annual data: treatment is year >= 2019 (first full post-ban year)
# Year-ended dates differ by release, so approximate:
# Years <= 2018 are pre-ban, >= 2019 are post-ban

annual_pre_ban <- annual_panel %>%
  filter(year <= 2018) %>%
  group_by(area) %>%
  summarize(pre_ban_pct_annual = mean(foreign_buyer_pct, na.rm = TRUE),
            n_pre = sum(!is.na(foreign_buyer_pct)), .groups = "drop") %>%
  filter(!is.na(pre_ban_pct_annual), n_pre >= 1)

ap <- annual_panel %>%
  inner_join(annual_pre_ban, by = "area") %>%
  filter(!is.na(foreign_buyer_pct)) %>%
  mutate(
    post_ban = as.integer(year >= 2019),
    year_fe = factor(year)
  )

m_annual <- feols(foreign_buyer_pct ~ post_ban:pre_ban_pct_annual | area + year_fe,
                  data = ap, cluster = ~area)
cat("Annual DiD (2016-2024):\n")
print(summary(m_annual))

# Annual event study
ap <- ap %>%
  mutate(event_year = year - 2018)

m_annual_es <- feols(foreign_buyer_pct ~ i(event_year, pre_ban_pct_annual, ref = 0) | area + year_fe,
                     data = ap, cluster = ~area)
cat("\nAnnual event study:\n")
print(coeftable(m_annual_es))

# ============================================================
# 4. Alternative treatment intensity: top vs bottom tertile
# ============================================================
cat("\n=== Robustness: Top vs bottom tertile ===\n")

tertiles <- quantile(pre_ban_intensity$pre_ban_pct, probs = c(1/3, 2/3))

qp <- qp %>%
  mutate(
    exposure_group = case_when(
      pre_ban_pct <= tertiles[1] ~ "Low",
      pre_ban_pct <= tertiles[2] ~ "Medium",
      TRUE ~ "High"
    ),
    exposure_group = factor(exposure_group, levels = c("Low", "Medium", "High"))
  )

# Compare high vs low (dropping medium)
qp_hl <- qp %>% filter(exposure_group != "Medium")

m_tertile <- feols(foreign_buyer_pct ~ i(exposure_group, post_ban, ref = "Low") | area + quarter_fe,
                   data = qp_hl, cluster = ~area)
cat("Top vs bottom tertile:\n")
print(summary(m_tertile))

# ============================================================
# Save robustness models
# ============================================================
saveRDS(list(
  m_no_auck = m_no_auck,
  m_no_qt = m_no_qt,
  m_placebo = m_placebo,
  m_annual = m_annual,
  m_annual_es = m_annual_es,
  m_tertile = m_tertile
), file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
