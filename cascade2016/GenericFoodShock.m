clear; close all; clc; 
%% Generic multi-year,food-shock simulation
%  GenericFoodShock.m
% -------------------------------------------
% Summary: Simulations of shock using cascade model based originally on
% Marchand et al (2016) model.  Allows for multi-year shock simulation.
%  
% Inputs:  1) Processed Stocks Data 
%          2) Country list (should be consistent with data above)
%          3) Table to convert country codes from 
%             one list to another (e.g., FAOSTAT to USDA)
%          4) Subset country list
%
% Outputs:
%          1) Network statistics for cereal networks before and after
%          shocks
%          2) Full and subset networks to Circos and Cytoscape
%
% Author: Michael J. Puma, 2016

%% Set environment
clear; clc; close all;
%rootdir = '/Users/michaeljpuma/';
rootdir = '/Users/mpuma/';
EventFolder  = [rootdir 'Dropbox/PumaCascadeModel/'];
FBSfolder = [rootdir 'Dropbox/FAOSTAT_FoodBalanceSheet/'];
ParamFolder = [rootdir 'Dropbox/FoodParameters/'];
TradeFolder  = [rootdir 'Dropbox/FoodMatrices/'];%%ComplexNetworkFood/Matrices/
ReservesFolder  = [rootdir 'FoodReserves/'];
FigFolder  = [EventFolder 'Figures/'];
flag_figstime = 1;

%% Shock specification
%Production decline
initfrac_Prodlost = 0.02; 

%Country list:
% % Laki
% disrupt_countries = {'AUT','BEL','CHN','CZE','DNK','EGY','FIN','FRA','DEU','HUN',...
%     'IND','ITA','JPN','LIE','LUX','NLD','NOR','POL',...
%     'PRT','RUS','ESP','SWE','CHE','GBR'}; %'ISL','SCG','SJM'
% disruptname = 'Laki';

% % % Great Famine of 1315 to 1317
% disrupt_countries = {'BEL','CZE','DNK','FIN','FRA','DEU','ISL','IRL','IMN','LUX'...
%     'NLD','NOR','POL','SWE','GBR'};
% disruptname = 'GreatFamine';

% % % Year without a summmer of 1816
% disrupt_countries = {'AND','AUT','BEL','BIH','CAN','HRV','CZE','EST',...
%     'FIN','FRA','DEU','HUN','ISL','IRL','IMN','ITA','LVA','LIE','LUX','MLT','MCO',...
%     'MNE','NLD','NOR','POL','PRT','SMR','SRB','SVK','SVN','ESP','SWE','CHE','GBR','USA'};
% disruptname = 'NoSummer';
% 
% % % Great Drought of 1876 to 1878
% disrupt_countries = {'DZA','AGO','AUS','BTN','BRA','BRN','KHM','CHN','PRK',...
%     'EGY','IND','IDN','JPN','LAO','MYS','MAR','MMR','PHL','KOR','SGP','ZAF',...
%     'LKA','SDN','THA','VNM'};
% disruptname = 'GreatDrought';
%
% % Nuclear Winter, India-Pakistan conflict
% disrupt_countries = {'PAK','IND'};
% disruptname = 'NuclearWinter'; 
%
% % % % Chinese Famine of 1959 to 1961
% disrupt_countries = {'CHN'};
% disruptname = 'ChineseFamine';
% % 
%Dust Bowl Drought of the 1930s
disrupt_countries = {'USA'};
disruptname = 'DustBowl';
%------------------------------
% South Africa
%disrupt_countries = {'ZAF'};
%disruptname = 'SAfrica';
% % Saudi Arabia
% disruptname = 'SAU';
% disrupt_countries = {'SAU'};
% Ireland
% disruptname = 'UK';
% disrupt_countries = {'GBR'};
%------------------------------

%% Trade data parameters and year to shock network & extract network stats
title_YearA = '2010'; 
Year_A = str2double(title_YearA);
commod_title='cerealsSPAM_tradeAMIS'; 
flow_type='kcal'; 
element='Export_Quantity';

%% Number of consecutive shock years
num_years = 20; %
years = 1:num_years;

%% Simulation Parameters
cfrac = 0;    % fraction of shock absorbed by C before changing trade 
asym = 1;     % asym = 1: shocked countries can't increase their exports if R = 0
kmax = 500;   % max number of iterations
amin = 1e-10;  % any shock below amin (as fraction of net supply) is negligible
tol =  1e-5;  % tolerance for post-cascade diagnostic 
anim_out = 0; % anim_out=1: return dR, dC and dE for each iteration

%% Threshold for stocks to use ratio
% Aggregate calories (wheat, rice, maize)	Bobenrieth, E., Wright, B., &
% Zeng, D. (2013). Stocks-to-use ratios and prices as indicators of
% vulnerability to spikes in global cereal markets. Agricultural Economics,
% 44(s1), 43-52. !!SEE FIGURE 5!!
SUR_threshold = 0.15;
flag_threshold = 1;

%% Item titles and FAO Calorie Content (kcal/100 gram)
num_items=9;
Item_title{1} =  'Wheat';        CalorieContent(1,1) =  334;
Item_title{2} =  'Barley';       CalorieContent(2,1) =  332;
Item_title{3} =  'Maize';        CalorieContent(3,1) =  356;
Item_title{4} =  'Rye';          CalorieContent(4,1) =  319;
Item_title{5} =  'Oats';         CalorieContent(5,1) =  385;
Item_title{6} =  'Millet';       CalorieContent(6,1) =  340;
Item_title{7} =  'Sorghum';      CalorieContent(7,1) =  343;
Item_title{8} =  'OtherCereals'; CalorieContent(8,1) =  346;
Item_title{9} =  'Rice';         CalorieContent(9,1) =  360;

% CalorieContent convert from "per 100 grams" to "per gram"
CalorieContent=CalorieContent/100;

% Full list with **FAOSTAT** country codes
[country_FAOSTATcodes,country_FAOSTATnames,temp] = xlsread([ParamFolder 'countrylist_partialv7_4column_China351.xls']);
index_tradecountry = 1:length(country_FAOSTATnames);
clear temp;

%Conversion table for FAOSTAT-based full list
[~, ~, countrycodeCONVERT] = xlsread([ParamFolder 'country_code_CONVERTv7.xls'],'Sheet1');
countrycodeCONVERT = countrycodeCONVERT(2:end,2:end);
countrycodeCONVERT(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),countrycodeCONVERT)) = {''};

FAOSTATcode = cell2mat(countrycodeCONVERT(:,2));
GAULcode = cell2mat(countrycodeCONVERT(:,6));
ISO3alpha = countrycodeCONVERT(:,9); 
USDAcode = countrycodeCONVERT(:,10);
clearvars countrycodeCONVERT; 

%% *** Identify country codes used in the USDA PSD dataset ***
for i = 1:size(country_FAOSTATcodes,1)
   index = find(FAOSTATcode==country_FAOSTATcodes(i));
   country_USDAtradecodes{i,1}  = USDAcode{index,1};
   country_GAULtradecodes(i,1) = GAULcode(index);
   country_ISO3alphatradecodes{i,1}  = ISO3alpha{index,1};
end

%% Import GDP data from GDP_countrylist_partialv7edit.xls (generated by
% GDP_extraction.m)
[~, ~, raw] = xlsread([ParamFolder 'GDP_countrylist_partialv7edit.xls'],'Sheet1');
raw = raw(2:end,:);
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
cellVectors = raw(:,2);
raw = raw(:,[1,3,4,5,6,7,8]);
data = reshape([raw{:}],size(raw)); % Create output variable
GDPcountrylistpartialv7edit = table; % Create table

% Allocate imported array to column variable names
GDPcountrylistpartialv7edit.CountryFAOSTATCode = data(:,1);
GDPcountrylistpartialv7edit.CountryAbbrev = cellVectors(:,1);
GDPcountrylistpartialv7edit.Year2011 = data(:,2);
GDPcountrylistpartialv7edit.Year2012 = data(:,3);
GDPcountrylistpartialv7edit.Year2013 = data(:,4);
GDPcountrylistpartialv7edit.Year2014 = data(:,5);
GDPcountrylistpartialv7edit.Year2015 = data(:,6);
GDPcountrylistpartialv7edit.GDPAvg = data(:,7);
clearvars data raw cellVectors; % Clear temporary variables
GDPavg = GDPcountrylistpartialv7edit.GDPAvg;
[GDPavg_sort,GDPavg_sortindex] = sort(GDPavg,'descend');

%% Subset countries for plotting
% country_title1= 'G20'; country_print1 = 'G20';
% [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_G20.xls']);
% country_title1= 'G8plus5'; country_print1 = 'G8plus5'; 
% [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_G8plus5.xls']); 
country_title1= 'G8plus5PAK'; country_print1 = 'G8plus5PAK'; 
[countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
    xlsread([ParamFolder 'countrylist_G8plus5_PAK.xls']);
% country_title1= 'G8plus5Irl'; country_print1 = 'G8plus5Irl'; 
% [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_G8plus5Ireland.xls']); 
% country_title1= 'southernAfrica'; country_print1 = 'southernAfrica';
% [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%      xlsread([ParamFolder 'countrylist_southernAfrica.xls']); 
% country_title1= 'Africa'; country_print1 = 'Africa'; 
%  [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_Africa.xls']); 

%% Shock country identification 
IndexC = [];
for i = 1:length(disrupt_countries)
    indtemp = strfind(country_ISO3alphatradecodes, disrupt_countries{i});
    indtemp2 = find(not(cellfun('isempty', indtemp)));
    IndexC(end+1) = indtemp2;
    clear indtemp indtemp2
end

%% Extract network statistics for individual country
%indtemp = strfind(country_FAOSTATnames, 'United States of America');
%indtemp = strfind(country_FAOSTATnames, 'Ireland');
%indtemp = strfind(country_FAOSTATnames, 'Republic of Korea');
%IndexC = find(not(cellfun('isempty', indtemp)));

%% Open trade data (export matrices)
load([TradeFolder 'Trade_Graph_' commod_title '_' flow_type '_' element '_' title_YearA '_' title_YearA '.mat']);
E0_YearA = zeros(max(Graph.Index.Properties.NodeIDs));
for i_link = 1: length(Graph.Data)
    E0_YearA(Graph.Data(i_link,1),Graph.Data(i_link,2))=Graph.Data(i_link,3);
end

% Sum export matrix to get export and import vectors (country totals)
E0_YearA_vec = sum(E0_YearA,2); % export vector
I0_YearA_vec = sum(E0_YearA,1); % import vector

%% Subset countries and add row/column to account for "Rest of World"
% Initialize Rest of World
restofWorld_Index = 1:size(country_FAOSTATcodes,1);
number_subsetCountries1 = length(countrysubset_codes1);

for i_country = 1:number_subsetCountries1   
    subset_index(i_country) = find(FAOSTATcode==countrysubset_codes1(i_country,1));
end
restofWorld_Index(subset_index)=[];

% Subset matrix
E0_YearA_subset = zeros(number_subsetCountries1+1,number_subsetCountries1+1);

for i_country = 1:number_subsetCountries1
    % Assign exports from each subset country 
    % (Identify column in fulll matrix and assign to subset matrix) 
   E0_YearA_subset(1:number_subsetCountries1,i_country)=...
       E0_YearA(subset_index,subset_index(i_country));
   
  E0_YearA_subset(number_subsetCountries1+1,i_country)=...
       nansum(E0_YearA(restofWorld_Index,subset_index(i_country)));   
end

% Import/exports between subset countries and "Rest of World"
for i_country = 1:number_subsetCountries1
E0_YearA_subset(i_country,number_subsetCountries1+1)=...
    nansum(E0_YearA(subset_index(i_country),restofWorld_Index));   
end

% Import/exports amoung "Rest of World"
temp=E0_YearA(restofWorld_Index,restofWorld_Index);
E0_YearA_subset(number_subsetCountries1+1,number_subsetCountries1+1)=nansum(temp(:));

if nansum(E0_YearA_subset(:))/nansum(E0_YearA(:))~=1
    'Error with subset' %#ok<NOPTS>
    return;
end

%% Open reserves data
filename = [ReservesFolder 'CerealStocks_movavg_20022011.txt'];
formatSpec = '%25s%25s%25s%25s%25s%25s%25s%25s%s%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '',  'ReturnOnError', false);
fclose(fileID);
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end
% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

% Allocate imported array to column variable names
WheatReserves = cell2mat(raw(:, 1));
BarleyReserves = cell2mat(raw(:, 2));
MaizeReserves = cell2mat(raw(:, 3));
RyeReserves = cell2mat(raw(:, 4));
OatReserves = cell2mat(raw(:, 5));
MilletReserves = cell2mat(raw(:, 6));
SorghumReserves = cell2mat(raw(:, 7));
OtherCerealReserves = cell2mat(raw(:, 8));
RiceReserves = cell2mat(raw(:, 9));
clearvars filename formatSpec fileID dataArray ans raw col numericData ...
    rawData row regexstr result numbers invalidThousandsSeparator ...
    thousandsRegExp me R;

% Remove any nan
WheatReserves(isnan(WheatReserves)) = 0;
BarleyReserves(isnan(BarleyReserves)) = 0;
MaizeReserves(isnan(MaizeReserves)) = 0;
RyeReserves(isnan(RyeReserves)) = 0;
OatReserves(isnan(OatReserves)) = 0;
MilletReserves(isnan(MilletReserves)) = 0;
SorghumReserves(isnan(SorghumReserves)) = 0;
OtherCerealReserves(isnan(OtherCerealReserves)) = 0;
RiceReserves(isnan(RiceReserves)) = 0;

%% Convert and aggregate reserves
% Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
gramsperMetricTon = 10^6;  % metric ton: unit of weight equal to 1,000 kilograms, or approximately 2,204.6 pounds.

R0_YearA = WheatReserves*10^3*gramsperMetricTon*CalorieContent(1,1) + ...
    BarleyReserves*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    MaizeReserves*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    RyeReserves*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    OatReserves*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    MilletReserves*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    SorghumReserves*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    OtherCerealReserves*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    RiceReserves*1000*gramsperMetricTon*CalorieContent(9,1);

%% Load data from FAOSTAT Food Balance Sheets (FBS): year_start = 1961; year_end =   2013;
%    generated by code CountryMetric_Fragility_Step1.m
%    Units: 1000 metric tons except "kcalpersonday" and "kgpersonyr"
year_FBS = 1961:2013;
index_YearA = find(year_FBS==Year_A);
yroffset = 1;

for i_item = 1:num_items
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Production_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Import_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Export_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_StockVariation_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_DomesticSupply_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Seed_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Waste_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Processed_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Otheruses_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_Food_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_FoodSupply_kcalpersonday_CountryFullList.txt']);
    load([FBSfolder 'FBS_processed/' Item_title{i_item} '_FoodSupply_kgpersonyr_CountryFullList.txt']);
end

%% Extract production for specified year (i.e., YearA)
% Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
P_Wheat_YearA = squeeze(Wheat_Production_CountryFullList(:,index_YearA+yroffset));
P_Barley_YearA = squeeze(Barley_Production_CountryFullList(:,index_YearA+yroffset));
P_Maize_YearA = squeeze(Maize_Production_CountryFullList(:,index_YearA+yroffset));
P_Rye_YearA = squeeze(Rye_Production_CountryFullList(:,index_YearA+yroffset));
P_Oats_YearA = squeeze(Oats_Production_CountryFullList(:,index_YearA+yroffset));
P_Millet_YearA = squeeze(Millet_Production_CountryFullList(:,index_YearA+yroffset));
P_Sorghum_YearA = squeeze(Sorghum_Production_CountryFullList(:,index_YearA+yroffset));
P_OtherCereals_YearA = squeeze(OtherCereals_Production_CountryFullList(:,index_YearA+yroffset));
P_Rice_YearA = squeeze(Rice_Production_CountryFullList(:,index_YearA+yroffset));

% Set NaN values to zero
P_Wheat_YearA(isnan(P_Wheat_YearA))=0;
P_Barley_YearA(isnan(P_Barley_YearA))=0;
P_Maize_YearA(isnan(P_Maize_YearA))=0;
P_Rye_YearA(isnan(P_Rye_YearA))=0;
P_Oats_YearA(isnan(P_Oats_YearA))=0;
P_Millet_YearA(isnan(P_Millet_YearA))=0;
P_Sorghum_YearA(isnan(P_Sorghum_YearA))=0;
P_OtherCereals_YearA(isnan(P_OtherCereals_YearA))=0;
P_Rice_YearA(isnan(P_Rice_YearA))=0;

% Convert to kilocalories and aggregate
P0_YearA_FBS  = P_Wheat_YearA*1000*gramsperMetricTon*CalorieContent(1,1) + ...
    P_Barley_YearA*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    P_Maize_YearA*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    P_Rye_YearA*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    P_Oats_YearA*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    P_Millet_YearA*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    P_Sorghum_YearA*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    P_OtherCereals_YearA*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    P_Rice_YearA*1000*gramsperMetricTon*CalorieContent(9,1);

%% Extract import for specified year (i.e., YearA)
% Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
I_Wheat_YearA = squeeze(Wheat_Import_CountryFullList(:,index_YearA+yroffset));
I_Barley_YearA = squeeze(Barley_Import_CountryFullList(:,index_YearA+yroffset));
I_Maize_YearA = squeeze(Maize_Import_CountryFullList(:,index_YearA+yroffset));
I_Rye_YearA = squeeze(Rye_Import_CountryFullList(:,index_YearA+yroffset));
I_Oats_YearA = squeeze(Oats_Import_CountryFullList(:,index_YearA+yroffset));
I_Millet_YearA = squeeze(Millet_Import_CountryFullList(:,index_YearA+yroffset));
I_Sorghum_YearA = squeeze(Sorghum_Import_CountryFullList(:,index_YearA+yroffset));
I_OtherCereals_YearA = squeeze(OtherCereals_Import_CountryFullList(:,index_YearA+yroffset));
I_Rice_YearA = squeeze(Rice_Import_CountryFullList(:,index_YearA+yroffset));

% Convert to kilocalories and aggregate
I0_YearA_FBS  = I_Wheat_YearA*1000*gramsperMetricTon*CalorieContent(1,1) + ...
    I_Barley_YearA*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    I_Maize_YearA*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    I_Rye_YearA*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    I_Oats_YearA*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    I_Millet_YearA*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    I_Sorghum_YearA*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    I_OtherCereals_YearA*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    I_Rice_YearA*1000*gramsperMetricTon*CalorieContent(9,1);

%% Extract export for specified year (i.e., YearA)
% Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
E_Wheat_YearA = squeeze(Wheat_Export_CountryFullList(:,index_YearA+yroffset));
E_Barley_YearA = squeeze(Barley_Export_CountryFullList(:,index_YearA+yroffset));
E_Maize_YearA = squeeze(Maize_Export_CountryFullList(:,index_YearA+yroffset));
E_Rye_YearA = squeeze(Rye_Export_CountryFullList(:,index_YearA+yroffset));
E_Oats_YearA = squeeze(Oats_Export_CountryFullList(:,index_YearA+yroffset));
E_Millet_YearA = squeeze(Millet_Export_CountryFullList(:,index_YearA+yroffset));
E_Sorghum_YearA = squeeze(Sorghum_Export_CountryFullList(:,index_YearA+yroffset));
E_OtherCereals_YearA = squeeze(OtherCereals_Export_CountryFullList(:,index_YearA+yroffset));
E_Rice_YearA = squeeze(Rice_Export_CountryFullList(:,index_YearA+yroffset));

% Convert to kilocalories and aggregate
E0_YearA_FBS = E_Wheat_YearA*1000*gramsperMetricTon*CalorieContent(1,1) + ...
    E_Barley_YearA*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    E_Maize_YearA*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    E_Rye_YearA*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    E_Oats_YearA*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    E_Millet_YearA*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    E_Sorghum_YearA*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    E_OtherCereals_YearA*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    E_Rice_YearA*1000*gramsperMetricTon*CalorieContent(9,1);


%% Extract stock variation for specified year (i.e., YearA)
%  we take dRsv to be positive if a commodity was consumed from
%  country's i reserves in a given year (leading to a net stock decrease).
%  Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
dRsv_Wheat_YearA = squeeze(Wheat_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Barley_YearA = squeeze(Barley_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Maize_YearA = squeeze(Maize_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Rye_YearA = squeeze(Rye_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Oats_YearA = squeeze(Oats_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Millet_YearA = squeeze(Millet_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Sorghum_YearA = squeeze(Sorghum_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_OtherCereals_YearA = squeeze(OtherCereals_StockVariation_CountryFullList(:,index_YearA+yroffset));
dRsv_Rice_YearA = squeeze(Rice_StockVariation_CountryFullList(:,index_YearA+yroffset));

% Convert to kilocalories and aggregate
dRsv0_YearA = dRsv_Wheat_YearA*1000*gramsperMetricTon*CalorieContent(1,1) + ...
    dRsv_Barley_YearA*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    dRsv_Maize_YearA*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    dRsv_Rye_YearA*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    dRsv_Oats_YearA*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    dRsv_Millet_YearA*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    dRsv_Sorghum_YearA*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    dRsv_OtherCereals_YearA*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    dRsv_Rice_YearA*1000*gramsperMetricTon*CalorieContent(9,1);


%% Network Statistics for baseline network
% (undisturbed) networks
i_YearA = 1;
[ NumbersOfNodes(1,i_YearA),NumbersOfLinks(1,i_YearA),NumNodes_out(1,i_YearA),NumNodes_in(1,i_YearA),TotalFlow(1,i_YearA),...
    lambda_unweight(1,i_YearA), efficiency_unweight(1,i_YearA), radius_unweight(1,i_YearA), diameter_unweight(1,i_YearA),...
    lambda_weight(1,i_YearA), efficiency_weight(1,i_YearA), radius_weight(1,i_YearA), diameter_weight(1,i_YearA), ...
    BC_bin(1,i_YearA), BC_wei(1,i_YearA), s_D_out(1,i_YearA), s_D_in(1,i_YearA), s_D(1,i_YearA)...
    ] ...
    = matrix_stats(E0_YearA,country_ISO3alphatradecodes);

%% Save baseline network statistics to file
StatName = {'# of Nodes';'# of Links';'# of exporting nodes';'# of importing nodes';'Total Trade (tons)';...
    'network (unweighted) characteristic path length'; 'network (unweighted) global efficiency';
    'network radius (unweighted)'; 'network diameter (unweighted)';
    'network (weighted) characteristic path length'; 'network (weighted) global efficiency';
    'network radius (weighted)'; 'network diameter (weighted)'};

OutStats = [ NumbersOfNodes(1,:);NumbersOfLinks(1,:);NumNodes_out(1,:);NumNodes_in(1,:);TotalFlow(1,:);...
    lambda_unweight(1,:); efficiency_unweight(1,:); radius_unweight(1,:); diameter_unweight(1,:);...
    lambda_weight(1,:); efficiency_weight(1,:); radius_weight(1,:); diameter_weight(1,:)];

T = table(OutStats,...
    'RowNames',StatName);
writetable(T,[EventFolder 'Tables/stats_baseline_' title_YearA '.txt'],'WriteRowNames',true);


%% Stocks-to-Use Ratio (SUR) vector for baseline network
SUR_0_YearA = R0_YearA./(P0_YearA_FBS+I0_YearA_vec'-E0_YearA_vec +dRsv0_YearA);

%% Compute "buffer" stocks above the threshold SUR
SUR_buffer = SUR_0_YearA - SUR_threshold;
SUR_buffer(SUR_buffer<0) = 0;
SUR_buffer(isnan(SUR_buffer)) = 0;

R0_YearA_threshold = SUR_buffer.*(P0_YearA_FBS+I0_YearA_vec'-E0_YearA_vec +dRsv0_YearA);
R0_YearA_threshold(isnan(R0_YearA_threshold)) = 0;

%% SUR in target country
SUR_target=zeros(num_years+1,1);
R_target= zeros(num_years+1,1);
SUR_target(1,1) = SUR_0_YearA(IndexC);
R_target(1,1) = R0_YearA(IndexC);
R_target_threshold(1,1) = R0_YearA_threshold(IndexC);

%% Vectors to quatify shock-related production changes for cascade model
dP_YearA = zeros(size(P0_YearA_FBS));
dP_YearA(IndexC) = -initfrac_Prodlost*P0_YearA_FBS(IndexC);

%% Identify "available" stocks
if flag_threshold==0
    R0_YearA_available = R0_YearA;
elseif flag_threshold==1
    R0_YearA_available = R0_YearA_threshold;
end

%%  Simulation Disruptions: functions "sim_cascade" and "sim_diagnostics"
%    as a multi-year disruption
for i_year = 1:num_years
    % **** Call global food network cascade model ***
    [dR_YearA,dC_YearA,dE_YearA,flag_equilibrium] = ...
        sim_cascade(dP_YearA, P0_YearA_FBS, R0_YearA_available, E0_YearA, ...
        cfrac, asym,kmax, amin, anim_out);
    
    % Diagnostic to check simulation
    [ message1, message2 ] = sim_diagnostics( P0_YearA_FBS, E0_YearA, dP_YearA, dR_YearA, dC_YearA, dE_YearA, tol, country_FAOSTATnames);
    if message1 ==1
        ['Total dC + dR does not match initial shock. (Year B)']
        return
    elseif message2 ==2
        ['Net supply change does not match dC + dR for countries. (Year B)']
        return
    end
    
    % Save changes for each year
    dE_YearA_save(:,:,i_year) = dE_YearA(:,:);
    dR_YearA_save(:,i_year) = dR_YearA(:);
    dC_YearA_save(:,i_year) = dC_YearA(:);
    
    % Update export matrix trade flows
    WD(:,:) = E0_YearA + dE_YearA;
    WD_YearA_save(:,:,i_year) = WD(:,:);
    
    % Update Food Balance (Imports,Exports,Production, Reserves)
    E0_YearA_update = sum(WD,2);             % export vector
    I0_YearA_update = sum(WD,1)';            % import vector
    P0_YearA_update = P0_YearA_FBS+dP_YearA; % production vector

    R0_YearA_available = R0_YearA_available + dR_YearA;
    R0_YearA_available(find(R0_YearA_available<0))=0;

    % Update SUR
    % Note: dRsv is positive if a commodity was consumed
    %       dR_YearA is negative if commodity is consumed (used reserves to
    %       absorb shock)
    R_target(i_year+1,1)  = R0_YearA_available(IndexC);
    SUR_target(i_year+1,1) = R0_YearA_available(IndexC)./(P0_YearA_update(IndexC)+I0_YearA_update(IndexC)-E0_YearA_update(IndexC) +dRsv0_YearA(IndexC)-dR_YearA(IndexC));
    
    %Clear yearly variables
    clear dE_YearA dR_YearA dC_YearA
    
    % Compute network statistics
    [ NumbersOfNodes_EXP(i_year,1),NumbersOfLinks_EXP(i_year,1),...
        NumNodes_out_EXP(i_year,1) ,NumNodes_in_EXP(i_year,1),...
        TotalFlow_EXP(i_year,1) ,...
        lambda_unweight_EXP(i_year,1), efficiency_unweight_EXP(i_year,1),...
        radius_unweight_EXP(i_year,1) , diameter_unweight_EXP(i_year,1) ,...
        lambda_weight_EXP(i_year,1) , efficiency_weight_EXP(i_year,1),...
        radius_weight_EXP(i_year,1) , diameter_weight_EXP(i_year,1), ...
        BC_bin_EXP(i_year,1), BC_wei_EXP(i_year,1),...
        s_D_out_EXP(i_year,1),s_D_in_EXP(i_year,1),s_D_EXP(i_year,1)...
        ] ...
        = matrix_stats(WD,country_ISO3alphatradecodes );
end


%% Subset matrix and add additional row/column for "Rest of World"
WD_YearA_final= squeeze(WD_YearA_save(:,:,end));
WD_YearA_final_subset = zeros(number_subsetCountries1+1,number_subsetCountries1+1);

for i_country = 1:number_subsetCountries1
    
    % Assign exports from each subset country
    % (Identify column in fulll matrix and assign to subset matrix)
    WD_YearA_final_subset(1:number_subsetCountries1,i_country)=...
        WD_YearA_final(subset_index,subset_index(i_country));
    
    WD_YearA_final_subset(number_subsetCountries1+1,i_country)=...
        nansum(WD_YearA_final(restofWorld_Index,subset_index(i_country)));
end

% Import/exports between subset countries and "Rest of World"
for i_country = 1:number_subsetCountries1
    WD_YearA_final_subset(i_country,number_subsetCountries1+1)=...
        nansum(WD_YearA_final(subset_index(i_country),restofWorld_Index));
end

% Import/exports amoung "Rest of World"
temp=WD_YearA_final(restofWorld_Index,restofWorld_Index);
WD_YearA_final_subset(number_subsetCountries1+1,number_subsetCountries1+1)=nansum(temp(:));

if abs(nansum(WD_YearA_final_subset(:))/nansum(WD_YearA_final(:))-1)>1e-14
    'Error with subset' %#ok<NOPTS>
    return;
end


%% Save network statistics to table
StatName = {'# of Nodes';'# of Links';'# of exporting nodes';'# of importing nodes';'Total Trade (tons)';...
    'network (unweighted) characteristic path length'; 'network (unweighted) global efficiency';
    'network radius (unweighted)'; 'network diameter (unweighted)';
    'network (weighted) characteristic path length'; 'network (weighted) global efficiency';
    'network radius (weighted)'; 'network diameter (weighted)'};

i_YearA = 1;
OutStats_YearA = [ NumbersOfNodes_EXP(:,i_YearA)';NumbersOfLinks_EXP(:,i_YearA)';NumNodes_out_EXP(:,i_YearA)';NumNodes_in_EXP(:,i_YearA)';TotalFlow_EXP(:,i_YearA)';...
    lambda_unweight_EXP(:,i_YearA)'; efficiency_unweight_EXP(:,i_YearA)'; radius_unweight_EXP(:,i_YearA)'; diameter_unweight_EXP(:,i_YearA)';...
    lambda_weight_EXP(:,i_YearA)'; efficiency_weight_EXP(:,i_YearA)'; radius_weight_EXP(:,i_YearA)'; diameter_weight_EXP(:,i_YearA)'];

T = table(OutStats_YearA,...
    'RowNames',StatName);
writetable(T,[EventFolder 'Tables/Stats_' disruptname '_' title_YearA '.dat'],'WriteRowNames',true);


%% CIRCOS: Save Networks to file for use by software Circos
cnames = countrysubset_names1(:,2);
cnames{length(countrysubset_names1)+1}='Rest.of.World';

% Original flows
T = table(round(E0_YearA_subset/1e6),...
    'RowNames',cnames);
writetable(T,[EventFolder 'Tables/CerealTrade_millionkcal_Start_' country_print1 '_' title_YearA '_' disruptname '.dat'],'WriteRowNames',true);

% Final flows
T2 = table(round(WD_YearA_final_subset/1e6),...
    'RowNames',cnames);
writetable(T2,[EventFolder 'Tables/CerealTrade_millionkcal_Final_' country_print1 '_' title_YearA '_' disruptname '.dat'],'WriteRowNames',true);


%% CYTOSCAPE: Save Networks to file for use by software Cytoscape
Network = squeeze(dE_YearA_save(:,:,i_year));
% Create 4 column cell arrray (with columns corresponding to Source, Destination, Weight, and Weight -- repeated for plotting)
Network3Col = cell(length(Network)^2,6);

% Assign country codes to all possible links
list_all = 1:length(Network);
max_connects = length(Network); %%%-1;
counter = 1;
i_year = 1;

for i_node = 1:length(Network)
    % Indices counter
    indices = 1+max_connects*(counter-1):max_connects*counter;

    temp = list_all;
    %temp(temp==i_node)=[];
    
    % Data from variable dE_YearA_save (lost exports)
    Network3Col(indices,1)=ISO3alpha(i_node,1);%%%i_node;
    Network3Col(indices,2)=ISO3alpha(:,1);%%% temp;
    Network3Col(indices,3)= num2cell(Network(i_node,:)); % export from source to destination
    Network3Col(indices,4)= num2cell(Network(i_node,:)); % (repeat) export from source to destination
    Network3Col(indices,5)= num2cell(ones(1,length(indices))*nansum(Network(i_node,:))); %total exports of source county
    Network3Col(indices,6)= num2cell(nansum(Network,1)); % Sum columns to get total imports of destination country
    counter= counter+1;
end
clear temp;

% Cytoscape Output: Remove links with NO trade
rm_rows =  find(cell2mat(Network3Col(:,3))==0);
Network3Col(rm_rows,:)=[]; clear rm_rows;
%%dlmcell_mp([FigFolder 'CytoscapeData_Network_LostExport_' disruptname '_' title_YearA '.txt'],Network3Col);


%% Extract network statistics for individual country
%IndexC = strfind(country_FAOSTATnames, 'United States of America');
%IndexC = strfind(country_FAOSTATnames, 'Ireland');
%IndexC = strfind(country_FAOSTATnames, 'Republic of Korea');
%Index = find(not(cellfun('isempty', IndexC)));

%BC_bin_EXP_USA =squeeze(BC_bin_EXP(Index,:,:));
%BC_wei_EXP_USA =squeeze(BC_wei_EXP(Index,:,:));

%% Transient Network Figures
if flag_figstime == 1
    titlename = ['Stocks to Use Ratio in ' country_ISO3alphatradecodes{IndexC}];
    filename = [FigFolder 'SUR_' country_ISO3alphatradecodes{IndexC} '_' disruptname '_' title_YearA '.eps'];
    figure
    plot([0 years],SUR_target,'LineStyle','--','LineWidth',3,'Color',rgb('Crimson'),'Marker','s','MarkerFaceColor',rgb('Crimson'),'MarkerSize',10)
    hold on
    ylabel('SUR','FontSize',24);
    xlabel('Consecutive Years','FontSize',24);
    title([titlename],'FontSize',28)
    set(gca,'Box','on')
    legend(title_YearA)
    set(get(gcf,'CurrentAxes'),'FontSize',18)
    set(gca,'XMinorTick','off')  % sets Minor X Ticks to display
    set(gcf,'Renderer','painters') %only vector graphics that matlab has- painters
    set(gcf,'OuterPosition',[170 1200 1000 500]) %left edge botton edge; width height
    set(gcf,'PaperPositionMode','auto')
    print('-depsc','-painters','-r600',filename)
  
     titlename = ['Reserves in ' country_ISO3alphatradecodes{IndexC}];
    filename = [FigFolder 'R_' country_ISO3alphatradecodes{IndexC} '_' disruptname '_' title_YearA '.eps'];
    figure
    plot([0 years],R_target,'LineStyle','--','LineWidth',3,'Color',rgb('Crimson'),'Marker','s','MarkerFaceColor',rgb('Crimson'),'MarkerSize',10)
    hold on
    ylabel('R','FontSize',24);
    xlabel('Consecutive Years','FontSize',24);
    title([titlename],'FontSize',28)
    set(gca,'Box','on')
    legend(title_YearA)
    set(get(gcf,'CurrentAxes'),'FontSize',18)
    set(gca,'XMinorTick','off')  % sets Minor X Ticks to display
    set(gcf,'Renderer','painters') %only vector graphics that matlab has- painters
    set(gcf,'OuterPosition',[170 1200 1000 500]) %left edge botton edge; width height
    set(gcf,'PaperPositionMode','auto')
    print('-depsc','-painters','-r600',filename)   
    
    titlename = 'Characteristic weighted path length';
    labX = 'Consecutive Years';
    X_data=years;
    labY = '\lambda_{w}';
    Y_data=lambda_weight_EXP;
    filename = [FigFolder 'lambda_weight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,lambda_weight,titlename,filename,leg_names);
    
    titlename = 'Characteristic unweighted path length';
    X_data=years;
    labY = '\lambda';
    Y_data=lambda_unweight_EXP;
    filename = [FigFolder 'lambda_unweight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,lambda_unweight,titlename,filename,leg_names);
    
    titlename = 'Global Network Efficiency (Unweighted)';
    X_data=years;
    labY = 'Efficiency';
    Y_data=efficiency_unweight_EXP;
    filename = [FigFolder 'efficiency_unweight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,efficiency_unweight,titlename,filename,leg_names);
    
    titlename = 'Global Network Efficiency (Weighted)';
    X_data=years;
    labY = 'Efficiency';
    Y_data=efficiency_weight_EXP;
    filename = [FigFolder 'efficiency_weight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,efficiency_weight,titlename,filename,leg_names);
    
    titlename = 'Global Network Radius (Unweighted)';
    X_data=years;
    labY = 'Radius';
    Y_data=radius_unweight_EXP;
    filename = [FigFolder 'radius_unweight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,radius_unweight,titlename,filename,leg_names);
    
    titlename = 'Global Network Radius (Weighted)';
    X_data=years;
    labY = 'Radius';
    Y_data=radius_weight_EXP;
    filename = [FigFolder 'radius_weight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,radius_weight,titlename,filename,leg_names);
    
    titlename = 'Global Network Diameter (Unweighted)';
    X_data=years;
    labY = 'Diameter';
    Y_data=diameter_unweight_EXP;
    filename = [FigFolder 'diameter_unweight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,diameter_unweight,titlename,filename,leg_names);
    
    titlename = 'Global Network Diameter (Weighted)';
    X_data=years;
    labY = 'Diameter';
    Y_data=diameter_weight_EXP;
    filename = [FigFolder 'diameter_weight_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,diameter_weight,titlename,filename,leg_names);
    
    titlename = 'Total Cereal Trade';
    X_data=years;
    labY = 'kcal';
    Y_data=TotalFlow_EXP;
    filename = [FigFolder 'TotalFlow_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,TotalFlow,titlename,filename,leg_names);
    
    titlename = 'Number of Nodes';
    X_data=years;
    labY = 'number';
    Y_data=NumbersOfNodes_EXP;
    filename = [FigFolder 'NumberofNodes_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,NumbersOfNodes,titlename,filename,leg_names);
    
    titlename = 'Number of Links';
    X_data=years;
    labY = 'number';
    Y_data=NumbersOfLinks_EXP;
    filename = [FigFolder 'NumbersOfLinks_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,NumbersOfLinks,titlename,filename,leg_names);
    
    titlename = 'Average Export Flows';
    X_data=years;
    labY = 'kcal';
    Y_data=s_D_out_EXP;
    filename = [FigFolder 'AvgExportFlows_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,s_D_out,titlename,filename,leg_names);
    
    titlename = 'Average Import Flows';
    X_data=years;
    labY = 'kcal';
    Y_data=s_D_in_EXP;
    filename = [FigFolder 'AvgImportFlows_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,s_D_in,titlename,filename,leg_names);
    
    titlename = 'Average Betweenness Centrality';
    X_data=years;
    labY = '-';
    Y_data=BC_bin_EXP;
    filename = [FigFolder 'AvgBtwCentral_' disruptname '_' title_YearA '.eps'];
    leg_names = {title_YearA};
    puma_singleline( X_data,Y_data,labX,labY,BC_bin,titlename,filename,leg_names);
end