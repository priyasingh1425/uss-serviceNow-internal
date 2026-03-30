/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Misc_Model {
    
    @AuraEnabled
    public String grouping_id { get; set; }
    @AuraEnabled
    public String grouping_label { get; set; }
    @AuraEnabled
    public String key_id { get; set; }
    @AuraEnabled
    public String key_label { get; set; }
    @AuraEnabled
    public String value { get; set; }
}