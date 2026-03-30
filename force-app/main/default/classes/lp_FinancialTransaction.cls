/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

public with sharing class lp_FinancialTransaction {

    public static final String GL_ACCOUNT_COST_OF_GOOD_SOLD = 'Cost of Goods Sold';
    public static final String GL_ACCOUNT_AP_LIABILITY = 'AP Liability';

    public SCMC__Inventory_Transaction_Perpetual_Record__c perpetualRecord;
    public List<SCMC__Inventory_Transaction_Financial_Records__c> financialRecords;

    public lp_FinancialTransaction() {
        this.financialRecords = new List<SCMC__Inventory_Transaction_Financial_Records__c>();
    }

    public lp_FinancialTransaction(SCMC__Inventory_Transaction_Perpetual_Record__c perpetual_record) {
        this.perpetualRecord = perpetual_record;
        this.financialRecords = new List<SCMC__Inventory_Transaction_Financial_Records__c>();
    }

    public List<SCMC__Inventory_Transaction_Financial_Records__c> billDropShipInventory(Id currencyId, Decimal adjustedValue) {
        return createTransactions(currencyId, adjustedValue, GL_ACCOUNT_COST_OF_GOOD_SOLD, GL_ACCOUNT_AP_LIABILITY);
    }

    private List<SCMC__Inventory_Transaction_Financial_Records__c> createTransactions(Id currencyId, Decimal adjustedValue, String positiveGLAccount, String negativeGLAccount) {

        Decimal quantity = this.perpetualRecord.SCMC__Quantity__c;
        Decimal changeValue = quantity * adjustedValue;

        SCMC__Inventory_Transaction_Financial_Records__c itfr1 = new SCMC__Inventory_Transaction_Financial_Records__c();
        itfr1.SCMC__GL_Account__c = positiveGLAccount;
        itfr1.SCMC__Quantity__c = quantity;
        itfr1.SCMC__ICP_Currency__c = currencyId;
        itfr1.SCMC__Trade_Currency__c = currencyId;
        itfr1.SCMC__ICP_Value_Amount__c = changeValue;
        itfr1.SCMC__Trade_Unit_Cost__c = adjustedValue;
        itfr1.SCMC__Trade_Value_Amount__c = quantity * itfr1.SCMC__Trade_Unit_Cost__c;
        itfr1.SCMC__ICP_Unit_Cost__c = adjustedValue;
        this.financialRecords.add(itfr1);

        SCMC__Inventory_Transaction_Financial_Records__c itfr2 = new SCMC__Inventory_Transaction_Financial_Records__c();
        itfr2.SCMC__GL_Account__c = negativeGLAccount;
        itfr2.SCMC__Quantity__c = quantity;
        itfr2.SCMC__ICP_Currency__c = currencyId;
        itfr2.SCMC__Trade_Currency__c = currencyId;
        itfr2.SCMC__ICP_Value_Amount__c = changeValue * -1;
        itfr2.SCMC__ICP_Unit_Cost__c = adjustedValue;
        itfr2.SCMC__Trade_Unit_Cost__c = adjustedValue;
        itfr2.SCMC__Trade_Value_Amount__c = (quantity * itfr2.SCMC__Trade_Unit_Cost__c) * -1;
        this.financialRecords.add(itfr2);

        return new List<SCMC__Inventory_Transaction_Financial_Records__c>{itfr1, itfr2};
    }

}