/*****************************************************************************************************
Program: 			DHScodevars.do
Purpose: 			code variables for each survey
Author:				Shireen Assaf			
Date last modified: Jan 5, 2021 by Shireen Assaf 
					Feb 24, 2021 by Shireen add ANC 8+ visits and ANC skilled provider vars
					Feb 25, 2021 by Sara Riese to update regions
					Mar 10, 2021 by Sara Riese to fix TZ ARI treatmentvar coding
					Mar 15, 2021 by Shireen to fix anc_skill variable in SN and TZ
					Mar 15, 2021 by Shireen to fix ANC indicators to match FR
					Mar 17, 2021 by Shireen to fix iron to be among those with any anc and add composite index. 
					Mar 19 by Shireen to add ANC composite indicies
					April 22 by Sara to fix coding of ch_diar_care and ch_ari_care
*****************************************************************************************************/

* IR files for ANC
foreach c in $irdata {
use "$DHSdatafilepath//`c'.dta", clear

label define yesno 0"No" 1"Yes"

**** Strata ****
qui do "C:\Users\\$user\ICF\Analysis - Shared Resources\Code\Stata Code\Survey_strata.do"

**** age of child ****
gen age = v008 - b3_01	
	* to check if survey has b19, which should be used instead to compute age. 
	scalar b19_included=1
		capture confirm numeric variable b19_01, exact 
		if _rc>0 {
		* b19 is not present
		scalar b19_included=0
		}
		if _rc==0 {
		* b19 is present; check for values
		summarize b19_01
		  if r(sd)==0 | r(sd)==. {
		  scalar b19_included=0
		  }
		}
	if b19_included==1 {
	drop age
	gen age=b19_01
	}
*****************************************
* change period to either last five years or last 2 years
gen period = 60

*gave birth in last five years
recode v208 (0=0) (1/4=1) , gen(birth5yr)
label values birth5yr yesno

//4+ ANC visits
recode m14_1 (0/3 98/99=0) (4/90=1), gen(anc4)
replace anc4=. if age>=period  
label values anc4 yesno	
lab var anc4 "Attended 4+ ANC visits"

//8+ ANC visits
recode m14_1 (0/7 98/99=0) (8/90=1), gen(anc8)
replace anc8=. if age>=period  
label values anc8 yesno	
lab var anc8 "Attended 8+ ANC visits"
		
//Any ANC visits (for denominator of ANC components indicators)
recode m14_1 (0 99 = 0 "None") (1/90 98 = 1 "1+ ANC visit"), g(ancany)

//ANC by type of provider
** Note: Please check the final report for this indicator to determine the categories and adjust the code and label accordingly. 
gen anc_pv = 6 if m2a_1! = .
replace anc_pv 	= 4 	if m2f_1 == 1 | m2g_1 == 1 | m2h_1 == 1 | m2i_1 == 1 | m2j_1 == 1 | m2k_1 == 1 | m2l_1 == 1 | m2m_1 == 1
replace anc_pv 	= 3 	if m2c_1 == 1 | m2d_1 == 1 | m2e_1 == 1
replace anc_pv 	= 2 	if m2b_1 == 1
replace anc_pv 	= 1 	if m2a_1 == 1
replace anc_pv 	= 5 	if m2a_1 == 9
replace anc_pv	= .		if age>=period
	
label define anc_pv ///
1 "Doctor" 		///
2 "Nurse/midwife"	///
3 "Other health worker" ///
4 "TBA/other/relative"		///
5 "Missing" ///
6 "No ANC" 
label val anc_pv anc_pv
label var anc_pv "Person providing assistance during ANC"	
	
//proxy for ANC in facility is ANC by doctor, nurse/midwife or other health worker
recode anc_pv (1/2 =1) (3/6=0), gen(anc_skill)
label var anc_skill "ANC by a skilled provider"

*for Senegal m2c_1 is nurse, nurse is not combined with midwife in m2b as in other surveys
if "`c'"=="SNIR81FL"{
drop anc_skill
*since m2d and m2e have no obs they I can recode anc_pv again to include m2c
recode anc_pv (1/3 =1) (4/6=0), gen(anc_skill)
}

*different code for TZ as well.
if "`c'"=="TZIR7BFL"{
drop anc_skill
gen anc_skill = 0 if m2a_1! = .
replace anc_skill 	= 1 	if m2a_1 == 1 | m2b_1 == 1 | m2c_1 == 1 | m2g_1 == 1 
*| m2h_1 == 1 | m2i_1 == 1 
* we exclude nurse assistant and MCH aide for consistency with other surveys. will not match FR
replace anc_skill	= .		if age>=period
}
	
*** ANC components ***	
//Took iron tablets or syrup
*reducing this denominator to those who had any anc visit so it can match with other components. 
*This will not match the FR
recode m45_1 (1=1 "yes") (else=0 "No") if v208>0 & ancany==1, gen(anc_iron)
replace anc_iron=. if age>=period  
label var anc_iron "Took iron tablet/syrup during pregnancy of last birth"
	
//Took intestinal parasite drugs 
*will not be using this.
cap recode m60_1 (1=1 "yes") (else=0 "No") if v208>0, gen(anc_parast)
cap replace anc_parast=. if age>=period  
cap label var anc_parast "Took intestinal parasite drugs during pregnancy of last birth"
* for surveys that do not have this variable
cap gen anc_parast=.
*/
	
//Informed of pregnancy complications
gen anc_prgcomp = 0 if ancany==1
replace anc_prgcomp = 1 if m43_1==1 & ancany==1
label values anc_prgcomp yesno
label var anc_prgcomp "Informed of pregnancy complications during ANC visit"
* In Nepal this is s413e_1 but will not recode since this indicator was only available in SN and NP
	
//Blood pressure measured
gen anc_bldpres = 0 if ancany==1
replace anc_bldpres=1 if m42c_1==1 & ancany==1
label values anc_bldpres yesno
label var anc_bldpres "Blood pressure was taken during ANC visit"
	
//Urine sample taken
gen anc_urine = 0 if ancany==1
replace anc_urine=1 if m42d_1==1 & ancany==1
label values anc_urine yesno
label var anc_urine "Urine sample was taken during ANC visit"
	
//Blood sample taken
*will not be using this.
gen anc_bldsamp = 0 if ancany==1
replace anc_bldsamp = 1 if m42e_1==1 & ancany==1
label values anc_bldsamp yesno
label var anc_bldsamp "Blood sample was taken during ANC visit"
*/
	
//tetnaus toxoid injections
recode m1_1 (0 1 8 9 . = 0 "No") (1/7 = 1 "Yes"), gen(anc_toxinj)
replace anc_toxinj = . if age>=period
label var anc_toxinj "Received 2+ tetanus injections during last pregnancy"
*****************************************
**** Background variables ****
* edu
recode v106 (0=1 None) (1=2 Primary) (2/3=3 "Secondary+") (8/9=.), gen(edu) 
	
* wealth v190
* need to modify the label to change from poorest, etc to the labels below
cap label define v190 1"Lowest" 2"Second" 3"Middle" 4"Fourth" 5"Highest", modify
cap label define V190 1"Lowest" 2"Second" 3"Middle" 4"Fourth" 5"Highest", modify

* place of residence v025	 
cap label define v025 1"Urban" 2"Rural", modify
cap label define V025 1"Urban" 2"Rural", modify


*region

if v000=="HT7" {
gen region2=v024+1
label define region2 1 "Aire metropolitaine" 2 "Rest-Ouest" 3 "Sud-Est" 4 "Nord" 5 "Nord-Est" 6 "Artibonite" 7 "Centre" 8 "Sud" 9 "Grand'Anse" 10 "Nord-Ouest" 11 "Nippes"
label values region2 region2
}

if v000=="MW7" {
gen region2=v024
label values region2 V024
}

if v000=="NP7" {
recode sdist (1/16=1 "Eastern development region") (17/35=2 "Central development region") (36/51=3 "Western development region") (52/66=4 "Mid-western development region") (67/75=5 "Far-western development region"), gen(region2)
}

if v000=="SN7"{
gen region2=0
replace region2 = 1 if v024==8 | v024==11 | v024==4
replace region2 = 2 if v024==1
replace region2 = 3 if v024==7
replace region2 = 4 if v024==6 | v024==3 | v024==9 | v024==12
* no Touba
replace region2 = 5 if v024==5 | v024==13
replace region2 = 6 if v024==10 | v024==2 | v024==14
* no Bignona or Kafountine
label define region2 1"North" 2"Dakar" 3"Thiès" 4"Central" 5"East" 6"South"
label values region2 region2
}

if v000=="TZ7" {
*Used geographic zones from page 13 of 2015-16 DHS report.
recode v024 (14 16 =1 "Western") (2/4=2 "Northern") (1 13 21=3 "Central") (10 11 22=4 "Southern Highlands") (8/9=5 "Southern") (12 15 23=6 "South West Highlands") (17/20 24/25=7 "Lake") (5/7=8 "Eastern") (51/55=9 "Zanzibar"), gen(region2)
}

*****************************************
*COMPOSITE MEASURES

*Approach 1-3 service coverage
g anc_c_123=ancany
label var anc_c_123 "ANC service contact coverage"

*Approach 1-3 intervention coverage
gen anc_i_123 = anc4
label var anc_i_123 "ANC intervention coverage"

*Approach 1 quality coverage
gen anc_q_1= (anc_iron + anc_bldpres + anc_urine + anc_toxinj) *(100/4)
label var anc_q_1 "Approach 1 ANC quality coverage"

*****************************************	
**** saving file ****

keep v000-v190 strata age period birth5yr anc* edu region2 
scalar country = substr(v000,1,2)
local country=country
save "$Codedfilepath//`country'/`c'coded.dta", replace
}

*/
**********************************************************************************
**********************************************************************************

*KR files for Sick Child
foreach c in $krdata {
use "$DHSdatafilepath//`c'.dta", clear

label define yesno 0"No" 1"Yes"
	
**** Strata ****
qui do "C:\Users\\$user\ICF\Analysis - Shared Resources\Code\Stata Code\Survey_strata.do"

**** age of child ****
gen age = v008 - b3
	* to check if survey has b19, which should be used instead to compute age. 
	scalar b19_included=1
		capture confirm numeric variable b19, exact 
		if _rc>0 {
		* b19 is not present
		scalar b19_included=0
		}
		if _rc==0 {
		* b19 is present; check for values
		summarize b19
		  if r(sd)==0 | r(sd)==. {
		  scalar b19_included=0
		  }
		}
	if b19_included==1 {
	drop age
	gen age=b19
	}

*****************************************
	
* change period to either last five years or last 2 years
gen period = 60

//ARI symptoms
* ari defintion differs by survey according to whether h31c is included or not
	scalar h31c_included=1
		capture confirm numeric variable h31c, exact 
		if _rc>0 {
		* h31c is not present
		scalar h31c_included=0
		}
		if _rc==0 {
		* h31c is present; check for values
		summarize h31c
		  if r(sd)==0 | r(sd)==. {
		  scalar h31c_included=0
		  }
		}
//all EC surveys have h31c included
if h31c_included==1 {
	gen ch_ari=0
	cap replace ch_ari=1 if h31b==1 & (h31c==1 | h31c==3)
	replace ch_ari =. if b5==0
}

if h31c_included==0 {
	gen ch_ari=0
	cap replace ch_ari=1 if h31b==1 & (h31==2)
	replace ch_ari =. if b5==0
}
	
label var ch_ari "ARI symptoms in the 2 weeks before the survey"
	
//ARI care-seeking
*Where sick children sought care is country specific, so
		
	if v000=="HT7" {
		gen ch_ari_care=0 if ch_ari==1
		foreach x in a b c d h i {
			replace ch_ari_care=1 if ch_ari==1 & h32`x'==1
			}
		gen ch_ari_care_govhosp=0 if ch_ari==1
		gen ch_ari_care_govhc=0 if ch_ari==1
		gen ch_ari_care_privhosp=0 if ch_ari==1
		gen ch_ari_care_privhc=0 if ch_ari==1
		replace ch_ari_care_govhosp=1 if ch_ari==1 & h32a==1
		replace ch_ari_care_govhc=1 if ch_ari==1 & h32b==1
		replace ch_ari_care_privhosp=1 if ch_ari==1 & (h32c==1 | h32h==1)
		replace ch_ari_care_privhc=1 if ch_ari==1 & (h32d==1 | h32i==1) //includes Haiti specific category of  "mixed" sector facilities.
	
	}

		if v000=="MW7" {
		gen ch_ari_care=0 if ch_ari==1
		foreach x in a b c h g j {
			replace ch_ari_care=1 if ch_ari==1 & h32`x'==1
			}
		gen ch_ari_care_govhosp=0 if ch_ari==1
		gen ch_ari_care_govhc=0 if ch_ari==1
		gen ch_ari_care_privhosp=0 if ch_ari==1
		gen ch_ari_care_privhc=0 if ch_ari==1
		replace ch_ari_care_govhosp=1 if ch_ari==1 & h32a==1
		replace ch_ari_care_govhc=1 if ch_ari==1 & (h32b==1 |h32c==1)
		replace ch_ari_care_privhosp=1 if ch_ari==1 & (h32g==1 | h32j==1)  //includes Malawi category of priv hosp/clinic
		replace ch_ari_care_privhc=1 if ch_ari==1 & h32h==1 
	}
	
		if v000=="NP7" {
		gen ch_ari_care=0 if ch_ari==1
		foreach x in a b c j k {
			replace ch_ari_care=1 if ch_ari==1 & h32`x'==1
			}
		gen ch_ari_care_govhosp=0 if ch_ari==1
		gen ch_ari_care_govhc=0 if ch_ari==1
		gen ch_ari_care_privhosp=0 if ch_ari==1
		gen ch_ari_care_privhc=0 if ch_ari==1
		replace ch_ari_care_govhosp=1 if ch_ari==1 & h32a==1
		replace ch_ari_care_govhc=1 if ch_ari==1 & (h32b==1 |h32c==1)
		replace ch_ari_care_privhosp=1 if ch_ari==1 & h32j==1 
		replace ch_ari_care_privhc=1 if ch_ari==1 & h32k==1 
	}
	
		if v000=="SN7" {
		gen ch_ari_care=0 if ch_ari==1
		foreach x in a b c g {
			replace ch_ari_care=1 if ch_ari==1 & h32`x'==1
			}
		gen ch_ari_care_govhosp=0 if ch_ari==1
		gen ch_ari_care_govhc=0 if ch_ari==1
		gen ch_ari_care_privhosp=0 if ch_ari==1
		gen ch_ari_care_privhc=0 if ch_ari==1
		replace ch_ari_care_govhosp=1 if ch_ari==1 & h32a==1
		replace ch_ari_care_govhc=1 if ch_ari==1 & (h32b==1 |h32c==1)
		replace ch_ari_care_privhosp=1 if ch_ari==1 & h32g==1 
		*replace ch_ari_care_privhc=1 if ch_ari==1 & h32h==1  //priv hosp/clinic are combined in Senegal DHS
	}
	
		if v000=="TZ7" {
		gen ch_ari_care=0 if ch_ari==1
		foreach x in a b c d  e f g i j k o p l m n q r s {
			replace ch_ari_care=1 if ch_ari==1 & h32`x'==1
			}
		gen ch_ari_care_govhosp=0 if ch_ari==1
		gen ch_ari_care_govhc=0 if ch_ari==1
		gen ch_ari_care_privhosp=0 if ch_ari==1
		gen ch_ari_care_privhc=0 if ch_ari==1
		replace ch_ari_care_govhosp=1 if ch_ari==1 & (h32a==1 | h32b==1 | h32c==1 | h32d==1)
		replace ch_ari_care_govhc=1 if ch_ari==1 & (h32e==1 | h32f==1 | h32g==1)
		replace ch_ari_care_privhosp=1 if ch_ari==1 & (h32i==1 | h32j==1 | h32k==1 | h32o==1 | h32p==1)
		replace ch_ari_care_privhc=1 if ch_ari==1 & (h32l==1 | h32m==1 | h32n==1 | h32q==1 | h32r==1 | h32s==1)
	}

label var ch_ari_care "Advice or treatment sought for ARI symptoms"
label var ch_ari_care_govhosp "Sought care at government hospital"
label var ch_ari_care_govhc "Sought care at government health center or below"
label var ch_ari_care_privhosp "Sought care at private hospital"
label var ch_ari_care_privhc "Sought care at private health center or below"

label values ch_ari_care_govhosp-ch_ari_care_privhc yesno

//Children with symptoms of ARI who received antibiotics
gen ch_ari_antibi=0 if ch_ari==1
replace ch_ari_antibi=1 if ch_ari==1 & (ml13i==1 | ml13j==1)
cap replace ch_ari_antibi=1 if ch_ari==1 & ml13o==1
replace ch_ari_antibi =. if b5==0
label var ch_ari_antibi "Children under 5 with symptoms of ARI who received antibiotics"


//Diarrhea symptoms
gen ch_diar=0
replace ch_diar=1 if h11==1 | h11==2
replace ch_diar =. if b5==0
label var ch_diar "Diarrhea in the 2 weeks before the survey"

//Diarrhea treatment	

*/


//Categorize by hftype

		
	if v000=="HT7" {
		gen ch_diar_care=0 if ch_diar==1
		foreach z in a b c d h i {
			replace ch_diar_care=1 if ch_diar==1 & h12`z'==1
		}
		gen ch_diar_care_govhosp=0 if ch_diar==1
		gen ch_diar_care_govhc=0 if ch_diar==1
		gen ch_diar_care_privhosp=0 if ch_diar==1
		gen ch_diar_care_privhc=0 if ch_diar==1
		replace ch_diar_care_govhosp=1 if ch_diar==1 & h12a==1
		replace ch_diar_care_govhc=1 if ch_diar==1 & h12b==1   //health center is inclusive of dispensary in this survey
		replace ch_diar_care_privhosp=1 if ch_diar==1 & (h12c==1 | h12h==1)
		replace ch_diar_care_privhc=1 if ch_diar==1 & (h12d==1 | h12i==1) //includes Haiti specific category of  "mixed" sector facilities, also includes dispensaries
	}

		if v000=="MW7" {
		gen ch_diar_care=0 if ch_diar==1
		foreach z in a b c g h i {
			replace ch_diar_care=1 if ch_diar==1 & h12`z'==1
			}
		gen ch_diar_care_govhosp=0 if ch_diar==1
		gen ch_diar_care_govhc=0 if ch_diar==1
		gen ch_diar_care_privhosp=0 if ch_diar==1
		gen ch_diar_care_privhc=0 if ch_diar==1
		replace ch_diar_care_govhosp=1 if ch_diar==1 & h12a==1
		replace ch_diar_care_govhc=1 if ch_diar==1 & (h12b==1 | h12c==1)    //include health centers and health posts
		replace ch_diar_care_privhosp=1 if ch_diar==1 & (h12g==1 | h12i==1)  //includes cham and private hospitals/clinics
		replace ch_diar_care_privhc=1 if ch_diar==1 & h12h==1 				//ncludes cham health centers only, no other private health centers
	}
	
		if v000=="NP7" {
		gen ch_diar_care=0 if ch_diar==1
		foreach z in a b c j k {
		replace ch_diar_care=1 if ch_diar==1 & h12`z'==1
			}
		gen ch_diar_care_govhosp=0 if ch_diar==1
		gen ch_diar_care_govhc=0 if ch_diar==1
		gen ch_diar_care_privhosp=0 if ch_diar==1
		gen ch_diar_care_privhc=0 if ch_diar==1
		replace ch_diar_care_govhosp=1 if ch_diar==1 & h12a==1					// govnt hospital/clinic
		replace ch_diar_care_govhc=1 if ch_diar==1 & (h12b==1 | h12c==1)		// primary health center and health posts
		replace ch_diar_care_privhosp=1 if ch_diar==1 & h12j==1 				//pvt hospital/nursing home
		replace ch_diar_care_privhc=1 if ch_diar==1 & h12k==1 				// pvt clinic
	}
	
		if v000=="SN7" {
		gen ch_diar_care=0 if ch_diar==1
		foreach z in a b c g  {
			replace ch_diar_care=1 if ch_diar==1 & h12`z'==1
			}
		gen ch_diar_care_govhosp=0 if ch_diar==1
		gen ch_diar_care_govhc=0 if ch_diar==1
		gen ch_diar_care_privhosp=0 if ch_diar==1
		gen ch_diar_care_privhc=0 if ch_diar==1
		replace ch_diar_care_govhosp=1 if ch_diar==1 & h12a==1 
		replace ch_diar_care_govhc=1 if ch_diar==1 & (h12b==1 | h12c==1)		//includes health centers and health posts
		replace ch_diar_care_privhosp=1 if ch_diar==1 & h12g==1 				//includes private hospitals/clinics
		*replace ch_diar_care_privhc=1 if ch_diar==1 & h12h==1  //h12h is pharmacy in the Senegal survey. There is no private health center option
	}
	
		if v000=="TZ7" {
		gen ch_diar_care=0 if ch_diar==1
		foreach z in a b c d e f g i j k l m n o p q r s {
			replace ch_diar_care=1 if ch_diar==1 & h12`z'==1
		}
		gen ch_diar_care_govhosp=0 if ch_diar==1
		gen ch_diar_care_govhc=0 if ch_diar==1
		gen ch_diar_care_privhosp=0 if ch_diar==1
		gen ch_diar_care_privhc=0 if ch_diar==1
		replace ch_diar_care_govhosp=1 if ch_diar==1 & (h12a==1 | h12b==1 | h12c==1 | h12d==1)		//all different types of hospitals (specialized, referral, regional, district)
		replace ch_diar_care_govhc=1 if ch_diar==1 & (h12e==1 | h12f==1 | h12g==1)			//health center, dispensaries, and clinics
		replace ch_diar_care_privhosp=1 if ch_diar==1 & (h12i==1 | h12j==1 | h12k==1 | h12o==1 | h12p==1)		//specialized, referral and district hospitals both religious, voluntary, and private
		replace ch_diar_care_privhc=1 if ch_diar==1 & (h12l==1 | h12m==1 | h12n==1 | h12q==1 | h12r==1 | h12s==1) 		//health center, dispensary, clinics both religious, voluntary, and private
	}

label var ch_diar_care "Advice or treatment sought for diarrhea"
label var ch_diar_care_govhosp "Sought care at government hospital"
label var ch_diar_care_govhc "Sought care at government health center or below"
label var ch_diar_care_privhosp "Sought care at private hospital"
label var ch_diar_care_privhc "Sought care at private health center or below"

gen hftype=.
replace hftype=1 if ch_ari_care_govhosp==1
replace hftype=2 if ch_ari_care_govhc==1
replace hftype=3 if ch_ari_care_privhosp==1
replace hftype=4 if ch_ari_care_privhc==1

label define hftype 1 "Govt hospital" 2 "Govt health center" 3 " Private hospital" 4 "Private health center"
label values hftype hftype

//ORS or zinc
gen ch_diar_ors=0 if ch_diar==1
replace ch_diar_ors=1 if ch_diar==1 & (h13==1 | h13==2 | h13b==1 | h15e)
label var ch_diar_ors "Given oral rehydration salts or zinc for diarrhea"

**************************************************
*Approach 1-3 service coverage
g sc_c_123=.
replace sc_c_123=0 if ch_ari==1
replace sc_c_123=0 if ch_diar==1
replace sc_c_123=1 if ch_ari_care==1
replace sc_c_123=1 if ch_diar_care==1
label var sc_c_123 "Sick child service contact coverage"

tab hftype, gen(sc_c_123_)

*Approach 1 intervention coverage
g sc_i_1=.
replace sc_i_1=0 if ch_ari==1 | ch_diar==1
replace sc_i_1=1 if (ch_ari_care==1 & ch_ari_antibi==1) | (ch_diar_care==1 & ch_diar_ors==1)
*replace sc_i_1=1 if (ch_ari==1 & ch_ari_antibi==1) | (ch_diar==1 & ch_diar_ors==1)
label var sc_i_1 "Approach 1 sick child intervention coverage"

*****************************************
**** Background variables ****
* edu
recode v106 (0=1 None) (1=2 Primary) (2/3=3 "Secondary+") (8/9=.), gen(edu) 
	
* wealth v190
* need to modify the label to change from poorest, etc to the labels below
cap label define v190 1"Lowest" 2"Second" 3"Middle" 4"Fourth" 5"Highest", modify
cap label define V190 1"Lowest" 2"Second" 3"Middle" 4"Fourth" 5"Highest", modify

* place of residence v025	 
cap label define v025 1"Urban" 2"Rural", modify
cap label define V025 1"Urban" 2"Rural", modify

*region

if v000=="HT7" {
gen region2=v024+1
label define region2 1 "Aire metropolitaine" 2 "Rest-Ouest" 3 "Sud-Est" 4 "Nord" 5 "Nord-Est" 6 "Artibonite" 7 "Centre" 8 "Sud" 9 "Grand'Anse" 10 "Nord-Ouest" 11 "Nippes"
label values region2 region2
}

if v000=="MW7" {
gen region2=v024
label values region2 V024
}

if v000=="NP7" {
recode sdist (1/16=1 "Eastern development region") (17/35=2 "Central development region") (36/51=3 "Western development region") (52/66=4 "Mid-western development region") (67/75=5 "Far-western development region"), gen(region2)
}

if v000=="SN7"{
gen region2=0
replace region2 = 1 if v024==8 | v024==11 | v024==4
replace region2 = 2 if v024==1
replace region2 = 3 if v024==7
replace region2 = 4 if v024==6 | v024==3 | v024==9 | v024==12
* no Touba
replace region2 = 5 if v024==5 | v024==13
replace region2 = 6 if v024==10 | v024==2 | v024==14
* no Bignona or Kafountine
label define region2 1"North" 2"Dakar" 3"Thiès" 4"Central" 5"East" 6"South"
label values region2 region2
}

if v000=="TZ7" {
*Used geographic zones from page 13 of 2015-16 DHS report.
recode v024 (14 16 =1 "Western") (2/4=2 "Northern") (1 13 21=3 "Central") (10 11 22=4 "Southern Highlands") (8/9=5 "Southern") (12 15 23=6 "South West Highlands") (17/20 24/25=7 "Lake") (5/7=8 "Eastern") (51/55=9 "Zanzibar"), gen(region2)
}

**** saving file ****
keep v000-v190 strata hftype age period ch* edu region2 sc*
scalar country = substr(v000,1,2)
local country=country
save "$Codedfilepath//`country'/`c'coded.dta", replace
}
*/

**********************************************************************************
**********************************************************************************