classdef DatetimeTest < matlab.unittest.TestCase
    % DATETIMETEST is an example validation test case for some features
    % of the MATLAB language.  This sample is intended to show how the user can
    % create additional tests to be executed.
    %
    % Copyright 2022 The MathWorks, Inc.

    properties
        datetimeSettings;
    end
    
    methods(TestClassSetup)
        function dtTestClassSetup(testcase)
            s = settings;
            testcase.datetimeSettings = s.matlab.datetime;
        end
    end
    
    methods(TestMethodTeardown)
        function dtTestPointTeardown(~)
            datetime.setDefaultFormats('reset');
        end
    end
    
    methods(Test)
        
        function datetimeTest(testcase)
            % Test for validating date and time and timezone

            t1 = datetime('now','TimeZone','Asia/Seoul','Format','d-MMM-y HH:mm:ss');
            testcase.verifyEqual(t1.TimeZone, 'Asia/Seoul', "Validate correct timezone")

            warning('off')

            %--- Case 1: date-only format is not a correct date format ---%
            testcase.datetimeSettings.DefaultDateFormat.PersonalValue = 'mm/dd/uuuu';
            testcase.datetimeSettings.DefaultFormat.PersonalValue = 'mm/dd/uuuu hh:mm:ss aa';
            act_d  = datetime(cellstr(datetime(2015,1,1)));
            act_dt = datetime(cellstr(datetime(2015,1,1,12,0,10)));
                        
            exp_d  = datetime(2015,1,1,0,0,0,'Format','mm/dd/uuuu hh:mm:ss aa');
            exp_dt = datetime(2015,1,1,12,0,10,'Format','mm/dd/uuuu hh:mm:ss aa');
            testcase.verifyEqual(act_d, exp_d, "Date-only format is not a correct date format");
            testcase.verifyEqual(act_dt,exp_dt, "Date-only format is not a correct date format");
            
            datetime.setDefaultFormats('reset');
            
            %--- Case 2: date and datetime format are both ambiguous -----%
            testcase.datetimeSettings.DefaultDateFormat.PersonalValue = 'dd/MM/uuuu';
            testcase.datetimeSettings.DefaultFormat.PersonalValue = 'mm/dd/uuuu hh:mm:ss aa';
            act_d  = datetime(cellstr(datetime(2015,1,2)));
            act_dt = datetime(cellstr(datetime(2015,1,2,5,6,7)));
            
            exp_d  = datetime(2015,2,1,'Format','dd/MM/uuuu');
            exp_dt = datetime(2015,6,2,5,6,7,'Format','MM/dd/uuuu hh:mm:ss aa');
            testcase.verifyEqual(act_d, exp_d, "Date and datetime format are both ambiguous");
            testcase.verifyEqual(act_dt,exp_dt, "Date and datetime format are both ambiguous");
            
            datetime.setDefaultFormats('reset');
            
            warning('on')

        end
        
    end %methods
end %classdef