libname z "/scratch/kennesaw/";

data data1;
/* 	set z.fullcomp1; */
	set z.fullcomp_q1;	
	if soa1>1 then soa1=.;
	if soa1<0 then soa1=.;
	if soa2>1 then soa2=.;
	if soa2<0 then soa2=.;
	if soap1>1 then soap1=.;
	if soap1<0 then soap1=.;
	if 1<=ownership<=2 then PEGroup=1; else PEGroup=0;
	if 3<=ownership<=4 then MEGroup=1; else MEGroup=0;

	numsic=input(sic,4.);
	if 4900<=numsic<=4949 then delete;/*Delete financials*/
	if 6000<=numsic<=6999 then delete;/*Delete utilities*/ 

/* 	if 1984<=fyear<=2018; */
	if 1984<=fyearq<=2018;
run;

	/*Winsorization*/
/* %winsorize(inset=data1, outset=data1, sortvar=gvkey,  */
/* vars= 	soa1 soa2 soap1, */
/* perc1=10, trim=0); */

/* Public vs Private Comparison */
proc sort data=data1;
	by private;
run;

/* proc means data=data1 nolabels n mean median; */
/* 	by private; */
/* 	var soa1 soa2 soap1; */
/* run; */

proc means data=data1 noprint;
	by private;
	output out=stats (drop=_FREQ_ _TYPE_)
	n(soa1 soap1)=n1-n2
	mean(soa1 soap1)=mn1-mn2
	median(soa1 soap1)=md1-md2;
run;

proc transpose data=stats out=transposed;
run;

proc print data=transposed; run;
	
proc ttest data=data1 plots=none;
	class private;
	var soa1 soap1;
run;

/* Within Private Comparison */
data data2;
	set data1;
	if private=1;
run;

proc sort data=data2;
	by MEGroup;
run;

/* proc means data=data2 nolabels n mean median; */
/* 	by ownership; */
/* 	var soa1 soa2 soap1; */
/* run; */

proc means data=data2 noprint;
	by MEGroup;
	output out=stats (drop=_FREQ_ _TYPE_)
	n(soa1 soap1)=n1-n2
	mean(soa1 soap1)=mn1-mn2
	median(soa1 soap1)=md1-md2;
run;

proc transpose data=stats out=transposed;
run;

proc print data=transposed; run;

proc ttest data=data2 plots=none;
	class MEGroup;
	var soa1 soap1;
run;

proc sort data=data2;
	by ownership;
run;

/* proc means data=data2 nolabels n mean median; */
/* 	by ownership; */
/* 	var soa1 soa2 soap1; */
/* run; */

proc means data=data2 noprint;
	by ownership;
	output out=stats (drop=_FREQ_ _TYPE_)
	n(soa1 soap1)=n1-n2
	mean(soa1 soap1)=mn1-mn2
	median(soa1 soap1)=md1-md2;
run;

proc transpose data=stats out=transposed;
run;

proc print data=transposed; run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
