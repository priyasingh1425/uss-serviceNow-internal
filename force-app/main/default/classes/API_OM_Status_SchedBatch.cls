public with sharing class API_OM_Status_SchedBatch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {

    private Set<Id> idsToProcess;

    public API_OM_Status_SchedBatch(){}

    public API_OM_Status_SchedBatch(Set<Id> ids){
        this.idsToProcess = ids;
    }

    public void execute(SchedulableContext sc){
        Database.executeBatch(this, 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        /*if(idsToProcess != null){
            return [SELECT Id FROM SBQQ__Quote__c WHERE Id IN :idsToProcess];
        }*/
        String query = 'SELECT Id'+
            ' FROM SBQQ__Quote__c'+
            ' WHERE   OM_Payload_Status__c = \'review\' OR '+
                    'OM_Payload_Status__c = \'pending\' OR '+
                    'OM_Payload_Status__c = \'accepted\' ';
        System.debug('Query: ' + query);
        return Database.getQueryLocator(
            query
        );
    }

    public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> records){
        API_Order_OmniIntegration_Util service = API_Order_OmniIntegration_Util.getService();
        API_OM_RequestLogger.setBulkMode(true);
        HLP_Case_SFQueue_Ins.isBulk = true;

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        List<Order> orders = new List<Order>();

        for(SBQQ__Quote__c quote:records){
            try{
                API_Order_OmniIntegration_Util.OfsStatus status = service.checkOrderStatus(quote.Id);
                quotes.add(status.quote);
                orders.addAll(status.orders);
            }catch(API_OM_Connection_Util.OMException ex){
                HLP_Case_SFQueue_Ins.createSFQueueCase('OM Status Polling Error', 'API_OM_Status_SchedBatch ::: Quote: ' + quote + ' ::: Messages: ' + ex.getMessage(), 'High');
            }
        }

        HLP_Case_SFQueue_Ins.saveCases();
        API_OM_RequestLogger.saveLogs();

        Database.update(orders, false);
        Database.update(quotes, false);
    }

    public void finish(Database.BatchableContext bc){}
}