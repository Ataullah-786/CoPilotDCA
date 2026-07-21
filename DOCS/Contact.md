# Contact

## Overview

Schema information extracted from DB: 'v3Angus'.

## Columns

| Order | Column | Data Type | Length | Precision | Scale | Nullable | Key |
|------:|--------|-----------|-------:|----------:|------:|----------|:---:|
| 1 | ContactId | int | 4 | 10 | 0 | NO | PK |
| 2 | BaseTenantId | int | 4 | 10 | 0 | NO | FK |
| 3 | BaseAreaId | int | 4 | 10 | 0 | NO | FK |
| 4 | DepartmentId | int | 4 | 10 | 0 | NO | FK |
| 5 | IsActiveContact | int | 4 | 10 | 0 | NO |  |
| 6 | IsRequester | int | 4 | 10 | 0 | NO |  |
| 7 | IsAuthorizer | int | 4 | 10 | 0 | NO |  |
| 8 | IsHost | int | 4 | 10 | 0 | NO |  |
| 9 | IsReceptionist | int | 4 | 10 | 0 | NO |  |
| 10 | IsReserver | int | 4 | 10 | 0 | NO |  |
| 11 | IsAdministrator | int | 4 | 10 | 0 | NO |  |
| 12 | IsTenantAuthorizer | int | 4 | 10 | 0 | NO |  |
| 13 | IsCOISubscribed | int | 4 | 10 | 0 | NO |  |
| 14 | CanViewColleaguesRequests | int | 4 | 10 | 0 | NO |  |
| 15 | CanViewColleaguesReservations | int | 4 | 10 | 0 | NO |  |
| 16 | CanViewColleaguesVisits | int | 4 | 10 | 0 | NO |  |
| 17 | CanGrantColleaguesRequests | int | 4 | 10 | 0 | NO |  |
| 18 | CanGrantColleaguesReservations | int | 4 | 10 | 0 | NO |  |
| 19 | WantsAuthorizationEmail | int | 4 | 10 | 0 | NO |  |
| 20 | LocaleCode | char | 5 | 0 | 0 | NO |  |
| 22 | Username | varchar | 50 | 0 | 0 | NO |  |
| 23 | ExternalContactCode | varchar | 50 | 0 | 0 | NO |  |
| 24 | ContactEmailAddress | varchar | 128 | 0 | 0 | NO |  |
| 25 | AlternateEmailAddress | varchar | 128 | 0 | 0 | NO |  |
| 26 | ContactPhoneNumber | varchar | 128 | 0 | 0 | NO |  |
| 27 | ContactFaxNumber | varchar | 128 | 0 | 0 | YES |  |
| 28 | LastLoginDate | smalldatetime | 4 | 16 | 0 | NO |  |
| 29 | LastPasswordChangeDate | smalldatetime | 4 | 16 | 0 | NO |  |
| 30 | EncryptedPassword | binary | 20 | 0 | 0 | NO |  |
| 31 | tmpContactId | int | 4 | 10 | 0 | NO |  |
| 32 | EmergencyPhone1 | varchar | 128 | 0 | 0 | YES |  |
| 33 | EmergencyPhone2 | varchar | 128 | 0 | 0 | YES |  |
| 34 | EmergencyEmail | varchar | 128 | 0 | 0 | YES |  |
| 35 | EmergencySms | varchar | 128 | 0 | 0 | YES |  |
| 36 | EmergencyEmployeeIdEnteredBy | int | 4 | 10 | 0 | NO | FK |
| 37 | EmergencyDateFrom | smalldatetime | 4 | 16 | 0 | NO |  |
| 38 | CanGrantColleaguesVisits | int | 4 | 10 | 0 | NO |  |
| 39 | CanSubscribeToAnnouncement | int | 4 | 10 | 0 | NO |  |
| 40 | CanSubscribeToEmergency | int | 4 | 10 | 0 | NO |  |
| 41 | CanGrantColleaguesAnnouncement | int | 4 | 10 | 0 | NO |  |
| 42 | CanGrantColleaguesEmergency | int | 4 | 10 | 0 | NO |  |
| 43 | ContactTitle | varchar | 50 | 0 | 0 | NO |  |
| 44 | ContactNotes | varchar | 2048 | 0 | 0 | NO |  |
| 45 | DateUpdatedUtc | datetime | 8 | 23 | 3 | NO |  |
| 46 | DateCreatedUtc | datetime | 8 | 23 | 3 | NO |  |
| 47 | CanAccessTenantGroupProperties | int | 4 | 10 | 0 | NO |  |
| 48 | CanAccessBillingReport | int | 4 | 10 | 0 | NO |  |
| 49 | AccessCardNumber | varchar | 50 | 0 | 0 | NO |  |
| 50 | CanGrantColleagesBillingReports | int | 4 | 10 | 0 | NO |  |
| 51 | UsesMobile | int | 4 | 10 | 0 | NO |  |
| 52 | ContactFirstName | varchar | 50 | 0 | 0 | NO |  |
| 53 | ContactLastName | varchar | 50 | 0 | 0 | NO |  |
| 54 | ContactName | varchar | 101 | 0 | 0 | NO |  |
| 55 | ShowInDirectory | int | 4 | 10 | 0 | NO |  |
| 56 | WasTerminated | bit | 1 | 1 | 0 | NO |  |
| 57 | UsesTenantIntegration | int | 4 | 10 | 0 | NO |  |
| 59 | Contact_CS_CompanyId | int | 4 | 10 | 0 | NO |  |
| 60 | DateToDeactivate | date | 3 | 10 | 0 | NO |  |
| 61 | IntegrationIdentifier | varchar | 50 | 0 | 0 | NO |  |
| 62 | ExternalSource | int | 4 | 10 | 0 | NO |  |
| 63 | CredentialTokenDateExpiryUtc | datetime | 8 | 23 | 3 | YES |  |
| 64 | CredentialToken | varchar | 50 | 0 | 0 | NO |  |
| 65 | CanSSOLogin | int | 4 | 10 | 0 | NO |  |
| 66 | IsAnonymousAuthenticatedContact | int | 4 | 10 | 0 | NO |  |
| 67 | IsServiceAccount | int | 4 | 10 | 0 | NO |  |
| 68 | CanReserveBillableResource | int | 4 | 10 | 0 | NO |  |

## Primary Key

**Constraint:** ``

| Order | Column |
|------:|--------|
| 1 | ContactId |

## References (Parent Tables)

| FK Name | This Column | References Table | References Column |
|---------|-------------|-------------------|--------------------|
| FK_Contact_Area | BaseAreaId | Area | AreaId |
| FK_Contact_Department | DepartmentId | Department | DepartmentId |
| FK_Contact_Employee | EmergencyEmployeeIdEnteredBy | Employee | EmployeeId |
| FK_Contact_Tenant | BaseTenantId | Tenant | TenantId |

## Referenced By (Child Tables)

| FK Name | Child Table | Child Column | This Column |
|---------|-------------|--------------|-------------|
| FK_AcsCredential_Contact_Updated | AcsCredential | ContactIdUpdatedBy | ContactId |
| FK_AcsTacAudit_ContactId | AcsTacAudit | ContactId | ContactId |
| FK_AcsTacAudit_ContactId_CreatedBy | AcsTacAudit | ContactId_CreatedBy | ContactId |
| FK_AcsTenantRequest_Contact_RequestedBy | AcsTenantRequest | ContactIdRequestedBy | ContactId |
| FK_AcsTenantRequest_Contact_RequestedFor | AcsTenantRequest | ContactIdRequestedFor | ContactId |
| FK_AcsUserMap_Contact | AcsUserMap | ContactId | ContactId |
| FK_CommunicationRecipient_Contact | CommunicationRecipient | ContactId | ContactId |
| FK_CommunicationSubscription_Contact | CommunicationSubscription | ContactId | ContactId |
| FK_ContactAddressBook_Contact | ContactAddressBook | ContactId | ContactId |
| FK_ContactInvited_ContactIdAdministrator | ContactInvited | ContactIdAdministrator | ContactId |
| FK_ContactPasswordReset_Contact | ContactPasswordReset | ContactId | ContactId |
| FK_ContactSecurityDesignation_ContactId | ContactSecurityDesignation | ContactId | ContactId |
| FK_EmployeeReportContanctRecipients_Contact | EmployeeReportContactRecipient | ContactId | ContactId |
| FK_EntityAccessAudit_Contact | EntityAccessAudit | ContactId | ContactId |
| FK_EstimateHistory_Contact | EstimateHistory | ContactId | ContactId |
| FK_FileAttachment_Contact | FileAttachment | ContactId | ContactId |
| FK_Message_Contact | Message | ContactId | ContactId |
| FK_PackagePass_Contact | PackagePass | ContactIdFor | ContactId |
| FK_PackagePass_Contact1 | PackagePass | ContactIdEnteredBy | ContactId |
| FK_PanelAccessCode_ContactId | PanelAccessCode | ContactId | ContactId |
| FK_Photo_Contact | Photo | ContactId | ContactId |
| FK_Request_Contact | Request | ContactId | ContactId |
| FK_Request_ContactIdAuthorizer | Request | ContactIdAuthorizer | ContactId |
| FK_Reservation_Contact | Reservation | ContactId | ContactId |
| FK_Reservation_ContactEnteredBy | Reservation | ContactIdEnteredBy | ContactId |
| FK_Reservation_ContactEditedBy | Reservation | ContactIdEditedBy | ContactId |
| FK_ReservationHistory_ContactEnteredBy | ReservationHistory | ContactIdEnteredBy | ContactId |
| FK_Subscription_Contact | Subscription | ContactId | ContactId |
| FK_SurveyInstance_Contact | SurveyInstance | ContactId | ContactId |
| FK_TenantContact_Contact | TenantContact | ContactId | ContactId |
| FK_TsiPermission_Contact | TsiPermission | ContactId | ContactId |
| FK_Visit_ContactEnteredBy | Visit | ContactIdEnteredBy | ContactId |
| FK_Visit_ContactHost | Visit | ContactIdHost | ContactId |
| FK_Visit_ContactIdUpdatedBy | Visit | ContactIdUpdatedBy | ContactId |
| FK_Visitor_ContactIdUpdatedBy | Visitor | ContactIdUpdatedBy | ContactId |
| FK_WorkOrder_Contact | WorkOrder | ContactId | ContactId |


