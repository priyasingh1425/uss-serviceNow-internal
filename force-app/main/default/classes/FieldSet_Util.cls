public with sharing class FieldSet_Util {

    @AuraEnabled(cacheable=true)
    public static FieldSet getFieldSet(String objectName, String fieldSetName){
        try {
            return new FieldSet(Schema.getGlobalDescribe().get(objectName).getDescribe().fieldsets.getMap().get(fieldSetName));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class FieldSet{
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public List<String> fields;

        public FieldSet(Schema.FieldSet sFieldSet){
            label = sFieldSet.label;
            name = sFieldSet.name;
            fields = new List<String>();
            for(Schema.FieldSetMember field:sFieldSet.fields){
                fields.add(field.fieldpath);
            }
        }
    }

}