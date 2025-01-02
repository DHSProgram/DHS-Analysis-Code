
/*****************************************************************************************************
Program:          FA NDHS 2022
Purpose:          Code equity analysis of maternal health services in Nepal FA152
Data inputs:      IR file
Outputs: 		  Coded datasets for 2022, 2016, and 2011 and tables included in FA 158
Author:           Resham Khatri                
Date last modified: 29 May 2024 by Resham Khatri
					24 June 2024 by Rachael Church
					18 July 2024 by Rebecca Rosenberg
*****************************************************************************************************/

cd "C:\Users\N116722\Downloads\FA 152"
use NPIR82FL.dta

gen wt=v005/1000000
svyset v021[pw=wt], strata(v023) vce(linearized) singleunit(missing)

***********************************************************************************
***SETTING UP DATASET AND RECODING VARIABLES***

***(b3_01-v008)=gen(brth1)
************ required sample sample size *************
keep if b19_01< 12 & m80_1 <5

********************List of Independent Variables for analysis**************
****v130, v131, v701, v133, v045c, v190, v024, v025, secoreg, v716, v704, p4_01, v741, bord_01

***************respondent's age at the birth of last child****************
gen agecb=int((b3_01-v011)/12)
ta agecb

recode agecb (13/19=1 " Less than 20") (20/24=2 " 20-24") (25/29=3 "25-29") (30/34=4 "30-34") (35/max=5 " 35 and avove"), gen(agecb1)
lab variable agecb1 "Respondent's age at the birth of last child"
ta agecb1 [iw=wt] if b19_01 <12 & m80_1 <5
*********************Respondent's Religion**************************************
recode v130 (1=1 "Hindu") (2/96=2 "Others"), gen(relig1)
label variable relig1 "Religion"
ta relig1
********************************Caste into 7 category******************************
recode v131 (1=1 "Brahmin")(2=2 "Chhetri")  (96 3/4=3 "Madheshi")(5 6=4 "Dalit")(8 7 9=5 "Janajati") (10=6 "Muslim"), gen (caste4)
label variable caste4 "Ethnicity"
ta caste4 [iw=wt] if b19_01 <12 & m80_1 <5

**ethnicity with two category ***
recode v131 1/3=1 7=1 96=1 4/6=0 8/10=0 ,gen(v131ethnicity)
lab var v131ethnicity " Ethnic category"
lab def v131ethnicity 0 "disadvantaged ethnicity " 1 "advantaged ethnicity"
lab val v131ethnicity v131ethnicity

*wealth status: two category 
recode v190 3/5=1 1/2=0 ,gen(v190wealthcat)
lab def v190wealthcat 0 "Low wealth rank " 1 "Higher wealth rank"
lab val v190wealthcat v190wealthcat

recode v106 1/3=1 0=0 ,gen(v106education)
lab def v106education 0 "no education " 1 "primary or higher"
lab val v106education v106education


*multiple marginalization 

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
tab intersectecw8

*recoding it into 4 groups 
recode intersectecw8 0=0 1/3=1 4/6=2 7=3, gen(intersect4) 
lab var intersect4 "Intersection edu wealth ethnicity"
lab def intersect4 0"triple disadvantages" 1"two disadvantage" 2" one disavantage" 3 "triple advantages"
lab val intersect4 intersect4
tab  intersect4



***************************Husband's education in 4 category***************************
recode v701 ( 0 8=0 " No Education") (1=1 "Basic") (2=2 " Secondary")(3=3 "Higher"), gen(husedu1)
label var husedu1 " Husband's Education Level"
ta husedu1 [iw=wt] 
**********************Respondent's education level*****************
recode v133 ( 0 =0 " No Education") (1/8=1 "Basic") (9/12=2 " Secondary Level") ( 13/max=3 "Higher"), gen(resedu1)
label var resedu1 " Maternal education"



***maternal education
 tab v106
*********************Respondent's Native Languages********************
recode v045c (2=1 "Nepali") (3=2 "Maithili")(4=3 "Bhojpuri") (6 1=4 "Others"),gen(reslang)
label var reslang " Maternal native language"
ta reslang
************************Respondent's occupation***********
recode v716 (0=0 "Not Working") (6=1 "Agriculture") (4/5=2 "Manual Labour")(1/3=3 "Working Paid"), gen(resoccup)
label var resoccup "Maternal occupation"
ta resoccup
***********************Husband's Occupation*********************************
recode v704 (0 99998 96=0 "Not Working") (6=1 "Agriculture") (4/5=2 "Manual Labour") (1/3=3 "Working Paid"), gen(husoccup)
label var husoccup "Paternal occupation"
ta husoccup
************Birth Order*********************************************************
ta bord_01
recode bord_01 (1=1 "1") (2=2 "2") (3/14=3 "3+"), gen(border)
lab variable border " Birth Order"
ta border
******************Independent variable same in the analysis*****************

****v190, v024, v025, secoreg, p4_01 // kept same in the analysis

******************** List of Dependent variables *******************

*****Maternal health (MNH continum of care)***

recode m14_1 (98 0/3=0 "No") (4/20=1 " Yes"), gen(ancvst)
label variable ancvst "At least 4ANC visits"
ta ancvst [iw=wt] if b19_01 <12 & m80_1 <5

*********************************ANC visit 4 category *****************************
recode m14_1 (0  98=0 "No") (1/3=1 "1-3") (4/7=2 " 4-7")(8/max= 3 "8 or more"), gen(ancvst4)
label variable ancvst4 "No of ANC visits"
ta  ancvst4 [iw=wt] 

******************* recoding to make UNIFORM denominaitor of HF delivery ********************

recode m15_1 (11 12 96=0 "No") (21/46=1 "Yes"), gen(Pdelivy)
lab var Pdelivy " Institutional delivery"
ta Pdelivy [iw=wt] 


ta m15_1 [iw=wt] if Pdelivy==1  

recode m15_1 (21/27=0 "Public HF") (31 32 36 41 46 =1 "Private") if Pdelivy==1 ,gen(hf_del) 
lab var hf_del " Place of HF delivery"
ta hf_del [iw=wt]
  
***** AMONG HF delivery- types of HF***


********************Types of HF Delivery*********************************
recode m15_1 (21/27=0 "Public HF") (31 32 36 41 46 =1 "Private and Other HF") ( 11 12 96= 2 "Home Delivery"),gen(hfdelivy1)
lab var hfdelivy1 "Type of Place of Delivery" 
ta hfdelivy1


********************Public,Private and home Delivery service(3 Categories)*********************************

*Delivery asisted by SBA
gen sbadelivery=.
replace sbadelivery=0 if m3a_1==0|m3b_1==0
replace sbadelivery=1 if m3a_1==1|m3b_1==1
lab var sbadelivery "delivery by SBA"
lab def sbadelivery 0"no SBA" 1"Yes SBA"
lab val sbadelivery sbadelivery
ta sbadelivery [iw=wt] 

**************Cash Incentive Received during Lastbirth*********************s435a_1 

recode s435a_1 ( 0 8=0 "No") (1=1 "Yes"), gen(cashbirth)
label var cashbirth " Received maternity incentive"
ta cashbirth
**********************


*****************************Delivry Type ( Normal and Caesarian)*******************************
ta m17_1 [iw=wt] if b19_01 <12 & m80_1 <5 & Pdelivy==1            
***** gives the delivery by caesarian or normal 

***** gives the delivery by caesarian in public facility  
 ta m17_1 [iw=wt] if hf_del==0 

***** gives the delivery by caesarian in privte facility 
 ta m17_1 [iw=wt] if hf_del==1


*****************Postnatal visit within 2 days****************************************
*PNC mothers witin two days 
gen pnc=.
replace pnc=0 if m62_1==0|m66_1==0
replace pnc=0 if m62_1==1& m63_1>202|m66_1==1 & m67_1>202
replace pnc=1 if m62_1==1& m63_1<=202|m66_1==1 & m67_1<=202 
lab var pnc "PNC by mother within 2 days"
lab def pnc 0"No" 1"Yes"
ta pnc [iw=wt] 


**** COC mothers****Continuum of care ******

gen cocm=.
replace cocm=0 if ancvst ==0|Pdelivy ==0|pnc==0
replace cocm=1 if ancvst ==1& Pdelivy==1& pnc==1
replace cocm=0 if cocm==.
lab var cocm "completion of COC mothers"
lab def cocm 0 "No" 1 "Yes"
lab val cocm cocm
ta cocm [iw=wt] 


********PNC newborn within two days 
gen pncn=.
replace pncn=0 if m74_1==0|m70_1==0
replace pncn=0 if m74_1==8|m70_1==8
replace pncn=0 if m74_1==1& m75_1>202|m70_1==1 &m71_1>202
replace pncn=1 if m74_1==1 & m75_1<=202|m70_1==1&m71_1<=202 
lab var pncn "at least one PNCnewborn within 2 days"
lab def pncn 0"No" 1"Yes"
lab val pncn pncn
ta pncn [iw=wt] 


********PNC mothers and newborns within 2 days post delivery 
gen pncmn=.
replace pncmn=0 if pnc==0|pncn==0
replace pncmn=0 if pnc==1 & pncn==0
replace pncmn=0 if pnc==0 & pncn==1
replace pncmn=1 if pnc==1 & pncn==1
lab var pncmn "PNC mothers and newborn within 2 days"
lab def pncmn 0"No" 1"Yes"
lab val pncmn pncmn
ta pncmn [iw=wt] 


****Continuum of care ******** completion of continuum of maternal and newborn care 
gen cocmnh=.
replace cocmnh=0 if ancvst ==0|Pdelivy ==0|pncmn==0
replace cocmnh=1 if ancvst ==1& Pdelivy==1& pncmn==1
replace cocmnh=0 if cocmnh==.
lab var cocmnh "completion of COC both"
lab def cocmnh 0 "No" 1 "Yes"
lab val cocmnh cocmnh
ta cocmnh [iw=wt] 

*************Descriptive analysis of outcome variables**************

*** Among all eligible women who had live birth one year prior to the survey ******

tabout  ancvst hfdelivy1  pnc pncn pncmn cocm cocmnh using descriptive2.xls [iw=wt], replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

*** Uptake of maternity incentive and delivery by CS among women who had delivered babies in health facilities one year prior to the survey ******
tabout   m17_1 cashbirth  using descriptive3.xls [iw=wt] if Pdelivy==1, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

*** CS delivery and uptake of maternity incentive in  private health facility************


tabout   m17_1 cashbirth  using descriptive2022pvt.xls [iw=wt] if hf_del==1, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop


*** CS delivery and uptake of maternity incentive in public  health facility************

tabout   m17_1 cashbirth  using descriptive2022pub.xls [iw=wt] if hf_del==0, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

*******************Background characteristics******************************************
tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border hfdelivy1 using descriptive.xls [iw=wt], replace oneway c(cell ci) clab(%) svy nwt(wt)sebnone per pop

***** Descriptive anaylysis******************

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border hfdelivy1 ancvst using crosstab_ancvst.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst Pdelivy using crosstab_Pdelivy.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst hfdelivy1 using crosstab_hfdelivy1.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst hf_del using crosstab_hfdelivy2.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst m17_1 using crosstab_m17_1.xls [iw=wt] if Pdelivy==1, replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst m17_1 using crosstab_m17_1pvt.xls [iw=wt] if hf_del==1, replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop
tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst m17_1 using crosstab_m17_1public.xls [iw=wt] if hf_del==0, replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst cashbirth using crosstab_cashbirth.xls [iw=wt] if Pdelivy==1, replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst cashbirth using crosstab_cashbirth1.xls [iw=wt] if hf_del==0, replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst cashbirth using crosstab_cashbirth2.xls [iw=wt] if hf_del==1, replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst hfdelivy1 pnc using crosstab_pnc.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst hfdelivy1 pncn using crosstab_pncn.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst hfdelivy1 pncmn using crosstab_pncmn.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop

tabout agecb1 relig1 caste4  resedu1 v190 intersect4 v024 v025 secoreg resoccup reslang border ancvst hfdelivy1 pncmn cocmnh using crosstab_cocmnh.xls [iw=wt], replace c(row ci) stats(chi2) svy nwt(wt)sebnone per pop


********************************************************************************************************************************************************
********Determinants ofat least 4ANC visits ******
svy: logit ancvst  i.agecb1 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05)replace 

svy:logit ancvst  i.relig1 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit ancvst  i.caste4  ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.resedu1 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.v190 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.intersect4 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.v024 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.v025 ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.secoreg ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append
svy:logit ancvst  i.resoccup ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.reslang ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.border ,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit ancvst  i.hfdelivy1,or
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


 ************MULTIVARIATE ANALYSIS of at least 4ANC visits******** 

*** checking VIF for multicolinearity
regress ancvst i.agecb1 i.relig1 i.caste4  i.resedu1 i.v190 i.intersect4 i.v024 i.v025 i.secoreg i.resoccup i.reslang i.border i.hfdelivy1
estat vif

**********variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded******


svy: logit ancvst i.agecb1 i.relig1 i.v024 i.v025 i.intersect4 i.resoccup i.reslang i.border i.hfdelivy1, or  
outreg2 using ancvst.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


********************************************************************************************************************************************************

************ place of delivery***ie home or HF*************
svy: logit Pdelivy   i.agecb1 ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05)replace 

svy:logit  Pdelivy i.caste4  ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  Pdelivy i.resedu1 ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  Pdelivy i.relig1  ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  Pdelivy i.v190 ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.intersect4 ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.v024 ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.v025 ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.secoreg ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append
svy:logit  Pdelivy i.resoccup ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.reslang ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.border ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit Pdelivy i.ancvst ,or
outreg2 using Pdelivy.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


**** multivarible analysis******* place of delivery**ie home or HF***************

*** checking VIF for multicolinearity
regress Pdelivy i.agecb1 i.relig1 i.caste4  i.resedu1 i.v190 i.intersect4 i.v024 i.v025 i.secoreg i.resoccup i.reslang i.border i.ancvst
estat vif

*************variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded******

svy: logit  Pdelivy  ib2.agecb1 i.relig1 ib7.v024 i.v025 ib3.intersect4  i.resoccup ib4.reslang i.border i.ancvst, or
outreg2 using Pdelivyaor.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace
********************************************************************************************************************************************************

***************health facility delivery***** public and private *******
svy: logit hf_del    i.agecb1 ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05)replace 

svy:logit hf_del   i.caste4  ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del   i.resedu1 ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del  i.relig1  ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.v190 ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.intersect4 ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.v024 ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.v025 ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.secoreg ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append
svy:logit  hf_del i.resoccup ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.reslang ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.border ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit hf_del i.ancvst ,or
outreg2 using hf_del.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


**** multivarible analysis****** public and private *********

*** checking VIF for multicolinearity
regress hf_del i.agecb1 i.relig1 i.caste4  i.resedu1 i.v190 i.intersect4 i.v024 i.v025 i.secoreg i.resoccup i.reslang i.border i.ancvst
estat vif
***e
*************variable intersect4 was created using education, caste, and v190 so these these three were excluded in the MV analysis and and ecoregion was highly co-related with province so ecoregion was excluded******

svy: logit hf_del i.agecb1 i.relig1  i.intersect4 ib7.v024 i.v025  i.resoccup i.reslang i.border i.ancvst, or
outreg2 using hf_delaor.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


********************************************************************************************************************************************************


********** DETERMINANTS OF delivery by CS****** these analysis are not included in the report ****
svy:logit  m17_1  i.i.agecb1  if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


svy:logit   m17_1   i. relig1 if Pdelivy==1, or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  m17_1  i.caste4  if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  m17_1   i.resedu1 if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit m17_1 i.v190 if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit m17_1 i.intersect4 if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit m17_1 i.v024 if Pdelivy==1,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit m17_1 i.v025 if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


svy:logit m17_1 i.secoreg  if Pdelivy==1,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append
svy:logit  m17_1 i.resoccup  if Pdelivy==1,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit m17_1 i.reslang if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit m17_1 i.border if Pdelivy==1 ,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit m17_1 i.ancvst if Pdelivy==1,or
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


**** multivarible analysis**DETERMINANTS OF delivery by CS****** these analysis are not included in the report ********

*** checking VIF for multicolinearity
regress m17_1  i.agecb1 i.relig1 i.caste4  i.resedu1 i.v190 i.intersect4 i.v024 i.v025 i.secoreg i.resoccup i.reslang i.border i.ancvst 
estat vif
********** i.intersect4 is created using education, caste, v190, so these three are removed ******

svy: logit m17_1   i.agecb1 i.relig1 ib7.v024 i.v025 ib3.intersect4 i.resoccup ib4.reslang i.border i.ancvst if Pdelivy==1, or  
outreg2 using m17_1.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace


************************************************************************************************************************************************

*****Determinants of uptake of maternity incentive ***** these analysis are not included in the report ********
svy:logit  cashbirth  i.i.agecb1  if Pdelivy==1 ,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

svy:logit   cashbirth   i. relig1 if Pdelivy==1, or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit  cashbirth  i.caste4 if Pdelivy==1 ,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace
svy:logit cashbirth    i.resedu1 if Pdelivy==1,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth  i.v190 if Pdelivy==1,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.intersect4 if Pdelivy==1,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.v024 if Pdelivy==1 ,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.v025 if Pdelivy==1 ,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.secoreg if Pdelivy==1,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append
svy:logit  cashbirth i.resoccup if Pdelivy==1 ,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.reslang if Pdelivy==1 ,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.border if Pdelivy==1,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append

svy:logit cashbirth i.ancvst if Pdelivy==1,or
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) append


**** multivarible analysis******uptake of maternity incentive ***** these analysis are not included in the report ********

*** checking VIF for multicolinearity
regress ancvst i.agecb1 i.relig1 i.caste4  i.resedu1 i.v190 i.intersect4 i.v024 i.v025 i.secoreg i.resoccup i.reslang i.border i.ancvst
estat vif

**********education, caste, v190, and ecoregion are highly correlated******


svy: logit cashbirth  i.agecb1 i.relig1 ib7.v024 i.v025 i.intersect4 i.resoccup ib3.reslang i.border i.ancvst, or  
outreg2 using cashbirth.xls, eform stats(coef ci) sideway dec(2) label(insert) alpha(0.001, 0.01, 0.05) replace

save 2022datacoded.dta

************************************************************************************************
****** for trends Analysis 
**************** NDHS 2016 ********

use NPIR61FL.dta
gen wt=v005/1000000
svyset v021[pw=wt], strata(v023) vce(linearized) singleunit(missing)

***********************************************************************************
***(b3_01-v008)=gen(brth1)
************ required sample sample size *************
keep if b19_01< 12 

******************** List of Dependent variables *******************

*****Maternal health (MNH continum of care)***

recode m14_1 (98 0/3=0 "No") (4/20=1 " Yes"), gen(ancvst)
label variable ancvst "At least 4ANC visits"
ta ancvst [iw=wt] if b19_01 <12 

*********************************ANC visit 4 category *****************************
recode m14_1 (0  98=0 "No") (1/3=1 "1-3") (4/7=2 " 4-7")(8/max= 3 "8 or more"), gen(ancvst4)
label variable ancvst4 "No of ANC visits"
ta  ancvst4 [iw=wt] 

******************* recoding to make UNIFORM denominaitor of HF delivery ********************

recode m15_1 (11 12 96=0 "No") (21/51=1 "Yes"), gen(Pdelivy)
lab var Pdelivy " Institutional delivery"
ta Pdelivy [iw=wt] 


********************Place of HF Delivery*********************************
recode m15_1 (21/27=0 "Public HF") (31 32 36 41 46 51 =1 "Private and Other HF") ( 11 12 96= 2 "Home Delivery"),gen(hfdelivy1)
lab var hfdelivy1 "Type of Place of Delivery" 
ta hfdelivy1


ta m15_1 [iw=wt] if Pdelivy==1  

recode m15_1 (21/27=0 "Public HF") (31 32 36 41 46 51 =1 "Private and Other HF") if Pdelivy==1 ,gen(hf_del) 

ta hf_del [iw=wt]
  

*Delivery asisted by SBA
gen sbadelivery=.
replace sbadelivery=0 if m3a_1==0|m3b_1==0
replace sbadelivery=1 if m3a_1==1|m3b_1==1
lab var sbadelivery "delivery by SBA"
lab def sbadelivery 0"no SBA" 1"Yes SBA"
lab val sbadelivery sbadelivery

***** AMONG HF delivery- types of HF***


**************Cash Incentive Received during Lastbirth*********************s431a_1 

recode s431a_1 ( 0 8=0 "No") (1=1 "Yes"), gen(cashbirth16)
label var cashbirth16 "Received maternity incentive"
ta cashbirth16

*****************************Delivry Type ( Normal and Caesarian)*******************************
ta m17_1 [iw=wt] if Pdelivy==1           

 ta m17_1 [iw=wt] if hf_del==0 
 ta m17_1 [iw=wt] if hf_del==1

***private health facility************

  ta m17_1 [iw=wt] if hf_del==0
ta m17_1 [iw=wt] if hf_del==1


*****************Postnatal visit within 2 days****************************************
*PNC mothers witin two days 
gen pnc=.
replace pnc=0 if m62_1==0|m66_1==0
replace pnc=0 if m62_1==1& m63_1>202|m66_1==1 & m67_1>202
replace pnc=1 if m62_1==1& m63_1<=202|m66_1==1 & m67_1<=202 
lab def pnc 0"No" 1"Yes"
recode pnc (0=0 "No") (1=1 "Yes"),gen(pnc1)
lab var pnc1 "PNC by mother within 2 days"
ta pnc1


*PNC newborn within two days 
gen pncn=.
replace pncn=0 if m74_1==0|m70_1==0
replace pncn=0 if m74_1==8|m70_1==8
replace pncn=0 if m74_1==1& m75_1>202|m70_1==1 &m71_1>202
replace pncn=1 if m74_1==1 & m75_1<=202|m70_1==1&m71_1<=202 
lab var pncn "at least one PNCnewborn within 2 days"
lab def pncn 0"No" 1"Yes"
lab val pncn pncn


*PNC mothers and newborns within 2 days post delivery 
gen pncmn=.
replace pncmn=0 if pnc==0|pncn==0
replace pncmn=0 if pnc==1 & pncn==0
replace pncmn=0 if pnc==0 & pncn==1
replace pncmn=1 if pnc==1 & pncn==1
lab var pncmn "PNC mothers and newborn within 2 days"
lab def pncmn 0"No" 1"Yes"
lab val pncmn pncmn


********completion of continuum of maternal  care 
gen cocm=.
replace cocm=0 if ancvst ==0|Pdelivy ==0|pnc1==0
replace cocm=1 if ancvst ==1& Pdelivy==1& pnc1==1
replace cocm=0 if cocm==.
lab var cocm "completion of COC mothers"
lab def cocm 0 "No" 1 "Yes"
lab val cocm cocm


****Continuum of care ******

** completion of continuum of maternal and newborn care 
gen cocmnh=.
replace cocmnh=0 if ancvst ==0|Pdelivy ==0|pncmn==0
replace cocmnh=1 if ancvst ==1& Pdelivy==1& pncmn==1
replace cocmnh=0 if cocmnh==.
lab var cocmnh "completion of COC"
lab def cocmnh 0 "No" 1 "Yes"
lab val cocmnh cocmnh


recode m15_1 (21/27=0 "Public HF") (31 32 36 41 46 51=1 "Private and Other HF") ( 11 12 96= 2 "Home Delivery"),gen(hfdelivy2016)
lab var hfdelivy2016 "Place of Delivery" 
ta hfdelivy2016

recode s431a_1 ( 0 8=0 "No") (1=1 "Yes"), gen(cashbirth2)
label var cashbirth2 " Received maternity incentive"
ta cashbirth2

***private health facility************

  ta m17_1 [iw=wt] if hf_del==0
ta m17_1 [iw=wt] if hf_del==1

  ta cashbirth16[iw=wt] if hf_del==0
ta cashbirth16 [iw=wt] if hf_del==1
*******************
tabout  ancvst hfdelivy2016 hf_del pnc pncn pncmn cocm cocmnh using descriptive16.xls [iw=wt], replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop
tabout   m17_1 cashbirth2  using descriptive2016.xls [iw=wt] if Pdelivy==1, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop
tabout   m17_1 cashbirth2  using descriptive2016pvt.xls [iw=wt] if hf_del==1, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop
tabout   m17_1 cashbirth2  using descriptive2016pub.xls [iw=wt] if hf_del==0, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

save 2016datacoded.dta

********NDHS2011 ********
use NPIR51FL.dta
gen wt=v005/1000000
svyset v021[pw=wt], strata(v023) vce(linearized) singleunit(missing)

***********************************************************************************

************ required sample sample size *************
gen childage=v008-b3_01
keep if childage<12


******************** List of Dependent variables *******************

*****Maternal health (MNH continum of care)***

recode m14_1 (98 0/3=0 "No") (4/20=1 " Yes"), gen(ancvst)
label variable ancvst "At least 4ANC visits"
ta ancvst [iw=wt] 

*********************************ANC visit 4 category *****************************
recode m14_1 (0  98=0 "No") (1/3=1 "1-3") (4/7=2 " 4-7")(8/max= 3 "8 or more"), gen(ancvst4)
label variable ancvst4 "No of ANC visits"
ta  ancvst4 [iw=wt] 

******************* recoding to make UNIFORM denominaitor of HF delivery ********************

recode m15_1 (11 12 96=0 "No") (21/46=1 "Yes"), gen(Pdelivy)
lab var Pdelivy "Institutional delivery"
ta Pdelivy [iw=wt] 


ta m15_1 [iw=wt] if Pdelivy==1  

recode m15_1 (21/27=0 "Public HF") (31 32 34 35 36 41 46 =1 "Private and Other HF") if Pdelivy==1 ,gen(hf_del) 

ta hf_del [iw=wt]
  
***** AMONG HF delivery- types of HF***


*****************************Delivery Type ( Normal and Caesarian)*******************************
ta m17_1 [iw=wt] if  Pdelivy==1            

 ta m17_1 [iw=wt] if hf_del==0 
 ta m17_1 [iw=wt] if hf_del==1
** gives the delivery by caesarian or normal 

*****************Postnatal visit within 2 days****************************************
*PNC mothers witin two days 
gen pnc=.
replace pnc=0 if m62_1==0|m66_1==0
replace pnc=1 if m62_1==1|m66_1==1  
lab def pnc 0"No" 1"Yes"


****Continuum of care ******

** completion of continuum of maternal and newborn care 
gen cocmnh=.
replace cocm=0 if ancvst ==0|Pdelivy ==0|pnc==0
replace cocm=1 if ancvst ==1& Pdelivy==1& pnc==1
replace cocm=0 if cocm==.
lab var cocm "completion of COC"
lab def cocm 0 "No" 1 "Yes"
lab val cocm cocm
ta cocm


recode m15_1 (21/27=0 "Public HF") (31/36=1 "Private and Other HF") ( 11 12 96= 2 "Home Delivery"),gen(hfdelivy2011)
lab var hfdelivy2011 "Place of Delivery" 
ta hfdelivy2011

recode s428a_1 ( 0 8=0 "No") (1=1 "Yes"), gen(cashbirth2)
label var cashbirth2 "Received maternity incentive"
ta cashbirth2

*cash incentive in facility delivery ***
gen cash2011 =.
replace cash2011 =0 if s428a_1==0
replace cash2011 =0 if s428a_1==8
replace cash2011 =1 if s428a_1==1

lab var cash2011 "Cash incentive received"
lab def cash2011 0"No" 1"Yes"
lab val cash2011 cash2011 
ta cash2011 [iw=wt]

ta cash2011 [iw=wt] if hf_del==0 
ta cash2011 [iw=wt] if hf_del==1


*******************
tabout  ancvst  hf_del hfdelivy2011 pnc cocm  using descriptive2011.xls [iw=wt], replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop
tabout   m17_1 cash2011 using descriptive2011.xls [iw=wt] if Pdelivy==1, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop


ta m17_1 [iw=wt] if hf_del==0 
ta m17_1 [iw=wt] if hf_del==1
ta cash2011 [iw=wt] if hf_del==0 
ta cash2011 [iw=wt] if hf_del==1

tabout   m17_1 cash2011  using descriptive2011pvt.xls [iw=wt] if hf_del==1, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop
tabout   m17_1 cash2011 using descriptive2011pub.xls [iw=wt] if hf_del==0, replace oneway c(cell ) clab(%) svy nwt(wt)sebnone per pop

save 2011datacoded.dta

*****************************************************significance test of trends by marginalization status **********

*******Trends by marginalization***********************************************

*****
*ANC*
*****

*Triple disadvantage
*2011 to 2016
prtesti 199 .2696 69 .4998

*2016 to 2022
prtesti 69 .4998 82 .6650

*2011 to 2022
prtesti 199 .2696 82 .6650


*Double disadvantage
*2011 to 2016
prtesti 337 .3812 334 .6135

*2016 to 2022
prtesti 334 .6135 293 .7536 

*2011 to 2022
prtesti 337 .3812 293 .7536


*Single disadvantage
*2011 to 2016
prtesti 306 .6574 423 .7483 

*2016 to 2022
prtesti 423 .7483 426 .8554

*2011 to 2022
prtesti 306 .6574 426 .8554


*No disadvantage
*2011 to 2016
prtesti 215 .8894 137 .9324 

*2016 to 2022
prtesti 137 .9324 180 .9131 

*2011 to 2022
prtesti 215 .8894 180 .9131


************************
*INSTITUTIONAL DELIVERY*
************************

*Triple disadvantage
*2011 to 2016
prtesti 199 .2256 69 .4143

*2016 to 2022
prtesti 69 .4143 82 .6023

*2011 to 2022
prtesti 199 .2256 82 .6023


*Double disadvantage
*2011 to 2016
prtesti 337 .2895 334 .4714

*2016 to 2022
prtesti 334 .4714 293 .7045 

*2011 to 2022
prtesti 337 .2895 293 .7045


*Single disadvantage
*2011 to 2016
prtesti 306 .5707 423 .7390 

*2016 to 2022
prtesti 423 .7390 426 .8587

*2011 to 2022
prtesti 306 .5707 426 .8587


*No disadvantage
*2011 to 2016
prtesti 215 .8138 137 .9677

*2016 to 2022
prtesti 137 .9677 180 .9655

*2011 to 2022
prtesti 215 .8138 180 .9655


*****
*PNC*
*****

*Triple disadvantage
*2011 to 2016
prtesti 199 .2643 69 .2877

*2016 to 2022
prtesti 69 .2877 82 .5893

*2011 to 2022
prtesti 199 .2643 82 .5893


*Double disadvantage
*2011 to 2016
prtesti 337 .3204 334 .4456

*2016 to 2022
prtesti 334 .4456 293 .6387 

*2011 to 2022
prtesti 337 .3204 293 .6387


*Single disadvantage
*2011 to 2016
prtesti 306 .5556 423 .6260 

*2016 to 2022
prtesti 423 .6260 426 .7553

*2011 to 2022
prtesti 306 .5556 426 .7553


*No disadvantage
*2011 to 2016
prtesti 215 .8330 137 .8867 

*2016 to 2022
prtesti 137 .8867 180 .9036 

*2011 to 2022
prtesti 215 .8330 180 .9036


*****
*COC*
*****

*Triple disadvantage
*2011 to 2016
prtesti 199 .0865 69 .1841

*2016 to 2022
prtesti 69 .1841 82 .3922

*2011 to 2022
prtesti 199 .0865 82 .3922


*Double disadvantage
*2011 to 2016
prtesti 337 .1431 334 .2712

*2016 to 2022
prtesti 334 .2712 293 .4874 

*2011 to 2022
prtesti 337 .1431 293 .4874


*Single disadvantage
*2011 to 2016
prtesti 306 .3733 423 .4919 

*2016 to 2022
prtesti 423 .4919 426 .6139

*2011 to 2022
prtesti 306 .3733 426 .6139


*No disadvantage
*2011 to 2016
prtesti 215 .7219 137 .8367 

*2016 to 2022
prtesti 137 .8367 180 .7969 

*2011 to 2022
prtesti 215 .7219 180 .7969


***************
*CS DELIVERIES*
***************

*Triple disadvantage
*2011 to 2016
prtesti 45 .0652 29 .1334

*2016 to 2022
prtesti 29 .1334 49 .1192

*2011 to 2022
prtesti 45 .0652 49 .1192


*Double disadvantage
*2011 to 2016
prtesti 98 .0851 158 .1005 

*2016 to 2022
prtesti  158 .1005 206 .1588

*2011 to 2022
prtesti 98 .0851 206 .1588


*Single disadvantage
*2011 to 2016
prtesti 175 .1051 313 .1691

*2016 to 2022
prtesti 313 .1691 366 .2564

*2011 to 2022
prtesti 175 .1051 366 .2564


*No disadvantage
*2011 to 2016
prtesti 175 .1951 133 .2905 

*2016 to 2022
prtesti 133 .2905 174 .2496 

*2011 to 2022
prtesti 175 .1951 174 .2496



*********************
*MATERNAL INCENTIVES*
*********************

*Triple disadvantage
*2011 to 2016
prtesti 45 .7265 27 .8512

*2016 to 2022
prtesti 27 .8512 49 .6805

*2011 to 2022
prtesti 45 .7265 49 .6805


*Double disadvantage
*2011 to 2016
prtesti 98 .7140 144 .7857

*2016 to 2022
prtesti 144 .7857 206 .7381 

*2011 to 2022
prtesti 98 .7140 206 .7381


*Single disadvantage
*2011 to 2016
prtesti 175 .8094 291 .7572

*2016 to 2022
prtesti 291 .7572 366 .6386

*2011 to 2022
prtesti 175 .8094 366 .6386


*No disadvantage
*2011 to 2016
prtesti 175 .6529 132 .6378 

*2016 to 2022
prtesti 132 .6378 174 .6657 

*2011 to 2022
prtesti 175 .6529 174 .6657
