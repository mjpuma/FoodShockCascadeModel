% equilibrium_actual.m
% Code is to load annual virtual water data from Siebert and Doell (2010) 
clear all; close all; clc
% Flags
save_figure=0; % 0 => no; 1 => yes
province_flag = 0; % province/state boundaries
shade_flag = 0;    % 0 for flat and 1 for interp
plot_log = 0;      % Flag to plot colorbar with log scale
plot_countrycodes = 0; % Flag to plot country codes

% Years to Compare between the two scenarios
anomaly_years  = 2000:2000;

%% Identify Base Directory
base_VW   ='/Users/admin/Documents/Documents_main/Virtual_water/Siebert/';
figure_dir='/Users/admin/Documents/Documents_main/Virtual_water/Siebert/figs/';

% Data name: ANNUAL_CWU_XXC_YYYY_05_MM_CZZ_1998_2002.ASC => 
% Mean annual crop water use 1998-2002 of crop ZZ in 5 minute resolution 
% in mm, YYYY is either BLUE (irrigation water) or GREEN (precipitation 
% stored in the soil), XX is either IR (irrigated) or RF (rainfed)

% To convert water uses in mm/yr to water uses in m3/yr please use 
% the following formula:
% crop_water_use_m3 = crop_water_use_mm * 10 * cellarea_ha
% A grid containing cell areas of the 5-minute grid cells in hectares 
% is included in the zip-archive (CELLAREA_05MN.ASC)
% 
% Lets assume that we want to compute total annual blue water use of a 
% soybeans in m3 yr-1. Then we need the following equation:
% 10 * CELLAREA_05MN.ASC * (ANNUAL_CWU_IRC_BLUE_05_MM_C08_1998_2002.ASC + 
%                           ANNUAL_CWU_RFC_BLUE_05_MM_C08_1998_2002.ASC)

% Irrigated crops:  ANNUAL_CWU_IFC_BLUE*is the evapotranspiration from
% irrigation water used on irrigated crops.

% Irrigated crops: ANNUAL_CWU_IFC_GREEN*is the evapotranspiration from
% precipitation of irrigated crops.

% Rainfed crops: ANNUAL_CWU_RFC_GREEN*is the evapotranspiration due to
% precipitation of rainfed crops.

% Rainfed crops: ANNUAL_CWU_RFC_BLUE refers to irrigation water still
% stored in the soil that is used by a rainfed crop which follows an
% irrigated crop.

crop_num = 1;


% variable filename info
watersources = {'RFC','IRC'};
watercolors = {'GREEN','BLUE'};

% water_color_flag = 1;
% watercolor = watercolors{water_color_flag};

[crop_name,crop_fname]=crop_lookup(crop_num);
dataname_print=[crop_name ' Total'];

% fixed filename info
dataname='ANNUAL_CWU'; year_range ='1998_2002'; resolution = '05_MM';

%% Lat/Lon limits for map
% Globe
lonmin = -180; lonmax = 180; latmin = -90; latmax = 90; area_txt='globe'; area_file='globe';
%lonmin = -180; lonmax = 180; latmin = 0; latmax = 90; area_txt='nhem';
% Latitutde bands
%lonmin = -180; lonmax = 180; latmin = 60; latmax = 90; area_txt='nhhi';
%lonmin = -180; lonmax = 180; latmin = 30; latmax = 60; area_txt='nhmid';
%lonmin = -180; lonmax = 180; latmin = 0; latmax = 30; area_txt='nhlo';
%lonmin = -180; lonmax = 180; latmin = -30; latmax = 0; area_txt='shlo';
%lonmin = -180; lonmax = 180; latmin = -60; latmax = -30; area_txt='shmid';
% Full globe
%lonmin = -180; lonmax = 180; latmin = -90; latmax = 90; area_txt='globe';
% Robock Regions
%lonmin = -104; lonmax = -98; latmin = 33; latmax = 44; area_txt='robreg1';
%lonmin = -98; lonmax = -92; latmin = 36; latmax = 45; area_txt='robreg2';
%lonmin = -92; lonmax = -85; latmin = 36; latmax = 45; area_txt='robreg3';
%lonmin = -98; lonmax = -85; latmin = 30; latmax = 36; area_txt='robreg4';
%lonmin = -108; lonmax = -90; latmin = 35; latmax = 44; area_txt='robnew';
% NEW PAPER REGIONS
%lonmin = -130; lonmax = -85; latmin = 30; latmax = 46; area_txt='newna';
%lonmin = -4; lonmax = 40; latmin = 42; latmax = 70; area_txt='neurope';
%lonmin = 98; lonmax = 122; latmin = 22; latmax = 42; area_txt='china';
%lonmin = 68; lonmax = 88; latmin = 8; latmax = 36; area_txt='india';
%lonmin = 35; lonmax = 67; latmin = 15; latmax = 48; area_txt='mideast';
%lonmin = -14; lonmax = 28; latmin = 30; latmax = 42; area_txt='mediter';
%lonmin = -80; lonmax = -45; latmin = -41; latmax = -27; area_txt='sam';
%lonmin = 39; lonmax = 62; latmin = 48; latmax = 68; area_txt='easteuro';
% For Cook, Puma, Krakauer
%lonmin = 98; lonmax = 122; latmin = 22; latmax = 42; area_txt='China';
%lonmin = -130; lonmax = -100; latmin = 30; latmax = 50; area_txt='westna';
%lonmin = -30; lonmax = 30; latmin = 7; latmax = 15; area_txt='sahel';
%lonmin = -130; lonmax = -70; latmin = 26; latmax = 50; area_txt='US';
% For Food Security
%%lonmin = -125; lonmax = -115; latmin = 32; latmax = 45; area_txt='Central Valley'; area_file='CA';
%%lonmin = -110; lonmax = -90; latmin = 32; latmax = 45; area_txt='High Plains'; area_file='highplains';
%lonmin = -125; lonmax = -95; latmin = 30; latmax = 45; area_txt='West US'; area_file='west_us';
%lonmin = 108; lonmax = 124; latmin = 32; latmax = 44; area_txt='NE China'; area_file='NEchina';
%lonmin = 64; lonmax = 88; latmin = 7; latmax = 35; area_txt='Pakistan/India'; area_file='pakistan_india';
%lonmin = 54; lonmax = 120; latmin = -5; latmax = 40; area_txt='Southern Asia'; area_file='S_asia';
% Central America
%lonmin = -104; lonmax = -76; latmin = 5.5; latmax = 23.5; area_txt='centamer';
% SE Asia
%lonmin = 93; lonmax = 112; latmin = 4.5; latmax = 23.5; area_txt='indochin';
% Mexico
%lonmin = -120; lonmax = -80; latmin = 10; latmax = 35; area_txt='Mexico'; area_file='Mex';
% For NASA ROSES Water
%lonmin = 30; lonmax = 52; latmin = 0; latmax = 16; area_txt='E Africa'; area_file='EAfrica';
%lonmin = 95; lonmax = 110; latmin = 8; latmax = 23; area_txt='SE Asia'; area_file='SEasia';
%lonmin = -95; lonmax = -80; latmin = 7; latmax = 20; area_txt='C America'; area_file='C_America';

% Lat/Lon limits for map
lonlim=[lonmin lonmax];
latlim=[latmin latmax];

% Map Projection
map_proj_name='Equidistant Cylindrical';  % Flat proj -- good for global/regional
%map_proj_name='Lambert Conformal Conic';  % Good for midlatitudes, about size of US
%map_proj_name='Mollweide';                % shrinks poles, good for global
%map_proj_name='Hammer-Aitoff'; latlim=[-90 90];               % shrinks poles, good for global


% Create a monthly name vector
monthName = {...
    'ANN'
    };

%% Load country admin codes
[country_codes,R] = arcgridread('/Users/admin/Documents/Documents_main/Virtual_water/Siebert/administrative_units/ADMIN_CODE.ASC');
country_codes = flipud(country_codes);
country_codes = floor(country_codes/1000);

%% Latitude/Longitude information in Siebert files
ncols=4320; nrows=2160; xllcorner=-180; yllcorner=-90; cellsize=5/60;
delta_plot_lat = cellsize; delta_plot_lon = cellsize;
latitude=(yllcorner)+cellsize/2:cellsize:90;
longitude=(xllcorner)+cellsize/2:cellsize:180;


%% Read in  grid cell areas (hectares); 
fname=[base_VW 'CELLAREA_05MN.ASC'];
[latloncell_area,R] = arcgridread(fname);
latloncell_area = latloncell_area*10000;% convert to sq meters (1 hectare = 10000 m2)
%[latloncell_area_b,subgrid_area,new_lon,new_lat] = ...
%        A_latloncell(latitude,longitude,delta_plot_lat,lonmin,lonmax,latmin,latmax);

VWC_data = zeros(nrows,ncols);

if plot_countrycodes ~= 1

    %% Loop over water colors
    for i_color = 1:2
        
        watercolor = watercolors{i_color};
        
        %% Loop over water sources
        for i_source = 1:2
            
            watersource = watersources{i_source};
            
            %% Variable name, test level, etc
            varname=[crop_fname '_' watersource '_' watercolor]; vartxt=dataname_print; unit_txt='mm/yr'; L=[0 10 20 30 40 50]; c_flag=2;
            %varname=[crop_fname '_' watersource '_' watercolor]; vartxt=dataname_print; unit_txt='mm yr^{-1}'; L=[10 27 115 500]; c_flag=2;
            
            %% Allocate memory and load data
            fname=[base_VW dataname '_' watersource '_' watercolor '_' resolution '_' crop_fname '_' year_range '.ASC'];
            [VWC_temp,R] = arcgridread(fname);
            
            %% Sum rainfed and irrigated crop water use
            VWC_data=VWC_data + flipud(VWC_temp);
            
        end
    end
end


%% Number of countries in Siebert database
num_countries = 231;
VWC_data_country_vol=zeros(num_countries,1);
%% Loop over countries
for i_country = 1:num_countries
    ID_temp = country_newindex(i_country);
    country_temp = country_newlookup(i_country)
    temp = country_codes==ID_temp;
    VWC_data_country= VWC_data.*temp;
    VWC_data_country_vol(i_country,1) = ...
        nansum(nansum((VWC_data_country/1000).*latloncell_area));
end


%% Calculate area averages
if plot_countrycodes == 1
    control = country_codes; L=[1.0 840 1000]; c_flag=1;
    vartxt='country'; unit_txt='-'; 
    clear VWC_data country_codes;
else
    control = VWC_data; clear VWC_data country_codes;
end

control(control<=0)=NaN;
cut_lat_ind  = find(latitude <=latmax & latitude >=latmin);
cut_lon_ind  = find(longitude <=lonmax & longitude >=lonmin);
cut_lat = latitude(cut_lat_ind);
cut_lon = longitude(cut_lon_ind);
control_cut=control(cut_lat_ind,cut_lon_ind);
subgrid_area=latloncell_area(cut_lat_ind,cut_lon_ind); 

%% Colormap Selection
%		http://soliton.vm.bytemark.co.uk/pub/cpt-city/cb/index.html
%		http://www.ncl.ucar.edu/Document/Graphics/ColorTables/colorblind_gr.shtml
if c_flag==1
    % hot or HSV
    cmap=flipud(hsv(50));
    %cmap=flipud(hot(50));
elseif c_flag==2
    % cpt-city/cb/seq/YlGnBu_09
    cmap=[...
%        1.0000,1.0000,0.8510;...
%        1.0000,1.0000,0.8510;...
        0.9294,0.9725,0.6941;...
        0.9294,0.9725,0.6941;...
        0.7804,0.9137,0.7059;...
        0.7804,0.9137,0.7059;...
        0.4980,0.8039,0.7333;...
        0.4980,0.8039,0.7333;...
        0.2549,0.7137,0.7686;...
        0.2549,0.7137,0.7686;...
        0.1137,0.5686,0.7529;...
        0.1137,0.5686,0.7529;...
        0.1333,0.3686,0.6588;...
        0.1333,0.3686,0.6588;...
        0.1451,0.2039,0.5804;...
        0.1451,0.2039,0.5804;...
        0.0314,0.1137,0.3451;...
        0.0314,0.1137,0.3451];
elseif c_flag==3
        %cpt-city/cb/seq/Reds_09
     cmap=[...
  1.0000,1,1;...
  1.0000,0.9608,0.9412;...
  0.9961,0.8784,0.8235;...
  0.9961,0.8784,0.8235;...
  0.9882,0.7333,0.6314;...
  0.9882,0.7333,0.6314;...
  0.9882,0.5725,0.4471;...
  0.9882,0.5725,0.4471;...
  0.9843,0.4157,0.2902;...
  0.9843,0.4157,0.2902;...
  0.9373,0.2314,0.1725;...
  0.9373,0.2314,0.1725;...
  0.7961,0.0941,0.1137;...
  0.7961,0.0941,0.1137;...
  0.6471,0.0588,0.0824;...
  0.6471,0.0588,0.0824;...
  0.4039,0.0000,0.0510;...
  0.4039,0.0000,0.0510];
elseif c_flag==4
       cmap=[0.4039,0.0000,0.1216;...
  0.4039,0.0000,0.1216;...
  0.6980,0.0941,0.1686;...
  0.6980,0.0941,0.1686;...
  0.8392,0.3765,0.3020;...
  0.8392,0.3765,0.3020;...
  0.9569,0.6471,0.5098;...
  0.9569,0.6471,0.5098;...
  0.9922,0.8588,0.7804;...
  0.9922,0.8588,0.7804;...
  0.9686,0.9686,0.9686;...
  0.9686,0.9686,0.9686;...
  0.8196,0.8980,0.9412;...
  0.8196,0.8980,0.9412;...
  0.5725,0.7725,0.8706;...
  0.5725,0.7725,0.8706;...
  0.2627,0.5765,0.7647;...
  0.2627,0.5765,0.7647;...
  0.1294,0.4000,0.6745;...
  0.1294,0.4000,0.6745;...
  0.0196,0.1882,0.3804;...
  0.0196,0.1882,0.3804];
  cmap = flipud(cmap);
end



%% Plots 
%seasname=['(' seas ', ' num2str(anomaly_years(1)) '-' num2str(anomaly_years(length(anomaly_years))) ')'];
seasname=['ANN'];
titlestring=[vartxt ' (' dataname_print '), ' unit_txt ' ' seasname];


country = shape_read('/Users/admin/Documents/Documents_main/matlab_files/10m-admin-0-countries/10m_admin_0_countries.shp');
province = shape_read('/Users/admin/Documents/Documents_main/matlab_files/10m-admin-1-states-provinces-shp/10m_admin_1_states_provinces_shp.shp');

figure
colormap(cmap)
m_proj(map_proj_name, 'lon', lonlim, 'lat', latlim);   
hold on

if plot_log ~= 1
    m_pcolor(cut_lon-delta_plot_lon, cut_lat-delta_plot_lat, control_cut)
else
    titlestring = 'Country Codes';
    m_pcolor(cut_lon-delta_plot_lon, cut_lat-delta_plot_lat, log10(control_cut))
end

if shade_flag == 0
    shading flat
elseif shade_flag == 1
    shading interp
end

if province_flag == 1
    m_plot(province.x,province.y,'color',[.6 .6 .6]);
end
m_plot(country.x,country.y,'color',[.2 .2 .2]);

m_grid('box','fancy','linestyle', 'none','fontsize',16,'fontname','helvetica','FontWeight','bold');
%m_grid('linestyle', 'none','fontsize',16,'fontname','helvetica','FontWeight','bold');

if plot_log ~= 1
    caxis([min(L) max(L)]);
    colorbar1 = colorbar('FontName','Times',...
        'FontSize',14,...
        'FontWeight','bold',...
        'XLim',[-0.5 1.5],'LOCATION','EastOutside','Ytick',L(1:length(L)),'YTicklabel',L(1:length(L)),'fontname','helvetica');
else
    myscale = [min(L) max(L)];
    h=colorbar('EastOutside',...
        'FontSize',14,...
        'FontWeight','bold');
    caxis(log10(myscale))
    ticks_wanted=L;
    set(h,'YTick',log10(ticks_wanted));
    set(h,'YTickLabel',ticks_wanted);
end

title(['\fontname{helvetica} \fontsize{18} \bf{' titlestring '}']);
set(gcf,'Renderer','painters')
set(gcf,'OuterPosition',[292   999   845   570])
set(gcf,'PaperPositionMode','auto')

if save_figure>0
   print('-depsc','-painters','-r600',[figure_dir varname '.' 'ANN_' dataname '_' area_txt '.eps' ])
   %print('-dpsc2','-painters',[figure_dir varname '.' seas '_' simname1 '-' dataname '.eps' ])
   %print('-dpsc2','-painters',[figure_dir varname '.' seas '_' simname1 '-' dataname '.' num2str(anomaly_years(1)) '-' num2str(anomaly_years(end))  '.eps' ])
end