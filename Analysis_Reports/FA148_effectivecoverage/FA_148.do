/*******************************************************************************************************************************

Purpose: 				This do file replicates the analysis in FA 148: Effective Coverage of Sick Child Care Services 
						and Relationship with Under-5 Mortality Across Seven Provinces, 2022 Nepal DHS and 2021 Nepal HFS 

Data Inputs: 			The data files used are NPFC8AFLSP.dta (facility SPA file), NPPV8AFLSP.dta (provider SPA file), NPFC8AFLSR.dta (inventory SPA file),
						NPKR82FL.dta (kids DHS file), and NPSC8AFLSP.dta (client SPA file).	
						
Data outputs:			This do file codes all variables from the facility, provider, inventory, and client SPA datasets and the kids recode file from the DHS. 
						The Excel files outputted by this file are 2021overallindexsc.xls and 2021Qoc_overall.xls
			
Author: 				Kiran Acharya and Rachael Church

Date last modified:		September 25, 2024 by Rachael Church

Notes:					This do file is organized into 3 main parts- 
						1. coding the variables from the different datasets and merging them into one main dataset
						2. analyzing the data
						3. outputting tables to Excel 
  				
*******************************************************************************/

clear all
cd "C:\Users\N116722\ICF\Analysis - FA148_child\Syntax" 

*Prepping facility file to be merged with provider file
*Nepal 2021 NHFS
clear all
use NPFC8AFLSP.dta, clear  
drop if q100==2	 // drop non response
					   
recode factype  (1/2= 1 "federal/provincial") (3=2 "local level hospitals") (5=3 "private hospital") /// 
                           (6=4 "PHCC") (7=5 "HPs") (8=6 "CHU") (9=7 "UHC") (10=8 "Stand alone HTC"), gen(fctype)

recode fctype (1 2=1 "Public hospitals") (3=2 "Private hospital") (4=3 "PHCCs") (5/7=4 "Basic Health Care Centres"), g(fctype1)
						   					   
ta munitype
recode munitype (1 2=1 "Metro/Submetro") (3=2 "Municipality") (4=3 "Rural municipality"), g(munitype1)
ta munitype1 [iw=facwt/1000000]					   

ta fctype				   
drop if fctype==8
drop if facil==580
drop if facil==589 // facilities not supposed to provide the child curative services were dropped. The details can be seen in the main report of 2021 NHFS (child health chapter)

gen fcwt=facwt/1000000
rename q1202_01 mal_diag_treat
save fc_rev.dta, replace

*Merging facility and provider files using facility type variable
use NPPV8AFLSP.dta, clear
drop if p101==2
merge m:1 facil using fc_rev.dta
keep if _merge==3

**Coding facility and provider variables
*Availabilty of trained child health providers
gen pchldcare=0
replace pchldcare=1 if  p300==1 | p301==1 | p302==1 //keep only providers that provide child health services 

*IMNCI training-any
gen imci_trn=0
replace imci_trn=1 if p304_02==1 | p304_02==2|p304_17==1 | p304_17==2&pchldcare==1

*IMNCI training in 24 months
gen imci_trn24=0 
replace imci_trn24=1 if (p304_02==1|p304_17==1)&pchldcare==1
ta imci_trn24, mi

gen  wt= provwt/1000000
*ta htc_trn [iw=wt]
ta imci_trn24  [iw=wt] 
save pv_rev.dta, replace 

collapse (mean) imci_trn imci_trn24, by(facil) //collapse provider-level data to facility level//

gen imci=(imci_trn!=0) 
gen imci_24=(imci_trn24!=0) 
save SC1_temp.dta, replace

use fc_rev.dta
merge 1:1 facil using SC1_temp.dta //merging results indicate that .. facilities had no providers interviewed that provide SC services//
replace imci=0 if imci==. //facilities without SC service providers interviewed were assumed to be zero//
replace imci_24=0 if imci_24==. //facilities without SC service providers interviewed were assumed to be zero//
drop _merge

*Staff Trained
ta imci  [iw=fcwt]
ta imci_24  [iw=fcwt]

*Outpatient curative care for sick children
gen chilcur_serv=0
replace chilcur_serv=1 if (q102_03==1) & (q1201a>=1 & q1201a<=31)
lab define chilcur_serv 1"yes" 0"no"
lab val chilcur_serv chilcur_serv
lab var chilcur_serv "Outpatient curative care for sick children"

// Child curative care services are services pertaining to diagnosis, treatment, and therapies provided to a child patient with the intent to improve symptoms and cure the patient's medical problem. These services involve treating major childhood illnesses such as pneumonia, diarrhea, malaria, measles, and malnutrition in a holistic way; caring for major problems in sick newborns such as birth asphyxia, bacterial infection, jaundice, hypothermia, and low birth weight; and providing breastfeeding counseling

save, replace

**Coding facility background characteristics
*Managing authority 
recode mga (1=1 public) (2/4=0 private), gen(mga2)
label var mga2 "managing authority"
ta mga2  [iw=fcwt]

*Ecological region
recode district	(101 102 103 301 302 303 402 403 601/605  701/703 =1 mountain)   ///
                (104/110 114 304/312 401 404/407 409/411 501/506 606/610 704/707 = 2 hill) ///
				(111/113 201/208 313 408 507/512 708 709  =3 terai), gen(ecoregion)		
ta ecoregion  [iw=fcwt]

*Recoded Provinces
ta province
	
*Location of the facilities
rename ftype location
ta location
egen strata = group(province factype)
ta strata
save SC_Nepal.dta, replace

********************************************************************************
**Merging facility dataset with main dataset 
*Use recoded datasets
clear all
set maxvar 10000
use NPFC8AFLSR.dta, clear

*merge raw and recoded datasets
rename inv_id facil
merge 1:1 facil using SC_Nepal.dta 
save SC_Nepal2021.dta, replace

drop fcwt
gen  fcwt= facwt/1000000

svyset [pw=fcwt], psu(facil) strata(strata) singleunit(centered)

*Calculating components of readiness for curative services for sick child care
*guidelines for IMNCI
gen imnciguide=0
replace imnciguide=1 if(q1211_1==1) | (q1211_6==1)
label define imnciguide 0 "No" 1"Yes"
label values imnciguide imnciguide
label var imnciguide "IMNCI guidelines available and observed"
ta imnciguide if chilcur_serv==1 [iw=fcwt]
      
*staff trained in IMNCI
recode v2000e (0=0 "No") (1/6=1 "Yes"), g (sc_24)
ta sc_24 if chilcur_serv==1 [iw=fcwt]

**Equipment
*child scale
gen chldweig=0
replace chldweig=1 if(q700a_02==1 & q700b_02==1)|(q1104a_01==1 & q1104b_01==1)|(q1210a_01==1 & q1210b_01==1)
label define chldweig 0 "No" 1 "Yes"
label values chldweig chldweig
label var chldweig "child weighing scale available and observed"
ta chldweig if chilcur_serv==1 [iw=fcwt]

*infant scale
gen infantweig=0
replace infantweig=1 if(q700a_03==1 & q700b_03==1)|(q1104a_02==1 & q1104b_02==1)|(q1210a_02==1 & q1210b_02==1)
label define infantweig 0 "No" 1 "Yes"
label values infantweig infantweig
label var infantweig "Infant weighing scale available and observed"
ta infantweig if chilcur_serv==1 [iw=fcwt]

*both infant and child scale available
gen inforchild_weigsc=0
replace inforchild_weigsc=1 if (chldweig==1 & infantweig==1)
label define inforchild_weigsc 0 "No" 1 "Yes"
label values inforchild_weigsc inforchild_weigsc
label var inforchild_weigsc "infant & child weighing scale available and observed"
ta inforchild_weigsc if chilcur_serv==1 [iw=fcwt]

*length/height measuring tape
gen htwt=0
replace htwt=1 if (q1104a_03==1&q1104b_03==1) | (q700a_04==1&q700b_04==1) 
ta htwt if chilcur_serv==1 [iw=fcwt]

*thermometer
gen thermo=0
replace thermo=1 if (q700a_06==1 & q700b_06==1)|(q1210a_03==1 & q1210b_03==1)
label define thermo 0 "No" 1 "Yes"
label values thermo thermo
label var thermo "Thermometer available and observed"
ta thermo if chilcur_serv==1 [iw=fcwt]

*stethoscope
gen stetho=0
replace stetho=1 if(q700a_07==1 & q700b_07==1)|(q1210a_04==1 & q1210b_04==1)
label define stetho 0 "No" 1 "Yes"
label values stetho stetho
label var stetho "Stethoscope available and observed"
ta stetho if chilcur_serv==1 [iw=fcwt]

*growth chart
gen growthcharts=0
replace growthcharts=1 if q1104a_05==1|q1104a_05==1
label define growthcharts 0 "No" 1 "Yes"
label values growthcharts growthcharts
label var growthcharts "Growth charts available and observed"
ta growthcharts if chilcur_serv==1 [iw=fcwt]

**Diagnostics
*hemoglobin
ta hemoglob if chilcur_serv==1 [iw=fcwt]

*parasite
rename stoolmicro stool_m
ta stool_m if chilcur_serv==1 [iw=fcwt]

*malaria
ta vt824 if chilcur_serv==1 [iw=fcwt]

**Medicines and commodities
*ORS
gen ORS=0
replace ORS=1 if (q906_09==1 | q1210a_09==1)
label define ORS 0 "No" 1 "Yes"
label values ORS ORS
label var ORS "ORS available and observed"
ta ORS if chilcur_serv==1 [iw=fcwt]

*amoxicillin
gen amox=0
replace amox=1 if q901_02==1
label define amox 0 "No" 1 "Yes"
label values amox amox
label var amox "amox available and observed"
ta amox if chilcur_serv==1 [iw=fcwt]

*gentamicin injectable
gen genta_inj=0
replace genta_inj=1 if q901_16==1
label define genta_inj 0 "No" 1 "Yes"
label values genta_inj genta_inj
label var genta_inj "gentamycin inj available and observed"
ta genta_inj if chilcur_serv==1 [iw=fcwt]

*paracetamol
gen paracetamol=0
replace paracetamol=1 if q908_3==1
label define paracetamol 0 "No" 1 "Yes"
label values paracetamol paracetamol
label var paracetamol "paracetamol available and observed"
ta paracetamol if chilcur_serv==1 [iw=fcwt]

*vitamin A
gen vitA=0
replace vitA=1 if q906_10==1
label define vitA 0 "No" 1 "Yes"
label values vitA vitA
label var vitA "Vitamin A available and observed"
ta vitA if chilcur_serv==1 [iw=fcwt]

*albendazole
gen albendazole=0
replace albendazole=1 if q902_1==1
label define albendazole 0 "No" 1 "Yes"
label values albendazole albendazole
label var albendazole "albendazole available and observed"
ta albendazole if chilcur_serv==1 [iw=fcwt]

*zinc sulphate
gen zinc=0
replace zinc=1 if(q906_11==1)
label define zinc 0 "No" 1 "Yes"
label values zinc zinc
label var zinc "zinc available and observed"
ta zinc if chilcur_serv==1 [iw=fcwt]


********************************************************************************
*Calculating Readiness Index
*Using four domains as per the who SARA
*Child curative care Service Readiness

*Staff and Training
gen domainsc1=(imnciguide+sc_24)*(100/2)
sum domainsc1 [iw=fcwt]

*Equipment and supplies
gen domainsc2=(inforchild_weigsc+htwt+thermo+stetho+growthcharts)*(100/5)
sum domainsc2 [iw=fcwt]

*Diagnostics
gen domainsc3=(hemoglob+stool_m+vt824)*(100/3)
sum domainsc3 [iw=fcwt]

*Medicines and commodities
gen domainsc4=(ORS+amox+paracetamol+vitA+genta_inj+albendazole+zinc)*(100/7)

*SC - Simple additive model
gen overallindexsc=(sc_24+imnciguide+inforchild_weigsc+htwt+thermo+stetho+growthcharts+hemoglob+stool_m+vt824+ORS+amox+paracetamol+vitA+genta_inj+albendazole+zinc)*(100/17)

*sum up to get the index 
sum overallindexsc if chilcur_serv==1 [aw=fcwt], detail
save Facility2022NHFS.dta, replace

clear all
use Facility2022NHFS.dta, clear

*dropping unneeded variables
keep facwt fcwt facil strata fctype fctype1 mga2 ecoregion location province chilcur_serv sc_24 imnciguide inforchild_weigsc htwt thermo stetho growthcharts hemoglob stool_m vt824 ORS amox paracetamol vitA genta_inj albendazole zinc domainsc1 domainsc2 domainsc3 domainsc4 overallindexsc

********************************************************************************
*Prepping data file for mortality rate calculation using KR (child file) from 2022 NDHS
*Analysis of association between mortality rates and effective coverage scores were conducted in Excel and are not included in this code file
clear all
use NPKR82FL.dta, clear
ta v024

*keeping only live children
drop if b5==0

gen wt=v005/1000000
svyset [pw=wt], psu (v001) strata (v022) singleunit(center)

*age if b19 is not available*
{
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

}

	cap label define yesno 0"no" 1"yes"
ta age

**Background characterics
*residence
ta v025
rename v025 residence
ta residence [iw=wt]

*ecological zone
ta secoreg
rename secoreg ecoregion
ta ecoregion [iw=wt]

*province
ta v024
rename v024 province
ta province [iw=wt]

*wealth quintile
ta v190
rename v190 wealth
ta wealth [iw=wt]

*ARI prevalence
gen ari=0
replace ari=1 if h31b==1 & (h31c==1 | h31c==3)
label define ari 0"No" 1 "Yes"
label variable ari ari
label variable ari "ARI Prevalance"

*ARI treatment
recode h32a (1=1) (.=0) (0=0), gen(h32ar)
recode h32b (1=1) (.=0) (0=0), gen(h32br)
recode h32c (1=1) (.=0) (0=0), gen(h32cr)
recode h32d (1=1) (.=0) (0=0), gen(h32dr)
recode h32e (1=1) (.=0) (0=0), gen(h32er)
recode h32f (1=1) (.=0) (0=0), gen(h32fr)
recode h32g (1=1) (.=0) (0=0), gen(h32gr)
recode h32h (1=1) (.=0) (0=0), gen(h32hr)
recode h32i (1=1) (.=0) (0=0), gen(h32ir)
recode h32j (1=1) (.=0) (0=0), gen(h32jr)
recode h32k (1=1) (.=0) (0=0), gen(h32kr)
recode h32l (1=1) (.=0) (0=0), gen(h32lr)
recode h32m (1=1) (.=0) (0=0), gen(h32mr)
recode h32n (1=1) (.=0) (0=0), gen(h32nr)
recode h32o (1=1) (.=0) (0=0), gen(h32or)
recode h32p (1=1) (.=0) (0=0), gen(h32pr)
recode h32q (1=1) (.=0) (0=0), gen(h32qr)
recode h32r (1=1) (.=0) (0=0), gen(h32rr)
recode h32s (1=1) (.=0) (0=0), gen(h32sr)
recode h32t (1=1) (.=0) (0=0), gen(h32tr)
recode h32u (1=1) (.=0) (0=0), gen(h32ur)
recode h32v (1=1) (.=0) (0=0), gen(h32vr)
recode h32w (1=1) (.=0) (0=0), gen(h32wr)
recode h32x (1=1) (.=0) (0=0), gen(h32xr)
recode h32y (1=1) (.=0) (0=0), gen(h32yr)
recode h32z (1=1) (.=0) (0=0), gen(h32zr)

tab ari [iw=wt]

gen ari_treatment_yes=.
replace ari_treatment_yes=0 if h32wr==1 | h32yr==1 | h32tr==1
replace ari_treatment_yes=1 if h32zr==1| h32xr==1 | h32hr==1| h32ir==1| h32jr==1| h32kr==1| h32lr==1| h32mr==1|h32nr==1| h32or==1| h32pr==1| h32qr==1| h32rr==1| h32sr==1| h32ur==1| h32vr==1 | h32ar==1| h32br==1 | h32cr==1| h32dr==1| h32fr==1| h32gr==1

svy:ta ari_treatment_yes if ari==1, per ci
svy:ta province ari_treatment_yes if ari==1, row per ci

*diarrhea prevalence
ta h11
recode h11 (0 8=0 "No") (2=1 "Yes") (.=.), g(diarr)
ta diarr [iw=wt]

svy: ta diarr, per ci
svy: ta province diarr , row per ci

*diarrhea treatment
recode h12a (1=1) (.=0) (0=0), gen(h12ar)
recode h12b (1=1) (.=0) (0=0), gen(h12br)
recode h12c (1=1) (.=0) (0=0), gen(h12cr)
recode h12d (1=1) (.=0) (0=0), gen(h12dr)
recode h12e (1=1) (.=0) (0=0), gen(h12er)
recode h12f (1=1) (.=0) (0=0), gen(h12fr)
recode h12g (1=1) (.=0) (0=0), gen(h12gr)
recode h12h (1=1) (.=0) (0=0), gen(h12hr)
recode h12i (1=1) (.=0) (0=0), gen(h12ir)
recode h12j (1=1) (.=0) (0=0), gen(h12jr)
recode h12k (1=1) (.=0) (0=0), gen(h12kr)
recode h12l (1=1) (.=0) (0=0), gen(h12lr)
recode h12m (1=1) (.=0) (0=0), gen(h12mr)
recode h12n (1=1) (.=0) (0=0), gen(h12nr)
recode h12o (1=1) (.=0) (0=0), gen(h12or)
recode h12p (1=1) (.=0) (0=0), gen(h12pr)
recode h12q (1=1) (.=0) (0=0), gen(h12qr)
recode h12r (1=1) (.=0) (0=0), gen(h12rr)
recode h12s (1=1) (.=0) (0=0), gen(h12sr)
recode h12t (1=1) (.=0) (0=0), gen(h12tr)
recode h12u (1=1) (.=0) (0=0), gen(h12ur)
recode h12v (1=1) (.=0) (0=0), gen(h12vr)
recode h12w (1=1) (.=0) (0=0), gen(h12wr)
recode h12x (1=1) (.=0) (0=0), gen(h12xr)
recode h12y (1=1) (.=0) (0=0), gen(h12yr)
recode h12z (1=1) (.=0) (0=0), gen(h12zr)

gen diarrhea_treatment_facility=0
replace diarrhea_treatment_facility=0 if  h12wr==1 | h12yr==1 
replace diarrhea_treatment_facility=1 if h12zr==1 | h12ar==1| h12xr==1 | h12kr==1 | h12sr==1| h12tr==1 | h12br==1 | h12cr==1 | h12dr==1 | h12er==1 | h12fr==1 | h12gr==1 | h12jr==1 | h12lr==1 | h12mr==1  | h12ur==1 | h12vr==1 | h12or==1 |h12p==1

tab diarrhea_treatment_facility if diarr==1 [iw=wt] 


********************************************************************************
*Coding process of care and variables using 2021 NFHS data
*opening the client file
clear all
use NPFC8AFLSP.dta, clear
numlabel, add 
drop if q100==2

*Opening and preparing "using" file
use NPPV8AFLSP.DTA, clear 
codebook facil provno, compact 

*Saving the prepared using file
save pv_temp.dta, replace

*Open the "master" file (the client file)
use NPSC8AFLSP.DTA, clear //Sick child client file

merge m:1 facil provno using pv_temp.dta

*keeping only matched cases and save merged file under a different name
keep if _merge==3
save scpv.dta, replace 

********************************************************************************
*Merging NHFS SC client and FC files
use NPFC8AFLSP.dta , clear
de, s
drop if q100==2 // drop facilities that rejected

*Identify and summarize the facility identification variable 
codebook facil, compact

*Save the prepared using file
save fc_temp.dta, replace

*open the master file (the SC file)
use scpv.dta , clear
de, s
drop _merge 

*Merge datasets 
merge m:1 facil using fc_temp.dta 

*drop unmatched cases and save merged file under a different name
drop if _merge!=3
save scpvfc.dta, replace

use scpvfc.dta, clear

********************************************************************************
*creating the stratification variables
*facility type
recode factype  (1/2= 1 "federal/provincial") (3=2 "local level hospitals") (5=3 "private hospital") /// 
                           (6=4 "PHCC") (7=5 "HPs") (8=6 "CHU") (9=7 "UHC") (10=8 "Stand alone HTC"), gen(fctype)
						   
drop if fctype==8

*New Facility type
recode fctype (1 2=1 "Public hospitals") (3=2 "Private hospital") (4=3 "PHCCs") (5/7=4 "Basic Health Care Centres"), g(fctype1)
			
*managing authority 
recode mga (1=1 public) (2/4=0 private), gen(mga2)
label var mga2 "managing authority"	
egen strata = group(province factype)

*ecological region
recode district	(101 102 103 301 302 303 402 403 601/605  701/703 =1 mountain)   ///
                (104/110 114 304/312 401 404/407 409/411 501/506 606/610 704/707 = 2 hill) ///
				(111/113 201/208 313 408 507/512 708 709  =3 terai), gen(ecoregion)

save 2021client.dta, replace
clear all

use 2021client.dta, clear
drop if xc100==2 // drop refused 43 cases not agreed for interview

*weighted variable for client
gen wt=clientwt/1000000
svyset [pw=wt], psu(facil) strata(strata) singleunit(centered)

*Physical Examination
gen oc_physical_exam=0
replace oc_physical_exam=1 if (regexm(oc108,"B") | regexm(oc108,"C")|regexm(oc108,"E")| regexm(oc108,"F")| regexm(oc108,"G") | regexm(oc108,"J")| regexm(oc108,"N"))
label var oc_physical_exam "Physical examination"
svy : ta oc_physical_exam, per ci

*took temperature with thermometer
gen oc_temp_thermoA=0
replace oc_temp_thermoA=1 if regexm(oc108,"A") |q1209_3==1
label var oc_temp_thermoA"Took child's temperature by thermometer"
svy : ta oc_temp_thermoA, per ci
 
*felt for body hotness
gen oc_physical_examB=0
replace oc_physical_examB=1 if regexm(oc108,"B") 
label var oc_physical_examB "Felt fever or body hotness"
svy : ta oc_physical_examB, per ci

*took temperature with thermometer or felt for body hotness
gen child_temp=0
replace child_temp=1 if oc_temp_thermoA==1|oc_physical_examB==1
label var child_temp "Took temperature or felt fever/body hotness"
svy : ta child_temp, per ci

*child has any respiratory problem
gen resp_prob=0
replace resp_prob=1 if (regexm(oc202,"A")| regexm(oc202,"B") | regexm(oc202,"C") | regexm(oc202,"D")| regexm(oc202,"E")| regexm(oc202,"F")| regexm(oc202,"G"))
label define resp_prob 0 "No" 1 "Yes"
label values resp_prob resp_prob
label var resp_prob "Respiration problem"

*counted respiration
gen oc_physical_examC=0
replace oc_physical_examC=1 if regexm(oc108,"C")
replace oc_physical_examC=1 if resp_prob==1
label var oc_physical_examC "Counted respiration for 60 seconds"
svy : ta oc_physical_examC, per ci

*auscultated child
gen oc_physical_examD=0
replace oc_physical_examD=1 if regexm(oc108,"D")
label var oc_physical_examD "Auscultated child (listen to chest with stethoscope) or count pulse"
svy : ta oc_physical_examD, per ci

*has diarrhea or dehydration
gen diarrhea_dehyany=0
replace diarrhea_dehyany=1 if (regexm(oc203,"A")| regexm(oc203,"B")|regexm(oc203,"C")|regexm(oc203,"D")|regexm (oc203,"X")) | ((oc201==1)|(oc201==2)|(oc201==3))
label var diarrhea_dehyany "Any diarrhea"
svy:ta diarrhea_dehyany, count

*checked skin tugor for dehydration
gen oc_physical_examE=0
replace oc_physical_examE=1 if regexm(oc108,"E")
replace oc_physical_examE=1 if diarrhea_dehyany==1
label var oc_physical_examE "Checked skin turgor for dehydration"
svy : ta oc_physical_examE, per ci

*checked palms for pallor
gen oc_physical_examF=0
replace oc_physical_examF=1 if regexm(oc108,"F")
label var oc_physical_examF "Checked palms for pallor"
svy : ta oc_physical_examF, per ci

*checked for conjunctiva
gen oc_physical_examG=0
replace oc_physical_examG=1 if regexm(oc108,"G")
label var oc_physical_examG "Checked inlooking conjunctiva"
svy : ta oc_physical_examG, per ci

*checked for pallor or conjunctiva
gen palm_conjunc=0
replace palm_conjunc=1 if oc_physical_examF==1|oc_physical_examG==1
label var palm_conjunc "Checked palms or conjunctiva"
svy : ta palm_conjunc, per ci

*looked into mouth
gen oc_physical_examH=0
replace oc_physical_examH=1 if regexm(oc108,"H")
label var oc_physical_examH "Looked into child's mouth"
svy : ta oc_physical_examH, per ci

*checked neck for stiffness
gen oc_physical_examI=0
replace oc_physical_examI=1 if regexm(oc108,"I")
label var oc_physical_examI "Checked for neck stiffness"
svy : ta oc_physical_examI, per ci

*looked in ear
gen oc_physical_examJ=0
replace oc_physical_examJ=1 if regexm(oc108,"J")
label var oc_physical_examJ "Looked in child's ear"
svy : ta oc_physical_examJ, per ci

*felt behind ear
gen oc_physical_examK=0
replace oc_physical_examK=1 if regexm(oc108,"K")
label var oc_physical_examK "Felt behind child's earr"
svy : ta oc_physical_examK, per ci

*looked or felt behind ear
gen felt_ear_behind=0
replace felt_ear_behind=1 if oc_physical_examJ==1|oc_physical_examK==1
label var felt_ear_behind "Looked in child's ear or Felt behind child's earr"
svy : ta felt_ear_behind, per ci

*undressed to examine
gen oc_physical_examL=0
replace oc_physical_examL=1 if regexm(oc108,"L")
label var oc_physical_examL "Undressed child to examine (up to shoulders/down to ankles)"
svy : ta oc_physical_examL, per ci

*checked for edema
gen oc_physical_examM=0
replace oc_physical_examM=1 if regexm(oc108,"M")
label var oc_physical_examM "Pressed both feet to check for edema"
svy : ta oc_physical_examM, per ci

*weighed child
gen oc_physical_examN=0
replace oc_physical_examN=1 if regexm(oc108,"N")|q1209_1==1
label var oc_physical_examN "Weighed the child"
svy : ta oc_physical_examN, per ci

*plotted weight on growth chart
gen oc_physical_examO=0
replace oc_physical_examO=1 if regexm(oc108,"O")|q1209_2==1
label var oc_physical_examO "Plotted weight on growth chart (child health card-HMIS 2.1, growth monitoring chart)"
svy : ta oc_physical_examO, per ci

*checked for enlarged lymph nodes
gen oc_physical_examP=0
replace oc_physical_examP=1 if regexm(oc108,"P")
label var oc_physical_examP "Checked for enlarged lymph nodes in 2 or more of the following sites: neck, axillae, groin"
svy : ta oc_physical_examP, per ci

*provider recorded on child health card
gen record_chldcard=0
replace record_chldcard=1 if regexm(oc108,"O")| regexm(oc109,"I")
label define record_chldcard 0 "No" 1 "Yes"
label values record_chldcard record_chldcard
label var record_chldcard "Provider recorded on child health card"
svy : ta record_chldcard, per ci

*information provided to caregiver
gen inform_careg=0
replace inform_careg=1 if (regexm(oc110,"A") | regexm(oc110,"B")| regexm(oc110,"C")| regexm(oc110,"D")| regexm(oc110,"E"))
label var inform_careg "Any Information Provided to caregiver"
svy :ta inform_careg, per ci

*provided information about feeding
gen c_feedin=0
replace c_feedin=1 if regexm(oc110,"A") 
label var c_feedin "Provided Information about feeding"
svy :ta c_feedin, per ci 

*counseled on extra fluids
gen c_extraf=0
replace c_extraf=1 if regexm(oc110,"B") 
label var c_extraf "counseled on extra fluids"
svy :ta c_extraf, per ci

*counseled on continued feeding
gen c_contfeed=0
replace c_contfeed=1 if regexm(oc110,"C")
label var c_contfeed "Counseled on continue feeding"
svy :ta c_contfeed, per ci  

*provider told about child illness
gen told_childillness=0
replace told_childillness=1 if (regexm(oc110,"D"))
label var told_childillness "Provider told about child illness"
svy :ta told_childillness, per ci

*described signs/symptoms for which to bring child back
gen c_signsymp=0
replace c_signsymp=1 if regexm(oc110,"E")
label var c_signsymp "Described signs/symptoms for which to bring child back"
svy :ta c_signsymp, per ci

*counseled caretaker on all items
gen inform_caregT=0
replace inform_caregT=c_feedin+ c_extraf + c_contfeed + told_childillness + c_signsymp
label var inform_caregT "All items on counseling of caretaker"
svy :ta inform_caregT, per ci

*counseled on at least 2 items
gen c_counselany2=0
replace c_counselany2=1 if inform_caregT >=2
label var c_counselany2 "At least2_any information provided to caregiver"
svy :ta c_counselany2, per ci

*used visual aid to educate caretaker
gen visualaid=0
replace visualaid=1 if (regexm(oc110,"F"))
label define visualaid 0 "No" 1 "Yes"
label values visualaid visualaid
label var visualaid "Provider used visual aid to educate caretaker"
svy :ta visualaid, per ci

*provider discussed followup visit
gen discuss_followup=0
replace discuss_followup=1 if regexm(oc111,"E")
label define discuss_followup 0 "No" 1 "Yes"
label values discuss_followup discuss_followup
label var discuss_followup "Provider discussed followup visit"
svy :ta discuss_followup, per ci

*outpatient curative care for sick children
gen chilcur_serv=0
replace chilcur_serv=1 if (q102_03==1) & (q1201a>=1 & q1201a<=31)
lab define chilcur_serv 1"yes" 0"no"
lab val chilcur_serv chilcur_serv
lab var chilcur_serv "Outpatient curative care for sick children"

*correct treatment for pnemonia
gen pneumonia=0
replace pneumonia=1 if regexm(oc202,"A")|regexm(oc202,"F")
label var pneumonia "Diagnosis of pneumonia"
ta pneumonia if chilcur_serv==1 [iw=wt]

gen pneumotreat=0
replace pneumotreat=1 if regexm(oc210,"F") | regexm(oc210,"G")
replace  pneumotreat=. if  pneumonia==0
label define pneumotreat 0 "No" 1 "Yes"
label values pneumotreat pneumotreat
label var pneumotreat "Correct Treatment of pneumonia"
ta pneumotreat  [iw=wt]

*any diarrhea without dehydration
gen diarrhea_dehy=0
replace diarrhea_dehy=1 if (regexm(oc203,"A")| regexm(oc203,"B")|regexm(oc203,"C")|regexm(oc203,"D")|regexm (oc203,"X")) & ((oc201==1)|(oc201==2)|(oc201==3))
label var diarrhea_dehy "Diagnosis diarrhea"
svy:ta diarrhea_dehy, count

*any diarrhea without dehydration
gen diarrhea_nodehy=0
replace diarrhea_nodehy=1 if (regexm(oc203,"A")| regexm(oc203,"B")|regexm(oc203,"C")|regexm(oc203,"D")|regexm (oc203,"X")) & ((oc201==8))
label var diarrhea_nodehy "Diagnosis diarrhea with no dehydration"
svy:ta diarrhea_dehy, per ci
svy:ta diarrhea_nodehy, per ci

*any diarrhea with or without dehydration
gen diarr_dehyT=0 if diarrhea_dehy==0 | diarrhea_nodehy==0
replace diarr_dehyT=1 if diarrhea_dehy==1 | diarrhea_nodehy==1
svy: ta diarr_dehyT, count
ta diarr_dehyT  [iw=wt]

*correct treatment of diarrhea
gen ors=0
replace ors=1 if (regexm(oc213,"A")| regexm(oc213,"B")|regexm(oc213,"C")|regexm(oc213,"D"))& (regexm(oc210,"K"))
svy: ta ors diarrhea_dehy, col per ci
svy: ta ors diarrhea_nodehy, col per ci
svy:ta mga2 ors, col per

gen ors_only=0
replace ors_only=1 if (regexm(oc213,"A")| regexm(oc213,"B")|regexm(oc213,"C")|regexm(oc213,"D"))

gen zinc_only=0
replace zinc_only=1 if (regexm(oc210,"K"))
ta ors_only
ta zinc_only

gen diatreat=0
replace diatreat=1 if ors==1
replace diatreat=. if diarr_dehyT==0
svy:ta diatreat, per ci

*any client history
gen oc_clienthistory=0
replace oc_clienthistory=1 if (regexm(oc105,"A") | regexm(oc105,"B")| regexm(oc105,"C"))
label var oc_clienthistory "Any client history"
svy: ta oc_clienthistory, per ci

*asked fever history
gen ochistoryA=0
replace ochistoryA=1 if regexm(oc105,"A") 
label var ochistoryA "Fever"
svy: ta ochistoryA, per ci

*asked cough or difficult breathing history
gen ochistoryB=0
replace ochistoryB=1 if regexm(oc105,"B")
label var ochistoryB "Cough or difficult breathing"
svy: ta ochistoryB, per ci

*asked diarrhea history
gen ochistoryC=0
replace ochistoryC=1 if regexm(oc105,"C") 
label var ochistoryC "Diarrhea"
svy: ta ochistoryC, per ci

*asked ear pain or discharge history
gen ochistoryD=0
replace ochistoryD=1 if regexm(oc105,"D")
label var ochistoryD "Ear pain or discharge"
svy: ta ochistoryD, per ci

*asked all client history
gen ochistoryT=0
replace ochistoryT=ochistoryA + ochistoryB + ochistoryC + ochistoryD
label var ochistoryT "All client history"
svy: ta ochistoryT, per ci

*asked at least 3 client history
gen ochistany3=0
replace ochistany3=1 if ochistoryT>=3
label var ochistany3 "At least three client history"
svy : ta ochistany3, per ci

*general danger signs asked by provider
gen oc_gds=0
replace oc_gds=1 if (regexm(oc106,"A") | regexm(oc106,"B")| regexm(oc106,"C"))
label var oc_gds "General Danger signs"
svy : ta oc_gds, per ci

*asked if unable to drink or breastfeed
gen ocgdsA=0
replace ocgdsA=1 if regexm(oc106,"A") 
label var ocgdsA "Unable to drink or breastfed"
svy : ta ocgdsA, per ci

*asked if vomits everything
gen ocgdsB=0
replace ocgdsB=1 if regexm(oc106,"B") 
label var ocgdsB "child vomit everything"
svy : ta ocgdsB, per ci

*asked if had convulsions
gen ocgdsC=0
replace ocgdsC=1 if regexm(oc106,"C")
label var ocgdsC "Child has had convulsions with this illness"
svy : ta ocgdsC, per ci

*asked all danger signs
gen ocgdsT=0
replace ocgdsT=ocgdsA + ocgdsB + ocgdsC
label var ocgdsT "All danger signs"
svy : ta ocgdsT, per ci

*asked at least 2 danger signs
gen ocgdsany2=0
replace ocgdsany2=1 if ocgdsT >=2
label var ocgdsany2 "At least2_Any danger signs"
svy : ta ocgdsany2, per ci

*information asked to caretaker*
*asked about normal feeding
gen ocinffed=0
replace ocinffed=1 if (regexm(oc109,"B") |regexm(oc109,"C"))
label var ocinffed "Asked about normal feeding or breastfeeding when not illness"
svy: ta ocinffed, per ci

*asked about feeding during illness
gen ocinffed_ill=0
replace ocinffed_ill=1 if regexm(oc109,"D")
label var ocinffed_ill "Asked about normal feeding or breastfeeding during illness"
svy: ta ocinffed_ill, per ci

*mentioned child weight or growth to the caretaker
gen infwt=0
replace infwt=1 if regexm(oc109,"E") 
label var infwt "Mentioned the child's weight or growth to the caretaker"
svy: ta infwt, per ci

*asked if child received Vitamin A/deworming within past 6 months or asked vaccination status
gen child_vacc=0
replace child_vacc=1 if (regexm(oc109,"G")|regexm(oc109,"J")|regexm(oc109,"K"))
label var child_vacc "Asked Vitamin A/deworming within past 6 months or asked vaccination status"
svy: ta child_vacc, per ci

*coding quality of care variables*
*quality of care variable 1: asked history
gen Qoc1=(ochistoryA+ochistoryB+ochistoryC)*(100/3)
sum Qoc1 [iw=wt]

*quality of care variable 2: asked danger signs
gen Qoc2=(ocgdsA+ocgdsB+ocgdsC)*(100/3)
sum Qoc2 [iw=wt]

*quality of care variable 3: asked information of a caretaker
gen Qoc3=(ocinffed+ocinffed_ill+infwt+child_vacc)*(100/4)
sum Qoc3 [iw=wt]

*quality of care variable 4: physical exam
gen Qoc4=(child_temp+oc_physical_examC+oc_physical_examD +oc_physical_examE+palm_conjunc+oc_physical_examH+felt_ear_behind+oc_physical_examN+record_chldcard)*(100/9)
sum Qoc4 [iw=wt]

*quality of care variable 5: Counselling provided and follow up
gen Qoc5=(c_feedin+c_extraf+c_contfeed+told_childillness+c_signsymp+discuss_followup)*(100/6)
sum Qoc5 [iw=wt]

*overall quality of care
gen Qoc_overall=(ochistoryA+ochistoryB+ochistoryC+ocgdsA+ocgdsB+ocgdsC+ocinffed+ocinffed_ill+infwt+child_vacc+child_temp+oc_physical_examC+oc_physical_examD +oc_physical_examE+palm_conjunc+oc_physical_examH +felt_ear_behind+oc_physical_examN+record_chldcard+c_feedin+c_extraf+c_contfeed+told_childillness+c_signsymp+discuss_followup)*(100/25)
sum Qoc_overall [iw=wt]

*keeping only matched cases and save merged
keep if _merge==3
keep wt facil strata fctype fctype1 mga2 ecoregion province chilcur_serv ochistoryA ochistoryB ochistoryC ocgdsA ocgdsB ocgdsC ochistoryD ocinffed ocinffed_ill infwt child_vacc child_temp oc_physical_examC oc_physical_examD oc_physical_examE palm_conjunc oc_physical_examH felt_ear_behind oc_physical_examN record_chldcard c_feedin c_extraf c_contfeed told_childillness visualaid c_signsymp discuss_followup pneumotreat diatreat  Qoc1 Qoc2 Qoc3 Qoc4 Qoc5 Qoc_overall
save main.dta, replace 

********************************************************************************
*Calculating U5MR & ARI care with birth recode DHS file*

clear all
use NPBR82FL.dta, clear

gen wt=v005/1000000
svyset [pw=wt], psu (v001) strata (v022) singleunit(center)
numlabel, add

*Computing age at death variable  
ssc install syncmrates

*5 years preceding the survey
syncmrates v008 b3 b7 [iweight=wt], t0(61) t1(1)
*by province 5 years preceding the survey
syncmrates v008 b3 b7 if v024==1 [iweight=wt], t0(61) t1(1)
syncmrates v008 b3 b7 if v024==2 [iweight=wt], t0(61) t1(1)
syncmrates v008 b3 b7 if v024==3 [iweight=wt], t0(61) t1(1)
syncmrates v008 b3 b7 if v024==4 [iweight=wt], t0(61) t1(1)
syncmrates v008 b3 b7 if v024==5 [iweight=wt], t0(61) t1(1)
syncmrates v008 b3 b7 if v024==6 [iweight=wt], t0(61) t1(1)
syncmrates v008 b3 b7 if v024==7 [iweight=wt], t0(61) t1(1)


*10 years preceding the survey
syncmrates v008 b3 b7 [iweight=wt], t0(121) t1(1)
*by province 10 years preceding the survey
syncmrates v008 b3 b7 if v024==1 [iweight=wt], t0(121) t1(1)
syncmrates v008 b3 b7 if v024==2 [iweight=wt], t0(121) t1(1)
syncmrates v008 b3 b7 if v024==3 [iweight=wt], t0(121) t1(1)
syncmrates v008 b3 b7 if v024==4 [iweight=wt], t0(121) t1(1)
syncmrates v008 b3 b7 if v024==5 [iweight=wt], t0(121) t1(1)
syncmrates v008 b3 b7 if v024==6 [iweight=wt], t0(121) t1(1)
syncmrates v008 b3 b7 if v024==7 [iweight=wt], t0(121) t1(1)

*syncmrates v008 b3 b7 [iw=wt], t0(121) t1(1)

*age at death using variables b7 and b5
gen     u5=.
replace u5 = 1  if  b7 < 60 & b5==0
replace u5 = 0  if (b7 > 59) | b5==1
lab def u5 1 "Died before age 5" 0 "Survived"
lab val u5 u5
lab var u5 "U5 Mortality Status"

ta u5 [iw=wt]


********************************************************************************
*Analyzing coded dataset

clear all
use Facility2022NHFS.dta, clear
*recoding provinces*
recode province (1=1 "koshi") (2=2 "madhesh province") (3=3 "bagmati province") (4=4 "gandaki province") (5=5 "lumbini province") (6=6 "karnali province") (7=7 "sudhurpashchim province"), g(v024)
ta v024
ta province

*prepping dataset for analysis
drop fcwt
gen fcwt= facwt/1000000
svyset [pw=fcwt], psu(facil) strata(strata) singleunit(centered)

*sum up to get the index 
sum overallindexsc if chilcur_serv==1 [aw=fcwt], detail
ta v024

********************************************************************************
*Creating tables

*Readiness Tables*
*availability of equipment and supplies
tabout imnciguide sc_24 inforchild_weigsc htwt thermo stetho growthcharts hemoglob stool_m vt824 ORS amox genta_inj paracetamol vitA albendazole zinc if chilcur_serv==1  using readiness.xls [iweight=fcwt], replace oneway c(cell ci) clab(%) svy nwt(fcwt)sebnone per pop

*facility type
tabout fctype1 mga2 ecoregion location province if chilcur_serv==1  using readiness.xls [iweight=fcwt], append oneway c(cell ci) clab(%) svy nwt(fcwt)sebnone per pop

*Output tables
tabout domainsc1 if chilcur_serv==1  using readiness.xls, svy sum c(mean domainsc1 se domainsc1 ci domainsc1) append f(2)
tabout domainsc2 if chilcur_serv==1  using readiness.xls, svy sum c(mean domainsc2 se domainsc2 ci domainsc2) append f(2)
tabout domainsc3 if chilcur_serv==1  using readiness.xls, svy sum c(mean domainsc3 se domainsc3 ci domainsc3) append f(2)
tabout domainsc4 if chilcur_serv==1  using readiness.xls, svy sum c(mean domainsc4 se domainsc4 ci domainsc4) append f(2)
tabout overallindexsc if chilcur_serv==1 using  readiness.xls, svy sum c(mean overallindexsc se overallindexsc ci overallindexsc) replace f(2)
tabout province if chilcur_serv==1  using readiness.xls, svy sum c(mean overallindexsc ci overallindexsc) replace f(1)
tabout fctype1 mga2 location ecoregion province if chilcur_serv==1  using readiness.xls, svy sum c(mean overallindexsc ci overallindexsc) append f(1)

summarize fctype mga2 ecoregion location v024 sc_24 imnciguide inforchild_weigsc htwt thermo stetho growthcharts hemoglob stool_m vt824 ORS amox paracetamol vitA genta_inj albendazole zinc domainsc1 domainsc2 domainsc3 domainsc4 overallindexsc

tabout v024 if chilcur_serv==1 using 2021overallindexsc.xls, svy sum c(mean overallindexsc ci overallindexsc) replace f(1)

*Process and Quality of Care Tables*
clear all
use main.dta, clear

*constructing client table*
*table of symptoms asked by provider
tabout ochistoryA ochistoryB ochistoryC ochistoryD using client.xls [iweight=wt], replace oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*table of danger signs asked by providers
tabout ocgdsA ocgdsB ocgdsC using client.xls [iweight=wt], append oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*table of information provided
tabout ocinffed ocinffed_ill infwt child_vacc  using client.xls [iweight=wt], append oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*table of physical exam
tabout child_temp oc_physical_examC oc_physical_examD oc_physical_examE palm_conjunc oc_physical_examH felt_ear_behind oc_physical_examN record_chldcard using client.xls [iweight=wt], append oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*table of counseling provided
tabout c_feedin c_extraf c_contfeed told_childillness c_signsymp visualaid discuss_followup using client.xls [iweight=wt], append oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*table of client background
tabout fctype1 mga2 ecoregion province using client.xls [iweight=wt], append oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*constructing QoC tables*
tabout Qoc1 using qoc.xls, svy sum c(mean Qoc1 se Qoc1 ci Qoc1) replace f(2)
tabout Qoc2 using qoc.xls, svy sum c(mean Qoc2 se Qoc2 ci Qoc2) append f(2)
tabout Qoc3 using qoc.xls, svy sum c(mean Qoc3 se Qoc3 ci Qoc3) append f(2)
tabout Qoc4 using qoc.xls, svy sum c(mean Qoc4 se Qoc4 ci Qoc4) append f(2)
tabout Qoc5 using qoc.xls, svy sum c(mean Qoc5 se Qoc5 ci Qoc5) append f(2)
tabout Qoc_overall using qoc.xls, svy sum c(mean Qoc_overall se Qoc_overall ci Qoc_overall) append f(2)
tabout fctype1 mga2  ecoregion province using qoc.xls, svy sum c(mean Qoc_overall ci Qoc_overall) append f(2)
tabout province using qoc.xls, svy sum c(mean Qoc_overall ci Qoc_overall) append f(2)

*constructing process of care tables*
tabout ochistoryA ochistoryB ochistoryC ocgdsA ocgdsB ocgdsC ocinffed ocinffed_ill infwt child_vacc child_temp oc_physical_examC oc_physical_examD oc_physical_examE palm_conjunc oc_physical_examH felt_ear_behind oc_physical_examN record_chldcard c_feedin c_extraf c_contfeed told_childillness c_signsymp discuss_followup pneumotreat diatreat using processofcare.xls [iweight=wt], replace oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

*coding Process of Care index*
summarize wt facil strata fctype mga2 ecoregion  province chilcur_serv ochistoryA ochistoryB ochistoryC ocgdsA ocgdsB ocgdsC ocinffed ocinffed_ill infwt child_vacc child_temp oc_physical_examC oc_physical_examD oc_physical_examE palm_conjunc oc_physical_examH felt_ear_behind oc_physical_examN record_chldcard c_feedin c_extraf c_contfeed told_childillness c_signsymp discuss_followup pneumotreat diatreat  Qoc1 Qoc2 Qoc3 Qoc4 Qoc5 Qoc_overall

***found only "." not missing as a number***
tabout province  using 2021Qoc_overall.xls, svy sum c(mean Qoc_overall ci Qoc_overall) replace f(1)