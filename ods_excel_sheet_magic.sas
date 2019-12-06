/* 
######################################################################################################################## 
ods_excel_sheet_magic.sas

Description: 
When you want to export multiple tables or images to a single worksheet using ODS but then want to
keep iterating through worksheets in the same book. In 9.4v5 they brought in sheet_interval="now" but without that 
functionality you can use this ODS trick to create a dummy object to advance the worksheet and then switch back to
sheet_interval="none"
########################################################################################################################
*/
ods excel file="<my_file>.xlsx" options(sheet_name="<my_name>" embedded_titles="yes" sheet_interval="none");

ods excel options(sheet_name= sheet_interval="none");
title "My Title 1";
proc print data=<my_data_1> noobs;
run;

title "My Title 2";
proc print data=<my_data_2> noobs;
run;

title "My Title 3";
proc print data=<my_data_3> noobs;
run;
title;

ods excel options(sheet_interval="output");

ods exclude all;
data _null_;
   declare odsout obj();
run;
ods select all;
