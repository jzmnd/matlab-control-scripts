function Time = clock2sec(clocktime)

% Convert clock to time in seconds

Time = clocktime(4)*60*60 + clocktime(5)*60 + clocktime(6);

end