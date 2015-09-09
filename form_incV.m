function form_incV(MaxCycles,Vpulsestart,Vpulsestop,Vread,Filename)
%
%   MaxCycles: Max cycles before increasing Vpulse, 10 by default
%   Vpulsestart: initial form pulse, 2V by default
%   Vpulsestop: final form pulse, 6V by default
%   Vread: read voltage, 1.5V by default
%   Filename: data by default
%
%   Device forming
%   Pulsed form scheme from Vpulsestart to Vpulsestop
%
%   Created by Jeremy Smith 2015/06/23
%   Email: j-smith@eecs.berkeley.edu
%

% Modify Parameters here for convenience
global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground
TargetRon = 5000;       % Target value of Ron (ohms)
Vstep = 0.2;            % Voltage step
FRM_PW = 0.010;         % Form pulse width (sec)
RD_PW = 0.050;          % Read pulse width (sec)
FRM_Icomp = 0.001;      % Form compliance (A)

if(nargin < 5)
    Filename = 'data';
end
if(nargin < 4)
    Vread = 1.5;
end
if(nargin < 3)
    Vpulsestop = 6.0;
end
if(nargin < 2)
    Vpulsestart = 2.0;
end
if(nargin < 1)
    MaxCycles = 10;
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
fprintf(TESTfile, '%s\n', 'Cycle, Pulse, Res, Vpulse');

% Open up the relay switches for the test
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);

chk = false;  % Check for end of while loop (true = device formed)
pindex = 0;

while chk == false
    Vpulse = Vpulsestart + pindex*Vstep;  % Vpulse increases by Vstep each loop
    if Vpulse > Vpulsestop
        disp('FAIL: ON Resistance target not met');
        break
    end
    disp(['Cycle: ' num2str(pindex)]);
    
    for index = 1:MaxCycles
        % Applies positive write pulse (0-state) then negative write pulse (1-state)
        PULSE_VOLTAGE(Vpulse,FRM_PW,BiasTerminal,GndTerminal,false,FRM_Icomp,0);
        pause(0.1);
        PULSE_VOLTAGE(-Vpulse,FRM_PW,BiasTerminal,GndTerminal,false,FRM_Icomp,0);
        pause(0.1);
    
        % Reads CRS device to check required ON resitance has been met
        Current = PULSE_READ(Vread,RD_PW,BiasTerminal,GndTerminal,false);
        Res = abs(Vread/Current);    % Calculated resistance
        disp(['    Pulse: ' num2str(index) ', Vpulse: ' num2str(Vpulse)  ',  Res: ' num2str(Res)]);

        write_data = ([num2str(pindex) ',' num2str(index) ',' num2str(Res) ',' num2str(Vpulse)]);
        fprintf(TESTfile, '%s\n', write_data);
        if Res < TargetRon
            chk = true;
            disp(['FORMED: ON Resistance: ' num2str(Res)]);
            break
        end
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