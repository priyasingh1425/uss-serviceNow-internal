@isTest
private class API_OM_SubmitContracts_Invoc_Test {

    @isTest
    static void testSubmitContract() {
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = a.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;

        Order o = new Order();
        o.AccountId = a.Id;
        o.SBQQ__Quote__c = quote.Id;
        o.EffectiveDate = Date.today();
        o.Status = 'Draft';
        insert o;

        Product2 product = new Product2();
        product.Name = 'Multi Tenant Cloud';
        product.IsActive = true; 
        product.SBQQ__SubscriptionPricing__c = 'Fixed Price'; 
        product.SBQQ__SubscriptionTerm__c = 1; 
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__ChargeType__c = 'Recurring';
        product.SBQQ__BillingFrequency__c = 'Monthly';
        product.SBQQ__BillingType__c = 'Arrears';

        Contract contract = new Contract();
        contract.AccountId = a.Id;
        contract.SBQQ__Opportunity__c = opp.Id;
        contract.SBQQ__Order__c = o.Id;
        contract.SBQQ__Quote__c = quote.Id;
        contract.Status = 'Draft'; 
        contract.StartDate = Date.today();
        contract.ContractTerm = 1;
        insert contract;

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Quantity__c = 10;
        subscription.SBQQ__NetPrice__c = 100;
        subscription.SBQQ__Contract__c = contract.Id;
        subscription.SBQQ__Account__c = a.Id;
        subscription.SBQQ__Product__c = product.Id;
        insert subscription;

        EBTLS.MockServer mock = API_OM_Connection_Util_Test.initWithToken();

        mock.whenRequest()
            .endpoint().contains('create-om-order')
            .thenReturn()
            .statusCode(200)
            .body('{'+
                '"payload_reference_id": "'+contract.Id+'",'+
                '"customer_id": 8976,'+
                '"cpq_quote_number": "Q-00910",'+
                '"account_id": 8976,'+
                '"orders": ['+
                    '{'+
                    '"services": ['+
                        '{'+
                        '"usage_rate": 2.5,'+
                        '"unit_of_measure": "Mbps",'+
                        '"service_component_id": "12,345,342,434,527,685,443",'+
                        '"secondary_usage_rate": 2.5,'+
                        '"quantity": 1,'+
                        '"nrc": 3,'+
                        '"mrc": 3,'+
                        '"discounted_from_std_rate": 0.5'+
                        '}'+
                    '],'+
                    '"provided_services": [],'+
                    '"order_data": {'+
                        '"uss_quote_id": "a1Ncb0000003dPqEAI",'+
                        '"term_cd": "36",'+
                        '"service_bandwidth_id": 70,'+
                        '"requested_due_date": "2025-03-31",'+
                        '"product_cd": "FR",'+
                        '"pci_compliance": true,'+
                        '"order_type": "Change",'+
                        '"hipaa_compliance": false,'+
                        '"gdpr_compliance": false,'+
                        '"elective_pin": true,'+
                        '"customer_ref": "TS Account",'+
                        '"cjis_compliance": false'+
                    '},'+
                    '"notes": [],'+
                    '"misc": []'+
                    '}'+
                ']'+
                '}');

        API_OM_SubmitContracts_Invoc.OMSubmitRequest req = new API_OM_SubmitContracts_Invoc.OMSubmitRequest();
        req.omOrderPayload = getOmOrderPayload(contract, quote);
        
        Test.startTest();
            try {
                API_OM_SubmitContracts_Invoc.submitContractsInvoc(new List<API_OM_SubmitContracts_Invoc.OMSubmitRequest>{req});
            } catch(API_OM_Connection_Util.OMException ex) {
                System.debug('API_OM_Connection_Util.OMException messages: ' + ex.getMessage().split(';'));
                System.assert(ex != null, 'API_OM_Connection_Util.OMException was thrown');
            } catch(Exception ex) {
                System.debug('Unexpected Exception: ' + ex.getMessage());
                System.debug(ex.getStackTraceString());
                System.assert(ex != null, 'Unexpected Exception.');
            }
        Test.stopTest();
    }

    @isTest
    static void testException(){
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = a.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;

        Order o = new Order();
        o.AccountId = a.Id;
        o.SBQQ__Quote__c = quote.Id;
        o.EffectiveDate = Date.today();
        o.Status = 'Draft';
        insert o;

        Product2 product = new Product2();
        product.Name = 'Multi Tenant Cloud';
        product.IsActive = true; 
        product.SBQQ__SubscriptionPricing__c = 'Fixed Price'; 
        product.SBQQ__SubscriptionTerm__c = 1; 
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__ChargeType__c = 'Recurring';
        product.SBQQ__BillingFrequency__c = 'Monthly';
        product.SBQQ__BillingType__c = 'Arrears';

        Contract contract = new Contract();
        contract.AccountId = a.Id;
        contract.SBQQ__Opportunity__c = opp.Id;
        contract.SBQQ__Order__c = o.Id;
        contract.SBQQ__Quote__c = quote.Id;
        contract.Status = 'Draft'; 
        contract.StartDate = Date.today();
        contract.ContractTerm = 1;
        insert contract;

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Quantity__c = 10;
        subscription.SBQQ__NetPrice__c = 100;
        subscription.SBQQ__Contract__c = contract.Id;
        subscription.SBQQ__Account__c = a.Id;
        subscription.SBQQ__Product__c = product.Id;
        insert subscription;

        EBTLS.MockServer mock = API_OM_Connection_Util_Test.initWithToken();

        API_OM_SubmitContracts_Invoc.OMSubmitRequest req = new API_OM_SubmitContracts_Invoc.OMSubmitRequest();
        req.omOrderPayload = getOmOrderPayload(contract, quote);

        Test.startTest();
            try {
                API_OM_SubmitContracts_Invoc.submitContractsInvoc(new List<API_OM_SubmitContracts_Invoc.OMSubmitRequest>{req});
            } catch(API_OM_Connection_Util.OMException ex) {
                System.debug('API_OM_Connection_Util.OMException messages: ' + ex.getMessage().split(';'));
                System.assert(ex != null, 'API_OM_Connection_Util.OMException was thrown');
            } catch(Exception ex) {
                System.debug('Unexpected Exception: ' + ex.getMessage());
                System.debug(ex.getStackTraceString());
                System.assert(ex != null, 'Unexpected Exception.');
            }
        Test.stopTest();
    }

    // Model OM JSON Objects
    private static API_OM_Order_Payload_Model getOmOrderPayload(Contract contract, SBQQ__Quote__c quote) {
        API_OM_OrderData_Model omOrderData = new API_OM_OrderData_Model();
            omOrderData.uss_quote_id = quote.Id;
            omOrderData.product_cd = 'FR';
            omOrderData.term_cd = '36';
            omOrderData.service_bandwidth_id = long.valueOf('70');
            omOrderData.requested_due_date = Date.valueOf('2025-03-31');
            omOrderData.order_type = 'Change';
            omOrderData.pci_compliance = true;
            omOrderData.hipaa_compliance = false;
            omOrderData.gdpr_compliance = false;
            omOrderData.elective_pin = true;
            omOrderData.customer_ref = 'HNB Venture Partners LLC';
            omOrderData.cjis_compliance = false;
            omOrderData.agent_company_id = 123;
            omOrderData.sales_rep_id = 123;
            omOrderData.retention_rep_id = 123;
            omOrderData.service_id = 'XXXXX/XXXXX/XXXXXXXXXX/XXXXXXXX';
            omOrderData.customer_serving_a_loc = 'XXXXXXXX';
            omOrderData.customer_serving_z_loc = 'XXXXXXXX';
            omOrderData.disco_reason_id = 20;
        API_OM_Service_Model omService = new API_OM_Service_Model();
            omService.usage_rate = 2.5;
            omService.unit_of_measure = 'Mbps';
            omService.service_component_id = '12,345,342,434,527,685,443';
            omService.secondary_usage_rate = 2.5;
            omService.quantity = 1;
            omService.nrc = 100.00;
            omService.mrc = 100.00;
            omService.discounted_from_std_rate = 0.5;
            omService.quoted_mrc = 100.00;
            omService.quoted_nrc = 100.00;
            omService.customer_ref = 'Show this on the invoice';
        API_OM_Address_Model omAddress = new API_OM_Address_Model();
            omAddress.address1 = '"201 Ionia';
            omAddress.address2 = '';
            omAddress.state = 'Grand Rapids';
            omAddress.zip = 'MI';  
            omAddress.zip4 = '49503';      
        API_OM_ProvidedService_Model omProvidedService = new API_OM_ProvidedService_Model();
            omProvidedService.service_address = omAddress;
            omProvidedService.expected_mrc = 100.00;
            omProvidedService.expected_nrc = 500.00;
            omProvidedService.ordering_clli = 'XXXXXXXX';
            omProvidedService.serving_clli = 'XXXXXXXX';
            omProvidedService.lec_vendor_id = 123;
        API_OM_Note_Model omNotes = new API_OM_Note_Model();
            omNotes.subject = 'Example Subject';
            omNotes.note = 'Example full text of note';
            omNotes.created = 'YYYY-MM-DD HH:MM:SS';
            omNotes.created_by_id = 123;
        API_OM_Misc_Model omMisc = new API_OM_Misc_Model();
            omMisc.grouping_id = 'OD2';
            omMisc.grouping_label = 'Secondary OrderData';
            omMisc.key_id = 'K123';
            omMisc.key_label = 'Does Warp Drive Apply?';
            omMisc.value = 'Yes – Now that Warp Drives Exist';
        API_OM_Attachment_Model omAttachment = new API_OM_Attachment_Model();
            omAttachment.file_id = '0698M000001wN0iQAE';
            omAttachment.file_name = 'Content Syndication Report – Acronis.pdf';
            omAttachment.mime_type = 'application/pdf';
            omAttachment.uploaded_date = 'YYYY-MM-DD HH:MM:SS';
        API_OM_Contact_Model omContact = new API_OM_Contact_Model();
            omContact.contact_id = '200454';
            omContact.contact_type_cd = 'PF';

        API_OM_Order_Model omOrder = new API_OM_Order_Model();
        	omOrder.order_reference_id = contract.SBQQ__Order__r.OrderNumber;
        	omOrder.description = 'Test OM';
        	omOrder.internal_reference = contract.Name;
            omOrder.order_data = omOrderData;
            omOrder.services.add(omService);
            omOrder.provided_services.add(omProvidedService);
            omOrder.notes.add(omNotes);
            omOrder.misc.add(omMisc); 

        API_OM_Order_Payload_Model omOrderPayload = new API_OM_Order_Payload_Model(String.valueOf(contract.Id), quote.Name, long.valueOf('123456789'), long.valueOf('123456789'), long.valueOf('123456789'), '');
            omOrderPayload.orders.add(omOrder);
            omOrderPayload.attachments.add(omAttachment);
            omOrderPayload.contacts.add(omContact);

        return omOrderPayload;
    }
}