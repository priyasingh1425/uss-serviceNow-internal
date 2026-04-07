@isTest
private class MPLResponseTest {

    @isTest
    static void test_incidentSuccess_validInputs_constructsProperly() {
        String msg        = 'Case successfully created';
        String id         = '500000000000001';
        String caseNumber = '00001234';

        Test.startTest();
        MPLResponse result = MPLResponse.incidentSuccess(msg, id, caseNumber);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" for incidentSuccess');
        System.assertEquals(msg, result.message,
            'message should match the provided msg parameter');
        System.assertEquals(id, result.recordId,
            'recordId should match the provided id parameter');
        System.assertEquals(caseNumber, result.IncidentID,
            'IncidentID should be set to the caseNumber parameter');
        System.assertEquals(id, result.IncidentRecID,
            'IncidentRecID should be set to the id parameter');
        System.assertNotEquals(null, result.Messages,
            'Messages list should be initialized');
        System.assertEquals(1, result.Messages.size(),
            'Messages list should contain exactly one entry');
        System.assertEquals(msg, result.Messages[0],
            'Messages[0] should match the provided msg parameter');
        System.assertEquals(null, result.LogID,
            'LogID should be null by design');
    }

    @isTest
    static void test_success_twoParams_constructsProperly() {
        String msg = 'Case resolved successfully';
        String id  = '500000000000002';

        Test.startTest();
        MPLResponse result = MPLResponse.success(msg, id);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success"');
        System.assertEquals(msg, result.message,
            'message should match the provided msg parameter');
        System.assertEquals(id, result.recordId,
            'recordId should match the provided id parameter');
        System.assertEquals(id, result.IncidentID,
            'IncidentID should be set to the id parameter for the two-param overload');
        System.assertEquals(id, result.IncidentRecID,
            'IncidentRecID should be set to the id parameter for the two-param overload');
        System.assertNotEquals(null, result.Messages,
            'Messages list should be initialized');
        System.assertEquals(1, result.Messages.size(),
            'Messages list should contain exactly one entry');
        System.assertEquals(null, result.ChangeID,
            'ChangeID should remain null for the two-param success overload');
        System.assertEquals(null, result.ChangeRecID,
            'ChangeRecID should remain null for the two-param success overload');
        System.assertEquals(null, result.JournalNoteRecID,
            'JournalNoteRecID should remain null for the two-param success overload');
    }

    @isTest
    static void test_success_threeParams_typeChange_assignsChangeIds() {
        String msg = 'Change request created';
        String id  = '500000000000003';

        Test.startTest();
        MPLResponse result = MPLResponse.success(msg, id, 'CHANGE');
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success"');
        System.assertEquals(msg, result.message,
            'message should match the provided msg parameter');
        System.assertEquals(id, result.recordId,
            'recordId should match the provided id parameter');
        System.assertEquals(id, result.ChangeID,
            'ChangeID should be set to the id parameter when responseType is CHANGE');
        System.assertEquals(id, result.ChangeRecID,
            'ChangeRecID should be set to the id parameter when responseType is CHANGE');
        System.assertEquals(null, result.JournalNoteRecID,
            'JournalNoteRecID should remain null when responseType is CHANGE');
        System.assertEquals(null, result.IncidentID,
            'IncidentID should remain null when responseType is CHANGE');
        System.assertEquals(null, result.IncidentRecID,
            'IncidentRecID should remain null when responseType is CHANGE');
    }

    @isTest
    static void test_success_threeParams_typeWorknote_assignsJournalNote() {
        String msg = 'Notes created successfully';
        String id  = '0D5000000000001';

        Test.startTest();
        MPLResponse result = MPLResponse.success(msg, id, 'WORKNOTE');
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success"');
        System.assertEquals(msg, result.message,
            'message should match the provided msg parameter');
        System.assertEquals(id, result.recordId,
            'recordId should match the provided id parameter');
        System.assertEquals(id, result.JournalNoteRecID,
            'JournalNoteRecID should be set to the id parameter when responseType is WORKNOTE');
        System.assertEquals(null, result.ChangeID,
            'ChangeID should remain null when responseType is WORKNOTE');
        System.assertEquals(null, result.ChangeRecID,
            'ChangeRecID should remain null when responseType is WORKNOTE');
    }

    @isTest
    static void test_successChange_validInputs_constructsProperly() {
        String msg         = 'Change request approved';
        String changeId    = '00001234';
        String changeRecId = '500000000000004';

        Test.startTest();
        MPLResponse result = MPLResponse.successChange(msg, changeId, changeRecId);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" for successChange');
        System.assertEquals(msg, result.message,
            'message should match the provided msg parameter');
        System.assertEquals(changeRecId, result.recordId,
            'recordId should be set to the changeRecId parameter');
        System.assertEquals(changeId, result.ChangeID,
            'ChangeID should be set to the changeId parameter');
        System.assertEquals(changeRecId, result.ChangeRecID,
            'ChangeRecID should be set to the changeRecId parameter');
        System.assertNotEquals(null, result.Messages,
            'Messages list should be initialized');
        System.assertEquals(1, result.Messages.size(),
            'Messages list should contain exactly one entry');
        System.assertEquals(msg, result.Messages[0],
            'Messages[0] should match the provided msg parameter');
        System.assertEquals(null, result.LogID,
            'LogID should be null by design');
    }

    @isTest
    static void test_error_constructsErrorPayload() {
        String msg = 'Missing action parameter';

        Test.startTest();
        MPLResponse result = MPLResponse.error(msg);
        Test.stopTest();

        System.assertEquals('error', result.status,
            'status should be "error" for the error factory method');
        System.assertEquals(msg, result.message,
            'message should match the provided error message');
        System.assertEquals(null, result.recordId,
            'recordId should be null for error responses');
        System.assertEquals(null, result.Messages,
            'Messages list should be null for error responses (not initialized)');
        System.assertEquals(null, result.IncidentID,
            'IncidentID should be null for error responses');
        System.assertEquals(null, result.IncidentRecID,
            'IncidentRecID should be null for error responses');
        System.assertEquals(null, result.ChangeID,
            'ChangeID should be null for error responses');
        System.assertEquals(null, result.ChangeRecID,
            'ChangeRecID should be null for error responses');
        System.assertEquals(null, result.JournalNoteRecID,
            'JournalNoteRecID should be null for error responses');
        System.assertEquals(null, result.LogID,
            'LogID should be null for error responses');
    }

    @isTest
    static void test_success_threeParams_unknownType_ignoresSpecialBinding() {
        String msg = 'Generic success';
        String id  = '500000000000005';

        Test.startTest();
        MPLResponse result = MPLResponse.success(msg, id, 'TASK');
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" even with an unknown responseType');
        System.assertEquals(msg, result.message,
            'message should match the provided msg parameter');
        System.assertEquals(id, result.recordId,
            'recordId should match the provided id parameter');
        System.assertEquals(null, result.ChangeID,
            'ChangeID should remain null for unknown responseType');
        System.assertEquals(null, result.ChangeRecID,
            'ChangeRecID should remain null for unknown responseType');
        System.assertEquals(null, result.JournalNoteRecID,
            'JournalNoteRecID should remain null for unknown responseType');
        System.assertEquals(null, result.IncidentID,
            'IncidentID should remain null for unknown responseType (three-param overload does not set it)');
    }

    @isTest
    static void test_incidentSuccess_nullInputs_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.incidentSuccess(null, null, null);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should still be "success" even with null inputs');
        System.assertEquals(null, result.message,
            'message should be null when null msg is passed');
        System.assertEquals(null, result.recordId,
            'recordId should be null when null id is passed');
        System.assertEquals(null, result.IncidentID,
            'IncidentID should be null when null caseNumber is passed');
        System.assertEquals(null, result.IncidentRecID,
            'IncidentRecID should be null when null id is passed');
        System.assertNotEquals(null, result.Messages,
            'Messages list should still be initialized even with null msg');
        System.assertEquals(1, result.Messages.size(),
            'Messages list should contain one entry (the null value)');
        System.assertEquals(null, result.Messages[0],
            'Messages[0] should be null when null msg is passed');
    }

    @isTest
    static void test_success_twoParams_nullInputs_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.success(null, null);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" even with null inputs');
        System.assertEquals(null, result.message,
            'message should be null when null msg is passed');
        System.assertEquals(null, result.recordId,
            'recordId should be null when null id is passed');
        System.assertEquals(null, result.IncidentID,
            'IncidentID should be null when null id is passed');
        System.assertEquals(null, result.IncidentRecID,
            'IncidentRecID should be null when null id is passed');
    }

    @isTest
    static void test_success_threeParams_nullResponseType_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.success('Test', '001', null);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" even with null responseType');
        System.assertEquals(null, result.ChangeID,
            'ChangeID should remain null when responseType is null');
        System.assertEquals(null, result.ChangeRecID,
            'ChangeRecID should remain null when responseType is null');
        System.assertEquals(null, result.JournalNoteRecID,
            'JournalNoteRecID should remain null when responseType is null');
    }

    @isTest
    static void test_successChange_nullInputs_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.successChange(null, null, null);
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" even with all-null inputs');
        System.assertEquals(null, result.message,
            'message should be null when null msg is passed');
        System.assertEquals(null, result.recordId,
            'recordId should be null when null changeRecId is passed');
        System.assertEquals(null, result.ChangeID,
            'ChangeID should be null when null changeId is passed');
        System.assertEquals(null, result.ChangeRecID,
            'ChangeRecID should be null when null changeRecId is passed');
    }

    @isTest
    static void test_error_nullMessage_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.error(null);
        Test.stopTest();

        System.assertEquals('error', result.status,
            'status should be "error" even with a null message');
        System.assertEquals(null, result.message,
            'message should be null when null is passed to error()');
    }

    @isTest
    static void test_incidentSuccess_emptyStrings_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.incidentSuccess('', '', '');
        Test.stopTest();

        System.assertEquals('success', result.status,
            'status should be "success" even with empty string inputs');
        System.assertEquals('', result.message,
            'message should be empty string when empty msg is passed');
        System.assertEquals('', result.recordId,
            'recordId should be empty string when empty id is passed');
        System.assertEquals('', result.IncidentID,
            'IncidentID should be empty string when empty caseNumber is passed');
        System.assertEquals('', result.IncidentRecID,
            'IncidentRecID should be empty string when empty id is passed');
    }

    @isTest
    static void test_error_emptyMessage_handlesGracefully() {
        Test.startTest();
        MPLResponse result = MPLResponse.error('');
        Test.stopTest();

        System.assertEquals('error', result.status,
            'status should be "error" even with an empty message');
        System.assertEquals('', result.message,
            'message should be empty string when empty string is passed');
    }

    @isTest
    static void test_multipleCalls_returnIndependentInstances() {
        Test.startTest();
        MPLResponse r1 = MPLResponse.error('Error One');
        MPLResponse r2 = MPLResponse.error('Error Two');
        MPLResponse r3 = MPLResponse.success('Success', '001');
        Test.stopTest();

        System.assertEquals('Error One', r1.message,
            'First error instance should retain its own message');
        System.assertEquals('Error Two', r2.message,
            'Second error instance should retain its own message');
        System.assertEquals('success', r3.status,
            'Success instance should be independent of error instances');
        System.assert(r1 !== r2,
            'Each call should return a distinct MPLResponse instance');
        System.assert(r2 !== r3,
            'Error and success calls should return distinct instances');
    }

    @isTest
    static void test_error_specialCharactersInMessage_handlesGracefully() {
        String specialMsg = 'Error: <script>alert("xss")</script> & "quotes" \' backslash\\';

        Test.startTest();
        MPLResponse result = MPLResponse.error(specialMsg);
        Test.stopTest();

        System.assertEquals('error', result.status,
            'status should be "error"');
        System.assertEquals(specialMsg, result.message,
            'message should preserve special characters verbatim');
    }
}
