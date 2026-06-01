

open_background_color   = [1 1 0.8750];
closed_background_color = [0.97, 0.84, 0.8];




Tiles = struct;
Tiles.open.fig   = figure('Name',"Open-Loop Solutions","Color",open_background_color);
Tiles.closed.fig = figure('Name',"Closed-Loop Simulations","Color",closed_background_color);

for loop = ["open", "closed"]

   % Graphs:
   show.(loop) = dictionary;

   show.(loop)("classic")      = struct;
   show.(loop)("osm")          = struct;
   show.(loop)("linear_term")  = struct;
   show.(loop)("aggressive")   = struct;
   show.(loop)("aggressive_2") = struct;
   

   show.(loop)("classic").color       = colorcode("green");
   show.(loop)("osm").color           = colorcode("yellow");
   show.(loop)("aggressive").color    = colorcode("cyan");
   show.(loop)("aggressive_2").color  = colorcode("red");
   show.(loop)("linear_term").color   = colorcode("blue");

   show.(loop)("classic").style      = '-';
   show.(loop)("osm").style          = '-';
   show.(loop)("aggressive").style   = '-';
   show.(loop)("aggressive_2").style = '--';
   show.(loop)("linear_term").style  = '-';

   show.(loop)("classic").linewidth      = 1;
   show.(loop)("osm").linewidth          = 2;
   show.(loop)("aggressive").linewidth   = 0.7;
   show.(loop)("aggressive_2").linewidth = 0.7;
   show.(loop)("linear_term").linewidth  = 0.7;

   show.(loop)("classic").display_name = "classic";
   show.(loop)("osm").display_name = "OSM";
   show.(loop)("aggressive").display_name= "aggr.(A)";
   show.(loop)("aggressive_2").display_name = "aggr.(B)";
   show.(loop)("linear_term").display_name  = "linear-term";


   %%% Tiles:
   Tiles.(loop).AX = configureDictionary('string','matlab.graphics.axis.Axes');
   Tiles.(loop).time_scale = "min";
   Tiles.(loop).ref = ref;
   Tiles.(loop).model = model;
   Tiles.(loop).layout = tiledlayout(Tiles.(loop).fig,'flow','TileSpacing','tight','Padding','tight');

end



title(Tiles.open.layout  ,  "Open-Loop Solutions")
title(Tiles.closed.layout,"Closed-Loop Simulations")