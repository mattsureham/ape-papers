# 01_fetch_data.R — Load and validate data
# Data already downloaded via Python (Census CBP API + Yahoo Finance)

library(tidyverse)

data_dir <- file.path(dirname(getwd()), "data")
stopifnot("Data directory must exist" = dir.exists(data_dir))

# --- Load scrap dealer data (primary outcome) ---
scrap <- read_csv(file.path(data_dir, "cbp_recyclable_material_wholesalers.csv"),
                  show_col_types = FALSE)
stopifnot("Scrap dealer data must have rows" = nrow(scrap) > 0)
cat("Scrap dealers:", nrow(scrap), "state-year obs\n")

# --- Load control industries ---
auto_repair <- read_csv(file.path(data_dir, "cbp_general_auto_repair.csv"),
                        show_col_types = FALSE)
auto_parts <- read_csv(file.path(data_dir, "cbp_auto_parts_stores.csv"),
                       show_col_types = FALSE)
cat("Auto repair:", nrow(auto_repair), "obs; Auto parts:", nrow(auto_parts), "obs\n")

# --- Load palladium prices ---
palladium <- read_csv(file.path(data_dir, "palladium_annual.csv"),
                      show_col_types = FALSE)
cat("Palladium annual prices:", nrow(palladium), "years\n")

# --- Load treatment data ---
laws <- read_csv(file.path(data_dir, "cat_theft_laws.csv"),
                 show_col_types = FALSE)
cat("Treatment states:", nrow(laws), "\n")

# --- Validate key fields ---
stopifnot("State FIPS must be character" = is.character(scrap$state_fips) || is.numeric(scrap$state_fips))
stopifnot("Years must span 2017-2023" = all(2017:2023 %in% unique(scrap$year)))
stopifnot("At least 30 treated states" = nrow(laws) >= 30)

cat("Data validation passed.\n")

# Save loaded data for next script
save(scrap, auto_repair, auto_parts, palladium, laws,
     file = file.path(data_dir, "loaded_data.RData"))
cat("Data saved to loaded_data.RData\n")
