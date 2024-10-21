/*

step 1: take raw_data and turn it into the following files (in order):

	- canadian_pcs.dta		Pooled cross-section of US & Canadian Men
	- women_pcs.dta			Pooled cross-section of their sample but female
	
	- canadian_linked.dta	Linked sample of US & Canadian Men
	- women_linked.dta		Linked sample of their sample but female

*/

clear all
frames reset

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"

cap mkdir "${route}/intermediate_datasets" // this will create the intermediate_datasets directory if it's not yet present, like from newly cloned repo (because there's a gitignore for this subdirectory as well lol)


************************************************************
* build the Canadian men's pooled cross section of 1900-1920
************************************************************
// done
foreach year in 1900 1910 1920 {
	use "${route}/raw_data/ipums_sets/ipums_baseline_`year'", clear
	drop serial pernum sample hhwt gq perwt versionhist raced bpld // extra variables we don't need that came by default with each sample can go!

	*we'll filter the cross-section as they do:
	keep if 	sex==1 							// men
	keep if		inrange(birthyr,1865,1882)		// aged 18-35 in 1900
	keep if 	race==1							// who are white,

	keep if		!inlist(stateicp,   	///
				11,40,41,42,43,44,  	///
				45,46,47,48,49,51,  	///
				52,53,54,56,98)					// aren't "in the South",
				
	keep if		bpl<99 | bpl==150				// are native to the US or Canada,
				
	keep if		inrange(yrimmig,1880,1900) | ///
					yrimmig==0					// and came to the US between
												// 1880-1900 if they're non-native.
	
	tempfile cross`year'_canada
	save `cross`year'_canada', replace // now we have the cross-section for a given year stored in memory temporarily:
}

clear
foreach year in 1900 1910 1920 {
	append using `cross`year'_canada' // so we can put them all together!
}

save "${route}/intermediate_datasets/canada_pcs.dta", replace // the replicated pooled cross-section is now saved and ready to go!	
*/


*****************************************************
* build the women's pooled cross section of 1900-1920
*****************************************************
// done
foreach year in 1900 1910 1920 {
	use "${route}/raw_data/ipums_sets/ipums_baseline_`year'", clear
	drop serial pernum sample hhwt gq perwt versionhist raced bpld // extra variables we don't need that came by default with each sample can go!

	*we'll filter the cross-section as they do:
	keep if 	sex==2						// women
	keep if		inrange(birthyr,1865,1882)	// aged 18-35 in 1900
	keep if 	race==1						// who are white,

	keep if		!inlist(stateicp,   	///
				11,40,41,42,43,44,  	///
				45,46,47,48,49,51,  	///
				52,53,54,56,98)				// aren't "in the South",
				
	keep if		bpl<99 | bpl==400 | 	/// 
				bpl==401 | bpl==404 |   ///
				bpl==405 | bpl==410 |	///
				bpl==411 | bpl==412 |	///
				bpl==414 | bpl==420 |   ///
				bpl==421 | bpl==426 |   ///
				bpl==436 | bpl==450 |	/// // are native to the U.S.
				bpl==453 | bpl==465			// or the 16 sending countries,
				
	keep if		inrange(yrimmig,1880,1900) | ///
					yrimmig==0					// and came to the US between
												// 1880-1900 if they're non-native.
	
	tempfile cross`year'_women
	save `cross`year'_women', replace // now we have the cross-section for a given year stored in memory temporarily:
}

clear
foreach year in 1900 1910 1920 {
	append using `cross`year'_women' // so we can put them all together!
}

save "${route}/intermediate_datasets/women_pcs.dta", replace // the replicated pooled cross-section is now saved and ready to go!	
*/


***********************************************
* build the two linked samples across 1900-1920
***********************************************
// pending
*we gotta narrow down the CT links to the ones we trust the most (and also the ones that actually use the tree lol)
foreach year in 1910 1920 {
	import delimited using "${route}/raw_data/census_tree/1900_`year'.csv", varn(1) clear
	
	egen methods = rowtotal(clp mlp xgb family_tree direct_hint profile_hint implied) // how do I link thee? let me count the ways
	
	drop if (family_tree!=1 & methods<2) 	| ///
			(clp==1 & mlp==1 & methods==2) 	| ///
			(implied==1 & methods<3)			 // these are combos that either don't involve the tree or aren't so trustworthy
								
	drop clp mlp xgb family_tree direct_hint profile_hint implied methods // don't need all the extra variables once we've cleaned the links up like we did above, so yeet!
	
	tempfile ct_1900_`year'
	save `ct_1900_`year'', replace // we'll tempfile them to save space (because they're .csv files so we can't merge them straight-up)
}

*************************************
*now let's link those Canadian gents:
use histid year if year==1900 using "${route}/intermediate_datasets/canada_pcs.dta", clear // start with the 1900 folks from the narrowed-down sample (so we don't have to narrow it down again)
drop year

rename histid histid1900

merge m:1 histid1900 using `ct_1900_1910', keep(3) nogen
merge m:1 histid1900 using `ct_1900_1920', keep(3) nogen // and now we've got them linked to their future selves!!

sort histid1900
gen id = _n
reshape long histid, i(id) j(year) 

foreach year in 1900 1910 1920 {
	
	// the update and keep(1 3 4) options allow us to "fill in the gaps" as we merge each year onto the list of histids
	merge m:1 histid using "${route}/raw_data/ipums_sets/ipums_baseline_`year'.dta", keep(1 3 4) update nogen
	
}

drop serial pernum sample hhwt gq perwt versionhist raced bpld // extra variables we don't need that came by default with each sample can go!

save "${route}/intermediate_datasets/canada_links.dta", replace // and save them!


*************************************
*and now we link the ladies!!!!!!!!!:
use histid year if year==1900 using "${route}/intermediate_datasets/women_pcs.dta", clear // start with the 1900 folks from the narrowed-down sample (so we don't have to narrow it down again)
drop year

rename histid histid1900

merge m:1 histid1900 using `ct_1900_1910', keep(3) nogen
merge m:1 histid1900 using `ct_1900_1920', keep(3) nogen // and now we've got them linked to their future selves!!

sort histid1900
gen id = _n
reshape long histid, i(id) j(year) 

foreach year in 1900 1910 1920 {
	
	// the update and keep(1 3 4) options allow us to "fill in the gaps" as we merge each year onto the list of histids
	merge m:1 histid using "${route}/raw_data/ipums_sets/ipums_baseline_`year'.dta", keep(1 3 4) update nogen
	
}

drop serial pernum sample hhwt gq perwt versionhist raced bpld // extra variables we don't need that came by default with each sample can go!

save "${route}/intermediate_datasets/women_links.dta", replace // and save them!
*/
										
										