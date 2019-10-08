/* Check the results using Proc Reg  */
%let timer_start = %sysfunc(datetime());
proc reg data=sashelp.bweight;
model weight = Married MomAge MomSmoke MomEdLevel;
run;

data _null_;
	dur=datetime()-&timer_start;
	put 30*'-' / ' Total Duration' dur MMSS13.6 / 30*'-';
run;

/* Building model in IML  */
proc iml;
/* Reading in data from SAS  */
use sashelp.bweight;
read all var {'Married' 'MomAge' 'MomSmoke' 'MomEdLevel'} into X;
read all var {'weight'} into Y;
close sashelp.bweight;
	
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
print 'OLS Statistics for regression of Infant Weight';
print reg_stats (|Colname={DF SS MS F} rowname={Model Residuals} format=8.4|);
print 'Parameter estimates';
print coefs (|Colname={Coef SE T p_stat} rowname={INT Married MomAge MomSmoke MomEdLevel} format=8.4|);
print " ";
print 'The Adjusted R-Square is ' Adj_R_2;
print 'The time to invert X*X was' (timer[1,1]);
print 'The time calculate all statistics was' (timer[2,1]);
quit; 
