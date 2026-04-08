# 03_main_analysis.R — Main DiD analysis
# APEP 1415: Morocco Cannabis Legalization

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "rows\n")
cat("Treated cells:", n_distinct(panel$cell_id[panel$treated == 1]), "\n")
cat("Control cells:", n_distinct(panel$cell_id[panel$adjacent == 1]), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")

# =============================================================================
# 1. Main specification: TWFE DiD
# =============================================================================

cat("\n=== Main TWFE DiD Results ===\n")

# Primary outcome: asinh(nightlights)
# Panel: grid cell × year, 2014-2023
# Treatment: eligible province × post-2022

# Model 1: Basic DiD
m1 <- feols(asinh_nl ~ treat_post | cell_id + year_fe,
            data = panel, cluster = ~adm2_name)

# Model 2: With latitude × year controls (smooth spatial trends)
m2 <- feols(asinh_nl ~ treat_post + lat:i(year_fe) | cell_id + year_fe,
            data = panel, cluster = ~adm2_name)

# Model 3: Log(NL + 0.01)
m3 <- feols(ln_nl ~ treat_post | cell_id + year_fe,
            data = panel, cluster = ~adm2_name)

cat("\n--- Model 1: Basic DiD (asinh NL) ---\n")
summary(m1)

cat("\n--- Model 2: Province trends (asinh NL) ---\n")
summary(m2)

cat("\n--- Model 3: Log NL ---\n")
summary(m3)

# =============================================================================
# 2. Callaway-Sant'Anna (2021) — staggered DiD
# =============================================================================

cat("\n=== Callaway-Sant'Anna Results ===\n")

# For C-S, we need: yname, tname, idname, gname, data
# Treatment timing: all treated units start in 2022 (not truly staggered)
# But C-S still handles this correctly

cs_data <- panel %>%
  mutate(
    id = as.integer(as.factor(cell_id)),
    first_treat = ifelse(treated == 1, 2022, 0)
  )

cs_out <- att_gt(
  yname = "asinh_nl",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = cs_data,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

cat("\nGroup-time ATT estimates:\n")
summary(cs_out)

# Aggregate to dynamic event study
cs_es <- aggte(cs_out, type = "dynamic", min_e = -7, max_e = 1)
cat("\nDynamic event study:\n")
summary(cs_es)

# Overall ATT
cs_overall <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:\n")
summary(cs_overall)

# =============================================================================
# 3. Event study (TWFE)
# =============================================================================

cat("\n=== Event Study ===\n")

# Create relative year indicators
panel$rel_year <- panel$year - 2022  # Treatment year
panel$rel_year_factor <- factor(panel$rel_year)

# Drop rel_year = -1 as reference
es_model <- feols(asinh_nl ~ i(rel_year, treated, ref = -1) | cell_id + year_fe,
                  data = panel, cluster = ~adm2_name)

cat("\nEvent study coefficients:\n")
summary(es_model)

# =============================================================================
# 4. Spatial RDD — boundary discontinuity
# =============================================================================

cat("\n=== Spatial RDD (boundary discontinuity) ===\n")

# Restrict to cells within 50km of the eligible boundary
rdd_data <- panel %>%
  filter(abs(dist_signed_km) <= 50)

cat("RDD sample (within 50km):", nrow(rdd_data), "observations\n")
cat("  Treated:", sum(rdd_data$treated == 1), "\n")
cat("  Control:", sum(rdd_data$adjacent == 1), "\n")

# Post-treatment only
rdd_post <- rdd_data %>% filter(post == 1)

# Sharp RDD at the boundary
rdd_result <- rdrobust(
  y = rdd_post$asinh_nl,
  x = rdd_post$dist_signed_km,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)

cat("\nRDD at provincial boundary (post-treatment):\n")
summary(rdd_result)

# Pre-treatment RDD (should show no discontinuity — placebo)
rdd_pre <- rdd_data %>% filter(post == 0 & year >= 2019)

rdd_placebo <- rdrobust(
  y = rdd_pre$asinh_nl,
  x = rdd_pre$dist_signed_km,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)

cat("\nRDD placebo (pre-treatment 2019-2021):\n")
summary(rdd_placebo)

# =============================================================================
# 5. Store results for tables
# =============================================================================

results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  cs_out = cs_out,
  cs_es = cs_es,
  cs_overall = cs_overall,
  es_model = es_model,
  rdd_result = rdd_result,
  rdd_placebo = rdd_placebo
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Compute SD(Y) for SDE calculations
sd_y_pre <- sd(panel$asinh_nl[panel$post == 0], na.rm = TRUE)
sd_y_all <- sd(panel$asinh_nl, na.rm = TRUE)
mean_y_pre <- mean(panel$asinh_nl[panel$post == 0], na.rm = TRUE)

sde_info <- list(
  sd_y_pre = sd_y_pre,
  sd_y_all = sd_y_all,
  mean_y_pre = mean_y_pre,
  beta_m1 = coef(m1)["treat_post"],
  se_m1 = sqrt(vcov(m1)["treat_post", "treat_post"]),
  beta_cs = cs_overall$overall.att,
  se_cs = cs_overall$overall.se
)
saveRDS(sde_info, file.path(data_dir, "sde_info.rds"))

cat("\n=== Summary ===\n")
cat("TWFE DiD (asinh NL):", round(coef(m1), 4), "\n")
cat("C-S Overall ATT:", round(cs_overall$overall.att, 4), "\n")
cat("SD(Y) pre-treatment:", round(sd_y_pre, 4), "\n")
cat("SDE (TWFE):", round(coef(m1) / sd_y_pre, 4), "\n")
