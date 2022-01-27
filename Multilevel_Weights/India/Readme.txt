
Purpose: approximation of level-weight of the India NFHS-4
Date: Jan 24, 2022

The purpose of this section is to support users regarding the approximation of level-weight of the India NFHS-4. 
The approximation follows the methods explained in the MR27. 

The final report of NFHS-4 only includes a table for number of HHs by states but does not include the table for number of clusters in the census frame. 
Such data is crucial for the approximation as the average number of households per cluster by sampling strata is required for the approximation. 

To overcome this problem, the user needs to deal with the urban and rural clusters separately and using two different approaches as follows:

1-	For urban clusters: we compiled a list of districts with number of CEBs and the average size of clusters. 
	The list can be found here (the excel sheet: EA average size_Urban.xlsx)

2-	For rural clusters: the user can obtain data about the number of villages and their size (number of households) from the Census of India. 
	This page includes the data in separate excel files by states and districts https://censusindia.gov.in/pca/cdb_pca_census/cd_block.html. 
	The user needs to download all the excel files and use this Stata code (the file: India_NFHS4_compile_rural_HHsize.do) to compile the needed data for rural clusters.


