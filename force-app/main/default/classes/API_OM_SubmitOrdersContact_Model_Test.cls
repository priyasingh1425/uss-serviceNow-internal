@isTest
public with sharing class API_OM_SubmitOrdersContact_Model_Test {
    @isTest
    public static void createOrderContact(){
        API_OM_SubmitOrdersContact_Model.OMContactRequest req = new API_OM_SubmitOrdersContact_Model.OMContactRequest();
        req.crmId = '12345';
        req.type = 'primary';
        List<API_OM_SubmitOrdersContact_Model.OMContactResponse> responses = API_OM_SubmitOrdersContact_Model.generate(new List<API_OM_SubmitOrdersContact_Model.OMContactRequest>{req});

        Assert.areEqual(1, responses.size());
        Assert.areEqual('12345', responses[0].omContact.contact_id);
        Assert.areEqual('primary', responses[0].omContact.contact_type_cd);
    }
}