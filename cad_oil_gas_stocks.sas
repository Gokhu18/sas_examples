/*Importing Model Handoff Parameters for Sector 3*/
proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/CNQ.TO.csv"
 out=work.cnq(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/CVE.TO.csv"
 out=work.cve(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/ECA.TO.csv"
 out=work.eca(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/ENB.TO.csv"
 out=work.enb(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

 proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/HSE.TO.csv"
 out=work.hse(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

 proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/IMO.TO.csv"
 out=work.imo(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/SU.TO.csv"
 out=work.SU(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

proc import 
 datafile="/opt/sas/sasdata/sasuser/ejohn07/sas_weekly/TRP.TO.csv"
 out=work.trp(keep=date 'Adj Close'n)
 dbms=csv
 replace
 ;

 data cnq;
 set cnq;
 ticker = "CNQ";
 if date='31OCT2014'd then call symputx('cnq_index','Adj Close'n);
 stock_base=input(symget('cnq_index'),best32.);
 run;

 data cve;
 set cve;
 ticker = "CVE";
  if date='31OCT2014'd then call symputx('cve_index','Adj Close'n);
  	stock_base=input(symget('cve_index'),best32.);
 run;

 data eca;
 set eca;
 ticker = "ECA";
  if date='31OCT2014'd then call symputx('eca_index','Adj Close'n);
  	stock_base=input(symget('eca_index'),best32.);
 run;

 data enb;
 set enb;
 ticker = "ENB";
  if date='31OCT2014'd then call symputx('enb_index','Adj Close'n);
  	stock_base=input(symget('enb_index'),best32.);
 run;

 data HSE;
 set HSE;
 ticker = "HSE";
  if date='31OCT2014'd then call symputx('hse_index','Adj Close'n);
  	stock_base=input(symget('hse_index'),best32.);
 run;

 data IMO;
 set IMO;
 ticker = "IMO";
  if date='31OCT2014'd then call symputx('imo_index','Adj Close'n);
  	stock_base=input(symget('imo_index'),best32.);
 run;

 data SU;
 set SU;
 length ticker $3.;
 ticker = "SU";
  if date='31OCT2014'd then call symputx('su_index','Adj Close'n);
  	stock_base=input(symget('su_index'),best32.);
 run;

 data TRP;
 set TRP;
 ticker = "TRP";
  if date='31OCT2014'd then call symputx('trp_index','Adj Close'n);
	stock_base=input(symget('trp_index'),best32.);
 run;

 data stocks_combined;
 set cnq cve eca enb hse imo su trp;
 stock_index= 'Adj Close'n/stock_base*100;
 run;

proc sgplot data=stocks_combined(where=(ticker not in ("ENB","TRP")));                                                                                                           
   	series x=date y=stock_index / 
		group= ticker;
		yaxis label='Adjusted Close (31OCT2014=100)';
	title "Top 8 CAD Oil/Gas Stocks, OCT2014-OCT2019";
run;
title ;
quit;

                                                                                      
                                                                                                                                        
/* Define symbol characteristics */
axis2 label=(angle=90 "Adjusted Close (CAD$)");  
symbol1 interpol=join color=mob width=2;

proc gplot data=stocks_combined(where=(ticker not in ("ENB","TRP")));
	by ticker; 
   	plot 'Adj Close'n*date / 
		vaxis=axis2;
	title "Top 8 CAD Oil/Gas Stocks, OCT2014-OCT2019";
run;
title ;
quit;  
