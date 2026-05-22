function color = colorcode(color,options)
   arguments
      color (1,1) string {mustBeMember(color,...
["blue","orange","yellow","purple","green","cyan","red","magenta","grey","gray","pink","black","white", ...
"navy","darkblue","royalblue","cornflower","steelblue","skyblue","lightblue", ...
"teal","turquoise","aqua","aquamarine","mint", ...
"lime","darkgreen","forestgreen","seagreen","springgreen","olive","chartreuse", ...
"gold","amber","mustard","khaki","cream","beige","ivory", ...
"coral","salmon","tomato","peach","apricot","rust","burntorange", ...
"maroon","burgundy","crimson","scarlet","rose", ...
"hotpink","deeppink","lightpink", ...
"violet","indigo","lavender","plum","orchid","lilac", ...
"brown","sienna","chocolate","tan","copper","bronze", ...
"silver","lightgray","darkgray","dimgray","slategray","charcoal", ...
"offwhite","snow","linen",...
"random","random_name","dictionary"])}
      
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

% Helper for 0-255 RGB values
rgb = @(x) x ./ 255;

colors("gray")          = colors("grey");   % alias

colors("navy")          = {rgb([0 0 128])};
colors("darkblue")      = {rgb([0 0 139])};
colors("royalblue")     = {rgb([65 105 225])};
colors("cornflower")    = {rgb([100 149 237])};
colors("steelblue")     = {rgb([70 130 180])};
colors("skyblue")       = {rgb([135 206 235])};
colors("lightblue")     = {rgb([173 216 230])};

colors("teal")          = {rgb([0 128 128])};
colors("turquoise")     = {rgb([64 224 208])};
colors("aqua")          = {rgb([0 255 255])};
colors("aquamarine")    = {rgb([127 255 212])};
colors("mint")          = {rgb([152 255 152])};

colors("lime")          = {rgb([0 255 0])};
colors("darkgreen")     = {rgb([0 100 0])};
colors("forestgreen")   = {rgb([34 139 34])};
colors("seagreen")      = {rgb([46 139 87])};
colors("springgreen")   = {rgb([0 255 127])};
colors("olive")         = {rgb([128 128 0])};
colors("chartreuse")    = {rgb([127 255 0])};

colors("gold")          = {rgb([255 215 0])};
colors("amber")         = {rgb([255 191 0])};
colors("mustard")       = {rgb([255 219 88])};
colors("khaki")         = {rgb([240 230 140])};
colors("cream")         = {rgb([255 253 208])};
colors("beige")         = {rgb([245 245 220])};
colors("ivory")         = {rgb([255 255 240])};

colors("coral")         = {rgb([255 127 80])};
colors("salmon")        = {rgb([250 128 114])};
colors("tomato")        = {rgb([255 99 71])};
colors("peach")         = {rgb([255 218 185])};
colors("apricot")       = {rgb([251 206 177])};
colors("rust")          = {rgb([183 65 14])};
colors("burntorange")   = {rgb([204 85 0])};

colors("maroon")        = {rgb([128 0 0])};
colors("burgundy")      = {rgb([128 0 32])};
colors("crimson")       = {rgb([220 20 60])};
colors("scarlet")       = {rgb([255 36 0])};
colors("rose")          = {rgb([255 0 127])};

colors("hotpink")       = {rgb([255 105 180])};
colors("deeppink")      = {rgb([255 20 147])};
colors("lightpink")     = {rgb([255 182 193])};

colors("violet")        = {rgb([238 130 238])};
colors("indigo")        = {rgb([75 0 130])};
colors("lavender")      = {rgb([230 230 250])};
colors("plum")          = {rgb([221 160 221])};
colors("orchid")        = {rgb([218 112 214])};
colors("lilac")         = {rgb([200 162 200])};

colors("brown")         = {rgb([165 42 42])};
colors("sienna")        = {rgb([160 82 45])};
colors("chocolate")     = {rgb([210 105 30])};
colors("tan")           = {rgb([210 180 140])};
colors("copper")        = {rgb([184 115 51])};
colors("bronze")        = {rgb([205 127 50])};

colors("silver")        = {rgb([192 192 192])};
colors("lightgray")     = {rgb([211 211 211])};
colors("darkgray")      = {rgb([169 169 169])};
colors("dimgray")       = {rgb([105 105 105])};
colors("slategray")     = {rgb([112 128 144])};
colors("charcoal")      = {rgb([54 69 79])};

colors("offwhite")      = {rgb([250 249 246])};
colors("snow")          = {rgb([255 250 250])};
colors("linen")         = {rgb([250 240 230])};

   if color == "dictionary"
      color = colors;
   elseif color == "random_name"
      names = colors.keys;
      color = names(randi([1 colors.numEntries]));
   else
      if color == "random"
         color = rand(1,3);
      else
         color = colors{color};
      end
      color = interp1(0:2,[0 0 0; color; 1 1 1],options.brightness);
   end
end