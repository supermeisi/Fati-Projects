clc;
clear;

mkdir('BUF')
Variable.Pb.Thickness=[1 2 3 4 5];
Variable.Fe.Thickness=[1 2 3 4 5 ];
Variable.Water.Thickness=[1 2 3 4 5];
Variable.Energy=[0.2 0.5 1 1.5 2];
[row1, col1]=size(Variable.Pb.Thickness);
[row2, col2]=size(Variable.Fe.Thickness);
[row3, col3]=size(Variable.Water.Thickness);
[row4, col4]=size(Variable.Energy);
%%
fileID2=fopen(['BUF', 'RunAllOfMyProgram' ,'.bat'   ],'w' ) ;
for m=1:col4
for i=1:col3
for j=1:col2
for k=1:col1
    filename=['BuildUp_',num2str(Variable.Energy(m)),'_',num2str(Variable.Pb.Thickness(i)),'_',num2str(Variable.Fe.Thickness(j)),'_',num2str(Variable.Water.Thickness(k))  ];
    fileID=fopen(['BUF/', filename ,'.i'   ],'w' ) ;
    %_____________________________________________________________________________________________________________________________________________________________________________________________________________
    fprintf(fileID, (' ************ Buildup ******************** \n' )   );
    fprintf(fileID,  'c ccccccccccccccc Cell card ccccccccccccccc \n'    );
    fprintf(fileID,  '1 1 -11.35  -1     imp:p=1   \n');   %Pb
    fprintf(fileID,  '2 2 -7.874  1 -2   imp:p=1 \n');      %Fe
    fprintf(fileID,  '3 3 -1      2 -3   imp:p=1  \n');      %water
    fprintf(fileID,  '4 0 -4 #1 #2 #3    imp:p=1   \n');
    fprintf(fileID,  '5 0  4             imp:p=0 \n\n');
    %________________________________________________________________________
    fprintf(fileID,  'c ************ Surface Card ***************** \n'    );
    fprintf(fileID,  'c ******************************************* \n'    );
    fprintf(fileID,  ['1 rcc 0 0 -5 0 0 10 5 ',num2str(Variable.Pb.Thickness(i)),' \n']    );
    fprintf(fileID,  ['2 rcc 0 0 -10 0 0 20 10',num2str(Variable.Pb.Thickness(i)+Variable.Fe.Thickness(j)),' \n']    );
    fprintf(fileID,  ['3 rcc 0 0 -15 0 0 30 15',num2str(Variable.Pb.Thickness(i)+ Variable.Fe.Thickness(j)+Variable.Water.Thickness(k)),'\n']    );
    fprintf(fileID,  '4 so 50 \n\n'    );
    %___________________________________________________________ %_______________________________________________________________________________
    
    fprintf(fileID,  'c ************ Data Card ******************** \n'    );
    fprintf(fileID,  'c ******************************************* \n'    );
    fprintf(fileID,  'mode p \n' );
    fprintf(fileID,  'm1 82000 1  \n'); %Pb
    fprintf(fileID,  'm2 26000 1  \n');  %Fe
    fprintf(fileID,  'm3 1001 0.3333 8016 0.6667 \n'); %Water
    fprintf(fileID,  'sdef erg=2 pos=-10 0 0 \n' );
    fprintf(fileID,  'f2:p 3.1 \n'    );
    fprintf(fileID,  'nps 1e6 \n'    );
    
    fclose(fileID) ;
%%
     fprintf(fileID2,  ['mcnpx2.7 i=',filename,'.i o=',filename,'_outa.o', '\n' ]   );
     if rem(m,5)==0
          fprintf(fileID2, ('call  1_ClearAll.bat \n' )   );
     end

end
end
end
     %%
end
fclose(fileID2) ;