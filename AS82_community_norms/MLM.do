

/*****************************************************************************************************
Program: 			MLM.do
Purpose: 			Conduct multilevel analysis using multilevel weights
Author:				Sara Riese. 	
Date last modified: Jan 31, 2022 by Sara Riese to export reg results
					Feb 10, 2022 by Sara Riese to add young/older reference groups
					March 1, 2022 by Sara Riese to revise individual level covariates in the model
					May 17, 2022 by Sara Riese to add standardized variables at community level for ease of interpretation
				
*****************************************************************************************************/

local indvars_f "wyoung i.v190 ceb fp_messages wideal i.desire i.decision swpatt swpsoc swpdec"
local indvars_m "myoung i.medu i.mv190 ceb fp_messages mideal i.desire i.promis"
local indvars_f_agegr "i.v190 ceb fp_messages wideal i.desire i.decision swpatt swpsoc swpdec"
local indvars_m_agegr "i.medu i.mv190 ceb fp_messages mideal i.desire i.promis"


local comvars_all "collect_urbrur collect_distance" 
local comvars_f "collect_wideal collect_decision collect_swpatt collect_swpsoc collect_swpdec collect_medu collect_promis" 
local comvars_f_young "collect_wyoungideal collect_wyoungdecision collect_wyoungswpatt collect_wyoungswpsoc collect_wyoungswpdec collect_myoungedu  collect_myoungpromis"
local comvars_f_older "collect_wolderideal collect_wolderdecision collect_wolderswpatt collect_wolderswpsoc collect_wolderswpdec collect_molderedu collect_molderpromis"

*For analysis: local comvars_m "collect_mideal collect_decision collect_swpatt collect_swpsoc collect_swpdec collect_medu collect_promis"
*Use below local for creating std vars
local comvars_m "collect_mideal"
*For analysis: local comvars_magegr "collect_myoungideal collect_molderideal collect_wolderdecision collect_wyoungdecision collect_wyoungswpatt collect_wolderswpatt collect_wyoungswpsoc collect_wolderswpsoc collect_wyoungswpdec collect_wolderswpdec collect_myoungedu collect_molderedu collect_myoungpromis collect_molderpromis" 
*Use below local for creating std vars
local comvars_m_young "collect_myoungideal"
local comvars_m_older "collect_molderideal"

local stdcomvars_all "collect_urbrur collect_distance" 
local stdcomvars_f "stdcollect_wideal stdcollect_decision stdcollect_swpatt stdcollect_swpsoc stdcollect_swpdec stdcollect_medu stdcollect_promis" 
local stdcomvars_f_young "stdcollect_wyoungideal stdcollect_wyoungdecision stdcollect_wyoungswpatt stdcollect_wyoungswpsoc stdcollect_wyoungswpdec  stdcollect_myoungedu stdcollect_myoungpromis"
local stdcomvars_f_older "stdcollect_wolderideal stdcollect_wolderdecision stdcollect_wolderswpatt stdcollect_wolderswpsoc stdcollect_wolderswpdec stdcollect_molderedu stdcollect_molderpromis"

local stdcomvars_m "stdcollect_mideal stdcollect_decision stdcollect_swpatt stdcollect_swpsoc stdcollect_swpdec stdcollect_medu stdcollect_promis"
local stdcomvars_m_young "stdcollect_myoungideal stdcollect_wyoungdecision stdcollect_wyoungswpatt stdcollect_wyoungswpsoc stdcollect_wyoungswpdec stdcollect_myoungedu stdcollect_myoungpromis" 
local stdcomvars_m_older " stdcollect_molderideal stdcollect_wolderdecision stdcollect_wolderswpatt stdcollect_wolderswpsoc stdcollect_wolderswpdec stdcollect_molderedu stdcollect_molderpromis" 

local combgraph_coefs "stdcollect_urbrur stdcollect_distance stdcollect_wideal stdcollect_decision stdcollect_swpatt stdcollect_swpsoc stdcollect_swpdec stdcollect_medu stdcollect_promis stdcollect_mideal" 


foreach c in $irdata {

local cn=substr("`c'",1,2)

use "$Codedfilepath//`cn'coded.dta", clear
*use "$Codedfilepath//ZMcoded.dta", clear

*local cn="ZM"

*Want to use some standardized variables for ease of interpretation
local complete_comvars "`comvars_all' `comvars_f' `comvars_f_young' `comvars_f_older' `comvars_m' `comvars_m_young' `comvars_m_older' "
foreach list in `complete_comvars' {
	foreach c in `list' {
		egen std`c' = std(`c')
	}
}


/*
foreach c in `comvars_all' {
	egen std`c' = std(`c')
}

foreach c in `comvars_f' {
	egen std`c' = std(`c')
}

foreach c in `comvars_f_young' {
	egen std`c' = std(`c')
}

foreach c in `comvars_f_older' {
	egen std`c' = std(`c')
}

foreach c in `comvars_m' {
	egen std`c' = std(`c')
}

foreach c in `comvars_m_young' {
	egen std`c' = std(`c')
}

foreach c in `comvars_m_older' {
	egen std`c' = std(`c')
}
*/

/*Code for sensitivity analysis to DROP any clusters less than 10
sort v001
by v001: gen Fclust = _N
sort mv001
by mv001: gen Mclust = _N
drop if Fclust < 10
drop if Mclust < 10

*/

*Test null model and calculate ICC (among all women)

svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)
svy: melogit modfp || v001:
estat icc
estadd scalar icc_w = r(icc2)

*Among younger women
svy, subpop(wyoung): melogit modfp || v001:
estat icc
estadd scalar icc_yw = r(icc2)


*Among older women
svy, subpop(wolder): melogit modfp || v001:
estat icc
estadd scalar icc_yw = r(icc2)


*Test null model and calculate ICC (among men)
svyset mv001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)
svy: melogit modfp || mv001:
estat icc
estadd scalar icc_m = r(icc2)


*Among younger men
svy, subpop(myoung): melogit modfp || mv001:
estat icc
estadd scalar icc_yw = r(icc2)

*Among older men
svy, subpop(molder): melogit modfp || mv001:
estat icc
estadd scalar icc_yw = r(icc2)

/************************************************************************
**Individual level variables only model
*************************************************************************/

svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)

*All women
svy, subpop(female): melogit modfp `indvars_f' || v001: , or
estat icc
estadd scalar icc_w = r(icc2)

*Younger women
svy, subpop(wyoung): melogit modfp `indvars_f_agegr'   || v001: , or
estat icc
estadd scalar icc_yw = r(icc2)

*Older women
svy, subpop(wolder): melogit modfp `indvars_f_agegr' || v001: , or
estat icc
estadd scalar icc_ow = r(icc2)

*Men
svyset mv001, weight(wt2) strata(mv022) , singleunit(centered) || _n, weight(wt1)
svy, subpop(male): melogit modfp `indvars_m' || mv001: ,or
estat icc
estadd scalar icc_m = r(icc2)

*Younger men
svy, subpop(myoung): melogit modfp `indvars_m_agegr' || mv001: ,or
estat icc
estadd scalar icc_ym = r(icc2)


*Older men
svy, subpop(molder): melogit modfp `indvars_m_agegr'   || mv001: ,or
estat icc
estadd scalar icc_om = r(icc2)

/************************************************************************
**Community level variables only model
*************************************************************************/

svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)

*All women
svy, subpop(female): melogit modfp `stdcomvars_all' `stdcomvars_f' || v001: , or
estat icc
estadd scalar icc_w = r(icc2)


*Younger women
svy, subpop(wyoung): melogit modfp `stdcomvars_all' `stdcomvars_f_young' `stdcomvars_f_older'  || v001: , or
estat icc
estadd scalar icc_yw = r(icc2)

*Older women
svy, subpop(wolder): melogit modfp `stdcomvars_all' `stdcomvars_f_young' `stdcomvars_f_older' || v001: , or
estat icc
estadd scalar icc_ow = r(icc2)

*Men
svyset mv001, weight(wt2) strata(mv022) , singleunit(centered) || _n, weight(wt1)
svy, subpop(male): melogit modfp `comvars_all' `stdcomvars_m' || mv001: ,or
estat icc
estadd scalar icc_m = r(icc2)


*Younger men
svy, subpop(myoung): melogit modfp `stdcomvars_all' `stdcomvars_m_young' `stdcomvars_m_older' || mv001: ,or
estat icc
estadd scalar icc_ym = r(icc2)


*Older men
svy, subpop(molder): melogit modfp `stdcomvars_all' `stdcomvars_m_young' `stdcomvars_m_older'  || mv001: ,or
estat icc
estadd scalar icc_om = r(icc2)

************************************************************************
**Community and individual level variables (Full model - all modern methods)
*************************************************************************/
*Women
svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)
svy, subpop(female): melogit modfp `indvars_f' `stdcomvars_all' `stdcomvars_f'  || v001: , or
est store f_`cn'
estat icc
estadd scalar icc = r(icc2)
gen in_m3_`cn'=e(sample)


*Men
svyset mv001, weight(wt2) strata(mv022) , singleunit(centered) || _n, weight(wt1)
svy, subpop(male): melogit modfp `indvars_m' `stdcomvars_all' `stdcomvars_m' || mv001: ,or
est store m_`cn'
estat icc
estadd scalar icc = r(icc2)

****************************************************************************************
**Community and individual level variables (Full model with young/older reference groups)
*****************************************************************************************/
*
*Younger women
svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)
svy, subpop(wyoung): melogit modfp `indvars_f_agegr' `stdcomvars_all' `stdcomvars_f_young' `stdcomvars_f_older'  || v001: , or
*svy, subpop(wyoung): melogit modfp `indvars_f_agegr' `stdcomvars_all' `stdcomvars_f_young'  || v001: , or
est store youngf_`cn'
estat icc
estadd scalar icc = r(icc2)

*Older women
svy, subpop(wolder): melogit modfp `indvars_f_agegr' `stdcomvars_all' `stdcomvars_f_young' `stdcomvars_f_older'  || v001: , or
*svy, subpop(wolder): melogit modfp `indvars_f_agegr' `stdcomvars_all' `stdcomvars_f_older'  || v001: , or
est store olderf_`cn'
estat icc
estadd scalar icc = r(icc2)

*Younger men
svyset mv001, weight(wt2) strata(mv022) , singleunit(centered) || _n, weight(wt1)
*svy, subpop(myoung): melogit modfp `indvars_m_agegr' `stdcomvars_all' `stdcomvars_m_young' || mv001: ,or
svy, subpop(myoung): melogit modfp `indvars_m_agegr' `stdcomvars_all' `stdcomvars_m_young' `stdcomvars_m_older'  || mv001: ,or
est store youngm_`cn'
estat icc
estadd scalar icc = r(icc2)

*Older men
svy, subpop(molder): melogit modfp `indvars_m_agegr' `stdcomvars_all' `stdcomvars_m_young' `stdcomvars_m_older'  || mv001: ,or
*svy, subpop(molder): melogit modfp `indvars_m_agegr' `stdcomvars_all' `stdcomvars_m_older'  || mv001: ,or
est store olderm_`cn'
estat icc
estadd scalar icc = r(icc2)

}