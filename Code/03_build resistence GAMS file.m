project_dir = fileparts(mfilename('fullpath'));
input_dir = fullfile(project_dir, 'Output', 'distances');
output_dir = fullfile(project_dir, 'Output', 'GAMS');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end
if exist('wgdx', 'file') == 0
    error('Add the GAMS MATLAB API directory containing wgdx to the MATLAB path.');
end

first = [1 5001 10001 15001 20001 25001 30001 35001 40001];
last = [5000 10000 15000 20000 25000 30000 35000 40000 45808];
files = cell(1, 9);
for k = 1:9
    files{k} = fullfile(input_dir, sprintf('short_Harvdis_production_demand_%d-%d.h5', first(k), last(k)));
    if ~isfile(files{k}), error('Missing input: %s', files{k}); end
end

blocks = cell(1, 9);
for k = 1:9
    blocks{k} = h5read(files{k}, sprintf('/distance_all%d', k));
end
data_all = vertcat(blocks{:});
clear blocks

guel = @(t,v) strcat(t,strsplit(num2str(v)));
[e,f] = size(data_all);
clus3.name = 'distances';
clus3.type = 'parameter';
clus3.val = data_all;
clus3.form = 'full';
clus3.dim = 2;
clus3.uels = {guel('i',1:e) guel('j',1:f)};
wgdx(fullfile(output_dir, 'distanceHisv_all'), clus3);
