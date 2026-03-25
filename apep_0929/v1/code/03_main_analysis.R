# 03_main_analysis.R — Main DiD analysis of Furusato Nozei gift cap

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Sample overview ===\n")
cat("Observations:", nrow(df), "\n")
cat("Municipalities:", n_distinct(df$muni_id), "\n")
cat("Treated:", sum(df$treat_binary == 1 & df$fy == 2018), "\n")
cat("Control:", sum(df$treat_binary == 0 & df$fy == 2018), "\n")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("\n=== Summary Statistics ===\n")

pre_data <- df %>% filter(fy <= 2018)
post_data <- df %>% filter(fy >= 2020)

summ_stats <- bind_rows(
  # Full sample
  df %>% summarise(
    Panel = "Full Sample",
    N = n(),
    `Mean Donations (¥M)` = mean(donation_amount / 1000, na.rm = TRUE),
    `SD Donations (¥M)` = sd(donation_amount / 1000, na.rm = TRUE),
    `Mean Count` = mean(donation_count, na.rm = TRUE),
    `Mean Gift Rate` = mean(fy2018_gift_rate, na.rm = TRUE),
    Municipalities = n_distinct(muni_id)
  ),
  # Treated
  df %>% filter(treat_binary == 1) %>% summarise(
    Panel = "Treated (Rate > 30%)",
    N = n(),
    `Mean Donations (¥M)` = mean(donation_amount / 1000, na.rm = TRUE),
    `SD Donations (¥M)` = sd(donation_amount / 1000, na.rm = TRUE),
    `Mean Count` = mean(donation_count, na.rm = TRUE),
    `Mean Gift Rate` = mean(fy2018_gift_rate, na.rm = TRUE),
    Municipalities = n_distinct(muni_id)
  ),
  # Control
  df %>% filter(treat_binary == 0) %>% summarise(
    Panel = "Control (Rate <= 30%)",
    N = n(),
    `Mean Donations (¥M)` = mean(donation_amount / 1000, na.rm = TRUE),
    `SD Donations (¥M)` = sd(donation_amount / 1000, na.rm = TRUE),
    `Mean Count` = mean(donation_count, na.rm = TRUE),
    `Mean Gift Rate` = mean(fy2018_gift_rate, na.rm = TRUE),
    Municipalities = n_distinct(muni_id)
  )
)

print(summ_stats)

# ============================================================
# MAIN SPECIFICATION: DiD with continuous treatment intensity
# ============================================================

cat("\n=== Main Results ===\n")

# Spec 1: Binary treatment × post
m1 <- feols(log_donations ~ treat_binary:post | muni_id + fy,
            data = df, cluster = ~prefecture)

# Spec 2: Continuous treatment intensity × post
m2 <- feols(log_donations ~ treat_intensity:post | muni_id + fy,
            data = df, cluster = ~prefecture)

# Spec 3: Gift rate (continuous) × post
m3 <- feols(log_donations ~ I(fy2018_gift_rate * post) | muni_id + fy,
            data = df, cluster = ~prefecture)

# Spec 4: Donation count (extensive margin)
m4 <- feols(log(donation_count + 1) ~ treat_binary:post | muni_id + fy,
            data = df, cluster = ~prefecture)

cat("Model 1 - Binary DiD (log donations):\n")
summary(m1)
cat("\nModel 2 - Continuous intensity DiD (log donations):\n")
summary(m2)
cat("\nModel 3 - Gift rate × post (log donations):\n")
summary(m3)
cat("\nModel 4 - Binary DiD (log donation count):\n")
summary(m4)

# ============================================================
# EVENT STUDY
# ============================================================

cat("\n=== Event Study ===\n")

# Create relative time dummies (base: FY2018, one period before reform)
df <- df %>%
  mutate(
    rel_time = fy - 2019,
    # Recode: rel_time for pre is -4,-3,-2,-1; for post is 1,2,3,4,5
    # FY2015 = -4, FY2016 = -3, FY2017 = -2, FY2018 = -1
    # FY2020 = 1, FY2021 = 2, FY2022 = 3, FY2023 = 4, FY2024 = 5
    rel_time_factor = factor(rel_time)
  )

# Event study: binary treatment
es_binary <- feols(
  log_donations ~ i(rel_time, treat_binary, ref = -1) | muni_id + fy,
  data = df, cluster = ~prefecture
)

cat("Event study coefficients:\n")
summary(es_binary)

# Event study: continuous treatment intensity
es_continuous <- feols(
  log_donations ~ i(rel_time, treat_intensity, ref = -1) | muni_id + fy,
  data = df, cluster = ~prefecture
)

# ============================================================
# MECHANISM: Redistribution test
# ============================================================

cat("\n=== Redistribution Test ===\n")

# If the cap redistributes donations, we should see:
# 1. High-gift municipalities lose donations
# 2. Medium-gift municipalities (near 30%) gain donations
# Tertiles of gift rate
df <- df %>%
  mutate(
    gift_tercile = case_when(
      fy2018_gift_rate <= 0.20 ~ "Low (<20%)",
      fy2018_gift_rate <= 0.30 ~ "Medium (20-30%)",
      TRUE ~ "High (>30%)"
    ),
    gift_tercile = factor(gift_tercile, levels = c("Medium (20-30%)", "Low (<20%)", "High (>30%)"))
  )

m_tercile <- feols(
  log_donations ~ i(gift_tercile, post, ref = "Medium (20-30%)") | muni_id + fy,
  data = df, cluster = ~prefecture
)

cat("Redistribution by gift rate tercile (base: medium 20-30%):\n")
summary(m_tercile)

# ============================================================
# Save results for tables
# ============================================================

results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  es_binary = es_binary, es_continuous = es_continuous,
  m_tercile = m_tercile,
  summ_stats = summ_stats
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================
# Write diagnostics.json for validate_v1.py
# ============================================================

diag <- list(
  n_treated = sum(df$treat_binary == 1 & df$fy == 2018, na.rm = TRUE),
  n_pre = length(unique(df$fy[df$fy < 2019])),
  n_obs = nrow(df)
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\ndiagnostics.json:", toJSON(diag, auto_unbox = TRUE), "\n")

cat("\nMain analysis complete.\n")
