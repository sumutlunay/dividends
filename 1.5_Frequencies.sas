/*Annual*/
proc import out= levelfull 
datafile = "/home/kennesaw/Sunay/Dividends/levelfull.dta";
run;

/*Idetify cuts and increases*/
data levelfull;
	set levelfull;
	if repurch>0 then repayer=1; else repayer=0;
	if repayer+payer>=1 then distributor=1; else distributor=0;
	totpay = (dvc+repurch);
	if (lagdv=0 or lagdv=.) and dvc>0 then divstart=1; else divstart=0;
	if lagdv>0 and (dvc=. or dvc=0) then divcut=1; else divcut=0;
run;

/*Aggregate Statistics*/
libname z "/scratch/kennesaw/";
proc sql;
create table z.privatestats
as select fyear, sum(divstart) as starts, sum(divcut) as cuts,
			sum(dvc) as aggdivs, sum(repurch) as aggrepurch, sum(totpay) as aggpayout,
			sum(payer) as divfreq, sum(repayer) as repfreq, sum(distributor) as distfreq,
			count(gvkey) as firmfreq
from levelfull
where private=1
group by fyear;

create table z.publicstats
as select fyear, sum(divstart) as starts, sum(divcut) as cuts,
			sum(dvc) as aggdivs, sum(repurch) as aggrepurch, sum(totpay) as aggpayout,
			sum(payer) as divfreq, sum(repayer) as repfreq, sum(distributor) as distfreq,
			count(gvkey) as firmfreq
from levelfull
where private=0
group by fyear;
quit;

data z.privatestats; set z.privatestats; private=1; run;
data z.publicstats; set z.publicstats; private=0; run;

data z.fullstats;
	set z.privatestats z.publicstats;
run;

/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;

/*Download from scratch directory for Tableau analysis*/

/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/


/*Quarterly*/
proc import out= levelfull 
datafile = "/home/kennesaw/Sunay/Dividends/levelfull_q.dta";
run;

data levelfull;
	set levelfull;
	if netrep>0 then repayer=1; else repayer=0;
	if repayer+payer>=1 then distributor=1; else distributor=0;
	totpay = (dvy+netrep);
	if (lagdv=0 or lagdv=.) and dvy>0 then divstart=1; else divstart=0;
	if lagdv>0 and (dvy=. or dvy=0) then divcut=1; else divcut=0;
run;

/*Aggregate Statistics*/
libname z "/scratch/kennesaw/";
proc sql;
create table z.privatestats_q
as select datacqtr, sum(divstart) as starts, sum(divcut) as cuts,
			sum(dvy) as aggdivs, sum(netrep) as aggrepurch, sum(totpay) as aggpayout,
			sum(payer) as divfreq, sum(repayer) as repfreq, sum(distributor) as distfreq,
			count(gvkey) as firmfreq
from levelfull
where private=1
group by datacqtr;

create table z.publicstats_q
as select datacqtr, sum(divstart) as starts, sum(divcut) as cuts,
			sum(dvy) as aggdivs, sum(netrep) as aggrepurch, sum(totpay) as aggpayout,
			sum(payer) as divfreq, sum(repayer) as repfreq, sum(distributor) as distfreq,
			count(gvkey) as firmfreq
from levelfull
where private=0
group by datacqtr;
quit;

data z.privatestats_q; set z.privatestats_q; private=1; run;
data z.publicstats_q; set z.publicstats_q; private=0; run;

data z.fullstats_q;
	set z.privatestats_q z.publicstats_q;
run;

/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;


/*Download from scratch directory for Tableau analysis*/