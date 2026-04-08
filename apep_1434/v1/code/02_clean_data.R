##############################################################################
# 02_clean_data.R — Construct agency × month analysis panel
# apep_1434: When Scandals Go Dark
##############################################################################

source("00_packages.R")

agency_hearings <- readRDS("data/agency_hearings.rds")
scandal_trends <- readRDS("data/scandal_trends.rds")
competing_trends <- readRDS("data/competing_trends.rds")
event_months <- readRDS("data/event_months.rds")
political <- readRDS("data/political.rds")
agencies <- readRDS("data/agencies.rds")

###########################################################################
# 1. Build balanced panel (2009-2024)
###########################################################################
cat("=== Building balanced panel ===\n")

months_grid <- tibble(
  ym = seq(as.Date("2009-01-01"), as.Date("2024-12-01"), by = "month")
)

panel <- expand_grid(
  agency_code = agencies$agency_code,
  ym = months_grid$ym
)

# Merge hearings
panel <- panel |>
  left_join(agency_hearings, by = c("agency_code", "ym")) |>
  mutate(n_hearings = replace_na(n_hearings, 0))

# Merge Google Trends scandal interest
panel <- panel |>
  left_join(scandal_trends, by = c("agency_code", "ym")) |>
  mutate(scandal_interest = replace_na(scandal_interest, 0))

# Merge competing event trends
panel <- panel |>
  left_join(competing_trends, by = "ym") |>
  mutate(
    across(c(olympics_interest, impeach_interest, competing_interest),
           ~replace_na(.x, 0))
  )

# Merge event calendar
panel <- panel |>
  left_join(event_months |> select(ym, has_mega_event, n_events), by = "ym") |>
  mutate(
    has_mega_event = replace_na(has_mega_event, FALSE),
    mega = as.integer(has_mega_event),
    n_events = replace_na(n_events, 0L)
  )

# Merge political controls
panel <- panel |>
  left_join(political, by = "ym")

###########################################################################
# 2. Construct variables
###########################################################################
cat("=== Constructing variables ===\n")

panel <- panel |>
  mutate(
    year = year(ym),
    month_num = month(ym),
    quarter = quarter(ym),

    # IHS transforms
    ihs_hearings = asinh(n_hearings),
    ihs_scandal = asinh(scandal_interest),
    ihs_competing = asinh(competing_interest),

    # Log transforms
    log_hearings = log(n_hearings + 1),
    log_scandal = log(scandal_interest + 1),

    # Binary outcomes
    any_hearing = as.integer(n_hearings > 0),

    # Agency fixed effect
    agency_num = as.integer(factor(agency_code))
  )

# Lagged variables
panel <- panel |>
  arrange(agency_code, ym) |>
  group_by(agency_code) |>
  mutate(
    lag1_hearings = lag(n_hearings, 1),
    lag2_hearings = lag(n_hearings, 2),
    lag1_scandal = lag(scandal_interest, 1)
  ) |>
  ungroup()

###########################################################################
# 3. Agency characteristics
###########################################################################

high_profile <- c("VA", "EPA", "FDA", "FAA", "IRS", "DHS", "CDC", "DOJ", "DOD")
panel$high_profile <- as.integer(panel$agency_code %in% high_profile)

budget_rank <- c(
  DOD = 1, HHS = 2, VA = 3, ED = 4, DHS = 5, DOT = 6, USDA = 7,
  DOJ = 8, DOE = 9, NASA = 10, HUD = 11, DOI = 12, DOL = 13,
  EPA = 14, FAA = 15, FDA = 16, FEMA = 17, IRS = 18, CDC = 19
)
panel$budget_rank <- budget_rank[panel$agency_code]

###########################################################################
# 4. Known scandals (for event study)
###########################################################################

known_scandals <- tribble(
  ~agency_code, ~scandal_name, ~scandal_ym,
  "VA",   "VA Wait Times",             "2014-05-01",
  "FAA",  "Boeing 737 MAX Grounding",  "2019-03-01",
  "EPA",  "Pruitt Ethics Scandals",    "2018-04-01",
  "IRS",  "Political Targeting",       "2013-05-01",
  "CDC",  "COVID Response",            "2020-03-01",
  "DHS",  "Family Separation",         "2018-06-01"
) |>
  mutate(scandal_ym = as.Date(scandal_ym))

panel <- panel |>
  left_join(known_scandals |> select(agency_code, scandal_ym),
            by = "agency_code") |>
  mutate(
    months_to_scandal = as.numeric(
      difftime(ym, scandal_ym, units = "days")
    ) / 30.44,
    months_to_scandal = round(months_to_scandal),
    in_scandal_window = !is.na(scandal_ym) & abs(months_to_scandal) <= 12
  )

###########################################################################
# 5. Summary
###########################################################################
cat("\n=== Panel Summary ===\n")
cat("Dimensions:", nrow(panel), "obs ×", ncol(panel), "vars\n")
cat("Agencies:", n_distinct(panel$agency_code), "\n")
cat("Months:", n_distinct(panel$ym), "\n")
cat("Range:", as.character(min(panel$ym)), "to", as.character(max(panel$ym)), "\n")
cat("\nHearings per agency-month:\n")
print(summary(panel$n_hearings))
cat("\nScandal interest (Google Trends):\n")
print(summary(panel$scandal_interest))
cat("\nCompeting interest (Google Trends):\n")
print(summary(panel$competing_interest))
cat("\nMega-event months:", sum(panel$has_mega_event) / n_distinct(panel$agency_code), "\n")

# Key correlation check
cat("\nCorr(scandal_interest, competing_interest):",
    cor(panel$scandal_interest, panel$competing_interest, use = "complete.obs"), "\n")

###########################################################################
# 6. Save
###########################################################################
saveRDS(panel, "data/analysis_panel.rds")
saveRDS(known_scandals, "data/known_scandals.rds")
cat("\nPanel saved.\n")
