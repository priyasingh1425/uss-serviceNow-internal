public class API_OM_SubmitOrdersContact_Model {
    @AuraEnabled
    @InvocableVariable(label='Contact CRM Id')
    public String contact_id;

    @AuraEnabled
    @InvocableVariable(label='Contact Type')
    public String contact_type_cd;

    public API_OM_SubmitOrdersContact_Model(String contactId, String type){
        this.contact_id = contactId;
        this.contact_type_cd = type;
    }

    @InvocableMethod(label='Generate OM Contact' category='OM Integration')
    public static List<OMContactResponse> generate(List<OMContactRequest> requests){
        List<OMContactResponse> contacts = new List<OMContactResponse>();
        for(OMContactRequest req:requests){
            contacts.add(new OMContactResponse(new API_OM_SubmitOrdersContact_Model(req.crmId, req.type)));
        }

        return contacts;
    }

    public class OMContactRequest{
        @InvocableVariable(label='OM Contact Type' required=true)
        public String type;
        @InvocableVariable(label='Contact CRM Id' required=true)
        public String crmId;
    }

    public class OMContactResponse{
        @InvocableVariable(label='OM Contact')
        public API_OM_SubmitOrdersContact_Model omContact;

        public OMContactResponse(API_OM_SubmitOrdersContact_Model omContact){
            this.omContact = omContact;
        }
    }
}