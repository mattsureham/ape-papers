# Human Initialization
Timestamp: 2026-03-26T14:18:00+01:00

## Launch Prompt
> "well, i think all the revisions turned it into an unreadable mess of a paper. like some junior person responding to every single senior professor comment in seminars, and every single referee complaining. Also, results became brittle. Overall, i would like you and Codex - who usually has great taste and is super smart so both of you should be able to produce a vision for the paper - to make a very ambitious revision. It needs a vision too. And the theory and structural estimation is apparently horrible. People have used Refine.ink on it and found so many errors. Maybe more and different data and analysis. Maybe throw out stuff that is not central to the paper, or push most of it to appendix. i leave it up to you. i just know that this paper sucks. and you have Codex need to collaborate like you never have before. End to end, for a v10."

## Contributor (Immutable)
**GitHub User:** @SocialCatalystLab

## System Information
- **Claude Model:** claude-opus-4-6

## Revision Information
**Parent Paper:** apep_0238
**Parent Title:** Demand Recessions Scar, Supply Recessions Don't: Evidence from State Labor Markets
**Parent Version:** v9
**Parent Decision:** MAJOR REVISION (user-initiated)
**Revision Rationale:** Complete rebuild. Kill structural model (J-test rejected, welfare ratio fragile). Reframe around duration/recall mechanism with new CPS microdata evidence. Single estimand replaces horizon-by-horizon forest. Rewrite prose from scratch. Co-authored with Codex via Duet.

## Key Changes Planned
1. Remove entire structural DMP model from main text
2. Add CPS microdata mechanism evidence (LTU share, temp layoffs, U→E flows)
3. Replace horizon-by-horizon estimand with single long-run regression
4. Switch primary outcome to prime-age EPOP
5. Rewrite all code in R (was Python)
6. Rewrite all prose from scratch (not patch v9)
7. Add duration-trap attenuation exercise as new empirical core

## Inherited from Parent
- Research question: why do demand recessions scar but supply recessions don't?
- Identification strategy: HPI (GR) + Bartik (COVID) cross-state exposure
- Primary data: BLS state-level labor market data via FRED
- Title: "Demand Recessions Scar, Supply Recessions Don't"
