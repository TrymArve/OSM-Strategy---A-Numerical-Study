function[time_string] = sec2str(sec)

% Tryms function for converting a double containing a number of seconds
% into a string in the 'hh mm ss'-format

if ~isa(sec,'double')
    error('ERROR: connot convert seconds to time-string, since the argument is not a double')
end

if sec < 0
    sec = -sec;
    neg = -1;
else 
    neg = 1;
end

hours = floor(sec/(60*60));
sec = sec - hours*(60*60);

min = floor(sec/60);
sec = sec - min*60;


h = num2str(hours*neg);
m = num2str(min*neg);
s = num2str(sec*neg);

% if size(h,2) < 2
%     h = ['0',h];
% end
% 
% if size(m,2) < 2
%     m = ['0',m];
% end
% 
% if floor(sec) < 10
%     s = ['0',s];
% end

if ~isempty(find(s == 'e',1))
    % do nothing, because the string is already in standard form
elseif isempty(find(s == '.',1))
    s = [s,'.0000'];
else
    s = [s,'0000'];
    s = s(1:7);
end

time_string = '(';
if hours > 0
    time_string = [time_string, h, 'hours '];
end
if min > 0
    time_string = [time_string, m, 'min ']; 
end
if sec > 0
    time_string = [time_string, s, 'sec']; 
end
time_string = [time_string, ')'];

end
