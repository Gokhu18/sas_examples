/*Read in the dataset*/
data dailyprices;
   infile datalines;
   length Symbol $ 4;
   input Symbol $ @;
   do Date = '01jan2007'd  to '05jan2007'd;
      input Price @;
      if not missing(Price) then output;
   end;
   format Date mmddyy10.;
datalines;
CSCO 19.75 20 20.5 21 .
IBM 76 78 75 79 81
LU 2.55 2.53 . . .
AVID 41.25 . . . .
BAC 51 51 51.2 49.9 52.1
;

proc sort data=dailyprices noequals;
by symbol date;
run;

/*First-day to last-day price difference with Data Step*/
data part_1;
retain initial_price;
set dailyprices;
by symbol date;
if not (first.symbol and last.symbol);
if first.symbol then initial_price=price;
else do;
	price_dif=price-initial_price;
end;
if not last.symbol then delete;
run;

/*First-day to last-day price difference with LAG/DIF operator*/
data part_2 (drop= pdif1 pdif2 pdif3 pdif4 check t);
retain t;
set dailyprices;
by symbol date;
/*Invoke the LAG/DIF operator before subsetting */
pDIF1=DIF(price);
pDIF2=DIF2(price);
pDIF3=DIF3(price);
pDIF4=DIF4(price);
if not (first.symbol and last.symbol);
if first.symbol then t=_n_;
else do;
	check=_n_-t;
	if _n_-t=1 then price_dif=pDIF1;
	else if _n_-t=2 then price_dif=pDIF2;
	else if _n_-t=3 then price_dif=pDIF3;
	else if _n_-t=4 then price_dif=pDIF4;
	else put "ERROR: I only wrote this code to deal with a daily difference of 4";
end;
if not last.symbol then delete;
run;

/*Day-to-day price differences*/
data part_3;
set dailyprices;
by symbol date;
/*Invoke the LAG/DIF operator before subsetting */
price_dif=dif(price);
if not (first.symbol and last.symbol);
if first.symbol then call missing(price_dif);
run;

proc sql;
select
	a.date,
	a.symbol,
	a.initial_price format=dollar12.2,
	a.price format=dollar12.2,
	a.price_dif format=dollar12.2,
	b.price_dif as price_dif_lag_op format=dollar12.2
from part_1 as a
inner join part_2 as b
on a.date=b.date and a.symbol=b.symbol
;
quit;

proc print data=part_3 noobs;
format price price_dif dollar12.2; 
run;
