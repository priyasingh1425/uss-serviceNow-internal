/**
 * Created by Ladd Partners on 12/27/2025.
 */

public with sharing class lp_UsageSelector extends lp_Selector {

    public static Map<Id, lp_UsageData> getUsageCreditDataMapByContractLineId(Map<Id, lp_UsageData> usageDataByContractLineId, Date earliestCreditFromDate) {
        Map<Id, lp_UsageData> usageCreditDataByContractLineId = new Map<Id, lp_UsageData>();

        List<AggregateResult> usageAggregates = [
            SELECT 
                ffbc__ContractLineItem__c lineId,
                SUM(LPC_Amount_on_BD__c) totalAmount,
                MAX(ffbc__Date__c) latestDate
            FROM ffbc__Usage__c
            WHERE ffbc__ContractLineItem__c IN :usageDataByContractLineId.keySet()
            AND ffbc__Date__c >= :earliestCreditFromDate
            AND ffbc__BillingDocumentLineItem__c != null
            GROUP BY ffbc__ContractLineItem__c
        ];

        for (AggregateResult ar : usageAggregates) {
            Id usageLineId = (Id)ar.get('lineId');
            Date latestDate = (Date)ar.get('latestDate');
            Decimal totalAmount = (Decimal)ar.get('totalAmount') ?? 0;
            lp_UsageData inputUsageData = usageDataByContractLineId.get(usageLineId);
            
            if (latestDate >= inputUsageData.creditFromDate) {
                lp_UsageData data = new lp_UsageData();
                data.billingContractLineId = usageLineId;
                data.creditFromDate = inputUsageData.creditFromDate;
                data.latestDate = latestDate;
                data.creditAmount = totalAmount * -1; // Negative value for credit
                usageCreditDataByContractLineId.put(usageLineId, data);
            }
        }

        return usageCreditDataByContractLineId;
    }

    public static lp_UsageData getUsageCreditData(lp_UsageData usageDataInput) {
        Map<Id, lp_UsageData> usageDataByContractLineId = getUsageCreditDataMapByContractLineId(new Map<Id, lp_UsageData>{ usageDataInput.billingContractLineId => usageDataInput }, usageDataInput.creditFromDate );
        return usageDataByContractLineId.get(usageDataInput.billingContractLineId);
    }

    public class lp_UsageData {
        public Id billingContractLineId;
        public Date creditFromDate;
        public Date latestDate;
        public Decimal creditAmount;
    }
}