function id = generateID(len)
   arguments
      len (1,1) double {mustBePositive,mustBeInteger} = 8;
   end
%GENERATEID Generate an ID of form: id<digit><8 alnum chars>

   % Character pool (upper, lower, digits)
   chars = ['A':'Z', 'a':'z', '0':'9'];

   % One digit
   id_dig = string(randi([0 9]));

   % Eight alphanumeric characters
   id_alphnum = chars(randi(numel(chars), 1, len-1));

   % Construct
   id = "id" + id_dig + string(id_alphnum);
end
