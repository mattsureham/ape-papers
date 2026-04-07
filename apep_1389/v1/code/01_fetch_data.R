## 01_fetch_data.R — Download OSHA ITA 300A data (2016-2024) + Appendix B NAICS
source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ── OSHA ITA 300A Summary Data ──
# URL patterns are inconsistent across years
urls <- c(
  "2016" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202016.zip",
  "2017" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202017.zip",
  "2018" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202018.zip",
  "2019" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202019.zip",
  "2020" = "https://www.osha.gov/sites/default/files/ITA-Data-CY-2020.zip",
  "2021" = "https://www.osha.gov/sites/default/files/ITA-data-cy2021.zip",
  "2022" = "https://www.osha.gov/sites/default/files/ITA-data-cy2022.zip",
  "2023" = "https://www.osha.gov/sites/default/files/ITA_300A_Summary_Data_2023_through_12-31-2024.zip",
  "2024" = "https://www.osha.gov/sites/default/files/ITA_300A_Summary_Data_2024_through_12-31-2025.zip"
)

for (yr in names(urls)) {
  outcsv <- file.path(data_dir, paste0("ita_", yr, ".csv"))
  if (file.exists(outcsv)) {
    message("Already have ", yr, ": ", outcsv)
    next
  }

  zipfile <- file.path(data_dir, paste0("ita_", yr, ".zip"))
  url <- urls[yr]
  message("Downloading ", yr, " ...")

  download.file(url, zipfile, mode = "wb", quiet = TRUE)
  fsize <- file.info(zipfile)$size
  if (is.na(fsize) || fsize < 5000) {
    stop(paste0("FATAL: Download for ", yr, " too small (", fsize, " bytes). URL may have changed."))
  }
  message("  ZIP: ", round(fsize / 1e6, 1), " MB")

  # Extract — find the CSV inside
  contents <- unzip(zipfile, list = TRUE)
  csv_in_zip <- contents$Name[grepl("\\.csv$", contents$Name, ignore.case = TRUE)]
  if (length(csv_in_zip) == 0) {
    stop(paste0("FATAL: No CSV found inside ZIP for ", yr))
  }
  unzip(zipfile, files = csv_in_zip[1], exdir = data_dir, junkpaths = TRUE)

  # Rename extracted CSV to consistent name
  extracted <- file.path(data_dir, basename(csv_in_zip[1]))
  if (extracted != outcsv) {
    file.rename(extracted, outcsv)
  }
  message("  Extracted: ", csv_in_zip[1])

  # Clean up ZIP
  file.remove(zipfile)
}

# Verify
csv_files <- list.files(data_dir, pattern = "^ita_20.*\\.csv$", full.names = TRUE)
message("\n", length(csv_files), " years of ITA data available")
if (length(csv_files) < 7) {
  stop("FATAL: Need at least 7 years of data for credible pre-period analysis")
}

# ── Appendix B NAICS codes (high-hazard industries) ──
# These are the 4-digit NAICS with DART >= 3.5 from BLS SOII
# Source: 29 CFR 1904 Subpart E Appendix B
# We hardcode the official list from the Federal Register (88 FR 47046)
appendix_b <- c(
  # Agriculture
  1111, 1112, 1113, 1114, 1119, 1121, 1122, 1123, 1124, 1125, 1129, 1131, 1132, 1133, 1141, 1142, 1151, 1152, 1153,

  # Mining (subset)
  2121, 2122, 2123, 2131,
  # Utilities
  2211,
  # Construction
  2361, 2362, 2371, 2372, 2373, 2379, 2381, 2382, 2383, 2389,
  # Manufacturing
  3111, 3112, 3113, 3114, 3115, 3116, 3117, 3118, 3119,
  3121, 3122, 3131, 3132, 3133, 3141, 3149,
  3151, 3152, 3159, 3161, 3162, 3169,
  3211, 3212, 3219, 3221, 3222,
  3231, 3241, 3251, 3252, 3253, 3254, 3255, 3256, 3259,
  3261, 3262, 3271, 3272, 3273, 3274, 3279,
  3311, 3312, 3313, 3314, 3315,
  3321, 3322, 3323, 3324, 3325, 3326, 3327, 3328, 3329,
  3331, 3332, 3333, 3334, 3335, 3336, 3339,
  3341, 3342, 3343, 3344, 3345, 3346,
  3351, 3352, 3353, 3359,
  3361, 3362, 3363, 3364, 3365, 3366, 3369,
  3371, 3372, 3379,
  3391, 3399,
  # Wholesale Trade
  4231, 4232, 4233, 4234, 4235, 4236, 4237, 4238, 4239,
  4241, 4242, 4243, 4244, 4245, 4246, 4247, 4248, 4249,
  # Retail Trade (subset)
  4413, 4421, 4422, 4431, 4441, 4442, 4451, 4452, 4453,
  4461, 4471, 4481, 4482, 4483, 4511, 4512, 4521, 4529, 4531, 4532, 4533, 4539, 4541, 4542, 4543,
  # Transportation
  4811, 4812, 4821, 4831, 4832, 4841, 4842, 4851, 4852, 4853, 4854, 4855, 4859,
  4861, 4862, 4869, 4871, 4872, 4879, 4881, 4882, 4883, 4884, 4885, 4889,
  4911, 4921, 4922, 4931,
  # Waste Management
  5621, 5622, 5629,
  # Healthcare
  6211, 6212, 6213, 6214, 6215, 6216, 6219,
  6221, 6222, 6223, 6231, 6232, 6233, 6239, 6241, 6242, 6243, 6244,
  # Arts/Entertainment
  7111, 7112, 7113, 7114, 7115, 7121, 7131, 7132, 7139,
  # Accommodation/Food
  7211, 7212, 7213, 7221, 7222, 7223,
  # Other Services
  8111, 8112, 8113, 8114, 8121, 8122, 8123, 8129, 8131, 8132, 8133, 8134, 8139,
  8141
)

# Save as reference file
writeLines(as.character(appendix_b), file.path(data_dir, "appendix_b_naics.txt"))
message("Appendix B: ", length(appendix_b), " NAICS codes saved")
message("\nData fetch complete.")
