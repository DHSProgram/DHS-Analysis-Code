# *****************************************************************************************************
# Program: 			mergeGPS.R
# Purpose: 			Explain how to merge an IR file with the GC (points) file in R 
# Author:				Rose Donohue, and Shireen Assaf
# Date last modified: Aug 2, 2023 by Shireen Assaf 
#
# Notes:		The Nigeria 2018 survey is used for this example.
# 					
# 					There are two sections to this code:  
# 					1. Merging the country GPS locations for each cluster to an IR file (use same logic for other file types)
# 					2. Merging the survey boundaries data at the region level, this code will also produce a map.
# 					
# 					For both sections you will need a dbf file 
# 					The cluster GPS locations can be downloaded along with the datasets from the DHS Program website. 
# 					These files have 'GE' in the name, for example NGGE7BFL
# 					
# 					To download the survey boundary data for any survey go to: https://spatialdata.dhsprogram.com/boundaries/
# 					These files will have the name sdr_subnational_boundaries
# 					
# *****************************************************************************************************/

#### Section one: Merging GPS locations at the cluster level ####

#load required packages
library(haven)
library(foreign)
library(data.table)
library(here)
here() # check your path, this is where you should have your saved datafiles

#Load the GPS data by reading the shapefile's .dbf file
gps_dat <-  read.dbf(here("Intro_DHSdata_Analysis","NGGE7BFL.dbf"))
names(gps_dat)

#Load the IR file
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","NGIR7BFL.dta"))

#Rename DHSCLUST in GE dataset to match IR dataset cluster ID variable name to allow for successful merge
setnames(gps_dat, 'DHSCLUST','v001')

#Join the GPS points (gps_dat) to the IR file
data_merged <- merge(IRdata, gps_dat, by ='v001')


# *****************************************************************************************************

#### Section two: Merging GPS locations at the region level for survey boundaries ####

#load required packages
library(haven)
library(foreign)
library(data.table)
library(dplyr)
library(labelled)   # used for Haven labelled variable creation
library(sf) # to read shape file with geometry 
library(ggplot2) # to create map
library(here)
here() # check your path, this is where you should have your saved datafiles

#Load the GPS data by reading the shapefile's .dbf file
gps_boundary <-  read_sf(here("Intro_DHSdata_Analysis","sdr_subnational_boundaries.shp"))
names(gps_boundary)

#Rename REGCODE to match IR dataset cluster ID variable name to allow for successful merge
setnames(gps_boundary, 'REGCODE','v024')

#Load the IR file
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","NGIR7BFL.dta"))

# We need to collapse the data to the region level before merging.
# Choose an indicator of interest that you would want to use in the merged data.

# For example, modern contraceptive use.
IRdata <- IRdata %>%
  mutate(mcp = ifelse(v313 == 3, 1, 0)) %>%   
  set_value_labels(mcp = c(yes = 1, no = 0)) %>%
  set_variable_labels(mcp ="Currently used any modern method") %>%
  mutate(wt = v005/1000000)

# calculate modern contraception for each region
region_means <- IRdata %>%
  group_by(v024) %>%
  summarize(mcp_mean = mean(mcp, na.rm = TRUE, weights = wt))

# compute percentages
region_means <- region_means %>%
  mutate(mcp_per=100*mcp_mean)

# Check the results
print(region_means)

# Merge the shapefile with the data frame of region means
gps_boundary <- left_join(gps_boundary, region_means, by = "v024")


# Create a map of the percentage of modern contraceptive use for each region
ggplot() +
  geom_sf(data = gps_boundary, aes(fill = mcp_per, geometry = geometry)) +
  scale_fill_continuous(low = "white", high = "blue") +
  geom_sf_label(aes(label = gps_boundary$REGNAME, geometry = gps_boundary$geometry), 
                fill=NA, label.size=0, position=position_jitter(width=0, height=.5), size = 4) +
  theme_minimal()


# *****************************************************************************************************
