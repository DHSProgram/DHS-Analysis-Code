
/*****************************************************************************************************
Program: 			codevars.do
Purpose: 			code variables for each survey
Author:				Shireen Assaf. 	
Date last modified: Oct 20, 2021 by Shireen Assaf 
					Nov 24, 2021 by Sara Riese to add SWPER global variables
					Feb 10,2022 by Sara Riese to create young/older reference group collective norm variables
				
*****************************************************************************************************/

*IR files
foreach c in $irdata {
use "$Datafilepath/`c'.dta", clear

cap label define yesno 0 "no" 1 "yes" 

local cn=substr("`c'",1,2)

************************************************
//OUTCOME: Currently use modern method
gen modfp = v313==3
label var modfp "Currently using any modern method"

************************************************

*marital status
recode v502 (0=1 "Never married") (1=2 "Currently in a union") (2=3 "Formerly in a union") (8 9 =.), gen(mstatus)

*Sample limited to married women and men
keep if mstatus==2

*exclude pregnant women or men with pregnant partners
drop if v213==1 

//Background variables
*generate female variable
gen female=1
gen male=0

*age	
recode v013 (1 2 =1 "15-24")(3 4 =2 "25-34")(5/7 =3 "35-49"),g(age_cat)

*young - for further "community" definition
recode v013 (1 2 3 = 1 "Young") (4 5 6 7 = 0 "Older"), g(wyoung)
label var wyoung "Younger age"

*older - for further "community" definition
recode v013 (1 2 3 = 0 "Young") (4 5 6 7 = 1 "Older"), g(wolder)
label var wolder "Older age"

*edu
recode v106 (0 = 1 "None") (1 = 2 "Primary") (2/3 =3 "Secondary+"),g(wedu)

*children ever born
gen ceb = v201
recode v201 (0 = 0 "0") (1 2 = 1 "1-2") (3 4 = 2 "3-4") (5/max =3 "5 or more"), g(ceb_cat)
lab var ceb "Parity"	

*Collective norm avg number of children***
bys v001: egen collect_ceb=mean(v201)
label var collect_ceb "Avg num children"

*Heard a family planning message from any of the 4 media sources: TV, radio, paper, or mobile
cap gen fp_messages = 1
cap replace fp_messages =0 if (v384a!=1 & v384b!=1 & v384c!=1 &v384d!=1)
cap label var fp_messages "Exposed to any FP message"

*Ideal number of children 
recode v613 (95/99=. ), gen(wideal) 
recode wideal (0=0 "0") (1/3 = 1 "1-3") (4/6 = 2 "4-6") (7/9 = 3 "7-9") (10/max = 4 "10+"), gen(wideal_cat)
label var wideal "Ideal num children"

*Collective norm ideal number of children***
bys v001: egen collect_wideal=mean(wideal)
label var collect_wideal "Avg ideal num children"

*Collective norm among younger women
gen wyoungideal=wideal
replace wyoungideal=. if wolder==1
bys v001: egen collect_wyoungideal=mean(wyoungideal)
label var collect_wyoungideal "Avg ideal num children - young women"

*Collective norm among older women
gen wolderideal=wideal
replace wolderideal=. if wyoung==1
bys v001: egen collect_wolderideal=mean(wolderideal)
label var collect_wolderideal "Avg ideal num children - older women"

*Desire for children 
recode v605 (1=1 "Wants soon") (2/4=0 "Does not want soon") (5/6=0) (7=.), gen(desire)
label var desire "Desire for children"

*Contraceptive decision-making: Sole or joint decision maker regarding contraceptive use or non-use 
capture recode v632 (1=1 "Self or jointly") (3=1) (2=0 "Husband or other") (6=0), gen(fp_decision)
replace fp_decision = . if (v502!=1 | v213!=0 | v312==0)
lab var fp_decision "Decision maker for using contraception"
	
*Then code decision making among those not using contraception
capture recode v632a (1=1 "Self or jointly") (3=1) (2=0 "Husband or other") (6=0), gen(nofp_decision)
lab var nofp_decision "Decision maker for not using contraception"

*Finally combine the two Sole or joint decision maker regarding contraceptive use or non-use 
gen decision=1
replace decision=0 if fp_decision==0 | nofp_decision==0 
lab var decision "Contraceptive use or non-use decision maker"
lab define decision 0 "Husband/other" 1 "Self/joint with husband"
lab val decision decision

*Collective norm contraceptive decision making***
bys v001: egen collect_decision=mean(decision)
label var collect_decision "Prop of women making fp decisions"

*Collective norm among younger women
gen wyoungdecision=decision
replace wyoungdecision=. if wolder==1
bys v001: egen collect_wyoungdecision=mean(wyoungdecision)
label var collect_wyoungdecision "Prop of young women making fp decisions"

*Collective norm among older women
gen wolderdecision=decision
replace wolderdecision=. if wyoung==1
bys v001: egen collect_wolderdecision=mean(wolderdecision)
label var collect_wolderdecision "Prop of older women making fp decisions"

*cluster urban or rural
recode v025 (2=0 "Rural") (1=1 "Urban"), gen(urbrur)
bys v001: egen collect_urbrur=mean(urbrur)
*label define urbrur 1 "urban" 2 "rural"
label val collect_urbrur urbrur
la var collect_urbrur "Urbanicity"

**** Strata
*checked strata code and this is v022 for all surveys
gen strata=v022
label values strata V022

**** SWPER global calculations

gen union = inlist(v501,1,2)				// Currently married or in union
  	  lab var union "Currently married or in union"
  	  lab val union yn
  	  
*** SWPER global - Survey-based women's empowerment index
*Written by Fernanda Ewerling*
*Updated July 2020*
						
// Recoding missings from 9, 99, 999 to . 

mvdecode v744a v744b v744c v744d v744e v743a v743b v743d v157, mv(9)
mvdecode v133 v715 v730, mv(99)
  		
// Beating NOT justified variables
recode v744a 0=1 1=-1 8=0, gen(beat1)
recode v744b 0=1 1=-1 8=0, gen(beat2)
recode v744c 0=1 1=-1 8=0, gen(beat3)
recode v744d 0=1 1=-1 8=0, gen(beat4)
recode v744e 0=1 1=-1 8=0, gen(beat5)
label define beat -1 "Yes" 0 "Don't know" 1 "No"
label value (beat1 beat2 beat3 beat4 beat5) beat
  		
//Decision variables - new categories
recode v743a 4/7=-1 2/3=1 8/max=., gen(decide1a)
recode v743b 4/7=-1 2/3=1 8/max=., gen(decide2a)
recode v743d 4/7=-1 2/3=1 8/max=., gen(decide3a)
label define decide1 -1 "Husband/partner or other alone" 1 "Respondent alone or jointly with husband/partner" 
label value (decide1a decide2a decide3a) decide1
  		
//Wm education & work variables
recode v133 98=., gen(educ)
recode v157 3=2, gen(read) 		// Most countries do not have the cathegory "almost everyday"(3), so we recoded it to "At least once a week"(2).
  		
//Wm autonomy questions
clonevar age1cohab=v511
	*Imputing age1birth for those women that do not have children***
	recode age1cohab 33/max=33, gen (age1)
	hotdeck v212, store by(age1) keep(caseid) imp(1)
	sort age1 v212
	preserve
	use "imp1.dta", clear
	rename v212 v212_i
	drop age1
	save, replace
	restore
	cap drop _merge
	merge 1:1 caseid using "imp1.dta"
	erase "imp1.dta"
	clonevar age1birth=v212_i
  		
//Husband variables
recode v715 98=., gen(husb_educ)		//Recode dk as missing 
gen educ_diff= educ - husb_educ 		//education difference: woman-husband years of schooling
recode v730 98=., gen(husb_age)			//Recode dk as missing 
gen age_diff = v012 - husb_age 			// age difference: woman-husband
  		

**Standardized the calculations to the regions (South Asia for Nepal, West & Central AFrica for Nigeria, and Eastern & Southern Africa for Zambia)

if "`c'"=="NGIR7BFL" {
gen swpatt=((-1.202)+(0.508*beat1)+(0.508*beat2)+(0.526*beat3)+(0.538*beat4)+(0.588*beat5)+(0.083*read)+(0.016*educ)+(-0.006*age1cohab)+(-0.010*age1birth)+(0.001*age_diff)+(0.002*educ_diff)+(0.001*decide1a)+(-0.017*decide2a)+(-0.002*decide3a)-(-0.601))/2.030
gen swpsoc=((-5.661)+(-0.012*beat1)+(-0.026*beat2)+(0.001*beat3)+(0.001*beat4)+(-0.015*beat5)+(0.422*read)+(0.081*educ)+(0.133*age1cohab)+(0.139*age1birth)+(0.031*age_diff)+(0.054*educ_diff)+(-0.004*decide1a)+(-0.022*decide2a)+(-0.034*decide3a)-(-0.683))/1.346
gen swpdec=((-0.168)+(-0.003*beat1)+(-0.040*beat2)+(0.007*beat3)+(0.028*beat4)+(-0.020*beat5)+(0.121*read)+(0.022*educ)+(-0.012*age1cohab)+(-0.016*age1birth)+(0.013*age_diff)+(0.001*educ_diff)+(0.599*decide1a)+(0.601*decide2a)+(0.619*decide3a)-(-0.913))/1.562
la var swpatt "SWPER - attitude to violence domain"
la var swpsoc "SWPER - social independence domain"
la var swpdec "SWPER - decision-making domain"
}

if "`c'"=="NPIR7HFL" {
gen swpatt=((-1.202)+(0.508*beat1)+(0.508*beat2)+(0.526*beat3)+(0.538*beat4)+(0.588*beat5)+(0.083*read)+(0.016*educ)+(-0.006*age1cohab)+(-0.010*age1birth)+(0.001*age_diff)+(0.002*educ_diff)+(0.001*decide1a)+(-0.017*decide2a)+(-0.002*decide3a)-(-0.138))/1.804
gen swpsoc=((-5.661)+(-0.012*beat1)+(-0.026*beat2)+(0.001*beat3)+(0.001*beat4)+(-0.015*beat5)+(0.422*read)+(0.081*educ)+(0.133*age1cohab)+(0.139*age1birth)+(0.031*age_diff)+(0.054*educ_diff)+(-0.004*decide1a)+(-0.022*decide2a)+(-0.034*decide3a)-(-0.121))/1.452
gen swpdec=((-0.168)+(-0.003*beat1)+(-0.040*beat2)+(0.007*beat3)+(0.028*beat4)+(-0.020*beat5)+(0.121*read)+(0.022*educ)+(-0.012*age1cohab)+(-0.016*age1birth)+(0.013*age_diff)+(0.001*educ_diff)+(0.599*decide1a)+(0.601*decide2a)+(0.619*decide3a)-(-0.097))/1.546
la var swpatt "SWPER - attitude to violence domain"
la var swpsoc "SWPER - social independence domain"
la var swpdec "SWPER - decision-making domain"
}

if "`c'"=="ZMIR71FL" {
gen swpatt=((-1.202)+(0.508*beat1)+(0.508*beat2)+(0.526*beat3)+(0.538*beat4)+(0.588*beat5)+(0.083*read)+(0.016*educ)+(-0.006*age1cohab)+(-0.010*age1birth)+(0.001*age_diff)+(0.002*educ_diff)+(0.001*decide1a)+(-0.017*decide2a)+(-0.002*decide3a)-(0.094))/1.745
gen swpsoc=((-5.661)+(-0.012*beat1)+(-0.026*beat2)+(0.001*beat3)+(0.001*beat4)+(-0.015*beat5)+(0.422*read)+(0.081*educ)+(0.133*age1cohab)+(0.139*age1birth)+(0.031*age_diff)+(0.054*educ_diff)+(-0.004*decide1a)+(-0.022*decide2a)+(-0.034*decide3a)-(-0.142))/1.350
gen swpdec=((-0.168)+(-0.003*beat1)+(-0.040*beat2)+(0.007*beat3)+(0.028*beat4)+(-0.020*beat5)+(0.121*read)+(0.022*educ)+(-0.012*age1cohab)+(-0.016*age1birth)+(0.013*age_diff)+(0.001*educ_diff)+(0.599*decide1a)+(0.601*decide2a)+(0.619*decide3a)-(0.246))/1.283
la var swpatt "SWPER - attitude to violence domain"
la var swpsoc "SWPER - social independence domain"
la var swpdec "SWPER - decision-making domain"
}

*Collective norm "SWPER global score - attitude to violence domain"***
bys v001: egen collect_swpatt=mean(swpatt)
la var collect_swpatt "Avg SWPER attitude"

*Collective norm among younger women
gen wyoungswpatt=swpatt
replace wyoungswpatt=. if wolder==1
bys v001: egen collect_wyoungswpatt=mean(wyoungswpatt)
la var collect_wyoungswpatt "Avg young women SWPER attitude"

*Collective norm among older women
gen wolderswpatt=swpatt
replace wolderswpatt=. if wyoung==1
bys v001: egen collect_wolderswpatt=mean(wolderswpatt)
la var collect_wolderswpatt "Avg older women SWPER attitude"

*Collective norm "SWPER global score - social independence domain"***
bys v001: egen collect_swpsoc=mean(swpsoc)
la var collect_swpsoc "Avg SWPER soc ind"

*Collective norm among younger women
gen wyoungswpsoc=swpsoc
replace wyoungswpsoc=. if wolder==1
bys v001: egen collect_wyoungswpsoc=mean(wyoungswpsoc)
la var collect_wyoungswpsoc "Avg young women SWPER soc ind"

*Collective norm among older women
gen wolderswpsoc=swpsoc
replace wolderswpsoc=. if wyoung==1
bys v001: egen collect_wolderswpsoc=mean(wolderswpsoc)
la var collect_wolderswpsoc "Avg older women SWPER soc ind"

*Collective norm "SWPER global score - decision-making domain"***
bys v001: egen collect_swpdec=mean(swpdec)
la var collect_swpdec "Avg SWPER dec making"

*Collective norm among younger women
gen wyoungswpdec=swpdec
replace wyoungswpdec=. if wolder==1
bys v001: egen collect_wyoungswpdec=mean(wyoungswpdec)
la var collect_wyoungswpdec "Avg young women SWPER dec making"

*Collective norm among older women
gen wolderswpdec=swpdec
replace wolderswpdec=. if wyoung==1
bys v001: egen collect_wolderswpdec=mean(wolderswpdec)
la var collect_wolderswpdec "Avg older women SWPER dec making"


*Collective norm on distance to facility being a barrier (>50% of the cluster reports distance being a barrier)
recode v467d (2=0 "Not a big problem") (1=1 "Big problem"), gen(distance)
bys v001: egen mean_distance=mean(distance)
gen collect_distance = 1 if mean_distance>=.5
replace collect_distance =0 if mean_distance<.5
la def fac_dist 0 "Distance not a barrier" 1 "Distance is a barrier"
la value collect_distance fac_dist
la var collect_distance "Prop of women saying distance as a barrier"

*update to only keep vars we need
keep v000-v025 v190 v213 modfp-swpdec collect_*
gen cluster=v001

save "$Codedfilepath//`cn'IRcoded.dta", replace
	
} 


********************************************************************************************
********************************************************************************************

* MR files
foreach c in $mrdata {
use "$Datafilepath/`c'.dta", clear
cap label define yesno 0 "no" 1 "yes" 
local cn=substr("`c'",1,2)

************************************************
//Currently use modern method
gen modfp = mv313==3
label var modfp "Currently using any modern method"

************************************************
************************************************

*marital status
recode mv502 (0=1 "Never married") (1=2 "Currently in a union") (2=3 "Formerly in a union") (8 9 =.), gen(mstatus)

*Sample limited to married women and men
keep if mstatus==2

*exclude pregnant women or men with pregnant partners
drop if mv213==1

//Background variables

*generate male variable
gen male=1
gen female=0

*age	
recode mv013 (1 2 =1 "15-24")(3 4 =2 "25-34")(5/7 =3 "35-49")(8 =4 "50+"),g(mage_cat)

*Want to grand-mean center age
summarize mv012, meanonly
gen centered_mage = mv012 - r(mean)
label var centered_mage "Age"

*young - for further "community" definition
recode mv013 (1 2 3 4= 1 "Young") (5 6 7 8 9 = 0 "Older"), g(myoung)
label var myoung "Younger age"

*older - for further "community" definition
recode mv013 (1 2 3 4 = 0 "Young") (5 6 7 8 9 = 1 "Older"), g(molder)
label var molder "Older age"


*edu
recode mv106 (0 = 1 "None") (1 = 2 "Primary") (2/3 =3 "Secondary+"),g(medu)
la var medu "Education"


*children ever born
gen ceb = mv201
recode mv201 (0 = 0 "0") (1 2 = 1 "1-2") (3 4 = 2 "3-4") (5/max =3 "5 or more"), g(ceb_cat)
lab var ceb "Parity"

*Collective norm avg number of children***
bys mv001: egen collect_ceb=mean(mv201)
label var collect_ceb "Avg num children"


*Any family planning message from any of the 4 media sources: TV, radio, paper, or mobile
cap gen fp_messages = 1
cap replace fp_messages = 0 if (mv384a!=1 & mv384b!=1 & mv384c!=1 & mv384d!=1)
cap label var fp_messages "Exposed to any of the four media sources"

*Ideal number of children
recode mv613 (95/99=. ), gen(mideal)
recode mideal (0=0 "0") (1/3 = 1 "1-3") (4/6 = 2 "4-6") (7/9 = 3 "7-9") (10/max = 4 "10+"), gen(mideal_cat)
label var mideal "Ideal number of children"

*Collective norm ideal number of children***
bys mv001: egen collect_mideal=mean(mideal)
label var collect_mideal "Avg ideal num children"

*Collective norm among younger men
gen myoungideal=mideal
replace myoungideal=. if molder==1
bys mv001: egen collect_myoungideal=mean(myoungideal)
label var collect_myoungideal "Avg young men ideal num children"

*Collective norm among older men
gen molderideal=mideal
replace molderideal=. if myoung==1
bys mv001: egen collect_molderideal=mean(molderideal)
label var collect_molderideal "Avg older men ideal num children"

*Desire for children
recode mv605 (1=1 "Wants soon") (2/4=0 "Does not want soon") (5/6=0) (7=.), gen(desire)
*recode mv605 (1=1 "Wants soon") (2/3=0 "Does not want soon") (5/6=0) (4=2 "Undecided/infecund") (7=2), gen(desire)
* indicator is usually computed for men in a union. should we keep this if we have ideal?
*replace desire=. if mv502!=1
label var desire "Desire for children"

*Belief that contraceptives make a woman more promiscuous
recode mv3b25b (0=0 "Disagree") (1=1 "Agree") (8=.), gen(promis)
label var promis "Believes fp make a woman more promiscuous"

*Collective norm contraceptives make a woman more promiscuous***
bys mv001: egen collect_promis=mean(promis)
label var collect_promis "Prop men believe fp make a woman more promiscuous"

*Collective norm among younger men
gen myoungpromis=promis
replace myoungpromis=. if molder==1
bys mv001: egen collect_myoungpromis=mean(myoungpromis)
label var collect_myoungpromis "Prop young men believe fp make a woman more promiscuous"

*Collective norm among older men
gen molderpromis=promis
replace molderpromis=. if myoung==1
bys mv001: egen collect_molderpromis=mean(molderpromis)
label var collect_molderpromis "Prop older men believe fp make a woman more promiscuous"

*Belief that contraceptives are a woman's business
recode mv3b25a (0=0 "Disagree") (1=1 "Agree") (8=.), gen(fpwomenonly)
label var fpwomenonly "Believe fp are a woman's business"

*Collective norm contraceptives are a woman's business***
bys mv001: egen collect_fpwomenonly=mean(fpwomenonly)
label var collect_fpwomenonly "Prop men believe fp are a woman's business"

*Collective norm among younger men
gen myoungfpwomenonly=fpwomenonly
replace myoungfpwomenonly=. if molder==1
bys mv001: egen collect_myoungfpwomenonly=mean(myoungfpwomenonly)
label var collect_myoungfpwomenonly "Prop young men believe fp are a woman's business"

*Collective norm among older men
gen molderfpwomenonly=fpwomenonly
replace molderfpwomenonly=. if myoung==1
bys mv001: egen collect_molderfpwomenonly=mean(molderfpwomenonly)
label var collect_molderfpwomenonly "Prop older men believe fp are a woman's business"

*cluster urban or rural
recode mv025 (2=0 "Rural") (1=1 "Urban"), gen(urbrur)
bys mv001: egen collect_urbrur=mean(urbrur)
label val collect_urbrur urbrur

*Collective norm meduc
recode mv133 98=., gen(yrsmedu)
bys mv001: egen collect_medu=mean(yrsmedu)

*Collective norm older medu
gen molderedu=medu
replace molderedu=. if myoung==1
bys mv001: egen collect_molderedu=mean(molderedu)
label var collect_molderedu "Average num yrs of older men's education"

*Collective norm younger meduc
gen myoungedu=medu
replace myoungedu=. if molder==1
bys mv001: egen collect_myoungedu=mean(myoungedu)
label var collect_myoungedu "Average num yrs of younger men's education"

**** Strata
*checked strata code and this is mv022 for all surveys
gen strata=mv022
label values strata MV022

*update to only keep vars we need
keep mv000-mv025 mv190 mv213 modfp-strata collect_*
gen cluster=mv001


save "$Codedfilepath//`cn'MRcoded.dta", replace
	
} 

********************************************************************************************
********************************************************************************************
*Run the do file to create the multilevel weights

do "multilev.do"  

**** Strata ****
*qui do "C:\Users\\$user\ICF\Analysis - Shared Resources\Code\Stata Code\Survey_strata.do"


********************************************************************************************
********************************************************************************************

*Add collect_medu, collect_promis and collect_fpwomenonly to women's files

foreach c in $mrdata {
local cn=substr("`c'",1,2)
use	"$Codedfilepath//`cn'MRcoded.dta"
collapse collect_mideal collect_myoungideal collect_molderideal collect_promis collect_myoungpromis collect_molderpromis collect_fpwomenonly collect_myoungfpwomenonly collect_molderfpwomenonly collect_medu collect_myoungedu collect_molderedu, by(cluster)
save "$Codedfilepath//`cn'MR_clustemp.dta", replace
}

foreach c in $irdata {
local cn=substr("`c'",1,2)
use	"$Codedfilepath//`cn'IRcoded.dta"

drop _merge


merge m:1 cluster using "$Codedfilepath//`cn'MR_clustemp.dta", keepusing (collect_mideal collect_myoungideal collect_molderideal collect_promis collect_myoungpromis collect_molderpromis collect_myoungfpwomenonly collect_molderfpwomenonly collect_fpwomenonly collect_medu collect_myoungedu collect_molderedu)

save "$Codedfilepath//`cn'IRcoded.dta", replace
}

*Add collective norms variables to men's files
foreach c in $irdata {
local cn=substr("`c'",1,2)
use	"$Codedfilepath//`cn'IRcoded.dta"
collapse collect_wideal collect_wolderideal collect_wyoungideal collect_distance collect_decision collect_wolderdecision collect_wyoungdecision collect_swpatt collect_wyoungswpatt collect_wolderswpatt collect_swpsoc collect_wyoungswpsoc collect_wolderswpsoc collect_swpdec collect_wyoungswpdec collect_wolderswpdec collect_swpatt_cn collect_wyoungswpatt_cn collect_wolderswpatt_cn collect_swpsoc_cn collect_wyoungswpsoc_cn collect_wolderswpsoc_cn collect_swpdec_cn collect_wyoungswpdec_cn collect_wolderswpdec_cn, by(cluster)
save "$Codedfilepath//`cn'IR_clustemp.dta", replace
}

foreach c in $mrdata {
local cn=substr("`c'",1,2)
use	"$Codedfilepath//`cn'MRcoded.dta"

merge m:1 cluster using "$Codedfilepath//`cn'IR_clustemp.dta", keepusing (collect_wideal collect_wolderideal collect_wyoungideal collect_distance collect_decision collect_wolderdecision collect_wyoungdecision collect_swpatt collect_wyoungswpatt collect_wolderswpatt collect_swpsoc collect_wyoungswpsoc collect_wolderswpsoc collect_swpdec collect_wyoungswpdec collect_wolderswpdec collect_swpatt_cn collect_wyoungswpatt_cn collect_wolderswpatt_cn collect_swpsoc_cn collect_wyoungswpsoc_cn collect_wolderswpsoc_cn collect_swpdec_cn collect_wyoungswpdec_cn collect_wolderswpdec_cn)

save "$Codedfilepath//`cn'MRcoded.dta", replace
clear
}

* Appending mens file to womens file and drop unmarried and pregnant people
foreach c in $irdata {
local cn=substr("`c'",1,2)
use	"$Codedfilepath//`cn'IRcoded.dta"

append using "$Codedfilepath//`cn'MRcoded.dta"

lab var collect_mideal "Avg ideal num children"
lab var collect_myoungideal "Avg young men ideal num children"
lab var collect_molderideal "Avg older men ideal num children"
lab var collect_promis "Prop men believe fp make a woman more promiscuous"
lab var collect_myoungpromis "Prop young men believe fp make a woman more promiscuous"
lab var collect_molderpromis "Prop older men believe fp make a woman more promiscuous"
lab var collect_fpwomenonly "Prop men believe fp are a woman's business"
lab var collect_myoungfpwomenonly "Prop young men believe fp are a woman's business"
lab var collect_molderfpwomenonly "Prop older men believe fp are a woman's business"
lab var collect_medu "Average years men's education"

save "$Codedfilepath//`cn'coded.dta", replace
clear
}