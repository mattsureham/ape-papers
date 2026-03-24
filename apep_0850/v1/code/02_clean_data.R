## 02_clean_data.R — apep_0850
## Construct analysis panel: sector bite classification + treatment variables

source("00_packages.R")

panel_fr <- readRDS("../data/panel_fr.rds")
panel_ti <- readRDS("../data/panel_ti.rds")
canton_names <- readRDS("../data/canton_names.rds")

cat("=== Constructing analysis panel ===\n")

# ---- Sector bite classification ----
# Based on 2018 Swiss Wage Structure Survey (LSE) estimates of share below CHF 23/hr
# Source: BFS, Table T17 (https://www.bfs.admin.ch/bfs/en/home/statistics/work-income/wages-income-employment-labour-costs/wage-levels-switzerland.html)
# High-bite sectors: >15% of workers estimated below CHF 23/hr
# Low-bite sectors: <5% of workers estimated below CHF 23/hr

high_bite_noga <- c(
  55,  # Accommodation (hotels) — ~35% below CHF 23
  56,  # Food and beverage service — ~38% below CHF 23
  47,  # Retail trade — ~22% below CHF 23
  96,  # Other personal services (hairdressing, laundry) — ~30% below CHF 23
  81,  # Building/landscape services — ~25% below CHF 23
  78,  # Employment activities (temp agencies) — ~20% below CHF 23
  93   # Sports/recreation — ~28% below CHF 23
)

low_bite_noga <- c(
  64,  # Financial services — ~3% below CHF 23
  65,  # Insurance — ~2% below CHF 23
  21,  # Pharmaceuticals — ~1% below CHF 23
  26,  # Electronics manufacturing — ~4% below CHF 23
  62,  # IT/programming — ~2% below CHF 23
  69,  # Legal/accounting — ~4% below CHF 23
  71,  # Architecture/engineering — ~3% below CHF 23
  72   # Scientific R&D — ~1% below CHF 23
)

# ---- Remove total row (NOGA = NA) and zero-count observations ----
panel_fr <- panel_fr[!is.na(noga) & cbw > 0]
panel_ti <- panel_ti[!is.na(noga) & cbw > 0]

cat(sprintf("After removing totals/zeros — FR panel: %s obs\n",
            format(nrow(panel_fr), big.mark = ",")))

# ---- Assign bite category ----
panel_fr[, bite := fcase(
  noga %in% high_bite_noga, "high",
  noga %in% low_bite_noga,  "low",
  default = "medium"
)]

panel_ti[, bite := fcase(
  noga %in% high_bite_noga, "high",
  noga %in% low_bite_noga,  "low",
  default = "medium"
)]

cat("\n=== Bite classification (FR panel, pre-treatment avg CBW) ===\n")
bite_summary <- panel_fr[year >= 2015 & year <= 2019,
                          .(sectors = uniqueN(noga),
                            mean_cbw = mean(cbw),
                            total_cbw = sum(cbw)),
                          by = bite]
print(bite_summary)

# ---- Treatment variables ----
# Geneva (canton 25): minimum wage CHF 23.27/hr effective November 1, 2020
# Treatment onset: Q4 2020 (Nov 2020)
# Ticino (canton 21): minimum wage CHF 19/hr effective April 2021 → Q2 2021

panel_fr[, `:=`(
  geneva     = as.integer(canton == 25),
  high_bite  = as.integer(bite == "high"),
  post       = as.integer(time_q >= 2020.75),  # Q4 2020 onward
  # DDD interaction
  treat_ddd  = as.integer(canton == 25 & bite == "high" & time_q >= 2020.75)
)]

# Canton-sector ID for FE
panel_fr[, canton_sector := paste0(canton, "_", noga)]
panel_fr[, sector_quarter := paste0(noga, "_", TIME_PERIOD)]
panel_fr[, canton_quarter := paste0(canton, "_", TIME_PERIOD)]

# Log outcome (add 1 to handle potential zeros after filtering)
panel_fr[, log_cbw := log(cbw + 1)]

# Time index (quarters since 2002-Q3)
panel_fr[, t := as.integer(factor(TIME_PERIOD))]

# Event time relative to Q4 2020 (treatment)
treatment_q <- panel_fr[TIME_PERIOD == "2020-Q4", unique(t)]
panel_fr[, event_time := t - treatment_q]

cat(sprintf("\nTreatment quarter index: t = %d (2020-Q4)\n", treatment_q))
cat(sprintf("Event time range: %d to %d\n", min(panel_fr$event_time), max(panel_fr$event_time)))

# ---- Ticino treatment variables ----
panel_ti[, `:=`(
  high_bite  = as.integer(bite == "high"),
  post       = as.integer(time_q >= 2021.25),  # Q2 2021 onward
  t          = as.integer(factor(TIME_PERIOD))
)]

# ---- Summary statistics ----
cat("\n=== Panel summary by canton ===\n")
canton_sum <- panel_fr[, .(
  n_sectors = uniqueN(noga),
  n_quarters = uniqueN(TIME_PERIOD),
  mean_cbw = round(mean(cbw), 1),
  total_obs = .N
), by = canton]
canton_sum <- merge(canton_sum, canton_names, by = "canton")
print(canton_sum)

cat("\n=== Pre-treatment parallel trends check (high vs low bite) ===\n")
# Average log CBW by bite × canton group, pre-treatment
pre_trends <- panel_fr[year >= 2015 & year <= 2019 & bite %in% c("high", "low"),
                        .(mean_log_cbw = mean(log_cbw)),
                        by = .(canton, bite, year)]
pre_wide <- dcast(pre_trends, canton + year ~ bite, value.var = "mean_log_cbw")
pre_wide[, gap := high - low]
cat("High-minus-low bite gap by canton, pre-treatment:\n")
print(dcast(pre_wide, canton ~ year, value.var = "gap"))

# ---- Save analysis-ready panels ----
saveRDS(panel_fr, "../data/analysis_panel_fr.rds")
saveRDS(panel_ti, "../data/analysis_panel_ti.rds")

# Also save bite classification for reference
bite_class <- data.table(
  noga = c(high_bite_noga, low_bite_noga),
  bite = c(rep("high", length(high_bite_noga)), rep("low", length(low_bite_noga)))
)
saveRDS(bite_class, "../data/bite_classification.rds")

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("Analysis panel (FR): %s obs\n", format(nrow(panel_fr), big.mark = ",")))
cat(sprintf("  Cantons: %d\n", uniqueN(panel_fr$canton)))
cat(sprintf("  Sectors: %d\n", uniqueN(panel_fr$noga)))
cat(sprintf("  Quarters: %d (%s to %s)\n",
            uniqueN(panel_fr$TIME_PERIOD),
            min(panel_fr$TIME_PERIOD), max(panel_fr$TIME_PERIOD)))
cat(sprintf("  High-bite obs: %s\n", format(sum(panel_fr$bite == "high"), big.mark = ",")))
cat(sprintf("  Low-bite obs: %s\n", format(sum(panel_fr$bite == "low"), big.mark = ",")))
