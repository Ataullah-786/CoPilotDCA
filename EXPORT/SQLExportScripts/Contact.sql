--===============
--CONTACT EXPORT
--===============

SELECT DISTINCT '"' + PropertyName + '"' AS PropertyName,
	'"' + BuildingName + '"' AS BuildingName,
	'"' + ExternalBuildingCode + '"' AS PropertyId,
	'"' + TenantName + '"' AS TenantName,
	'"' + ExternalTenantCode + '"' AS TenantId,
	IsActiveTenant,
	'"' + v3Equity.dbo.fn_okapi_str(ContactName) + '"' AS ContactName,
	'"' + v3Equity.dbo.fn_okapi_str(ContactTitle) + '"' AS ContactTitle,
	'"' + v3Equity.dbo.fn_okapi_str(ExternalContactCode) + '"' AS ContactId_1,
	IsActiveContact,
	'"' + v3Equity.dbo.fn_okapi_str(Username) + '"' AS Username,
	convert(DATE, Contact.DateUpdatedUtc, 103) AS Updated,
	'"' + v3Equity.dbo.fn_okapi_str(Floor) + '"' AS Floor,
	'"' + v3Equity.dbo.fn_okapi_str(Suite) + '"' AS Suite,
	'"' + isnull(ExternalLeaseCode, '') + '"' AS LeaseCode,
	'"' + isnull(ExternalFloorCode, '') + '"' AS FloorCode,
	'"' + isnull(ExternalSuiteCode, '') + '"' AS SuiteCode,
	'"' + LocaleCode + '"' AS LocaleCode,
	convert(DATE, LastLoginDate, 103) AS LastLoginDate,
	'"' + ContactEmailAddress + '"' AS EmailAddress,
	'"' + AlternateEmailAddress + '"' AS AlternateEmailAddress,
	'"' + PhoneNumber + '"' AS PhoneNumber,
	'"' + ContactFaxNumber + '"' AS FaxNumber,
	'"' + EmergencyPhone1 + '"' AS PrimaryEmergencyPhone,
	'"' + EmergencyPhone2 + '"' AS SecondaryEmergencyPhone,
	'"' + EmergencyEmail + '"' AS EmergencyEmail,
	'"' + EmergencySms + '"' AS EmergencySMS,
	'"' + left(REPLACE(REPLACE(REPLACE(+ v3Equity.dbo.fn_okapi_str(ContactNotes), CHAR(9), ' '), CHAR(10), ' '), CHAR(13), ' '), 250) + '"' AS Notes,
	IsRequester,
	IsAuthorizer,
	IsHost,
	IsReserver,
	IsAdministrator,
	IsTenantAuthorizer,
	IsCOISubscribed,
	CanViewColleaguesRequests,
	CanViewColleaguesReservations,
	CanViewColleaguesVisits,
	CanGrantColleaguesRequests,
	CanGrantColleaguesReservations,
	CanGrantColleaguesVisits,
	CanAccessTenantGroupProperties,
	ContactFirstName,
	ContactLastName
--	dbo.tmpsub.*
--INTO tmp_okapi_contact
FROM v3Equity.dbo.Property
INNER JOIN v3Equity.dbo.Tenant ON Tenant.BasePropertyId = Property.PropertyId
INNER JOIN v3Equity.dbo.Contact ON Contact.BaseTenantId = Tenant.TenantId
INNER JOIN v3Equity.dbo.Area ON Area.AreaId = Contact.BaseAreaId
INNER JOIN v3Equity.dbo.Building ON Building.BuildingId = Area.BuildingId
LEFT OUTER JOIN (
	SELECT AreaId,
		max(ExternalLeaseCode) AS ExternalLeaseCode
	FROM v3Equity.dbo.TenantAreaLease
	INNER JOIN v3Equity.dbo.vTenant ON vTenant.TenantId = TenantAreaLease.TenantId
	INNER JOIN v3Equity.dbo.Lease ON Lease.LeaseId = TenantAreaLease.LeaseId
	WHERE CompanyId = 200000244
		AND IsActiveTenant = 1
		AND IsActiveLease = 1
		AND Lease.DateEnd >= getdate()
	GROUP BY AreaId
	) A ON A.AreaId = Area.AreaId
--LEFT OUTER JOIN dbo.tmpSub ON contact.contactid = dbo.tmpsub.contactid
WHERE CompanyId = 200000244
	AND IsActiveProperty = 1
	AND IsActiveBuilding = 1

--ALTER TABLE dbo.tmp_okapi_contact

--DROP COLUMN contactid

--EXEC dbo.sp_rename 'dbo.tmp_okapi_contact.contactid_1',
--	'contactid',
--	'COLUMN' --SELECT distinct * FROM dbo.tmp_okapi_contact  --order by  -- PropertyName, BuildingName, TenantName, ContactName   
