@isTest
public class AssetFromCRMOrderTest {
    
    @isTest
    static void deactivateParentTest(){
	    Test.startTest();	
        Account acct = new Account(Name='Test Account');
        acct.RecordTypeId = '0120a0000004bwXAAQ';
        insert acct;
        Asset parent = new Asset(AccountID=acct.Id, Name='Test Parent', Base_Order_ID__c= 12345, Customer__c=acct.Id);
        Asset updateParent = new Asset(AccountID=acct.Id, Name='Test updateParent', Base_Order_ID__c= 65432, Parent_Base_Order_ID__c= 12345, Status= 'Closed', Customer__c=acct.Id);
        insert parent;
               System.debug('parent ' + parent.name + parent.Id);
        System.debug('parent ' + parent.name + parent.Base_Order_ID__c);
        

        insert updateParent;
                System.debug('updateParent ' + updateParent.Name + updateParent.Id);
        System.debug('updateParent ' + updateParent.Name + updateParent.Base_Order_ID__c);
        Boolean actual = parent.Inactive__c;
        AssetFromCRMOrder.deactivateParent(updateParent);
        Boolean expected = parent.Inactive__c;
        System.assertEquals(expected, actual);
        
        Test.stopTest();
    }
    
    @isTest
    static void getParentAccountAccountForPendingTest(){
        	    Test.startTest();	
        Account acct = new Account(Name='Test Account');
        insert acct;
        Account cust = new Account(Name='Test Account');
        cust.RecordTypeId = '0120a0000004bwXAAQ';
        insert cust;
        Asset parent = new Asset(AccountID=acct.Id, Customer__c=cust.Id, Name='Test Parent', Base_Order_ID__c= 12345);
        Asset newAsset = new Asset(AccountID=cust.Id, Customer__c=cust.Id, Name='Test newAsset', Base_Order_ID__c= 65432, Parent_Base_Order_ID__c= 12345, Status= 'Pending');
        insert parent;
               System.debug('parent ' + parent.name + parent.Id);
        System.debug('parent ' + parent.name + parent.Base_Order_ID__c);
        

        insert newAsset;
                System.debug('newAsset ' + newAsset.Name + newAsset.Id);
        System.debug('newAsset ' + newAsset.Name + newAsset.Base_Order_ID__c);
        Asset parentAsset = [Select Id, AccountId from Asset where Base_Order_ID__c =: newAsset.Base_Order_ID__c];
        Asset childAsset = [Select Id, AccountId from Asset where Parent_Base_Order_ID__c =: parent.Base_Order_ID__c];
        Id expected = parentAsset.AccountId;
        Id actual = childAsset.AccountId;
        System.assertEquals(expected, actual);
        
        Test.stopTest();
    }
        @isTest
    static void getParentAccountAccountForPendingNegativeTest(){
        	    Test.startTest();	

        Account cust = new Account(Name='Test Account');
        insert cust;
        Asset newAsset = new Asset(AccountID=cust.Id, Customer__c=cust.Id, Name='Test newAsset', Base_Order_ID__c= 951559, Parent_Base_Order_ID__c= 98765, Status= 'Pending');

        insert newAsset;
                System.debug('newAsset ' + newAsset.Name + newAsset.Id);
        System.debug('newAsset ' + newAsset.Name + newAsset.Base_Order_ID__c);
        Id expected = cust.Id;
        Id actual = newAsset.AccountId;
        System.assertEquals(expected, actual);
        
        Test.stopTest();
         }
}