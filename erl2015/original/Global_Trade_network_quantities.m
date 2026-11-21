% VW_to_matrix.m
% Reads in annual bilateral trade network and computes complex network
% statistics after converting to matrix... also uses the Matlab Complex 
% Network Toolbox by Lev Muchnik.
% M. J. Puma, Summer 2012
clear all; close all; clc;
basefold = '/Users/admin/Documents/Documents_main/Virtual_water/';
figure_dir='/Users/admin/Documents/Documents_main/Virtual_water/Figures/';
%% Simulation/analysis flags
save_figure = 1;

%% Years to plot
year_start = 1986; year_end = 2009;
num_years = year_end-year_start+1;

%% Open commodity list
commod_title='wheat'; commod_print = 'Wheat';
commod_title2='maize'; commod_print2 = 'Maize';
commod_title3='rice'; commod_print3 = 'Paddy Rice';

%% Flow Type (i.e. virtual water, tons of commoditites, etc)
%flow_type = 'green'; flow_title = 'Green Virtual Water'; flow_units = 'm^3';
%flow_type = 'blue'; flow_title = 'Blue Virtual Water'; flow_units = 'm^3';
flow_type = 'tonscropeq'; flow_title = 'Weight'; flow_units = 'metric tons';

%% Element to plot
i_element = 3; %%NOTE we only look at exports... right now set to 3 because of save error
element_vec = {...
'Import_Value'
'Export_Value'
'Import_Quantity'
'Export_Quantity'};
element = element_vec{i_element};

%% Open country list
[country_codes,country_names,country_info] = xlsread([basefold 'Input_data/countrylist_partialv2.xls']);

%% initialize correlation matrix
Graph_g = GraphLoadFromFile([basefold 'Matrices/Trade_Graph_' commod_title '_' flow_type '_' element '_' num2str(year_start) '_' num2str(year_start) '.mat']);
Graph_b = GraphLoadFromFile([basefold 'Matrices/Trade_Graph_' commod_title2 '_' flow_type '_' element '_' num2str(year_start) '_' num2str(year_start) '.mat']);
Graph_3 = GraphLoadFromFile([basefold 'Matrices/Trade_Graph_' commod_title3 '_' flow_type '_' element '_' num2str(year_start) '_' num2str(year_start) '.mat']);

rank_matrix_g =zeros(length(Graph_g.Data), size(year_start:year_end,2));
rank_matrix_b =zeros(length(Graph_b.Data), size(year_start:year_end,2));
rank_matrix_3 =zeros(length(Graph_3.Data), size(year_start:year_end,2));
clear Graph_g Graph_b Graph_3;

%% Year Loop
i_year = 0;
for year = year_start:year_end
    year
    i_year = i_year + 1; % year index
    
    %% Read in network from file
    Graph_g = GraphLoadFromFile([basefold 'Matrices/Trade_Graph_' commod_title '_' flow_type '_' element '_' num2str(year) '_' num2str(year) '.mat']);
    Graph_b = GraphLoadFromFile([basefold 'Matrices/Trade_Graph_' commod_title2 '_' flow_type '_' element '_' num2str(year) '_' num2str(year) '.mat']);
    Graph_3 = GraphLoadFromFile([basefold 'Matrices/Trade_Graph_' commod_title3 '_' flow_type '_' element '_' num2str(year) '_' num2str(year) '.mat']);
 
    %% Identify the links
    LinkID_g = (1:length(Graph_g.Data))';
    LinkID_b = (1:length(Graph_b.Data))';
    LinkID_3 = (1:length(Graph_3.Data))';
    
    %% Place data in a matrix containing all years
    rank_matrix_g(:,i_year)=Graph_g.Data(:,3);
    rank_matrix_b(:,i_year)=Graph_b.Data(:,3);    
    rank_matrix_3(:,i_year)=Graph_3.Data(:,3); 
    
    %% WD is the directed trade matrix: virtual water trade network forms a
    % weighted, directed network; WD is not symmetric and W(i, i) = 0; that is,
    % a country cannot trade with itself.
    WD_g = zeros(max(Graph_g.Index.Properties.NodeIDs));
    WD_b = zeros(max(Graph_b.Index.Properties.NodeIDs));
    WD_3 = zeros(max(Graph_3.Index.Properties.NodeIDs));
    
    % goes through
    for i_link = 1: length(Graph_g.Data)
        WD_g(Graph_g.Data(i_link,1),Graph_g.Data(i_link,2))=Graph_g.Data(i_link,3);
    end

    for i_link = 1: length(Graph_b.Data)
        WD_b(Graph_b.Data(i_link,1),Graph_b.Data(i_link,2))=Graph_b.Data(i_link,3);
    end
    
    for i_link = 1: length(Graph_3.Data)
        WD_3(Graph_3.Data(i_link,1),Graph_3.Data(i_link,2))=Graph_3.Data(i_link,3);
    end
    
    %% Check diagonal is zero
    if sum(diag(WD_g)) >0
        'error in diagonal 1' %#ok<NOPTS>
        return   
    elseif sum(diag(WD_b)) >0
        'error in diagonal 1' %#ok<NOPTS>
        return
    elseif sum(diag(WD_3)) >0
        'error in diagonal 1' %#ok<NOPTS>
        return
    end
    
    
    %% Weighted, undirected network (WU): created by symmetrizing the directed,
    % weighted network on the basis of the sum of the link weights between
    % two nodes. This symmetrization creates an undirected network
    % with at most a single link between any two nodes
    L_g = tril(WD_g,-1); U_g = triu(WD_g,1); 
    WU_g = WD_g+transpose(L_g)+transpose(U_g); % Weighted, undirected network (WU)
    AD_g = WD_g>0; % Unweighted, directed network (AD)
    AU_g = WU_g>0; % Unweighted, undirected network (AU)
    
    L_b = tril(WD_b,-1); U_b = triu(WD_b,1); 
    WU_b = WD_b+transpose(L_b)+transpose(U_b); % Weighted, undirected network (WU)
    AD_b = WD_b>0; % Unweighted, directed network (AD)
    AU_b = WU_b>0; % Unweighted, undirected network (AU)
    
    L_3 = tril(WD_3,-1); U_3 = triu(WD_3,1); 
    WU_3 = WD_3+transpose(L_3)+transpose(U_3); % Weighted, undirected network (WU)
    AD_3 = WD_3>0; % Unweighted, directed network (AD)
    AU_3 = WU_3>0; % Unweighted, undirected network (AU)
    
    %% Compute the number of links in the network (import or export)
    NumLinks_g(i_year) = sum(AD_g(:));
    NumLinks_b(i_year) = sum(AD_b(:));
    NumLinks_3(i_year) = sum(AD_3(:));
    %disp(sprintf('Number of Links in green network: %d',GraphCountNumberOfLinks(Graph_g)))
    %disp(sprintf('Number of Links in blue network: %d',GraphCountNumberOfLinks(Graph_b))) 
    
    %% Number of nodes in graph (sum rows of undirected network WU, to identify active nodes)
    NumNodes_g(i_year) = nnz(sum(WU_g,1));
    NumNodes_b(i_year) = nnz(sum(WU_b,1));
    NumNodes_3(i_year) = nnz(sum(WU_3,1));
    %disp(sprintf('Number of Nodes in network 1: %d',GraphCountNumberOfNodes(Graph_b)));
    %disp(sprintf('Number of Nodes in network 2: %d',GraphCountNumberOfNodes(Graph_g)));
   
    %% Volume of water traded globally 
    TotTradeGlobal_g(i_year) = sum(WD_g(:));
    TotTradeGlobal_b(i_year) = sum(WD_b(:));
    TotTradeGlobal_3(i_year) = sum(WD_3(:)); 
    
    %% Strength, si, is calculated as the sum of all the exporting fluxes from
    % that node (i.e., as the row sum in the virtual water trade matrix)
    s_D_g(i_year,:) = sum(WD_g,2);
    s_D_b(i_year,:) = sum(WD_b,2); 
    s_D_3(i_year,:) = sum(WD_3,2);  
    
    %% Compute degrees in network for exports in directed network
    k_D_out_g(:,i_year) = nansum(AD_g,2);  % sum each row for export
    k_D_out_b(:,i_year) = nansum(AD_b,2);  % sum each row for export
    k_D_out_3(:,i_year) = nansum(AD_3,2);  % sum each row for export
    
    
   %% Average nearest neighbor degree
   % First dataset
   for i =1:size(k_D_out_g,1)
       if sum(AD_g(i,:)==1)>0
           % Find indices of active trade partners
           j_indices = find(AD_g(i,:)==1);
           
           %%%% remove j_indices == 1
           %%j_indices(find(j_indices==i))=[];
           
           sum_kj = sum(k_D_out_g(j_indices,i_year));
           knn_D_out_g(i,i_year) = sum_kj/k_D_out_g(i);
       else
           knn_D_out_g(i,i_year) = 0;
       end
   end
   
   puma(:,1)=knn_D_out_g(find(knn_D_out_g(:,i_year)~=0),i_year);
   clear puma;
    
    %% Concentration index(for non fractions, >1 if similar weights... approaches 1 as you hav a donimant node
    Iconcentrate_g(:,i_year) =  (nansum(WD_g,1).^2)'./(nansum(WD_g.^2,1))'; % sum each column for import  
    Iconcentrate_b(:,i_year) =  (nansum(WD_b,1).^2)'./(nansum(WD_b.^2,1))'; % sum each column for import
    Iconcentrate_3(:,i_year) =  (nansum(WD_3,1).^2)'./(nansum(WD_3.^2,1))'; % sum each column for import

    % Sort Concentration index
    temp = Iconcentrate_g(:,i_year); temp(isnan(temp))=-9999; [Bg,IXg] = sort(temp,'descend');
    temp = Iconcentrate_b(:,i_year); temp(isnan(temp))=-9999; [Bb,IXb] = sort(temp,'descend');
    temp = Iconcentrate_3(:,i_year); temp(isnan(temp))=-9999; [B3,IX3] = sort(temp,'descend');

    % Save Concentration index and country names
    for i = 1:length(country_names)
        Iconcentrate_rank_g.name{i,i_year} = country_names{IXg(i)};
        Iconcentrate_rank_g.value(i,i_year) = Bg(i);
        
        Iconcentrate_rank_b.name{i,i_year} = country_names{IXb(i)};
        Iconcentratel_rank_b.value(i,i_year) = Bb(i);
                
        Iconcentrate_rank_3.name{i,i_year} = country_names{IX3(i)};
        Iconcentratel_rank_3.value(i,i_year) = B3(i);
    end    
       
    %% Control index
    for i = 1:size(WD_g,1) % rows
        for j = 1:size(WD_g,2) % columns
%            Measures the number of important outgoing edges of the
%            vertices. For a given vertex i, with a destination vertex j, we first define a measure which reflects
            Hfcontrol_g(i,j)=WD_g(i,j).^2./(nansum(WD_g(:,j).^2));
            Hfcontrol_b(i,j)=WD_b(i,j).^2./(nansum(WD_b(:,j).^2))';
            Hfcontrol_3(i,j)=WD_3(i,j).^2./(nansum(WD_3(:,j).^2))';
        end
        hcontrol_g(i,i_year) = nansum(Hfcontrol_g(i,:));
        hcontrol_b(i,i_year) = nansum(Hfcontrol_b(i,:));
        hcontrol_3(i,i_year) = nansum(Hfcontrol_3(i,:));
    end
    
    hcontrol_g_mean(i_year,1)=nanmean(hcontrol_g(:,i_year));
    hcontrol_b_mean(i_year,1)=nanmean(hcontrol_b(:,i_year));
    hcontrol_3_mean(i_year,1)=nanmean(hcontrol_3(:,i_year));
    
    % Sort control index
    temp = hcontrol_g(:,i_year); temp(isnan(temp))=-9999; [Bg,IXg] = sort(temp,'descend');
    temp = hcontrol_b(:,i_year); temp(isnan(temp))=-9999; [Bb,IXb] = sort(temp,'descend');
    temp = hcontrol_3(:,i_year); temp(isnan(temp))=-9999; [B3,IX3] = sort(temp,'descend');

    % Save  control index and country names
    for i = 1:length(country_names)
        hcontrol_rank_g.name{i,i_year} = country_names{IXg(i)};
        hcontrol_rank_g.value(i,i_year) = Bg(i);
        
        hcontrol_rank_b.name{i,i_year} = country_names{IXb(i)};
        hcontrol_rank_b.value(i,i_year) = Bb(i);
        
        hcontrol_rank_3.name{i,i_year} = country_names{IX3(i)};
        hcontrol_rank_3.value(i,i_year) = B3(i);
    end
 
     %% Remove non-existing links (i.e., links with zero weight)
    LinkID_g(Graph_g.Data(:,3)==0,:)=[];
    LinkID_b(Graph_b.Data(:,3)==0,:)=[]; 
    LinkID_3(Graph_3.Data(:,3)==0,:)=[]; 
    
    Graph_g.Data(Graph_g.Data(:,3)==0,:)=[];
    Graph_b.Data(Graph_b.Data(:,3)==0,:)=[];
    Graph_3.Data(Graph_3.Data(:,3)==0,:)=[];    

    %% Remove inactive nodes
    Graph_g=GraphRemoveUnlinkedNodes(Graph_g);
    Graph_b=GraphRemoveUnlinkedNodes(Graph_b);
    Graph_3=GraphRemoveUnlinkedNodes(Graph_3); 
    
    Graph_g = mexGraphSqueeze(Graph_g);
    NearestNeighborData_g = mexGraphAverageNearestNeighborDegree(Graph_g,[],'direct');
    Graph_b = mexGraphSqueeze(Graph_b);
    NearestNeighborData_b = mexGraphAverageNearestNeighborDegree(Graph_b,[],'direct');  
    Graph_3 = mexGraphSqueeze(Graph_3);
    NearestNeighborData_3 = mexGraphAverageNearestNeighborDegree(Graph_3,[],'direct');  

end


% figure
% hold on
% scatter(k_D_out_b(:,1),kout_knnout_D_in_b(:,1))
% 
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% xlabel('k','FontSize',18);
% ylabel('knn','FontSize',18);





%% Figure with number of links in network as a function of time
figure
hold on
plot(year_start:year_end,NumLinks_g, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,NumLinks_b,'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
     'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,NumLinks_3,'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k') 
set(get(gcf,'CurrentAxes'),'FontSize',18)
ylabel('Number of links','FontSize',18);
xlabel('year','FontSize',18);
xlim([1985 2010])
title(['Links in the Network'])% ' to ' num2str(year1_end)])
%legend(commod_print,commod_print2,commod_print3,'Location','Northwest')
box on
axis square
hold off
set(gcf,'Renderer','painters');
set(gcf,'OuterPosition',[100   500   450 450]);
set(gcf,'PaperPositionMode','auto');
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'numberlinks_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end

%% Total flows in the network as relative change from base year (year 1)
figure
hold on
plot(year_start:year_end,100*(TotTradeGlobal_g-TotTradeGlobal_g(1))./TotTradeGlobal_g(1),'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,100*(TotTradeGlobal_b-TotTradeGlobal_b(1))./TotTradeGlobal_b(1),'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
    'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,100*(TotTradeGlobal_3-TotTradeGlobal_3(1))./TotTradeGlobal_3(1),'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k')
set(get(gcf,'CurrentAxes'),'FontSize',18)
xlabel('Year','FontSize',17);
ylabel('Relative Changes (%)','FontSize',18);
title(['Trade Flow (Base Yr 1986)'],'FontSize',20)
%legend(commod_print,commod_print2,commod_print3,'Location','Northwest')
xlim([1985 2010])
hold off
box on
axis square
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[100   500   450 450])
set(gcf,'PaperPositionMode','auto')
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'relative_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end



%% Total flows in the network 
mmt_convert = 1000000;
figure
hold on
plot(year_start:year_end,TotTradeGlobal_g/mmt_convert,'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,TotTradeGlobal_b/mmt_convert,'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
    'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,TotTradeGlobal_3/mmt_convert,'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k')
set(get(gcf,'CurrentAxes'),'FontSize',18)
xlabel('Year','FontSize',17);
ylabel('Cereal Equivalent (mmt)','FontSize',18);
title(['Trade Flow'],'FontSize',20)
%legend(commod_print,commod_print2,commod_print3,'Location','Northwest')
xlim([1985 2010])
hold off
box on
axis square
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[100   500   450 450])
set(gcf,'PaperPositionMode','auto')
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'actual_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end
return

%% Compute Spearman rank correlation
rank_matrix_g(find(rank_matrix_g==0))=NaN;
RHO_g = corr(rank_matrix_g,'type','Spearman','rows','pairwise');
RHO_g_lag1=zeros(length(RHO_g)-1,1);
for i = 1:length(RHO_g)-1
    RHO_g_lag1(i,1)=RHO_g(i+1,i);
end

rank_matrix_b(find(rank_matrix_b==0))=NaN;
RHO_b = corr(rank_matrix_b,'type','Spearman','rows','pairwise');
RHO_b_lag1=zeros(length(RHO_b)-1,1);
for i = 1:length(RHO_b)-1
    RHO_b_lag1(i,1)=RHO_b(i+1,i);
end

rank_matrix_3(find(rank_matrix_3==0))=NaN;
RHO_3 = corr(rank_matrix_3,'type','Spearman','rows','pairwise');
RHO_3_lag1=zeros(length(RHO_3)-1,1);
for i = 1:length(RHO_3)-1
    RHO_3_lag1(i,1)=RHO_3(i+1,i);
end


%% Figure with number of exporting nodes
figure
hold on
plot(year_start:year_end,number_exporters_g./NumNodes_g, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,number_exporters_b./NumNodes_b,'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
     'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,number_exporters_3./NumNodes_3,'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k') 
set(get(gcf,'CurrentAxes'),'FontSize',18)
ylabel('# of Exporters/# Countries Active','FontSize',18);
xlabel('year','FontSize',18);
legend(commod_print,commod_print2,commod_print3,'Location','Northwest')
title(['Fraction of Countries Exporting'])% ' to ' num2str(year1_end)])
box on
axis square
hold off
set(gcf,'Renderer','painters');
set(gcf,'OuterPosition',[100   500   500 500]);
set(gcf,'PaperPositionMode','auto');
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'frexport_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end

%% Figure with number of importer nodes
figure
hold on
plot(year_start:year_end,number_importers_g./NumNodes_g, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,number_importers_b./NumNodes_b,'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
     'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,number_importers_3./NumNodes_3,'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k') 
set(get(gcf,'CurrentAxes'),'FontSize',18)
ylabel('# of Importers/# Countries Active','FontSize',18);
xlabel('year','FontSize',18);
legend(commod_print,commod_print2,commod_print3,'Location','Southeast')
title(['Fraction of Countries Importing'])% ' to ' num2str(year1_end)])
box on
axis square
hold off
set(gcf,'Renderer','painters');
set(gcf,'OuterPosition',[100   500   500 500]);
set(gcf,'PaperPositionMode','auto');
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'frimport_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end


%% Concentration Index Time Series
figure
hold on
plot(year_start:year_end,nanmean(Iconcentrate_g,1), 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,nanmean(Iconcentrate_b,1),'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
     'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,nanmean(Iconcentrate_3,1),'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k')
set(get(gcf,'CurrentAxes'),'FontSize',18)
ylabel('<s_j>','FontSize',18);
xlabel('year','FontSize',18);
title(['Concentration Index'])% 
%title(['Mean Concentration Index, ' flow_title])% ' to ' num2str(year1_end)])
%legend(commod_print,commod_print2,commod_print3,'Location','Northwest')
box on
axis square
hold off
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[100   500   500 500])
set(gcf,'PaperPositionMode','auto')
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'concentration_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end


%% Control Index Time Series
figure
hold on
plot(year_start:year_end,hcontrol_g_mean, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
    'MarkerFaceColor','r','Color','k')
plot(year_start:year_end,hcontrol_b_mean,'LineStyle','--','LineWidth',1.5,'Marker','o','MarkerSize',8,...
     'MarkerFaceColor','b','Color','b')
plot(year_start:year_end,hcontrol_3_mean,'LineStyle','--','LineWidth',1.5,'Marker','d','MarkerSize',10,...
    'MarkerFaceColor','g','Color','k')
set(get(gcf,'CurrentAxes'),'FontSize',18)
ylabel('<s_j>','FontSize',18);
xlabel('year','FontSize',18);
title(['Control Index'])% 
%title(['Mean Control Index, ' flow_title])% ' to ' num2str(year1_end)])
%legend(commod_print,commod_print2,commod_print3,'Location','Southeast')
box on
axis square
hold off
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[100   500   500 500])
set(gcf,'PaperPositionMode','auto')
if save_figure>0
    print('-depsc','-painters','-r600',[figure_dir 'control_' flow_type '_' commod_title '_' commod_title2 '_' commod_title3 '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
end

return

% %% Normalized histogram of distribution of the concentration index 
% delta = .5;
% variable_g_min = nanmin(Iconcentrate_g(:)); variable_g_max = nanmax(Iconcentrate_g(:)); 
% variable_g_bins = variable_g_min-delta:delta:variable_g_max+delta;
% 
% variable_b_min = nanmin(Iconcentrate_b(:)); variable_b_max = nanmax(Iconcentrate_b(:)); 
% variable_b_bins = variable_b_min-delta:delta:variable_b_max+delta;
% 
% figure
% %subplot(1,2,1)
% [no_Icg ,xo_Icg]  = histnorm(Iconcentrate_g(:,end-17), variable_g_bins);
% [no_Icg2 ,xo_Icg2]  = histnorm(Iconcentrate_g(:,end-9), variable_g_bins);
% hold on
% h_cg =stairs(xo_Icg,no_Icg,'g');
% h_cg2=stairs(xo_Icg2,no_Icg2,'k');
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% xlabel(['Concentration Index'],'FontSize',14);
% ylabel('# in bin/total #/bin width','FontSize',14)
% title(['Concentration Index, ' commod_print])% 
% set(get(gcf,'CurrentAxes'),'FontSize',14)
% set(h_cg,'LineWidth', 2, 'LineStyle','-');
% set(h_cg2,'LineWidth', 2, 'LineStyle','--');
% hold off
% 
% % subplot(1,2,2)
% % [no_Icb ,xo_Icb]  = histnorm(Iconcentrate_b(:,end-17), variable_b_bins);
% % [no_Icb2 ,xo_Icb2]  = histnorm(Iconcentrate_b(:,end-9), variable_b_bins);
% % hold on
% % h_cb =stairs(xo_Icb,no_Icb,'b');
% % h_cb2=stairs(xo_Icb2,no_Icb2,'k');
% % legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% % xlabel(['Concentration Index'],'FontSize',14);
% % ylabel('# in bin/total #/bin width','FontSize',14)
% % title(['Concentration Index (Blue), ' commod_print])% 
% % set(get(gcf,'CurrentAxes'),'FontSize',14)
% % set(h_cb,'LineWidth', 2, 'LineStyle','-');
% % set(h_cb2,'LineWidth', 2, 'LineStyle','--');
% % hold off
% 
% set(gcf,'Renderer','painters')
% set(gcf,'OuterPosition',[100   500   400 400])
% set(gcf,'PaperPositionMode','auto')
% 
% %% Normalized histogram of distribution of the control index 
% delta = 6;
% variable_g_min = nanmin(hcontrol_g(:)); variable_g_max = nanmax(hcontrol_g(:)); 
% variable_g_bins = variable_g_min:delta:variable_g_max+delta;
% 
% variable_b_min = nanmin(hcontrol_b(:)); variable_b_max = nanmax(hcontrol_b(:)); 
% variable_b_bins = variable_b_min:delta:variable_b_max+delta;
% 
% figure
% %subplot(1,2,1)
% [no_Icg ,xo_Icg]  = histnorm(hcontrol_g(:,1), variable_g_bins);
% [no_Icg2 ,xo_Icg2]  = histnorm(hcontrol_g(:,end), variable_g_bins);
% hold on
% h_cg =stairs(xo_Icg,no_Icg,'g');
% h_cg2=stairs(xo_Icg2,no_Icg2,'k');
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% xlabel(['Control Index'],'FontSize',14);
% ylabel('# in bin/total #/bin width','FontSize',14)
% title(['Control Index, ' commod_print])% 
% set(get(gcf,'CurrentAxes'),'FontSize',14)
% set(h_cg,'LineWidth', 2, 'LineStyle','-');
% set(h_cg2,'LineWidth', 2, 'LineStyle','--');
% hold off
% 
% % subplot(1,2,2)
% % [no_Icb ,xo_Icb]  = histnorm(hcontrol_g(:,1), variable_b_bins);
% % [no_Icb2 ,xo_Icb2]  = histnorm(hcontrol_g(:,end), variable_b_bins);
% % hold on
% % h_cb =stairs(xo_Icb,no_Icb,'b');
% % h_cb2=stairs(xo_Icb2,no_Icb2,'k');
% % legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% % xlabel(['Control Index'],'FontSize',14);
% % ylabel('# in bin/total #/bin width','FontSize',14)
% % title(['Control Index (Blue), ' commod_print])% 
% % set(get(gcf,'CurrentAxes'),'FontSize',14)
% % set(h_cb,'LineWidth', 2, 'LineStyle','-');
% % set(h_cb2,'LineWidth', 2, 'LineStyle','--');
% % hold off
% 
% set(gcf,'Renderer','painters')
% set(gcf,'OuterPosition',[100   500   400 400])
% set(gcf,'PaperPositionMode','auto')
% 
% 
% % %% Figure with Spearman's rank correlation
% % figure
% % hold on
% % plot((year_start:(year_end-1))+.5,RHO_g_lag1,'LineStyle','none','LineWidth',1.5,'Marker','s','MarkerSize',8,...
% %     'MarkerFaceColor','g','Color','g')
% % plot((year_start:(year_end-1))+.5,RHO_b_lag1,'LineStyle','none','LineWidth',1.5,'Marker','o','MarkerSize',8,...
% %     'MarkerFaceColor','b','Color','b')
% % set(get(gcf,'CurrentAxes'),'FontSize',16)
% % xlabel('Year','FontSize',16);
% % ylabel(['\rho (-)'],'FontSize',16);
% % title(['Spearman''s rank correlation, ' commod_print],'FontSize',18)
% % %legend('green','blue','Location','Northwest')
% % hold off
% % box on
% % if save_figure>0
% %     print('-depsc','-painters','-r600',[figure_dir 'Rho_' commod_title '_' num2str(year_start) '_' num2str(year_end) '.eps' ])
% % end
% 
% 
% return
% 
% 
% 
% %% Fit of exponential distribution to cumulative distribution of the node degrees 
% figure
% set(gcf,'Renderer','painters')
% set(gcf,'OuterPosition',[100   500   800 800])
% set(gcf,'PaperPositionMode','auto')
% 
% subplot(2,2,1)
% hold on
% eX = eprob(k_D_out_g(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% eX = eprob(k_D_out_g(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('P(K>k)','FontSize',18);
% xlabel('k','FontSize',18);
% title(['Node Degree for Exports (Green), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% subplot(2,2,2)
% hold on
% eX = eprob(k_D_in_g(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% eX = eprob(k_D_in_g(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('P(K>k)','FontSize',18);
% xlabel('k','FontSize',18);
% title(['Node Degree for Imports (Green), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% subplot(2,2,3)
% hold on
% eX = eprob(k_D_out_b(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','b');
% eX = eprob(k_D_out_b(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('P(K>k)','FontSize',18);
% xlabel('k','FontSize',18);
% title(['Node Degree for Exports (Blue), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% subplot(2,2,4)
% hold on
% eX = eprob(k_D_in_b(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','b');
% eX = eprob(k_D_in_b(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('P(K>k)','FontSize',18);
% xlabel('k','FontSize',18);
% title(['Node Degree for Imports (Blue), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% %% Fit of exponential distribution to cumulative distribution of the node strengths 
% figure
% set(gcf,'Renderer','painters')
% set(gcf,'OuterPosition',[100   500   800 800])
% set(gcf,'PaperPositionMode','auto')
% 
% subplot(2,2,1)
% hold on
% eX = eprob(kw_D_out_g(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% eX = eprob(kw_D_out_g(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('ln(P(S>s))','FontSize',18);
% xlabel('s','FontSize',18);
% title(['Node Strength for Exports (Green), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% subplot(2,2,2)
% hold on
% eX = eprob(kw_D_in_g(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% eX = eprob(kw_D_in_g(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('ln(P(S>s))','FontSize',18);
% xlabel('s','FontSize',18);
% title(['Node Strength for Imports (Green), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% subplot(2,2,3)
% hold on
% eX = eprob(kw_D_out_b(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','b');
% eX = eprob(kw_D_out_b(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('ln(P(S>s))','FontSize',18);
% xlabel('s','FontSize',18);
% title(['Node Strength for Exports (Blue), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% subplot(2,2,4)
% hold on
% eX = eprob(kw_D_in_b(:,1));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','b');
% eX = eprob(kw_D_in_b(:,end));
% plot(eX.sort,eX.eprob,'LineWidth',2,'Color','k','LineStyle','--');
% set(get(gcf,'CurrentAxes'),'FontSize',18)
% ylabel('ln(P(S>s))','FontSize',18);
% xlabel('s','FontSize',18);
% title(['Node Strength for Imports (Blue), ' commod_print])% 
% legend({num2str(year_start) num2str(year_end)},'Location','Northeast');
% hold off
% 
% % if save_figure>0
% %     print('-depsc','-painters','-r600',[basefolder 'Figures/'  'Exceed_Prob' num2str(year1_start) '_' num2str(year2_end) '.eps' ])
% % end
% 
% 
% return
% 
% % %% Remove degrees in network equal to zero
% % for i_yr = 1:num_years
% %     temp_out = k_D_out_g(:,i_yr);
% %     temp_in = k_D_in_g(:,i_yr);
% %     
% %     temp_out(temp_out==0)=[];
% %     temp_in(temp_in==0)=[];
% %     
% %     k_D_out_g_mean(i_yr)=mean(temp_out);
% %     k_D_in_g_mean(i_yr)=mean(temp_in);
% % 
% %     k_D_out_g_single(i_yr)=sum(temp_out==1);
% %     k_D_in_g_single(i_yr)=sum(temp_in==1);
% %     
% %     k_D_out_g_less5(i_yr)=sum(temp_out<=5);
% %     k_D_in_g_less5(i_yr)=sum(temp_in<=5);
% %     
% %     k_D_out_g_greater10(i_yr)=sum(temp_out>=10);
% %     k_D_in_g_greater10(i_yr)=sum(temp_in>=10);
% % 
% %     eX_out = eprob(temp_out);
% %     eX_in = eprob(temp_in);
% %     
% % end
% 
% % figure
% % hold on
% % plot(year_start:year_end,k_D_out_g_single, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
% %     'MarkerFaceColor','g','Color','k')
% % plot(year_start:year_end,k_D_in_g_single, 'LineStyle','-','LineWidth',1.5,'Marker','o','MarkerSize',8,...
% %     'MarkerFaceColor','b','Color','k')
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('Number','FontSize',18);
% % xlabel('year','FontSize',18);
% % title(['Number of countries with single trade partner, ' commod_print])% ' to ' num2str(year1_end)])
% % legend('export','import','Location','Northeast')
% % hold off
% % 
% % figure
% % hold on
% % plot(year_start:year_end,k_D_out_g_less5, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
% %     'MarkerFaceColor','g','Color','k')
% % plot(year_start:year_end,k_D_in_g_less5, 'LineStyle','-','LineWidth',1.5,'Marker','o','MarkerSize',8,...
% %     'MarkerFaceColor','b','Color','k')
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('Number','FontSize',18);
% % xlabel('year','FontSize',18);
% % title(['Number of countries with 5 or less trade partners, ' commod_print])% ' to ' num2str(year1_end)])
% % legend('export','import','Location','Northeast')
% % hold off
% % 
% % figure
% % hold on
% % plot(year_start:year_end,k_D_out_g_greater10, 'LineStyle','-','LineWidth',1.5,'Marker','s','MarkerSize',8,...
% %     'MarkerFaceColor','g','Color','k')
% % plot(year_start:year_end,k_D_in_g_greater10, 'LineStyle','-','LineWidth',1.5,'Marker','o','MarkerSize',8,...
% %     'MarkerFaceColor','b','Color','k')
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('Number','FontSize',18);
% % xlabel('year','FontSize',18);
% % title(['Number of countries with 10 or more trade partners, ' commod_print])% ' to ' num2str(year1_end)])
% % legend('export','import','Location','Northeast')
% % hold off
% % 
% % return
% % 
% % 
% % %% Plot total strength of the network (i.e., the sum of the strengths of 
% % % all nodes in the network))
% % figure
% % hold on
% % plot(year_start:year_end,s_D_g, 'Marker','s','LineStyle','-')
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('\Sigma s_{i} (m^3 virtual water)','FontSize',18);
% % xlabel('year','FontSize',18);
% % title(['Total Strength of Network'])% ' to ' num2str(year1_end)])
% % hold off
% % if save_figure>0
% %     print('-depsc','-painters','-r600',[basefolder 'Figures/'  'TotStrength' num2str(year1_start) '_' num2str(year2_end) '.eps' ])
% % end
% % 
% % 
% % 
% % 
% % 
% % 
% % %% Node Degree Distribution: 
% % % Exceedance Probability Plot
% % figure
% % set(gcf,'Renderer','painters')
% % set(gcf,'OuterPosition',[100   500   400 800])
% % set(gcf,'PaperPositionMode','auto')
% % 
% % subplot(3,1,1)
% % hold on
% % eX = eprob(k_1U);
% % plot(eX.sort,eX.eprob,'LineWidth',2);
% % eX = eprob(k_3U);
% % plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('P(K>k)','FontSize',18);
% % xlabel('k','FontSize',18);
% % title(['Undirected Network'])% ' to ' num2str(year1_end)])
% % legend({num2str(year1_start),num2str(year3_start)},'Location','Northeast');
% % hold off
% % 
% % subplot(3,1,2)
% % hold on
% % eX = eprob(k_1D_out);
% % plot(eX.sort,eX.eprob,'LineWidth',2);
% % eX = eprob(k_3D_out);
% % plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('P(K>k)','FontSize',18);
% % xlabel('k_{out}, Export','FontSize',18);
% % title(['Directed Network, Export'])% ' to ' num2str(year1_end)])
% % legend({num2str(year1_start),num2str(year3_start)},'Location','Northeast');
% % hold off
% % 
% % subplot(3,1,3)
% % hold on
% % eX = eprob(k_1D_in);
% % plot(eX.sort,eX.eprob,'LineWidth',2);
% % eX = eprob(k_3D_in);
% % plot(eX.sort,eX.eprob,'LineWidth',2,'Color','g');
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('P(K>k)','FontSize',18);
% % xlabel('k_{in}, Import','FontSize',18);
% % title(['Directed Network, Import'])% ' to ' num2str(year1_end)])
% % legend({num2str(year1_start),num2str(year3_start)},'Location','Northeast');
% % hold off
% % 
% % if save_figure>0
% %     print('-depsc','-painters','-r600',[basefolder 'Figures/'  'Exceed_Prob' num2str(year1_start) '_' num2str(year2_end) '.eps' ])
% % end
% % 
% % 
% % 
% % 
% % %% Nearest neighbor degree plot
% % figure; 
% % hold on
% % scatter(NewrestNeighborData1.Degree,NewrestNeighborData1.AverageNeiborsOutDegree,'b')
% % scatter(NewrestNeighborData2.Degree,NewrestNeighborData2.AverageNeiborsOutDegree,'g')
% % scatter(NewrestNeighborData3.Degree,NewrestNeighborData3.AverageNeiborsOutDegree,'k')
% % hold off
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % ylabel('k_{nn}','FontSize',18);
% % xlabel('k','FontSize',18);
% % legend({'2006','2007','2008'},'Location','Northeast');
% 
% 
% 
% % act_rank_matrix_g=zeros(size(rank_matrix_g));
% % i_year = 0;
% % for year = year_start:year_end
% %     
% %     i_year = i_year + 1; % year index
% %     % get ranks of green water
% %     data_temp = rank_matrix_g(:,i_year);
% %     act_rank_matrix_g(:,i_year)=floor(tiedrank(-data_temp));
% %     % get ranks of blue water
% %     data_temp = rank_matrix_b(:,i_year);
% %     act_rank_matrix_b(:,i_year)=floor(tiedrank(-data_temp));    
% %     
% % end
% 
% 
% 
% 
% % %%  Identify top nodes
% % figure
% % hold on
% % top10 = zeros(10,num_years);
% % for i_rank = 1:10
% %     row_ind = find(act_rank_matrix_g(:,1)==i_rank);
% %     for i_yr = 1:num_years
% %         top10(i_rank,i_yr) = act_rank_matrix_g(row_ind,i_yr);
% %         top10_link(i_rank,i_yr) =  row_ind;
% %         top10names.exporter{i_rank,i_yr} = Graph_g.Index.Names(Graph_g.Data(row_ind,1));
% %         top10names.importer{i_rank,i_yr} = Graph_g.Index.Names(Graph_g.Data(row_ind,2));
% %     end
% %     top10(find(top10>400)) = NaN;
% %     plot(year_start:year_end,top10(i_rank,:), 'Marker','s','LineStyle','-')
% % end
% % set(get(gcf,'CurrentAxes'),'FontSize',18)
% % %ylabel('\Sigma s_{i} (m^3 virtual water)','FontSize',18);
% % xlabel('year','FontSize',18);
% % %title(['Total Strength of Network'])% ' to ' num2str(year1_end)])
% % hold off
% 
% 
% 
% 
% %     %% Sort ascending
% %     [B,index]  = sortrows(Graph_g.Data,3);
% %     index=flipud(index); B=flipud(B);
% %     Graph_g.Data(index(1),:)
% %     B_top5 = B(1:5,:);
% %     Graph_b.Index.Names(60)
% 
% 
% % %     kout_knnout_D_in_g = [1:length(k_D_in_g); knn_D_in_g]';
% % %     kout_knnout_D_in_g = flipud(sortrows(kout_knnout_D_in_g,2));
% % % 
% % %     % second dataset    
% % %     for i =1:size(k_D_in_b,1)
% % %         if sum(AU_b(i,:)==1)>0
% % %             j_indices = find(k_D_in_b(i,:)==1);
% % %             sum_kj = sum(k_D_in_b(j_indices));
% % %             knn_D_in_b(i) = sum_kj/k_D_in_b(i);
% % %         else
% % %             knn_D_in_b(i) = 0;
% % %         end
% % %     end
% % %     kout_knnout_D_in_b = [1:length(k_D_in_b); knn_D_in_b]';
% % %     kout_knnout_D_in_b = flipud(sortrows(kout_knnout_D_in_b,2));
% % %     
% % %     % third dataset   
% % %     for i =1:size(k_D_in_3,1)
% % %         if sum(AU_3(i,:)==1)>0
% % %             j_indices = find(k_D_in_3(i,:)==1);
% % %             sum_kj = sum(k_D_in_3(j_indices));
% % %             knn_D_in_3(i) = sum_kj/k_D_in_3(i);
% % %         else
% % %             knn_D_in_3(i) = 0;
% % %         end
% % %     end
% % %     
% % %     kout_knnout_D_in_3 = [1:length(k_D_in_3); knn_D_in_3]';
% % %     kout_knnout_D_in_3 = flipud(sortrows(kout_knnout_D_in_3,2));
% % 
% %     
% % %     
% % %     %% Compute other network properties   
% % %     k_U_g(:,i_year) = nansum(AU_g)';
% % %     k_D_in_g(:,i_year) =  nansum(AD_g,1)'; % sum each column for import
% % %     number_importers_g(:,i_year) = nnz(k_D_in_g(:,i_year)); % compute number of importers 
% % %     number_exporters_g(:,i_year) = nnz(k_D_out_g(:,i_year)); % compute number of exporter 
% % %     
% % %     k_U_b(:,i_year) = nansum(AU_b)';
% % %     k_D_in_b(:,i_year) =  nansum(AD_b,1)'; % sum each column for import
% % %     number_importers_b(:,i_year) = nnz(k_D_in_b(:,i_year)); % compute number of importers 
% % %     number_exporters_b(:,i_year) = nnz(k_D_out_b(:,i_year)); % compute number of exporter 
% % %     
% % %     k_U_3(:,i_year) = nansum(AU_3)';
% % %     k_D_in_3(:,i_year) =  nansum(AD_3,1)'; % sum each column for import
% % %     number_importers_3(:,i_year) = nnz(k_D_in_3(:,i_year)); % compute number of importers 
% % %     number_exporters_3(:,i_year) = nnz(k_D_out_3(:,i_year)); % compute number of exporter 
% % %     
% %     %% Compute weighted degrees in network
% %     kw_U_g(:,i_year) = nansum(WU_g)';
% %     kw_D_in_g(:,i_year) =  nansum(WD_g,1)'; % sum each column for import
% %     kw_D_out_g(:,i_year) = nansum(WD_g,2);  % sum each row for export
% % 
% %     kw_U_b(:,i_year) = nansum(WU_b)';
% %     kw_D_in_b(:,i_year) =  nansum(WD_b,1)'; % sum each column for import
% %     kw_D_out_b(:,i_year) = nansum(WD_b,2);  % sum each row for export
% %     
% %     kw_U_3(:,i_year) = nansum(WU_3)';
% %     kw_D_in_3(:,i_year) =  nansum(WD_3,1)'; % sum each column for import
% %     kw_D_out_3(:,i_year) = nansum(WD_3,2);  % sum each row for export
% %     
% 
%     
%     
% %     %% Clustering Coefficient
% %     CCout_g = mexGraphClusteringCoefficient(Graph_g,[],'inverse');
% %     CCout_b = mexGraphClusteringCoefficient(Graph_b,[],'inverse');
% %     CCout_3 = mexGraphClusteringCoefficient(Graph_3,[],'inverse');