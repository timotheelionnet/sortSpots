function save_batch_sort_spots_results_as_Matrix(saveFilename,t,prefix,suffix)
nDigits = 2; % number of digits in channel indices used as variable names.
% leading zeros will be used, e.g. if nDigits = 2 :  ch01, ch02, ch03 etc

%% generate a list variable names that includes for each channel its channel index plus files prefix/suffix
nChannels = numel(prefix) - 1;
if (numel(suffix) - 1 ) ~= nChannels
    disp('prefix and suffix should have the same size. Cannot create output matrix');
    return
end

v = t.properties.VariableNames;
idx = find(ismember(v,'channel'));
if isempty(idx)
    disp('couldn''t find channel in table. Cannot create output matrix');
    return
end

if nChannels ~= max(t(:,idx))
    disp('prefix /suffix info doesn''t match channel numbers in table. Cannot create output matrix');
    return
end

channelVars = cell(1,nChannels);
for i=1:nChannels
    nZeros = nDigits - floor(log(i)/log(10)+1);
    zeroString = repmat('0',1,nZeros);
    channeVars{i} = ['ch',zeroString,num2str(i),'_',prefix{i},'_',suffix{i}];
end

% create new variable string
v2 = [v(1:idx-1),channelVars,v(idx+1:end)];

% omit variable that stores the file name for each channel
v2 = v2(~ismember(v2,{'filename','num_spots','integrated_spotInt'}))

%% compile channel counts into a matrix format
t2 = t(:,~ismember(v,{'filename','num_spots','integrated_spotInt'}));
r = unique(t2,'rows');


end