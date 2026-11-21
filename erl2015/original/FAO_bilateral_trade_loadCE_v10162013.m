clear all; close all; clc;
%% Code to extract trade network structure from the FAOSTAT Bilateral Trade 
% forfiles containing the years 1986 to 2009.  After 2009, files are
% availble by year (i.e. include all commodities within year).

%% flag = 0, enables weighting for crop equivalency 
flag_check_trade = 0; 

%% Start and end years for the study
yr_start =1986; yr_end =2009; 
base_folder = '/Users/admin/Documents/Documents_main/Virtual_water/';
out_folder = '/Users/admin/Documents/Documents_main/Virtual_water/';


%% Load crop equivalent factors (by commodity)
[~, ~, raw] = xlsread([base_folder 'Input_data/commodity_cropequivalency.xls'],'Sheet1');
raw = raw(2:end,2:end);

%% Create output variable
datatemp = reshape([raw{:}],size(raw));
CE_tons_commoditycode(:,1) = datatemp(:,1);
commoditycropequivalency = datatemp(:,2:end);

%% Clear temporary variables
clearvars raw datatemp;


%% Open country list (for countrylist_partialv2.xls, China is all under 
% code 351 which includes China mainland, Hong Kong SAR, Macao SAR, Taiwan)
% Note: code 357 is China mainland and Taiwan); 
% Taiwan is 214; Hong Kong is 96; Macau is 128;
[country_codes,country_names,country_info] = xlsread([base_folder 'Input_data/countrylist_partialv2.xls']);

%% Open commodity list
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Wheat.xls']); commod_title='wheat';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Rice.xls']); commod_title='rice';
[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Maize.xls']); commod_title='maize';
%---
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Wheatonly.xls']); commod_title='wheatonly';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Riceonly.xls']); commod_title='riceonly';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Maizeonly.xls']); commod_title='maizeonly';
%---
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_top10ag.xls']); commod_title='10crop';
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_topcrop.xls']);
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist_Wheat_Rice_Maize.xls']);
%[commodity_codes,commodity_names,commodity_info] = xlsread([base_folder 'Input_data/commoditylist.xls']);


%% Select element/element codes (i.e., import/export and value/qualitity codes)
element_vec = {...
'Import_Value'
'Export_Value'
'Import_Quantity'
'Export_Quantity'};
element_code_vec = [5622; 5922; 5610; 5910];


%% Year Loop
for year_data=yr_start:yr_end
    year_data %#ok<NOPTS>
    
    %% Create Matrix with Origin, Destination, Weight
    % Matrix A is for exports as reported in FAOSTAT
    trade_matrixA = zeros(length(country_codes)*(length(country_codes)-1),3);
    
    % Matrix B is for exports as dervied from imports reported in FAOSTAT
    trade_matrixB = zeros(length(country_codes)*(length(country_codes)-1),3);
    
    % Assign country codes to all possible links
    list_all = 1:length(country_codes);
    max_connects = length(country_codes)-1;
    counter = 1;
    for i_node = 1:length(country_codes)
        temp = list_all;
        temp(temp==i_node)=[];
        trade_matrixA(1+max_connects*(counter-1):max_connects*counter,1)=i_node;
        trade_matrixA(1+max_connects*(counter-1):max_connects*counter,2)=temp;
        trade_matrixB(1+max_connects*(counter-1):max_connects*counter,1)=i_node;
        trade_matrixB(1+max_connects*(counter-1):max_connects*counter,2)=temp;
        counter= counter+1;
    end
   
    
    %% Loop over commodities
    for i_commodity = 1:length(commodity_codes);
        
        ['Processing ' commodity_names(i_commodity)] %#ok<NOPTS>
        
        fname_commodity = ['FAO_DATA/FAO_by_Commodity/FAO_bilateral_trade_' num2str(commodity_codes(i_commodity)) '.txt'];
        
        %% Open and read FAOSTAT Bilateral Trade Dataset
        fid = fopen([base_folder fname_commodity], 'r');
        header = textscan(fid, '%s %s %s %s %s %s %s %s %s %s %s %s %s',1, 'delimiter', '\t');
        format = '%u %s %u %s %u %s %u %s %u %s %f %s %s';
        
        % Read data into structure array
        GVWT_matrix = textscan(fid, format,Inf,'delimiter', '\t');
        
        % Close data
        fclose(fid);
        
        % Check commodity code matches file name
        if commodity_codes(i_commodity) ~= GVWT_matrix{1,5}(1);
            'Error with naming of commodity file' %#ok<NOPTS>
            return
        end  
   
        %% Export values derived from import values in the FAOSTAT database
        i_select_element = 4;
        element = element_vec{i_select_element};
        element_code=element_code_vec(i_select_element);
        
        % Identify existing links and assign weights to those links
        for i_row = 1: length(trade_matrixA);
            
            % Identify countries to extract trade information
            i_origin = trade_matrixA(i_row,1);
            i_destin = trade_matrixA(i_row,2);
            
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
            
            %  Check units (tonnes vs head)
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
            
            % Extract value (ie tonnes, 1000 US$)
            value=GVWT_matrix{1,11}(index_extract);
            
            % Find indice for relevant commodity
            CE_tons_irow =find(CE_tons_commoditycode==commodity_codes(i_commodity));
            
            % Check to see if there is any trade data for given country 
            % and commodity combination
            if isempty(value) == 0
                if flag_check_trade == 1
                    weight_link = value;
                else
                    weight_link = value*commoditycropequivalency(CE_tons_irow,2);
                end
                
                %  Sum quanitites over all commodities based on i_select_element
                %  (e.g. if i_select_element =4, then sum all export quanitities)
                trade_matrixA(i_row,3)=trade_matrixA(i_row,3)+sum(weight_link); 
            end
            
        end       
        
        %% Direct export values from import values in FAOSTAT database
        i_select_element = 3;
        element = element_vec{i_select_element};
        element_code=element_code_vec(i_select_element);
        
        % Identify existing links and assign weights to those links
        for i_row = 1: length(trade_matrixB);
            
            % Identify countries to extract trade information
            i_origin = trade_matrixB(i_row,1);
            i_destin = trade_matrixB(i_row,2);
            
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
            
            %  Check units (tonnes vs head)
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
            
            % Extract value (ie tonnes, 1000 US$)
            value=GVWT_matrix{1,11}(index_extract);
            
            % Find indice for relevant commodity
            CE_tons_irow =find(CE_tons_commoditycode==commodity_codes(i_commodity));
            
            % Check to see if there is any trade data for given country 
            % and commodity combination
            if isempty(value) == 0
                if flag_check_trade == 1
                    weight_link = value;
                else
                    weight_link = value*commoditycropequivalency(CE_tons_irow,2);
                end
                
                %  Sum quanitites over all commodities based on i_select_element
                %  (e.g. if i_select_element =4, then sum all export quanitities)
                trade_matrixB(i_row,3)=trade_matrixB(i_row,3)+sum(weight_link); 
            end
            
        end
        
        clear GVWT_matrix weight_link;
 
    end
    
    % Switch columns with origin and destination codes to convert from
    % imports to exports
    tempB = trade_matrixB;
    trade_matrixB(:,1)=tempB(:,2);
    trade_matrixB(:,2)=tempB(:,1);
    
    % Sort matrix with import-derived export values
    trade_matrixB = sortrows(trade_matrixB);
    
    % Replace zeros with NaNs
    trade_matrixA(trade_matrixA == 0) = NaN;
    trade_matrixB(trade_matrixB == 0) = NaN;
    
    % Average original exports and import-derived exports
    trade_matrix(:,1) = trade_matrixA(:,1);
    trade_matrix(:,2) = trade_matrixA(:,2);
    trade_matrix(:,3) = nanmean([trade_matrixA(:,3) trade_matrixB(:,3)],2);
    
    % Convert NaNs back to zeros in the final output
    trade_matrix(isnan(trade_matrix)) = 0;
    clear tempB trade_matrixA trade_matrixB;
        
    %% SAVE FILES
    if flag_check_trade == 1
        % Trade values
        Graph.Type = 'Graph';
        Graph.Signature{1}='ObjectCreateGraph';
        Graph.Signature{2}='TradeImportGraph';
        Graph.FileName{1}=[base_folder 'Trade_matrix_' commod_title '_tons_' element_vec{i_select_element} '_' num2str(year_data) '_' num2str(year_data) '.mat']
        Graph.Data = trade_matrix;
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
        % Save in special format: Tons in crop equivalent
        Graph.Type = 'Graph';
        Graph.Signature{1}='ObjectCreateGraph';
        Graph.Signature{2}='TradeImportGraph';
        Graph.FileName{1}=[base_folder 'Trade_matrix_' commod_title '_tonscropeq_ExportAvg_' num2str(year_data) '_' num2str(year_data) '.mat']
        Graph.Data = trade_matrix;
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
        save([out_folder 'Matrices/Trade_Graph_' commod_title '_tonscropeq_ExportAvg_' num2str(year_data) '_' num2str(year_data) '.mat'],'Graph');
        clear Graph
        
     end
    clear Graph trade_matrix
    clear GVWT_matrix
end % year loop

