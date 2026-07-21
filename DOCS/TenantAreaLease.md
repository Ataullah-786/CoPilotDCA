# TenantAreaLease

## Overview

Schema information extracted from DB: 'v3Angus'.

## Columns

| Order | Column | Data Type | Length | Precision | Scale | Nullable | Key |
|------:|--------|-----------|-------:|----------:|------:|----------|:---:|
| 1 | TenantAreaLeaseId | int | 4 | 10 | 0 | NO | PK |
| 2 | TenantId | int | 4 | 10 | 0 | NO | FK |
| 3 | AreaId | int | 4 | 10 | 0 | NO | FK |
| 4 | LeaseId | int | 4 | 10 | 0 | NO | FK |
| 5 | IsActiveTenantAreaLease | int | 4 | 10 | 0 | NO |  |
| 6 | IsSubLease | int | 4 | 10 | 0 | NO |  |
| 7 | IsBaseAreaLease | int | 4 | 10 | 0 | NO |  |
| 8 | ExternalAreaCode | varchar | 50 | 0 | 0 | NO |  |
| 9 | ExternalFloorCode | varchar | 50 | 0 | 0 | NO |  |
| 10 | SquareFootage | int | 4 | 10 | 0 | NO |  |
| 11 | Occupancy | int | 4 | 10 | 0 | NO |  |
| 12 | tmpTenantAreaLeaseId | int | 4 | 10 | 0 | NO |  |
| 13 | ShowInDirectory | int | 4 | 10 | 0 | NO |  |
| 15 | TenantAreaLease_CS_CompanyId | int | 4 | 10 | 0 | NO |  |

## Primary Key

**Constraint:** ``

| Order | Column |
|------:|--------|
| 1 | TenantAreaLeaseId |

## References (Parent Tables)

| FK Name | This Column | References Table | References Column |
|---------|-------------|-------------------|--------------------|
| FK_TenantAreaLease_Area | AreaId | Area | AreaId |
| FK_TenantAreaLease_Lease | LeaseId | Lease | LeaseId |
| FK_TenantAreaLease_Tenant | TenantId | Tenant | TenantId |

## Referenced By (Child Tables)

_No other tables reference this table._


