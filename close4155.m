function close4155()

% Closes connection to 4155
% Modified by Jeremy Smith 2015/03/19

% Returns all serial port objects existing in memory
objs = instrfind;

if (isempty(objs)~=1)
    disp('Closing:');
    disp(objs);
    fclose (objs);
    delete (objs);
end

clear global MAX4155BUF
clear global OBJ4155