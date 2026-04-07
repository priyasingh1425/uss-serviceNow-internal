@isTest
private class CityIntegrationConstantsTest {

    @isTest
    static void test_getAccountId_customSettingPopulated_returnsSettingValue() {
        Account acc = new Account(Name = 'Constants Test Account');
        insert acc;

        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Account_Id__c = acc.Id
        );
        insert settings;

        Test.startTest();
        Id result = CityIntegrationConstants.ACCOUNT_ID;
        Test.stopTest();

        System.assertEquals(acc.Id, result,
            'ACCOUNT_ID should return the Account Id stored in custom settings');
    }

    @isTest
    static void test_getContactName_customSettingPopulated_returnsSettingValue() {
        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Contact_Name__c = 'Custom Contact Name'
        );
        insert settings;

        Test.startTest();
        String result = CityIntegrationConstants.CONTACT_NAME;
        Test.stopTest();

        System.assertEquals('Custom Contact Name', result,
            'CONTACT_NAME should return the value from custom settings when populated');
    }

    @isTest
    static void test_getQueueTOC_customSettingPopulated_returnsSettingValue() {
        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Queue_Name__c = 'Custom Queue'
        );
        insert settings;

        Test.startTest();
        String result = CityIntegrationConstants.QUEUE_TOC;
        Test.stopTest();

        System.assertEquals('Custom Queue', result,
            'QUEUE_TOC should return the value from custom settings when populated');
    }

    @isTest
    static void test_getSupportQueueTOC_customSettingPopulated_returnsSettingValue() {
        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Support_Queue_Name__c = 'Custom Support Queue'
        );
        insert settings;

        Test.startTest();
        String result = CityIntegrationConstants.SUPPORT_QUEUE_TOC;
        Test.stopTest();

        System.assertEquals('Custom Support Queue', result,
            'SUPPORT_QUEUE_TOC should return the value from custom settings when populated');
    }

    @isTest
    static void test_getAccountId_customSettingMissing_returnsNull() {
        Test.startTest();
        Id result = CityIntegrationConstants.ACCOUNT_ID;
        Test.stopTest();

        System.assertEquals(null, result,
            'ACCOUNT_ID should return null when custom setting Account_Id__c is not configured');
    }

    @isTest
    static void test_getContactName_customSettingMissing_returnsFallback() {
        Test.startTest();
        String result = CityIntegrationConstants.CONTACT_NAME;
        Test.stopTest();

        System.assertEquals('City Of Minneapolis Service Desk', result,
            'CONTACT_NAME should fall back to the hardcoded default when custom settings are absent');
    }

    @isTest
    static void test_getQueueTOC_customSettingMissing_returnsFallback() {
        Test.startTest();
        String result = CityIntegrationConstants.QUEUE_TOC;
        Test.stopTest();

        System.assertEquals('TOC Queue', result,
            'QUEUE_TOC should fall back to "TOC Queue" when custom settings are absent');
    }

    @isTest
    static void test_getSupportQueueTOC_customSettingMissing_returnsFallback() {
        Test.startTest();
        String result = CityIntegrationConstants.SUPPORT_QUEUE_TOC;
        Test.stopTest();

        System.assertEquals('TOC Support', result,
            'SUPPORT_QUEUE_TOC should fall back to "TOC Support" when custom settings are absent');
    }

    @isTest
    static void test_getPriorityLabel_validNumber1_returnsUrgent() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('1');
        Test.stopTest();

        System.assertEquals('Urgent', result,
            'Priority number "1" should map to label "Urgent"');
    }

    @isTest
    static void test_getPriorityLabel_validNumber2_returnsHigh() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('2');
        Test.stopTest();

        System.assertEquals('High', result,
            'Priority number "2" should map to label "High"');
    }

    @isTest
    static void test_getPriorityLabel_validNumber3_returnsMedium() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('3');
        Test.stopTest();

        System.assertEquals('Medium', result,
            'Priority number "3" should map to label "Medium"');
    }

    @isTest
    static void test_getPriorityLabel_validNumber4_returnsLow() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('4');
        Test.stopTest();

        System.assertEquals('Low', result,
            'Priority number "4" should map to label "Low"');
    }

    @isTest
    static void test_getPriorityLabel_numberWithSpaces_trimmingReturnsLabel() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel(' 1 ');
        Test.stopTest();

        System.assertEquals('Urgent', result,
            'getPriorityLabel should trim whitespace before lookup');
    }

    @isTest
    static void test_getPriorityLabel_nullInput_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel(null);
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityLabel(null) should return an empty string');
    }

    @isTest
    static void test_getPriorityLabel_blankInput_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('   ');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityLabel with blank spaces should return an empty string');
    }

    @isTest
    static void test_getPriorityLabel_emptyString_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityLabel with empty string should return an empty string');
    }

    @isTest
    static void test_getPriorityLabel_invalidNumber_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('99');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityLabel with unmapped number "99" should return an empty string');
    }

    @isTest
    static void test_getPriorityLabel_nonNumericInput_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityLabel('critical');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityLabel with a non-numeric string should return an empty string');
    }

    @isTest
    static void test_getPriorityNumber_lowercaseLabel_returnsNumber() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('low');
        Test.stopTest();

        System.assertEquals('4', result,
            'Priority label "low" should map to number "4"');
    }

    @isTest
    static void test_getPriorityNumber_mediumLabel_returnsNumber() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('medium');
        Test.stopTest();

        System.assertEquals('3', result,
            'Priority label "medium" should map to number "3"');
    }

    @isTest
    static void test_getPriorityNumber_highLabel_returnsNumber() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('high');
        Test.stopTest();

        System.assertEquals('2', result,
            'Priority label "high" should map to number "2"');
    }

    @isTest
    static void test_getPriorityNumber_urgentLabel_returnsNumber() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('urgent');
        Test.stopTest();

        System.assertEquals('1', result,
            'Priority label "urgent" should map to number "1"');
    }

    @isTest
    static void test_getPriorityNumber_mixedCaseLabel_returnsNumber() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('UrGeNt');
        Test.stopTest();

        System.assertEquals('1', result,
            'getPriorityNumber should be case-insensitive');
    }

    @isTest
    static void test_getPriorityNumber_nullInput_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber(null);
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityNumber(null) should return an empty string');
    }

    @isTest
    static void test_getPriorityNumber_blankInput_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('   ');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityNumber with blank spaces should return an empty string');
    }

    @isTest
    static void test_getPriorityNumber_emptyString_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityNumber with empty string should return an empty string');
    }

    @isTest
    static void test_getPriorityNumber_invalidLabel_returnsEmptyString() {
        Test.startTest();
        String result = CityIntegrationConstants.getPriorityNumber('Unknown Priority');
        Test.stopTest();

        System.assertEquals('', result,
            'getPriorityNumber with unmapped label should return an empty string');
    }

    @isTest
    static void test_constants_accountStatusActive_isAccessible() {
        Test.startTest();
        String result = CityIntegrationConstants.ACCOUNT_STATUS_ACTIVE;
        Test.stopTest();

        System.assertEquals('Active', result,
            'ACCOUNT_STATUS_ACTIVE constant should be "Active"');
    }

    @isTest
    static void test_constants_recordTypeDevNames_areAccessible() {
        Test.startTest();
        String rtChangeRequest  = CityIntegrationConstants.RT_CHANGE_REQUEST;
        String rtExtCustSupport = CityIntegrationConstants.RT_EXTERNAL_CUSTOMER_SUPPORT;
        String rtChangeReqLabel = CityIntegrationConstants.RT_CHANGE_REQUEST_LABEL;
        String rtExtCustLabel   = CityIntegrationConstants.RT_EXTERNAL_CUSTOMER_SUPPORT_LABEL;
        Test.stopTest();

        System.assertEquals('Change_Request', rtChangeRequest,
            'RT_CHANGE_REQUEST should be "Change_Request"');
        System.assertEquals('External_Customer_Support', rtExtCustSupport,
            'RT_EXTERNAL_CUSTOMER_SUPPORT should be "External_Customer_Support"');
        System.assertEquals('Change Request', rtChangeReqLabel,
            'RT_CHANGE_REQUEST_LABEL should be "Change Request"');
        System.assertEquals('External Customer Support', rtExtCustLabel,
            'RT_EXTERNAL_CUSTOMER_SUPPORT_LABEL should be "External Customer Support"');
    }

    @isTest
    static void test_constants_stringConstants_areAccessible() {
        Test.startTest();
        String origin      = CityIntegrationConstants.ORIGIN_API;
        String prefixInc   = CityIntegrationConstants.PREFIX_INCIDENT;
        String prefixChg   = CityIntegrationConstants.PREFIX_CHANGE;
        String prefixCtask = CityIntegrationConstants.PREFIX_CHANGE_TASK;
        Test.stopTest();

        System.assertEquals('API', origin, 'ORIGIN_API should be "API"');
        System.assertEquals('INC', prefixInc, 'PREFIX_INCIDENT should be "INC"');
        System.assertEquals('CHG', prefixChg, 'PREFIX_CHANGE should be "CHG"');
        System.assertEquals('CTASK', prefixCtask, 'PREFIX_CHANGE_TASK should be "CTASK"');
    }

    @isTest
    static void test_constants_statusValues_areAccessible() {
        Test.startTest();
        String statusNew      = CityIntegrationConstants.STATUS_NEW;
        String statusResolved = CityIntegrationConstants.STATUS_RESOLVED;
        String statusClosed   = CityIntegrationConstants.STATUS_CLOSED;
        String statusReopen   = CityIntegrationConstants.STATUS_REOPEN;
        String statusParked   = CityIntegrationConstants.STATUS_PARKED;
        String statusReason   = CityIntegrationConstants.STATUS_REASON_WAITING;
        Test.stopTest();

        System.assertEquals('New', statusNew, 'STATUS_NEW should be "New"');
        System.assertEquals('Resolved', statusResolved, 'STATUS_RESOLVED should be "Resolved"');
        System.assertEquals('Closed', statusClosed, 'STATUS_CLOSED should be "Closed"');
        System.assertEquals('Reopen', statusReopen, 'STATUS_REOPEN should be "Reopen"');
        System.assertEquals('Parked', statusParked, 'STATUS_PARKED should be "Parked"');
        System.assertEquals('Waiting for Customer', statusReason, 'STATUS_REASON_WAITING should be "Waiting for Customer"');
    }

    @isTest
    static void test_constants_maxFeedItems_isAccessible() {
        Test.startTest();
        Integer result = CityIntegrationConstants.MAX_FEEDITEMS_PER_QUEUEABLE;
        Test.stopTest();

        System.assertEquals(90, result,
            'MAX_FEEDITEMS_PER_QUEUEABLE should be 90');
    }

    @isTest
    static void test_constants_eligiblePriorities_containsExpectedValues() {
        Test.startTest();
        Set<String> result = CityIntegrationConstants.ELIGIBLE_PRIORITIES;
        Test.stopTest();

        System.assertEquals(3, result.size(),
            'ELIGIBLE_PRIORITIES should contain exactly 3 values');
        System.assert(result.contains('Medium'),
            'ELIGIBLE_PRIORITIES should contain "Medium"');
        System.assert(result.contains('High'),
            'ELIGIBLE_PRIORITIES should contain "High"');
        System.assert(result.contains('Urgent'),
            'ELIGIBLE_PRIORITIES should contain "Urgent"');
        System.assert(!result.contains('Low'),
            'ELIGIBLE_PRIORITIES should NOT contain "Low"');
    }

    @isTest
    static void test_constants_priorityMaps_containExpectedSize() {
        Test.startTest();
        Map<String, String> numToLabel = CityIntegrationConstants.PRIORITY_NUMBER_TO_LABEL;
        Map<String, String> labelToNum = CityIntegrationConstants.PRIORITY_LABEL_TO_NUMBER;
        Test.stopTest();

        System.assertEquals(4, numToLabel.size(),
            'PRIORITY_NUMBER_TO_LABEL should contain 4 mappings');
        System.assertEquals(4, labelToNum.size(),
            'PRIORITY_LABEL_TO_NUMBER should contain 4 mappings');

        System.assertEquals('Urgent', numToLabel.get('1'), 'Map should map "1" to "Urgent"');
        System.assertEquals('1', labelToNum.get('urgent'), 'Map should map "urgent" to "1"');
    }

    @isTest
    static void test_constants_accountRTCustomer_isAccessible() {
        Test.startTest();
        String result = CityIntegrationConstants.ACCOUNT_RT_CUSTOMER;
        Test.stopTest();

        System.assertEquals('Customer', result,
            'ACCOUNT_RT_CUSTOMER should be "Customer"');
    }
}
