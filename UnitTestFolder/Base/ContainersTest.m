classdef ContainersTest < matlab.unittest.TestCase
% CONTAINERSTEST is a validation test case for some features
% of the MATLAB language.  Specifically, it demonstrates basic
% operatorations with containers like classes, structs, and cells.
% It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2023 The MathWorks, Inc.

    methods(Test)
        function ClassTest(testCase)
            % Tests the basics of the class system, including classdef,
            % properties and methods.

            obj = Containers.ExampleClass(1.1, 2.2);
            
            testCase.verifyEqual(obj.Property1, 3.3, 'RelTol', eps, ...
                'object property not set on contruction');

            result = obj.AddToProperty1(-4.4);

            testCase.verifyEqual(result, -1.1, ...
                'RelTol', eps, 'Method invocation failed');

            obj.Property1 = 5.5;
            Property1 = obj.Property1;
            testCase.verifyEqual(Property1, 5.5, ...
                'RelTol', eps, 'Property set/get failed');
        end

        function StructTest(testCase)
            % test of MATLAB structs

            thisStruct = struct('fieldA',[1 2 3],'fieldB',"string test", ...
                'substruct', struct('substruct_field_1',2.2));
            
            testCase.verifyEqual(thisStruct.fieldA, [1, 2, 3], 'RelTol', eps, ...
                'Struct field test failed');
            testCase.verifyEqual(thisStruct.substruct.substruct_field_1, 2.2, 'RelTol', eps, ...
                'substruct field test failed');
            thisStruct.fieldA = int32(-1);
            testCase.verifyEqual(thisStruct.fieldA, int32(-1), ...
                'Struct field reassignment test failed');

            fields = fieldnames(thisStruct);
            expectedFields = {'fieldA'; 'fieldB'; 'substruct'};
            testCase.verifyEqual(fields, expectedFields, ...
                'Struct field reassignment test failed');
            
        end        

        function CellArrayTest(testCase)
            % test of cell arrays
            cellArray = repmat({},3,1);

            cellArray{1} = 'A character array';
            cellArray{2} = [3 2 1];
            cellArray{3} = [{'sub cell array char array'}, {[true false false]}];

            testCase.verifyEqual(cellArray{1}, 'A character array', ...
                'Cell array string element failed');
            testCase.verifyEqual(cellArray{2}, [3 2 1], ...
                'Cell array numeric array element failed');
            testCase.verifyEqual(cellArray{3}{2}, [true false false], ...
                'Cell array cell array element failed');

            cellArray = [cellArray [{2.2} {'concat test'}]];

            testCase.verifyEqual(cellArray{end}, 'concat test', ...
                'Cell array concatenation failed');

            cellArray2D{1,1} = 1.1;
            cellArray2D{2,1} = 2.1;
            cellArray2D{3,1} = 3.1;
            cellArray2D{1,2} = 1.2;
            cellArray2D{2,2} = 2.2;
            cellArray2D{3,2} = 3.2;
            
            testCase.verifyEqual(cellArray2D{2,2}, 2.2, ...
                'Cell 2D array test failed');
            testCase.verifyEqual(cellArray2D{3,1}, 3.1, ...
                'Cell 2D array test failed');

            % convert a numeric array to a cell array
            cellArray = num2cell([1 2 3; 4 5 6]);
            testCase.verifyEqual(cellArray, [{1} {2} {3}; {4} {5} {6}], ...
                'Num2Cell test failed');
            cellArray = num2cell([1 2 3; 4 5 6],1);
            testCase.verifyEqual(cellArray, [{[1; 4]} {[2; 5]} {[3; 6]}], ...
                'Num2Cell test failed');
            cellArray = num2cell([1 2 3; 4 5 6],2);
            testCase.verifyEqual(cellArray, [{[1 2 3]}; {[4 5 6]}], ...
                'Num2Cell test failed');

            % contains() for cell arrays of strings
            strings = {'fieldA', 'fieldB', 'substruct'};
            isThere = contains(strings,'field');
            testCase.verifyEqual(isThere, [true true false], ...
                'contains failed to find matching string');

            isThere = contains(strings,'fieldC');
            testCase.verifyEqual(isThere, [false false false], ...
                'contains failed to report no matching string');
            

        end

        function cellToTable(testCase)
            % cell array of cell arrays of the same size (to become table
            % rows
            cellArray = [{{1 2 3}}; {{4 5 6}}];
            cellTable = cell2table(vertcat(cellArray{:}),'VariableNames',{'a', 'b', 'c'});
   
            a = [1; 4];
            b = [2; 5];
            c = [3; 6];
            expectedTable = table(a,b,c);

            testCase.verifyEqual(cellTable, expectedTable, 'Verify cell2table');
            
        end
    end
end