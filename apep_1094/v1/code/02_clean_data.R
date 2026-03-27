# =============================================================================
# 02_clean_data.R — Panel construction
# apep_1094: Film Tax Credits and Racial Employment Gains
# =============================================================================

source("00_packages.R")

qwi_raw <- readRDS("../data/qwi_raw.rds")
film_credits <- readRDS("../data/film_credits.rds")

# Reverse FIPS mapping
fips_to_abbr <- c(
  "01"="AL","02"="AK","04"="AZ","05"="AR","06"="CA","08"="CO","09"="CT",
  "10"="DE","11"="DC","12"="FL","13"="GA","15"="HI","16"="ID","17"="IL",
  "18"="IN","19"="IA","20"="KS","21"="KY","22"="LA","23"="ME","24"="MD",
  "25"="MA","26"="MI","27"="MN","28"="MS","29"="MO","30"="MT","31"="NE",
  "32"="NV","33"="NH","34"="NJ","35"="NM","36"="NY","37"="NC","38"="ND",
  "39"="OH","40"="OK","41"="OR","42"="PA","44"="RI","45"="SC","46"="SD",
  "47"="TN","48"="TX","49"="UT","50"="VT","51"="VA","53"="WA","54"="WV",
  "55"="WI","56"="WY"
)

never_treated <- c("AK","CA","DE","ID","IA","KS","ND","NE","NH","SD","VT","WY","DC")

# Clean QWI data
# Create numeric state ID for did package
state_id_map <- data.frame(
  state_abbr = sort(unique(fips_to_abbr[qwi_raw$state])),
  state_id = seq_along(sort(unique(fips_to_abbr[qwi_raw$state])))
)
saveRDS(state_id_map, "../data/state_id_map.rds")

qwi <- qwi_raw %>%
  mutate(
    state_abbr = fips_to_abbr[state],
    year = as.integer(year),
    quarter = as.integer(quarter),
    Emp = as.numeric(Emp),
    HirA = as.numeric(HirA),
    Sep = as.numeric(Sep),
    EarnHirAS = as.numeric(EarnHirAS),
    time_q = year + (quarter - 1) / 4  # Continuous quarter index
  ) %>%
  filter(!is.na(state_abbr)) %>%
  left_join(state_id_map, by = "state_abbr")

cat(sprintf("QWI cleaned: %d rows, %d states\n", nrow(qwi), n_distinct(qwi$state_abbr)))

# Merge treatment dates
qwi <- qwi %>%
  left_join(
    film_credits %>% select(state_abbr, adopt_year, adopt_qtr, repeal_year),
    by = "state_abbr"
  ) %>%
  mutate(
    # Treatment group timing (year-quarter as numeric for CS-DiD)
    treat_yq = ifelse(!is.na(adopt_year),
                      adopt_year + (adopt_qtr - 1) / 4,
                      0),  # 0 = never treated
    # For CS-DiD: first_treat as integer period
    # Convert year-quarter to sequential integer: 2001Q1=1, 2001Q2=2, etc.
    period = (year - 2001) * 4 + quarter,
    first_treat = ifelse(treat_yq > 0,
                         (adopt_year - 2001) * 4 + adopt_qtr,
                         0),
    # Post-treatment indicator
    post = ifelse(treat_yq > 0, time_q >= treat_yq, FALSE),
    treated = treat_yq > 0,
    # For NC repeal analysis
    repealed = !is.na(repeal_year) & year >= repeal_year
  )

# Create separate panels for each analysis
# Panel A: NAICS 512 (Motion Picture) — main analysis
panel_512 <- qwi %>%
  filter(industry == "512") %>%
  # Handle suppressed cells (NA values)
  mutate(across(c(Emp, HirA, Sep, EarnHirAS), ~replace_na(., 0)))

# Panel B: NAICS 722 (Food Services) — placebo
panel_722 <- qwi %>%
  filter(industry == "722") %>%
  mutate(across(c(Emp, HirA, Sep, EarnHirAS), ~replace_na(., 0)))

# Log outcomes (add 1 for zeros)
panel_512 <- panel_512 %>%
  mutate(
    log_emp = log(Emp + 1),
    log_hir = log(HirA + 1),
    log_sep = log(Sep + 1),
    log_earn = log(EarnHirAS + 1)
  )

panel_722 <- panel_722 %>%
  mutate(
    log_emp = log(Emp + 1),
    log_hir = log(HirA + 1),
    log_sep = log(Sep + 1),
    log_earn = log(EarnHirAS + 1)
  )

# Summary statistics
cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("NAICS 512 panel: %d state-quarter-race obs\n", nrow(panel_512)))
cat(sprintf("  States: %d\n", n_distinct(panel_512$state_abbr)))
cat(sprintf("  Periods: %d-%d (%d quarters)\n",
            min(panel_512$year), max(panel_512$year),
            n_distinct(panel_512$period)))
cat(sprintf("  Treated: %d states\n",
            n_distinct(panel_512$state_abbr[panel_512$treated])))
cat(sprintf("  Never-treated: %d states\n",
            n_distinct(panel_512$state_abbr[!panel_512$treated])))
cat(sprintf("  Races: %s\n", paste(unique(panel_512$race), collapse=", ")))
cat(sprintf("  Mean employment (all races): %.0f\n",
            mean(panel_512$Emp[panel_512$race == "A0"], na.rm = TRUE)))

cat(sprintf("\nNAICS 722 panel: %d state-quarter-race obs\n", nrow(panel_722)))

# Create race-specific panels for main analysis
panel_white <- panel_512 %>% filter(race == "A1")
panel_black <- panel_512 %>% filter(race == "A2")
panel_hisp  <- panel_512 %>% filter(race == "A5")
panel_all   <- panel_512 %>% filter(race == "A0")

# Compute Black employment share (pre-treatment)
black_share_pre <- panel_512 %>%
  filter(race %in% c("A1", "A2"), !post, year >= 2003) %>%
  group_by(state_abbr, race) %>%
  summarize(mean_emp = mean(Emp, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = race, values_from = mean_emp) %>%
  mutate(
    black_share = A2 / (A1 + A2),
    high_black = black_share >= median(black_share, na.rm = TRUE)
  ) %>%
  select(state_abbr, black_share, high_black)

panel_all <- panel_all %>%
  left_join(black_share_pre, by = "state_abbr")

# Save
saveRDS(panel_512, "../data/panel_512.rds")
saveRDS(panel_722, "../data/panel_722.rds")
saveRDS(panel_all, "../data/panel_all.rds")
saveRDS(panel_white, "../data/panel_white.rds")
saveRDS(panel_black, "../data/panel_black.rds")
saveRDS(panel_hisp, "../data/panel_hisp.rds")
saveRDS(black_share_pre, "../data/black_share_pre.rds")

cat("\nAll panels saved.\n")
