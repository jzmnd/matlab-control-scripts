function Current = PULSE_READ(Vpulse,PulseWidth,BiasTerminal,GndTerminal,Relay,HoldTime)

% Pulse Voltage for READ
% Pulse Width
% Relay: True: Toggle Relays, False: Do Not Toggle Relays [Save Relay Life]
% Hold Time
%
% Return Measured Current
%
% Commented Out by Shong Yin, 2010/01/13
% Identical to Pulse Voltage, but waits for valid data on measurement
% instead of constraining pulse width
%
% Modified by Jeremy Smith 2015/03/19
% Email: j-smith@eecs.berkeley.edu

global OBJ4155;

if(nargin < 6)
    HoldTime = 0;
end
if(nargin < 5)
    Relay = true;
end
if(nargin < 4)
    GndTerminal = '3';
end
if(nargin < 3)
    BiasTerminal = '1';
end
if(nargin < 2)
    PulseWidth = 0.001; % 1ms default pulse width    
end
if(nargin < 1)
    disp('ERROR: NOT ENOUGH ARGUMENTS');
    return;
end

% Time Input Parameters
Hold = num2str(HoldTime);
Width = num2str(PulseWidth);
Period = num2str(0.01 + PulseWidth); % 10ms pulse gap
Delay = '0'; % Trigger Delay

% IV Input Parameters
Range = '0'; % Auto-ranging
Vbase = '0'; % 0V base voltage
Vbias = num2str(Vpulse);
Vgnd = '0';
Icomp = '0.02'; % Read Current Compliance (A)
Priority = '1'; % 1: Wait for measurement 0: Keep pulse width

% Set up Parameters
fprintf(OBJ4155, 'FMT 2,0'); % Output Data w/o Header
fprintf(OBJ4155, ['FL 0,' BiasTerminal]); % Turn Off Filter
if(Relay)
    fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);
end

% Set Measurement Mode
fprintf(OBJ4155, ['MM 3,' BiasTerminal]); % 3: 1ch pulsed spot measurement

% GND Terminal
fprintf(OBJ4155, ['DV ' GndTerminal ',' Range ',' Vgnd ',' Icomp]);

% BIAS Terminal
fprintf(OBJ4155, ['PT ' Hold ',' Width ',' Period ',' Delay ',' Priority]);
fprintf(OBJ4155, ['PV ' BiasTerminal ',' Range ',' Vbase ',' Vbias ',' Icomp]);

% Execute Measurement
fprintf(OBJ4155, 'XE'); % Initiate Single Measurement

% Check for Errors
fprintf(OBJ4155, ':SYST:ERR?');
BufferStr = fscanf(OBJ4155);

[Code, Message] = strread(BufferStr,'%d%s','delimiter',',');

if(Code ~= 0)
    disp(['ERROR: ' num2str(Code) ',' char(Message)]);
    beep;
    return;
end

% Read Back Data
fprintf(OBJ4155, 'RMD? ');
BufferStr = fscanf(OBJ4155);
Current = str2num(BufferStr);

if(Relay)
    fprintf(OBJ4155, 'CL');
end

end