/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_MonthlyPayableInvoiceLineItem {
    private static final String LINE_DESCRIPTION = '{0} {1}';

    public static List<c2g__codaPurchaseInvoiceExpenseLineItem__c> createFromITSPayable(Master_ITS_Payable_Invoice__c itsHeader, Id monthlyPayableId, Id ownerCompany) {
        List<c2g__codaPurchaseInvoiceExpenseLineItem__c> monthlyPayableLines = new List<c2g__codaPurchaseInvoiceExpenseLineItem__c>();

        for(Master_ITS_Payable_Invoice_Line__c line : itsHeader.Master_ITS_Payable_Invoice_Lines__r) {
            c2g__codaPurchaseInvoiceExpenseLineItem__c newMonthlyPayableLine = new c2g__codaPurchaseInvoiceExpenseLineItem__c();

            newMonthlyPayableLine.c2g__PurchaseInvoice__c = monthlyPayableId;
            newMonthlyPayableLine.c2g__OwnerCompany__c = ownerCompany;
            newMonthlyPayableLine.c2g__DeriveLineNumber__c = true;
            newMonthlyPayableLine.c2g__LineDescription__c = String.format(LINE_DESCRIPTION, new List<String> {line.LEC_Circuit_ID__c, line.Charge_Type__c});
            newMonthlyPayableLine.c2g__NetValue__c = line.Amt_Paid__c;
            newMonthlyPayableLine.c2g__GeneralLedgerAccount__c = line.General_Ledger_Account_Number__c;
            newMonthlyPayableLine.c2g__Dimension1__c = line.Department__c;
            newMonthlyPayableLine.c2g__Dimension2__c = line.State__c;
            newMonthlyPayableLine.c2g__Dimension3__c = line.Location__c;
            newMonthlyPayableLine.c2g__Dimension4__c = line.Product__c;
            newMonthlyPayableLine.Master_ITS_Payable_Invoice_Line__c = line.Id;

            monthlyPayableLines.add(newMonthlyPayableLine);
        }

        return monthlyPayableLines;
    }
}