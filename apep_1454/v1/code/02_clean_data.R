# 02_clean_data.R — Clean and construct analysis datasets
source("00_packages.R")

# ── Load raw data ────────────────────────────────────────────────────
auf02 <- readRDS("../data/raw_auh02_benefits.rds")
auf03 <- readRDS("../data/raw_auh03_benefits_region.rds")
ras200 <- readRDS("../data/raw_ras200_employment.rds")
folk1a <- readRDS("../data/raw_folk1a_population.rds")

cat("Column names:\n")
cat("AUH02:", names(auf02), "\n")
cat("AUH03:", names(auf03), "\n")
cat("RAS200:", names(ras200), "\n")
cat("FOLK1A:", names(folk1a), "\n")

# ══════════════════════════════════════════════════════════════════════
# 1. National-level benefit data (AUH02)
# ══════════════════════════════════════════════════════════════════════
benefits <- auf02 %>%
  rename(type = 1, benefit_type = 2, age_group = 3, sex = 4, year = 5, value = 6) %>%
  mutate(
    year = as.integer(str_extract(year, "\\d{4}")),
    value = as.numeric(gsub("[^0-9.-]", "", value)),
    post = as.integer(year >= 2014),
    treated = as.integer(age_group %in% c("16-24 years", "25-29 years"))
  )

cat(sprintf("Benefits: %d rows, years %d-%d\n", nrow(benefits),
            min(benefits$year), max(benefits$year)))
cat("Benefit types:\n")
print(table(benefits$benefit_type))
cat("Age groups:\n")
print(table(benefits$age_group))

# ══════════════════════════════════════════════════════════════════════
# 2. Population denominators from FOLK1A
# ══════════════════════════════════════════════════════════════════════
pop <- folk1a %>%
  rename(age = 1, quarter = 2, pop = 3) %>%
  mutate(
    age_num = as.integer(str_extract(age, "\\d+")),
    year = as.integer(str_extract(quarter, "\\d{4}")),
    pop = as.numeric(gsub("[^0-9.-]", "", pop))
  ) %>%
  filter(!is.na(age_num))

# Aggregate to 5-year age bins matching benefit data
pop_bins <- pop %>%
  mutate(age_group = case_when(
    age_num >= 16 & age_num <= 24 ~ "16-24 years",
    age_num >= 25 & age_num <= 29 ~ "25-29 years",
    age_num >= 30 & age_num <= 34 ~ "30-34 years",
    age_num >= 35 & age_num <= 39 ~ "35-39 years",
    age_num >= 40 & age_num <= 44 ~ "40-44 years",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(age_group)) %>%
  group_by(age_group, year) %>%
  summarise(population = sum(pop, na.rm = TRUE), .groups = "drop")

cat(sprintf("Population bins: %d rows\n", nrow(pop_bins)))

# ══════════════════════════════════════════════════════════════════════
# 3. Merge benefits with population → benefit rates
# ══════════════════════════════════════════════════════════════════════
benefit_rates <- benefits %>%
  left_join(pop_bins, by = c("age_group", "year")) %>%
  mutate(rate = value / population * 100)  # per 100 population

cat("Benefit rates sample:\n")
benefit_rates %>%
  filter(benefit_type == "Net unemployed recipients of social assistance",
         sex == "Total", age_group %in% c("25-29 years", "30-34 years")) %>%
  select(year, age_group, value, population, rate) %>%
  as.data.frame() %>% head(20) %>% print()

# ══════════════════════════════════════════════════════════════════════
# 4. Regional employment data (RAS200)
# ══════════════════════════════════════════════════════════════════════
employment <- ras200 %>%
  rename(region = 1, origin = 2, age_group = 3, sex = 4, measure = 5, year = 6, value = 7) %>%
  mutate(
    year = as.integer(str_extract(year, "\\d{4}")),
    value = as.numeric(gsub("[^0-9.-]", "", value)),
    post = as.integer(year >= 2014),
    treated = as.integer(age_group == "25-29 years"),
    # Clean age group labels
    age_group_clean = case_when(
      grepl("25-29", age_group) ~ "25-29",
      grepl("30-34", age_group) ~ "30-34",
      grepl("35-39", age_group) ~ "35-39",
      grepl("20-24", age_group) ~ "20-24",
      grepl("18-19", age_group) ~ "18-19",
      TRUE ~ age_group
    )
  )

cat(sprintf("Employment: %d rows, years %d-%d\n", nrow(employment),
            min(employment$year, na.rm = TRUE), max(employment$year, na.rm = TRUE)))
cat("Measures:\n")
print(table(employment$measure))

# ══════════════════════════════════════════════════════════════════════
# 5. Regional activation data (AUH03)
# ══════════════════════════════════════════════════════════════════════
activation <- auf03 %>%
  rename(region = 1, benefit_type = 2, sex = 3, age_group = 4, year = 5, value = 6) %>%
  mutate(
    year = as.integer(str_extract(year, "\\d{4}")),
    value = as.numeric(gsub("[^0-9.-]", "", value)),
    post = as.integer(year >= 2014),
    treated = as.integer(grepl("25-29", age_group))
  )

cat(sprintf("Activation: %d rows\n", nrow(activation)))

# ══════════════════════════════════════════════════════════════════════
# Save cleaned data
# ══════════════════════════════════════════════════════════════════════
saveRDS(benefit_rates, "../data/clean_benefit_rates.rds")
saveRDS(employment, "../data/clean_employment.rds")
saveRDS(activation, "../data/clean_activation.rds")
saveRDS(pop_bins, "../data/clean_population.rds")
cat("\nCleaned data saved.\n")
