function cycle_PE(NumberCycles,FV,RV,MaxCycle,Filename,Threshold)

% Cycle testing
%   NumberCycles: 1 by default
%   FV: Forward voltage = +2 by default
%   RV: Reverse voltage = -2 by default
%   MaxCycle: 100 by default
%   Filename: data by default
%   Threshold: 10 by Default, to stop execution
%
%   Starts the testing with an ERASE cycle
%
%   Modified by Jeremy Smith 2015/03/19
%   Email: j-smith@eecs.berkeley.edu

% Modify Parameters here for convenience
global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground
TargetRon = 5000;       % Target value of Ron (ohms)
TargetRoff = 50000;     % Target value of Roff (ohms)
ERS_PW = 0.001;         % Erase pulse width (sec)
PGM_PW = 0.001;         % Program pulse width (sec)
RD_PW = 0.050;          % Read pulse width (sec)
Vread = 1.5;            % Read voltage
ERS_Icomp = 0.020;      % Erase compliance (A)
PGM_Icomp = 0.020;      % Program compliance (A)

if(nargin < 6)
    Threshold = 5;   % Threshold for Ron/Roff
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

% Enables SMUs for the cycling test
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);
    
% Setup For Loop to Run Cycles
for index = 1:NumberCycles
    disp(['Starting Cycle: ' num2str(index)]);
    % Perform ERASE to High Resistance
    [PulseCount,Res] = ERASE(TargetRoff,RV,ERS_PW,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW,ERS_Icomp,index);
    
    PCE = PulseCount;
    Roff = Res(length(Res));
    disp(['  CYCLE FINISHED Roff: ' num2str(Roff)]);
    
    % Store Data to Buffer
    % Store R values versus pulse
    OutputString = regexprep(num2str(Res),'\s*',',');
    OutputString = [num2str(index) 'E,' OutputString];
    
    fprintf(TESTfile,'%s\n',OutputString);
    
    % Perform Program to Low Resistance
    [PulseCount,Res] = PROGRAM(TargetRon,FV,PGM_PW,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW,PGM_Icomp,index); 
    
    PCP = PulseCount;
    Ron = Res(length(Res));
    disp(['  CYCLE FINISHED Ron: ' num2str(Ron)]);
    
    % Store Data to Buffer
    OutputString = regexprep(num2str(Res),'\s*',',');
    OutputString = [num2str(index) 'P,' OutputString];
    fprintf(TESTfile,'%s\n',OutputString);    

    % Output Summary Data
    fprintf(TESTres,'%d,%f,%f,%f,%d,%d\n',index,Ron,Roff,Roff/Ron,PCE,PCP);
    
    % Check Ron/Roff Ratio, Return if not met
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