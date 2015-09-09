function reten(NumberCycles,Vpulse,Vread,MaxCycle,Filename)
%
%   This one implements time delay - 4/15/10
%
%   Note: Works for individual RRAM devices not CRS
%   because CRS requires a destructive read
%
%   NumberCycles: 10 by default
%   Vpulse: initial program or erase pulse, 3V by default
%   Vread: read voltage, 0.1V by default
%   MaxCycle: max number of initial program/erase pulses 100 by default 
%   Filename: data by default
%
%   Modified by Jeremy Smith 2015/05/06
%   Email: j-smith@eecs.berkeley.edu
%

% Modify Parameters here for convenience
global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground
TargetRon = 1000;       % Target value of Ron (ohms)
TargetRoff = 50000;     % Target value of Roff (ohms)
ERS_PW = 0.005;         % Erase pulse width (sec)
PGM_PW = 0.010;         % Program pulse width (sec)
RD_PW = 0.100;          % Read pulse width (sec)
ERS_Icomp = 0.020;      % Erase compliance (A)
PGM_Icomp = 0.001;      % Program compliance (A)

if(nargin < 5)
    Filename = 'data';
end
if(nargin < 4)
    MaxCycle = 100;
end
if(nargin < 3)
    Vread = 0.1;
end
if(nargin < 2)
    Vpulse = 3.0;
end
if(nargin < 1)
    NumberCycles = 10;
end

disp('RETENTION TESTING');
% Suppress Warning Message from using custom fit for resistance slope fit
warning off curvefit:fit:noStartPoint;

% Append Time to filenames to prevent overlap
TimeVect = fix(clock);
TimeVect = regexprep(num2str(TimeVect(4:6)),'\s*','_');
IVfilename = [Filename '_reten' '_' TimeVect '.csv'];

% If files do not exist, open with append
TESTfile = fopen(IVfilename,'a','native','US-ASCII'); 
fprintf(TESTfile, '%s\n', 'Time, Res, ReadV');

% Open up the relay switches for the cycling test
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);

% Programming or Erase voltage step
if Vpulse > 0
    [~,StartRes] = PROGRAM(TargetRon,Vpulse,PGM_PW,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW,PGM_Icomp);
    if (StartRes > TargetRon)
        disp('FAIL: ON Resistance target not met');
        fclose(TESTfile);
        fprintf(OBJ4155, 'CL');
        warning on curvefit:fit:noStartPoint;
        return;
    end
else
    [~,StartRes] = ERASE(TargetRoff,Vpulse,ERS_PW,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW,ERS_Icomp);
    if (StartRes < TargetRoff)
        disp('FAIL: OFF Resistance target not met');
        fclose(TESTfile);
        fprintf(OBJ4155, 'CL');
        warning on curvefit:fit:noStartPoint;
        return;
    end
end

% === Setup Zero Time ===
cur_time = clock;
base_seconds = clock2sec(cur_time);

% Setup For Loop to Run Cycles
for index = 1:NumberCycles
    
    cur_time = clock;
    Current = PULSE_READ(Vread,RD_PW,BiasTerminal,GndTerminal,false);

    Res = abs(Vread/Current);    % Calculated resistance
    
    seconds = clock2sec(cur_time) - base_seconds;
    
    write_data = ([num2str(seconds) ',' num2str(Res) ',' num2str(Vread)]);
    fprintf(TESTfile, '%s\n', write_data);
    
    disp(['Cycle: ' num2str(index)  ',  Time: ' num2str(seconds) ',  Res: ' num2str(Res)]);
    
    if (index < 10)
        pause(0.5);      % 0.5 sec wait for 0-10 cycles
    elseif (index < 100)
        pause(5);        % 5 sec wait for 10-100 cycles
    elseif (index < 1000)
        pause(50);       % 50 sec wait for 100-1000 cycles
    else
        pause(500);      % 500 sec wait for >1000 cycles
    end  
    
end

% Close file
fclose(TESTfile);

% Close Relay switches
fprintf(OBJ4155, 'CL');

% re-enable warning for testing
warning on curvefit:fit:noStartPoint;

end