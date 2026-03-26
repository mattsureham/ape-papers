# 04_robustness.R — Robustness checks
# APEP Working Paper apep_0992

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
load("data/main_results.RData")

cat("Running robustness checks...\n")

# ==========================================================================
# 1. ALTERNATIVE CLUSTERING
# ==========================================================================
# Province-level clustering (more conservative)
r1_province <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                     data = panel, cluster = ~province_id)
cat("\n1. Province-clustered SEs:\n")
print(summary(r1_province))

# Two-way clustering: department + campaign_year
r1_twoway <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                   data = panel, cluster = ~dept_id + campaign_year)
cat("\nTwo-way clustered (dept + year):\n")
print(summary(r1_twoway))

# ==========================================================================
# 2. ALTERNATIVE SAMPLE WINDOWS
# ==========================================================================
# Narrow window: 2012-2017 (3 pre, 3 post)
panel_narrow <- panel[campaign_year >= 2012 & campaign_year <= 2017]
r2_narrow <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                   data = panel_narrow, cluster = ~dept_id)
cat("\n2a. Narrow window (2012-2017):\n")
print(summary(r2_narrow))

# Wide window: 2008-2019 (7 pre, 5 post) — need to reload raw
raw <- readRDS("data/magyp_raw.rds")
raw[, campaign_year := as.integer(sub("/.*", "", campania))]
raw[, crop := fcase(
  cultivo == "soja total", "Soybean",
  cultivo == "trigo total", "Wheat",
  cultivo == "girasol", "Sunflower",
  grepl("^ma.*z$", cultivo), "Corn",
  default = NA_character_
)]
wide_panel <- raw[!is.na(crop) & campaign_year >= 2008 & campaign_year <= 2019 &
                  superficie_sembrada_ha > 0,
  .(dept_id = departamento_id, province_id = provincia_id, crop, campaign_year,
    planted_area = superficie_sembrada_ha)]
wide_panel[, log_planted := log(planted_area)]
wide_panel[, treated_crop := as.integer(crop != "Soybean")]
wide_panel[, post := as.integer(campaign_year >= 2015)]
wide_panel[, treat_post := treated_crop * post]
wide_panel[, dept_crop := paste(dept_id, crop, sep = "_")]
wide_panel[, dept_year := paste(dept_id, campaign_year, sep = "_")]
wide_panel[, crop_year := paste(crop, campaign_year, sep = "_")]

r2_wide <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                 data = wide_panel, cluster = ~dept_id)
cat("\n2b. Wide window (2008-2019):\n")
print(summary(r2_wide))

# ==========================================================================
# 3. PLACEBO TEST: Pre-treatment fake reform in 2012
# ==========================================================================
panel_pre <- panel[campaign_year < 2015]
panel_pre[, fake_post := as.integer(campaign_year >= 2012)]
panel_pre[, fake_treat_post := treated_crop * fake_post]
panel_pre[, fake_dept_year := paste(dept_id, campaign_year, sep = "_")]

r3_placebo <- feols(log_planted ~ fake_treat_post | dept_crop + fake_dept_year,
                    data = panel_pre, cluster = ~dept_id)
cat("\n3. Placebo test (fake reform at 2012):\n")
print(summary(r3_placebo))

# ==========================================================================
# 4. LEVELS INSTEAD OF LOGS
# ==========================================================================
r4_levels <- feols(planted_area ~ treat_post | dept_crop + dept_year,
                   data = panel, cluster = ~dept_id)
cat("\n4. Levels specification (hectares):\n")
print(summary(r4_levels))

# ==========================================================================
# 5. PRODUCTION ROBUSTNESS
# ==========================================================================
r5_prod <- feols(log_production ~ treat_post | dept_crop + dept_year,
                 data = panel, cluster = ~dept_id)
cat("\n5. Production (logs):\n")
print(summary(r5_prod))

# ==========================================================================
# 6. EXCLUDING PAMPA HÚMEDA (core soybean region)
# ==========================================================================
# Pampa provinces: Buenos Aires, Córdoba, Santa Fe, Entre Ríos, La Pampa
pampa_prov_ids <- panel[province %in% c("Buenos Aires", "C\u00f3rdoba", "Santa Fe",
                                         "Entre R\u00edos", "La Pampa"), unique(province_id)]
# Check actual province names in data
cat("\nAll provinces:\n")
print(sort(unique(panel$province)))

# Try matching on actual encoded names
pampa_keywords <- c("Buenos", "rdoba", "Santa Fe", "Entre", "Pampa")
pampa_ids <- panel[grepl(paste(pampa_keywords, collapse = "|"), province), unique(province_id)]
cat("Pampa province IDs:", paste(pampa_ids, collapse = ", "), "\n")

r6_nopampa <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                    data = panel[!(province_id %in% pampa_ids)], cluster = ~dept_id)
cat("\n6. Excluding Pampa Húmeda:\n")
print(summary(r6_nopampa))

# Only Pampa
r6_pampa <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                  data = panel[province_id %in% pampa_ids], cluster = ~dept_id)
cat("\n6b. Pampa Húmeda only:\n")
print(summary(r6_pampa))

# ==========================================================================
# SAVE
# ==========================================================================
# ==========================================================================
# 7. EXCLUDING SUNFLOWER (corn + wheat only vs soybeans)
# ==========================================================================
r7_nosunflower <- feols(log_planted ~ treat_post | dept_crop + dept_year,
                        data = panel[crop != "Sunflower"], cluster = ~dept_id)
cat("\n7. Excluding sunflower:\n")
print(summary(r7_nosunflower))

save(r1_province, r1_twoway, r2_narrow, r2_wide, r3_placebo, r4_levels,
     r5_prod, r6_nopampa, r6_pampa, r7_nosunflower,
     file = "data/robustness_results.RData")
cat("\nRobustness checks complete.\n")
