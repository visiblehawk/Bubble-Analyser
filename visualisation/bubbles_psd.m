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
