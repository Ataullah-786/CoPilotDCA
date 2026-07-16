# Import_Area.ps1 — Technical Specification
**January 2026 | Ataullah Toffar | DataOps Engineer**

---

## Document Version Control

| Title | Import Area Data Pipeline — Technical Specification |
|---|---|
| **Customer** | JBG Smith |
| **Reference** | CoPilotDCA / IMPORT / Import_Area.ps1 |
| **Filename** | Import_Area.ps1 |
| **Status** | Draft |
| **Revision** | 1.0 |

---

## Modification History

| Revision | Author | Purpose | Date |
|---|---|---|---|
| 1.0 | Ataullah Toffar | Initial Draft | June 02, 2026 |
| | | | |
| | | | |

---

## Open Issues / Gaps

| Ref # | Issue / Gap | Assigned To | Resolution Notes | Status |
|---|---|---|---|---|
| 1 | `$FailedFilePath` is defined but commented out — failed files are not being moved to a FAILED directory | Ataullah Toffar | Needs decision on whether to enable failed file archiving | Open |
| 2 | `Show-Dialog` (pop-up alert on failure) is commented out — no UI alert on failure | Ataullah Toffar | Confirm if GUI alerts are required in the target environment | Open |
| 3 | `Execute_PowerShellScript` is defined but commented out in the main execution block | Ataullah Toffar | Confirm if chained PS script execution is needed | Open |
| 4 | Several extended columns (`ExternalBuildingCode`, `Floor`, `ExternalFloorCode`, `Suite`, `ExternalSuiteCode`, `buildingid`, `areaid`, `ErrorReason`) are inserted as empty strings | Ataullah Toffar | Confirm if source CSV will ever populate these fields | Open |
| 5 | CSV input uses a wildcard pattern (`CommUnits*.csv`) — behaviour if multiple files exist is not explicitly handled | Ataullah Toffar | Clarify expected behaviour when multiple matching CSVs are present | Open |

---

## Project Overview

### Introduction

The purpose of this document is to provide details on the delivery of custom development for the CoPilotDCA Data Cleanup Agent project. It provides a Project Overview focusing on requirements that have been agreed upon by MRI Software and JBG Smith ("Client") based on the scope of the project and business considerations, as well as a Technical Overview detailing the design of the project.

The `Import_Area.ps1` script is a PowerShell-based **automated data import pipeline** that is part of the broader CoPilotDCA Enterprise DataOps framework. Its primary function is to read commercial unit area data from a client-supplied CSV file and insert it row-by-row into a SQL Server staging table (`tmpArea_JBGSmith`) on the `MRIPF3DNGQF` server. The script is designed to be triggered via the Flask API (`app.py`) through keyword-based intent routing and coordinated by `Orchestrator.py`.

---

### Current Business Process

For any further details of this project, please refer back to the CoPilotDCA repository.

Currently, JBG Smith provides commercial unit area data in CSV format (`CommUnits*.csv`). This data must be cleaned, validated, and loaded into the MRI SQL Server environment for downstream processing. Without automation, this process requires manual intervention to parse, validate, and insert data — introducing risk of human error and delayed processing. This script automates the entire pipeline end-to-end.

---

### Project Scope

The following items are explicitly **in scope** for this script:

- Reading and sanitizing a client-supplied `CommUnits*.csv` file
- Clearing the staging table (`tmpArea_JBGSmith`) before each run to avoid duplicate data
- Inserting cleaned CSV data row-by-row into `tmpArea_JBGSmith` in the `v3_common` database on `MRIPF3DNGQF`
- Validating that the CSV file exists before processing
- Validating that at least one row was successfully inserted
- Writing detailed timestamped logs to `log.log`
- Writing user-friendly messages to `Client_log.txt`
- Sending failure notification emails to the **internal DBA team** via `sqlcmd`
- Sending failure notification emails to the **client** via `msdb.dbo.sp_send_dbmail` with the client log as an attachment
- Archiving successfully processed CSV files to `C:\CopilotDCA\Repo\IMPORT\Archive\`

---

### Out of Scope

Any item not explicitly noted as in-scope within this document is considered out-of-scope. The following are explicitly out of scope for this script:

- Moving failed files to a `FAILED` directory (functionality exists but is currently disabled)
- GUI/pop-up dialog alerts on failure (functionality exists but is currently disabled)
- Processing of any data entity other than commercial unit area (`CommUnits`)
- Transformation or enrichment of extended fields (`ExternalBuildingCode`, `Floor`, `Suite`, etc.)
- Direct integration with any MRI front-end or web portal
- Scheduling or triggering logic (handled externally by `Orchestrator.py` and the Flask API)

---

### Project Tasks / Deliverables

| # | Task | Description |
|---|---|---|
| 1 | CSV Ingestion | Read `CommUnits*.csv` from `C:\CopilotDCA\Repo\IMPORT\ImportFiles\` |
| 2 | Data Sanitization | Clean each CSV line by stripping embedded commas from quoted fields |
| 3 | Staging Table Clear | Delete all existing rows from `tmpArea_JBGSmith` before import |
| 4 | Data Insert | Insert cleaned rows into `[dbo].[tmpArea_JBGSmith]` in `v3_common` |
| 5 | Validation | Confirm at least one row was inserted; halt and notify on failure |
| 6 | Logging | Write timestamped entries to both `log.log` and `Client_log.txt` |
| 7 | Failure Notification | Send email to DBA team and client on any failure event |
| 8 | File Archiving | Move processed CSV to Archive folder upon successful completion |

---

## Requirements

### Functional Requirements

- The script **must** verify the CSV file exists before attempting to process it
- The script **must** clear the staging table prior to each import run
- The script **must** log every significant action with a timestamp
- The script **must** send failure emails to both the internal team and client on any error
- The script **must** validate that at least one row was inserted — an empty file is treated as a failure
- The script **must** archive the CSV file upon successful completion
- The script **must** exit immediately (`exit 1`) upon any unrecoverable error

### Non-Functional Requirements

- **Server:** `MRIPF3DNGQF` (SQL Server via Windows Authentication `-E`)
- **Database:** `v3_common`
- **Email Profile:** `SQL_DBMAIL` via `msdb.dbo.sp_send_dbmail`
- **Encoding:** UTF-8 for client log output
- **Excel Support:** `Convert-ExcelToCsv` function available as a fallback (requires Excel COM object)

---

## Technical Approach

### Data Requirement Details

The following columns are mapped from the source CSV to the SQL staging table `[dbo].[tmpArea_JBGSmith]`:

| Column Name | Table Field | Comments |
|---|---|---|
| `columns[0]` | `Property_Code` | Mapped from CSV column 1 |
| `columns[1]` | `Floor_code` | Mapped from CSV column 2 |
| `columns[2]` | `Unit_Code` | Mapped from CSV column 3 |
| `columns[3]` | `SQFT` | Mapped from CSV column 4 |
| `columns[4]` | `Exclude` | Mapped from CSV column 5 |
| *(empty)* | `ExternalBuildingCode` | Not populated — reserved for future use |
| *(empty)* | `Floor` | Not populated — reserved for future use |
| *(empty)* | `ExternalFloorCode` | Not populated — reserved for future use |
| *(empty)* | `Suite` | Not populated — reserved for future use |
| *(empty)* | `ExternalSuiteCode` | Not populated — reserved for future use |
| *(empty)* | `buildingid` | Not populated — reserved for future use |
| *(empty)* | `areaid` | Not populated — reserved for future use |
| *(empty)* | `ErrorReason` | Not populated at insert time — used downstream |

---

### Web Requirement Details

#### API

| Item | Detail |
|---|---|
| **API Name** | CoPilotDCA Flask API (`app.py`) |
| **Trigger Method** | Keyword-based intent routing via HTTP request |
| **Orchestration** | Managed by `Orchestrator.py` |
| **Frequency** | On-demand / as triggered by the Flask API |
| **Script Invocation** | `Import_Area.ps1` called via `Execute_PowerShellScript` or direct invocation |

---

#### Email Template

| Item | Detail |
|---|---|
| **Template Name** | Job Execution Failure Notification |
| **Email Profile** | `SQL_DBMAIL` |
| **Recipients** | DBA team emails from `_TestDBAlerts` table (`servername = 'export/import'`) |
| **Subject** | `Job Execution Failure Notification \|\| SingleServer Import JBGSmith_Secondary.ps1` |
| **Body Format** | HTML |
| **Body Content** | Plain-English error message in red, sourced from `Client_log.txt` |
| **Attachment** | `Client_log.txt` |
| **Sent On** | Any failure event (CSV not found, SQL insert failure, empty file, DB inaccessible) |

---

#### Client Log — Friendly Message Mapping

| Error Context | Client-Facing Message |
|---|---|
| Failed to send failure email | *"We were unable to notify our support team about this issue."* |
| Failed to execute .bat file | *"A background process could not be completed."* |
| Database does not exist or is inaccessible | *"We couldn't connect to the database needed to complete your request."* |
| Failed to execute SQL script | *"There was a problem processing your request."* |
| SQL Insert failure | *"There was an issue saving some of your data."* |
| CSV file not found | *"We couldn't find the file needed to complete your request."* |
| No data inserted | *"The file you provided did not contain usable information."* |
| String/binary truncation | *"A value being inserted or updated is too large for the target column."* |
| Unexpected error | *"An unexpected issue occurred. Our team has already been notified."* |

---

### Analytics Requirement Details

| Column Name | Table Field | Comments |
|---|---|---|
| `Property_Code` | `tmpArea_JBGSmith.Property_Code` | Primary identifier for the property |
| `Floor_code` | `tmpArea_JBGSmith.Floor_code` | Identifies the floor |
| `Unit_Code` | `tmpArea_JBGSmith.Unit_Code` | Identifies the individual unit |
| `SQFT` | `tmpArea_JBGSmith.SQFT` | Square footage of the unit |
| `Exclude` | `tmpArea_JBGSmith.Exclude` | Flag to exclude unit from processing |
| `Row Count` | *(logged only)* | Total rows inserted — written to `log.log` |

---

## Delivery Method

The script is deployed as part of the **CoPilotDCA** repository on GitHub (`Ataullah-786/CoPilotDCA`) and is executed on the local Windows server environment via:

1. **Manual trigger:** `CoPilotDCA_StartUP.bat`
2. **Automated trigger:** Via Flask API (`app.py`) and `Orchestrator.py` through keyword-based intent routing

---

## Document Distribution

| Organization | Name | Date |
|---|---|---|
| MRI Software | Ataullah Toffar | July 16, 2026 |
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

> 📝 **Note:** Fields marked with *(Client Representative)* should be completed by the appropriate JBG Smith stakeholder prior to final approval. Open issues in the **Open Issues/Gaps** section should be reviewed and resolved before this document is marked as **Final**.
