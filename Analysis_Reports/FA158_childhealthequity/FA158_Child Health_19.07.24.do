
/*****************************************************************************************************
Program:          FA NDHS 2022
Purpose:          Code equity analysis of child health services in Nepal FA 158
Data inputs:      KR file
Outputs: 		  Coded datasets for 2022, 2016, and 2011 and tables included in FA 158
Author:           Resham Khatri               
Date last modified: 29 May 2024 by Resham Khatri
					24 June 2024 by Rachael Church
					18 July 2024 by Rebecca Rosenberg
*****************************************************************************************************/

cd "C:\Users\N116722\Downloads\FA 158"
use NPKR82FL.dta

gen wt=v005/1000000
svyset v021[pw=wt], strata(v023) vce(linearized) singleunit(missing)

********************List of Independent Variables for analysis**************v130, v131, v701, v106, v045c, v190, v024, v025, secoreg, v716,  v704, p4_01, v741
keep if b5==1

*******************************newcategories************************************
***************respondent's age at the birth of last child****************
gen agecb=int((b3-v011)/12)
ta agecb
recode agecb (13/19=1 "Less than 20") (20/29=2 "20-29") (30/max= 3 "30 and above"), gen(agecb1)
lab variable agecb1 "Maternal age in years"
ta agecb1
ta agecb1 [iw=wt] 

***********************Child's Age in Months recoded*****************************************
recode b19 (0/5=1 "<6")(6/11=2 "6-11")(12/23=3 "12-23")(24/35=4 "24-35")(36/47=5 "36-47")(48/59=6 "48-59"),gen (agechild2)
lab var agechild2 "Child age in months"
ta agechild2 [iw=wt]if b19 <60 & b5==1
*********************Respondent's Religion**************************************
recode v130 (1=1 "Hindu") (2/96=2 "Others"), gen(relig1)
label variable relig1 "Religion"
ta relig1 [iw=wt] 
********************************Caste into 8 category******************************
recode v131 (1=1 "Brahamin")(2=2 "Chhetri")  (96 3/4=3 "Madheshi")(5 6=4 "Dalit")(8 9=5 "Janajati")(7=6 "Newar")(10=7 "Muslim"), gen (caste4)
label variable caste4 "Ethnicity"
ta caste4 [iw=wt] if b19 <60 & b5==1


**ethnicity with two category ***
recode v131 1/3=1 7=1 96=1 4/6=0 8/10=0 ,gen(v131ethnicity)
lab var v131ethnicity " Ethnic category"
lab def v131ethnicity 0 "disadvantaged ethnicity " 1 "advantaged ethnicity"
lab val v131ethnicity v131ethnicity
ta  v131ethnicity[iw=wt] 

***wealth status: two category 
recode v190 3/5=1 1/2=0 ,gen(v190wealthcat)
lab def v190wealthcat 0 "Low wealth rank " 1 "Higher wealth rank"
lab val v190wealthcat v190wealthcat
ta  v131ethnicity [iw=wt] 

recode v106 1/3=1 0=0 ,gen(v106education)
lab def v106education 0 "no education " 1 "primary or higher"
lab val v106education v106education
ta  v131ethnicity [iw=wt] 

*****multiple marginalization 

gen intersectecw8=.
replace intersectecw8=0 if v131ethnicity==0 & v106education==0 & v190wealthcat==0
replace intersectecw8=1 if v131ethnicity==1 & v106education==0 & v190wealthcat==0 
replace intersectecw8=2 if v131ethnicity==0 & v106education==1 & v190wealthcat==0
replace intersectecw8=3 if v131ethnicity==0 & v106education==0 & v190wealthcat==1
replace intersectecw8=4 if v131ethnicity==1 & v106education==1 & v190wealthcat==0
replace intersectecw8=5 if v131ethnicity==1 & v106education==0 & v190wealthcat==1
replace intersectecw8=6 if v131ethnicity==0 & v106education==1 & v190wealthcat==1
replace intersectecw8=7 if v131ethnicity==1 & v106education==1 & v190wealthcat==1
lab var intersectecw8 "Intersection of education wealth and ethnicity"
lab def intersectecw8 0"triple disadvantage" 1" advethnic illiterate poor" 2"ethminority literate poor" 3"ethminority illiterate rich" 4 "advethnic literatepoor" 5 "advethnic illiteraterich" 6 "ethminority literaterich" 7  "triple advantaged"
lab val intersectecw8 intersectecw8
tab intersectecw8 [iw=wt]

*recoding it into 4 groups 
recode intersectecw8 0=0 1/3=1 4/6=2 7=3, gen(intersect4) 
lab var intersect4 "Intersection edu wealth ethnicity"
lab def intersect4 0"triple disadvantages" 1"two disadvantage" 2" one disavantage" 3 "triple advantages"
lab val intersect4 intersect4
tab intersect4 [iw=wt]  


***************************Husband's education in 4 category***************************
recode v701 ( 0 8=0 " No Education") (1=1 "Basic") (2=2 " Secondary")(3=3 "Higher"), gen(husedu1)
label var husedu1 " Husband's Education Level"
ta husedu1 [iw=wt] if b19 <60 & b5==1
**********************Respondent's education level*****************
recode v133 ( 0 =0 " No Education") (1/8=1 "Basic") (9/12=2 " Secondary Level") ( 13/max=3 "Higher"), gen(resedu1)
label var resedu1 " Maternal education"
ta resedu1 [iw=wt] if b19 <60 & b5==1
*********************Respondent's Native Languages********************
recode v045c (2=1 "Nepali") (3=2 "Maithili")(4=3 "Bhojpuri") (6 1=4 "Others"),gen(reslang)
label var reslang " Respondent's Native Language"
ta reslang [iw=wt] if b19 <60 & b5==1
************************Respondent's occupation***********
recode v716 (0 96=0 "Not Working") (6=1 "Agriculture") (4/5=2 "Manual Labour")(1/3=3 "Working Paid"), gen(resoccup)
label var resoccup "Respondent's Occupation"
ta resoccup [iw=wt] if b19 <60 & b5==1
***********************Husband's Occupation*********************************
recode v704 (0 99998 96=0 "Not Working") (6=1 "Agriculture") (4/5=2 "Manual Labour") (1/3=3 "Working Paid"), gen(husoccup)
label var husoccup "Husband's Occupation"
ta husoccup [iw=wt] if b19 <60 & b5==1
************Birth Order*********************************************************
ta bord
recode bord (1=1 "1") (2=2 "2") (3/max=3 "3+"), gen(border)
lab variable border " Birth Order"
ta border [iw=wt] if b19 <60 & b5==1
******************Independent variable same in the analysis***************** v190, v024, v025, secoreg, b4 // kept same in the analysis


******************** List of Dependent variables *******************
**********************Diarrhoea in the last 2 weeks**********************
recode h11 (0 8=0 "No") (2=1 "Yes"), gen (diarr)
label var diarr " Children had diarrhoea"
ta diarr [iw=wt] 
****************Treatment done in Diarrhoea cases********************************

ta h12y [iw=wt]       


****SOURCE OF CARE SEEKING ***************Diarrhoea in the last 2 weeks**********************

label var diarr " Children had diarrhoea"
ta diarr [iw=wt] 
****************Treatment done in Diarrhoea cases********************************
ta h12y [iw=wt]        
***keep same explanation will be different than the main report ( Includes traditional practitioner)***


**Generate diarrhea treatment sought from private health facilities only out of those who sought treatment//
gen darr_trt_pvt=.
replace darr_trt_pvt=0 if h44a==11| h44a==12 | h44a==13 | h44a==14 | h44a==15 | h44a==16 | h44a==17
replace darr_trt_pvt=1 if h44a==21 | h44a==22 | h44a==23 | h44a==42 | h44a==96 

label variable darr_trt_pvt " Treatmeny for diarrhea"
lab def darr_trt_pvt  0 "Public facility" 1 "Private" 
tab darr_trt_pvt [iw=wt]


**********************Fever in the last 2 weeks**********************
recode h22 (0 8=0 "No") (2=1 "Yes"), gen (fever)
label var fever "Children had fever"
ta fever [iw=wt] 
*************************Fever Treatment*******************************
gen fev_tret=.
replace fev_tret=1 if h22==1 & h32y==0
replace fev_tret=0 if h22==1 & h32y==1

label variable fev_tret " Treatment sought for fever"
ta fev_tret [iw=wt] 
************************Treatment seeking at FEVER*******************
recode fev_tret ( 0=0 "No") ( 1=1 "Yes"),gen (fev_tret1)
label variable fev_tret1 " Sought treatment for fever"
ta fev_tret1 [iw=wt] 

*************************************************************************************************** *****  fever treatment private facility**** REVISED FINAL ****
tab h22, m

gen fevertrt_pvt= . 
replace fevertrt_pvt=0 if h22==1 & h46a== 11 | h22==1 & h46a==12 |h22==1 & h46a==13 | h22==1 & h46a==14 | h22==1 & h46a==15 | h22==1 & h46a==16 | h22==1 & h46a==17 | h22==1 & h46a==18
replace fevertrt_pvt=1 if h22==1 & h46a==21 | h22==1 & h46a==22 |h22==1 &  h46a==23 | h22==1 & h46a==41 |h22==1 &  h46a==42|h22==1 &  h46a==96

label variable fevertrt_pvt " Sought treatment for fever in private facilty "
lab def fevertrt_pvt 0"Public" 1"Private"
ta fevertrt_pvt [iw=wt] 

save 2022coded.dta, replace

***** child health**********fever and diarrhea among children in  NDHS2022***********************************************

tabout  diarr h12y   darr_trt_pvt fever   fev_tret1  using outcome_ch2022.xls [iw=wt], replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop
ta diarr [iw=wt]

******************Descriptive Analysis******************************************


tabout  b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border using descriptivech2022.xls [iw=wt], replace oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

***** bivariable analysis of all outcome variables***

tabout b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border diarr using crosstab_diarr.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border h12y using crosstab_h12y.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border darr_trt_pvt using crosstab_darr_trt_pvt.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border fever using crosstab_fever.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border fev_tret1 using crosstab_fev_tret1.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout b4 agechild2  agecb1 relig1 caste4 resedu1 v190 intersect4 v024 v025 secoreg reslang border h32y  fevertrt_pvt using  crosstab_fevertrt_pvt.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop


*** treatment of fever in private facilities is calculated at the end of regression analysis of care seeking of fever **********************************


********* determinants of prevalence of diarrhoea among children****************
svy:logit  diarr  i.b4   ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit diarr  i.agechild2   ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit diarr i.agecb1  ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit diarr i.relig1 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit diarr i.caste4 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit diarr  i.resedu1 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit diarr i.v190 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit diarr i.intersect4 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  diarr i.v024 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit diarr  i.v025 ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit diarr  i.secoreg ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit diarr  i.reslang ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  diarr i.border ,or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append



**** multivarible analysis*** determinants of prevalence of diarrhoea among children*******

*** checking VIF for multicolinearity
regress diarr  i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 i.v024 i.v025  i.secoreg i.resoccup i.reslang i.border 
estat vif

**************variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded************

svy: logit   diarr  i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 ib7.v024 i.v025 i.secoreg  ib4.reslang i.border , or
outreg2 using diarr.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


****** Determinants of treatment of diarrhoea among children aged under five ****************
svy:logit  h12y i.b4   ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit h12y i.agechild2   ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.agecb1  ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.relig1 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y  i.caste4 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.resedu1 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.v190 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.intersect4 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.v024 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.v025 ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.secoreg ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.resoccup ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit h12y i.reslang ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit h12y i.border ,or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

*** checking VIF for multicolinearity
regress h12y   i.b4 i.agechild2 i.agecb1 i.relig1  i.intersect4 i.v024 i.v025 i.secoreg  i.reslang i.border 
estat vif

**********variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded*********

svy: logit   h12y  i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 ib7.v024 i.v025 i.reslang ib2.border , or
outreg2 using h12y.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


*************determinants of treaatment of diarrhea in private facility *****************************
svy:logit  darr_trt_pvt i.b4   ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit darr_trt_pvt i.agechild2   ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.agecb1  ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.relig1 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.caste4 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.resedu1 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.v190 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.intersect4 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.v024 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.v025 ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit darr_trt_pvt i.secoreg ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit darr_trt_pvt i.reslang ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit darr_trt_pvt i.border ,or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append



*** checking VIF for multicolinearity
regress darr_trt_pvt i.b4 i.agechild2 i.agecb1 i.relig1  i.intersect4 i.v024 i.v025 i.secoreg  i.reslang i.border 
estat vif

*****************variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded********

svy: logit   darr_trt_pvt i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 ib7.v024 i.v025 i.reslang i.border , or
outreg2 using darr_trt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


*****************************Prevalence of fever among children aged under five years***************************************************************
svy:logit fever  i.b4   ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit fever i.agechild2   ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  fever i.agecb1  ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fever i.relig1 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fever i.caste4 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fever i.resedu1 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fever i.v190 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fever i.intersect4 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fever i.v024 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fever i.v025 ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fever i.secoreg ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fever i.reslang ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fever i.border ,or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append



*** checking VIF for multicolinearity
regress fever   i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 i.v024 i.v025 i.secoreg i.reslang i.border 
estat vif

***variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded************

svy: logit  fever  i.b4 i.agechild2 i.agecb1 i.relig1 ib7.intersect4 i.v024 i.v025 ib4.reslang i.border , or
outreg2 using fever.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


**************************care seeking for fever among children aged under five years ***************
svy:logit  fev_tret1 i.b4   ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit fev_tret1  i.agechild2   ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.agecb1  ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.relig1 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.caste4 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.resedu1 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append
svy:logit fev_tret1 i.v190 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.intersect4 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1  i.v024 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.v025 ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.secoreg ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.reslang ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fev_tret1 i.border ,or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


*** checking VIF for multicolinearity
regress fev_tret1  i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 i.v024 i.v025 i.secoreg  i.reslang i.border 
estat vif

**********ecoregion is highly correlated******

svy: logit fev_tret1  i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 i.v024 i.v025  ib4.reslang i.border , or
outreg2 using fev_tret1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace



*************************************************************

svy:logit  fevertrt_pvt i.b4   ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit fevertrt_pvt i.agechild2   ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.agecb1  ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.relig1 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.caste4 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.resedu1 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fevertrt_pvt i.v190 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.intersect4 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fevertrt_pvt i.v024 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.v025 ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.secoreg ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit fevertrt_pvt i.reslang ,or
outreg2 using fevertrt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit fevertrt_pvt i.border ,or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append



*** checking VIF for multicolinearity
regress fevertrt_pvt  i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 i.v024 i.v025 i.secoreg  i.reslang i.border 
estat vif
*******variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded******

svy: logit fevertrt_pvt i.b4 i.agechild2 i.agecb1 i.relig1 i.intersect4 ib7.v024 ib2.v025  i.reslang i.border , or
outreg2 using fevertrt_pvt.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace



**********************************************************************************************************************************

****** for trend analysis NDHS 2016***
******** List of Dependent variables *******************
clear
use NPKR61FL.dta

gen wt=v005/1000000
svyset v021[pw=wt], strata(v023) vce(linearized) singleunit(missing)

********************List of Independent Variables for analysis**************v130, v131, v701, v106, v045c, v190, v024, v025, secoreg, v716,  v704, p4_01, v741

keep if b5==1
*******************
**********************Diarrhoea in the last 2 weeks**********************
recode h11 (0 8=0 "No") (2=1 "Yes"), gen (diarr)
label var diarr " Children had diarrhoea"
ta diarr [iw=wt] 
****************Treatment done in Diarrhoea cases********************************
***keep same explanation will be different than the main report ( Includes traditional practitioner)***
ta h12y [iw=wt]

**********************Fever in the last 2 weeks**********************
recode h22 (0 8=0 "No") (2=1 "Yes"), gen (fever)
label var fever "Children had fever"
ta fever [iw=wt] 
*************************Fever Treatment*******************************
gen fev_tret=.
replace fev_tret=1 if h22==1 & h32y==0
replace fev_tret=0 if h22==1 & h32y==1
label variable fev_tret "Treatment sought for fever"
lab def yesno 0 "No" 1 "Yes"
lab val fev_tret yesno
ta fev_tret [iw=wt] 
************************Treatment seeking at FEVER*******************
recode fev_tret ( 0=0 "No") ( 1=1 "Yes"), gen (fev_tret1)
label variable fev_tret1 "Sought treatment for fever"
ta fev_tret1 [iw=wt] 

*******************Outcome Variables********************************************
****SOURCE OF CARE SEEKING ****************Diarrhoea in the last 2 weeks**********************
//Diarrhea treatment in private medical sector
gen diarr_primed=0 if diarr==1
replace diarr_primed=1 if diarr==1 & h12j==1|h12k==1|h12l==1|h12m==1
replace diarr_primed=. if b5==0
label var diarr_primed "Diarrhea treatment sought from private medical sector among children with diarrhea"
tab diarr_primed [iw=wt]

gen diarr_primed_trt=0 if h12y==0
replace diarr_primed_trt=1 if diarr==1 & h12j==1|h12k==1|h12l==1|h12m==1
replace diarr_primed_trt=. if b5==0
label var diarr_primed_trt "Diarrhea treatment sought from private medical sector among children with diarrhea that sought treatment"
tab diarr_primed_trt [iw=wt]

**********************Fever/cough  in the last 2 weeks**********************
recode h31 (0 8=0 "No") (2=1 "Yes"), gen (cough)
label var cough "Children had cough"
ta cough [iw=wt] 

gen fevcough_tret=.
replace fevcough_tret=1 if h31==2 & h32y==0
replace fevcough_tret=0 if h31==0 & h32y==1
label variable fevcough_tret "Treatment sought for fever/cough"
lab def fevcough_tret 0 "No" 1 "Yes"
label value fevcough_tret fevcough_tret
ta fevcough_tret [iw=wt] 


*****fever treatment private facility**** REVISED FINAL ****
tab h22, m
keep if h22==1

clonevar fevertrt=h46a
replace fevertrt=0 if h46a== 11 | h46a==12 | h46a==13 | h46a==14 | h46a==15 | h46a==16 
replace fevertrt=1 if fevertrt==21| fevertrt==22 | fevertrt==23 | fevertrt==32 |fevertrt==46 | fevertrt==96

label variable fevertrt " Sought treatment for fever in private facilty "
lab def fevertrt 0"Public" 1"Private"
label value fevertrt fevertrt
ta fevertrt [iw=wt] 


***trend analysis NDHS 2016 ****

tabout diarr h12y diarr_primed_trt fever fev_tret1 fevertrt  using outcome_ch2016.xls [iw=wt], replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

save 2016coded.dta, replace

***** OUTCOME VARAIBLES NDHS 2011****
******* List of Dependent variables *******************
clear
use NPKR51FL.dta

gen wt=v005/1000000
svyset v021[pw=wt], strata(v023) vce(linearized) singleunit(missing)

********************List of Independent Variables for analysis**************v130, v131, v701, v106, v045c, v190, v024, v025, secoreg, v716,  v704, p4_01, v741

keep if b5==1
******** List of Dependent variables *******************

**********************Diarrhoea in the last 2 weeks**********************
recode h11 (0 8=0 "No") (2=1 "Yes"), gen (diarr)
label var diarr " Children had diarrhoea"
ta diarr [iw=wt] 
****************Treatment done in Diarrhoea cases********************************
***keep same explanation will be different than the main report (Includes traditional practitioner)***
ta h12y [iw=wt]        

**********************Fever in the last 2 weeks**********************
recode h22 (0 8=0 "No") (2=1 "Yes"), gen (fever)
label var fever "Children had fever"
ta fever [iw=wt] 
*************************Fever Treatment*******************************
gen fev_tret=.
replace fev_tret=1 if h22==1 & h32y==0
replace fev_tret=0 if h22==1 & h32y==1
label variable fev_tret "Treatment sought for fever"
lab def yesno 0 "No" 1 "Yes"
lab val fev_tret yesno
ta fev_tret [iw=wt] 

************************Treatment seeking at FEVER*******************
recode fev_tret ( 0=0 "No") ( 1=1 "Yes"), gen (fev_tret1)
label variable fev_tret1 "Sought treatment for fever"
ta fev_tret1 [iw=wt] 


****************Treatment done in Diarrhoea cases********************************
ta h12y [iw=wt]        
***keep same explanation will be different than the main report (Includes traditional practitioner)***

//Diarrhea treatment in private medical sector
gen diarr_primed=0 if diarr==1
replace diarr_primed=1 if diarr==1 & h12j==1|h12k==1|h12l==1|h12m==1
replace diarr_primed=. if b5==0
label var diarr_primed "Diarrhea treatment sought from private medical sector among children with diarrhea"
tab diarr_primed [iw=wt]

gen diarr_primed_trt=0 if h12y==0
replace diarr_primed_trt=1 if diarr==1 & h12j==1|h12k==1|h12l==1|h12m==1
replace diarr_primed_trt=. if b5==0
label var diarr_primed_trt "Diarrhea treatment sought from private medical sector among children with diarrhea that sought treatment"
tab diarr_primed_trt [iw=wt]


***************
*****  fever treatment private facility**** REVISED FINAL ****
tab h22, m
*keep if h22==1

clonevar fevertrt=h46a
replace fevertrt=0 if h46a== 11 | h46a==12 | h46a==13 | h46a==14 | h46a==15 | h46a==16 | h46a==17 
replace fevertrt=1 if fevertrt==21| fevertrt==22 | fevertrt==25| fevertrt==26   |fevertrt==31 |fevertrt==32 | fevertrt==96

label variable fevertrt "Sought treatment for fever in private facilty "
lab def fevertrt 0"Public" 1"Private"
ta fevertrt [iw=wt] 
**************** **********************Fever/cough  in the last 2 weeks**********************
recode h31(0 8=0 "No") (2=1 "Yes"), gen (cough)
label var cough "Children had cough/fever"
ta cough [iw=wt] 

gen fevcough_tret=.
replace fevcough_tret=1 if h31==2 & h32y==0
replace fevcough_tret=0 if h31==0 & h32y==1
label variable fevcough_tret "Treatment sought for fever"
lab def fevcough_tret 0"No" 1"Yes"
label value fevcough_tret fevcough_tret
ta fevcough_tret [iw=wt] 

save 2011coded.dta, replace

*ANALYSIS DESIRPTIVE ** FOR TRENDS ****
tabout  diarr h12y   diarr_primed_trt fever   fev_tret1 fevertrt  using outcome_ch2011.xls [iw=wt], replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

***************** significant test was calculated using proportion test******************************************************
******Significance tests for trends by marginalization***********

*********************
*DIARRHEA PREVALENCE*
*********************

*TRIPLE DISADVANTAGE
*2011 to 2016
prtesti 1200 .1477 597 .0775

*2016 to 2022
prtesti 597 .0775 615 .1047

*2011 to 2022
prtesti 1200 .1477 615 .1047


*DOUBLE DISADVANTAGE
*2011 to 2016
prtesti 1672 .1415 1783 .0780

*2016 to 2022
prtesti 1783 .0780 1510 .1153

*2011 to 2022
prtesti 1672 .1415 1510 .1153
 

*SINGLE DISADVANTAGE
*2011 to 2016
prtesti 1348 .1361 1720 .0833

*2016 to 2022
prtesti 1720 .0833 2118 .0993

*2011 to 2022
prtesti 1348 .1361 2118 .0993


*NO DISADVANTAGE
*2011 to 2016
prtesti 920 .1238 787 .0543

*2016 to 2022
prtesti 787 .0543 797 .0948 

*2011 to 2022
prtesti 920 .1238 797 .0948


*********************
*DIARRHEA TREATMENT*
*********************

*TRIPLE DISADVANTAGE
*2011 to 2016
prtesti 177 .5526 46 .5744

*2016 to 2022
prtesti 46 .5744 64 .6486

*2011 to 2022
prtesti 177 .5526 64 .6486


*DOUBLE DISADVANTAGE
*2011 to 2016
prtesti 237 .5934 139 .6472

*2016 to 2022
prtesti 139 .6472 174 .5392

*2011 to 2022
prtesti 237 .5934 174 .5392


*SINGLE DISADVANTAGE
*2011 to 2016
prtesti 183 .6761 143 .7199

*2016 to 2022
prtesti 143 .7199 210 .5677

*2011 to 2022
prtesti 183 .6761 210 .5677 


*NO DISADVANTAGE
*2011 to 2016
prtesti 114 .6932 43 .4865

*2016 to 2022
prtesti 43 .4865 76 .5931

*2011 to 2022
prtesti 114 .6932 76 .5931


*********************
*FEVER PREVALENCE*
*********************

*TRIPLE DISADVANTAGE
*2011 to 2016
prtesti 1200 .1513 597 .1882

*2016 to 2022
prtesti 597 .1882 615 .1922
 
*2011 to 2022
prtesti 1200 .1513 615 .1922


*DOUBLE DISADVANTAGE
*2011 to 2016
prtesti 1672 .1841 1783 .2066

*2016 to 2022
prtesti 1783 .2066 1510 .2304

*2011 to 2022
prtesti 1672 .1841 1510 .2304


*SINGLE DISADVANTAGE
*2011 to 2016
prtesti 1348 .2061 1720 .2100

*2016 to 2022
prtesti 1720 .2100 2118 .2309

*2011 to 2022
prtesti 1348 .2061 2118 .2309


*NO DISADVANTAGE
*2011 to 2016
prtesti 920 .2098 787 .2442

*2016 to 2022
prtesti 787 .2442 797 .2553 

*2011 to 2022
prtesti 920 .2098 797 .2553

*********************
*FEVER TREATMENT    *
*********************

*TRIPLE DISADVANTAGE
*2011 to 2016
prtesti 181 .5876 112 .6928

*2016 to 2022
prtesti 112 .6928 118 .7908

*2011 to 2022
prtesti 181 .5876 118 .7908


*DOUBLE DISADVANTAGE
*2011 to 2016
prtesti 308 .6882 368 .7810

*2016 to 2022
prtesti 368 .7810 348 .7456

*2011 to 2022
prtesti 308 .6882 348 .7456


*SINGLE DISADVANTAGE
*2011 to 2016
prtesti 278 .7592 361 .8401

*2016 to 2022
prtesti 361 .8401 489 .7803

*2011 to 2022
prtesti 278 .7592 489 .7803 


*NO DISADVANTAGE
*2011 to 2016
prtesti 193 .8143 192 .8178

*2016 to 2022
prtesti 192 .8178 203 .8364

*2011 to 2022
prtesti 193 .8143 203 .8364





