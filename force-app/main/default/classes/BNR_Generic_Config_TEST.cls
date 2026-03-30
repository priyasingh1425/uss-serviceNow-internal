@IsTest
public class BNR_Generic_Config_TEST {
	@IsTest
    public static void getFieldValueTest(){
        Id recordTypeIdC = [select Id from recordtype where SobjectType = 'Account' and Name = 'Customer' limit 1].get(0).Id;
        Account ac = new Account(Name='Test', RecordTypeId=recordTypeIdC);
        insert ac;
        
        Test.startTest();
        System.assertEquals('Test', BNR_Generic_Config_CTL.getFieldValue('Account', 'Name', ac.Id));
        Test.stopTest();
    }
}