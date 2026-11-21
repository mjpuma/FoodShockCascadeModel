function [ dEprop ] = dEalloc( prop_dT, shocked )
%dEalloc: Function to calculate the relative change in each trade link
%  from the proportion of trade volume (by country) affected by shock (prop_dT)
%  and a vector (zeros and ones) indicating shocked countries 
%  (that aren't exporting any more)
nc =length(shocked);

% Results in dEprop(i,j) = prop_dT(i) - (!shocked[i]) * prop_dT(j) 
dEprop=prop_dT*ones(1,nc) - ~shocked*ones(1,nc).* rot90(prop_dT*ones(1,nc));
dEprop(logical(eye(size(dEprop)))) = 0; %set diagonal to zero

end

