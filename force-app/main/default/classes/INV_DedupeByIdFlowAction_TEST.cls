@isTest
private class INV_DedupeByIdFlowAction_TEST {

    @isTest
    static void testDedupeByConfigItemField() {
        CMDB_Config_Item__c ci1 = new CMDB_Config_Item__c(Name = 'CI-1');
        CMDB_Config_Item__c ci2 = new CMDB_Config_Item__c(Name = 'CI-2');
        insert new List<CMDB_Config_Item__c>{ ci1, ci2 };

        Case_Config_Item_Junction__c j1 = new Case_Config_Item_Junction__c(CMDB_Config_Item__c = ci1.Id);
        Case_Config_Item_Junction__c j2 = new Case_Config_Item_Junction__c(CMDB_Config_Item__c = ci2.Id);
        Case_Config_Item_Junction__c j3 = new Case_Config_Item_Junction__c(CMDB_Config_Item__c = ci1.Id); // duplicate
        insert new List<Case_Config_Item_Junction__c>{ j1, j2, j3 };

        List<SObject> inputRecords = new List<SObject>{ j1, j2, j3 };

        INV_DedupeByIdFlowAction_UTL.InputWrapper input = new INV_DedupeByIdFlowAction_UTL.InputWrapper();
        input.records = inputRecords;
        input.fieldName = 'CMDB_Config_Item__c';

        Test.startTest();
        List<INV_DedupeByIdFlowAction_UTL.OutputWrapper> result =
            INV_DedupeByIdFlowAction_UTL.dedupe(new List<INV_DedupeByIdFlowAction_UTL.InputWrapper>{ input });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(2, result[0].uniqueRecords.size());

        Set<Id> seen = new Set<Id>();
        for (SObject s : result[0].uniqueRecords) {
            Id relatedCI = (Id)s.get('CMDB_Config_Item__c');
            System.assertNotEquals(null, relatedCI);
            seen.add(relatedCI);
        }

        System.assert(seen.contains(ci1.Id));
        System.assert(seen.contains(ci2.Id));
    }

    @isTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        // Null input list
        List<INV_DedupeByIdFlowAction_UTL.OutputWrapper> result1 =
            INV_DedupeByIdFlowAction_UTL.dedupe(null);
        System.assertEquals(0, result1[0].uniqueRecords.size());

        // Empty input list
        List<INV_DedupeByIdFlowAction_UTL.OutputWrapper> result2 =
            INV_DedupeByIdFlowAction_UTL.dedupe(new List<INV_DedupeByIdFlowAction_UTL.InputWrapper>());
        System.assertEquals(0, result2[0].uniqueRecords.size());

        // Null field name
        INV_DedupeByIdFlowAction_UTL.InputWrapper input = new INV_DedupeByIdFlowAction_UTL.InputWrapper();
        input.records = new List<SObject>();
        input.fieldName = null;
        List<INV_DedupeByIdFlowAction_UTL.OutputWrapper> result3 =
            INV_DedupeByIdFlowAction_UTL.dedupe(new List<INV_DedupeByIdFlowAction_UTL.InputWrapper>{ input });
        System.assertEquals(0, result3[0].uniqueRecords.size());
        Test.stopTest();
    }

@isTest
static void testNonIdFieldValue() {
    SObject fakeRecord = new Account(Name = 'Test Account'); // Use a standard object
    fakeRecord.put('Name', 'ABC'); // Not an Id

    INV_DedupeByIdFlowAction_UTL.InputWrapper input = new INV_DedupeByIdFlowAction_UTL.InputWrapper();
    input.records = new List<SObject>{ fakeRecord };
    input.fieldName = 'Name'; // Not an Id field

    Test.startTest();
    List<INV_DedupeByIdFlowAction_UTL.OutputWrapper> result =
        INV_DedupeByIdFlowAction_UTL.dedupe(new List<INV_DedupeByIdFlowAction_UTL.InputWrapper>{ input });
    Test.stopTest();

    System.assertEquals(0, result[0].uniqueRecords.size());
}

    @isTest
    static void testForceCatchBlockWithInvalidField() {
        // Create a valid object
        CMDB_Config_Item__c ci = new CMDB_Config_Item__c(Name = 'CI');
        insert ci;

        Case_Config_Item_Junction__c j = new Case_Config_Item_Junction__c(CMDB_Config_Item__c = ci.Id);
        insert j;

        INV_DedupeByIdFlowAction_UTL.InputWrapper input = new INV_DedupeByIdFlowAction_UTL.InputWrapper();
        input.records = new List<SObject>{ j };
        input.fieldName = 'This_Field_Does_Not_Exist__c'; // Force exception

        Test.startTest();
        List<INV_DedupeByIdFlowAction_UTL.OutputWrapper> result =
            INV_DedupeByIdFlowAction_UTL.dedupe(new List<INV_DedupeByIdFlowAction_UTL.InputWrapper>{ input });
        Test.stopTest();

        System.assertEquals(0, result[0].uniqueRecords.size());
    }
}