function cycle_PE(NumberCycles,FV,RV,MaxCycle,Filename,Threshold)

% Cycle testing
%   NumberCycles: 1 by default (Number of test cycles)
%   FV: Forward voltage = +2 by default (RRAM, reverse sign for CRS)
%   RV: Reverse voltage = -2 by default (RRAM, reverse sign for CRS)
%   MaxCycle: 100 by default
%   Filename: 'data' by default
%   Threshold: 10x by Default, to stop execution
%
%   Starts the testing with an ERASE cycle
%
%   Modified by Jeremy Smith 2015/03/19
%   Modified by Jeremy Smith 2016/10/10
%   Email: j-smith@eecs.berkeley.edu

% Modify Parameters here for convenience
global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground
TargetRon = 5000;       % Target value of Ron (ohms)
TargetRoff = 50000;     % Target value of Roff (ohms)
ERS_PW = 5;             % Erase pulse width (msec)
PGM_PW = 5;             % Program pulse width (msec)
RD_PW = 100;            % Read pulse width (msec)
Vread = 0.9;            % Read voltage
ERS_Icomp = 0.01;     % Erase compliance (A)
PGM_Icomp = 0.01;     % Program compliance (A)

if(nargin < 6)
    Threshold = 10;   % Threshold for Ron/Roff
end
if(nargin < 5)
    Filename = 'data';
end
if(nargin < 4)
    MaxCycle = 100;   % Maximum number of Erase/Program Cycles before device fail
end
if(nargin < 3)   % REVERSE VOLTAGE
    RV = -2;
end
if(nargin < 2)   % FORWARD VOLTAGE
    FV = 2;
end
if(nargin < 1)
    NumberCycles = 1;
end

disp('CYCLE TESTING');
% Suppress Warning Message from using custom fit for resistance slope fit
warning off curvefit:fit:noStartPoint;

% Append Time to filenames to prevent overlap
TimeVect = fix(clock);
TimeVect = regexprep(num2str(TimeVect(4:6)),'\s*','_');
RonRoff_filename = [Filename '_Ron_Roff' '_' TimeVect '.csv'];
IVfilename = [Filename '_IV_data' '_' TimeVect '.csv'];

% If files do not exist, open with append
TESTfile = fopen(IVfilename,'a','native','US-ASCII');
TESTres = fopen(RonRoff_filename,'a','native','US-ASCII');

% Add Header to files
fprintf(TESTfile,'TargetRon = %f,', TargetRon);
fprintf(TESTres,'TargetRon = %f,', TargetRon);
fprintf(TESTfile,'TargetRoff = %f\n', TargetRoff);
fprintf(TESTres,'TargetRoff = %f\n', TargetRoff);
fprintf(TESTfile,'ERS_PW = %f,', ERS_PW);
fprintf(TESTres,'ERS_PW = %f,', ERS_PW);
fprintf(TESTfile,'PGM_PW = %f,', PGM_PW);
fprintf(TESTres,'PGM_PW = %f,', PGM_PW);
fprintf(TESTfile,'RD_PW = %f\n', RD_PW);
fprintf(TESTres,'RD_PW = %f\n', RD_PW);
fprintf(TESTfile,'Vread = %f,', Vread);
fprintf(TESTres,'Vread = %f,', Vread);
fprintf(TESTfile,'FV = %f,', FV);
fprintf(TESTres,'FV = %f,', FV);
fprintf(TESTfile,'RV = %f\n', RV);
fprintf(TESTres,'RV = %f\n', RV);
fprintf(TESTfile,'ERS_Icomp = %f,', ERS_Icomp);
fprintf(TESTres,'ERS_Icomp = %f,', ERS_Icomp);
fprintf(TESTfile,'PGM_Icomp = %f\n', PGM_Icomp);
fprintf(TESTres,'PGM_Icomp = %f\n', PGM_Icomp);
fprintf(TESTfile,'Threshold = %f\n', Threshold);
fprintf(TESTres,'Threshold = %f\n', Threshold);

% Enables SMUs for the cycling test
fprintf(OBJ4155, 'FMT 2,0');               % Output Data w/o Header
fprintf(OBJ4155, ['FL 0,' BiasTerminal]);  % Turn Off Filter
fprintf(OBJ4155, ['FL 0,' GndTerminal]);   % Turn Off Filter
fprintf(OBJ4155, ['MM 3,' BiasTerminal]);  % 3: 1ch pulsed spot measurement
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);

% Setup For Loop to Run Cycles
for index = 1:NumberCycles
    disp(['Starting Cycle: ' num2str(index)]);
    % Perform ERASE to High Resistance
    [PulseCount,Res] = ERASE(TargetRoff,RV,ERS_PW/1000,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW/1000,ERS_Icomp,index);
    
    PCE = PulseCount;
    Roff = Res(length(Res));
    disp(['  CYCLE FINISHED Roff: ' num2str(Roff)]);
    
    % Store Data to Buffer (R values versus pulse)
    OutputString = regexprep(num2str(Res),'\s*',',');
    OutputString = [num2str(index) 'E,' OutputString];
    
    fprintf(TESTfile,'%s\n',OutputString);
    
    % Perform Program to Low Resistance
    [PulseCount,Res] = PROGRAM(TargetRon,FV,PGM_PW/1000,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW/1000,PGM_Icomp,index); 
    
    PCP = PulseCount;
    Ron = Res(length(Res));
    disp(['  CYCLE FINISHED Ron: ' num2str(Ron)]);
    
    % Store Data to Buffer (R values versus pulse)
    OutputString = regexprep(num2str(Res),'\s*',',');
    OutputString = [num2str(index) 'P,' OutputString];    

    % Output Summary Data
    fprintf(TESTres,'%d,%f,%f,%f,%d,%d\n',index,Ron,Roff,Roff/Ron,PCE,PCP);
    fprintf(TESTfile,'%s\n',OutputString);
    
    % Check Ron/Roff Ratio, Return if Threshold not met
    if(Roff/Ron < Threshold)
        disp(['FAIL: Roff/Ron = ' num2str(Roff/Ron)]);
        disp(['  Roff: ' num2str(Roff)]);
        disp(['  Ron: ' num2str(Ron)]);
        fclose(TESTfile);
        fclose(TESTres);
        fprintf(OBJ4155, 'CL');
        warning on curvefit:fit:noStartPoint;
        return;
    end
    
end

% Close Relay switches
fprintf(OBJ4155, 'CL');

fclose(TESTfile);
fclose(TESTres);

% re-enable warning for testing
warning on curvefit:fit:noStartPoint;

end