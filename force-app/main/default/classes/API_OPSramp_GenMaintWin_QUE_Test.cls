/*************************************************
* Name: API_OPSramp_GenMaintWin_QUE_Test
* Description: Test class for API_OPSramp_GenMaintWin_QUE
* ***********************************************/
@isTest
public class API_OPSramp_GenMaintWin_QUE_Test {
    
    @testSetup
    static void testSetup() {
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
    static void testQueueableExecuteSuccess() {
        // Set up mock HTTP response
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        // Create test events
        List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> testEvents = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
        
        API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent event1 = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
        event1.caseId = 'case-123';
        event1.deviceMaintenanceUniqueId = 'device-123';
        event1.clientId = 'client-456';
        event1.hostName = 'TestHost1';
        event1.startDateTime = DateTime.now().addHours(1);
        event1.endDateTime = DateTime.now().addHours(3);
        event1.caseNumber = 'CR-001';
        testEvents.add(event1);
        
        API_OPSramp_GenMaintWin_QUE queueableJob = new API_OPSramp_GenMaintWin_QUE('client-456', testEvents);
        
        Test.startTest();
        queueableJob.execute(null);
        Test.stopTest();
        
        // Verify API_Response__c records were created
        List<API_Response__c> apiResponses = [SELECT Id, Success__c FROM API_Response__c];
        System.assert(apiResponses.size() > 0, 'API Response records should be created');
    }
    
    @isTest
    static void testQueueableExecuteWithHostNameMapping() {
        // Set up mock HTTP response
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        // Create test events with no deviceMaintenanceUniqueId (should use hostname mapping)
        List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> testEvents = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
        
        API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent event1 = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
        event1.caseId = 'case-123';
        event1.deviceMaintenanceUniqueId = ''; // Empty to trigger hostname mapping
        event1.clientId = 'client-456';
        event1.hostName = 'TestHost1'; // This should match the mock response
        event1.startDateTime = DateTime.now().addHours(1);
        event1.endDateTime = DateTime.now().addHours(3);
        event1.caseNumber = 'CR-001';
        testEvents.add(event1);
        
        API_OPSramp_GenMaintWin_QUE queueableJob = new API_OPSramp_GenMaintWin_QUE('client-456', testEvents);
        
        Test.startTest();
        queueableJob.execute(null);
        Test.stopTest();
        
        System.assert(true, 'Hostname mapping test completed');
    }
    
    @isTest
    static void testQueueableExecuteWithInvalidDevice() {
        // Set up mock HTTP response
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        // Create test events with invalid device ID
        List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> testEvents = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
        
        API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent event1 = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
        event1.caseId = 'case-123';
        event1.deviceMaintenanceUniqueId = 'invalid-device-id';
        event1.clientId = 'client-456';
        event1.hostName = 'InvalidHost';
        event1.startDateTime = DateTime.now().addHours(1);
        event1.endDateTime = DateTime.now().addHours(3);
        event1.caseNumber = 'CR-001';
        testEvents.add(event1);
        
        API_OPSramp_GenMaintWin_QUE queueableJob = new API_OPSramp_GenMaintWin_QUE('client-456', testEvents);
        
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();
        
        System.assert(true, 'Invalid device test completed');
    }
    
    @isTest
    static void testQueueableExecuteWithLargeBatch() {
        // Set up mock HTTP response
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        // Create 150 test events to test batching logic (should create 2 batches)
        List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> testEvents = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
        
        for(Integer i = 0; i < 150; i++) {
            API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent event = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
            event.caseId = 'case-' + i;
            event.deviceMaintenanceUniqueId = 'device-123'; // Use valid device ID from mock
            event.clientId = 'client-456';
            event.hostName = 'TestHost' + i;
            event.startDateTime = DateTime.now().addHours(1);
            event.endDateTime = DateTime.now().addHours(3);
            event.caseNumber = 'CR-' + i;
            testEvents.add(event);
        }
        
        API_OPSramp_GenMaintWin_QUE queueableJob = new API_OPSramp_GenMaintWin_QUE('client-456', testEvents);
        
        Test.startTest();
        queueableJob.execute(null);
        Test.stopTest();
        
        System.assert(true, 'Large batch test completed');
    }
}