## 03_main_analysis.R — Primary regressions
## apep_1179: Anti-corruption enforcement and fiscal composition in China

source("00_packages.R")
panel <- readRDS("../data/analysis_panel.rds")

# =============================================================================
# DESIGN NOTE
# =============================================================================
# Nearly all cities (253/258) were investigated during the campaign.
# Only 5 cities had zero investigations 2013-2016.
#
# Primary identification: CONTINUOUS TREATMENT INTENSITY
#   - Variation in the NUMBER of investigated officials per city
#   - Intensity ranges from 0 to 260 (median 45 among treated)
#   - Specification: Y_it = α_i + γ_t + β(Post_t × log(1+Inv_i)) + ε_it
#   - Post = 1 for year >= 2013; Inv_i = total investigations in city i
#   - β captures effect of a 1-log-point increase in investigation intensity
#
# Secondary: Callaway-Sant'Anna for staggered timing (2013 vs 2014 cohorts)
#   - Control group = not-yet-treated (since only 5 never-treated)
# =============================================================================

# Define campaign period
panel <- panel %>%
  mutate(
    campaign = as.integer(year >= 2013),
    # Pre-determined intensity (total investigations 2013-2016, assigned to all years)
    post_x_intensity = campaign * log_intensity,
    # Binary treatment for the subset analysis
    treated_binary = as.integer(first_treat > 0)
  )

# =============================================================================
# 1. MAIN RESULTS: Education expenditure share
# =============================================================================

cat("=== TABLE 1: Education Expenditure Share ===\n\n")

# Column 1: Simple TWFE with binary post × treated
m1 <- feols(edu_share ~ post | city_id + year, data = panel,
            cluster = ~city_id)

# Column 2: Intensity DiD — Post × log(investigations)
m2 <- feols(edu_share ~ post_x_intensity | city_id + year, data = panel,
            cluster = ~city_id)

# Column 3: Intensity DiD with GDP control
m3 <- feols(edu_share ~ post_x_intensity + log_gdp | city_id + year, data = panel,
            cluster = ~city_id)

# Column 4: Log education expenditure (level, not share)
m4 <- feols(log_edu_exp ~ post_x_intensity | city_id + year, data = panel,
            cluster = ~city_id)

# Column 5: Log total fiscal expenditure (denominator check)
m5 <- feols(log_fiscal_exp ~ post_x_intensity | city_id + year, data = panel,
            cluster = ~city_id)

etable(m1, m2, m3, m4, m5,
       se.below = TRUE,
       headers = c("Binary DiD", "Intensity", "+ Controls", "Log Edu Exp", "Log Total Exp"),
       fitstat = ~ n + r2)

# =============================================================================
# 2. SECONDARY OUTCOMES: Science share, FAI/GDP
# =============================================================================

cat("\n=== TABLE 2: Alternative Fiscal Outcomes ===\n\n")

# Science expenditure share
m_sci <- feols(sci_share ~ post_x_intensity | city_id + year, data = panel,
               cluster = ~city_id)

# Fixed asset investment / GDP (infrastructure proxy)
m_fai <- feols(fai_share ~ post_x_intensity | city_id + year, data = panel,
               cluster = ~city_id)

# Education / GDP
m_edugdp <- feols(edu_gdp ~ post_x_intensity | city_id + year, data = panel,
                  cluster = ~city_id)

# Hospital beds per capita (health capacity)
m_beds <- feols(beds_pc ~ post_x_intensity | city_id + year, data = panel,
                cluster = ~city_id)

etable(m_sci, m_fai, m_edugdp, m_beds,
       se.below = TRUE,
       headers = c("Science Share", "FAI/GDP", "Edu/GDP", "Beds p.c."),
       fitstat = ~ n + r2)

# =============================================================================
# 3. CALLAWAY-SANT'ANNA (staggered timing)
# =============================================================================

cat("\n=== Callaway-Sant'Anna ATT ===\n\n")

# For CS, need only cities with first_treat in {2013, 2014} or never-treated
# first_treat = 0 means never-treated; first_treat > 0 means treated in that year
cs_data <- panel %>%
  filter(first_treat %in% c(0, 2013, 2014)) %>%
  # CS requires complete panels
  group_by(city_id) %>%
  filter(n() == 10, !any(is.na(edu_share))) %>%
  ungroup()

cat("CS sample:", n_distinct(cs_data$city_id), "cities\n")
cat("Control group:", sum(cs_data$first_treat == 0 & cs_data$year == 2007), "never-treated +",
    "not-yet-treated\n")

# CS with not-yet-treated control group
cs_out <- att_gt(
  yname = "edu_share",
  tname = "year",
  idname = "city_id",
  gname = "first_treat",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  est_method = "dr",
  base_period = "universal"
)

cat("\nGroup-time ATTs:\n")
summary(cs_out)

# Aggregate: overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:\n")
summary(cs_agg)

# Dynamic event study
cs_es <- aggte(cs_out, type = "dynamic")
cat("\nEvent study:\n")
summary(cs_es)

# =============================================================================
# 4. SAVE RESULTS
# =============================================================================

# Save coefficients for table generation
results <- list(
  main = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
  secondary = list(m_sci = m_sci, m_fai = m_fai, m_edugdp = m_edugdp, m_beds = m_beds),
  cs = list(att_gt = cs_out, agg = cs_agg, event_study = cs_es)
)

saveRDS(results, "../data/main_results.rds")

# =============================================================================
# 5. DIAGNOSTICS for validator
# =============================================================================

diag <- list(
  n_treated = n_distinct(panel$city_id[panel$first_treat > 0]),
  n_pre = length(unique(panel$year[panel$year < 2013])),
  n_obs = nrow(panel),
  n_cities = n_distinct(panel$city_id),
  n_years = n_distinct(panel$year),
  n_never_treated = n_distinct(panel$city_id[panel$first_treat == 0]),
  intensity_mean = mean(panel$intensity[panel$first_treat > 0 & panel$year == 2007]),
  intensity_max = max(panel$intensity),
  main_coef = coef(m2)["post_x_intensity"],
  main_se = se(m2)["post_x_intensity"]
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")
cat(sprintf("Main result: β = %.5f (SE = %.5f)\n",
            diag$main_coef, diag$main_se))
