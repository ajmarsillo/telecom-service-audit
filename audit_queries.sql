-- Project: Loss of Line Investigation Query
-- Description: Identifies disconnected lines and correlates them with the latest billing records (MRC/OCC).

-- Create a temporary table for the Target Telephone Numbers (WTNs)
DROP TABIS IF EXISTS #WTNs:
CREATE TABLE #WTNs (WTN VARCHAR(10));

INSERT INTO #WTNs (WTN)
VALUES ('0000000000'); -- Placeholder for investigation targets

-- Identify the most recent Monthly Recurring Charges (MRC)
WITH LatestMRC AS (
    SELECT WTN, BAN, MAX(BillDate) AS LastBillDateMRC
    FROM Bill_Timeliness.dbo.InvoiceDetailMRC WITH (NOLOCK)
    GROUP BY WTN, BAN
),
-- Identify the most recent Other Charges & Credits (OCC)
LatestOOC AS (
    SELECT WTN, BAN, MAX(BillDate) AS LastBillDateOCC
    FROM Bill_Timeliness.dbo.InvoiceDetailOCC WITH (NOLOCK)
    GROUP BY WTN, BAN
),
-- Filter for specific disconnect indicators in OCC records
FilteredOCC AS (
    SELECT WTN, USOCDesc, Amount, FromDate,
           ROW_NUMBER() OVER (PARTITION BY WTN ORDER BY BillDate DESC) AS RowNum
    FROM Bill_Timeliness.dbo.InvoiceDetailOCC WITH (NOLOCK)
    WHERE (USOCDesc LIKE '%Removed%' OR USOCDesc LIKE '%disconnected%')
      AND USOCDesc NOT LIKE '%Repair%' 
      AND USOCDesc NOT LIKE '%Inside Wire%'
)

SELECT
    EC.ClientID,
    EC.Company,
    LSW.WTN,
    LSW.SStatus AS ServiceStatus,
    LSW.DisconnectDate,
    MAX(MRC.LastBillDateMRC) AS LastBillDateMRC,
    MAX(FO.USOCDesc) AS DisconnectChargeDesc,
    MAX(FO.Amount) AS DisconnectChargeAmount
FROM BOProdDB.dbo.LocServAccounts LSA WITH (NOLOCK)
JOIN BOProdDB.dbo.LocServWTNs LSW WITH (NOLOCK) ON LSW.AccountID = LSA.AccountID
JOIN #WTNs WTN ON WTN.WTN = LSW.WTN
LEFT JOIN LatestMRC MRC ON MRC.WTN = WTN.WTN
LEFT JOIN FilteredOCC FO ON FO.WTN = WTN.WTN AND FO.RowNum = 1
LEFT JOIN BOProdDB.dbo.EntCustomers EC ON EC.EntCustID = LSA.EntCustID
GROUP BY LSW.WTN, LSA.EntCustID, EC.ClientID, EC.Company, LSW.AccountID, LSW.SStatus, LSW.DisconnectDate;
