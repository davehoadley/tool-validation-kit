classdef LinearAlgebraTest < matlab.unittest.TestCase
% LINEARALGEBRATEST is an example validation test case for some features
% of the MATLAB language.  Specifically, linear algebra matrix operations 
% and solving systems of linear equations are demonstrated.
% It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2017 - 2018 The MathWorks, Inc.

    methods(Test)
        function matrixOperationsTest(testCase)
            % cross, dot, tril, triu
   
            % vector cross (outer) product
            A = [4 -2 1];
            B = [1 -1 3];

            C = cross(A,B);
            C_exp = [-5, -11, -2];
            
            testCase.verifyEqual(C, C_exp, ...
                'cross function test failed');
            
            % matrix cross (outer) product
            A = [ ...
                13    14     5    15    15; ...
                14    10     9     3     8; ...
                 2     2    15    15    13];

            B = [...
                 4    20     1    17    10; ...
                11    24    22    19    17; ...
                23    17    24    19     5];       
            
            C = cross(A, B);
            
            C_exp = [ ...
               300   122  -114  -228  -181; ...
              -291  -198  -105   -30    55; ...
                87   136   101   234   175];
    
            testCase.verifyEqual(C, C_exp, ...
                'cross function test failed');

            % vector dot (inner) product
            A = [4 -1 2];
            B = [2 -2 -1];
            C = dot(A,B);
            C_exp = 8;
            
            testCase.verifyEqual(C, C_exp, ...
                'cross function test failed');

            % vector dot (inner) product - complex values
            A = [1+1i 1-1i -1+1i -1-1i];
            B = [3-4i 6-2i 1+2i 4+3i];
            C = dot(A,B);
            C_exp = 1 - 5i;
            D = dot(A,A);
            D_exp = 8;
            
            testCase.verifyEqual(C, C_exp, ...
                'dot function test failed');

            testCase.verifyEqual(D, D_exp, ...
                'dot function test failed');

            % matrix dot (inner) product
            A = [1 2 3;4 5 6;7 8 9];
            B = [9 8 7;6 5 4;3 2 1];
            C = dot(A,B);
            C_exp = [54 57 54];
            
            testCase.verifyEqual(C, C_exp, ...
                'dot function test failed');
            
            % triangular matrix subsets
            A = triu(ones(4,4));

            A_exp = [ ...
                1    1    1    1; ...
                0    1    1    1; ...
                0    0    1    1; ...
                0    0    0    1];
            
            testCase.verifyEqual(A, A_exp, ...
                'triu function test failed');
            
            A = tril(ones(4,4));

            A_exp = [ ...
                1    0    0    0; ...
                1    1    0    0; ...
                1    1    1    0; ...
                1    1    1    1];
            
            testCase.verifyEqual(A, A_exp, ...
                'triu function test failed');
        end
        
        function linearEquationsTest(testCase)
            % rank, inv, det, mldivide, mrdivide

            A = [...
                 1     1     1; ...
                 1     2     3; ...
                 1     3     6];
             
             u = [3; 1; 4];
             x = A\u;
             x_exp = [10; -12; 5];
            
            testCase.verifyEqual(x, x_exp, ...
                'mldivide test failed');

            A = [1 1 3; 2 0 4; -1 6 -1];
            B = [2 19 8];
            x = B/A;
            x_exp = [1, 2 ,3];

            testCase.verifyEqual(x, x_exp, "AbsTol", 0.0001, ...
                'mrdivide test failed');

            A = [3 2 4; -1 1 2; 9 5 10];
            r = rank(A);
            r_exp = 2;

            testCase.verifyEqual(r, r_exp, ...
                'rank test failed');

            A = [1 -2 4; -5 2 0; 1 0 3];
            d = det(A);
            d_exp = -32;

            testCase.verifyEqual(d, d_exp, ...
                'det test failed');

            X = [1 0 2; -1 5 0; 0 3 -9];
            Y = inv(X);
            Y_exp = [
                0.8824   -0.1176    0.1961
                0.1765    0.1765    0.0392
                0.0588    0.0588   -0.0980
                ];
           
            testCase.verifyEqual(Y, Y_exp, 'AbsTol', 0.001, ...
                'inv test failed');
        end %function
        
        function setOperations(testCase)
            % intersect, ismember, setdiff, setxor, union, unique
            % join, innerjoin, outerjoin
            a = [1, 2, 3];
            b = [4, 3, 2];
            ab = intersect(a, b);
            c = [-1 0];
            ac = intersect(a, c);
            
            testCase.verifyEqual(ab, [2 3], ...
                'intersect test failed');

            testCase.verifyEqual(isempty(ac), true, ...
                'intersect test failed');
            
            % ismember returns an array of logical to determine if an
            % element is part of a set
            testCase.verifyEqual(ismember(a, 3), [false false true], ...
                'ismember test failed');
            
            % setdiff is the unique elements of arg1 vs arg2
            testCase.verifyEqual(setdiff(a, b), 1, ...
                'setdiff test failed');

            % setdiff is the unique elements of arg1 vs arg2
            testCase.verifyEqual(setdiff(b, a), 4, ...
                'setdiff test failed');

            % setxor is the unique elements of arg1 and arg2
            testCase.verifyEqual(setxor(a, b), [1 4], ...
                'setxor test failed');

            testCase.verifyEqual(union(a, b), [1 2 3 4], ...
                'union test failed');
            
            d = [1 1 1 1 2 1 1 2 2 1];
            % unique removes duplicated elements
            testCase.verifyEqual(unique(d), [1 2], ...
                'unique test failed');
            
            % join functions are for table data
            a = table({'John' 'Jane' 'Jim' 'Jerry' 'Jill'}',[1 2 1 2 1]', ...
                  'VariableNames',{'Employee' 'Department'});
            b = table([1 2]',{'Mary' 'Mike'}','VariableNames',{'Department' 'Manager'});
            ab = join(a, b);

            c = table({'John' 'Jane' 'Jim' 'Jerry' 'Jill'}',[1 2 1 2 1]', ...
                  {'Mary' 'Mike' 'Mary' 'Mike' 'Mary'}', 'VariableNames', ...
                  {'Employee' 'Department' 'Manager'});
            
            testCase.verifyEqual(ab, c, ...
                'join test failed');

            d = table([2 3]',{'Mary' 'Mike'}','VariableNames',{'Department' 'Manager'});
            
            % innerjoin only keeps rows where the key is the same in both
            % tables (Department in this case)
            ad_in = innerjoin(a, d);

            e = table({'Jane' 'Jerry'}',[2 2]', ...
                  {'Mary' 'Mary'}', 'VariableNames', ...
                  {'Employee' 'Department' 'Manager'});
              
            testCase.verifyEqual(ad_in, e, ...
                'innerjoin test failed');
            
            % outerjoin duplicates the key row and adds rows where a value
            % only occurs in one table or the other.  But it joins the rows
            % where the keys agree.  Unknown values become '' or NaN
            % depending on whether they are string or numeric types.
            
            ad_out = outerjoin(a, d);

            dept_a = ad_out(:,:).Department_a;
            dept_d = ad_out(:,:).Department_d;
            empl = ad_out(:,:).Employee;
            mgr = ad_out(:,:).Manager;
            
            testCase.verifyEqual(isequaln(dept_a, [1 1 1 2 2 NaN]'), true, ...
                'outerjoin test failed');

            testCase.verifyEqual(isequaln(dept_d, [NaN NaN NaN 2 2 3]'), ... 
                true, 'outerjoin test failed');

            testCase.verifyEqual(empl, {'John' 'Jim' 'Jill' 'Jane' 'Jerry' ''}', ... 
                'outerjoin test failed');
            
            testCase.verifyEqual(mgr, {'' '' '' 'Mary' 'Mary' 'Mike'}', ... 
                'outerjoin test failed');
        end
        function bitwiseOperators(testCase)
            % bitand/&, bitcmp, bitget, bitor/|, bitset, bitshift, bitxor,
            % swapbytes
            a = 4;
            b = 2;
            c = 15;
            
            testCase.verifyEqual(bitand(a,b), 0, ...
                'bitwise operator test failed');

            testCase.verifyEqual(bitor(a,b), 6, ...
                'bitwise operator test failed');

            testCase.verifyEqual(bitand(a,c), 4, ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(bitor(a,c), 15, ...
                'bitwise operator test failed');

            % bitcomp is complement (1110 -> 0001)
            testCase.verifyEqual(bitcmp(int8(4)), int8(-5), ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(bitcmp(uint8(4)), uint8(251), ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(bitget(int8(4),1), int8(0), ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(bitget(int8(4),3), int8(1), ...
                'bitwise operator test failed');
            
            d = bitset(uint8(4),4);
            
            testCase.verifyEqual(d, uint8(12), ...
                'bitwise operator test failed');

            e = bitshift(uint8(4), -2);
            f = bitshift(uint8(4), 3);
            
            testCase.verifyEqual(e, uint8(1), ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(f, uint8(32), ...
                'bitwise operator test failed');
            
            g = bitxor(uint8(4), uint8(2));
            h = bitxor(uint8(4), uint8(15));
            
            testCase.verifyEqual(g, uint8(6), ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(h, uint8(11), ...
                'bitwise operator test failed');
            
            testCase.verifyEqual(swapbytes(uint16(2816)), uint16(11), ...
                'bitwise operator test failed');

        end
        function operatorPrecedence(testCase)
            %{ 
            MATLAB documents the operator precedence rules as:
                Parentheses ()
                Transpose (.'), power (.^), complex conjugate transpose ('), matrix power (^)
                Unary plus (+), unary minus (-), logical negation (~)
                Multiplication (.*), right division (./), left division (.\), matrix multiplication (*), matrix right division (/), matrix left division (\)
                Addition (+), subtraction (-)
                Colon operator (:)
                Less than (<), less than or equal to (<=), greater than (>), greater than or equal to (>=), equal to (==), not equal to (~=)
                Element-wise AND (&)
                Element-wise OR (|)
                Short-circuit AND (&&)
                Short-circuit OR (||) 
            %}
            
            % make sure paren, power, unary -, *, and + happen in that
            % order
            a = -(3 + 4).^2 + 6 * 2;
            
            testCase.verifyEqual(-37, a, ...
                'operator precedence test failed');
            
            % logical operator precedence: ~ before rel.
            b = true == ~false;
            
            testCase.verifyEqual(b, true, ...
                'operator precedence test failed');
            
            % ~ before &.
            c = true & ~true;
            
            testCase.verifyEqual(c, false, ...
                'operator precedence test failed');

            % rel ops have low precedence vs. arithmetic
            d = 0 < 1 - 5;
            
            testCase.verifyEqual(d, false, ...
                'operator precedence test failed');
        
        end
    end
end