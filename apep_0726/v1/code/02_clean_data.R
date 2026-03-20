# =============================================================================
# 02_clean_data.R — Clean and construct analysis variables
# Paper: Fiscal Windfalls and Violence Against Women (apep_0726)
# =============================================================================

source("code/00_packages.R")

cat("=== CLEANING DATA ===\n")

pop_df <- readRDS("data/ibge_population.rds")
sim_df <- readRDS("data/sim_mortality.rds")

# ---- 1. CONSTRUCT FPM RUNNING VARIABLE ----

assign_fpm_threshold <- function(population) {
  thresholds <- c(10189, 13585, 16981, 23773, 30565, 37357, 44149,
                  50941, 61329, 71717, 82105, 92493, 115617, 138741,
                  161865, 188987)

  nearest_thresh <- sapply(population, function(p) {
    dists <- abs(p - thresholds)
    thresholds[which.min(dists)]
  })

  tibble(
    nearest_threshold = nearest_thresh,
    running_var = population - nearest_thresh,
    above_threshold = as.integer(population >= nearest_thresh)
  )
}

# Filter to years with SIM data (2015-2019) and merge
pop_filtered <- pop_df %>%
  filter(year >= 2015, year <= 2019) %>%
  bind_cols(assign_fpm_threshold(.$population)) %>%
  mutate(
    fpm_coef = case_when(
      population < 10189 ~ 0.6, population < 13585 ~ 0.8,
      population < 16981 ~ 1.0, population < 23773 ~ 1.2,
      population < 30565 ~ 1.4, population < 37357 ~ 1.6,
      population < 44149 ~ 1.8, population < 50941 ~ 2.0,
      population < 61329 ~ 2.2, population < 71717 ~ 2.4,
      population < 82105 ~ 2.6, population < 92493 ~ 2.8,
      population < 115617 ~ 3.0, population < 138741 ~ 3.2,
      population < 161865 ~ 3.4, population < 188987 ~ 3.6,
      TRUE ~ 3.8
    ),
    state_code = substr(mun_code, 1, 2),
    threshold_fe = as.factor(nearest_threshold)
  )

cat(sprintf("Population data: %d municipality-years\n", nrow(pop_filtered)))

# ---- 2. AGGREGATE SIM MORTALITY TO MUNICIPALITY-YEAR ----

sim_clean <- sim_df %>%
  mutate(
    mun_code = as.character(CODMUNRES),
    is_female = (SEXO == "2" | SEXO == 2),
    cause = as.character(CAUSABAS),
    is_homicide = grepl("^(X8[5-9]|X9[0-9]|Y0[0-9])", cause),
    is_traffic = grepl("^V", cause)
  ) %>%
  filter(!is.na(mun_code), nchar(mun_code) == 6)

# Female homicides
fem_homicide <- sim_clean %>%
  filter(is_female, is_homicide) %>%
  count(mun_code, year, name = "n_female_homicide")

# Male homicides (placebo)
male_homicide <- sim_clean %>%
  filter(!is_female, is_homicide) %>%
  count(mun_code, year, name = "n_male_homicide")

# Traffic deaths (placebo)
traffic <- sim_clean %>%
  filter(is_traffic) %>%
  count(mun_code, year, name = "n_traffic_deaths")

cat(sprintf("Female homicide mun-years: %d\n", nrow(fem_homicide)))
cat(sprintf("Male homicide mun-years: %d\n", nrow(male_homicide)))

# ---- 3. MERGE ALL DATASETS ----

analysis_df <- pop_filtered %>%
  left_join(fem_homicide, by = c("mun_code", "year")) %>%
  left_join(male_homicide, by = c("mun_code", "year")) %>%
  left_join(traffic, by = c("mun_code", "year")) %>%
  mutate(across(starts_with("n_"), ~replace_na(., 0))) %>%
  mutate(
    female_pop = population * 0.508,
    fem_homicide_rate = n_female_homicide / female_pop * 100000,
    male_homicide_rate = n_male_homicide / (population - female_pop) * 100000,
    traffic_rate = n_traffic_deaths / population * 100000,
    # Create a domestic violence proxy: use female homicide as primary
    dv_rate = fem_homicide_rate  # For code compatibility
  )

# Focus on municipalities near thresholds
analysis_df <- analysis_df %>%
  filter(abs(running_var) <= 5000)

cat(sprintf("\nFinal analysis dataset: %d municipality-years\n", nrow(analysis_df)))
cat(sprintf("Unique municipalities: %d\n", n_distinct(analysis_df$mun_code)))
cat(sprintf("Years: %d to %d\n", min(analysis_df$year), max(analysis_df$year)))
cat(sprintf("Thresholds: %d\n", n_distinct(analysis_df$nearest_threshold)))
cat(sprintf("Total female homicides: %d\n", sum(analysis_df$n_female_homicide)))
cat(sprintf("Total male homicides: %d\n", sum(analysis_df$n_male_homicide)))

stopifnot("No data" = nrow(analysis_df) > 100)
stopifnot("No homicide data" = sum(analysis_df$n_female_homicide) > 0)

saveRDS(analysis_df, "data/analysis_df.rds")
cat("Saved: data/analysis_df.rds\n")
