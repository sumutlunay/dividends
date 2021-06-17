proc sql;
	create table base0
	as select DATAFMT, FYEARQ, DATACQTR, GDWLIPQ, GVKEY, INDFMT, POPSRC, RCPQ, SETPQ, 
			SPIOPQ, WDPQ, ATQ,	CEQQ, CIK, CONM, CSHOQ, CUSIP, EXCHG,	FIC, FYR, IBQ, LTQ, OANCFY, 
			SALEQ, SPIQ, TIC, OIBDPQ, DVY, OIADPQ, DLTTQ, ADRRQ, ACTQ,  LCTQ, CHQ, CAPXY, PPENTQ,
			PRSTKCY, SSTKY, TSTKQ, PRCRAQ, PRSTKCY, PSTKQ, CSHIQ, PRCCQ, XINTQ, INTANQ, ppegtq, dpactq,
			DVPSPQ, EPSPXQ, NIQ
		from compd.fundq;
quit;

	/*Clean Data!!*/
data base1;
	set base0;
	if datafmt = "STD";/*Non restated data*/
	if indfmt = "INDL"; /*Industrial format*/
	if missing(dvy) then div1=0;
	div1=DVY/OIBDPQ;
	dps=dvy/cshoq;
	eps=IBQ/cshoq;
run;

/*Create Lag Variables*/
proc sort data=base1; 
	by gvkey DATACQTR;
run;

data base1;
	set base1;
	by gvkey DATACQTR;
	lagquarter=lag(DATACQTR);
	lagdps=lag(dps);
	lagaltdps=lag(DVPSPQ);
	lagPRSTKCY=lag(PRSTKCY);
	lagPSTKQ=lag(PSTKQ);
	if first.gvkey then do
		lagdps=.;
		lagaltdps=.;
		lagPRSTKCY=.;
		lagPSTKQ=.;
	end;
run;

data base2;
	set base1;
	chgdps = dps - lagdps;
	chgaltdps = DVPSPQ - lagaltdps;
run;

data base2;
	set base2;
/*Grennan-JFE 2018 Calculation*/
	if missing(PRCRAQ) then 
		grossrep = 	(PRSTKCY - lagPRSTKCY) - (PSTKQ - lagPSTKQ);
	else grossrep = CSHOPQ*PRCRAQ;

	if grossrep<0 then grossrep=0;
	payouti = (grossrep+dvy)/OIBDPQ;
	payoutps = (grossrep+dvy)/cshoq;
run;

proc sort data=base2; 
	by gvkey DATACQTR;
run;

data base2;
	set base2;
	by gvkey DATACQTR;
	lagpps=lag(payoutps);
	if first.gvkey then do
		lagpps=.;
	end;
run;

/*Estimate target payout ratio for each firm during the sample period*/
proc sql;
	create table tpr
	as select gvkey, median(div1) as tpr, median(payouti) as tppr
	from base2
	group by gvkey;
quit;
run;

proc sql;
	create table base3
	as select * 
	from base2 as a, tpr as b
	where a.gvkey=b.gvkey;
quit;

/* Calculate deviation */
data base3;
	set base3;
	dev = tpr*eps - lagdps;
	devalt = tpr*EPSPXQ - lagaltdps;
	devp = tppr*eps - lagpps;
	chgpps = payoutps - lagpps;
run;

/* Firm level regressions to estimate SOA */
proc reg data=base3 outest= soamodel1 noprint;
	by gvkey;
	model chgdps = dev;
run;

data soamodel1 (rename=(dev=soa1));
	set soamodel1;
	keep gvkey dev;
run;

proc reg data=base3 outest= soamodel2 noprint;
	by gvkey;
	model chgaltdps = devalt;
run;

data soamodel2 (rename=(devalt=soa2));
	set soamodel2;
	keep gvkey devalt;
run;

proc reg data=base3 outest= soapmodel1 noprint;
	by gvkey;
	model chgpps = devp;
run;

data soapmodel1 (rename=(devp=soap1));
	set soapmodel1;
	keep gvkey devp;
run;

/* Merge with main data */
libname z "/scratch/kennesaw/";
proc sql;
	create table data0
	as select * 
	from z.fullcomp_q as a
	left join soamodel1 as b
	on a.gvkey=b.gvkey;
quit;

proc sql;
	create table data1
	as select * 
	from data0 as a
	left join soamodel2 as b
	on a.gvkey=b.gvkey;
quit;

proc sql;
	create table z.fullcomp_q1
	as select * 
	from data1 as a
	left join soapmodel1 as b
	on a.gvkey=b.gvkey;
quit;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
