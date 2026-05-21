      function [W] = make_posdef(W)
         % Ensure symmetric
         W = 0.5*(W + W');

         n = size(W,1);

         % Try Cholesky
         [~, p] = chol(W);
         if p ~= 0
            lambda = 1e-8 * max(1, norm(W,'inf'));
            I = speye(n);
            maxIter = 20;
            for k = 1:maxIter
               W_trial = W + lambda*I;
               W_trial = 0.5*(W_trial + W_trial'); % keep symmetry
               [~, p] = chol(W_trial);
               if p == 0
                  break;
               end
               lambda = lambda * 10;
            end
            if p ~= 0
               warning('make_posdef:CouldNotMakePD', ...
                  'Failed to obtain a positive definite Hessian with diagonal regularization.');
            end
            W = W_trial;
         end
      end