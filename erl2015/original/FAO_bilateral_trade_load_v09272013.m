clear all; close all; clc;
%% Code to extract trade network structure from the FAOSTAT Bilateral Trade 
% forfiles containing the years 1986 to 2009.  After 2009, files are
% availble by year (i.e. include all commodities within year).

%% flag = 1 disables virtual water weighting, leaving only trade quantity or value 
flag_check_trade = 1; 

%% Start and end years for the study
yr_start =1986; yr_end =2009; 
base_folder = '/Users/admin/Documents/Documents_main/Virtual_water/';
out_folder = '/Users/admin/Documents/Documents_main/Virtual_water/';


%% Load Green and Blue water virtual water content file (by country and by commodity)
% Load Greenwater data
greenData = load([base_folder 'Input_data/Greenwater_Country_CommodityPart_filled.mat']);
load([base_folder 'Input_data/Greenwater_Country_Codes.mat']);
load([base_folder 'Input_data/Greenwater_Commodity_Codes.mat']);
VWC_green_countrycode(:,1) = country_codes; clear country_codes;
VWC_green_commoditycode(:,1) = commodities_codes; clear commodities_codes;
VWC_green(:,:) = greenData.wfp_info; VWC_green(VWC_green<0)=NaN;

% Load Bluewater data
blueData = load([base_folder 'Input_data/Bluewater_Country_CommodityPart_filled.mat']);
load([base_folder 'Input_data/Bluewater_Country_Codes.mat']);
load([base_folder 'Input_data/Bluewater_Commodity_Codes.mat']); 
VWC_blue_countrycode(:,1) = country_codes; clear country_codes;
VWC_blue_commoditycode(:,1) = commodities_codes; clear commodities_codes;
VWC_blue(:,:) = blueData.wfp_info; VWC_blue(VWC_blue<0)=NaN;


%% Open country list (for countrylist_partialv2.xls, China is all under 
% code 351 which includes China mainland, Hong Kong SAR, Macao SAR, Taiwan)
% Note: code 357 is China mainland and Taiwan); 
% Taiwan is 214; Hong Kong is 96; Macau is 128;
[country_codes,country_names,country_info] = xlsread([base_folder 'Input_data/countrylist_partialv2.xls']);

%% Open commodity list
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Wheatonly.xls']); commod_title='wheatonly';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Riceonly.xls']); commod_title='riceonly';
[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Maizeonly.xls']); commod_title='maizeonly';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Wheat.xls']); commod_title='wheat';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Rice.xls']); commod_title='rice';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Maize.xls']); commod_title='maize';
%---
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_top10ag.xls']); commod_title='10crop';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_topcrop.xls']);
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Wheat_Rice_Maize.xls']);
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist.xls']);


%% Select element/element codes (i.e., import/export and value/qualitity codes)
i_select_element = 4;
element_vec = {...
'Import_Value'
'Export_Value'
'Import_Quantity'
'Export_Quantity'};
element_code_vec = [5622; 5922; 5610; 5910];	

element = element_vec{i_select_element};
element_code=element_code_vec(i_select_element);


%% Year Loop
for year_data=yr_start:yr_end
    year_data %#ok<NOPTS>
    
    %% Create Matrix with Origin, Destination, Weight
    trade_matrix_green = zeros(length(country_codes)*(length(country_codes)-1),3);
    trade_matrix_blue = zeros(length(country_codes)*(length(country_codes)-1),3);
    list_all = 1:length(country_codes);
    max_connects = length(country_codes)-1;
    
    counter = 1;
    for i_node = 1:length(country_codes)
        temp = list_all;
        temp(temp==i_node)=[];
        trade_matrix_green(1+max_connects*(counter-1):max_connects*counter,1)=i_node;
        trade_matrix_green(1+max_connects*(counter-1):max_connects*counter,2)=temp;
        trade_matrix_blue(1+max_connects*(counter-1):max_connects*counter,1)=i_node;
        trade_matrix_blue(1+max_connects*(counter-1):max_connects*counter,2)=temp;
        counter= counter+1;
    end
    
    %% Loop over commodities
    for i_commodity = 1:length(commodity_codes);
        
        ['Processing ' commodity_names(i_commodity)] %#ok<NOPTS>
        
        fname_commodity = ['FAO_DATA/FAO_by_Commodity/FAO_bilateral_trade_' num2str(commodity_codes(i_commodity)) '.txt'];
        
        %% Open FAOSTAT Bilateral Trade Dataset
        fid = fopen([base_folder fname_commodity], 'r');
        header = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s %s %s',1, 'delimiter', '\t');
        format = '%u %s %u %s %u %s %u %s %u %s %f %s %s';
        
        %% Read data into structure array
        GVWT_matrix = textscan(fid, format,Inf,'delimiter', '\t');
        
        fclose(fid);
        
        
        if commodity_codes(i_commodity) ~= GVWT_matrix{1,5}(1);
            'Error with naming of commodity file' %#ok<NOPTS>
            return
        end
        
        %% Identify existing links and assign weights to those links
        for i_row = 1: length(trade_matrix_green);
            
            %% Identify countries to extract trade information
            i_origin = trade_matrix_green(i_row,1);
            i_destin = trade_matrix_green(i_row,2);
            
            if country_codes(i_origin,2)==-1 && country_codes(i_destin,2) ==-1
                index_country_origin=find(GVWT_matrix{1,1}(:)==country_codes(i_origin,1));
                index_country_destin=find(GVWT_matrix{1,3}(:)==country_codes(i_destin,1));
            elseif country_codes(i_origin,2)>-1 && country_codes(i_destin,2) ==-1
                index_country_origin=find(GVWT_matrix{1,1}(:)==country_codes(i_origin,1)|GVWT_matrix{1,1}(:)==country_codes(i_origin,2));
                index_country_destin=find(GVWT_matrix{1,3}(:)==country_codes(i_destin,1));                
            elseif country_codes(i_destin,2)>-1 && country_codes(i_origin,2) ==-1
                index_country_origin=find(GVWT_matrix{1,1}(:)==country_codes(i_origin,1));
                index_country_destin=find(GVWT_matrix{1,3}(:)==country_codes(i_destin,1)|GVWT_matrix{1,3}(:)==country_codes(i_destin,2));               
            else
                'Error with country code' %#ok<NOPTS>
                return 
            end
            index_year=find(GVWT_matrix{1,9}(:)>=year_data & GVWT_matrix{1,9}(:)<=year_data);
            index_element = find(GVWT_matrix{1,7}(:)==element_code);
            
            temp_index= intersect(index_country_origin, index_country_destin);
            temp_index= intersect(temp_index, index_year);
            index_extract = intersect(temp_index, index_element);
            
            %%  Check units (tonnes vs head)
            if isfinite(index_extract)
                if i_select_element == 3||i_select_element == 4
                    %  FAO (metric tonnes); waterfootprint.org also uses metric tonnes
                    unitcheck = strmatch('tonnes', GVWT_matrix{1,10}(index_extract),'exact');
                    if isempty(unitcheck)
                        'Problem with units; not tonnes' %#ok<NOPTS>
                        return
                    end
                    clear unitcheck;
                end
            end
            
            %% Extract value (ie tonnes, 1000 US$, head of cattle)
            value=GVWT_matrix{1,11}(index_extract);
            
            %% Find indice for relevant commodity
            VWC_green_irow =find(VWC_green_commoditycode==commodity_codes(i_commodity));
            VWC_blue_irow =find(VWC_blue_commoditycode==commodity_codes(i_commodity));
            
%             %% DEBUGGING
%             if country_codes(i_origin) == 11 && country_codes(i_destin) == 9
%                 VWC_green_irow
%                  VWC_blue_irow
%             end
            
            %% Find indice for relevant country
            if i_select_element == 1||i_select_element == 3;
                VWC_green_icol =find(VWC_green_countrycode==country_codes(i_destin));
                VWC_blue_icol =find(VWC_blue_countrycode==country_codes(i_destin));
            elseif i_select_element == 2||i_select_element == 4
                VWC_green_icol =find(VWC_green_countrycode==country_codes(i_origin));
                VWC_blue_icol =find(VWC_blue_countrycode==country_codes(i_origin));
            end
            
            % Check to see if there is any trade data for given country 
            % and commodity combination
            if isempty(value) == 0
                if flag_check_trade == 1
                    weight_green = value;
                    weight_blue = value;
                else
                    weight_green = VWC_green(VWC_green_irow,VWC_green_icol)*value;
                    weight_blue = VWC_blue(VWC_blue_irow,VWC_blue_icol)*value;
                end
                
                %  Sum quanitites over all commodities based on i_select_element
                %  (e.g. if i_select_element =4, then sum all export quanitities)
                trade_matrix_green(i_row,3)=trade_matrix_green(i_row,3)+sum(weight_green);
                trade_matrix_blue(i_row,3)=trade_matrix_blue(i_row,3)+sum(weight_blue); 
            end
            
        end
        
%         %% DEBUGGING
%          if country_codes(i_origin) == 11 && country_codes(i_destin) == 9
%                 VWC_green_irow
%                  VWC_blue_irow
%          end

        clear GVWT_matrix;
    end
    %% SAVE FILES
    if flag_check_trade == 1
        % Trade values
        Graph.Type = 'Graph';
        Graph.Signature{1}='ObjectCreateGraph';
        Graph.Signature{2}='TradeImportGraph';
        Graph.FileName{1}=[base_folder 'Trade_matrix_' commod_title '_tons_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat']
        Graph.Data = trade_matrix_green;
        Graph.Index.Names=country_names;
        Graph.Index.Values=1:length(country_codes);
        Graph.Index.Codes=country_codes;
        Graph.Index.Exist=1;
        Graph.Index.Properties.PropertyName='Country Names';
        Graph.Index.Properties.PropertyDescription='Partial country names from FAOSTAT';
        Graph.Index.Properties.NodeIDs=1:length(country_codes);
        Graph.Index.Properties.Values=country_names;
        Graph.Year{1} = year_data;
        Graph.Year{2} = year_data;
        save([out_folder 'Matrices/Trade_Graph_' commod_title '_tons_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'Graph');
        clear Graph
    elseif  flag_check_trade == 0
        % Virtual water values
        % Save in special format: GREEN
        Graph.Type = 'Graph';
        Graph.Signature{1}='ObjectCreateGraph';
        Graph.Signature{2}='TradeImportGraph';
        Graph.FileName{1}=[base_folder 'Trade_matrix_' commod_title '_green_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat']
        Graph.Data = trade_matrix_green;
        Graph.Index.Names=country_names;
        Graph.Index.Values=1:length(country_codes);
        Graph.Index.Codes=country_codes;
        Graph.Index.Exist=1;
        Graph.Index.Properties.PropertyName='Country Names';
        Graph.Index.Properties.PropertyDescription='Partial country names from FAOSTAT';
        Graph.Index.Properties.NodeIDs=1:length(country_codes);
        Graph.Index.Properties.Values=country_names;
        Graph.Year{1} = year_data;
        Graph.Year{2} = year_data;
        save([out_folder 'Matrices/Trade_Graph_' commod_title '_green_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'Graph');
        clear Graph
        
        % Save in special format: BLUE
        Graph.Type = 'Graph';
        Graph.Signature{1}='ObjectCreateGraph';
        Graph.Signature{2}='TradeImportGraph';
        Graph.FileName{1}=[base_folder 'Trade_matrix_' commod_title '_blue_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat']
        Graph.Data = trade_matrix_blue;
        Graph.Index.Names=country_names;
        Graph.Index.Values=1:length(country_codes);
        Graph.Index.Codes=country_codes;
        Graph.Index.Exist=1;
        Graph.Index.Properties.PropertyName='Country Names';
        Graph.Index.Properties.PropertyDescription='Partial country names from FAOSTAT';
        Graph.Index.Properties.NodeIDs=1:length(country_codes);
        Graph.Index.Properties.Values=country_names;
        Graph.Year{1} = year_data;
        Graph.Year{2} = year_data;
        save([out_folder 'Matrices/Trade_Graph_' commod_title '_blue_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'Graph');
    end
    clear Graph trade_matrix_green trade_matrix_blue weight_green weight_blue
    clear GVWT_matrix
end % year loop


    
%    % Save trade matrix with all possible links (non-existing links have 0 weight)
%     save([out_folder 'Matrices/Trade_matrix_' commod_title '_withzeros_green_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'trade_matrix_green');
%     save([out_folder 'Matrices/Trade_matrix_' commod_title '_withzeros_blue_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'trade_matrix_blue');

% Remove non-existing links (i.e., links with zero weight)
%    trade_matrix_green(trade_matrix_green(:,3)==0,:)=[];
%    trade_matrix_blue(trade_matrix_blue(:,3)==0,:)=[];

% Save trade matrix with active links
% save([out_folder 'Matrices/Trade_matrix_' commod_title '_green_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'trade_matrix_green');
% save([out_folder 'Matrices/Trade_matrix_' commod_title '_blue_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat'],'trade_matrix_blue');
