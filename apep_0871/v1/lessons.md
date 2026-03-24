## Discovery
- **Idea selected:** idea_0709 — EU NIS2 cybersecurity directive with sharp 50-employee threshold
- **Data source:** Eurostat ICT Security Survey (isoc_cisce_ra), triennial waves 2019/2022/2024. Clean API access via `eurostat` R package, no keys needed. 33 indicators, 27 countries.
- **Key risk:** Only 2 pre-treatment periods (triennial survey) and aggregate country × size-class data

## Execution
- **What worked:** The DDD exploiting transposition variation was the key innovation. The aggregate DiD null paired with the significant DDD told a clean story about enforcement mattering. Decomposing into compliance/technical/training categories added depth.
- **What didn't:** Wild cluster bootstrap failed (software issue with fwildclusterboot package). Pre-trend test split by transposer group revealed a concerning differential pre-trend in early transposers — an important caveat that required honest reporting.
- **Review feedback adopted:** Added pre-trend analysis split by transposer group, strengthened inference caveats about 27 clusters, clarified that the DDD enforcement interpretation is "suggestive rather than definitive."
