## 02_clean_data.R — Clean Home Office PFA crime data
## apep_0780: Last Orders for Crime?

source("00_packages.R")

data_dir <- "../data"
pfa_raw <- readRDS(file.path(data_dir, "pfa_raw.rds"))
cia_forces <- readRDS(file.path(data_dir, "cia_forces.rds"))

## ---- Clean column names ----
# The data has messy column names from the ODS. Key columns:
# Financial Year, Financial Quarter, Force Name, Offence Group, Number of Offences
setnames(pfa_raw, old = names(pfa_raw),
         new = c("row_id", "sheet", "table_header", "fy", "quarter", "force",
                 "offence_desc", "offence_group", "offence_subgroup",
                 "offence_code", "n_offences"),
         skip_absent = TRUE)

# Drop header/notes rows (no force name)
pfa <- pfa_raw[!is.na(force) & force != "" & force != "Force Name"]
pfa[, n_offences := as.numeric(n_offences)]
cat(sprintf("After cleaning: %s rows\n", format(nrow(pfa), big.mark = ",")))

## ---- Extract financial year as integer ----
pfa[, fy_start := as.integer(substr(fy, 1, 4))]
cat("Financial years:", paste(sort(unique(pfa$fy_start)), collapse = ", "), "\n")

## ---- Identify English forces only ----
eng_forces <- sort(unique(pfa$force))
cat(sprintf("All forces: %d\n", length(eng_forces)))
# Remove Welsh, Scottish, Northern Irish, BTP, CIFAS, Action Fraud
exclude <- c("British Transport Police", "Action Fraud", "CIFAS", "Cifas",
             "Dyfed-Powys", "Gwent", "North Wales", "South Wales",
             "Police Scotland", "PSNI", "Financial Fraud Action UK",
             "UK Finance")
pfa <- pfa[!(force %in% exclude)]
eng_forces <- sort(unique(pfa$force))
cat(sprintf("English forces: %d\n", length(eng_forces)))

## ---- Classify crime types ----
pfa[, violent := as.integer(offence_group == "Violence against the person")]
pfa[, sexual := as.integer(offence_group == "Sexual offences")]
pfa[, public_order := as.integer(offence_group == "Public order offences")]
pfa[, criminal_damage := as.integer(offence_group == "Criminal damage and arson")]
pfa[, theft := as.integer(offence_group == "Theft offences")]
pfa[, drug := as.integer(offence_group == "Drug offences")]

# Placebo categories
pfa[, vehicle := as.integer(offence_subgroup == "Vehicle offences")]
pfa[, bike := as.integer(offence_subgroup == "Bicycle theft")]
pfa[, shoplifting := as.integer(offence_subgroup == "Shoplifting")]

## ---- Aggregate to force × financial year ----
panel <- pfa[, .(
  violent_crime = sum(n_offences[violent == 1], na.rm = TRUE),
  sexual_offences = sum(n_offences[sexual == 1], na.rm = TRUE),
  public_order = sum(n_offences[public_order == 1], na.rm = TRUE),
  criminal_damage = sum(n_offences[criminal_damage == 1], na.rm = TRUE),
  theft = sum(n_offences[theft == 1], na.rm = TRUE),
  drug = sum(n_offences[drug == 1], na.rm = TRUE),
  vehicle_crime = sum(n_offences[vehicle == 1], na.rm = TRUE),
  bike_theft = sum(n_offences[bike == 1], na.rm = TRUE),
  shoplifting = sum(n_offences[shoplifting == 1], na.rm = TRUE),
  total_crime = sum(n_offences, na.rm = TRUE)
), by = .(force, fy, fy_start)]

cat(sprintf("\nPanel: %d force × year observations\n", nrow(panel)))
cat(sprintf("Forces: %d, Years: %d\n", uniqueN(panel$force), uniqueN(panel$fy_start)))

## ---- Merge CIA treatment ----
panel[, treated := as.integer(force %in% cia_forces$force)]

# Treatment timing: April 2018 statutory strengthening
# Financial year 2018/19 is the first full post-treatment year
panel[, post := as.integer(fy_start >= 2018)]

# DiD
panel[, did := treated * post]

# Relative time
panel[, rel_year := fy_start - 2018L]

## ---- Log outcomes ----
for (v in c("violent_crime", "public_order", "total_crime", "vehicle_crime",
            "bike_theft", "shoplifting", "drug", "criminal_damage")) {
  panel[, paste0("log_", v) := log(get(v) + 1)]
}

## ---- Summary ----
cat("\n--- Treatment × period ---\n")
print(panel[, .N, by = .(treated, post)])

cat("\n--- Mean violent crime ---\n")
print(panel[, .(mean_violent = round(mean(violent_crime)),
                mean_total = round(mean(total_crime)),
                mean_vehicle = round(mean(vehicle_crime))),
           by = .(treated, post)])

cat("\n--- Treated vs control forces ---\n")
cat("Treated forces:", paste(sort(unique(panel[treated == 1, force])), collapse = ", "), "\n")
cat("\nControl forces:", paste(sort(unique(panel[treated == 0, force])), collapse = ", "), "\n")

## ---- Save ----
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat(sprintf("\nSaved analysis panel: %d observations\n", nrow(panel)))
