--==================
--WO TR FULL EXPORT
--==================

SELECT '"' + w.PropertyName + '"' AS PropertyName,
	'"' + w.BuildingName + '"' AS BuildingName,
	'"' + w.ExternalBuildingCode + '"' AS BuildingCode,
	'"' + w.DisplayId + '"' AS DisplayId,
	CASE 
		WHEN w.IsProactive = 1
			THEN '"Yes"'
		ELSE '"No"'
		END AS Proactive,
	'"' + CASE 
		WHEN w.IsProactive = 1
			THEN w.EmployeeRequestedFullName
		ELSE w.ContactName
		END + '"' AS RequestedBy,
	'"' + w.WoStatusDescription + '"' AS STATUS,
	v3Equity.dbo.fn_okapi_dtcov(w.DateUpdated) AS StatusDate,
	v3Equity.dbo.fn_okapi_dtcov(w.DateScheduled) AS DateDue,
	v3Equity.dbo.fn_okapi_dtcov(w.DateCreated) AS DateOpened,
	CASE 
		WHEN G.DateFirstDispatched IS NULL
			THEN ''
		ELSE convert(VARCHAR, G.DateFirstDispatched, 120)
		END AS DateDispatched,
	v3Equity.dbo.fn_okapi_dtcov(w.DateAccepted) AS DateAccepted,
	v3Equity.dbo.fn_okapi_dtcov(w.DateWorkStarted) AS DateWorkStarted,
	CASE 
		WHEN C.DateEstimateGenerated IS NULL
			THEN ''
		ELSE convert(VARCHAR, C.DateEstimateGenerated, 120)
		END AS DateEstimateGenerated,
	CASE 
		WHEN D.DateEstimateApproved IS NULL
			THEN ''
		ELSE convert(VARCHAR, D.DateEstimateApproved, 120)
		END AS DateEstimateApproved,
	v3Equity.dbo.fn_okapi_dtcov(w.DateWorkCompleted) AS DateCompleted,
	v3Equity.dbo.fn_okapi_dtcov(w.DateClosed) AS DateClosed,
	v3Equity.dbo.fn_okapi_dtcov(w.DateVerified) AS DateVerified,
	CASE 
		WHEN A.DateInvoiced IS NULL
			THEN ''
		ELSE convert(VARCHAR, A.DateInvoiced, 120)
		END AS DateInvoiced,
	'"' + v3Equity.dbo.fn_okapi_str(w.TenantName) + '"' AS TenantName,
	'"' + w.ExternalTenantCode + '"' AS TenantID,
	'"' + v3Equity.dbo.fn_okapi_str(w.EmployeeAssignedFullName) + '"' AS AssignedTo,
	'"' + v3Equity.dbo.fn_okapi_str(w.Floor) + '"' AS Floor,
	'"' + v3Equity.dbo.fn_okapi_str(w.Suite) + '"' AS Suite,
	'"' + w.RequestTypeDescription + '"' AS RequestType,
	w.Priority,
	'"' + w.TradeDescription + '"' AS Trade,
	'"' + v3Equity.dbo.fn_okapi_str(w.ContactName) + '"' AS ContactName,
	'"' + w.ContactEmailAddress + '"' AS ContactEmailAddress,
	'"' + w.EmployeeOwnerFullName + '"' AS OWNER,
	w.ScheduleId,
	'"' + left(v3Equity.dbo.fn_okapi_str(w.WoDetail), 250) + '"' AS WoDetail,
	isnull(B.TimeTaken, 0) AS TimeTaken,
	isnull(A.TotalAmountBilled, 0) AS TotalAmountBilled,
	isnull(E.TotalAmountEstimated, 0) AS TotalAmountEstimated,
	'"' + isnull(A.externalleasecode, '') + '"' AS LeaseIdBilled,
	isnull(F.TotalAmountBillable, 0) AS TotalAmountBillable,
	WorkOrder.QRSRating,
	'"' + left(v3Equity.dbo.fn_okapi_str(WorkOrder.QRSComment), 250) + '"' AS QRSComment,
	'"' + left(v3Equity.dbo.fn_okapi_str((
				SELECT TOP 1 WoHistoryDetail
				FROM v3Equity.dbo.WoHistory woh WITH (NOLOCK)
				WHERE w.WorkOrderId = woh.WorkOrderId
					AND woh.WoHistoryEvent = 14
					AND wohistorydetail <> ''
				ORDER BY woh.WoHistoryId DESC
				)), 250) + '"' AS ClosureNotes,
	'"' + Dictionary.Description + '"' AS RequestSource,
	WorkOrder.TimeAcceptance,
	W.TimeResponse,
	W.TimeCompletion,
	isnull(B.NumEmployees, 0) AS NumEmployees,
	isnull(B.IsVendor, 0) AS IsVendor,
	'"' + isnull(B.VendorCode, '') + '"' AS VendorCode,
	'"' + isnull(v3Equity.dbo.InspectionTemplate.Name, '') + '"' AS InspectionSchedule,
	'"' + isnull(Bulletin.Type, '') + '"' AS BulletinType,
	isnull(Inspection.InspectionId, 0) AS InspectionId,
	v3Equity.dbo.fn_okapi_dtcov(w.DateEscalated1) AS DateEscalated1,
	v3Equity.dbo.fn_okapi_dtcov(w.DateEscalated2) AS DateEscalated2,
	v3Equity.dbo.fn_okapi_dtcov(w.DateEscalated3) AS DateEscalated3,
	CASE 
		WHEN H.DateDelayed IS NULL
			THEN ''
		ELSE convert(VARCHAR, H.DateDelayed, 120)
		END AS DateDelayed,
	'"' + left(v3Equity.dbo.fn_okapi_str((
				SELECT TOP 1 WoHistoryDetail
				FROM v3Equity.dbo.WoHistory woh WITH (NOLOCK)
				WHERE w.WorkOrderId = woh.WorkOrderId
					AND woh.WoHistoryEvent = 10
					AND wohistorydetail <> ''
				ORDER BY woh.WoHistoryId DESC
				)), 250) + '"' AS DelayComment,
	'"' + w.ExternalPropertyCode + '"' AS PropertyCode
FROM v3Equity.dbo.vWorkOrder w
INNER JOIN v3Equity.dbo.WorkOrder WITH (NOLOCK) ON w.WorkOrderId = WorkOrder.WorkOrderId
INNER JOIN v3Equity.dbo.Dictionary WITH (NOLOCK) ON WorkOrder.RequestSource = Dictionary.RequestSource
LEFT OUTER JOIN v3Equity.dbo.InspectionTask WITH (NOLOCK) ON InspectionTask.WorkOrderId = WorkOrder.WorkOrderId
LEFT OUTER JOIN v3Equity.dbo.Inspection WITH (NOLOCK) ON Inspection.InspectionId = InspectionTask.InspectionId
LEFT OUTER JOIN v3Equity.dbo.InspectionSchedule WITH (NOLOCK) ON InspectionSchedule.InspectionScheduleId = Inspection.InspectionScheduleId
LEFT OUTER JOIN v3Equity.dbo.InspectionTemplate WITH (NOLOCK) ON InspectionTemplate.InspectionTemplateId = InspectionSchedule.InspectionTemplateId
LEFT OUTER JOIN v3Equity.dbo.Bulletin WITH (NOLOCK) ON Bulletin.BulletinId = WorkOrder.BulletinId
LEFT OUTER JOIN (
	SELECT workorderid,
		externalleasecode,
		sum(total) AS TotalAmountBilled,
		max(DateExtracted) AS DateInvoiced
	FROM v3Equity.dbo.vxferHistorical
	GROUP BY workorderid,
		externalleasecode
	) A ON w.WorkOrderId = A.WorkOrderId
LEFT OUTER JOIN (
	SELECT workorderid,
		sum(minutesworked) AS TimeTaken,
		count(DISTINCT WoHistory.EmployeeId) AS NumEmployees,
		max(IsVendor) AS IsVendor,
		max(ExternalVendorCode) AS VendorCode
	FROM v3Equity.dbo.wohistory WITH (NOLOCK)
	INNER JOIN v3Equity.dbo.Employee WITH (NOLOCK) ON Employee.EmployeeId = WoHistory.EmployeeId
	LEFT OUTER JOIN v3Equity.dbo.Vendor WITH (NOLOCK) ON Vendor.EmployeeId = Employee.EmployeeId
	WHERE WoHistoryEvent IN (
			10,
			14,
			136
			)
	GROUP BY workorderid
	) B ON w.WorkOrderId = B.WorkOrderId
LEFT OUTER JOIN (
	SELECT requestid,
		EstimateHistoryDate AS DateEstimateGenerated
	FROM v3Equity.dbo.estimate WITH (NOLOCK)
	INNER JOIN v3Equity.dbo.EstimateHistory WITH (NOLOCK) ON estimate.EstimateId = EstimateHistory.EstimateId
		AND EstimateHistoryEvent = 10
	) C ON w.requestid = C.requestid
LEFT OUTER JOIN (
	SELECT requestid,
		EstimateHistoryDate AS DateEstimateApproved
	FROM v3Equity.dbo.estimate WITH (NOLOCK)
	INNER JOIN v3Equity.dbo.EstimateHistory WITH (NOLOCK) ON estimate.EstimateId = EstimateHistory.EstimateId
		AND EstimateHistoryEvent = 40
	) D ON w.requestid = D.requestid
LEFT OUTER JOIN (
	SELECT requestid,
		sum(LabourAmount + MaterialAmount + MarkupAmount + AdminAmount) AS TotalAmountEstimated
	FROM v3Equity.dbo.estimate WITH (NOLOCK)
	INNER JOIN v3Equity.dbo.EstimateService WITH (NOLOCK) ON estimate.EstimateId = EstimateService.EstimateId
	GROUP BY requestid
	) E ON w.requestid = E.requestid
LEFT OUTER JOIN (
	SELECT workorderid,
		sum(total) AS TotalAmountBillable
	FROM v3Equity.dbo.vWoServiceBill
	GROUP BY workorderid
	) F ON w.WorkOrderId = F.WorkOrderId
LEFT OUTER JOIN (
	SELECT workorderid,
		min(WoHistoryDate) AS DateFirstDispatched
	FROM v3Equity.dbo.wohistory WITH (NOLOCK)
	WHERE WoHistoryEvent = 106
	GROUP BY workorderid
	) G ON w.WorkOrderId = G.WorkOrderId
LEFT OUTER JOIN (
	SELECT workorderid,
		min(WoHistoryDate) AS DateDelayed
	FROM v3Equity.dbo.wohistory WITH (NOLOCK)
	WHERE WoHistoryEvent = 10
	GROUP BY workorderid
	) H ON w.WorkOrderId = H.WorkOrderId
WHERE w.companyid = 200000244
	AND w.WoType = 'TR'
	AND w.DateScheduled >= getdate()-90
ORDER BY w.PropertyName,
	w.BuildingName,
	w.DisplayId
