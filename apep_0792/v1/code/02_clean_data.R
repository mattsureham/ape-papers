## 02_clean_data.R — Construct analysis panel
source("00_packages.R")

cat("=== Cleaning Trade Data ===\n")

trade <- fread("../data/wits_trade.csv")

## Remove aggregate categories (keep only HS chapter groups)
## HS chapter groups have patterns like "01-05_Animal", "06-15_Vegetable"
## Aggregates: "Total", "AgrRaw", "Chemical", "Food", "Fuels", etc.
hs_sectors <- trade[grepl("^\\d+-\\d+_", sector)]
agg_sectors <- trade[!grepl("^\\d+-\\d+_", sector)]

cat("HS chapter groups:", uniqueN(hs_sectors$sector), "\n")
cat("Aggregate categories:", paste(unique(agg_sectors$sector), collapse=", "), "\n")

## Keep the 16 HS chapter groups
panel <- hs_sectors[, .(year, partner, partner_name, sector, export_value_1000usd)]

## Create sector-level panel: exports to Venezuela and to World
ven_exports <- panel[partner == "VEN", .(
  ven_exports = sum(export_value_1000usd, na.rm = TRUE)
), by = .(year, sector)]

world_exports <- panel[partner == "WLD", .(
  world_exports = sum(export_value_1000usd, na.rm = TRUE)
), by = .(year, sector)]

## Merge
sector_panel <- merge(world_exports, ven_exports, by = c("year", "sector"), all.x = TRUE)
sector_panel[is.na(ven_exports), ven_exports := 0]

## Compute Venezuela share of total exports
sector_panel[, ven_share := ven_exports / world_exports]
sector_panel[is.nan(ven_share) | is.infinite(ven_share), ven_share := 0]

## Non-Venezuela exports
sector_panel[, nonven_exports := world_exports - ven_exports]

## Pre-crisis average Venezuela share (2005-2008)
pre_shares <- sector_panel[year %in% 2005:2008, .(
  ven_share_pre = mean(ven_share, na.rm = TRUE),
  ven_exports_pre = mean(ven_exports, na.rm = TRUE),
  world_exports_pre = mean(world_exports, na.rm = TRUE)
), by = sector]

sector_panel <- merge(sector_panel, pre_shares, by = "sector")

## Post-crisis indicator (Venezuela collapse accelerated from 2009)
sector_panel[, post := as.integer(year >= 2009)]

## Log exports
sector_panel[, log_world := log(pmax(world_exports, 1))]
sector_panel[, log_nonven := log(pmax(nonven_exports, 1))]
sector_panel[, log_ven := log(pmax(ven_exports, 1))]

## Sector-level growth relative to 2008
sector_panel[, world_2008 := world_exports[year == 2008], by = sector]
sector_panel[, ven_2008 := ven_exports[year == 2008], by = sector]
sector_panel[, growth_world := world_exports / pmax(world_2008, 1)]
sector_panel[, growth_ven := ven_exports / pmax(ven_2008, 1)]

cat("\nSector panel:", nrow(sector_panel), "rows\n")
cat("Sectors:", uniqueN(sector_panel$sector), "\n")
cat("Year range:", range(sector_panel$year), "\n")

## Print pre-crisis Venezuela shares
cat("\nPre-crisis Venezuela shares by sector:\n")
print(pre_shares[order(-ven_share_pre)][, .(sector, ven_share_pre = round(ven_share_pre, 3),
  ven_exports_pre = round(ven_exports_pre))],
  nrows = 20)

## === Diversification panel: exports by partner ===
cat("\n=== Building diversification panel ===\n")

partners_panel <- panel[, .(exports = sum(export_value_1000usd, na.rm = TRUE)),
                        by = .(year, sector, partner_name)]

## Compute HHI of export destinations by sector-year
hhi_panel <- partners_panel[partner_name != "World", .(
  total = sum(exports, na.rm = TRUE),
  hhi = sum((exports / sum(exports))^2, na.rm = TRUE)
), by = .(year, sector)]

sector_panel <- merge(sector_panel, hhi_panel[, .(year, sector, dest_hhi = hhi)],
                      by = c("year", "sector"), all.x = TRUE)

## === World Bank macro panel ===
cat("\n=== Cleaning World Bank Data ===\n")

wb <- fread("../data/wb_macro.csv")
wb[, year := as.integer(date)]
wb[, value := as.numeric(value)]

## Pivot wide: one row per country-year
wb_wide <- dcast(wb, country_code + year ~ indicator_id, value.var = "value")

cat("WB panel:", nrow(wb_wide), "rows\n")
cat("Countries:", paste(unique(wb_wide$country_code), collapse = ", "), "\n")

## Save
fwrite(sector_panel, "../data/sector_panel.csv")
fwrite(wb_wide, "../data/wb_wide.csv")
fwrite(pre_shares, "../data/pre_shares.csv")

cat("\n=== Data cleaning complete ===\n")
