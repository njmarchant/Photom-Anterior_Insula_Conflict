function [c, b] = tdtcall_IA(filepath)
% -Phil JRDB, Sylvia Liu
% Modified from: http://jaewon.mine.nu/jaewon/2010/10/04/how-to-import-tdt-tank-into-matlab/
%modified by Isis 10/11/20

files = dir(filepath);
name_path ={files.name};

tev_path = name_path(contains(name_path,'tev'));
tev_path = [filepath filesep tev_path{1}];

tsq_path = name_path(contains(name_path,'tsq'));
tsq_path = [filepath filesep tsq_path{1}];

% open the files
tev = fopen(tev_path);

% count number of tsq records (40 bytes/record)
tsq = fopen(tsq_path); fseek(tsq, 0, 'eof'); ntsq = ftell(tsq)/40; fseek(tsq, 0, 'bof');

% read from tsq
data.size      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  4, 'bof');
data.type      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  8, 'bof');
data.name(:,1) = fread(tsq, [ntsq 1], '*char*1', 39); fseek(tsq, 9, 'bof');
data.name(:,2) = fread(tsq, [ntsq 1], '*char*1', 39); fseek(tsq, 10, 'bof');
data.name(:,3) = fread(tsq, [ntsq 1], '*char*1', 39); fseek(tsq, 11, 'bof');
data.name(:,4) = fread(tsq, [ntsq 1], '*char*1', 39); fseek(tsq, 12, 'bof');
data.chan      = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 14, 'bof');
data.sortcode  = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 16, 'bof');
data.timestamp = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 24, 'bof');
data.fp_loc    = fread(tsq, [ntsq 1], 'int64',  32); fseek(tsq, 24, 'bof');
data.strobe    = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 32, 'bof');
data.format    = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq, 36, 'bof');
data.frequency = fread(tsq, [ntsq 1], 'float',  36);

% TDT timestamps are in Unix time (seconds since 1/1/1970--
% http://en.wikipedia.org/wiki/Unix_time )

allnames = unique(data.name,'rows');
%exclude 'names' that contain ASCII Null character, these are special TDT
%codes.
allnames = allnames(all(double(allnames)~=0,2),:);
allnames = cellstr(allnames);
a = allnames([find(~contains(allnames, 'Cam'))]);
d = a([find(~contains(a, 'Fi1'))]);

% idx = allnames(find(~contains(allnames,'Cam'))); 
% % d = idx(find(~contains(idx,'Fi1'))); 

b = d([find(contains(d,'\')); find(contains(d,'_'))]);
c = d([find(contains(d, 'P')); find(contains(d, 'B'))]); 
%find(contains(d, '5B'))]);



%close files
fclose(tev);
fclose(tsq);
end
