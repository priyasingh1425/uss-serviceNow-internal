/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Address_Model {
    
    @AuraEnabled
    public String address1 { get; set; }
    @AuraEnabled
    public String address2 { get; set; }
    @AuraEnabled
    public String city { get; set; }
    @AuraEnabled
    public String state { get; set; }
    @AuraEnabled
    public String zip { get; set; }
    @AuraEnabled
    public String zip4 { get; set; }
}