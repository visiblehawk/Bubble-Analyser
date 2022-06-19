%Script to wrap the opening of the APP, so we can check the current Matlab
%version
%
% Syntax: BubbleAnalyserApp()
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Author: Reyes, Francisco; Quintanilla, Paulina; Mesa, Diego
% email: f.reyes@uq.edu.au,
% Website: https://gitlab.com/frreyes1/bubble-sizer
% Copyright Feb-2021;
%
%This file is part of Bubble Analyser
%
%    Bubble Analyser is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation version 3 only of the License.
%
%    Bubble Analyser is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with Bubble Analyser. If not, see <https://www.gnu.org/licenses/>.
%
%------------- BEGIN CODE --------------

%test Matlab version
v = ver('matlab');
current_ver = datetime(v.Date);
test_ver = datetime(2020,01,01);
if current_ver < test_ver
    uiwait(msgbox({'This app has been tested on Matlab 2020 or newer'},...
                    'Matlab version mismatch','warn'));
    drawnow
end

%test if certain toolboxes are present
pat = '(?<=^.+[\\/]toolbox[\\/])[^\\/]+';
test_tlbx = regexp(which('impixel'), pat, 'match', 'once'); %test if impixel exist
if isempty(test_tlbx) 
    uiwait(msgbox({'Bubble Analyser needs Image Processing Toolbox to work. Please install using the Add-on Manager'},...
                    'Toolbox missing','warn'));
    drawnow
end

%run the app anyway, but the user has been warned
clearvars
Interface
