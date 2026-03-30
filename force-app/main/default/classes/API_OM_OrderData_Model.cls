/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration 
**/
public class API_OM_OrderData_Model {
    
    @AuraEnabled
    public String product_cd { get; set; }
    @AuraEnabled
    public String term_cd { get; set; }
    @AuraEnabled
    public Date requested_due_date { get; set; }
    @AuraEnabled
    public Date bill_start_date { get; set; }
    @AuraEnabled
    public Date contract_start_date { get; set; }
    @AuraEnabled
    public Integer proj_mgr_id { get; set; }
    @AuraEnabled
    public Date order_submitted { get; set; }
    @AuraEnabled
    public Long agent_company_id { get; set; }
    @AuraEnabled
    public Long sales_rep_id { get; set; }
    @AuraEnabled
    public Long retention_rep_id { get; set; }
    @AuraEnabled
    public String order_type { get; set; }
    @AuraEnabled
    public String order_number { get; set; }
    @AuraEnabled
    public String service_id { get; set; }
    @AuraEnabled
    public String legacy_service_id { get; set; }
    @AuraEnabled
    public Long service_bandwidth_id { get; set; }
    @AuraEnabled
    public String customer_serving_a_loc { get; set; }
    @AuraEnabled
    public String customer_serving_z_loc { get; set; }
    @AuraEnabled
    public String uss_quote_id { get; set; }
    @AuraEnabled
    public String customer_ref { get; set; }
    @AuraEnabled
    public Boolean hipaa_compliance { get; set; } 
    @AuraEnabled
    public Boolean pci_compliance { get; set; }
    @AuraEnabled
    public Boolean elective_pin { get; set; }
    @AuraEnabled
    public Boolean gdpr_compliance { get; set; }
    @AuraEnabled
    public Boolean cjis_compliance { get; set; }
    @AuraEnabled
    public Integer disco_reason_id { get; set; }
}