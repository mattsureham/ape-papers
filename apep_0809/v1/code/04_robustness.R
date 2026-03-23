## 04_robustness.R — Robustness checks for apep_0809
source("00_packages.R")
if (basename(getwd()) == "code") setwd("..")

df <- readRDS("data/analysis_panel.rds")
df <- df |>
  mutate(
    high_exposure = share_construction + coalesce(share_agriculture, 0),
    post = as.integer(year >= 2007),
    post_a8 = as.integer(year >= 2007),
    post_a2 = as.integer(year >= 2012)
  )

# ============================================================================
# 1. PLACEBO TEST — Pre-treatment trends
# ============================================================================
cat("=== Placebo: Pre-treatment trends ===\n")

# Test: is high_exposure associated with FN trends BEFORE 2004?
# If so, our design has a pre-trend problem
df_pre <- df |> filter(year <= 2002)

# 1995 → 2002 change (both pre-enlargement)
df_pre_wide <- df_pre |>
  select(dept_code, year, fn_vote_share, high_exposure) |>
  pivot_wider(names_from = year, values_from = fn_vote_share, names_prefix = "fn_") |>
  mutate(
    delta_fn_95_02 = fn_2002 - fn_1995
  )

placebo_pre <- lm(delta_fn_95_02 ~ high_exposure, data = df_pre_wide)
cat("  Pre-trend test (1995→2002 change ~ exposure):\n")
cat(sprintf("  Coef = %.3f, SE = %.3f, p = %.3f\n",
            coef(placebo_pre)["high_exposure"],
            sqrt(vcov(placebo_pre)["high_exposure", "high_exposure"]),
            summary(placebo_pre)$coefficients["high_exposure", "Pr(>|t|)"]))

# ============================================================================
# 2. EVENT STUDY — Period-by-period effects
# ============================================================================
cat("\n=== Event study ===\n")

# Interact exposure with each election year (omit 2002 as reference)
df <- df |>
  mutate(
    yr_1995 = as.integer(year == 1995),
    yr_2007 = as.integer(year == 2007),
    yr_2012 = as.integer(year == 2012),
    yr_2017 = as.integer(year == 2017),
    yr_2022 = as.integer(year == 2022)
  )

m_event <- feols(
  fn_vote_share ~ high_exposure:yr_1995 + high_exposure:yr_2007 +
    high_exposure:yr_2012 + high_exposure:yr_2017 + high_exposure:yr_2022 |
    dept_code + year,
  data = df, cluster = ~dept_code
)

cat("  Event study (reference = 2002):\n")
etable(m_event, se.below = TRUE)

# Extract event study coefficients for table
event_coefs <- tibble(
  year = c(1995, 2002, 2007, 2012, 2017, 2022),
  coef = c(coef(m_event)["high_exposure:yr_1995"], 0,
           coef(m_event)["high_exposure:yr_2007"],
           coef(m_event)["high_exposure:yr_2012"],
           coef(m_event)["high_exposure:yr_2017"],
           coef(m_event)["high_exposure:yr_2022"]),
  se = c(se(m_event)["high_exposure:yr_1995"], 0,
         se(m_event)["high_exposure:yr_2007"],
         se(m_event)["high_exposure:yr_2012"],
         se(m_event)["high_exposure:yr_2017"],
         se(m_event)["high_exposure:yr_2022"])
)
cat("  Event study coefficients:\n")
print(event_coefs)

# ============================================================================
# 3. ALTERNATIVE MEASURES — Different exposure definitions
# ============================================================================
cat("\n=== Alternative exposure measures ===\n")

# a) Construction share only (excluding agriculture)
m_constr <- feols(fn_vote_share ~ share_construction:post | dept_code + year,
                  data = df, cluster = ~dept_code)

# b) Agriculture share only
m_agric <- feols(fn_vote_share ~ I(coalesce(share_agriculture, 0)):post |
                   dept_code + year, data = df, cluster = ~dept_code)

# c) Manufacturing share (tradable sector — should NOT respond to posted workers)
m_manuf <- feols(fn_vote_share ~
                   I(coalesce(share_manufacturing, share_industry, 0)):post |
                   dept_code + year, data = df, cluster = ~dept_code)

cat("  Sector-specific effects:\n")
etable(m_constr, m_agric, m_manuf,
       headers = c("Construction", "Agriculture", "Manufacturing (Placebo)"),
       se.below = TRUE)

# ============================================================================
# 4. CONTROLLING FOR CHINA SHOCK
# ============================================================================
cat("\n=== China shock control ===\n")

m_china <- feols(fn_vote_share ~ high_exposure:post + china_shock |
                   dept_code + year, data = df, cluster = ~dept_code)

cat("  With China import shock control:\n")
etable(m_china, se.below = TRUE)

# ============================================================================
# 5. EXCLUDING OUTLIERS
# ============================================================================
cat("\n=== Excluding Paris/Corsica ===\n")

# Paris (75) and Corsica (2A, 2B) are unusual
df_no_outlier <- df |> filter(!dept_code %in% c("75", "2A", "2B"))

m_no_outlier <- feols(fn_vote_share ~ high_exposure:post | dept_code + year,
                      data = df_no_outlier, cluster = ~dept_code)
cat("  Without Paris/Corsica:\n")
etable(m_no_outlier, se.below = TRUE)

# ============================================================================
# 6. ALTERNATIVE CLUSTERING
# ============================================================================
cat("\n=== Alternative clustering ===\n")

# Cluster at NUTS2 (region) level instead of département
df$nuts2_cl <- case_when(
  df$dept_code %in% c("75","77","78","91","92","93","94","95") ~ "FR10",
  df$dept_code %in% c("59","62") ~ "FRE1",
  df$dept_code %in% c("02","60","80") ~ "FRE2",
  df$dept_code %in% c("13","83","84","04","05","06") ~ "FRL0",
  df$dept_code %in% c("31","09","12","32","46","65","81","82") ~ "FRJ1",
  df$dept_code %in% c("69","01","07","26","38","42","43","73","74","03","15","63") ~ "FRK1",
  df$dept_code %in% c("67","68") ~ "FRF1",
  df$dept_code %in% c("54","55","57","88") ~ "FRF2",
  df$dept_code %in% c("44","49","53","72","85") ~ "FRG0",
  df$dept_code %in% c("22","29","35","56") ~ "FRH0",
  df$dept_code %in% c("2A","2B") ~ "FRM0",
  TRUE ~ paste0("FR_", substr(df$dept_code, 1, 1))
)

m_region_cluster <- feols(fn_vote_share ~ high_exposure:post | dept_code + year,
                          data = df, cluster = ~nuts2_cl)

cat("  Clustered at NUTS2 level:\n")
etable(m_region_cluster, se.below = TRUE)

# ============================================================================
# Save robustness results
# ============================================================================
robustness <- list(
  placebo_pre = placebo_pre,
  event_study = m_event,
  event_coefs = event_coefs,
  m_constr = m_constr,
  m_agric = m_agric,
  m_manuf = m_manuf,
  m_china = m_china,
  m_no_outlier = m_no_outlier,
  m_region_cluster = m_region_cluster
)

saveRDS(robustness, "data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
