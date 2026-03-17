# 02_clean_data.R — Clean and prepare data for DiD analysis
# apep_0719: Alien Land Laws and Japanese Occupational Sorting

source("00_packages.R")

data_dir <- "../data"
treatment <- readRDS(file.path(data_dir, "treatment_assignment.rds"))

# ----- Load Japanese data -----
df_j <- readRDS(file.path(data_dir, "japanese_1920_1930.rds"))
cat(sprintf("Japanese sample: %d individuals\n", nrow(df_j)))

# ----- Create analysis variables -----
df_j <- df_j %>%
  mutate(
    # Treatment: newly treated state (enacted ALL between 1920-1930)
    newly_treated = as.integer(statefip_1920 %in% treatment$newly_treated),

    # Farm status in each census
    farmer_1920 = as.integer(farm_1920 == 2),  # farm=2 means farm residence in IPUMS
    farmer_1930 = as.integer(farm_1930 == 2),

    # Alternative: use occupation (OCC1950 100-123 are farm occupations)
    farm_occ_1920 = as.integer(occ1950_1920 >= 100 & occ1950_1920 <= 123),
    farm_occ_1930 = as.integer(occ1950_1930 >= 100 & occ1950_1930 <= 123),

    # Farm exit indicator
    farm_exit = as.integer(farm_occ_1920 == 1 & farm_occ_1930 == 0),

    # Occupational score change
    occscore_change = occscore_1930 - occscore_1920,

    # SEI change
    sei_change = sei_1930 - sei_1920,

    # Working-age filter (age 18-60 in 1920)
    working_age = as.integer(age_1920 >= 18 & age_1920 <= 60),

    # Male indicator
    male = as.integer(sex_1920 == 1),

    # Literate
    literate_1920 = as.integer(lit_1920 == 4),

    # Class of worker
    farm_owner_1920 = as.integer(farm_occ_1920 == 1 & classwkr_1920 == 2),
    farm_laborer_1920 = as.integer(farm_occ_1920 == 1 & classwkr_1920 == 1),

    # Mover indicator
    interstate_mover = mover,

    # State names for readability
    state_1920 = statefip_1920
  )

# Filter to working-age males (primary sample)
df_j_main <- df_j %>% filter(working_age == 1 & male == 1)
cat(sprintf("Japanese working-age males: %d\n", nrow(df_j_main)))

# Farm subsample (for farm exit analysis)
df_j_farm <- df_j_main %>% filter(farm_occ_1920 == 1)
cat(sprintf("Japanese farmers in 1920: %d\n", nrow(df_j_farm)))

# ----- Load white placebo data -----
df_w <- readRDS(file.path(data_dir, "white_placebo_1920_1930.rds"))
cat(sprintf("White placebo sample: %d individuals\n", nrow(df_w)))

df_w <- df_w %>%
  mutate(
    newly_treated = as.integer(statefip_1920 %in% treatment$newly_treated),
    farm_occ_1920 = as.integer(occ1950_1920 >= 100 & occ1950_1920 <= 123),
    farm_occ_1930 = as.integer(occ1950_1930 >= 100 & occ1950_1930 <= 123),
    farm_exit = as.integer(farm_occ_1920 == 1 & farm_occ_1930 == 0),
    occscore_change = occscore_1930 - occscore_1920,
    working_age = as.integer(age_1920 >= 18 & age_1920 <= 60),
    male = as.integer(sex_1920 == 1),
    state_1920 = statefip_1920
  )

df_w_farm <- df_w %>% filter(working_age == 1 & male == 1 & farm_occ_1920 == 1)
cat(sprintf("White farmers (working-age males): %d\n", nrow(df_w_farm)))

# ----- Summary statistics -----
cat("\n--- Japanese Farm Exit by Treatment Status ---\n")
df_j_farm %>%
  group_by(newly_treated) %>%
  summarise(
    n = n(),
    farm_exit_rate = mean(farm_exit),
    mean_occscore_1920 = mean(occscore_1920),
    mean_occscore_1930 = mean(occscore_1930),
    mean_occscore_change = mean(occscore_change),
    .groups = "drop"
  ) %>%
  print()

cat("\n--- White Placebo Farm Exit by Treatment Status ---\n")
df_w_farm %>%
  group_by(newly_treated) %>%
  summarise(
    n = n(),
    farm_exit_rate = mean(farm_exit),
    mean_occscore_change = mean(occscore_change),
    .groups = "drop"
  ) %>%
  print()

# ----- Save cleaned data -----
saveRDS(df_j_main, file.path(data_dir, "japanese_main.rds"))
saveRDS(df_j_farm, file.path(data_dir, "japanese_farmers.rds"))
saveRDS(df_w_farm, file.path(data_dir, "white_farmers.rds"))

cat("\nCleaned data saved.\n")
