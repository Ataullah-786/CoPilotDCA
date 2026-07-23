# CoPilotDCA — Data Cleanup Agent Technical Specification

**July 23, 2026**

**Ataullah Toffar**

**DataOps Engineer**

---

## Table of Contents

- [Document Version Control](#document-version-control)
- [Modification History](#modification-history)
- [Open Issues / Gaps](#open-issues--gaps)
- [Project Overview](#project-overview)
  - [Introduction](#introduction)
  - [Current Business Process](#current-business-process)
  - [Project Scope](#project-scope)
  - [Out of Scope](#out-of-scope)
  - [Project Tasks / Deliverables](#project-tasks--deliverables)
- [Requirements](#requirements)
  - [Functional Requirements](#functional-requirements)
  - [Non-Functional Requirements](#non-functional-requirements)
- [Technical Approach](#technical-approach)
- [Data Requirement Details](#data-requirement-details)
  - [Import: Area Data Mapping](#import-area-data-mapping)
  - [Import: Contact Data Mapping](#import-contact-data-mapping)
  - [Import: Lease Data Mapping](#import-lease-data-mapping)
  - [Export: Contact Fields](#export-contact-fields)
  - [Export: PM Full (Work Order) Fields](#export-pm-full-work-order-fields)
  - [Export: TR Full (Tenant Request) Fields](#export-tr-full-tenant-request-fields)
- [Web Requirement Details](#web-requirement-details)
  - [API](#api)
  - [Email Template](#email-template)
  - [SQL Job Monitoring Dashboard](#sql-job-monitoring-dashboard)
- [Analytics Requirement Details](#analytics-requirement-details)
- [Process Flow](#process-flow)
  - [Import Pipeline](#import-pipeline)
  - [Export Pipeline](#export-pipeline)
- [Delivery Method](#delivery-method)
- [Document Distribution](#document-distribution)
- [Document Approval](#document-approval)

---

## Document Version Control

| Title | CoPilotDCA -- Data Cleanup Agent Technical Specification |
|---|---|
| **Customer** | JBG Smith / MayInstitute (Export pipelines) |
| **Reference** | Ataullah-786/CoPilotDCA (GitHub) |
| **Filename** | CoPilotDCA_TechnicalSpec.md |
| **Status** | Draft |
| **Revision** | 1.0 |

---

## Modification History

| Revision | Author | Purpose | Date |
|---|---|---|---|
| 1.0 | Ataullah Toffar | Initial Draft -- full project specification | July 23, 2026 |
| | | | |
| | | | |

---

## Open Issues / Gaps

| Ref # | Issue / Gap | Assigned To | Resolution Notes | Status |
|---|---|---|---|---|
| 1 | `$FailedFilePath` is defined but commented out in all import scripts -- failed files are not moved to a FAILED directory | Ataullah Toffar | Decide whether to enable failed file archiving | Open |
| 2 | `Show-Dialog` (pop-up alert on failure) is commented out -- no GUI alert on failure | Ataullah Toffar | Confirm if GUI alerts are required in the target environment | Open |
| 3 | `Execute_PowerShellScript` is defined as a utility function but its call is commented out in the main execution blocks | Ataullah Toffar | Confirm if chained PowerShell script execution is needed | Open |
| 4 | Extended columns in the Area import (`ExternalBuildingCode`, `Floor`, `ExternalFloorCode`, `Suite`, `ExternalSuiteCode`, `buildingid`, `areaid`, `ErrorReason`) are inserted as empty strings | Ataullah Toffar | Confirm if the source CSV will ever populate these fields | Open |
| 5 | CSV input uses a wildcard pattern (`CommUnits*.csv`) -- behaviour when multiple matching files exist is not explicitly handled | Ataullah Toffar | Clarify expected behaviour for multiple matching CSVs | Open |
| 6 | `CoPilotDCA_StartUP.bat` has a hardcoded ngrok URL (`cake-overhead-browbeat.ngrok-free.dev`) -- this will break when ngrok assigns a new URL | Ataullah Toffar | Automate ngrok URL retrieval or parameterize | Open |
| 7 | `app.py` and `Orchestrator.py` both bind to port 5000 -- they cannot run simultaneously | Ataullah Toffar | Confirm if these are meant to run as alternatives or if one should use a different port | Open |
| 8 | Import scripts share identical utility function definitions (duplicated across `Import_Area.ps1`, `Import_Contact.ps1`, `Import_Lease.ps1`) rather than importing from a shared module | Ataullah Toffar | Consider refactoring shared functions into a common `.psm1` module | Open |
| 9 | Export scripts reference hardcoded paths on `D:\SQLShare\` which differ from the import scripts' `C:\CopilotDCA\` paths | Ataullah Toffar | Confirm if this is expected (different servers) or should be normalized | Open |
| 10 | `Test.ps1` (SQL Job Monitor) references a hardcoded list of servers including `localhost`, `MRIPF3DNGQF`, `DBPGINT`, `PRODINTEG` | Ataullah Toffar | Confirm these are the correct production/staging servers | Open |

---

## Project Overview

### Introduction

The purpose of this document is to provide a complete technical specification for the **CoPilotDCA (Data Cleanup Agent)** project. It covers:

- **Project Overview** focusing on requirements that have been agreed upon by MRI Software and the client based on the scope of the project and business considerations.
- **Technical Overview** detailing the design, architecture, data flows, and individual pipeline components.

CoPilotDCA is an **Enterprise DataOps automation framework** built with Python, PowerShell, and SQL Server. It provides modular ETL pipelines for importing and exporting data, triggered through a keyword-based intent routing system via a Flask REST API. The framework is designed to automate repetitive data cleanup, validation, import, and export tasks that would otherwise require manual DBA intervention.

### Current Business Process

Clients provide data in CSV format (imports) or request data extracts (exports) from the MRI Software platform. Without automation, these operations require manual parsing, validation, SQL execution, SFTP uploads, and file archiving -- introducing risk of human error and delayed processing.

CoPilotDCA automates the entire pipeline end-to-end:

1. A natural-language prompt is sent via HTTP POST to the Flask API.
2. The Orchestrator matches keywords to the correct pipeline script.
3. The PowerShell script executes the ETL operation against SQL Server.
4. Results, logs, and notifications are generated automatically.

### Project Scope

The following items are explicitly **in scope** for CoPilotDCA:

**Import Pipelines:**
- Reading and sanitizing client-supplied CSV files
- Clearing staging tables before each import run
- Row-by-row insertion into SQL Server staging tables
- CSV file existence validation
- Row count validation (empty files treated as failures)
- Dual logging (technical `log.log` + client-friendly `Client_log.txt`)
- Failure email notifications to internal DBA team and client
- Archiving processed files to an Archive directory
- Excel-to-CSV conversion fallback (via COM object)

**Export Pipelines:**
- SQL query execution against source databases
- CSV export with configurable field quoting
- ZIP compression of export files
- SFTP upload to client endpoints
- File archiving after successful delivery

**Orchestration:**
- Flask REST API with keyword-based intent routing
- Direct SQL script execution endpoint
- Startup automation via batch script with ngrok tunneling

**Monitoring:**
- Web-based SQL Server job monitoring dashboard (`Test.ps1`)

### Out of Scope

Any item not explicitly noted as in-scope within this document is considered out-of-scope.

- Moving failed files to a `FAILED` directory (functionality exists but is currently disabled)
- GUI/pop-up dialog alerts on failure (functionality exists but is currently disabled)
- Direct integration with any MRI front-end or web portal
- Scheduling or cron-based triggering (external to this project)
- User authentication or API key management on the Flask endpoints
- Multi-tenant routing (scripts are client-specific)

### Project Tasks / Deliverables

| # | Component | Description |
|---|---|---|
| 1 | **Orchestrator.py** | Flask API with keyword-based routing to PowerShell scripts |
| 2 | **app.py** | Flask API for direct SQL script execution via PowerShell |
| 3 | **Import_Area.ps1** | Import commercial unit area data from CSV into `tmpArea_JBGSmith` |
| 4 | **Import_Contact.ps1** | Import contact data from CSV into SQL Server staging |
| 5 | **Import_Lease.ps1** | Import lease data from CSV into SQL Server staging |
| 6 | **Export_Contact.ps1** | Export contact data from SQL Server to CSV, ZIP, and SFTP upload |
| 7 | **Export_PMFull.ps1** | Export PM (preventive maintenance) work order data |
| 8 | **Export_TRFull.ps1** | Export TR (tenant request) work order data |
| 9 | **SQL Export Scripts** | SQL queries for Contact, PMFull, and TRFull exports |
| 10 | **Test.ps1** | Web-based SQL Server job monitoring dashboard |
| 11 | **CoPilotDCA_StartUP.bat** | Startup script launching Flask API and ngrok tunnel |

---

## Requirements

### Functional Requirements

| Requirement ID | Requirement | Status |
|---|---|---|
| FR-001 | The Orchestrator API must accept a JSON prompt and match keywords to registered scripts using case-insensitive, all-keywords-must-match logic | Confirmed |
| FR-002 | The Orchestrator must return the matched script path, stdout, and stderr as JSON | Confirmed |
| FR-003 | The Orchestrator must return a 400 error with a descriptive message when no script matches | Confirmed |
| FR-004 | The direct SQL API (`app.py`) must accept server, database, and script path and execute via PowerShell | Confirmed |
| FR-005 | Import scripts must verify the CSV file exists before processing | Confirmed |
| FR-006 | Import scripts must clear the staging table prior to each import run | Confirmed |
| FR-007 | Import scripts must log every significant action with a timestamp | Confirmed |
| FR-008 | Import scripts must send failure emails to both the internal DBA team and client on any error | Confirmed |
| FR-009 | Import scripts must validate that at least one row was inserted -- an empty file is treated as a failure | Confirmed |
| FR-010 | Import scripts must archive the CSV file upon successful completion | Confirmed |
| FR-011 | Import scripts must exit immediately (`exit 1`) upon any unrecoverable error | Confirmed |
| FR-012 | Export scripts must query SQL Server, export to CSV, compress to ZIP, and upload via SFTP | Confirmed |
| FR-013 | Export scripts must archive exported and compressed files after delivery | Confirmed |
| FR-014 | The startup script must launch the Flask API and an ngrok tunnel | Confirmed |

### Non-Functional Requirements

| Requirement ID | Requirement | Value |
|---|---|---|
| NFR-001 | Flask API port | `5000` |
| NFR-002 | SQL Server (imports) | `MRIPF3DNGQF` via Windows Authentication (`-E`) |
| NFR-003 | SQL Server (exports) | Determined by `Get-DbServer` function (integration_toolset module) |
| NFR-004 | Import database | `v3_common` |
| NFR-005 | Export database | `v3Equity` |
| NFR-006 | Email profile | `SQL_DBMAIL` via `msdb.dbo.sp_send_dbmail` |
| NFR-007 | Client log encoding | UTF-8 |
| NFR-008 | Excel fallback | Via COM object (`Convert-ExcelToCsv`) -- requires Excel installed |
| NFR-009 | SQL query timeout (exports) | 600 seconds |
| NFR-010 | SFTP endpoint (exports) | `sftp1.angusanywhere.com` |

---

## Technical Approach

CoPilotDCA follows a layered architecture:

```
HTTP Client (Copilot / curl / external system)
        |
        v
+---------------------+
| Flask API Layer      |   Orchestrator.py (keyword routing)
| (Python)             |   app.py (direct SQL execution)
+---------------------+
        |
        v
+---------------------+
| PowerShell Scripts   |   IMPORT/*.ps1  -- CSV-to-SQL pipelines
| (Execution Layer)    |   EXPORT/*.ps1  -- SQL-to-CSV-to-SFTP pipelines
+---------------------+
        |
        v
+---------------------+
| SQL Server           |   MRIPF3DNGQF (imports)
| (Data Layer)         |   v3Equity / v3_common databases
+---------------------+
        |
        v
+---------------------+
| Notification Layer   |   sqlcmd + sp_send_dbmail
| (Email / Logging)    |   log.log + Client_log.txt
+---------------------+
```

**Keyword Matching Algorithm:**

The `find_script()` function in `Orchestrator.py` iterates through the `SCRIPTS` registry. Each entry has a `keywords` list and a `script` path. The prompt is uppercased, and a match occurs when **all** keywords in a rule are found in the prompt. The first matching rule wins.

**Import Script Architecture:**

All import scripts share a common set of utility functions (currently duplicated in each file):

| Function | Purpose |
|---|---|
| `Clean_CsvLine` | Strips commas from quoted CSV fields to allow safe column splitting |
| `Write-Log` | Appends timestamped messages to `log.log` |
| `Write-ClientLog` | Maps error contexts to client-friendly messages and writes to `Client_log.txt` |
| `Send-FailureEmail` | Sends DBA team failure notification via `sqlcmd` |
| `Send-ClientEmail` | Sends client failure notification via `sp_send_dbmail` with log attachment |
| `Convert-ExcelToCsv` | Converts `.xlsx` to `.csv` using Excel COM object |
| `Execute_SqlScript` | Runs a `.sql` file against a specified database after verifying accessibility |
| `Execute_SqlInsert` | Executes a single SQL INSERT statement via `Invoke-Sqlcmd` |
| `Execute_PowerShellScript` | Runs an external PowerShell script with error handling |
| `Insert_CommUnits_tmpArea` | Reads CSV, builds INSERT statements, and inserts row-by-row |

**Export Script Architecture:**

Export scripts use the `integration_toolset` PowerShell module for server discovery and SFTP operations. The general flow is: load SQL query from file, substitute parameters, execute query, pipe to CSV, compress, SFTP upload, archive.

---

## Data Requirement Details

### Import: Area Data Mapping

Source: `CommUnits*.csv` from `C:\CopilotDCA\Repo\IMPORT\ImportFiles\`
Target: `[dbo].[tmpArea_JBGSmith]` in `v3_common` on `MRIPF3DNGQF`

| Output Field | Source Field | Transformation / Rule | Required? | Notes |
|---|---|---|---|---|
| `Property_Code` | CSV column 1 | Single quotes escaped via `Clean_CsvLine` | Yes | Primary property identifier |
| `Floor_code` | CSV column 2 | Single quotes escaped | Yes | Floor identifier |
| `Unit_Code` | CSV column 3 | Single quotes escaped | Yes | Individual unit identifier |
| `SQFT` | CSV column 4 | Single quotes escaped | Yes | Square footage |
| `Exclude` | CSV column 5 | Single quotes escaped | Yes | Exclusion flag |
| `ExternalBuildingCode` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `Floor` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `ExternalFloorCode` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `Suite` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `ExternalSuiteCode` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `buildingid` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `areaid` | *(not mapped)* | Inserted as empty string | No | Reserved for future use |
| `ErrorReason` | *(not mapped)* | Inserted as empty string | No | Used downstream |

### Import: Contact Data Mapping

Source: Client-supplied CSV
Target: SQL Server staging table (contact-specific)
Structure: Follows the same utility function pattern as Import_Area with `Clean_CsvLine`, `Write-Log`, `Write-ClientLog`, and the full error handling / notification chain.

> *Note: Detailed field mapping to be added once the contact-specific INSERT function is documented.*

### Import: Lease Data Mapping

Source: Client-supplied CSV
Target: SQL Server staging table (lease-specific)
Structure: Follows the same utility function pattern as Import_Area.

> *Note: Detailed field mapping to be added once the lease-specific INSERT function is documented.*

### Export: Contact Fields

Source: `v3Equity` database -- joins across Contact, Tenant, Property, Building, and Lease tables.

Key output fields include:

| Column Name | Source | Comments |
|---|---|---|
| `PropertyName` | Property table | Quoted in output |
| `BuildingName` | Building table | Quoted in output |
| `PropertyId` | `ExternalBuildingCode` | Quoted in output |
| `TenantName` | Tenant table | Quoted in output |
| `TenantId` | `ExternalTenantCode` | Quoted in output |
| `IsActiveTenant` | Tenant table | Boolean flag |
| `ContactName` | Contact table | Sanitized via `fn_okapi_str` |
| `ContactTitle` | Contact table | Sanitized via `fn_okapi_str` |
| `ContactId_1` | `ExternalContactCode` | Sanitized via `fn_okapi_str` |
| `IsActiveContact` | Contact table | Boolean flag |
| `Username` | Contact table | Sanitized via `fn_okapi_str` |
| `Updated` | `Contact.DateUpdatedUtc` | Converted to DATE format |
| `EmailAddress` | `ContactEmailAddress` | Quoted in output |
| `PhoneNumber` | Contact table | Quoted in output |
| `Notes` | `ContactNotes` | Sanitized, truncated to 250 chars |

### Export: PM Full (Work Order) Fields

Source: `v3Equity` database -- work order tables.

Key output fields include:

| Column Name | Source | Comments |
|---|---|---|
| `PropertyName` | Work order view | Quoted in output |
| `BuildingName` | Work order view | Quoted in output |
| `BuildingCode` | `ExternalBuildingCode` | Quoted in output |
| `DisplayId` | Work order ID | Quoted in output |
| `STATUS` | `WoStatusDescription` | Quoted in output |
| `StatusDate` | `DateUpdated` | Converted to VARCHAR(120), null-safe |
| `DateOpened` | `DateCreated` | Converted to VARCHAR(120), null-safe |
| `DateDue` | `DateScheduled` | Converted to VARCHAR(120), null-safe |
| `DateCompleted` | `DateWorkCompleted` | Converted to VARCHAR(120), null-safe |
| `AssignedTo` | `EmployeeAssignedFullName` | Sanitized (quotes, newlines, tabs removed) |
| `OnDemand` | `IsOnDemand` | Boolean flag |
| `System` | `EquipmentClassDescription` | Sanitized |
| `Equipment` | `EquipmentDescription` | Sanitized |
| `Priority` | Work order table | Numeric |

### Export: TR Full (Tenant Request) Fields

Source: `v3Equity` database -- work order and tenant request tables.

Key output fields include:

| Column Name | Source | Comments |
|---|---|---|
| `PropertyName` | Work order view | Quoted in output |
| `BuildingName` | Work order view | Quoted in output |
| `BuildingCode` | `ExternalBuildingCode` | Quoted in output |
| `DisplayId` | Work order ID | Quoted in output |
| `Proactive` | `IsProactive` | Converted to "Yes"/"No" |
| `RequestedBy` | `EmployeeRequestedFullName` or `ContactName` | Conditional on `IsProactive` |
| `STATUS` | `WoStatusDescription` | Quoted in output |
| `StatusDate` | `DateUpdated` | Via `fn_okapi_dtcov` |
| `DateDue` | `DateScheduled` | Via `fn_okapi_dtcov` |
| `DateOpened` | `DateCreated` | Via `fn_okapi_dtcov` |
| `DateDispatched` | `DateFirstDispatched` | From subquery, null-safe |
| `DateAccepted` | `DateAccepted` | Via `fn_okapi_dtcov` |
| `DateWorkStarted` | `DateWorkStarted` | Via `fn_okapi_dtcov` |
| `DateCompleted` | `DateWorkCompleted` | Via `fn_okapi_dtcov` |

---

## Web Requirement Details

### API

| Item | Detail |
|---|---|
| **API Name** | CoPilotDCA Orchestrator (`Orchestrator.py`) |
| **Endpoint** | `POST /run` |
| **Input** | `{"prompt": "<keywords>"}` |
| **Output** | `{"success": bool, "script": "<path>", "output": "<stdout>", "errors": "<stderr>"}` |
| **Trigger Method** | Keyword-based intent routing via HTTP POST |
| **Frequency** | On-demand |

| Item | Detail |
|---|---|
| **API Name** | CoPilotDCA Direct SQL (`app.py`) |
| **Endpoint** | `POST /run-sql` |
| **Input** | `{"server": "...", "database": "...", "script": "..."}` |
| **Output** | `{"success": bool, "output": "<stdout>", "error": "<stderr>"}` |
| **Trigger Method** | Direct HTTP POST with explicit parameters |
| **Frequency** | On-demand |

**Script Registry (Orchestrator.py):**

| Keywords | Script Path |
|---|---|
| `IMPORT` + `AREA` | `C:\CopilotDCA\Repo\IMPORT\Import_Area.ps1` |
| `IMPORT` + `CONTACT` | `C:\CopilotDCA\Repo\IMPORT\Import_Contact.ps1` |
| `IMPORT` + `LEASE` | `C:\CopilotDCA\Repo\IMPORT\Import_Lease.ps1` |
| `EXPORT` + `CONTACT` | `C:\CopilotDCA\Repo\EXPORT\Export_Contact.ps1` |
| `EXPORT` + `PMFULL` | `C:\CopilotDCA\Repo\EXPORT\Export_PMFull.ps1` |
| `EXPORT` + `TRFULL` | `C:\CopilotDCA\Repo\EXPORT\Export_TRFull.ps1` |

### Email Template

| Item | Detail |
|---|---|
| **Template Name** | Job Execution Failure Notification |
| **Email Profile** | `SQL_DBMAIL` |
| **DBA Recipients** | Sourced from `_TestDBAlerts` table (`servername = 'export/import'`) in `v3_Common` |
| **Subject** | `Job Execution Failure Notification \|\| <script name>` |
| **Body Format** | HTML |
| **Body Content** | Client-friendly error message in red, sourced from `Client_log.txt` |
| **Attachment** | `Client_log.txt` |
| **Sent On** | Any failure event: CSV not found, SQL insert failure, empty file, DB inaccessible, email send failure |

**Client Log -- Friendly Message Mapping (`Write-ClientLog`):**

| Error Context (wildcard) | Client-Facing Message |
|---|---|
| `*Failed to send failure email notification*` | "We were unable to notify our support team about this issue." |
| `*Failed to execute .bat file*` | "A background process could not be completed." |
| `*does not exist or is inaccessible*` | "We couldn't connect to the database needed to complete your request." |
| `*Failed to execute SQL script*` | "There was a problem processing your request." |
| `*SQL Insert into*` | "There was an issue saving some of your data." |
| `*CSV file not found*` | "We couldn't find the file needed to complete your request." |
| `*No data inserted into table*` | "The file you provided did not contain usable information." |
| `*String or binary data would be truncated*` | "A value being inserted or updated is too large for the target column." |
| *(default)* | "An unexpected issue occurred. Our team has already been notified." |

### SQL Job Monitoring Dashboard

| Item | Detail |
|---|---|
| **Script** | `Test.ps1` |
| **Type** | Self-hosted web UI (PowerShell HTTP listener) |
| **Port** | `8086` |
| **Servers Monitored** | `localhost`, `MRIPF3DNGQF`, `DBPGINT`, `PRODINTEG` |
| **Features** | SQL Server job status display, job duration formatting, HTML-encoded output |
| **Dependencies** | `System.Web` assembly, `Invoke-Sqlcmd` (`SqlServer` module) |

---

## Analytics Requirement Details

| Report / Metric | Source | Comments |
|---|---|---|
| Rows inserted per import | `log.log` | Logged as "($rowCount rows affected)" |
| Import success/failure | `log.log` + email notifications | Each failure triggers email + log entry |
| Export file generation | Export script stdout | "Export Complete..." messages per entity |
| SFTP upload status | SFTP log file | Per-export date-stamped log |
| SQL job status | `Test.ps1` dashboard | Real-time web UI on port 8086 |

---

## Process Flow

### Import Pipeline

1. **API receives prompt** -- `POST /run` with `{"prompt": "IMPORT AREA"}`
2. **Keyword matching** -- `find_script()` matches `["IMPORT", "AREA"]` to `Import_Area.ps1`
3. **Script invocation** -- PowerShell executed with `-ExecutionPolicy Bypass -File <script>`
4. **Initialization** -- Log file paths set, `Write-ClientLog` called with `MainScriptStart`
5. **Staging table cleared** -- `DELETE FROM tmpArea_JBGSmith` via `Invoke-Sqlcmd`
6. **CSV validation** -- Check file existence at the wildcard path
7. **CSV reading** -- `Get-Content` with header skip, single-quote replacement, whitespace trimming
8. **Row processing** -- For each line: `Clean_CsvLine` (strip embedded commas), split on commas, build INSERT statement
9. **SQL insertion** -- `Execute_SqlInsert` for each row via `Invoke-Sqlcmd`
10. **Row count validation** -- If zero rows inserted, trigger failure notification
11. **File archiving** -- Move processed CSV to `Archive\` directory
12. **Completion logging** -- Log total rows inserted and script completion

**On any failure:** `Write-Log` + `Write-ClientLog` + `Send-ClientEmail` + `Send-FailureEmail` + `exit 1`

### Export Pipeline

1. **API receives prompt** -- `POST /run` with `{"prompt": "EXPORT CONTACT"}`
2. **Keyword matching** -- `find_script()` matches to `Export_Contact.ps1`
3. **Script invocation** -- PowerShell executed
4. **Module loading** -- `integration_toolset` and `SqlServer` modules loaded
5. **Configuration** -- Date, company ID, server, database, file paths set
6. **SQL query execution** -- Query file read, `db_companyid` placeholder replaced, executed via `Invoke-Sqlcmd`
7. **CSV export** -- Results piped through `ConvertTo-Csv` and written to export file
8. **ZIP compression** -- `Compress-Archive` creates date-stamped ZIP
9. **SFTP upload** -- `SFTP_upload` function from `integration_toolset` delivers files
10. **File archiving** -- CSV and ZIP files moved to `Archive\` directory

---

## Delivery Method

The project is deployed as part of the **CoPilotDCA** GitHub repository (`Ataullah-786/CoPilotDCA`) and is executed on the local Windows server environment via:

1. **Manual trigger:** `CoPilotDCA_StartUP.bat` -- launches Flask API on port 5000 and opens an ngrok tunnel for external access
2. **Automated trigger:** Via Flask API (`Orchestrator.py`) through keyword-based intent routing from any HTTP client
3. **Direct SQL execution:** Via `app.py` endpoint for ad-hoc SQL script runs

**Deployment path:** `C:\CopilotDCA\Repo\` (server) mapped to the GitHub repository root.

---

## Document Distribution

| Organization | Name | Date |
|---|---|---|
| MRI Software | Ataullah Toffar | July 23, 2026 |
| JBG Smith | *(Client Representative)* | |
| | | |

---

## Document Approval

| Organization | Name | Signature | Date |
|---|---|---|---|
| MRI Software | Ataullah Toffar | | |
| JBG Smith | *(Client Representative)* | | |
| | | | |

---

> **Note:** Fields marked with *(Client Representative)* should be completed by the appropriate client stakeholder prior to final approval. Open issues in the **Open Issues/Gaps** section should be reviewed and resolved before this document is marked as **Final**.
