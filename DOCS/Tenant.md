# Tenant

## Overview

Schema information extracted from DB: 'v3Angus'.

## Columns

| Order | Column | Data Type | Length | Precision | Scale | Nullable | Key |
|------:|--------|-----------|-------:|----------:|------:|----------|:---:|
| 1 | TenantId | int | 4 | 10 | 0 | NO | PK |
| 2 | BasePropertyId | int | 4 | 10 | 0 | NO | FK |
| 3 | TenantIdParent | int | 4 | 10 | 0 | NO | FK |
| 4 | TenantGroupId | int | 4 | 10 | 0 | NO | FK |
| 5 | IsActiveTenant | int | 4 | 10 | 0 | NO |  |
| 6 | IsTenantTaxExempt | int | 4 | 10 | 0 | NO |  |
| 7 | IsTenantAutoVerified | int | 4 | 10 | 0 | NO |  |
| 8 | IsCorporateTenant | int | 4 | 10 | 0 | NO |  |
| 9 | AuthorizationType | int | 4 | 10 | 0 | NO |  |
| 10 | BillableResRequireAuth | int | 4 | 10 | 0 | NO |  |
| 11 | TenantName | varchar | 50 | 0 | 0 | NO |  |
| 12 | TenantPhone | varchar | 50 | 0 | 0 | NO |  |
| 13 | ExternalTenantCode | varchar | 50 | 0 | 0 | NO |  |
| 14 | BaseExternalServiceAddressCode | varchar | 50 | 0 | 0 | NO |  |
| 15 | BillingAddress | varchar | 256 | 0 | 0 | NO |  |
| 16 | TenantCustom1 | varchar | 128 | 0 | 0 | NO |  |
| 17 | TenantCustom2 | varchar | 128 | 0 | 0 | NO |  |
| 18 | tmpTenantId | int | 4 | 10 | 0 | NO |  |
| 19 | IsBillable | int | 4 | 10 | 0 | NO |  |
| 20 | TenantFax | varchar | 50 | 0 | 0 | NO |  |
| 21 | Notes | varchar | 2048 | 0 | 0 | NO |  |
| 22 | DateUpdatedUtc | datetime | 8 | 23 | 3 | NO |  |
| 23 | DateCreatedUtc | datetime | 8 | 23 | 3 | NO |  |
| 24 | IsCoiRequired | int | 4 | 10 | 0 | NO |  |
| 25 | BusinessNameAlias | varchar | 100 | 0 | 0 | YES |  |
| 26 | ShowInDirectory | int | 4 | 10 | 0 | NO |  |
| 28 | Tenant_CS_CompanyId | int | 4 | 10 | 0 | NO |  |
| 29 | DateToDeactivate | date | 3 | 10 | 0 | NO |  |
| 30 | IntegrationIdentifier | varchar | 50 | 0 | 0 | NO |  |
| 31 | UsesSSO | int | 4 | 10 | 0 | NO |  |
| 32 | IsAnonymousTenant | int | 4 | 10 | 0 | NO |  |
| 33 | CanReserveBillableResource | int | 4 | 10 | 0 | NO |  |

## Primary Key

**Constraint:** ``

| Order | Column |
|------:|--------|
| 1 | TenantId |

## References (Parent Tables)

| FK Name | This Column | References Table | References Column |
|---------|-------------|-------------------|--------------------|
| FK_Tenant_Property | BasePropertyId | Property | PropertyId |
| FK_Tenant_Tenant | TenantIdParent | Tenant | TenantId |
| FK_Tenant_TenantGroup | TenantGroupId | TenantGroup | TenantGroupId |

## Referenced By (Child Tables)

| FK Name | Child Table | Child Column | This Column |
|---------|-------------|--------------|-------------|
| FK_AccountCode_Tenant | AccountCode | TenantId | TenantId |
| FK_AcsTenantAccessLevel_TenantId | AcsTenantAccessLevel | TenantId | TenantId |
| FK_AcsTenantBadgeType_TenantId | AcsTenantBadgeType | TenantId | TenantId |
| FK_AcsTenantFacilityCode_TenantId | AcsTenantFacilityCode | TenantId | TenantId |
| FK_Address_Tenant | Address | TenantId | TenantId |
| FK_AuthorizedRequestType_Tenant | AuthorizedRequestType | TenantId | TenantId |
| FK_COI_Tenant | COI | TenantId | TenantId |
| FK_CommunicationCriteria_Tenant | CommunicationCriteria | TenantId | TenantId |
| FK_Contact_Tenant | Contact | BaseTenantId | TenantId |
| FK_ContactInvited_BaseTenantId | ContactInvited | BaseTenantId | TenantId |
| FK_Department_Tenant | Department | TenantId | TenantId |
| FK_Employee_Tenant | Employee | TenantIdScope | TenantId |
| FK_Lease_Tenant | Lease | TenantId | TenantId |
| FK_Message_Tenant | Message | TenantId | TenantId |
| FK_PackagePass_Tenant | PackagePass | TenantId | TenantId |
| FK_PropertyTenant_Tenant | PropertyTenant | TenantId | TenantId |
| FK_Request_Tenant | Request | TenantId | TenantId |
| FK_Reservation_Tenant | Reservation | TenantId | TenantId |
| FK_ResourceTenantRestriction_TenantId | ResourceTenantRestriction | TenantId | TenantId |
| FK_Service_Tenant | Service | TenantId | TenantId |
| FK_Tenant_Tenant | Tenant | TenantIdParent | TenantId |
| FK_TenantAreaLease_Tenant | TenantAreaLease | TenantId | TenantId |
| FK_TenantBilling_Tenant | TenantBilling | TenantId | TenantId |
| FK_TenantContact_Tenant | TenantContact | TenantId | TenantId |
| FK_TenantWorkflow_Tenant | TenantWorkflow | TenantId | TenantId |
| FK_TsiPermission_Tenant | TsiPermission | TenantId | TenantId |
| FK_Visit_TenantHost | Visit | TenantIdHost | TenantId |
| FK_VisitorContact_TenantHost | VisitorContact | TenantIdHost | TenantId |
| FK_WorkOrder_Tenant | WorkOrder | TenantId | TenantId |


