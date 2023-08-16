/*****************************************************************************************************
Program: 			codevars.do
Purpose: 			Code variables for Gender Attitudes/Norms report
Data inputs: 		MR and IR files
Data outputs:		coded MR and IR files
Author:				Rebecca Rosenberg, adapted from code written by Shireen Assaf			
Date last modified: Aug 16, 2023 by Shireen Assaf 


Notes: The code below show how the variables were coded for the MR and IR files.
Only six countries were coded for the IR file (see readme).
For comparison between men and women, the MR and IR files should be appended. 
*****************************************************************************************************/

* path to DHS data
global Datafilepath "C:\DHSdata"

* Selected countries with at least 3 DHS's since 2000 and a Men's survey
global mrdata "AMMR72FL AMMR61FL AMMR52FL BDMR61FL BDMR51FL BDMR4JFL BJMR71FL BJMR61FL BJMR51FL KHMR81FL KHMR72FL KHMR61FL CMMR71FL CMMR61FL CMMR44FL DRMR61FL DRMR52FL DRMR4BFL ETMR71FL ETMR61FL ETMR51FL GHMR71FL GHMR5AFL GHMR4BFL GNMR71FL GNMR62FL GNMR52FL HTMR70FL HTMR61FL HTMR52FL IAMR7EFL IAMR74FL IAMR52FL IDMR71FL IDMR63FL IDMR51FL KEMR8AFL KEMR72FL KEMR52FL LSMR71FL LSMR61FL LSMR41FL MDMR81FL MDMR51FL MDMR42FL MWMR7AFL MWMR61FL MWMR4EFL MLMR7HFL MLMR6AFL MLMR53FL NMMR61FL NMMR51FL NMMR41FL NPMR81FL NPMR7HFL NPMR61FL NGMR7AFL NGMR6AFL NGMR52FL RWMR81FL RWMR70FL RWMR61FL SNMR8BFL SNMR70FL SNMR61FL SLMR7AFL SLMR61FL SLMR51FL TZMR7BFL TZMR61FL TZMR4IFL UGMR7BFL UGMR60FL UGMR52FL ZMMR71FL ZMMR61FL ZMMR51FL ZWMR72FL ZWMR62FL ZWMR52FL"

* Only six countries were used to compare men and women
global irdata "ETMR71FL ETMR61FL ETMR51FL GHMR71FL GHMR5AFL GHMR4BFL IDMR71FL IDMR63FL IDMR51FL RWMR81FL RWMR70FL RWMR61FL UGMR7BFL UGMR60FL UGMR52FL ZMMR71FL ZMMR61FL ZMMR51FL"

*****************************************************************************************************
* Coding variables in Men's file

foreach c in $mrdata {
use "$Datafilepath//`c'.dta", clear

gen weight = mv005/100000

*DECISION MAKING
*binary - 1 if respondent alone should have greater say in large household purchases, otherwise 0
gen purchase=0
replace purchase=1 if mv743b==1

*IPV
*binary -  1 if yes to any wife beating justification, otherwise 0
gen goesout=0
replace goesout=1 if mv744a==1

gen neglect=0
replace neglect=1 if mv744b==1

gen argue=0
replace argue=1 if mv744c==1

gen refuse=0
replace refuse=1 if mv744d==1

gen food=0
replace food=1 if mv744e==1

gen combined_ipv=0 
replace combined_ipv=1 if goesout==1|neglect==1|argue==1|refuse==1|food==1

*SON PREFERENCE
*Ideal number of boys - Ideal number of girls
gen son_difference=mv627-mv628
replace son_difference=. if mv627==96 | mv628==96

*CONTRACEPTION
*binary - 1 if men agree that contraception is woman's business and men should not worry
gen w_business=0
replace w_business=1 if mv3b25a==1

*SEXUAL AUTONOMY
*binary - 1 if beating justified if wife refuses sex, otherwise 0 (use of condom if husband has sti v822 is missing from many surveys)
gen refuse_sex=0
replace refuse_sex=1 if v744d==1

*CONTRACEPTION
gen w_business=0
replace w_business=1 if v3b25a==1

  **** Year of survey ****
		qui sum v007
		scalar year_num = r(mean)
		scalar year1=string(r(min))
		scalar year2=string(r(max))

		if (year1==year2) {
		scalar year3 = " "
		}
		else if (year1!=year2) {
		scalar year3 = "-" + substr(year2,3,4)
		}
                                             
		gen yr=year1 + year3
		
*****
*gen sex variable that is needed for appended files
gen sex=1

*rename mv variables to match the v variables, this is needed before appending files
rename mv* v*
		
save "`c'coded.dta", replace

}

*****************************************************************************************************
* Coding variables in Women's file
* Only six countries were used for comparing men and women, see irdata list

foreach c in $irdata {

use "$Datafilepath//`c'.dta", clear
	
gen wt=v005/1000000
	
gen sex=2
	
*check strate variable for the country
gen strata=v023

label define yesno 0"no" 1"yes"

*DECISION MAKING
*binary - 1 if men should have final say in large household purchase
gen purchase=0
replace purchase=1 if v743b==1

*IPV
*binary -  1 if yes to any wife beating justification, otherwise 0
gen combined_ipv=0
replace combined_ipv=1 if v744a==1|v744b==1|v744c==1|v744d==1|v744e==1
*replace beating=. if married==0

*SON PREFERENCE
*ideal number of boys - ideal number of girls
gen son_difference=v627-v628
replace son_difference=. if v627==96 | v628==96

*SEXUAL AUTONOMY
*binary - 1 if beating justified if wife refuses sex, otherwise 0 (use of condom if husband has sti v822 is missing from many surveys)
gen refuse_sex=0
replace refuse_sex=1 if v744d==1

*CONTRACEPTION
*doesn't exist in women's recode, so make a blank variable
gen w_business=0

  **** Year of survey ****
qui sum v007
scalar year_num = r(mean)
scalar year1=string(r(min))
scalar year2=string(r(max))

if (year1==year2) {
	scalar year3 = " "
	}
else if (year1!=year2) {
	scalar year3 = "-" + substr(year2,3,4)
	}
                                             
gen yr=year1 + year3
  
save "`c'coded.dta", replace

 }

*****************************************************************************************************
