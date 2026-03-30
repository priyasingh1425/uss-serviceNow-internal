/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_Order_Payload_Model {
    
    @AuraEnabled
    public string payload_reference_id;
    @AuraEnabled
    public String cpq_quote_number;
    @AuraEnabled
    public Long customer_id;
    @AuraEnabled
    public Long account_id;
    @AuraEnabled
    public Long created_by_id;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public List<API_OM_Order_Model> orders;
    @AuraEnabled
    public List<API_OM_Attachment_Model> attachments;
    @AuraEnabled
    public List<API_OM_Contact_Model> contacts;

    public API_OM_Order_Payload_Model(){}

    public API_OM_Order_Payload_Model(String referenceId, String referenceName, Long customerId, Long accountId, Long createdById, String description) {
        this.payload_reference_id = referenceId;
        this.cpq_quote_number = referenceName;
        this.customer_id = customerId;
        this.account_id = accountId;
        this.created_by_id = createdById;
        this.description = description;
        this.orders = new List<API_OM_Order_Model>();
        this.attachments = new List<API_OM_Attachment_Model>();
        this.contacts = new List<API_OM_Contact_Model>();
    }
}