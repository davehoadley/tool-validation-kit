classdef ControlFlowTest < matlab.unittest.TestCase
% CONTROLFLOWTEST is an example validation test case for some features
% of the MATLAB language.  Specifically, it demonstrates control flow
% language elements such as if/else, switch/case, for and while loops
% It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2017 - 2018 The MathWorks, Inc.

    methods(Test)
        function conditionalPoint(testCase)
            
            x = true;
            passIfTest = false; %#ok<NASGU>
            
            if x
                passIfTest = true;
            end
            
            testCase.verifyEqual(passIfTest, true, 'IF control flow test failed');
            
            if ~x
                passElseTest = false;
            else
                passElseTest = true;
            end

            testCase.verifyEqual(passElseTest, true, 'ELSE control flow test failed');
            
            u = false;
            
            if x && u
                passElseIfTest = false;
            elseif x
                passElseIfTest = true;
            else
                passElseIfTest = false; %#ok<UNRCH>
            end
           
            testCase.verifyEqual(passElseIfTest, true, 'ELSEIF control flow test failed');

            color = 'yellow';
            passOtherwise = true;
            passSwitchCase = false;
            
            switch(color)
                case 'red'
                    passSwitchCase = false;
                case 'yellow'
                    passSwitchCase = true;
                case 'green'
                    passSwitchCase = false;
                otherwise
                    passOtherwise = false;
            end
            
            testCase.verifyEqual(passSwitchCase, true, 'SWITCH CASE control flow test failed');
            testCase.verifyEqual(passOtherwise, true, 'SWITCH OTHERWISE control flow test failed');

            color = 'blue';
            passSwitchCase = false;

            % multiple 
            switch(color)
                case {'blue', 'yellow'}
                    passSwitchCase = true;
                case {'red', 'green'}
                    passSwitchCase = false;
            end
            
            testCase.verifyEqual(passSwitchCase, true, 'SWITCH CASE control flow test failed');
        end
        
        function loopPoint(testCase)

            endCount = 8;
            value = 1;
            
            % 8 loops, so value = 2^8
            for index = 1:endCount
                value = value * 2;
            end
            
            testCase.verifyEqual(value, 256, 'FOR control flow test failed');
            testCase.verifyEqual(index, endCount, 'FOR control flow test failed');

            value = 1;

            % 4 loops with step size 2 instead of 1: expected value = 16
            for index = 1:2:endCount
                value = value * 2;
            end
            
            testCase.verifyEqual(value, 16, 'FOR control flow test failed');

            value = 256;
            
            % count down with step size -1: e.v. = 1
            for index = endCount:-1:1
                value = value / 2;
            end
            
            testCase.verifyEqual(value, 1, 'FOR control flow test failed');

            value = 1;
            % zero iterations (start > end)
            for index = endCount:1
                value = value / 2;
            end
            
            testCase.verifyEqual(value, 1, 'FOR control flow test failed');

            value = 1;
            index = 1;
            
            % stop after 11th iteration
            while (value < 1024)
                index = index + 1;
                value = value * 2;
            end
            
            testCase.verifyEqual(index, 11, 'WHILE control flow test failed');

            value = 1;
            index = 1;

            % zero iterations test
            while (value < 1)
                index = index + 1;
                value = value * 2;
            end
            
            testCase.verifyEqual(index, 1, 'WHILE control flow test failed');
            
            value = 1;

            % break exits the loop early
            for index = 1:1000
                value = value * 2;
                if value > 1024
                    break;
                end
            end
            
            testCase.verifyEqual(value, 2048, 'BREAK control flow test failed');


            % break exits the loop early
            value = 1;
            while (true)
                value = value * 2;
                if value == 1024
                    break;
                end
            end
            
            testCase.verifyEqual(value, 1024, 'BREAK control flow test failed');

            value = 1;

            % continue skips subsequent statements and goes to the next
            % iteration.  We double value only on odd indices, so e.v. =
            % 65536 (2^16)
            for index = 1:32
                if mod(index,2) == 0
                    continue;
                end
                value = value * 2;
            end
            
            testCase.verifyEqual(value, 65536, 'CONTINUE control flow test failed');

            % continue skips subsequent statements and goes to the next
            % iteration.  We double value only on odd indices, so e.v. =
            % 1024 (2^10)

            index = 1;
            value = 1;
            while (index <= 20)
                index = index + 1;
                if mod(index,2) == 0
                    continue;
                end
                value = value * 2;
            end
            
            testCase.verifyEqual(value, 1024, 'CONTINUE control flow test failed');
            
            try
                error('Test of error handling');
                % should not get here
                testCase.verifyEqual(false, true, 'TRY control flow test failed'); %#ok<UNRCH>
            catch thisError
                testCase.verifyEqual(thisError.message, 'Test of error handling', ...
                    'CATCH error handling test failed');
            end

            try
                x = true;
                % should get here
                testCase.verifyEqual(x, true, 'TRY control flow test failed');
            catch thisError %#ok<NASGU>
                testCase.verifyEqual(false, true, 'CATCH control flow test failed');
            end

            return;

            % should not get here
            testCase.verifyEqual(false, true, 'RETURN control flow test failed'); %#ok<UNRCH>
            
        end
        
        function functionPoint(testCase)
            
            addpath([pwd filesep 'ControlFlow']);
            % functions
            
            % userFunction doubles its input argument
            y = userFunction(2);
            
            testCase.verifyEqual(y, 4, 'User-defined function call test failed');
            
            fHandle = @userFunction;
            
            y = fHandle(3);
            
            testCase.verifyEqual(y, 6, 'Function handle call test failed');

            x = ones(2, 3);
            y = [1 1 1; 1 1 1];
            
            testCase.verifyEqual(x, y, 'Built-in function call test failed');
            
            % localFunction multiplies by -2
            y = localFunction(-1);
            testCase.verifyEqual(y, 2, 'local function call test failed');
            
            % feval, eval, evalin, and assignin
            
            y = feval('userFunction',-3);
            testCase.verifyEqual(y, -6, 'feval function call test failed');
            
            y = eval('userFunction(4)');
            testCase.verifyEqual(y, 8, 'eval function call test failed');
            
            y = evalin('base','userFunction(7)');
            testCase.verifyEqual(y, 14, 'evalin function call test failed');

            assignin('base','global_x',11.5);
            x = evalin('base','global_x');
            testCase.verifyEqual(x, 11.5, 'assignin test failed');
            
            % userScript doubles the workspace variable global_x and stores
            % the answer as global_y
            evalin('base','userScript');
            
            y = evalin('base','global_y');
            testCase.verifyEqual(y, 23, 'evalin script call test failed');
            
            function y = localFunction(x)
            
                y = -2 * x;
                
            end
            
            %nargin, varargin
            [numArgs, varArgs] = checkArgs(-1, [1 2; 3 4; 5 6], 'testme');
            testCase.verifyEqual(numArgs, 3, 'nargin test failed');
            testCase.verifyEqual(varArgs{1}, -1, 'varargin test failed');
            testCase.verifyEqual(varArgs{2}, [1 2; 3 4; 5 6], 'varargin test failed');
            testCase.verifyEqual(varArgs{3}, 'testme', 'varargin test failed');

            [numArgs, varArgs] = checkArgs();
            testCase.verifyEqual(numArgs, 0, 'nargin test failed');
            testCase.verifyEqual(isempty(varArgs), true, 'varargin test failed');
            
            % cleanup 
            evalin('base','clear(''global_x'')');
            evalin('base','clear(''global_y'')');
            rmpath([pwd filesep 'ControlFlow']);

            % anonymous function
            myGTZ = @(x) x > 0;
            res = myGTZ([1 0 -1]);
            testCase.verifyEqual(res, [true false false], ...
                'anonymous function test failed');
            
            % arrayfun
            S(1).f1 = [3 2 1];
            S(2).f1 = [2 4 6 8];
            S(3).f1 = [-1; 3; 5];
            A = arrayfun(@(x) mean(x.f1),S);
            testCase.verifyEqual(A, [2 5 7/3], ...
                'arrayfun test failed');
            
            % cellfun iterates over a cell array
            C = {};
            C{1} = [1; 3; 4];
            C{2} = [];
            C{3} = 'This is a string';

            A = cellfun(@(x) numel(x), C);
            testCase.verifyEqual(A, [3 0 16], ...
                'cellfun test failed - unformoutput true');

            C = {};
            C{1} = [1; 3; 4];
            C{2} = [];
            C{3} = zeros([3 6 2]);
            C{4} = 'This is a string';

            A = cellfun(@(x) size(x), C, 'UniformOutput',false);
            testCase.verifyEqual(A, [{[3 1]} {[0 0]} {[3 6 2]} {[1 16]}], ...
                'cellfun test failed - uniformoutput false');
        end
    end
end