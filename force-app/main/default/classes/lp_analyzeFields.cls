/**
 * @author Ladd Partners
 * @date 12/9/18
 * @group
*/

public with sharing class lp_analyzeFields {

    public Map<String, Schema.SObjectField> headFieldMap;
    public Map<String, Schema.SObjectField> detailFieldMap;
    public Map<String, Schema.SObjectField> stagefs {get; set;}
    public Map<String, fieldAttributes> headAttrs {get; set;}
    public Map<String, fieldAttributes> detailAttrs {get; set;}


    public lp_analyzeFields(Map<String, Schema.SObjectField> headFieldMap, Map<String, Schema.SObjectField> detailFieldMap) {

        this.headFieldMap = headFieldMap;
        this.detailFieldMap = detailFieldMap;
    }


    public Map<String,Set<String>> mapreferenceToData(SObject[]records) {

        Map<String, Set<String>>objToName = new Map< String, Set<String>>();

        headAttrs = getFieldAttributes(headFieldMap);
        detailAttrs = getFieldAttributes(detailFieldMap);


       for (SObject record : records) {
            SCMImpToolsSO_Stage__c stage = (SCMImpToolsSO_Stage__c) record;
            stage.Error__c = false;
            stage.Error_Message__c = '';
            for (String fieldName : stagefs.keySet()) {
                System.debug('stage field name ' + fieldName);
                lp_analyzeFields.fieldAttributes attr = null;
                lp_analyzeFields.fieldAttributes fieldAttr = headAttrs.get(fieldName);
                System.debug('fieldAttrs in header ' + fieldAttr);
                lp_analyzeFields.fieldAttributes lineAttr = detailAttrs.get(fieldName);
                if (fieldAttr == null &&
                        lineAttr == null) {
                    lp_toolsUtility.setStageError(stage, 'Unknown field ' + fieldName);
                } else if (fieldAttr != null) {
                    attr = fieldAttr;
                } else if (lineAttr != null) {
                    System.debug('lineAttr ' + lineAttr);
                    attr = lineAttr;
                }
                if (attr != null &&
                        attr.isSetable &&
                        attr.fieldType == Schema.DisplayType.REFERENCE) {
                    System.debug('Reference field ' + fieldName);
                    Set<String> keys = objToName.get(attr.lookupName);
                    if (keys == null) {
                        keys = new Set<String>();
                        objToName.put(attr.lookupName, keys);
                    }
                    String stageData = (String) lp_toolsUtility.getData(stagefs,stage, fieldName);
                    if (stageData != null) {
                        keys.add(stageData);
                    }

                }
            }
        }

        return objToName;
    }



    public Map<String, fieldAttributes> getFieldAttributes(Map<String, Schema.SObjectField> fieldMap) {

        Map<String, fieldAttributes> retMap = new Map<String, fieldAttributes>();

        for (SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            System.debug('field we are getting attributes for ' + fieldDesc.getName());
            fieldAttributes attr = new fieldAttributes(fieldDesc.getName(), true);
            //retMap.put(fieldDesc.getName(), attr);
            String rootname = fieldDesc.getName();
            if (isPackaged(fieldDesc.getName())){
                Integer startName = fieldDesc.getName().indexOfIgnoreCase('__');

                rootname = fieldDesc.getName().substring(startName + 2);
                System.debug('namespace end ' + startName + '*' + rootName);

            }
            rootname = rootname.toLowerCase();
            retMap.put(rootname, attr);

            if (fieldDesc.isAutoNumber() ||
                    !fieldDesc.isCreateable() ||
                    fieldDesc.isCalculated() ||
                    fieldDesc.getLabel().contains('deprecated') ||
                    rootname == 'account__c') {
                //can't set autonumber, calculated or not creatable fields
                attr.isSetable = false;
                continue;
            }
            //TODO consider supporting case where reference can point to more than one object type
            //for now just consider field is not settable  e.g. ownerId field
            if (fieldDesc.isNamePointing()){
                attr.isSetable = false;
            }

            attr.fieldType = fieldDesc.getType();
            if (attr.fieldType  == Schema.DisplayType.PICKLIST){
                attr.pickEntries = fieldDesc.getPicklistValues();
            } else if (attr.fieldType == Schema.DisplayType.REFERENCE){
                List <Schema.SObjectType> refTos = fieldDesc.getReferenceTo();
                if (refTos.size() > 0) {
                    attr.referenceTo = refTos[0];
                    Schema.DescribeSObjectResult lookupObj = attr.referenceTo.getDescribe();
                    attr.lookupName = lookupObj.getName();
                }
            }
            System.debug('field attributes ' + attr);
        }
        System.debug('ret map for attributes ' + retMap);
        return retMap;
    }

    public Boolean isPackaged(String fieldName){
        Boolean retPackaged = FALSE;
        System.debug('field in isPackaged ' + fieldName);
        if (fieldName.length() > 6){
            if (fieldName.startsWith('SCMC__') ||
                    fieldName.startsWith('SCMFFA__')){
                retPackaged = TRUE;
            }
        }
        System.debug('indicate if packaged ' + retPackaged);
        return retPackaged;
    }


    public class fieldAttributes {

        public String fieldName {get;set;}
        public Boolean isSetable {get;set;}
        public List<Schema.PicklistEntry> pickEntries {get;set{
            pickEntries = value;
            for (Schema.PicklistEntry pickEntry : pickEntries){
                validPicks.add(pickEntry.getValue());
            }
        }}
        public Set<String> validPicks  {get; set;}
        public Schema.DisplayType fieldType {get;set;}
        public Schema.SObjectType referenceTo {get;set;}
        public String lookupName {get; set;}

        fieldAttributes(String name, Boolean setable){
            this.fieldName = name;
            this.isSetable = setable;
            this.validPicks = new Set<String>();
        }
    }

}