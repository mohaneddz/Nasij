# YallaRent Source Register

This register tracks all external references used across Porter, Empathy Card, PESTEL, BMC, and Business Plan.

Legend for source tiers:
- `official`: government, multilateral, or statutory primary sources.
- `industry`: specialized research publishers and market intelligence reports.
- `company-primary`: first-party company websites or official product pages.

| ID | Metric / Claim | Value Used | Year / Period | Geography | Source Organization | URL | Access Date | Tier | Note |
|---|---|---:|---|---|---|---|---|---|---|
| <a id="s01"></a>S01 | Population, total | 46,814,308 | 2024 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/SP.POP.TOTL?format=json&mrv=1 | 2026-04-24 | official | Used for TAM sizing denominators. |
| <a id="s02"></a>S02 | GDP (current US$) | 269,322,281,664.77 | 2024 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/NY.GDP.MKTP.CD?format=json&mrv=1 | 2026-04-24 | official | Macro purchasing context. |
| <a id="s03"></a>S03 | GDP per capita (current US$) | 5,752.99 | 2024 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/NY.GDP.PCAP.CD?format=json&mrv=1 | 2026-04-24 | official | Affordability context in pricing strategy. |
| <a id="s04"></a>S04 | GDP growth (annual %) | 3.70% | 2024 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/NY.GDP.MKTP.KD.ZG?format=json&mrv=1 | 2026-04-24 | official | Macro trend context. |
| <a id="s05"></a>S05 | Unemployment, total (% labor force) | 11.633% | 2025 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/SL.UEM.TOTL.ZS?format=json&mrv=1 | 2026-04-24 | official | Demand pressure context. |
| <a id="s06"></a>S06 | Youth unemployment (15-24) | 29.444% | 2025 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/SL.UEM.1524.ZS?format=json&mrv=1 | 2026-04-24 | official | Core affordability signal for student segment. |
| <a id="s07"></a>S07 | Inflation, consumer prices (annual %) | 4.046% | 2024 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/FP.CPI.TOTL.ZG?format=json&mrv=1 | 2026-04-24 | official | Cost escalation assumptions. |
| <a id="s08"></a>S08 | Tertiary enrollment (gross) | 54.428% | 2024 | Algeria | World Bank (WDI API) | https://api.worldbank.org/v2/country/DZA/indicator/SE.TER.ENRR?format=json&mrv=1 | 2026-04-24 | official | Education participation benchmark. |
| <a id="s09"></a>S09 | Total enrolled students in universities | 1,530,230 | 2024/2025 | Algeria | MESRS (Ministry of Higher Education) | https://www.mesrs.dz/index.php/agregats-2024-2025-2/ | 2026-04-24 | official | Primary TAM base for university users. |
| <a id="s10"></a>S10 | Female student share | 938,673 (63%) | 2024/2025 | Algeria | MESRS (Ministry of Higher Education) | https://www.mesrs.dz/index.php/agregats-2024-2025-2/ | 2026-04-24 | official | Persona and inclusion context. |
| <a id="s11"></a>S11 | Students in natural & life sciences | 272,290 (18.2%) | 2024/2025 | Algeria | MESRS (Ministry of Higher Education) | https://www.mesrs.dz/index.php/agregats-2024-2025-2/ | 2026-04-24 | official | Segmenting living/lab-related demand patterns. |
| <a id="s12"></a>S12 | Higher education institutions in Algeria | 117 institutions | 2025 guide | Algeria | MESRS / CRUC guide (official publication) | https://cruc.univ-medea.dz/wp-content/uploads/2025/06/GUIDE_ENGLISH_VERSION.pdf | 2026-04-24 | official | Expansion map denominator. |
| <a id="s13"></a>S13 | International students trained | 65,000+ since 1962 | Cumulative | Algeria | MESRS / CRUC guide | https://cruc.univ-medea.dz/wp-content/uploads/2025/06/GUIDE_ENGLISH_VERSION.pdf | 2026-04-24 | official | Mobility and temporary-stay demand context. |
| <a id="s14"></a>S14 | Student housing capacity mention | 400,000+ accommodation capacity | Guide reference | Algeria | MESRS / CRUC guide | https://cruc.univ-medea.dz/wp-content/uploads/2025/06/GUIDE_ENGLISH_VERSION.pdf | 2026-04-24 | official | Supports campus logistics opportunity. |
| <a id="s15"></a>S15 | Cellular mobile connections | 54.8 million (116% of population) | Early 2025 | Algeria | DataReportal | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Digital access readiness for platform usage. |
| <a id="s16"></a>S16 | Internet users | 36.2 million (76.9% penetration) | Early 2025 | Algeria | DataReportal | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Online booking feasibility baseline. |
| <a id="s17"></a>S17 | Active social media user identities | 25.6 million (54.2% of population) | Jan 2025 | Algeria | DataReportal | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Social-led growth channel potential. |
| <a id="s18"></a>S18 | Median mobile download speed | 23.42 Mbps | Jan 2025 | Algeria | DataReportal (Ookla cited) | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Mobile UX constraints/opportunity. |
| <a id="s19"></a>S19 | Median fixed download speed | 15.05 Mbps | Jan 2025 | Algeria | DataReportal (Ookla cited) | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Back-office and dashboard UX context. |
| <a id="s20"></a>S20 | Mobile speed YoY change | +2.06 Mbps (+9.6%) | 12 months to Jan 2025 | Algeria | DataReportal (Ookla cited) | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Trend for improving mobile experience. |
| <a id="s21"></a>S21 | Fixed speed YoY change | +2.73 Mbps (+22.2%) | 12 months to Jan 2025 | Algeria | DataReportal (Ookla cited) | https://datareportal.com/reports/digital-2025-algeria | 2026-04-24 | industry | Trend for improving fixed connectivity. |
| <a id="s22"></a>S22 | Data protection law reference | Law No. 18-07 (10 June 2018) | 2018 | Algeria | Journal Officiel (JORADP) | https://www.joradp.dz/FTP/jo-francais/2018/F2018034.pdf | 2026-04-24 | official | Personal data obligations in legal analysis. |
| <a id="s23"></a>S23 | Consent basis for personal-data processing | Processing requires express consent, with legal exceptions | 2018 law text | Algeria | Journal Officiel (JORADP) | https://www.joradp.dz/FTP/jo-francais/2018/F2018034.pdf | 2026-04-24 | official | Used in legal constraints and onboarding design. |
| <a id="s24"></a>S24 | Startup label duration and renewal | 4 years, renewable once | Active policy page | Algeria | Startup.dz (official startup portal) | https://startup.dz/pour-obtenir-et-renouveler-label-startup/ | 2026-04-24 | official | Policy support for startup scaling assumptions. |
| <a id="s25"></a>S25 | Startup label legal basis mention | Decree No. 20-254 dated 15 Sep 2020 | Active policy page | Algeria | Startup.dz (official startup portal) | https://startup.dz/pour-obtenir-et-renouveler-label-startup/ | 2026-04-24 | official | Regulatory context for entity status. |
| <a id="s26"></a>S26 | Ouedkniss market existence | National classified ads platform (buy/sell/rent) | Current | Algeria | Ouedkniss | https://www.ouedkniss.com/?lang=en | 2026-04-24 | company-primary | Used as local substitute benchmark. |
| <a id="s27"></a>S27 | OpenSooq market existence | Office & study furniture listings in Algeria | Current | Algeria | OpenSooq | https://dz.opensooq.com/en/algeria/home-garden/office-furniture | 2026-04-24 | company-primary | Used as local substitute benchmark. |
| <a id="s28"></a>S28 | Dirleco positioning | Equipment and construction material rental platform in Algeria | Current | Algeria | Dirleco | https://dirleco.com/ | 2026-04-24 | company-primary | Confirms rental behavior in local market. |
| <a id="s29"></a>S29 | CORT student package entry point | Student package specials starting at $139 | Current page | US benchmark | CORT | https://www.cort.com/furniture-rental/furniture-packages/student | 2026-04-24 | company-primary | International benchmark for rental packaging. |
| <a id="s30"></a>S30 | CORT lease anchor | Packages start at $139/mo for 12-month leases | Current page | US benchmark | CORT | https://www.cort.com/furniture-rental/furniture-packages/student | 2026-04-24 | company-primary | Pricing benchmark for semester/annual packaging logic. |

## Notes on unavailable direct crawls

Some competitor pages used in earlier ideation are behind anti-bot layers from this environment (e.g., selected US rental pages). Where direct extraction failed, this implementation avoided relying on unverifiable numeric claims from those pages.
