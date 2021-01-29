% function main(path_to_folder)
%main.m - Bubble sizer image processing code, soon to be the GUI
%This script calls all other functions/subrutines.
%At some point we need to change this into a GUI asociated M-file
%
% Syntax:  main(path_to_folder)
%
% Inputs:
%    path_to_folder - path to the folder with the images to be analysed
%    
% Outputs:
%    none
%
% Example: 
%    main('./Sample_photos/')
%
% Author: Reyes, Francisco; Quintanilla, Paulina; Mesa, Diego
% email: f.reyes@uq.edu.au,  
% Website: https://gitlab.com/frreyes1/bubble-sizer
% Copyright Oct-2020;
%
%This file is part of Foobar.
%
%    Foobar is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation version 3 only of the License.
%
%    Foobar is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
%
%------------- BEGIN CODE --------------
function [x, q, Q] = bubbles_psd(data, xbins,Xlim,Xlabel)

fig1 = figure('Color',[1 1 1]);
ax1 = axes('Parent',fig1);
hold(ax1,'on');

% Activate the left side of the axes
yyaxis(ax1,'left');
hist(ax1,data,xbins);
[q,x] = hist(data,xbins);
ylabel('q [#]');
set(ax1,'YColor',[0 0 0]);
% Activate the right side of the axes
yyaxis(ax1,'right');
dx = (x(2)-x(1))/2;
Q = cumsum(q)/sum(q);
plot(x+dx,Q,'MarkerSize',7,'Marker','square','LineWidth',1.5,...
    'Color',[1 0 0]);
ylabel('Q [%]');
set(ax1,'YColor',[0 0 0]);

% Set the remaining axes properties
set(ax1,'XGrid','on','XMinorTick','on','YGrid','on');
xlim(ax1,Xlim);
xlabel(ax1,Xlabel);
