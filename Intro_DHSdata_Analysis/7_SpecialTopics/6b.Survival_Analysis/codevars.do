/********************************************************************************************************************************************
Program: 			codevars.do
Purpose: 			set up the data file for analysis
Data inputs: 		recode KR data files
Data outputs:		coded data files
Author:				Lindsay Mallick	
Date last modified: June 23, 2023 by Lindsay Mallick
******************************************************************************************************************************************/
cd "~\coded data"
global origdata "~\original data"
global do 		"~\do"

#delimit ; 
foreach d in 	ALKR71 AOKR71 AMKR72 BDKR72 BJKR71 BUKR70 
				KHKR73 TDKR71 EGKR61 ETKR70 GHKR72 GUKR71 
				HTKR70 IAKR74 IDKR71 JOKR71 KEKR71 LSKR71 
				MWKR7H MVKR71 MMKR71 NPKR7H PKKR71 PHKR70 
				SNKR7Z ZAKR71 TJKR71 TZKR7A TLKR71 UGKR7B 
				ZWKR71  { 
;
#delimit cr

*open data file
	use "$origdata\\`d'FL.dta", clear 

******************************************************************************
*SET UP DATA FILES 
******************************************************************************
	
*run programs to code country-specific strata
* Use the Survey_strata.do file from section 2
	quietly do "$do\Survey_strata".do

*define weight and survey set
	*Gen weight		
	gen wt = v005/1000000
					
	*survey set and set scalar for country
	svyset v021 [pw=wt], strata(strata) singleunit(centered)

	*generate country name
	gen cntry=substr(v000, 1, 2)			
	
*if b19 does not exist,  create equivalent for old calculation method
	capture confirm variable b19
	if _rc { 
		gen b19 = v008 - b3
		label variable b19 "Age of child in months or months since birth"
	}

	if v000 == "MM7" {
		replace b19 = v008 - b3 
		label variable b19 "Age of child in months or months since birth"
		}	
		
	if v000 == "KE6" {
		keep if v044!=.
	}		
	
*restrict to analytic sample
	*keep only births in the last 2 years
		keep if b19<24 & bidx==1

	*keep if newborn did not die on days 0-4
		keep if b6 > 103
		
*set up value label that can be used for binary yes/no variables  
	label define yesno 0 "No" 1 "Yes"	
		
******************************************************************************
*RECODE OUTCOME
******************************************************************************

*calculate bf among all women with a birth in the last 2 years (ever, never, still breastfeeding)
	*early initiation of breastfeeding
	gen eibf = 0 
	replace eibf = 1 if m34 <101
	
*To create one variable that is a continuous measure of time to inititation of breastfeeding in hours, 
	*first, the days and hours need to be coded separately 
	*create a variable for days to initiation
	*then hours
	*then add half of the time period (hour or day) to capture the average-likely the midpoint of the time
	*then create a categorical variable
	if cntry != "BD" & cntry != "IA" & cntry != "ID" & cntry != "ZA" & cntry!= "KE" {
		recode m34 (0/123 = 0)(124/147 201 = 1) (900/999 . 199 299 = 999) if (m4 ==93 | m4==95), gen(days)
		gen bfdays = days
		replace bfdays = days - 200 if days > 201 & days < 998
		replace bfdays = 999 if m4==94|m4==98|m4==99|m4==.
		}
	if cntry == "BD" |cntry == "IA" | cntry == "ID" | cntry== "KE" {
		recode m34 (0/123 = 0)(124/147 201  = 1) (900/999 . 199 299 = 998) , gen(days)
		gen bfdays = days
		replace bfdays = days - 200 if days > 200 & days < 998
		*replace bfdays = 999 if (m4==94) //m4==98 m4==.|
		}
	if cntry == "ZA"  {
		recode m34 (0/123 = 0)(124/147 201  = 1) (900/999 . 199 299 = 999) , gen(days)
		gen bfdays = days
		replace bfdays = days - 200 if days > 200 & days < 998
	}
	if cntry == "GH"  {
		replace bfdays = 3 if m34 ==180
	}
	label var bfdays "Number of days to initiation of breastfeeding"
	
	*combine if days are 4 or greater, missing or other
		recode bfdays (4/900 = 4)(998 999 . = 5), gen(bfdays_r)

	*create a variable for hours to initiation 
		gen bfhours = 0 if m34 < 101
		replace bfhours = m34 -100 if m34 >99 & m34 <200 
		*if one day or greater, combine to 1 day
		replace bfhours = 24 if days > 0 & days <900
		replace bfhours = 999 if bfdays >997
		label var bfhours "Number of hours to initiation of breastfeeding"
		*recode missing to over 24
		recode bfhours(998 999 . = 25), gen(bfhours_r)

	*create one continuous variables
		*add half of time to get to midpoint of time period
		*add days to hours hours to initiation 
		gen bfcont = bfhours+0.5 if bfhours <24
		replace bfcont  = ((bfdays * 24)+12) if  (bfdays!=998&bfdays!=999) & bfdays >0
		label var bfcont "Time to breastfeeding in hours and days converted"

		*categorical variable for ttibf - align with censoring
		recode bfcont (0.5=1 "First hour")(1.5/2.5=2 "1-2 hours")(3.5/5.5=3 "3-5 hours")(6.5/23.5=4 "6-23 hours") ///
			(24/59=5 "Next day")(60/131=6 "2-4 days")(132/2000 = 7), gen(bfcat)
		replace bfcat = 7 if bfhours_r==25 //missing
		replace bfcat = 7 if m4==94 //never
		label define bfcat 7 "5 days+, never, missing", modify	
		label values bfcat bfcat
		label var bfcat "Time to breastfeeding w censor cat"

		
***************************************************
**COVARIATES	
***************************************************

***Demographic characteristics*** 	
*Education
	recode v106 (0  1=1 "None or primary") (2/3=2 "Secondary or higher"), gen(edu)
	label var edu "Education"

*Urban/Rural
	gen residence=v025
	label variable residence "Place of Residence"
	label values residence v025

*Wealth 
	gen wealth=v190
	label variable wealth "Wealth Quintile"
	label values wealth wealth
	label define wealth 1 "Lowest" 2 "Second" 3 "Middle" 4 "Fourth" 5 "Highest"

*Employment	
	recode v717 (0=0 "Not employed") (else=1 "Employed, other"), gen(employ)
	label var employ "Employment"

*Media exposure
	gen media=(v157==2 | v158==2 | v159==2)
	label var media "Exposed to TV,radio or newspaper at least once a week"
	label define med 0 " < once per week" 1 " >= once per week" 
	label val media med

*Marital status
	gen married = 0 
	replace married =1 if v502==1
	label var married "Currently married"
	label def mar 0 "Not married" 1 "Married"
	label val married mar

****Birth vars*******
*Parity
	recode v201(1=1 "1 child")(2/3 = 2 "2-3" ) (4/19 = 3 " 4+"), gen(parity)
	label var parity "Number of children"
	
*ANC 
	recode m14 (4/50= 1 "4 or more ANC visits") (else = 0 "0-3 visits or dk/miss") if v208>0 , gen(anc4) 
	label var anc4 "Number of anc visits"	

*Home, facility delivery, csec	
	gen vagfac = 0 
	replace vagfac = 1 if m15>20 & m15 < 60 
	replace vagfac = 2 if m17 ==1 
	label var vagfac "Mode and place of delivery"
	label define vagfac 0  "Home, vaginal" 1 "Faciliy, vaginal" 2 "Facility, C-section"
	label val vagfac vagfac 

*sex of child
	gen sex = (b4 ==2) 
	label define sex 0 "Male" 1 "Female"
	label val sex sex
	label var sex "Sex of child" 	
	
*Size at birth is a combination of mother-reported size or weight 
	*Mother-reported birth size OR weighted < 2.5 kg at birth
	gen bwt = 0 if (m19a==1|m19a==2) 
	replace bwt = 1 if (m19 < 2500 & m19 >0) & (m19a ==1|m19a==2)
	replace bwt = 2 if (m19 > 4000 & m19 <9000) & (m19a==1|m19a==2)

	*birth size combining card and report
	gen bsize = bwt 
	replace bsize = 0 if (m18==3) & bwt ==.
	replace bsize = 1 if (m18==4| m18==5) & bwt ==.  
	replace bsize = 2 if (m18==1| m18==2) & bwt ==.
	replace bsize = 3 if (m18>5 | m18==.) & bwt ==.
	label var bsize "Size at birth by card or mother's report"
	label define bsize   0 "Normal" 1 "Small or very small" 2 "Large or very large" 3 "Missing" 
	label values bsize bsize
	*group missing with largest value 
	replace bsize =0 if bsize ==3 

*skin to skin and PNC code varies by survey	
	if cntry != "TD" & cntry != "EG" & cntry != "BD" & cntry != "KH"  & cntry != "IA" & cntry != "GH"  & cntry != "KE"  & cntry != "LS" & cntry != "GU"  {
		*Skin to skin
		recode m77 (0 2 3 8 9 . = 0 "No, don't know or missing") (1 = 1 "Yes") , gen(skin2skin)
		label var skin2skin "Baby placed on bare chest immediately after birth"

		*any pnc in 1 hr
		gen pnc1hr= 0 
		replace pnc1hr =1 if (m63<101 | m67<101 | m71 <101 |m75<101)
	}

	if cntry == "TD" | cntry == "EG" | cntry == "BD" | cntry == "KH" | cntry == "IA" | cntry == "GH"  | cntry == "KE" | cntry == "LS" | cntry == "GU" {
		gen pnc1hr= 0 
		replace pnc1hr =1 if (m51<101 |  m71 <101 )
	}

	label define pnc1hr 0 "No PNC in first hour after birth" 1 "PNC in first hour after birth"
	label values pnc1hr pnc1hr	

*save with unique file name	
	local cntry = substr(v000, 1, 2)
	save "`cntry'.dta", replace
	
}	
