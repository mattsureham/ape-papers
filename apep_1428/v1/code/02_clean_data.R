## 02_clean_data.R
## apep_1428: Does Financial Parity Follow Legal Parity?
## Clean and harmonize 2018 + 2021 INE data; build DDD panel

source("code/00_packages.R")

## ── Helper: parse MXN currency strings ────────────────────────────────────
parse_mxn <- function(x) {
  x <- gsub("\\$|,|\"", "", as.character(x))
  x <- trimws(x)
  val <- suppressWarnings(as.numeric(x))
  ifelse(is.na(val), 0, val)
}

## ── Load 2021 data ─────────────────────────────────────────────────────────
cat("Loading 2021 data...\n")
raw21 <- read.csv("data/ine_2021_local.csv",
                  fileEncoding = "latin1",
                  stringsAsFactors = FALSE,
                  check.names = FALSE)
cat("  2021 raw rows:", nrow(raw21), "| cols:", ncol(raw21), "\n")

# Standardize column names
names(raw21) <- toupper(trimws(names(raw21)))

# Map 2021 columns
d21 <- raw21 %>%
  transmute(
    year            = 2021,
    state           = trimws(`ESTADO ELECCION`),
    office          = trimws(CARGO),
    party           = trimws(SIGLAS),
    candidate_name  = trimws(`NOMBRE COMPLETO`),
    female          = as.integer(trimws(SEXO) == "M"),
    # Income sources
    party_transfer  = parse_mxn(`TRANSFERENCIAS DE CONCENTRADORAS`),
    sympathizer     = parse_mxn(`APORTACIONES DE SIMPATIZANTES`),
    self_finance    = parse_mxn(`APORTACIONES DEL CANDIDATO`),
    public_funding  = parse_mxn(`FINANCIAMIENTO PÚBLICO`),
    total_income    = parse_mxn(`TOTAL INGRESOS`)
  )

## ── Load 2018 data ─────────────────────────────────────────────────────────
cat("Loading 2018 data...\n")
raw18 <- read.csv("data/ine_2018_local.csv",
                  fileEncoding = "latin1",
                  stringsAsFactors = FALSE,
                  check.names = FALSE)
cat("  2018 raw rows:", nrow(raw18), "| cols:", ncol(raw18), "\n")

names(raw18) <- toupper(trimws(names(raw18)))

# 2018 uses different column names for transfers
# "Transferencia de Recursos Federales" + "Transferencia de Recursos Locales"
# = equivalent to party headquarters transfers
d18 <- raw18 %>%
  transmute(
    year            = 2018,
    state           = trimws(`ENTIDAD FEDERATIVA`),
    office          = trimws(`CARGO DE ELECCIÓN`),
    party           = trimws(SIGLAS),
    candidate_name  = trimws(`NOMBRE COMPLETO`),
    female          = as.integer(trimws(SEXO) == "M"),
    # In 2018, party transfers = federal + local transfer resources
    party_transfer  = parse_mxn(`TRANSFERENCIA DE RECURSOS FEDERALES`) +
                      parse_mxn(`TRANSFERENCIA DE RECURSOS LOCALES`),
    sympathizer     = parse_mxn(`APORTACIONES DE SIMPATIZANTES`),
    self_finance    = parse_mxn(`APORTACIONES DE CANDIDATO`),
    public_funding  = parse_mxn(`FINANCIAMIENTO PÚBLICO`),
    total_income    = parse_mxn(`TOTAL INGRESOS`)
  )

## ── Harmonize office labels across years ───────────────────────────────────
# Mayor = PRESIDENTE MUNICIPAL or ALCALDE
harmonize_office <- function(x) {
  x <- toupper(trimws(x))
  case_when(
    grepl("PRESIDENTE MUNICIPAL|ALCALDE", x) ~ "MAYOR",
    grepl("DIPUTADO LOCAL", x)               ~ "LEGISLATOR",
    grepl("CONCEJAL|REGIDOR", x)             ~ "COUNCIL",
    grepl("SINDICO", x)                       ~ "SINDICO",
    grepl("GOBERNADOR", x)                    ~ "GOVERNOR",
    TRUE                                       ~ "OTHER"
  )
}

d21$office_type <- harmonize_office(d21$office)
d18$office_type <- harmonize_office(d18$office)

## ── Stack datasets ──────────────────────────────────────────────────────────
df <- bind_rows(d21, d18) %>%
  filter(office_type %in% c("MAYOR", "LEGISLATOR", "COUNCIL", "SINDICO")) %>%
  mutate(
    post = as.integer(year == 2021),
    is_mayor = as.integer(office_type == "MAYOR")
  )

cat("\nCombined dataset:\n")
cat("  Total rows:", nrow(df), "\n")
cat("  Year distribution:\n")
print(table(df$year))
cat("  Office type distribution:\n")
print(table(df$office_type))
cat("  Gender distribution:\n")
print(table(df$female, df$year))

## ── Create LONG format for income-source DDD ──────────────────────────────
# Each candidate appears 2 times: once for party_transfer, once for sympathizer
df_long <- df %>%
  select(year, state, office_type, party, candidate_name, female, post, is_mayor,
         party_transfer, sympathizer, self_finance) %>%
  pivot_longer(
    cols = c(party_transfer, sympathizer, self_finance),
    names_to = "income_source",
    values_to = "amount"
  ) %>%
  mutate(
    # Treatment indicator: party_transfer is the "treated" income source
    is_party_source = as.integer(income_source == "party_transfer"),
    # Log-transform with +1 to handle zeros
    log_amount = log(amount + 1),
    # Party × state fixed effect key
    party_state = paste0(party, "___", state)
  )

## ── Filter to MAYOR subsample for main analysis ────────────────────────────
df_mayor_long <- df_long %>%
  filter(office_type == "MAYOR")

cat("\nMayor long-format dataset:\n")
cat("  Rows:", nrow(df_mayor_long), "\n")
cat("  Candidates:", nrow(df) %>% {sum(df$office_type == "MAYOR")}, "\n")
cat("  Income sources:", paste(unique(df_mayor_long$income_source), collapse = ", "), "\n")

## ── Descriptive statistics ─────────────────────────────────────────────────
desc <- df %>%
  filter(office_type == "MAYOR") %>%
  group_by(year, female) %>%
  summarise(
    n = n(),
    party_transfer_mean = mean(party_transfer, na.rm = TRUE),
    sympathizer_mean = mean(sympathizer, na.rm = TRUE),
    self_finance_mean = mean(self_finance, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nDescriptive statistics (MAYOR only):\n")
print(desc)

## ── Save cleaned data ───────────────────────────────────────────────────────
saveRDS(df, "data/df_clean.rds")
saveRDS(df_long, "data/df_long.rds")
saveRDS(df_mayor_long, "data/df_mayor_long.rds")
saveRDS(desc, "data/df_descriptives.rds")

cat("\nData cleaning complete. Saved:\n")
cat("  data/df_clean.rds\n")
cat("  data/df_long.rds\n")
cat("  data/df_mayor_long.rds\n")
cat("  data/df_descriptives.rds\n")
