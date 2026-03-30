public with sharing class INV_DedupeByIdFlowAction_UTL {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public List<SObject> records;

        @InvocableVariable(required=true)
        public String fieldName;
    }

    public class OutputWrapper {
        @InvocableVariable
        public List<SObject> uniqueRecords;

        public OutputWrapper(List<SObject> records) {
            this.uniqueRecords = records;
        }
    }

    @InvocableMethod
    public static List<OutputWrapper> dedupe(List<InputWrapper> inputList) {
        List<SObject> output = new List<SObject>();
        Set<Id> seenIds = new Set<Id>();

        try {
            if (inputList == null || inputList.isEmpty() || inputList[0].records == null || inputList[0].fieldName == null) {
                return new List<OutputWrapper>{ new OutputWrapper(output) };
            }

            String field = inputList[0].fieldName;

            for (SObject record : inputList[0].records) {
                if (record == null) continue;

                Object fieldValue = record.get(field);
                if (fieldValue != null && fieldValue instanceof Id) {
                    Id relatedId = (Id)fieldValue;
                    if (seenIds.add(relatedId)) {
                        output.add(record);
                    }
                }
            }

        } catch (Exception ex) {
            // Log the error as a support case
            HLP_Case_SFQueue_Ins.createSFQueueCase(
                'Error in INV_DedupeByIdFlowAction_UTL.dedupe',
                'Exception: ' + ex.getMessage() + '\nStack Trace: ' + ex.getStackTraceString(),
                'High'
            );
        }

        return new List<OutputWrapper>{ new OutputWrapper(output) };
    }
}