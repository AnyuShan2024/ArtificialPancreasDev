% store output bg data
%BG = out.BG_data; 
t = 1:5:5*length(BG);

% Figure setting

figure_width = 9;     % [cm]

figure_height = 9;    % [cm]

figure_font_size = 11; % [pt]

%draw figure

figure

set(gca,'FontSize',9,'FontName','times')

hold on

plot(out.simout.time, out.simout.data*18,'k-','LineWidth',2)
plot(t, 70 * ones(size(t)),'r-','LineWidth',2)
plot(t, 180 * ones(size(t)),'b-','LineWidth',2)

xlabel('time(s)')
ylabel('BG(mg/dl)')
legend('BGMPC','BGPID','hypo','hyper')

xlim([0 length(BG)*5]);
ylim([0 500]);

grid on; box on
