function form(FV,RV,MaxCycles,Vread,Filename)
%
%   MaxCycles: Max cycles before fail
%   Vread: read voltage, 1.5V by default
%   Filename: data by default
%
%   Device forming
%   Pulsed form scheme until target current is met
%
%   Created by Jeremy Smith 2015/07/15
%   Email: j-smith@eecs.berkeley.edu
%

% Modify Parameters here for convenience
global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground
TargetIon = 0.001;      % Target value of Ion (A)
FRM_PW = 0.001;         % Form pulse width (sec)
RD_PW = 0.001;          % Read pulse width (sec)
FRM_Icomp = 0.001;      % Form compliance (A)

if(nargin < 5)
    Filename = 'data';
end
if(nargin < 4)
    Vread = 1.5;
end
if(nargin < 3)
    MaxCycles = 100;
end
if(nargin < 2)
    RV = -2;
end
if(nargin < 1)
    FV = 2;
end

disp('FORMING');
% Suppress Warning Message from using custom fit for resistance slope fit
warning off curvefit:fit:noStartPoint;

% Append Time to filenames to prevent overlap
TimeVect = fix(clock);
TimeVect = regexprep(num2str(TimeVect(4:6)),'\s*','_');
IVfilename = [Filename '_FORM' '_' TimeVect '.csv'];

% If files do not exist, open with append
TESTfile = fopen(IVfilename,'a','native','US-ASCII'); 
fprintf(TESTfile, '%s\n', 'Cycle, Ion');

% Open up the relay switches for the test
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);

chk = false;  % Check for end of while loop (true = device formed)
pindex = 0;

while chk == false
    disp(['Cycle: ' num2str(pindex)]);

    % Applies positive write pulse (0-state) then negative write pulse (1-state)
    PULSE_VOLTAGE(RV,FRM_PW,BiasTerminal,GndTerminal,false,FRM_Icomp,0);
    pause(0.1);
    PULSE_VOLTAGE(FV,FRM_PW,BiasTerminal,GndTerminal,false,FRM_Icomp,0);
    pause(0.1);

    % Reads CRS device to check required ON resitance has been met
    Current = PULSE_READ(Vread,RD_PW,BiasTerminal,GndTerminal,false);
    disp(['    FV: ' num2str(FV) ',  RV: ' num2str(RV) ',  ON Current: ' num2str(Current)]);

    write_data = ([num2str(pindex) ',' num2str(Current)]);
    fprintf(TESTfile, '%s\n', write_data);
    if (Current > TargetIon)
        chk = true;
        disp(['FORMED: ON Current: ' num2str(Current)]);
        break
    end
    if (pindex == MaxCycles)
        disp(['FAILED TO FORMED: ON Current: ' num2str(Current)]);
        break
    end
 
    pindex = pindex + 1;
    
end

% Close file
fclose(TESTfile);

% Close Relay switches
fprintf(OBJ4155, 'CL');

% re-enable warning for testing
warning on curvefit:fit:noStartPoint;

end