/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Contact_Model {
    
    @AuraEnabled
    public String contact_id { get; set; }
    @AuraEnabled
    public String contact_type_cd { get; set; }
}