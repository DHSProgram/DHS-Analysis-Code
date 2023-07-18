/********************************************************************************************************************************************
Program: 			analysis.do
Purpose: 			analyze data : descriptive and survival analysis
Data inputs: 		coded data produced from the codevars.do 
Data outputs:		results
Author:				Lindsay Mallick	
Date last modified: June 21, 2023 by Lindsay Mallick	
******************************************************************************************************************************************/

cd "~\coded data"

*create global for two different sets of surveys 
	global cn "AL AM JO MV TJ ID NP PK PH TL AO BJ BU ET MW SN ZA TZ UG ZW HT" 
	global cnall "AL AM EG JO MV TJ BD KH IA ID MM NP PK PH TL AO BJ BU TD ET GH KE LS MW SN ZA TZ UG ZW GU HT " // 

*Descriptive analysis	
*loop through countries	
	foreach d in $cnall {
	*open code data file 
	use `d'.dta, clear

*survey set and set scalar for country
	svyset v021 [pw=wt], strata(strata) singleunit(centered)
	
*Figure 1/Appendix Table 1 - distribution of time to initation (categorical)
	estpost svy: ta bfcat , per 

*Table 2 -  Mean and median times to initation by mode of birth
*mean time
	svy: poisson bfcont
	forvalues i = 0/2 {
	svy: poisson bfcont if vagfac == `i'
	}
*median time 		
	_pctile bfcont [pw=wt] , p(50)	
	_pctile bfcont [pw=wt] if vagfac==0, p(50)	
	_pctile bfcont [pw=wt] if vagfac==1, p(50)	
	_pctile bfcont [pw=wt] if vagfac==2, p(50)	

*Appendix Table 2 - background characteristics
	tab1 vagfac skin2skin pnc1hr anc4 bsize sex parity married media employ edu wealth v025 if bfcont <109 [iw=wt], m	
}

*******************************************************
****** Survival analysis ******
*******************************************************

* analyzed data from the 21 of the 31 recent DHS surveys completed (as of September 2019) 
	*that included a question about skin-to-skin contact	
	
*open code data file 
	foreach d in SN { //$cn
		use `d'.dta, clear
	
*survey set and set scalar for country
	svyset v021 [pw=wt], strata(strata) singleunit(centered)
	
/*set up data (stset) for survival	
	*failure is considered when breastfeeding was initiated within 5 days
			Where 0 if initiation not acheived in less than 5 days and
			  1 if initiation occured within the first 4 days
	*truncation occurs among those who started breastfeeding after 4 days		  
*/			
	
*generate failure variable
	gen bffail = 0 if m4!=94
	replace bffail = 1 if bfcont <109 & bfcont!=. 
	
*stset data
	stset bfcont  [pw=wt], failure(bffail) exit(bfcont==108)

*test proportionality: first run cox model
	stcox ib1.vagfac i.skin2skin i.v025 i.wealth i.edu i.employ  ///
		i.media ib1.married i.parity i.sex ib1.anc4 i.pnc1hr i.bsize i.v024 
		
	estat phtest, detail

*not proportional hazards, so use accelerated failure time model, which does not require and assumption of proportional hazards	
	*examine goodness of fit of different distributions (e.g., Weibull, log-normal, and log-logistic)
	streg ib1.vagfac i.skin2skin i.pnc1hr ib1.anc4 i.bsize i.sex i.parity  ///
	ib1.married i.media  i.employ i.edu i.wealth  i.v025  i.v024 , d(weibull) 	time tr
	
	estat ic	

*select model with lowest AIC and run with svy: 
	svy: streg ib1.vagfac i.skin2skin i.pnc1hr b1.anc4 i.bsize i.sex i.parity ///
	ib1.married i.media i.employ i.edu i.wealth  i.v025 i.v024 , d(loglogistic) tr
	
}	
