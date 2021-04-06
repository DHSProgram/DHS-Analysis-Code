/*******************************************************************************************************************************
Purpose: 				Generate strata variable for each DHS survey
Data outputs:			any type of file will work (i.e. IR, BR, KR, MR, HR, PR) and a strata variable will be produced. 
						This code does not check MIS, AIS, and interim surveys.
						
Author: 				Shireen Assaf, November 2, 2020 and modifed from a program by Kerry MacQuarrie
Date last modified:		March 4, 2021 by Shireen Assaf to correct strata for BJ6, SZ5, RW6, and LB5 (DHS) 
Notes: 					
						For most surveys and especially recent surveys, the strata variable is v022. 
						Exceptions to this will be added. 
						For several surveys, especially recent sureys, v022 and v023 are the same. 
						For updates and any new surveys, just need to check if strata is different from v022. 
*******************************************************************************************************************************/
cap drop strata*

gen strata=.
cap replace strata=v022
cap replace strata=hv022
cap replace strata=mv022

cap egen strata_v023=group(v023 v025)
cap egen strata_v023=group(mv023 mv025)
cap egen strata_v023=group(hv023 hv025)

cap egen strata_v024=group(v024 v025)
cap egen strata_v024=group(mv024 mv025)
cap egen strata_v024=group(hv024 hv025)

cap gen phase=v000
cap gen phase=mv000
cap gen phase=hv000 

cap gen year=v007
cap gen year=mv007
cap gen year=hv007 

**** Exceptions ****

if phase=="AL5" | phase=="AM4" | phase=="AZ5" | phase=="BD5" | phase=="BJ4" | phase=="BF3" | phase=="CM4" | phase=="KM6" | phase=="CI3" | phase=="EG2" | phase=="ET4" | phase=="GA3" | phase=="GH3"| phase=="GN3"| phase=="ID2" | phase=="ID3" | phase=="KK3" | phase=="KE2" | phase=="KE3"| phase=="KY3" | phase=="LB6" | phase=="MD3" | phase=="MD4" | phase=="MW2" | phase=="ML3" | phase=="MB4" | phase=="MZ3" | phase=="NM4" | phase=="NG3"| phase=="NG4" | phase=="PE5"  | phase=="SN2" | phase=="TZ2" | phase=="TR3"| phase=="TR4" | phase=="TR6" | phase=="UG3" | phase=="UZ3"  | phase=="ZM3" | phase=="ZW3" | phase=="ZW4" {
	cap replace strata = v023
	cap replace strata = mv023
	cap replace strata = hv023
}

if phase=="BD4" | phase=="BJ3" | phase=="BJ6" | phase=="CF3" | phase=="TD4" | phase=="CO2" | phase=="CO3" | phase=="KM3" | phase=="CG5" | phase=="CD5" | phase=="DR3"  | phase=="DR4"  | phase=="DR5" | phase=="EG3" | phase=="EG4" | phase=="GH2" | phase=="GY4" | phase=="HT4" | phase=="HT5" | phase=="IA2" | phase=="IA3"  | phase=="ID4" | phase=="ID5" | phase=="JO2" | phase=="JO3" | phase=="LS4" | phase=="LS5" | phase=="MD2" | phase=="MA2" | phase=="NM2" | phase=="NM5" | phase=="NI2" | phase=="NI3" | phase=="NG2" | phase=="PK2" | phase=="PY2"  | phase=="PE4" | phase=="PH5" | phase=="RW2" | phase=="ST5" | phase=="SN4"| phase=="SZ5"| phase=="ZA3" | phase=="TZ3"  | phase=="TG3" | phase=="TR5" | phase=="UG4"| phase=="UG5" | phase=="UG6" | phase=="UA5" | phase=="VNT" | phase=="UA5" | phase=="YE2" | phase=="ZM2" | phase=="ZM4" | phase=="ZW" | phase=="ZW5" {
	cap replace strata = strata_v024
}

if phase =="BD3" | phase=="BO4" | phase=="BR2" | phase=="BR3" | phase=="BF4" | phase=="BR2" | phase=="DR2"  | phase=="GH4" | phase=="GU3" | phase=="GN4" | phase=="HN5" | phase=="JO5" | phase=="KE4" | phase=="MW4" | phase=="ML4"| phase=="ML5" | phase=="MA4" | phase=="MZ4" | phase=="NP4"| phase=="NP5"| phase=="NP6" | phase=="NC3"| phase=="NC4" | phase=="NI5" | phase=="PK5" | phase=="PK6" | phase=="PE2" | phase=="PE3" | phase=="PH2" | phase=="PH3"| phase=="PH4" | phase=="RW4" | phase=="RW6" | phase=="TR2" {
	cap replace strata = strata_v023
}

cap replace strata =  v023 if (phase =="BD3" & (year==99 | year==2000 | year==0))
cap replace strata = mv023 if (phase =="BD3" & (year==99 | year==2000 | year==0))
cap replace strata = hv023 if (phase =="BD3" & (year==99 | year==2000 | year==0))

if phase=="BO" & year==89 {
	*no MR or HR files
	cap egen stratabo = group(sdepto v102)
	replace strata = stratabo
}

cap replace strata = strata_v023 if (phase=="BO3" & (year==93 | year==94))

if phase=="BR" | phase=="BF2" | phase=="BU" | phase=="CO" | phase=="DR"  | phase=="EC" | phase=="ES" | phase=="EG" | phase=="GH" | phase=="GU" | phase=="ID" | phase=="KE" | phase=="LB" | phase=="LK" | phase=="ML" | phase=="MX" | phase=="MA" | phase=="OS" | phase=="PE" | phase=="SD" | phase=="SN" | phase=="TH" | phase=="TT" | phase=="TG"| phase=="TN" | phase=="UG" {
	cap egen stratax = group(v101 v102)
	cap egen stratax = group(mv101 mv102)
	cap egen stratax = group(hv024 hv025)
	replace strata = stratax
}

cap replace strata = sstratum if  phase=="KH4"
cap replace strata = shstratu if  phase=="KH4" // no MR file for this survey
cap replace strata = strata_v024 if (phase=="KH5" & (year==2005 | year==2006))

cap replace strata = sstrate  if phase=="CM2" | phase=="CM3"
cap replace strata = smstrat  if phase=="CM3" // MR file for 1991 survey used CM3 instead of CM2, so this works for both 1991 and 1998 surveys
cap replace strata = shstrate  if phase=="CM2" | phase=="CM3"

cap replace strata = strata_v023 if (phase=="CO4" & year==2000)
cap replace strata = strata_v024 if (phase=="CO4" & (year==2004 | year==2005))

if phase=="HT3" {
	cap egen stratad = group(sdepart v025)
	cap egen stratad = group(smdepart mv025)
	cap egen stratad = group(shdepart hv025)
	replace strata = stratad
}

if phase=="LB5" & year<2008 {
drop strata
cap egen strata=group(scty v025 v024)
cap egen strata=group(shcty hv025 hv024)
cap egen strata=group(smcty mv025 mv024)
}

if phase=="NP3" {
	cap egen stratanp = group(secozone v024)
	cap egen stratanp = group(shez hv024)
	replace strata = stratanp
}

cap replace strata = strata_v024 if (phase=="SN2" (year==92 | year==93))

**** END ****













