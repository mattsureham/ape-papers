# Research Plan: When Scandals Go Dark

## Research Question
Does TV news coverage of federal agency scandals causally increase congressional oversight? If oversight attention depends on media visibility, then agency accountability is partially outsourced to cable news scheduling — creating a "scandal timing lottery" where agencies whose failures coincide with mega-events escape scrutiny.

## Identification Strategy
**Eisensee-Strömberg competing-news IV.** Major competing events (Olympics, impeachments, mass shootings, royal weddings) mechanically crowd out scandal coverage on cable news. These events are orthogonal to the timing and severity of agency failures — the Olympic schedule is set years before any specific scandal. We instrument scandal coverage with competing mega-event intensity.

- **Endogenous variable:** TV news mentions of agency + scandal terms (agency × month)
- **Instrument:** TV news coverage of pre-determined competing events (month level)
- **Exclusion restriction:** Mega-event timing affects oversight only through its displacement of scandal coverage. We test this by showing mega-events don't predict agency misconduct or whistleblower filings.

## Expected Effects
- **First stage:** Competing mega-events reduce agency-scandal coverage (negative)
- **Second stage (reduced form):** Less scandal coverage → fewer oversight hearings
- **Mechanism:** Media attention → public salience → congressional action
- **Heterogeneity:** Stronger effect for minority-party oversight (needs media leverage); weaker for Appropriations (mandatory calendar)

## Primary Specification
Panel: ~20 major federal agencies × 192 months (2009–2024)
$$\text{Hearings}_{at} = \beta \cdot \widehat{\text{ScandalCoverage}}_{at} + \gamma X_{at} + \alpha_a + \delta_t + \varepsilon_{at}$$

First stage:
$$\text{ScandalCoverage}_{at} = \pi \cdot \text{CompetingNews}_t + \gamma X_{at} + \alpha_a + \delta_t + u_{at}$$

Controls: agency budget (OMB), congressional session indicators, divided government, lagged hearings.
Clustering: agency level (conservative, ~20 clusters).

## Data Sources
1. **GovInfo API** (api.data.gov): Congressional hearings metadata — title, date, committee, chamber. Use REGS_GOV API key for higher rate limits.
2. **Internet Archive TV News** (archive.org): Closed caption text searchable by keyword. Build agency × month mention counts for ~20 agencies.
3. **Competing events list:** Olympics (Summer/Winter), presidential impeachments, major mass shootings, royal events — pre-determined dates from Wikipedia.
4. **OMB Historical Tables:** Agency budget authority for controls.

## Robustness
- Event studies around specific scandals (VA 2014, FAA Boeing 2019, Secret Service 2022)
- Placebo instruments (sporting events without real viewership displacement)
- Alternative clustering (Conley HAC, wild cluster bootstrap)
- GDELT BigQuery as alternative media source
