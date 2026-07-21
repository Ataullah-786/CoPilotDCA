# Area

## Overview

Schema information extracted from DB: 'v3Angus'.

## Columns

| Order | Column | Data Type | Length | Precision | Scale | Nullable | Key |
|------:|--------|-----------|-------:|----------:|------:|----------|:---:|
| 1 | AreaId | int | 4 | 10 | 0 | NO | PK |
| 2 | BuildingId | int | 4 | 10 | 0 | NO | FK |
| 3 | IsTrArea | int | 4 | 10 | 0 | NO |  |
| 4 | IsPmArea | int | 4 | 10 | 0 | NO |  |
| 5 | IsCommonArea | int | 4 | 10 | 0 | NO |  |
| 6 | IsActiveArea | int | 4 | 10 | 0 | NO |  |
| 7 | Floor | varchar | 50 | 0 | 0 | NO |  |
| 8 | Suite | varchar | 50 | 0 | 0 | NO |  |
| 9 | ExternalFloorCode | varchar | 50 | 0 | 0 | NO |  |
| 10 | ExternalSuiteCode | varchar | 50 | 0 | 0 | NO |  |
| 11 | tmpSubLocationId | int | 4 | 10 | 0 | NO |  |
| 12 | AciVisitorAccessLevel | varchar | 50 | 0 | 0 | NO |  |
| 13 | DateUpdatedUtc | datetime | 8 | 23 | 3 | NO |  |
| 14 | DateCreatedUtc | datetime | 8 | 23 | 3 | NO |  |
| 16 | Area_CS_CompanyId | int | 4 | 10 | 0 | NO |  |
| 17 | AciSegmentName | varchar | 50 | 0 | 0 | NO |  |
| 18 | IntegrationIdentifier | varchar | 50 | 0 | 0 | NO |  |

## Primary Key

**Constraint:** ``

| Order | Column |
|------:|--------|
| 1 | AreaId |

## References (Parent Tables)

| FK Name | This Column | References Table | References Column |
|---------|-------------|-------------------|--------------------|
| FK_Area_Building | BuildingId | Building | BuildingId |

## Referenced By (Child Tables)

| FK Name | Child Table | Child Column | This Column |
|---------|-------------|--------------|-------------|
| FK_CommunicationCriteria_Area | CommunicationCriteria | AreaId | AreaId |
| FK_Contact_Area | Contact | BaseAreaId | AreaId |
| FK_Equipment_Area | Equipment | AreaId | AreaId |
| FK_InspectionScheduleArea_Area | InspectionScheduleArea | AreaId | AreaId |
| FK_PackagePass_Area | PackagePass | AreaId | AreaId |
| FK_Request_Area | Request | AreaId | AreaId |
| FK_Resource_Area | Resource | AreaId | AreaId |
| FK_TenantAreaLease_Area | TenantAreaLease | AreaId | AreaId |
| FK_Visit_Area | Visit | AreaIdDestination | AreaId |
| FK_WorkOrder_Area | WorkOrder | AreaId | AreaId |


