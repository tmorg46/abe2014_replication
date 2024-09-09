clear
cap log close
set more off

/* This do file begins with matched samples from 16 sending countries. It appends data from each country and then creates variables necessary for the 
analysis*/

/* Start with Portugal*/
use portugal_all_final
destring immigration_year, replace
save, replace
clear

/* Append 16 matched samples. In each case, some variables are in the wrong format (e.g., string instead of numeric). We drop these if they are not necessary 
and if they will impede the appending process.*/
use france_all_final_c.dta
drop if idnum_1900==.
drop birthyear

append using ireland_all_final_c.dta
replace bpl=414 if bpl==.
drop birthyear var*

append using sweden_all_final_c.dta
replace bpl=405 if bpl==.
drop birthyear var*

append using belgium_all_final.dta
drop birthyear var*

append using wales_test.dta
drop birthyear*

append using finland_all_final.dta
drop birthyear var* sex

append using portugal_all_final.dta
drop var* birthyear sex county

append using norway_all_final_c.dta
drop birthyear var* sex county
save panel_all.dta, replace
clear

use scotland_all_final.dta
rename county county_str
drop birthyear var* sex
append using panel_all.dta
save panel_all.dta, replace

use denmark_all_final.dta
rename county county_str
drop birthyear var* sex
append using panel_all.dta
save panel_all.dta, replace

use italy_test.dta
append using panel_all.dta
save panel_all.dta, replace

use Switzerland_all_final.dta
drop birthyear sex var* county
append using panel_all.dta
save panel_all.dta, replace

use england_final_noimmigyear_c.dta
drop birthyear var* sex
destring idnum_1900, replace
append using panel_all.dta
save panel_all.dta, replace

use germany_test.dta
destring idnum_1900, replace
append using panel_all.dta
save panel_all.dta, replace

use austria_final_noimmigyear_c.dta
drop birthyear sex var*
destring idnum_1900, replace
append using panel_all.dta
save panel_all.dta, replace

use russia_final_noimmigyear_c.dta
drop if idnum_1900==""
drop birthyear
replace sex="1" if sex=="M"
destring sex, replace
destring idnum_1900, replace
drop var*
append using panel_all.dta
save panel_all.dta, replace

use US_all_final_c.dta
drop if idnum_1900==""
replace age=age+10 if year==1910
replace age=age+20 if year==1920
drop if region>29 & region<35
rename idnum_1900 idnum_1900_US
rename idnum_1910 idnum_1910_US
rename idnum_1920 idnum_1920_US
append using panel_all.dta

tab bpl

/* Create a unique ID for each individual in the dataset - rather than simply having a unique code *within* country*/
gen idnum_1900_uniq=string(idnum_1900)+"fr" if bpl==421 
replace idnum_1900_uniq=string(idnum_1900)+"be" if bpl==420
replace idnum_1900_uniq=string(idnum_1900)+"fi" if bpl==401 
replace idnum_1900_uniq=string(idnum_1900)+"po" if bpl==436 
replace idnum_1900_uniq=string(idnum_1900)+"wa" if bpl==412 
replace idnum_1900_uniq=string(idnum_1900)+"no" if bpl==404 
replace idnum_1900_uniq=string(idnum_1900)+"de" if bpl==400 
replace idnum_1900_uniq=string(idnum_1900)+"sc" if bpl==411 
replace idnum_1900_uniq=string(idnum_1900)+"gr" if bpl==433 
replace idnum_1900_uniq=string(idnum_1900)+"hu" if bpl==454 
replace idnum_1900_uniq=string(idnum_1900)+"it" if bpl==434 
replace idnum_1900_uniq=string(idnum_1900)+"sw" if bpl==426 
replace idnum_1900_uniq=string(idnum_1900)+"en" if bpl==410 
replace idnum_1900_uniq=string(idnum_1900)+"ge" if bpl==453 
replace idnum_1900_uniq=string(idnum_1900)+"au" if bpl==450 
replace idnum_1900_uniq=string(idnum_1900)+"ru" if bpl==465 
replace idnum_1900_uniq=string(idnum_1900)+"ir" if bpl==414 
replace idnum_1900_uniq=string(idnum_1900)+"sw" if bpl==405 
replace idnum_1900_uniq=idnum_1900_US+"us" if bpl<60 

/* Drop variables that were only used in the matching process and are not needed for analysis*/
drop idnum_1920* idnum_1910* occup* occstr occscore age1900 age1920 v*
drop original_name residence birthplace race gender relation bpl_pop bpl_mom webaddress name1-age1910 name6-spouse

/* Make immigration year a "person" level characteristic, rather than person-year, because missing in 1900, particularly for countries 
where sample does not begin with IPUMS. Also, reported immigration year often changes over time within person and so create "mean" of these reports*/
sort idnum_1900_uniq
destring immigration_year, replace
by idnum_1900_uniq: egen yrimmig1=mean(immigration_year)
replace yrimmig=yrimmig1 if yrimmig==.
drop yrimmig1
/* Fill in missing information on yrimmig in 1910 and 1920 for a few countries*/
sort idnum_1900_uniq year
replace yrimmig=yrimmig[_n-1] if yrimmig==. & yrimmig[_n-1]!=. & idnum_1900_uniq==idnum_1900_uniq[_n-1]
replace yrimmig=yrimmig[_n-2] if yrimmig==. & yrimmig[_n-2]!=. & idnum_1900_uniq==idnum_1900_uniq[_n-2]
/* For Wales, missing in 1900*/
replace yrimmig=yrimmig[_n+1] if yrimmig==. & yrimmig[_n+1]!=. &  idnum_1900_uniq==idnum_1900_uniq[_n+1]

/*Calculate age at immigration so later able to divide immigrants who arrived as children from those who arrived as adults*/
replace birthyear=year-age if birthyear==.
gen age_immig=yrimmig-birthyear
replace age_immig=0 if bpl<100
/* Drop cases where age at immigration = negative. A sign that something is wrong with birth year (age) or arrival year*/
drop if age_immig<0 & bpl>100

/*Generate a "years spent in US" variable for observations that did not derive from IPUMS*/
replace yrsusa1=. if yrsusa1==20
replace yrsusa1=age-age_immig if yrsusa1==.
/* Correct 34 observations with weird yrsusa1*/
replace yrsusa1=year-yrimmig if (yrsusa1!=year-yrimmig & (yrsusa1+1)!=year-yrimmig & (yrsusa1-1)!=year-yrimmig) & bpl>90
/*Create time in US intervals*/ 
drop yrsusa2
gen yrsusa2=0 if bpl<100
replace yrsusa2=1 if yrsusa1>=0 & yrsusa1<=5 & bpl>100
replace yrsusa2=2 if yrsusa1>5 & yrsusa1<=10
replace yrsusa2=3 if yrsusa1>10 & yrsusa1<=20
replace yrsusa2=4 if yrsusa1>20 & yrsusa1<=30
replace yrsusa2=5 if yrsusa1>30
xi, pref(I) i.yrsusa2

/* Keep all arrival cohorts before 1900*/
drop if yrimmig>1900 & bpl>100
/*Year of arrival cohorts*/
gen C1=(yrimmig>=1891)

/*Age polynomial*/
gen age2=age*age
gen age3=age2*age
gen age4=age3*age

/* Experience (for Hatton specification) simply = age*/
gen exp=age
/* Allow experience to have different slope before/after age 38*/
gen age35=(age>=35)
gen age35exp=age35*exp

/*Census year dummies*/
gen Y1910=(year==1910)
gen Y1920=(year==1920)

/* Birth place dummy variables*/
gen bpl1=bpl
/* Code all native born with single birth place*/
replace bpl1=0 if bpl<100
xi, pref(T) i.bpl1
/*Drop dummy for Italians -- they become base category when include two sets of fixed effects that span the set of foreign-born observations (1) years spent in 
US and (2) country of origin*/
drop Tbpl1_434

/* Merge in state identifiers*/
sort idnum_1900_uniq year
/* Drop if more than one observation with same idnum/year -- those with missing idnums*/
drop if idnum_1900_uniq==idnum_1900_uniq[_n-1] & year==year[_n-1]
drop _merge
merge idnum_1900_uniq year using states_all_ids.dta
tab _merge
rename _merge _merge1

/*First dependent variable = 1950 occupation-based earnings = "occscore_all" 
Note that for observations that derive from IPUMS, we have information on occupation score directly ("OCCSCORE" variable). For hand-coded observations, we only 
have occupation strings. To generate occupation scores for these strings, we use the full 1900, 1910 and 1920 IPUMS samples to create a correspondence between 
occupation string ("OCCSTR") and occupation score. We then use the average of these associated occupation scores (which are not always the same for a given 
occupation string, likely due to variation across coders at the IPUMS or Census) to create a occupation score associated with each occupation string. This 
process is done in a different file...*/ 
rename occscore_mean occscore_all
/* Drop if occscore = 0*/
drop if occscore_all==0

/* Second dependent variable = 1900 Cost of Living earnings = "income"*/
/* First need to merge in the 1950 occupation codes for Germany, Italy and Wales -- these are missing*/
sort idnum_1900_uniq year
merge idnum_1900_uniq year using italy_germany_wales_occs.dta, update
tab _merge
rename _merge _merge2
/* For IPUMS observations, occ1950 is provided variable. For hand-coded observations, we only have occupation string. As above, we create a correspondence 
between occupation string ("OCCSTR") and the standardized occupation 1950 code ("OCC1950"). We assign the mode of these 1950 occupation codes to each occupation 
string*/
gen occ1950_all=occ1950_mode
replace occ1950_all=occ1950 if occ1950_mode==.
sort occ1950_all
/* Once we have occupation codes for each observation, we merge in the earnings data from the 1901 Cost of Living survey collected by Haines and Preston. These 
earnings are the *mean* earnings for each occupation. The file 'occ1950_hpincomes.dta' uses our cross-walk between the 1901 occupation categories and the 1950 
occupation codes*/
merge occ1950_all using occ1950_hpincomes.dta
tab _merge
rename _merge _merge3
/*Replace farm income with average net revenue for owner-occupier farmers in the 1900 Census of Agriculture (= revenue - expenditures). This approach uses the 
method described in the online appendix to our AER (2012) paper to calculate farm net revenue. Rather than using only data from Minnesota (to reflect Norwegian 
farmers), as in our AER paper, we use Minnesota, Colorado and Massachusetts to reflect the geographic diversity of our larger sample*/ 
replace income=796 if hp==16
gen lnincome=ln(income)

/* Create urban/rural dummy according to characteristic of county of residence in 1900. Use the variable "shurb1," which is based on the Census definition where 
urban = 2,500 residents or more in town. Median of sample for this variable is roughly 40% urban. (Note: the data on urban share was already merged in to the 
panel data at the county level for each individual country)*/
sort idnum_1900_uniq
drop temp
gen temp=shurb1 if year==1900
by idnum_1900_uniq: egen shurb1_1900=max(temp)
drop temp

/* For individuals whose observations were originally derived from the 1900 IPUMS, we needed to confirm that these individuals were indeed unique by name, place
of birth and age in the full 1900 Census. The datasets "unique_panelimmigrants.dta" and "natives_clean.dta" contain an indicator variable ("yes") =1 if the 
individual is unique. We keep only these observations*/
sort idnum_1900 bpl
merge idnum_1900 bpl using unique_panelimmigrants.dta
tab _merge
drop if yes==0
drop yes _merge
sort idnum_1900_US bpl
merge idnum_1900_US bpl using natives_clean
tab _merge
drop if yes==0
drop yes

label var age_immig "Age at immigration to US, =0 for natives"
label var yrsusa2 "Years in US categories, =0 for natives"
label var idnum_1900_uniq "Unique individual identifier in sample"
label var C1 "=1 if arrive in US after 1890 (immigrants)"
label var exp "Experience (= age)"
label var age35 "=1 if age>35"
label var age35exp "age35* exp"
label var bpl1 "birthplace code, all natives  = 0"
label var occ1950_all "Occupation code, 1950 basis (see IPUMS)"
label var income "Occupation-based income using 1901 CoL survey"
label var lnincome "ln(income)"
label var shurb1_1900 "share urban in county as of 1900"
label var shurb1 "% of county in urban area, defined as jurisdiction of 2,500+ residents"
label var shurb2 "% of county in urban area, defined as jurisdiction of 25,000+ residents"
label var occscore_all "Occupation-based earnings, using 1950 occupation score"
label var occscore_mode "Modal occupation score associated with given occupation string (in IPUMS)"
label var occscore_med "Median occupation score associated with given occupation string (in IPUMS)"
label var occ1950_mode "Modal occupation code associated with given occupation string (in IPUMS)"
label var bpl "birthplace code, all"
label var birthyear "Calendar year of birth"

save panel_all_forjpe.dta, replace

