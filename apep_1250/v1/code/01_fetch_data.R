source("code/00_packages.R")

ensure_dir("data/raw")
ensure_dir("data/raw/moj_zip")

downloads <- tribble(
  ~url, ~dest,
  "https://www.fca.org.uk/publication/data/underlying-data-hcstc-consumer-credit-01-19.xlsx",
  "data/raw/fca_hcstc_underlying_2019.xlsx",
  "https://assets.publishing.service.gov.uk/media/689b69807b0b51a850e940c1/Mortgage_and_landlord_statistical_data.zip",
  "data/raw/moj_possession_data.zip",
  "https://assets.publishing.service.gov.uk/media/689caedb9a65499b44636203/Mortgage_and_Landlord_Possession_Accessible_Tables_Q2_Apr_to_Jun_2025.ods",
  "data/raw/moj_possession_q2_2025.ods"
)

for (i in seq_len(nrow(downloads))) {
  if (!file.exists(downloads$dest[i])) {
    download.file(downloads$url[i], downloads$dest[i], mode = "wb", quiet = TRUE)
  }
  stopifnot(file.exists(downloads$dest[i]))
}

zip_target <- "data/raw/moj_zip/LA CSV.csv"
if (!file.exists(zip_target)) {
  unzip("data/raw/moj_possession_data.zip", exdir = "data/raw/moj_zip")
}

required_files <- c(
  "data/raw/fca_hcstc_underlying_2019.xlsx",
  "data/raw/moj_zip/LA CSV.csv",
  "data/raw/moj_zip/court CSV.csv",
  "data/raw/moj_zip/MAP_CSV.csv"
)

stopifnot(all(file.exists(required_files)))

cat("Downloaded and validated raw FCA and MoJ files.\n")

