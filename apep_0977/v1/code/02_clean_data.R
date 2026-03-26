## 02_clean_data.R — Clean and classify products
## apep_0977: Korea-Japan boycott trade hysteresis

source("00_packages.R")

df_raw <- readRDS("../data/comtrade_raw.rds")
stopifnot("Raw data is empty" = nrow(df_raw) > 0)

## ── Parse period to date ───────────────────────────────────────────────────
df <- df_raw |>
  mutate(
    year  = as.integer(substr(period, 1, 4)),
    month = as.integer(substr(period, 5, 6)),
    date  = as.Date(paste0(period, "01"), format = "%Y%m%d"),
    ym    = year * 12 + month,  # Numeric year-month for event study
    dest  = ifelse(partner == "410", "Korea", "China"),
    hs2   = cmd_code
  ) |>
  filter(!is.na(trade_value), trade_value > 0)

## ── Product classification ─────────────────────────────────────────────────
## Consumer vs. Industrial based on BEC correspondence and product descriptions
## Consumer: products primarily purchased by households
## Industrial: intermediate/capital goods primarily used by firms

consumer_hs2 <- c(
  "02",  # Meat
  "03",  # Fish
  "04",  # Dairy, eggs, honey
  "06",  # Live plants, flowers
  "07",  # Vegetables
  "08",  # Fruits, nuts
  "09",  # Coffee, tea, spices
  "10",  # Cereals
  "11",  # Milling products
  "12",  # Oil seeds
  "15",  # Fats, oils
  "16",  # Prepared meat/fish
  "17",  # Sugar
  "18",  # Cocoa
  "19",  # Prepared cereals
  "20",  # Prepared vegetables/fruit
  "21",  # Miscellaneous food
  "22",  # Beverages (BEER — key boycott target)
  "24",  # Tobacco
  "33",  # Essential oils, cosmetics
  "34",  # Soap, washing preparations
  "42",  # Leather articles, handbags
  "43",  # Furskins
  "46",  # Straw/plaiting articles
  "49",  # Printed books, newspapers
  "57",  # Carpets
  "61",  # Knitted apparel
  "62",  # Woven apparel
  "63",  # Textile articles
  "64",  # Footwear
  "65",  # Headgear
  "66",  # Umbrellas
  "87",  # Vehicles (CARS — key boycott target)
  "91",  # Clocks, watches
  "92",  # Musical instruments
  "93",  # Arms, ammunition
  "94",  # Furniture, lighting
  "95",  # Toys, games, sports
  "96",  # Miscellaneous manufactured articles
  "97"   # Works of art
)

## Rauch (1999) classification: differentiated vs. reference-priced/homogeneous
## Differentiated goods have no close substitutes (brand matters)
## Homogeneous goods trade on organized exchanges or have reference prices
differentiated_hs2 <- c(
  "33",  # Cosmetics
  "42",  # Leather articles
  "61", "62",  # Apparel
  "64",  # Footwear
  "84",  # Machinery
  "85",  # Electrical machinery
  "87",  # Vehicles
  "88",  # Aircraft
  "90",  # Optical/medical instruments
  "91",  # Clocks
  "94",  # Furniture
  "95",  # Toys/games
  "96"   # Misc manufactured
)

## Visibility: publicly consumed (socially visible boycott signaling) vs. private
visible_hs2 <- c(
  "22",  # Beverages (drinking Japanese beer in public)
  "87",  # Vehicles (driving Japanese car)
  "62",  # Clothing (wearing Japanese brands)
  "64",  # Footwear
  "42",  # Handbags
  "91",  # Watches
  "95"   # Sporting goods
)

## ── Apply classifications ──────────────────────────────────────────────────
df <- df |>
  mutate(
    consumer      = as.integer(hs2 %in% consumer_hs2),
    industrial    = 1L - consumer,
    differentiated = as.integer(hs2 %in% differentiated_hs2),
    visible       = as.integer(hs2 %in% visible_hs2),
    korea         = as.integer(dest == "Korea"),
    post          = as.integer(date >= as.Date("2019-07-01")),
    # Event time relative to June 2019 (month 0 = Jul 2019)
    event_time    = ym - (2019 * 12 + 6),  # Relative to Jun 2019
    log_trade     = log(trade_value),
    # Product-destination ID for panel
    pd_id         = paste0(hs2, "_", dest),
    # Interaction terms
    treat_ddd     = consumer * korea * post
  )

## ── Summary statistics ─────────────────────────────────────────────────────
cat("=== Data Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(df)))
cat(sprintf("Products (HS2): %d\n", n_distinct(df$hs2)))
cat(sprintf("Consumer products: %d\n", n_distinct(df$hs2[df$consumer == 1])))
cat(sprintf("Industrial products: %d\n", n_distinct(df$hs2[df$industrial == 1])))
cat(sprintf("Months: %d\n", n_distinct(df$period)))
cat(sprintf("Date range: %s to %s\n", min(df$date), max(df$date)))

# Check key products
cat("\n=== Key Product Checks ===\n")
for (hs in c("22", "87", "33", "85")) {
  sub <- df |> filter(hs2 == hs)
  desc <- unique(sub$cmd_desc)[1]
  cat(sprintf("HS %s (%s): consumer=%d, differentiated=%d, visible=%d\n",
              hs, desc, unique(sub$consumer), unique(sub$differentiated),
              unique(sub$visible)))
}

## ── Pre/post means by group ────────────────────────────────────────────────
cat("\n=== Pre/Post Trade Values (Monthly Mean, $M) ===\n")
group_means <- df |>
  group_by(consumer, korea, post) |>
  summarize(
    mean_trade = mean(trade_value, na.rm = TRUE) / 1e6,
    n = n(),
    .groups = "drop"
  ) |>
  mutate(
    group = case_when(
      consumer == 1 & korea == 1 ~ "Consumer, Korea",
      consumer == 1 & korea == 0 ~ "Consumer, China",
      consumer == 0 & korea == 1 ~ "Industrial, Korea",
      consumer == 0 & korea == 0 ~ "Industrial, China"
    ),
    period_label = ifelse(post == 1, "Post", "Pre")
  )

print(group_means |> select(group, period_label, mean_trade, n) |> arrange(group, period_label))

## ── Save cleaned data ──────────────────────────────────────────────────────
saveRDS(df, "../data/analysis_panel.rds")
cat("\nSaved to data/analysis_panel.rds\n")
