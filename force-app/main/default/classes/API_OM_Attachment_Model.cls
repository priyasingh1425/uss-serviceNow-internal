/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Attachment_Model {
    
    @AuraEnabled
    public String file_id { get; set; }
    @AuraEnabled
    public String file_name { get; set; }
    @AuraEnabled
    public String mime_type { get; set; }
    @AuraEnabled
    public String uploaded_date { get; set; }

}