global class OneNeckAccountFlagsBatch implements Database.Batchable<SObject> {

    // Picklist values on Product2.System_Origin__c
    public static final String ORIGIN_DYNAMICS = 'OneNeck Dynamics';
    public static final String ORIGIN_POM      = 'OneNeck POM Microsoft';

    // Confirmed Account lookup field on ffbc__Contract__c
    public static final String CONTRACT_ACCOUNT_FIELD = 'ffbc__Account__c';

    global Database.QueryLocator start(Database.BatchableContext bc) {

        // Only process Contract Line Items created in the last 25 hours (buffered window)
        Datetime cutoff = System.now().addHours(-25);

        return Database.getQueryLocator([
            SELECT Id,
                   ffbc__Contract__c,
                   ffbc__Contract__r.ffbc__Account__c,
                   ffbc__ProductService__c,
                   ffbc__ProductService__r.System_Origin__c
            FROM ffbc__ContractLineItem__c
            WHERE ffbc__ProductService__c != null
              AND ffbc__Contract__c != null
              AND ffbc__Contract__r.ffbc__Account__c != null
              AND ffbc__ProductService__r.System_Origin__c IN (:ORIGIN_DYNAMICS, :ORIGIN_POM)
              AND CreatedDate >= :cutoff
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        // Sparse Account updates (only set TRUE, no resets)
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        for (SObject sob : scope) {
            ffbc__ContractLineItem__c cli = (ffbc__ContractLineItem__c) sob;

            // Account Id from parent Billing Contract
            Id accountId = (Id) cli.ffbc__Contract__r.get(CONTRACT_ACCOUNT_FIELD);
            if (accountId == null) continue;

            // System Origin from Product
            String origin = (String) cli.ffbc__ProductService__r.get('System_Origin__c');
            if (String.isBlank(origin)) continue;

            Account acc = accountsToUpdate.get(accountId);
            if (acc == null) {
                acc = new Account(Id = accountId);
                accountsToUpdate.put(accountId, acc);
            }

            if (origin == ORIGIN_DYNAMICS) {
                acc.Has_OneNeck_Dynamics_on_BC__c = true;
            } else if (origin == ORIGIN_POM) {
                acc.Has_OneNeck_POM_Microsoft_on_BC__c = true;
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate.values(), false);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: logging, notifications, or audit events
    }
}