# Telecom Service & Revenue Assurance Audit

## Executive Summary
This project implements a high-precision SQL audit framework designed to identify "Loss of Line" discrepancies within telecommunications billing systems. By reconciling multi-vendor billing data against internal service lifecycle records, the framework detects revenue leakage caused by post-termination invoicing and facilitates the generation of financial recovery claims.

## Business Problem
In large-scale telecom operations, a significant source of financial leakage occurs when a service line (WTN) is disconnected in the field but remains "Active" in the billing system. These discrepancies—often hidden within complex Monthly Recurring Charges (MRC) and Other Charges & Credits (OCC)—result in thousands of dollars in overcharges. This project provides the logic necessary to audit these gaps and maintain billing integrity.

## Data Overview
The audit leverages a relational database structure containing:
- Service Records (LocServWTNs, LocServAccounts): The source of truth for line status and disconnect dates.
- Billing Details (InvoiceDetailMRC): Historical records of recurring monthly charges.
- Adjustment Records (InvoiceDetailOCC): Credits and one-time charges where disconnect indicators (e.g., "Removed", "Disconnected") are often logged.
- Customer Metadata (EntCustomers): Facilitates client-level reporting and impact analysis.

## Analytical Approach
- Multi-Source Reconciliation: Developed a complex join logic to align disparate billing tables (MRC/OCC) with core service accounts.
- Temporal Analysis: Implemented Common Table Expressions (CTEs) to isolate the most recent billing event for any specific line item.
- Forensic Keyword Filtering: Applied string-matching logic to parse billing descriptions, specifically isolating disconnect events while excluding noise like repair or maintenance fees.
- Deduplication: Utilized window functions (ROW_NUMBER) to ensure only the most relevant, recent billing anomalies are flagged for review.
- Financial Quantification: Aggregated "Other Charges" to provide a clear dollar amount for vendor credit claims.

## Key Findings
- Revenue Leakage Detection: Identified instances where billing continued for several cycles following a confirmed line disconnection.
- Process Gaps: Highlighted discrepancies between the "Disconnect Date" in service records and the "From Date" in vendor billing.
- Claim Readiness: Produced a standardized output of specific Bill Dates, USOC Descriptions, and Amounts required for successful vendor dispute resolution.

## Project Architecture
The repository is organized to support easy integration into production audit workflows:
- sql-scripts/: Contains the primary audit query (loss-of-line-audit.sql) utilizing CTEs and window functions.
- README.md: Project documentation and business context.

## Tools Used
- SQL (T-SQL/MS SQL Server): Used for data extraction, joining, and complex filtering.
- Relational Database Management: Working with production-scale schemas (dbo.InvoiceDetail).
- GitHub: Version control and project documentation.

## Next Steps
- Automated Variance Reporting: Develop a scheduled version of the script to flag discrepancies within 24 hours of a bill load.
- Predictive Leakage Modeling: Use historical disconnect patterns to predict which accounts are most likely to experience billing "hangover" after termination.
- Visualization: Connect the SQL output to a Power BI dashboard to track total "Dollars Recovered" via audit claims.
