# =============================================================================
# 03_main_analysis.R — Main DiD regressions
# =============================================================================

source("00_packages.R")

analysis      <- readRDS("../data/analysis.rds")
analysis_long <- readRDS("../data/analysis_long.rds")

# ---------------------------------------------------------------------------
# 1. Descriptive statistics
# ---------------------------------------------------------------------------
# Pre-period means by treatment status
desc <- analysis %>%
  filter(year <= 2016) %>%
  group_by(has_closure) %>%
  summarise(
    n_counties      = n_distinct(county_fips),
    mean_cc_total   = mean(cc_total, na.rm = TRUE),
    mean_cc_black   = mean(cc_black, na.rm = TRUE),
    mean_cc_hispanic = mean(cc_hispanic, na.rm = TRUE),
    mean_cc_white   = mean(cc_white, na.rm = TRUE),
    mean_displaced  = mean(closed_total, na.rm = TRUE),
    .groups = "drop"
  )
cat("Pre-period descriptive stats:\n")
print(desc)

# Total displacement
total_displaced <- analysis %>%
  filter(year == 2015) %>%
  summarise(
    total = sum(closed_total),
    black = sum(closed_black),
    hispanic = sum(closed_hispanic),
    white = sum(closed_white)
  )
cat("\nTotal displaced enrollment (2015):\n")
print(total_displaced)

# ---------------------------------------------------------------------------
# 2. Main specification: Continuous treatment intensity DiD
# ---------------------------------------------------------------------------
# Outcome: log community college enrollment
# Treatment: log(1 + displaced FP enrollment) × Post
# FE: county + year
# Cluster: state level

# 2a. Total enrollment
m1 <- feols(log_cc_total ~ log_displaced:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

# 2b. Black enrollment
m2 <- feols(log_cc_black ~ log_displaced:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

# 2c. Hispanic enrollment
m3 <- feols(log_cc_hispanic ~ log_displaced:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

# 2d. White enrollment
m4 <- feols(log_cc_white ~ log_displaced:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

cat("\n--- Main Results ---\n")
etable(m1, m2, m3, m4,
       headers = c("Total", "Black", "Hispanic", "White"),
       se.below = TRUE)

# ---------------------------------------------------------------------------
# 3. Event study (dynamic effects)
# ---------------------------------------------------------------------------
# Create relative time dummies
analysis <- analysis %>%
  mutate(rel_time = year - 2016)

# Event study with leads and lags
es_total <- feols(log_cc_total ~ i(rel_time, log_displaced, ref = -1) |
                    county_fips + year,
                  data = analysis,
                  cluster = ~state_fips)

es_black <- feols(log_cc_black ~ i(rel_time, log_displaced, ref = -1) |
                    county_fips + year,
                  data = analysis,
                  cluster = ~state_fips)

es_hispanic <- feols(log_cc_hispanic ~ i(rel_time, log_displaced, ref = -1) |
                       county_fips + year,
                     data = analysis,
                     cluster = ~state_fips)

cat("\n--- Event Study (Total) ---\n")
print(summary(es_total))

# ---------------------------------------------------------------------------
# 4. Binary treatment specification
# ---------------------------------------------------------------------------
m5 <- feols(log_cc_total ~ has_closure:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

m6 <- feols(log_cc_black ~ has_closure:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

m7 <- feols(log_cc_hispanic ~ has_closure:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

m8 <- feols(log_cc_white ~ has_closure:post | county_fips + year,
            data = analysis,
            cluster = ~state_fips)

cat("\n--- Binary Treatment Results ---\n")
etable(m5, m6, m7, m8,
       headers = c("Total", "Black", "Hispanic", "White"),
       se.below = TRUE)

# ---------------------------------------------------------------------------
# 5. Triple difference: race × treatment × post
# ---------------------------------------------------------------------------
m_ddd <- feols(log_enroll ~ log_displaced:post:minority +
                 log_displaced:post +
                 minority:post |
                 county_fips^race + year^race,
               data = analysis_long,
               cluster = ~state_fips)

cat("\n--- Triple Difference ---\n")
print(summary(m_ddd))

# ---------------------------------------------------------------------------
# 6. Placebo: 4-year public university enrollment
# ---------------------------------------------------------------------------
analysis <- analysis %>%
  mutate(
    log_pub4_total = log(replace_na(pub4_total, 0) + 1),
    log_pub4_black = log(replace_na(pub4_black, 0) + 1)
  )

m_placebo <- feols(log_pub4_total ~ log_displaced:post | county_fips + year,
                   data = analysis,
                   cluster = ~state_fips)

cat("\n--- Placebo (4-year public) ---\n")
print(summary(m_placebo))

# ---------------------------------------------------------------------------
# 7. Save models and updated analysis
# ---------------------------------------------------------------------------
saveRDS(analysis, "../data/analysis.rds")  # Updated with rel_time

models <- list(
  m_total = m1, m_black = m2, m_hispanic = m3, m_white = m4,
  m_bin_total = m5, m_bin_black = m6, m_bin_hispanic = m7, m_bin_white = m8,
  m_ddd = m_ddd, m_placebo = m_placebo,
  es_total = es_total, es_black = es_black, es_hispanic = es_hispanic
)
saveRDS(models, "../data/models.rds")

# ---------------------------------------------------------------------------
# 8. Write diagnostics.json
# ---------------------------------------------------------------------------
n_treated <- analysis %>%
  filter(year == 2015, has_closure == 1) %>%
  n_distinct(.$county_fips)

n_pre <- analysis %>%
  filter(year < 2017) %>%
  pull(year) %>%
  unique() %>%
  length()

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre     = n_pre,
    n_obs     = nrow(analysis)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\nDiagnostics written. n_treated=", n_treated, " n_pre=", n_pre,
    " n_obs=", nrow(analysis), "\n")
