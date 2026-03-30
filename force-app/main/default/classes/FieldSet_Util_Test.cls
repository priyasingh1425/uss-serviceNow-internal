@isTest
public with sharing class FieldSet_Util_Test {

    @isTest
    public static void readFieldSet(){
        FieldSet_Util.FieldSet fs = FieldSet_Util.getFieldSet('OrderItem', 'OM_Address');
        System.assertEquals('OM_Address', fs.label);
    }
}