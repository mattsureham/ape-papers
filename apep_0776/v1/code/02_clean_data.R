# ==============================================================================
# 02_clean_data.R — Variable Construction
# Paper: Working Themselves to Death? (apep_0776)
# ==============================================================================

source("00_packages.R")

deaths_raw <- readRDS("../data/deaths_raw.rds")
pop_raw    <- readRDS("../data/pop_raw.rds")
emp_raw    <- readRDS("../data/emp_raw.rds")

# ---- 1. Clean deaths: aggregate ages 55-64 by region x sex x year ----
cat("Cleaning deaths data...\n")

# Identify age column and filter to ages 55-64
names(deaths_raw) <- tolower(names(deaths_raw))
cat("  Deaths columns:", paste(names(deaths_raw), collapse = ", "), "\n")

# Single-year ages: Y55, Y56, ..., Y64
ages_55_64 <- paste0("Y", 55:64)
ages_45_54 <- paste0("Y", 45:54)

deaths <- deaths_raw %>%
  mutate(year = as.integer(time)) %>%
  filter(age %in% ages_55_64) %>%
  group_by(geo, sex, year) %>%
  summarise(deaths_55_64 = sum(values, na.rm = TRUE), .groups = "drop")

cat(sprintf("  Deaths 55-64: %d region-sex-year obs\n", nrow(deaths)))

# Placebo: 45-54
deaths_placebo <- deaths_raw %>%
  mutate(year = as.integer(time)) %>%
  filter(age %in% ages_45_54) %>%
  group_by(geo, sex, year) %>%
  summarise(deaths_45_54 = sum(values, na.rm = TRUE), .groups = "drop")

# ---- 2. Clean population: get 55-64 and 45-54 denominators ----
cat("Cleaning population data...\n")

names(pop_raw) <- tolower(names(pop_raw))
cat("  Pop columns:", paste(names(pop_raw), collapse = ", "), "\n")

# Population in 5-year groups: Y55-59, Y60-64
pop <- pop_raw %>%
  mutate(year = as.integer(time)) %>%
  filter(age %in% c("Y55-59", "Y60-64")) %>%
  group_by(geo, sex, year) %>%
  summarise(pop_55_64 = sum(values, na.rm = TRUE), .groups = "drop")

pop_placebo <- pop_raw %>%
  mutate(year = as.integer(time)) %>%
  filter(age %in% c("Y45-49", "Y50-54")) %>%
  group_by(geo, sex, year) %>%
  summarise(pop_45_54 = sum(values, na.rm = TRUE), .groups = "drop")

cat(sprintf("  Pop 55-64: %d obs\n", nrow(pop)))

# ---- 3. Clean employment rates: get Fornero bite ----
cat("Computing Fornero bite...\n")

names(emp_raw) <- tolower(names(emp_raw))

emp <- emp_raw %>%
  mutate(year = as.integer(time)) %>%
  filter(age == "Y55-64") %>%
  select(geo, sex, year, emp_rate = values)

# Fornero bite = employment rate change 2010 → 2014
emp_2010 <- emp %>% filter(year == 2010) %>% select(geo, sex, emp_2010 = emp_rate)
emp_2014 <- emp %>% filter(year == 2014) %>% select(geo, sex, emp_2014 = emp_rate)

fornero_bite <- emp_2010 %>%
  inner_join(emp_2014, by = c("geo", "sex")) %>%
  mutate(fbite = emp_2014 - emp_2010)

cat("Fornero bite by sex:\n")
fornero_bite %>%
  group_by(sex) %>%
  summarise(mean_bite = mean(fbite, na.rm = TRUE),
            min_bite = min(fbite, na.rm = TRUE),
            max_bite = max(fbite, na.rm = TRUE),
            .groups = "drop") %>%
  print()

# ---- 4. Merge into analysis panel ----
cat("Building analysis panel...\n")

panel <- deaths %>%
  inner_join(pop, by = c("geo", "sex", "year")) %>%
  inner_join(fornero_bite %>% select(geo, sex, fbite), by = c("geo", "sex")) %>%
  mutate(
    death_rate = deaths_55_64 / pop_55_64 * 100000,
    log_death_rate = log(death_rate),
    post = as.integer(year >= 2012),
    treat = fbite * post,
    female = as.integer(sex == "F")
  ) %>%
  filter(!is.na(death_rate), death_rate > 0, year >= 2000, year <= 2020)

# Add placebo panel
panel_placebo <- deaths_placebo %>%
  inner_join(pop_placebo, by = c("geo", "sex", "year")) %>%
  inner_join(fornero_bite %>% select(geo, sex, fbite), by = c("geo", "sex")) %>%
  mutate(
    death_rate_45_54 = deaths_45_54 / pop_45_54 * 100000,
    post = as.integer(year >= 2012),
    treat = fbite * post
  ) %>%
  filter(!is.na(death_rate_45_54), death_rate_45_54 > 0, year >= 2000, year <= 2020)

cat(sprintf("  Analysis panel: %d obs (%d regions × %d sexes × %d years)\n",
            nrow(panel), n_distinct(panel$geo), n_distinct(panel$sex), n_distinct(panel$year)))

# ---- 5. Summary ----
cat("\n=== Panel Summary ===\n")
cat(sprintf("Regions: %d\n", n_distinct(panel$geo)))
cat(sprintf("Period: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Mean death rate (55-64): %.1f per 100K\n", mean(panel$death_rate, na.rm = TRUE)))

panel %>%
  group_by(sex) %>%
  summarise(
    mean_fbite = mean(fbite, na.rm = TRUE),
    mean_death_rate = mean(death_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ---- 6. Save ----
saveRDS(panel, "../data/panel.rds")
saveRDS(panel_placebo, "../data/panel_placebo.rds")
saveRDS(fornero_bite, "../data/fornero_bite.rds")

cat("Clean data saved.\n")
