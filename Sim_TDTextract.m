%% TDT extract - Isis Alonso, November 2020 
%This function extracts data from two set up fibre photometry it produces
%the raw data extracted, as well as the sampling rate and time for further
%analysis depending on the transformation the researcher wishes to make 

%%%TO DO: make it so the script knows whether it's left or right set up
%%%channels

function [data, events, ts, conversion] = Sim_TDTextract(path_to_data)

res = 64; %downsampling factor

% set up Tank name, variables to extract
tankdir = path_to_data;

% tev_path = strcat(path_to_data,'/',uigetfile('*.tev'));
% tsq_path = strcat(path_to_data,'/',uigetfile('*.tsq'));

cd(path_to_data);
[a, evn] = tdtcall_IA(path_to_data); %extract the events (timestamp names)
tevfile=dir('*.tev');
tsqfile=dir('*.tsq');
tev_path = strcat(path_to_data,'/', tevfile.name);
tsq_path = strcat(path_to_data,'/', tsqfile.name);

% extract photometry signals
for k = 1:numel(a)
  storename = a{k}; 
  dat{k} = tdt2mat(tankdir, storename, tev_path, tsq_path);
end
% extract timestamps for events
if ~isempty(evn)
for k = 1:numel(evn)
  storename = evn{k}; 
  ev{k} = tdt2mat(tankdir, storename, tev_path, tsq_path);
end
else
    warning('NO EVENTS in tank!\n')
end

%% Get the control and signal data

% Get LMag data as a vector (repeat for each channel)
%NEED TO MAKE THIS MORE GENERAL 
for i = 1:length(dat)
    clear tmp 
    LMag = dat{i};
    chani = LMag.channels == 1;
    data{i,1} = dat{i}.storename;
   tmp = dat{i}.data(chani,:); 
   data{i,2} = resample(reshape(tmp', [], 1), 1, res);
end

% chani1 = LMag.channels==1;
% Get LMag timestamps (use chani1 - timestamps should be the same for all Wpht channels
ts = LMag.timestamps(chani);
t_rec_start = ts(1); ts = ts-ts(1); % convert from Unix time to 'seconds from block start' 
ts = bsxfun(@plus, ts(:), (0:LMag.npoints-1)*(1./LMag.sampling_rate));
ts = reshape(ts',[],1);
 

%% Get timestamps from events
if exist('ev', 'var')
for i = 1:length(ev) % unwrap event data  and put it on left or right structs
  events{i,1} = ev{i}.storename;
  tmp = ev{i}.timestamps; events{i,2}= tmp-t_rec_start; 
end
else
    events = [];
end

 conversion = LMag.sampling_rate/res;
 ts = downsample(ts, res);


end



