/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_ProvidedService_Model {
    
    @AuraEnabled
    public Decimal expected_mrc { get; set; }
    @AuraEnabled
    public Decimal expected_nrc { get; set; }
    @AuraEnabled
    public String ordering_clli { get; set; }
    @AuraEnabled
    public String serving_clli { get; set; }
    @AuraEnabled
    public Long lec_vendor_id { get; set; }
    @AuraEnabled
    public API_OM_Address_Model service_address { get; set; }
}