# ============================================================
# 02_clean_data.R — Clean and construct analysis panel
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

source("00_packages.R")

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Load raw data
# ----------------------------------------------------------
cat("=== Loading raw data ===\n")
retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"),
                   showProgress = FALSE)
ea_dates <- readRDS(file.path(data_dir, "ea_expiration_dates.rds"))

cat("  Raw retailers:", format(nrow(retailers), big.mark = ","), "\n")

# ----------------------------------------------------------
# 2. Clean retailer data
# ----------------------------------------------------------
cat("\n=== Cleaning retailer data ===\n")

# Standardize column names
setnames(retailers, gsub(" ", "_", names(retailers)))

# Parse dates
retailers[, auth_date := as.Date(Authorization_Date, format = "%m/%d/%Y")]
retailers[, end_date := as.Date(End_Date, format = "%m/%d/%Y")]

# If those formats don't work, try alternatives
if (sum(is.na(retailers$auth_date)) > nrow(retailers) * 0.5) {
  cat("  Trying alternative date formats...\n")
  retailers[, auth_date := as.Date(Authorization_Date)]
  retailers[, end_date := as.Date(End_Date)]
}

cat("  Auth dates parsed:", sum(!is.na(retailers$auth_date)),
    "/", nrow(retailers), "\n")
cat("  End dates (exits):", sum(!is.na(retailers$end_date)),
    "/", nrow(retailers), "\n")

# Create exit indicator and quarter
retailers[, exited := !is.na(end_date)]
retailers[, exit_year := year(end_date)]
retailers[, exit_quarter := quarter(end_date)]
retailers[, exit_yearqtr := ifelse(exited,
                                    paste0(exit_year, "Q", exit_quarter),
                                    NA_character_)]
retailers[, exit_month := floor_date(end_date, "month")]

# Authorization timing
retailers[, auth_year := year(auth_date)]
retailers[, auth_month := floor_date(auth_date, "month")]

# Simplify store type categories
retailers[, store_cat := fcase(
  Store_Type %in% c("Convenience Store"), "convenience",
  Store_Type %in% c("Small Grocery Store"), "small_grocery",
  Store_Type %in% c("Medium Grocery Store"), "medium_grocery",
  Store_Type %in% c("Large Grocery Store", "Supermarket", "Super Store"), "supermarket",
  Store_Type %in% c("Combination Grocery/Other"), "combo",
  default = "other"
)]

cat("  Store categories:\n")
print(table(retailers$store_cat))

# State standardization
retailers[, state := State]

# ----------------------------------------------------------
# 3. Construct state × quarter panel
# ----------------------------------------------------------
cat("\n=== Constructing state-quarter panel ===\n")

# Define analysis window: 2019Q1 to 2024Q4
quarters <- data.table(
  yearqtr = paste0(rep(2019:2024, each = 4), "Q", rep(1:4, 6))
)
quarters[, year := as.integer(substr(yearqtr, 1, 4))]
quarters[, qtr := as.integer(substr(yearqtr, 6, 6))]
quarters[, qtr_date := as.Date(paste0(year, "-", (qtr - 1) * 3 + 1, "-01"))]
quarters[, time_id := .I]

# For each state × quarter, count:
# (a) authorized stores at start of quarter
# (b) exits during that quarter
# (c) new authorizations during that quarter

states <- unique(ea_dates$state_abbr)

# Filter to relevant states
retailers_us <- retailers[state %in% states]

cat("  Retailers in analysis states:", format(nrow(retailers_us), big.mark = ","), "\n")

# Build panel: for each quarter, how many stores were active and how many exited
panel_list <- list()

for (i in seq_len(nrow(quarters))) {
  q_start <- quarters$qtr_date[i]
  q_end <- q_start %m+% months(3) - 1  # End of quarter

  for (s in states) {
    state_stores <- retailers_us[state == s]

    # Active at start of quarter: authorized before quarter start, not exited before quarter start
    active <- state_stores[auth_date <= q_start &
                             (is.na(end_date) | end_date >= q_start)]

    # Exits during quarter
    exits <- state_stores[exited == TRUE & end_date >= q_start & end_date <= q_end]

    # By store category
    for (cat_name in c("convenience", "small_grocery", "supermarket", "other_snap")) {
      if (cat_name == "other_snap") {
        active_cat <- active[!store_cat %in% c("convenience", "small_grocery", "supermarket")]
        exits_cat <- exits[!store_cat %in% c("convenience", "small_grocery", "supermarket")]
      } else {
        active_cat <- active[store_cat == cat_name]
        exits_cat <- exits[store_cat == cat_name]
      }

      panel_list[[length(panel_list) + 1]] <- data.table(
        state = s,
        yearqtr = quarters$yearqtr[i],
        time_id = quarters$time_id[i],
        qtr_date = q_start,
        store_type = cat_name,
        n_active = nrow(active_cat),
        n_exits = nrow(exits_cat)
      )
    }
  }

  if (i %% 4 == 0) cat("  Processed quarter", quarters$yearqtr[i], "\n")
}

panel <- rbindlist(panel_list)

# Exit rate per 1,000 stores
panel[, exit_rate := ifelse(n_active > 0, (n_exits / n_active) * 1000, NA_real_)]

cat("  Panel dimensions:", nrow(panel), "rows\n")
cat("  States:", length(unique(panel$state)), "\n")
cat("  Quarters:", length(unique(panel$yearqtr)), "\n")
cat("  Store types:", paste(unique(panel$store_type), collapse = ", "), "\n")

# ----------------------------------------------------------
# 4. Merge treatment timing
# ----------------------------------------------------------
cat("\n=== Merging EA expiration treatment ===\n")

# Convert EA dates to quarter
ea_dates$ea_expire_qtr <- paste0(
  year(ea_dates$ea_last_month + months(1)), "Q",
  quarter(ea_dates$ea_last_month + months(1))
)
# The treatment quarter is the first quarter WITHOUT EA
# (i.e., the quarter after the last month EA was issued)

ea_dates$ea_expire_date <- floor_date(ea_dates$ea_last_month + months(1), "quarter")

# Map to time_id
ea_treat <- merge(
  as.data.table(ea_dates),
  quarters[, .(yearqtr, time_id, qtr_date)],
  by.x = "ea_expire_qtr", by.y = "yearqtr",
  all.x = TRUE
)

# Rename for clarity
setnames(ea_treat, c("time_id", "qtr_date"),
         c("treat_time_id", "treat_qtr_date"))

# Merge into panel
panel <- merge(panel, ea_treat[, .(state_abbr, ea_last_month, early_optout,
                                    ea_expire_qtr, treat_time_id)],
               by.x = "state", by.y = "state_abbr",
               all.x = TRUE)

# Treatment indicator: 1 if current quarter >= treatment quarter
panel[, treated := as.integer(time_id >= treat_time_id)]
panel[is.na(treated), treated := 0L]

# Group variable for CS: first treatment quarter (0 for never-treated, but all are treated)
panel[, first_treat := treat_time_id]

cat("  Treatment timing:\n")
print(table(panel[store_type == "convenience",
                  .(ea_expire_qtr, early_optout)][, .N, by = .(ea_expire_qtr, early_optout)]))

# ----------------------------------------------------------
# 5. Create aggregate panel (all SNAP stores)
# ----------------------------------------------------------
cat("\n=== Creating aggregate panel ===\n")

agg_panel <- panel[, .(
  n_active = sum(n_active),
  n_exits = sum(n_exits)
), by = .(state, yearqtr, time_id, qtr_date, ea_last_month, early_optout,
          ea_expire_qtr, treat_time_id, treated, first_treat)]

agg_panel[, exit_rate := ifelse(n_active > 0, (n_exits / n_active) * 1000, NA_real_)]

# ----------------------------------------------------------
# 6. Summary statistics
# ----------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# Pre-treatment means
pre_treat <- panel[treated == 0 & store_type == "convenience"]
cat("  Pre-treatment convenience store exit rate (mean):",
    round(mean(pre_treat$exit_rate, na.rm = TRUE), 2), "per 1,000\n")
cat("  Pre-treatment convenience store exit rate (sd):",
    round(sd(pre_treat$exit_rate, na.rm = TRUE), 2), "\n")

# By opt-out status
cat("\n  Pre-treatment exit rates by opt-out status:\n")
cat("  Early opt-out:",
    round(mean(pre_treat[early_optout == TRUE]$exit_rate, na.rm = TRUE), 2), "\n")
cat("  Non-opt-out:",
    round(mean(pre_treat[early_optout == FALSE]$exit_rate, na.rm = TRUE), 2), "\n")

# ----------------------------------------------------------
# 7. Save analysis datasets
# ----------------------------------------------------------
cat("\n=== Saving analysis datasets ===\n")

saveRDS(panel, file.path(data_dir, "panel_by_type.rds"))
saveRDS(agg_panel, file.path(data_dir, "panel_aggregate.rds"))
saveRDS(quarters, file.path(data_dir, "quarters.rds"))

cat("  Saved panel_by_type.rds:", nrow(panel), "rows\n")
cat("  Saved panel_aggregate.rds:", nrow(agg_panel), "rows\n")

cat("\n=== Cleaning complete ===\n")
