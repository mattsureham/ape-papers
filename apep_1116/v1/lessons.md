## Discovery
- **Idea selected:** idea_2113 — Patent examiner twin study using continuation reassignment. Selected from random draw of 10 because examiner IV designs are explicitly praised in tournament lessons, and the within-family design is genuinely novel.
- **Data source:** USPTO PatEx via Google BigQuery — free-tier access confirmed, 9.8M applications. Minor schema discovery needed (string dates, 0/1 entity indicators).
- **Key risk:** "As-good-as-random" assignment assumption within art units. Balance tests show tiny but statistically significant correlations — enough to warrant cautious language but not to undermine the design.

## Execution
- **What worked:** BigQuery data pipeline was smooth — 3 queries produced all needed data. Within-family twin design delivered very clean results (F > 1,000 on leniency). 702K analysis pairs with 97.9K reassigned — massive statistical power.
- **What didn't:** Initial BigQuery project ID wrong (scl-librechat vs gen-lang-client), date fields were strings not dates, small_entity was 0/1 not YES/NO. Each required debugging.
- **Review feedback adopted:** Softened "holds invention quality fixed" to "holds invention family fixed" per GPT-5.4's valid criticism. Removed misleading "first-stage F" framing (this is OLS, not 2SLS). Restrained welfare extrapolation. Added explicit caveat about CON vs DIV differences.
- **Key insight for future:** Examiner/judge leniency designs with administrative data are powerful settings for APEP — massive N, clean institutional variation, portable mechanism framing ("regulatory lottery"). The twin study twist of comparing within the same invention family is a genuine methodological innovation that could extend to other adjudication settings.
