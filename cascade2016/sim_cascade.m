function [dR,dC,dE,flag_equilibrium] = ...
    sim_cascade(dP, P0, R0, E0, cfrac, asym,kmax, amin, anim_out)
% Function to simulate cascade of a shock in the global food network that 
% is associated with a change (decline) in production dP 

% INPUTS 
%  dP: change in production (should be negative, i.e. a production decline)
%  P0: initial production vector
%  E0: trade (export) matrix
%  R0: "available" reserves meaning the reserves that a country can or is willing to use
%  cfrac: fraction of shock absorbed by C before changing trade 
%  asym = 1: shocked countries can't increase their exports if R = 0
%  kmax: max number of iterations 
%  amin: any shock below amin (as fraction of net supply) is negligible
%  anim_out=1: return dR, dC and dE for each iteration

% PARAMETER 
%  tol: threshold to determine if equilibrium has been reached

% OUTPUTS 
%  dR: change in reserves
%  dC: change in consumption
%  dE: change in export matrix(dE)
%  flag_equilibrium: flag indicating whether eqilibrium has been reached

tol = 1e-100;
nc =length(P0); % number of nodes

% Check input validity
if (max(dP(:)>0))
    'dP must be negative.' %#ok<NOPRT>
    return
end

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

% Initialize flags and arrays
flag_equilibrium = 0;
R = zeros(nc,kmax+1);    % Reserve vector
E = zeros(nc,nc,kmax+1); % Trade matrix
S = zeros(nc,kmax+1);    % Supply vector
shocked = zeros(nc,1); % Node(s) shocked

dR = zeros(nc,kmax+1);   % Change in reserves
dC = zeros(nc,kmax+1);   % Change in consumption
dE = zeros(nc,nc,kmax+1);% Change in trade

R(:,1) = R0;
E(:,:,1) = E0;

% Net supply = production + imports(sum values in each column= colSums) 
% - exports (sum values in each row = rowSums)
S(:, 1) = P0 + sum(E0,1)' - sum(E0,2);

% Initial shock (dS = change in supply, must be negative in this code)
dS = dP;

%% Main loop
k = 0;
while k < kmax
    k = k+1;
    % Shock first absorbed by reserves, some consumption (cfrac of shock)
    % then trade (up to Tvol = E + I), then consumption.
    % Countries don't pass a shock smaller than amin * S, just absorb
    % if asym = 1, shocked countries with R = 0 can't export more,
    %  i.e. E(i,j) doesn't count in j's imports if shocked[i]
    
    %% Step 1: Use "available" reserves to absorb shock 
    % Note: dS must be negative in current formulation 
    dR(:, k) = max(dS, -R(:,k)); 
    dSequalR = dS==-R(:,k) & dS<0;
    
    %% Step 2: Compute residual shock
    res_shock = dS - dR(:, k);
   
    %% Step 3: Export ban 
    %  Prevent shocked countries with no "available" reserves 
    %  from exporting (note: "shocked" is not reinitialized within loop, 
    %  meaning we keep track of each country that was shocked and the size 
    %  of the shock exceeded the amount of reserves available)
    if (asym == 1)
        shocked(res_shock < 0) = 1;
        shocked(dSequalR == 1) = 1; 
        if max(dSequalR == 1)
            'NOTE: dS equals R' %#ok<NOPRT>
        end
    end
    
    %% Step 4: Absorb shock through reduction in consumption
    dC(:, k) = cfrac .* res_shock;
    res_shock = (1 - cfrac) .* res_shock;
    
    %% Step 5: Compute modifiable flow (Tvol = Imports + Exports)
    % This means that Any country that has depleted its reserves 
    % (or had none to begin with) will block any increase in its outgoing  
    %  trade and is thus removed from the set U, which initially 
    % includes all countries.
    
    trade_matrix = squeeze(E(:,:, k));
    
    % This picks out the shocked country with R=0 and zeros out the row 
    % (i.e. export row); meaning that other countries don't import from  
    % the shocked country when reserves go to zero; these imports are 
    % excluded from the modifiable flow (Tvol) calculation
    import_temp = trade_matrix;        % temporarily set to full export matrix
    import_temp(find(shocked==1),:)=0; % zero out values in full export matrix  
    import_temp = sum(import_temp,1)'; % transform to import vector   
    
    % Existing exports are unmodified 
    export_temp = trade_matrix;        % temporarily set to full export matrix
    export_temp = sum(export_temp,2);  % transform to export vector 
    
    % Tvol is total flow per node that can be modified (modifiable flow)
    Tvol = import_temp + export_temp; 
    clear import_temp export_temp trade_matrix
    
    %% Step 6: Adjust propagated shock to ignore any small shocks 
    % (i.e., amin * S(:,k) are not propagated);
    % instead, they are accounted for as a consumption reduction
    dTvol = zeros(size(Tvol));
    index_shocks = find(abs(res_shock) > (amin * S(:,k))); 
    % Reduce trade by shock amount or total modifiable trade 
    % (whichever is smaller in magnitude)
    dTvol(index_shocks) = max(res_shock(index_shocks), -Tvol(index_shocks));
    % Adjust consumption
    dC(:, k) = dC(:, k) + res_shock - dTvol;
    
    %% Step 7: Compute shock as fraction of modifiable flow (prop_dT) then
    %  allocate change in trade volume (+ imports, - exports) proportionally 
    %  to the initial volume of trade on each link (see dEalloc function)
    %  => linear modeling approach
    prop_dT = zeros(size(Tvol));
    prop_dT(find(Tvol ~= 0)) = dTvol(find(Tvol ~= 0)) ./ Tvol(find(Tvol ~= 0));     
    E_adjust   = dEalloc(prop_dT, shocked); % Call to function dEalloc
    if max(E_adjust(:))>1
      'Error in sim_cascade: E_adjust>1' %#ok<NOPRT>
    end
    dE(:,:, k) = E_adjust .* E(:,:, k);
    
    %% Step 8: Update values for next iteration
    % Decrease in net supply corresponds to shock absorbed internally (R, C)
    R(:, k+1) = R(:, k) + dR(:, k);
    Echeck = squeeze(E(:,:,k)) + squeeze(dE(:,:,k));
    if ~isempty(find(Echeck<0))
       'Error in sim_cascade: exports become negative' %#ok<NOPRT>
       dE_temp = squeeze(dE(:,:,k));
       Eoriginal =E0(find(Echeck<0));
       dE_toolarge = dE_temp(find(Echeck<0));
       diff = Eoriginal(1) + dE_toolarge(1);
    end
    E(:,:,k+1) = E(:,:,k) + dE(:,:,k);
    S(:, k+1) = S(:,k) + dR(:,k) + dC(:,k);
    
    % Decrease in I-E due to other countries corresponds to next dS
    dS = sum(squeeze(dE(:,:,k)),1)' - sum(squeeze(dE(:,:,k)),2) + dTvol;
    
    % If no more decrease in production, returns a list with all simulation
    %  parameters and the sum (over iterations) of dC, dE and dR
    if abs(min(dS)) <= tol %eps(0)
        k = kmax;
        flag_equilibrium = 1;  
    end
        
end %end while loop

%% Adjust output: If anim_out=1, return dR, dC and dE for each iteration
if (anim_out==1) 
    dR = dR(:,1:k);
    dC = dC(:,1:k);
    dE = dE(:,:,1:k);
else
    dR = sum(dR,2);
    dC = sum(dC,2);
    dE = sum(dE,3);
end

if flag_equilibrium == 0
    'No equilibrium reached after maximum number of iterations' %#ok<NOPRT>    
end

end % end function