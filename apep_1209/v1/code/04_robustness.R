## 04_robustness.R — Robustness checks and mechanism tests
## apep_1209: Cannabis dispensary lotteries and property values

source("00_packages.R")

cat("=== Loading data ===\n")
sales <- readRDS("../data/sales_clean.rds")
disp <- readRDS("../data/dispensary_clean.rds")
crime <- readRDS("../data/crime_panel.rds")

## ---------------------------------------------------------------
## 4A. Placebo test: pre-lottery dispensaries
## ---------------------------------------------------------------
cat("\n=== Placebo: Pre-lottery dispensaries ===\n")

# Pre-lottery dispensaries (opened before July 2021) were NOT randomly assigned
# Compare: lottery-era effect vs pre-lottery effect
sales_prelot <- sales[nearest_lottery == FALSE]
cat("  Pre-lottery sample:", nrow(sales_prelot), "\n")

if (nrow(sales_prelot) > 100 && sum(sales_prelot$treat_050) > 10) {
  m_placebo <- feols(log_price ~ treat_050 | disp_cluster + yq,
                     data = sales_prelot, cluster = ~disp_cluster)
  cat("  Pre-lottery DiD:", round(coef(m_placebo)["treat_050"], 4),
      "SE:", round(se(m_placebo)["treat_050"], 4), "\n")
} else {
  cat("  Insufficient pre-lottery treated observations for placebo test\n")
  m_placebo <- NULL
}

## ---------------------------------------------------------------
## 4B. Alternative distance thresholds
## ---------------------------------------------------------------
cat("\n=== Alternative distance thresholds ===\n")

# Test robustness to different ring definitions
ring_results <- data.table()
for (r in c(0.10, 0.15, 0.25, 0.35, 0.50, 0.75)) {
  sales[, treat_r := as.integer(dist_nearest <= r & post_open == 1)]
  n_treated <- sum(sales$treat_r)
  if (n_treated < 20) {
    cat("  Ring", r, "mi: too few treated (", n_treated, ")\n")
    next
  }
  mr <- feols(log_price ~ treat_r | disp_cluster + yq, data = sales,
              cluster = ~disp_cluster)
  ring_results <- rbind(ring_results, data.table(
    ring = r, coef = coef(mr)["treat_r"], se = se(mr)["treat_r"],
    n_treated = n_treated
  ))
  cat("  Ring", r, "mi: β =", round(coef(mr)["treat_r"], 4),
      "SE =", round(se(mr)["treat_r"], 4), "n =", n_treated, "\n")
}

## ---------------------------------------------------------------
## 4C. Heterogeneity: by neighborhood income
## ---------------------------------------------------------------
cat("\n=== Heterogeneity: Income ===\n")

# Split by median property price in neighborhood (proxy for income)
nbhd_med <- sales[, .(med_price = median(sale_price, na.rm = TRUE)), by = nbhd]
sales <- merge(sales, nbhd_med, by = "nbhd", all.x = TRUE)
sales[, high_income := as.integer(med_price > median(med_price, na.rm = TRUE))]

# High-income neighborhoods
m_hi <- feols(log_price ~ treat_050 | disp_cluster + yq,
              data = sales[high_income == 1], cluster = ~disp_cluster)
cat("  High-income: β =", round(coef(m_hi)["treat_050"], 4),
    "SE =", round(se(m_hi)["treat_050"], 4), "\n")

# Low-income neighborhoods
m_lo <- feols(log_price ~ treat_050 | disp_cluster + yq,
              data = sales[high_income == 0], cluster = ~disp_cluster)
cat("  Low-income: β =", round(coef(m_lo)["treat_050"], 4),
    "SE =", round(se(m_lo)["treat_050"], 4), "\n")

## ---------------------------------------------------------------
## 4D. Heterogeneity: by property type
## ---------------------------------------------------------------
cat("\n=== Heterogeneity: Property type ===\n")

# Class codes: 2xx = residential, 3xx = multi-family
sales[, residential := as.integer(grepl("^2", class))]

m_res <- feols(log_price ~ treat_050 | disp_cluster + yq,
               data = sales[residential == 1], cluster = ~disp_cluster)
cat("  Residential: β =", round(coef(m_res)["treat_050"], 4),
    "SE =", round(se(m_res)["treat_050"], 4),
    "n =", sum(sales$residential == 1 & sales$treat_050 == 1), "\n")

m_multi <- tryCatch({
  feols(log_price ~ treat_050 | disp_cluster + yq,
        data = sales[residential == 0], cluster = ~disp_cluster)
}, error = function(e) {
  cat("  Multi-family: insufficient data\n")
  NULL
})

if (!is.null(m_multi)) {
  cat("  Multi-family: β =", round(coef(m_multi)["treat_050"], 4),
      "SE =", round(se(m_multi)["treat_050"], 4), "\n")
}

## ---------------------------------------------------------------
## 4E. Crime analysis (secondary outcome)
## ---------------------------------------------------------------
cat("\n=== Crime analysis ===\n")

# For crime, we need dispensary exposure at community_area level
# Compute number of dispensaries that opened in each community area
crime_geo <- readRDS("../data/crime_geo.rds")

# Get community area centroids
ca_centroids <- crime_geo[!is.na(lat) & !is.na(lon),
  .(ca_lat = mean(lat), ca_lon = mean(lon)), by = community_area]

# For each community area, count dispensaries within 0.5 miles
haversine <- function(lat1, lon1, lat2, lon2) {
  R <- 3958.8
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

ca_exposure <- data.table()
for (i in seq_len(nrow(ca_centroids))) {
  ca <- ca_centroids[i]
  # Count dispensaries within 1 mile that have opened by each quarter
  for (yr in 2019:2025) {
    for (q in 1:4) {
      qdate <- as.Date(paste0(yr, "-", (q-1)*3+1, "-01"))
      n_open <- sum(haversine(ca$ca_lat, ca$ca_lon,
                              disp$lat, disp$lon) <= 1.0 &
                    disp$open_date <= qdate, na.rm = TRUE)
      ca_exposure <- rbind(ca_exposure, data.table(
        community_area = ca$community_area,
        year = yr, quarter = q,
        yq = paste0(yr, "Q", q),
        n_dispensaries = n_open
      ))
    }
  }
}

# Merge with crime panel
crime_panel <- merge(crime, ca_exposure,
                     by = c("community_area", "year", "quarter", "yq"), all.x = TRUE)
crime_panel[is.na(n_dispensaries), n_dispensaries := 0]
crime_panel[, has_disp := as.integer(n_dispensaries > 0)]
crime_panel[, log_total := log(total_crime + 1)]
crime_panel[, log_drug := log(drug_crime + 1)]
crime_panel[, log_property := log(property_crime + 1)]

cat("  Crime panel:", nrow(crime_panel), "observations\n")
cat("  Community areas with dispensaries:", sum(crime_panel$has_disp > 0), "\n")

# Crime regressions
if (sum(crime_panel$has_disp) > 10) {
  m_crime_total <- feols(log_total ~ has_disp | community_area + yq,
                         data = crime_panel, cluster = ~community_area)
  cat("  Total crime: β =", round(coef(m_crime_total)["has_disp"], 4),
      "SE =", round(se(m_crime_total)["has_disp"], 4), "\n")

  m_crime_drug <- feols(log_drug ~ has_disp | community_area + yq,
                        data = crime_panel, cluster = ~community_area)
  cat("  Drug crime: β =", round(coef(m_crime_drug)["has_disp"], 4),
      "SE =", round(se(m_crime_drug)["has_disp"], 4), "\n")

  m_crime_prop <- feols(log_property ~ has_disp | community_area + yq,
                        data = crime_panel, cluster = ~community_area)
  cat("  Property crime: β =", round(coef(m_crime_prop)["has_disp"], 4),
      "SE =", round(se(m_crime_prop)["has_disp"], 4), "\n")
} else {
  cat("  Insufficient crime variation\n")
  m_crime_total <- m_crime_drug <- m_crime_prop <- NULL
}

## ---------------------------------------------------------------
## 4F. Save all robustness results
## ---------------------------------------------------------------
robust_results <- list(
  m_placebo = m_placebo,
  ring_results = ring_results,
  m_high_income = m_hi,
  m_low_income = m_lo,
  m_residential = m_res,
  m_multifamily = m_multi,
  m_crime_total = m_crime_total,
  m_crime_drug = m_crime_drug,
  m_crime_property = m_crime_prop
)
saveRDS(robust_results, "../data/robustness_results.rds")
cat("\n=== Robustness complete ===\n")
