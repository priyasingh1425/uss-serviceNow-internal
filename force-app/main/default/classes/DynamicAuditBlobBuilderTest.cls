@IsTest
public class DynamicAuditBlobBuilderTest {

    @IsTest
    static void testBuildAuditBlobWithCase_NoTrim() {
        // This test checks a small payload that does not get trimmed

        Id caseRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'External Customer Support' LIMIT 1].Id;

        Case testCase = new Case(
            Subject = 'Short Subject',
            Description = 'Short Description',
            Priority = 'Medium',
            Origin = 'Phone',
            RecordTypeId = caseRecordTypeId,
            Support_Queue__c = 'TOC Support'
        );

        DynamicAuditBlobBuilder.InputWrapper input = new DynamicAuditBlobBuilder.InputWrapper();
        input.inputRecord = testCase;

        List<DynamicAuditBlobBuilder.InputWrapper> inputs = new List<DynamicAuditBlobBuilder.InputWrapper>{ input };

        List<DynamicAuditBlobBuilder.OutputWrapper> outputs = DynamicAuditBlobBuilder.buildAuditBlob(inputs);

        System.assertEquals(1, outputs.size(), 'Should return one output');
        String resultBlob = outputs[0].auditBlob;

        System.debug('No-Trim Blob: ' + resultBlob);

        System.assert(resultBlob != null && resultBlob.length() > 0, 'Blob should not be empty');
        System.assert(!resultBlob.startsWith('This blob was trimmed'), 'Blob should not include trim notice');
    }

    @IsTest
    static void testBuildAuditBlobWithCase_Trimmed() {
        // This test checks a huge payload that WILL get trimmed

        Id caseRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'External Customer Support' LIMIT 1].Id;

        // Create an intentionally large string
        String longDescription = 'A'.repeat(150000);

        Case testCase = new Case(
            Subject = 'Big Subject',
            Description = longDescription,
            Priority = 'High',
            Origin = 'Email',
            RecordTypeId = caseRecordTypeId,
            Support_Queue__c = 'TOC Support'
        );

        DynamicAuditBlobBuilder.InputWrapper input = new DynamicAuditBlobBuilder.InputWrapper();
        input.inputRecord = testCase;

        List<DynamicAuditBlobBuilder.InputWrapper> inputs = new List<DynamicAuditBlobBuilder.InputWrapper>{ input };

        List<DynamicAuditBlobBuilder.OutputWrapper> outputs = DynamicAuditBlobBuilder.buildAuditBlob(inputs);

        System.assertEquals(1, outputs.size(), 'Should return one output');
        String resultBlob = outputs[0].auditBlob;

        System.debug('Trimmed Blob: ' + resultBlob);

        System.assert(resultBlob.startsWith('This blob was trimmed to fit and is not the full blob'), 'Trim notice should be included');
        System.assert(resultBlob.length() <= 131000, 'Trimmed blob should be under the limit');
    }
}