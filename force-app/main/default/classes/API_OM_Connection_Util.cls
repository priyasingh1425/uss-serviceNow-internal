/**
 * This class handles the API connection between Salesforce and Omni. It leverages
 * a named credential and external credential for authentication, initializing a
 * token when the service is created.
 *
 * Failured requests are logged to the API_Response__c object via the API_OM_RequestLogger
 * class.
 *
 * Callouts utilize the EB Tools - Callout Utilities package, which is a framework
 * for semantically creating requests, logging activities, and testing.
 * https://bitbucket.org/eidebailly/eb-tools-callout-utilities
 * 
 * SC-0000187 Case 00509459: Refactored createOrders and added method sendRequestToOmni to pass in a json serialized payload.
 * */
public with sharing class API_OM_Connection_Util {
    private static API_OM_Connection_Util service;

    @testVisible private String authToken;

    private static FINAL String NAMED_CREDENTIAL = 'OM_API';
    private static FINAl String EXT_CREDENTIAL_KEY = 'OM_DEV.API_KEY';

    private API_OM_Connection_Util() {
        authToken = getToken();
    }

    public static API_OM_Connection_Util getService(){
        if(service == null){
            service = new API_OM_Connection_Util();
            EBTLS.HttpRequestBuilder.enableLogging(new API_OM_RequestLogger());
        }
        return service;
    }

    @testVisible
    public static String getToken(){
        try{
            HttpResponse resp = ebtls.HttpRequestBuilder.post()
                .namedCredential(NAMED_CREDENTIAL)
                .endpoint('/get-token')
                .multipartBody()
                .addField('api_key', '{!$Credential.' + EXT_CREDENTIAL_KEY + '}')
                .setMultipartBody()
                .send();

            //Handle error response
            if(resp.getStatusCode() < 500){
                TokenResponse apiResp = (TokenResponse) JSON.deserialize(resp.getBody(), TokenResponse.class);

                if(apiResp.success){
                    //Return the valid token
                    return apiResp.data.token;
                }else{
                    throw new OMException(apiResp.error + ':' + apiResp.message);
                }
            }

            System.debug(resp.getBody());

            //Handle catastrphic failures from remote server.
            throw new OMException(resp.getStatusCode() + ':' + resp.getStatus());
        }catch(OMException ex){
            throw ex;
        }catch(Exception ex){
            System.debug('An unknown exception occurred ' + ex);
            throw new OMException('An unknown exception occurred.', ex);
        }
    }

    public QuoteStatus createOrders(String referenceId, String referenceName, Long customerId, Long accountId, Long createdById, String description, List<Order> orders, List<Attachment> attachments, List<Contact> contacts){
        CreateOrderRequest req = new CreateOrderRequest(referenceId, referenceName, customerId, accountId, createdById);
        req.description = description;
        req.orders = orders;
        req.attachments = attachments;
        req.contacts = contacts;

        return sendRequestToOmni(JSON.serialize(req, true));
    }

    public QuoteStatus sendRequestToOmni(String serializedPayload) {
        try{
            HttpResponse resp = ebtls.HttpRequestBuilder.post()
            .namedCredential(NAMED_CREDENTIAL)
            .endpoint('/create-om-order')
            .header('Authorization', 'Bearer ' + authToken)
            .header('Content-Type', 'application/json')
            .body(serializedPayload)
            .send();

            if(resp.getStatusCode() < 500){
                System.debug(resp.getBody());
                OrderResponse apiResp = (OrderResponse) JSON.deserialize(resp.getBody(), OrderResponse.class);

                if(apiResp.success){
                    return apiResp.data;
                }else if(apiResp.message != null){ //The general failure case
                    throw new OMException(apiResp.error + ':' + apiResp.message);
                }else{//Handle list of validation failures.
                    String message = '';
                    for(Message m:apiResp.messages){
                        if(m.field == 'general'){
                            message += m.message + ';';
                        }else{
                            message += m.field + ':' + m.message + ';';
                        }
                    }
                    throw new OMException(message);
                }
            }

            throw new OMException(resp.getStatusCode() + ':' + resp.getStatus());
        }catch(OMException ex){
            throw ex;
        }catch(Exception ex){
            throw new OMException('An unknown exception occurred.', ex);
        }
    }

    public QuoteStatus getQuoteStatus(String referenceId){
        try{
            HttpResponse resp = ebtls.HttpRequestBuilder.get()
                .namedCredential(NAMED_CREDENTIAL)
                .endpoint('/order-state-inquiry?payload_reference_id=' + referenceId)
                .header('Authorization', 'Bearer ' + authToken)
                .header('Content-Type', 'application/json')
                .send();

            if(resp.getStatusCode() < 500){
                System.debug(resp.getBody());
                OrderResponse apiResp = (OrderResponse) JSON.deserialize(resp.getBody(), OrderResponse.class);

                if(apiResp.success){
                    return apiResp.data;
                }else if(apiResp.message != null){
                    throw new OMException(apiResp.error + ':' + apiResp.message);
                }else{
                    String message = '';
                    for(Message m:apiResp.messages){
                        if(m.field == 'general'){
                            message += m.message + ';';
                        }else{
                            message += m.field + ':' + m.message + ';';
                        }
                    }
                    throw new OMException(message);
                }
            }

            throw new OMException(resp.getStatusCode() + ':' + resp.getStatus());
        }catch(OMException ex){
            throw ex;
        }catch(Exception ex){
            throw new OMException('An unknown exception occurred.', ex);
        }
    }

    private class CreateOrderRequest{
        string payload_reference_id;
        String cpq_quote_number;
        Long customer_id;
        Long account_id;
        Long created_by_id;
        String description;
        List<Order> orders;
        List<Attachment> attachments;
        List<Contact> contacts;

        public CreateOrderRequest(
            String referenceId,
            String referenceName,
            Long customerId,
            Long accountId,
            Long createdById
        ){
            this.payload_reference_id = referenceId;
            this.cpq_quote_number = referenceName;
            this.customer_id = customerId;
            this.account_id = accountId;
            this.created_by_id = createdById;
            this.orders = new List<Order>();
            this.attachments = new List<Attachment>();
            this.contacts = new List<Contact>();
        }
    }

    public class Order{
        public String order_reference_id;
        public String description;
        public String internal_reference;
        public OrderData order_data;
        public List<Service> services;
        public List<ProvidedService> provided_services;
        public List<Note> notes;
        public List<Misc> misc;

        public Order(){
            order_data = new OrderData();
            services = new List<Service>();
            provided_services = new List<ProvidedService>();
            notes = new List<Note>();
            misc = new List<Misc>();
        }

        public Order(String orderReference){
            order_data = new OrderData();
            services = new List<Service>();
            provided_services = new List<ProvidedService>();
            notes = new List<Note>();
            misc = new List<Misc>();

            order_reference_id = orderReference;
        }
    }

    public class OrderData{
        public String product_cd;
        public String term_cd;
        public Date requested_due_date;
        public Long agent_company_id;
        public Long sales_rep_id;
        public Long retention_rep_id;
        public String order_type;
        public String service_id;
        public Long service_bandwidth_id;
        public String customer_serving_a_loc;
        public String customer_serving_z_loc;
        public String uss_quote_id;
        public String customer_ref;
        public Boolean hipaa_compliance;
        public Boolean pci_compliance;
        public Boolean elective_pin;
        public Boolean gdpr_compliance;
        public Boolean cjis_compliance;
    }

    public class Service{
        public Long service_component_id;
        public Decimal mrc;
        public Decimal nrc;
        public Decimal quoted_mrc;
        public Decimal quoted_nrc;
        public Decimal quantity;
        public Decimal usage_rate;
        public Decimal secondary_usage_rate;
        public String unit_of_measure;
        public String customer_ref;
        public Decimal discounted_from_std_rate;
    }

    public class ProvidedService{
        public Decimal expected_mrc;
        public Decimal expected_nrc;
        public String ordering_clli;
        public String serving_clli;
        public Long lec_vendor_id;
        public Address service_address;
    }

    public class Note{
        public String subject;
        public String note;
        public String created;
        public Long created_by_id;
    }

    public class Misc{
        public String grouping_id;
        public String grouping_label;
        public String key_id;
        public String key_label;
        public String value;
    }

    public class Attachment{
        public String file_id;
        public String file_name;
        public String mime_type;
        public String uploaded_date;

        public Attachment(String fileId, String fileName, String mimeType, String uploadedDate){
            this.file_id = fileId;
            this.file_name = fileName;
            this.mime_type = mimeType;
            this.uploaded_date = uploadedDate;
        }

        public Attachment(ContentVersion cv){
            this.file_id = cv.Id;
            this.file_name = cv.Title;
            this.mime_type = cv.FileExtension;
            this.uploaded_date = cv.CreatedDate?.formatGMT('yyyy-MM-dd HH:mm:ss');
        }
    }

    public class Contact{
        public String contact_id;
        public String contact_type_cd;

        public Contact(String contactId, String contactType){
            this.contact_id = contactId;
            this.contact_type_cd = contactType;
        }
    }

    public class Address{
        public String address1;
        public String address2;
        public String city;
        public String state;
        public String zip;
        public String zip4;
    }

    public virtual class APIResponse{
        public Boolean success;
        public Integer error;
        public String code;
        public String message;
        public List<Message> messages;
    }

    public class Message{
        public String message;
        public String type;
        public String field;
    }

    public class TokenResponse extends APIResponse{
        public Token data;
    }

    public class Token{
        public String token;
    }

    public class OrderResponse extends APIResponse{
        public QuoteStatus data;
    }

    public class QuoteStatus{
        public String payload_reference_id;
        public String payload_state;
        public List<Message> messages;
        public List<OrderStatus> orders;
    }

    public class OrderStatus{
        public String order_reference_id;
        public String order_state;
        public String om_order_number;
        public String service_id;
        public Date bill_start_date;
        public Date contract_start_date;
        public List<Message> messages;
        public Integer rejection_reason_id;
        public String rejection_reason;
        public String rejection_note;
    }

    public class OMException extends Exception{}
}