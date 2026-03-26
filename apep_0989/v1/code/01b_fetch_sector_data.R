# 01b_fetch_sector_data.R — Fetch sector-by-ORP data from CZSO
source("00_packages.R")

# Dataset 140133: "Ekonomické subjekty podle odvětví převažující činnosti za správní obvody ORP"
# This gives business counts by NACE SECTOR and ORP district — critical for treatment intensity
cat("=== Fetching CZSO 140133 (businesses by sector x ORP) ===\n")
sector_orp <- czso::czso_get_table("140133")
cat("Dimensions:", nrow(sector_orp), "x", ncol(sector_orp), "\n")
cat("Columns:", paste(names(sector_orp), collapse = ", "), "\n")
cat("\nSample rows:\n")
print(head(sector_orp, 20))

# Check what sectors and territories are available
cat("\n--- Unique sectors (first 30): ---\n")
if ("aktivita_txt" %in% names(sector_orp)) {
  print(head(unique(sector_orp$aktivita_txt), 30))
}
if ("odvetvi_txt" %in% names(sector_orp)) {
  cat("\nodvetvi_txt values:\n")
  print(head(unique(sector_orp$odvetvi_txt), 30))
}

cat("\n--- Territory info: ---\n")
if ("vuzemi_txt" %in% names(sector_orp)) {
  cat("Number of unique territories:", length(unique(sector_orp$vuzemi_txt)), "\n")
  cat("Sample territories:", paste(head(unique(sector_orp$vuzemi_txt), 5), collapse = ", "), "\n")
}

cat("\n--- Time info: ---\n")
if ("casref" %in% names(sector_orp)) {
  cat("Time range:", range(sector_orp$casref, na.rm = TRUE), "\n")
  cat("Unique time periods:", length(unique(sector_orp$casref)), "\n")
  cat("Sample times:", paste(head(unique(sort(sector_orp$casref)), 10), collapse = ", "), "\n")
}

saveRDS(sector_orp, "../data/czso_sector_orp_raw.rds")
cat("\nSaved to data/czso_sector_orp_raw.rds\n")

# Also explore the 140131 data more carefully
cat("\n=== Exploring 140131 (business by legal form x ORP) ===\n")
biz_data <- readRDS("../data/czso_business_raw.rds")
cat("forma_txt values (legal forms):\n")
if ("forma_txt" %in% names(biz_data)) {
  print(unique(biz_data$forma_txt))
}
cat("\naktivita_txt values:\n")
if ("aktivita_txt" %in% names(biz_data)) {
  print(head(unique(biz_data$aktivita_txt), 20))
}
cat("\ncasref range:\n")
if ("casref" %in% names(biz_data)) {
  cat(range(biz_data$casref, na.rm = TRUE), "\n")
  cat("Sample:", paste(head(unique(sort(biz_data$casref)), 10), collapse = ", "), "\n")
}
cat("\nstapro_kod values:\n")
print(unique(biz_data$stapro_kod))
