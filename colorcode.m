function color = colorcode(color,options)
   arguments
      color (1,1) string {mustBeMember(color,["blue","orange","yellow","purple","green","cyan","red","magenta","grey","pink","black","white","random","dictionary"])}
      options.brightness (1,1) double {mustBeInRange(options.brightness,0,2)} = 1;
   end

   colors = dictionary;

   colors("blue")    = {[0 0.4470 0.7410]};
   colors("orange")  = {[0.8500 0.3250 0.0980]};
   colors("yellow")  = {[0.9290 0.6940 0.1250]};
   colors("purple")  = {[0.4940 0.1840 0.5560]};
   colors("green")   = {[0.4660 0.6740 0.1880]};
   colors("cyan")    = {[0.3010 0.7450 0.9330]};
   colors("red")     = {[0.6350 0.0780 0.1840]};
   colors("magenta") = {[0.5 0 0.5]};
   colors("grey")    = {[1 1 1]*0.5};
   colors("pink")    = {[0.9686 0.498 0.7451]};
   colors("black")   = {[0 0 0]};
   colors("white")   = {[1 1 1]};

   if color == "dictionary"
      color = colors;
   else
      if color == "random"
         color = 0.1.*(rand(1,3)-0.5).*colors.values{randi([1 colors.numEntries])};
         color = max(0,color);
         color = min(1,color);
      else
         color = colors{color};
      end
      color = interp1(0:2,[0 0 0; color; 1 1 1],options.brightness);
   end

end