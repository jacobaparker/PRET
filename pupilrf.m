function output = pupilrf(t,n,tmax,t0)
% pupilrf
% output = pupilrf(t,n,tmax,t0)
% 
% Calculates the pupil response function at time points "t" with given
% parameters n, tmax, and t0.
% 
% INPUTS
% t = time vector (in ms)
% n+1 = number of layers (canonical value of n = 10.1)
% tmax = response maximum (canonical value of tmax = 930)
% function is normalized to a max of 0.01 (tmax affects amplitude of pupil
% response function)
% t0 = the time of the event
% 
% OUTPUT
% output = time series of pupil response function resulting from the input
% parameters, at the time points specified in t
% 
% For more information about the pupil response function, see "Pupillary
% dilation as a measure of attention: A quantitative system analysis", 
% Hoeks&Levelt 1993
% 
% 
%     Copyright (C) 2019  Jacob Parker and Rachel Denison
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.
% 

output = ((t-t0).^n).*exp(-n.*(t-t0)./tmax);
output((t-t0)<=0) = 0;
output = (output/(max(output)));
