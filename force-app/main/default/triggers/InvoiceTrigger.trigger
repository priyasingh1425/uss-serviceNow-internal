trigger InvoiceTrigger on Invoice__c (after insert, after update) {
	Set<Id> customerIds = new Set<Id>(); //list of parent account ids   
    List<Invoice__c> invList = new List<Invoice__c>(); //list of invoices under child accounts
    
    if(Trigger.isInsert || Trigger.isUpdate) { //load the list of parent ids and a list of child accounts
        for(Invoice__c inv : [SELECT Id, Account__c, Account__r.ParentId FROM Invoice__c WHERE Id IN:Trigger.new]) {
            if(inv.Account__c != null && inv.Account__r.ParentId != null) {
                customerIds.add(inv.Account__r.ParentId);
                invList.add(inv);
            }
        }
    }

    if (!customerIds.isEmpty()) {
		List<Account> customersToUpdate = new List<Account>(); //new list of parent accounts
        
        for (AggregateResult ar : [SELECT SUM(Invoice_Amount__c) totalInv, 
                                   		  SUM(Invoice_Amount_if_Current_Month__c) monthlyInv, 
                                   		  Account__r.ParentId
                                   FROM Invoice__c 
                                   WHERE Account__r.ParentId IN :customerIds 
                                   GROUP BY Account__r.ParentId]) {
		    Account customer = new Account();
            customer.Id = (Id)ar.get('ParentId');
            customer.Total_Invoiced_All_Accounts__c = (Decimal)ar.get('totalInv');
            customer.Total_Invoiced_This_Month_All_Accounts__c = (Decimal)ar.get('monthlyInv');
            customersToUpdate.add(customer);
        }
        
        if (!customersToUpdate.isEmpty()) {
            update customersToUpdate;
        }
    }
    
}