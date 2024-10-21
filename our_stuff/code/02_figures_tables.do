/*

step 2: do analysis by replicating tables and figures with our new results!

	

*/

clear all
frames reset

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"


******************************************************
* Replicate their Table 1 - Sample Sizes & Match Rates
******************************************************
// pending
* we need to reopen the big census sample of non-Southern white people 18-35 to get 1900 baseline number-in-universe measures
use if ///
	inrange(birthyr,1865,1882) & ///
	race==1 				   & ///
	!inlist(stateicp,   		 ///
		11,40,41,42,43,44,  	 ///
		45,46,47,48,49,51,  	 ///
		52,53,54,56,98)		   & ///
	(inrange(yrimmig,1880,1900)  ///
		| yrimmig==0)			 ///
	using "${route}/raw_data/ipums_sets/ipums_baseline_1900.dta", clear
	
*let's get the American men & women first:
foreach sex in 1 2 {
	
	sum if sex==`sex' & ///
		bpl<99
		
	local american`sex' = r(N)
}

*now the Canadian men:
sum if sex==1 & bpl==150
	






