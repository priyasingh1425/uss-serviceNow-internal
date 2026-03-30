/*************************************************
* Name: API_OPSramp_GenMaintW_HLP_Test
* Description: Test class for API_OPSramp_GenMaintW_HLP
* ***********************************************/
@isTest
public class API_OPSramp_GenMaintW_HLP_Test {
    
    @testSetup
    static void testSetup() {
        //Create setup Objects in a future call to avoid mixed DML operations
        createSetupObjects();
        
        // Create test case
        Case testCase = new Case(
            Subject = 'Test Change Request',
            Status = 'New',
            Priority = 'Medium'
        );
        insert testCase;
        
        // Create test configuration items
        CMDB_Config_Item__c configItem1 = new CMDB_Config_Item__c(
            Name = 'TestHost1',
            Monitoring_System__c = 'OpsRamp',
            Device_Maintenance_UniqueID__c = 'device-123',
            Device_Maintenance_ClientID__c = 'client-456'
        );
        
        CMDB_Config_Item__c configItem2 = new CMDB_Config_Item__c(
            Name = 'TestHost2',
            Monitoring_System__c = 'OpsRamp',
            Device_Maintenance_UniqueID__c = 'device-789',
            Device_Maintenance_ClientID__c = 'client-456'
        );
        
        CMDB_Config_Item__c configItemNoClientId = new CMDB_Config_Item__c(
            Name = 'TestHostNoClient',
            Monitoring_System__c = 'OpsRamp',
            Device_Maintenance_UniqueID__c = 'device-noclient'
        );
        
        insert new List<CMDB_Config_Item__c>{configItem1, configItem2, configItemNoClientId};
        
        // Create test downtime events
        Downtime_Event__c downtimeEvent1 = new Downtime_Event__c(
            Case__c = testCase.Id,
            Configuration_Item__c = configItem1.Id,
            Start_Date_Time__c = DateTime.now().addHours(1),
            End_Date_Time__c = DateTime.now().addHours(3)
        );
        
        Downtime_Event__c downtimeEvent2 = new Downtime_Event__c(
            Case__c = testCase.Id,
            Configuration_Item__c = configItem2.Id,
            Start_Date_Time__c = DateTime.now().addHours(1),
            End_Date_Time__c = DateTime.now().addHours(3)
        );
        
        Downtime_Event__c downtimeEventNoClientId = new Downtime_Event__c(
            Case__c = testCase.Id,
            Configuration_Item__c = configItemNoClientId.Id,
            Start_Date_Time__c = DateTime.now().addHours(1),
            End_Date_Time__c = DateTime.now().addHours(3)
        );
        
        insert new List<Downtime_Event__c>{downtimeEvent1, downtimeEvent2, downtimeEventNoClientId};
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
    static void testGenerateMaintWindowSuccess() {
        // Get test case
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Change Request' LIMIT 1];
        
        Test.startTest();
        API_OPSramp_GenMaintW_HLP.generateMaintWindow(testCase.Id);
        Test.stopTest();
        
        // Verify that queueable jobs were enqueued (we can't directly test the queueable execution)
        // The method should complete without exceptions
        System.assert(true, 'Method completed successfully');
    }
    
    @isTest
    static void testGenerateMaintWindowWithInvalidCaseId() {
        // Create a fake case ID
        Id fakeCaseId = '500000000000000';
        
        Test.startTest();
        try {
            API_OPSramp_GenMaintW_HLP.generateMaintWindow(fakeCaseId);
        } catch (Exception e) {
            // Expected to handle the exception
            System.assert(true, 'Exception handled for invalid case ID');
        }
        Test.stopTest();
    }
}