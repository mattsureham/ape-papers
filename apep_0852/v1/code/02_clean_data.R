## 02_clean_data.R — Construct analysis dataset from CPS FSS
## Creates household-level panel with treatment indicators
## Uses 2016-2019 + 2021-2023 (skip 2020 due to COVID fieldwork)

library(data.table)
library(jsonlite)

# Set working directory to paper root (parent of code/)
paper_dir <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE),
  error = function(e) normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
)
if (dir.exists(paper_dir)) setwd(paper_dir)
datadir <- "data"

cat("=== Cleaning CPS FSS data (extended panel) ===\n")

# ── Load all person-level data ───────────────────────────────────
person_main <- fread(file.path(datadir, "cps_fss_person.csv"))
person_extra <- fread(file.path(datadir, "cps_fss_extra_years.csv"))
person <- rbindlist(list(person_extra, person_main), fill = TRUE)
cat(sprintf("Person records loaded: %s\n", format(nrow(person), big.mark = ",")))

# ── Identify reference persons ───────────────────────────────────
# PERRP coding: 2016-2019 uses 1=ref person; 2021+ uses 40/41
person[, is_ref := fifelse(
  year <= 2019,
  PERRP == 1,
  PERRP %in% c(40, 41)
)]

cat(sprintf("Reference persons: %s\n", format(sum(person$is_ref), big.mark = ",")))

# ── Count school-age children per household ──────────────────────
person[, hh_id := paste(HRHHID, HRHHID2, year, sep = "_")]

school_age <- person[PRTAGE >= 5 & PRTAGE <= 18, .(n_school_age = .N), by = hh_id]
young_child <- person[PRTAGE >= 0 & PRTAGE <= 4, .(n_young_child = .N), by = hh_id]

# ── Build household-level dataset ────────────────────────────────
hh <- person[is_ref == TRUE]
hh[, hh_id := paste(HRHHID, HRHHID2, year, sep = "_")]

hh <- merge(hh, school_age, by = "hh_id", all.x = TRUE)
hh <- merge(hh, young_child, by = "hh_id", all.x = TRUE)
hh[is.na(n_school_age), n_school_age := 0]
hh[is.na(n_young_child), n_young_child := 0]

cat(sprintf("Household records: %s\n", format(nrow(hh), big.mark = ",")))
cat("By year:\n")
print(hh[, .N, by = year][order(year)])

# ── Treatment variables ──────────────────────────────────────────
cohort1 <- c(6, 23)          # CA, ME
cohort2 <- c(8, 26, 27, 50)  # CO, MI, MN, VT

hh[, `:=`(
  treat_state = as.integer(GESTFIPS %in% c(cohort1, cohort2)),
  first_treat = fifelse(
    GESTFIPS %in% cohort1, 2022,
    fifelse(GESTFIPS %in% cohort2, 2023, 0)
  ),
  has_school_age = as.integer(n_school_age > 0),
  young_only = as.integer(n_young_child > 0 & n_school_age == 0)
)]

hh[, post := as.integer(
  (GESTFIPS %in% cohort1 & year >= 2022) |
  (GESTFIPS %in% cohort2 & year >= 2023)
)]

hh[, treat_x_school_x_post := treat_state * has_school_age * post]

# ── Outcomes ─────────────────────────────────────────────────────
hh[, `:=`(
  food_insecure = as.integer(HRFS12M1 %in% c(2, 3)),
  very_low_fs   = as.integer(HRFS12M1 == 3),
  low_fs        = as.integer(HRFS12M1 == 2),
  food_secure   = as.integer(HRFS12M1 == 1),
  snap_receipt  = as.integer(HESS2 == 1)
)]

# Filter to valid food security
hh <- hh[HRFS12M1 > 0]
cat(sprintf("With valid food security status: %s\n", format(nrow(hh), big.mark = ",")))

# ── Controls ─────────────────────────────────────────────────────
hh[, educ_cat := fifelse(
  PEEDUCA <= 38, "less_hs",
  fifelse(PEEDUCA == 39, "hs_diploma",
  fifelse(PEEDUCA %in% 40:42, "some_college", "college_plus"))
)]

hh[, race_eth := fifelse(
  PEHSPNON == 1, "hispanic",
  fifelse(PTDTRACE == 1, "white_nh",
  fifelse(PTDTRACE == 2, "black_nh", "other_nh"))
)]

hh[, `:=`(
  metro = as.integer(GTMETSTA == 1),
  low_income = as.integer(HRPOOR == 1),
  single_parent = as.integer(HRHTYPE %in% c(5, 6, 7, 8)),
  hhsize = pmin(HRNUMHOU, 10),
  age_ref = pmin(PRTAGE, 85),
  female_ref = as.integer(PESEX == 2)
)]

# ── Weights ──────────────────────────────────────────────────────
hh[, wt := fifelse(is.na(PWSSWGT) | PWSSWGT <= 0, 1, PWSSWGT)]

# ── State names ──────────────────────────────────────────────────
state_names <- data.table(
  GESTFIPS = c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                 "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                 "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                 "UT","VT","VA","WA","WV","WI","WY")
)
hh <- merge(hh, state_names, by = "GESTFIPS", all.x = TRUE)

# ── Summary ──────────────────────────────────────────────────────
cat("\n=== Analysis Dataset Summary ===\n")
cat(sprintf("Total households: %s\n", format(nrow(hh), big.mark = ",")))
cat(sprintf("Years: %s\n", paste(sort(unique(hh$year)), collapse = ", ")))
cat(sprintf("States: %d\n", uniqueN(hh$GESTFIPS)))
cat(sprintf("Pre-treatment years: %d\n", length(unique(hh[year < 2022]$year))))

cat("\nFood insecurity by year:\n")
print(hh[, .(fi = round(100 * weighted.mean(food_insecure, wt), 1), n = .N), by = year][order(year)])

cat("\nTreated HH with DDD=1:\n")
cat(sprintf("  %d household-year observations\n", sum(hh$treat_x_school_x_post)))

# ── Save ─────────────────────────────────────────────────────────
fwrite(hh, file.path(datadir, "analysis_data.csv"))
cat(sprintf("\nSaved: %s/analysis_data.csv\n", datadir))
cat("=== Cleaning complete ===\n")
