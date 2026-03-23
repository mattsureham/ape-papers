# 02_clean_data.R — Clean and merge crime + population data
# apep_0827: Dutch cannabis supply chain experiment and crime

source("00_packages.R")

# ============================================================================
# Municipality definitions
# ============================================================================

treatment_gm <- c("GM0855", "GM0758", "GM0202", "GM0034", "GM0014",
                   "GM0917", "GM0268", "GM0479", "GM0935", "GM1992")
treatment_names <- c("Tilburg", "Breda", "Arnhem", "Almere", "Groningen",
                     "Heerlen", "Nijmegen", "Zaanstad", "Maastricht", "Voorne aan Zee")

control_gm <- c("GM0153", "GM0392", "GM0794", "GM0080", "GM0546",
                 "GM0995", "GM0957", "GM0281", "GM0344", "GM0301")
control_names <- c("Enschede", "Haarlem", "Helmond", "Leeuwarden", "Leiden",
                   "Lelystad", "Roermond", "Tiel", "Utrecht", "Zutphen")

gm_lookup <- tibble(
  gm_code = c(treatment_gm, control_gm),
  name = c(treatment_names, control_names),
  treated = c(rep(1L, 10), rep(0L, 10))
)

# ============================================================================
# Clean crime data
# ============================================================================

cat("Loading crime data...\n")
crime_raw <- readRDS("../data/crime_raw.rds")

# Examine columns
cat("Crime columns:", paste(names(crime_raw), collapse = ", "), "\n")

# Clean region codes (CBS pads with spaces)
crime_raw <- crime_raw %>%
  mutate(
    RegioS = str_trim(RegioS),
    Perioden = str_trim(Perioden),
    SoortMisdrijf = str_trim(SoortMisdrijf)
  )

# Extract year from Perioden (format: "2023JJ00" for annual)
crime <- crime_raw %>%
  filter(str_detect(Perioden, "JJ00$")) %>%  # Annual data only
  mutate(year = as.integer(str_extract(Perioden, "^\\d{4}"))) %>%
  filter(year >= 2010, year <= 2025)

cat(sprintf("Crime data: %d records, years %d-%d\n",
            nrow(crime), min(crime$year), max(crime$year)))

# Identify the crime type column (varies by CBS version)
crime_col <- names(crime)[str_detect(names(crime), "(?i)geregistreerde|misdrijven_1|registered")]
cat("Crime count column(s):", paste(crime_col, collapse = ", "), "\n")

# Standardize column name
if (length(crime_col) == 0) {
  # Try all numeric columns
  num_cols <- names(crime)[sapply(crime, is.numeric)]
  cat("Numeric columns:", paste(num_cols, collapse = ", "), "\n")
  crime_col <- num_cols[!num_cols %in% c("year")]
  if (length(crime_col) > 0) crime_col <- crime_col[1]
}

crime <- crime %>%
  rename(crime_count = !!sym(crime_col[1]))

# Map crime types of interest
# CBS code prefixes: check actual codes
crime_types <- crime %>% distinct(SoortMisdrijf) %>% pull()
cat("Sample crime type codes:", paste(head(crime_types, 20), collapse = ", "), "\n")

# Map crime categories
crime_map <- tribble(
  ~code_pattern, ~crime_type,
  "^1\\.1",      "TotalCrime",      # Total
  "^6",          "DrugTotal",       # Drug offenses (Opiumwet)
  "^6\\.1",      "DrugHard",        # Hard drugs
  "^6\\.2",      "DrugSoft",        # Soft drugs
  "^3",          "Violence",        # Violent crimes
  "^4",          "Property",        # Property crimes
  "^5",          "Vandalism"        # Vandalism/public order
)

# First check what format the SoortMisdrijf codes are in
cat("\nFirst 30 unique SoortMisdrijf values:\n")
cat(paste(head(sort(unique(crime$SoortMisdrijf)), 30), collapse = "\n"), "\n")

# Create wide format: one row per municipality-year with crime types as columns
# Try numeric-prefix matching first
crime_clean <- crime %>%
  mutate(
    crime_type = case_when(
      str_detect(SoortMisdrijf, "^1\\.1\\s") ~ "TotalCrime",
      str_detect(SoortMisdrijf, "^T001161") ~ "TotalCrime",
      str_detect(SoortMisdrijf, "^6\\s|^6\\.0\\s|^CRI6000") ~ "DrugTotal",
      str_detect(SoortMisdrijf, "^6\\.1\\s|^CRI6100") ~ "DrugHard",
      str_detect(SoortMisdrijf, "^6\\.2\\s|^CRI6200") ~ "DrugSoft",
      str_detect(SoortMisdrijf, "^3\\s|^3\\.0\\s|^CRI3000") ~ "Violence",
      str_detect(SoortMisdrijf, "^4\\s|^4\\.0\\s") ~ "Property",
      str_detect(SoortMisdrijf, "^5\\s|^5\\.0\\s") ~ "Vandalism",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(crime_type))

cat(sprintf("\nAfter crime type mapping: %d records\n", nrow(crime_clean)))
cat("Crime types found:", paste(unique(crime_clean$crime_type), collapse = ", "), "\n")

# If no types matched, try alternative CBS code formats
if (nrow(crime_clean) == 0) {
  cat("\nRetrying with alternative code format...\n")
  # Check if codes are like "A045000" etc.
  crime_clean <- crime %>%
    mutate(
      crime_type = case_when(
        SoortMisdrijf == "T001161" ~ "TotalCrime",
        SoortMisdrijf == "A048426" | str_detect(SoortMisdrijf, "Opiumwet") ~ "DrugTotal",
        str_detect(SoortMisdrijf, "(?i)hard") ~ "DrugHard",
        str_detect(SoortMisdrijf, "(?i)soft|hennep") ~ "DrugSoft",
        str_detect(SoortMisdrijf, "(?i)geweld|violen") ~ "Violence",
        str_detect(SoortMisdrijf, "(?i)vermogens|dief|theft") ~ "Property",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(crime_type))
}

# Pivot to wide format
crime_wide <- crime_clean %>%
  select(RegioS, year, crime_type, crime_count) %>%
  pivot_wider(
    names_from = crime_type,
    values_from = crime_count,
    values_fn = sum  # In case of multiple matches
  )

cat(sprintf("Wide crime data: %d municipality-years\n", nrow(crime_wide)))

# ============================================================================
# Clean population data
# ============================================================================

cat("\nLoading population data...\n")
pop_raw <- readRDS("../data/pop_raw.rds")
cat("Population columns:", paste(names(pop_raw), collapse = ", "), "\n")

pop <- pop_raw %>%
  mutate(
    RegioS = str_trim(RegioS),
    Perioden = str_trim(Perioden)
  ) %>%
  filter(str_detect(Perioden, "JJ00$")) %>%
  mutate(year = as.integer(str_extract(Perioden, "^\\d{4}"))) %>%
  filter(year >= 2010, year <= 2025)

# Find population column
pop_col <- names(pop)[str_detect(names(pop), "(?i)bevolking|population")]
cat("Population column:", pop_col, "\n")

pop <- pop %>%
  rename(population = !!sym(pop_col[1])) %>%
  select(RegioS, year, population) %>%
  filter(!is.na(population), population > 0)

# ============================================================================
# Merge and create analysis dataset
# ============================================================================

cat("\nMerging crime and population data...\n")

df <- crime_wide %>%
  left_join(pop, by = c("RegioS", "year")) %>%
  left_join(gm_lookup, by = c("RegioS" = "gm_code"))

# Create analysis variables
# All Dutch municipalities panel (for SCM donor pool)
df_all <- df %>%
  filter(!is.na(population), population > 0) %>%
  mutate(
    # Crime rates per 100,000
    across(
      any_of(c("TotalCrime", "DrugTotal", "DrugHard", "DrugSoft",
               "Violence", "Property", "Vandalism")),
      ~ . / population * 100000,
      .names = "{.col}_rate"
    ),
    # Treatment indicators
    experiment = if_else(!is.na(treated), 1L, 0L),
    post = if_else(year >= 2024, 1L, 0L),
    treat_post = if_else(!is.na(treated) & treated == 1L & year >= 2024, 1L, 0L)
  )

# Experiment sample: 20 municipalities
df_exp <- df_all %>% filter(experiment == 1)

cat(sprintf("\nAll municipalities panel: %d obs, %d unique municipalities\n",
            nrow(df_all), n_distinct(df_all$RegioS)))
cat(sprintf("Experiment sample: %d obs, %d municipalities, years %d-%d\n",
            nrow(df_exp), n_distinct(df_exp$RegioS),
            min(df_exp$year), max(df_exp$year)))

# Verify treatment/control municipalities present
cat("\nTreatment municipalities found:\n")
df_exp %>% filter(treated == 1) %>% distinct(RegioS, name) %>% print(n = 10)
cat("\nControl municipalities found:\n")
df_exp %>% filter(treated == 0) %>% distinct(RegioS, name) %>% print(n = 10)

# Check years available
cat("\nYears available:", paste(sort(unique(df_exp$year)), collapse = ", "), "\n")

# Summary statistics
cat("\n=== Summary: Drug Crime Rates ===\n")
df_exp %>%
  filter(!is.na(DrugTotal_rate)) %>%
  group_by(treated, post) %>%
  summarise(
    n = n(),
    mean_drug = mean(DrugTotal_rate, na.rm = TRUE),
    sd_drug = sd(DrugTotal_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Save analysis datasets
saveRDS(df_all, "../data/df_all.rds")
saveRDS(df_exp, "../data/df_exp.rds")

cat("\nAnalysis datasets saved.\n")
