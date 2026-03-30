/**
 * Created by Ladd Partners on 3/15/2025.
 */

public with sharing class lp_CertifySettings {

    @TestVisible private static Certify_Settings__c settings {
        get {
            if (settings == null) {
                settings = Certify_Settings__c.getInstance();
            }
            return settings;
        }
        private set;
    }
    
    public static Boolean isProduction {
        get { return settings.Is_Production__c; }
    }
    
    public static Decimal importExpenseReportsTimeout {
        get { return settings.Import_Expense_Reports_Timeout__c; }
    }

    public static Integer getPayableInvoiceBatchSize() {
        Integer batchScope = 200;

        if (settings.Create_Payable_Invoice_Batch_Size__c < 200 &&
            settings.Create_Payable_Invoice_Batch_Size__c != null &&
            settings.Create_Payable_Invoice_Batch_Size__c >= 1) {
            batchScope = (Integer) settings.Create_Payable_Invoice_Batch_Size__c;
        }

        if (Test.isRunningTest()) {
            batchScope = 5;
        }

        return batchScope;
    }
}