# **AEGISLIFE INSURANCE: RISK ANALYTICS AND CLAIMS INTELLIGENCE**

### **Excel · MySQL · Python · Power BI | Loss ratio, claims leakage, fraud signals, agent performance and customer value**


<img width="2400" height="1350" alt="image" src="https://github.com/user-attachments/assets/48f03e42-d94e-489d-822d-269a04fe1441" />


---

## **Project Overview**

AegisLife Insurance Pvt. Ltd. is a Mumbai-based life and general insurer growing policy issuance about 35% a year. Management faces three problems: **high claim ratios**, **possible anomalies and fraud in claims data**, and **no unified dashboard** for decision-makers. This capstone builds the full analytics workflow to diagnose them: data cleaning in Excel, relational analysis in MySQL, statistical testing and modelling in Python, and an executive dashboard in Power BI.

| Dataset (sample provided) | Records |
|---|---|
| Customers | **1,648** |
| Policies (Term, Whole, Health, Vehicle, Property) | **2,828** |
| Claims (2020 to mid-2025) | **1,406** |
| Agents (6 regions) | **300** |
| Customer feedback surveys | **1,000** |

All amounts are in INR (as stated in the project brief). The business context mentions 2M+ customers; the files provided are a sample.

---

## **Project Workflow**

| Stage | Tool | What was done | Output |
|---|---|---|---|
| **1. Clean and validate** | **Excel** | Profiled the 5 raw tables, built a Cleaning Log, fixed typos (for example "mal", "wset", "Rejeted"), standardised dates, flagged orphan keys and claims above cover (not deleted), built pivots and insight sheets | Cleaned CSVs, `AegisLife_Analysis.xlsx` |
| **2. Model and query** | **MySQL** | Designed the schema with primary and foreign keys, loaded the cleaned data, built the reusable view `vw_policy_master`, wrote 11 analysis queries (risk, pricing, lapse, fraud, leakage, processing time, agents, satisfaction, profitability, CLV) | `01_schema_and_load.sql`, `02_analysis_queries.sql` |
| **3. Analyse and model** | **Python** | Connected to MySQL (SQLAlchemy, PyMySQL), cleaned and normalised, ran EDA and hypothesis tests, built churn and fraud models, scored policies by risk tier, calculated customer lifetime value | `AegisLife.ipynb`, `policy_scores.csv`, `customer_clv.csv`, `risk_tier_summary.csv` |
| **4. Visualise** | **Power BI** | Built a 6-relationship data model with 13 DAX measures and a 3-page interactive dashboard (Executive, Regional, Risk-Claim-Fraud) | `capstone project.pbix` |

---

## **KPI Framework**

| KPI | Definition | Value |
|---|---|---|
| Total claims | Count of claims | **1,406** |
| Average claim amount | Mean claimed amount | **252,932** |
| Claim approval rate | Approved / all claims | **35.8%** (504 approved, 448 rejected, 454 pending) |
| Claim frequency | Claims per policy | **0.497** |
| Loss ratio (dashboard) | Approved claims / annual premium | **168.8%** (127.4M / 75.5M) |
| Loss ratio (earned basis) | Approved claims / annual premium x years in force | **130.9%** (127.4M / 97.3M) |
| Fraud-flag ratio | Fraud-flagged / all claims | **49.0%** |
| Policy lapse rate | Lapsed or cancelled / all policies | **65.7%** |
| Avg processing time | Mean days to process | **31.2 days** (24.3% take more than 45) |
| Agent lapse rate | Agent lapsed / policies sold | **14.9%** (agent table) |

---

## **10 Business Questions and Reports**

### **Q1. Is AegisLife profitable?**
- **Finding:** No. Approved claims total **127.4M** against **75.5M** of annual premium, a loss ratio of **168.8%**. Measured against premium earned over the time policies were in force (97.3M), the loss ratio is **130.9%**. Either way, the book pays out more than it collects. Only **35.8%** of claims are approved; **32.3%** are still pending.
- **Report:** The headline 169% overstates the loss because annual premium ignores multi-year cover (average policy life is 1.28 years). The earned-basis 131% is the fairer figure, and it is still a loss.

### **Q2. Where are the losses concentrated by region and product?**
- **Finding:** **26 of 30** region-product cells run above a 100% loss ratio. Worst: **East / Vehicle 250%**, **North / Whole 245%**, **South / Whole 241%**, South / Property 233%. Only four cells are below 100%: North-East / Property **58%**, North-East / Whole **83%**, North / Property **89%** and West / Vehicle **97%**. By region, South is worst (**207%**) and North-East best (**124%**). By product, Health is worst (**189%**) and Property best (**146%**).
- **Report:** Loss is widespread, not limited to one product or region. Cells hold only 30 to 60 claims each, so single-cell rankings should be treated as flags for review rather than conclusions.

### **Q3. How are claims trending over time?**
- **Finding:** Claims grew from **16** (2020, partial) to **114** (2021), **237** (2022), **437** (2023) and **540** (2024); approved claim value rose from 3.6M to **53.6M** over the same years. There is **no significant seasonality** across months (chi-square p = 0.29). Volumes fall in Q4 2024 (88) and 2025 (62, data to June).
- **Report:** Claims grew in step with the policy book, so volume growth alone does not explain the loss. The late decline may reflect the data cut-off and unresolved pending claims and should be confirmed before it is read as improvement.

### **Q4. Is the fraud flag reliable?**
- **Finding:** **49.0%** of claims carry a fraud flag. The flag shows **no relationship** with claim status (chi-square p = 0.86), claim amount (p = 0.49) or claim type (p = 0.16). **248 flagged claims worth 61.5M** were still approved, **48.3%** of all approved value. A fraud-prediction model scores an AUC of about 0.5 (no better than chance).
- **Report:** A flag on nearly half of all claims cannot guide investigations, and it does not change approval decisions. Its definition needs to be validated with the business before it is used.

### **Q5. Do smokers cost more to insure?**
- **Finding:** Claim cost per policy is **134,016 for smokers vs 117,521 for non-smokers** (**+14.0%**, 95% CI +1.8K to +31.2K, Welch p = **0.028**). The loss ratio is **186.5%** vs **151.1%**. Per individual claim the gap is smaller and borderline (259,747 vs 245,615, p = 0.060), and claim incidence is similar (41.1% vs 38.8%, p = 0.23). Pre-existing illness shows no effect (p = 0.62).
- **Report:** There is moderate evidence that smokers cost more, driven by total cost per policy rather than claim size. It supports smoking status as a rating factor, but the Mann-Whitney test (p = 0.082) shows the result is not robust.

### **Q6. Is pricing aligned with risk?**
- **Finding:** Average premium is **flat across risk bands**: 27.6K (Low), 26.4K (Medium), 26.3K (High); ANOVA p = 0.12. Loss ratios rise from **150% to 168% to 188%** (relativity 0.89, 1.00, 1.12), but claim cost per policy does **not** differ significantly by band (ANOVA p = 0.46), and risk score has **no correlation with claim amount** (r = -0.016, p = 0.56). Lapse rises from 63.0% to 69.1% (p = 0.0498).
- **Report:** Price ignores risk, but the risk score itself does not predict claim cost in this dataset. The score should be re-validated before it is used to reprice.

### **Q7. Do claims differ by region, product, age or claim type?**
- **Finding:** No. Average claim amount is about **243K to 265K everywhere**: region (ANOVA p = 0.58), product (p = 0.37), age band (p = 0.66) and claim type (p = 0.61). Claim status is independent of claim type (chi-square p = 0.62). Approval rate ranges from **31.2%** (North-East) to **39.1%** (North).
- **Report:** Claim size cannot be explained by customer profile, so claim-size controls should be company-wide rather than segment-specific.

### **Q8. How efficient is claims processing?**
- **Finding:** Average **31.2 days** (median 32, maximum 59); **24.3%** of claims take more than 45 days. Processing time does not differ by status (p = 0.61) or claim type (p = 0.83). **454 claims (32.3%) are pending, worth 117.6M**, and **134 of them were filed in 2020 to 2022**.
- **Report:** A pending backlog this old points to an unmanaged queue rather than normal processing time. A 45-day service target and an ageing report for pending claims are priorities.

### **Q9. Which agents and tiers underperform?**
- **Finding:** Average agent lapse rate is **14.9%**. The **10 highest-lapse agents lose 29.1%** of policies (AGT5190, AGT5154, AGT5168, AGT5264 and AGT5079 lead). Lapse does not differ by agent tier (Gold 14.7%, Silver 15.3%, Bronze 14.4%; p = 0.77), region (p = 0.80) or volume sold (r = 0.02). The hypothesis that **West agents have higher fraud association than average is not supported** (3.51% vs 3.33%, p = 0.70; regional ANOVA p = 0.29).
- **Report:** Underperformance sits with specific individuals, not tiers or regions, so targeted audits beat blanket training. Agent fraud ratio looks higher for Bronze agents (5.7% vs 1.6% for Gold), but this is largely because the same kind of count is divided by fewer policies sold, so use fraud counts alongside the ratio.

### **Q10. Who creates and destroys customer value, and how do customers feel?**
- **Finding:** The **lowest-value quartile (412 customers) generates 98.0% of approved claims** (CLV **-99.6M**), while the top quartile adds **+48.0M**. **75.1% of customers (1,238)** have no approved claim. The **worst 100 customers** account for **57.9M of claims against 5.4M of premium**; without them the book runs at about **98% (annual basis)**. Customer satisfaction averages **3.22 / 5**: claim waiting (**1.47**), documentation requests (**1.96**), premium (**2.05**) and coverage clarity (**2.20**) score worst, against **4.46 to 4.60** for agents, service and the claim experience (ANOVA p < 0.001).
- **Report:** Profit and loss are concentrated in a small group, and service pain is concentrated in claims handling, not in agents. 36.9% of feedback comes from customers not in the master table (anonymous feedback, kept in the analysis).

---

## **Dashboard Preview**

> **How to add your dashboard screenshots:** open `capstone project.pbix` in Power BI Desktop, go to each report page and take a screenshot (or *File > Export > Export to PDF*). Save the three images into `images/dashboard/` using the exact names below and they will appear on GitHub once pushed. The screenshots in the `Evidence` folder of this project show the Python notebook, not the Power BI pages.

### **Page 1: Executive Dashboard**


<img width="1329" height="742" alt="Screenshot 2026-11-07 120240" src="https://github.com/user-attachments/assets/b2c5ef82-5e3f-4401-ad3d-e25463cc59a9" />



 **Visuals: KPI cards, monthly claims area chart, product donut, agent fraud-ratio bar. Filters: region, product, claim status, claim type, agent, risk band, year.**


| Total claims | Avg claim | Approval rate | Fraud ratio | Loss ratio | Agent fraud ratio |
|---|---|---|---|---|---|
| 1,406 | 252,932 | 35.8% | 49.0% | 168.8% | 2.6% |


**Business insight:** Approved claims of **127.4M** exceed annual premium of **75.5M** (loss ratio **168.8%**; 130.9% on earned premium). Claims are spread almost evenly across products (Health 314, Property 285, Vehicle 282, Whole 263, Term 262), with premium also near-equal at 19% to 21% each, so no single product explains the loss. Monthly claims climb from 16 in 2020 to a 2024 peak (540 for the year).


**Statistical insight:** Month-to-month volume shows no significant seasonality (chi-square p = 0.29). The fraud flag (49.0%) is statistically unrelated to claim status (p = 0.86), amount (p = 0.49) or claim type (p = 0.16). Weighted agent fraud ratio is 2.6% (mean 3.3%, maximum 16.0%).

----

### **Page 2: Regional Dashboard**



<img width="1324" height="741" alt="Screenshot 2026-11-07 120126" src="https://github.com/user-attachments/assets/3de5ffae-6e73-4748-a54f-a16e88531256" />



 **Visuals: KPI cards, loss ratio by region, region x product matrix, lapse rate by agent and region, agent tier columns, CLV segment columns, customer table.**


| Lapse rate | Total premium | Claim frequency | Loss ratio | Worst region | Best region |
|---|---|---|---|---|---|
| 65.7% | 75.5M | 0.497 | 168.8% | South 207% | North-East 124% |


**Business insight:** South has the highest loss ratio (**207%**) and North-East the lowest (**124%**). In the region x product matrix, **26 of 30 cells** exceed 100%, led by East / Vehicle (**250%**) and North / Whole (**245%**). Claim frequency ranges from **0.44** (North-East) to **0.53** (South). The ten highest-lapse agents lose **29.1%** of policies against 14.9% on average.


**Statistical insight:** Claim amount does not differ by region (ANOVA p = 0.58; Kruskal-Wallis p = 0.58), and lapse does not differ by agent region (p = 0.80) or tier (p = 0.77). Regional loss-ratio gaps are therefore not driven by claim size, which is uniform everywhere. Cells hold 30 to 60 claims, so treat rankings as review flags.

----

### **Page 3: Risk, Claim and Fraud**


<img width="1330" height="737" alt="Screenshot 2026-11-07 120159" src="https://github.com/user-attachments/assets/b8dd554f-27d3-4194-b8b5-3233c15e79ab" />



 **Visuals: processing days and approved-paid cards, fraud ratio by claim type, processing days by status, risk-band donut, agent fraud and lapse table, net customer value table.**


| Approved paid | Avg processing days | Fraud ratio | Claim frequency | Approval rate |
|---|---|---|---|---|
| 127.4M | 31.2 | 49.0% | 0.497 | 35.8% |


**Business insight:** Fraud flags run from **44.8%** (Theft) to **55.1%** (Death) across claim types. Claims split by customer risk band as Medium 734, High 361, Low 311. **89 approved claims** paid above policy cover, **12.4M** over the limit, and **248 flagged claims (61.5M)** were approved. The lowest-value quartile of customers (412) carries **98.0%** of approved claims.


**Statistical insight:** Fraud differences by claim type are not significant (chi-square p = 0.16). Processing time is flat across approved (30.8 days), rejected (31.0) and pending (31.8) claims (ANOVA p = 0.61). Risk score has no correlation with claim amount (r = -0.016), while loss ratio per risk band is 150%, 168% and 188%.

---

## **Statistical Testing Summary**

| Test | Question | Result | Conclusion |
|---|---|---|---|
| Welch t-test | Smoker vs non-smoker claim cost per policy | 134,016 vs 117,521; p = 0.028 | Smokers cost more (+14%), moderate evidence |
| Welch t-test | Smoker vs non-smoker amount per claim | 259,747 vs 245,615; p = 0.060 | Borderline, not significant |
| Chi-square | Claim incidence, smoker vs non-smoker | 41.1% vs 38.8%; p = 0.23 | No difference |
| ANOVA | Claim amount by region / product / age / type | p = 0.58 / 0.37 / 0.66 / 0.61 | No differences |
| Chi-square | Claim status vs claim type | chi2 = 6.28; p = 0.62 | Independent |
| Chi-square | Fraud flag vs claim status | p = 0.86 | Flag does not affect decisions |
| Pearson / Spearman | Risk score vs claim amount | r = -0.016 (p = 0.56) | No relationship |
| ANOVA | Premium by risk band | p = 0.12 | Premium is flat across risk |
| ANOVA | Claim cost per policy by risk band | p = 0.46 | Loss-ratio gap not significant |
| t-test / ANOVA | West agents' fraud ratio vs national | 3.51% vs 3.33%; p = 0.70 | Hypothesis not supported |
| ANOVA | Agent lapse by tier | p = 0.77 | No tier effect |
| Models | Churn / fraud prediction | AUC about 0.47 to 0.52 | No better than chance |

---

## **Key Takeaways**

1. **The book loses money on any basis.** Loss ratio is 168.8% on annual premium and 130.9% on earned premium.
2. **Losses come from a few customers.** The lowest-value 25% generate 98.0% of approved claims; the worst 100 customers cost 57.9M against 5.4M of premium.
3. **Loss is broad across products and regions.** 26 of 30 region-product cells are above 100%.
4. **Claims leak.** 89 approved claims exceeded cover by 12.4M, and 248 fraud-flagged claims (61.5M) were approved.
5. **The fraud flag is not usable.** It is set on 49% of claims and is unrelated to outcome, amount or type.
6. **Price ignores risk, but the risk score is weak.** Premium is flat while loss ratio rises 150% to 188%, yet the score does not predict claim cost.
7. **Claims handling is the pain point.** Satisfaction on claim waiting is 1.47 / 5, a third of claims are pending, and 134 pending claims date from 2020 to 2022.

## **Business Recommendations**

*Impact estimates use the dashboard's annual-premium basis and are scenarios, not forecasts.*

| Insight | Recommended action | Estimated impact |
|---|---|---|
| 89 approved claims paid above cover (12.4M) | Cap approved payouts at the policy cover amount with an automatic system check | Loss ratio -16 points (169% to about 152%) |
| 248 flagged claims (61.5M) approved; flag set on 49% of claims | Review the approved flagged claims and rebuild the fraud flag with the business | Each 10% recovered = about -8 points |
| Premium is flat while loss ratio rises with risk band; smokers cost 14% more | Add smoking status as a rating factor and re-validate the risk score before repricing | +10% premium = about -15 points |
| 100 customers cost 57.9M against 5.4M of premium | Re-underwrite or reprice the worst 100 customers | Book runs near break-even (about 98%) without them |
| 454 pending claims (134 older than 3 years); claim delay scores 1.47 / 5 | Set a 45-day SLA on claim decisions and an ageing report for pending claims | Improves satisfaction and clears 117.6M of open claims |
| 10 agents lose 29.1% of policies vs 14.9% average | Audit and coach those specific agents rather than whole tiers | Lapse of those agents toward average |

---

## **Data Quality and Limitations**

- **Cleaning log (Excel):** 17 gender typos, 10 region typos, 4 product typos and 6 claim-status typos were corrected; 1,000 feedback dates stored as text were converted; **369 feedback records (36.9%)** belong to customers not in the master table (anonymous feedback, kept); **266 claims (18.9%)** exceed policy cover and were flagged, not deleted.
- **Two loss-ratio bases:** the dashboard divides approved claims by *annual* premium (168.8%). The earned-premium basis gives 130.9%. Define which basis is used before the figure is quoted externally.
- **Two lapse definitions:** the policy table gives 65.7% (lapsed or cancelled), while the agent table gives about 14.9%. They measure different things and should be aligned.
- **Agent table is a different population:** it records 52,792 policies sold in total versus 2,828 policies in the policy table, and its fraud-association counts do not match the claim-level flags. Agent fraud ratio should be read as indicative.
- **Sample, synthetic-looking data:** the files are a sample, and the 49% fraud flag, near-zero correlations and uniform claim amounts suggest generated data. Findings are descriptive and should be re-run on production data.
- **Regions:** dashboard region slicers use the customer region; the agent bar chart uses the agent region.
- **Cells and rankings:** region-product cells hold 30 to 60 claims, so rankings are review flags.
- **Association, not causation:** statistical tests describe patterns in this data and do not prove cause.

## **Tools Used**

- **Excel:** data profiling, cleaning log, pivots, conditional formatting, scenario sheets
- **MySQL 8:** schema design, constraints, views, window functions, 11 analysis queries
- **Python:** pandas, SQLAlchemy, PyMySQL, matplotlib, seaborn, SciPy, statsmodels, scikit-learn, XGBoost, imbalanced-learn
- **Power BI Desktop:** data modelling (6 relationships), 13 DAX measures, calculated columns (Risk Band, Agent Tier), 3-page report with slicers
- **Statistics:** Welch t-test, ANOVA, Kruskal-Wallis, chi-square, correlation, confidence intervals

## **Repository Structure**

```
AegisLife-Risk-Analytics/
├── README.md
├── 01_excel/
│   └── AegisLife_Analysis.xlsx
├── 02_sql/
│   ├── 01_schema_and_load.sql
│   └── 02_analysis_queries.sql
├── 03_python/
│   └── AegisLife.ipynb
├── 04_powerbi/
│   └── capstone project.pbix
├── data/
│   ├── customer_clean.csv  policy_clean.csv  claim_clean.csv
│   ├── agent_clean.csv  feedback_clean.csv
│   └── policy_scores.csv  customer_clv.csv  risk_tier_summary.csv
├── docs/
│   └── AegisLife_Executive_Report.docx
└── images/
    ├── aegislife.png
    └── dashboard/
        ├── 01_executive_dashboard.png
        ├── 02_regional_dashboard.png
        └── 03_risk_claim_fraud.png
```

## **How to Reproduce**

1. Run `02_sql/01_schema_and_load.sql` in MySQL Workbench to create the `aegislife` database and load the cleaned CSVs.
2. Run `02_sql/02_analysis_queries.sql` one statement at a time.
3. Open `03_python/AegisLife.ipynb` and update the connection string for your MySQL instance.
4. Open `04_powerbi/capstone project.pbix` in Power BI Desktop and refresh the data source paths.

---

**Author:** Trishula Mitra · Data Analyst
