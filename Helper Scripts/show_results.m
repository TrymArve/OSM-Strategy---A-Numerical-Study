
Tiles.(loop) = show_results_(show.(loop),Tiles.(loop));


function Tiles = show_results_(show,Tiles)
   arguments
      show dictionary
      Tiles struct
   end

   model = Tiles.model;
   ref   = Tiles.ref;
   
   time_scale = dictionary("s",1,"min",60,"h",60*60,"d",60*60*24);


   for key = show.keys'
      
      s = show(key);
      if isfield(s,'traj')
         for type = ["state", "input"]
            for name = model.names.(type)

               % Select or create relevant axes
               ax_name = type + "_" + name;
               if ismember(ax_name,Tiles.AX.keys)
                  ax = Tiles.AX(ax_name);
               else
                  ax = nexttile(Tiles.layout);
                  Tiles.AX(ax_name) = ax;

                  % Add info and style:
                  hold(ax,"on")
                  grid(ax,"on")
                  y_label = model.style.(type).(name).label + model.style.(type).(name).unit;
                  ylabel(ax,y_label,Interpreter="latex")
                  xlabel(ax,"time ["+Tiles.time_scale+"]",Interpreter="latex")
                  switch type
                     case "state"
                        ax.Color = min([0.95, 0.99, 1],1);
                     case "input"
                        ax.Color = min([1, 0.96, 0.99],1);
                  end
                  % Add reference
                  value =  ref.(type)(model.ind.(type).(name));
                  times  = (s.traj.times([1 end]))/time_scale(Tiles.time_scale);
                  plot(ax, times, value([1 1]), color=[0.5000    0.5000    0.5000],LineStyle='--',LineWidth=2)


               end

               % disp("type: "+type+", name: "+name)

               % Plot trajectory
               values =  s.traj.(type)(model.ind.(type).(name),:);
               times  = (s.traj.times(1:size(values,2)))/time_scale(Tiles.time_scale);
               myplot(type,ax, times, values, color=s.color,LineStyle=s.style,LineWidth=s.linewidth)


            end
         end
      end
   end

   function myplot(type,varargin)
      switch type
         case "state"
            plot(varargin{:})
         case "input"
            stairs(varargin{:})
         otherwise
            error('DEV ERROR: unrecognized type.')
      end
   end

end

