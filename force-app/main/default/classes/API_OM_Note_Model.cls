/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Note_Model {
    
    @AuraEnabled
    public String subject { get; set; }
    @AuraEnabled
    public String note { get; set; }
    @AuraEnabled
    public String created { get; set; }
    @AuraEnabled
    public Long created_by_id { get; set; }
}