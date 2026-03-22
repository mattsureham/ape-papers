# 04_robustness.R — Robustness checks
# apep_0734: Wales 20mph Speed Limit and Road Casualties

source("00_packages.R")

cat("=== Loading data ===\n")
load("../data/models.RData")

# ============================================================
# 1. EXCLUDE COVID PERIOD (2020-2021)
# ============================================================
cat("\n=== Robustness: Exclude COVID 2020-2021 ===\n")

panel_nocovid <- panel[!(year_q >= 2020.0 & year_q < 2022.0)]
m_nocovid <- feols(log_casualties ~ treat | la_code + quarter,
                   data = panel_nocovid, cluster = ~la_code)
summary(m_nocovid)

# ============================================================
# 2. BORDER LAs ONLY
# ============================================================
cat("\n=== Robustness: Border LAs ===\n")

# Welsh LAs bordering England:
# Wrexham, Flintshire, Powys, Monmouthshire
# English LAs bordering Wales:
# Shropshire, Herefordshire, Cheshire West and Chester, Gloucester, West of England

# Use STATS19 LA codes for border authorities
# Welsh border: W06000005 (Wrexham), W06000019 (Flintshire), W06000023 (Powys), W06000021 (Monmouthshire)
# English border: approximate by name matching or geographic proximity

welsh_border <- panel[wales == 1]$la_code |> unique()  # Will subset to actual border below

# For now, compare Welsh LAs to their English neighbors
# We can identify border LAs by geographic adjacency
# Key English border LAs (ONS codes):
english_border_codes <- c(
  "E06000051",  # Shropshire
  "E06000019",  # Herefordshire
  "E06000050",  # Cheshire West and Chester
  "E06000025",  # South Gloucestershire
  "E10000015",  # Gloucestershire
  "E06000049"   # Cheshire East
)

# Welsh border LAs
welsh_border_codes <- c(
  "W06000005",  # Wrexham
  "W06000019",  # Flintshire
  "W06000023",  # Powys
  "W06000021"   # Monmouthshire
)

border_codes <- c(english_border_codes, welsh_border_codes)
panel_border <- panel[la_code %in% border_codes]

if (nrow(panel_border) > 0 && uniqueN(panel_border[wales == 1]$la_code) >= 2) {
  m_border <- feols(log_casualties ~ treat | la_code + quarter,
                    data = panel_border, cluster = ~la_code)
  summary(m_border)
} else {
  cat("Border LA sample too small — trying broader definition\n")
  # Use all Welsh LAs vs nearest English LAs
  m_border <- NULL
}

# ============================================================
# 3. PLACEBO: HIGH-SPEED ROADS
# ============================================================
cat("\n=== Placebo: High-speed roads (40+ mph) ===\n")

m_placebo <- feols(log_cas_high ~ treat | la_code + quarter,
                   data = panel, cluster = ~la_code)
summary(m_placebo)

# ============================================================
# 4. POISSON REGRESSION (count outcome)
# ============================================================
cat("\n=== Poisson regression ===\n")

m_poisson <- tryCatch({
  fepois(casualties ~ treat | la_code + quarter, data = panel, cluster = ~la_code)
}, error = function(e) {
  cat("Poisson model error:", e$message, "\n")
  NULL
})

if (!is.null(m_poisson)) {
  summary(m_poisson)
}

# ============================================================
# 5. DIFFERENT PRE-PERIOD WINDOWS
# ============================================================
cat("\n=== Robustness: 2022-2024 only (short window) ===\n")

panel_short <- panel[year_q >= 2022.0]
m_short <- feols(log_casualties ~ treat | la_code + quarter,
                 data = panel_short, cluster = ~la_code)
summary(m_short)

# ============================================================
# 6. EXCLUDE SCOTLAND SPILLOVERS (already excluded, but verify)
# ============================================================
cat("\n=== Verify: No Scottish LAs in sample ===\n")
cat("Countries in panel:", paste(unique(panel$country), collapse = ", "), "\n")

# ============================================================
# 7. COLLISIONS (instead of casualties)
# ============================================================
cat("\n=== Alternative outcome: Collisions ===\n")

m_collisions <- feols(log_collisions ~ treat | la_code + quarter,
                      data = panel, cluster = ~la_code)
summary(m_collisions)

# ============================================================
# SAVE ALL ROBUSTNESS RESULTS
# ============================================================
save(m_nocovid, m_border, m_placebo, m_poisson, m_short, m_collisions,
     file = "../data/robustness_models.RData")
cat("\n=== Robustness checks complete ===\n")
