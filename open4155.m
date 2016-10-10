function open4155()

% Opens connection to 4155
% Modified by Jeremy Smith 2015/03/19

objs = instrfind;
if (isempty(objs)~=1)
    disp('ERROR: Already Connected')
    return
end
    
%1.  Create the gpib object
global MAX4155BUF
global OBJ4155

MAX4155BUF = 1056;
% The GPIB controller card number, this is the LOGICAL UNIT in the Agilent IO config software
BoardNumber = 7;        
DeviceNumber = 11;      % This is device settable

OBJ4155 = gpib('agilent',BoardNumber,DeviceNumber);

%2.  Configure the gpib object
% Large input buffer.  This makes room for bringing in a lot of data.
set(OBJ4155,'InputBufferSize',2000000);

%3. Connect to the object
fopen(OBJ4155);                % Open communication
fprintf(OBJ4155, '*RST');
fprintf(OBJ4155, '*CLS');
warning off instrument:fscanf:unsuccessfulRead;
warning off MATLAB:nonIntegerTruncatedInConversionToChar

%4. Set Measurement Parameter to use FLEX Commands
fprintf(OBJ4155, 'US');

disp('Connected to:');
disp(OBJ4155);

end