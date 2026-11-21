function [crop_name_out,crop_fname_out]=crop_lookup(crop_id)

% Create a crop name vector

CropName = {...
'Wheat'
'Maize'
'Rice'
'Barley'
'Rye'
'Millet'
'Sorghum'
'Soybeans'
'Sunflower'
'Potatoes'
'Cassava'
'Sugar cane'
'Sugar beets'
'Oil palm'
'Rapeseed / canola'
'Groundnuts / Peanuts'
'Pulses'
'Citrus'
'Date palm'
'Grapes / vine'
'Cotton'
'Cocoa'
'Coffee'
'Others (perennial)'
'Managed grassland/pasture'
'Others (annual)'
};

CropFName = {...
'C01'
'C02'
'C03'
'C04'
'C05'
'C06'
'C07'
'C08'
'C09'
'C10'
'C11'
'C12'
'C13'
'C14'
'C15'
'C16'
'C17'
'C18'
'C19'
'C20'
'C21'
'C22'
'C23'
'C24'
'C25'
'C26'
};

crop_name_out = CropName{crop_id};
crop_fname_out = CropFName{crop_id};