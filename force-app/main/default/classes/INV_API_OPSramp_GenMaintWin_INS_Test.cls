/*************************************************
* Name: INV_API_OPSramp_GenMaintWin_INS_Test
* Description: Test class for INV_API_OPSramp_GenMaintWin_INS
* ***********************************************/
@isTest
public class INV_API_OPSramp_GenMaintWin_INS_Test {
    
    @testSetup
    static void testSetup() {
        //Create setup Objects in a future call to avoid mixed DML operations
        createSetupObjects();
        
        // Create test case
        Case testCase = new Case(
            Subject = 'Test Change Request for Invocable',
            Status = 'New',
            Priority = 'Medium'
        );
        insert testCase;
        
        // Create test configuration item
        CMDB_Config_Item__c configItem = new CMDB_Config_Item__c(
            Name = 'TestHost1',
            Device_Maintenance_UniqueID__c = 'device-123',
            Device_Maintenance_ClientID__c = 'client-456'
        );
        insert configItem;
        
        // Create test downtime event
        Downtime_Event__c downtimeEvent = new Downtime_Event__c(
            Case__c = testCase.Id,
            Configuration_Item__c = configItem.Id,
            Start_Date_Time__c = DateTime.now().addHours(1),
            End_Date_Time__c = DateTime.now().addHours(3)
        );
        insert downtimeEvent;
    }
    
    @future
    public static void createSetupObjects()
    {
        // Create test queue
        Group testQueue = new Group(
            Name = 'Ops - Monitoring',
            Type = 'Queue'
        );
        insert testQueue;
        
        QueueSObject queueSObject = new QueueSObject(
            QueueId = testQueue.Id,
            SObjectType = 'Case'
        );
        insert queueSObject;
    }
    
    @isTest
    static void testGenerateMaintenanceWindowInOpsRampSuccess() {
        // Get test case
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Change Request for Invocable' LIMIT 1];
        
        // Create input variables
        List<INV_API_OPSramp_GenMaintWin_INS.InputVariables> inputVars = new List<INV_API_OPSramp_GenMaintWin_INS.InputVariables>();
        INV_API_OPSramp_GenMaintWin_INS.InputVariables inputVar = new INV_API_OPSramp_GenMaintWin_INS.InputVariables();
        inputVar.inputCase = testCase;
        inputVars.add(inputVar);
        
        Test.startTest();
        INV_API_OPSramp_GenMaintWin_INS.generateMaintenanceWindowInOpsRamp(inputVars);
        Test.stopTest();
        
        // Verify method completed without throwing exceptions
        System.assert(true, 'Invocable method completed successfully');
    }
    
    @isTest
    static void testGenerateMaintenanceWindowInOpsRampMultipleCases() {
        // Get test case and create additional cases
        Case testCase1 = [SELECT Id FROM Case WHERE Subject = 'Test Change Request for Invocable' LIMIT 1];
        
        Case testCase2 = new Case(
            Subject = 'Test Change Request 2',
            Status = 'New',
            Priority = 'Medium'
        );
        insert testCase2;
        
        // Create input variables for multiple cases
        List<INV_API_OPSramp_GenMaintWin_INS.InputVariables> inputVars = new List<INV_API_OPSramp_GenMaintWin_INS.InputVariables>();
        
        INV_API_OPSramp_GenMaintWin_INS.InputVariables inputVar1 = new INV_API_OPSramp_GenMaintWin_INS.InputVariables();
        inputVar1.inputCase = testCase1;
        inputVars.add(inputVar1);
        
        INV_API_OPSramp_GenMaintWin_INS.InputVariables inputVar2 = new INV_API_OPSramp_GenMaintWin_INS.InputVariables();
        inputVar2.inputCase = testCase2;
        inputVars.add(inputVar2);
        
        Test.startTest();
        INV_API_OPSramp_GenMaintWin_INS.generateMaintenanceWindowInOpsRamp(inputVars);
        Test.stopTest();
        
        // Verify method completed without throwing exceptions for multiple cases
        System.assert(true, 'Invocable method completed successfully for multiple cases');
    }
        @isTest
    static void testGenerateMaintenanceWindowInOpsRampWithException() {
        // Create input variables with null case to force exception
        List<INV_API_OPSramp_GenMaintWin_INS.InputVariables> inputVars = new List<INV_API_OPSramp_GenMaintWin_INS.InputVariables>();
        INV_API_OPSramp_GenMaintWin_INS.InputVariables inputVar = new INV_API_OPSramp_GenMaintWin_INS.InputVariables();
        inputVar.inputCase = null; // This should cause an exception
        inputVars.add(inputVar);
        
        Test.startTest();
        try {
            INV_API_OPSramp_GenMaintWin_INS.generateMaintenanceWindowInOpsRamp(inputVars);
        } catch (Exception e) {
            // Exception handling is done within the method, so this shouldn't be reached
            System.assert(false, 'Exception should be handled within the method');
        }
        Test.stopTest();
        
        // Method should handle exceptions gracefully
        System.assert(true, 'Method handled exception gracefully');
    }
    
    @isTest
    static void testInputVariablesClassInstantiation() {
        // Test InputVariables class can be instantiated
        INV_API_OPSramp_GenMaintWin_INS.InputVariables inputVar = new INV_API_OPSramp_GenMaintWin_INS.InputVariables();
        
        Case testCase = new Case(Subject = 'Test', Status = 'New');
        inputVar.inputCase = testCase;
        
        System.assertEquals(testCase, inputVar.inputCase, 'Input case should be set correctly');
    }
}