/**
 * Created by Ladd Partners on 5/18/2025.
 */

public with sharing class lp_AnalysisItemSelector extends lp_Selector {

    public lp_AnalysisItemSelector () {
        setSObjectType(fferpcore__AnalysisItem__c.getSObjectType());
        addField(fferpcore__AnalysisItem__c.Id);
        addField(fferpcore__AnalysisItem__c.Name);
    }

    public List<fferpcore__AnalysisItem__c> getByName(Set<String> analysisItemNames){
        String query = getSelectStatement();
        query += ' WHERE Name IN :analysisItemNames';
        return Database.query(query);
    }

    public Map<String, fferpcore__AnalysisItem__c> getMapByName(Set<String> analysisItemNames){
        List<fferpcore__AnalysisItem__c> analysisItems = getByName(analysisItemNames);
        Map<String, fferpcore__AnalysisItem__c> analysisItemByName = new Map<String, fferpcore__AnalysisItem__c>();
        for(fferpcore__AnalysisItem__c analysisItem : analysisItems){
            analysisItemByName.put(analysisItem.Name.toLowerCase(), analysisItem);
        }
        return analysisItemByName;
    }
}