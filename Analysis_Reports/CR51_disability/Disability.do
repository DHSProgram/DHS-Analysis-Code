/*****************************************************************************************************
Program: 			Disability.do
Purpose: 			Code disability variables
Author:				Shireen Assaf. 	
Date last modified: July 17, 2023 by Shireen Assaf 				
*****************************************************************************************************/

* path to DHS data, change to your own path
global Datafilepath "C:\DHSdata"

* surveys used in the analysis. These surveys must be downloaded and saved in your Datafilepath
global prdata "HTPR71FL MLPR7AFL NGPR7BFL PKPR71FL RWPR81FL ZAPR71FL SNPR8BFL TLPR71FL UGPR7BFL"

* Prepare PR files 
foreach c in $prdata {
use "$Datafilepath/`c'.dta", clear

*drop under 5 - disability questions not asked for children 0-4
drop if hv105<5

**************************************
*** Disabilitiy measrues ***
**************************************

* Uganda and Senegal have country-specific disability variable names. Therefore, these are renamed to the standard variable names for all countries. 

*Rename Uganda disability vars
 if "`c'"=="UGPR7BFL" {
	rename sh23 hdis1	//glasses
	rename sh24 hdis2	//vision
	replace hdis2=sh25 if hdis2==.
	rename sh26 hdis3	//hearing aid
	rename sh27 hdis4	//hearing
	replace hdis4=sh28 if hdis4==.
	rename sh29 hdis5	//communication
	rename sh30 hdis6	//cognition
	rename sh31 hdis7	//mobility
	rename sh32 hdis8	//self-care			
	}

*Rename Senegal disability vars
 if "`c'"=="SNPR8BFL" {
	rename sh20ga hdis1	//glasses
	rename sh20gb hdis2	//vision
	replace hdis2=sh20gc if hdis2==.
	rename sh20gd hdis3	//hearing aid
	rename sh20ge hdis4	//hearing
	replace hdis4=sh20gf if hdis4==.
	rename sh20gg hdis5	//communication
	rename sh20gh hdis6	//cognition
	rename sh20gi hdis7	//mobility
	rename sh20gj hdis8	//self-care
	}

**Disability vars - any difficulty coded as disability
	gen dsight= inrange(hdis2,2,7)
	replace dsight=. if hdis2==.
	lab var dsight "Vision disability - any"
		
	gen dhear= inrange(hdis4,2,7)
	replace dhear=. if hdis4==.
	lab var dhear "Hearing disability - any"
		
	gen dspeech= inrange(hdis5,2,7)
	replace dspeech=. if hdis5==.
	lab var dspeech "Speech/communication disability - any"
		
	gen dcog= inrange(hdis6,2,7)
	replace dcog=. if hdis6==.
	lab var dcog "Cognitive disability - any"
		 
	gen dwalk= inrange(hdis7,2,7)
	replace dwalk=. if hdis7==.
	lab var dwalk "Mobility disability - any"
		
	gen dcare=inrange(hdis8,2,7)
	replace dcare=. if hdis8==.
	lab var dcare "Self-care disability - any"
	
	gen disab=0
	replace disab=1 if dsight==1 | dhear==1 | dspeech==1 | dcog==1 | dwalk==1 | dcare==1
	replace disab=. if hdis2==. | hdis4==.| hdis5==.| hdis6==. | hdis7==.| hdis8==.
	lab var disab "Any disability"
	
		
	egen totdisany= rsum(dsight dhear dspeech dcog dwalk dcare)
	recode totdisany (0=0 "None") (1=1 "One") (2/6=2 "2+"), gen(disnumany)
	lab var disnumany "Number of disabilities - any"
	
	recode totdisany (2/6=1 "2+") (0/1=0 "0-1"), gen(dis2p)

	
**Disability vars - a lot of difficulty or cannot do at all
	gen dsightsv= inrange(hdis2,3,7)
	replace dsightsv=. if hdis2==.
	lab var dsightsv "Vision disability - severe"
		
	gen dhearsv= inrange(hdis4,3,7)
	replace dhearsv=. if hdis4==.
	lab var dhearsv "Hearing disability - severe"
		
	gen dspeechsv= inrange(hdis5,3,7)
	replace dspeechsv=. if hdis5==.
	lab var dspeechsv "Speech/communication disability - severe"
		
	gen dcogsv= inrange(hdis6,3,7)
	replace dcogsv=. if hdis6==.
	lab var dcogsv "Cognitive disability - severe"
		
	gen dwalksv= inrange(hdis7,3,7)
	replace dwalksv=. if hdis7==.
	lab var dwalksv "Mobility disability - severe"
		
	gen dcaresv=inrange(hdis8,3,7)
	replace dcaresv=. if hdis8==.
	lab var dcaresv "Self-care disability - severe"
		
	gen disabsv=0
	replace disabsv=1 if dsightsv==1 | dhearsv==1 | dspeechsv==1 | dcogsv==1 | dwalksv==1 | dcaresv==1
	replace disabsv=. if hdis2==. | hdis4==.| hdis5==.| hdis6==. | hdis7==.| hdis8==.
	lab var disabsv "Any disability - severe"
		
	egen totdissv= rsum(dsightsv dhearsv dspeechsv dcogsv dwalksv dcaresv)
	recode totdissv (0=0 "None") (1=1 "One") (2/6=2 "2+"), gen(disnumsv)
	lab var disnumsv "Number of disabilities  - severe"
	
	recode totdissv (2/6=1 "2+") (0/1=0 "0-1"), gen(dis2psv)
 	
**************************************
*** Background vars ***
**************************************

* sex hv104

*age 
recode hv105 (5/14=0 "5-14") (15/24 =1 "15-24") (25/34=2 "25-34") (35/49=3 "35-49") (50/95=4 "50+") (else=.), gen(hhage)
* age2
recode hv105 (5/9=0 "5-9") (10/14 =1 "10-14") (15/19=2 "15-19") (20/29=3 "20-29") (30/39=4 "30-39") (40/49=5 "40-49") (50/59=6 "50-59") (60/95=7 "60+") (else=.), gen(hhage2)

* edu
recode hv106 (0=1 None) (1=2 Primary) (2/3=3 "Secondary+") (8/9=.), gen(hhedu) 

*marital status
recode hv115 (0=1 "Never married") (1=2 "Currently in a union") (2/4=3 "Formally in a union") (8 9 . =4 "No marital status information or NA"), gen(hhmstatus)
	
* wealth v190
* need to modify the label to change from poorest, etc to the labels below
cap label define hv270 1"Lowest" 2"Second" 3"Middle" 4"Fourth" 5"Highest", modify
cap label define HV270 1"Lowest" 2"Second" 3"Middle" 4"Fourth" 5"Highest", modify

* place of residence v025	 
cap label define hv025 1"Urban" 2"Rural", modify
cap label define HV025 1"Urban" 2"Rural", modify

*number of household members
recode hv009 (1/2=1 "1-2") (3/4=2 "3-4") (5/8=3 "5-8") (9/max=4 "9+") (98 99 =.), gen(hhnum)
label var hhnum "Number of household members"

**************************************

* for merging with IR files
gen  v001=hv001
gen  v002=hv002
gen  v003=hvidx

* for merging with MR files
gen  mv001=hv001
gen  mv002=hv002
gen  mv003=hvidx

*** Strata ***
* to get strata, this can be found in the Intro_DHSdata_Analysis\2_SurveyDesign folder of the Analysis repository 
qui do "Survey_strata.do"
	
keep v001-v003 mv001-mv003 hv000-hv025 hv102-hv105 hv270 d* hh* tot* strata

*to get the country code (ex: HT, ML, etc.)
local cn=substr("`c'",1,2)

save "$Codedfilepath//`cn'PRcoded.dta", replace
}
