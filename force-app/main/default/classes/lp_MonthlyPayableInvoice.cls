/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_MonthlyPayableInvoice {
    private static final String COMPANY_NAME = 'US Signal Company, LLC';
    private static final String INVOICE_STATUS = 'In Progress';

    private static final String CREATING_PIN_HEADER = 'Creating Monthly Payable Invoice Header: ';
    private static final String INSERTING_PIN_HEADER = 'Inserting Monthly Payable Invoice Header: ';
    private static final String CREATING_PIN_LINES = 'Creating Monthly Payable Invoice Line Items: ';
    private static final String INSERTING_PIN_LINES = 'Inserting Monthly Payable Invoice Line Items: ';

    public static c2g__codaPurchaseInvoice__c createFromITSPayable(Id itsPayableId) {
        c2g__codaPurchaseInvoice__c monthlyPayableInvoice = new c2g__codaPurchaseInvoice__c();

        Master_ITS_Payable_Invoice__c itsPayable = new lp_ITSPayableSelector().getWithLinesById(itsPayableId);

        List<c2g__codaCompany__c> companies = [SELECT Id FROM c2g__codaCompany__c WHERE Name = :COMPANY_NAME];
        Id ownerCompany = !companies.isEmpty() ? companies[0].Id : null;

        Savepoint sp = Database.setSavepoint();
        String stage = CREATING_PIN_HEADER;

        try {
            monthlyPayableInvoice.Master_ITS_Payable_Invoice__c = itsPayable.Id;
            monthlyPayableInvoice.c2g__OwnerCompany__c = ownerCompany;
            monthlyPayableInvoice.c2g__DeriveCurrency__c = true;
            monthlyPayableInvoice.c2g__DerivePeriod__c = true;
            monthlyPayableInvoice.c2g__Account__c = itsPayable.Vendor__c;
            monthlyPayableInvoice.c2g__AccountInvoiceNUmber__c = itsPayable.Invoice_Number__c;
            monthlyPayableInvoice.c2g__InvoiceDate__c = itsPayable.Invoice_Date__c;
            monthlyPayableInvoice.c2g__DueDate__c = itsPayable.Due_Date__c;
            monthlyPayableInvoice.c2g__InvoiceStatus__c = INVOICE_STATUS;

            stage = INSERTING_PIN_HEADER;
            insert monthlyPayableInvoice;

            stage = CREATING_PIN_LINES;
            List<c2g__codaPurchaseInvoiceExpenseLineItem__c> monthlyPayableInvoiceLines = lp_MonthlyPayableInvoiceLineItem.createFromITSPayable(itsPayable, monthlyPayableInvoice.Id, ownerCompany);

            stage = INSERTING_PIN_LINES;
            insert monthlyPayableInvoiceLines;
        }
        catch(Exception e) {
            Database.rollback(sp);
            throw new lp_Exception(stage + e.getMessage());
        }

        return monthlyPayableInvoice;
    }
}