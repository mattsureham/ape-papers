## 01_fetch_data.R — Read parquet data (already fetched by Python from Azure)
source("00_packages.R")

dt <- as.data.table(read_parquet("../data/qwi_state_panel.parquet"))
cat("Loaded", nrow(dt), "rows from QWI state panel\n")
cat("States:", uniqueN(dt$state_abbr), "\n")
cat("Industries:", unique(dt$industry), "\n")
cat("Races:", unique(dt$race), "\n")
cat("Years:", range(dt$year), "\n")

# Validate: no empty dataset
stopifnot(nrow(dt) > 0)
stopifnot(sum(!is.na(dt$Emp)) > 100)

saveRDS(dt, "../data/qwi_raw.rds")
cat("Saved qwi_raw.rds\n")
