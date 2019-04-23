/*******

Fall 2018 Cluster Analysis Query
Written by: Megan Leonard
Last Updated: 3/4/2019

Purpose: to pull data to perform a two-step cluster analysis in SPSS




Add: 
taking a MC course
number of MC courses

cross location 

Fall 2018 GPA
Fall 2018 Success Rate
Fall 2018 Completion Rate
Cumulative Success Rate
Cumulative Completion Rate

Age range

Degree goal
Cert goal

only taking public safety?

earned a BA degree already? <--- do we have this info?


-- coding unknowns as NA for SPSS


*******/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SELECT DISTINCT
	ce.STC_PERSON_ID,
	pe.Ethnicity,
	CASE WHEN pe.ethnicity LIKE '%latino%' THEN 'Latino' ELSE 'Not' END AS Latino,
	pe.URM,
	CASE WHEN ce.Gender IS NULL THEN 'NA' ELSE ce.GENDER END AS Gender,
	age.AgeYears AS Age,
	-- AS AgeRange
	CASE WHEN z.CountyLoc IS NULL THEN 'Not in SCC' ELSE z.CountyLoc END AS CountyLoc,
	CASE WHEN z.PO_NAME IS NULL THEN 'Not in SCC' ELSE z.PO_Name END AS PO_Name,
	CASE WHEN z.CountyLoc IN ('North County','South County') THEN 'Santa Cruz County' 
		 WHEN z.CountyLoc IS NULL THEN 'Not'
		 ELSE 'Not' END AS SCC,
	CASE WHEN eops.STUDENT_ID IS NOT NULL THEN 'Y'
		 WHEN eops.STUDENT_ID IS NULL THEN 'N'
		 END AS EOPSEver,
	CASE WHEN vet.ID IS NOT NULL THEN 'Y'
		 WHEN vet.ID IS NULL THEN 'N'
		 END AS VeteranStatus,
	CASE WHEN ds.DSPS_ID IS NOT NULL THEN 'Y'
		 ELSE 'N' 
		 END AS DisabilityEver,
	CASE WHEN fy.STUDENTS_ID IS NOT NULL THEN 'Y'
		 WHEN fy.STUDENTS_ID IS NULL THEN 'N'
		 END AS FosterYouthStatus,
	CASE WHEN fg.FirstGen = 0 THEN 'N' 
		 WHEN fg.FirstGen = 1 THEN 'Y'
		 ELSE 'NA' 
		 END AS FirstGenStatus,
	CASE WHEN bog.SA_STUDENT_ID IS NOT NULL OR pell.SA_STUDENT_ID IS NOT NULL THEN 'Y'
		 ELSE 'N'
		 END AS EconomicallyDisadvantaged,
	eg.VAL_EXTERNAL_REPRESENTATION AS EducationGoal,
	eg.TransferEdGoal,
	m.Major AS Major,
	CASE WHEN m.Major = 'Undeclared' THEN 0 ELSE 1 END AS HasMajor,
	b.CreditsAttempted AS UnitsAttemptedF18,
	CASE WHEN b.CreditsAttempted >= 12 THEN 'Full Time'
		 WHEN b.CreditsAttempted = 0 THEN 'Non-Credit'
		 ELSE 'Part Time'
		 END AS FTPTEnrollment,
	gpa.gpa AS CumulativeGPA,
	at.TotUnitsAttempted,
	tc.TotalCredits AS TotalCreditsEarned,
	NumCourses AS NumCoursesTakingF18,
	CASE WHEN NumOnlineCourses = NumCourses THEN 1 ELSE 0 END AS OnlineOnlyStudentF18,
	CASE WHEN NumOnlineCourses IS NULL THEN 0 ELSE 1 END AS TakingOnlineCourseF18,
	CASE WHEN NumOnlineCourses IS NULL THEN 0 ELSE NumOnlineCourses END AS NumOnlineCoursesF18,
	CASE WHEN NumWCCourses IS NULL THEN 0 ELSE 1 END AS TakingWCCourseF18,
	CASE WHEN NumWCCourses IS NULL THEN 0 ELSE NumWCCourses END AS NumWCCoursesF18,
	CASE WHEN pt.NumPrimaryTerms IS NULL THEN 0 ELSE pt.NumPrimaryTerms END AS NumPrimaryTerms,
	CASE WHEN st.NumSecondaryTerms IS NULL THEN 0 ELSE st.NumSecondaryTerms END AS NumSecondaryTerms
	FROM
		datatel.dbo.factbook_coreenrollment_view ce
		LEFT JOIN 
		datatel.dbo.person_ethnicities_view pe ON pe.ID = ce.STC_PERSON_ID
		LEFT JOIN 
		datatel.dbo.person_addresses_view pa ON pa.ID = ce.stc_person_id
		LEFT JOIN
		pro.dbo.CabrilloZips z ON z.zip = LEFT(pa.ZIP, 5) 
		LEFT JOIN 
		datatel.dbo.Majors_View_COALESCED m
		ON m.STC_PERSON_ID = ce.stc_person_id
		LEFT JOIN 
		datatel.dbo.AgeByTerm_View age ON age.ID = ce.stc_person_id AND age.TERMS_ID = ce.STC_TERM
		LEFT JOIN 
		(SELECT 
			ce.STC_PERSON_ID,
			COUNT(ce.STC_COURSE_NAME) AS NumCourses
			FROM 
			datatel.dbo.FACTBOOK_CoreEnrollment_View ce
			WHERE
				ce.STC_TERM = '2018FA' 
				GROUP BY 
				ce.STC_PERSON_ID
		) crs ON crs.stc_person_id = ce.STC_PERSON_ID
		LEFT JOIN 
		(SELECT 
			ce.STC_PERSON_ID,
			COUNT(ce.STC_COURSE_NAME) AS NumOnlineCourses
			FROM 
			datatel.dbo.FACTBOOK_CoreEnrollment_View ce
			WHERE
				ce.STC_TERM = '2018FA' 
				AND 
				ce.SEC_LOCATION = 'OL'
				GROUP BY 
				ce.STC_PERSON_ID
		) ol ON ol.stc_person_id = ce.STC_PERSON_ID
		LEFT JOIN 
		(SELECT 
			ce.STC_PERSON_ID,
			COUNT(ce.STC_COURSE_NAME) AS NumWCCourses
			FROM 
			datatel.dbo.FACTBOOK_CoreEnrollment_View ce
			WHERE
				ce.STC_TERM = '2018FA' 
				AND 
				ce.SEC_LOCATION IN ('WC','WA')
				GROUP BY 
				ce.STC_PERSON_ID
		) wc ON wc.stc_person_id = ce.STC_PERSON_ID
		LEFT JOIN 
		(SELECT
			ce.stc_person_id,
			SUM(ce.stc_cred) AS CreditsAttempted
			FROM 
				datatel.dbo.FACTBOOK_CoreEnrollment_View ce
				WHERE 
				ce.STC_TERM = '2018FA'
				GROUP BY ce.STC_PERSON_ID
		) b ON b.STC_PERSON_ID = ce.STC_PERSON_ID
		LEFT JOIN 
		(SELECT DISTINCT
			ce.[STC_PERSON_ID],
			COUNT(DISTINCT ce.[STC_TERM]) AS NumPrimaryTerms
			FROM 
				[datatel].[dbo].[FACTBOOK_CoreEnrollment_View] ce
				WHERE 
				ce.[TERM_SESSION] IN ('FA','SP')
				GROUP BY ce.[STC_PERSON_ID]
		) pt ON pt.stc_person_id = ce.stc_person_id
		LEFT JOIN
		(SELECT DISTINCT
			ce.[STC_PERSON_ID],
			COUNT(DISTINCT ce.[STC_TERM]) AS NumSecondaryTerms
			FROM 
				[datatel].[dbo].[FACTBOOK_CoreEnrollment_View] ce
				WHERE 
					ce.[TERM_SESSION] IN ('IN','SU')
					GROUP BY ce.[STC_PERSON_ID]
		) st
		ON st.stc_person_id = ce.stc_person_id
		LEFT JOIN
		(SELECT DISTINCT 
			fy.STUDENTS_ID
			FROM 
				datatel.dbo.FosterYouthStatus AS fy
		) AS fy 
		ON fy.STUDENTS_ID = ce.stc_person_id
		LEFT JOIN
		(SELECT DISTINCT 
			[SA_STUDENT_ID]
			FROM 
				[datatel].[dbo].[FinAidAwards_View]
				WHERE 
				[SA_AWARD] = 'PELL' AND [SA_ACTION] = 'A' OR [SA_XMIT_AMT] > 0
		) AS pell 
		ON ce.stc_person_id = pell.SA_STUDENT_ID
		LEFT JOIN 
		(SELECT DISTINCT 
			[SA_STUDENT_ID]
			FROM 
				[datatel].[dbo].[FinAidAwards_View]
				WHERE 
				[SA_AWARD] LIKE ('BOG%') AND [SA_ACTION] = 'A' OR [SA_XMIT_AMT] > 0
		) AS bog 
		ON ce.stc_person_id = bog.SA_STUDENT_ID	
		LEFT JOIN
		(SELECT DISTINCT 
			eops.STUDENT_ID
			FROM 
				[datatel].[dbo].C09_DW_STUDENT_EOPS AS eops
		) AS eops 
		ON ce.stc_person_id = eops.STUDENT_ID	
		LEFT JOIN
		(SELECT DISTINCT 
			v.ID
			FROM 
				datatel.dbo.VETERAN_ASSOC AS v
				WHERE 
					v.POS = 1 
					AND 
					v.VETERAN_TYPE NOT IN ('S', 'V35', 'VDEP') -- VRAP is iffy, but I left it in
		) AS vet 
		ON ce.stc_person_id = vet.ID
		LEFT JOIN 
		(SELECT DISTINCT 
			fg.ID AS StudentID, 
			fg.ParentEdLevel, 
			CASE WHEN fg.ParentEdLevel IN ('11','12','13','14','1X','1Y','21','22','23','24','2X','2Y','31','32','33','34','3X','3Y','41','42','43','44','4X','4Y','X1','X2','X3','X4','Y1','Y2','Y3','Y4') THEN 1 
				 WHEN fg.ParentEdLevel IS NULL OR fg.ParentEdLevel IN ('YY','XX') THEN NULL 
				 ELSE 0 
				 END AS FirstGen
			FROM 
				(SELECT 
					[APPLICANTS_ID] AS ID,
					([APP_PARENT1_EDUC_LEVEL] + [APP_PARENT2_EDUC_LEVEL]) AS ParentEdLevel,
					MAX([APPLICANTS_CHGDATE]) AS MaxAppChangeDate
					FROM
						[datatel].[dbo].[APPLICANTS]
						GROUP BY [APPLICANTS_ID], [APP_PARENT1_EDUC_LEVEL], [APP_PARENT2_EDUC_LEVEL]
				) AS fg
		) fg
		ON fg.StudentID = ce.stc_person_id
		LEFT JOIN 
		(SELECT 
			DisPrim.*, 
			DisAll.AllDisabilities
			FROM
				(SELECT DISTINCT 
					d.[PERSON_HEALTH_ID] AS DSPS_ID,
					dd.HC_DESC AS PrimaryDisability
					FROM 
						[datatel].[dbo].[PHL_DISABILITIES] AS d
						INNER JOIN 
						[datatel].[dbo].[DISABILITY] AS dd 
						ON d.[PHL_DISABILITY] = dd.DISABILITY_ID
						WHERE 
							d.PHL_DIS_TYPE = 'PRI'
				) AS DisPrim
				INNER JOIN 
				(SELECT DISTINCT 
					d.[PERSON_HEALTH_ID] AS DSPS_ID,
					datatel.[dbo].[ConcatField](dd.HC_DESC, ', ') AS AllDisabilities
					FROM 
						[datatel].[dbo].[PHL_DISABILITIES] AS d
						INNER JOIN 
						[datatel].[dbo].[DISABILITY] AS dd 
						ON d.[PHL_DISABILITY] = dd.DISABILITY_ID
						GROUP BY [PERSON_HEALTH_ID]
				) AS DisAll
				ON DisPrim.DSPS_ID = DisAll.DSPS_ID
		) ds
		ON ds.DSPS_ID = ce.stc_person_id
		LEFT JOIN 
		(SELECT
			STUDENT_ID AS StudentID,
			TERMS_ID,
			GPA
			FROM
				datatel.dbo.C09_DW_cum_gpa_through_term
		) gpa
		ON gpa.StudentID = ce.stc_person_id and gpa.terms_id = ce.stc_term
		LEFT JOIN 
		(SELECT DISTINCT 
			ce.STC_PERSON_ID, 
			SUM(ce.STC_CRED) AS TotUnitsAttempted
			FROM 
				datatel.dbo.FACTBOOK_CoreEnrollment_View ce
				GROUP BY ce.STC_PERSON_ID
		) at
		ON at.STC_PERSON_ID = ce.STC_PERSON_ID
		LEFT JOIN 
		(SELECT DISTINCT 
			ce.STC_PERSON_ID, 
			SUM(ce.STC_CMPL_CRED) AS TotalCredits
			FROM 
				datatel.dbo.FACTBOOK_CoreEnrollment_View ce
				GROUP BY ce.STC_PERSON_ID
		) tc
		ON tc.STC_PERSON_ID = ce.STC_PERSON_ID
		LEFT JOIN 
		(SELECT DISTINCT 
			eg3.ID AS StudentID, 
			v1.VAL_EXTERNAL_REPRESENTATION, 
			eg3.[PST_EDUC_GOALS] AS EducationGoal,
			CASE WHEN eg3.[PST_EDUC_GOALS] IN ('1','2','1A','1B','1C','1D','1E','1F','1G','2A','2B','2C','2D','2E','2F','2G') THEN 'Transfer' 
				 WHEN eg3.[PST_EDUC_GOALS] = '14'THEN '4yrStudent' 
				 ELSE 'Not' 
				 END AS TransferEdGoal
			FROM 
				(SELECT 
					eg2.ID, 
					eg2.PST_EDUC_GOALS
					FROM 
						(SELECT
							eg1.ID, 
							eg1.MaxPOS, 
							eg.[PST_EDUC_GOALS]
							FROM 
								(SELECT DISTINCT 
									eg.[PERSON_ST_ID] AS ID, 
									MAX(eg.POS) AS MaxPOS
									FROM 
										[datatel].[dbo].[EDUC_GOALS] AS eg
										GROUP BY eg.[PERSON_ST_ID]
								) AS eg1
								INNER JOIN 
								[datatel].[dbo].[EDUC_GOALS] AS eg
								ON eg1.ID = eg.[PERSON_ST_ID] AND eg1.MaxPOS = eg.[POS]
						) AS eg2
				) AS eg3
				INNER JOIN 
				(SELECT DISTINCT 
					[VALCODE_ID],
					[POS],
					[VAL_MINIMUM_INPUT_STRING],
					[VAL_EXTERNAL_REPRESENTATION]
					FROM 
						[datatel].[dbo].[ST_VALS]
						WHERE 
						valcode_id = 'EDUCATION.GOALS'
				) AS v1
				ON eg3.PST_EDUC_GOALS = v1.[VAL_MINIMUM_INPUT_STRING]
		) eg
		ON eg.StudentID = ce.STC_PERSON_ID
		WHERE
		ce.stc_term = '2018FA'





