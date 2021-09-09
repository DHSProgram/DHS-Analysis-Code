/*****************************************************************************************************
Program: 			Readiness.do
Purpose: 			Code readiness variables at the facility level to create composite readiness measure 
						for the MR31 report on Effective Coverage. All key structural items were coded, 
						but inclusion in readiness composite measures was determined as described in the report.
Author:				Shireen Assaf and Sara Riese					
Date last modified: May 27, 2021
*****************************************************************************************************/

* SPA surveys used in the analysis

* SPA Files - provider
global spapvdata "HTPV7AFLSP MWPV6KFLSP NPPV71FLSP SNPV81FLSP TZPV71FLSP"

* SPA Files - facility inventory
global spafcdata "HTFC7AFLSP MWFC6KFLSP NPFC71FLSP SNFC81FLSP TZFC71FLSP"

****************************************************************************************************

*start with provider file first to get the training variables

foreach c in $spapvdata {

use "`c'.dta", clear

gen anc_train = 0 
*replace anc_train=1 if p501==1
replace anc_train=1 if p502_1==1 | p502_2==1 | p502_3==1 | p502_4==1 | p502_5==1
/*Below code will match the FRs. Haiti had slightly different training items from the other countries. Our code focuses on core ANC training, rather than including other types of pregnancy-related training
	if "`c'"=="HTPV7AFLSP" {
	replace anc_train=1 if (p500==1 | p500==2 | p500==3) & (p502_1==1 | p502_2==1 | p502_3==1 | p502_4==1 | p502_5==1 | p505_1==1 | p505_5==1 | 	p206_5==1)
	}
	if "`c'"!="HTPV7AFLSP" {
replace anc_train=1 if (p500==1 | p500==2 | p500==3) & (p502_1==1 | p502_2==1 | p502_3==1 | p502_4==1 | p502_5==1 | p505_1==1 | p505_5==1 | p206_5==1 | p206_6==1)
	}
*/	
label var anc_train "received ANC training"
label values anc_train anc_train

gen imci_train =0
replace imci_train=1 if p304_02==1
label var imci_train "received IMCI training"

collapse (mean) sc1=imci_train sa1=anc_train, by(facil)

recode sc1 0.0001/1=1
label var sc1 "at least one staff trained in IMCI in last 2 years"

recode sa1 0.0001/1=1
label var sa1 "at least one staff trained in ANC in last 2 years"

sort facil
save "`c'traintemp.dta", replace

}

*now we can open facility file
tokenize HTPV7AFLSPtraintemp MWPV6KFLSPtraintemp NPPV71FLSPtraintemp SNPV81FLSPtraintemp TZPV71FLSPtraintemp
foreach c in $spafcdata {
use "`c'.dta", clear

*drop facilities that refused to interview
drop if q100==2

sort facil
merge 1:1 facil using `1'.dta
* recode where no providers are interviewed (missing) to zero
recode sa1 .=0 
recode sc1 .=0 

	if "`c'"=="SNFC81FLSP" {
	*drop health huts
	drop if factype==4
	}
	
erase "`1'.dta"
mac shift

scalar country = "`c'"
local country = substr(country,1,2)
save "`c'ready1.dta",replace
}
*/

foreach c in $spafcdata {
scalar country = "`c'"
local country = substr(country,1,2)
use "`c'ready1.dta", clear

scalar sfn = "`c'"
gen sur = substr(sfn,1,6)

*******************************************************************************
** Creating structure variables
*******************************************************************************
** General structure outcome variables
** coding variables as binary and having 0 for not having item
** name is always sg# for structure general 

** Electricity
gen sg1=0
replace sg1=1 if (q340==1 & q341==1) 
replace sg1=1 if regexm(q343, "A") & q345==1 & q346==1
replace sg1=1 if regexm(q343, "B") & q345==1 & q346==1
replace sg1=1 if regexm(q343, "C")
*Nepal has another power source from invertor
	if "`c'"=="NPFC71FLSP"{
	replace sg1=1 if regexm(q343, "D") & q346b==1
	}

** Improved water
gen sg2=0
replace sg2=1 if q330==1 | q330==2 | q330==10
replace sg2=1 if (q330==3 | q330==4 | q330==5 | q330==7 | q330==9) & q331<3

** Privacy
gen sg3=0
replace sg3=1 if q711<3

** Toilet
gen sg4=0
replace sg4=1 if q620<22 | q620==31

** Communication equipment
gen sg5=0
replace sg5=1 if (q311==1 & q312==1) | (q314==1 & q315==1) | (q317==1 & q318==1)
cap replace sg5=1 if q315a==1

*For sg6 and sg7 checked CSPro code. In sg7 transport does not need to be observed. 

** Computer / Internet/email
gen sg6=0
replace sg6=1 if  (q322==1 & q323==1)

** Emergency transport
gen sg7=0
replace sg7=1 if (q450==1 & q453==1) | q452==1

** Disposal of sharps
* Safe final disposal of sharps includes incineration, open burning in protected
* area, dump without burning in protected area, or remove offsite with protected
* storage.
gen sg8=0
replace sg8=1 if q600<4 & q608==1 & q609==1
* If incinerator method used, incinerator functioning and fuel available.
replace sg8=1 if q600==5 | q600==7 | q600==9 | q600==10 | q600==11
*Nepal has additional option
	if "`c'"=="NPFC71FLSP"{
	replace sg8=1 if q600==13
	}

** Disposal of medical waste
gen sg9=0
	if "`c'"=="HTFC7AFLSP" | "`c'"=="MWFC6KFLSP" | "`c'"=="SNFC81FLSP" | "`c'"=="TZFC71FLSP" {
	replace sg9=1 if (q601==2 | q601==3) & q608==1 & q609==1
	replace sg9=1 if q601==5 | q601==7 | q601==9 | q601==10 | q601==11
	replace sg9=1 if q601==1 & sg8==1
	}

*Nepal has slighty different definition
	if "`c'"=="NPFC71FLSP"{
	replace sg9=1 if (((q601==2 | q601==3) | (q601==1 & q600<4)) & q607==1 & q608==1 & q609==1)
	replace sg9=1 if q601==5 | q601==7 | q601==9 | q601==10 | q601==11 | q601==13
	replace sg9=1 if q601==1 & (q600==5 | q600==7 | q600==9 | q600==10 | q600==11 | q600==13)
	}

*******************************************************************************
* Facility management vars
*******************************************************************************
** Monthly admin meetings
gen sg16=0
*replace sg16=1 if q410==1
*to match FR use code below
replace sg16=1 if q410==1 & (q411==1 | q411==2 | q411==3) & q412==1 & q413==1

** Quality assurance
gen sg17=0
*replace sg17=1 if q440==1
*to match FR use code below
replace sg17=1 if q440==1 & q441==1 & q442==1

**System to collect client opinion
gen sg18=0
*replace sg18=1 if q430==1
*to match FR use code below
replace sg18=1 if q430==1 & (regexm(q431, "A") | regexm(q431, "B") | regexm(q431, "C") | regexm(q431, "D") | regexm(q431, "E") | regexm(q431, "F") | regexm(q431, "G") | regexm(q431, "H") | regexm(q431, "I") ) & q432==1 & q433==1

**supervision visit in the last 6 months
gen sg19=0
if "`c'"=="HTFC7AFLSP" | "`c'"=="NPFC71FLSP" | "`c'"=="SNFC81FLSP" | "`c'"=="TZFC71FLSP" {
replace sg19=1 if q351==1
}

*Malawi has an extra "in past 3 months" response option
if "`c'"=="MWFC6KFLSP"{
replace sg19=1 if q351==1 | q351==2
}

**Health workers always available
gen sg20=0
replace sg20=1 if q300==1

*******************************************************************************
* ANC structure vars
*******************************************************************************
** coding variables as binary and having 0 for not having item
** name is always sa# for structure antenatal care

** select facilities that have ANC services
gen ancfacil =0
replace ancfacil=1 if (q102_05==1 & inrange(q1401,0,31)) 
*| q102_05==3

* sa1 is the ANC training variable. 

* provide iron supplementation in ANC and iron is available and valid in the facility or ANC
gen sa2 = 0
replace sa2=1 if q906_03==1 | q906_04==1 | q1422_1==1 | q1422_3==1
* q1402_1==1

* provide folic acid supplementation in ANC and iron is available and valid in the facility or ANC
gen sa3 = 0 
replace sa3=1 if q906_02==1 | q906_04==1 | q1422_2==1 | q1422_3==1    

* provide tetanus toxoid in ANC and iron is available and valid in the facility or ANC
gen sa4 = 0
replace sa4=1 if q906_08==1 | q1422_5==1   

* ANC guidelines
gen sa5 =0
replace sa5 =1 if q1410==1 | q1412==1

* BP machine or manual plus stethoscope
gen sa6 =0 
*replace sa6=1 if (q700a_08==1 & q700b_08==1) | (q700a_09==1 & q700b_09==1 &  q700a_07==1 & q700b_07==1) 
replace sa6 =1 if (q1421a_1==1 & q1421b_1==1) | (q1421a_2==1 & q1421b_2==1 &  q1421a_3==1 & q1421b_3==1)

* does facility do haemoglobin testing in ANC and are available and valid at the facility
gen sa7=0
replace sa7=1 if  q1406_4==1  

*q801==1 |
forvalues i=1/7 {
cap replace sa7=1 if q802a_`i'==1 & q802b_`i'==1 & q802c_`i'==1
cap replace sa7=1 if q802a_0`i'==1 & q802b_0`i'==1 & q802c_0`i'==1
}

* urine dipstick protein
gen sa8=0
replace sa8=1 if q837b_1==1 | q1406_2==1

* urine dipstick glucose
gen sa9=0
replace sa9=1 if q837b_2==1 | q1406_3==1

* Vaginal speculum
* Removed since speculum is ony observed in family planning clinic

* Fetoscope
gen sa10=0
replace sa10=1 if q1421a_5==1 & q1421b_5==1

* Adult scale
gen sa11=0
replace sa11=1 if q1421a_6==1 & q1421b_6==1

** syphillis test
gen sa12=0
replace sa12=1 if  q1406_5==1
replace sa12=1 if q854==1 & q855==1 & q856==1
foreach i in 1 2 4 {
replace sa12=1 if q858a_`i'==1 & q858b_`i'==1 & q858c_`i'==1
}

** Stethoscope				
gen sa13=0
replace sa13=1 if q1421a_3==1 & q1421b_3==1

** Appropriate sharps storage in ANC 	
gen sa14=0
replace sa14=1 if q1451_06==1

** Appropriate waste storage  in ANC 		
gen sa15=0
replace sa15=1 if q1451_04==1

** Disinfectant in ANC
gen sa16=0
replace sa16=1 if q1451_08==1

** Syringes in ANC
gen sa17=0
replace sa17=1 if q1451_09==1

** Running water and soap or alcohol rub in ANC
gen sa18=0
*Nepal has slightly different components
if  "`c'"=="NPFC71FLSP." {
replace sa18=1 if (q1451_01==1 & q1451_02==1) | q1451_03==1 | q1451_15==1
}
if  "`c'"!="NPFC71FLSP."{
replace sa18=1 if (q1451_01==1 & q1451_02==1) | q1451_03==1
}

** Gloves in ANC
gen sa19=0
replace sa19=1 if q1451_07==1

*******************************************************************************
** Child currative structure variable
*******************************************************************************
** coding variables as binary and having 0 for not having item
** name is always sc# for structure child currative care

** select facilities that have child currative care services
gen childfacil = 0
replace childfacil=1 if (q102_03==1 & inrange(q1201a,0,31)) 

* sc1 is the imci training variable. 

* guidelines for IMCI
gen sc2 = 0
replace sc2=1 if q1205==1

* child scale
gen sc3 = 0
replace sc3=1 if q1104a_1==1 & q1104b_1==1      //child growth monitoring area
replace sc3=1 if q700a_02==1 & q700b_02==1      // general equipment 

*For all surveys except SN, in the child health area the child scale is asked about first, then infant.
*In SN survey, the infant scale is asked about first.
if "`c'"=="SNFC81FLSP"{
replace sc3=1 if q1210a_02==1 & q1210b_02==1
}
if "`c'"!="SNFC81FLSP"{
replace sc3=1 if q1210a_01==1 & q1210b_01==1
}

* infant scale
gen sc4= 0
replace sc4=1 if q1104a_2==1 & q1104b_2==1		//child growth monitoring area
replace sc4=1 if q700a_03==1 & q700b_03==1      // general equipment 

if "`c'"=="SNFC81FLSP"{
replace sc4=1 if q1210a_01==1 & q1210b_01==1
}
if "`c'"!="SNFC81FLSP"{
replace sc4=1 if q1210a_02==1 & q1210b_02==1
}

* thermometer
gen sc5=0
replace sc5=1 if  q1210a_03==1 & q1210b_03==1 | q700a_06==1 & q700b_06==1	

* stethoscope
gen sc6 = 0
replace sc6=1 if q1210a_04==1 & q1210b_04==1 | q700a_07==1 & q700b_07==1	

**Timer or watch with seconds hand
gen sc7=0
replace sc7=1 if q1210a_05==1 & q1210b_05==1 | q1210a_06==1  

*************** Diagnostic tests *****************
** Malaria diagnostics   //remove since not all countries in analysis are malaria endemic
*gen sc10=0
*replace sc10=1 if q841==1

******************Medicines *****************
** Co-trimoxazole for children
gen sc8=0

if "`c'"!="HTFC7AFLSP"{
replace sc8=1 if q901_12==1
}

if "`c'"=="HTFC7AFLSP"{
replace sc8=1 if q901_14==1
}

** ACTs  //remove since not all countries in analysis are malaria endemic
*gen sc9=0
*replace sc9=1 if q905_1==1 | q905_2==1

**	amoxicillin child
gen sc9=0

if "`c'"!="HTFC7AFLSP"{
replace sc9=1 if q901_02==1
}
if "`c'"=="HTFC7AFLSP"{
replace sc9=1 if q901_14==1
}

**	ORS or zinc
gen sc10=0
replace sc10=1 if q906_09==1 | q906_11==1 | q1210a_09==1

**	Paracetamol
gen sc11=0
if "`c'"!="HTFC7AFLSP"{
cap replace sc11=1 if q908_3==1
cap replace sc11=1 if q908_03==1
}
if "`c'"=="HTFC7AFLSP"{
replace sc11=1 if q908_6==1
}

** Appropriate sharps storage in sick child 	
gen sc12=0
replace sc12=1 if q1251_06==1

** Appropriate waste storage  in sick child 		
gen sc13=0
replace sc13=1 if q1251_04==1

** Disinfectant in  sick child
gen sc14=0
replace sc14=1 if q1251_08==1

** Syringes in sick child
gen sc15=0
replace sc15=1 if q1251_09==1

** Running water and soap or alcohol rub in  sick child
gen sc16=0
replace sc16=1 if (q1251_01==1 & q1251_02==1) | q1251_03==1 
*NEpal includes Methylated spirit with glycerin Q1251(15) as equivalent to “alcohol-based hand disinfectant” ADD

** Gloves in sick child
gen sc17=0
replace sc17=1 if q1251_07==1

/*DO NOT USE BELOW IN STUDY
**ORS (just for checking against FR)
*gen sc18=0
*replace sc18=1 if q906_09==1 | q1210a_09==1

**ZINC (just for checking against FR)
*gen sc19=0
*replace sc19=1 if q906_11==1
*/
**************************************************
*COMPOSITE READINESS MEASURES

* ANC
**Approach 2
gen anc_r_2 =((sg1+sg4+sa18)/3)*100
label var anc_r_2 "Approach 2 ANC readiness measure"

**Approach 3
gen anc_r_3 = ((sg1+sg2+sg3+sg4+sg5+sg6+sg7+sg8+sg9+sg16+sg17+sg18+sg19+sg20+sa1+sa2+sa3+sa4+sa5+sa6+sa7+sa8+sa9+sa10+sa11+sa12+sa13+sa14+sa15+sa16+sa17+sa18+sa19)/33)*100
label var anc_r_3 "Approach 3 ANC readiness measure"

* Sick child
**Approach 2
gen sc_r_2 = ((sc9 + sc10)/2)*100 
label var sc_r_2 "Approach 2 sick child readiness measure"

**Approach 3
gen sc_r_3= ((sg1 + sg2 + sg3 +sg4 +sg5 +sg6 +sg7 + sg8 +sg9 +sg16 + sg17 +sg18 +sg19 +sg20 + sc1 + sc2 +sc3 +sc4 + sc5 +sc6 +sc7 +sc8 +sc9 + sc10 + sc11 + sc12 + sc13 + sc14 +sc15 +sc16 +sc17)/31)*100
label var sc_r_3 "Approach 3 sick child readiness measure"

**************************************************
*Code other facility variables  

* managing authority
*recode mga (1=1 "gov") (3=2 "private") (2 4 5 6 = 0 "faith/ngo/other"), gen(mga2)
recode mga (1=1 "gov") (2 3 4 5 6 = 0 "private/faith/ngo/other"), gen(mga2)

 ****************
* coding facility type and region
if sur=="HTFC7A" {
	recode factype (1/4= 1 "hospital") (5/7=2 "health center"), gen(factype1)		//these have been coded to match DHS

	gen hftype=.
	replace hftype=1 if factype1==1 & mga==1
	replace hftype=2 if factype1==2 & mga==1
	replace hftype=3 if factype1==1 & (mga==2 | mga==3 | mga==4)
	replace hftype=4 if factype1==2 & (mga==2 | mga==3 | mga==4)

	label define hftype 1 "Govt hospital" 2 "Govt health center" 3 " Private hospital" 4 "Private health center"
	label values hftype hftype
	
	*Some locations of facilities in Aire Metropolitaine needed to be corrected
	replace depart=0 if inlist(facil,15,26,58,101,102,113, 119,141,156,168,173,196,197,200,202,204,205,207,2045,2076,2079,2080,3202,3223)
	replace depart=0 if inrange(facil,8,9)
	replace depart=0 if inrange(facil,12,13)
	replace depart=0 if inrange(facil,18,19)
	replace depart=0 if inrange(facil,23,24)
	replace depart=0 if inrange(facil,28,31)
	replace depart=0 if inrange(facil,33,51)
	replace depart=0 if inrange(facil,53,56)
	replace depart=0 if inrange(facil,60,62)
	replace depart=0 if inrange(facil,64,77)
	replace depart=0 if inrange(facil,79,89)
	replace depart=0 if inrange(facil,91,92)
	replace depart=0 if inrange(facil,94,99)
	replace depart=0 if inrange(facil,104,109)
	replace depart=0 if inrange(facil,116,117)
	replace depart=0 if inrange(facil,122,129)
	replace depart=0 if inrange(facil,131,135)
	replace depart=0 if inrange(facil,137,139)
	replace depart=0 if inrange(facil,143,147)
	replace depart=0 if inrange(facil,151,152)
	replace depart=0 if inrange(facil,158,165)
	replace depart=0 if inrange(facil,175,177)
	replace depart=0 if inrange(facil,179,184)
	replace depart=0 if inrange(facil,186,188)
	replace depart=0 if inrange(facil,190,193)
	replace depart=0 if inrange(facil,2010,2012)
	replace depart=0 if inrange(facil,2040,2043)
	replace depart=0 if inrange(facil,2048,2051)
	replace depart=0 if inrange(facil,2059,2061)
	replace depart=0 if inrange(facil,2064,2071)
	replace depart=0 if inrange(facil,2083,2108)

	gen region2=depart+1
	label define region2 1 "Aire metropolitaine" 2 "Rest-Ouest" 3 "Sud-Est" 4 "Nord" 5 "Nord-Est" 6 "Artibonite" 7 "Centre" 8 "Sud" 9 "Grand'Anse" 10 "Nord-Ouest" 11 "Nippes"
	label values region2 region2


	*no strata in Haiti
	cap gen spastrata=.
	}
 
if sur=="MWFC6K" {
	recode factype (1/4= 1 "hospital") (5/9=2 "health center") , gen(factype1)	//these have been coded to match DHS

	gen hftype=.
	replace hftype=1 if factype1==1 & mga==1
	replace hftype=2 if factype1==2 & mga==1
	replace hftype=3 if factype1==1 & (mga==2 | mga==3 | mga==4 | mga==5 | mga==6)
	replace hftype=4 if factype1==2 & (mga==2 | mga==3 | mga==4 | mga==5 | mga==6)
	label values hftype hftype

	gen region2=region
	label values region2 REGION
}
 
if sur=="NPFC71" {
	recode factype (1/6 12/14= 1 "hospital") (7/11=2 "health center"), gen(factype1) //these have been coded to match DHS

	gen hftype=.
	replace hftype=1 if factype1==1 & mga==1
	replace hftype=2 if factype1==2 & mga==1
	replace hftype=3 if factype1==1 & (mga==2 | mga==3 | mga==4)
	replace hftype=4 if factype1==2 & (mga==2 | mga==3 | mga==4)
	label values hftype hftype

	gen region2=region
	label values region2 REGION

	****ecological region****
	recode district	(1 9 11 22 23 29 41 42 62/68 75 =1 mountain)   ///
					(2 3 7 8 10 12/14 20 21 24/28 30 31 36/40 43/47 51/55 59/61 69 70 73 74 = 2 hill) ///
					(4/6 15/19 32/35 48/50 56/58 71 72 =3 terai), gen(ecoregion)					
	* development-ecological zones used for stratification				
	egen zones = group(ecoregion region)
	*Combine Far/Mid/Western Mountain together
	replace zones=3 if zones ==4 | zones==5

	** facility type for creating strata
	recode factype  (1/4 13 = 1 "zonal & above hospital") (5 14 =2 "district hospital") (6=3 "private hospital") /// 
		(7=4 "PHCC") (8 9=5 "HPs") (10=6 "UHC") (11=7 "Stand alone HTC"), gen(fctype)
		
	* number of beds
	recode q112 (0/99 =1 ) (100/max=2), gen(beds)
	gen fctypebed=fctype
	* stratify private hospitals by number of beds
	replace fctypebed=8 if beds==2 & fctype==3
	* combine all government hospitals
	replace fctypebed=1 if fctypebed==2

	*strata
	egen spastrata = group(fctypebed mga2 zones)	
}
 
if sur=="SNFC81"  {
	recode factype (1= 1 "hospital") (2/4=2 "health center") , gen(factype1)		//these have been coded to match DHS

	gen hftype=.
	replace hftype=1 if factype1==1 & mga==1
	replace hftype=2 if factype1==2 & mga==1
	replace hftype=3 if factype1==1 & (mga==2 | mga==3 )
	replace hftype=4 if factype1==2 & (mga==2 | mga==3 )
	label values hftype hftype

	gen region2 = 0
	replace region2 = 1 if region==9 | region==8 | region==10
	replace region2 = 2 if region==1
	replace region2 = 3 if region==13
	replace region2 = 4 if region==5 | region==2 | region==3 | region==4
	* no Touba
	replace region2 = 5 if region==12 | region==6
	replace region2 = 6 if region==7 | region==14 | region==11
	* no Bignona or Kafountine
	label define region2 1"North" 2"Dakar" 3"Thiès" 4"Central" 5"East" 6"South"
	label values region2 region2

	*strata
	egen spastrata = group(factype region)
}
 
if sur=="TZFC71" {
	recode factype (1/5= 1 "hospital") (6/8=2 "health center"), gen(factype1) //these have been coded to match DHS

	gen hftype=.
	replace hftype=1 if factype1==1 & mga==1
	replace hftype=2 if factype1==2 & mga==1
	replace hftype=3 if factype1==1 & (mga==2 | mga==3 | mga==4)
	replace hftype=4 if factype1==2 & (mga==2 | mga==3 | mga==4)
	label values hftype hftype

	*Used geographic zones from page 13 of 2015-16 DHS report.
	recode region (14 16 =1 "Western") (2/4=2 "Northern") (1 13 21=3 "Central") (10 11 22=4 "Southern Highlands") (8/9=5 "Southern") (12 15 23=6 "South West Highlands") (17/20 24/25=7 "Lake") (5/7=8 "Eastern") (51/55=9 "Zanzibar"), gen(region2)

	*strata
	egen spastrata = group(factype mga ftype)
}

*for Nepal vars that are not included in other surveys
cap gen district=.
cap gen zone=.
cap gen ecoregion=.
cap gen fctypebed=.
cap gen fctype=.

*no strata in Malawi
cap gen spastrata=.

keep facil facwt sur mga* factype hftype ftype region* ancfacil childfacil q10* q11* q12* q14* sg* sa* sc* anc* district zone ecoregion fctypebed fctype spastrata

scalar country = "`c'"
local country = substr(country,1,2)
save "`c'ready.dta", replace
erase "`c'ready1.dta"
}


