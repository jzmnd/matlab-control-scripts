function [PulseCount,Res] = PROGRAM(TargetRon,Vpulse,PulseWidth,MaxCycle,BiasTerminal,GndTerminal,ReadVoltage,ReadTime,Icomp,index)

% SET function
% In Order to use PROGRAM, the relays should be externally called and
% enabled and disabled.  This is done to reduce wear on the relays
%
% Index is the current P/E cycle
%
% PROGRAM: HIGH Resistance to LOW Resistance (SET)
%
% Modified by Jeremy Smith 2015/03/19
% Email: j-smith@eecs.berkeley.edu

if nargin < 10
   index = 1; 
end

CycleDone = 0;

Current = PULSE_READ(ReadVoltage,ReadTime,BiasTerminal,GndTerminal,false,0);

% Calculated ON resistance
Ron = abs(ReadVoltage/Current);
disp(['PROGRAM Start Ron: ' num2str(Ron)]);

Res = 0; % Initialize

% Insert the following "if" statement, to make sure something is written to Res
if (Ron <= TargetRon)
    Res  = Ron;
end

while ((CycleDone < MaxCycle) && (Ron > TargetRon))
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
    
    % Calculated ON resistance
    Ron = abs(ReadVoltage/Current);
    Res(CycleDone+1) = Ron;
    CycleDone = CycleDone + 1;
    disp(['    Index: ' num2str(index) ' Program Pulse: ' num2str(CycleDone) ' Ron: ' num2str(Ron)]);
end

PulseCount = CycleDone;

end