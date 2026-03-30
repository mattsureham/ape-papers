## 02_clean_data.R — Clean and prepare analysis samples
## APEP-1133: The Tenure Shield

source("00_packages.R")

data_dir <- "../data"

## ---- Load raw data ----
accidents <- readRDS(file.path(data_dir, "accidents.rds"))
mines     <- readRDS(file.path(data_dir, "mines.rds"))
prod      <- readRDS(file.path(data_dir, "prod_quarterly.rds"))

cat("Raw accidents:", nrow(accidents), "\n")

## ---- Clean accidents ----
acc <- accidents %>%
  as_tibble() %>%
  mutate(
    mine_id    = as.character(MINE_ID),
    tot_exper  = as.numeric(TOT_EXPER),
    mine_exper = as.numeric(MINE_EXPER),
    job_exper  = as.numeric(JOB_EXPER),
    days_lost  = as.numeric(DAYS_LOST),
    days_restrict = as.numeric(DAYS_RESTRICT),
    degree_injury = as.character(DEGREE_INJURY),
    occ_cd     = as.character(OCCUPATION_CD),
    subunit    = as.character(SUBUNIT_CD),
    cal_yr     = as.numeric(CAL_YR),
    cal_qtr    = as.numeric(CAL_QTR)
  ) %>%
  ## Filter to records with all three experience fields
  filter(
    !is.na(tot_exper),
    !is.na(mine_exper),
    !is.na(job_exper),
    ## Sanity: experience should be non-negative
    tot_exper >= 0,
    mine_exper >= 0,
    job_exper >= 0,
    ## Mine-specific tenure cannot exceed total experience
    mine_exper <= tot_exper + 1,  # allow 1yr rounding
    ## Calendar year in range
    cal_yr >= 2000, cal_yr <= 2025
  )

cat("After experience filter:", nrow(acc), "\n")

## ---- Construct severity measures ----
acc <- acc %>%
  mutate(
    ## Primary: days away from work
    days_away = pmax(days_lost, 0, na.rm = TRUE),
    ## Binary: any days lost
    any_days_lost = as.integer(days_away > 0),
    ## Log days lost (for intensive margin)
    log_days_lost = log(days_away + 1),
    ## Severity categories from DEGREE_INJURY (text descriptions)
    severe = as.integer(grepl("FATALITY|PERM TOT", degree_injury, ignore.case = TRUE)),
    high_severity = as.integer(grepl("FATALITY|PERM TOT|DAYS AWAY|DYS AWY", degree_injury, ignore.case = TRUE)),
    ## Year-quarter identifier
    yq = cal_yr + (cal_qtr - 1) / 4,
    ## Experience bins for descriptive analysis
    mine_exper_bin = cut(mine_exper, breaks = c(-1, 1, 3, 5, 10, 20, Inf),
                         labels = c("<1yr", "1-3yr", "3-5yr", "5-10yr", "10-20yr", "20+yr")),
    tot_exper_bin = cut(tot_exper, breaks = c(-1, 1, 3, 5, 10, 20, Inf),
                        labels = c("<1yr", "1-3yr", "3-5yr", "5-10yr", "10-20yr", "20+yr")),
    ## New arrival indicator (mine tenure < 1 year)
    new_arrival = as.integer(mine_exper < 1)
  )

## ---- Merge mine characteristics ----
mine_chars <- mines %>%
  as_tibble() %>%
  transmute(
    mine_id       = as.character(MINE_ID),
    mine_type     = CURRENT_MINE_TYPE,
    mine_status   = CURRENT_MINE_STATUS,
    state         = STATE,
    fips_cnty     = FIPS_CNTY_CD,
    coal_metal    = COAL_METAL_IND,
    primary_sic   = PRIMARY_SIC,
    primary_canvass = PRIMARY_CANVASS
  )

acc <- acc %>%
  left_join(mine_chars, by = "mine_id")

cat("After mine merge:", nrow(acc), "\n")
cat("Mine type distribution:\n")
print(table(acc$mine_type, useNA = "ifany"))
cat("\nCoal vs Metal/NonMetal:\n")
print(table(acc$coal_metal, useNA = "ifany"))

## ---- Construct mine-quarter panel ----
## Aggregate accidents to mine-quarter
mine_qtr <- acc %>%
  group_by(mine_id, cal_yr, cal_qtr) %>%
  summarise(
    n_injuries      = n(),
    n_days_lost     = sum(days_away, na.rm = TRUE),
    n_severe        = sum(severe, na.rm = TRUE),
    mean_mine_exper = mean(mine_exper, na.rm = TRUE),
    mean_tot_exper  = mean(tot_exper, na.rm = TRUE),
    frac_new_arrival = mean(new_arrival, na.rm = TRUE),
    .groups = "drop"
  )

## Merge quarterly employment data
emp <- prod %>%
  as_tibble() %>%
  transmute(
    mine_id   = as.character(MINE_ID),
    cal_yr    = as.numeric(CAL_YR),
    cal_qtr   = as.numeric(CAL_QTR),
    avg_emp   = as.numeric(AVG_EMPLOYEE_CNT),
    hours     = as.numeric(HOURS_WORKED)
  ) %>%
  filter(cal_yr >= 2000, cal_yr <= 2025)

mine_panel <- emp %>%
  left_join(mine_qtr, by = c("mine_id", "cal_yr", "cal_qtr")) %>%
  mutate(
    n_injuries = replace_na(n_injuries, 0),
    n_days_lost = replace_na(n_days_lost, 0),
    n_severe = replace_na(n_severe, 0),
    ## Injury rate per 100 FTE (2000 hours/year = 500 hours/quarter)
    injury_rate = ifelse(hours > 0, n_injuries / hours * 200000, NA),
    yq = cal_yr + (cal_qtr - 1) / 4
  ) %>%
  filter(avg_emp > 0, hours > 0)  # active mines only

cat("\nMine-quarter panel:", nrow(mine_panel), "obs,",
    n_distinct(mine_panel$mine_id), "mines\n")

## ---- Save analysis datasets ----
saveRDS(acc, file.path(data_dir, "accidents_clean.rds"))
saveRDS(mine_panel, file.path(data_dir, "mine_panel.rds"))

cat("\n=== Cleaning complete ===\n")
cat("Individual accidents (w/ experience):", nrow(acc), "\n")
cat("Mine-quarter panel:", nrow(mine_panel), "\n")

## Summary stats for the paper
cat("\n=== Key summary statistics ===\n")
cat("Mean total experience:", round(mean(acc$tot_exper), 1), "years\n")
cat("Mean mine experience:", round(mean(acc$mine_exper), 1), "years\n")
cat("Mean job experience:", round(mean(acc$job_exper), 1), "years\n")
cat("Fraction new arrivals (<1yr mine):", round(mean(acc$new_arrival), 3), "\n")
cat("Mean days lost:", round(mean(acc$days_away), 1), "\n")
cat("Any days lost:", round(mean(acc$any_days_lost), 3), "\n")
cat("N unique mines:", n_distinct(acc$mine_id), "\n")
cat("Year range:", min(acc$cal_yr), "-", max(acc$cal_yr), "\n")
