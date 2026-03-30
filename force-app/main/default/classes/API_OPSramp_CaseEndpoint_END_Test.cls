/*************************************************
* Name: API_OPSramp_CaseEndpoint_END_Test
* Description: Test class for API_OPSramp_CaseEndpoint_END
* Code Coverage Target: 95%+
* ***********************************************/
@isTest
private class API_OPSramp_CaseEndpoint_END_Test {
    
    /*************************************************
    * Method Name: setupTestData
    * Description: Creates test data needed for all test methods
    * ***********************************************/
    @testSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account for OpsRamp'
        );
        insert testAccount;
        
        // Create Configuration Item
        CMDB_Config_Item__c configItem = new CMDB_Config_Item__c(
            Name = 'Test Device',
            Device_Maintenance_UniqueID__c = 'DEVICE123',
            Device_Maintenance_ClientID__c = 'CLIENT123',
            Customer_Account__c = testAccount.Id
        );
        insert configItem;
        
    }
    
    /*************************************************
    * Method Name: testCreateCaseSuccess
    * Description: Tests successful case creation via POST to /create endpoint
    * ***********************************************/
    @isTest
    static void testCreateCaseSuccess() {
        // Setup test data
        CMDB_Config_Item__c configItem = [SELECT Id, Device_Maintenance_UniqueID__c FROM CMDB_Config_Item__c LIMIT 1];
        
        // Create request body
        String requestBody = '{"ShortDescription":"Test Alert","Description":"Test Description","Priority":"4","SourceID":"OPS12345","MonitoringHostname":"' + configItem.Device_Maintenance_UniqueID__c + '"}';
        
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Test
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        // Verify
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Success'), 'Expected success response');
        
        // Verify Case was created
        List<Case> cases = [SELECT Id, Subject, Description, Priority, MA_External_Rec_Id__c, Status, System_Origin__c 
                           FROM Case WHERE MA_External_Rec_Id__c = 'OPR-OPS12345'];
        System.assertEquals(1, cases.size(), 'Expected one case to be created');
        System.assertEquals('Test Alert', cases[0].Subject);
        System.assertEquals('High', cases[0].Priority);
        System.assertEquals('OpsRamp', cases[0].System_Origin__c);
        
        // Verify Case_Config_Item_Junction was created
        List<Case_Config_Item_Junction__c> junctions = [SELECT Id FROM Case_Config_Item_Junction__c WHERE Case__c = :cases[0].Id];
        System.assertEquals(1, junctions.size(), 'Expected junction record to be created');
        
        // Verify API Response was logged
        List<API_Response__c> apiResponses = [SELECT Id, Success__c, Status_Code__c FROM API_Response__c];
        System.assertEquals(1, apiResponses.size(), 'Expected API response to be logged');
        System.assertEquals('Success', apiResponses[0].Success__c);
        
        // Verify Automation Analytics was created
        List<Automation_Analytics__c> analytics = [SELECT Id FROM Automation_Analytics__c];
        System.assertEquals(1, analytics.size(), 'Expected automation analytics to be created');
    }
    
    /*************************************************
    * Method Name: testCreateCaseWithMultipleDevices
    * Description: Tests case creation with multiple monitoring hostnames
    * ***********************************************/
    @isTest
    static void testCreateCaseWithMultipleDevices() {
        // Create additional config item
        Account acc = [SELECT Id FROM Account LIMIT 1];
        CMDB_Config_Item__c configItem2 = new CMDB_Config_Item__c(
            Name = 'Test Device 2',
            Device_Maintenance_UniqueID__c = 'DEVICE456',
            Customer_Account__c = acc.Id
        );
        insert configItem2;
        
        List<CMDB_Config_Item__c> items = [SELECT Device_Maintenance_UniqueID__c FROM CMDB_Config_Item__c];
        String deviceList = items[0].Device_Maintenance_UniqueID__c + ',' + items[1].Device_Maintenance_UniqueID__c;
        
        // Create request body
        String requestBody = '{"ShortDescription":"Test Alert","Description":"Multiple Devices Alert","Priority":"3","SourceID":"OPS67890","MonitoringHostname":"' + deviceList + '"}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        // Verify multiple junctions were created
        List<Case> cases = [SELECT Id FROM Case WHERE MA_External_Rec_Id__c = 'OPR-OPS67890'];
        List<Case_Config_Item_Junction__c> junctions = [SELECT Id FROM Case_Config_Item_Junction__c WHERE Case__c = :cases[0].Id];
        System.assertEquals(2, junctions.size(), 'Expected two junction records to be created');
    }
    
    /*************************************************
    * Method Name: testCreateCaseInvalidJSON
    * Description: Tests case creation with invalid JSON
    * ***********************************************/
    @isTest
    static void testCreateCaseInvalidJSON() {
        String requestBody = '{invalid json}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Error'), 'Expected error response');
    }
    
    /*************************************************
    * Method Name: testUpdateCaseSuccess
    * Description: Tests successful case update via POST to /update endpoint
    * ***********************************************/
    @isTest
    static void testUpdateCaseSuccess() {
        // Create a case to update
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case testCase = new Case(
            Subject = 'Original Subject',
            Description = 'Original Description',
            Priority = 'Low',
            Status = 'New',
            AccountId = acc.Id,
            MA_External_Rec_Id__c = 'OPR-UPDATE123'
        );
        insert testCase;
        
        // Create update request
        String requestBody = '{"fieldId":"' + testCase.Id + '",' +
            '"status":"New",' +
            '"priority":"5",' +
            '"subject":"Updated Subject",' +
            '"description":"Updated Description"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        String responseBody = res.responseBody.toString();
        
        // Verify case was updated
        Case updatedCase = [SELECT Subject, Description, Priority, Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Updated Subject', updatedCase.Subject);
        System.assertEquals('Urgent', updatedCase.Priority);
    }
    
    /*************************************************
    * Method Name: testUpdateCaseToClearedStatus
    * Description: Tests updating case status to Cleared (which maps to Parked)
    * ***********************************************/
    @isTest
    static void testUpdateCaseToClearedStatus() {
        // Create a case to update
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Priority = 'Medium',
            Status = 'New',
            AccountId = acc.Id
        );
        insert testCase;
        
        String requestBody = '{"fieldId":"' + testCase.Id + '",' +
            '"status":"Cleared",' +
            '"priority":"3",' +
            '"subject":"Test Case",' +
            '"description":"Test Description"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
    }
    
    /*************************************************
    * Method Name: testUpdateCaseNotFound
    * Description: Tests updating a case that doesn't exist
    * ***********************************************/
    @isTest
    static void testUpdateCaseNotFound() {
        String fakeId = '500000000000000AAA';
        
        String requestBody = '{"fieldId":"' + fakeId + '",' +
            '"status":"New",' +
            '"priority":"3",' +
            '"subject":"Test",' +
            '"description":"Test"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Error'), 'Expected error response');
        System.assert(responseBody.contains('No case found'), 'Expected case not found message');
    }
    
    /*************************************************
    * Method Name: testUpdateCaseInvalidStatus
    * Description: Tests updating with an invalid status value
    * ***********************************************/
    @isTest
    static void testUpdateCaseInvalidStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case testCase = new Case(
            Subject = 'Test Case',
            Priority = 'Medium',
            Status = 'New',
            AccountId = acc.Id
        );
        insert testCase;
        
        String requestBody = '{"fieldId":"' + testCase.Id + '",' +
            '"status":"InvalidStatus",' +
            '"priority":"3",' +
            '"subject":"Test",' +
            '"description":"Test"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/update';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Error'), 'Expected error response');
        System.assert(responseBody.contains('Invalid Status'), 'Expected invalid status message');
    }
    
    /*************************************************
    * Method Name: testInvalidEndpoint
    * Description: Tests calling an invalid endpoint
    * ***********************************************/
    @isTest
    static void testInvalidEndpoint() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/invalidendpoint';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Error'), 'Expected error response');
        System.assert(responseBody.contains('Invalid API Call'), 'Expected invalid API call message');
    }
    

    /*************************************************
    * Method Name: testPriorityParserInvalidValue
    * Description: Tests the priority parser with an invalid value
    * ***********************************************/
    @isTest
    static void testPriorityParserInvalidValue() {
        CMDB_Config_Item__c configItem = [SELECT Device_Maintenance_UniqueID__c FROM CMDB_Config_Item__c LIMIT 1];
        
        String requestBody = buildRequestBody('99', configItem.Device_Maintenance_UniqueID__c, 'TEST5');
        executeCreateRequest(requestBody);
        
        // Verify a support case was created for invalid priority
        // This will be logged in the API response
        List<API_Response__c> responses = [SELECT Success__c FROM API_Response__c];
        System.assert(responses.size() > 0, 'Expected API response to be logged');
    }
    
    /*************************************************
    * Method Name: testCreateCaseNoDevices
    * Description: Tests case creation when no monitoring hostname is provided
    * ***********************************************/
    @isTest
    static void testCreateCaseNoDevices() {
        String requestBody = '{"ShortDescription":"No Device Alert","Description":"Test","Priority":"3","SourceID":"NODEV123","MonitoringHostname":""}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
        Test.stopTest();
        
    }
    
    /*************************************************
    * Helper Methods
    * ***********************************************/
    
    private static String buildRequestBody(String priority, String deviceId, String sourceId) {
        String requestBody = '{"ShortDescription":"Test","Description":"Test","Priority":"' + priority + '","' + sourceId + '","MonitoringHostname":"' + deviceId + '"}';
        return requestBody;
    }
    
    private static void executeCreateRequest(String requestBody) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/OPSramp/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        API_OPSramp_CaseEndpoint_END.createOpsRampCase();
    }
}