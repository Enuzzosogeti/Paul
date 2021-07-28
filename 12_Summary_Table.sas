data Summary_Table;
set test10_scA test10_scB test10_scC;
run;

proc export data=Summary_Table 
            outfile="&path_scenarios_ST./&Country_imported._SummaryTable.txt"
            dbms = tab replace;
            delimiter = ";";
putnames = no;
run;