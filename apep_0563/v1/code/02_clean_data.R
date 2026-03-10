## ============================================================================
## 02_clean_data.R — Variable Construction
## Japan Dual-Rate Consumption Tax Paper (apep_0563)
## ============================================================================

source("00_packages.R")

data_dir <- "../data"
cpi <- fread(file.path(data_dir, "cpi_clean.csv"))
cpi_detail <- fread(file.path(data_dir, "cpi_detail_clean.csv"))

## --- 1. Create Treatment Variables ---
cat("=== Constructing treatment variables ===\n")

# Treatment: October 2019 dual-rate tax reform
cpi[, post := as.integer(yyyymm >= 201910)]
cpi[, date := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]

# Months relative to treatment (October 2019 = 0)
cpi[, event_time := (year - 2019) * 12 + (month - 10)]

# COVID flag (February 2020 onward = first emergency declaration April 2020,
# but effects started ~Feb 2020)
cpi[, covid := as.integer(yyyymm >= 202002)]

# Clean pre-COVID post-treatment window: Oct 2019 - Jan 2020 (4 months)
cpi[, clean_post := as.integer(post == 1 & covid == 0)]

# Seasonality controls
cpi[, month_factor := factor(month)]
cpi[, quarter := ceiling(month / 3)]

## --- 2. Construct Relative Price Indices ---
cat("=== Constructing relative price indices ===\n")

# Key outcome: relative price of eating out vs. cooked food (takeout)
# If tax passed through, this ratio should jump ~1.85% in Oct 2019
cpi[, relative_eatin_takeout := eating_out / cooked_food * 100]

# Placebo: relative price of alcohol vs. cooked food
# Both went up in Oct 2019, but alcohol by full 2% and cooked food by 0%
cpi[, relative_alcohol_takeout := alcoholic_beverages / cooked_food * 100]

# Normalize to September 2019 = 100
base_eatin <- cpi[yyyymm == 201909, relative_eatin_takeout]
base_alcohol <- cpi[yyyymm == 201909, relative_alcohol_takeout]
cpi[, relative_eatin_norm := relative_eatin_takeout / base_eatin * 100]
cpi[, relative_alcohol_norm := relative_alcohol_takeout / base_alcohol * 100]

# Log indices (for percentage interpretation in regressions)
cpi[, log_eating_out := log(eating_out)]
cpi[, log_cooked_food := log(cooked_food)]
cpi[, log_alcohol := log(alcoholic_beverages)]
cpi[, log_beverages := log(beverages)]
cpi[, log_food := log(food)]
cpi[, log_all := log(all_items)]

# Log relative prices
cpi[, log_relative_eatin := log_eating_out - log_cooked_food]
cpi[, log_relative_alcohol := log_alcohol - log_cooked_food]

## --- 3. Construct DDD Panel ---
cat("=== Constructing DDD panel ===\n")

# Reshape to category-month panel for triple-difference
cpi_long <- melt(cpi,
  id.vars = c("year", "month", "yyyymm", "date", "post", "event_time",
              "covid", "clean_post", "month_factor", "quarter"),
  measure.vars = c("eating_out", "cooked_food", "alcoholic_beverages", "beverages"),
  variable.name = "category",
  value.name = "cpi_index"
)

# Tax rate treatment: which categories got the full 10% rate?
cpi_long[, full_rate := as.integer(category %in% c("eating_out", "alcoholic_beverages"))]

# Differential treatment: which categories got the DIFFERENTIAL rate?
# eating_out = 10% (higher), cooked_food = 8% (lower)
# alcohol = 10% (both eat-in and takeout), beverages = 8% (both)
cpi_long[, differential := as.integer(category == "eating_out")]

# Reduced rate category (8% instead of 10%)
cpi_long[, reduced_rate := as.integer(category %in% c("cooked_food", "beverages"))]

# Category dummies
cpi_long[, is_eating_out := as.integer(category == "eating_out")]
cpi_long[, is_cooked := as.integer(category == "cooked_food")]
cpi_long[, is_alcohol := as.integer(category == "alcoholic_beverages")]

cpi_long[, log_cpi := log(cpi_index)]

## --- 4. Process Detailed CPI for Heterogeneity ---
cat("=== Processing detailed CPI items ===\n")

# Identify detailed item columns (those that aren't metadata)
meta_cols <- c("year", "month", "yyyymm", "base")
item_cols <- setdiff(names(cpi_detail), meta_cols)

# Add treatment variables
cpi_detail[, post := as.integer(yyyymm >= 201910)]
cpi_detail[, date := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]
cpi_detail[, event_time := (year - 2019) * 12 + (month - 10)]
cpi_detail[, covid := as.integer(yyyymm >= 202002)]

## --- 5. Summary Statistics ---
cat("\n=== Summary Statistics ===\n")

# Pre-treatment (2017.10-2019.09) and post-treatment (2019.10-2020.01)
pre <- cpi[yyyymm >= 201710 & yyyymm < 201910]
post_clean <- cpi[yyyymm >= 201910 & yyyymm < 202002]
post_full <- cpi[yyyymm >= 201910]

summ <- data.table(
  Variable = c("Eating out CPI", "Cooked food CPI", "Alcoholic beverages CPI",
               "Relative price (eat-in/takeout)", "All items CPI"),
  Pre_Mean = c(mean(pre$eating_out), mean(pre$cooked_food),
               mean(pre$alcoholic_beverages), mean(pre$relative_eatin_takeout),
               mean(pre$all_items)),
  Pre_SD = c(sd(pre$eating_out), sd(pre$cooked_food),
             sd(pre$alcoholic_beverages), sd(pre$relative_eatin_takeout),
             sd(pre$all_items)),
  Post_Clean_Mean = c(mean(post_clean$eating_out), mean(post_clean$cooked_food),
                      mean(post_clean$alcoholic_beverages),
                      mean(post_clean$relative_eatin_takeout),
                      mean(post_clean$all_items)),
  Post_Full_Mean = c(mean(post_full$eating_out), mean(post_full$cooked_food),
                     mean(post_full$alcoholic_beverages),
                     mean(post_full$relative_eatin_takeout),
                     mean(post_full$all_items)),
  N_Pre = nrow(pre),
  N_Post_Clean = nrow(post_clean),
  N_Total = nrow(cpi)
)
print(summ)

## --- Save ---
fwrite(cpi, file.path(data_dir, "cpi_analysis.csv"))
fwrite(cpi_long, file.path(data_dir, "cpi_panel.csv"))
fwrite(cpi_detail, file.path(data_dir, "cpi_detail_analysis.csv"))
fwrite(summ, file.path(data_dir, "summary_statistics.csv"))

cat("\n✓ Data cleaning complete.\n")
