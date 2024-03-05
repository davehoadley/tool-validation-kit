classdef ExampleClass
    %TestClass an example class for unit testing

    properties
        Property1 double = 0
    end

    methods
        function obj = ExampleClass(inputArg1,inputArg2)
            %TestClass Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function outputArg = AddToProperty1(obj,inputArg)
            %AddToProperty1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end