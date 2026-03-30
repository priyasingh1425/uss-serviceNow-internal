/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_BillingDocumentSelector extends lp_Selector {
  public static final String INVOICE_STATUS_POSTED = 'Posted';
  public static final Decimal BILL_DOC_OUTSTANDING_VALUE = 0.00;

  public lp_BillingDocumentSelector() {
    setSObjectType(fferpcore__BillingDocument__c.getSObjectType());
    addField(fferpcore__BillingDocument__c.Customer_Notes__c);
    addField(fferpcore__BillingDocument__c.Document_Is_Late__c);
    addField(fferpcore__BillingDocument__c.Id);
    addField(fferpcore__BillingDocument__c.c2g__OutstandingValue__c);
    addField(fferpcore__BillingDocument__c.c2g__PostingStatus__c);
    addField(fferpcore__BillingDocument__c.c2g__PostingError__c);
    addField(fferpcore__BillingDocument__c.fferpcore__Account__c);
    addField(fferpcore__BillingDocument__c.fferpcore__Company__c);
    addField(fferpcore__BillingDocument__c.fferpcore__DocumentDate__c);
    addField(fferpcore__BillingDocument__c.fferpcore__DocumentStatus__c);
    addField(fferpcore__BillingDocument__c.Finance_Charge_Calculation__c);
    addField('fferpcore__Account__r.Finance_Charge__c');
    addField('fferpcore__Account__r.Suppress_Late_Charge__c');
  }

  public List<fferpcore__BillingDocument__c> getLateBillingDocuments() {
    String query = getSelectStatement();
    query += ' WHERE Customer_Notes__c LIKE \'Finance Charge -%\'';

    return Database.query(query);
  }

  public fferpcore__BillingDocument__c getWithLinesById(Id documentId) {
    lp_BillingDocumentLineSelector lineSelector = new lp_BillingDocumentLineSelector();
    lineSelector.setSObjectType('fferpcore__ChildBillingDocumentLineItems__r');

    String query = getSelectStatement(lineSelector.getSelectStatement());
    query += ' WHERE Id = :documentId';

    return Database.query(query);
}

public List<fferpcore__BillingDocument__c> getWithLinesById(Set<Id> documentIds) {
    lp_BillingDocumentLineSelector lineSelector = new lp_BillingDocumentLineSelector();
    lineSelector.setSObjectType('fferpcore__ChildBillingDocumentLineItems__r');

    String query = getSelectStatement(lineSelector.getSelectStatement());
    query += ' WHERE Id IN :documentIds';

    return Database.query(query);
}

  public List<fferpcore__BillingDocument__c> getBillingDocuments(Set<Id> billingDocumentIds) {
    String query = getSelectStatement();
    query += ' WHERE Id IN :billingDocumentIds';

    return Database.query(query);
  }

  public List<fferpcore__BillingDocument__c> getMonthlyLateFeesBillDocs() {
    String query = getSelectStatement();
    query += ' WHERE c2g__PostingStatus__c = :INVOICE_STATUS_POSTED';
    query += ' AND c2g__OutstandingValue__c > :BILL_DOC_OUTSTANDING_VALUE';
    query += ' AND Finance_Charge_Calculation__c = true';
    query += ' AND Document_Is_Late__c = true';

    return Database.query(query);
  }

  public fferpcore__BillingDocument__c getById(Id documentId) {
    List<fferpcore__BillingDocument__c> billingDocuments = getById(new Set<Id>{ documentId }, false);
    if (!billingDocuments.isEmpty()) {
        return billingDocuments[0];
    } else {
        return null;
    }
  }

  public List<fferpcore__BillingDocument__c> getById(Set<Id> ids, Boolean isForUpdate) {
    String query = getSelectStatement();
    query += ' WHERE Id IN :ids';
    if (isForUpdate) {
        query += ' FOR UPDATE';
    }

    return Database.query(query);
  }

  public Set<Id> getAccountIds(List<fferpcore__BillingDocument__c> billingDocuments) {
    Set<Id> accountIds = new Set<Id>();

    for (fferpcore__BillingDocument__c billingDocument : billingDocuments) { 
      if(!accountIds.contains(billingDocument.fferpcore__Account__c)) {
        accountIds.add(billingDocument.fferpcore__Account__c);
      }
    }

    return accountIds;
  }
}