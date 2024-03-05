classdef RelationalLogicalTest < matlab.unittest.TestCase
% FILEIOTEST is an example validation test case for some features
% of the MATLAB language.  Tests demonstrate relational, logical, set, and 
% bitwise operators.  It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2017 - 2018 The MathWorks, Inc.

    methods(Test)
        function relationalOperators(testCase)
            % eq/==, ge/>=, gt/>, le/<=, lt/<, ne/~=, isequal, isequaln
   
            a = -0.001;
            a_relop = (a == -0.001);
            
            testCase.verifyEqual(a_relop, true, ...
                'eq operator test failed');
            
            a_relop = eq(-0.001, a);
            
            testCase.verifyEqual(a_relop, true, ...
                'eq operator test failed');

            a_relop = (a == -0.0010001);
            
            testCase.verifyEqual(a_relop, false, ...
                'eq operator test failed');
            
            a_relop = eq(11, a);
            
            testCase.verifyEqual(a_relop, false, ...
                'eq operator test failed');

            % row vector == returns a logical row vector of element comparisons
            b = [0.2 - 3i, 34, pi/2];
            b_relop = (b == [0.2 - 3i, 34, pi/2]);

            testCase.verifyEqual(b_relop, [true, true, true], ...
                'eq operator test failed');
            
            b_relop = (b == pi/2);

            testCase.verifyEqual(b_relop, [false, false, true], ...
                'eq operator vector expansion test failed');

            c = 96;
            c_relop = (c >= -101);
            
            testCase.verifyEqual(c_relop, true, ...
                'ge operator test failed');
            
            c_relop = ge(117.5, c);
            
            testCase.verifyEqual(c_relop, true, ...
                'ge operator test failed');

            c_relop = (c >= 101);
            
            testCase.verifyEqual(c_relop, false, ...
                'ge operator test failed');
            
            c_relop = ge(c, 117.5);
            
            testCase.verifyEqual(c_relop, false, ...
                'ge operator test failed');

            % column vector >= returns a logical column vector of element 
            % comparisons
            d = [55; 0.9; -3i];
            d_relop = (d >= [55; 0.9; -3i]);

            testCase.verifyEqual(d_relop, [true; true; true], ...
                'ge operator test failed');
            
            d_relop = (d >= 2);

            testCase.verifyEqual(d_relop, [true; false; false], ...
                'ge operator vector expansion test failed');

            e = 10;
            e_relop = (e > 9.9);
            
            testCase.verifyEqual(e_relop, true, ...
                'gt operator test failed');
            
            e_relop = gt(e, 1/7);
            
            testCase.verifyEqual(e_relop, true, ...
                'gt operator test failed');

            e_relop = (e > 10);
            
            testCase.verifyEqual(e_relop, false, ...
                'gt operator test failed');
            
            e_relop = gt(e, 117.5);
            
            testCase.verifyEqual(e_relop, false, ...
                'gt operator test failed');

            % column vector >= returns a logical column vector of element 
            % comparisons
            f = [44; 38; 11];
            f_relop = (f > [19; 199; 0]);

            testCase.verifyEqual(f_relop, [true; false; true], ...
                'gt operator test failed');
            
            f_relop = (f > 37);

            testCase.verifyEqual(f_relop, [true; true; false], ...
                'gt operator vector expansion test failed');
            
            g = -1.2e4;
            g_relop = (g <= -1000);
            
            testCase.verifyEqual(g_relop, true, ...
                'le operator test failed');

            g_relop = le(g,-50000);
            
            testCase.verifyEqual(g_relop, false, ...
                'le operator test failed');

            % row vector <= returns a logical row vector of element 
            % comparisons
            h = [80, 79, 78];
            h_relop = (h <= [20, 40, 60]);

            testCase.verifyEqual(h_relop, [false, false, false], ...
                'le operator test failed');
            
            h_relop = (h <= 79);

            testCase.verifyEqual(h_relop, [false, true, true], ...
                'le operator vector expansion test failed');
            
            j = 324.1;
            j_relop = (j <= 324);
            
            testCase.verifyEqual(j_relop, false, ...
                'lt operator test failed');

            j_relop = le(j, 325);
            
            testCase.verifyEqual(j_relop, true, ...
                'lt operator test failed');

            % col vector < returns a logical col vector of element 
            % comparisons
            k = [1/5; 1/6; 1/7];
            k_relop = (k < [0; 1; 2]);

            testCase.verifyEqual(k_relop, [false; true; true], ...
                'lt operator test failed');
            
            k_relop = (k < .199);

            testCase.verifyEqual(k_relop, [false; true; true], ...
                'lt operator vector expansion test failed');

            l = 80.09;
            l_relop = (l ~= -0.001);
            
            testCase.verifyEqual(l_relop, true, ...
                'ne operator test failed');
            
            l_relop = ne(-0.001, l);
            
            testCase.verifyEqual(l_relop, true, ...
                'ne operator test failed');

            l_relop = (l ~= 80.09);
            
            testCase.verifyEqual(l_relop, false, ...
                'ne operator test failed');
            
            l_relop = ne(80.09, l);
            
            testCase.verifyEqual(l_relop, false, ...
                'ne operator test failed');

            % row vector == returns a logical row vector of element comparisons
            m = [12, 12, 12.1];
            m_relop = (m ~= [12.1, 12.1, 12]);

            testCase.verifyEqual(m_relop, [true, true, true], ...
                'ne operator test failed');
            
            m_relop = (m ~= 12.1);

            testCase.verifyEqual(m_relop, [true, true, false], ...
                'ne operator vector expansion test failed');

            n = 9;
            n_relop = isequal(n,9);
            
            testCase.verifyEqual(n_relop, true, ...
                'isequal test failed');

            n_relop = isequal(n, 9 + 5*eps);
            
            testCase.verifyEqual(n_relop, false, ...
                'isequal operator test failed');

            % isequal fails on NaNs
            n_relop = isequal(NaN, NaN);
            
            testCase.verifyEqual(n_relop, false, ...
                'isequal operator test failed');

            % isequal requires same dimensions for vector/matrix
            % comparisons to be true
            o = [0.5i; 13; -.09];
            o_relop = isequal(o, [0.5i; 13; -.09]);

            testCase.verifyEqual(o_relop, true, ...
                'isequal operator test failed');
            
            o_relop = isequal(o, [0.5i; 12; -.09]);

            testCase.verifyEqual(o_relop, false, ...
                'isequal operator test failed');

            o_relop = isequal(o, [0.5i, 13, -.09]);

            testCase.verifyEqual(o_relop, false, ...
                'isequal operator test failed');
            
            % isequaln is similar to isequal, except NaNs are considered
            % equal
            p_relop = isequaln(NaN, NaN);
            
            testCase.verifyEqual(p_relop, true, ...
                'isequaln operator test failed');

            p_relop = isequaln(NaN, 0);
            
            testCase.verifyEqual(p_relop, false, ...
                'isequaln operator test failed');
        end
        
        function logicalOperators(testCase)
            % and/&&, not/~, or/||, xor, all, any, find, islogical, logical
            testCase.verifyEqual(true && true, true, ...
                'and test failed'); %#ok<*LBODUP> 

            testCase.verifyEqual(and(true, false), false, ...
                'and test failed');
            
            testCase.verifyEqual(and([1 0], [1 1]), [true false], ...
                'and test failed');
            
            testCase.verifyEqual(~true, false, ...
                'not test failed');
            
            testCase.verifyEqual(~[1 1 0], [false false true], ...
                'not test failed');
            
            testCase.verifyEqual(true || true, true, ...
                'or test failed');

            testCase.verifyEqual(or(true, false), true, ...
                'or test failed');
            
            testCase.verifyEqual(or([1 0], [0 0]), [true false], ...
                'or test failed');
            
            testCase.verifyEqual(xor(true, true), false, ...
                'xor test failed');

            testCase.verifyEqual(xor(true, false), true, ...
                'xor test failed');
            
            testCase.verifyEqual(xor([0 0], [1 0]), [true false], ...
                'xor test failed');

            % all means all elements of a vector are true (like
            % and-ing all elements).  For matrixes, cols are all-ed
            testCase.verifyEqual(all([1 1]), true, ...
                'all test failed');
        
            testCase.verifyEqual(all([1 1; 0 1]), [false, true], ...
                'all test failed');
            
            % any means at least one element of a vector is true 
            % (like or-ing all elements).  For matrices, cols are any-ed
            testCase.verifyEqual(any([1 0]), true, ...
                'any test failed');
        
            testCase.verifyEqual(any([0 0; 0 1]), [false, true], ...
                'any test failed');

            % find returns the (linearing ) indexes of an array where the 
            % elements are true
             a = [1 1; 0 1];
             a_found = find(a);
             
            testCase.verifyEqual(a_found, [1; 3; 4], ...
                'find test failed');
            
            b_found = find([0 0]);
            testCase.verifyEqual(length(b_found), 0, ...
                'find test failed');
            
            testCase.verifyEqual(islogical(true), true, ...
                'islogical test failed');
            
            testCase.verifyEqual(islogical('test'), false, ...
                'islogical test failed');

            testCase.verifyEqual(logical(1), true, ...
                'logical test failed'); %#ok<LOGL>

            % & performs an element-wise AND of matrices
            A = [1 0; 0 1];
            B = [0 0; 0 1];
            C = [false false; false true];
            
            testCase.verifyEqual(A & B, C, ...
                'logical test failed');
            
            % | performs an element-wise OR of matrices
            D = [true false; false true];
            
            testCase.verifyEqual(A | B, D, ...
                'logical test failed');
        end
        
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