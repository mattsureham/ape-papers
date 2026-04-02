## Discovery
- **Idea selected:** idea_2052 — WWII airfields as IV for airport access → manufacturing. Selected after multiple overlap rejections (vaping ban, Korea boycott, OSHA heat, FEMA delays all had >50% overlap with existing papers).
- **Data source:** Wikipedia (WWII airfields), OurAirports (current airports), Census CBP (employment), Census ACS (population). BTS T-100 freight data was unavailable (form-locked, no API).
- **Key risk:** Exclusion restriction — WWII airfields brought military spending, not just airports.

## Execution
- **What worked:** Wikipedia category-based scraping with MediaWiki API for coordinates was reliable (729 airfields, 45 states). Census CBP API clean. First stage very strong (F=73).
- **What didn't:** BTS T-100 freight data behind login form — forced pivot from freight tonnage to airport presence as treatment. Wikipedia's first scraping attempt (HTML table parsing) only got 5 states; needed to switch to category-level API approach.
- **Review feedback adopted:** Acknowledged BTS data limitation explicitly in intro. Added Wikipedia selection bias caveat. Expanded exclusion restriction discussion to acknowledge non-airport military channels. Tempered conclusion from "airports don't attract factories" to LATE-appropriate caveats about complier geography and generalizability.
