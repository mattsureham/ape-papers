## 02_clean_data.R — Clean and construct panels for apep_1228
## GIPP waterbed effect in UK insurance

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Bank of England — Line-of-business quarterly panel
## ============================================================

boe_raw <- readxl::read_excel(file.path(data_dir, "boe_insurance_aggregate.xlsx"), sheet = 1)

## Extract Net Written Premium and Loss Ratio by line of business
boe_panel <- boe_raw %>%
  filter(Chart == "Chart 4.1",
         `Chart Feature 1` != "Total") %>%
  select(quarter = `Reporting Period`,
         line = `Chart Feature 1`,
         metric = `Chart Feature 2`,
         gbp_value = `GBP Value`,
         ratio = Ratio) %>%
  mutate(
    value = case_when(
      metric == "Net Written Premium" ~ gbp_value,
      metric == "Loss ratio" ~ ratio,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(value)) %>%
  select(quarter, line, metric, value) %>%
  tidyr::pivot_wider(names_from = metric, values_from = value) %>%
  rename(nwp = `Net Written Premium`, loss_ratio = `Loss ratio`)

## Parse quarter to numeric
boe_panel <- boe_panel %>%
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    q = as.integer(substr(quarter, 6, 6)),
    time = year + (q - 1) / 4,
    ## GIPP treatment: Motor and Property lines were primary targets
    ## FCA PS21/5 specifically covers home and motor insurance
    gipp_target = as.integer(line %in% c("Motor liability", "Motor other", "Property")),
    post = as.integer(time >= 2022.0),
    treat_post = gipp_target * post,
    ## Log NWP for growth analysis
    log_nwp = log(nwp)
  )

cat("=== BoE Panel Summary ===\n")
cat("Lines:", paste(sort(unique(boe_panel$line)), collapse = ", "), "\n")
cat("Quarters:", min(boe_panel$quarter), "to", max(boe_panel$quarter), "\n")
cat("Obs:", nrow(boe_panel), "\n")
cat("GIPP target lines:", sum(boe_panel$gipp_target == 1) / length(unique(boe_panel$quarter)), "per quarter\n")
cat("Control lines:", sum(boe_panel$gipp_target == 0) / length(unique(boe_panel$quarter)), "per quarter\n")
cat("Pre-treatment quarters:", sum(boe_panel$post == 0) / length(unique(boe_panel$line)), "\n")
cat("Post-treatment quarters:", sum(boe_panel$post == 1) / length(unique(boe_panel$line)), "\n\n")

## Summary stats
cat("=== NWP by GIPP target status ===\n")
boe_panel %>%
  group_by(gipp_target, post) %>%
  summarise(
    mean_nwp = mean(nwp, na.rm = TRUE),
    mean_loss_ratio = mean(loss_ratio, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  print()

## ============================================================
## 2. FCA GI Value Measures — Product-level panel
## ============================================================

## Read product-level data across years
read_fca_products <- function(file, year_label) {
  sheet_name <- ifelse(year_label == "2024", "Product Table", "Products")
  skip_n <- ifelse(year_label == "2024", 0, 4)

  raw <- readxl::read_excel(file, sheet = sheet_name, skip = skip_n, col_names = FALSE)

  ## Find the header row
  header_idx <- which(grepl("Product Category|product", raw[[1]], ignore.case = TRUE))[1]
  if (is.na(header_idx)) {
    warning(paste("Could not find header in", file))
    return(NULL)
  }

  ## Set column names from header row
  headers <- as.character(raw[header_idx, ])
  data_rows <- raw[(header_idx + 1):nrow(raw), ]
  names(data_rows) <- headers

  ## Remove NA rows
  data_rows <- data_rows[!is.na(data_rows[[1]]), ]

  return(data_rows)
}

## Read all three years
fca_prod_2022 <- read_fca_products(file.path(data_dir, "fca_gi_vm_2022.xlsx"), "2022")
fca_prod_2023 <- read_fca_products(file.path(data_dir, "fca_gi_vm_2023.xlsx"), "2023")
fca_prod_2024 <- read_fca_products(file.path(data_dir, "fca_gi_vm_2024.xlsx"), "2024")

cat("\n=== FCA Product Table columns ===\n")
if (!is.null(fca_prod_2022)) {
  cat("2022:", paste(names(fca_prod_2022), collapse = " | "), "\n")
  cat("  Products:", nrow(fca_prod_2022), "\n")
}
if (!is.null(fca_prod_2023)) {
  cat("2023:", paste(names(fca_prod_2023), collapse = " | "), "\n")
  cat("  Products:", nrow(fca_prod_2023), "\n")
}
if (!is.null(fca_prod_2024)) {
  cat("2024:", paste(names(fca_prod_2024), collapse = " | "), "\n")
  cat("  Products:", nrow(fca_prod_2024), "\n")
}

## ============================================================
## 3. FCA Firm-level panel (banded data → midpoints)
## ============================================================

read_fca_firms <- function(file, year_label) {
  if (year_label == "2022") {
    raw <- readxl::read_excel(file, sheet = "Firms", skip = 5, col_names = FALSE)
    ## 2022 has 6 columns, no year column (single cross-section = 2021)
    raw <- raw[!is.na(raw[[1]]) & raw[[1]] != "Firm name", ]
    names(raw) <- c("firm_name", "product_category", "claims_freq_band",
                     "claims_accept_band", "claims_complaints_band", "avg_payout_band")
    raw$year <- 2021L
  } else {
    raw <- readxl::read_excel(file, sheet = "Firms")
    names(raw) <- c("firm_name", "product_category", "year",
                     "claims_freq_band", "claims_accept_band",
                     "avg_payout_band", "claims_complaints_band")
    raw$year <- as.integer(raw$year)
  }
  return(raw)
}

firms_2022 <- read_fca_firms(file.path(data_dir, "fca_gi_vm_2022.xlsx"), "2022")
firms_2023 <- read_fca_firms(file.path(data_dir, "fca_gi_vm_2023.xlsx"), "2023")
firms_2024 <- read_fca_firms(file.path(data_dir, "fca_gi_vm_2024.xlsx"), "2024")

## Stack into panel
firms_panel <- bind_rows(firms_2022, firms_2023, firms_2024) %>%
  distinct(firm_name, product_category, year, .keep_all = TRUE)

## Parse band midpoints
parse_band_midpoint <- function(band) {
  ## Handle various formats: "0 - 5%", "£0 - £100", "50 - 55%"
  nums <- as.numeric(str_extract_all(band, "[0-9]+\\.?[0-9]*")[[1]])
  if (length(nums) >= 2) return(mean(nums[1:2]))
  if (length(nums) == 1) return(nums[1])
  return(NA_real_)
}

firms_panel <- firms_panel %>%
  rowwise() %>%
  mutate(
    claims_freq_mid = parse_band_midpoint(claims_freq_band),
    claims_accept_mid = parse_band_midpoint(claims_accept_band),
    claims_complaints_mid = parse_band_midpoint(claims_complaints_band)
  ) %>%
  ungroup() %>%
  mutate(
    ## Classify products into GIPP-exposure groups
    gipp_exposure = case_when(
      grepl("^Motor|^Home", product_category) ~ "high",
      grepl("Travel|Pet|Vehicle breakdown", product_category) ~ "medium",
      TRUE ~ "low"
    ),
    post = as.integer(year >= 2022),
    high_gipp = as.integer(gipp_exposure == "high"),
    treat_post = high_gipp * post
  )

cat("\n=== FCA Firm Panel Summary ===\n")
cat("Total obs:", nrow(firms_panel), "\n")
cat("Unique firms:", length(unique(firms_panel$firm_name)), "\n")
cat("Unique products:", length(unique(firms_panel$product_category)), "\n")
cat("Years:", paste(sort(unique(firms_panel$year)), collapse = ", "), "\n")
cat("Obs by year:\n")
print(table(firms_panel$year))
cat("\nGIPP exposure:\n")
print(table(firms_panel$gipp_exposure, firms_panel$year))

## ============================================================
## 4. Save cleaned panels
## ============================================================

saveRDS(boe_panel, file.path(data_dir, "boe_panel.rds"))
saveRDS(firms_panel, file.path(data_dir, "firms_panel.rds"))

cat("\nCleaned panels saved to data/\n")
