clear; close all; clc; 
%% Dowl Bowl - Multi-year shock simulation
%  DustBowlShock_multiyear.m

rootdir = '/Users/michaeljpuma/Dropbox/DustBowl/';
%rootdir = '/Users/mpuma/Dropbox/DustBowl/';
fig_dir = [rootdir 'figures/'];

%% Country Names
load([rootdir 'CountryNames.mat']);

%% Number of consecutive shock years
num_years = 15; %
years = 1:num_years;

%% Shock specification
initfrac_Prodlost = 0.1;
indtemp = strfind(CountryNames, 'USA');
IndexC = find(not(cellfun('isempty', indtemp)));

%% Simulation Parameters
cfrac = 0;    % fraction of shock absorbed by C before changing trade 
asym = 1;     % asym = 1: shocked countries can't increase their exports if R = 0
kmax = 500;   % max number of iterations
amin = 1e-5;  % any shock below amin (as fraction of net supply) is negligible
tol =  1e-5;  % tolerance for
anim_out = 0; % anim_out=1: return dR, dC and dE for each iteration
%%Rfrac = .1;   % ALL COUNTRIES: fraction of reserves used
num_periods = 2; % number of time periods


%% Baseline data
R0_2000=load([rootdir 'dustbowl_disrupt_results_R0_2000.mat']);
E0_2000=load([rootdir 'dustbowl_disrupt_results_E0_2000.mat']);
P0_2000=load([rootdir 'dustbowl_disrupt_results_P0_2000.mat']);

R0_2009=load([rootdir 'dustbowl_disrupt_results_R0_2009.mat']);
E0_2009=load([rootdir 'dustbowl_disrupt_results_E0_2009.mat']);
P0_2009=load([rootdir 'dustbowl_disrupt_results_P0_2009.mat']);


%% Inputs for cascade model
P0_2000=P0_2000.dustbowlResults_P0;
R0_2000=R0_2000.dustbowlResults_R0;
E0_2000=E0_2000.dustbowlResults_E0;
dP_2000 = zeros(size(P0_2000));
dP_2000(IndexC) = -initfrac_Prodlost*P0_2000(IndexC);

P0_2009=P0_2009.dustbowlResults_P0;
R0_2009=R0_2009.dustbowlResults_R0;
E0_2009=E0_2009.dustbowlResults_E0;
dP_2009 = zeros(size(P0_2009));
dP_2009(IndexC) = -initfrac_Prodlost*P0_2009(IndexC);

%% Network Statistics for baseline networks
% (undisturbed) networks, 2000 values
[ NumbersOfNodes(1,1),NumbersOfLinks(1,1),NumNodes_out(1,1),NumNodes_in(1,1),TotalFlow(1,1),...
    country_alpha_active_2000(:,1:3),...
    lambda_unweight(1,1), efficiency_unweight(1,1), radius_unweight(1,1), diameter_unweight(1,1),...
    lambda_weight(1,1), efficiency_weight(1,1), radius_weight(1,1), diameter_weight(1,1), ...
    BC_bin(:,1), BC_wei(:,1)] ...
    = matrix_stats(E0_2000,CountryNames);

% (undisturbed) networks, 2009 values
[ NumbersOfNodes(1,2),NumbersOfLinks(1,2),NumNodes_out(1,2),NumNodes_in(1,2),TotalFlow(1,2),...
    country_alpha_active_2009(:,1:3),...
    lambda_unweight(1,2), efficiency_unweight(1,2), radius_unweight(1,2), diameter_unweight(1,2),...
    lambda_weight(1,2), efficiency_weight(1,2), radius_weight(1,2), diameter_weight(1,2), ...
    BC_bin(:,2), BC_wei(:,2)] ...
    = matrix_stats(E0_2009,CountryNames);

% Extract stats for USA
BC_bin_USA =BC_bin(IndexC,:);
BC_wei_USA =BC_wei(IndexC,:);

% Save statistics to table
StatName = {'# of Nodes';'# of Links';'# of exporting nodes';'# of importing nodes';'Total Trade (tons)';...
    'network (unweighted) characteristic path length'; 'network (unweighted) global efficiency';
    'network radius (unweighted)'; 'network diameter (unweighted)';
    'network (weighted) characteristic path length'; 'network (weighted) global efficiency';
    'network radius (weighted)'; 'network diameter (weighted)'; ...
    'Betweenness Centrality (unweighted) USA'; 'Betweenness Centrality (weighted) USA'};

OutStats = [ NumbersOfNodes(1,:);NumbersOfLinks(1,:);NumNodes_out(1,:);NumNodes_in(1,:);TotalFlow(1,:);...
    lambda_unweight(1,:); efficiency_unweight(1,:); radius_unweight(1,:); diameter_unweight(1,:);...
    lambda_weight(1,:); efficiency_weight(1,:); radius_weight(1,:); diameter_weight(1,:); ...
    BC_bin_USA(1,:); BC_wei_USA(1,:)];

T = table(OutStats,...
    'RowNames',StatName);
writetable(T,[rootdir 'DustBowlStats_baseline.dat'],'WriteRowNames',true);


%%  Simulation Disruptions
for i_period = 1:num_periods
    
    for i_year = 1:num_years
        
        % WD is the directed trade matrix: forms a
        % weighted, directed network; WD is not symmetric
        if i_period == 1% Year 2000
            
            % Call global food network cascade model
            [dR_2000,dC_2000,dE_2000,flag_equalibrium] = ...
                sim_cascade(dP_2000, P0_2000, R0_2000, E0_2000, ...
                cfrac, asym,kmax, amin, anim_out);
            WD(:,:) = E0_2000 + dE_2000;
            
            [ NumbersOfNodes_EXP(i_year,i_period),NumbersOfLinks_EXP(i_year,i_period),...
                NumNodes_out_EXP(i_year,i_period) ,NumNodes_in_EXP(i_year,i_period),...
                TotalFlow_EXP(i_year,i_period) ,...
                country_alpha_active_2000_EXP(:,1:3),...
                lambda_unweight_EXP(i_year,i_period), efficiency_unweight_EXP(i_year,i_period),...
                radius_unweight_EXP(i_year,i_period) , diameter_unweight_EXP(i_year,i_period) ,...
                lambda_weight_EXP(i_year,i_period) , efficiency_weight_EXP(i_year,i_period),...
                radius_weight_EXP(i_year,i_period) , diameter_weight_EXP(i_year,i_period) , ...
                BC_bin_EXP(:,i_year,i_period) , BC_wei_EXP(:,i_year,i_period)] ...
                = matrix_stats(WD,CountryNames );
            % Diagnostic to check simulation
            [ message1, message2 ] = sim_diagnostics( P0_2000, E0_2000, dP_2000, dR_2000, dC_2000, dE_2000, tol, CountryNames);
            if message1 ==1
                ['Total dC + dR does not match initial shock.']
                return
            elseif message2 ==2
                ['Net supply change does not match dC + dR for countries.']
                return
            end
            
            % Update Reserves 
            R0_2000 = R0_2000 + dR_2000;
            
            ['Shocked reserves in 2000: ' num2str(R0_2000(IndexC))] %#ok<NOPTS>
        else% Year 2009
            
            % Call global food network cascade model
            [dR_2009,dC_2009,dE_2009,flag_equalibrium] = ...
                sim_cascade(dP_2009, P0_2009, R0_2009, E0_2009, ...
                cfrac, asym,kmax, amin, anim_out);
            WD(:,:) = E0_2009 + dE_2009;
            
            [ NumbersOfNodes_EXP(i_year,i_period),NumbersOfLinks_EXP(i_year,i_period),...
                NumNodes_out_EXP(i_year,i_period) ,NumNodes_in_EXP(i_year,i_period),...
                TotalFlow_EXP(i_year,i_period) ,...
                country_alpha_active_2009_EXP(:,1:3),...
                lambda_unweight_EXP(i_year,i_period), efficiency_unweight_EXP(i_year,i_period),...
                radius_unweight_EXP(i_year,i_period) , diameter_unweight_EXP(i_year,i_period) ,...
                lambda_weight_EXP(i_year,i_period) , efficiency_weight_EXP(i_year,i_period),...
                radius_weight_EXP(i_year,i_period) , diameter_weight_EXP(i_year,i_period) , ...
                BC_bin_EXP(:,i_year,i_period) , BC_wei_EXP(:,i_year,i_period)] ...
                = matrix_stats(WD,CountryNames );
            
            % Diagnostic to check simulation
            [ message1, message2 ] = sim_diagnostics( P0_2009, E0_2009, dP_2009, dR_2009, dC_2009, dE_2009, tol, CountryNames);
            
            % Update Reserves 
            R0_2009 = R0_2009 + dR_2009;
            
        end
        
    end
    
end


%% Extract stats for USA
IndexC = strfind(CountryNames, 'USA');
Index = find(not(cellfun('isempty', IndexC)));
BC_bin_EXP_USA =squeeze(BC_bin_EXP(Index,:,:));
BC_wei_EXP_USA =squeeze(BC_wei_EXP(Index,:,:));

%% Save statistics to table
StatName = {'# of Nodes';'# of Links';'# of exporting nodes';'# of importing nodes';'Total Trade (tons)';...
    'network (unweighted) characteristic path length'; 'network (unweighted) global efficiency';
    'network radius (unweighted)'; 'network diameter (unweighted)';
    'network (weighted) characteristic path length'; 'network (weighted) global efficiency';
    'network radius (weighted)'; 'network diameter (weighted)'; ...
    'Betweenness Centrality (unweighted) USA'; 'Betweenness Centrality (weighted) USA'};

OutStats_2000 = [ NumbersOfNodes_EXP(:,1)';NumbersOfLinks_EXP(:,1)';NumNodes_out_EXP(:,1)';NumNodes_in_EXP(:,1)';TotalFlow_EXP(:,1)';...
    lambda_unweight_EXP(:,1)'; efficiency_unweight_EXP(:,1)'; radius_unweight_EXP(:,1)'; diameter_unweight_EXP(:,1)';...
    lambda_weight_EXP(:,1)'; efficiency_weight_EXP(:,1)'; radius_weight_EXP(:,1)'; diameter_weight_EXP(:,1)'; ...
    BC_bin_EXP_USA(:,1)'; BC_wei_EXP_USA(:,1)'];

T = table(OutStats_2000,...
    'RowNames',StatName);
writetable(T,[rootdir 'DustBowlStats_fracRexp_2000.dat'],'WriteRowNames',true);

OutStats_2009 = [ NumbersOfNodes_EXP(:,2)';NumbersOfLinks_EXP(:,2)';NumNodes_out_EXP(:,2)';NumNodes_in_EXP(:,2)';TotalFlow_EXP(:,2)';...
    lambda_unweight_EXP(:,2)'; efficiency_unweight_EXP(:,2)'; radius_unweight_EXP(:,2)'; diameter_unweight_EXP(:,2)';...
    lambda_weight_EXP(:,2)'; efficiency_weight_EXP(:,2)'; radius_weight_EXP(:,2)'; diameter_weight_EXP(:,2)'; ...
    BC_bin_EXP_USA(:,2)'; BC_wei_EXP_USA(:,2)'];

T = table(OutStats_2009,...
    'RowNames',StatName);
writetable(T,[rootdir 'DustBowlStats_fracRexp_2009.dat'],'WriteRowNames',true);


%% Figures
titlename = 'Characteristic weighted path length';
labX = 'Year';
X_data=years;
labY = '\lambda_{w}';
Y_data=lambda_weight_EXP;
filename = [fig_dir 'lambda_weight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,lambda_weight,titlename,filename,leg_names);

titlename = 'Characteristic unweighted path length';
labX = 'Year';
X_data=years;
labY = '\lambda';
Y_data=lambda_unweight_EXP;
filename = [fig_dir 'lambda_unweight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,lambda_unweight,titlename,filename,leg_names);

titlename = 'Global Network Efficiency (Unweighted)';
labX = 'Year';
X_data=years;
labY = 'Efficiency';
Y_data=efficiency_unweight_EXP;
filename = [fig_dir 'efficiency_unweight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,efficiency_unweight,titlename,filename,leg_names);

titlename = 'Global Network Efficiency (Weighted)';
labX = 'Year';
X_data=years;
labY = 'Efficiency';
Y_data=efficiency_weight_EXP;
filename = [fig_dir 'efficiency_weight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,efficiency_weight,titlename,filename,leg_names);

titlename = 'Global Network Radius (Unweighted)';
labX = 'Year';
X_data=years;
labY = 'Radius';
Y_data=radius_unweight_EXP;
filename = [fig_dir 'radius_unweight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,radius_unweight,titlename,filename,leg_names);

titlename = 'Global Network Radius (Weighted)';
labX = 'Year';
X_data=years;
labY = 'Radius';
Y_data=radius_weight_EXP;
filename = [fig_dir 'radius_weight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,radius_weight,titlename,filename,leg_names);

titlename = 'Global Network Diameter (Unweighted)';
labX = 'Year';
X_data=years;
labY = 'Diameter';
Y_data=diameter_unweight_EXP;
filename = [fig_dir 'diameter_unweight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,diameter_unweight,titlename,filename,leg_names);

titlename = 'Global Network Diameter (Weighted)';
labX = 'Year';
X_data=years;
labY = 'Diameter';
Y_data=diameter_weight_EXP;
filename = [fig_dir 'diameter_weight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,diameter_weight,titlename,filename,leg_names);

titlename = 'Betweenness Centrality of USA (Unweighted)';
labX = 'Year';
X_data=years;
labY = 'B_{c}';
Y_data=BC_bin_EXP_USA;
filename = [fig_dir 'BC_unweight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,BC_bin_USA,titlename,filename,leg_names);

titlename = 'Betweenness Centrality of USA (Weighted)';
labX = 'Year';
X_data=years;
labY = 'B_{c}';
Y_data=BC_wei_EXP_USA;
filename = [fig_dir 'BC_weight.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,BC_wei_USA,titlename,filename,leg_names);


titlename = 'Total Cereal Trade';
labX = 'Year';
X_data=years;
labY = 'kcal';
Y_data=TotalFlow_EXP;
filename = [fig_dir 'TotalFlow.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,TotalFlow,titlename,filename,leg_names);

titlename = 'Number of Nodes';
labX = 'Year';
X_data=years;
labY = 'number';
Y_data=NumbersOfNodes_EXP;
filename = [fig_dir 'NUmberofNodes.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,NumbersOfNodes,titlename,filename,leg_names);

titlename = 'Number of Links';
labX = 'Year';
X_data=years;
labY = 'number';
Y_data=NumbersOfLinks_EXP;
filename = [fig_dir 'NumbersOfLinks.eps'];
leg_names = {'2000';'2009'};
puma_line( X_data,Y_data,labX,labY,NumbersOfLinks,titlename,filename,leg_names);
