%% Dowl Bowl - Shock simulation output
clc; clear; close all

rootdir = '/Users/michaeljpuma/Dropbox/DustBowl/';
%rootdir = '/Users/mpuma/Dropbox/DustBowl/';
fig_dir = [rootdir 'Dropbox/FoodCascadeModel/figures/'];

%% Simulation Parameters
cfrac = 0.01; % fraction of shock absorbed by C before changing trade 
asym = 1;     % asym = 1: shocked countries can't increase their exports if R = 0
kmax = 500;   % max number of iterations
amin = 1e-5;  % any shock below amin (as fraction of net supply) is negligible
tol =  1e-5;  % tolerance for
anim_out = 0; % anim_out=1: return dR, dC and dE for each iteration
Rfrac = 0.2;  % fraction of reserves used   


%% Country Names
load([rootdir 'CountryNames.mat']);


%% Number of reserve fractions & time periods
num_fr = 5;
num_periods = 2;

%% Baseline data
R0_2000=load([rootdir 'dustbowl_disrupt_results_R0_2000.mat']);
R0_2009=load([rootdir 'dustbowl_disrupt_results_R0_2009.mat']);

E0_2000=load([rootdir 'dustbowl_disrupt_results_E0_2000.mat']);
E0_2009=load([rootdir 'dustbowl_disrupt_results_E0_2009.mat']);

P0_2000=load([rootdir 'dustbowl_disrupt_results_P0_2000.mat']);
P0_2009=load([rootdir 'dustbowl_disrupt_results_P0_2009.mat']);


%% Specify disruption
initfrac_Prodlost = 0.4;
indtemp = strfind(CountryNames, 'USA');
IndexC = find(not(cellfun('isempty', indtemp)));


%% Inputs for cascade model
P0=P0_2000.dustbowlResults_P0;
R0=R0_2000.dustbowlResults_R0;
E0=E0_2000.dustbowlResults_E0;
dP = zeros(size(P0));
dP(IndexC) = -initfrac_Prodlost*P0(IndexC);


%%  Adjust reserves to available reserves to be used
Rfrac_vec = zeros(size(R0));
Rfrac_vec(:) = Rfrac;
Rfrac_vec(IndexC) = 1;
R0 = Rfrac_vec.*R0;


%% Call global food network cascade model
[dR,dC,dE,flag_equalibrium] = sim_cascade(dP, P0, R0, E0, cfrac, asym,kmax, amin, anim_out);

%% Diagnostic to check simulation
[ message1, message2 ] = sim_diagnostics( P0, E0, dP, dR, dC, dE, tol, CountryNames);




return

%% Change in Reserves 
dR_Rcoef02_2000=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.2_2000.mat']);
dR_Rcoef04_2000=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.4_2000.mat']);
dR_Rcoef06_2000=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.6_2000.mat']);
dR_Rcoef08_2000=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.8_2000.mat']);
dR_Rcoef10_2000=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef1_2000.mat']);

dR_Rcoef02_2009=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.2_2009.mat']);
dR_Rcoef04_2009=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.4_2009.mat']);
dR_Rcoef06_2009=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.6_2009.mat']);
dR_Rcoef08_2009=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef0.8_2009.mat']);
dR_Rcoef10_2009=load([rootdir 'dustbowl_disrupt_results_dR_Rcoef1_2009.mat']);

DeltaReserve(:,1,1) = dR_Rcoef02_2000.dustbowlResults_dR2000(:);
DeltaReserve(:,2,1) = dR_Rcoef04_2000.dustbowlResults_dR2000(:);
DeltaReserve(:,3,1) = dR_Rcoef06_2000.dustbowlResults_dR2000(:);
DeltaReserve(:,4,1) = dR_Rcoef08_2000.dustbowlResults_dR2000(:);
DeltaReserve(:,5,1) = dR_Rcoef10_2000.dustbowlResults_dR2000(:);

DeltaReserve(:,1,2) = dR_Rcoef02_2009.dustbowlResults_dR2009(:);
DeltaReserve(:,2,2) = dR_Rcoef04_2009.dustbowlResults_dR2009(:);
DeltaReserve(:,3,2) = dR_Rcoef06_2009.dustbowlResults_dR2009(:);
DeltaReserve(:,4,2) = dR_Rcoef08_2009.dustbowlResults_dR2009(:);
DeltaReserve(:,5,2) = dR_Rcoef10_2009.dustbowlResults_dR2009(:);

%% Change in Consumption 
dC_Rcoef02_2000=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.2_2000.mat']);
dC_Rcoef04_2000=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.4_2000.mat']);
dC_Rcoef06_2000=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.6_2000.mat']);
dC_Rcoef08_2000=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.8_2000.mat']);
dC_Rcoef10_2000=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef1_2000.mat']);

dC_Rcoef02_2009=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.2_2009.mat']);
dC_Rcoef04_2009=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.4_2009.mat']);
dC_Rcoef06_2009=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.6_2009.mat']);
dC_Rcoef08_2009=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef0.8_2009.mat']);
dC_Rcoef10_2009=load([rootdir 'dustbowl_disrupt_results_dC_Rcoef1_2009.mat']);

DeltaConsumption(:,1,1) = dC_Rcoef02_2000.dustbowlResults_dC2000(:);
DeltaConsumption(:,2,1) = dC_Rcoef04_2000.dustbowlResults_dC2000(:);
DeltaConsumption(:,3,1) = dC_Rcoef06_2000.dustbowlResults_dC2000(:);
DeltaConsumption(:,4,1) = dC_Rcoef08_2000.dustbowlResults_dC2000(:);
DeltaConsumption(:,5,1) = dC_Rcoef10_2000.dustbowlResults_dC2000(:);

DeltaConsumption(:,1,2) = dC_Rcoef02_2009.dustbowlResults_dC2009(:);
DeltaConsumption(:,2,2) = dC_Rcoef04_2009.dustbowlResults_dC2009(:);
DeltaConsumption(:,3,2) = dC_Rcoef06_2009.dustbowlResults_dC2009(:);
DeltaConsumption(:,4,2) = dC_Rcoef08_2009.dustbowlResults_dC2009(:);
DeltaConsumption(:,5,2) = dC_Rcoef10_2009.dustbowlResults_dC2009(:);

%% Change in Trade 
dE_Rcoef02_2000=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.2_2000.mat']);
dE_Rcoef04_2000=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.4_2000.mat']);
dE_Rcoef06_2000=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.6_2000.mat']);
dE_Rcoef08_2000=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.8_2000.mat']);
dE_Rcoef10_2000=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef1_2000.mat']);

dE_Rcoef02_2009=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.2_2009.mat']);
dE_Rcoef04_2009=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.4_2009.mat']);
dE_Rcoef06_2009=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.6_2009.mat']);
dE_Rcoef08_2009=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef0.8_2009.mat']);
dE_Rcoef10_2009=load([rootdir 'dustbowl_disrupt_results_dE_Rcoef1_2009.mat']);

DeltaExportA(:,:,1,1) = dE_Rcoef02_2000.dustbowlResults_dE2000(:,:);
DeltaExportA(:,:,2,1) = dE_Rcoef04_2000.dustbowlResults_dE2000(:,:);
DeltaExportA(:,:,3,1) = dE_Rcoef06_2000.dustbowlResults_dE2000(:,:);
DeltaExportA(:,:,4,1) = dE_Rcoef08_2000.dustbowlResults_dE2000(:,:);
DeltaExportA(:,:,5,1) = dE_Rcoef10_2000.dustbowlResults_dE2000(:,:);

DeltaExportB(:,:,1,2) = dE_Rcoef02_2009.dustbowlResults_dE2009(:,:);
DeltaExportB(:,:,2,2) = dE_Rcoef04_2009.dustbowlResults_dE2009(:,:);
DeltaExportB(:,:,3,2) = dE_Rcoef06_2009.dustbowlResults_dE2009(:,:);
DeltaExportB(:,:,4,2) = dE_Rcoef08_2009.dustbowlResults_dE2009(:,:);
DeltaExportB(:,:,5,2) = dE_Rcoef10_2009.dustbowlResults_dE2009(:,:);


%% Network Statistics for baseline (undisturbed) networks, 2000 values
if sum(diag(E0_2000.dustbowlResults_E0)) >0
    'E0_2000.dustbowlResults_E0: Countries trade with themselves' %#ok<NOPTS>
    for i = 1:length(E0_2000.dustbowlResults_E0)
        E0_2000.dustbowlResults_E0(i,i) = 0;
    end
    %return
end
[ NumbersOfNodes(1,1),NumbersOfLinks(1,1),NumNodes_out(1,1),NumNodes_in(1,1),TotalFlow(1,1),...
    country_alpha_active_2000(:,1:3),...
    lambda_unweight(1,1), efficiency_unweight(1,1), radius_unweight(1,1), diameter_unweight(1,1),...
    lambda_weight(1,1), efficiency_weight(1,1), radius_weight(1,1), diameter_weight(1,1), ...
    BC_bin(:,1)] ...
    = matrix_stats(E0_2000.dustbowlResults_E0,CountryNames );
%, BC_wei(:,1)

%% Network Statistics for baseline (undisturbed) networks, 2009 values
if sum(diag(E0_2009.dustbowlResults_E0)) >0
    'E0_2009.dustbowlResults_E0: Countries trade with themselves' %#ok<NOPTS>
    for i = 1:length(E0_2009.dustbowlResults_E0)
        E0_2009.dustbowlResults_E0(i,i) = 0;
    end
end
[ NumbersOfNodes(1,2),NumbersOfLinks(1,2),NumNodes_out(1,2),NumNodes_in(1,2),TotalFlow(1,2),...
    country_alpha_active_2009(:,1:3),...
    lambda_unweight(1,2), efficiency_unweight(1,2), radius_unweight(1,2), diameter_unweight(1,2),...
    lambda_weight(1,2), efficiency_weight(1,2), radius_weight(1,2), diameter_weight(1,2), ...
    BC_bin(:,2)] ...
    = matrix_stats(E0_2009.dustbowlResults_E0,CountryNames );
    %, BC_wei(:,2)

%% Extract stats for USA
IndexC = strfind(CountryNames, 'USA');
Index = find(not(cellfun('isempty', IndexC)));
BC_bin_USA =BC_bin(Index,:);
%BC_wei_USA =BC_wei(Index,:);


%% Save statistics to table
StatName = {'# of Nodes';'# of Links';'# of exporting nodes';'# of importing nodes';'Total Trade (tons)';...
    'network (unweighted) characteristic path length'; 'network (unweighted) global efficiency';
    'network radius (unweighted)'; 'network diameter (unweighted)';
    'network (weighted) characteristic path length'; 'network (weighted) global efficiency';
    'network radius (weighted)'; 'network diameter (weighted)'; ...
    'Betweenness Centrality (unweighted) USA'};
%; 'Betweenness Centrality (weighted) USA'
OutStats = [ NumbersOfNodes(1,:);NumbersOfLinks(1,:);NumNodes_out(1,:);NumNodes_in(1,:);TotalFlow(1,:);...
    lambda_unweight(1,:); efficiency_unweight(1,:); radius_unweight(1,:); diameter_unweight(1,:);...
    lambda_weight(1,:); efficiency_weight(1,:); radius_weight(1,:); diameter_weight(1,:); ...
    BC_bin_USA(1,:)];
%; BC_wei_USA(1,:)

T = table(OutStats,...
    'RowNames',StatName);
writetable(T,[rootdir 'DustBowlStats_baseline.dat'],'WriteRowNames',true);


%%  Network Statistics
for i_scen = 1:num_fr % number of fraction R coefficients
    for i_period = 1:num_periods
        
        % WD is the directed trade matrix: forms a
        % weighted, directed network; WD is not symmetric
        if i_period == 1% Year 2000
            WD(:,:) = E0_2000.dustbowlResults_E0+squeeze(DeltaExportA(:,:,i_scen,i_period));
        else% Year 2009
            WD(:,:) = E0_2009.dustbowlResults_E0+squeeze(DeltaExportB(:,:,i_scen,i_period));
        end
        
        % Check diagonal is zero
        % W(i, i) = 0; that is, a country cannot trade with itself.
        if sum(diag(WD)) >0
            'countries trade with themselves' %#ok<NOPTS>
            for i = 1:length(WD)
                WD(i,i) = 0;
            end
        end
        
        [ NumbersOfNodes_EXP(i_scen,i_period),NumbersOfLinks_EXP(i_scen,i_period),...
            NumNodes_out_EXP(i_scen,i_period) ,NumNodes_in_EXP(i_scen,i_period),...
            TotalFlow_EXP(i_scen,i_period) ,...
            country_alpha_active_2000_EXP(:,1:3),...
            lambda_unweight_EXP(i_scen,i_period), efficiency_unweight_EXP(i_scen,i_period),...
            radius_unweight_EXP(i_scen,i_period) , diameter_unweight_EXP(i_scen,i_period) ,...
            lambda_weight_EXP(i_scen,i_period) , efficiency_weight_EXP(i_scen,i_period),...
            radius_weight_EXP(i_scen,i_period) , diameter_weight_EXP(i_scen,i_period) , ...
            BC_bin_EXP(:,i_scen,i_period)] ...
            = matrix_stats(WD,CountryNames );
        
        %, BC_wei_EXP(i_scen,i_period,:)
    end
end

%% Extract stats for USA
IndexC = strfind(CountryNames, 'USA');
Index = find(not(cellfun('isempty', IndexC)));
BC_bin_EXP_USA =squeeze(BC_bin_EXP(Index,:,:));
%BC_wei_USA =BC_wei(Index,:);


OutStats_2000 = [ NumbersOfNodes_EXP(:,1)';NumbersOfLinks_EXP(:,1)';NumNodes_out_EXP(:,1)';NumNodes_in_EXP(:,1)';TotalFlow_EXP(:,1)';...
    lambda_unweight_EXP(:,1)'; efficiency_unweight_EXP(:,1)'; radius_unweight_EXP(:,1)'; diameter_unweight_EXP(:,1)';...
    lambda_weight_EXP(:,1)'; efficiency_weight_EXP(:,1)'; radius_weight_EXP(:,1)'; diameter_weight_EXP(:,1)'; ...
    BC_bin_EXP_USA(:,1)'];
%; BC_wei_USA_EXP(:,1)'

T = table(OutStats_2000,...
    'RowNames',StatName);
writetable(T,[rootdir 'DustBowlStats_fracRexp.dat'],'WriteRowNames',true);
type 'DustBowlStats_fracRexp_2000.dat'



return

%% FIGURES
figure
bar(dustbowlResults_R0)
ylabel('Initial Reserves (kcal)','FontSize',24);
xlabel('Country','FontSize',24);
title(['Cereal Reserves'],'FontSize',28)
%axis([10^-1 10^2.5 10^-1 10^8]);     
%axis square
%set(gca,'XTick',[1.5 3.5 5.5 7.5])
set(gca,'Box','on')
xlim([0 166])
%set(gca,'XTickLabel',{'NE';'S';'W';'FW'})
set(get(gcf,'CurrentAxes'),'FontSize',18)
set(gca,'XMinorTick','off')  % sets Minor X Ticks to display
set(gcf,'Renderer','painters') %only vector graphics that matlab has- painters
%set(gcf,'PaperOrientation','landscape')
set(gcf,'OuterPosition',[170 1200 1000 500]) %left edge botton edge; width height
set(gcf,'PaperPositionMode','auto')
%print('-depsc','-painters','-r600',[fig_dir 'InitialReserves_1996.eps' ])


h=figure;
subplot(4,1,1)
range=1:45;
reserveloss = abs(dustbowlResults_dR(range,1))'/1000000;
bar(range,reserveloss,'LineWidth',1,'BarWidth',1.1)
%legend({'wheat';'maize';'rice'; 'soybean'})
%set the axis properties
ax=gca;
set(ax, 'FontSize',8)
xticklabel_rotate(range,90,CountryNames(range))
set(gca,'xtick',[])


subplot(4,1,2)
range=46:90;
reserveloss = abs(dustbowlResults_dR(range,1))'/1000000;
bar(range,reserveloss,'LineWidth',1,'BarWidth',1.1)
%legend({'wheat';'maize';'rice'; 'soybean'})
%set the axis properties
ax=gca;
set(ax, 'FontSize',8)
xticklabel_rotate(range,90,CountryNames(range))
set(gca,'xtick',[])

subplot(4,1,3)
range=91:125;
reserveloss = abs(dustbowlResults_dR(range,1))'/1000000;
bar(range,reserveloss,'LineWidth',1,'BarWidth',1.1)
%legend({'wheat';'maize';'rice'; 'soybean'})
%set the axis properties
ax=gca;
set(ax, 'FontSize',8)
xticklabel_rotate(range,90,CountryNames(range))
set(gca,'xtick',[])

subplot(4,1,4)
range=126:165;
reserveloss = abs(dustbowlResults_dR(range,1))'/1000000;
bar(range,reserveloss,'LineWidth',1,'BarWidth',1.1)
%legend({'wheat';'maize';'rice'; 'soybean'})
%set the axis properties
ax=gca;
set(ax, 'FontSize',8)
xticklabel_rotate(range,90,CountryNames(range))
set(gca,'xtick',[])


%Don't like the colors? You can change them by modifying the colormap:
%barmap=[c_wheat; c_maize; c_rice ;c_soybean];% is grey, [ 0.05 .45 0.1] is a green
%colormap(barmap);
ylabel('Reserves Lost, million kcal','FontSize',14)
%title('Title of Experiment','FontSize',14)
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[100   100   1200   600]) %left edge botton edge; width height
set(gcf,'PaperPositionMode','auto')
%print('-depsc','-painters','-r600',[fig_dir 'DeltaReserves_dustbowl1997.eps' ])


figure
bar(sum(dustbowlResults_E0,2))
ylabel('Initial Exports (kcal)','FontSize',24);
xlabel('Country','FontSize',24);
title(['Cereal Exports'],'FontSize',28)
%axis([10^-1 10^2.5 10^-1 10^8]);     
%axis square
%set(gca,'XTick',[1.5 3.5 5.5 7.5])
set(gca,'Box','on')
xlim([0 166])
%set(gca,'XTickLabel',{'NE';'S';'W';'FW'})
set(get(gcf,'CurrentAxes'),'FontSize',18)
set(gca,'XMinorTick','off')  % sets Minor X Ticks to display
set(gcf,'Renderer','painters') %only vector graphics that matlab has- painters
%set(gcf,'PaperOrientation','landscape')
set(gcf,'OuterPosition',[170 1200 1000 500]) %left edge botton edge; width height
set(gcf,'PaperPositionMode','auto')
print('-depsc','-painters','-r600',[fig_dir 'InitialExports_1996.eps' ])

Export_avgdelta_1997 = sum(dustbowlResults_dE(:,:,1),2);


figure
bar(Export_avgdelta_1997)
ylabel('\DeltaE (kcal)','FontSize',24);
xlabel('Country','FontSize',24);
title(['Export Change'],'FontSize',28)
%axis([10^-1 10^2.5 10^-1 10^8]);     
%axis square
%set(gca,'XTick',[1.5 3.5 5.5 7.5])
set(gca,'Box','on')
xlim([0 166])
%set(gca,'XTickLabel',{'NE';'S';'W';'FW'})
set(get(gcf,'CurrentAxes'),'FontSize',18)
set(gca,'XMinorTick','off')  % sets Minor X Ticks to display
set(gcf,'Renderer','painters') %only vector graphics that matlab has- painters
%set(gcf,'PaperOrientation','landscape')
set(gcf,'OuterPosition',[170 1200 1000 500]) %left edge botton edge; width height
set(gcf,'PaperPositionMode','auto')
print('-depsc','-painters','-r600',[fig_dir 'DeltaExports_dustbowl1997.eps' ])

