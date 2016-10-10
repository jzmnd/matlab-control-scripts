function testing()

global OBJ4155;
BiasTerminal = '1';     % SMU bias
GndTerminal = '3';      % SMU ground

ERS_PW = 0.100;         % Erase pulse width (sec)
PGM_PW = 0.100;         % Program pulse width (sec)
FV = 2.0;               % Write voltages
RV = -2.0;
RD_PW = 0.100;          % Read pulse width (sec)
Vread = 0.20;           % Read voltage

Icomp = 0.02;

disp('CYCLE TESTING TROUBLESHOOT');
% Suppress Warning Message from using custom fit for resistance slope fit
warning off curvefit:fit:noStartPoint;

% Enables SMUs for the cycling test
fprintf(OBJ4155, 'FMT 2,0'); % Output Data w/o Header
fprintf(OBJ4155, ['FL 0,' BiasTerminal]); % Turn Off Filter
fprintf(OBJ4155, ['FL 0,' GndTerminal]);  % Turn Off Filter
fprintf(OBJ4155, ['MM 3,' BiasTerminal]); % 3: 1ch pulsed spot measurement
fprintf(OBJ4155, ['CN ' BiasTerminal ',' GndTerminal]);

Count = 0;
while(true)
    disp(num2str(Count));
    
    Current = PULSE_VOLTAGE(FV,PGM_PW,BiasTerminal,GndTerminal,false,Icomp,0);
    disp(['Write Current: ' num2str(Current)]);
    disp(['Write Voltage: ' num2str(FV)]);
    resistance = FV / Current;
    disp(['Resistance: ' num2str(resistance)]);

    Current = PULSE_READ(Vread,RD_PW,BiasTerminal,GndTerminal,false,0);
    disp([' Read Current: ' num2str(Current)]);
    disp([' Read Voltage: ' num2str(Vread)]);
    resistance = Vread / Current;
    disp([' Resistance: ' num2str(resistance)]);
    
    Current = PULSE_VOLTAGE(RV,ERS_PW,BiasTerminal,GndTerminal,false,Icomp,0);
    disp(['Write Current: ' num2str(Current)]);
    disp(['Write Voltage: ' num2str(RV)]);
    resistance = RV / Current;
    disp(['Resistance: ' num2str(resistance)]);

    Current = PULSE_READ(Vread,RD_PW,BiasTerminal,GndTerminal,false,0);
    disp([' Read Current: ' num2str(Current)]);
    disp([' Read Voltage: ' num2str(Vread)]);
    resistance = Vread / Current;
    disp([' Resistance: ' num2str(resistance)]);
    
    pause(1.0);
    
    Count = Count + 1;
end

end
