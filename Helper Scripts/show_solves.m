
fig = figure;
Tiles = tiledlayout(fig,'flow');

ax_iter = nexttile(Tiles);
hold(ax_iter,"on")
grid(ax_iter,"on")
title(ax_iter,'Numer of Iterations')
xlabel(ax_iter,'Solution Number')
ylabel(ax_iter,'N. Iterations')


ax_time = nexttile(Tiles);
hold(ax_time,"on")
grid(ax_time,"on")
title(ax_time,'Solve Times')
xlabel(ax_time,'Solution Number')
ylabel(ax_time,'Solve Time [ms]')

shape = dictionary("classic","o","osm","square","linear_term","diamond","aggressive","^");

for key = show.closed.keys'
   s = show.closed(key);

   ind_errors = s.traj.success == 0;
   ind_success = find(s.traj.success == 1);

   varargin = {  'Color'           ,s.color      ,...
                 'LineWidth'       ,2            ,...
                 'LineStyle'       ,':'          ,...
                 'Marker'          ,shape(key)   ,...
                 'MarkerFaceColor' ,'auto'       ,...
                 'MarkerIndices'   ,ind_success(:) };

   plot(ax_iter,s.traj.iterations,       varargin{:})
   plot(ax_time,s.traj.solve_times*1000, varargin{:}, 'DisplayName',key)


   % Error markers
   i_err = find(ind_errors);

   plot(ax_iter, i_err, s.traj.iterations(ind_errors), ...
        'LineStyle', 'none', ...
        'Marker', 'x', ...
        'Color', 'r', ...
        'LineWidth', 2, ...
        'MarkerSize', 8, ...
        'HandleVisibility', 'off')

   plot(ax_time, i_err, s.traj.solve_times(ind_errors), ...
        'LineStyle', 'none', ...
        'Marker', 'x', ...
        'Color', 'r', ...
        'LineWidth', 2, ...
        'MarkerSize', 8, ...
        'HandleVisibility', 'off')


end

legend(ax_time)
