% Gridded seasonal absolute surface air temperature for Europe 1500-2002:
% 
% ORIGINAL REFERENCES: Using the reconstructed data, please cite
% 
% Luterbacher, J., Dietrich, D., Xoplaki, E., Grosjean, M., and Wanner, H.,
% 2004: European seasonal and annual temperature variability, trends, and
% extremes since 1500, Science 303, 1499-1503
% (DOI:10.1126/science.1093877).
% 
% Xoplaki, E., Luterbacher, J., Paeth, H., Dietrich, D., Steiner N.,
% Grosjean, M., and Wanner, H., 2005: European spring and autumn
% temperature variability and change of extremes over the last half
% millennium, Geophys. Res. Lett., 32, L15713 (DOI:10.1029/2005GL023424).
%% Start clean
clear all; close all; clc;
basefolder = '/Users/michaeljpuma/1816_Data/';
folder_feature = '/Users/michaeljpuma/MapFeatures/';

%% User defined variables
% Scenario Name Options
% window_cut define the time periods to retain the spatial fields.       

window_ave =[1500 2002]; % 
scen_name1='climatology'; window_cut=[1971 2000];%window_cut=[1900 1995];

yrs=window_ave(1):window_ave(2);
cut_yrs=window_cut(1):window_cut(2);

%% Variables
province_flag = 0; flag_high = 1;
dataset_name='atmos'; var_name='tas'; unit_name='K'; var_name_cru = 'tmp'; unit_name_cru='^oC'; title_name = 'Temperature'; labelaxis = 'T'; L=[-4:1:4]; c_flag=35; 
convert_F = 0;

%% Colors
color_ocean = rgb('LightSlateGrey');
color_land = rgb('Cornsilk');
color_basin = rgb('DarkGreen');

%% Physical and cultural features for plots
if flag_high == 1
    country = shape_read([folder_feature '10m_cultural/10m_cultural/ne_10m_admin_0_countries.shp']);
    provinces = shape_read([folder_feature '10m_cultural/10m_cultural/ne_10m_admin_1_states_provinces_lines_shp.shp']);
    rivers_lakes = shape_read([folder_feature '10m_physical/ne_10m_rivers_lake_centerlines.shp']);
    ocean = shape_read([folder_feature '10m_physical/ne_10m_ocean.shp']);
    land = shape_read([folder_feature '10m_physical/ne_10m_land.shp']);
    coastline = shape_read([folder_feature '10m_physical/ne_10m_coastline.shp']);
elseif flag_high == 0
    country = shape_read([folder_feature '50m_cultural/ne_50m_admin_0_countries.shp']);
    provinces = shape_read([folder_feature '50m_cultural/ne_50m_admin_1_states_provinces_lines.shp']);
    rivers_lakes = shape_read([folder_feature '50m_physical/ne_50m_rivers_lake_centerlines.shp']);
    ocean = shape_read([folder_feature '50m_physical/ne_50m_ocean.shp']);
    land = shape_read([folder_feature '50m_physical/ne_50m_land.shp']);
    coastline = shape_read([folder_feature '50m_physical/ne_50m_coastline.shp']);
end

%% Define Area for Europe
% Grid: 0.5? x 0.5?  
% Spatial area: 25W - 40E und 35 - 70N
% Note: the date are valied for a 0.5x0.5deg box. The center of the box is
% always on a xx.25 coordinate
basin_name='Europe'; area_txt='Europe'; lonmin = -25; lonmax = 40; latmin = 35; latmax = 70;

%% Load Absolute temperature data
TT_Europe_1500_2002_New=load([basefolder 'TT_Europe_1500_2002_New.GDX']);
year_season = TT_Europe_1500_2002_New(:,1); num_seasons = size(year_season,1);
TT_data = TT_Europe_1500_2002_New(:,2:end); 
clear TT_Europe_1500_2002_New;

%YearSeason followed by 9100 Gridpoints
%Seasons are given as  13(Winter, DJF), 14(Spring, MAM), 15 (Summer, JJA), 16 (Autumn, SON)
for i_seas =1:num_seasons
    temp=int2str(year_season(i_seas));
    temp1=temp(1:4); temp2=temp(5:6);
    year_TT(i_seas,1) = str2num(temp1);
    seas_TT(i_seas,1) = str2num(temp2);
end
clear temp temp1 temp2;

% Grid and reshape
delta_plot_lon=.5; delta_plot_lat=.5;
longitude = lonmin+.25:delta_plot_lon:lonmax-.25;
latitude = latmin+.25:delta_plot_lat:latmax-.25;
obs_data = zeros(length(longitude),length(latitude),num_seasons);
for i_seas =1:num_seasons
    temp(1,:) = TT_data(i_seas,:);
    obs_data(:,:,i_seas)=reshape(temp,length(longitude),length(latitude));
end
obs_data(find(obs_data<=-999))=NaN;
clear TT_data;

%% Extract Time Periods
index_JJA = seas_TT==15;
index_1816 = year_TT == 1816;
index_clim = (year_TT >= window_cut(1)&year_TT <= window_cut(2));
index_clim_JJA = find(index_clim==1 & index_JJA == 1);
index_1816_JJA = find(index_1816==1 & index_JJA == 1);

anomaly_JJA = squeeze(obs_data(:,:,index_1816_JJA))-nanmean(obs_data(:,:,index_clim_JJA),3);

%% Plot OBSERVATIONS
obs_map=rot90(anomaly_JJA); 
%% Plot vectors
%CS = {'k','b','r','g','m','c'};%,'y'
CS =[0.1059,0.6196,0.4667;...
  0.8510,0.3725,0.0078;...
  0.4588,0.4392,0.7020;...
  0.9059,0.1608,0.5412;...
  0.4000,0.6510,0.1176;...
  0.9020,0.6706,0.0078;...
  0.6510,0.4627,0.1137;...
  0.4000,0.4000,0.4000];
MS={'o','s','d','+','*','s','x','o'};%'+','*','x','^','>','<','p','h'};
LS = {'-.','--','-',':'};

%% Get colormap for plots
cmap=flipud(colormap_function(c_flag));

%% Lat/Lon limits for map
country = shape_read('/Users/michaeljpuma/matlab_files/10m-admin-0-countries/10m_admin_0_countries.shp');
province = shape_read('/Users/michaeljpuma/matlab_files/10m-admin-1-states-provinces-shp/10m_admin_1_states_provinces_shp.shp');

%% Place plotting limits into vector
reduce_plot = 1;
lonlim=[lonmin+reduce_plot lonmax-reduce_plot];
latlim=[latmin latmax-reduce_plot];

%% Map Projection
%map_proj_name='Equidistant Cylindrical';  % Flat proj, usually use
%map_proj_name='Lambert Conformal Conic';  % Good for midlatitudes, about size of US
map_proj_name='Mollweide';                % shrinks poles, good for global
%map_proj_name='Hammer-Aitoff'; latlim=[-90 90];               % shrinks poles, good for global
%map_proj_name='Robinson';

%% Plot maps
figure
% 2-D lat/lon grids for ocean masking
new_lon(:,1)=0.5:.25:360;
new_lat(:,1)=-89.5:.25:89.5;
lon_grid=repmat(new_lon',[length(new_lat) 1]);
lat_grid=repmat(new_lat,[1 length(new_lon)]);
colormap(cmap)
hold on
m_proj(map_proj_name, 'lon', lonlim, 'lat', latlim);
%m_patch(ocean.x,ocean.y,color_ocean,'FaceAlpha',1);
%m_patch(lon_grid,lat_grid,[.7 .7 .7],'EdgeColor','none');
%m_patch(lon_grid-360,lat_grid,[0.494 0.60 0.675],'EdgeColor','none');
h=m_pcolor(longitude-delta_plot_lon, latitude-delta_plot_lat, obs_map);
set(h,'LineStyle','none')

if province_flag == 1
    m_plot(province.x,province.y,'color',[.6 .6 .6]);
end
set(gca,'color',[.9 .99 1]);     % Trick is to set this *before* the patch call.
m_plot(country.x,country.y,'color','k');
%m_coast('patch',[.6 .6 .6]);
caxis([min(L) max(L)]);
%m_grid('linestyle', 'none','fontsize',16,'fontname','helvetica','FontWeight','bold');
m_grid('box','off','linestyle', 'none','xticklabels','','yticklabels','','xtick','','ytick','');
colorbar1 = colorbar('FontName','Times',...
    'FontSize',16,...
    'FontWeight','bold',...
    'XLim',[-0.5 1.5],'LOCATION','EastOutside','Ytick',L(1:length(L)),'YTicklabel',L(1:length(L)),'fontname','helvetica');
title(['Year Without a Summer (1816)'],'FontSize',32);
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[292   999   845   570])
set(gcf,'PaperPositionMode','auto')
print('-depsc','-painters','-r600',[basefolder 'figures/TTanomaly_JJA_1816.eps' ])
