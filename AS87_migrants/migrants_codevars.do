/*****************************************************************************************************
Program: 			migrants_codevars.do
Purpose: 			Code variables for internal migrants report
Data inputs: 		IR files
Data outputs:		coded IR files
Author:				Shireen Assaf			
Date last modified: July 27, 2023 by Shireen Assaf 

*****************************************************************************************************/

* path to DHS data
global Datafilepath "C:\DHSdata"

* surveys used in the analysis. These surveys must be downloaded and saved in your Datafilepath
global irdata "BDIR7RFL BDIR51FL BJIR71FL BJIR51FL CMIR71FL CMIR44FL HTIR71FL HTIR52FL KEIR72FL KEIR42FL LBIR7AFL LBIR51FL NPIR7HFL PHIR71FL PHIR52FL RWIR81FL RWIR53FL SLIR7AFL SLIR51FL ZAIR71FL TZIR7BFL  UGIR7BFL UGIR52FL ZMIR71FL ZMIR51FL ZWIR72FL ZWIR52FL"

 foreach c in $irdata {
  use "$Datafilepath//`c'.dta", clear
	
	gen sur="`c'"
	local cn=substr("`c'",1,6)
	
	*getting the country two letter acronym. 
	local cntry=substr("`c'",1,2)
	
	gen tot=1
	gen wt=v005/1000000
	
	* to get strata, this can be found in the Intro_DHSdata_Analysis\2_SurveyDesign folder of the Analysis repository 
	do "Survey_strata.do"
	
	* age of child
	gen age = v008 - b3_01
	
	*to check if survey has b19, which should be used instead to compute age. 
	scalar b19_included=1
		capture confirm numeric variable b19_01, exact 
		if _rc>0 {
		* b19 is not present
		scalar b19_included=0
		}
		if _rc==0 {
		* b19 is present; check for values
		qui summarize b19_01
		  if r(sd)==0 | r(sd)==. {
		  scalar b19_included=0
		  }
		}

	if b19_included==1 {
	drop age
	gen age=b19_01
	}
	
***************************************************************************	
*** Main indicators/outcomes ***
***************************************************************************	

* ANC visits 
recode m14_1 (4/90=1) (else=0), gen(anc)
replace anc=. if age>=36  
label var anc "Four or more ANC visits in the last 3 years"

* modern contraceptive use
recode v313 (3=1) (else=0), gen(mcpr)
replace mcpr=. if v525==0 // replace as missing those who never had sex 
label var mcpr "Modern contraceptive use"
	
*** Probems accessing care ***

*Obtaining money
recode v467c (0 2 9 . = 0 "No") (1 = 1 "Yes"), gen(prob_money)
label var prob_money "Problem health care access: getting money"
	
*Distance to facility
recode v467d (0 2 9 . = 0 "No") (1 = 1 "Yes"), gen(prob_dist)
label var prob_dist "Problem health care access: distance to facility"	

* country specific code required after checks
if "`c'"=="CMIR71FL" | "`c'"=="HTIR71FL" | "`c'"=="KEIR72FL"  {
replace mcpr=. if v313==.
replace prob_dist=. if v467d==.
replace prob_money=. if v467c==.
}

***************************************************************************	
*** Migrant status variables ***
***************************************************************************	

* dropping those whose previous place of residence is not known if they are not residents or those who previously lived abroad.
cap gen v105a=. // older surveys do not have this variable

	if "`c'"!="ZAIR71FL"{
	drop if (v105>3 | v105a==96) & v104!=95 
	}

	if "`c'"=="ZAIR71FL"{
	drop if (v105>3 | v105a==26) & v104!=95 
	}

drop if v104==96 // dropping visitors

* drop child migrants, to do this must calculate age at migration
gen agemigrate= v012-v104
replace agemigrate=. if v104==95
drop if agemigrate<18

* keep only adult respondents <18 
drop if v012<18

* place of previous residence
recode v105 (0/2=1 urban) (3/7=2 rural) (else=.), gen(prevresd)

* years lived in place of residence
recode v104 (0/2=1 "less than 3 years") (3/9=2 "3-9 years") (10/94=3 "10+ years") (95=4 "non-migrants") (else=.), gen (yrstay)
replace yrstay=4 if v104>v012  & v104<95 // incase there was an error in reporting yrs of stay more than current age. 
label var yrstay "years lived in residence"

egen migrantsall = group(v025 yrstay prevresd)
replace migrantsall=13 if v025==2 & yrstay==4
replace migrantsall=14 if v025==1 & yrstay==4

*All types of migrants by all durations of stay including within urban and within rural migrants. 
label define migrantsall 1 "urb-urb <3" 2"rur-urb <3" 3"urb-urb 3-9" 4"rur-urb 3-9" 5"urb-urb 10+" 6"rur-urb 10+" 7"urb-rur <3" 8"rur-rur <3" 9"urb-rur 3-9" 10"rur-rur 3-9" 11"urb-rur 10+" 12"rur-rur 10+" 13"rural non-migrants" 14"urban non-migrants"
label values migrantsall migrantsall
label var migrantsall "Migration status with all categories of duration of stay and all migration streams"

/* Assumptions set for the analysis: Please read the report for more details
 *1st assumption: migrants who stayed 10+ years in current place of residents, can be considered residents 
 *2nd assumption: within urban or within rural migrants, can be considered residents of the place of residence
urban non-migrants // 10+ years, urban residents, urban-urban migrants
rural-urban migrant <3yrs //recent migrant
rural-urban migrant 3-9 // migrant 
rural non-migrants // 10+ years, rural residents, rural-rural migrants
urban-rural migrant <3 yr // recent migrant
urban-rural migrant 3-9 // migrant
*/

* migrant status after second assumption only
recode migrantsall (8 10 12 13=1 "rural non-migrants") (1 3 5 14= 2 "urban non-migrants") (6=3 "rural-urban 10+") (4=4 "rural-urban 3-9yrs") (2=5 "rural-urban <3yrs") (11=6 "urban-rural 10+") (9=7 "urban-rural 3-9yrs") (7=8 "urban-rural <3yrs"), gen(migt)
label var migt "Migration status by time spent in current place of residence"

* migrant status after both assumptions - this measure was used in the analysis
recode migrantsall (1 3 5 6 14= 1 "urban non-migrants") (4=2 "rural-urban 3-9yrs") (2=3 "rural-urban <3yrs") (8 10 11 12 13=4 "rural non-migrants") (9=5 "urban-rural 3-9yrs") (7=6 "urban-rural <3yrs"), gen(migrants)
label var migrants "Migration status by time spent in current place of residence"

***************************************************************************	
*** Background variables ***
***************************************************************************	

* current age
* use v013

* number of living children
recode v218 (4/max = 4 "4+"), gen(numchild)

* marital status
* use v502

* education
recode v106 (0=1 None) (1=2 Primary) (2/3=3 "Secondary+") (8/9=.), gen(edu) 

* working by pay status
gen work=.
replace work=1 if v714==0
replace work=2 if v741==0 & v714==1
replace work=3 if v741>0 & v714==1
label define work 1"Not working" 2"Working but not paid" 3"Working and paid"
label values work work
label var work "working by pay status"	

 **** Year of survey ****
qui sum v007
scalar year1=string(r(min))
scalar year2=string(r(max))

if (year1==year2) {
  scalar year3 = " "
 }
else if (year1!=year2) {
  scalar year3 = "-" + substr(year2,3,4)
 }
                                             
gen yrstr=year1 + year3

*checking variables with one-way tabulation
*tabout migrantsall migrants numchild edu work anc mcpr prob_money prob_dist using "`cn'migrantdist.xls", c(cell) oneway nwt(wt) per pop append

keep v000-v313 m14_1 v467* v501 v502 b3_01 bidx_01 bord_01 sur-yrstr 

save "`c'coded.dta", replace 

	}


  