# 04_robustness.R — Robustness checks
# apep_0719: Alien Land Laws and Japanese Occupational Sorting

source("00_packages.R")

data_dir <- "../data"
treatment <- readRDS(file.path(data_dir, "treatment_assignment.rds"))
df_j_farm <- readRDS(file.path(data_dir, "japanese_farmers.rds"))
df_j_main <- readRDS(file.path(data_dir, "japanese_main.rds"))
df_w_farm <- readRDS(file.path(data_dir, "white_farmers.rds"))

# ===================================================================
# TEST 1: SEI (Socioeconomic Index) as alternative measure
# ===================================================================

cat("=== SEI Change (alternative to OCCSCORE) ===\n")

m_sei <- feols(sei_change ~ newly_treated + age_1920 + literate_1920,
                data = df_j_farm, cluster = ~state_1920)
cat("Farm subsample SEI change:\n")
summary(m_sei)

# ===================================================================
# TEST 2: Non-farm placebo occupation transition
# ===================================================================

cat("\n=== Non-farm Japanese (Placebo) ===\n")

df_j_nonfarm <- df_j_main %>% filter(farm_occ_1920 == 0)
cat(sprintf("Non-farm Japanese: %d\n", nrow(df_j_nonfarm)))

m_nonfarm <- feols(occscore_change ~ newly_treated + age_1920,
                    data = df_j_nonfarm, cluster = ~state_1920)
summary(m_nonfarm)

# ===================================================================
# TEST 3: Interstate mobility (movers)
# ===================================================================

cat("\n=== Interstate Mobility ===\n")

m_mover_j <- feols(interstate_mover ~ newly_treated + age_1920,
                    data = df_j_farm, cluster = ~state_1920)
cat("Japanese farmers — interstate mobility:\n")
summary(m_mover_j)

m_mover_w <- feols(mover ~ newly_treated + age_1920,
                    data = df_w_farm, cluster = ~state_1920)
cat("\nWhite farmers — interstate mobility:\n")
summary(m_mover_w)

# ===================================================================
# TEST 4: Alternative control groups
# ===================================================================

cat("\n=== Alternative control: Including California/Arizona (already treated) ===\n")

# Re-read full Japanese data
df_j_all <- readRDS(file.path(data_dir, "japanese_1920_1930.rds"))
df_j_all <- df_j_all %>%
  mutate(
    newly_treated = as.integer(statefip_1920 %in% treatment$newly_treated),
    already_treated = as.integer(statefip_1920 %in% treatment$already_treated),
    farm_occ_1920 = as.integer(occ1950_1920 >= 100 & occ1950_1920 <= 123),
    farm_occ_1930 = as.integer(occ1950_1930 >= 100 & occ1950_1930 <= 123),
    farm_exit = as.integer(farm_occ_1920 == 1 & farm_occ_1930 == 0),
    occscore_change = occscore_1930 - occscore_1920,
    working_age = as.integer(age_1920 >= 18 & age_1920 <= 60),
    male = as.integer(sex_1920 == 1),
    state_1920 = statefip_1920
  )

# Include CA/AZ as "always treated" control
df_j_alt <- df_j_all %>%
  filter(working_age == 1 & male == 1 & farm_occ_1920 == 1)

cat(sprintf("Including CA/AZ: %d farmers total\n", nrow(df_j_alt)))
cat(sprintf("  Newly treated: %d\n", sum(df_j_alt$newly_treated)))
cat(sprintf("  Already treated (CA/AZ): %d\n", sum(df_j_alt$already_treated)))
cat(sprintf("  Never treated: %d\n",
            sum(!df_j_alt$newly_treated & !df_j_alt$already_treated)))

m_alt <- feols(farm_exit ~ newly_treated + already_treated + age_1920,
                data = df_j_alt, cluster = ~state_1920)
cat("Farm exit with CA/AZ already-treated indicator:\n")
summary(m_alt)

# ===================================================================
# TEST 5: Persistence (triple panel 1920-1930-1940)
# ===================================================================

cat("\n=== Persistence: 1920-1930-1940 Triple Panel ===\n")

df_triple <- readRDS(file.path(data_dir, "japanese_triple_1920_1940.rds"))
cat(sprintf("Triple panel: %d individuals\n", nrow(df_triple)))

# Check available columns
triple_cols <- names(df_triple)
cat("Triple panel columns:", paste(triple_cols[grep("1940", triple_cols)], collapse=", "), "\n")

# If 1940 data has occscore, compare persistence
if ("occscore_1940" %in% triple_cols) {
  df_triple <- df_triple %>%
    mutate(
      newly_treated = as.integer(statefip_1920 %in% treatment$newly_treated),
      farm_occ_1920 = as.integer(occ1950_1920 >= 100 & occ1950_1920 <= 123),
      occscore_change_30_40 = occscore_1940 - occscore_1930,
      occscore_change_20_40 = occscore_1940 - occscore_1920,
      working_age = as.integer(age_1920 >= 18 & age_1920 <= 50),
      male = as.integer(sex_1920 == 1),
      state_1920 = statefip_1920
    )

  df_triple_main <- df_triple %>%
    filter(working_age == 1 & male == 1 & farm_occ_1920 == 1 &
             statefip_1920 %in% c(treatment$newly_treated, treatment$never_treated))

  cat(sprintf("Triple panel farmers: %d\n", nrow(df_triple_main)))

  if (nrow(df_triple_main) >= 30) {
    m_persist <- feols(occscore_change_20_40 ~ newly_treated,
                        data = df_triple_main, cluster = ~state_1920)
    cat("20-year occscore change (1920→1940):\n")
    summary(m_persist)
  }
}

# ===================================================================
# SAVE
# ===================================================================

robustness <- list(
  m_sei = m_sei,
  m_nonfarm = m_nonfarm,
  m_mover_j = m_mover_j,
  m_mover_w = m_mover_w,
  m_alt = m_alt
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
