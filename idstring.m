function str = idstring(input)
%IDSTRING Prepend a generated ID to a string.
%
%   str = idstring("myName") 
%   → "id4Ab09dQk_myName"
   arguments
      input (1,1) string
   end
   id = generateID(randi([1 10]));
   str = char(id + "_" + input);
end
