# MathWorks :registered: Tool Validation Kit Application

**Table of Contents**

- [Tool Validation Kit Application](#tool-validation-kit-application)
  - [Background](#background)
  - [Code Overview](#code-overview)
  - [Getting Started](#getting-started)

## Background

The goal of this work is to provide an example tool validation suite to for commercial off-the-shelf software tools from MathWorks. To comply with the US Food and Drug Administration’s Quality System Regulations, any software tool that is used as part of a medical device development process must be validated as fit for its intended use. Such validation requires documentation of context of use, risks of failure, and mitigation strategies. As this effort is use-case specific, it is outside the scope of this project. However, a very common risk mitigation strategy for commercial off-the-shelf software is to run a set of validation tests to confirm correct results on the end user’s computer system. This project helps automate the construction and execution of such a suite of tool validation unit tests. The resulting test report may be used as evidence for completion of a software validation plan. Some key aspects of the package include
* A MATLAB :registered: app to run a collection of unit tests and report on their outcome
* A collection of unit tests for base MATLAB features and features of some MATLAB toolboxes and add-ons
* A template for adding new tests to cover additional use cases
* Documentation such as MathWorks product quality statements and user guides
* An optional installer to add the TVK to a MATLAB installation as an add-on toolbox

This version works with MATLAB R2023b

## Code Overview

The project code is organized into eight folders: **app**, **demos**, **documentation**,  **documents**, **release**, **source**, **test**, and **UnitTestFolder**.

The **app** folder contains the files needed to run the TVK Application UI. The files contain both programmatic execution of the app, as well as the App Designer file (TVKApp.mlapp).

The **demos** folder contains one demo:

- **Getting Started - Tool Validation Kit CLI Demo**
  - demo_TVK.mlx

The **documentation** folder contains all files required for generating the custom documentation in the Supplemental Software section of the MATLAB:registered: documentation. Please navigate to the "Supplemental Software" section of the MATLAB doc after toolbox installation to access the documentation.

The **documents** folder contains further documentation on getting starting with the Tool Validation Kit, including:

- MATLAB Tool Validation Suite User Guide
- Tool Validation Kit App Guide
- MATLAB-Quality-Statement
- Simulink :registered: -Quality-Statement

The **release** folder contains the toolbox packaging files for installing the source code and TVK UI.

The **source** folder contains all the code for implementing the TVK tool, which is organized in the `+tvk` package. Type `tvk.` on the command line followed by the `Tab` key to list available classes and methods. You can also type `help tvk` to list all contents in the `+tvk` package.

There are two main component of the tvk package:

- **@TVKBase**: This class implements an interface for running the tool validation kit, including running tests and generating reports. Type `help tvk.TVKBase` into the command window for the full list of properties and methods.

- **utilities**: Convenience functions used in both the source and app code.

The **test** folder contains all software unit/integration tests and corresponding utilities. In order to execute all tests, select the `runAllTests` button in the `Projects Shortcuts` tab, or execute this function in the command window. This folder contains the following components:

- **app**: App-based unit tests for TVKApp.mlapp.
  
- **unit**: Unit tests focused on the `@TVKBase` class methods.

- **utilities**: Convenience functions used in the test classes to find project data root location, generate expected results, and run all tests with support for GitLab CI.

To learn more about testing software and continuous integration in MATLAB, refer to the following documentation links:

- [MATLAB Unit Test Framework](https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html)
- [Continuous Integration](https://www.mathworks.com/help/matlab/continuous-integration.html)

The **UnitTestFolder** contains pre-written collection of test cases for various toolboxes including:

- MATLAB
- Computer Vision Toolbox :tm:
- Deep Learning Toolbox :tm:
- Image Processing Toolbox :tm:
- Signal Processing Toolbox :tm:
- Statistics and Machine Learning Toolbox :tm:

## Getting Started

To get started using the TVK tool, please follow the steps below:

1. Open the MATLAB Project by selecting the **TVKApp.prj** file.
2. Open the **TVKApp.mlapp** and the user guide to run the tool interactively and/or
3. Follow the steps in **demo_TVK.mlx** live script for instructions on how to use the tool for selecting test cases, running the test suite, and generating the report.

Alternatively, if you would like to avoid opening the MATLAB project each time, you can install the "Tool Validation Kit.mltbx" toolbox file found in the **release** folder, which will install all custom documentation and allow you to use the app and CLI without modifying any source code.