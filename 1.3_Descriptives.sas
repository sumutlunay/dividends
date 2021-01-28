/*Annual*/
proc import out= levelfull 
datafile = "/home/kennesaw/Sunay/Dividends/levelfull.dta";
run;

data levelfull;
	set levelfull;
	if repurch>0 then repayer=1; else repayer=0;
	if repayer+payer>=1 then distributor=1; else distributor=0;
	totpay = (dvc+repurch);
	if 1<=ownership<=2 then PEGroup=1; else PEGroup=0;
	if 3<=ownership<=4 then MEGroup=1; else MEGroup=0;
run;

/*Main statistics*/
proc sql;
create table stats
as select private, dvc, repurch, totpay, div1, repurch1, payout1, div2, repurch2, payout2, payer, repayer, 
			distributor, numdivs, divs4, divs3, divs2, divs1, DVPSP_F
from levelfull;
quit;

proc means data=stats nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

/*Within payers&repayers per Fabrizio's comment*/
proc sql;
create table withinstats1
as select private, dvc, repurch, totpay
from levelfull
where payer=1;
quit;

proc means data=withinstats1 nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

	/**/
proc sql;
create table withinstats2
as select private, dvc, repurch, totpay
from levelfull
where repayer=1;
quit;

proc means data=withinstats2 nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

	/**/
proc sql;
create table withinstats3
as select private, dvc, repurch, totpay
from levelfull
where distributor=1;
quit;

proc means data=withinstats3 nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

/*Within private firm types per Fabrizio's comment*/
proc sql;
create table withinprivate
as select ownership, private, dvc, repurch, totpay, div1, repurch1, payout1, div2, repurch2, payout2, payer, repayer, 
			distributor, numdivs, divs4, divs3, divs2, divs1, DVPSP_F
from levelfull
where private=1;
quit;


proc means data=withinprivate nolabels
	n mean median;
	class ownership;
run;

	/*Comparison of Main Groups*/
proc sql;
create table withinprivate
as select PEGroup, MEGroup, private, dvc, repurch, totpay, div1, repurch1, payout1, div2, repurch2, payout2, payer, repayer, 
			distributor, numdivs, divs4, divs3, divs2, divs1, DVPSP_F
from levelfull
where private=1;
quit;


proc means data=withinprivate nolabels
	n mean median;
	class PEGroup MEGroup;
run;


/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;


/*Quarterly*/
proc import out= levelfull 
datafile = "/home/kennesaw/Sunay/Dividends/levelfull_q.dta";
run;

data levelfull;
	set levelfull;
	if netrep>0 then repayer=1; else repayer=0;
	if repayer+payer>=1 then distributor=1; else distributor=0;
	totpay = (dvy+netrep);
	if 1<=ownership<=2 then PEGroup=1; else PEGroup=0;
	if 3<=ownership<=4 then MEGroup=1; else MEGroup=0;
run;

/*Main statistics*/
proc sql;
create table stats
as select private, dvy, netrep, totpay, div1, netrepi, payouti, div2, netrepa, payouta, payer, repayer, distributor, 
			numdivs, divs4, divs3, divs2, divs1, DVPSPQ
from levelfull;
quit;

proc means data=stats nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

/*Within payers&repayers per Fabrizio's comment*/
proc sql;
create table withinstats1
as select private, dvy, netrep, totpay
from levelfull
where payer=1;
quit;

proc means data=withinstats1 nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

	/**/
proc sql;
create table withinstats2
as select private, dvy, netrep, totpay
from levelfull
where repayer=1;
quit;

proc means data=withinstats2 nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

	/**/
proc sql;
create table withinstats3
as select private, dvy, netrep, totpay
from levelfull
where distributor=1;
quit;

proc means data=withinstats3 nolabels
	n mean median min p5 q1 q3 p95 max std;
	class private;
run;

/*Within private firm types per Fabrizio's comment*/
proc sql;
create table withinprivate
as select ownership, private, dvy, netrep, totpay, div1, netrepi, payouti, div2, netrepa, payouta, payer, repayer, distributor, 
			numdivs, divs4, divs3, divs2, divs1, DVPSPQ
from levelfull
where private=1;
quit;

proc means data=withinprivate nolabels
	n mean median;
	class ownership;
run;

	/*Comparison of Main Groups*/
proc sql;
create table withinprivate
as select PEGroup, MEGroup, private, dvy, netrep, totpay, div1, netrepi, payouti, div2, netrepa, payouta, payer, repayer, distributor, 
			numdivs, divs4, divs3, divs2, divs1, DVPSPQ
from levelfull
where private=1;
quit;


proc means data=withinprivate nolabels
	n mean median;
	class PEGroup MEGroup;
run;


/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
