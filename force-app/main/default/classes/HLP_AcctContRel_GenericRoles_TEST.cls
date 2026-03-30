@IsTest
public class HLP_AcctContRel_GenericRoles_TEST {

    @IsTest
    public static void testAfterInsertGenericRoles(){
        User testUser = TestDataFactory.createUser(true,'Standard User', new List<String>{
                'PMT_User',
                'Allow_Restricted_Accounting_Contact_Editing',
                'Allow_Restricted_TOC_Contact_Editing',
                'Allow_TOC_ownership_Changes',
                'Allow_TOC_ownership_Changes',
                'Edit TOC History'});

        System.runAs(testUser) {
            Id recordTypeIdC = [select Id from recordtype where SobjectType = 'Account' and Name = 'Customer' limit 1].get(0).Id;
            Account ac = new Account(Name = 'Test', RecordTypeId = recordTypeIdC);
            insert ac;

            Id recordTypeIdA = [select Id from recordtype where SobjectType = 'Account' and Name = 'Account' limit 1].get(0).Id;
            Account a = new Account(Name = 'Test', RecordTypeId = recordTypeIdA, ParentId = ac.Id);
            insert a;

            Contact c = new Contact(AccountId = ac.Id, LastName = 'test');
            insert c;

            Test.startTest();
            Contact actual = [select Id, Restricted_Roles_TOC__c from Contact where Id = :c.Id].get(0);

            System.assertEquals(false, actual.Restricted_Roles_TOC__c);
            AccountContactRelation acr = new AccountContactRelation(AccountId = a.Id, ContactId = c.Id, IsActive = true, Roles = 'C1');
            insert acr;
            Contact actual2 = [select Id, Restricted_Roles_TOC__c from Contact where Id = :c.Id].get(0);
            System.assertEquals(true, actual2.Restricted_Roles_TOC__c);
            Test.stopTest();
        }
        
    }
    
    @IsTest
    public static void testBeforeDeleteGenericRoles(){

        User testUser = TestDataFactory.createUser(true,'System Administrator', null);

        System.runAs(testUser) {
            Id recordTypeIdC = [select Id from recordtype where SobjectType = 'Account' and Name = 'Customer' limit 1].get(0).Id;
            Account ac = new Account(Name = 'Test', RecordTypeId = recordTypeIdC);
            insert ac;

            Id recordTypeIdA = [select Id from recordtype where SobjectType = 'Account' and Name = 'Account' limit 1].get(0).Id;
            Account a = new Account(Name = 'Test', RecordTypeId = recordTypeIdA, ParentId = ac.Id);
            insert a;

            Contact c = new Contact(AccountId = ac.Id, LastName = 'test');
            insert c;

            AccountContactRelation acr = new AccountContactRelation(AccountId = a.Id, ContactId = c.Id, IsActive = true, Roles = 'C1');
            insert acr;

            Test.startTest();

            Contact actual = [select Id, Restricted_Roles_TOC__c from Contact where Id = :c.Id].get(0);
            System.assertEquals(true, actual.Restricted_Roles_TOC__c);
            delete acr;
            Contact actual2 = [select Id, Restricted_Roles_TOC__c from Contact where Id = :c.Id].get(0);
            System.assertEquals(false, actual2.Restricted_Roles_TOC__c);

            Test.stopTest();
        }
    }
    
}