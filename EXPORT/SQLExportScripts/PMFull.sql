use v3Equity

SELECT '"' + w.PropertyName + '"' AS PropertyName,
	'"' + w.BuildingName + '"' AS BuildingName,
	'"' + w.ExternalBuildingCode + '"' AS BuildingCode,
	'"' + w.DisplayId + '"' AS DisplayId,
	'"' + w.WoStatusDescription + '"' AS STATUS,
	CASE 
		WHEN convert(VARCHAR, w.DateUpdated, 120) = '1900-01-01 00:00:00'
			THEN ''
		ELSE convert(VARCHAR, w.DateUpdated, 120)
		END AS StatusDate,
	CASE 
		WHEN convert(VARCHAR, w.DateCreated, 120) = '1900-01-01 00:00:00'
			THEN ''
		ELSE convert(VARCHAR, w.DateCreated, 120)
		END AS DateOpened,
	CASE 
		WHEN convert(VARCHAR, w.DateScheduled, 120) = '1900-01-01 00:00:00'
			THEN ''
		ELSE convert(VARCHAR, w.DateScheduled, 120)
		END AS DateDue,
	CASE 
		WHEN convert(VARCHAR, w.DateDispatched, 120) = '1900-01-01 00:00:00'
			THEN ''
		ELSE convert(VARCHAR, w.DateDispatched, 120)
		END AS DateDispatched,
	CASE 
		WHEN convert(VARCHAR, w.DateWorkCompleted, 120) = '1900-01-01 00:00:00'
			THEN ''
		ELSE convert(VARCHAR, w.DateWorkCompleted, 120)
		END AS DateCompleted,
	'"' + replace(replace(replace(replace(w.EmployeeAssignedFullName, '"', ''''''), CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ') + '"' AS AssignedTo,
	'"' + v3Equity.dbo.fn_okapi_str(w.Floor) + '"' AS Floor,
	'"' + v3Equity.dbo.fn_okapi_str(w.Suite) + '"' AS Suite,
	w.IsOnDemand AS OnDemand,
	'"' + replace(replace(replace(replace(w.EquipmentClassDescription, '"', ''''''), CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ') + '"' AS System,
	'"' + replace(replace(replace(replace(w.EquipmentDescription, '"', ''''''), CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ') + '"' AS Equipment,
	w.Priority,
	w.ScheduleId,
	'"' + replace(replace(replace(replace(w.WoDescription, '"', ''''''), CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ') + '"' AS WOTitle,
	'"' + replace(replace(replace(replace(isnull(ScheduleDescription, ''), '"', ''''''), CHAR(10), ' '), CHAR(13), ' '), CHAR(9), ' ') + '"' AS SchedTitle,
	w.TradeDescription AS Trade,
	isnull(A.TimeEst, 0) AS EstTime,
	isnull(B.TimeTaken, 0) AS ActTime,
	'"' + left(v3Equity.dbo.fn_okapi_str((
				SELECT TOP 1 WoHistoryDetail
				FROM v3Equity.dbo.WoHistory woh WITH (NOLOCK)
				WHERE w.WorkOrderId = woh.WorkOrderId
					AND woh.WoHistoryEvent = 16
					AND wohistorydetail <> ''
				ORDER BY woh.WoHistoryId DESC
				)), 250) + '"' AS ClosureNotes,
	w.IsCallAttention AS NotifySupervisor,
	w.IsMissingValues AS MissingValues,
	CASE 
		WHEN convert(VARCHAR, w.DateCancelled, 120) = '1900-01-01 00:00:00'
			THEN ''
		ELSE convert(VARCHAR, w.DateCancelled, 120)
		END AS DateCancelled,
	w.IsAutoCancelled AS IsAutoCancelled,
	isnull(s.Period, 0) AS Period,
	PeriodType = isnull(CASE 
			WHEN s.PeriodType = 'D'
				THEN 'Day'
			WHEN s.PeriodType = 'W'
				THEN 'Week'
			WHEN s.PeriodType = 'M'
				THEN 'Month'
			END, ''),
	e.IsActiveEquipment,
	NumTasks,
	w.EquipmentId,
	'"' + w.ExternalPropertyCode + '"' AS PropertyCode
FROM v3Equity.dbo.vWorkOrder w
INNER JOIN v3Equity.dbo.equipment e ON w.equipmentid = e.equipmentid
LEFT OUTER JOIN v3Equity.dbo.Schedule s ON w.ScheduleId = s.ScheduleId
LEFT OUTER JOIN (
	SELECT workorderid,
		sum(MinutesEstimated) AS TimeEst,
		count(wotaskid) AS NumTasks
	FROM v3Equity.dbo.wotask
	GROUP BY workorderid
	) A ON w.WorkOrderId = A.WorkOrderId
LEFT OUTER JOIN (
	SELECT workorderid,
		sum(minutesworked) AS TimeTaken
	FROM v3Equity.dbo.wohistory
	GROUP BY workorderid
	) B ON w.WorkOrderId = B.WorkOrderId
WHERE w.companyid = 200000244
	AND w.WoType = 'PM'
	AND w.DateScheduled >= '2017-01-01'
ORDER BY w.PropertyName,
	w.BuildingName,
	w.DisplayId
