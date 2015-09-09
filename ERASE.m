function [PulseCount,Res] = ERASE(TargetRoff,Vpulse,PulseWidth,MaxCycle,BiasTerminal,GndTerminal,ReadVoltage,ReadTime,Icomp,index) 

% RESET function
% In Order to use ERASE, the relays should be externally called and
% enabled and disabled.  This is done to reduce wear on the relays
%
% Index is the current P/E cycle
%
% ERASE: LOW Resistance to HIGH Resistance (RESET)
%
% Modified by Jeremy Smith 2015/03/19
% Email: j-smith@eecs.berkeley.edu

if nargin < 10
   index = 1; 
end

CycleDone = 0;

Current = PULSE_READ(ReadVoltage,ReadTime,BiasTerminal,GndTerminal,false,0);

% Calculated OFF resistance
Roff = abs(ReadVoltage/Current);
disp(['ERASE Start Roff: ' num2str(Roff)]);

Res = 0; % Initialize

% Insert the following "if" statement, to make sure something is written to Res
if (Roff >= TargetRoff)
    Res  = Roff;
end

while ((CycleDone < MaxCycle) && (Roff < TargetRoff))
    WriteCurrent = PULSE_VOLTAGE(Vpulse,PulseWidth,BiasTerminal,GndTerminal,false,Icomp);
    disp(['    Write current: ' num2str(WriteCurrent)]);
    
    % WAIT state to make sure the device is stable
    pause(0.1);
    
    % Need to do the following, because for SOME REASON PULSE_READ
    % sometimes gets negative results and fucks everything up
    Current = PULSE_READ(ReadVoltage,ReadTime,BiasTerminal,GndTerminal,false,0);
    while(Current < 0)
        Current = PULSE_READ(ReadVoltage,ReadTime,BiasTerminal,GndTerminal,false,0);
    end
    
    % Calculated OFF resistance
    Roff = abs(ReadVoltage/Current);
    Res(CycleDone+1) = Roff;
    CycleDone = CycleDone + 1;
    disp(['    Index: ' num2str(index) ' Erase Pulse: ' num2str(CycleDone) ' Roff: ' num2str(Roff)]);
end

PulseCount = CycleDone;

end