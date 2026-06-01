# Hospital-Admission-Data

About the Project
This project transforms raw clinical intake data into an enterprise-ready reporting system using Microsoft SQL Server (T-SQL). It leverages non-destructive data cleaning views to handle duplicates and semantic errors, then models the impact of chronic comorbidities (Diabetes, Hypertension, CKD) on hospital resource utilization (ICU stays, bed turnover, and mortality rates).


Project Objectives
Optimize Throughput: Identify baseline daily, weekly, and rolling capacity trends to mitigate ER bottlenecks.
Map Vulnerabilities: Isolate complex comorbidity intersections that disproportionately exhaust critical care resources.
Data Governance: Build automated data cleaning layers and source-system quality audits without altering historical records.


Advanced SQL Concepts Applied
View Architecture: CREATE OR ALTER VIEW to abstract data transformations from physical storage.
Window Functions: ROW_NUMBER(), RANK(), and LAG() for complex sequential analysis without slow iterative loops.
Analytical Framing: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW for real-time moving averages.
Defensive Coding: TRY_CONVERT(), TRY_CAST(), and NULLIF() to bypass data truncation and division-by-zero crashes.
Conditional Aggregation: Complex SUM(CASE WHEN...) logic to extract multiple KPIs in a single table scan.
