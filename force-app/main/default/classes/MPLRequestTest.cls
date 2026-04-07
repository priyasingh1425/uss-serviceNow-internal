@isTest
private class MPLRequestTest {

    @isTest
    static void test_CreateIncident_properties_canBeSetAndRead() {
        Test.startTest();
        MPLRequest.CreateIncident req = new MPLRequest.CreateIncident();
        req.Description      = 'Server outage in DC-1';
        req.ShortDescription = 'DC-1 Outage';
        req.Priority         = '1';
        req.APITicketID      = 'INC0012345';
        req.Category         = 'break fix';
        req.Subcategory      = 'Hardware';
        Test.stopTest();

        System.assertEquals('Server outage in DC-1', req.Description,
            'Description should match the assigned value');
        System.assertEquals('DC-1 Outage', req.ShortDescription,
            'ShortDescription should match the assigned value');
        System.assertEquals('1', req.Priority,
            'Priority should match the assigned value');
        System.assertEquals('INC0012345', req.APITicketID,
            'APITicketID should match the assigned value');
        System.assertEquals('break fix', req.Category,
            'Category should match the assigned value');
        System.assertEquals('Hardware', req.Subcategory,
            'Subcategory should match the assigned value');
    }

    @isTest
    static void test_CreateWorkNote_properties_canBeSetAndRead() {
        Test.startTest();
        MPLRequest.CreateWorkNote req = new MPLRequest.CreateWorkNote();
        req.ParentRecID = '500000000000001';
        req.Details     = 'Technician dispatched to site.';
        Test.stopTest();

        System.assertEquals('500000000000001', req.ParentRecID,
            'ParentRecID should match the assigned value');
        System.assertEquals('Technician dispatched to site.', req.Details,
            'Details should match the assigned value');
    }

    @isTest
    static void test_ResolveIncident_properties_canBeSetAndRead() {
        Test.startTest();
        MPLRequest.ResolveIncident req = new MPLRequest.ResolveIncident();
        req.IncidentRecID    = '500000000000002';
        req.CloseDescription = 'Root cause identified and fixed.';
        Test.stopTest();

        System.assertEquals('500000000000002', req.IncidentRecID,
            'IncidentRecID should match the assigned value');
        System.assertEquals('Root cause identified and fixed.', req.CloseDescription,
            'CloseDescription should match the assigned value');
    }

    @isTest
    static void test_ReopenIncident_properties_canBeSetAndRead() {
        Test.startTest();
        MPLRequest.ReopenIncident req = new MPLRequest.ReopenIncident();
        req.IncidentRecID = '500000000000003';
        Test.stopTest();

        System.assertEquals('500000000000003', req.IncidentRecID,
            'IncidentRecID should match the assigned value');
    }

    @isTest
    static void test_ChangeRequestTask_properties_canBeSetAndRead() {
        Test.startTest();
        MPLRequest.ChangeRequestTask task = new MPLRequest.ChangeRequestTask();
        task.Title              = 'Pre-check connectivity';
        task.Description        = 'Verify all links';
        task.Type               = 'Implementation';
        task.Priority           = '2';
        task.ScheduledStartDate = '2026-04-01 08:00:00';
        task.ScheduledEndDate   = '2026-04-01 10:00:00';
        task.APITicketID        = 'CTASK0012345';
        Test.stopTest();

        System.assertEquals('Pre-check connectivity', task.Title,
            'Title should match the assigned value');
        System.assertEquals('Verify all links', task.Description,
            'Description should match the assigned value');
        System.assertEquals('Implementation', task.Type,
            'Type should match the assigned value');
        System.assertEquals('2', task.Priority,
            'Priority should match the assigned value');
        System.assertEquals('2026-04-01 08:00:00', task.ScheduledStartDate,
            'ScheduledStartDate should match the assigned value');
        System.assertEquals('2026-04-01 10:00:00', task.ScheduledEndDate,
            'ScheduledEndDate should match the assigned value');
        System.assertEquals('CTASK0012345', task.APITicketID,
            'APITicketID should match the assigned value');
    }

    @isTest
    static void test_CreateChangeRequest_properties_canBeSetAndRead() {
        MPLRequest.ChangeRequestTask task1 = new MPLRequest.ChangeRequestTask();
        task1.Title       = 'Task Alpha';
        task1.Description = 'Alpha work';
        task1.APITicketID = 'CTASK_A';

        MPLRequest.ChangeRequestTask task2 = new MPLRequest.ChangeRequestTask();
        task2.Title       = 'Task Beta';
        task2.Description = 'Beta work';
        task2.APITicketID = 'CTASK_B';

        Test.startTest();
        MPLRequest.CreateChangeRequest req = new MPLRequest.CreateChangeRequest();
        req.Description        = 'Scheduled router upgrade';
        req.ShortDescription   = 'Router Upgrade';
        req.ScheduledStartDate = '2026-04-01 06:00:00';
        req.ScheduledEndDate   = '2026-04-01 10:00:00';
        req.Priority           = '2';
        req.Type               = 'Normal';
        req.APIChangeID        = 'CHG0012345';
        req.SalesforceID       = '500000000000004';
        req.State              = 'pending deployment';
        req.tasks              = new List<MPLRequest.ChangeRequestTask>{ task1, task2 };
        Test.stopTest();

        System.assertEquals('Scheduled router upgrade', req.Description,
            'Description should match the assigned value');
        System.assertEquals('Router Upgrade', req.ShortDescription,
            'ShortDescription should match the assigned value');
        System.assertEquals('2026-04-01 06:00:00', req.ScheduledStartDate,
            'ScheduledStartDate should match the assigned value');
        System.assertEquals('2026-04-01 10:00:00', req.ScheduledEndDate,
            'ScheduledEndDate should match the assigned value');
        System.assertEquals('2', req.Priority,
            'Priority should match the assigned value');
        System.assertEquals('Normal', req.Type,
            'Type should match the assigned value');
        System.assertEquals('CHG0012345', req.APIChangeID,
            'APIChangeID should match the assigned value');
        System.assertEquals('500000000000004', req.SalesforceID,
            'SalesforceID should match the assigned value');
        System.assertEquals('pending deployment', req.State,
            'State should match the assigned value');
        System.assertNotEquals(null, req.tasks,
            'tasks list should not be null after assignment');
        System.assertEquals(2, req.tasks.size(),
            'tasks list should contain exactly 2 tasks');
        System.assertEquals('Task Alpha', req.tasks[0].Title,
            'First task Title should match');
        System.assertEquals('Task Beta', req.tasks[1].Title,
            'Second task Title should match');
    }

    @isTest
    static void test_CreateIncident_jsonDeserialization_succeeds() {
        String jsonPayload = '{'
            + '"Description": "Network failure",'
            + '"ShortDescription": "Net Down",'
            + '"Priority": "1",'
            + '"APITicketID": "INC0099999",'
            + '"Category": "service request",'
            + '"Subcategory": "Connectivity"'
            + '}';

        Test.startTest();
        MPLRequest.CreateIncident req = (MPLRequest.CreateIncident)
            JSON.deserialize(jsonPayload, MPLRequest.CreateIncident.class);
        Test.stopTest();

        System.assertEquals('Network failure', req.Description,
            'Deserialized Description should match JSON value');
        System.assertEquals('Net Down', req.ShortDescription,
            'Deserialized ShortDescription should match JSON value');
        System.assertEquals('1', req.Priority,
            'Deserialized Priority should match JSON value');
        System.assertEquals('INC0099999', req.APITicketID,
            'Deserialized APITicketID should match JSON value');
        System.assertEquals('service request', req.Category,
            'Deserialized Category should match JSON value');
        System.assertEquals('Connectivity', req.Subcategory,
            'Deserialized Subcategory should match JSON value');
    }

    @isTest
    static void test_CreateChangeRequest_jsonDeserialization_withTasks_succeeds() {
        String jsonPayload = '{'
            + '"Description": "Firmware upgrade",'
            + '"ShortDescription": "FW Upgrade",'
            + '"ScheduledStartDate": "2026-04-01 06:00:00",'
            + '"ScheduledEndDate": "2026-04-01 10:00:00",'
            + '"Priority": "2",'
            + '"Type": "Standard",'
            + '"APIChangeID": "CHG0055555",'
            + '"SalesforceID": "500000000000099",'
            + '"State": "scheduled",'
            + '"tasks": ['
            + '  {"Title": "Backup config", "Description": "Save running config", '
            + '   "Type": "Preparation", "Priority": "3", '
            + '   "ScheduledStartDate": "2026-04-01 06:00:00", '
            + '   "ScheduledEndDate": "2026-04-01 07:00:00", '
            + '   "APITicketID": "CTASK001"},'
            + '  {"Title": "Apply firmware", "Description": "Flash update", '
            + '   "Type": "Implementation", "Priority": "1", '
            + '   "ScheduledStartDate": "2026-04-01 07:00:00", '
            + '   "ScheduledEndDate": "2026-04-01 09:00:00", '
            + '   "APITicketID": "CTASK002"}'
            + ']}';

        Test.startTest();
        MPLRequest.CreateChangeRequest req = (MPLRequest.CreateChangeRequest)
            JSON.deserialize(jsonPayload, MPLRequest.CreateChangeRequest.class);
        Test.stopTest();

        System.assertEquals('Firmware upgrade', req.Description,
            'Deserialized Description should match JSON value');
        System.assertEquals('FW Upgrade', req.ShortDescription,
            'Deserialized ShortDescription should match JSON value');
        System.assertEquals('2', req.Priority,
            'Deserialized Priority should match JSON value');
        System.assertEquals('CHG0055555', req.APIChangeID,
            'Deserialized APIChangeID should match JSON value');
        System.assertEquals('500000000000099', req.SalesforceID,
            'Deserialized SalesforceID should match JSON value');
        System.assertEquals('scheduled', req.State,
            'Deserialized State should match JSON value');

        System.assertNotEquals(null, req.tasks,
            'Deserialized tasks list should not be null');
        System.assertEquals(2, req.tasks.size(),
            'Deserialized tasks list should contain 2 entries');

        System.assertEquals('Backup config', req.tasks[0].Title,
            'First task Title should match JSON value');
        System.assertEquals('CTASK001', req.tasks[0].APITicketID,
            'First task APITicketID should match JSON value');
        System.assertEquals('Preparation', req.tasks[0].Type,
            'First task Type should match JSON value');

        System.assertEquals('Apply firmware', req.tasks[1].Title,
            'Second task Title should match JSON value');
        System.assertEquals('CTASK002', req.tasks[1].APITicketID,
            'Second task APITicketID should match JSON value');
        System.assertEquals('Implementation', req.tasks[1].Type,
            'Second task Type should match JSON value');
    }

    @isTest
    static void test_CreateIncident_nullDefaults() {
        Test.startTest();
        MPLRequest.CreateIncident req = new MPLRequest.CreateIncident();
        Test.stopTest();

        System.assertEquals(null, req.Description,
            'Description should default to null');
        System.assertEquals(null, req.ShortDescription,
            'ShortDescription should default to null');
        System.assertEquals(null, req.Priority,
            'Priority should default to null');
        System.assertEquals(null, req.APITicketID,
            'APITicketID should default to null');
        System.assertEquals(null, req.Category,
            'Category should default to null');
        System.assertEquals(null, req.Subcategory,
            'Subcategory should default to null');
    }

    @isTest
    static void test_CreateWorkNote_nullDefaults() {
        Test.startTest();
        MPLRequest.CreateWorkNote req = new MPLRequest.CreateWorkNote();
        Test.stopTest();

        System.assertEquals(null, req.ParentRecID,
            'ParentRecID should default to null');
        System.assertEquals(null, req.Details,
            'Details should default to null');
    }

    @isTest
    static void test_ResolveIncident_nullDefaults() {
        Test.startTest();
        MPLRequest.ResolveIncident req = new MPLRequest.ResolveIncident();
        Test.stopTest();

        System.assertEquals(null, req.IncidentRecID,
            'IncidentRecID should default to null');
        System.assertEquals(null, req.CloseDescription,
            'CloseDescription should default to null');
    }

    @isTest
    static void test_ReopenIncident_nullDefaults() {
        Test.startTest();
        MPLRequest.ReopenIncident req = new MPLRequest.ReopenIncident();
        Test.stopTest();

        System.assertEquals(null, req.IncidentRecID,
            'IncidentRecID should default to null');
    }

    @isTest
    static void test_CreateChangeRequest_nullDefaults() {
        Test.startTest();
        MPLRequest.CreateChangeRequest req = new MPLRequest.CreateChangeRequest();
        Test.stopTest();

        System.assertEquals(null, req.Description,
            'Description should default to null');
        System.assertEquals(null, req.ShortDescription,
            'ShortDescription should default to null');
        System.assertEquals(null, req.ScheduledStartDate,
            'ScheduledStartDate should default to null');
        System.assertEquals(null, req.ScheduledEndDate,
            'ScheduledEndDate should default to null');
        System.assertEquals(null, req.Priority,
            'Priority should default to null');
        System.assertEquals(null, req.Type,
            'Type should default to null');
        System.assertEquals(null, req.APIChangeID,
            'APIChangeID should default to null');
        System.assertEquals(null, req.SalesforceID,
            'SalesforceID should default to null');
        System.assertEquals(null, req.State,
            'State should default to null');
        System.assertEquals(null, req.tasks,
            'tasks list should default to null');
    }

    @isTest
    static void test_ChangeRequestTask_nullDefaults() {
        Test.startTest();
        MPLRequest.ChangeRequestTask task = new MPLRequest.ChangeRequestTask();
        Test.stopTest();

        System.assertEquals(null, task.Title,
            'Title should default to null');
        System.assertEquals(null, task.Description,
            'Description should default to null');
        System.assertEquals(null, task.Type,
            'Type should default to null');
        System.assertEquals(null, task.Priority,
            'Priority should default to null');
        System.assertEquals(null, task.ScheduledStartDate,
            'ScheduledStartDate should default to null');
        System.assertEquals(null, task.ScheduledEndDate,
            'ScheduledEndDate should default to null');
        System.assertEquals(null, task.APITicketID,
            'APITicketID should default to null');
    }

    @isTest
    static void test_CreateChangeRequest_emptyTasksList() {
        Test.startTest();
        MPLRequest.CreateChangeRequest req = new MPLRequest.CreateChangeRequest();
        req.tasks = new List<MPLRequest.ChangeRequestTask>();
        Test.stopTest();

        System.assertNotEquals(null, req.tasks,
            'tasks list should not be null after explicit empty list assignment');
        System.assertEquals(0, req.tasks.size(),
            'tasks list should be empty');
    }

    @isTest
    static void test_CreateIncident_jsonDeserialization_partialPayload() {
        String jsonPayload = '{"Description": "Partial payload", "Priority": "3"}';

        Test.startTest();
        MPLRequest.CreateIncident req = (MPLRequest.CreateIncident)
            JSON.deserialize(jsonPayload, MPLRequest.CreateIncident.class);
        Test.stopTest();

        System.assertEquals('Partial payload', req.Description,
            'Description should match the partial JSON value');
        System.assertEquals('3', req.Priority,
            'Priority should match the partial JSON value');
        System.assertEquals(null, req.ShortDescription,
            'ShortDescription should be null when omitted from JSON');
        System.assertEquals(null, req.APITicketID,
            'APITicketID should be null when omitted from JSON');
        System.assertEquals(null, req.Category,
            'Category should be null when omitted from JSON');
        System.assertEquals(null, req.Subcategory,
            'Subcategory should be null when omitted from JSON');
    }

    @isTest
    static void test_CreateChangeRequest_jsonDeserialization_noTasks() {
        String jsonPayload = '{"Description": "No tasks", "APIChangeID": "CHG999"}';

        Test.startTest();
        MPLRequest.CreateChangeRequest req = (MPLRequest.CreateChangeRequest)
            JSON.deserialize(jsonPayload, MPLRequest.CreateChangeRequest.class);
        Test.stopTest();

        System.assertEquals('No tasks', req.Description,
            'Description should match the JSON value');
        System.assertEquals('CHG999', req.APIChangeID,
            'APIChangeID should match the JSON value');
        System.assertEquals(null, req.tasks,
            'tasks should be null when omitted from JSON');
    }

    @isTest
    static void test_outerClass_canBeInstantiated() {
        Test.startTest();
        MPLRequest testouter = new MPLRequest();
        Test.stopTest();

        System.assertNotEquals(null, testouter,
            'testouter MPLRequest class should be instantiable');
    }
}
