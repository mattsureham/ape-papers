# 02_clean_data.R — Construct analysis variables
# apep_1071: Golden Visa and Existing-New Dwelling Price Divergence

source("00_packages.R")

hpi <- read_csv("../data/hpi_quarterly.csv", show_col_types = FALSE)

# ── Treatment definitions ─────────────────────────────────────────

# Golden Visa launch: October 8, 2012 → first full quarter = 2012-Q4
# Golden Visa residential suspension: February 16, 2023 → 2023-Q1
treatment_start <- as.Date("2012-10-01")
suspension_start <- as.Date("2023-01-01")

hpi <- hpi %>%
  mutate(
    # Treatment indicators
    portugal = as.integer(country == "PT"),
    existing = as.integer(dwelling_type == "DW_EXST"),
    post = as.integer(time >= treatment_start),
    post_suspension = as.integer(time >= suspension_start),

    # DDD interaction
    ddd = portugal * existing * post,

    # Fixed effects identifiers
    country_dwelling = paste(country, dwelling_type, sep = "_"),
    quarter_id = as.integer(factor(time)),
    unit_id = as.integer(factor(country_dwelling)),

    # Event time (quarters relative to treatment)
    event_time = as.integer(round(
      as.numeric(difftime(time, treatment_start, units = "days")) / 91.25
    ))
  )

# ── Create within-country existing-new gap ────────────────────────
gap_data <- hpi %>%
  select(country, time, dwelling_type, hpi, quarter_id) %>%
  pivot_wider(names_from = dwelling_type, values_from = hpi) %>%
  filter(!is.na(DW_EXST), !is.na(DW_NEW)) %>%
  mutate(
    gap = DW_EXST - DW_NEW,
    portugal = as.integer(country == "PT"),
    post = as.integer(time >= treatment_start),
    post_suspension = as.integer(time >= suspension_start)
  )

# ── Summary statistics ────────────────────────────────────────────
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Countries in panel:", length(unique(gap_data$country)), "\n")
cat("Quarters:", length(unique(gap_data$quarter_id)), "\n")
cat("Total gap observations:", nrow(gap_data), "\n")

# Gap by country and period
cat("\n=== EXISTING-NEW GAP BY COUNTRY (Pre vs Post) ===\n")
gap_summary <- gap_data %>%
  group_by(country, post) %>%
  summarise(
    mean_gap = mean(gap, na.rm = TRUE),
    sd_gap = sd(gap, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(gap_change = mean_gap - lag(mean_gap)) %>%
  filter(post == 1) %>%
  arrange(desc(gap_change))

# Show gap changes
for (i in seq_len(nrow(gap_summary))) {
  r <- gap_summary[i, ]
  cat(sprintf("  %s: gap change = %+.1f (post mean = %.1f)\n",
              r$country, r$gap_change, r$mean_gap))
}

# ── Save analysis datasets ───────────────────────────────────────
write_csv(hpi, "../data/analysis_panel.csv")
write_csv(gap_data, "../data/gap_data.csv")

cat("\nSaved analysis_panel.csv (", nrow(hpi), "rows) and gap_data.csv (",
    nrow(gap_data), "rows)\n")
