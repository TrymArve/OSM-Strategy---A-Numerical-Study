function str = full_struct(str)
   for field = string(fieldnames(str))'
      str.(field) = full(str.(field));
   end
end