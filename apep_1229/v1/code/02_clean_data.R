# 02_clean_data.R — Clean and construct analysis datasets
# apep_1229: GIPP and Insurance Market Competition

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# 1. ONS CPIH Detailed Indices — Monthly insurance CPI (1988-2026)
# ============================================================================
# Table 37: rows = months (198801...), columns = COICOP categories
# Row 5 = aggregate numbers, Row 6 = CDIDs, Row 7 = names, Row 8+ = data
# Key columns identified by exploration:
#   Col   3: CPIH ALL ITEMS (agg=0, cdid=L522)
#   Col 112: MISCELLANEOUS GOODS AND SERVICES (agg=12, cdid=L55D)
#   Col 120: INSURANCE (agg=12.5, cdid=L55H)
#   Col 121: HOUSE CONTENTS INSURANCE (agg=12.5.2, cdid=L55I)
#   Col 122: HEALTH INSURANCE (agg=12.5.3, cdid=L55J)
#   Col 123: TRANSPORT INSURANCE (agg=12.5.4, cdid=L55K)
#   Col  66: TRANSPORT (agg=7)
#   Col  30: HOUSING (agg=4)

cat("--- Processing ONS CPIH detailed indices ---\n")

raw <- readxl::read_excel(paste0(data_dir, "ons_cpi_detailed.xlsx"),
                          sheet = "Table 37", col_names = FALSE)

# Column map (hardcoded from exploration)
col_map <- list(
  cpih_all    = 3,    # CPIH ALL ITEMS
  insurance   = 120,  # INSURANCE (12.5)
  house_ins   = 121,  # HOUSE CONTENTS INSURANCE (12.5.2)
  health_ins  = 122,  # HEALTH INSURANCE (12.5.3)
  transport_ins = 123 # TRANSPORT INSURANCE (12.5.4)
)

# Data rows: row 8 onwards (row 1 = link, rows 3 = title, row 5 = agg nums,
# row 6 = CDIDs, row 7 = names, row 8 = first data row)
date_col <- as.character(unlist(raw[8:nrow(raw), 1]))
n_data <- length(date_col)

extract_col <- function(col_idx) {
  vals <- suppressWarnings(as.numeric(as.character(unlist(raw[8:(7 + n_data), col_idx]))))
  return(vals)
}

cpih <- tibble(
  date_str = date_col,
  cpih_all = extract_col(col_map$cpih_all),
  insurance = extract_col(col_map$insurance),
  house_ins = extract_col(col_map$house_ins),
  health_ins = extract_col(col_map$health_ins),
  transport_ins = extract_col(col_map$transport_ins)
) %>%
  filter(!is.na(date_str), nchar(date_str) == 6) %>%
  mutate(
    year = as.integer(substr(date_str, 1, 4)),
    month = as.integer(substr(date_str, 5, 6)),
    date = as.Date(paste0(year, "-", sprintf("%02d", month), "-01")),
    post_gipp = as.integer(date >= as.Date("2022-01-01")),
    # Months relative to treatment (Jan 2022 = 0)
    event_time = (year - 2022) * 12 + (month - 1)
  ) %>%
  filter(!is.na(cpih_all))

# Compute year-on-year % changes (12-month log differences)
cpih <- cpih %>%
  arrange(date) %>%
  mutate(
    across(c(cpih_all, insurance, house_ins, health_ins, transport_ins),
           list(yoy = ~(log(.) - log(lag(., 12))) * 100),
           .names = "{.col}_{.fn}")
  )

cat("CPIH panel:", nrow(cpih), "months\n")
cat("Date range:", as.character(min(cpih$date)), "to", as.character(max(cpih$date)), "\n")
cat("Insurance index (Dec 2021):", cpih$insurance[cpih$date == "2021-12-01"], "\n")
cat("Insurance index (Jan 2022):", cpih$insurance[cpih$date == "2022-01-01"], "\n")
cat("Insurance index (Dec 2023):", cpih$insurance[cpih$date == "2023-12-01"], "\n")
cat("Transport ins (Dec 2021):", cpih$transport_ins[cpih$date == "2021-12-01"], "\n")
cat("Transport ins (Jan 2022):", cpih$transport_ins[cpih$date == "2022-01-01"], "\n")
cat("Transport ins (Dec 2023):", cpih$transport_ins[cpih$date == "2023-12-01"], "\n")

saveRDS(cpih, paste0(data_dir, "cpih_panel.rds"))

# ============================================================================
# 2. FCA GI Value Measures — Product-level loss ratios (2021-2024)
# ============================================================================

cat("\n--- Processing FCA GI Value Measures ---\n")

parse_fca_product_table <- function(filepath, file_year) {
  sheets <- readxl::excel_sheets(filepath)
  if (!"Product Table" %in% sheets) {
    cat("  No Product Table in", basename(filepath), "\n")
    return(NULL)
  }

  raw <- readxl::read_excel(filepath, sheet = "Product Table")

  # Header row (row 1) has column descriptions
  # Data starts at row 2
  # The structure varies slightly by year but the key columns are:
  # Col 1: Product Category
  # Last 2 cols: "% of premiums paid out in claims" for year1, year2

  yr1 <- file_year - 1
  yr2 <- file_year
  n_cols <- ncol(raw)

  # Extract product names and loss ratios
  products <- as.character(raw[[1]])[-1]

  # Loss ratio is the last pair of columns
  lr_yr1 <- suppressWarnings(as.numeric(as.character(raw[[n_cols - 1]])[-1]))
  lr_yr2 <- suppressWarnings(as.numeric(as.character(raw[[n_cols]])[-1]))

  # Premiums are columns n_cols-3, n_cols-2
  prem_yr1 <- suppressWarnings(as.numeric(as.character(raw[[n_cols - 3]])[-1]))
  prem_yr2 <- suppressWarnings(as.numeric(as.character(raw[[n_cols - 2]])[-1]))

  # Policies in force: n_cols-5, n_cols-4
  pol_yr1 <- suppressWarnings(as.numeric(as.character(raw[[n_cols - 5]])[-1]))
  pol_yr2 <- suppressWarnings(as.numeric(as.character(raw[[n_cols - 4]])[-1]))

  # Claims frequency: cols 2, 3
  cf_yr1 <- suppressWarnings(as.numeric(as.character(raw[[2]])[-1]))
  cf_yr2 <- suppressWarnings(as.numeric(as.character(raw[[3]])[-1]))

  bind_rows(
    tibble(product = products, year = yr1,
           loss_ratio = lr_yr1, premiums = prem_yr1,
           policies = pol_yr1, claims_freq = cf_yr1,
           source = basename(filepath)),
    tibble(product = products, year = yr2,
           loss_ratio = lr_yr2, premiums = prem_yr2,
           policies = pol_yr2, claims_freq = cf_yr2,
           source = basename(filepath))
  ) %>%
    filter(!is.na(product), product != "Product Category")
}

fca_data <- bind_rows(
  parse_fca_product_table(paste0(data_dir, "fca_gi_vm_2022.xlsx"), 2022),
  parse_fca_product_table(paste0(data_dir, "fca_gi_vm_2023.xlsx"), 2023),
  parse_fca_product_table(paste0(data_dir, "fca_gi_vm_2024.xlsx"), 2024)
)

# Deduplicate: keep observation from the file closest to reporting year
fca_data <- fca_data %>%
  group_by(product, year) %>%
  slice_tail(n = 1) %>%
  ungroup()

# Classify products
# GIPP PS21/5 specifically targeted motor and home insurance loyalty pricing
treated_products <- c(
  "Motor (All)",
  "Home - (buildings and contents combined) (All)",
  "Home - buildings only (All)",
  "Home - contents only (All)"
)

control_products <- c(
  "Pet - covered for life (All)",
  "Pet - maximum benefit (All)",
  "Pet - time limited (All)",
  "Travel - annual european (All)",
  "Travel - annual worldwide (All)",
  "Travel - single trip (Stand-alone)",
  "Gadget (including mobile phone) (Add-on)",
  "Gadget (including mobile phone) (Stand-alone)",
  "Vehicle breakdown (Add-on)",
  "Vehicle breakdown (Stand-alone)",
  "Extended warranty - motor (Stand-alone)",
  "Healthcare cash plan (All)",
  "Personal accident (Add-on)",
  "Personal accident (Stand-alone)"
)

fca_data <- fca_data %>%
  mutate(
    treated = case_when(
      product %in% treated_products ~ 1L,
      product %in% control_products ~ 0L,
      TRUE ~ NA_integer_
    ),
    post = as.integer(year >= 2022),
    product_group = case_when(
      grepl("^Motor", product) ~ "Motor",
      grepl("^Home", product) ~ "Home",
      grepl("^Pet", product) ~ "Pet",
      grepl("^Travel", product) ~ "Travel",
      TRUE ~ "Other"
    )
  ) %>%
  filter(!is.na(treated))

cat("FCA product-level panel:\n")
cat("  Products:", n_distinct(fca_data$product), "\n")
cat("  Years:", paste(sort(unique(fca_data$year)), collapse = ", "), "\n")
cat("  Obs:", nrow(fca_data), "\n")

# Summary table
cat("\nLoss ratios by group and year:\n")
fca_data %>%
  group_by(treated, year) %>%
  summarise(
    n = n(),
    mean_lr = round(mean(loss_ratio, na.rm = TRUE), 3),
    median_lr = round(median(loss_ratio, na.rm = TRUE), 3),
    .groups = "drop"
  ) %>%
  mutate(group = ifelse(treated == 1, "Treated (Motor+Home)", "Control")) %>%
  select(group, year, n, mean_lr, median_lr) %>%
  print(n = 20)

saveRDS(fca_data, paste0(data_dir, "fca_panel.rds"))

# ============================================================================
# Summary
# ============================================================================
cat("\n=== DATA CLEANING COMPLETE ===\n")
cat("1. CPIH monthly panel:", nrow(cpih), "months (1988-2026)\n")
cat("   - Insurance, house insurance, health insurance, transport insurance\n")
cat("2. FCA product panel:", nrow(fca_data), "product-year obs (2021-2024)\n")
cat("   - Treated:", n_distinct(fca_data$product[fca_data$treated == 1]), "products\n")
cat("   - Control:", n_distinct(fca_data$product[fca_data$treated == 0]), "products\n")
