## 02_clean_data.R — Construct state-year panel with treatment coding
## APEP-1033: Pouring Risk — Raw Milk Legalization and Foodborne Illness

source("00_packages.R")

cat("=== Building Analysis Panel ===\n")

## ---- Load NORS raw data ----
nors <- read_csv("../data/nors_raw.csv", show_col_types = FALSE)
cat("NORS records:", nrow(nors), "\n")

## ---- Identify unpasteurized dairy outbreaks ----
## Filter: food_vehicle contains "unpasteurized" AND dairy product, OR "Raw Milk"
nors_food <- nors %>% filter(primary_mode == "Food")

unpast_dairy <- nors_food %>%
  filter(
    grepl("Raw Milk", food_vehicle, ignore.case = FALSE) |
    (grepl("unpasteurized", food_vehicle, ignore.case = TRUE) &
     grepl("milk|cheese|dairy|queso|cream cheese", food_vehicle, ignore.case = TRUE))
  )

cat("Unpasteurized dairy outbreaks:", nrow(unpast_dairy), "\n")
cat("Year range:", range(as.integer(unpast_dairy$year), na.rm = TRUE), "\n")

## Verify state coverage
cat("States with outbreaks:", n_distinct(unpast_dairy$state), "\n")
cat("Top states:\n")
print(sort(table(unpast_dairy$state), decreasing = TRUE)[1:15])

## ---- Pasteurized dairy outbreaks (placebo) ----
all_dairy <- nors_food %>%
  filter(ifsac_category == "Dairy" | grepl("milk|cheese|dairy", food_vehicle, ignore.case = TRUE))

past_dairy <- all_dairy %>%
  filter(!(
    grepl("Raw Milk", food_vehicle, ignore.case = FALSE) |
    (grepl("unpasteurized", food_vehicle, ignore.case = TRUE) &
     grepl("milk|cheese|dairy|queso|cream cheese", food_vehicle, ignore.case = TRUE))
  ))

cat("Pasteurized/other dairy outbreaks (placebo):", nrow(past_dairy), "\n")

## ---- Non-dairy foodborne outbreaks (second placebo) ----
non_dairy <- nors_food %>%
  filter(
    !grepl("milk|cheese|dairy|queso|cream cheese|Raw Milk", food_vehicle, ignore.case = TRUE),
    ifsac_category != "Dairy" | is.na(ifsac_category)
  )
cat("Non-dairy foodborne outbreaks:", nrow(non_dairy), "\n")

## ---- Aggregate to state-year ----
## Main outcome: count of unpasteurized dairy outbreaks
unpast_sy <- unpast_dairy %>%
  mutate(year = as.integer(year)) %>%
  group_by(state, year) %>%
  summarise(
    outbreaks_unpast = n(),
    illnesses_unpast = sum(as.integer(illnesses), na.rm = TRUE),
    hosp_unpast      = sum(as.integer(hospitalizations), na.rm = TRUE),
    .groups = "drop"
  )

## Placebo: pasteurized dairy
past_sy <- past_dairy %>%
  mutate(year = as.integer(year)) %>%
  group_by(state, year) %>%
  summarise(
    outbreaks_past = n(),
    illnesses_past = sum(as.integer(illnesses), na.rm = TRUE),
    .groups = "drop"
  )

## Placebo: non-dairy
nondairy_sy <- non_dairy %>%
  mutate(year = as.integer(year)) %>%
  group_by(state, year) %>%
  summarise(
    outbreaks_nondairy = n(),
    .groups = "drop"
  )

## ---- Raw milk law treatment variable ----
## Sources: Whitten et al. (2018, Epidemiology & Infection 146:1420-1430, PMC6140832)
##          Farm-to-Consumer Legal Defense Fund (FTCLDF) interactive map (2024)
##          NCSL Policy Research on Raw Milk
##          Langer et al. (2012, CDC MMWR)
##          Mungai et al. (2015, EID 21:119-122)
##
## Classification follows Whitten et al. 5-category system:
##   R = Retail (off-farm sales in stores)
##   F = Farm-gate (on-farm direct sales only)
##   H = Herdshare (cow-share arrangements, sales illegal)
##   P = Pet food (sold as animal feed only)
##   I = Illegal (all raw milk sales prohibited)
##
## Treatment: first_legal_year = year state first legalized ANY form of raw milk
##   sales for human consumption (R, F, or H). Pet food (P) excluded from main
##   treatment definition. For always-legal states (pre-1998), coded as 0.
##   For never-treated states (illegal through 2023), coded as Inf.
##
## "Always treated" verified against 2004 NASDA Survey of State Departments of
## Agriculture (the earliest comprehensive enumeration in the literature).

treatment <- tribble(
  ~state_abbr, ~state_name,        ~first_legal_year, ~category, ~source_note,
  "AL",        "Alabama",          Inf,  "I", "Illegal throughout; FTCLDF 2024",
  "AK",        "Alaska",           0,    "F", "On-farm w/ registration; pre-1998; NASDA 2004",
  "AZ",        "Arizona",          0,    "R", "Retail legal; pre-1998; NASDA 2004",
  "AR",        "Arkansas",         Inf,  "I", "Illegal through 2023; incidental sales 2025; FTCLDF 2024",
  "CA",        "California",       0,    "R", "Retail legal since 1930s; NASDA 2004",
  "CO",        "Colorado",         2005, "H", "Herdshare legalized ~2005; Whitten et al. 2018",
  "CT",        "Connecticut",      0,    "R", "Retail legal; pre-1998; NASDA 2004",
  "DE",        "Delaware",         Inf,  "I", "Illegal through 2023; permit 2024; FTCLDF 2024",
  "FL",        "Florida",          Inf,  "I", "Illegal (pet food only); FTCLDF 2024",
  "GA",        "Georgia",          2023, "F", "Raw milk permit introduced 2023; FTCLDF 2024",
  "HI",        "Hawaii",           Inf,  "I", "Illegal throughout; FTCLDF 2024",
  "ID",        "Idaho",            0,    "R", "Retail legal w/ license; pre-1998; NASDA 2004",
  "IL",        "Illinois",         2006, "F", "On-farm sales legalized 2006 (SB 858); Whitten et al. 2018",
  "IN",        "Indiana",          Inf,  "I", "Illegal (pet food only); FTCLDF 2024",
  "IA",        "Iowa",             2017, "F", "Limited on-farm legalized 2017; FTCLDF 2024",
  "KS",        "Kansas",           0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "KY",        "Kentucky",         2009, "H", "Herdshare legalized ~2009; Whitten et al. 2018",
  "LA",        "Louisiana",        Inf,  "I", "Illegal (pet food only); FTCLDF 2024",
  "ME",        "Maine",            0,    "R", "Retail legal; pre-1998; NASDA 2004",
  "MD",        "Maryland",         Inf,  "P", "Pet food only (2006); excluded from human consumption treatment",
  "MA",        "Massachusetts",    0,    "F", "On-farm legal (Grade A); pre-1998; NASDA 2004",
  "MI",        "Michigan",         2013, "H", "Herdshare legalized ~2013; Whitten et al. 2018",
  "MN",        "Minnesota",        0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "MS",        "Mississippi",      0,    "F", "Goat milk on-farm; pre-1998; NASDA 2004",
  "MO",        "Missouri",         0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "MT",        "Montana",          2007, "F", "On-farm legalized ~2007 (HB 574); FTCLDF/NCSL",
  "NE",        "Nebraska",         0,    "F", "On-farm direct-to-consumer; pre-1998; NASDA 2004",
  "NV",        "Nevada",           2015, "F", "On-farm/retail expanded ~2015; FTCLDF 2024",
  "NH",        "New Hampshire",    0,    "R", "Retail legal; pre-1998; NASDA 2004",
  "NJ",        "New Jersey",       Inf,  "I", "Illegal throughout; FTCLDF 2024",
  "NM",        "New Mexico",       0,    "R", "Retail legal; pre-1998; NASDA 2004",
  "NY",        "New York",         0,    "F", "On-farm w/ license; pre-1998; NASDA 2004",
  "NC",        "North Carolina",   2018, "H", "Herdshare legalized ~2018; FTCLDF 2024",
  "ND",        "North Dakota",     2011, "H", "Herdshare legalized ~2011; Whitten et al. 2018",
  "OH",        "Ohio",             2013, "H", "Herdshare legalized ~2013; Whitten et al. 2018",
  "OK",        "Oklahoma",         0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "OR",        "Oregon",           0,    "F", "On-farm legal (limited); pre-1998; NASDA 2004",
  "PA",        "Pennsylvania",     0,    "R", "Retail legal w/ permit; pre-1998; NASDA 2004",
  "RI",        "Rhode Island",     Inf,  "I", "Illegal (limited goat Rx only); FTCLDF 2024",
  "SC",        "South Carolina",   0,    "R", "Farm-gate pre-1998; retail expanded ~2008; NASDA/Whitten",
  "SD",        "South Dakota",     0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "TN",        "Tennessee",        2009, "H", "Herdshare legalized ~2009; Whitten et al. 2018",
  "TX",        "Texas",            0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "UT",        "Utah",             0,    "R", "Farm-gate pre-1998; retail expanded ~2007; NASDA/Whitten",
  "VT",        "Vermont",          0,    "F", "On-farm legal; pre-1998; NASDA 2004",
  "VA",        "Virginia",         Inf,  "I", "Illegal throughout; FTCLDF 2024",
  "WA",        "Washington",       0,    "R", "Retail legal; pre-1998; NASDA 2004",
  "WV",        "West Virginia",    2016, "H", "Herdshare legalized ~2016; Whitten/FTCLDF",
  "WI",        "Wisconsin",        2011, "H", "Herdshare practice ~2011; FTCLDF 2024",
  "WY",        "Wyoming",          2005, "H", "Herdshare legalized ~2005; Whitten et al. 2018"
)

cat("Treatment coding:\n")
cat("  Always treated (pre-1998):", sum(treatment$first_legal_year == 0), "states\n")
cat("  Treated during sample:",    sum(is.finite(treatment$first_legal_year) &
                                         treatment$first_legal_year > 0), "states\n")
cat("  Never treated:",            sum(is.infinite(treatment$first_legal_year)), "states\n")

## ---- Map state names to abbreviations ----
## NORS uses full state names; treatment uses abbreviations
state_xwalk <- tibble(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC")
)

## Add DC as never-treated
treatment <- bind_rows(treatment,
  tibble(state_abbr = "DC", state_name = "District of Columbia",
         first_legal_year = Inf, category = "I",
         source_note = "Illegal; federal jurisdiction"))

## ---- Build balanced state-year panel ----
years <- 1998:2023
states_in_data <- sort(unique(nors$state))
cat("\nStates in NORS:", length(states_in_data), "\n")

## Create balanced panel (all state-year combinations)
panel <- expand_grid(
  state = states_in_data,
  year  = years
)

## Join treatment info
panel <- panel %>%
  left_join(state_xwalk, by = c("state" = "state_name")) %>%
  left_join(treatment %>% dplyr::select(state_abbr, first_legal_year, category),
            by = "state_abbr")

## Check for unmatched states
unmatched <- panel %>% filter(is.na(first_legal_year)) %>% distinct(state)
if (nrow(unmatched) > 0) {
  cat("WARNING: States without treatment coding:\n")
  print(unmatched$state)
  ## Drop territories/unmatched
  panel <- panel %>% filter(!is.na(first_legal_year))
}

## ---- Construct treatment indicators ----
panel <- panel %>%
  mutate(
    ## For CS: first_treat = 0 means never treated
    ## For always-treated: exclude from CS (set to earliest year)
    first_treat_cs = case_when(
      is.infinite(first_legal_year)     ~ 0L,           # never treated
      first_legal_year == 0             ~ NA_integer_,   # always treated — excluded from CS
      TRUE                              ~ as.integer(first_legal_year)
    ),
    ## Binary treatment indicator (any legal access this year)
    legal = case_when(
      first_legal_year == 0                          ~ 1L,  # always legal
      is.finite(first_legal_year) & year >= first_legal_year ~ 1L,
      TRUE                                           ~ 0L
    ),
    ## Post indicator for newly-treated states only
    post = as.integer(is.finite(first_legal_year) & first_legal_year > 0 & year >= first_legal_year)
  )

## ---- Merge outcomes ----
panel <- panel %>%
  left_join(unpast_sy,   by = c("state", "year")) %>%
  left_join(past_sy,     by = c("state", "year")) %>%
  left_join(nondairy_sy, by = c("state", "year")) %>%
  mutate(
    across(c(outbreaks_unpast, illnesses_unpast, hosp_unpast,
             outbreaks_past, illnesses_past, outbreaks_nondairy),
           ~replace_na(.x, 0L))
  )

## ---- Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", n_distinct(panel$state), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Total unpasteurized dairy outbreaks:", sum(panel$outbreaks_unpast), "\n")
cat("Total illnesses:", sum(panel$illnesses_unpast), "\n")
cat("Total hospitalizations:", sum(panel$hosp_unpast), "\n")
cat("Mean outbreaks per state-year:", round(mean(panel$outbreaks_unpast), 3), "\n")
cat("Share state-years with zero:", round(mean(panel$outbreaks_unpast == 0), 3), "\n")

cat("\nBy treatment status (ever vs never legal):\n")
panel %>%
  group_by(ever_legal = legal == 1 | first_legal_year == 0 |
             (is.finite(first_legal_year) & first_legal_year > 0)) %>%
  summarise(
    n_sy = n(),
    mean_outbreaks = mean(outbreaks_unpast),
    mean_illnesses = mean(illnesses_unpast),
    .groups = "drop"
  ) %>%
  print()

cat("\nBy newly-treated vs never-treated (CS sample):\n")
panel_cs <- panel %>% filter(!is.na(first_treat_cs))  # exclude always-treated
cat("CS sample size:", nrow(panel_cs), "\n")
cat("Newly treated states:", n_distinct(panel_cs$state[panel_cs$first_treat_cs > 0]), "\n")
cat("Never-treated states:", n_distinct(panel_cs$state[panel_cs$first_treat_cs == 0]), "\n")

## ---- Save ----
write_csv(panel, "../data/panel.csv")
write_csv(panel_cs, "../data/panel_cs.csv")
write_csv(treatment, "../data/treatment_coding.csv")

cat("\nPanel saved. Ready for analysis.\n")
