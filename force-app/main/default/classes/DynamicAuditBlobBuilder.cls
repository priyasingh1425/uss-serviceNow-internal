public with sharing class DynamicAuditBlobBuilder {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public SObject inputRecord;
    }

    public class OutputWrapper {
        @InvocableVariable
        public String auditBlob;
    }

    @InvocableMethod(label='Build Audit Blob' description='Concatenates populated fields into a single text blob with optional trimming')
    public static List<OutputWrapper> buildAuditBlob(List<InputWrapper> inputList) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        final Integer BLOB_LIMIT = 131000;
        final String NOTICE = 'This blob was trimmed to fit and is not the full blob. ';
        final Integer NOTICE_LENGTH = NOTICE.length();

        for (InputWrapper input : inputList) {
            Map<String, Object> populatedFields = input.inputRecord.getPopulatedFieldsAsMap();
            String auditBlobText = '';

            for (String fieldName : populatedFields.keySet()) {
                Object fieldValue = populatedFields.get(fieldName);
                auditBlobText += fieldName + ': ' + String.valueOf(fieldValue) + ' | ';
            }

            // Trim trailing separator
            if (auditBlobText.endsWith(' | ')) {
                auditBlobText = auditBlobText.substring(0, auditBlobText.length() - 3);
            }

            // Check length and trim if needed
            if (auditBlobText.length() > BLOB_LIMIT) {
                auditBlobText = NOTICE + auditBlobText.substring(0, BLOB_LIMIT - NOTICE_LENGTH);
            }

            OutputWrapper result = new OutputWrapper();
            result.auditBlob = auditBlobText;

            results.add(result);
        }

        return results;
    }
}