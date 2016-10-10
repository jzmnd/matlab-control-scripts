function reten_CRS(NumberCycles,Vpulse,Vread,MaxCycle,Filename)
%
%   This one implements time delay - 4/15/10
%
%   NumberCycles: 10 by default
%   Vpulse: initial program or erase pulse, 3V by default
%   Vread: read voltage, 1.5V by default
%   MaxCycle: max number of initial program/erase pulses 100 by default 
%   Filename: data by default
%
%   Modified for use for CRS with destructive read
%   Rewrites state each cycle
%   Cycle length increases with each cycle
%
%   Modified by Jeremy Smith 2015/05/12
%   Email: j-smith@eecs.berkeley.edu
%

% Modify Parameters here for convenience
global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground
TargetRon = 500;        % Target value of Ron (ohms)
TargetRoff = 10000;     % Target value of Roff (ohms)
ERS_PW = 10;            % Erase pulse width (msec)
PGM_PW = 10;            % Program pulse width (msec)
RD_PW = 100;            % Read pulse width (msec)
ERS_Icomp = 0.020;      % Erase compliance (A)
PGM_Icomp = 0.020;      % Program compliance (A)

if(nargin < 5)
    Filename = 'data';
end
if(nargin < 4)
    MaxCycle = 100;
end
if(nargin < 3)
    Vread = 1.5;
end
if(nargin < 2)
    Vpulse = 3.0;
end
if(nargin < 1)
    NumberCycles = 10;
end

disp('CRS RETENTION TESTING');
% Suppress Warning Message from using custom fit for resistance slope fit
warning off curvefit:fit:noStartPoint;

% Append Time to filenames to prevent overlap
TimeVect = fix(clock);
TimeVect = regexprep(num2str(TimeVect(4:6)),'\s*','_');
IVfilename = [Filename '_CRSreten' '_' TimeVect '.csv'];

% If files do not exist, open with append
TESTfile = fopen(IVfilename,'a','native','US-ASCII'); 
fprintf(TESTfile, '%s\n', 'Time, Res, ReadV');

% Open up the relay switches for the cycling test
fprintf(OBJ4155, 'FMT 2,0'); % Output Data w/o Header
fprintf(OBJ4155, ['FL 0,' BiasTerminal]); % Turn Off Filter
fprintf(OBJ4155, ['FL 0,' GndTerminal]);  % Turn Off Filter
fprintf(OBJ4155, ['MM 3,' BiasTerminal]); % 3: 1ch pulsed spot measurement
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);

% Programming or Erase voltage step
if Vpulse < 0       % note: opposite of standard RRAM - on state formed with -ve voltage
    [~,StartRes] = PROGRAM(TargetRon,Vpulse,PGM_PW/1000,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW/1000,PGM_Icomp);
    if (StartRes > TargetRon)
        disp('FAIL: ON Resistance target not met');
        fclose(TESTfile);
        fprintf(OBJ4155, 'CL');
        warning on curvefit:fit:noStartPoint;
        return;
    end
else
    [~,StartRes] = ERASE(TargetRoff,Vpulse,ERS_PW/1000,MaxCycle,BiasTerminal,GndTerminal,Vread,RD_PW/1000,ERS_Icomp);
    if (StartRes < TargetRoff)
        disp('FAIL: OFF Resistance target not met');
        fclose(TESTfile);
        fprintf(OBJ4155, 'CL');
        warning on curvefit:fit:noStartPoint;
        return;
    end
end

% Setup For Loop to Run Cycles
for index = 1:NumberCycles
    
    % Program or Erase for each cycle without reading
    pause(0.5)
    if Vpulse < 0
        PULSE_VOLTAGE(Vpulse,PGM_PW/1000,BiasTerminal,GndTerminal,false,PGM_Icomp,0);
    else
        PULSE_VOLTAGE(Vpulse,ERS_PW/1000,BiasTerminal,GndTerminal,false,ERS_Icomp,0);
    end
    
    % === Setup Zero Time (now resets base_time each loop) ===
    cur_time = clock;
    base_time = clock2sec(cur_time);
    
    % wait time increases with each cycle (10, 20, 30 sec...)
    if (index < 10)
        pause(10*index);
    % wait time increases with each cycle (100, 200, 300 sec...)
    elseif (index < 20)
        pause(100*(index-9));
    % wait time increases with each cycle (1000, 2000, 3000 sec...)
    else
        pause(1000*(index-18));
    end
    
    cur_time = clock;
    Current = PULSE_READ(Vread,RD_PW/1000,BiasTerminal,GndTerminal,false);
    Res = abs(Vread/Current);    % Calculated resistance
    
    seconds = clock2sec(cur_time) - base_time;
    
    write_data = ([num2str(seconds) ',' num2str(Res) ',' num2str(Vread)]);
    fprintf(TESTfile, '%s\n', write_data);
    
    disp(['Cycle: ' num2str(index)  ',  Time: ' num2str(seconds) ',  Res: ' num2str(Res)]); 
    
end

% Close file
fclose(TESTfile);

% Close Relay switches
fprintf(OBJ4155, 'CL');

% re-enable warning for testing
warning on curvefit:fit:noStartPoint;

end