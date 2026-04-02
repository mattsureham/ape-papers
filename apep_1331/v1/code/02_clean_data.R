## 02_clean_data.R — Parse FOS Excel files and build product-quarter panel
## APEP apep_1331: The No-Advice Trap

source("00_packages.R")
library(readxl)

data_dir <- "../data"

fos_files <- sort(list.files(data_dir, pattern = "^fos_Q[0-9]", full.names = TRUE))
cat(sprintf("Found %d FOS files to parse\n", length(fos_files)))

parse_fos_file <- function(fpath) {
  fname <- basename(fpath)
  m <- regmatches(fname, regexec("fos_Q([0-9])_([0-9]{4})\\.xlsx", fname))[[1]]
  if (length(m) < 3) return(NULL)

  quarter_num <- as.integer(m[2])
  fy_start <- as.integer(m[3])
  cal_year <- ifelse(quarter_num == 4, fy_start + 1, fy_start)
  cal_quarter <- c(2, 3, 4, 1)[quarter_num]

  df <- tryCatch(
    read_excel(fpath, sheet = 1, col_names = TRUE),
    error = function(e) { warning(sprintf("Read error: %s", fname)); NULL }
  )
  if (is.null(df) || nrow(df) == 0) return(NULL)

  cn <- tolower(trimws(names(df)))
  cn <- gsub("\\s+", "_", cn)

  # Find product name column (could be "products", "product", "product_name")
  prod_idx <- which(grepl("^product", cn))
  # Find "new cases" or "new complaints" column
  cases_idx <- which(grepl("new_case|new_complaint", cn))
  # Find uphold column
  uphold_idx <- which(grepl("uphold|upheld", cn))

  if (length(prod_idx) == 0 || length(cases_idx) == 0) {
    warning(sprintf("Cannot find columns in %s: cols=%s", fname, paste(cn, collapse=",")))
    return(NULL)
  }

  # Product name is the LAST product column (if there are Group + Product, take Product)
  prod_col <- prod_idx[length(prod_idx)]
  # If there's a Group column, use it
  group_col <- if (length(prod_idx) > 1) prod_idx[1] else NA
  cases_col <- cases_idx[1]
  uph_col <- if (length(uphold_idx) > 0) uphold_idx[1] else NA

  result <- tibble(
    product_group = if (!is.na(group_col)) as.character(df[[group_col]]) else NA_character_,
    product_name = as.character(df[[prod_col]]),
    new_complaints_raw = as.character(df[[cases_col]]),
    uphold_rate_raw = if (!is.na(uph_col)) as.character(df[[uph_col]]) else NA_character_
  ) %>%
    mutate(
      new_complaints = case_when(
        grepl("^<", new_complaints_raw) ~ as.numeric(gsub("<", "", new_complaints_raw)) / 2,
        TRUE ~ suppressWarnings(as.numeric(new_complaints_raw))
      ),
      uphold_rate = case_when(
        is.na(uphold_rate_raw) ~ NA_real_,
        grepl("^<|^-$|^$", uphold_rate_raw) ~ NA_real_,
        TRUE ~ suppressWarnings(as.numeric(uphold_rate_raw))
      ),
      fy_quarter = quarter_num,
      fy_start = fy_start,
      cal_year = cal_year,
      cal_quarter = cal_quarter,
      time_index = cal_year + (cal_quarter - 1) / 4,
      fy_label = sprintf("Q%d %d/%02d", quarter_num, fy_start, (fy_start + 1) %% 100)
    ) %>%
    filter(!is.na(product_name), !is.na(new_complaints))

  return(result)
}

all_data <- bind_rows(compact(map(fos_files, parse_fos_file)))
cat(sprintf("Parsed %d total product-quarter rows from %d files\n",
            nrow(all_data), length(fos_files)))
cat(sprintf("Quarters covered: %d\n", length(unique(all_data$time_index))))

# --- Classify products (case-insensitive) ---
all_data <- all_data %>%
  mutate(
    pn_lower = tolower(trimws(product_name)),
    product_category = case_when(
      # TREATMENT: DB pension transfers (contingent charging ban)
      grepl("defined benefit transfer", pn_lower) ~ "DB Transfer",
      grepl("occupational pension transfer", pn_lower) ~ "DB Transfer",

      # CONTROL 1: Annuities
      pn_lower == "annuities" ~ "Annuities",
      pn_lower == "conventional annuities" ~ "Annuities",

      # CONTROL 2: Personal pensions
      pn_lower == "personal pensions" ~ "Personal Pensions",

      # CONTROL 3: SIPPs
      grepl("^self-invested personal pension", pn_lower) ~ "SIPP",
      grepl("^sipp \\(self", pn_lower) ~ "SIPP",
      grepl("^standard investments$", pn_lower) ~ "SIPP",

      TRUE ~ NA_character_
    )
  )

# Check coverage per quarter
cat("\n=== Coverage by quarter and product ===\n")
coverage <- all_data %>%
  filter(!is.na(product_category)) %>%
  group_by(time_index, fy_label) %>%
  summarise(
    products = paste(sort(unique(product_category)), collapse=","),
    n_products = n_distinct(product_category),
    .groups = "drop"
  ) %>%
  arrange(time_index)
print(coverage, n = 50)

# Build the analysis panel
panel <- all_data %>%
  filter(!is.na(product_category)) %>%
  group_by(product_category, cal_year, cal_quarter, time_index, fy_label) %>%
  summarise(
    new_complaints = sum(new_complaints, na.rm = TRUE),
    uphold_rate = {
      valid <- !is.na(uphold_rate) & !is.na(new_complaints)
      if (sum(valid) > 0) weighted.mean(uphold_rate[valid], new_complaints[valid])
      else NA_real_
    },
    .groups = "drop"
  ) %>%
  arrange(product_category, time_index) %>%
  mutate(
    treated = as.integer(product_category == "DB Transfer"),
    # FCA PS20/6 effective 1 October 2020 = Q4 cal 2020 = time_index 2020.75
    post = as.integer(time_index >= 2020.75),
    did = treated * post,
    ln_complaints = log(new_complaints + 1)
  )

n_products <- length(unique(panel$product_category))
n_quarters <- length(unique(panel$time_index))
pre_q <- length(unique(panel$time_index[panel$post == 0]))
post_q <- length(unique(panel$time_index[panel$post == 1]))

cat(sprintf("\n=== PANEL SUMMARY ===\n"))
cat(sprintf("Observations: %d (%d products × %d quarters)\n", nrow(panel), n_products, n_quarters))
cat(sprintf("Products: %s\n", paste(unique(panel$product_category), collapse = ", ")))
cat(sprintf("Time: %.2f to %.2f\n", min(panel$time_index), max(panel$time_index)))
cat(sprintf("Pre-ban: %d quarters | Post-ban: %d quarters\n", pre_q, post_q))

cat("\n=== Mean complaints by group and period ===\n")
panel %>%
  group_by(product_category, treated, period = ifelse(post, "Post-ban", "Pre-ban")) %>%
  summarise(
    mean = round(mean(new_complaints)),
    sd = round(sd(new_complaints)),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(product_category, period) %>%
  print(n = 20)

saveRDS(panel, file.path(data_dir, "panel.rds"))
saveRDS(all_data, file.path(data_dir, "all_products.rds"))
cat("\nPanel saved.\n")
