IF NOT EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[SCHEMATA]
    WHERE SCHEMA_NAME = 'analytics'
)
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA [analytics]';
END;

IF NOT EXISTS
(
    SELECT 1
    FROM [INFORMATION_SCHEMA].[SCHEMATA]
    WHERE SCHEMA_NAME = 'analytics_config'
)
BEGIN
    EXEC sp_executesql N'CREATE SCHEMA [analytics_config]';
END;
/****** Object:  View [analytics].[ContactPersonDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[ContactPersonDimension]
AS
WITH [ParentAddress]
AS (
   SELECT [ParentAddress].[ParentUSI],
          ISNULL([ParentAddress].[StreetNumberName], '')
          + COALESCE(', ' + [ParentAddress].[ApartmentRoomSuiteNumber], '')
          + COALESCE(', ' + [ParentAddress].[City], '') + COALESCE(' ' + [sad].[CodeValue], '')
          + COALESCE(' ' + [ParentAddress].[PostalCode], '') AS [Address],
          pad.[CodeValue] AS [AddressType],
          [ParentAddress].[CreateDate] AS [LastModifiedDate]
   FROM [edfi].[ParentAddress]
       INNER JOIN [edfi].[Descriptor] pad
           ON [ParentAddress].[AddressTypeDescriptorId] = pad.[DescriptorId]
       INNER JOIN [edfi].[Descriptor] sad
           ON [ParentAddress].[StateAbbreviationDescriptorId] = sad.[DescriptorId]),
     [ParentTelephone]
AS (SELECT [ParentTelephone].[ParentUSI],
           [ParentTelephone].[TelephoneNumber],
           ttd.[CodeValue] AS [TelephoneNumberType],
           [ParentTelephone].[CreateDate]
    FROM [edfi].[ParentTelephone]
        INNER JOIN [edfi].[Descriptor] ttd
            ON [ParentTelephone].TelephoneNumberTypeDescriptorId = ttd.DescriptorId),
     [ParentEmail]
AS (SELECT [ParentElectronicMail].[ParentUSI],
           [ParentElectronicMail].[ElectronicMailAddress],
           [ParentElectronicMail].[PrimaryEmailAddressIndicator],
           [HomeEmailType].[CodeValue] AS [EmailType],
           [ParentElectronicMail].[CreateDate]
    FROM [edfi].[ParentElectronicMail]
        LEFT OUTER JOIN [edfi].[Descriptor] AS [HomeEmailType]
            ON [ParentElectronicMail].[ElectronicMailTypeDescriptorId] = [HomeEmailType].[DescriptorId])
SELECT [Parent].[ParentUSI] AS [ContactPersonKey],
       [StudentParentAssociation].[StudentUSI] AS [StudentKey],
       [Parent].[FirstName] AS [ContactFirstName],
       [Parent].[LastSurname] AS [ContactLastName],
       [RD].[CodeValue] AS [RelationshipToStudent],
       ISNULL([HomeAddress].[Address], '') AS [ContactHomeAddress],
       ISNULL([PhysicalAddress].[Address], '') AS [ContactPhysicalAddress],
       ISNULL([MailingAddress].[Address], '') AS [ContactMailingAddress],
       ISNULL([WorkAddress].[Address], '') AS [ContactWorkAddress],
       ISNULL([TemporaryAddress].[Address], '') AS [ContactTemporaryAddress],
       ISNULL([HomeTelephone].[TelephoneNumber], '') AS [HomePhoneNumber],
       ISNULL([MobileTelephone].[TelephoneNumber], '') AS [MobilePhoneNumber],
       ISNULL([WorkTelephone].[TelephoneNumber], '') AS [WorkPhoneNumber],
       CASE
           WHEN [HomeEmail].[PrimaryEmailAddressIndicator] = 1 THEN
               N'Personal'
           WHEN [WorkEmail].[PrimaryEmailAddressIndicator] = 1 THEN
               N'Work'
           ELSE
               N'Not specified'
       END AS [PrimaryEmailAddress],
       ISNULL([HomeEmail].[ElectronicMailAddress], '') AS [PersonalEmailAddress],
       ISNULL([WorkEmail].[ElectronicMailAddress], '') AS [WorkEmailAddress],
       ISNULL([StudentParentAssociation].[PrimaryContactStatus], 0) AS [IsPrimaryContact],
       ISNULL([StudentParentAssociation].[LivesWith], 0) AS [StudentLivesWith],
       ISNULL([StudentParentAssociation].[EmergencyContactStatus], 0) AS [IsEmergencyContact],
       ISNULL([StudentParentAssociation].[ContactPriority], 0) AS [ContactPriority],
       ISNULL([StudentParentAssociation].[ContactRestrictions], '') AS [ContactRestrictions],
       (
           SELECT MAX([LastModifiedDate])
           FROM
           (
               VALUES
                   ([StudentParentAssociation].[LastModifiedDate]),
                   ([Parent].[LastModifiedDate]),
                   ([HomeAddress].[LastModifiedDate]),
                   ([PhysicalAddress].[LastModifiedDate]),
                   ([MailingAddress].[LastModifiedDate]),
                   ([WorkAddress].[LastModifiedDate]),
                   ([TemporaryAddress].[LastModifiedDate]),
                   ([HomeTelephone].[CreateDate]),
                   ([MobileTelephone].[CreateDate]),
                   ([WorkTelephone].[CreateDate]),
                   ([HomeEmail].[CreateDate]),
                   ([WorkEmail].[CreateDate])
           ) AS value ([LastModifiedDate])
       ) AS [LastModifiedDate]
FROM [edfi].[StudentParentAssociation]
    INNER JOIN [edfi].[Parent]
        ON [StudentParentAssociation].[ParentUSI] = [Parent].[ParentUSI]
    INNER JOIN [edfi].[Descriptor] RD
        ON [StudentParentAssociation].[RelationDescriptorId] = RD.DescriptorId
    LEFT OUTER JOIN [ParentAddress] AS [HomeAddress]
        ON [Parent].[ParentUSI] = [HomeAddress].[ParentUSI]
           AND [HomeAddress].[AddressType] = 'Home'
    LEFT OUTER JOIN [ParentAddress] AS [PhysicalAddress]
        ON [Parent].[ParentUSI] = [PhysicalAddress].[ParentUSI]
           AND [HomeAddress].[AddressType] = 'Physical'
    LEFT OUTER JOIN [ParentAddress] AS [MailingAddress]
        ON [Parent].[ParentUSI] = [MailingAddress].[ParentUSI]
           AND [HomeAddress].[AddressType] = 'Mailing'
    LEFT OUTER JOIN [ParentAddress] AS [WorkAddress]
        ON [Parent].[ParentUSI] = [WorkAddress].[ParentUSI]
           AND [HomeAddress].[AddressType] = 'Work'
    LEFT OUTER JOIN [ParentAddress] AS [TemporaryAddress]
        ON [Parent].[ParentUSI] = [TemporaryAddress].[ParentUSI]
           AND [HomeAddress].[AddressType] = 'Temporary'
    LEFT OUTER JOIN [ParentTelephone] AS [HomeTelephone]
        ON [Parent].[ParentUSI] = [HomeTelephone].[ParentUSI]
           AND [HomeTelephone].[TelephoneNumberType] = 'Home'
    LEFT OUTER JOIN [ParentTelephone] AS [MobileTelephone]
        ON [Parent].[ParentUSI] = [MobileTelephone].[ParentUSI]
           AND [MobileTelephone].[TelephoneNumberType] = 'Mobile'
    LEFT OUTER JOIN [ParentTelephone] AS [WorkTelephone]
        ON [Parent].[ParentUSI] = [WorkTelephone].[ParentUSI]
           AND [WorkTelephone].[TelephoneNumberType] = 'Work'
    LEFT OUTER JOIN [ParentEmail] AS [HomeEmail]
        ON [Parent].[ParentUSI] = [HomeEmail].[ParentUSI]
           AND [HomeEmail].[EmailType] = 'Home/Personal'
    LEFT OUTER JOIN [ParentEmail] AS [WorkEmail]
        ON [Parent].[ParentUSI] = [WorkEmail].[ParentUSI]
           AND [WorkEmail].[EmailType] = 'Work';
GO
/****** Object:  View [analytics].[StudentDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StudentDimension]
AS
WITH StudentRaces
AS (SELECT
  seoar.StudentUSI,
  COUNT(DISTINCT seoar.RaceDescriptorId) AS RaceCount,
  MAX(seoar.RaceDescriptorId) AS RaceDescriptorId
FROM edfi.StudentEducationOrganizationAssociationRace seoar
GROUP BY seoar.StudentUSI)

SELECT
  [Student].[StudentUSI] AS [StudentKey],
  [Student].[FirstName] AS [StudentFirstName],
  ISNULL([Student].[MiddleName], '') AS [StudentMiddleName],
  ISNULL([Student].[LastSurname], '') AS [StudentLastName],
  [StudentSchoolAssociation].[SchoolId] AS [SchoolKey],
  [StudentSchoolAssociation].[EntryDate] AS [EnrollmentDate],
  [Descriptor].[CodeValue] AS [GradeLevel],
   CASE
    WHEN StudentRaces.RaceCount > 1 THEN 'Two or more'
    ELSE d.CodeValue
  END AS RaceDescriptor,
  ISNULL([LimitedEnglishDescriptor].[CodeValue], 'Not applicable') AS [LimitedEnglishProficiency],
  --[Student].[EconomicDisadvantaged] AS [IsEconomicallyDisadvantaged], 
  CASE
    WHEN [FoodServicesDescriptor].[CodeValue] <> 'FullPrice' THEN 1
    ELSE 0
  END AS IsEligibleForSchoolFoodService,
  [StudentEducationOrganizationAssociation].[HispanicLatinoEthnicity] AS [IsHispanic],
  std.[CodeValue] AS [Sex] ,
  [PrimaryContact].[ContactName],
  [PrimaryContact].[ContactRelationship],
  [PrimaryContact].[ContactAddress],
  [PrimaryContact].[ContactMobilePhoneNumber],
  [PrimaryContact].[ContactWorkPhoneNumber],
  [PrimaryContact].[ContactEmailAddress],
  (SELECT
    MAX([LastModifiedDate])
  FROM (
  VALUES
  ([Student].[LastModifiedDate]),
  ([PrimaryContact].[LastModifiedDate])
  ) AS value ([LastModifiedDate]))
  AS [LastModifiedDate]
FROM [edfi].[Student]
INNER JOIN [edfi].[StudentSchoolAssociation]
  ON [Student].[StudentUSI] = [StudentSchoolAssociation].[StudentUSI]
INNER JOIN edfi.StudentEducationOrganizationAssociation
  ON StudentEducationOrganizationAssociation.StudentUSI = Student.StudentUSI
LEFT JOIN [edfi].[StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService]
  ON StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.EducationOrganizationId = StudentEducationOrganizationAssociation.EducationOrganizationId
  AND StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService.StudentUSI = Student.StudentUSI
INNER JOIN [edfi].[Descriptor]
  ON [StudentSchoolAssociation].[EntryGradeLevelDescriptorId] = [Descriptor].[DescriptorId]
LEFT OUTER JOIN [edfi].[Descriptor] AS [LimitedEnglishDescriptor]
  ON [edfi].[StudentEducationOrganizationAssociation].[LimitedEnglishProficiencyDescriptorId] = [LimitedEnglishDescriptor].[DescriptorId]
LEFT JOIN [edfi].[Descriptor] std
  ON [Student].[BirthSexDescriptorId] = std.DescriptorId
LEFT OUTER JOIN [edfi].[Descriptor] AS [FoodServicesDescriptor]
  ON [StudentSchoolFoodServiceProgramAssociationSchoolFoodServiceProgramService].SchoolFoodServiceProgramServiceDescriptorId = [FoodServicesDescriptor].[DescriptorId]
LEFT OUTER JOIN StudentRaces ON edfi.Student.StudentUSI = StudentRaces.StudentUSI
LEFT OUTER JOIN edfi.RaceDescriptor rd ON rd.RaceDescriptorId = StudentRaces.RaceDescriptorId
LEFT OUTER JOIN edfi.Descriptor d ON rd.RaceDescriptorId = d.DescriptorId
OUTER APPLY (
-- It is possible for more than one person to be marked as primary contact, therefore 
-- we have to carefully restrict to just one record.
SELECT TOP 1
  [ContactFirstName] + ' ' + [ContactLastName] AS [ContactName],
  [RelationshipToStudent] AS [ContactRelationship],
  COALESCE(
  NULLIF([ContactHomeAddress], ''),
  NULLIF([ContactPhysicalAddress], ''),
  NULLIF([ContactMailingAddress], ''),
  NULLIF([ContactWorkAddress], ''),
  NULLIF([ContactTemporaryAddress], '')
  ) AS [ContactAddress],
  [WorkPhoneNumber] AS [ContactWorkPhoneNumber],
  [MobilePhoneNumber] AS [ContactMobilePhoneNumber],
  CASE
    WHEN [PrimaryEmailAddress] = 'Work' THEN [WorkEmailAddress]
    ELSE [PersonalEmailAddress]
  END AS [ContactEmailAddress],
  [analytics].[ContactPersonDimension].LastModifiedDate
FROM [analytics].[ContactPersonDimension]
WHERE [Student].[StudentUSI] = [ContactPersonDimension].[StudentKey]
AND [ContactPersonDimension].[IsPrimaryContact] = 1) AS [PrimaryContact]
--WHERE [StudentSchoolAssociation].[ExitWithdrawDate] IS NULL;
GO
/****** Object:  View [analytics].[TeacherCandidateContactDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateContactDimension]
AS

WITH [TeacherCandidateAddress]
AS (
   SELECT [TeacherCandidateAddress].TeacherCandidateIdentifier,
          ISNULL([TeacherCandidateAddress].[StreetNumberName], '')
          + COALESCE(', ' + [TeacherCandidateAddress].[ApartmentRoomSuiteNumber], '')
          + COALESCE(', ' + [TeacherCandidateAddress].[City], '') + COALESCE(' ' + [sad].[CodeValue], '')
          + COALESCE(' ' + [TeacherCandidateAddress].[PostalCode], '') AS [Address],
          pad.[CodeValue] AS [AddressType],
          [TeacherCandidateAddress].[CreateDate] AS [LastModifiedDate]
   FROM [tpdm].[TeacherCandidateAddress]
       INNER JOIN [edfi].[Descriptor] pad
           ON [TeacherCandidateAddress].[AddressTypeDescriptorId] = pad.[DescriptorId]
       INNER JOIN [edfi].[Descriptor] sad
           ON [TeacherCandidateAddress].[StateAbbreviationDescriptorId] = sad.[DescriptorId]),
     [TeacherCandidateTelephone]
AS (SELECT [TeacherCandidateTelephone].TeacherCandidateIdentifier,
           [TeacherCandidateTelephone].[TelephoneNumber],
           ttd.[CodeValue] AS [TelephoneNumberType],
           [TeacherCandidateTelephone].[CreateDate]
    FROM [tpdm].[TeacherCandidateTelephone]
        INNER JOIN [edfi].[Descriptor] ttd
            ON [TeacherCandidateTelephone].TelephoneNumberTypeDescriptorId = ttd.DescriptorId),
     [TeacherCandidateEmail]
AS (SELECT [TeacherCandidateElectronicMail].[TeacherCandidateIdentifier],
           [TeacherCandidateElectronicMail].[ElectronicMailAddress],
           [TeacherCandidateElectronicMail].[PrimaryEmailAddressIndicator],
           [HomeEmailType].[CodeValue] AS [EmailType],
           [TeacherCandidateElectronicMail].[CreateDate]
    FROM [tpdm].[TeacherCandidateElectronicMail]
        LEFT OUTER JOIN [edfi].[Descriptor] AS [HomeEmailType]
            ON [TeacherCandidateElectronicMail].[ElectronicMailTypeDescriptorId] = [HomeEmailType].[DescriptorId])
SELECT [TeacherCandidate].[TeacherCandidateIdentifier] AS [TeacherCandidateKey],
       [TeacherCandidate].[StudentUSI] AS [StudentKey],
       [TeacherCandidate].[FirstName] AS [FirstName],
       [TeacherCandidate].[LastSurname] AS [LastName],
   
       ISNULL([HomeAddress].[Address], '') AS [HomeAddress],
       ISNULL([PhysicalAddress].[Address], '') AS [PhysicalAddress],
       ISNULL([MailingAddress].[Address], '') AS [MailingAddress],
       ISNULL([WorkAddress].[Address], '') AS [WorkAddress],
       ISNULL([TemporaryAddress].[Address], '') AS [TemporaryAddress],
       ISNULL([HomeTelephone].[TelephoneNumber], '') AS [HomePhoneNumber],
       ISNULL([MobileTelephone].[TelephoneNumber], '') AS [MobilePhoneNumber],
       ISNULL([WorkTelephone].[TelephoneNumber], '') AS [WorkPhoneNumber],
       CASE
           WHEN [HomeEmail].[PrimaryEmailAddressIndicator] = 1 THEN
               N'Personal'
           WHEN [WorkEmail].[PrimaryEmailAddressIndicator] = 1 THEN
               N'Work'
           ELSE
               N'Not specified'
       END AS [PrimaryEmailAddress],
       ISNULL([HomeEmail].[ElectronicMailAddress], '') AS [PersonalEmailAddress],
       ISNULL([WorkEmail].[ElectronicMailAddress], '') AS [WorkEmailAddress],
 
       (
           SELECT MAX([LastModifiedDate])
           FROM
           (
               VALUES
          
                   ([TeacherCandidate].[LastModifiedDate]),
                   ([HomeAddress].[LastModifiedDate]),
                   ([PhysicalAddress].[LastModifiedDate]),
                   ([MailingAddress].[LastModifiedDate]),
                   ([WorkAddress].[LastModifiedDate]),
                   ([TemporaryAddress].[LastModifiedDate]),
                   ([HomeTelephone].[CreateDate]),
                   ([MobileTelephone].[CreateDate]),
                   ([WorkTelephone].[CreateDate]),
                   ([HomeEmail].[CreateDate]),
                   ([WorkEmail].[CreateDate])
           ) AS value ([LastModifiedDate])
       ) AS [LastModifiedDate]
FROM [tpdm].[TeacherCandidate] [TeacherCandidate] 
    LEFT OUTER JOIN [TeacherCandidateAddress] HomeAddress ON [TeacherCandidate].[TeacherCandidateIdentifier] = [HomeAddress].[TeacherCandidateIdentifier] 
           AND [HomeAddress].[AddressType] = 'Home'
    LEFT OUTER JOIN [TeacherCandidateAddress] AS [PhysicalAddress]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [PhysicalAddress].[TeacherCandidateIdentifier]
           AND [HomeAddress].[AddressType] = 'Physical'
    LEFT OUTER JOIN [TeacherCandidateAddress] AS [MailingAddress]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [MailingAddress].[TeacherCandidateIdentifier]
           AND [HomeAddress].[AddressType] = 'Mailing'
    LEFT OUTER JOIN [TeacherCandidateAddress] AS [WorkAddress]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [WorkAddress].[TeacherCandidateIdentifier]
           AND [HomeAddress].[AddressType] = 'Work'
    LEFT OUTER JOIN [TeacherCandidateAddress] AS [TemporaryAddress]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [TemporaryAddress].[TeacherCandidateIdentifier]
           AND [HomeAddress].[AddressType] = 'Temporary'
    LEFT OUTER JOIN [TeacherCandidateTelephone] AS [HomeTelephone]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [HomeTelephone].[TeacherCandidateIdentifier]
           AND [HomeTelephone].[TelephoneNumberType] = 'Home'
    LEFT OUTER JOIN [TeacherCandidateTelephone] AS [MobileTelephone]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [MobileTelephone].[TeacherCandidateIdentifier]
           AND [MobileTelephone].[TelephoneNumberType] = 'Mobile'
    LEFT OUTER JOIN [TeacherCandidateTelephone] AS [WorkTelephone]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [WorkTelephone].[TeacherCandidateIdentifier]
           AND [WorkTelephone].[TelephoneNumberType] = 'Work'
    LEFT OUTER JOIN [TeacherCandidateEmail] AS [HomeEmail]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [HomeEmail].[TeacherCandidateIdentifier]
           AND [HomeEmail].[EmailType] = 'Home/Personal'
    LEFT OUTER JOIN [TeacherCandidateEmail] AS [WorkEmail]
        ON [TeacherCandidate].[TeacherCandidateIdentifier] = [WorkEmail].[TeacherCandidateIdentifier]
           AND [WorkEmail].[EmailType] = 'Work';
GO
/****** Object:  View [analytics].[TeacherCandidateDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateDimension]
AS
WITH TeacherCandidateRaces
AS (SELECT
  tc.TeacherCandidateIdentifier,
  COUNT(DISTINCT tcr.RaceDescriptorId) AS RaceCount,
  MAX(tcr.RaceDescriptorId) AS RaceDescriptorId
FROM tpdm.TeacherCandidate tc
INNER JOIN tpdm.TeacherCandidateRace tcr
  ON tc.TeacherCandidateIdentifier = tcr.TeacherCandidateIdentifier
GROUP BY tc.TeacherCandidateIdentifier)

SELECT
  tc.TeacherCandidateIdentifier TeacherCandidateKey,
  [tc].[StudentUSI] AS [StudentKey],
  [tctppa].TeacherPreparationProviderId AS [TeacherPreparationProviderKey],
  tc.[FirstName] AS [TeacherCandidateFirstName],
  ISNULL(tc.[MiddleName], '') AS [TeacherCandidateMiddleName],
  ISNULL(tc.[LastSurname], '') AS [TeacherCandidateLastName],
  [tctppa].[EntryDate] AS [EnrollmentDate],
  d1.[CodeValue] AS [Sex],
  CASE
    WHEN TeacherCandidateRaces.RaceCount > 1 THEN 'Two or more'
    ELSE d3.CodeValue
  END AS RaceDescriptor,
  [PrimaryContact].[TeacherCandidateName],
  [PrimaryContact].[TeacherCandidateAddress],
  [PrimaryContact].[TeacherCandidateMobilePhoneNumber],
  [PrimaryContact].[TeacherCandidateWorkPhoneNumber],
  [PrimaryContact].[ContactEmailAddress],
  d.CodeValue AS TPPDegreeType,
  d2.[CodeValue] AS [GradeLevel],
  tcds.MajorSpecialization,
  tcds.MinorSpecialization,
  tc.ProgramComplete AS ProgramComplete,
  tccy.SchoolYear AS CohortYear,
  tc.EconomicDisadvantaged,
  tc.FirstGenerationStudent,
  (SELECT
    MAX([LastModifiedDate])
  FROM (VALUES ([tc].[LastModifiedDate])
  ) AS value ([LastModifiedDate]))
  AS [LastModifiedDate]
FROM tpdm.TeacherCandidate tc
LEFT JOIN tpdm.TeacherCandidateCohortYear tccy
  ON tc.TeacherCandidateIdentifier = tccy.TeacherCandidateIdentifier
INNER JOIN tpdm.TeacherCandidateTPPProgramDegree tctd
  ON tc.TeacherCandidateIdentifier = tctd.TeacherCandidateIdentifier
INNER JOIN edfi.GradeLevelDescriptor gld
  ON tctd.GradeLevelDescriptorId = gld.GradeLevelDescriptorId
INNER JOIN edfi.Descriptor d2
  ON gld.GradeLevelDescriptorId = d2.DescriptorId
LEFT JOIN tpdm.TeacherCandidateDegreeSpecialization tcds
  ON tc.TeacherCandidateIdentifier = tcds.TeacherCandidateIdentifier
INNER JOIN tpdm.TPPDegreeTypeDescriptor ttd
  ON tctd.TPPDegreeTypeDescriptorId = ttd.TPPDegreeTypeDescriptorId
INNER JOIN edfi.Descriptor d
  ON ttd.TPPDegreeTypeDescriptorId = d.DescriptorId
LEFT JOIN edfi.Descriptor d1
  ON tc.BirthSexDescriptorId = d1.DescriptorId
INNER JOIN tpdm.TeacherCandidateTeacherPreparationProviderAssociation tctppa
  ON tc.TeacherCandidateIdentifier = tctppa.TeacherCandidateIdentifier
INNER JOIN tpdm.TeacherPreparationProvider tpp
  ON tctppa.TeacherPreparationProviderId = tpp.TeacherPreparationProviderId
INNER JOIN edfi.EducationOrganization eo
  ON tpp.TeacherPreparationProviderId = eo.EducationOrganizationId
LEFT JOIN TeacherCandidateRaces
  ON tc.TeacherCandidateIdentifier = TeacherCandidateRaces.TeacherCandidateIdentifier
LEFT JOIN edfi.Descriptor d3
  ON d3.DescriptorId = TeacherCandidateRaces.RaceDescriptorId
OUTER APPLY (
-- It is possible for more than one person to be marked as primary contact, therefore 
-- we have to carefully restrict to just one record.
SELECT TOP 1
  [FirstName] + ' ' + [LastName] AS [TeacherCandidateName],
  COALESCE(
  NULLIF([HomeAddress], ''),
  NULLIF([PhysicalAddress], ''),
  NULLIF([MailingAddress], ''),
  NULLIF([WorkAddress], ''),
  NULLIF([TemporaryAddress], '')
  ) AS [TeacherCandidateAddress],
  [WorkPhoneNumber] AS [TeacherCandidateWorkPhoneNumber],
  [MobilePhoneNumber] AS [TeacherCandidateMobilePhoneNumber],
  CASE
    WHEN [PrimaryEmailAddress] = 'Work' THEN [WorkEmailAddress]
    ELSE [PersonalEmailAddress]
  END AS [ContactEmailAddress],
  tccd.LastModifiedDate
FROM [analytics].[TeacherCandidateContactDimension] tccd
WHERE tc.TeacherCandidateIdentifier = tccd.TeacherCandidateKey) AS [PrimaryContact]
WHERE tctppa.[ExitWithdrawDate] IS NULL;
GO
/****** Object:  View [analytics].[ApplicantDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[ApplicantDimension]
AS
SELECT
  a.ApplicantIdentifier AS ApplicantKey,
  a.TeacherCandidateIdentifier AS TeacherCandidateKey,
  a.FirstName + ' ' + a.LastSurname AS ApplicantFullName,
  d.CodeValue AS Sex,
  d1.CodeValue AS RaceDescriptor
FROM tpdm.Applicant a
LEFT OUTER JOIN tpdm.TeacherCandidate tc
  ON a.TeacherCandidateIdentifier = tc.TeacherCandidateIdentifier
LEFT OUTER JOIN edfi.SexDescriptor sd
  ON a.SexDescriptorId = sd.SexDescriptorId
LEFT OUTER JOIN edfi.Descriptor d
  ON sd.SexDescriptorId = d.DescriptorId
LEFT JOIN tpdm.ApplicantRace ar
  ON a.ApplicantIdentifier = ar.ApplicantIdentifier
  AND a.EducationOrganizationId = ar.EducationOrganizationId
LEFT JOIN edfi.RaceDescriptor rd
  ON ar.RaceDescriptorId = rd.RaceDescriptorId
LEFT JOIN edfi.Descriptor d1
  ON rd.RaceDescriptorId = d1.DescriptorId
GO
/****** Object:  View [analytics].[ApplicantFacts]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[ApplicantFacts]
AS

SELECT
  ApplicantIdentifier AS Applicantkey,
  [College Board examination scores],
  [ACT score],
  [Letter grade/mark]
FROM (SELECT
  asr.ApplicantIdentifier,
  asr.EducationOrganizationId,
  asr.Result,
  d.CodeValue AS AssessmentTitle
FROM tpdm.ApplicantScoreResult asr
INNER JOIN edfi.AssessmentReportingMethodDescriptor armd
  ON asr.AssessmentReportingMethodDescriptorId = armd.AssessmentReportingMethodDescriptorId
INNER JOIN edfi.Descriptor d
  ON armd.AssessmentReportingMethodDescriptorId = d.DescriptorId) t
PIVOT (
MAX(Result)
FOR AssessmentTitle IN ([College Board examination scores], [ACT score], [Letter grade/mark])
) p
GO
/****** Object:  View [analytics].[ApplicantProgramFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[ApplicantProgramFact]
AS
SELECT
  tctpppa.ApplicantIdentifier AS [ApplicantKey],
  tctpppa.[EducationOrganizationId] AS [TeacherCandidatePreparationProviderKey],
  tppp.ProgramId AS ProgramKey,
  tppp.ProgramName  ,
  MAX(a.AcceptedDate) AcceptedDate,
  MAX(WithdrawDate) WithdrawDate,
  CASE
    WHEN MAX(a.AcceptedDate) IS NOT NULL THEN 'Accepted'
    WHEN MAX(a.WithdrawDate) IS NOT NULL THEN 'Withddrawn'
    ELSE 'Uknown'
  END AS Status,
  MAX(tctpppa.GPA) AS ApplicantGPA
FROM tpdm.ApplicantTeacherPreparationProgram tctpppa
INNER JOIN tpdm.TeacherPreparationProviderProgram tppp
  ON tctpppa.EducationOrganizationId = tppp.EducationOrganizationId
INNER JOIN tpdm.Application a
  ON a.EducationOrganizationId = tctpppa.EducationOrganizationId
  AND a.ApplicantIdentifier = tctpppa.ApplicantIdentifier
  AND tppp.ProgramName = tctpppa.TeacherPreparationProgramName

GROUP BY tctpppa.ApplicantIdentifier,
         tctpppa.[EducationOrganizationId],
         tppp.ProgramId,
		 tppp.ProgramName
GO
/****** Object:  View [analytics].[LocalEducationAgencyDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[LocalEducationAgencyDimension]
AS
WITH LocalEducationAgencySuperIntendent
AS (SELECT
  lea.LocalEducationAgencyId,
  s.FirstName + ' ' + s.LastSurname AS SuperIntendentFullName
FROM edfi.StaffEducationOrganizationAssignmentAssociation seoaa
INNER JOIN edfi.EducationOrganization eo
  ON seoaa.EducationOrganizationId = eo.EducationOrganizationId
INNER JOIN edfi.LocalEducationAgency lea
  ON eo.EducationOrganizationId = lea.LocalEducationAgencyId
INNER JOIN edfi.Staff s
  ON seoaa.StaffUSI = s.StaffUSI
WHERE seoaa.PositionTitle LIKE 'Superintendent')
SELECT
  [EducationOrganization].[EducationOrganizationId] AS [LocalEducationAgencyKey],
  [EducationOrganization].[NameOfInstitution] AS [LocalEducationAgencyName],
  ISNULL(lacd.[CodeValue], '') AS [LocalEducationAgencyType],
  [LocalEducationAgency].[ParentLocalEducationAgencyId] AS [LocalEducationAgencyParentLocalEducationAgencyKey],
  ISNULL([StateEducationAgency].[NameOfInstitution], '') AS [LocalEducationAgencyStateEducationAgencyName],
  [LocalEducationAgency].[StateEducationAgencyId] AS [LocalEducationAgencyStateEducationAgencyKey],
  ISNULL([EducationServiceCenter].[NameOfInstitution], '') AS [LocalEducationAgencyServiceCenterName],
  [EducationServiceCenter].[EducationOrganizationId] AS [LocalEducationAgencyServiceCenterKey],
  ISNULL(csd.[CodeValue], '') AS [LocalEducationAgencyCharterStatus],
  SuperIntendentFullName,
  LocalEducationAgencyAddress.LocalEducationAgencyAddress, LocalEducationAgencyAddress.TelephoneNumber,

  (SELECT
    MAX([LastModifiedDate])
  FROM (VALUES ([EducationOrganization].[LastModifiedDate]), ([EducationServiceCenter].[LastModifiedDate])
  ) AS value ([LastModifiedDate]))
  AS [LastModifiedDate]
FROM [edfi].[EducationOrganization]
INNER JOIN [edfi].[LocalEducationAgency]
  ON [EducationOrganization].[EducationOrganizationId] = [LocalEducationAgency].[LocalEducationAgencyId]
LEFT OUTER JOIN [edfi].[Descriptor] lacd
  ON [LocalEducationAgency].[LocalEducationAgencyCategoryDescriptorId] = lacd.DescriptorId
LEFT OUTER JOIN [edfi].[EducationOrganization] AS [EducationServiceCenter]
  ON [LocalEducationAgency].[EducationServiceCenterId] = [EducationServiceCenter].[EducationOrganizationId]
LEFT OUTER JOIN [edfi].[Descriptor] csd
  ON [LocalEducationAgency].[CharterStatusDescriptorId] = csd.DescriptorId
LEFT OUTER JOIN [edfi].[EducationOrganization] AS [StateEducationAgency]
  ON [LocalEducationAgency].[StateEducationAgencyId] = [StateEducationAgency].[EducationOrganizationId]
LEFT OUTER JOIN LocalEducationAgencySuperIntendent
  ON edfi.LocalEducationAgency.LocalEducationAgencyId = LocalEducationAgencySuperIntendent.LocalEducationAgencyId
OUTER APPLY (SELECT TOP 1
  CONCAT(
  [EducationOrganizationAddress].[StreetNumberName],
  ', ',
  ([EducationOrganizationAddress].[ApartmentRoomSuiteNumber] + ', '),
  [EducationOrganizationAddress].[City],
  [sad].[CodeValue],
  ' ',
  [EducationOrganizationAddress].[PostalCode]
  ) AS [LocalEducationAgencyAddress],
  [EducationOrganizationAddress].[City] AS [LocalEducationAgencyCity],
  [EducationOrganizationAddress].[NameOfCounty] AS [LocalEducationAgencyCounty],
  [sad].[CodeValue] AS [LocalEducationAgencyState],
  d.CodeValue as TelephoneNumberType, eoit1.TelephoneNumber,
  [EducationOrganizationAddress].[CreateDate] AS [LastModifiedDate]
FROM [edfi].[EducationOrganizationAddress]
INNER JOIN [edfi].[Descriptor] atd
  ON [EducationOrganizationAddress].[AddressTypeDescriptorId] = atd.DescriptorId
INNER JOIN [edfi].[Descriptor] sad
  ON [EducationOrganizationAddress].[StateAbbreviationDescriptorId] = sad.DescriptorId
LEFT JOIN edfi.EducationOrganizationInstitutionTelephone eoit1 ON edfi.EducationOrganizationAddress.EducationOrganizationId = eoit1.EducationOrganizationId
LEFT JOIN edfi.Descriptor d ON atd.DescriptorId = d.DescriptorId
WHERE edfi.EducationOrganization.EducationOrganizationId = [EducationOrganizationAddress].[EducationOrganizationId]
AND [atd].[CodeValue] = 'Physical') AS [LocalEducationAgencyAddress];
GO
/****** Object:  View [analytics].[MentorTeacherGradeLevelAcademicSubject]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[MentorTeacherGradeLevelAcademicSubject]
AS
SELECT DISTINCT
  ssa.StaffUSI AS StaffKey,
  CASE
    WHEN d.CodeValue IN ('Kindergarten', 'First grade', 'Second grade', 'Third grade', 'Fourth grade', 'Fifth grade') THEN 'Grades k-5'
    WHEN d.CodeValue IN ('Sixth grade', 'Seventh grade', 'Eighth grade') THEN 'Grades 6-8'
    WHEN d.CodeValue IN ('Ninth grade', 'Tenth grade', 'Eleventh grade', 'Twelfth grade') THEN 'Grades 9-12'
  END AS GradeLevelBand,
   CASE WHEN d.CodeValue IN ('Kindergarten', 'First grade', 'Second grade', 'Third grade', 'Fourth grade', 'Fifth grade') THEN 1 
                                               WHEN d.CodeValue  IN ('Sixth grade', 'Seventh grade', 'Eighth grade') THEN 2
                                               WHEN d.CodeValue IN ('Ninth grade', 'Tenth grade', 'Eleventh grade', 'Twelfth grade') THEN 3 END AS DisplayOrder,
  CASE
    WHEN d1.CodeValue = 'English Language Arts' THEN 'ELA'
    WHEN d1.CodeValue = 'Mathematics' THEN 'Math'
    ELSE d1.CodeValue
  END AS AcademicSubjectDescriptor, co.SessionName
FROM edfi.StaffSectionAssociation ssa
INNER JOIN edfi.Section s
  ON ssa.LocalCourseCode = s.LocalCourseCode
  AND ssa.SchoolId = s.SchoolId
  AND ssa.SchoolYear = s.SchoolYear
  AND ssa.SectionIdentifier = s.SectionIdentifier
  AND ssa.SessionName = s.SessionName
INNER JOIN edfi.StudentSectionAssociation ssa1
  ON s.LocalCourseCode = ssa1.LocalCourseCode
  AND s.SchoolId = ssa1.SchoolId
  AND s.SchoolYear = ssa1.SchoolYear
  AND s.SectionIdentifier = ssa1.SectionIdentifier
  AND s.SessionName = ssa1.SessionName
INNER JOIN edfi.Student s1
  ON ssa1.StudentUSI = s1.StudentUSI
INNER JOIN edfi.StudentSchoolAssociation ssa2
  ON s1.StudentUSI = ssa2.StudentUSI
INNER JOIN edfi.GradeLevelDescriptor gld
  ON ssa2.EntryGradeLevelDescriptorId = gld.GradeLevelDescriptorId
INNER JOIN edfi.Descriptor d
  ON gld.GradeLevelDescriptorId = d.DescriptorId
INNER JOIN edfi.CourseOffering co
  ON s.LocalCourseCode = co.LocalCourseCode
  AND s.SchoolId = co.SchoolId
  AND s.SchoolYear = co.SchoolYear
  AND s.SessionName = co.SessionName
INNER JOIN edfi.Course c
  ON co.CourseCode = c.CourseCode
  AND co.EducationOrganizationId = c.EducationOrganizationId
INNER JOIN edfi.AcademicSubjectDescriptor asd
  ON c.AcademicSubjectDescriptorId = asd.AcademicSubjectDescriptorId
INNER JOIN edfi.Descriptor d1
  ON d1.DescriptorId = asd.AcademicSubjectDescriptorId
LEFT JOIN edfi.Session s2 ON co.SchoolId = s2.SchoolId AND co.SchoolYear = s2.SchoolYear AND co.SessionName = s2.SessionName


WHERE d1.CodeValue IN ('Mathematics', 'English Language Arts', 'Science', 'Social Studies')
GO
/****** Object:  View [analytics].[MentorTeacherProfessionalDevelopment]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[MentorTeacherProfessionalDevelopment]
AS
WITH StaffProfessionalDevelopmentEvent AS 
  (
SELECT
  spdea.StaffUSI AS StaffKey,
  spdea.AttendanceDate,
  spdea.ProfessionalDevelopmentTitle,
  d.CodeValue AS StaffCassificationDescriptor,
  ROW_NUMBER() OVER (PARTITION BY s.StaffUSI, spdea.ProfessionalDevelopmentTitle ORDER BY spdea.AttendanceDate DESC) Recent

FROM edfi.Staff s
LEFT JOIN tpdm.StaffProfessionalDevelopmentEventAttendance spdea
  ON s.StaffUSI = spdea.StaffUSI
LEFT JOIN edfi.StaffEducationOrganizationAssignmentAssociation seoaa
  ON spdea.StaffUSI = seoaa.StaffUSI
LEFT JOIN edfi.StaffClassificationDescriptor scd
  ON seoaa.StaffClassificationDescriptorId = scd.StaffClassificationDescriptorId
LEFT JOIN edfi.Descriptor d
  ON scd.StaffClassificationDescriptorId = d.DescriptorId
WHERE d.CodeValue LIKE 'Mentor Teacher'
)
SELECT  StaffKey,
        AttendanceDate,
        ProfessionalDevelopmentTitle,
        StaffCassificationDescriptor, CASE WHEN ProfessionalDevelopmentTitle LIKE 'Classroom Management' THEN 'Completed' ELSE 'Not Completed' END AS Status
  FROM StaffProfessionalDevelopmentEvent
  WHERE Recent = 1
GO
/****** Object:  View [analytics].[ProgramTypeDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[ProgramTypeDimension] AS

	SELECT 
		[ptd].[ProgramTypeDescriptorId] AS [ProgramTypeKey],
		[CodeValue] AS [ProgramType]
	FROM
		[edfi].[ProgramTypeDescriptor] ptd
		INNER JOIN edfi.Descriptor d ON d.DescriptorId = ptd.ProgramTypeDescriptorId
GO
/****** Object:  View [analytics].[SchoolDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[SchoolDimension]
AS

WITH    AccountablityRating
          AS ( SELECT   s.SchoolId ,
                        ar.Rating
               FROM     edfi.School s
                        INNER JOIN edfi.EducationOrganization eo ON s.SchoolId = eo.EducationOrganizationId
                        INNER JOIN edfi.AccountabilityRating ar ON eo.EducationOrganizationId = ar.EducationOrganizationId
               WHERE    ar.SchoolYear = ( SELECT    MAX(SchoolYear)
                                          FROM      edfi.AccountabilityRating
                                        )
             )
    SELECT  [School].[SchoolId] AS [SchoolKey] ,
            [EducationOrganization].[NameOfInstitution] AS [SchoolName] ,
            ISNULL([std].[CodeValue], '') AS [SchoolType] ,
            ISNULL(AccountablityRating.Rating, '') Rating ,
            ISNULL(d.CodeValue, '') AS SchoolCategoryType ,
            ISNULL([SchoolAddress].[SchoolAddress], '') AS [SchoolAddress] ,
            ISNULL([SchoolAddress].[SchoolCity], '') AS [SchoolCity] ,
            ISNULL([SchoolAddress].[SchoolCounty], '') AS [SchoolCounty] ,
            ISNULL([SchoolAddress].[SchoolState], '') AS [SchoolState] ,
            ISNULL([EdOrgLocal].[NameOfInstitution], '') AS [LocalEducationAgencyName] ,
            [EdOrgLocal].[EducationOrganizationId] AS [LocalEducationAgencyKey] ,
            ISNULL([EdOrgState].[NameOfInstitution], '') AS [StateEducationAgencyName] ,
            [EdOrgState].[EducationOrganizationId] AS [StateEducationAgencyKey] ,
            ISNULL([EdOrgServiceCenter].[NameOfInstitution], '') AS [EducationServiceCenterName] ,
            [EdOrgServiceCenter].[EducationOrganizationId] AS [EducationServiceCenterKey] ,
            d1.Description FederalLocaleCode ,
            ( SELECT    MAX([LastModifiedDate])
              FROM      ( VALUES ( [EducationOrganization].[LastModifiedDate]),
                        ( [std].[LastModifiedDate]),
                        ( [EdOrgLocal].[LastModifiedDate]),
                        ( [EdOrgState].[LastModifiedDate]),
                        ( [EdOrgServiceCenter].[LastModifiedDate]),
                        ( [SchoolAddress].[LastModifiedDate]) ) AS value ( [LastModifiedDate] )
            ) AS [LastModifiedDate]
    FROM    [edfi].[School]
            INNER JOIN [edfi].[EducationOrganization] ON [School].[SchoolId] = [EducationOrganization].[EducationOrganizationId]
            LEFT OUTER JOIN [edfi].[Descriptor] std ON [School].[SchoolTypeDescriptorId] = std.DescriptorId
            LEFT OUTER JOIN [edfi].[LocalEducationAgency] ON [School].[LocalEducationAgencyId] = [LocalEducationAgency].[LocalEducationAgencyId]
            LEFT OUTER JOIN [edfi].[EducationOrganization] AS [EdOrgLocal] ON [School].[LocalEducationAgencyId] = [EdOrgLocal].[EducationOrganizationId]
            LEFT OUTER JOIN [edfi].[EducationOrganization] AS [EdOrgState] ON [LocalEducationAgency].[StateEducationAgencyId] = [EdOrgState].[EducationOrganizationId]
            LEFT OUTER JOIN [edfi].[EducationOrganization] AS [EdOrgServiceCenter] ON [LocalEducationAgency].[EducationServiceCenterId] = [EdOrgServiceCenter].EducationOrganizationId
            LEFT OUTER JOIN AccountablityRating ON School.SchoolId = AccountablityRating.SchoolId
            LEFT OUTER JOIN edfi.SchoolCategory sc ON School.SchoolId = sc.SchoolId
            LEFT OUTER JOIN edfi.SchoolCategoryDescriptor scd ON sc.SchoolCategoryDescriptorId = scd.SchoolCategoryDescriptorId
            LEFT OUTER JOIN edfi.Descriptor d ON scd.SchoolCategoryDescriptorId = d.DescriptorId
            LEFT JOIN tpdm.SchoolExtension se ON se.SchoolId = [School].SchoolId
            LEFT JOIN edfi.Descriptor d1 ON se.FederalLocaleCodeDescriptorId = d1.DescriptorId
            OUTER APPLY ( SELECT TOP 1
                                    CONCAT([EducationOrganizationAddress].[StreetNumberName],
                                           ', ',
                                           ( [EducationOrganizationAddress].[ApartmentRoomSuiteNumber]
                                             + ', ' ),
                                           [EducationOrganizationAddress].[City],
                                           [sad].[CodeValue], ' ',
                                           [EducationOrganizationAddress].[PostalCode]) AS [SchoolAddress] ,
                                    [EducationOrganizationAddress].[City] AS [SchoolCity] ,
                                    [EducationOrganizationAddress].[NameOfCounty] AS [SchoolCounty] ,
                                    [sad].[CodeValue] AS [SchoolState] ,
                                    [EducationOrganizationAddress].[CreateDate] AS [LastModifiedDate]
                          FROM      [edfi].[EducationOrganizationAddress]
                                    INNER JOIN [edfi].[Descriptor] atd ON [EducationOrganizationAddress].[AddressTypeDescriptorId] = atd.DescriptorId
                                    INNER JOIN [edfi].[Descriptor] sad ON [EducationOrganizationAddress].[StateAbbreviationDescriptorId] = sad.DescriptorId
                          WHERE     [School].[SchoolId] = [EducationOrganizationAddress].[EducationOrganizationId]
                                    AND [atd].[CodeValue] = 'Physical'
                        ) AS [SchoolAddress];
GO
/****** Object:  View [analytics].[SchoolFacts]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[SchoolFacts]
AS
WITH EducationOrganizationFactsMaxDate
AS (SELECT
  eof.EducationOrganizationId,
  MAX(eof.FactsAsOfDate) AS FactsAsOfDate
FROM tpdm.EducationOrganizationFacts eof
GROUP BY eof.EducationOrganizationId),
RaceTypeAggregate
AS (SELECT
  EducationOrganizationId,
  FactAsOfDate,
  ValueTypeDescriptor,
  [American Indian - Alaska Native],
  [Asian],
  [Black - African American],
  [Choose Not to Respond],
  [Native Hawaiian - Pacific Islander],
  [White],
  [Other],
  [Two or More],
  [Hispanic/Latino]
FROM (SELECT
  eosfar.EducationOrganizationId,
  eosfar.FactAsOfDate,
  eosfar.ValueTypeDescriptorId,
  eosfar.RaceTypeNumber,
  eosfar.RaceTypePercentage,
  d.CodeValue RaceTypeDescriptor,
  d1.CodeValue AS ValueTypeDescriptor
FROM tpdm.EducationOrganizationStudentFactsAggregatedRace eosfar
INNER JOIN EducationOrganizationFactsMaxDate
  ON eosfar.EducationOrganizationId = EducationOrganizationFactsMaxDate.EducationOrganizationId
  AND EducationOrganizationFactsMaxDate.FactsAsOfDate = eosfar.FactAsOfDate
INNER JOIN edfi.RaceDescriptor rd
  ON eosfar.RaceDescriptorId = rd.RaceDescriptorId
INNER JOIN edfi.Descriptor d
  ON rd.RaceDescriptorId = d.DescriptorId
LEFT JOIN tpdm.ValueTypeDescriptor vtd
  ON eosfar.ValueTypeDescriptorId = vtd.ValueTypeDescriptorId
LEFT JOIN edfi.Descriptor d1
  ON vtd.ValueTypeDescriptorId = d1.DescriptorId
WHERE d1.CodeValue LIKE 'Actual') t
PIVOT (
MAX(t.RaceTypePercentage)
FOR RaceTypeDescriptor IN ([American Indian - Alaska Native], [Asian], [Black - African American], [Choose Not to Respond], [Native Hawaiian - Pacific Islander], [White], [Other], [Two or More], [Hispanic/Latino])
) p),

EnrolledTeacherCandidates
AS (SELECT
  tcfe.SchoolId,
  COUNT(distinct tc.TeacherCandidateIdentifier) AS CandidatesPlaced
FROM tpdm.TeacherCandidate tc
INNER JOIN tpdm.TeacherCandidateFieldworkExperience tcfe
  ON tc.TeacherCandidateIdentifier = tcfe.TeacherCandidateIdentifier
GROUP BY tcfe.SchoolId),
EmployeedTeacherCandidates
AS (SELECT
  seoaa.EducationOrganizationId,
  COUNT(DISTINCT s.StaffUSI) AS CandidatesEmployeed
FROM edfi.StaffEducationOrganizationAssignmentAssociation seoaa
INNER JOIN edfi.Staff s
  ON seoaa.StaffUSI = s.StaffUSI
INNER JOIN tpdm.TeacherCandidate tc
  ON tc.TeacherCandidateIdentifier = s.StaffUniqueId
GROUP BY seoaa.EducationOrganizationId),
HomlessStudents
AS (SELECT
  shpa.EducationOrganizationId,
  (COUNT(DISTINCT shpa.StudentUSI) * 1.0 / COUNT(DISTINCT ssa.StudentUSI)) AS HomelessStudentPercentage
FROM edfi.StudentSchoolAssociation ssa
LEFT JOIN edfi.StudentHomelessProgramAssociation shpa
  ON ssa.EducationOrganizationId = shpa.EducationOrganizationId
GROUP BY shpa.EducationOrganizationId)

SELECT
  s.SchoolId AS SchoolKey,
  eosf.FactsAsOfDate,
  eosf.SchoolYear,
  eosf.NumberAdministratorsEmployed,
  eosf.NumberStudentsEnrolled,
  eosf.NumberTeachersEmployed,
  CandidatesEmployeed,
  CandidatesPlaced,
  eosf.PercentStudentsFreeReducedLunch,
  eosf.PercentStudentsLimitedEnglishProficiency,
  eosf.PercentStudentsSpecialEducation,
  HomelessStudentPercentage,
  eosf.HiringRate,
  eosf.RetentionRate,
  eosf.RetirementRate,
  eosf.AverageYearsInDistrictEmployed,
  [American Indian - Alaska Native],
  [Asian],
  [Black - African American],
  [Choose Not to Respond],
  [Native Hawaiian - Pacific Islander],
  [White],
  [Other],
  [Two or More],
  [Hispanic/Latino],
  CASE
    WHEN eosf.PercentStudentsLimitedEnglishProficiency > 0.2 OR
      eosf.PercentStudentsFreeReducedLunch > 0.6 OR
      eosf.PercentStudentsSpecialEducation > 0.15 THEN 'Yes'
    ELSE 'No'
  END AS HighNeed
FROM tpdm.EducationOrganizationFacts eosf
INNER JOIN edfi.EducationOrganization eo
  ON eosf.EducationOrganizationId = eo.EducationOrganizationId
INNER JOIN edfi.School s
  ON eo.EducationOrganizationId = s.SchoolId
INNER JOIN EducationOrganizationFactsMaxDate lef
  ON eosf.EducationOrganizationId = lef.EducationOrganizationId
  AND eosf.FactsAsOfDate = lef.FactsAsOfDate
LEFT JOIN RaceTypeAggregate
  ON eosf.EducationOrganizationId = RaceTypeAggregate.EducationOrganizationId
  AND eosf.FactsAsOfDate = RaceTypeAggregate.FactAsOfDate
LEFT JOIN EmployeedTeacherCandidates
  ON eosf.EducationOrganizationId = EmployeedTeacherCandidates.EducationOrganizationId
  AND eosf.FactsAsOfDate = RaceTypeAggregate.FactAsOfDate
LEFT JOIN EnrolledTeacherCandidates
  ON s.SchoolId = EnrolledTeacherCandidates.SchoolId
LEFT JOIN HomlessStudents
  ON eosf.EducationOrganizationId = HomlessStudents.EducationOrganizationId
GO
/****** Object:  View [analytics].[SchoolNetworkAssociationDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[SchoolNetworkAssociationDimension] AS

	SELECT
		[School].[SchoolId]AS [SchoolKey],
		[EducationOrganization].[NameOfInstitution] AS [NetworkName],
		[EducationOrganizationNetworkAssociation].[EducationOrganizationNetworkId] AS [NetworkKey],
		[npd].[CodeValue] AS [NetworkPurpose],
		[EducationOrganizationNetworkAssociation].[BeginDate],
		[EducationOrganizationNetworkAssociation].[EndDate]
	FROM
		[edfi].[EducationOrganizationNetworkAssociation]
	INNER JOIN
		[edfi].[EducationOrganizationNetwork] ON
			[EducationOrganizationNetworkAssociation].[EducationOrganizationNetworkId] = [EducationOrganizationNetwork].[EducationOrganizationNetworkId]
	INNER JOIN
		[edfi].[School] ON
			[EducationOrganizationNetworkAssociation].[MemberEducationOrganizationId] = [School].[SchoolId]
	INNER JOIN
		[edfi].[EducationOrganization] ON
			[EducationOrganizationNetworkAssociation].[EducationOrganizationNetworkId] = [EducationOrganization].[EducationOrganizationId]
	INNER JOIN
		[edfi].[Descriptor] npd ON
			[EducationOrganizationNetwork].[NetworkPurposeDescriptorId] = [npd].DescriptorId
GO
/****** Object:  View [analytics].[SchoolStudentAssessmentFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[SchoolStudentAssessmentFact]
AS
/* This query has flaw that it doesn't look at the max date for the fact , the reason is the issue with the data model */
WITH SchoolStudentAssessmentFact

AS (SELECT
  eosaf.EducationOrganizationId,
 CASE WHEN  d1.CodeValue = 'English Language Arts' THEN 'ELA'
                    WHEN d1.CodeValue = 'Mathematics' THEN 'Math' ELSE d1.CodeValue END AS AcademicSubjectDescriptor,
  d.CodeValue GradeLevelDescriptor,
  CASE
    WHEN d.CodeValue IN ('Kindergarten', 'First grade', 'Second grade', 'Third grade', 'Fourth grade', 'Fifth grade') THEN 'Grades k-5'
    WHEN d.CodeValue IN ('Sixth grade', 'Seventh grade', 'Eighth grade') THEN 'Grades 6-8'
    WHEN d.CodeValue IN ('Ninth grade', 'Tenth grade', 'Eleventh grade', 'Twelfth grade') THEN 'Grades 9-12'
  END AS GradeLevels,
  eosafapl.PerformanceLevelMetPercentage
FROM tpdm.EducationOrganizationStudentAssessmentFacts eosaf
INNER JOIN tpdm.EducationOrganizationStudentAssessmentFactsAggregatedPerformanceLevel eosafapl
  ON eosaf.EducationOrganizationId = eosafapl.EducationOrganizationId
  AND eosaf.FactAsOfDate = eosafapl.FactAsOfDate
  AND eosaf.TakenSchoolYear = eosafapl.TakenSchoolYear
INNER JOIN edfi.GradeLevelDescriptor gld
  ON eosaf.GradeLevelDescriptorId = gld.GradeLevelDescriptorId
INNER JOIN edfi.Descriptor d
  ON gld.GradeLevelDescriptorId = d.DescriptorId
INNER JOIN edfi.AcademicSubjectDescriptor asd
  ON eosaf.AcademicSubjectDescriptorId = asd.AcademicSubjectDescriptorId
INNER JOIN edfi.Descriptor d1
  ON asd.AcademicSubjectDescriptorId = d1.DescriptorId
INNER JOIN edfi.School s
  ON s.SchoolId = eosaf.EducationOrganizationId)

SELECT
  EducationOrganizationId AS SchoolKey,
  GradeLevels, AcademicSubjectDescriptor,
  
  
   CASE WHEN GradeLevels = 'Grades k-5' THEN 1 
                                               WHEN GradeLevels = 'Grades 6-8' THEN 2
                                               WHEN GradeLevels = 'Grades 9-12' THEN 3 END AS DisplayOrder,
  AVG(PerformanceLevelMetPercentage) AS PerformanceLevelMetPercentage
FROM SchoolStudentAssessmentFact
WHERE GradeLevels IS NOT NULL 
GROUP BY EducationOrganizationId,
         GradeLevels, GradeLevels, AcademicSubjectDescriptor
GO
/****** Object:  View [analytics].[Section]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[Section] AS 
SELECT 
  c.CourseCode AS CourseKey,
  s.SchoolId SchoolKey,
  s.SectionIdentifier SectionKey,
  s.SchoolYear,
  s.SessionName
FROM edfi.Section s
INNER JOIN edfi.CourseOffering co
  ON s.LocalCourseCode = co.LocalCourseCode
  AND s.SchoolId = co.SchoolId
  AND s.SessionName = co.SessionName
INNER JOIN edfi.Course c
  ON co.CourseCode = c.CourseCode
  AND co.EducationOrganizationId = c.EducationOrganizationId
GO
/****** Object:  View [analytics].[StaffCredential]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StaffCredential]
AS
SELECT
  s.StaffUSI AS StaffKey,
  c.CredentialIdentifier CredentialKey,
  d1.CodeValue AS StateOfIssue,
  d.CodeValue AS CredentialField
FROM edfi.Staff s
INNER JOIN edfi.StaffCredential sc
  ON s.StaffUSI = sc.StaffUSI
INNER JOIN edfi.Credential c
  ON sc.CredentialIdentifier = c.CredentialIdentifier
  AND sc.StateOfIssueStateAbbreviationDescriptorId = c.StateOfIssueStateAbbreviationDescriptorId
INNER JOIN edfi.CredentialFieldDescriptor cfd
  ON c.CredentialFieldDescriptorId = cfd.CredentialFieldDescriptorId
INNER JOIN edfi.Descriptor d
  ON cfd.CredentialFieldDescriptorId = d.DescriptorId
INNER JOIN edfi.StateAbbreviationDescriptor sad
  ON c.StateOfIssueStateAbbreviationDescriptorId = sad.StateAbbreviationDescriptorId
INNER JOIN edfi.Descriptor d1
  ON d1.DescriptorId = c.StateOfIssueStateAbbreviationDescriptorId
GO
/****** Object:  View [analytics].[StaffDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StaffDimension]
AS
SELECT
  a.StaffUSI AS StaffKey,
  a.FirstName + ' ' + a.LastSurname AS StaffFullName,
  d.CodeValue AS RaceDescriptor,
  d1.CodeValue AS Sex
FROM edfi.Staff a
LEFT JOIN edfi.StaffRace sr
  ON a.StaffUSI = sr.StaffUSI
LEFT JOIN edfi.RaceDescriptor rd
  ON sr.RaceDescriptorId = rd.RaceDescriptorId
LEFT JOIN edfi.Descriptor d
  ON rd.RaceDescriptorId = d.DescriptorId
LEFT JOIN edfi.SexDescriptor sd
  ON a.SexDescriptorId = sd.SexDescriptorId
LEFT JOIN edfi.Descriptor d1
  ON sd.SexDescriptorId = d1.DescriptorId
WHERE a.StaffUSI IN (SELECT
  a.StaffUSI
FROM edfi.StaffEducationOrganizationAssignmentAssociation seoaa
INNER JOIN edfi.StaffClassificationDescriptor scd
  ON seoaa.StaffClassificationDescriptorId = scd.StaffClassificationDescriptorId
INNER JOIN edfi.Descriptor d2
  ON scd.StaffClassificationDescriptorId = d2.DescriptorId
WHERE d2.CodeValue LIKE 'Mentor Teacher'
OR d2.CodeValue LIKE 'Site Coordinator')
GO
/****** Object:  View [analytics].[StaffEducationOrganizationAssociationDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StaffEducationOrganizationAssociationDimension]
AS
SELECT DISTINCT
  seoaa.EducationOrganizationId AS  EducationOrganizationKey,
  seoaa.StaffUSI StaffKey,
  d.CodeValue AS StaffClassificationDescriptor
FROM edfi.StaffEducationOrganizationAssignmentAssociation seoaa
INNER JOIN edfi.StaffClassificationDescriptor scd
  ON seoaa.StaffClassificationDescriptorId = scd.StaffClassificationDescriptorId
INNER JOIN edfi.Descriptor d
  ON scd.StaffClassificationDescriptorId = d.DescriptorId
GO
/****** Object:  View [analytics].[StaffSectionAssociation]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StaffSectionAssociation]
AS
SELECT DISTINCT
  ssa.SectionIdentifier AS SectionKey,
  ssa.StaffUSI AS StaffKey,
  ssa.LocalCourseCode,
  ssa.SchoolId,
  ssa.SchoolYear,
  ssa.SessionName,
  ssa.BeginDate,
  ssa.EndDate
FROM edfi.StaffSectionAssociation ssa
INNER JOIN edfi.Staff
  ON ssa.StaffUSI = edfi.Staff.StaffUSI
INNER JOIN tpdm.TeacherCandidate tc
  ON tc.TeacherCandidateIdentifier = Staff.StaffUniqueId
GO
/****** Object:  View [analytics].[StaffStudentGrowthMeasure]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StaffStudentGrowthMeasure] as
SELECT
  [StaffUSI] AS StaffKey,
  [FactAsOfDate],
  [SchoolYear],
  [StudentGrowthMeasureDate],
  d.CodeValue [ResultDatatypeType],
  d1.CodeValue AS [StudentGrowthType],
  [StudentGrowthTargetScore],
  [StudentGrowthActualScore],
  [StudentGrowthMet],
  [StudentGrowthNCount]
FROM [tpdm].[StaffStudentGrowthMeasure]
INNER JOIN edfi.ResultDatatypeTypeDescriptor rdtd
  ON tpdm.StaffStudentGrowthMeasure.ResultDatatypeTypeDescriptorId = rdtd.ResultDatatypeTypeDescriptorId
INNER JOIN edfi.Descriptor d
  ON d.DescriptorId = rdtd.ResultDatatypeTypeDescriptorId
INNER JOIN tpdm.StudentGrowthTypeDescriptor sgtd
  ON tpdm.StaffStudentGrowthMeasure.StudentGrowthTypeDescriptorId = sgtd.StudentGrowthTypeDescriptorId
INNER JOIN edfi.Descriptor d1
  ON d1.DescriptorId = sgtd.StudentGrowthTypeDescriptorId
GO
/****** Object:  View [analytics].[StaffSurveyResponseFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StaffSurveyResponseFact]
AS
SELECT
  sqr.SurveyResponseIdentifier AS SurveyResponseKey,
  sr.StaffUSI AS Staffkey,
  s.SurveyIdentifier,
  s.SurveyTitle,
  ss.SurveySectionTitle,
  sq.QuestionText,
  sqr.TextResponse,
  sqr.NoResponse
FROM tpdm.Survey s
INNER JOIN tpdm.SurveySection ss
  ON s.SurveyIdentifier = ss.SurveyIdentifier
INNER JOIN tpdm.SurveyQuestion sq
  ON s.SurveyIdentifier = sq.SurveyIdentifier
INNER JOIN tpdm.SurveyQuestionResponse sqr
  ON sq.QuestionCode = sqr.QuestionCode
  AND sq.SurveyIdentifier = sqr.SurveyIdentifier
INNER JOIN tpdm.SurveyResponse sr
  ON sqr.SurveyIdentifier = sr.SurveyIdentifier
  AND sqr.SurveyResponseIdentifier = sr.SurveyResponseIdentifier
INNER JOIN tpdm.QuestionFormDescriptor qfd
  ON sq.QuestionFormDescriptorId = qfd.QuestionFormDescriptorId
INNER JOIN edfi.Descriptor d
  ON qfd.QuestionFormDescriptorId = d.DescriptorId
WHERE s.SurveyTitle LIKE 'Mentor Teacher Self Reflection Survey'
OR s.SurveyTitle LIKE 'Principal Feeback Survey'
OR s.SurveyTitle LIKE 'TPP Support Survey'
GO
/****** Object:  View [analytics].[StudentAssessment]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE EdFi_Ods_TPDM_Base
--GO
--
--SET QUOTED_IDENTIFIER, ANSI_NULLS ON
--GO
--
--
----USE EdFi_Ods_TPDM_Base
----GO
----
----DROP VIEW analytics.TeacherCandidateAcademicFact
----GO
----
----SET QUOTED_IDENTIFIER, ANSI_NULLS ON
----GO
----
--
--
--
----USE EdFi_Ods_TPDM_Base
----GO
----
----DROP VIEW analytics.TeacherCandidateGradePointAverageFact
----GO
----
----SET QUOTED_IDENTIFIER, ANSI_NULLS ON
----GO
----EdFi_Ods_TPDM_Base.edfi.Assessment
----
CREATE VIEW [analytics].[StudentAssessment]
AS
WITH StudentAssessmentMaxAdministrationDate
AS (SELECT
  sa.AssessmentTitle,
  sa.StudentUSI,
  MAX(sa.AdministrationDate) AS MaxAdminstrationDate
FROM edfi.StudentAssessment sa
GROUP BY sa.AssessmentTitle,
         sa.StudentUSI),

StudentAssessment
AS (SELECT
  sa.StudentUSI,
  sa.AssessmentTitle,
  sasr.Result,
  d.CodeValue AS PerformanceLevel,
  sapl.PerformanceLevelMet,
  ROW_NUMBER() OVER (PARTITION BY sa.StudentUSI, sa.AssessmentTitle ORDER BY sa.AdministrationDate DESC) Latest
FROM edfi.StudentAssessment sa

INNER JOIN edfi.StudentAssessmentScoreResult sasr
  ON sa.AcademicSubjectDescriptorId = sasr.AcademicSubjectDescriptorId
  AND sa.AdministrationDate = sasr.AdministrationDate
  AND sa.AssessedGradeLevelDescriptorId = sasr.AssessedGradeLevelDescriptorId
  AND sa.AssessmentTitle = sasr.AssessmentTitle
  AND sa.AssessmentVersion = sasr.AssessmentVersion
  AND sa.StudentUSI = sasr.StudentUSI
INNER JOIN edfi.StudentAssessmentPerformanceLevel sapl
  ON sa.AcademicSubjectDescriptorId = sapl.AcademicSubjectDescriptorId
  AND sa.AdministrationDate = sapl.AdministrationDate
  AND sa.AssessedGradeLevelDescriptorId = sapl.AssessedGradeLevelDescriptorId
  AND sa.AssessmentTitle = sapl.AssessmentTitle
  AND sa.AssessmentVersion = sapl.AssessmentVersion
  AND sa.StudentUSI = sapl.StudentUSI
INNER JOIN edfi.PerformanceLevelDescriptor pld
  ON sapl.PerformanceLevelDescriptorId = pld.PerformanceLevelDescriptorId
INNER JOIN edfi.Descriptor d
  ON pld.PerformanceLevelDescriptorId = d.DescriptorId
INNER JOIN StudentAssessmentMaxAdministrationDate tcamad
  ON sa.AssessmentTitle = tcamad.AssessmentTitle
  AND sa.StudentUSI = tcamad.StudentUSI
  AND sa.AdministrationDate = tcamad.MaxAdminstrationDate)
SELECT
  sa.StudentUSI StudentKey,
  AssessmentTitle,
  Result,
  PerformanceLevelMet,
  Latest,
  PerformanceLevel,
  d1.CodeValue AS GradeLevelDescriptor,
  CASE
    WHEN d1.CodeValue = 'First grade' THEN 1
    WHEN d1.CodeValue = 'Second grade' THEN 2
    WHEN d1.CodeValue = 'Third grade' THEN 3
    WHEN d1.CodeValue = 'Fourth grade' THEN 4
    WHEN d1.CodeValue = 'Fifth grade' THEN 5
    WHEN d1.CodeValue = 'Sixth grade' THEN 6
    WHEN d1.CodeValue = 'Seventh grade' THEN 7
    WHEN d1.CodeValue = 'Eighth grade' THEN 8
    WHEN d1.CodeValue = 'Ninth grade' THEN 9
    WHEN d1.CodeValue = 'Tenth grade' THEN 10
    WHEN d1.CodeValue = 'Eleventh grade' THEN 11
    WHEN d1.CodeValue = 'Twelfth grade' THEN 12
  END GradeLevelOrder
FROM StudentAssessment sa
LEFT JOIN edfi.StudentSchoolAssociation ssa
  ON sa.StudentUSI = ssa.StudentUSI
LEFT JOIN edfi.GradeLevelDescriptor gld
  ON gld.GradeLevelDescriptorId = ssa.EntryGradeLevelDescriptorId
LEFT JOIN edfi.Descriptor d1
  ON d1.DescriptorId = gld.GradeLevelDescriptorId
WHERE sa.AssessmentTitle LIKE '%State%'
GO
/****** Object:  View [analytics].[StudentSectionDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StudentSectionDimension]
AS
SELECT
  SectionIdentifier AS SectionKey,
  StudentUSI as StudentKey, 
  Course.CourseCode as CourseKey,
  asd.CodeValue as AcademicSubject, 
  CourseOffering.SchoolYear, 
  CourseOffering.SessionName
FROM [edfi].[StudentSectionAssociation]
INNER JOIN [edfi].[CourseOffering]
  ON [CourseOffering].[SchoolId] = [StudentSectionAssociation].[SchoolId]
  AND [CourseOffering].[LocalCourseCode] = [StudentSectionAssociation].[LocalCourseCode]
  AND [CourseOffering].[SessionName] = [StudentSectionAssociation].[SessionName]
  AND [CourseOffering].[SchoolYear] = [StudentSectionAssociation].[SchoolYear]
INNER JOIN [edfi].[Course]
  ON [Course].[CourseCode] = [CourseOffering].[CourseCode]
  AND [Course].[EducationOrganizationId] = [CourseOffering].[EducationOrganizationId]
LEFT OUTER JOIN [edfi].[AcademicSubjectDescriptor]
  ON [AcademicSubjectDescriptor].[AcademicSubjectDescriptorId] = [Course].[AcademicSubjectDescriptorId]
LEFT OUTER JOIN [edfi].[Descriptor] asd
  ON asd.[DescriptorId] = [AcademicSubjectDescriptor].[AcademicSubjectDescriptorId];
GO
/****** Object:  View [analytics].[StudentSectionGradeFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[StudentSectionGradeFact]
AS
SELECT [Grade].[StudentUSI] AS [StudentKey],
       [Grade].[SchoolId] AS [SchoolKey],
       CAST([Grade].[GradingPeriodDescriptorId] AS NVARCHAR) + '-' + CAST([Grade].[SchoolId] AS NVARCHAR) + '-'
       + CONVERT(NVARCHAR, [Grade].[BeginDate], 112) AS [GradingPeriodKey],
       CAST([Grade].[StudentUSI] AS NVARCHAR) + '-' + CAST([Grade].[SchoolId] AS NVARCHAR) + '-'
       + [Grade].[SessionName] + '-' + [Grade].[SectionIdentifier] + '-' + [Grade].[LocalCourseCode] + '-'
       + CAST([Grade].[SchoolYear] AS NVARCHAR) + '-' + CONVERT(NVARCHAR, [Grade].[BeginDate], 112) AS [StudentSectionKey],
       CAST([Grade].[SchoolId] AS NVARCHAR) + '-' + [Grade].[SessionName] + '-' + [Grade].[SectionIdentifier] + '-'
       + [Grade].[LocalCourseCode] + '-' + CAST([Grade].[SchoolYear] AS NVARCHAR) AS [SectionKey],
       [Grade].[NumericGradeEarned]
FROM [edfi].[Grade]
    INNER JOIN [edfi].[Descriptor]
        ON [Grade].[GradeTypeDescriptorId] = [edfi].[Descriptor].[DescriptorId]
    INNER JOIN [edfi].[GradingPeriod]
        ON [Grade].[GradingPeriodDescriptorId] = [GradingPeriod].[GradingPeriodDescriptorId]
           AND [Grade].[SchoolId] = [GradingPeriod].[SchoolId]
           AND [Grade].[BeginDate] = [GradingPeriod].[BeginDate]
    INNER JOIN [edfi].[Descriptor] AS [GradingPeriodDescriptor]
        ON [GradingPeriod].[GradingPeriodDescriptorId] = [GradingPeriodDescriptor].[DescriptorId]
WHERE [edfi].[Descriptor].[CodeValue] = 'Grading Period';
GO
/****** Object:  View [analytics].[SurveyQuestionResponseFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[SurveyQuestionResponseFact]
AS
SELECT
  sqr.SurveyResponseIdentifier AS SurveyResponseKey,
  srtca.TeacherCandidateIdentifier AS TeacherCandidateKey,
  sr.StudentUSI AS StudentKey,
  s.SurveyIdentifier,
  s.SurveyTitle,
  ss.SurveySectionTitle,
  sq.QuestionText,
  sqr.TextResponse,
  sqr.NoResponse
FROM tpdm.Survey s
INNER JOIN tpdm.SurveySection ss
  ON s.SurveyIdentifier = ss.SurveyIdentifier
INNER JOIN tpdm.SurveyQuestion sq
  ON s.SurveyIdentifier = sq.SurveyIdentifier
INNER JOIN tpdm.SurveyQuestionResponse sqr
  ON sq.QuestionCode = sqr.QuestionCode
  AND sq.SurveyIdentifier = sqr.SurveyIdentifier
INNER JOIN tpdm.SurveyResponse sr
  ON sqr.SurveyIdentifier = sr.SurveyIdentifier
  AND sqr.SurveyResponseIdentifier = sr.SurveyResponseIdentifier
INNER JOIN tpdm.SurveyResponseTeacherCandidateAssociation srtca
  ON sqr.SurveyResponseIdentifier = srtca.SurveyResponseIdentifier
  AND s.SurveyIdentifier = srtca.SurveyIdentifier
INNER JOIN tpdm.QuestionFormDescriptor qfd
  ON sq.QuestionFormDescriptorId = qfd.QuestionFormDescriptorId
INNER JOIN edfi.Descriptor d
  ON qfd.QuestionFormDescriptorId = d.DescriptorId
WHERE d.CodeValue NOT IN ('Ranking')
AND s.SurveyTitle LIKE 'Student Perception - K-%'
GO
/****** Object:  View [analytics].[TeacherCandidateAcademicRecordFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateAcademicRecordFact]
AS

WITH MostCurrentGPA
AS (SELECT
  tcargpa.TeacherCandidateIdentifier,
  tcargpa.GPATypeDescriptorId,
  MAX(tcargpa.SchoolYear) SchoolYear,
  MAX(tcargpa.TermDescriptorId) AS TermDescriptorId
FROM tpdm.TeacherCandidateAcademicRecordGradePointAverage tcargpa
GROUP BY tcargpa.TeacherCandidateIdentifier,
         tcargpa.GPATypeDescriptorId)

SELECT
  tcargpa.TeacherCandidateIdentifier TeacherCandidateKey,
  tcargpa.SchoolYear,
  tcargpa.TermDescriptorId,
  tcargpa.CumulativeGradePointAverage,
  d.CodeValue AS GPAType
FROM tpdm.TeacherCandidateAcademicRecordGradePointAverage tcargpa
INNER JOIN MostCurrentGPA
  ON tcargpa.TeacherCandidateIdentifier = MostCurrentGPA.TeacherCandidateIdentifier
  AND tcargpa.GPATypeDescriptorId = MostCurrentGPA.GPATypeDescriptorId
  AND tcargpa.SchoolYear = MostCurrentGPA.SchoolYear
LEFT JOIN tpdm.GPATypeDescriptor gd
  ON tcargpa.GPATypeDescriptorId = gd.GPATypeDescriptorId
LEFT OUTER JOIN edfi.Descriptor d
  ON gd.GPATypeDescriptorId = d.DescriptorId
GO
/****** Object:  View [analytics].[TeacherCandidateAssessment]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE EdFi_Ods_TPDM_Base
--GO
--
--DROP VIEW analytics.TeacherCandidateAcademicFact
--GO
--
--SET QUOTED_IDENTIFIER, ANSI_NULLS ON
--GO
--



--USE EdFi_Ods_TPDM_Base
--GO
--
--DROP VIEW analytics.TeacherCandidateGradePointAverageFact
--GO
--
--SET QUOTED_IDENTIFIER, ANSI_NULLS ON
--GO
--EdFi_Ods_TPDM_Base.edfi.Assessment
--
CREATE VIEW [analytics].[TeacherCandidateAssessment]
AS
WITH TeacherCandidateAssessmentMaxAdministrationDate
AS (SELECT
  tc.TeacherCandidateIdentifier,
  sa.AssessmentTitle,
  sa.StudentUSI,
  MAX(sa.AdministrationDate) AS MaxAdminstrationDate
FROM edfi.StudentAssessment sa
INNER JOIN tpdm.TeacherCandidate tc
  ON sa.StudentUSI = tc.StudentUSI
GROUP BY sa.AssessmentTitle,
         tc.TeacherCandidateIdentifier,
         sa.StudentUSI),

TeacherCandidateAssessment
AS (SELECT
  TeacherCandidateIdentifier,
  sa.StudentUSI,
  sa.AssessmentTitle,
  sasr.Result,
  d.CodeValue AS PerformanceLevel,
  sapl.PerformanceLevelMet,
  ROW_NUMBER() OVER (PARTITION BY TeacherCandidateIdentifier, sa.AssessmentTitle ORDER BY sa.AdministrationDate DESC) Latest
FROM edfi.StudentAssessment sa
INNER JOIN edfi.StudentAssessmentScoreResult sasr
  ON sa.AcademicSubjectDescriptorId = sasr.AcademicSubjectDescriptorId
  AND sa.AdministrationDate = sasr.AdministrationDate
  AND sa.AssessedGradeLevelDescriptorId = sasr.AssessedGradeLevelDescriptorId
  AND sa.AssessmentTitle = sasr.AssessmentTitle
  AND sa.AssessmentVersion = sasr.AssessmentVersion
  AND sa.StudentUSI = sasr.StudentUSI
INNER JOIN edfi.StudentAssessmentPerformanceLevel sapl
  ON sa.AcademicSubjectDescriptorId = sapl.AcademicSubjectDescriptorId
  AND sa.AdministrationDate = sapl.AdministrationDate
  AND sa.AssessedGradeLevelDescriptorId = sapl.AssessedGradeLevelDescriptorId
  AND sa.AssessmentTitle = sapl.AssessmentTitle
  AND sa.AssessmentVersion = sapl.AssessmentVersion
  AND sa.StudentUSI = sapl.StudentUSI
INNER JOIN edfi.PerformanceLevelDescriptor pld ON sapl.PerformanceLevelDescriptorId = pld.PerformanceLevelDescriptorId
INNER JOIN edfi.Descriptor d ON pld.PerformanceLevelDescriptorId = d.DescriptorId
INNER JOIN TeacherCandidateAssessmentMaxAdministrationDate tcamad
  ON sa.AssessmentTitle = tcamad.AssessmentTitle
  AND sa.StudentUSI = tcamad.StudentUSI
  AND sa.AdministrationDate = tcamad.MaxAdminstrationDate)
SELECT
  TeacherCandidateIdentifier TeacherCandidateKey,
  StudentUSI StudentKey,
  AssessmentTitle,
  Result,
  PerformanceLevelMet,
  Latest, 
  PerformanceLevel
FROM TeacherCandidateAssessment
GO
/****** Object:  View [analytics].[TeacherCandidateCourseTranscriptFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateCourseTranscriptFact]
AS
SELECT
  tcct.EducationOrganizationId AS TeacherCandidatePreparationProviderkey,
  tcct.TeacherCandidateIdentifier AS TeacherCandidateKey,
  tcct.CourseCode AS CourseCodeKey,
  tcct.FinalLetterGradeEarned,
  cast(cast(tcct.FinalNumericGradeEarned AS int ) AS nvarchar(10)) FinalNumericGradeEarned,
 cast( tcct.SchoolYear AS nvarchar(10)) + ' ' +d.CodeValue AS Term
FROM tpdm.TeacherCandidateCourseTranscript tcct
LEFT JOIN edfi.TermDescriptor td
  ON tcct.TermDescriptorId = td.TermDescriptorId
LEFT JOIN edfi.Descriptor d
  ON td.TermDescriptorId = d.DescriptorId
GO
/****** Object:  View [analytics].[TeacherCandidateEnrolledSectionAssociation]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateEnrolledSectionAssociation]
AS
SELECT
  ssa.SectionIdentifier AS SectionKey,
  ssa.StudentUSI AS StudentKey,
  tc.TeacherCandidateIdentifier AS TeacherCandidateKey,
  s1.FirstName + ' ' + s1.LastSurname AS InstructorFullName,
  d.CodeValue as MediumOfInstruction, 
  c.CourseTitle AS CourseTitle,
  ssa.BeginDate,
  ssa.SchoolId,
  ssa.SchoolYear,
  ssa.SessionName,
  ssa.EndDate
FROM edfi.StudentSectionAssociation ssa
INNER JOIN edfi.Section s
  ON ssa.LocalCourseCode = s.LocalCourseCode
  AND ssa.SchoolId = s.SchoolId
  AND ssa.SchoolYear = s.SchoolYear
  AND ssa.SectionIdentifier = s.SectionIdentifier
  AND ssa.SessionName = s.SessionName
INNER JOIN edfi.CourseOffering co
  ON ssa.LocalCourseCode = co.LocalCourseCode
  AND s.LocalCourseCode = co.LocalCourseCode
  AND ssa.SchoolId = co.SchoolId
  AND ssa.SchoolYear = co.SchoolYear
  AND s.SessionName = co.SessionName
INNER JOIN edfi.Course c
  ON co.CourseCode = c.CourseCode
LEFT JOIN edfi.MediumOfInstructionDescriptor moid ON s.MediumOfInstructionDescriptorId = moid.MediumOfInstructionDescriptorId
LEFT JOIN edfi.Descriptor d ON d.DescriptorId = moid.MediumOfInstructionDescriptorId
INNER JOIN tpdm.TeacherCandidate tc
  ON tc.StudentUSI = ssa.StudentUSI
LEFT JOIN edfi.StaffSectionAssociation ssa1
  ON ssa1.LocalCourseCode = s.LocalCourseCode
  AND ssa1.SchoolId = s.SchoolId
  AND ssa1.SchoolYear = s.SchoolYear
  AND ssa1.SectionIdentifier = s.SectionIdentifier
  AND ssa1.SessionName = s.SessionName
LEFT JOIN edfi.Staff s1
  ON ssa1.StaffUSI = s1.StaffUSI
GO
/****** Object:  View [analytics].[TeacherCandidateFieldworkExperienceFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateFieldworkExperienceFact]
AS


SELECT
DISTINCT
  tcfe.TeacherCandidateIdentifier TeacherCandidateKey,
  tcfe.SchoolId AS SchoolKey,
  lea.LocalEducationAgencyId AS LocalEducationAgencyKey,
  eo.NameOfInstitution PlacementSchool,
  eo1.NameOfInstitution PlacementDistrict,
  tcfesa.SessionName AS Semester,
  SUM(tcfe.HoursPerWeek) AS HoursPerWeek
FROM tpdm.TeacherCandidateFieldworkExperience tcfe
INNER JOIN edfi.School s
  ON tcfe.SchoolId = s.SchoolId
INNER JOIN edfi.EducationOrganization eo
  ON s.SchoolId = eo.EducationOrganizationId
INNER JOIN edfi.LocalEducationAgency lea
  ON s.LocalEducationAgencyId = lea.LocalEducationAgencyId
INNER JOIN edfi.EducationOrganization eo1
  ON lea.LocalEducationAgencyId = eo1.EducationOrganizationId
LEFT JOIN tpdm.TeacherCandidateTeacherPreparationProviderAssociation tctppa
  ON tcfe.TeacherCandidateIdentifier = tctppa.TeacherCandidateIdentifier
LEFT JOIN tpdm.TeacherCandidateFieldworkExperienceSectionAssociation tcfesa
  ON tcfe.BeginDate = tcfesa.BeginDate
  AND tcfe.FieldworkIdentifier = tcfesa.FieldworkIdentifier
  AND tcfe.SchoolId = tcfesa.SchoolId
  AND tcfe.TeacherCandidateIdentifier = tcfesa.TeacherCandidateIdentifier
GROUP BY tcfe.TeacherCandidateIdentifier,
         tcfe.SchoolId,
         lea.LocalEducationAgencyId,
         eo.NameOfInstitution,
         eo1.NameOfInstitution,
         tcfesa.SessionName
GO
/****** Object:  View [analytics].[TeacherCandidateGatewayCorurseCompleted]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Definition of denomiDefinition of denominator -
--Gateway 1: enrollees that have completed course code ‘EDCI3334’ with a grade equal to or greater than a 'B', but not course codes ‘EDTC3310’, ‘ECEC4311’, ‘EDUL6391’, ‘UTCH1101’, ‘EDUC4611’ or ‘UNIV1301’
--Gateway 2: enrollees that have completed course codes ‘EDCI3334’, ‘EDTC3310’, and ‘ECEC4311’ with a grade equal to or greater than a 'B', but not course codes ‘EDUL6391’, ‘UTCH1101’, ‘EDUC4611’ or ‘UNIV1301’
--Gateway 3: enrollees that have completed course codes ‘EDCI3334’, ‘EDTC3310’, ‘ECEC4311’, ‘EDUL6391’, and ‘UTCH1101’, with a grade equal to or greater than a 'B', but not course codes ‘EDUC4611’ or ‘UNIV1301’
--Gateway 4: enrollees that have completed course codes ‘EDCI3334’, ‘EDTC3310’, ‘ECEC4311’, ‘EDUL6391’, ‘UTCH1101’, ‘EDUC4611’ and ‘UNIV1301’ with a grade equal to or greater than a 'B'
--

CREATE VIEW [analytics].[TeacherCandidateGatewayCorurseCompleted]
AS
/** Gate way one **/
WITH GateWayCoursesTaken
AS (SELECT
  TeacherCandidateIdentifier,
  [EDCI3334],
  [EDTC3310],
  [ECEC4311],
  [EDUL6391],
  [UTCH1101],
  [EDUC4611],
  [UNIV1301]
FROM (SELECT DISTINCT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('EDCI3334')
UNION ALL
SELECT DISTINCT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('EDTC3310')
UNION ALL
SELECT DISTINCT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('ECEC4311')
UNION ALL
SELECT DISTINCT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('EDUL6391')

UNION ALL
SELECT DISTINCT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('UTCH1101')
UNION ALL
SELECT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('EDUC4611')
UNION ALL
SELECT
  tcct.TeacherCandidateIdentifier,
  tcct.CourseCode,
  CASE
    WHEN tcct.FinalLetterGradeEarned IN ('A', 'B') THEN 1
    ELSE 0
  END AS Completed
FROM tpdm.TeacherCandidateCourseTranscript tcct
WHERE tcct.CourseCode IN ('UNIV1301')


) t
PIVOT (
MAX(t.Completed)
FOR CourseCode IN ([EDCI3334], [EDTC3310], [ECEC4311], [EDUL6391], [UTCH1101], [EDUC4611], [UNIV1301])
--‘EDCI3334’, ‘EDTC3310’, ‘ECEC4311’, ‘EDUL6391’, ‘UTCH1101’, ‘EDUC4611’ and ‘UNIV1301’
) p),
TakenCompleted
AS (SELECT
  TeacherCandidateIdentifier,
  CASE
    WHEN EDCI3334 = 1 THEN 'Completed'
    WHEN EDCI3334 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS EDCI3334,
  CASE
    WHEN EDTC3310 = 1 THEN 'Completed'
    WHEN EDTC3310 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS EDTC3310,
  CASE
    WHEN ECEC4311 = 1 THEN 'Completed'
    WHEN ECEC4311 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS ECEC4311,
  CASE
    WHEN EDUL6391 = 1 THEN 'Completed'
    WHEN EDUL6391 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS EDUL6391,
  CASE
    WHEN UTCH1101 = 1 THEN 'Completed'
    WHEN UTCH1101 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS UTCH1101,
  CASE
    WHEN EDUC4611 = 1 THEN 'Completed'
    WHEN EDUC4611 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS EDUC4611,
  CASE
    WHEN UNIV1301 = 1 THEN 'Completed'
    WHEN UNIV1301 = 0 THEN 'Not Completed'
    ELSE 'Not Taken'
  END AS UNIV1301

FROM GateWayCoursesTaken)



SELECT
  TeacherCandidateKey,
  CASE
    WHEN GateWayOne IS NULL THEN GateWayOne
    ELSE CAST(GateWayOne AS BIT)
  END AS GateWayOneCourseComplete,
  CASE
    WHEN GateWayTwo IS NULL THEN GateWayTwo
    ELSE CAST(GateWayTwo AS BIT)
  END AS GateWayTwoCourseComplete,
  CASE
    WHEN GateWayThree IS NULL THEN GateWayThree
    ELSE CAST(GateWayThree AS BIT)
  END AS GateWayThreeCourseComplete,
  CASE
    WHEN GateWayFour IS NULL THEN GateWayFour
    ELSE CAST(GateWayFour AS BIT)
  END AS GateWayFourCourseComplete
FROM (SELECT
  TeacherCandidateIdentifier AS TeacherCandidateKey, --‘EDCI3334’ 
  CASE
    WHEN EDCI3334 = 'Completed' THEN 1
    WHEN EDCI3334 = 'Not Completed' THEN 0
    ELSE NULL
  END AS MeetsCriteria,
  'GateWayOne' AS GateWay
FROM TakenCompleted
WHERE EDTC3310 = 'Not Taken'
AND ECEC4311 = 'Not Taken'
AND EDUL6391 = 'Not Taken'
AND UTCH1101 = 'Not Taken'
AND EDUC4611 = 'Not Taken'
AND UNIV1301 = 'Not Taken'
UNION
SELECT
  TeacherCandidateIdentifier, --‘EDCI3334’, ‘EDTC3310’, and ‘ECEC4311’
  CASE
    WHEN EDCI3334 = 'Completed' AND
      EDTC3310 = 'Completed' AND
      ECEC4311 = 'Completed' THEN 1
    WHEN EDCI3334 IN ('Completed', 'Not Completed') AND
      EDTC3310 IN ('Completed', 'Not Completed') AND
      ECEC4311 IN ('Completed', 'Not Completed') THEN 0
    ELSE NULL
  END AS MeetsCriteria,
  'GateWayTwo' AS Gateway
FROM TakenCompleted
WHERE EDUL6391 = 'Not Taken'
AND UTCH1101 = 'Not Taken'
AND EDUC4611 = 'Not Taken'
AND UNIV1301 = 'Not Taken'
UNION
SELECT
  TeacherCandidateIdentifier, --‘EDCI3334’, ‘EDTC3310’, ‘ECEC4311’, ‘EDUL6391’, and ‘UTCH1101’,
  CASE
    WHEN EDCI3334 = 'Completed' AND
      EDTC3310 = 'Completed' AND
      ECEC4311 = 'Completed' AND
      EDUL6391 = 'Completed' AND
      UTCH1101 = 'Completed' THEN 1
    WHEN EDCI3334 = 'Completed' AND
      EDTC3310 IN ('Completed', 'Not Completed') AND
      ECEC4311 IN ('Completed', 'Not Completed') AND
      EDUL6391 IN ('Completed', 'Not Completed') AND
      UTCH1101 IN ('Completed', 'Not Completed') THEN 0
    ELSE null
  END AS MeetsCriteria,
  'GateWayThree' AS GateWay
FROM TakenCompleted
WHERE EDUC4611 = 'Not Taken'
AND UNIV1301 = 'Not Taken'
UNION
SELECT
  TeacherCandidateIdentifier, -- ‘EDCI3334’, ‘EDTC3310’, ‘ECEC4311’, ‘EDUL6391’, ‘UTCH1101’, ‘EDUC4611’ and ‘UNIV1301’ 
  CASE
    WHEN EDCI3334 = 'Completed' AND
      EDTC3310 = 'Completed' AND
      ECEC4311 = 'Completed' AND
      EDUL6391 = 'Completed' AND
      UTCH1101 = 'Completed' AND
      EDUC4611 = 'Completed' AND
      UNIV1301 = 'Completed' THEN 1
    WHEN EDCI3334 = 'Completed' AND
      EDTC3310 IN ('Completed', 'Not Completed') AND
      ECEC4311 IN ('Completed', 'Not Completed') AND
      EDUL6391 IN ('Completed', 'Not Completed') AND
      UTCH1101 IN ('Completed', 'Not Completed') AND
      EDUC4611 IN ('Completed', 'Not Completed') AND
      UNIV1301 IN ('Completed', 'Not Completed') THEN 0
    ELSE NULL 
  END AS MeetsCriteria,
  'GateWayFour' AS GateWay
FROM TakenCompleted) t
PIVOT (
MAX(MeetsCriteria)
FOR GateWay IN ([GateWayOne], [GateWayTwo], [GateWayThree], [GateWayFour])
) p
GO
/****** Object:  View [analytics].[TeacherCandidatePerformanceMeasureFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidatePerformanceMeasureFact]
AS
WITH MaxPerformanceDate
AS (SELECT
  rlr.RubricTitle,
  rlr.RubricLevelCode,
  pmpbr.TeacherCandidateIdentifier,
  MAX(pm.ActualDateOfPerformanceMeasure) ActualDateOfPerformanceMeasure
FROM tpdm.PerformanceMeasure pm
INNER JOIN tpdm.RubricLevelResponse rlr
  ON pm.PerformanceMeasureIdentifier = rlr.PerformanceMeasureIdentifier
INNER JOIN tpdm.PerformanceMeasurePersonBeingReviewed pmpbr
  ON pm.PerformanceMeasureIdentifier = pmpbr.PerformanceMeasureIdentifier
GROUP BY rlr.RubricTitle,
         rlr.RubricLevelCode,
         pmpbr.TeacherCandidateIdentifier)

SELECT DISTINCT
  pmpbr.TeacherCandidateIdentifier TeacherCandidateKey,
  pm.PerformanceMeasureIdentifier PerformanceMeasureKey,
  d.CodeValue AS PerformanceMeasureType,
  rli.RubricLevelCode,
  rlr.NumericResponse,
  d1.CodeValue AS Term,
  r.RubricTitle,
  rli.LevelTitle,
  rlr.AreaOfRefinement,
  rlr.AreaOfReinforcement,
  pmr.StaffUSI AS StaffKey,
  CASE
    WHEN AreaOfRefinement = 1 THEN 'Refinement'
    WHEN AreaOfReinforcement = 1 THEN 'Reinforcement'
    ELSE ''
  END AS [Status],
  CASE
    WHEN tc.FirstName = pmr.FirstName AND
      tc.LastSurname = pmr.LastSurname AND
      pmr.StaffUSI IS NULL THEN 'Yes'
    ELSE 'No'
  END AS SelfRefelction,
  'Assessment #' + CAST(ROW_NUMBER() OVER (PARTITION BY pmpbr.TeacherCandidateIdentifier, d.CodeValue, rl.RubricLevelCode ORDER BY pm.ActualDateOfPerformanceMeasure) AS NVARCHAR(4)) AS Assessment
FROM tpdm.PerformanceMeasure pm
INNER JOIN tpdm.PerformanceMeasurePersonBeingReviewed pmpbr
  ON pm.PerformanceMeasureIdentifier = pmpbr.PerformanceMeasureIdentifier
INNER JOIN tpdm.PerformanceMeasureReviewer pmr
  ON pm.PerformanceMeasureIdentifier = pmr.PerformanceMeasureIdentifier
INNER JOIN tpdm.PerformanceMeasureReviewer pmr1
  ON pm.PerformanceMeasureIdentifier = pmr1.PerformanceMeasureIdentifier
INNER JOIN tpdm.TeacherCandidate tc
  ON pmpbr.TeacherCandidateIdentifier = tc.TeacherCandidateIdentifier
INNER JOIN tpdm.Rubric r
  ON pmpbr.EducationOrganizationId = r.EducationOrganizationId
INNER JOIN tpdm.RubricLevel rl
  ON r.EducationOrganizationId = rl.EducationOrganizationId
  AND r.RubricTitle = rl.RubricTitle
  AND r.RubricTypeDescriptorId = rl.RubricTypeDescriptorId
INNER JOIN tpdm.RubricLevelInformation rli
  ON rl.EducationOrganizationId = rli.EducationOrganizationId
  AND rl.RubricLevelCode = rli.RubricLevelCode
  AND rl.RubricTitle = rli.RubricTitle
  AND rl.RubricTypeDescriptorId = rli.RubricTypeDescriptorId
INNER JOIN tpdm.RubricLevelResponse rlr
  ON pm.PerformanceMeasureIdentifier = rlr.PerformanceMeasureIdentifier
  AND rl.EducationOrganizationId = rlr.EducationOrganizationId
  AND rl.RubricLevelCode = rlr.RubricLevelCode
  AND rl.RubricTitle = rlr.RubricTitle
  AND rl.RubricTypeDescriptorId = rlr.RubricTypeDescriptorId
INNER JOIN tpdm.PerformanceMeasureTypeDescriptor pmtd
  ON pm.PerformanceMeasureTypeDescriptorId = pmtd.PerformanceMeasureTypeDescriptorId
INNER JOIN tpdm.RubricLevelInformation rli1
  ON rl.EducationOrganizationId = rli1.EducationOrganizationId
  AND rl.RubricLevelCode = rli1.RubricLevelCode
  AND rl.RubricTitle = rli1.RubricTitle
  AND rl.RubricTypeDescriptorId = rli1.RubricTypeDescriptorId
--INNER JOIN MaxPerformanceDate
--ON  rl.RubricLevelCode = MaxPerformanceDate.RubricLevelCode
--  AND pmpbr.TeacherCandidateIdentifier = MaxPerformanceDate.TeacherCandidateIdentifier
--  AND pm.ActualDateOfPerformanceMeasure = MaxPerformanceDate.ActualDateOfPerformanceMeasure
--  AND r.RubricTitle = MaxPerformanceDate.RubricTitle
INNER JOIN edfi.Descriptor d
  ON pmtd.PerformanceMeasureTypeDescriptorId = d.DescriptorId
INNER JOIN edfi.TermDescriptor td
  ON pm.TermDescriptorId = td.TermDescriptorId
INNER JOIN edfi.Descriptor d1
  ON d1.DescriptorId = td.TermDescriptorId
GO
/****** Object:  View [analytics].[TeacherCandidateProgramFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateProgramFact]
AS

WITH TeacherCandidateAcademicRecord
AS (SELECT
  tcar.TeacherCandidateIdentifier,
  tcar.EducationOrganizationId,
  tcar.ProjectedGraduationDate,
  ROW_NUMBER() OVER (PARTITION BY tcar.TeacherCandidateIdentifier, tcar.EducationOrganizationId ORDER BY tcar.SchoolYear, tcar.TermDescriptorId) AS LatestAcademicRecord
FROM tpdm.TeacherCandidateAcademicRecord tcar)

SELECT
  x.TeacherCandidateKey,
  x.TeacherCandidatePreparationProviderKey,
  x.ProgramKey,
  x.ReasonExitedDescriptor,
  x.ProgramName, 
  x.ProgramStatus
FROM (SELECT
  tctpppa.TeacherCandidateIdentifier AS [TeacherCandidateKey],
  tctpppa.[EducationOrganizationId] AS [TeacherCandidatePreparationProviderKey],
  tppp.ProgramId AS ProgramKey,
  tctpppa.ProgramName AS ProgramName,
  d.CodeValue AS ReasonExitedDescriptor,
  CASE
    WHEN d.Description LIKE '%Graduat%' AND
      tctpppa.EndDate <= tcar.ProjectedGraduationDate THEN 'Completed on time'
    WHEN d.Description LIKE '%Graduat%' AND
      tctpppa.EndDate > tcar.ProjectedGraduationDate THEN 'Completed not on time'
    WHEN tctpppa.EndDate IS NULL AND
      d.Description IS NOT NULL THEN 'Discontiued'
    ELSE 'Still Enrolled'
  END AS ProgramStatus,
  ROW_NUMBER() OVER (PARTITION BY tcar.TeacherCandidateIdentifier, tcar.EducationOrganizationId ORDER BY tctpppa.BeginDate) AS LatestProgramAssociation
FROM tpdm.TeacherCandidateTeacherPreparationProviderProgramAssociation tctpppa
INNER JOIN tpdm.TeacherPreparationProviderProgram tppp
  ON tctpppa.EducationOrganizationId = tppp.EducationOrganizationId
  AND tctpppa.ProgramName = tppp.ProgramName
INNER JOIN TeacherCandidateAcademicRecord tcar
  ON tctpppa.TeacherCandidateIdentifier = tcar.TeacherCandidateIdentifier
  AND tctpppa.EducationOrganizationId = tcar.EducationOrganizationId
LEFT JOIN edfi.ReasonExitedDescriptor red
  ON tctpppa.ReasonExitedDescriptorId = red.ReasonExitedDescriptorId
LEFT JOIN edfi.Descriptor d
  ON red.ReasonExitedDescriptorId = d.DescriptorId
WHERE tcar.LatestAcademicRecord = 1) x
WHERE x.LatestProgramAssociation = 1
GO
/****** Object:  View [analytics].[TeacherCandidateStaffAssociation]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateStaffAssociation]
AS
WITH TeacherCandidateMentorTeacher
AS (SELECT
  tcsa.TeacherCandidateIdentifier,
  s.StaffUSI,
  seoaa.EducationOrganizationId,
  s.FirstName + ' ' + s.LastSurname AS FullName, seoaa.PositionTitle
FROM tpdm.TeacherCandidateStaffAssociation tcsa
INNER JOIN edfi.StaffEducationOrganizationAssignmentAssociation seoaa
  ON tcsa.StaffUSI = seoaa.StaffUSI
INNER JOIN edfi.Staff s
  ON tcsa.StaffUSI = s.StaffUSI
WHERE seoaa.PositionTitle LIKE 'Mentor Teacher'
OR seoaa.PositionTitle LIKE 'Site Coordinator')

SELECT
   TeacherCandidateIdentifier as TeacherCandidateKey,
   StaffUSI AS StaffKey,
   EducationOrganizationId,
   FullName,
   PositionTitle
FROM TeacherCandidateMentorTeacher
GO
/****** Object:  View [analytics].[TeacherCandidateStaffCredential]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateStaffCredential]
AS
SELECT
  StaffKey,
  CredentialKey,
  StateOfIssue,
  CredentialField,
  CertificationStatus,
  CASE
    WHEN CertificationExamPassFail = 1 AND
      Attempt = 1 THEN '1st Attempt'
    WHEN CertificationExamPassFail = 1 AND
      Attempt = 2 THEN '2nd Attempt'
    WHEN CertificationExamPassFail = 1 AND
      Attempt = 3 THEN '3rd Attempt'
    WHEN CertificationExamPassFail = 1 AND
      Attempt >= 4 THEN 'More than 3 attempts'
    ELSE 'Unknown'
  END AttemptStatus
FROM (SELECT
  s.StaffUSI AS StaffKey,
  c.CredentialIdentifier CredentialKey,
  d1.CodeValue AS StateOfIssue,
  d.CodeValue AS CredentialField,
  --COALESCE(d.Description, '') + ' ' + COALESCE(m.Description, '') CertificationAreaName ,
  CASE
    WHEN c.IssuanceDate IS NOT NULL THEN 'Certified'
    WHEN n.CertificationExamDate IS NOT NULL AND
      c.IssuanceDate IS NULL THEN 'In Progress'
    WHEN n.CertificationExamDate IS NULL AND
      c.IssuanceDate IS NULL THEN 'Not Attempted'
  END CertificationStatus,
  CertificationExamPassFail,
  ROW_NUMBER() OVER (PARTITION BY tc.TeacherCandidateIdentifier,
  n.CertificationExamTitle ORDER BY n.CertificationExamDate ASC) Attempt
FROM tpdm.TeacherCandidate tc
INNER JOIN edfi.Staff s
  ON s.StaffUniqueId = tc.TeacherCandidateIdentifier
INNER JOIN edfi.StaffCredential sc
  ON s.StaffUSI = sc.StaffUSI
INNER JOIN edfi.Credential c
  ON sc.CredentialIdentifier = c.CredentialIdentifier
  AND sc.StateOfIssueStateAbbreviationDescriptorId = c.StateOfIssueStateAbbreviationDescriptorId
INNER JOIN edfi.CredentialFieldDescriptor cfd
  ON c.CredentialFieldDescriptorId = cfd.CredentialFieldDescriptorId
INNER JOIN edfi.Descriptor d
  ON cfd.CredentialFieldDescriptorId = d.DescriptorId
INNER JOIN edfi.StateAbbreviationDescriptor sad
  ON c.StateOfIssueStateAbbreviationDescriptorId = sad.StateAbbreviationDescriptorId
INNER JOIN edfi.Descriptor d1
  ON d1.DescriptorId = c.StateOfIssueStateAbbreviationDescriptorId
LEFT JOIN edfi.CredentialGradeLevel k
  ON sc.CredentialIdentifier = k.CredentialIdentifier
LEFT JOIN edfi.Descriptor m
  ON k.GradeLevelDescriptorId = m.DescriptorId
LEFT JOIN tpdm.CredentialCertificationExam n
  ON sc.CredentialIdentifier = n.CredentialIdentifier) a
GO
/****** Object:  View [analytics].[TeacherCandidateStaffDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateStaffDimension]
AS
WITH TeacherCandidateStaffDimension
AS (SELECT
  seoaa.EducationOrganizationId AS SchoolKey,
  s1.LocalEducationAgencyId AS LocalEducationAgencyKey,
  tc.TeacherCandidateIdentifier TeacherCandidateKey,
  seoaa.StaffUSI StaffKey,
  seoaa.BeginDate,
  d1.CodeValue RaceDescriptor,
  d2.CodeValue SexDescriptor,
  seoaa.StaffClassificationDescriptorId,
  seoaa.PositionTitle,
  seoaa.EndDate,
  seoaa.OrderOfAssignment,
  seoaa.EmploymentEducationOrganizationId,
  d.CodeValue AS EmploymentStatus,
  seoaa.EmploymentHireDate,
  RetentionYears = DATEDIFF(YEAR, seoaa.EmploymentHireDate, GETDATE())

FROM tpdm.TeacherCandidate tc
INNER JOIN  tpdm.StaffTeacherCandidateAssociation stca ON tc.TeacherCandidateIdentifier = stca.TeacherCandidateIdentifier
INNER JOIN edfi.Staff s ON s.StaffUSI = stca.StaffUSI
INNER JOIN edfi.StaffEducationOrganizationAssignmentAssociation seoaa
INNER JOIN edfi.School s1 ON s1.SchoolId = seoaa.EducationOrganizationId
LEFT JOIN edfi.EmploymentStatusDescriptor esd
  ON seoaa.EmploymentStatusDescriptorId = esd.EmploymentStatusDescriptorId
LEFT JOIN edfi.Descriptor d
  ON esd.EmploymentStatusDescriptorId = d.DescriptorId
  ON s.StaffUSI = seoaa.StaffUSI
LEFT JOIN edfi.StaffRace sr
  ON s.StaffUSI = sr.StaffUSI
LEFT JOIN edfi.RaceDescriptor rd
  ON rd.RaceDescriptorId = sr.RaceDescriptorId
LEFT JOIN edfi.Descriptor d1
  ON rd.RaceDescriptorId = d1.DescriptorId
LEFT JOIN edfi.SexDescriptor sd
  ON sd.SexDescriptorId = s.SexDescriptorId
LEFT JOIN edfi.Descriptor d2
  ON d2.DescriptorId = sd.SexDescriptorId)
SELECT
  SchoolKey,
  TeacherCandidateKey,
  LocalEducationAgencyKey,
  StaffKey,
  BeginDate,
  RaceDescriptor,
  SexDescriptor,
  StaffClassificationDescriptorId,
  PositionTitle,
  EndDate,
  OrderOfAssignment,
  EmploymentEducationOrganizationId,
  EmploymentStatus,
  EmploymentHireDate,
  RetentionYears,
  CASE
    WHEN RetentionYears >= 1 AND
      RetentionYears < 3 THEN '1 Year'
    WHEN RetentionYears >= 3 AND
      RetentionYears < 5 THEN '3 year'
    ELSE '5+ year'
  END AS RetentionBand
FROM TeacherCandidateStaffDimension
GO
/****** Object:  View [analytics].[TeacherCandidateStaffFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateStaffFact]
  AS

  WITH TeacherCandidateStaffFact
  AS (SELECT
    seoaa.EducationOrganizationId,
    tc.TeacherCandidateIdentifier TeacherCandidateKey,
    seoaa.StaffUSI StaffKey,
    seoaa.BeginDate,
    seoaa.StaffClassificationDescriptorId,
    seoaa.PositionTitle,
    seoaa.EndDate,
    seoaa.OrderOfAssignment,
    seoaa.EmploymentEducationOrganizationId,
    d.CodeValue AS EmploymentStatus,
    seoaa.EmploymentHireDate,
    RetentionYears = DATEDIFF(YEAR, seoaa.EmploymentHireDate, GETDATE())
  FROM tpdm.TeacherCandidate tc
  INNER JOIN edfi.Staff s
    ON s.StaffUniqueId = tc.TeacherCandidateIdentifier
  INNER JOIN edfi.StaffEducationOrganizationAssignmentAssociation seoaa
  LEFT JOIN edfi.EmploymentStatusDescriptor esd
    ON seoaa.EmploymentStatusDescriptorId = esd.EmploymentStatusDescriptorId
  LEFT JOIN edfi.Descriptor d
    ON esd.EmploymentStatusDescriptorId = d.DescriptorId
    ON s.StaffUSI = seoaa.StaffUSI)
  SELECT
    EducationOrganizationId AS Shoolkey,
    TeacherCandidateKey,
    StaffKey,
    BeginDate,

    StaffClassificationDescriptorId,
    PositionTitle,
    EndDate,
    OrderOfAssignment,
    EmploymentEducationOrganizationId,
    EmploymentStatus,
    EmploymentHireDate,
    RetentionYears,
    CASE
      WHEN RetentionYears >= 1 AND
        RetentionYears < 3 THEN '1 Year'
      WHEN RetentionYears >= 3 AND
        RetentionYears < 5 THEN '3 year'
      ELSE '5+ year'
    END AS RetentionBand
  FROM TeacherCandidateStaffFact
GO
/****** Object:  View [analytics].[TeacherCandidateSurveyResponseFact]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherCandidateSurveyResponseFact]
AS
SELECT
  sqr.SurveyResponseIdentifier AS SurveyResponseKey,
  sr.TeacherCandidateIdentifier AS TeacherCandidateKey,
  s.SurveyIdentifier,
  s.SurveyTitle,
  ss.SurveySectionTitle,
  sq.QuestionText,
  sqr.TextResponse,
  sqr.NoResponse
FROM tpdm.Survey s
INNER JOIN tpdm.SurveySection ss
  ON s.SurveyIdentifier = ss.SurveyIdentifier
INNER JOIN tpdm.SurveyQuestion sq
  ON s.SurveyIdentifier = sq.SurveyIdentifier
INNER JOIN tpdm.SurveyQuestionResponse sqr
  ON sq.QuestionCode = sqr.QuestionCode
  AND sq.SurveyIdentifier = sqr.SurveyIdentifier
INNER JOIN tpdm.SurveyResponse sr
  ON sqr.SurveyIdentifier = sr.SurveyIdentifier
  AND sqr.SurveyResponseIdentifier = sr.SurveyResponseIdentifier
INNER JOIN tpdm.QuestionFormDescriptor qfd
  ON sq.QuestionFormDescriptorId = qfd.QuestionFormDescriptorId
INNER JOIN edfi.Descriptor d
  ON qfd.QuestionFormDescriptorId = d.DescriptorId
WHERE s.SurveyTitle LIKE 'Program Satisfaction%'
OR s.SurveyTitle LIKE 'Mentor Teacher Feedback Survey'
OR s.SurveyTitle LIKE 'Course Evaluation'
GO
/****** Object:  View [analytics].[TeacherPreparationProviderDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherPreparationProviderDimension]
AS
SELECT
	tpp.TeacherPreparationProviderId TeacherPrepartionProviderKey
   ,tpp.UniversityId UniversityKey
   ,d.CodeValue FederalLocalCodeType
   ,TeacherPreparationProvider.NameOfInstitution TeacherPreparationProviderName
   ,TeacherPreparationProvider.WebSite TeacherPreparationProviderWebSite
   ,University.NameOfInstitution UniversityName
   ,University.WebSite UniversityWebSite
   ,(SELECT
			MAX([LastModifiedDate])
		FROM (VALUES(TeacherPreparationProvider.[LastModifiedDate]),

		(University.[LastModifiedDate]),

		([TeacherPreparationProviderAddress].[LastModifiedDate])
		) AS value ([LastModifiedDate]))
	AS [LastModifiedDate]
FROM tpdm.TeacherPreparationProvider tpp
LEFT JOIN tpdm.FederalLocaleCodeDescriptor flcd
	ON tpp.FederalLocaleCodeDescriptorId = flcd.FederalLocaleCodeDescriptorId
LEFT JOIN edfi.Descriptor d
	ON flcd.FederalLocaleCodeDescriptorId = d.DescriptorId
LEFT JOIN tpdm.University u
	ON flcd.FederalLocaleCodeDescriptorId = u.FederalLocaleCodeDescriptorId
LEFT JOIN edfi.EducationOrganization TeacherPreparationProvider
	ON tpp.TeacherPreparationProviderId = TeacherPreparationProvider.EducationOrganizationId
LEFT JOIN edfi.EducationOrganization University
	ON u.UniversityId = University.EducationOrganizationId
OUTER APPLY (SELECT TOP 1
		CONCAT(
		[EducationOrganizationAddress].[StreetNumberName],
		', ',
		([EducationOrganizationAddress].[ApartmentRoomSuiteNumber] + ', '),
		[EducationOrganizationAddress].[City],
		[sad].[CodeValue],
		' ',
		[EducationOrganizationAddress].[PostalCode]
		) AS [SchoolAddress]
	   ,[EducationOrganizationAddress].[City] AS [SchoolCity]
	   ,[EducationOrganizationAddress].[NameOfCounty] AS [SchoolCounty]
	   ,[sad].[CodeValue] AS [SchoolState]
	   ,[EducationOrganizationAddress].[CreateDate] AS [LastModifiedDate]
	FROM [edfi].[EducationOrganizationAddress]
	INNER JOIN [edfi].[Descriptor] atd
		ON [EducationOrganizationAddress].[AddressTypeDescriptorId] = atd.DescriptorId
	INNER JOIN [edfi].[Descriptor] sad
		ON [EducationOrganizationAddress].[StateAbbreviationDescriptorId] = sad.DescriptorId
	WHERE tpp.TeacherPreparationProviderId = [EducationOrganizationAddress].[EducationOrganizationId]
	AND [atd].[CodeValue] = 'Physical') AS [TeacherPreparationProviderAddress];
GO
/****** Object:  View [analytics].[TeacherPreparationProviderProgramDimension]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics].[TeacherPreparationProviderProgramDimension] AS 
SELECT
  tppp.ProgramId AS ProgramKey,
  tppp.EducationOrganizationId AS [TeacherCandidatePreparationProviderKey],
  tppp.ProgramName AS ProgramName,
  d.CodeValue AS ProgramType
FROM tpdm.TeacherPreparationProviderProgram tppp
INNER JOIN tpdm.TeacherPreparationProgramTypeDescriptor tpptd
  ON tppp.TeacherPreparationProgramTypeDescriptorId = tpptd.TeacherPreparationProgramTypeDescriptorId
INNER JOIN edfi.Descriptor d
  ON d.DescriptorId = tpptd.TeacherPreparationProgramTypeDescriptorId
GO
/****** Object:  View [analytics_config].[Security]    Script Date: 4/26/2019 9:21:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [analytics_config].[Security]
AS
WITH TeacherCandidateStaffSectionAssociation
AS (SELECT DISTINCT
  seoaa.StaffUSI,
  tc.TeacherCandidateIdentifier,
  d.CodeValue AS StaffClassificationDescriptor,
  tc.LoginId
FROM tpdm.TeacherCandidate tc
INNER JOIN edfi.Student s
  ON tc.StudentUSI = s.StudentUSI
INNER JOIN edfi.StudentSectionAssociation ssa
  ON s.StudentUSI = ssa.StudentUSI
INNER JOIN edfi.Section s1
  ON ssa.LocalCourseCode = s1.LocalCourseCode
  AND ssa.SchoolId = s1.SchoolId
  AND ssa.SchoolYear = s1.SchoolYear
  AND ssa.SectionIdentifier = s1.SectionIdentifier
  AND ssa.SessionName = s1.SessionName
INNER JOIN edfi.StaffSectionAssociation ssa1
  ON s1.LocalCourseCode = ssa1.LocalCourseCode
  AND s1.SchoolId = ssa1.SchoolId
  AND s1.SchoolYear = ssa1.SchoolYear
  AND s1.SectionIdentifier = ssa1.SectionIdentifier
  AND s1.SessionName = ssa1.SessionName
INNER JOIN edfi.StaffEducationOrganizationAssignmentAssociation seoaa
  ON seoaa.StaffUSI = ssa1.StaffUSI
INNER JOIN edfi.StaffClassificationDescriptor scd
  ON seoaa.StaffClassificationDescriptorId = scd.StaffClassificationDescriptorId
INNER JOIN edfi.Descriptor d
  ON scd.StaffClassificationDescriptorId = d.DescriptorId),

TeacherCandidateStaffAssociation
AS (SELECT DISTINCT
  seoaa.StaffUSI,
  tcs.TeacherCandidateIdentifier,
  d.CodeValue AS StaffClassificationDescriptor,
  s.LoginId
FROM tpdm.TeacherCandidateStaffAssociation tcs
INNER JOIN edfi.StaffEducationOrganizationAssignmentAssociation seoaa
  ON tcs.StaffUSI = seoaa.StaffUSI
INNER JOIN edfi.StaffClassificationDescriptor scd
  ON seoaa.StaffClassificationDescriptorId = scd.StaffClassificationDescriptorId
INNER JOIN edfi.Descriptor d
  ON scd.StaffClassificationDescriptorId = d.DescriptorId
INNER JOIN edfi.Staff s
  ON s.StaffUSI = seoaa.StaffUSI
WHERE d.CodeValue IN ('Site Coordinator')),
TeacherCandidates
AS (SELECT
  tc.TeacherCandidateIdentifier AS StaffUSI,
  tc.TeacherCandidateIdentifier,
  'Teacher Candidate' AS StaffClassificationDescriptor,
  tc.LoginId
FROM tpdm.TeacherCandidate tc)


SELECT
  *
FROM TeacherCandidateStaffAssociation
UNION
SELECT
  *
FROM TeacherCandidateStaffSectionAssociation
UNION
SELECT
  *
FROM TeacherCandidates
GO
