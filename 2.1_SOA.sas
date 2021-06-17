proc sql;
	create table base0
	as select CONSOL, COSTAT, CURCD,DATADATE, DATAFMT, FYEAR, GDWLIP, GVKEY, INDFMT, POPSRC, RCP, SETP, 
			SPIOP, WDP,	AT,	CEQ, CIK, CONM, CSHO, CUSIP, EXCHG,	FIC, FYR, IB, LT, OANCF, PRCC_F, PRCC_C, 
			SALE, SPI, TIC, SICH, OIBDP, DVC, OIADP, XRD, DLTT, ADRR, ACT,  LCT, CH, DD1, TXP, CAPX, DP, DV,
			WCAP, RE, PPENT, PPEGT, COGS, XIDOC, RECCH, XINT, IBC, RECT, INVT, DLC, XAD, AP, INTAN, RECD, AU, PI,
			TSTKC, PRSTKC, SSTK, DVPSX_F, AJEX, EPSPX, dpact, ebit, DVPSP_C, DVPSP_F, INTPN, NI, PSTKRV
		from compd.funda;
quit;

	/*Clean Data!!*/
data base1;
	set base0;
	if datafmt = "STD";/*Non restated data*/
	if indfmt = "INDL"; /*Industrial format*/
	if missing(dvc) then div1=0;
	div1 = dvc/OIBDP;
	purch1 = PRSTKC - PSTKRV;
	dps=dvc/csho;
	eps=ib/csho;
run;

/*Create Lag Variables*/
data lags;
	set base1 (rename=(dps = lagdps
				DVPSP_F = lagaltdps
				TSTKC = lagtreas));
	lagyear=fyear+1;
	keep gvkey lagyear lagdps lagaltdps lagtreas;
run;

proc sql;
	create table base2
	as select * 
	from base1 as a, lags as b
	where a.gvkey=b.gvkey
	and a.fyear = b.lagyear;
quit;

data base2;
	set base2;
	chgdps = dps - lagdps;
	chgaltdps = DVPSX_F - lagaltdps;
	if (TSTKC=0 and lagtreas=0)
		then repurch=purch1;
		else repurch=TSTKC-lagtreas;
	if repurch<0 then repurch=0;
	payout1=(dvc+repurch)/OIBDP;
	payoutps=(dvc+repurch)/csho;
run;

/*Create Lag Payout Per Share*/
data lags1;
	set base2 (rename=(payoutps = lagpps));
	lagyear=fyear+1;
	keep gvkey lagyear lagpps;
run;

proc sql;
	create table base2
	as select * 
	from base2 as a, lags1 as b
	where a.gvkey=b.gvkey
	and a.fyear = b.lagyear;
quit;

/*Estimate target payout ratio for each firm during the sample period*/
proc sql;
	create table tpr
	as select gvkey, median(div1) as tpr, median(payout1) as tppr
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
	devalt = tpr*EPSPX - lagaltdps;
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
	from z.fullcomp as a
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
	create table z.fullcomp1
	as select * 
	from data1 as a
	left join soapmodel1 as b
	on a.gvkey=b.gvkey;
quit;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
