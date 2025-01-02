

/*****************************************************************************************************
Program: 			RegionalMLM.do
Purpose: 			Conduct multilevel analysis using multilevel weights by region for each country
Author:				Sara Riese. 	
Date last modified: March 18, 2022 by Sara Riese 
				
*****************************************************************************************************/

local indvars_f "wyoung i.v190 ceb fp_messages wideal i.desire i.decision swpatt_cn swpsoc_cn swpdec_cn"
local indvars_m "myoung i.medu i.mv190 ceb fp_messages mideal i.desire i.promis"
local comvars_all "collect_urbrur collect_distance"
local comvars_f "collect_wideal collect_decision collect_swpatt_cn collect_swpsoc_cn collect_swpdec_cn" 
local comvars_m " collect_mideal collect_medu collect_promis"

local stdcomvars_all "collect_urbrur collect_distance"
local stdcomvars_f "stdcollect_wideal stdcollect_decision stdcollect_swpatt_cn stdcollect_swpsoc_cn stdcollect_swpdec_cn stdcollect_medu stdcollect_promis" 
local stdcomvars_m "stdcollect_mideal stdcollect_decision stdcollect_swpatt_cn stdcollect_swpsoc_cn stdcollect_swpdec_cn stdcollect_medu stdcollect_promis"

foreach c in $irdata {

local cn=substr("`c'",1,2)

use "$Codedfilepath//`cn'coded.dta", clear

*Want to use some standardized variables for ease of interpretation
local complete_comvars "`comvars_all' `comvars_f' `comvars_m' "
foreach list in `complete_comvars' {
	foreach c in `list' {
		egen std`c' = std(`c')
	}
}

svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)

levelsof v024, local(region)

tabulate v024, gen(reg_)

foreach l of local region {
	svy, subpop(reg_`l'): melogit modfp `stdcomvars_all' `stdcomvars_f' `indvars_f' || v001: , or
	estat icc
	estadd scalar icc = r(icc2)
	}

svyset mv001, weight(wt2) strata(mv022) , singleunit(centered) || _n, weight(wt1)
levelsof mv024, local(region)

tabulate mv024, gen(mreg_)

foreach l of local region {
	
	
	svy, subpop(mreg_`l'): melogit modfp `stdcomvars_all' `stdcomvars_m' `indvars_m'|| mv001: ,or
	estat icc
	estadd scalar icc = r(icc2)

	}
	
}

