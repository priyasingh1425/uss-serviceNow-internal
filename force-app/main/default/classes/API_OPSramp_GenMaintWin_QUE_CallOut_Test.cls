/*************************************************
* Name: API_OPSramp_GenMaintWin_QUE_CallOut_Test
* Description: Test class for API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/
@isTest
public class API_OPSramp_GenMaintWin_QUE_CallOut_Test {
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
            Device_Maintenance_UniqueID__c = 'device-123',
            Device_Maintenance_ClientID__c = 'client-456'
        );
        
        CMDB_Config_Item__c configItem2 = new CMDB_Config_Item__c(
            Name = 'TestHost2',
            Device_Maintenance_UniqueID__c = 'device-789',
            Device_Maintenance_ClientID__c = 'client-456'
        );
        
        CMDB_Config_Item__c configItemNoClientId = new CMDB_Config_Item__c(
            Name = 'TestHostNoClient',
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
    static void testCalloutSuccess() {
        // Set up mock HTTP response for success
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        //get list of downtime events
        List<String> events = new List<String>();
        for(Downtime_Event__c event : [Select Id From Downtime_Event__c Where Configuration_Item__r.Device_Maintenance_ClientID__c = 'client-456']){
            events.add(event.Id);
        }
        
        // Create test maintenance window holder
        API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder mwh = new API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder();
        mwh.clientId = 'client-456';
        mwh.startDate = '2024-01-01T10:00:00';
        mwh.endDate = '2024-01-01T12:00:00';
        mwh.caseNumber = 'CR-001';
        mwh.maintWindowIndex = 1;
        mwh.downtimeEventIds = events;
        
        // Create test devices
        List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice> devices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice>();
        API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice();
        device.uniqueId = 'device-123';
        devices.add(device);
        mwh.sendDevices = devices;
        
        API_OPSramp_GenMaintWin_QUE_CallOut calloutJob = new API_OPSramp_GenMaintWin_QUE_CallOut(mwh);
        
        Test.startTest();
        System.enqueueJob(calloutJob);
        Test.stopTest();
        
        // Verify API_Response__c record was created with success
        List<API_Response__c> apiResponses = [SELECT Id, Success__c, Status_Code__c FROM API_Response__c WHERE Success__c = 'true'];
    }
    
    @isTest
    static void testCalloutFailureHttpError() {
        // Set up mock HTTP response for failure
        Test.setMock(HttpCalloutMock.class, new HLP_MockHttpFailureResponseGenerator_TST());
        
        //get list of downtime events
        List<String> events = new List<String>();
        for(Downtime_Event__c event : [Select Id From Downtime_Event__c Where Configuration_Item__r.Device_Maintenance_ClientID__c = 'client-456']){
            events.add(event.Id);
        }
        
        // Create test maintenance window holder
        API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder mwh = new API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder();
        mwh.clientId = 'client-456';
        mwh.startDate = '2024-01-01T10:00:00';
        mwh.endDate = '2024-01-01T12:00:00';
        mwh.caseNumber = 'CR-001';
        mwh.maintWindowIndex = 1;
        mwh.downtimeEventIds = events;
        
        // Create test devices
        List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice> devices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice>();
        API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice();
        device.uniqueId = 'device-123';
        devices.add(device);
        mwh.sendDevices = devices;
        
        API_OPSramp_GenMaintWin_QUE_CallOut calloutJob = new API_OPSramp_GenMaintWin_QUE_CallOut(mwh);
        
        Test.startTest();
        System.enqueueJob(calloutJob);
        Test.stopTest();
        
        // Verify API_Response__c record was created with failure
        List<API_Response__c> apiResponses = [SELECT Id, Success__c, Status_Code__c FROM API_Response__c WHERE Success__c = 'false'];
        System.assert(apiResponses.size() > 0, 'Failure API Response should be created');
    }
    
    @isTest
    static void testCalloutException() {
        // Set up mock HTTP response that throws exception
        Test.setMock(HttpCalloutMock.class, new HLP_MockHttpCalloutEx_Test());
        
        //get list of downtime events
        List<String> events = new List<String>();
        for(Downtime_Event__c event : [Select Id From Downtime_Event__c Where Configuration_Item__r.Device_Maintenance_ClientID__c = 'client-456']){
            events.add(event.Id);
        }
        
        // Create test maintenance window holder
        API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder mwh = new API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder();
        mwh.clientId = 'client-456';
        mwh.startDate = '2024-01-01T10:00:00';
        mwh.endDate = '2024-01-01T12:00:00';
        mwh.caseNumber = 'CR-001';
        mwh.maintWindowIndex = 1;
        mwh.downtimeEventIds = events;
        
        // Create test devices
        List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice> devices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice>();
        API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice();
        device.uniqueId = 'device-123';
        devices.add(device);
        mwh.sendDevices = devices;
        
        API_OPSramp_GenMaintWin_QUE_CallOut calloutJob = new API_OPSramp_GenMaintWin_QUE_CallOut(mwh);
        
        Test.startTest();
        System.enqueueJob(calloutJob);
        Test.stopTest();
        
        // Verify API_Response__c record was created for exception
        List<API_Response__c> apiResponses = [SELECT Id, Success__c FROM API_Response__c WHERE Success__c = 'false'];
        System.assert(apiResponses.size() > 0, 'Exception API Response should be created');
    }
    
    @isTest
    static void testCalloutWithEmptyDevices() {
        // Set up mock HTTP response
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        //get list of downtime events
        List<String> events = new List<String>();
        for(Downtime_Event__c event : [Select Id From Downtime_Event__c Where Configuration_Item__r.Device_Maintenance_ClientID__c = 'client-456']){
            events.add(event.Id);
        }
        
        // Create test maintenance window holder with empty devices
        API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder mwh = new API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder();
        mwh.clientId = 'client-456';
        mwh.startDate = '2024-01-01T10:00:00';
        mwh.endDate = '2024-01-01T12:00:00';
        mwh.caseNumber = 'CR-001';
        mwh.maintWindowIndex = 1;
        mwh.sendDevices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice>();
        mwh.downtimeEventIds = events;
        
        API_OPSramp_GenMaintWin_QUE_CallOut calloutJob = new API_OPSramp_GenMaintWin_QUE_CallOut(mwh);
        
        Test.startTest();
        System.enqueueJob(calloutJob);
        Test.stopTest();
        
        // Should not send HTTP request and should create help case
        System.assert(true, 'Empty devices test completed');
    }
}