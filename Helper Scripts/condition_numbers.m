
%%% If the condition numbers where stored during simulation, you can
%%% display them here:

figure
ax = axes;hold(ax,"on");grid(ax,"on")
title(ax,"Condition number of Hessian, W, throughout all iterations")
for method = string(fieldnames(condition))'
   condition_number = horzcat(condition.(method){:});
   plot(ax,condition_number,Color=show.closed(method).color,LineStyle=show.closed(method).style,DisplayName=method,Marker="square",MarkerFaceColor="auto",MarkerSize=7)
end
legend