# 01_fetch_data.R — Fetch ARCOS data from Azure
# apep_1344: The Potency Arms Race
# TRANSACTION_DATE is BIGINT in MMDDYYYY format. Year = TRANSACTION_DATE % 10000.

source("00_packages.R")

# Load .env explicitly (azure_data.R's auto-load may not find it from deep paths)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

source("../../../../scripts/lib/azure_data.R")

cat("=== Step 1: Load ARCOS oxycodone transactions from Azure ===\n")
con <- apep_azure_connect()

# Oxycodone: manufacturer × county × year × dose strength
cat("Querying oxycodone by manufacturer/dose/county/year...\n")
oxy_detail <- DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE,
    BUYER_COUNTY,
    Reporter_family,
    Revised_Company_Name,
    DRUG_NAME,
    dos_str,
    MME_Conversion_Factor,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    SUM(DOSAGE_UNIT) AS total_pills,
    SUM(DOSAGE_UNIT * CAST(dos_str AS DOUBLE) * MME_Conversion_Factor) AS total_mme
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE DRUG_NAME LIKE '%OXYCODONE%'
    AND CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
")
cat(sprintf("Oxycodone detail rows: %s\n", format(nrow(oxy_detail), big.mark = ",")))

# Hydrocodone: county × year for placebo
cat("Querying hydrocodone for placebo test...\n")
hydro_cy <- DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE,
    BUYER_COUNTY,
    Revised_Company_Name,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    SUM(DOSAGE_UNIT) AS total_pills,
    SUM(DOSAGE_UNIT * CAST(dos_str AS DOUBLE) * MME_Conversion_Factor) AS total_mme
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE DRUG_NAME LIKE '%HYDROCODONE%'
    AND CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY 1, 2, 3, 4
")
cat(sprintf("Hydrocodone rows: %s\n", format(nrow(hydro_cy), big.mark = ",")))

apep_azure_disconnect(con)

cat("\n=== Step 2: Build county-year oxycodone panel ===\n")

county_oxy <- oxy_detail %>%
  mutate(dos_numeric = as.numeric(dos_str)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY, year) %>%
  summarise(
    total_oxy_pills = sum(total_pills, na.rm = TRUE),
    total_oxy_mme = sum(total_mme, na.rm = TRUE),
    mme_per_pill = sum(total_mme, na.rm = TRUE) / sum(total_pills[!is.na(total_mme)], na.rm = TRUE),
    high_dose_pills = sum(total_pills[dos_numeric >= 20], na.rm = TRUE),
    high_dose_share = sum(total_pills[dos_numeric >= 20], na.rm = TRUE) / sum(total_pills, na.rm = TRUE),
    n_manufacturers = n_distinct(Revised_Company_Name),
    n_products = n_distinct(paste(Revised_Company_Name, dos_str)),
    .groups = "drop"
  )

cat(sprintf("County-year panel: %s rows, %s counties\n",
            format(nrow(county_oxy), big.mark = ","),
            format(n_distinct(paste(county_oxy$BUYER_STATE, county_oxy$BUYER_COUNTY)), big.mark = ",")))

cat("\n=== Step 3: 2006 Mallinckrodt oxycodone share (instrument) ===\n")

# Check what Mallinckrodt names look like in the data
malli_names <- oxy_detail %>%
  filter(grepl("MALLINCKRODT|COVIDIEN|SpecGx", Revised_Company_Name, ignore.case = TRUE)) %>%
  pull(Revised_Company_Name) %>%
  unique()
cat("Mallinckrodt-related names in data:", paste(malli_names, collapse = ", "), "\n")

malli_share_2006 <- oxy_detail %>%
  filter(year == 2006) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(
    total_oxy_pills_2006 = sum(total_pills),
    malli_pills_2006 = sum(total_pills[grepl("MALLINCKRODT|COVIDIEN|SpecGx",
                                              Revised_Company_Name, ignore.case = TRUE)]),
    malli_share_2006 = malli_pills_2006 / total_oxy_pills_2006,
    .groups = "drop"
  )

cat(sprintf("Counties with 2006 data: %s\n", nrow(malli_share_2006)))
cat(sprintf("Mean Mallinckrodt share: %.4f\n", mean(malli_share_2006$malli_share_2006, na.rm = TRUE)))
cat(sprintf("SD Mallinckrodt share: %.4f\n", sd(malli_share_2006$malli_share_2006, na.rm = TRUE)))
cat(sprintf("Counties with any Mallinckrodt: %d (%.1f%%)\n",
            sum(malli_share_2006$malli_share_2006 > 0),
            100 * mean(malli_share_2006$malli_share_2006 > 0)))

# Verify Mallinckrodt's product expansion
cat("\n=== Mallinckrodt product line expansion ===\n")
malli_products <- oxy_detail %>%
  filter(grepl("MALLINCKRODT|COVIDIEN|SpecGx", Revised_Company_Name, ignore.case = TRUE)) %>%
  group_by(year) %>%
  summarise(
    n_strengths = n_distinct(dos_str),
    strengths = paste(sort(unique(dos_str)), collapse = ", "),
    total_pills = sum(total_pills),
    avg_mme_pill = sum(total_mme) / sum(total_pills),
    .groups = "drop"
  )
print(malli_products)

cat("\n=== Step 4: Potency changes (pre vs post) ===\n")

potency_pre <- county_oxy %>%
  filter(year %in% c(2006, 2007)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(
    mme_per_pill_pre = weighted.mean(mme_per_pill, total_oxy_pills, na.rm = TRUE),
    high_dose_share_pre = weighted.mean(high_dose_share, total_oxy_pills, na.rm = TRUE),
    total_pills_pre = sum(total_oxy_pills, na.rm = TRUE),
    .groups = "drop"
  )

potency_post <- county_oxy %>%
  filter(year %in% c(2009, 2010)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(
    mme_per_pill_post = weighted.mean(mme_per_pill, total_oxy_pills, na.rm = TRUE),
    high_dose_share_post = weighted.mean(high_dose_share, total_oxy_pills, na.rm = TRUE),
    total_pills_post = sum(total_oxy_pills, na.rm = TRUE),
    .groups = "drop"
  )

hydro_pre <- hydro_cy %>%
  filter(year %in% c(2006, 2007)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(hydro_mme_pre = sum(total_mme) / sum(total_pills), .groups = "drop")

hydro_post <- hydro_cy %>%
  filter(year %in% c(2009, 2010)) %>%
  group_by(BUYER_STATE, BUYER_COUNTY) %>%
  summarise(hydro_mme_post = sum(total_mme) / sum(total_pills), .groups = "drop")

cat("\n=== Step 5: Merge analysis dataset ===\n")

analysis_df <- malli_share_2006 %>%
  inner_join(potency_pre, by = c("BUYER_STATE", "BUYER_COUNTY")) %>%
  inner_join(potency_post, by = c("BUYER_STATE", "BUYER_COUNTY")) %>%
  left_join(hydro_pre, by = c("BUYER_STATE", "BUYER_COUNTY")) %>%
  left_join(hydro_post, by = c("BUYER_STATE", "BUYER_COUNTY")) %>%
  mutate(
    delta_mme = mme_per_pill_post - mme_per_pill_pre,
    delta_high_dose = high_dose_share_post - high_dose_share_pre,
    delta_hydro_mme = hydro_mme_post - hydro_mme_pre,
    log_pills_pre = log(total_pills_pre + 1)
  ) %>%
  filter(total_pills_pre >= 1000, total_pills_post >= 1000)

cat(sprintf("Analysis dataset: %s counties\n", nrow(analysis_df)))
cat(sprintf("Mean potency change (MME/pill): %.3f (SD: %.3f)\n",
            mean(analysis_df$delta_mme, na.rm = TRUE),
            sd(analysis_df$delta_mme, na.rm = TRUE)))

# Quintile means for verification
cat("\n=== First stage preview (quintiles) ===\n")
analysis_df %>%
  mutate(q = ntile(malli_share_2006, 5)) %>%
  group_by(q) %>%
  summarise(
    n = n(),
    malli_share = mean(malli_share_2006),
    delta_mme = mean(delta_mme, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== Step 6: Annual panel for event study ===\n")

panel_df <- county_oxy %>%
  inner_join(malli_share_2006, by = c("BUYER_STATE", "BUYER_COUNTY")) %>%
  filter(total_oxy_pills >= 500) %>%
  mutate(
    county_id = paste(BUYER_STATE, BUYER_COUNTY, sep = "_"),
    post = as.integer(year >= 2008)
  )

cat(sprintf("Annual panel: %s county-years, %s counties\n",
            format(nrow(panel_df), big.mark = ","),
            format(n_distinct(panel_df$county_id), big.mark = ",")))

cat("\n=== Step 7: Save ===\n")
saveRDS(analysis_df, "../data/analysis_df.rds")
saveRDS(panel_df, "../data/panel_df.rds")
saveRDS(county_oxy, "../data/county_oxy.rds")
saveRDS(oxy_detail, "../data/oxy_detail.rds")

cat("All data saved to data/\n")
cat("=== Data fetch complete ===\n")
