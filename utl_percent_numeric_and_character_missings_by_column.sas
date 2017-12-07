Percent numeric and character missings by column

  Two Solutions
     WPS/SAS
     WPS/PROC R  SAS/IML

Original topic: Send this IML output to dataset instead of result window

INPUT
=====

  SD1.HAVE total obs=5                |  RULES
                                      |
    X1    X2    X3    C1    C2    C3  |  C3 (missing/number rows)  X1
                                      |  ==                        ==
     .    62    41    7     3     2   |  3/8 = 37.5%               4/4 = 50%
    65    51    34          6     9   |
    37     9     .          3     8   |
    71    96    52    6               |
    36    19    98    2     1     9   |
     .     0     .    9     2         |
     .    84     8                    |
     .    94     .    1           2   |


WORKING CODE
============

   WPS/PROC R
     apply(have,2, function(col) sum(is.na(col) | col=="") / length(col))

   SAS/WPS

     proc format;
       value $chr2mis ' '='MIS' other='POP' ;
       value num2mis . = 'MIS'  other='POP' ;
     run;quit;

     proc freq data=sd1.have ;
        format _numeric_    num2mis.;
        format _character_ $chr2mis.;
        tables _all_ / missing;
     run;quit;

     data havfix;
       set wantpre;
       mispop=coalescec(of F_:);
       var=scan(table,2);
       keep mispop table percent;
     run;quit;

OUTPUT
======

  WPS/PROC R

    WORK.WANT total obs=1

    X1    X2     X3      C1      C2      C3

    50     0    37.5    37.5    37.5    37.5

  SAS/WPS Base

   WORK.HAVFIX total obs=11

     VAR    MISPOP    PERCENT

     X1      MIS        50.0
     X1      POP        50.0

     X2      POP       100.0  * no missing;

     X3      MIS        37.5
     X3      POP        62.5

     C1      MIS        37.5
     C1      POP        62.5

     C2      MIS        37.5
     C2      POP        62.5

     C3      MIS        37.5
     C3      POP        62.5

see
https://goo.gl/j2pxiQ
https://communities.sas.com/t5/SAS-IML-Software-and-Matrix/Send-this-IML-output-to-dataset-instead-of-result-window/m-p/419318

*                _              _       _
 _ __ ___   __ _| | _____    __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \  / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/ | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|  \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have(drop=rec i);
 array num[3] x1-x3;
 array chr[3] $1 c1-c3;
 do rec=1 to 8;
 do i=1 to 3;
   if uniform(5732)<.4 then num[i]=.;
     else num[i]=int(100*uniform(-1));
   if uniform(5731)<.4 then chr[i]='';
     else chr[i]=put(int(10*uniform(-1)),1.);
 end;
 output;
 end;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

;

* SAS and wps - same code;


%utl_submit_wps64('
libname sd1 sas7bdat "d:/sd1";
libname wrk sas7bdat "%sysfunc(pathname(work))";
ods exclude all;
ods output OneWayFreqs=wantpre;
proc freq data=sd1.have ;
   format _numeric_    num2mis.;
   format _character_ $chr2mis.;
   tables _all_ / missing;
run;quit;
ods select all;

data havfix;
  retain var mispop percent;
  set wantpre;
  mispop=coalescec(of F_:);
  var=scan(table,2);
  keep mispop var percent;
run;quit;
proc print;
run;quit;
');


* Wps proc R;
%utl_submit_wps64('
libname sd1 sas7bdat "d:/sd1";
libname wrk sas7bdat "%sysfunc(pathname(work))";
proc r;
submit;
library(haven);
have<-read_sas("d:/sd1/have.sas7bdat");
have;
want<-as.data.frame(t(apply(have, 2, function(col) 100*sum(is.na(col) | col=="") / length(col))));
colnames(want)<-colnames(have);
str(want);
endsubmit;
import r=want data=wrk.want;
run;quit;
');
