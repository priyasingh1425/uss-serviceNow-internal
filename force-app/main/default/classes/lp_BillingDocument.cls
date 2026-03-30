/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_BillingDocument {
    private static final String invoiceMemoPrefix = 'Finance Charge - ';

    private static final String CREATING_LATE_BILL_DOCS = 'Creating Late Bill Docs: ';
    private static final String CREATING_LATE_BILL_DOC_LINES = 'Creating Late Bill Doc Line Items: ';
    private static final String COMPLETING_LATE_BILL_DOCS = 'Completing Late Bill Docs: ';
    private static final String POSTING_LATE_BILL_DOCS = 'Posting with Certinia: ';

    private static lp_AccountSelector accSelector = new lp_AccountSelector();

    public static fferpcore__BillingDocument__c create(Id accountID) {
        fferpcore__BillingDocument__c billingDocument = new fferpcore__BillingDocument__c();

        billingDocument.fferpcore__Account__c = accountId;
        billingDocument.fferpcore__DocumentDate__c = Date.today();

        return billingDocument;
    }

    public static fferpcore__BillingDocument__c createLateFees(Id accountID) {
        fferpcore__BillingDocument__c billingDocument = create(accountID);
        String monthName = DateTime.newInstance(Date.today().year(), Date.today().month(), 1).format('MMMM');

        billingDocument.Customer_Notes__c = invoiceMemoPrefix + monthName;
        billingDocument.fferpcore__DocumentType__c = 'Invoice';

        return billingDocument;
    }

    public static Map<Id, String[]> createFinanceCharge(List<Account> accounts) {
        String stage = CREATING_LATE_BILL_DOCS;

        Set<Id> accountIds = lp_CollectionUtil.getIdSet(accounts);
        Set<Id> billDocsToPost = new Set<Id>();

        Map<Id, Map<Id, Decimal>> outstandingValueByCompanyIdByAccountId = lp_AccountSelector.getAccountOutstandingAggregate(accountIds);
        Map<Id, String[]> errorsByAccountId = new Map<Id, String[]>();

        List<Account> currentAccounts = accSelector.getByIds(accountIds);
        Map<Id, Account> accountMap = new Map<Id, Account>(currentAccounts);

        List<fferpcore__BillingDocument__c> newLateBillDocs = new List<fferpcore__BillingDocument__c>();
        List<fferpcore__BillingDocument__c> successfulLateBillDocs = new List<fferpcore__BillingDocument__c>();
        List<fferpcore__BillingDocumentLineItem__c> newLateBillDocLines = new List<fferpcore__BillingDocumentLineItem__c>();

        for(Id accountId : accountIds) { 
            Map<Id, Decimal> outstandingValueByCompanyId = outstandingValueByCompanyIdByAccountId.get(accountId);

            for(Id companyId : outstandingValueByCompanyId.keySet()) {
                fferpcore__BillingDocument__c lateBillDoc = createLateFees(accountId);
                lateBillDoc.fferpcore__Company__c = companyId;

                newLateBillDocs.add(lateBillDoc);
            }
        }

        Database.SaveResult[] saveResults = Database.insert(newLateBillDocs, false);
        for(Integer i = 0; i < saveResults.size(); i++) {
            if(!saveResults[i].isSuccess()) {
                Id erroredAccountId = newLateBillDocs[i].fferpcore__Account__c;
                (errorsByAccountId.containsKey(erroredAccountId) ? errorsByAccountId.get(erroredAccountId) : errorsByAccountId.put(erroredAccountId, new String[]{})).add(stage + String.valueOf(saveResults[i].getErrors()));
            }
            else {
                successfulLateBillDocs.add(newLateBillDocs[i]);
            }
        }

        stage = CREATING_LATE_BILL_DOC_LINES;
        for(fferpcore__BillingDocument__c currentBillDoc : successfulLateBillDocs) {
            Id accountId = currentBillDoc.fferpcore__Account__c;
            Id companyId = currentBillDoc.fferpcore__Company__c;

            Decimal outstandingValue = outstandingValueByCompanyIdByAccountId.get(accountId).get(companyId);
            System.debug(outstandingValue);
            Decimal lateFeeOutstandingValue = outstandingValue * (accountMap.get(accountId).Finance_Charge__c / 100);
            System.debug(lateFeeOutstandingValue);

            fferpcore__BillingDocumentLineItem__c newLateBillDocLineItem = lp_BillingDocumentLineItem.createLateFees(currentBillDoc.Id, lateFeeOutstandingValue);

            newLateBillDocLines.add(newLateBillDocLineItem);
        }

        saveResults = Database.insert(newLateBillDocLines, false);
        List<fferpcore__BillingDocumentLineItem__c> successfulLateBillDocLineItems = new List<fferpcore__BillingDocumentLineItem__c>();
        for(Integer i = 0; i < saveResults.size(); i++) {
            if(!saveResults[i].isSuccess()) {
                Id erroredAccountId = newLateBillDocLines[i].fferpcore__BillingDocument__r.fferpcore__Account__c;
                (errorsByAccountId.containsKey(erroredAccountId) ? errorsByAccountId.get(erroredAccountId) : errorsByAccountId.put(erroredAccountId, new String[]{})).add(stage + String.valueOf(saveResults[i].getErrors()));
            }
        }

        stage = COMPLETING_LATE_BILL_DOCS;
        List<fferpcore__BillingDocument__c> finalUpdateBillDocs = new List<fferpcore__BillingDocument__c>();
        for(fferpcore__BillingDocument__c currentBillDoc : successfulLateBillDocs) {
            fferpcore__BillingDocument__c updateBillDoc = new fferpcore__BillingDocument__c( Id = currentBillDoc.Id, fferpcore__DocumentStatus__c = 'Complete' );
            finalUpdateBillDocs.add(updateBillDoc);
        }

        saveResults = Database.update(finalUpdateBillDocs, false);
        for(Integer i = 0; i < saveResults.size(); i++) {
            if(!saveResults[i].isSuccess()) {
                Id erroredAccountId = finalUpdateBillDocs[i].fferpcore__Account__c;
                (errorsByAccountId.containsKey(erroredAccountId) ? errorsByAccountId.get(erroredAccountId) : errorsByAccountId.put(erroredAccountId, new String[]{})).add(stage + String.valueOf(saveResults[i].getErrors()));
            }
            else {
                billDocsToPost.add(finalUpdateBillDocs[i].Id);
            }
        }

        stage = POSTING_LATE_BILL_DOCS;
        try {
            postLateBillDocs(billDocsToPost);
        }
        catch(Exception e) {
            for(Id currentAccountId : errorsByAccountId.keySet()) {
                errorsByAccountId.get(currentAccountId).add(stage + e.getMessage());
            }
        }

        return errorsByAccountId;
    }

    public static void postLateBillDocs(Set<Id> billDocs) {
        c2g.CODAAPICommon_6_0.Context ctx = new c2g.CODAAPICommon_6_0.Context();
        c2g.CODAAPICommon_10_0.Context context = new c2g.CODAAPICommon_10_0.Context();
        List<c2g.CODAAPICommon.Reference> refs = new List<c2g.CODAAPICommon.Reference>();

        try {
            c2g.BillingDocumentPostingService.PostingRequest request = new c2g.BillingDocumentPostingService.PostingRequest(billDocs);
            c2g.BillingDocumentPostingService.postNow(request);
        }
        catch(Exception e) {
            throw new lp_Exception('Error posting billing documents: ' + e.getMessage(), false);
        }
    }
}