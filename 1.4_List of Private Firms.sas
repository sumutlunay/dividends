/*Annual*/
proc import out= levelfull 
datafile = "/home/kennesaw/Sunay/Dividends/levelfull.dta";
run;

data levelfull;
	set levelfull;
	if repurch>0 then repayer=1; else repayer=0;
	if repayer+payer>=1 then distributor=1; else distributor=0;
	totpay = (dvc+repurch);
run;

/*List of Private Distributors*/
proc sql;
create table distributors
as select conm, gvkey, fyear, datadate, payer, repayer, dvc, repurch, totpay, at, oibdp
from levelfull
where distributor=1
and private=1;
quit;

proc export data=distributors
outfile="/home/kennesaw/Sunay/Dividends/distributors.csv"
dbms=csv;
run;

/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
