<!-- rmarkdown v1 -->
  
  # Project 7
  
  ### Created by Asif Chowdhury, Justin Owens, Jash Choraria
  
  his is the seventh project for CS 329E Data Visualization. 
The data we will analyze comes from the Center for Medicare and Medicaid Services website. 
The goals for this project is to successfully use the blend function on Tableau to blend two data sets and create interesting visualizations. The data sets we have chose are tobacco usage in different states and medicaid payments across states.

In order to reproduce this project, please follow the following instructions.

## Step 1

#### Load the correct packages into R

Use the following code to load the correct packages into RStudio.
It might be necessary to install them manually if they have never been installed on your machince prior to this experience.

```r
source("../00 Doc/Packages.R", echo = TRUE)
```

```
## 
## > require(plyr)
## 
## > require(dplyr)
## 
## > require(ggplot2)
## 
## > require(knitr)
## 
## > require(reshape2)
## 
## > require(RCurl)
## 
## > require(grid)
## 
## > require(plyr)
## 
## > require(gplots)
## 
## > require(tidyr)
## 
## > require(jsonlite)
## 
## > require(ggthemes)
```

## Step 2

#### Clean up the CSV file

Sometimes, the data in a CSV file is incompatible with Oracle. In this situation, we would want to clean up the data. 
Make sure the CSV file is in the appropriate place, as defined by the following code, and modify the working directory in line 1 for your machine. Then run the code in order to get rid of special characters and set data types that are compatible with Oracle. 
You should now have a new CSV File with the reformatted data. 

Due to the complexity in calling directories, we will display the code here, but not run it. This HTML is not dependent on the modified CSV, but if you would like to reproduce our modified CSV, follow the code found in the ReformattingData.R file in the 00 Doc folder or it's representation here.


```r
setwd(**PLACE WORKING DIRECTORY PATH FOR 00 DOC FOLDER HERE**)

getfile_path <- "tobaccousage.csv"
measures <- c("Order, State", "X12_or_Older_Estimate", "X12_or_Older_95_CI_Lower", "12_or_Older_95_CI_Upper_X12_17_Estimate", "X12_17_95_CI_Lower", "X12_17_95_CI_Upper", "X18_25_Estimate", "X18_25_95_CI_Lower", "X18_25_95_CI_Upper", "X26_or_Older_Estimate", "X26_or_Older_95_CI_Lower", "X26_or_Older_95_CI_Upper")

df <- read.csv(file_path, stringsAsFactors = FALSE)

names(df) <- gsub("\\.+", "_", names(df))

# Get rid of special characters in each column.
for(n in names(df)) {
df[n] <- data.frame(lapply(df[n], gsub, pattern="[^ -~]",replacement= ""))
}

dimensions <- setdiff(names(df), measures)
for(d in dimensions) {
# Get rid of " and ' in dimensions.
df[d] <- data.frame(lapply(df[d], gsub, pattern="[\"']",replacement= ""))
# Change & to and in dimensions.
df[d] <- data.frame(lapply(df[d], gsub, pattern="&",replacement= " and "))
# Change : to ; in dimensions.
df[d] <- data.frame(lapply(df[d], gsub, pattern=":",replacement= ";"))
}

library(lubridate)

# The following is an example of dealing with special cases like making state abbreviations be all upper case.
# df["State"] <- data.frame(lapply(df["State"], toupper))

# Get rid of all characters in measures except for numbers, the - sign, and period.
for(m in measures) {
  df[m] <- data.frame(lapply(df[m], gsub, pattern="[^--.,0-9]",replacement= ""))
}

write.csv(df, paste(gsub(".csv", "", file_path), ".reformatted.csv", sep=""), row.names=FALSE)

tableName <- gsub(" +", "_", gsub("[^A-z, 0-9, ]", "", gsub(".csv", "", file_path)))
sql <- paste("CREATE TABLE", tableName, "(\n-- Change table_name to the table name you want.\n")
for(d in dimensions) {
  sql <- paste(sql, paste(d, "varchar2(4000),\n"))
}
for(m in measures) {
  if(m != tail(measures, n=1)) sql <- paste(sql, paste(m, "number(38,4),\n"))
  else sql <- paste(sql, paste(m, "number(38,4)\n"))
}
sql <- paste(sql, ");")
cat(sql)
```

## Step 3

#### Import and retrieve the data from the Oracle cloud server.

After cleaning up the data, it should be fairly simple to import the table into the Oracle cloud. After doing so, use the following code to create a data frame in R using the newly imported SQL table. This will be useful mostly for when we start using Tableau to create crosstabs.

The tobaccousage.csv data frame has the following 12 columns: "Order, State", "X12_or_Older_Estimate", "X12_or_Older_95_CI_Lower", "12_or_Older_95_CI_Upper_X12_17_Estimate", "X12_17_95_CI_Lower", "X12_17_95_CI_Upper", "X18_25_Estimate", "X18_25_95_CI_Lower", "X18_25_95_CI_Upper", "X26_or_Older_Estimate", "X26_or_Older_95_CI_Lower", "X26_or_Older_95_CI_Upper"



```r
source("../00 Doc/FED_CON_ZIPCODE.R", echo = TRUE)
```

```
## 
## > FED_CON_ZIPCODE <- data.frame(fromJSON(getURL(URLencode("129.152.144.84:5001/rest/native/?query=\"select * from FED_CON_ZIPCODE\""), 
## +     httphead .... [TRUNCATED] 
## 
## > head(FED_CON_ZIPCODE)
##          ID ZIPCODE GENDER AMOUNT AVERAGEINCOME AVERAGEWAGES AVERAGETAXES
## 1 218639382   78209      N   1000     351933606    159713750     11749179
## 2 218639385   78212      U   1000     154787985     67019780      3694433
## 3 218639386   78209      M    250     351933606    159713750     11749179
## 4 218639387   78212      M    500     154787985     67019780      3694433
## 5 218639388   78230      F   1000     211789256    130087792      6535803
## 6 218639389   78255      M    500      54910212     40989637      2563669
##   AVERAGEINCOMETAX
## 1         68177172
## 2         29441626
## 3         68177172
## 4         29441626
## 5         35654807
## 6          8223123
```

## Step 4
#### Import Data for Tableau Blending.

To blend the data sets, we must first import the data to tableau. 
First, we need to either import the reformatted CSV file directly into Oracle (easiest), or pull the information from the cloud.
  
In order to import the CSV file, follow these steps:  
  
  1) Open Tableau.

2) Click "Connect Data" on the top left corner and then Connect to "Text File" underneath the Connect heading on the left side of the screen.

![This is the link you need to click.](../02 Tableau Workbook/ConnectText.PNG)

3) On the screen that appears, locate the reformatted CSV file from Step 2. For this project, the file should be in the 00 Doc folder.

4) On the following screen, click the tab at the bottom left of the screen that says "Sheet 1". This will take you to the main workbook.

![This is the tab you need to click.](../02 Tableau Workbook/Sheet1.PNG)

Alternatively, you can retrieve the table from the cloud:
  
  1) Open Tableau.

2) Click "Connect Data" on the top left corner and then Connect to "Oracle" underneath the Connect heading on the left side of the screen.

![This is the link you need to click.](../02 Tableau Workbook/ConnectOracle.PNG)

3) In the screen that appears, enter the required information. For our project, the information is:
  
  Server: 129.152.144.84

Service: ORCL.usuniversi01134.oraclecloud.internal

Port: 1521

Username: C##cs329e_ac52722

Password: orcl_ac52722

4) On the following screen, click the tab at the bottom left of the screen that says "Sheet 1". This will take you to the main workbook.

![This is the tab you need to click.](../02 Tableau Workbook/Sheet1.PNG)

## Step 5

####Blend the two data sets on Tableau.

Now that the data is uploaded into the oracle cloud properly, we can now start 'blending' the two data sets on Tableau. 
To blend the two data sets, we connected the two sources of data using an inner join as shown below, where in we joint based on the states. 

The visual representations created from this are shown in step 5.

IMAGE OF BELNDING (BLENDING.PNG) comes her e

##Step 6

#### Differnt sybmol maps and tables can be created using the Tableau tools available

Since the data was blended according to state, it is most advisable to use symbol maps to help show the distinction in states and the different in tobacco usage, medicaid payments, discharges and covered costs across the different states. The maps can be recreated by dragging the correct Dimensions and Measures to the proper places as decribed in the following pictures of the completed visualizations. In all the symbol maps it is important to keep Longitude as Columns and Latitudes as Row.

For each visualization, be sure to click on the new sheet button so that you can save each of them.

The description of the visualzation is below its respective picture along with an explanation on how to create it.

**Average Covered Charges vs. State:**
  
  !AVG COVERED CHARGES VS STATE PICTURE GOES HERE

This visualizations shows how the average amount of charges covered by the insurance company in that state.

To recreate the above visualization, drag stateabbrev (from the dimension list) over the COLOR mark. Then drag Total Covered Charges (from the measures list) over the SIZE mark and LABEL mark. Ensure the change the measure of Total Covered Charges from SUM to AVG to ensure the average is provided. 

From the visual map that shows the average amounts paid by the insurance companies in Alaska, California and Delaware, the highest insurance coverage is in California (at $67,509) while Delaware is almost $40,000 less than California. Alaska falls in between California and Delaware with $40,349.

**Average Total Payments vs. State:**
  
  !AVG TOTAL PAYMENT VS STATE PICTURE GOES HERE

This visualizations shows how the average amount of total payments made by each patient across that state.
To recreate the above visualization, drag stateabbrev (from the dimension list) over the COLOR mark. Then drag Total Payments (from the Measures list) over the SIZE mark and LABEL mark. Ensure the change the measure of Total Payments from SUM to AVG to ensure the average is provided. 

Analyzing the above visual representation of the average total payment made by patients across the state, it is suprising to see that there is a far smaller gap between the highest average total payments (Alaska at $14,572) and the lowest (Delaware ate $10,360). What is interesting to note is that Alaska has far lower covered charges compared to California however, California residents pay lesser than those in Alaska.


**Average Discharge vs. State:**
  
  !AVG DISCHARGE VS STATE PICTURE GOES HERE

This visualizations shows how the average discharge across the states.

To recreate the above visualization, drag stateabbrev (from the dimension list) over the COLOR mark. Then drag Total Discharges (from the Measures list) over the SIZE mark and LABEL mark. Ensure the change the measure of Total Discharges from SUM to AVG to ensure the average is provided.

Needs analysis


**Average Medicare Payments vs. State:**
  
  ! AVG MEDICARE PAYMENTS VS STATE PICTURE GOES HERE

This visualizations shows how the average medicare payments made by the government across the sates.

To recreate the above visualization, drag stateabbrev (from the dimension list) over the COLOR mark. Then drag Total Medicare Payments (from the Measures list) over the SIZE mark and LABEL mark. Ensure the change the measure of Total Medicare Payments from SUM to AVG to ensure the average is provided.

This important visualizations shows how much the government contributes from their medicare plan towards providing health insurance to its citizens. It is interesting to see how this varies across the 3 states. The highest medicare payments are made out to those in Alaska. This could be attributed to their small per capita population hence making it easier to pay out larger amounts across the state. On average, eack California citizen received around a $1,000 less in Medicare payments. Delaware is a distant third at $,8,960. From these visualizations we can see that Delaware receives far smaller amounts in medicare payments and covered costs. However, they also have the lowest amount of average total payments between the three states.

The below visualization shows a comparison of all these four averages on one Tableau worksheet.
 
  ! COMPARING AK, CA, DE goes here

**All Payments vs State:**
  ! PAYMENTS VS STATES PNG GOES HERE

This bar graph visualzation shows how different states measure up on different aspects of health insurance payments discussed above (Covered Charges, Medicare Payments, Discharges and Patient Payments.
                                                                                                                                     
To create the above visualization first drag State and Stateabbrev into the Columns tab as shone above. Then drag, from the Measures, Total Covered Charges, Total Medicare Payments, Total Payments and Total Discharges to the Rows Tab. Ensure that you changes the Measure from SUM to AVG to obtain the average amounts of these payments across the states. Drag Provider State over the COLOR mark. Also add Provider State into the Filters.                                                                                                                                     
                                                                                                                                     
Looking at the observed states and analyzing their payments towards healthcare, one can see that California has the one higest averages for all four payments. Only Hawaii has a higher average medicare payment and only Florida has higer discharges. Americans in Alabama have the least burden on their pockets as Alabama has the lowest average patient contributions. New York, on the other hand, has high patient and medicare contributions but relatively low insurance coverage. New Jersey has the second highest insurance coverage, just behind California. Texas falls in the middle of this selection across all four forms of payments. However, it does have the second highest average discharges.
