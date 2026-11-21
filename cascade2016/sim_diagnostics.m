function [ message1, message2 ] = sim_diagnostics( P0, E0, dP, dR, dC, dE, tol, CountryNames)
% sim_diagnostics: This function takes the output of sim_cascade
% and tests whether it respects equation:
% S = P + I - E = R + C
S0 = P0 + sum(E0,1)' - sum(E0,2);
dS0 = sum(dP);

% Test 1: Total dR + dC must match initial shock
% (within relative difference of tol)
discrep = (sum(dR) + sum(dC))/dS0 - 1;
if (abs(discrep) > tol)
    'Total dC + dR does not match initial shock.' %#ok<NOPRT>
    ['Relative difference:', discrep] %#ok<NOPRT>
    message1 = 1;
else
    message1 = 0; 
end

% Test 2: After initial shock, dI - dE = dR + dC by country
% (within relative difference of tol * final net supply)
dS_byc = dP + sum(dE,1)' - sum(dE,2);
S_final = dS_byc + S0;
Index_SupplyZero = find(S_final == 0);

% Relative difference of tol * final net supply
reldS_byc = abs((dS_byc - dR - dC)./S_final);
reldS_byc(Index_SupplyZero)=0;

% Apply the test
discrep = find(reldS_byc > tol);

if(~isempty(discrep))
    ['Net supply change does not match dC + dR for countries:',...
        CountryNames{discrep}] %#ok<NOPRT>
    message2 = 2;
else
    message2 = 0;
end


end

