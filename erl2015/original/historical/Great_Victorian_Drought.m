% Asian Monsoon Failure and Megadrought During the Last Millennium
% 
% Science Vol. 328, No. 5977, pp. 486 - 489, 23 April 2010 DOI:
% 10.1126/science.1185188
% 
% Edward R. Cook1, Kevin J. Anchukaitis1, Brendan M. Buckley1, Rosanne D.
% D'Arrigo1, Gordon C. Jacoby1, William E. Wright1,2 1Tree-Ring Laboratory,
% Lamont-Doherty Earth Observatory of Columbia University, Palisades, New
% York 10964 USA 2 School of Forestry and Natural Resources, National
% Taiwan University, Taipei 10617 Taiwan

%% Start clean
clear all; close all; clc;
basefolder = '/Users/michaeljpuma/1876_1878_MegaDrought/';
folder_feature = '/Users/michaeljpuma/MapFeatures/';

%% User defined variables
% Scenario Name Options
% window_cut define the time periods to retain the spatial fields.       
window_cut=[1876 1878];

%% Variables
province_flag = 0; flag_high = 1;
dataset_name='atmos'; var_name='PDSI'; unit_name='-'; var_name_cru = 'pdsi'; unit_name='none'; title_name = 'PDSI'; labelaxis = 'PDSI'; L=[-2 -1.5 -1 -.5 0 .5 1 1.5 2]; c_flag=10; 
convert_F = 0;

%% Regions
area_txt='Asia'; lonmin = 65; lonmax = 143; latmin = -8.5; latmax = 56;
%area_txt='globe'; lonmin = -180; lonmax = 180; latmin = -90; latmax = 90; 
%area_txt='globe'; lonmin = -180; lonmax = 180; latmin = -60; latmax = 80;  
%area_txt='US'; lonmin = -130; lonmax = -65; latmin = 25; latmax = 50; 




%% Load data
vardata = double(ncread([basefolder 'MADApdsi.nc'],'PDSI'));
longitude = double(ncread([basefolder 'MADApdsi.nc'],'lon'));
latitude = double(ncread([basefolder 'MADApdsi.nc'],'lat'));
year = double(ncread([basefolder 'MADApdsi.nc'],'time'));
window_ave =[min(year) max(year)];
yrs=window_ave(1):window_ave(2);
cut_yrs=window_cut(1):window_cut(2);

delta_plot_lon=nanmean(diff(longitude));
delta_plot_lat=nanmean(diff(latitude));

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

%% Extract Time Periods
index_GVD = find(year >= window_cut(1)&year <= window_cut(2));

mean_JJA = nanmean(vardata(:,:,index_GVD),3);

%% Plot OBSERVATIONS
obs_map=flipud(rot90(mean_JJA)); 
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
cmap=colormap_function(c_flag);

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
%map_proj_name='Mollweide';                % shrinks poles, good for global
%map_proj_name='Hammer-Aitoff'; latlim=[-90 90];               % shrinks poles, good for global
map_proj_name='Robinson';

%% Plot maps
% 2-D lat/lon grids for ocean masking
new_lon(:,1)=0.5:.25:360;
new_lat(:,1)=flipud(-89.5:.25:89.5);
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
m_plot(country.x,country.y,'color','k');

caxis([min(L) max(L)]);
m_grid('box','off','linestyle', 'none','xticklabels','','yticklabels','','xtick','','ytick','');
%m_grid('linestyle', 'none','fontsize',16,'fontname','helvetica','FontWeight','bold');
colorbar1 = colorbar('FontName','Times',...
    'FontSize',16,...
    'FontWeight','bold',...
    'XLim',[-0.5 1.5],'LOCATION','EastOutside','Ytick',L(1:length(L)),'YTicklabel',L(1:length(L)),'fontname','helvetica');
title(['Great Victorian Drought (1876-1878)'],'FontSize',32);
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[292   999   845   570])
set(gcf,'PaperPositionMode','auto')
print('-depsc',[basefolder 'figures/PDSI.JJA.GreatDrought.eps' ])

%%orginal map
% %% Map Projection
% %map_proj_name='Equidistant Cylindrical';  % Flat proj, usually use
% %map_proj_name='Lambert Conformal Conic';  % Good for midlatitudes, about size of US
% map_proj_name='Mollweide';                % shrinks poles, good for global
% %map_proj_name='Hammer-Aitoff'; latlim=[-90 90];               % shrinks poles, good for global
% %map_proj_name='Robinson';
% 
% %% Plot maps
% % 2-D lat/lon grids for ocean masking
% new_lon(:,1)=0.5:.25:360;
% new_lat(:,1)=flipud(-89.5:.25:89.5);
% lon_grid=repmat(new_lon',[length(new_lat) 1]);
% lat_grid=repmat(new_lat,[1 length(new_lon)]);
% colormap(cmap)
% hold on
% m_proj(map_proj_name, 'lon', lonlim, 'lat', latlim);
% m_patch(ocean.x,ocean.y,color_ocean,'FaceAlpha',1);
% %m_patch(lon_grid,lat_grid,[.7 .7 .7],'EdgeColor','none');
% %m_patch(lon_grid-360,lat_grid,[0.494 0.60 0.675],'EdgeColor','none');
% h=m_pcolor(longitude-delta_plot_lon, latitude-delta_plot_lat, obs_map);
% set(h,'LineStyle','none')
% 
% if province_flag == 1
%     m_plot(province.x,province.y,'color',[.6 .6 .6]);
% end
% m_plot(country.x,country.y,'color','k');
% 
% caxis([min(L) max(L)]);
% m_grid('linestyle', 'none','fontsize',16,'fontname','helvetica','FontWeight','bold');
% %m_grid('linestyle', 'none','fontsize',16,'fontname','helvetica','FontWeight','bold');
% colorbar1 = colorbar('FontName','Times',...
%     'FontSize',16,...
%     'FontWeight','bold',...
%     'XLim',[-0.5 1.5],'LOCATION','EastOutside','Ytick',L(1:length(L)),'YTicklabel',L(1:length(L)),'fontname','helvetica');
% title(['Great Victorian Drought (1876-1878)'],'FontSize',32);
% set(gcf,'Renderer','painters')
% set(gcf,'OuterPosition',[292   999   845   570])
% set(gcf,'PaperPositionMode','auto')
% print('-depsc',[basefolder 'figures/PDSI.JJA.GreatDrought.eps' ])