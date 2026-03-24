# =============================================================================
# 02_clean_data.R — Construct Analysis Panel
# Paper: apep_0886 — Childcare Stabilization Grants and Maternal Labor Supply
# =============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_panel.rds")

# Drop sex=0 (aggregate) to avoid double counting
qwi <- qwi %>% filter(sex %in% c(1, 2))

cat("Records after dropping sex=0:", nrow(qwi), "\n")
cat("States:", n_distinct(qwi$state_fips), "\n")

# ---- ARP Stabilization Allocations (CLASP data, CCDF formula) ---- #
# Source: CLASP fact sheet, "Child Care Relief Funding in American Rescue Plan"
# These are predetermined by the CCDF formula — exogenous to labor markets
alloc <- tribble(
  ~state_fips, ~state_abbr, ~alloc_millions,
  "01", "AL", 451.4,
  "02", "AK", 45.3,
  "04", "AZ", 596.4,
  "05", "AR", 286.1,
  "06", "CA", 2313.2,
  "08", "CO", 286.2,
  "09", "CT", 169.9,
  "10", "DE", 66.8,
  "11", "DC", 39.8,
  "12", "FL", 1523.1,
  "13", "GA", 968.3,
  "15", "HI", 79.9,
  "16", "ID", 138.6,
  "17", "IL", 796.3,
  "18", "IN", 540.2,
  "19", "IA", 227.6,
  "20", "KS", 213.9,
  "21", "KY", 470.1,
  "22", "LA", 475.7,
  "23", "ME", 73.2,
  "24", "MD", 309.1,
  "25", "MA", 314.4,
  "26", "MI", 700.7,
  "27", "MN", 324.2,
  "28", "MS", 319.5,
  "29", "MO", 444.1,
  "30", "MT", 68.1,
  "31", "NE", 143.1,
  "32", "NV", 222.4,
  "33", "NH", 47.7,
  "34", "NJ", 427.5,
  "35", "NM", 197.1,
  "36", "NY", 1124.5,
  "37", "NC", 805.8,
  "38", "ND", 46.7,
  "39", "OH", 799.8,
  "40", "OK", 362.9,
  "41", "OR", 248.9,
  "42", "PA", 728.9,
  "44", "RI", 57.3,
  "45", "SC", 436.6,
  "46", "SD", 61.9,
  "47", "TN", 554.4,
  "48", "TX", 2724.4,
  "49", "UT", 261.4,
  "50", "VT", 29.3,
  "51", "VA", 488.6,
  "53", "WA", 389.6,
  "54", "WV", 160.4,
  "55", "WI", 357.0,
  "56", "WY", 29.3
)

# State populations (2021 Census estimates) for per-capita normalization
# Source: Census Bureau Annual Population Estimates
pop <- tribble(
  ~state_fips, ~pop_2021,
  "01", 5039877, "02", 732673, "04", 7276316, "05", 3025891,
  "06", 39237836, "08", 5812069, "09", 3605597, "10", 1003384,
  "11", 670050, "12", 21781128, "13", 10799566, "15", 1441553,
  "16", 1900923, "17", 12671469, "18", 6805985, "19", 3193079,
  "20", 2934582, "21", 4509394, "22", 4624047, "23", 1372247,
  "24", 6165129, "25", 6984723, "26", 10050811, "27", 5707390,
  "28", 2949965, "29", 6168187, "30", 1104271, "31", 1963692,
  "32", 3143991, "33", 1388992, "34", 9267130, "35", 2115877,
  "36", 19835913, "37", 10551162, "38", 774948, "39", 11780017,
  "40", 3986639, "41", 4237256, "42", 13002700, "44", 1095610,
  "45", 5190705, "46", 895376, "47", 6975218, "48", 29527941,
  "49", 3337975, "50", 645570, "51", 8642274, "53", 7738692,
  "54", 1782959, "55", 5895908, "56", 578803
)

# Merge allocations with population, compute per-capita
alloc <- alloc %>%
  left_join(pop, by = "state_fips") %>%
  mutate(
    alloc_total = alloc_millions * 1e6,
    alloc_pc = alloc_total / pop_2021  # $ per person
  )

cat("Allocation per capita range: $",
    round(min(alloc$alloc_pc), 2), "to $",
    round(max(alloc$alloc_pc), 2), "\n")
cat("Median allocation per capita: $", round(median(alloc$alloc_pc), 2), "\n")

# ---- Create analysis variables ---- #
panel <- qwi %>%
  left_join(alloc %>% select(state_fips, state_abbr, alloc_pc, alloc_total),
            by = "state_fips") %>%
  mutate(
    # Time variable (quarterly)
    time_q = year + (quarter - 1) / 4,
    yq = paste0(year, "Q", quarter),

    # Treatment indicators
    female = as.integer(sex == 2),
    childcare = as.integer(industry_code == "624"),
    childcare_broad = as.integer(industry_code %in% c("624", "623", "611")),
    manufacturing = as.integer(industry_code %in% c("311", "332")),

    # Post-ARP indicator: ARP signed March 2021, first disbursements Q4 2021
    # Main: post = 1 for 2021Q4+ (conservative — after first disbursements)
    post = as.integer(year > 2021 | (year == 2021 & quarter >= 4)),

    # Grant expiration: September 30, 2023
    post_expiry = as.integer(year > 2023 | (year == 2023 & quarter == 4)),

    # DDD interaction terms
    post_female = post * female,
    post_childcare = post * childcare,
    female_childcare = female * childcare,
    ddd = post * female * childcare,

    # Dose-response: allocation per capita × female × post
    dose_ddd = alloc_pc * female * post,

    # Log outcomes (handle zeros)
    log_emp = ifelse(emp > 0, log(emp), NA_real_),
    log_hires = ifelse(hires > 0, log(hires), NA_real_),

    # Panel identifiers
    cell_id = paste(state_fips, industry_code, sex, sep = "_"),

    # Event time (quarters since 2021Q4)
    event_time = (year - 2021) * 4 + (quarter - 4),

    # Standardized allocation (for interpretation)
    alloc_pc_std = (alloc_pc - mean(alloc_pc, na.rm = TRUE)) / sd(alloc_pc, na.rm = TRUE),

    # High allocation indicator (above median)
    high_alloc = as.integer(alloc_pc > median(alloc_pc, na.rm = TRUE))
  )

# Drop observations with missing data
panel <- panel %>% filter(!is.na(log_emp), !is.na(alloc_pc))

cat("\n=== Analysis Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", n_distinct(panel$state_fips), "\n")
cat("Industries:", n_distinct(panel$industry_code), "\n")
cat("Quarters:", n_distinct(panel$yq), "\n")
cat("Cells (state×industry×sex):", n_distinct(panel$cell_id), "\n")
cat("\nBy sex:\n")
panel %>% count(sex) %>% print()
cat("\nBy industry:\n")
panel %>% count(industry_code) %>% print()
cat("\nPre/Post split:\n")
panel %>% count(post) %>% print()

# Save analysis panel
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved: data/analysis_panel.rds\n")
