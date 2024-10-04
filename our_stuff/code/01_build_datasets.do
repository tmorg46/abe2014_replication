/*

step 1: take raw_data and turn it into "their sample"

*/

clear all
frames reset

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"

cap mkdir "${route}/intermediate_datasets" // this will create the intermediate_datasets directory if it's not yet present, like from newly cloned repo


*********************************************
* build the pooled cross section of 1900-1920
*********************************************
// pending
foreach year in 1900 1910 1920 {
	use "${route}/raw_data/ipums_sets/ipums_baseline_`year'", clear
	drop sample hhwt gq perwt versionhist raced bpld // extra variables we don't need that came by default with each sample can go!

	*we'll filter the cross-section as they do:
	keep if 	sex==1 						// men
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
				
	keep if		yrsusa2!=5					// and came to the U.S. between
											// 1880-1900 if they're non-native.
	
	tempfile cross`year'
	save `cross`year'', replace // now we have the cross-section for a given year stored in memory temporarily:
}

clear
foreach year in 1900 1910 1920 {
	append using `cross`year'' // so we can put them all together!
}

save "${route}/intermediate_datasets/replicated_pcs.dta", replace // the replicated pooled cross-section is now saved and ready to go!		
										
					
										
										
										