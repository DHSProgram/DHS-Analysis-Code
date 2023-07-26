# Using Multiple Files

When analyzing DHS data, you will sometimes need to use more than one file. 
For instance, some information about the household (such as water and sanitation) can only be found in the HR or PR file. 
However, you may need this information for an analysis of women so you would need to merge to the IR file.

For more detailed explanation on merging please check the DHS Program website for this topic [Merging DHS data](https://www.dhsprogram.com/data/Merging-Datasets.cfm)

There are several types of merges that can be performed. The code for the most common types are available here.
When possible, the DHS model datasets are used.

You may also need to use multiple files when performing a multi-country analysis or trend analysis.
This involves appending or pooling two or more surveys of the same file type. 
Appending can also be used to append data from men (MR) and women (IR) which is shown in the code for merging AR to IR or MR files. 

### mergePR_toKRorIR
The code will show how to merge a PR to a KR file, and a PR to an IR file.

### mergeHR_toIR
The purpose of this code is to show an example of a many to one merge by merging the HR file to the IR file.

### mergeAR_toIRorMR
This shows how to merge the HIV test results from the AR file to the IR file or the MR file.
The code also shows how to append the merged IR and MR files to a dataset that contains both men and women.

### mergeHW
Older datasets may not contain the anthropometry variables according to the WHO reference. 
HW files are created with the WHO reference nutrition indicators that can be merged to datasets.
Here we show an example using the Bangladesh 1999-2000 survey since there is no HW file for model datasets.

### mergeWI 
Older datasets sometimes do not contain the wealth index. 
To include the wealth index, a WI file was created for these surveys. 
The Bangladesh 1999-2000 survey as an example since there is no WI file for model datasets.
The code will show how to merge the WI with an IR file and notes on how to merge with MR or PR/HR files. 

### mergeGPS
This shows how to merge an IR file with the GC (points) file in STATA
The Nigeria 2015 MIS data is used for this example, but the code should work for any DHS survey

### mergeHHhead_toIR
Construct a file that attaches the characteristics of the household head to each eligible woman in the household.

### mergeChild01_17_parents
Merging children 0-17 in the PR file with all the data about their mothers and fathers and all the data in the BR file.
This will produce three different data files. See description in the file for more detail.
The execution begins at the bottom of the do file where you need to specify your paths. 

### mergeIR_toSR
This is an example of how to produce an IRSR file, using separate IR and SR files. 
The Cote d'Ivoire 2022 survey is used since the model datasets do not have an SR file. 

### merge_loop
This code shows how to perform a merge in a loop in the case you need to perform merges for several countries. 

### pool_trends
This shows how to append two surveys from one country for a trend analysis. 
The Nigeria 2013 and 2018 DHS are used as an example for one country and code is provided to show how an append of several countries can be performed in a loop.



##### author: Shireen Assaf
##### last updated: July 26, 2023 by Shireen Assaf