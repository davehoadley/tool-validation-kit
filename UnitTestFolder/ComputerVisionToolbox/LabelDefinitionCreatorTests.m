classdef LabelDefinitionCreatorTests < matlab.unittest.TestCase
    % LABELDEFINITIONCREATORTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
   
    methods (Test)
        %------------------------------------------------------------------
        function constructEmpty(test)
            
            % Create an empty LDC.
            ldc = labelDefinitionCreator();
            
            % check that it creates an empty table.
            labelDefTable = ldc.create();
            test.verifyEqual(isempty(labelDefTable), true);
        end
        
        %------------------------------------------------------------------
        function constructorFromTable(test)
            
            % Create an LDC from an existing labelDefinitions table.
            ldc = labelDefinitionCreator();
            
            % create a table from scratch.
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addLabel('testpc', labelType.ProjectedCuboid);
            ldc.addAttribute('test', 'testAttribute', 'Li', {'1', '2', '3'});
            ldc.addAttribute('testpc', 'testAttribute', 'Li', {'1', '2', '3'});
            labelDefTable = ldc.create();
            
            % Import it into a new Creator.
            ldc2 = labelDefinitionCreator(labelDefTable);
            labelDefTable2 = ldc2.create();
            test.verifyEqual(labelDefTable, labelDefTable2);
            
            % Check that PixelLabelID is not generated, but hierarchy is.
            test.verifyEqual(numel(labelDefTable.Properties.VariableNames), 6);
        end
        
        %------------------------------------------------------------------
        function addLabel(test)
            
            % Add several labels, and check that they all have the right
            % properties.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', 'r', 'LabelColor', [1 0 1]);
            labelDefTable = ldc.create();
            
            test.verifyEqual(height(labelDefTable), 1);
            test.verifyEqual(labelDefTable.Name, {'test'});
            test.verifyEqual(labelDefTable.Type, labelType.Rectangle);
            
            % Check that PixelLabelID and Hierarchy columns are not generated.
            test.verifyEqual(numel(labelDefTable.Properties.VariableNames), 5);
            
            % add a custom label, and check that the table is setup
            % correctly.
            customDesc = 'this is a custom label';
            ldc.addLabel('test2', labelType.Custom, 'Descripti', customDesc);
            labelDefTable = ldc.create();
            
            test.verifyEqual(height(labelDefTable), 2);
            test.verifyEqual(labelDefTable.Name{1}, 'test');
            test.verifyEqual(labelDefTable.Name{2}, 'test2');
            test.verifyEqual(labelDefTable.Type(1), labelType.Rectangle);
            test.verifyEqual(labelDefTable.Description{1}, ' ');
            test.verifyEqual(labelDefTable.Type(2), labelType.Custom);
            test.verifyEqual(labelDefTable.Description{2}, customDesc);
            test.verifyEqual(labelDefTable.Group{1}, 'None');
            test.verifyEqual(labelDefTable.Group{2}, 'None'); 
            test.verifyEqual(labelDefTable.LabelColor{1}, [1 0 1]);
            test.verifyEqual(labelDefTable.LabelColor{2}, '');
            
            % Add a scene label, and check that it appends to the existing
            % labels.
            ldc.addLabel('test3', labelType.Scene, 'Group', 'Scene');
            labelDefTable = ldc.create();
            
            test.verifyEqual(height(labelDefTable), 3);
            test.verifyEqual(labelDefTable.Name{1}, 'test');
            test.verifyEqual(labelDefTable.Name{3}, 'test3');
            test.verifyEqual(labelDefTable.Type(2), labelType.Custom);
            test.verifyEqual(labelDefTable.Type(3), labelType.Scene);
            test.verifyEqual(labelDefTable.Group{3}, 'Scene');  
            test.verifyEqual(labelDefTable.LabelColor{3}, '');
        end
        
        %------------------------------------------------------------------
        function removeLabel(test)
            
            % Remove a label from the label definition table.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addLabel('test2', "Pi");
            labelDefTable = ldc.create();
            
            % check that there are two labels.
            test.verifyEqual(height(labelDefTable), 2);
            test.verifyEqual(labelDefTable.Name{1}, 'test');
            test.verifyEqual(labelDefTable.Name{2}, 'test2');
            
            % remove 'test', and check that only 'test2' remains.
            ldc.removeLabel('test');
            labelDefTable2 = ldc.create();
            test.verifyEqual(height(labelDefTable2), 1);
            test.verifyEqual(labelDefTable2.Name{1}, 'test2');
            
            % remove 'test2' also, and check that nothing remains.
            ldc.removeLabel('test2');
            labelDefTable3 = ldc.create();
            test.verifyEqual(isempty(labelDefTable3), true);
        end
        
        %------------------------------------------------------------------
        function addSublabel(test)
            
            % Create a single label, and a sublabel.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addSublabel('test', 'testsublabel', 'recta', 'LabelColor', [1 0 1]);
            ldc.addLabel('testpc', labelType.ProjectedCuboid);
            ldc.addSublabel('testpc', 'testsublabelpc', 'ProjectedCuboid', 'LabelColor', [1 0 1]);
            labelDefTable = ldc.create();
            
            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 2);
            % which has a sublabel with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testsublabel')));
            % type,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.Type, labelType.Rectangle);
            test.verifyEqual(labelDefTable.Hierarchy{2}.testsublabelpc.Type, labelType.ProjectedCuboid);
            % description,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.Description, ' ');
            % color
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.LabelColor, [1 0 1]);
            % and that there's only one sublabel (no attributes or other
            % sublabels). 3 = Type of parent, Description of parent, and
            % sublabel struct.
            test.verifyEqual(numel(fieldnames(labelDefTable.Hierarchy{1})), 3);
            
            % Create another sublabel, and verify the same properties.
            sublabelDesc = 'this is a custom sublabel description';
            ldc.addSublabel('test', 'testsublabel2', labelType.Line, 'Descr', sublabelDesc);
            labelDefTable2 = ldc.create();
            
            test.verifyEqual(height(labelDefTable2), 2);
            % which has a sublabel with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable2.Hierarchy{1})), 'testsublabel2')));
            % type,
            test.verifyEqual(labelDefTable2.Hierarchy{1}.testsublabel2.Type, labelType.Line);
            % description,
            test.verifyEqual(labelDefTable2.Hierarchy{1}.testsublabel2.Description, sublabelDesc);
            % color,
            test.verifyEqual(labelDefTable2.Hierarchy{1}.testsublabel2.LabelColor, '');
            % and that there's only one sublabel (no attributes or other
            % sublabels). 3 = Type of parent, Description of parent, and
            % sublabel struct.
            test.verifyEqual(numel(fieldnames(labelDefTable2.Hierarchy{1})), 4);            
        end
        
        %------------------------------------------------------------------
        function removeSublabel(test)
            
            % Add two sublabels to a label, and remove one.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addSublabel('test', 'testsublabel', "Rectang", 'LabelColor', [1 0 1]);
            ldc.addSublabel('test', 'testsublabel2', 'l');
            ldc.removeSublabel('test', 'testsublabel2');
            labelDefTable = ldc.create();
            
            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 1);
            % which has a sublabel with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testsublabel')));
            % type,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.Type, labelType.Rectangle);
            % description,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.Description, ' ');
            % color
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.LabelColor, [1 0 1]);
            % and that there's only one sublabel (no attributes or other
            % sublabels). 3 = Type of parent, Description of parent, and
            % sublabel struct.
            test.verifyEqual(numel(fieldnames(labelDefTable.Hierarchy{1})), 3);
            
            % make sure that testsublabel2 is gone.
            test.verifyFalse(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testsublabel2')));

            ldc.removeSublabel('test','testsublabel');
            labelDefTable = ldc.create();

            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 1);
            % which does not have a hierarchy column.
            test.verifyFalse(ismember('Hierarchy', labelDefTable.Properties.VariableNames));
        end
        
        %------------------------------------------------------------------
        function addAttribute(test)
            
            % Create a single label, and an attribute.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addAttribute('test', 'testAttribute', attributeType.List, {'1', '2', '3'});
            labelDefTable = ldc.create();
            
            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 1);
            % with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testAttribute')));
            % list items,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testAttribute.ListItems, {'1', '2', '3'});
            % description,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testAttribute.Description, ' ');
            % and that there's only one attribute (no sublabels or other
            % attributes). 3 = Type of parent, Description of parent, and
            % attribute struct.
            test.verifyEqual(numel(fieldnames(labelDefTable.Hierarchy{1})), 3);
            
            % Now add a Logical attribute, and test the same properties.
            logicalDesc = 'this is a logical attribute';
            ldc.addAttribute('test', 'testAttribute2', 'lo', false, 'Desc', logicalDesc);
            labelDefTable2 = ldc.create();
            
            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable2), 1);
            % with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable2.Hierarchy{1})), 'testAttribute2')));
            % default value,
            test.verifyEqual(labelDefTable2.Hierarchy{1}.testAttribute2.DefaultValue, false);
            % description,
            test.verifyEqual(labelDefTable2.Hierarchy{1}.testAttribute2.Description, logicalDesc);
            % and that there are two attributes now.
            test.verifyEqual(numel(fieldnames(labelDefTable2.Hierarchy{1})), 4);
            
            % Now add a new label and a Numeric attribute, to a new
            % sublabel in it, and test the same properties.
            ldc.addLabel('test2', labelType.Line);
            ldc.addSublabel('test2', 'testsublabel', 'lin'); % line
            numericDesc = 'this is a numeric attribute';
            ldc.addAttribute('test2/testsublabel', 'testAttribute', attributeType.Numeric, 42, 'Desc', numericDesc);
            labelDefTable3 = ldc.create();
            
            % Check that there are two labels now.
            test.verifyEqual(height(labelDefTable3), 2);
            % with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable3.Hierarchy{2}.testsublabel)), 'testAttribute')));
            % default value,
            test.verifyEqual(labelDefTable3.Hierarchy{2}.testsublabel.testAttribute.DefaultValue, 42);
            % description,
            test.verifyEqual(labelDefTable3.Hierarchy{2}.testsublabel.testAttribute.Description, numericDesc);
            % and that there's only one sublabel for test2.
            test.verifyEqual(numel(fieldnames(labelDefTable3.Hierarchy{2})), 3);
            % and that there's only one attribute for testsublabel.
            test.verifyEqual(numel(fieldnames(labelDefTable3.Hierarchy{2}.testsublabel)), 4);
        end
        
        %------------------------------------------------------------------
        function removeAttribute(test)
            
            % Create a label, add two attributes and remove one.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addAttribute('test', 'testAttr', attributeType.List, {'a', 'b', 'c'});
            ldc.addAttribute('test', 'testAttr2', 'n', 999); % numeric
            ldc.removeAttribute('test', 'testAttr');
            labelDefTable = ldc.create();
            
            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 1);
            % which has an attribute with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testAttr2')));
            % default value,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testAttr2.DefaultValue, 999);
            % description,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testAttr2.Description, ' ');
            % and that there's only one attribute remaining.
            test.verifyEqual(numel(fieldnames(labelDefTable.Hierarchy{1})), 3); 

            ldc.removeAttribute('test', 'testAttr2');
            labelDefTable = ldc.create();

            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 1);
            % which does not have a hierarchy column.
            test.verifyFalse(ismember('Hierarchy', labelDefTable.Properties.VariableNames));

            % Add the lastly removed attribute back to the label
            ldc.addAttribute('test', 'testAttr2', 'n', 999); % numeric
            
            % Now add a sublabel, and then add two attributes to it, and
            % remove one.
            ldc.addSublabel('test', 'testsublabel', labelType.Rectangle);
            ldc.addAttribute('test/testsublabel', 'testAttr', attributeType.List, {'a', 'b', 'c'});
            ldc.addAttribute('test/testsublabel', 'testAttr2', 'str', 'defString');
            ldc.removeAttribute('test/testsublabel', 'testAttr');
            labelDefTable = ldc.create();
            
            % Check that there's only one label,
            test.verifyEqual(height(labelDefTable), 1);
            % which has a sublabel with the right name,
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testsublabel')));
            % and an attribute (previously created)
            test.verifyTrue(any(contains(string(fieldnames(labelDefTable.Hierarchy{1})), 'testAttr2')));
            
            % now look into the testsublabel, and check if the attribute is
            % good.
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.testAttr2.DefaultValue, 'defString');
            % description,
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.testAttr2.Description, ' ');
            % and that there's only one attribute and sublabel remaining.
            test.verifyEqual(numel(fieldnames(labelDefTable.Hierarchy{1})), 4);
        end

        %------------------------------------------------------------------
        function editLabelDescription(test)
            
            % TODO: currently, only character vectors are allowed. Also
            % allow string descriptions.
            
            % Add several labels, and check that descriptions are
            % updateable.
            labelDesc = 'this is a test label description';
            
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.PixelLabel, 'Desc', labelDesc);
            ldc.addLabel('test2', labelType.Scene, 'Desc', labelDesc);
            ldc.addLabel('test3', labelType.Line, 'Desc', labelDesc);
            ldc.addSublabel('test3', 'testsublabel', labelType.Rectangle, 'Desc', labelDesc);
            labelDefTable = ldc.create();
            
            test.verifyEqual(labelDefTable.Description{1}, labelDesc);
            test.verifyEqual(labelDefTable.Description{2}, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{3}.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{3}.testsublabel.Description, labelDesc);
            
            newLabelDesc = 'this is a new label description';
            ldc.editLabelDescription('test2', newLabelDesc);
            ldc.editLabelDescription('test3', newLabelDesc);
            ldc.editLabelDescription('test3/testsublabel', newLabelDesc);
            labelDefTable = ldc.create();
            
            test.verifyEqual(labelDefTable.Description{1}, labelDesc);
            test.verifyEqual(labelDefTable.Description{2}, newLabelDesc);
            test.verifyEmpty(labelDefTable.Hierarchy{2}); % if there's no hierarchy, edit label description does not add it.
            test.verifyEqual(labelDefTable.Description{3}, newLabelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{3}.Description, newLabelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{3}.testsublabel.Description, newLabelDesc);
            
            % g1796410
            ldc = labelDefinitionCreator();
            addLabel(ldc,'Label_1',labelType.Line)
            addSublabel(ldc,'Label_1','Sublabel_1',labelType.Line)
            editLabelDescription(ldc,'Label_1','This is description for Label_1');
            labelDefs = create(ldc);
            test.verifyEqual(labelDefs.Description{1}, labelDefs.Hierarchy{1}.Description);
        end
        
        %------------------------------------------------------------------
        function editLabelGroup(test)
            ldc = labelDefinitionCreator();
            ldc.addLabel('Car', labelType.Rectangle, 'Group', 'Vehicle');
            ldc.addLabel('Stop', labelType.Rectangle, 'Group', 'Vehicle'); 
            
            ldc.editLabelGroup('Stop', 'TrafficSign');
            labelDefTable = ldc.create();

            test.verifyEqual(labelDefTable.Group{1}, 'Vehicle');
            test.verifyEqual(labelDefTable.Group{2}, 'TrafficSign');            
        end
        
        %------------------------------------------------------------------
        function editGroupName(test)
            
            ldc = labelDefinitionCreator();
            ldc.addLabel('Car', labelType.Rectangle, 'Group', 'Vehicle');
            ldc.addLabel('Truck', labelType.Rectangle, 'Group', 'Vehicle');   
            
            ldc.editGroupName('Vehicle', 'FourWheeler');
            labelDefTable = ldc.create();
            
            test.verifyEqual(labelDefTable.Group{1}, 'FourWheeler');
            test.verifyEqual(labelDefTable.Group{2}, 'FourWheeler');  
            
            ldc = labelDefinitionCreator();
            ldc.addLabel('Car', labelType.ProjectedCuboid, 'Group', 'Vehicle');
            ldc.addLabel('Truck', labelType.ProjectedCuboid, 'Group', 'Vehicle');   
            
            ldc.editGroupName('Vehicle', 'FourWheeler');
            labelDefTable = ldc.create();
            
            test.verifyEqual(labelDefTable.Group{1}, 'FourWheeler');
            test.verifyEqual(labelDefTable.Group{2}, 'FourWheeler'); 
        end
        
        %------------------------------------------------------------------
        function editAttributeDescription(test)
            
            % Add several labels with attributes, and check that
            % descriptions are updateable.
            labelDesc = 'this is a test label description';
            attrDesc = 'this is a test attribute description';
            
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Line, 'Desc', labelDesc);
            ldc.addLabel('test2', labelType.Rectangle, 'Desc', labelDesc);
            ldc.addSublabel('test', 'testsublabel', labelType.Rectangle, 'Desc', labelDesc);
            ldc.addAttribute('test/testsublabel', 'testAttr', attributeType.Logical, true, 'Desc', attrDesc);
            ldc.addAttribute('test2', 'testAttr', attributeType.Numeric, 43, 'Desc', attrDesc);
            labelDefTable = ldc.create();
            
            test.verifyEqual(labelDefTable.Description{1}, labelDesc);
            test.verifyEqual(labelDefTable.Description{2}, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{1}.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.testAttr.Description, attrDesc);
            test.verifyEqual(labelDefTable.Hierarchy{2}.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{2}.testAttr.Description, attrDesc);
            
            newAttrDesc = 'this is a new label description';
            ldc.editAttributeDescription('test/testsublabel', 'testAttr', newAttrDesc);
            ldc.editAttributeDescription('test2', 'testAttr', newAttrDesc);
            labelDefTable = ldc.create();
            
            test.verifyEqual(labelDefTable.Description{1}, labelDesc);
            test.verifyEqual(labelDefTable.Description{2}, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{1}.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{1}.testsublabel.testAttr.Description, newAttrDesc);
            test.verifyEqual(labelDefTable.Hierarchy{2}.Description, labelDesc);
            test.verifyEqual(labelDefTable.Hierarchy{2}.testAttr.Description, newAttrDesc);
            
        end
        
        % create only simply returns the table. There's nothing really to
        % test here. It is also used in all the tests above, and so should
        % be sufficiently tested.
        
        %------------------------------------------------------------------
        function show(test)
            
            labelDesc = 'this is a test label description';
            attrDesc = 'this is a test attribute description';
            
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Line, 'Desc', labelDesc);
            ldc.addLabel('test2', labelType.Rectangle, 'Desc', labelDesc);
            ldc.addSublabel('test', 'testsublabel', labelType.Rectangle, 'Desc', labelDesc);
            ldc.addAttribute('test/testsublabel', 'testAttr', attributeType.Logical, true, 'Desc', attrDesc);
            ldc.addAttribute('test2', 'testAttr', attributeType.Numeric, 43, 'Desc', attrDesc);
            ldc2 = labelDefinitionCreator(); %#ok<NASGU>
            
            %capture the display
            out1 = evalc('ldc');
            out2 = evalc('ldc2');
            
            function out = replaceREGEXP(in)
                out = strrep(in, 'R_E_G_E_X_P', '.*');            
            end
            
            expectedString = replaceREGEXP(regexptranslate('escape', getString(message('vision:labelDefinitionCreator:HeaderWithLabels','R_E_G_E_X_P'))));
            % Header
            test.verifyTrue(~isempty(regexp(out1, expectedString, 'once')));
            test.verifyTrue(contains(out1, "test"));
            % 1 with 0 sublabel
            expectedString1 = replaceREGEXP(regexptranslate('escape', getString(message('vision:labelDefinitionCreator:LabelDetails','R_E_G_E_X_P','1','0','R_E_G_E_X_P'))));
            test.verifyTrue(~isempty(regexp(out1, expectedString1, 'once')));
            % 0 with 1 sublabel
            expectedString2 = replaceREGEXP(regexptranslate('escape', getString(message('vision:labelDefinitionCreator:LabelDetails','R_E_G_E_X_P','0','1','R_E_G_E_X_P'))));            
            test.verifyTrue(~isempty(regexp(out1, expectedString2, 'once')));
            test.verifyTrue(contains(out1, "test2"));
            
            addLabelLink = "<a href=""matlab:help('labelDefinitionCreator/addLabel')"">addLabel</a>";
            expectedString = replaceREGEXP(regexptranslate('escape', getString(message('vision:labelDefinitionCreator:HeaderNoLabels','R_E_G_E_X_P', addLabelLink))));            
            test.verifyTrue(~isempty(regexp(out2, expectedString, 'once')));
        end
                
        %------------------------------------------------------------------
        function stringSupport(test)
            
            % Ensure Strings are supported.
            ldcString = labelDefinitionCreator();
            labelDesc = "This is a test label description";
            ldcString.addLabel("test", labelType.Line, "Desc", labelDesc);
            ldcString.addLabel("test2", labelType.Rectangle, "Desc", labelDesc);
            ldcString.addSublabel('test', "testsublabel", labelType.Rectangle, 'Desc', labelDesc);
            ldcString.addAttribute("test/testsublabel", "testAttr", attributeType.Logical, true);
            ldcString.addAttribute("test2", "testAttr", attributeType.Numeric, 43);
            labelDefTable = ldcString.create();
            
            ldc = labelDefinitionCreator();
            labelDesc = 'This is a test label description';
            ldc.addLabel('test', labelType.Line, 'Desc', labelDesc);
            ldc.addLabel('test2', labelType.Rectangle, 'Desc', labelDesc);
            ldc.addSublabel('test', 'testsublabel', labelType.Rectangle, 'Desc', labelDesc);
            ldc.addAttribute('test/testsublabel', 'testAttr', attributeType.Logical, true);
            ldc.addAttribute('test2', 'testAttr', attributeType.Numeric, 43);
            labelDefTableChar = ldc.create();
            
            test.verifyEqual(labelDefTable, labelDefTableChar);
            
            ldc = labelDefinitionCreator();
            addLabel(ldc,'Car', labelType.Rectangle, 'Group', 'Vehicle');
            addLabel(ldc, 'Truck', labelType.Rectangle, 'Group', 'FourWheeler');
            editGroupName(ldc, 'Vehicle', 'FourWheeler');
            editLabelGroup(ldc, 'Car', 'FourWheeler');
            removeLabel(ldc, 'Car');
         
            ldc_Str = labelDefinitionCreator();
            addLabel(ldc_Str, "Car", labelType.Rectangle, "Group" , "Vehicle");
            addLabel(ldc_Str, "Truck", labelType.Rectangle, "Group", "FourWheeler");
            editGroupName(ldc_Str, "Vehicle", "FourWheeler");
            editLabelGroup(ldc_Str, "Car", "FourWheeler");
            removeLabel(ldc_Str, "Car");
            
            test.verifyEqual(ldc, ldc_Str)
            
            ldc = labelDefinitionCreator();
            addLabel(ldc, 'Vehicle', labelType.Rectangle);

            editLabelDescription(ldc, 'Vehicle', 'Bounding boxes for vehicles');
            addLabel(ldc, 'TrafficLight', labelType.Rectangle, 'Description', 'Bounding boxes for traffic light');
            addSublabel(ldc, 'TrafficLight', 'RedLight', labelType.Rectangle);
            addSublabel(ldc, 'TrafficLight', 'GreenLight', labelType.Rectangle);
            addSublabel(ldc, 'TrafficLight', 'BlueLight', labelType.Rectangle);
            addAttribute(ldc, 'TrafficLight/RedLight', 'isOn', attributeType.Logical, false);
            editAttributeDescription(ldc, 'TrafficLight/RedLight', 'isOn', 'Logical status of light: true if turned on');
            addAttribute(ldc, 'TrafficLight/RedLight', 'Color', attributeType.String, 'Red');
            removeAttribute(ldc, 'TrafficLight/RedLight', 'Color');
            removeSublabel(ldc, 'TrafficLight', 'BlueLight');
            
            ldc_Str = labelDefinitionCreator();
            addLabel(ldc_Str, "Vehicle", labelType.Rectangle);
            editLabelDescription(ldc_Str, "Vehicle", "Bounding boxes for vehicles");
            addLabel(ldc_Str, "TrafficLight", labelType.Rectangle, "Description", "Bounding boxes for traffic light");
            addSublabel(ldc_Str, 'TrafficLight', "RedLight", labelType.Rectangle);
            addSublabel(ldc_Str, "TrafficLight", "GreenLight", labelType.Rectangle);
            addSublabel(ldc_Str, "TrafficLight", "BlueLight", labelType.Rectangle);
            addAttribute(ldc_Str, "TrafficLight/RedLight", "isOn", attributeType.Logical, false);
            editAttributeDescription(ldc_Str, "TrafficLight/RedLight", "isOn", "Logical status of light: true if turned on");
            addAttribute(ldc_Str, "TrafficLight/RedLight", "Color", attributeType.String, "Red");
            removeAttribute(ldc_Str, "TrafficLight/RedLight", "Color");
            removeSublabel(ldc_Str, "TrafficLight", "BlueLight");
            
            test.verifyEqual(ldc, ldc_Str)
        end
        
    end
    
    %----------------------------------------------------------------------
    methods (Test)
        %------------------------------------------------------------------
        function listlabels(test)
            % Create a set of labels and sublabel hierarchies, and list
            % them out.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addSublabel('test', 'testsublabel', labelType.Line);
            ldc.addLabel('test2', labelType.Line);
            ldc.addLabel('test3', labelType.Line);
            ldc.addSublabel('test3', 'testsublabel', labelType.Line);
            ldc.addSublabel('test3', 'testsublabel2', labelType.Rectangle);
            ldc.addAttribute('test3/testsublabel2', 'testAttr', attributeType.Logical, false); % Should not be included in labels list.
            labelNames = ldc.listLabels(true);
            test.verifyEqual(numel(labelNames), 6);
            
            labelNames = ldc.listLabels(false);
            test.verifyEqual(numel(labelNames), 3);
        end
        
        %------------------------------------------------------------------
        function listattributes(test)
            % Create a set of labels, sublabels and attribute hierarchies
            % and list them out.
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle);
            ldc.addSublabel('test', 'testsublabel', labelType.Line);
            ldc.addAttribute('test/testsublabel', 'testAttr', attributeType.String, 'hello');
            ldc.addLabel('test2', labelType.Line);
            ldc.addAttribute('test2', 'testAttr', attributeType.String, 'hello again');
            ldc.addLabel('test3', labelType.Line);
            ldc.addAttribute('test3', 'testAttr', attributeType.Logical, false);
            ldc.addSublabel('test3', 'testsublabel2', labelType.Rectangle);
            ldc.addAttribute('test3/testsublabel2', 'testAttr', attributeType.Logical, false);
            
            % List attributes of test3 only.
            attributenames = ldc.listAttributes('test3');
            test.verifyEqual(numel(attributenames), 1);
            
            % List all attributes
            attributenames = ldc.listAttributes();
            test.verifyEqual(numel(attributenames), 4);
            
            % List attributes of test/testsublabel
            attributenames = ldc.listAttributes('test/testsublabel');
            test.verifyEqual(numel(attributenames), 1);
        end
        
        %------------------------------------------------------------------
        function info(test)
            % Create a set of attributes and labels, and query details
            % about them.
            
            ldc = labelDefinitionCreator();
            ldc.addLabel('test', labelType.Rectangle, 'Group', 'group', 'Description', 'hello, world!', 'LabelColor', [1 0 1]);
            ldc.addSublabel('test', 'testsublabel', labelType.Line);
            ldc.addAttribute('test/testsublabel', 'testAttr', attributeType.String, 'hello');
            ldc.addLabel('test2', labelType.Line);
            ldc.addAttribute('test2', 'testAttr', attributeType.Numeric, 1);
            ldc.addLabel('test3', labelType.Line);
            ldc.addAttribute('test3', 'testAttr', attributeType.List, {'1', '2', '3'});
            ldc.addSublabel('test3', 'testsublabel2', labelType.Rectangle);
            ldc.addAttribute('test3/testsublabel2', 'testAttr', attributeType.Logical, false);
            
            teststr = ldc.info('test');
            test.verifyEqual(teststr.Name, "test");
            test.verifyEqual(teststr.Type, labelType.Rectangle);
            test.verifyEqual(teststr.Group, "group");
            test.verifyEqual(teststr.Description, 'hello, world!');
            test.verifyEqual(teststr.LabelColor{1}, [1 0 1]);
            test.verifyEqual(numel(fields(teststr)), 7); % attributes + sublabels.
            
            testsl = ldc.info("test/testsublabel");
            test.verifyEqual(testsl.Name, "testsublabel");
            test.verifyEqual(testsl.Type, labelType.Line);
            
            testslattr = ldc.info("test\testsublabel\testAttr");
            test.verifyEqual(testslattr.Name, "testAttr");
            test.verifyEqual(testslattr.Type, attributeType.String);
            test.verifyEqual(testslattr.DefaultValue, 'hello');
            test.verifyEqual(testslattr.Description, ' ');
            test.verifyEqual(numel(fields(testslattr)), 4);
            
            testattr = ldc.info('test3/testAttr');
            test.verifyEqual(testattr.Name, "testAttr");
            test.verifyEqual(testattr.Type, attributeType.List);
            test.verifyEqual(testattr.ListItems, {'1', '2', '3'});
            test.verifyEqual(testattr.Description, ' ');
            test.verifyEqual(numel(fields(testattr)), 4);
        end
        
    end %methods
end %classdef