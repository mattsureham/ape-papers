source("00_packages.R")

# Read the Census ZIP crosswalk and figure out the columns
cat("Downloading ZIP-county crosswalk...\n")
zip_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
tmp <- tempfile(fileext = ".txt")
download.file(zip_url, tmp, quiet = TRUE)
zc_raw <- fread(tmp, sep = "|")
cat("Columns:", paste(names(zc_raw), collapse = ", "), "\n")
cat("First 3 rows:\n")
print(head(zc_raw, 3))

# Find the right columns
cat("\nColumn name patterns:\n")
for (col in names(zc_raw)) {
  cat(sprintf("  %s: %s\n", col, paste(head(zc_raw[[col]], 2), collapse=", ")))
}
