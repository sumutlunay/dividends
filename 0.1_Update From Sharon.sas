/*Sharon's update April-2020*/

proc import datafile="/home/kennesaw/Sunay/Dividends/From Sharon/modified_update_2020_v1.xlsx"
			out=privatesupdate dbms=xlsx;
			sheet=Ultraclean;
run;

data privatesupdate;
	set privatesupdate;
	if missing(A) then delete;
run;

libname p "/home/kennesaw/Sunay/Dividends/From Sharon";
data p.privatesupdate_ready;
	set privatesupdate (rename = (y=fyear gvkey1=gvkey));
	if missing(gvkey) then delete;
	if private=1;
	gvkey1=input(gvkey,6.);
	keep gvkey1 fyear ownership PERank private financier gov sub_coop coop
			PE_own Mgmt_own Employ_own CEO_own Group_own Tribe_own Family_Own Chairman
			No_Deals No_Firms Equity_Invested;
run;
