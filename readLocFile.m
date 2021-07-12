function [loc,header] = readLocFile(fname)
% loads a file holding a loc, loc3 or loc4 data
% for loc4 files which have a header, loc is an array holding the data, header is a
% cell array holding the variables in the table.
% for loc and loc3 files which are raw columns of data, loc is an array holding the data, header is an
% empty cell array

    [~,~,ext] = fileparts(fname);
    if strcmp(ext,'.loc4')
        loc = readtable(fname,'FileType','text','Delimiter','\t');
        header = loc.Properties.VariableNames;
        loc = table2array(loc);
    else
        loc = load(fname);
        header = {};
    end
end
