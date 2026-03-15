## 03_main_analysis.R — apep_0697
## Main DiD analysis: NZ Foreign Buyer Ban

source("00_packages.R")

data_dir <- "../data"

# Load cleaned data
quarterly_panel <- readRDS(file.path(data_dir, "quarterly_panel.rds"))
annual_panel <- readRDS(file.path(data_dir, "annual_panel.rds"))
national_quarterly <- readRDS(file.path(data_dir, "national_quarterly.rds"))
bis_data <- readRDS(file.path(data_dir, "bis_house_prices.rds"))

# ============================================================
# 0. Harmonize area names (macron variants)
# ============================================================
name_map <- c(
  "Waitematā" = "Waitemata",
  "Kaipātiki" = "Kaipatiki",
  "Puketāpapa" = "Puketapapa",
  "Ōrakei" = "Orakei",
  "Māngere-Ōtāhuhu" = "Mangere-Otahuhu",
  "Ōtara-Papatoetoe" = "Otara-Papatoetoe",
  "Maungakiekie-Tāmaki" = "Maungakiekie-Tamaki",
  "Waitākere Ranges" = "Waitakere Ranges"
)

harmonize_names <- function(df) {
  df %>%
    mutate(area = if_else(area %in% names(name_map), name_map[area], area))
}

quarterly_panel <- harmonize_names(quarterly_panel)
annual_panel <- harmonize_names(annual_panel)

# ============================================================
# 1. Construct quarterly panel for DiD
# ============================================================
# Treatment date: October 22, 2018 (ban effective)
# Q3 2018 (Jul-Sep) is the last pre-ban quarter
# Q4 2018 (Oct-Dec) is the first post-ban quarter

quarterly_panel <- quarterly_panel %>%
  mutate(
    post_ban = date >= as.Date("2018-12-01"),  # Q4 2018 onwards
    time_to_ban = as.numeric(difftime(date, as.Date("2018-09-01"), units = "days")) / 90  # quarters relative to Q3 2018
  )

# Calculate pre-ban foreign buyer intensity (treatment intensity)
pre_ban_intensity <- quarterly_panel %>%
  filter(!post_ban) %>%
  group_by(area) %>%
  summarize(
    pre_ban_pct = mean(foreign_buyer_pct, na.rm = TRUE),
    pre_ban_count = mean(foreign_buyer_count, na.rm = TRUE),
    n_pre = sum(!is.na(foreign_buyer_pct)),
    .groups = "drop"
  ) %>%
  filter(!is.na(pre_ban_pct), n_pre >= 2)  # Need at least 2 pre-ban observations

cat("Treatment intensity distribution:\n")
summary(pre_ban_intensity$pre_ban_pct)
cat(sprintf("  Areas with pre-ban data: %d\n", nrow(pre_ban_intensity)))

# Merge treatment intensity into quarterly panel
qp <- quarterly_panel %>%
  inner_join(pre_ban_intensity, by = "area") %>%
  filter(!is.na(foreign_buyer_pct))

# Binary high/low treatment (above/below median pre-ban share)
median_exposure <- median(pre_ban_intensity$pre_ban_pct)
cat(sprintf("  Median pre-ban foreign buyer %%: %.2f\n", median_exposure))

qp <- qp %>%
  mutate(
    high_exposure = pre_ban_pct > median_exposure,
    # Quarter fixed effects
    quarter_fe = factor(paste0(year, "Q", quarter))
  )

cat(sprintf("\nAnalysis sample: %d area-quarter obs, %d areas, %d quarters\n",
            nrow(qp), n_distinct(qp$area), n_distinct(qp$quarter_fe)))

# ============================================================
# 2. Main specification: Continuous treatment intensity DiD
# ============================================================
# Y_{it} = alpha_i + gamma_t + beta * (ForeignShare_i x Post_t) + e_{it}

cat("\n=== MAIN RESULTS ===\n\n")

# Spec 1: Continuous treatment intensity
m1 <- feols(foreign_buyer_pct ~ pre_ban_pct:post_ban | area + quarter_fe,
            data = qp, cluster = ~area)
cat("Spec 1: Continuous treatment DiD\n")
print(summary(m1))

# Spec 2: Binary high/low exposure DiD
m2 <- feols(foreign_buyer_pct ~ high_exposure:post_ban | area + quarter_fe,
            data = qp, cluster = ~area)
cat("\nSpec 2: Binary high/low exposure DiD\n")
print(summary(m2))

# Spec 3: Foreign buyer COUNT as outcome (levels, not percentage)
m3 <- feols(foreign_buyer_count ~ pre_ban_pct:post_ban | area + quarter_fe,
            data = qp %>% filter(!is.na(foreign_buyer_count)),
            cluster = ~area)
cat("\nSpec 3: Foreign buyer count as outcome\n")
print(summary(m3))

# ============================================================
# 3. Event study: Quarter-by-quarter effects
# ============================================================
cat("\n=== EVENT STUDY ===\n\n")

# Create event time variable (relative to Q3 2018 = last pre-ban quarter)
# Reference: use Q3 2018 (event time 0 = last pre-ban)
qp <- qp %>%
  mutate(
    event_time = round(time_to_ban),
    event_time_f = factor(event_time)
  )

# Drop the reference period (event_time = 0, which is Q3 2018)
m_es <- feols(foreign_buyer_pct ~ i(event_time_f, pre_ban_pct, ref = "0") | area + quarter_fe,
              data = qp, cluster = ~area)
cat("Event study (interaction with continuous treatment intensity):\n")
print(summary(m_es))

# ============================================================
# 4. National-level analysis
# ============================================================
cat("\n=== NATIONAL QUARTERLY DATA ===\n")
national_quarterly <- national_quarterly %>%
  mutate(post_ban = date >= as.Date("2018-12-01"))

cat("National foreign buyer % over time:\n")
national_quarterly %>%
  select(date, foreign_buyer_pct, foreign_buyers, total_known_buyers) %>%
  print(n = 30)

# Pre-ban vs post-ban national averages
national_summary <- national_quarterly %>%
  group_by(post_ban) %>%
  summarize(
    mean_foreign_pct = mean(foreign_buyer_pct, na.rm = TRUE),
    mean_foreign_count = mean(foreign_buyers, na.rm = TRUE),
    mean_total = mean(total_known_buyers, na.rm = TRUE),
    n_quarters = n(),
    .groups = "drop"
  )
cat("\nNational pre vs post ban:\n")
print(national_summary)

# ============================================================
# 5. SCM on BIS house prices (supplementary)
# ============================================================
cat("\n=== SYNTHETIC CONTROL (supplementary) ===\n\n")

# Prepare BIS data for SCM
bis_wide <- bis_data %>%
  mutate(
    year_q = as.numeric(format(date, "%Y")) + (as.numeric(format(date, "%m")) - 1) / 12,
    time_id = dense_rank(date)
  ) %>%
  filter(!is.na(value))

# Treatment: NZ, time ~55 (2018 Q3)
nz_treat_time <- bis_wide %>%
  filter(country == "NZ", date >= as.Date("2018-07-01"), date <= as.Date("2018-09-30")) %>%
  pull(time_id) %>%
  first()

cat(sprintf("NZ treatment time ID: %d\n", nz_treat_time))

# Prepare Synth dataprep
# Use country numeric IDs
country_ids <- bis_wide %>%
  distinct(country) %>%
  mutate(country_id = row_number())

bis_synth <- bis_wide %>%
  left_join(country_ids, by = "country") %>%
  arrange(country_id, time_id)

# Run Synth
tryCatch({
  dp <- dataprep(
    foo = as.data.frame(bis_synth %>% select(country_id, time_id, value)),
    predictors = "value",
    predictors.op = "mean",
    dependent = "value",
    unit.variable = "country_id",
    time.variable = "time_id",
    treatment.identifier = country_ids$country_id[country_ids$country == "NZ"],
    controls.identifier = country_ids$country_id[country_ids$country != "NZ"],
    time.predictors.prior = 1:nz_treat_time,
    time.optimize.ssr = 1:nz_treat_time,
    time.plot = 1:max(bis_synth$time_id)
  )

  synth_out <- synth(dp)

  # Gap = NZ - Synthetic NZ
  gap <- dp$Y1plot - dp$Y0plot %*% synth_out$solution.w
  gap_df <- tibble(
    time_id = as.integer(rownames(dp$Y1plot)),
    nz_actual = as.numeric(dp$Y1plot),
    nz_synthetic = as.numeric(dp$Y0plot %*% synth_out$solution.w),
    gap = as.numeric(gap)
  ) %>%
    left_join(bis_synth %>% distinct(time_id, date = date), by = "time_id")

  # Post-ban average gap
  post_gap <- gap_df %>%
    filter(time_id > nz_treat_time) %>%
    summarize(mean_gap = mean(gap), sd_gap = sd(gap))

  cat(sprintf("SCM post-ban gap: %.2f (SD = %.2f)\n", post_gap$mean_gap, post_gap$sd_gap))

  # Donor weights
  w <- synth_out$solution.w
  cat("\nSCM donor weights:\n")
  for (i in seq_along(w)) {
    cc <- country_ids$country[country_ids$country_id == dp$names.and.numbers$controls.identifier[i]]
    if (w[i] > 0.01) cat(sprintf("  %s: %.3f\n", cc, w[i]))
  }

  # Save SCM results
  saveRDS(list(gap = gap_df, weights = w, synth = synth_out, dataprep = dp),
          file.path(data_dir, "scm_results.rds"))

}, error = function(e) {
  cat("SCM failed:", e$message, "\n")
  cat("Proceeding without SCM — regional DiD is the main design.\n")
})

# ============================================================
# 6. Save diagnostics for validation
# ============================================================
diagnostics <- list(
  n_treated = n_distinct(qp$area),  # All areas treated (continuous intensity DiD)
  n_pre = n_distinct(qp$quarter_fe[!qp$post_ban]),
  n_obs = nrow(qp),
  n_areas = n_distinct(qp$area),
  n_quarters = n_distinct(qp$quarter_fe),
  median_exposure = median_exposure,
  treatment_date = "2018-Q4"
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
print(diagnostics)

# Save main models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m_es = m_es),
        file.path(data_dir, "main_models.rds"))
