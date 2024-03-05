classdef MatricesTest < matlab.unittest.TestCase
% MATRICESTEST is an example validation test case for some features
% of the MATLAB language.  Specifically, it demonstrates elementary
% operations to create and access elements of arrays, matrices, and tables.
% It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2017 - 2018 The MathWorks, Inc.

    methods(Test)
        function arrayCreationPoint(testCase)
            % blkdiag, diag, eye, false, linspace, logspace, ones, rand,
            % true, zeros, cat, horzcat, vertcat
            
            % basic array constant indexing
            a = [5, 4, 2];
            
            testCase.verifyEqual(a(1), 5, ...
                'Array create/index test failed');

            testCase.verifyEqual(a(2), 4, ...
                'Array create/index test failed');
            
            testCase.verifyEqual(a(3), 2, ...
                'Array create/index test failed');
            
            % basic matrix constant indexing
            m = [ -2 5; 6 8; 2.4 -3];
            
            testCase.verifyEqual(m(1,1), -2, ...
                'Matrix create/index test failed');

            testCase.verifyEqual(m(1,2), 5, ...
                'Matrix create/index test failed');
            
            testCase.verifyEqual(m(2,1), 6, ...
                'Matrix create/index test failed');
            
            testCase.verifyEqual(m(2,2), 8, ...
                'Matrix create/index test failed');

            testCase.verifyEqual(m(3,1), 2.4, ...
                'Matrix create/index test failed');
            
            testCase.verifyEqual(m(3,2), -3, ...
                'Matrix create/index test failed');

            % diag creates a matrix with vector argument as its diagonal
            % elements
            a = [5, 4, 2];
            b = diag(a);
            b_expected = [5 0 0; 0 4 0; 0 0 2];
            testCase.verifyEqual(b, b_expected, ...
                'diag test failed');
            
            % diag also returns the diagonal elements of a matrix
            a = diag(b_expected);
            a_expected = [5; 4; 2];
            testCase.verifyEqual(a, a_expected, ...
                'diag test failed');
            
            % eye makes a unit matrix
            c = eye(4);
            c_expected = [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1];
            testCase.verifyEqual(c, c_expected, ...
                'eye test failed');
            
            % false
            d = false(2, 1);
            d_expected = [false; false];
            testCase.verifyEqual(d, d_expected, ...
                'false test failed');
            
            % linspace makes arg3 even divisions from arg1 to arg2
            e = linspace(1,5,9);
            e_expected = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5];
            testCase.verifyEqual(e, e_expected, ...
                'linspace test failed');
            
            % logspace makes arg3 even log divsions from arg1 to arg2
            f = logspace(1,2,5);
            f_expected = [10 17.78279410038923, 31.622776601683793, ...
                56.234132519034908, 100];
            testCase.verifyEqual(f, f_expected, 'RelTol', eps, ...
                'logspace test failed');
            
            % ones makes a matrix of all ones
            g = ones(3);
            g_expected = [1 1 1; 1 1 1; 1 1 1];
            testCase.verifyEqual(g, g_expected, ...
                'ones test failed');

            % true with one arg makes a square matrix of trues
            h = true(2);
            h_expected = [true true; true true];
            testCase.verifyEqual(h, h_expected, ...
                'true test failed');
            
            % rand... hmmm...
            
            % zeros makes a matrix of all zeroes
            j = zeros(2, 3);
            j_expected = [0 0 0; 0 0 0];
            testCase.verifyEqual(j, j_expected, ...
                'zeros test failed');
            
            % cat, horzcat, vertcat
            % C = cat(dim, A, B)concatenates the arrays A and B along 
            % the dimension specified by dim
            k = cat(1, [10 20 30], [40 50 60], [70 80 90]);
            k_expected = [10 20 30; 40 50 60; 70 80 90];
            testCase.verifyEqual(k, k_expected, ...
                'cat test failed');
            
            % horzcat combines matrices horizontally (cats columns)
            l = horzcat([-1 -2; -3 -4; -5 -6], [0; 2; 4]);
            l_expected = [-1 -2 0; -3 -4 2; -5 -6 4];
            testCase.verifyEqual(l, l_expected, ...
                'cat test failed');

            % vertcat combines matrices vertically (cats rows)
            m = vertcat([11 23], [-1 -2; -3 -4; -5 -6]);
            m_expected = [11 23; -1 -2; -3 -4; -5 -6];
            testCase.verifyEqual(m, m_expected, ...
                'cat test failed');
        end
        
        function indexingPoint(testCase)
            % array indexing 
            a = [5, 4, 2];
            
            testCase.verifyEqual(a(1), 5, ...
                'Array index test failed');

            % 2 colon 3 is a range of indices
            testCase.verifyEqual(a(2:3), [4 2], ...
                'Array index test failed');
            
            testCase.verifyEqual(a(end), 2, ...
                'Array index test failed');
            
            % matrix indexing
            m = [-2 5; 6 8; 2.4 -3];
            
            testCase.verifyEqual(m(1,1), -2, ...
                'Matrix index test failed');

            testCase.verifyEqual(m(3,1), 2.4, ...
                'Matrix index test failed');
            
            % submatrix indexing
            testCase.verifyEqual(m(2:3,1:2), [6 8; 2.4 -3], ...
                'Matrix index test failed');

            % (colon,2) means all rows, column 2
            testCase.verifyEqual(m(:,2), [5; 8; -3], ...
                'Matrix index test failed');
    
            % linear indexing [(col-1) * nRows + row = (row,col)]
            testCase.verifyEqual(m(5), m(2,2), ...
                'Matrix linear index test failed');
            
            testCase.verifyEqual(m(end), -3, ...
                'Matrix linear index test failed');
            
            % logical indexing to take a subset of a vector
            testCase.verifyEqual(a([false true true]), [4 2], ...
                'logical indexing test failed');
            
        end
        
        function dimensionsPoint(testCase)
            % length, ndims, numel, size, iscolumn, isempty,
            % ismatrix, isrow, isscalar, isvector
            s = -1;
            v = [0 0 0 0];
            e = [];
            m = ones(4,7,3);

            % length is the longest dimension's number of elements
            testCase.verifyEqual(length(s), 1, ...
                'length test failed');

            testCase.verifyEqual(length(v), 4, ...
                'length test failed');

            testCase.verifyEqual(length(e), 0, ...
                'length test failed');

            testCase.verifyEqual(length(m), 7, ...
                'length test failed');

            % everything in MATLAB is an mxArray with at least 2 dims for
            % ndims
            testCase.verifyEqual(ndims(s), 2, ...
                'ndims test failed');

            testCase.verifyEqual(ndims(m), 3, ...
                'ndims test failed');

            % numel is count of all elements
            testCase.verifyEqual(numel(s), 1, ...
                'numel test failed');

            testCase.verifyEqual(numel(v), 4, ...
                'numel test failed');

            testCase.verifyEqual(numel(e), 0, ...
                'numel test failed');

            testCase.verifyEqual(numel(m), 84, ...
                'numel test failed');
            
            % size is a vector of dimension lengths 
            testCase.verifyEqual(size(s), [1 1], ...
                'size test failed');

            testCase.verifyEqual(size(v), [1 4], ...
                'size test failed');

            testCase.verifyEqual(size(e), [0 0], ...
                'size test failed');

            testCase.verifyEqual(size(m), [4 7 3], ...
                'size test failed');

            % iscolumn is true if the vector is a column vector (vertical)
            % and false otherwise
            testCase.verifyEqual(iscolumn([1 2]), false, ...
                'iscolumn test failed');
            
            testCase.verifyEqual(iscolumn([1 2]'), true, ...
                'iscolumn test failed');

            testCase.verifyEqual(isempty(e), true, ...
                'isempty test failed');
            
            testCase.verifyEqual(isempty(m), false, ...
                'isempty test failed');
            
            % ismatrix is true if size() returns 2 elements.  In other
            % words, if ndims < 3.  (even scalars have size of [1 1])
            testCase.verifyEqual(ismatrix(m), false, ...
                'ismatrix test failed');

            testCase.verifyEqual(ismatrix(s), true, ...
                'ismatrix test failed');

            % isrow is true if the vector is a row vector (horizontal)
            % and false otherwise
            testCase.verifyEqual(isrow([1 2]), true, ...
                'isrow test failed');
            
            testCase.verifyEqual(isrow([1 2]'), false, ...
                'isrow test failed');

            testCase.verifyEqual(isscalar(m), false, ...
                'isscalar test failed');

            testCase.verifyEqual(isscalar(s), true, ...
                'isscalar test failed');

            testCase.verifyEqual(isvector(m), false, ...
                'isvector test failed');

            testCase.verifyEqual(isvector(v), true, ...
                'isvector test failed');
        end
        function sortingAndReshapingPoint(testCase)
            % ctranspose ('), permute, ipermute, repmat, reshape, sort,
            % squeeze, transpose
            cm = [0-1i, 1, 0.5; 0, 1+1i, 2; 2+0.2i, 1, 0.25];
            cm_ctrans = [1i, 0, 2-0.2i;1, 1-1i, 1; 0.5, 2, 0.25];
            cm_trans = [-1i, 0, 2+0.2i; 1, 1+1i, 1; 0.5, 2, 0.25];
            m = [-1 0 1 2; 4 3 2 1; 0.2, 0.4, 0.6, 0.8];

            % ctranspose is adjunct matrix (transp + complex conjugate)
            testCase.verifyEqual(cm_ctrans, ctranspose(cm), ...
                'ctranspose test failed');
            
            testCase.verifyEqual(cm_ctrans, cm', ...
                'ctranspose test failed');
            
            % permute and ipermute re-order a matrix (ipermute is inverse)
            zz(1,:,:) = [2 3; 4 5];
            zz(2,:,:) = [-1 -3; 9 0];
            zz(3,:,:) = [4 3; 2 1];
            
            yy = permute(zz,[3 1 2]);
            yy_expected(1,:,:) = [2 4; -1 9; 4 2];
            yy_expected(2,:,:) = [3 5; -3 0; 3 1];

            testCase.verifyEqual(yy, yy_expected, ...
                'permute test failed');
            
            testCase.verifyEqual(zz, ipermute(yy,[3 1 2]), ...
                'ipermute test failed');

            % repmat repeats the first argument nxn times to form a matrix
            a = repmat([1 0; 0 1], 3);
            a_expected = [[1 0; 0 1], [1 0; 0 1], [1 0; 0 1]; ...
                [1 0; 0 1], [1 0; 0 1], [1 0; 0 1]; ...
                [1 0; 0 1], [1 0; 0 1], [1 0; 0 1]];
            testCase.verifyEqual(a, a_expected, ...
                'repmat test failed');
            
            b = repmat(-11, 2, 3);
            b_expected = [-11, -11, -11; -11, -11, -11];
            testCase.verifyEqual(b, b_expected, ...
                'repmat test failed');
            
            % reshape changes dimensions but keeps data in place.  Note
            % MATLAB is column-major, so the data points go down row 1
            % first then to column 2, etc.
            c = reshape(m, 6, 2);
            c_expected = [-1 1; 4 2; 0.2 0.6; 0 2; 3 1; 0.4 0.8];
            testCase.verifyEqual(c, c_expected, ...
                'reshape test failed');

            d = [1 0 1; 2 2 4; 7 2 9];
            d = reshape(d, 3, 1, 3);
            testCase.verifyEqual(size(d), [3 1 3], ...
                'reshape test failed');

            % sort
            %   vector
            testCase.verifyEqual([-1 0 3 4 6], sort([3 6 4 -1 0]), ...
                'sort test failed');
            
            %   sort matrix columns
            e = [1 0 3; 2 -1 14; 4 -3 12];
            e_sort = sort(e, 1);
            e_sort_exp = [1 -3 3; 2 -1 12; 4 0 14];

            testCase.verifyEqual(e_sort, e_sort_exp, ...
                'sort test failed');

            %   sort matrix rows
            e = [1 0 3; 2 -1 14; 4 -3 12];
            e_sort = sort(e, 2);
            e_sort_exp = [0 1 3; -1 2 14; -3 4 12];

            testCase.verifyEqual(e_sort, e_sort_exp, ...
                'sort test failed');

            %   array of strings
            strs = {'One string', 'Another string', ...
                '10 a string that starts with a numeral', 'lowercase'};
            strs_sort = sort(strs);
            strs_sort_exp = {'10 a string that starts with a numeral', ...
                'Another string', 'One string', 'lowercase'};

            testCase.verifyEqual(strs_sort, strs_sort_exp, ...
                'sort test failed');
            
            % squeeze
            f = [1 0 1; 2 2 4; 7 2 9];
            f = reshape(f, 3, 1, 3);
            g = squeeze(f);
            g_expected = [1 0 1; 2 2 4; 7 2 9];
            testCase.verifyEqual(g, g_expected, ...
                'squeeze test failed');
            
            testCase.verifyEqual(size(g), [3 3], ...
                'squeeze test failed');

            % transpose swaps row<->column
            testCase.verifyEqual(cm_trans, transpose(cm), ...
                'transpose test failed');
        end

        function mathOperationsPoint(testCase)
            % min
            A = [3 1 2; 4 5 0];
            V = [-1.1 20 -47*pi 3/7];

            Vmin = min(V);
            Amin = min(A);
            Amin1 = min(A,[],1);
            Amin2 = min(A,[],2);
            Aminall = min(A,[],'all');
            testCase.verifyEqual(Vmin, -147.65485472, 'AbsTol', 1e-6, ...
                'min test failed');
            testCase.verifyEqual(Amin, [3 1 0], 'AbsTol', 1e-6, ...
                'min test failed');
            testCase.verifyEqual(Amin1, [3 1 0], 'AbsTol', 1e-6, ...
                'min test failed');
            testCase.verifyEqual(Amin2, [1; 0], 'AbsTol', 1e-6, ...
                'min test failed');
            testCase.verifyEqual(Aminall, 0, 'AbsTol', 1e-6, ...
                'min test failed');

            % max
            Vmax = max(V'); %#ok<UDIM> 
            Amax = max(A');
            Amax1 = max(A',[],1); %#ok<UDIM> 
            Amax2 = max(A',[],2); %#ok<UDIM> 
            Amaxall = max(A',[],'all'); %#ok<UDIM> 
            testCase.verifyEqual(Vmax, 20, 'AbsTol', 1e-6, ...
                'max test failed');
            testCase.verifyEqual(Amax, [3 5], 'AbsTol', 1e-6, ...
                'max test failed');
            testCase.verifyEqual(Amax1, [3 5], 'AbsTol', 1e-6, ...
                'max test failed');
            testCase.verifyEqual(Amax2, [4; 5; 2], 'AbsTol', 1e-6, ...
                'max test failed');
            testCase.verifyEqual(Amaxall, 5, 'AbsTol', 1e-6, ...
                'max test failed');

            % mean
            Vmean = mean(V);
            Amean = mean(A);
            Amean1 = mean(A,1);
            Amean2 = mean(A,2);
            testCase.verifyEqual(Vmean, -32.081570822537, 'AbsTol', 1e-6, ...
                'mean test failed');
            testCase.verifyEqual(Amean, [3.5 3 1], 'AbsTol', 1e-6, ...
                'mean test failed');
            testCase.verifyEqual(Amean1, [3.5 3 1], 'AbsTol', 1e-6, ...
                'mean test failed');
            testCase.verifyEqual(Amean2, [2; 3], 'AbsTol', 1e-6, ...
                'mean test failed');

            % sum
            Vsum = sum(V);
            Asum = sum(A);
            Asum1 = sum(A,1);
            Asum2 = sum(A,2);
            testCase.verifyEqual(Vsum, -128.32628329, 'AbsTol', 1e-6, ...
                'sum test failed');
            testCase.verifyEqual(Asum, [7 6 2], 'AbsTol', 1e-6, ...
                'sum test failed');
            testCase.verifyEqual(Asum1, [7 6 2], 'AbsTol', 1e-6, ...
                'sum test failed');
            testCase.verifyEqual(Asum2, [6; 9], 'AbsTol', 1e-6, ...
                'sum test failed');

            % diff
            Vdiff = diff(V);
            Adiff = diff(A);
            Adiff1 = diff(A,1,1);
            Adiff2 = diff(A,1,2);
            testCase.verifyEqual(Vdiff, ...
                [21.1 -167.65485471872 148.08342614729171], 'AbsTol', 1e-6, ...
                'diff test failed');
            testCase.verifyEqual(Adiff, [1 4 -2], 'AbsTol', 1e-6, ...
                'diff test failed');
            testCase.verifyEqual(Adiff1, [1 4 -2], 'AbsTol', 1e-6, ...
                'diff test failed');
            testCase.verifyEqual(Adiff2, [-2 1; 1 -5], 'AbsTol', 1e-6, ...
                'diff test failed');
            
        end

        function tablePoint(testCase)
            LastName = {'Smith';'Johnson';'Williams';'Jones';'Wright'};
            Age = [38;43;38;40;46];
            Height = [71;69;64;67;63];
            Weight = [176;163;131;133;110];
            BloodPressure = [124 93; 109 77; 125 83; 117 75; 91 58];

            % see Access Data in a Table in MATLAB help for details
            % create a table
            T = table(Age,Height,Weight,BloodPressure,'RowNames',LastName);
            
            % access table element's data
            testCase.verifyEqual(T(3,3).Weight, 131, ...
                'numerical element access test failed');

            testCase.verifyEqual(T.Weight(2), 163, ...
                'dot element access test failed');

            % number of rows
            testCase.verifyEqual(height(T), 5, ...
                'height test failed');

            % number of columns
            testCase.verifyEqual(width(T), 4, ...
                'width test failed');
            
            % select a sub-table by name
            T2 = T({'Williams','Smith'},:);
            
            testCase.verifyEqual(T2.Weight, [131; 176], ...
                'sub-table dot element access test failed');

            testCase.verifyEqual(height(T2), 2, ...
                'sub-table height test failed');

            testCase.verifyEqual(width(T2), 4, ...
                'sub-table width test failed');
        end
    end
end