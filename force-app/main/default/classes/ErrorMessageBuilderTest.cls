@isTest
private class ErrorMessageBuilderTest {

    @isTest
    static void test_build_nullError_returnsGenericMessage() {
        Test.startTest();
        String result = ErrorMessageBuilder.build(null);
        Test.stopTest();

        System.assertEquals(
            'Unable to process the request due to an unknown error.',
            result,
            'Passing null should return the generic unknown error message'
        );
    }

    @isTest
    static void test_build_requiredFieldMissing_returnsFieldList() {
        Account acc = new Account();
        Database.SaveResult sr = Database.insert(acc, false);

        if (!sr.isSuccess()) {
            Database.Error err = sr.getErrors()[0];

            if (err.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING) {
                Test.startTest();
                String result = ErrorMessageBuilder.build(err);
                Test.stopTest();

                System.assert(result.startsWith('Missing or invalid required information:'),
                    'REQUIRED_FIELD_MISSING should return message starting with "Missing or invalid required information:"');
                System.assert(result.contains('Name'),
                    'Message should reference the missing required field "Name"');
                return;
            }
        }

        Contact con = new Contact();
        Database.SaveResult sr2 = Database.insert(con, false);

        System.assert(!sr2.isSuccess(),
            'Contact insert without LastName should fail');

        Database.Error err2 = sr2.getErrors()[0];

        Test.startTest();
        String result2 = ErrorMessageBuilder.build(err2);
        Test.stopTest();

        System.assert(result2 != null && result2.length() > 0,
            'build() should return a non-empty message for a DML error');
    }

    @isTest
    static void test_build_duplicateValue_returnsFormattedMessage() {
        String errorJson = '{"statusCode":"DUPLICATE_VALUE","message":"duplicate value found","fields":[]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assertEquals(
            'A record with the same information already exists.',
            result,
            'DUPLICATE_VALUE should return the duplicate record message'
        );
    }

    @isTest
    static void test_build_unableToLockRow_returnsFormattedMessage() {
        String errorJson = '{"statusCode":"UNABLE_TO_LOCK_ROW","message":"unable to obtain exclusive access","fields":[]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assertEquals(
            'The record is currently being updated by another process. Please try again.',
            result,
            'UNABLE_TO_LOCK_ROW should return the lock-row retry message'
        );
    }

    @isTest
    static void test_build_insufficientAccess_returnsFormattedMessage() {
        String errorJson = '{"statusCode":"INSUFFICIENT_ACCESS_OR_READONLY","message":"insufficient access rights","fields":[]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assertEquals(
            'You do not have permission to perform this action.',
            result,
            'INSUFFICIENT_ACCESS_OR_READONLY should return the permission-denied message'
        );
    }

    @isTest
    static void test_build_customValidation_returnsFormattedMessage() {
        String errorJson = '{"statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION","message":"Amount must be greater than zero","fields":["Amount"]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assert(result.startsWith('The record does not meet business validation rules:'),
            'FIELD_CUSTOM_VALIDATION_EXCEPTION should start with the validation rules prefix');
        System.assert(result.contains('Amount must be greater than zero'),
            'Message should contain the original validation error message');
    }

    @isTest
    static void test_build_unknownStatusWithFields_returnsFieldsFallback() {
        String errorJson = '{"statusCode":"INVALID_FIELD","message":"Invalid field: Foo__c","fields":["Foo__c","Bar__c"]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assert(result.startsWith('Unable to save the record. Fields with issues:'),
            'Unknown status with fields should return the fields-fallback message');
        System.assert(result.contains('Foo__c'),
            'Message should list the first problematic field');
        System.assert(result.contains('Bar__c'),
            'Message should list the second problematic field');
        System.assert(result.contains('Invalid field: Foo__c'),
            'Message should include the detail from err.getMessage()');
    }

    @isTest
    static void test_build_unknownStatusNoFields_returnsCatchAll() {
        String errorJson = '{"statusCode":"UNKNOWN_EXCEPTION","message":"Something went wrong internally.","fields":[]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assert(result.startsWith('Unable to save the record due to a system validation error:'),
            'Unknown status without fields should return the catch-all message');
        System.assert(result.contains('Something went wrong internally.'),
            'Catch-all message should include the original error message');
    }

    @isTest
    static void test_build_realDmlError_returnsNonEmptyMessage() {
        Contact con = new Contact();
        Database.SaveResult sr = Database.insert(con, false);

        System.assert(!sr.isSuccess(),
            'Contact insert without LastName should fail');
        System.assert(!sr.getErrors().isEmpty(),
            'There should be at least one Database.Error');

        Database.Error err = sr.getErrors()[0];

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'build() should never return null for a real DML error');
        System.assert(result.length() > 0,
            'build() should return a non-empty message for a real DML error');
    }

    @isTest
    static void test_build_requiredFieldMissing_multipleFields_joinsCorrectly() {
        String errorJson = '{"statusCode":"REQUIRED_FIELD_MISSING","message":"Required fields are missing","fields":["AccountId","ContactId","Subject"]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assert(result.startsWith('Missing or invalid required information:'),
            'REQUIRED_FIELD_MISSING should return the required-fields prefix');
        System.assert(result.contains('AccountId'),
            'Message should include the first missing field');
        System.assert(result.contains('ContactId'),
            'Message should include the second missing field');
        System.assert(result.contains('Subject'),
            'Message should include the third missing field');
    }

    @isTest
    static void test_build_customValidation_emptyMessage_handlesGracefully() {
        String errorJson = '{"statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION","message":"","fields":[]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assert(result.startsWith('The record does not meet business validation rules:'),
            'Even with an empty message, the prefix should be present');
    }

    @isTest
    static void test_build_catchAll_specialCharacters_preserved() {
        String specialMsg = 'Error: <field> "Name" & \'value\' are invalid';
        String errorJson = '{"statusCode":"UNKNOWN_EXCEPTION","message":"' + specialMsg.replace('"', '\\"') + '","fields":[]}';
        Database.Error err = (Database.Error) JSON.deserialize(errorJson, Database.Error.class);

        Test.startTest();
        String result = ErrorMessageBuilder.build(err);
        Test.stopTest();

        System.assert(result.contains(specialMsg),
            'Special characters in the error message should be preserved verbatim');
    }
}
