%%
% 读取 HDF5 文件中的数据
filename = 'G:/short_Harvdis_production_demand_1-5000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all1';  % 替换为你要读取的数据集的名称
data_1 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_5001-10000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all2';  % 替换为你要读取的数据集的名称
data_2 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_10001-15000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all3';  % 替换为你要读取的数据集的名称
data_3 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_15001-20000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all4';  % 替换为你要读取的数据集的名称
data_4 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_20001-25000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all5';  % 替换为你要读取的数据集的名称
data_5 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_25001-30000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all6';  % 替换为你要读取的数据集的名称
data_6 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_30001-35000.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all7';  % 替换为你要读取的数据集的名称
data_7 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part1.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_81 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part2.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_82 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part3.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_83 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part4.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_84 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part5.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_85 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part6.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_86 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part7.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_87 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part8.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_88 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part9.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_89 = h5read(filename, dataset_name);

filename = 'G:/short_Harvdis_production_demand_35001-40000_part10.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all8';  % 替换为你要读取的数据集的名称
data_810 = h5read(filename, dataset_name);

data_8 = [data_81; data_82; data_83; data_84; data_85; data_86; data_87; data_88; data_89; data_810];

filename = 'G:/short_Harvdis_production_demand_40001-45808.h5';  % 替换为你自己的文件路径
dataset_name = '/distance_all9';  % 替换为你要读取的数据集的名称
data_9 = h5read(filename, dataset_name);

data_all = [data_1;data_2;data_3;data_4;data_5;data_6;data_7;data_8;data_9];

%% 输出到GAMS
cd  E:\software\GAMS\41


guel = @(t,v) strcat(t,strsplit(num2str(v)));
[e,f]=size(data_all);
clus3.name ='distances';
clus3.type = 'parameter';
clus3.val = data_all;
clus3.form = 'full';
clus3.dim=2;
clus3.uels={guel('i',1:e) guel('j',1:f)};
wgdx('G:/Foodshed/for gams/distanceHisv_all', clus3);



