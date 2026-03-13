## 03_main_analysis.R — Difference-in-discontinuities at CAZ boundaries
## apep_0649: Clean Air Zone property values

source("00_packages.R")
setDTthreads(4)

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE)

df <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
df[, date := as.Date(date)]
df[, launch := as.Date(launch)]

cat(sprintf("Analysis panel: %d transactions, %d cities\n", nrow(df), length(unique(df$city))))

# ═══════════════════════════════════════════════════════════════
# 1) SUMMARY STATISTICS (for Table 1)
# ═══════════════════════════════════════════════════════════════

bw <- 500  # Primary bandwidth

df500 <- df[abs(signed_dist_m) <= bw]
cat(sprintf("\nWithin %dm bandwidth: %d transactions\n", bw, nrow(df500)))

summ_by_side <- df500[, .(
  N = .N,
  mean_price = mean(price, na.rm = TRUE),
  median_price = median(price, na.rm = TRUE),
  sd_price = sd(price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  sd_log_price = sd(log_price, na.rm = TRUE),
  pct_flat = mean(prop_type == "F", na.rm = TRUE),
  pct_terraced = mean(prop_type == "T", na.rm = TRUE),
  pct_semi = mean(prop_type == "S", na.rm = TRUE),
  pct_detached = mean(prop_type == "D", na.rm = TRUE)
), by = .(inside)]

cat("\nSummary by side of boundary (500m):\n")
print(summ_by_side)

summ_by_city <- df500[, .(
  N = .N,
  mean_price = mean(price),
  pct_post = mean(post)
), by = .(city, class)]

cat("\nBy city:\n")
print(summ_by_city[order(-N)])

# ═══════════════════════════════════════════════════════════════
# 2) MAIN SPECIFICATION: DIFFERENCE-IN-DISCONTINUITIES
# ═══════════════════════════════════════════════════════════════
# Equation: log(price) = f(distance) + α*Post + β*(Inside × Post) + City FE + ε
# β captures the causal effect of CAZ on property values at the boundary.
# The diff-in-disc absorbs permanent boundary effects.

cat("\n=== MAIN RESULTS ===\n")

# 2a) Pooled diff-in-disc with local linear, 500m bandwidth
m1 <- feols(log_price ~ inside_post + inside + post |
              city + year_quarter,
            data = df500,
            cluster = ~postcode)
cat("\nModel 1: Pooled DiDisc (500m), City + YQ FE:\n")
summary(m1)

# 2b) With property type controls
m2 <- feols(log_price ~ inside_post + inside + post + i(prop_type) |
              city + year_quarter,
            data = df500,
            cluster = ~postcode)
cat("\nModel 2: + Property type controls:\n")
summary(m2)

# 2c) With local linear polynomial in distance
m3 <- feols(log_price ~ inside_post + inside + post +
              signed_dist_m + I(signed_dist_m * inside) +
              I(signed_dist_m * post) + I(signed_dist_m * inside_post) +
              i(prop_type) |
              city + year_quarter,
            data = df500,
            cluster = ~postcode)
cat("\nModel 3: + Local linear in distance:\n")
summary(m3)

# 2d) Narrow bandwidth (250m)
df250 <- df[abs(signed_dist_m) <= 250]
m4 <- feols(log_price ~ inside_post + inside + post +
              signed_dist_m + I(signed_dist_m * inside) +
              I(signed_dist_m * post) + I(signed_dist_m * inside_post) +
              i(prop_type) |
              city + year_quarter,
            data = df250,
            cluster = ~postcode)
cat("\nModel 4: 250m bandwidth:\n")
summary(m4)

# 2e) Wide bandwidth (1000m)
df1000 <- df[abs(signed_dist_m) <= 1000]
m5 <- feols(log_price ~ inside_post + inside + post +
              signed_dist_m + I(signed_dist_m * inside) +
              I(signed_dist_m * post) + I(signed_dist_m * inside_post) +
              i(prop_type) |
              city + year_quarter,
            data = df1000,
            cluster = ~postcode)
cat("\nModel 5: 1000m bandwidth:\n")
summary(m5)

# ═══════════════════════════════════════════════════════════════
# 3) HETEROGENEITY BY CHARGE CLASS
# ═══════════════════════════════════════════════════════════════

cat("\n=== CHARGE CLASS HETEROGENEITY ===\n")

# Class B (Portsmouth only): commercial vehicles only
df_B <- df500[class == "B"]
if (nrow(df_B) > 50) {
  m_B <- feols(log_price ~ inside_post + inside + post + i(prop_type) |
                 year_quarter,
               data = df_B,
               cluster = ~postcode)
  cat("\nClass B (commercial only):\n")
  summary(m_B)
} else {
  m_B <- NULL
  cat("Class B: insufficient observations\n")
}

# Class C (Bath, Bradford, Tyneside): commercial + taxis + LGVs
df_C <- df500[class == "C"]
m_C <- feols(log_price ~ inside_post + inside + post + i(prop_type) |
               city + year_quarter,
             data = df_C,
             cluster = ~postcode)
cat("\nClass C (commercial + taxis + LGVs):\n")
summary(m_C)

# Class D (Birmingham, Bristol, Sheffield): all vehicles incl. private cars
df_D <- df500[class == "D"]
m_D <- feols(log_price ~ inside_post + inside + post + i(prop_type) |
               city + year_quarter,
             data = df_D,
             cluster = ~postcode)
cat("\nClass D (all vehicles incl. cars):\n")
summary(m_D)

# ═══════════════════════════════════════════════════════════════
# 4) CITY-BY-CITY ESTIMATES
# ═══════════════════════════════════════════════════════════════

cat("\n=== CITY-BY-CITY RESULTS ===\n")

city_results <- list()
for (city_name in unique(df500$city)) {
  dfc <- df500[city == city_name]
  if (nrow(dfc) > 100) {
    mc <- feols(log_price ~ inside_post + inside + post + i(prop_type) | year_quarter,
                data = dfc, cluster = ~postcode)
    city_results[[city_name]] <- mc
    cat(sprintf("\n%s (N=%d): β = %.4f (SE = %.4f)\n",
                city_name, nrow(dfc), coef(mc)["inside_post"], se(mc)["inside_post"]))
  } else {
    cat(sprintf("\n%s: too few observations (%d)\n", city_name, nrow(dfc)))
  }
}

# ═══════════════════════════════════════════════════════════════
# 5) SAVE RESULTS & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════

# Save main objects
save(m1, m2, m3, m4, m5, m_B, m_C, m_D, city_results,
     summ_by_side, summ_by_city,
     file = file.path(DATA_DIR, "main_results.RData"))

# Write diagnostics.json for validator
n_pre <- nrow(df500[post == 0])
n_post <- nrow(df500[post == 1])
n_inside <- nrow(df500[inside == 1])
n_outside <- nrow(df500[inside == 0])
n_cities <- length(unique(df500$city))

diagnostics <- list(
  n_treated = n_inside,
  n_pre = n_pre,
  n_obs = nrow(df500),
  n_post = n_post,
  n_outside = n_outside,
  n_cities = n_cities,
  bandwidth_m = bw,
  main_coef = coef(m3)["inside_post"],
  main_se = se(m3)["inside_post"]
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved. N_obs=%d, N_treated=%d, N_pre=%d\n",
            nrow(df500), n_inside, n_pre))

cat("\n=== Main analysis complete ===\n")
