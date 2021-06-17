/*Annual Data*/
libname z "/scratch/kennesaw/";

*proc sort data=q.gopublic out=data1;
proc sort data=z.goprivate out=data1;
	by gvkey private;
run;

proc means data=data1 noprint;
	by gvkey private;
	var private;
	output out = data2 n=freq;
run;

proc sort data=data2 out=data3 nodupkey;
by gvkey;
run;

data data4;
	set data2;
	if private=1;
run;

proc freq data=data4;
table freq;
run;

data data5;
	set data2;
	if private=0;
run;

proc freq data=data5;
table freq;
run;

/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;

/*Quarterly Data*/
libname z "/scratch/kennesaw/";
*proc sort data=q.gopublic_q out=data1;
proc sort data=z.goprivate_q out=data1;
	by gvkey private;
run;

proc means data=data1 noprint;
	by gvkey private;
	var private;
	output out = data2 n=freq;
run;

proc sort data=data2 out=data3 nodupkey;
by gvkey;
run;

data data4;
	set data2;
	if private=1;
run;

proc freq data=data4;
table freq;
run;

data data5;
	set data2;
	if private=0;
run;

proc freq data=data5;
table freq;
run;

/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
