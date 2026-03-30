@isTest
public class InvoiceTrigger_Test {
	@isTest static void testSumInvoices() { 
        Test.startTest();
        
        Account customer = new Account(Name='Test Account', RecordTypeId='0120a0000004bwXAAQ', Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail');
        insert customer;
        
        List<Account> accounts = new List<Account>();
        Integer x = 0;        
        
        do {
            Account a = new Account(Name='Test Account ' + x, RecordTypeId='0120a0000004bwcAAA', Type='Account', ParentId=customer.Id, Type_Custom__c='Account', Sub_Type__c='Retail');
            accounts.add(a);
            x++; 
        } while (x < 3);
		insert accounts;
        
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Account a : accounts) {
            Invoice__c inv = new Invoice__c(Account__c=a.Id,Invoice_Amount__c=100,Invoice_Amount_if_Current_Month__c=100,Invoice_Date__c=Date.today());
            invoices.add(inv);
        }        
        insert invoices;
        
        Account customer2 = [SELECT Id, Total_Invoiced_All_Accounts__c, Total_Invoiced_This_Month_All_Accounts__c FROM Account WHERE Id=:customer.Id];
        
        System.debug('Total Invoiced (All Accounts): ' + customer2.Total_Invoiced_All_Accounts__c);
        System.debug('Total Invoiced This Month (All Accounts): ' + customer2.Total_Invoiced_This_Month_All_Accounts__c);
        
        System.assert(customer2.Total_Invoiced_All_Accounts__c == 300); 
        System.assert(customer2.Total_Invoiced_This_Month_All_Accounts__c == 300); 
        
        Test.stopTest();
    }    
}