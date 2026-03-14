# Research Plan: Smoke-Free Europe and the Hospitality Jobs Myth

## Research Question

Did comprehensive workplace smoking bans destroy hospitality jobs, as industry lobbies predicted? 18 European countries adopted bans between 2004 and 2019, creating a staggered natural experiment.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD.** Treatment = year of comprehensive workplace smoking ban. 18 treated countries, remaining EU/EEA as never-treated controls. Outcome = hospitality sector (NACE I) employment from Eurostat national accounts.

## Exposure Alignment

Treatment is at the country level (national smoking ban legislation). Outcome is measured at the same country level (national accounts employment by sector). The economic margin is direct: smoking bans apply in hospitality venues, and the outcome measures employment in exactly those venues.

## Expected Effects

The industry lobby predicted massive job losses. The economic literature on smoking bans in individual countries (Ireland, Italy) generally finds null or small positive effects. We expect a precisely estimated null — bans did not destroy hospitality jobs.

## Key Placebo

Non-hospitality sectors (NACE J: Information/Communication, NACE K: Finance, NACE M: Professional) should show no effect. This placebo-sector design strengthens identification.

## Data

Eurostat `nama_10_a64_e`: Employment by NACE A*64 sector, 42 countries, 1975-2025. Free REST API, confirmed in smoke test (1,249 data points).
