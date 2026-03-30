/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Service_Model {
    
    @AuraEnabled
    public String service_component_id { get; set; }
    @AuraEnabled
    public Decimal mrc { get; set; }
    @AuraEnabled
    public Decimal nrc { get; set; }
    @AuraEnabled
    public Decimal quoted_mrc { get; set; }
    @AuraEnabled
    public Decimal quoted_nrc { get; set; }
    @AuraEnabled
    public Decimal quantity { get; set; }
    @AuraEnabled
    public Decimal usage_rate { get; set; }
    @AuraEnabled
    public Decimal secondary_usage_rate { get; set; }
    @AuraEnabled
    public String unit_of_measure { get; set; }
    @AuraEnabled
    public String customer_ref { get; set; }
    @AuraEnabled
    public Decimal discounted_from_std_rate { get; set; }
    @AuraEnabled
    public String billing_contract_line_item_id { get; set; }
    @AuraEnabled
    public Date bill_start_date { get; set; }
}