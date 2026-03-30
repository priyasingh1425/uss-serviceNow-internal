/*************************************************
* Name: API_OPSramp_GenMaintW_UTL_Test
* Description: Test class for API_OPSramp_GenMaintW_UTL utility classes
* ***********************************************/
@isTest
public class API_OPSramp_GenMaintW_UTL_Test {
    
    @isTest
    static void testApexDowntimeEventClass() {
        // Test ApexDowntimeEvent class instantiation and property setting
        API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent event = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
        
        event.caseId = 'test-case-id';
        event.configurationId = 'test-config-id';
        event.startDateTime = DateTime.now();
        event.endDateTime = DateTime.now().addHours(2);
        event.deviceMaintenanceUniqueId = 'test-device-id';
        event.clientId = 'test-client-id';
        event.hostName = 'test-hostname';
        event.caseNumber = 'CR-001';
        
        System.assertEquals('test-case-id', event.caseId, 'Case ID should be set correctly');
        System.assertEquals('test-config-id', event.configurationId, 'Configuration ID should be set correctly');
        System.assertNotEquals(null, event.startDateTime, 'Start date time should be set');
        System.assertNotEquals(null, event.endDateTime, 'End date time should be set');
        System.assertEquals('test-device-id', event.deviceMaintenanceUniqueId, 'Device maintenance unique ID should be set correctly');
        System.assertEquals('test-client-id', event.clientId, 'Client ID should be set correctly');
        System.assertEquals('test-hostname', event.hostName, 'Host name should be set correctly');
        System.assertEquals('CR-001', event.caseNumber, 'Case number should be set correctly');
    }
    
    @isTest
    static void testCaseHolderClass() {
        // Test CaseHolder class instantiation and property setting
        API_OPSramp_GenMaintW_UTL.CaseHolder caseHolder = new API_OPSramp_GenMaintW_UTL.CaseHolder();
        
        // Test default values
        System.assertEquals('OPS - Monitoring', caseHolder.caseGroup, 'Default case group should be OPS - Monitoring');
        System.assertEquals(false, caseHolder.isBulk, 'Default isBulk should be false');
        System.assertEquals('API_OPSramp_GenMaintWin process failed.', caseHolder.subject, 'Default subject should be set');
        System.assertEquals('', caseHolder.description, 'Default description should be empty string');
        
        // Test setting custom values
        caseHolder.ownerID = 'test-owner-id';
        caseHolder.supportQueue = 'Custom Queue';
        caseHolder.caseGroup = 'Custom Group';
        caseHolder.isBulk = true;
        caseHolder.subject = 'Custom Subject';
        caseHolder.description = 'Custom Description';
        
        System.assertEquals('test-owner-id', caseHolder.ownerID, 'Owner ID should be set correctly');
        System.assertEquals('Custom Queue', caseHolder.supportQueue, 'Support queue should be set correctly');
        System.assertEquals('Custom Group', caseHolder.caseGroup, 'Case group should be set correctly');
        System.assertEquals(true, caseHolder.isBulk, 'Is bulk should be set correctly');
        System.assertEquals('Custom Subject', caseHolder.subject, 'Subject should be set correctly');
        System.assertEquals('Custom Description', caseHolder.description, 'Description should be set correctly');
    }
    
    @isTest
    static void testHelpCaseHolderClass() {
        // Test HelpCaseHolder class instantiation and property setting
        API_OPSramp_GenMaintW_UTL.HelpCaseHolder helpCaseHolder = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
        
        // Test default values
        System.assertEquals('API_OPSramp_GenMaintWin process failed with errors.', helpCaseHolder.subject, 'Default subject should be set');
        System.assertEquals('Medium', helpCaseHolder.casePriority, 'Default case priority should be Medium');
        System.assertEquals(null, helpCaseHolder.description, 'Default description should be null');
        
        // Test setting custom values
        helpCaseHolder.subject = 'Custom Help Subject';
        helpCaseHolder.description = 'Custom Help Description';
        helpCaseHolder.casePriority = 'High';
        
        System.assertEquals('Custom Help Subject', helpCaseHolder.subject, 'Subject should be set correctly');
        System.assertEquals('Custom Help Description', helpCaseHolder.description, 'Description should be set correctly');
        System.assertEquals('High', helpCaseHolder.casePriority, 'Case priority should be set correctly');
    }
    
    @isTest
    static void testAllUtilityClassesTogether() {
        // Test creating and using all utility classes together
        List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> events = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
        List<API_OPSramp_GenMaintW_UTL.CaseHolder> cases = new List<API_OPSramp_GenMaintW_UTL.CaseHolder>();
        List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder> helpCases = new List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder>();
        
        // Create downtime event
        API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent event = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
        event.caseId = 'case-123';
        event.clientId = 'client-456';
        events.add(event);
        
        // Create case holder
        API_OPSramp_GenMaintW_UTL.CaseHolder caseHolder = new API_OPSramp_GenMaintW_UTL.CaseHolder();
        caseHolder.description = 'Test case description';
        cases.add(caseHolder);
        
        // Create help case holder
        API_OPSramp_GenMaintW_UTL.HelpCaseHolder helpCaseHolder = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
        helpCaseHolder.description = 'Test help case description';
        helpCases.add(helpCaseHolder);
        
        System.assertEquals(1, events.size(), 'Should have one event');
        System.assertEquals(1, cases.size(), 'Should have one case');
        System.assertEquals(1, helpCases.size(), 'Should have one help case');
        System.assertEquals('case-123', events[0].caseId, 'Event case ID should match');
        System.assertEquals('Test case description', cases[0].description, 'Case description should match');
        System.assertEquals('Test help case description', helpCases[0].description, 'Help case description should match');
    }
}