# 02_clean_data.R — Construct analysis panel
# APEP Paper apep_0956: Rockets and Feathers in Food Taxation

source("00_packages.R")

# =============================================================================
# 1. Load raw data
# =============================================================================
dk_cpi <- readRDS("../data/dk_cpi_pris6.rds")
hicp <- readRDS("../data/eurostat_hicp.rds")

# =============================================================================
# 2. Denmark product-level panel
# =============================================================================

# Define treatment status based on saturated fat content
# Tax applied to products >2.3% saturated fat: butter, cheese, meat (partial)
# Control: fish, bread/cereals, fruit, vegetables, sugar

# Use ALL available subcategories for maximum cross-sectional variation
# The tax applied to products with >2.3% saturated fat by weight
# Treated subcategories:
treated_codes <- c(
  "011500",   # Butter, oils, margarine (~52% sat fat for butter)
  "011440",   # Cheese (~20% sat fat)
  "011430",   # Other dairy (cream, yogurt — many exceed 2.3%)
  "011410",   # Milk (whole milk ~2.3%, threshold product)
  "011210",   # Beef (~5-10% sat fat)
  "011220",   # Veal
  "011230",   # Pork (~4-8% sat fat)
  "011240",   # Lamb (~8% sat fat)
  "011250",   # Poultry (~2-4% sat fat, marginal)
  "011260"    # Processed meat/offal
)
# Control subcategories (all <2.3% saturated fat or exempt):
control_codes <- c(
  "011100",   # Bread and cereals
  "011300",   # Fish
  "011450",   # Eggs (<2% sat fat)
  "011600",   # Fruit
  "011710",   # Fresh vegetables
  "011720",   # Potatoes
  "011735",   # Frozen vegetables
  "011800",   # Sugar/sweets
  "011900",   # Other food
  "012100",   # Coffee/tea/cocoa
  "012200"    # Soda/mineral water/juice
)
# Also keep the aggregate meat code for aggregate analysis
aggregate_meat_code <- "011200"

dk_panel <- dk_cpi %>%
  filter(product_code %in% c(treated_codes, control_codes)) %>%
  mutate(
    treated = as.integer(product_code %in% treated_codes),
    product_name = case_when(
      product_code == "011500" ~ "Butter/Oils",
      product_code == "011440" ~ "Cheese",
      product_code == "011430" ~ "Other Dairy",
      product_code == "011410" ~ "Milk",
      product_code == "011210" ~ "Beef",
      product_code == "011220" ~ "Veal",
      product_code == "011230" ~ "Pork",
      product_code == "011240" ~ "Lamb",
      product_code == "011250" ~ "Poultry",
      product_code == "011260" ~ "Processed Meat",
      product_code == "011300" ~ "Fish",
      product_code == "011100" ~ "Bread/Cereals",
      product_code == "011450" ~ "Eggs",
      product_code == "011600" ~ "Fruit",
      product_code == "011710" ~ "Fresh Vegetables",
      product_code == "011720" ~ "Potatoes",
      product_code == "011735" ~ "Frozen Vegetables",
      product_code == "011800" ~ "Sugar/Sweets",
      product_code == "011900" ~ "Other Food",
      product_code == "012100" ~ "Coffee/Tea",
      product_code == "012200" ~ "Soda/Juice",
      TRUE ~ product_label
    ),
    # Tax treatment intensity
    treatment_intensity = case_when(
      product_code == "011500" ~ "high",
      product_code %in% c("011440", "011430") ~ "medium",
      product_code %in% c("011410", "011210", "011220", "011230", "011240", "011250", "011260") ~ "low",
      TRUE ~ "none"
    ),
    # Broad category for aggregate results
    broad_category = case_when(
      product_code == "011500" ~ "Butter/Oils",
      product_code == "011440" ~ "Cheese",
      product_code %in% c("011210", "011220", "011230", "011240", "011250", "011260") ~ "Meat",
      TRUE ~ "Control"
    )
  )

# Also build aggregate panel (butter/oils, cheese, aggregate meat, controls)
dk_panel_agg <- dk_cpi %>%
  filter(product_code %in% c("011500", "011440", aggregate_meat_code,
                              "011300", "011100", "011600", "011700")) %>%
  mutate(
    treated = as.integer(product_code %in% c("011500", "011440", aggregate_meat_code)),
    product_name = case_when(
      product_code == "011500" ~ "Butter/Oils",
      product_code == "011440" ~ "Cheese",
      product_code == "011200" ~ "Meat",
      product_code == "011300" ~ "Fish",
      product_code == "011100" ~ "Bread/Cereals",
      product_code == "011600" ~ "Fruit",
      product_code == "011700" ~ "Vegetables",
      TRUE ~ product_label
    ),
    treatment_intensity = case_when(
      product_code == "011500" ~ "high",
      product_code == "011440" ~ "medium",
      product_code == "011200" ~ "low",
      TRUE ~ "none"
    )
  )

# Define event periods
# Tax introduction: October 1, 2011
# Tax abolition: January 1, 2013
dk_panel <- dk_panel %>%
  mutate(
    # Time relative to introduction (Oct 2011 = month 0)
    intro_date = as.Date("2011-10-01"),
    abolish_date = as.Date("2013-01-01"),

    # Period indicators
    pre_tax = as.integer(date < intro_date),
    tax_period = as.integer(date >= intro_date & date < abolish_date),
    post_abolish = as.integer(date >= abolish_date),

    # Post indicator (for simple DiD: post = during or after tax)
    post_intro = as.integer(date >= intro_date),
    post_abolish_ind = as.integer(date >= abolish_date),

    # Event time relative to introduction (in months)
    event_time_intro = as.integer(round(difftime(date, intro_date, units = "days") / 30.44)),

    # Event time relative to abolition (in months)
    event_time_abolish = as.integer(round(difftime(date, abolish_date, units = "days") / 30.44)),

    # Log CPI
    log_cpi = log(cpi),

    # Calendar month for seasonality
    cal_month = factor(month),

    # Numeric time trend
    time_trend = as.numeric(date - as.Date("2000-01-01")) / 365.25,

    # Product group as factor
    product_fct = factor(product_code)
  )

# Restrict to analysis window: Jan 2008 - Dec 2015
dk_panel <- dk_panel %>%
  filter(date >= as.Date("2008-01-01") & date <= as.Date("2015-12-01"))

# Apply same transformations to aggregate panel
dk_panel_agg <- dk_panel_agg %>%
  mutate(
    intro_date = as.Date("2011-10-01"),
    abolish_date = as.Date("2013-01-01"),
    pre_tax = as.integer(date < intro_date),
    tax_period = as.integer(date >= intro_date & date < abolish_date),
    post_abolish = as.integer(date >= abolish_date),
    post_intro = as.integer(date >= intro_date),
    post_abolish_ind = as.integer(date >= abolish_date),
    event_time_intro = as.integer(round(difftime(date, intro_date, units = "days") / 30.44)),
    event_time_abolish = as.integer(round(difftime(date, abolish_date, units = "days") / 30.44)),
    log_cpi = log(cpi),
    cal_month = factor(month),
    time_trend = as.numeric(date - as.Date("2000-01-01")) / 365.25,
    product_fct = factor(product_code),
    is_butter = as.integer(product_code == "011500"),
    is_cheese = as.integer(product_code == "011440"),
    is_meat = as.integer(product_code == "011200")
  ) %>%
  filter(date >= as.Date("2008-01-01") & date <= as.Date("2015-12-01"))

cat("Denmark analysis panel:", nrow(dk_panel), "obs\n")
cat("  Products:", n_distinct(dk_panel$product_code), "\n")
cat("  Months:", n_distinct(dk_panel$date), "\n")
cat("  Treated products:", sum(dk_panel$treated == 1) / n_distinct(dk_panel$date), "\n")
cat("  Control products:", sum(dk_panel$treated == 0) / n_distinct(dk_panel$date), "\n")

# =============================================================================
# 3. Denmark-Sweden cross-country panel
# =============================================================================

# Map COICOP codes between PRIS6 and Eurostat
coicop_map <- tribble(
  ~dk_code,  ~eurostat_coicop, ~category_name,     ~dk_treated,
  "011500",  "CP0115",         "Oils/Fats",         1L,
  "011200",  "CP0112",         "Meat",              1L,
  "011440",  "CP0114",         "Milk/Cheese/Eggs",  1L,   # Eurostat groups at 4-digit

  "011300",  "CP0113",         "Fish",              0L,
  "011100",  "CP0111",         "Bread/Cereals",     0L,
  "011600",  "CP0116",         "Fruit",             0L,
  "011700",  "CP0117",         "Vegetables",        0L
)

cross_country <- hicp %>%
  inner_join(coicop_map, by = c("coicop" = "eurostat_coicop")) %>%
  filter(date >= as.Date("2008-01-01") & date <= as.Date("2015-12-01")) %>%
  mutate(
    denmark = as.integer(country == "DK"),
    treated_product = dk_treated,
    post_intro = as.integer(date >= as.Date("2011-10-01")),
    post_abolish = as.integer(date >= as.Date("2013-01-01")),
    log_hicp = log(hicp),
    country_product = paste(country, coicop, sep = "_"),
    cal_month = factor(month)
  )

cat("\nCross-country panel:", nrow(cross_country), "obs\n")
cat("  Countries:", n_distinct(cross_country$country), "\n")
cat("  Products:", n_distinct(cross_country$coicop), "\n")

# =============================================================================
# 4. Summary statistics
# =============================================================================
summary_stats <- dk_panel %>%
  group_by(product_name, treated, treatment_intensity) %>%
  summarise(
    n_months = n(),
    mean_cpi = mean(cpi, na.rm = TRUE),
    sd_cpi = sd(cpi, na.rm = TRUE),
    min_cpi = min(cpi, na.rm = TRUE),
    max_cpi = max(cpi, na.rm = TRUE),
    mean_log_cpi = mean(log_cpi, na.rm = TRUE),
    sd_log_cpi = sd(log_cpi, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(treated), product_name)

cat("\nSummary statistics:\n")
print(summary_stats)

# By period
period_stats <- dk_panel %>%
  mutate(period = case_when(
    pre_tax == 1 ~ "Pre-tax (2008-2011M09)",
    tax_period == 1 ~ "Tax period (2011M10-2012M12)",
    post_abolish == 1 ~ "Post-abolition (2013M01-2015)"
  )) %>%
  group_by(product_name, treated, period) %>%
  summarise(
    mean_cpi = mean(cpi, na.rm = TRUE),
    sd_cpi = sd(cpi, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nBy-period statistics:\n")
print(period_stats %>% filter(product_name %in% c("Butter/Oils", "Cheese", "Fish")))

# =============================================================================
# 5. Save cleaned data
# =============================================================================
saveRDS(dk_panel, "../data/dk_panel.rds")
saveRDS(dk_panel_agg, "../data/dk_panel_agg.rds")
saveRDS(cross_country, "../data/cross_country_panel.rds")
saveRDS(summary_stats, "../data/summary_stats.rds")
saveRDS(period_stats, "../data/period_stats.rds")

cat("\nCleaned data saved.\n")
