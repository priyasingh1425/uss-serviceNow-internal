/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration 
**/
public class API_OM_Order_Model {

    @AuraEnabled
    public String order_reference_id { get; set; }
    @AuraEnabled
    public String description { get; set; }
    @AuraEnabled
    public String internal_reference { get; set; }
    @AuraEnabled
    public API_OM_OrderData_Model order_data;
    @AuraEnabled
    public List<API_OM_Service_Model> services;
    @AuraEnabled
    public List<API_OM_ProvidedService_Model> provided_services;
    @AuraEnabled
    public List<API_OM_Note_Model> notes;
    @AuraEnabled
    public List<API_OM_Misc_Model> misc;

    public API_OM_Order_Model() {
        order_data = new API_OM_OrderData_Model();
        services = new List<API_OM_Service_Model>();
        provided_services = new List<API_OM_ProvidedService_Model>();
        notes = new List<API_OM_Note_Model>();
        misc = new List<API_OM_Misc_Model>();
    }
}