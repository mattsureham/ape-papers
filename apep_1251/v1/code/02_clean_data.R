source("code/00_packages.R")

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)

strikes <- fread("data/raw/nwsd_strikes.csv.gz")
airports <- fread("data/raw/faa_airports.csv.gz")
class3 <- fread("data/raw/class3_airports_2001.csv")

strikes[, incident_date := as.Date(IncidentDate)]
strikes[, year := year(incident_date)]
strikes[, airport_code_raw := toupper(sub("^.*\\(([^)]+)\\).*$", "\\1", AIRPORT))]
strikes[airport_code_raw == AIRPORT, airport_code_raw := NA_character_]
strikes[, airport_code_norm := fifelse(grepl("^K[A-Z0-9]{3}$", airport_code_raw), substr(airport_code_raw, 2, 4), airport_code_raw)]

airports <- airports[Country == "USA" | STATE_CODE %in% state.abb]
airports[, AirportCode := toupper(trimws(AirportCode))]
airports[, FAA_Airport_Code := toupper(trimws(FAA_Airport_Code))]
airports[, ICAO_Airport_Code := toupper(trimws(ICAO_Airport_Code))]
airports[, IATA_Airport_Code := toupper(trimws(IATA_Airport_Code))]

code_lookup <- rbindlist(list(
  airports[, .(Airport_ID, code = AirportCode, Country, STATE_CODE, Part_139_Class)],
  airports[, .(Airport_ID, code = FAA_Airport_Code, Country, STATE_CODE, Part_139_Class)],
  airports[, .(Airport_ID, code = ICAO_Airport_Code, Country, STATE_CODE, Part_139_Class)],
  airports[, .(Airport_ID, code = IATA_Airport_Code, Country, STATE_CODE, Part_139_Class)]
), use.names = TRUE, fill = TRUE)
code_lookup <- unique(code_lookup[!is.na(code) & code != ""])
code_lookup[, code_norm := fifelse(grepl("^K[A-Z0-9]{3}$", code), substr(code, 2, 4), code)]
code_lookup <- unique(code_lookup[, .(code_norm, Airport_ID, STATE_CODE, Part_139_Class)])

strikes <- merge(
  strikes,
  code_lookup,
  by.x = "airport_code_norm",
  by.y = "code_norm",
  all.x = TRUE
)

strikes <- strikes[!is.na(Airport_ID) & !is.na(year)]
strikes[, treated := airport_code_norm %chin% class3$airport_code]
strikes[, post := year >= 2007]
strikes[, transition := year %between% c(2004, 2006)]
strikes[, damage_code := fifelse(is.na(Damage) | Damage == "", "BLANK", Damage)]
strikes[, damaging_any := damage_code %chin% c("M", "M?", "S", "D")]
strikes[, severe_damage := damage_code %chin% c("S", "D")]
strikes[, no_damage := damage_code == "N"]

pre_counts <- strikes[year <= 2003, .(pre_strikes = .N), by = .(airport_code_norm, Airport_ID, treated, STATE_CODE, Part_139_Class)]
treated_pre <- pre_counts[treated == TRUE]

control_pool <- pre_counts[
  treated == FALSE &
    Part_139_Class %chin% c("", "0") &
    pre_strikes >= 1
]

treated_sample_ids <- unique(treated_pre$Airport_ID)
control_sample_ids <- unique(control_pool$Airport_ID)
sample_ids <- unique(c(treated_sample_ids, control_sample_ids))

sample_airports <- unique(strikes[Airport_ID %in% sample_ids, .(
  Airport_ID, airport_code_norm, treated, STATE_CODE, Part_139_Class
)])[order(-treated, airport_code_norm)]

panel_grid <- CJ(
  Airport_ID = sample_airports$Airport_ID,
  year = 1990:2024,
  unique = TRUE
)

annual <- strikes[
  Airport_ID %in% sample_ids,
  .(
    total_strikes = .N,
    damaging_strikes = sum(damaging_any, na.rm = TRUE),
    severe_strikes = sum(severe_damage, na.rm = TRUE),
    no_damage_strikes = sum(no_damage, na.rm = TRUE),
    known_damage_strikes = sum(damage_code != "BLANK", na.rm = TRUE)
  ),
  by = .(Airport_ID, year)
]

panel <- merge(panel_grid, annual, by = c("Airport_ID", "year"), all.x = TRUE)
panel <- merge(panel, sample_airports, by = "Airport_ID", all.x = TRUE)

for (col in c("total_strikes", "damaging_strikes", "severe_strikes", "no_damage_strikes", "known_damage_strikes")) {
  set(panel, which(is.na(panel[[col]])), col, 0L)
}

panel[, post := year >= 2007]
panel[, transition := year %between% c(2004, 2006)]
panel[, treated_post := treated & post]
panel[, damage_share := fifelse(total_strikes > 0, damaging_strikes / total_strikes, 0)]
panel[, severe_share := fifelse(total_strikes > 0, severe_strikes / total_strikes, 0)]
panel[, ln_total_plus1 := log1p(total_strikes)]
panel[, ln_damage_plus1 := log1p(damaging_strikes)]

fwrite(panel, "data/clean/airport_year_panel.csv.gz")
fwrite(sample_airports, "data/clean/sample_airports.csv")

summary_dt <- panel[
  transition == FALSE,
  .(
    mean_total = mean(total_strikes),
    mean_damage = mean(damaging_strikes),
    mean_damage_share = mean(damage_share)
  ),
  by = .(treated, post)
]
fwrite(summary_dt, "data/clean/summary_cells.csv")

stopifnot(
  panel[treated == TRUE, uniqueN(Airport_ID)] >= 20,
  panel[year <= 2003, uniqueN(year)] >= 5,
  nrow(panel) >= 1000
)

message("Clean panel built with ", panel[treated == TRUE, uniqueN(Airport_ID)], " treated airports.")
