function [path,basename, prefix,suffix,ext] = find_basename_and_extension2(varargin)
%function that finds the common elements within files and outputs it along
%with the file-specific prefix and suffix. 
%Assumes the center part only is conserved. Might run into issues if more
%than one stretch is conserved.

%input: structure name with n entries, each a string of a file name
%finds the shared common substring in the set of n file names 
%(ignoring paths and extension) and decomposes each file name name{k} into:
%<path{k}> 
%<prefix{k}>
%<basename> (shared between all files)
%<suffix{k}>
%<ext{k}>

%if no shared substring between file names, basename = '' and each filename
%are entered as the prefix (prefix{k} = name{k}); suffix{k} is also left
%empty

%load and parse file names
k=1;
for i=1:nargin
    if ~iscell(varargin{i})
        [path{k},name{k},ext{k}] = fileparts(varargin{i}); 
        k = k+1;
    else
        for j=1:numel(varargin{i})
            [path{k},name{k},ext{k}] = fileparts(varargin{i}{j}); 
            k = k+1;
        end
    end
end
nfiles = k-1;

%find longest common substring (basename)
basename = name{1};
for i=2:nfiles
    basename = LCSubstr(basename,name{i});
end

if isempty(basename)
    for i=1:nfiles
        prefix{i} = name{i};
        suffix{i} = '';
    end
    return
else
    
end

%isolate file specific prefix and suffix
lb = length(basename);
for i=1:nfiles
    k = strfind(name{i},basename);
    if ~isempty(k)
        l = length(name{i});
        if k==1
            prefix{i} = '';
        else
            prefix{i} = name{i}(1:k-1);
        end

        if k+lb == l+1
            suffix{i} = '';
        else
            suffix{i} = name{i}(k+lb:l);
        end
    else
        disp(['could not find basemane (',basename,') in filename: ',...
            name{k}]);
        prefix{i} = '';
        suffix{i} = '';
    end
end

