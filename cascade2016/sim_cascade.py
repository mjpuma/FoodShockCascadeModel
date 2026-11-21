# Function to simulate cascade of a shock in the global food network that 
# is associated with a change (decline) in production dP 
from __future__ import print_function, division
from netCDF4 import Dataset as NetCDFFile
from mpl_toolkits.basemap import Basemap, shiftgrid, cm
import matplotlib.pyplot as plt
import time
from numpy import *
import numpy as np
"""
Created on Sat Jun  4 13:16:33 2016

@author: michaeljpuma
"""

function [dR,dC,dE,flag_equalibrium] = ...
    sim_cascade(dP, P0, R0, E0, cfrac, asym,kmax, amin, anim_out)
# Function to simulate cascade of a shock in the global food network that 
# is associated with a change (decline) in production dP 

# INPUTS 
#  dP: change in production (should be negative, i.e. a production decline)
#  P0: initial production vector
#  E0: trade (export) matrix
#  R0: "available" reserves meaning the reserves that a country can or is willing to use
#  cfrac: fraction of shock absorbed by C before changing trade 
#  asym = 1: shocked countries can't increase their exports if R = 0
#  kmax: max number of iterations 
#  amin: any shock below amin (as fraction of net supply) is negligible
#  anim_out=1: return dR, dC and dE for each iteration

# OUTPUTS 
#  dR: change in reserves
#  dC: change in consumption
#  dE: change in export matrix(dE)
#  flag_equalibrium: flag indicating whether eqilibrium has been reached

nc =length(P0); % number of nodes

# Check input validity
if (~isvector(P0))
    'P0 must be a vector.' %#ok<NOPRT>
    return
end

if (~isvector(R0))
    'R0 must be a vector.' %#ok<NOPRT>
    return
end

if (~ismatrix(E0)) 
    'E0 must be a matrix.' %#ok<NOPRT>
    return
end

if (length(R0) ~= length(P0)) 
    'dimensions of P0 and R0 don''t match.' %#ok<NOPRT>
    return
end

if (length(E0) ~= length(P0)) 
    'dimensions of P0 and E0 don''t match.' %#ok<NOPRT>
    return
end

if (cfrac < 0 || cfrac > 1) 
    'cfrac must be between 0 and 1' %#ok<NOPRT>
    return
end

# Initialize flags and arrays
flag_equalibrium = 0;
R = zeros(nc,kmax+1);    # Reserve vector
E = zeros(nc,nc,kmax+1); # Trade matrix
S = zeros(nc,kmax+1);    # Supply vector
shocked = zeros(nc,1); # Node(s) shocked

dR = zeros(nc,kmax+1);   # Change in reserves
dC = zeros(nc,kmax+1);   # Change in consumption
dE = zeros(nc,nc,kmax+1);# Change in trade

R(:,1) = R0;
E(:,:,1) = E0;

# Net supply = production + imports(sum values in each column= colSums) 
# - exports (sum values in each row = rowSums)
S(:, 1) = P0 + sum(E0,1)' - sum(E0,2);

# Initial shock (dS = drop in supply)
dS = dP;

# Main loop
k = 0;
while k < kmax
    k = k+1;
    # Shock first absorbed by reserves, some consumption (cfrac of shock)
    # then trade (up to Tvol = E + I), then consumption.
    # Countries don't pass a shock smaller than amin * S, just absorb
    # if asym = 1, shocked countries with R = 0 can't export more,
    #  i.e. E(i,j) doesn't count in j's imports if shocked[i]
    
    # Step 1: use reserves to absorb shock  
    dR(:, k) = max(dS, -R(:,k)); 
    
    # Step 2: compute residual shock
    res_shock = dS - dR(:, k);
    
    # Step 3: prevent shocked countries with R = 0 from exporting more
    if (asym == 1)
        shocked(res_shock < 0) = 1;
    end
    
    # Step 4: absorb shock through reduction in consumption
    dC(:, k) = cfrac .* res_shock;
    res_shock = (1 - cfrac) .* res_shock;
    
    # Step 5: absorb shock through reduction in consumption
    # Tvol = Imports + Exports
    trade_matrix = squeeze(E(:,:, k));
    import_temp = trade_matrix;
    
    # This picks out the shocked country with R=0 and zeros out the row (i.e. 
    # export row); this means that other countries don't import from the 
    # shocked country or these imports are excluded from the Tvol calc.
    import_temp(find(shocked==1),:)=0;   
    import_temp = sum(import_temp,1)';    
    
    # Existing exports are unmodified 
    export_temp = trade_matrix;
    export_temp = sum(export_temp,2);
    
    # Tvol is total flow per node that can be modified (modifiable flow)
    Tvol = import_temp + export_temp; 
    clear import_temp export_temp trade_matrix
    
    # Step 5: Adjust propagated shock to ignore any small shocks 
    # (i.e., amin * S(:,k) are not propagated);
    # instead, they are accounted for as a consumption reduction
    dTvol = zeros(size(Tvol));
    index_shocks = find(abs(res_shock) > (amin * S(:,k))); 
    # Reduce trade by shock amount or total modifiable trade 
    # (whichever is smaller in magnitude)
    dTvol(index_shocks) = max(res_shock(index_shocks), -Tvol(index_shocks));
    # Adjust consumption
    dC(:, k) = dC(:, k) + res_shock - dTvol;
    
    # Step 6: Compute shock as fraction of modifiable flow (prop_dT) then
    #  allocate change in trade volume (+ imports, - exports) proportionally 
    #  to the initial volume of trade on each link (see dEalloc function)
    prop_dT = zeros(size(Tvol));
    prop_dT(find(Tvol ~= 0)) = dTvol(find(Tvol ~= 0)) ./ Tvol(find(Tvol ~= 0));    

    dE(:,:, k) = dEalloc(prop_dT, shocked) .* E(:,:, k);
    
    # Update values for next iteration
    # Decrease in net supply corresponds to shock absorbed internally (R, C)
    R(:, k+1) = R(:, k) + dR(:, k);
    E(:,:,k+1) = E(:,:,k) + dE(:,:,k);
    S(:, k+1) = S(:,k) + dR(:,k) + dC(:,k);
    
    # Decrease in I-E due to other countries corresponds to next dS
    dS = sum(squeeze(dE(:,:,k)),1)' - sum(squeeze(dE(:,:,k)),2) + dTvol;
    
    # If no more decrease in production, returns a list with all simulation
    #  parameters and the sum (over iterations) of dC, dE and dR
    if abs(min(dS)) <= eps(0)
        k = kmax;
        flag_equalibrium = 1;  
    end
        
end #end while loop

# Adjust output: If anim_out=1, return dR, dC and dE for each iteration
if (anim_out==1) 
    dR = dR(:,1:k);
    dC = dC(:,1:k);
    dE = dE(:,:,1:k);
else
    dR = sum(dR,2);
    dC = sum(dC,2);
    dE = sum(dE,3);
end

if flag_equalibrium == 0
    'No equilibrium reached after maximum number of iterations' %#ok<NOPRT>    
end