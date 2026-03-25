## 02_clean_data.R — Read, merge, and clean USSC sentencing data
## APEP-0935: First Step Act Safety Valve and Judge Leniency
## Handles both fixed-width .dat files (FY2016-2023) and CSV (FY2024)

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# Helper: Parse SAS INPUT statement for column positions
# ============================================================
parse_sas_input <- function(sas_file) {
  lines <- readLines(sas_file)

  # Find INPUT block
  input_start <- grep("^\\s*INPUT", lines, ignore.case = TRUE)
  if (length(input_start) == 0) stop("No INPUT statement found")
  input_start <- input_start[1]

  # Find the semicolon that ends the INPUT statement
  input_end <- input_start
  for (i in input_start:length(lines)) {
    if (grepl(";", lines[i])) {
      input_end <- i
      break
    }
  }

  # Combine INPUT block into one string
  input_block <- paste(lines[input_start:input_end], collapse = " ")
  input_block <- gsub("INPUT|;", "", input_block)

  # Parse variable definitions
  # Patterns: VARNAME $ start-end  OR  VARNAME start-end  OR  VARNAME $ pos
  tokens <- strsplit(trimws(input_block), "\\s+")[[1]]

  specs <- data.frame(
    name = character(),
    start = integer(),
    end = integer(),
    type = character(),
    stringsAsFactors = FALSE
  )

  i <- 1
  while (i <= length(tokens)) {
    tok <- tokens[i]

    # Skip empty tokens
    if (tok == "" || tok == "$") { i <- i + 1; next }

    # Check if this looks like a variable name (letters, digits, underscore, starts with letter)
    if (grepl("^[A-Za-z]", tok)) {
      name <- tok
      is_char <- FALSE
      i <- i + 1

      # Check for $ (character type)
      if (i <= length(tokens) && tokens[i] == "$") {
        is_char <- TRUE
        i <- i + 1
      }

      # Get position(s)
      if (i <= length(tokens)) {
        pos_str <- tokens[i]
        if (grepl("^\\d+-\\d+$", pos_str)) {
          # Range: start-end
          parts <- as.integer(strsplit(pos_str, "-")[[1]])
          specs <- rbind(specs, data.frame(
            name = name, start = parts[1], end = parts[2],
            type = ifelse(is_char, "character", "numeric"),
            stringsAsFactors = FALSE
          ))
          i <- i + 1
        } else if (grepl("^\\d+$", pos_str)) {
          # Single position
          pos <- as.integer(pos_str)
          specs <- rbind(specs, data.frame(
            name = name, start = pos, end = pos,
            type = ifelse(is_char, "character", "numeric"),
            stringsAsFactors = FALSE
          ))
          i <- i + 1
        }
      }
    } else {
      i <- i + 1
    }
  }

  specs
}

# Variables we need (uppercase)
needed_vars <- c(
  "USSCIDN", "SENTTOT", "SENSPLT0", "TOTPRISN", "SENTTCAP",
  "AGE", "MONSEX", "NEWRACE", "XCRHISSR", "XFOLSOR",
  "DISTRICT", "CIRCDIST", "CITIZEN", "EDUCATN",
  "DRUGTYP", "DRUGTYP1", "PRIMARY", "OFFTYPE2", "STATMIN", "STATMAX",
  "SAFE", "SAFETY", "DEPMAND", "BOOTEFCT", "SENTRNGE",
  "MAND1", "MAND2", "MAND3", "MAND4", "MAND5", "MAND6",
  "IS924C", "COMBDRG2", "DISPOSIT", "NUMSV", "NODRUG", "DRUGMIN"
)

# ============================================================
# 1. Read all USSC yearly files
# ============================================================
cat("=== Reading USSC individual datafiles ===\n")

ussc_years <- 2014:2024
all_dfs <- list()

for (yr in ussc_years) {
  extract_dir <- file.path(data_dir, paste0("ussc_fy", yr))

  if (yr == 2024) {
    # CSV format for FY2024
    csv_file <- list.files(extract_dir, pattern = "\\.csv$",
                           full.names = TRUE, ignore.case = TRUE)
    if (length(csv_file) == 0) {
      cat(sprintf("  FY%d: NO CSV FILE - skipping\n", yr))
      next
    }
    cat(sprintf("  FY%d: reading CSV...\n", yr))
    # Read header to find matching columns
    hdr <- names(data.table::fread(csv_file[1], nrows = 0))
    sel_cols <- hdr[toupper(hdr) %in% needed_vars]
    df <- data.table::fread(csv_file[1], showProgress = FALSE, select = sel_cols)
    df <- as_tibble(df)
    names(df) <- toupper(names(df))
    df$FISCALYR <- yr
    cat(sprintf("  FY%d: %d rows, %d cols\n", yr, nrow(df), ncol(df)))
    all_dfs[[as.character(yr)]] <- df
  } else {
    # Fixed-width .dat format with SAS read program
    dat_file <- list.files(extract_dir, pattern = "\\.dat$",
                           full.names = TRUE, ignore.case = TRUE)
    sas_file <- list.files(extract_dir, pattern = "\\.sas$",
                           full.names = TRUE, ignore.case = TRUE)

    if (length(dat_file) == 0 || length(sas_file) == 0) {
      cat(sprintf("  FY%d: NO DAT/SAS FILES - skipping\n", yr))
      next
    }

    cat(sprintf("  FY%d: parsing SAS input spec...\n", yr))
    specs <- parse_sas_input(sas_file[1])
    cat(sprintf("    Total variables defined: %d\n", nrow(specs)))

    # Filter to only needed variables
    specs_needed <- specs[toupper(specs$name) %in% needed_vars, ]
    cat(sprintf("    Needed variables found: %d of %d\n",
                nrow(specs_needed), length(needed_vars)))

    if (nrow(specs_needed) == 0) {
      cat(sprintf("  FY%d: NO MATCHING VARIABLES - skipping\n", yr))
      next
    }

    # Build fwf column positions
    col_positions <- readr::fwf_positions(
      start = specs_needed$start,
      end = specs_needed$end,
      col_names = toupper(specs_needed$name)
    )

    col_types_vec <- ifelse(specs_needed$type == "character", "c", "d")
    col_types_str <- paste(col_types_vec, collapse = "")

    cat(sprintf("  FY%d: reading fixed-width data...\n", yr))
    df <- readr::read_fwf(
      dat_file[1],
      col_positions = col_positions,
      col_types = col_types_str,
      show_col_types = FALSE,
      progress = FALSE
    )

    df$FISCALYR <- yr
    cat(sprintf("  FY%d: %d rows, %d cols\n", yr, nrow(df), ncol(df)))
    all_dfs[[as.character(yr)]] <- df
  }
}

# ============================================================
# 2. Bind all years
# ============================================================
cat("\n=== Binding all years ===\n")

if (length(all_dfs) == 0) {
  stop("FATAL: No data files could be read.")
}

ussc <- bind_rows(all_dfs, .id = "source_year")
cat(sprintf("  Combined dataset: %d rows, %d cols\n", nrow(ussc), ncol(ussc)))
cat(sprintf("  Years: %s\n", paste(sort(unique(ussc$FISCALYR)), collapse = ", ")))

# ============================================================
# 3. Clean and construct analysis variables
# ============================================================
cat("\n=== Constructing analysis variables ===\n")

# Sentence variable
if ("SENTTOT" %in% names(ussc)) {
  ussc$sentence_months <- as.numeric(ussc$SENTTOT)
} else if ("TOTPRISN" %in% names(ussc)) {
  ussc$sentence_months <- as.numeric(ussc$TOTPRISN)
} else {
  stop("FATAL: No sentence variable found")
}

# Handle special codes (9996=probation, 9997=fine, 9998=suspended, 9999=missing)
ussc <- ussc %>%
  mutate(
    sentence_months = ifelse(sentence_months >= 9996, NA_real_, sentence_months)
  )

ussc$fiscal_year <- as.integer(ussc$FISCALYR)

# Construct analysis variables
ussc <- ussc %>%
  mutate(
    post_fsa = as.integer(fiscal_year >= 2019),
    crim_hist = as.integer(XCRHISSR),
    newly_eligible = as.integer(crim_hist %in% c(2, 3, 4)),
    already_eligible = as.integer(crim_hist == 1),
    treated = post_fsa * newly_eligible,

    race = case_when(
      NEWRACE == 1 ~ "White",
      NEWRACE == 2 ~ "Black",
      NEWRACE == 3 ~ "Hispanic",
      TRUE ~ "Other"
    ),
    black = as.integer(NEWRACE == 2),
    hispanic = as.integer(NEWRACE == 3),
    female = as.integer(MONSEX == 1),
    age = as.numeric(AGE),
    us_citizen = as.integer(CITIZEN == 1),
    district = as.character(DISTRICT),
    offense_level = as.integer(XFOLSOR),
    safety_valve = as.integer(
      coalesce(as.integer(SAFE == 1), as.integer(SAFETY == 1), 0L)
    ),
    has_mandatory_min = as.integer(!is.na(STATMIN) & as.numeric(STATMIN) > 0 &
                                    as.numeric(STATMIN) < 9000)
  )

# Add missing columns as NA to prevent errors
for (v in c("NODRUG", "DRUGMIN", "DRUGTYP1", "DRUGTYP", "SAFETY", "SAFE")) {
  if (!v %in% names(ussc)) ussc[[v]] <- NA_real_
}

# Drug offense: NODRUG >= 1, or DRUGMIN > 0, or DRUGTYP1 > 0
ussc <- ussc %>%
  mutate(
    drug_offense = as.integer(
      (!is.na(NODRUG) & as.numeric(NODRUG) >= 1) |
      (!is.na(DRUGMIN) & as.numeric(DRUGMIN) > 0 & as.numeric(DRUGMIN) < 9000) |
      (!is.na(DRUGTYP1) & as.numeric(DRUGTYP1) > 0) |
      (!is.na(DRUGTYP) & as.numeric(DRUGTYP) > 0)
    )
  )

cat(sprintf("  Drug offenses: %d (%.1f%%)\n",
            sum(ussc$drug_offense, na.rm = TRUE),
            100 * mean(ussc$drug_offense, na.rm = TRUE)))

# ============================================================
# 4. Filter to drug trafficking offenses
# ============================================================
cat("\n=== Filtering to drug trafficking cases ===\n")

drug_df <- ussc %>%
  filter(
    drug_offense == 1,
    !is.na(sentence_months),
    !is.na(crim_hist),
    crim_hist >= 1 & crim_hist <= 6,
    !is.na(district),
    fiscal_year >= 2014,
    fiscal_year <= 2024
  )

cat(sprintf("  Drug cases with valid data: %d\n", nrow(drug_df)))
cat(sprintf("  Years: %s\n", paste(sort(unique(drug_df$fiscal_year)), collapse=", ")))

# Criminal history distribution
cat("\n  Criminal history by year:\n")
xtab <- table(drug_df$crim_hist, drug_df$fiscal_year)
print(xtab)

# ============================================================
# 5. District-level leniency proxy
# ============================================================
cat("\n=== District-level leniency measures ===\n")

pre_fsa_district <- drug_df %>%
  filter(fiscal_year <= 2018, crim_hist == 1) %>%
  group_by(district) %>%
  summarise(
    n_pre = n(),
    pre_sv_rate = mean(safety_valve, na.rm = TRUE),
    pre_mean_sentence = mean(sentence_months, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_pre >= 20)

cat(sprintf("  Districts with 20+ pre-FSA eligible cases: %d\n", nrow(pre_fsa_district)))

if (nrow(pre_fsa_district) > 0) {
  cat(sprintf("  Pre-FSA safety valve rate: mean=%.1f%%, range=[%.1f%%, %.1f%%]\n",
              100 * mean(pre_fsa_district$pre_sv_rate),
              100 * min(pre_fsa_district$pre_sv_rate),
              100 * max(pre_fsa_district$pre_sv_rate)))
}

drug_df <- drug_df %>%
  left_join(pre_fsa_district %>% select(district, pre_sv_rate, n_pre),
            by = "district")

drug_df <- drug_df %>%
  mutate(
    leniency_tercile = ntile(pre_sv_rate, 3),
    high_leniency = as.integer(pre_sv_rate > median(pre_sv_rate, na.rm = TRUE))
  )

# ============================================================
# 6. Save
# ============================================================
analysis_df <- drug_df %>% filter(!is.na(pre_sv_rate))

cat(sprintf("\n=== Final analysis sample ===\n"))
cat(sprintf("  Observations: %d\n", nrow(analysis_df)))
cat(sprintf("  Districts: %d\n", n_distinct(analysis_df$district)))
cat(sprintf("  Years: %s\n", paste(sort(unique(analysis_df$fiscal_year)), collapse=", ")))
cat(sprintf("  Newly eligible (CH 2-4): %d (%.1f%%)\n",
            sum(analysis_df$newly_eligible),
            100 * mean(analysis_df$newly_eligible)))
cat(sprintf("  Post-FSA: %d (%.1f%%)\n",
            sum(analysis_df$post_fsa),
            100 * mean(analysis_df$post_fsa)))

saveRDS(analysis_df, file.path(data_dir, "analysis_df.rds"))
cat("  Saved analysis_df.rds\n")
cat("\n=== Data cleaning complete ===\n")
