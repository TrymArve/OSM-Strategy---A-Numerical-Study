classdef StructorSX < handle

   properties(Dependent)
      cas
      num
      vec
      len
   end

   properties(SetAccess=private,Hidden)
      internal_cas (:,1) casadi.SX = casadi.SX([]);
      internal_num (:,1) double
      ind (1,1) struct = struct;
   end

   methods

      function add(C, name,SX_expr)
         arguments
            C
         end
         arguments(Repeating)
            name (1,1) string
            SX_expr casadi.SX
         end

         ind_names = string(fieldnames(C.ind))';
         for i = 1:length(name)
            if ~ismember(name{i},ind_names)
               C.ind.(name{i}) = {};
            end
         end

         for i = 1:length(name)
            expr = SX_expr{i};

            L = numel(C.internal_cas);
            N = numel(expr);

            C.ind.(name{i}){end+1} = L + reshape(1:N, size(expr));
            C.internal_cas      = [C.internal_cas; reshape(expr, N, 1)];
            C.internal_num      = [C.internal_num; zeros(N,1)];
         end
      end

      % ---------- num setter ----------

      function set.num(C,in)
         arguments
            C
            in
         end

         switch class(in)
            case "double"
               if numel(in) ~= C.len
                  error("USER ERROR: trying to set the numeric vector with incorrect size. You have: "+numel(in)+", but expected: "+C.len)
               end
               C.internal_num = in(:);

            case "struct"
               for type = string(fieldnames(C.ind))'
                  if ~isfield(in,type)
                     continue;
                  end
                  for sz = 1:2
                     if size(in.(type),sz) ~= C.size.(type)(sz)
                        error("USER ERROR: trying to set the numeric value of the "+type+"-vector with incorrect size in dimension "+sz+". You have: "+size(in.(type),sz)+", but expected: "+C.size.(type)(sz))
                     end
                  end
                  C.internal_num([C.ind.(type){:}]) = in.(type);
               end
            otherwise
               error("USER ERROR: num must be either a double vector or a struct with fields corresponding to the custom defined fields names for this object instance.");
         end


      end


      function set.vec(C,in)
         for type = ["cas","num"]
            for sz = 1:2
               if (size(in.(type),sz) ~= size(C.("internal_"+type),sz) ) && (numel(in.(type))~=0 || numel(C.("internal_"+type))~=0)
                  error("USER ERROR: trying to set the value of the "+type+"-vector with incorrect size in dimension "+sz+". You have: "+size(in.(type),sz)+", but expected: "+size(C.("internal_"+type),sz))
               end
            end
            C.("internal_"+type) = in.(type);
         end
      end

      % ---------- cas / num / vec getters ----------

      function cas = get.cas(C)
         cas = struct;
         for type = string(fieldnames(C.ind))'
            cas.(type) = C.internal_cas([C.ind.(type){:}]);
         end
      end

      function num = get.num(C)
         num = struct;
         for type = string(fieldnames(C.ind))'
            num.(type) = C.internal_num([C.ind.(type){:}]);
         end
      end

      function vec = get.vec(C)
         vec.num = C.internal_num;
         vec.cas = C.internal_cas;
      end

      function L = get.len(C)
         L = numel(C.internal_cas);
      end

      % ---------- bookkeeping helpers ----------

      function L = numel(C)
         for type = string(fieldnames(C.ind))'
            L.(type) = numel([C.ind.(type){:}]);
         end
      end

      function S = size(C)
         for type = string(fieldnames(C.ind))'
            S.(type) = size([C.ind.(type){:}]);
         end
      end

   end

end
