global class TEMP_PMT_UpdateOrder_BTC_DTL implements Database.Batchable<sObject>,Database.Stateful{
    global final String query;
    global final List<String> exception_List = new List<String>();
    
    global TEMP_PMT_UpdateOrder_BTC_DTL(String inputStatus) {
        String q = 'SELECT Id, ';
        q = q + 'Quote__r.Id, ';
        q = q + 'OwnerId ';
        q = q + 'from PMT_Project__c ';
        q = q + 'WHERE ';
        q = q + 'Quote__r.Id != null';
        q = q + ' AND ';
        q = q + ' Project_Status__c =  \'';
        q = q + inputStatus + '\'';
        this.query = q;
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {        // Collect Quote IDs and their corresponding Owner IDs
        Set<Id> quoteIds = new Set<Id>();
        Map<Id, Id> quoteToOwnerMap = new Map<Id, Id>(); // Quote ID -> Owner ID
        
        for (sObject s : scope) {
            PMT_Project__c p = (PMT_Project__c)s;
            quoteIds.add(p.Quote__r.Id);
            
            quoteToOwnerMap.put(p.Quote__r.Id, p.OwnerId);
        }
        
        // Query ALL Orders related to Quotes in this batch
        // This will get ALL Orders per Quote, not just one
        List<Order> ordersToUpdate = new List<Order>();
        
        for (Order o : [SELECT Id, SBQQ__Quote__c 
                        FROM Order 
                        WHERE SBQQ__Quote__c IN :quoteIds]) {
                            
                            Id newOwnerId = quoteToOwnerMap.get(o.SBQQ__Quote__c);
                            if (newOwnerId != null) {ordersToUpdate.add(new Order(Id = o.Id,OwnerId = newOwnerId));
                                                    }
                        }
        
        System.debug('Number of records being updated: ' + ordersToUpdate.size());
        System.debug('Orders to update: ' + ordersToUpdate);
        
        if (!ordersToUpdate.isEmpty()) {
            Database.SaveResult[] saveResultList = Database.update(ordersToUpdate, false);
        }        
    }
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished. Orders updated: ' + BC.getJobId());
    }
}