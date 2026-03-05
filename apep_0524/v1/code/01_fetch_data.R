## ============================================================
## 01_fetch_data.R — Fetch ACS 1-Year Tables via Census API
## ============================================================
## State-level data by race for 2015-2023
## Tables: C23002 (employment by sex/age/race), B20017 (earnings by race),
##         B24010 (occupation by sex/race)

source("00_packages.R")

CENSUS_API_KEY <- Sys.getenv("CENSUS_API_KEY")
if (nchar(CENSUS_API_KEY) == 0) {
  stop("CENSUS_API_KEY not set in environment. Cannot proceed without real data.")
}

OUT_DIR <- "../data"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

## ---- CROWN Act adoption dates ----
crown_dates <- tribble(
  ~state_fips, ~state_abbr, ~state_name,       ~crown_effective,
  "06",        "CA",        "California",       "2020-01-01",
  "36",        "NY",        "New York",         "2019-07-12",
  "34",        "NJ",        "New Jersey",       "2019-12-19",
  "08",        "CO",        "Colorado",         "2020-03-06",
  "51",        "VA",        "Virginia",         "2020-07-01",
  "53",        "WA",        "Washington",       "2020-07-01",
  "24",        "MD",        "Maryland",         "2020-10-01",
  "09",        "CT",        "Connecticut",      "2021-03-04",
  "35",        "NM",        "New Mexico",       "2021-04-05",
  "10",        "DE",        "Delaware",         "2021-12-16",
  "31",        "NE",        "Nebraska",         "2021-07-01",
  "32",        "NV",        "Nevada",           "2021-10-01",
  "41",        "OR",        "Oregon",           "2022-01-01",
  "17",        "IL",        "Illinois",         "2023-01-01",
  "23",        "ME",        "Maine",            "2022-03-28",
  "25",        "MA",        "Massachusetts",    "2022-10-24",
  "22",        "LA",        "Louisiana",        "2022-08-01",
  "02",        "AK",        "Alaska",           "2022-09-14",
  "27",        "MN",        "Minnesota",        "2023-01-31",
  "48",        "TX",        "Texas",            "2023-09-01",
  "26",        "MI",        "Michigan",         "2023-06-08",
  "47",        "TN",        "Tennessee",        "2022-04-28",
  "04",        "AZ",        "Arizona",          "2024-01-01",
  "21",        "KY",        "Kentucky",         "2024-07-15",
  "05",        "AR",        "Arkansas",         "2024-01-01"
) %>%
  mutate(crown_effective = as.Date(crown_effective),
         crown_year = as.integer(format(crown_effective, "%Y")))

fwrite(crown_dates, file.path(OUT_DIR, "crown_act_dates.csv"))
cat("CROWN Act dates saved:", nrow(crown_dates), "states\n")

## ---- Census API helper ----
fetch_census <- function(year, variables, label = "data") {
  url <- paste0(
    "https://api.census.gov/data/", year, "/acs/acs1",
    "?get=NAME,", paste(variables, collapse = ","),
    "&for=state:*",
    "&key=", CENSUS_API_KEY
  )

  tryCatch({
    resp <- httr::GET(url, httr::timeout(120))
    if (httr::status_code(resp) != 200) {
      body <- httr::content(resp, "text", encoding = "UTF-8")
      stop("Census API returned HTTP ", httr::status_code(resp),
           " for ", label, " year ", year, "\n", substr(body, 1, 200))
    }
    raw <- httr::content(resp, "text", encoding = "UTF-8")
    mat <- jsonlite::fromJSON(raw)
    df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
    names(df) <- mat[1, ]
    df$year <- year
    return(df)
  }, error = function(e) {
    stop("Data fetch FAILED for ", label, " year ", year, ": ", e$message,
         "\nPivot research question or fix the source.")
  })
}

## ---- Define variables ----
## C23002: Employment Status by Sex by Age (working age 16-64)
## Suffix A=White, B=Black, D=Asian
## _001E=total, _003E=male 16-64, _007E=male employed, _008E=male unemployed
## _016E=female 16-64, _020E=female employed, _021E=female unemployed

emp_vars <- function(suffix) {
  paste0("C23002", suffix, "_",
         sprintf("%03d", c(1, 3, 4, 7, 8, 9, 16, 17, 20, 21, 22)), "E")
}

## B20017: Median Earnings (suffix A=White, B=Black, D=Asian)
earn_var <- function(suffix) paste0("B20017", suffix, "_001E")

## B24010: Sex by Occupation (suffix A=White, B=Black)
## Male: _001=total, _002=male total, _003=mgmt/bus/sci/arts, _019=service,
##       _027=sales/office, _030=natural resources, _034=production
## Female: _038=female total, _039=mgmt, _055=service,
##         _063=sales/office, _066=natural resources, _070=production
occ_vars <- function(suffix) {
  paste0("B24010", suffix, "_",
         sprintf("%03d", c(1, 2, 3, 19, 27, 30, 34, 38, 39, 55, 63, 66, 70)), "E")
}

## ---- Fetch all years ----
## NOTE: 2020 ACS 1-year was NOT released due to COVID low response rates.
## The Census Bureau produced only "experimental" estimates for 2020.
## We skip 2020 entirely, which is also our primary robustness check.
years <- c(2015:2019, 2021:2023)
all_rows <- list()

for (yr in years) {
  cat("Fetching year", yr, "...\n")

  for (race_info in list(
    list(suffix = "A", label = "White"),
    list(suffix = "B", label = "Black"),
    list(suffix = "D", label = "Asian")
  )) {
    sfx <- race_info$suffix
    race_label <- race_info$label

    ## Employment
    emp_df <- fetch_census(yr, emp_vars(sfx), paste0("emp_", race_label))

    ## Earnings
    earn_df <- fetch_census(yr, earn_var(sfx), paste0("earn_", race_label))

    ## Occupation (only for White and Black)
    has_occ <- sfx %in% c("A", "B")
    if (has_occ) {
      occ_df <- tryCatch(
        fetch_census(yr, occ_vars(sfx), paste0("occ_", race_label)),
        error = function(e) {
          cat("  WARNING: occupation data unavailable for", race_label, yr, "\n")
          NULL
        }
      )
    } else {
      occ_df <- NULL
    }

    ## Process employment
    ev <- emp_vars(sfx)
    row <- emp_df %>%
      transmute(
        state_fips = sprintf("%02d", as.integer(state)),
        year = as.integer(year),
        race_group = race_label,
        pop_total = as.numeric(.data[[ev[1]]]),
        male_16_64 = as.numeric(.data[[ev[2]]]),
        male_in_lf = as.numeric(.data[[ev[3]]]),
        male_employed = as.numeric(.data[[ev[4]]]),
        male_unemployed = as.numeric(.data[[ev[5]]]),
        male_nilf = as.numeric(.data[[ev[6]]]),
        female_16_64 = as.numeric(.data[[ev[7]]]),
        female_in_lf = as.numeric(.data[[ev[8]]]),
        female_employed = as.numeric(.data[[ev[9]]]),
        female_unemployed = as.numeric(.data[[ev[10]]]),
        female_nilf = as.numeric(.data[[ev[11]]])
      ) %>%
      mutate(
        pop_16_64 = male_16_64 + female_16_64,
        total_employed = male_employed + female_employed,
        total_in_lf = male_in_lf + female_in_lf,
        emp_rate = total_employed / pop_16_64,
        lfp_rate = total_in_lf / pop_16_64,
        female_emp_rate = female_employed / female_16_64,
        male_emp_rate = male_employed / male_16_64
      )

    ## Add earnings
    evar <- earn_var(sfx)
    row$median_earnings <- as.numeric(earn_df[[evar]])
    row$log_median_earn <- ifelse(row$median_earnings > 0,
                                   log(row$median_earnings), NA_real_)

    ## Add occupation shares
    if (!is.null(occ_df)) {
      ov <- occ_vars(sfx)
      occ_processed <- occ_df %>%
        transmute(
          state_fips = sprintf("%02d", as.integer(state)),
          occ_total = as.numeric(.data[[ov[1]]]),
          male_total = as.numeric(.data[[ov[2]]]),
          male_prof = as.numeric(.data[[ov[3]]]),  # mgmt/business/science/arts
          male_service = as.numeric(.data[[ov[4]]]),
          male_sales_office = as.numeric(.data[[ov[5]]]),
          male_natural = as.numeric(.data[[ov[6]]]),
          male_production = as.numeric(.data[[ov[7]]]),
          female_total = as.numeric(.data[[ov[8]]]),
          female_prof = as.numeric(.data[[ov[9]]]),
          female_service = as.numeric(.data[[ov[10]]]),
          female_sales_office = as.numeric(.data[[ov[11]]]),
          female_natural = as.numeric(.data[[ov[12]]]),
          female_production = as.numeric(.data[[ov[13]]])
        ) %>%
        mutate(
          total_prof = male_prof + female_prof,
          total_service = male_service + female_service,
          total_sales_office = male_sales_office + female_sales_office,
          ## Customer-facing = service + sales/office
          total_customer_facing = total_service + total_sales_office,
          share_professional = total_prof / occ_total,
          share_service = total_service / occ_total,
          share_sales_office = total_sales_office / occ_total,
          share_customer_facing = total_customer_facing / occ_total,
          ## Female-specific shares
          female_share_prof = female_prof / female_total,
          female_share_customer = (female_service + female_sales_office) / female_total,
          male_share_prof = male_prof / male_total,
          male_share_customer = (male_service + male_sales_office) / male_total
        )

      row <- row %>%
        left_join(
          occ_processed %>% select(state_fips, share_professional, share_service,
                                    share_sales_office, share_customer_facing,
                                    female_share_prof, female_share_customer,
                                    male_share_prof, male_share_customer),
          by = "state_fips"
        )
    }

    all_rows[[paste(yr, race_label)]] <- row
  }

  cat("  Year", yr, "complete\n")
  Sys.sleep(0.5)
}

panel <- bind_rows(all_rows)
cat("\nTotal panel rows:", nrow(panel), "\n")

## ---- Merge CROWN Act treatment ----
panel <- panel %>%
  left_join(crown_dates %>% select(state_fips, crown_year),
            by = "state_fips") %>%
  mutate(
    crown_state = as.integer(!is.na(crown_year)),
    crown_active = as.integer(!is.na(crown_year) & year >= crown_year),
    first_treat = ifelse(crown_state == 1, crown_year, 0L),
    black = as.integer(race_group == "Black"),
    state_id = as.integer(factor(state_fips))
  )

## ---- Save ----
fwrite(panel, file.path(OUT_DIR, "state_year_race_panel.csv"))
cat("Saved state-year-race panel:", nrow(panel), "rows\n")

## ---- DATA VALIDATION ----
n_states <- n_distinct(panel$state_fips)
n_years <- n_distinct(panel$year)
n_treated <- n_distinct(panel$state_fips[panel$first_treat > 0])
n_races <- n_distinct(panel$race_group)

stopifnot("Expected 50+ state FIPS" = n_states >= 50)
stopifnot("Expected 8 years (2015-2019, 2021-2023)" = n_years >= 8)
stopifnot("Expected 20+ treated states" = n_treated >= 20)
stopifnot("Expected 3 race groups" = n_races >= 3)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("States:", n_states, "\n")
cat("Years:", n_years, "\n")
cat("Treated states:", n_treated, "\n")
cat("Race groups:", n_races, "\n")
cat("Panel observations:", nrow(panel), "\n")
