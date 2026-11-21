clear; close all; clc; 
%% Volcanic nulti-year,food-shock simulation
%  LakiEruptionShock.m
% -------------------------------------------
% Summary: Simulations of shock using cascade model based originally on
% Marchand et al (2016) model.  Multi-year shock simulation for Laki-like
% eruption
%  
% Inputs:  1) Processed Stocks Data 
%          4) Country list (should be consistent with data above)
%          5) Table to convert country codes from 
%             one list to another (e.g., FAOSTAT to USDA)
% Outputs:
%          1) Network statistics for cereal networks before and after
%          shocks
%
% Author: Michael J. Puma, 2016

%% Set environment
clear; clc; close all;
%rootdir = '/Users/michaeljpuma/';
rootdir = '/Users/mpuma/';
EventFolder  = [rootdir 'Dropbox/VolcanoShocks/'];
FBSfolder = [rootdir 'Dropbox/FAOSTAT_FoodBalanceSheet/'];
ParamFolder = [rootdir 'Dropbox/FoodParameters/'];
TradeFolder  = [rootdir 'Dropbox/FoodMatrices/'];%%ComplexNetworkFood/Matrices/
ReservesFolder  = [rootdir 'FoodReserves/'];
FigFolder  = [EventFolder 'figures/'];

%% Number of consecutive shock years
num_years = 1; %
years = 1:num_years;


%% Simulation Parameters
cfrac = 0;    % fraction of shock absorbed by C before changing trade 
asym = 1;     % asym = 1: shocked countries can't increase their exports if R = 0
kmax = 500;   % max number of iterations
amin = 1e-10;  % any shock below amin (as fraction of net supply) is negligible
tol =  1e-5;  % tolerance for post-cascade diagnostic 
anim_out = 0; % anim_out=1: return dR, dC and dE for each iteration
num_periods = 2; % number of time periods
initfrac_Prodlost = 0.5;


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
[country_FAOSTATcodes,country_FAOSTATnames,temp] = xlsread([ParamFolder 'countrylist_partialv6_4column_China351.xls']);
index_tradecountry = 1:length(country_FAOSTATnames);
clear temp;

%Conversion table for FAOSTAT-based full list
[~, ~, countrycodeCONVERT] = xlsread([ParamFolder 'country_code_CONVERTv6.xls'],'Sheet1');
countrycodeCONVERT = countrycodeCONVERT(2:end,2:end);
countrycodeCONVERT(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),countrycodeCONVERT)) = {''};

FAOSTATcode = cell2mat(countrycodeCONVERT(:,2));
GAULcode = cell2mat(countrycodeCONVERT(:,6));
ISO3alpha = countrycodeCONVERT(:,9); 
USDAcode = countrycodeCONVERT(:,10);
clearvars countrycodeCONVERT; 

% *** Identify country codes used in the USDA PSD dataset ***
for i = 1:size(country_FAOSTATcodes,1)
   index = find(FAOSTATcode==country_FAOSTATcodes(i));
   country_USDAtradecodes{i,1}  = USDAcode{index,1};
   country_GAULtradecodes(i,1) = GAULcode(index);
   country_ISO3alphatradecodes{i,1}  = ISO3alpha{index,1};
end

%% Subset countries for plotting
% country_title1= 'G20'; country_print1 = 'G20'; 
% [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_G20.xls']); 
% country_title1= 'G8plus5'; country_print1 = 'G8plus5'; 
% [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_G8plus5.xls']); 
% country_title1= 'Africa'; country_print1 = 'Africa'; 
%  [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
%     xlsread([ParamFolder 'countrylist_Africa.xls']); 
country_title1= 'KoreaImport'; country_print1 = 'KoreaImport'; 
 [countrysubset_codes1,countrysubset_names1,countrysubset_info1] = ...
    xlsread([ParamFolder 'countrylist_koreaimport.xls']);


%% Shock specification
% Laki
disrupt_countries = {'ALB','AUT','BLR','BEL','BIH','BGR','CHN',...
    'HRV','CZE','DNK','EGY','EST','FIN','FRA','DEU','GRC','HUN',...
    'IND','IRL','ITA','JPN','LVA','LTU','NLD','NOR','POL',...
    'PRT','ROU','RUS','SVK','SVN','ESP','SWE','CHE',...
    'MKD','UKR','GBR'}; %'ISL','SCG','SJM'
IndexC = [];
for i = 1:length(disrupt_countries)
    
    indtemp = strfind(country_ISO3alphatradecodes, disrupt_countries{i});
    indtemp2 = find(not(cellfun('isempty', indtemp)));
    IndexC(end+1) = indtemp2;
    clear indtemp indtemp2
end

%indtemp = strfind(country_FAOSTATnames, 'United States of America');
%indtemp = strfind(country_FAOSTATnames, 'Ireland');
%indtemp = strfind(country_FAOSTATnames, 'Republic of Korea');
%IndexC = find(not(cellfun('isempty', indtemp)));

%% Open trade data (export matrices)
title_YearA = '2000'; Year_A = str2double(title_YearA);
commod_title='cerealsSPAM_tradeAMIS'; flow_type='kcal'; element='Export_Quantity';
load([TradeFolder 'Trade_Graph_' commod_title '_' flow_type '_' element '_' title_YearA '_' title_YearA '.mat']);
E0_YearA = zeros(max(Graph.Index.Properties.NodeIDs));
for i_link = 1: length(Graph.Data)
    E0_YearA(Graph.Data(i_link,1),Graph.Data(i_link,2))=Graph.Data(i_link,3);
end

title_YearB = '2010'; Year_B = str2double(title_YearB);
commod_title='cerealsSPAM_tradeAMIS'; flow_type='kcal'; element='Export_Quantity';
load([TradeFolder 'Trade_Graph_' commod_title '_' flow_type '_' element '_' title_YearB '_' title_YearB '.mat']);
E0_YearB = zeros(max(Graph.Index.Properties.NodeIDs));
for i_link = 1: length(Graph.Data)
    E0_YearB(Graph.Data(i_link,1),Graph.Data(i_link,2))=Graph.Data(i_link,3);
end

%% Subgroup code
% Initialize Rest of World
restofWorld_Index = 1:size(country_FAOSTATcodes,1);
number_subsetCountries1 = length(countrysubset_codes1);

for i_country = 1:number_subsetCountries1   
    subset_index(i_country) = find(FAOSTATcode==countrysubset_codes1(i_country,1));
end
restofWorld_Index(subset_index)=[];

% Subset matrix
E0_YearB_subset = zeros(number_subsetCountries1+1,number_subsetCountries1+1);

for i_country = 1:number_subsetCountries1
   
    % Assign exports from each subset country 
    % (Identify column in fulll matrix and assign to subset matrix) 
   E0_YearB_subset(1:number_subsetCountries1,i_country)=...
       E0_YearB(subset_index,subset_index(i_country));
   
  E0_YearB_subset(number_subsetCountries1+1,i_country)=...
       nansum(E0_YearB(restofWorld_Index,subset_index(i_country)));   
end

% Import/exports between subset countries and "Rest of World"
for i_country = 1:number_subsetCountries1
E0_YearB_subset(i_country,number_subsetCountries1+1)=...
    nansum(E0_YearB(subset_index(i_country),restofWorld_Index));   
end

% Import/exports amoung "Rest of World"
temp=E0_YearB(restofWorld_Index,restofWorld_Index);
E0_YearB_subset(number_subsetCountries1+1,number_subsetCountries1+1)=nansum(temp(:));

if nansum(E0_YearB_subset(:))/nansum(E0_YearB(:))~=1
    'Error with subset' %#ok<NOPTS>
    break
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
R0_YearB=R0_YearA;


%% Load data from FAOSTAT Food Balance Sheets (FBS): year_start = 1961; year_end =   2013;
%    generated by code CountryMetric_Fragility_Step1.m
%    Units: 1000 metric tons except "kcalpersonday" and "kgpersonyr"
year_FBS = 1961:2013;

index_YearA = find(year_FBS==Year_A);
index_YearB = find(year_FBS==Year_B);
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


%% Extract production data for Year A
% Remove any nan
Wheat_Production_CountryFullList(isnan(Wheat_Production_CountryFullList)) = 0;
Barley_Production_CountryFullList(isnan(Barley_Production_CountryFullList)) = 0;
Maize_Production_CountryFullList(isnan(Maize_Production_CountryFullList)) = 0;
Rye_Production_CountryFullList(isnan(Rye_Production_CountryFullList)) = 0;
Oats_Production_CountryFullList(isnan(Oats_Production_CountryFullList)) = 0;
Millet_Production_CountryFullList(isnan(Millet_Production_CountryFullList)) = 0;
Sorghum_Production_CountryFullList(isnan(Sorghum_Production_CountryFullList)) = 0;
OtherCereals_Production_CountryFullList(isnan(OtherCereals_Production_CountryFullList)) = 0;
Rice_Production_CountryFullList(isnan(Rice_Production_CountryFullList)) = 0;

% Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
P_Wheat_YearA = squeeze(Wheat_Production_CountryFullList(:,index_YearA+yroffset));
P_Barley_YearA = squeeze(Barley_Production_CountryFullList(:,index_YearA+yroffset));
P_Maize_YearA = squeeze(Maize_Production_CountryFullList(:,index_YearA+yroffset));
P_Rye_YearA = squeeze(Rye_Production_CountryFullList(:,index_YearA+yroffset));
P_Oats_YearA = squeeze(Oats_Production_CountryFullList(:,index_YearA+yroffset));
P_Millet_YearA = squeeze(Millet_Production_CountryFullList(:,index_YearA+yroffset));
P_Sorghum_YearA = squeeze(Sorghum_Production_CountryFullList(:,index_YearA+yroffset));
P_OtherCereal_YearA = squeeze(OtherCereals_Production_CountryFullList(:,index_YearA+yroffset));
P_Rice_YearA = squeeze(Rice_Production_CountryFullList(:,index_YearA+yroffset));

% Convert to kilocalories and aggregate
P0_YearA = P_Wheat_YearA*1000*gramsperMetricTon*CalorieContent(1,1) + ...
    P_Barley_YearA*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    P_Maize_YearA*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    P_Rye_YearA*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    P_Oats_YearA*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    P_Millet_YearA*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    P_Sorghum_YearA*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    P_OtherCereal_YearA*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    P_Rice_YearA*1000*gramsperMetricTon*CalorieContent(9,1);

%% Extract production data for Year A
% Conversion: 1000 metric tons -> metric tons -> grams -> kilocalories
P_Wheat_YearB = squeeze(Wheat_Production_CountryFullList(:,index_YearB+yroffset));
P_Barley_YearB = squeeze(Barley_Production_CountryFullList(:,index_YearB+yroffset));
P_Maize_YearB = squeeze(Maize_Production_CountryFullList(:,index_YearB+yroffset));
P_Rye_YearB = squeeze(Rye_Production_CountryFullList(:,index_YearB+yroffset));
P_Oats_YearB = squeeze(Oats_Production_CountryFullList(:,index_YearB+yroffset));
P_Millet_YearB = squeeze(Millet_Production_CountryFullList(:,index_YearB+yroffset));
P_Sorghum_YearB = squeeze(Sorghum_Production_CountryFullList(:,index_YearB+yroffset));
P_OtherCereals_YearB = squeeze(OtherCereals_Production_CountryFullList(:,index_YearB+yroffset));
P_Rice_YearB = squeeze(Rice_Production_CountryFullList(:,index_YearB+yroffset));

% Convert to kilocalories and aggregate
P0_YearB = P_Wheat_YearB*1000*gramsperMetricTon*CalorieContent(1,1) + ...
    P_Barley_YearB*1000*gramsperMetricTon*CalorieContent(2,1) + ...
    P_Maize_YearB*1000*gramsperMetricTon*CalorieContent(3,1) + ...
    P_Rye_YearB*1000*gramsperMetricTon*CalorieContent(4,1) + ...
    P_Oats_YearB*1000*gramsperMetricTon*CalorieContent(5,1) + ...
    P_Millet_YearB*1000*gramsperMetricTon*CalorieContent(6,1) + ...
    P_Sorghum_YearB*1000*gramsperMetricTon*CalorieContent(7,1) + ...
    P_OtherCereals_YearB*1000*gramsperMetricTon*CalorieContent(8,1) + ...
    P_Rice_YearB*1000*gramsperMetricTon*CalorieContent(9,1);





%% Vectors to quatify shock-related production changes for cascade model
dP_YearA = zeros(size(P0_YearA));
dP_YearA(IndexC) = -initfrac_Prodlost*P0_YearA(IndexC);

dP_YearB = zeros(size(P0_YearB));
dP_YearB(IndexC) = -initfrac_Prodlost*P0_YearB(IndexC);

%% Network Statistics for baseline networks
% (undisturbed) networks, Year A 
[ NumbersOfNodes(1,1),NumbersOfLinks(1,1),NumNodes_out(1,1),NumNodes_in(1,1),TotalFlow(1,1),...
    lambda_unweight(1,1), efficiency_unweight(1,1), radius_unweight(1,1), diameter_unweight(1,1),...
    lambda_weight(1,1), efficiency_weight(1,1), radius_weight(1,1), diameter_weight(1,1), ...
    BC_bin(1,1), BC_wei(1,1), s_D_out(1,1), s_D_in(1,1), s_D(1,1)...
    ] ...
    = matrix_stats(E0_YearA,country_ISO3alphatradecodes);

% (undisturbed) networks, Year B 
[ NumbersOfNodes(1,2),NumbersOfLinks(1,2),NumNodes_out(1,2),NumNodes_in(1,2),TotalFlow(1,2),...
    lambda_unweight(1,2), efficiency_unweight(1,2), radius_unweight(1,2), diameter_unweight(1,2),...
    lambda_weight(1,2), efficiency_weight(1,2), radius_weight(1,2), diameter_weight(1,2), ...
    BC_bin(1,2), BC_wei(1,2), s_D_out(1,2), s_D_in(1,2), s_D(1,2)...
    ] ...
    = matrix_stats(E0_YearB,country_ISO3alphatradecodes);

%% Extract stats for USA
%BC_bin_USA =BC_bin(IndexC,:);
%BC_wei_USA =BC_wei(IndexC,:);

% Save statistics to table
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
writetable(T,[EventFolder 'lakiStats_baseline.dat'],'WriteRowNames',true);


%%  Simulation Disruptions: functions "sim_cascade" and "sim_diagnostics"
for i_period = 1:num_periods
    
    for i_year = 1:num_years
        
        if i_period == 1% Year A
            
            % Call global food network cascade model ***
            [dR_YearA,dC_YearA,dE_YearA,flag_equilibrium] = ...
                sim_cascade(dP_YearA, P0_YearA, R0_YearA, E0_YearA, ...
                cfrac, asym,kmax, amin, anim_out);
            
            % Diagnostic to check simulation
            [ message1, message2 ] = sim_diagnostics( P0_YearA, E0_YearA, dP_YearA, dR_YearA, dC_YearA, dE_YearA, tol, country_FAOSTATnames);
            if message1 ==1
                ['Total dC + dR does not match initial shock.']
                return
            elseif message2 ==2
                ['Net supply change does not match dC + dR for countries.']
                return
            end
            
            % Save changes for each year
            dE_YearA_save(:,:,i_year) = dE_YearA(:,:);
            dR_YearA_save(:,i_year) = dR_YearA(:);
            dC_YearA_save(:,i_year) = dC_YearA(:);
            
            % Update "net" trade flows
            WD(:,:) = E0_YearA + dE_YearA;
            WD_YearA_save(:,:,i_year) = WD(:,:);
             
            % Update Reserves
            R0_YearA = R0_YearA + dR_YearA;
            R0_YearA(find(R0_YearA<0))=0;
            
            %Clear yearly variables
            clear dE_YearA dR_YearA dC_YearA
            
            % Compute network statistics after shock cascade 
            [ NumbersOfNodes_EXP(i_year,i_period),NumbersOfLinks_EXP(i_year,i_period),...
                NumNodes_out_EXP(i_year,i_period) ,NumNodes_in_EXP(i_year,i_period),...
                TotalFlow_EXP(i_year,i_period) ,...
                lambda_unweight_EXP(i_year,i_period), efficiency_unweight_EXP(i_year,i_period),...
                radius_unweight_EXP(i_year,i_period) , diameter_unweight_EXP(i_year,i_period) ,...
                lambda_weight_EXP(i_year,i_period) , efficiency_weight_EXP(i_year,i_period),...
                radius_weight_EXP(i_year,i_period) , diameter_weight_EXP(i_year,i_period),...
                BC_bin_EXP(i_year,i_period), BC_wei_EXP(i_year,i_period),...
                s_D_out_EXP(i_year,i_period),s_D_in_EXP(i_year,i_period),s_D_EXP(i_year,i_period)...
                ] ...
                = matrix_stats(WD,country_FAOSTATnames );
            

            
        else% Year B
            
            % **** Call global food network cascade model ***
            [dR_YearB,dC_YearB,dE_YearB,flag_equilibrium] = ...
                sim_cascade(dP_YearB, P0_YearB, R0_YearB, E0_YearB, ...
                cfrac, asym,kmax, amin, anim_out);
            
            % Diagnostic to check simulation
            [ message1, message2 ] = sim_diagnostics( P0_YearB, E0_YearB, dP_YearB, dR_YearB, dC_YearB, dE_YearB, tol, country_FAOSTATnames);
            if message1 ==1
                ['Total dC + dR does not match initial shock. (Year B)']
                return
            elseif message2 ==2
                ['Net supply change does not match dC + dR for countries. (Year B)']
                return
            end
           

            % Save changes for each year
            dE_YearB_save(:,:,i_year) = dE_YearB(:,:);
            dR_YearB_save(:,i_year) = dR_YearB(:);
            dC_YearB_save(:,i_year) = dC_YearB(:);
            
            % Update "net" trade flows
            WD(:,:) = E0_YearB + dE_YearB;
            WD_YearB_save(:,:,i_year) = WD(:,:);
            
            % Update Reserves
            R0_YearB = R0_YearB + dR_YearB;
            R0_YearB(find(R0_YearB<0))=0;
            
            
            %Clear yearly variables
            clear dE_YearB dR_YearB dC_YearB            

           % Compute network statistics
            [ NumbersOfNodes_EXP(i_year,i_period),NumbersOfLinks_EXP(i_year,i_period),...
                NumNodes_out_EXP(i_year,i_period) ,NumNodes_in_EXP(i_year,i_period),...
                TotalFlow_EXP(i_year,i_period) ,...
                lambda_unweight_EXP(i_year,i_period), efficiency_unweight_EXP(i_year,i_period),...
                radius_unweight_EXP(i_year,i_period) , diameter_unweight_EXP(i_year,i_period) ,...
                lambda_weight_EXP(i_year,i_period) , efficiency_weight_EXP(i_year,i_period),...
                radius_weight_EXP(i_year,i_period) , diameter_weight_EXP(i_year,i_period), ...
                BC_bin_EXP(i_year,i_period), BC_wei_EXP(i_year,i_period),...
                s_D_out_EXP(i_year,i_period),s_D_in_EXP(i_year,i_period),s_D_EXP(i_year,i_period)...
                ] ...    
            = matrix_stats(WD,country_ISO3alphatradecodes );
        end
        
    end
    
end


%% Subset matrix
WD_YearB_final= squeeze(WD_YearB_save(:,:,end));
WD_YearB_final_subset = zeros(number_subsetCountries1+1,number_subsetCountries1+1);

for i_country = 1:number_subsetCountries1
    
    % Assign exports from each subset country
    % (Identify column in fulll matrix and assign to subset matrix)
    WD_YearB_final_subset(1:number_subsetCountries1,i_country)=...
        WD_YearB_final(subset_index,subset_index(i_country));
    
    WD_YearB_final_subset(number_subsetCountries1+1,i_country)=...
        nansum(WD_YearB_final(restofWorld_Index,subset_index(i_country)));
end

% Import/exports between subset countries and "Rest of World"
for i_country = 1:number_subsetCountries1
    WD_YearB_final_subset(i_country,number_subsetCountries1+1)=...
        nansum(WD_YearB_final(subset_index(i_country),restofWorld_Index));
end

% Import/exports amoung "Rest of World"
temp=WD_YearB_final(restofWorld_Index,restofWorld_Index);
WD_YearB_final_subset(number_subsetCountries1+1,number_subsetCountries1+1)=nansum(temp(:));

if abs(nansum(WD_YearB_final_subset(:))/nansum(WD_YearB_final(:))-1)>1e-14
    'Error with subset' %#ok<NOPTS>
    break
end


%% Extract stats for USA
%IndexC = strfind(country_FAOSTATnames, 'United States of America');
%IndexC = strfind(country_FAOSTATnames, 'Ireland');
%IndexC = strfind(country_FAOSTATnames, 'Republic of Korea');
%Index = find(not(cellfun('isempty', IndexC)));

%BC_bin_EXP_USA =squeeze(BC_bin_EXP(Index,:,:));
%BC_wei_EXP_USA =squeeze(BC_wei_EXP(Index,:,:));

%% Save statistics to table
StatName = {'# of Nodes';'# of Links';'# of exporting nodes';'# of importing nodes';'Total Trade (tons)';...
    'network (unweighted) characteristic path length'; 'network (unweighted) global efficiency';
    'network radius (unweighted)'; 'network diameter (unweighted)';
    'network (weighted) characteristic path length'; 'network (weighted) global efficiency';
    'network radius (weighted)'; 'network diameter (weighted)'};

OutStats_YearA = [ NumbersOfNodes_EXP(:,1)';NumbersOfLinks_EXP(:,1)';NumNodes_out_EXP(:,1)';NumNodes_in_EXP(:,1)';TotalFlow_EXP(:,1)';...
    lambda_unweight_EXP(:,1)'; efficiency_unweight_EXP(:,1)'; radius_unweight_EXP(:,1)'; diameter_unweight_EXP(:,1)';...
    lambda_weight_EXP(:,1)'; efficiency_weight_EXP(:,1)'; radius_weight_EXP(:,1)'; diameter_weight_EXP(:,1)'];

T = table(OutStats_YearA,...
    'RowNames',StatName);
writetable(T,[EventFolder 'lakiStats_fracRexp_' title_YearA '.dat'],'WriteRowNames',true);

OutStats_YearB = [ NumbersOfNodes_EXP(:,2)';NumbersOfLinks_EXP(:,2)';NumNodes_out_EXP(:,2)';NumNodes_in_EXP(:,2)';TotalFlow_EXP(:,2)';...
    lambda_unweight_EXP(:,2)'; efficiency_unweight_EXP(:,2)'; radius_unweight_EXP(:,2)'; diameter_unweight_EXP(:,2)';...
    lambda_weight_EXP(:,2)'; efficiency_weight_EXP(:,2)'; radius_weight_EXP(:,2)'; diameter_weight_EXP(:,2)'];

T = table(OutStats_YearB,...
    'RowNames',StatName);
writetable(T,[EventFolder 'lakiStats_fracRexp_' title_YearB '.dat'],'WriteRowNames',true);


%% Save Trade data for Circos
cnames = countrysubset_names1(:,2);
cnames{length(countrysubset_names1)+1}='Rest.of.World';

% Original flows
T = table(round(E0_YearB_subset/1e6),...
    'RowNames',cnames);
writetable(T,[EventFolder 'CerealTrade_millionkcal_2010_Start_' country_print1 '.dat'],'WriteRowNames',true);

% Final flows
T2 = table(round(WD_YearB_final_subset/1e6),...
    'RowNames',cnames);
writetable(T2,[EventFolder 'CerealTrade_millionkcal_2010_Final_' country_print1 '.dat'],'WriteRowNames',true);


%% Save Networks to file for use by visualization software Cytoscape
%CYTOSCAPE OUTPUT
Network = squeeze(dE_YearB_save(:,:,i_year));
% Create 4 column cell arrray (with columns corresponding to Source, Destination, Weight, and Weight -- repeated for plotting)
Network3Col = cell(length(Network)^2,6);
% Network3Col_disrupted = cell(length(Network_disrupted)^2,6);
% Network3Col_LOST= cell(length(Network_disrupted)^2,6);

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
    
    % Undisturbed Network
    Network3Col(indices,1)=ISO3alpha(i_node,1);%%%i_node;
    Network3Col(indices,2)=ISO3alpha(:,1);%%% temp;
    Network3Col(indices,3)= num2cell(Network(i_node,:)); % export from source to destination
    Network3Col(indices,4)= num2cell(Network(i_node,:)); % (repeat) export from source to destination
    Network3Col(indices,5)= num2cell(ones(1,length(indices))*nansum(Network(i_node,:))); %total exports of source county
    Network3Col(indices,6)= num2cell(nansum(Network,1)); % Sum columns to get total imports of destination country
    counter= counter+1;
end
clear temp;

%% Remove links with NO trade
rm_rows =  find(cell2mat(Network3Col(:,3))==0);
Network3Col(rm_rows,:)=[]; clear rm_rows;
dlmcell([FigFolder 'CytoscapeData_Network_Lostexports_2010.txt'],Network3Col);
% dlmcell([outfold 'CytoscapeData_NetworkDisrupted' '_' country_print commod_title '_tons_' element '_' disturb_title2 '_' yrname '.txt'],Network3Col_disrupted);
% dlmcell([outfold 'CytoscapeData_NetworkLost' '_' country_print commod_title '_tons_' element '_' disturb_title2 '_' yrname '.txt'],Network3Col_LOST);


%% Figures
titlename = 'Characteristic weighted path length';
labX = 'Consecutive Years w/ 50% US Production Loss';
X_data=years;
labY = '\lambda_{w}';
Y_data=lambda_weight_EXP;
filename = [FigFolder 'lambda_weight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,lambda_weight,titlename,filename,leg_names);

titlename = 'Characteristic unweighted path length';
X_data=years;
labY = '\lambda';
Y_data=lambda_unweight_EXP;
filename = [FigFolder 'lambda_unweight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,lambda_unweight,titlename,filename,leg_names);

titlename = 'Global Network Efficiency (Unweighted)';
X_data=years;
labY = 'Efficiency';
Y_data=efficiency_unweight_EXP;
filename = [FigFolder 'efficiency_unweight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,efficiency_unweight,titlename,filename,leg_names);

titlename = 'Global Network Efficiency (Weighted)';
X_data=years;
labY = 'Efficiency';
Y_data=efficiency_weight_EXP;
filename = [FigFolder 'efficiency_weight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,efficiency_weight,titlename,filename,leg_names);

titlename = 'Global Network Radius (Unweighted)';
X_data=years;
labY = 'Radius';
Y_data=radius_unweight_EXP;
filename = [FigFolder 'radius_unweight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,radius_unweight,titlename,filename,leg_names);

titlename = 'Global Network Radius (Weighted)';
X_data=years;
labY = 'Radius';
Y_data=radius_weight_EXP;
filename = [FigFolder 'radius_weight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,radius_weight,titlename,filename,leg_names);

titlename = 'Global Network Diameter (Unweighted)';
X_data=years;
labY = 'Diameter';
Y_data=diameter_unweight_EXP;
filename = [FigFolder 'diameter_unweight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,diameter_unweight,titlename,filename,leg_names);

titlename = 'Global Network Diameter (Weighted)';
X_data=years;
labY = 'Diameter';
Y_data=diameter_weight_EXP;
filename = [FigFolder 'diameter_weight.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,diameter_weight,titlename,filename,leg_names);

titlename = 'Total Cereal Trade';
X_data=years;
labY = 'kcal';
Y_data=TotalFlow_EXP;
filename = [FigFolder 'TotalFlow.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,TotalFlow,titlename,filename,leg_names);

titlename = 'Number of Nodes';
X_data=years;
labY = 'number';
Y_data=NumbersOfNodes_EXP;
filename = [FigFolder 'NumberofNodes.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,NumbersOfNodes,titlename,filename,leg_names);

titlename = 'Number of Links';
X_data=years;
labY = 'number';
Y_data=NumbersOfLinks_EXP;
filename = [FigFolder 'NumbersOfLinks.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,NumbersOfLinks,titlename,filename,leg_names);

titlename = 'Average Export Flows';
X_data=years;
labY = 'kcal';
Y_data=s_D_out_EXP;
filename = [FigFolder 'AvgExportFlows.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,s_D_out,titlename,filename,leg_names);

titlename = 'Average Import Flows';
X_data=years;
labY = 'kcal';
Y_data=s_D_in_EXP;
filename = [FigFolder 'AvgImportFlows.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,s_D_in,titlename,filename,leg_names);

titlename = 'Average Betweenness Centrality';
X_data=years;
labY = '-';
Y_data=BC_bin_EXP;
filename = [FigFolder 'AvgBtwCentral.eps'];
leg_names = {title_YearA;title_YearB};
puma_line( X_data,Y_data,labX,labY,BC_bin,titlename,filename,leg_names);