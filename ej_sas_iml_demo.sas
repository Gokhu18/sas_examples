/* SAS code for TASS 2019q3 "Enter the Matrix"  */
/* Set output folder for graphs  */
%let results_dir=<output_directory>;
/* Inputting Matrix Test Data */
data my_data;
	infile datalines delimiter=","; 
	input A B C ;
	datalines;
1,5,3
5,1,5
3,3,1
;

data my_data_2;
	infile datalines delimiter=","; 
	input D E F ;
	datalines;
3,7,0
7,3,7
0,0,3
;

/* Importing data into SAS/IML */
proc iml;
use work.my_data; 
	read all var _ALL_ into matrix[colname=varNames];
close work.my_data;
print matrix;

use work.my_data_2; 
	read all var _ALL_ into matrix_2[colname=varNames];
close work.my_data_2;
print matrix_2;

/* Exporting data from IML to SAS */
varNames = {A B C};
create my_data_is_back from matrix [colname=varNames];
append from matrix;
close my_data_is_back;

/* Transposition of a matrix */
transposed=T(matrix);
transposed_2=matrix_2`;
print transposed transposed_2;

/* Matrix Addition  */
matrix_add=matrix+matrix_2;
print matrix_add;

/* Matrix Multiplication  */
matrix_mult=matrix*matrix_2;
matrix_mult_2=matrix_2*matrix;
print matrix_mult[rowname= {row1,row2,row3} colname={A B C}] matrix_mult_2[colname={co1 col2 col3}];

/* Matrix Element-wise powers  */
matrix_e_power=matrix##3;
matrix_e_power_2=matrix_2##3;
print matrix_e_power matrix_e_power_2 ;

/* Other Matrix Operators */
matrix_inv=inv(matrix);
matrix_trace=trace(matrix);
matrix_det=det(matrix);
matrix_logic=matrix>=matrix_2;
print matrix_inv matrix_logic;
print matrix_trace matrix_det;

/* Matrix reduction operations */
matrix_row_red=matrix_e_power[+,];
matrix_row_red_2=(matrix_e_power_2[+,])[,<>];
print matrix_row_red matrix_row_red_2;
quit;

/* Statistics in IML (Ordinary Least Squares Regression) */
/* Read SASHELP.CARS into work and create an interaction with foreign and MPG  */
data cars;
	set sashelp.cars;
	if origin eq "USA" then foreign = 0 ;
	else foreign = 1;
	mpg_x_foreign=foreign*mpg_highway;
run;

/* Check the results using Proc Reg  */
%let timer_start = %sysfunc(datetime());
proc reg data=work.cars;
model msrp = mpg_highway weight foreign mpg_x_foreign;
run;

data _null_;
	dur=datetime()-&timer_start;
	put 30*'-' / ' Total Duration' dur MMSS13.6 / 30*'-';
run;

/* Building model in IML  */
proc iml;
/* Reading in data from SAS  */
use work.cars;
read all var {'MPG_Highway' 'Weight' 'Foreign' 'mpg_x_foreign'} into X;
read all var {'MSRP'} into Y;
close cars;
	
/* Transforming the Data for a regression  */
timer=J(2,1,0);
n=nrow(X);
X=J(n,1,1) || X;
k=ncol(X);
/* Estimating Beta_hat  */
t0=time();
beta_hat=(inv(X`*X))*X`*y;
timer[1,1]=time()-t0;
u_hat=y-beta_hat`*X`*y;

/* Use Matrix Algebra to Calculate OLS statistics */
SSE=y`*y-beta_hat`*X`*y;
MSE=sse/(n-k);
Y_bar=sum(Y)/n;
ESS=beta_hat`*X`*y-n*y_bar**2;
MSR=ESS/(k-1);
F=MSR/MSE;
SST=ESS+SSE;
R_2=ESS/SST;
/* Note SAS is using Adjusted R-Square of 1-(n)/(n-k+1)*(1-R_2) */
Adj_R_2=1-(n-1)/(n-k+1)*(1-R_2);

/* Calculate Hypothesis Testing Components  */
SE=sqrt(vecdiag(inv(X`*X))#MSE);
T=beta_hat/se;
p_stats=2*(1-CDF('T',ABS(T),n-k));
timer[2,1]=time()-t0;

/* Clean up the results to print  */
reg_stats=(k||ESS||MSR||F) // (n-k||SSE||MSE||{.});
coefs=beta_hat || SE || T || p_stats;
print 'OLS Statistics for regression of Car Prices';
print reg_stats (|Colname={DF SS MS F} rowname={Model Residuals} format=8.4|);
print 'Parameter estimates';
print coefs (|Colname={Coef SE T p_stat} rowname={INT MPG Weight Foreign MPG_x_Foreign} format=8.4|);
print " ";
print 'The Adjusted R-Square is ' Adj_R_2;
print 'The time to invert X*X was' (timer[1,1]);
print 'The time to calculate all statistics was' (timer[2,1]);
quit; 


/* The bootstrap in IML */
ods listing gpath="&results_dir.";
ods graphics on / imagename="iml_results_" ;
proc univariate data=cars;
	var weight;
	histogram weight;
	inset N Kurtosis (8.4) / position=NE;
run;

/* Call IML and implement a bootstrap procedure for the Kurtosis */
proc iml;

/* Create module to estimate kurtosis */
start BootStat(A);
	return kurtosis(A);
finish;

/* Set Critical Value and number of bootstrap samples  */
alpha=0.05;
B=10000;

/* Read in cars data */
use work.cars;
read all var "Weight";
close; 

/* Resample the Weight data and recalculate kurtosis  */
call randseed(153);
est=BootStat(weight);
s=sample(weight, B // nrow(weight));
bStat=T(BootStat(s));
bootEst=mean(bStat);
SE=std(bStat);
call qntl(CI, bStat, alpha/2 || 1-alpha/2);

/* Summarize results of Bootstrap procedure  */
R=Est || BootEst || SE || CI` ;
print R[format=8.4 L="95% Bootstrap CI" c={"Obs" "BootEst" "StdErr" "Lower" "Upper"}];

/* Output the results as a graph */
call symputx('BootEst', round(BootEst, 1e-4));
call symputx('Lower', round(CI[1], 1e-4));
call symputx('Upper', round(CI[2], 1e-4));
refStmt = 'refline &BootEst / axis=x lineattrs=(color=red) 
             name="BootEst" legendlabel="Bootstrap Statistic = &BootEst";'
        +  'refline &Lower &Upper  / axis=x lineattrs=(color=blue) 
                  name="CI" legendlabel="95% Pctl CI";'
        +  'keylegend "BootEst" "CI";';
title "Bootstrap Distribution";
call histogram(bStat) label="Kurtosis" other=refStmt;
title;

ods graphics off;
ods _all_ close;

quit;
