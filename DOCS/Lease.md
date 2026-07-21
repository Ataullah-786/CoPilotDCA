# Lease

## Overview

Schema information extracted from DB: 'v3Angus'.

## Columns

| Order | Column | Data Type | Length | Precision | Scale | Nullable | Key |
|------:|--------|-----------|-------:|----------:|------:|----------|:---:|
| 1 | LeaseId | int | 4 | 10 | 0 | NO | PK |
| 2 | PropertyId | int | 4 | 10 | 0 | NO | FK |
| 3 | BuildingId | int | 4 | 10 | 0 | NO | FK |
| 4 | TenantId | int | 4 | 10 | 0 | NO | FK |
| 5 | AgreementAttachmentId | int | 4 | 10 | 0 | YES | FK |
| 6 | IsActiveLease | int | 4 | 10 | 0 | NO |  |
| 7 | DateInactive | smalldatetime | 4 | 16 | 0 | NO |  |
| 8 | ExternalLeaseCode | varchar | 50 | 0 | 0 | NO |  |
| 9 | ExternalAddressCode | varchar | 50 | 0 | 0 | NO |  |
| 10 | ExternalAltAddressCode | varchar | 50 | 0 | 0 | NO |  |
| 11 | ExternalUnitCode | varchar | 50 | 0 | 0 | NO |  |
| 12 | BusinessUnit | varchar | 50 | 0 | 0 | NO |  |
| 13 | LeaseType | varchar | 50 | 0 | 0 | NO |  |
| 14 | LeaseTenantName | varchar | 50 | 0 | 0 | NO |  |
| 15 | DateStart | smalldatetime | 4 | 16 | 0 | NO |  |
| 16 | DateEnd | smalldatetime | 4 | 16 | 0 | NO |  |
| 17 | tmpLeaseId | int | 4 | 10 | 0 | NO |  |
| 19 | Lease_CS_CompanyId | int | 4 | 10 | 0 | NO |  |

## Primary Key

**Constraint:** ``

| Order | Column |
|------:|--------|
| 1 | LeaseId |

## References (Parent Tables)

| FK Name | This Column | References Table | References Column |
|---------|-------------|-------------------|--------------------|
| FK_Lease_Building | BuildingId | Building | BuildingId |
| FK_Lease_FileAttachment | AgreementAttachmentId | FileAttachment | AttachmentId |
| FK_Lease_Property | PropertyId | Property | PropertyId |
| FK_Lease_Tenant | TenantId | Tenant | TenantId |

## Referenced By (Child Tables)

| FK Name | Child Table | Child Column | This Column |
|---------|-------------|--------------|-------------|
| FK_COI_Lease | COI | LeaseId | LeaseId |
| FK_TenantAreaLease_Lease | TenantAreaLease | LeaseId | LeaseId |
| FK_WorkOrder_Lease | WorkOrder | LeaseId | LeaseId |
| FK_XFerHistorical_Lease | XFerHistorical | LeaseId | LeaseId |


