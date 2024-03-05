classdef StringTest < matlab.unittest.TestCase

    methods(TestClassSetup)
        % Shared setup for the entire test class
    end

    methods(TestMethodSetup)
        % Setup for each test
    end

    methods(Test)
        % Test methods

        function str2doubleTest(testCase)
            val = str2double('2.625');
            testCase.verifyEqual(val, 2.625, 'verify str2double with scalar argument');
        end

        function num2str(testCase)
            str = num2str(5);
            testCase.verifyEqual(str, '5', 'verify num2str with integer argument');

            str = num2str(-14.09);
            testCase.verifyEqual(str, '-14.09', 'verify num2str with float argument');
            
            str = num2str(pi,3);
            testCase.verifyEqual(str, '3.14', 'verify num2str with specified precision');

            str = char(48);
            testCase.verifyEqual(str, '0', 'verify char conversion from ASCII');

        end

        function stringManipulation(testCase)
            str = 'This is the string we will mdify to test';
            str2 = strrep(str,'mdify','modify');
            testCase.verifyEqual(str2, 'This is the string we will modify to test', 'verify strrep');

            str = 'This is the string we will mdify to test';
            stringsOut = split(str,'t');
            expectedStrings = {'This is '; 'he s'; 'ring we will mdify '; 'o '; 'es'; ''};
            testCase.verifyEqual(stringsOut, expectedStrings, 'verify split');

            str = 'This is the string we will mdify to test';
            stringsOut = split(str,'z');
            expectedStrings = {'This is the string we will mdify to test'};
            testCase.verifyEqual(stringsOut, expectedStrings, 'verify split');

            wsString = '    White space start and end       ';
            str1 = strip(wsString);
            str2 = strip(wsString,'left');
            str3 = strip(wsString,'right');

            testCase.verifyEqual(str1, 'White space start and end', 'verify strip');
            testCase.verifyEqual(str2, 'White space start and end       ', 'verify strip');
            testCase.verifyEqual(str3, '    White space start and end', 'verify strip');
            
        end

    end

end