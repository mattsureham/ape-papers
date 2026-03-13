## 01_fetch_data.R — Download ENOE microdata from INEGI
## Downloads SDEMT (demographics) and COE2 (income/hours) for multiple quarters

source("code/00_packages.R")

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
options(timeout = 300)  # 5 min timeout for INEGI's slow servers

# ENOE quarterly microdata URL pattern
# Format: {year}trim{quarter}_csv.zip
# Each ZIP contains sdemt{YY}{Q}.csv and coe2t{YY}{Q}.csv

# ENOE direct download URLs work for 2019; post-2020 INEGI changed URL structure.
# ENOE was renamed ENOEN post-COVID. Focus on 2019 (4 quarters, ~16K males at 18).
quarters <- expand.grid(year = 2019, q = 1:4)
quarters <- quarters[order(quarters$year, quarters$q), ]

# Also try 2018 for additional pre-period depth
quarters <- rbind(
  expand.grid(year = 2018, q = 1:4),
  quarters
)
quarters <- quarters[order(quarters$year, quarters$q), ]

cat(sprintf("Attempting to download %d quarters of ENOE data...\n", nrow(quarters)))

downloaded <- list()
for (i in seq_len(nrow(quarters))) {
  yr <- quarters$year[i]
  qq <- quarters$q[i]
  yy <- substr(yr, 3, 4)

  zip_name <- sprintf("%dtrim%d_csv.zip", yr, qq)
  url <- sprintf("https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/microdatos/%s", zip_name)
  dest <- file.path("data/raw", zip_name)

  if (file.exists(dest)) {
    cat(sprintf("  [%d/%d] %dQ%d already downloaded, skipping\n", i, nrow(quarters), yr, qq))
    downloaded[[length(downloaded) + 1]] <- list(year = yr, quarter = qq, file = dest)
    next
  }

  cat(sprintf("  [%d/%d] Downloading %dQ%d ... ", i, nrow(quarters), yr, qq))
  tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
    fsize <- file.info(dest)$size
    if (is.na(fsize) || fsize < 1e6) {
      cat("FAILED (too small)\n")
      file.remove(dest)
    } else {
      cat(sprintf("OK (%.1f MB)\n", fsize / 1e6))
      downloaded[[length(downloaded) + 1]] <- list(year = yr, quarter = qq, file = dest)
    }
  }, error = function(e) {
    cat(sprintf("FAILED (%s)\n", e$message))
    if (file.exists(dest)) file.remove(dest)
  })
}

cat(sprintf("\nSuccessfully downloaded %d quarters.\n", length(downloaded)))
stopifnot(length(downloaded) >= 3)  # Need at least 3 quarters

# Extract and read SDEMT + COE2 files, combine across quarters
all_data <- list()

for (dl in downloaded) {
  yr <- dl$year
  qq <- dl$quarter
  yy <- substr(yr, 3, 4)
  zip_path <- dl$file

  # Determine file naming convention
  # Pre-2020: sdemt{YY}{Q}.csv, coe2t{YY}{Q}.csv
  # Post-2020: SDEMT{YY}{Q}.csv or sdemt{YY}{Q}.CSV — need to check
  tmpdir <- tempdir()
  files_in_zip <- unzip(zip_path, list = TRUE)$Name

  # Find SDEMT file (case-insensitive) — contains all needed variables
  sdemt_file <- grep("sdemt", files_in_zip, ignore.case = TRUE, value = TRUE)

  if (length(sdemt_file) == 0) {
    cat(sprintf("  WARNING: %dQ%d missing sdemt, skipping\n", yr, qq))
    next
  }

  cat(sprintf("  Reading %dQ%d: %s ... ", yr, qq, sdemt_file[1]))

  # Extract SDEMT
  unzip(zip_path, files = sdemt_file[1], exdir = tmpdir, overwrite = TRUE)

  # Read SDEMT (demographics + labor market variables)
  # ENOE stores derived variables (ingocup, hrsocup, seg_soc, pos_ocu) in SDEMT, not COE2
  sdemt <- fread(file.path(tmpdir, sdemt_file[1]), colClasses = "character")
  names(sdemt) <- sub("^\xef\xbb\xbf", "", names(sdemt))
  names(sdemt) <- sub("^\ufeff", "", names(sdemt))
  setnames(sdemt, tolower(names(sdemt)))
  sdemt_want <- c("cd_a", "ent", "con", "v_sel", "n_hog", "h_mud", "n_ren",
                  "sex", "eda", "nac_anio", "anios_esc", "cs_p13_1",
                  "clase1", "clase2", "clase3",
                  "ingocup", "ing_x_hrs", "hrsocup", "pos_ocu", "seg_soc",
                  "rama", "scian")
  sdemt_keep <- intersect(sdemt_want, names(sdemt))
  dt <- sdemt[, ..sdemt_keep]

  # Convert numeric columns
  num_cols <- c("eda", "sex", "nac_anio", "anios_esc", "clase1", "clase2",
                "ingocup", "ing_x_hrs", "hrsocup", "pos_ocu", "seg_soc")
  for (col in intersect(num_cols, names(dt))) {
    dt[[col]] <- suppressWarnings(as.numeric(dt[[col]]))
  }

  # Add quarter identifier
  dt[, year := yr]
  dt[, quarter := qq]
  dt[, yq := yr + (qq - 1) / 4]

  # Filter to ages 15-35
  dt <- dt[eda >= 15 & eda <= 35]

  all_data[[length(all_data) + 1]] <- dt

  cat(sprintf("OK (%s obs ages 15-35)\n", format(nrow(dt), big.mark = ",")))

  # Cleanup
  file.remove(file.path(tmpdir, sdemt_file[1]))
}

# Combine all quarters
enoe <- rbindlist(all_data, fill = TRUE)

cat(sprintf("\n=== ENOE Combined Dataset ===\n"))
cat(sprintf("Total observations (ages 15-35): %s\n", format(nrow(enoe), big.mark = ",")))
cat(sprintf("Quarters: %d (%dQ%d to %dQ%d)\n",
            length(all_data),
            min(enoe$year), min(enoe[year == min(year)]$quarter),
            max(enoe$year), max(enoe[year == max(year)]$quarter)))
cat(sprintf("Males aged 18: %s\n", format(nrow(enoe[sex == 1 & eda == 18]), big.mark = ",")))
cat(sprintf("Females aged 18: %s\n", format(nrow(enoe[sex == 2 & eda == 18]), big.mark = ",")))

stopifnot(nrow(enoe) > 100000)  # Fail loudly if data is insufficient
stopifnot(nrow(enoe[sex == 1 & eda == 18]) > 5000)  # Need enough males at age 18

# Save combined dataset
fwrite(enoe, "data/enoe_combined.csv")
cat(sprintf("Saved: data/enoe_combined.csv (%.0f MB)\n", file.info("data/enoe_combined.csv")$size / 1e6))
