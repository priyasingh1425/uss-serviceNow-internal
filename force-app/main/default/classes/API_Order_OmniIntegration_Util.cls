/**
 * This class contains the business logic for transforming CPQ Quotes and Orders
 * into and Omni acceptable payload.
 */
public with sharing class API_Order_OmniIntegration_Util {

    private static API_Order_OmniIntegration_Util serviceInstance;
    public static API_Order_OmniIntegration_Util getService(){
        if(serviceInstance == null){
            serviceInstance = new API_Order_OmniIntegration_Util();
        }

        return serviceInstance;
    }

    @testVisible
    private Long runningUserCRMId;
    @testVisible
    private Set<String> orderFields = new Set<String>();
    @testVisible
    private Set<String> orderItemFields = new Set<String>();
    @testVisible
    private Set<String> subscriptionFields = new Set<String>();
    @testVisible
    private Map<String, Schema.FieldSet> orderFieldSets = Order.getSObjectType().getDescribe().fieldsets.getMap();
    @testVisible
    private Map<String, Schema.FieldSet> orderItemFieldSets = OrderItem.getSObjectType().getDescribe().fieldsets.getMap();

    public API_Order_OmniIntegration_Util(){
        loadRunningUser();
        loadFields();
        loadFieldSets(orderFieldSets, orderFields);
        loadFieldSets(orderItemFieldSets, orderItemFields);
    }

    private void loadRunningUser(){
        User u = [SELECT Id, CRM_User_ID__c from User WHERE Id = :UserInfo.getUserId()];
        runningUserCRMId = u.CRM_User_ID__c != null ? Long.valueOf(u.CRM_User_ID__c) : 9999;
    }

    private String getSOQLFields(Set<String> fieldSet, String prefix){
        if(prefix == null){
            prefix = '';
        }

        List<String> fields = new List<String>();
        for(String field:fieldSet){
            fields.add(prefix + field);
        }
        return String.join(fields, ',');
    }

    /**
     * This method forces any hardcoded fields to be included in the query. Additional
     * fields are added via field sets.
     */
    private void loadFields(){
        orderFields.add('OrderNumber');
        orderFields.add('Description');
        orderFields.add('Partner__r.CRM_Id__c');
        orderFields.add('Sales_Rep__r.CRM_User_ID__c');
        orderFields.add('Opportunity.Client_Development_Rep__r.CRM_User_ID__c');
        orderFields.add('Elective_Pin__c');
        orderFields.add('HIPAA_Is_a_Bus_Associates_Agr_Required__c');
        orderFields.add('HIPAA_ePHI_Present__c');
        orderFields.add('PCI_DSS_Cardholder_data_present__c');
        orderFields.add('GDPR_Personal_or_Sensitive_Data_Present__c');
        orderFields.add('CJIS_Maintain_Criminal_Justice_Info__c');
        
        orderItemFields.add('SBQQ__QuoteLine__r.Order_Type__c');

        //orderItemFields.add('Order_Type__c');
        orderItemFields.add('SBQQ__QuoteLine__r.SBQQ__RequiredBy__c');
        orderItemFields.add('SBQQ__QuoteLine__r.SBQQ__Product__r.ProductCode');
        orderItemFields.add('SBQQ__QuoteLine__c');
        orderItemFields.add('LastModifiedDate');
        orderItemFields.add('LastModifiedBy.CRM_User_Id__c');
        orderItemFields.add('Product2.ProductCode');
        orderItemFields.add('SBQQ__SubscriptionTerm__c');
        orderItemFields.add('ServiceDate');
        orderItemFields.add('EndDate');
        orderItemFields.add('Service_Component_Id__c');
        orderItemFields.add('Circuit_ID__c');
        orderItemFields.add('Product_Bandwidth__c');
        orderItemFields.add('Customer_Reference__c');
        orderItemFields.add('SBQQ__RequiredBy__c');
        orderItemFields.add('Facility__c');
        orderItemFields.add('Backup_Target_Data_Center__c');
        orderItemFields.add('Location__c');
        orderItemFields.add('External_Quote_Id__c');
        // orderItemFields.add('Ordering_Location__c');
        orderItemFields.add('Customer_Service_Location__c');
        //orderItemFields.add('MRC__c');
        orderItemFields.add('OM_MRC__c');
        orderItemFields.add('NRC_Price__c');
        // orderItemFields.add('Vendor_Id__c');
        orderItemFields.add('Unit_of_Measure__c');
        //orderItemFields.add('Quantity');
        orderItemFields.add('OM_Quantity__c');
        orderItemFields.add('Product2.Provided_Service_Required__c');
        orderItemFields.add('Product2.OM_Field_Sets_Order_Item__c');
        orderItemFields.add('Product2.Usage_Product__c');
        orderItemFields.add('SBQQ__QuotedListPrice__c');
        // orderItemFields.add('Backup_Address__Street__s');
        // orderItemFields.add('Backup_Address__City__s');
        // orderItemFields.add('Backup_Address__StateCode__s');
        // orderItemFields.add('Backup_Address__PostalCode__s');
        // orderItemFields.add('Address__c');
        // orderItemFields.add('Address_2__c');
        // orderItemFields.add('City__c');
        // orderItemFields.add('Zip__c');
        orderItemFields.add('Order_Notes__c');
        orderItemFields.add('Product2.Retail_Service_Component_ID__c');
        orderItemFields.add('Product2.Wholesale_Service_Component_ID__c');
        orderItemFields.add('SBQQ__QuoteLine__r.SBQQ__Discount__c');
        
        subscriptionFields.add('Circuit_ID__c');

    }

    /**
     * This method loads dynamic fields based on the field sets perfixed with OM_
     * on the Order and OrderItem.
     */
    private void loadFieldSets(Map<String, Schema.FieldSet> fieldSetMap, Set<String> fields){
        for(String key:fieldSetMap.keySet()){
            if(key.startsWithIgnoreCase('OM_')){
                for(Schema.FieldSetMember fsMember:fieldSetMap.get(key).getFields()){
                    fields.add(fsMember.getFieldPath());
                }
            }
        }
    }

    public OfsStatus checkOrderStatus(String payloadId){
        API_OM_Connection_Util.QuoteStatus status = API_OM_Connection_Util.getService()
            .getQuoteStatus(payloadId);

        return parseStatus(status);
    }

    public OfsStatus parseStatus(API_OM_Connection_Util.QuoteStatus status){
        OfsStatus qs = new OfsStatus();

        qs.quote = parseQuoteStatus(status);
        qs.orders.addAll(parseBundlesStatus(status.orders));
        return qs;
    }

    public SBQQ__Quote__c parseQuoteStatus(API_OM_Connection_Util.QuoteStatus status){
        return new SBQQ__Quote__c(Id=status.payload_reference_id, OM_Payload_Status__c = status.payload_state);
    }

    public List<Order> parseBundlesStatus(List<API_OM_Connection_Util.OrderStatus> statuses){
        List<Order> lines = new List<Order>();
        if(statuses == null){
            return lines;
        }
        for(API_OM_Connection_Util.OrderStatus orderStatus:statuses){
            Order o = new Order();
            o.Id = orderStatus.order_reference_id;
            o.OM_Status__c = orderStatus.order_state;
            o.OM_Order_Number__c = orderStatus.om_order_number;
            o.Circuit_ID__c = orderStatus.service_id;
            o.Bill_Start_Date__c = orderStatus.bill_start_date;
            if(orderStatus.contract_start_date != null){
                o.EffectiveDate = orderStatus.contract_start_date;
            }
            lines.add(o);
        }
        return lines;
    }

    public void submitOrders(String quoteId, List<API_OM_SubmitOrdersContact_Model> omContacts, List<Id> fileIds){
        // SBQQ__Quote__c quote = getQuote(quoteId);

        // Map<Id, Order> ofsOrders = getOrders(quoteId);

        OfsPayloadData payloadData = getPayloadData(quoteId);

        // List<API_OM_Connection_Util.Order> orders = createOrders(ofsOrders);
        List<API_OM_Connection_Util.Order> orders = createOrders(payloadData.orders.values());
        List<API_OM_Connection_Util.Attachment> attachments = createAttachments(fileIds);
        List<API_OM_Connection_Util.Contact> contacts = createContacts(omContacts);

        API_OM_Connection_Util.QuoteStatus status = API_OM_Connection_Util.getService()
        .createOrders(
            quoteId,
            payloadData.quote.Name,
            convertToLong(payloadData.quote.SBQQ__Account__r?.CRM_ID__c?.substring(1)),
            convertToLong(payloadData.quote.Account_Account_Name__r?.CRM_Id__c?.substring(1)),
            runningUserCRMId,
            payloadData.quote.SBQQ__Opportunity2__r?.Name,
            orders,
            attachments,
            contacts
        );

        OfsStatus statusObjects = parseStatus(status);
        update statusObjects.orders;
        update statusObjects.quote;
    }

    /**
     * This unified query method loads the data in such a way as to combine
     * multiple orders in amendment scenarios.
     */
    public OfsPayloadData getPayloadData(String quoteId){
        OfsPayloadData data = new OfsPayloadData();
        data.quote = getQuote(quoteId);

        for(Order o:data.quote.SBQQ__Orders__r){
            OfsOrderData orderData = new OfsOrderData();
            data.orders.put(o.Id, orderData);

            orderData.order = o;

            String rootId;
            Set<Id> linesOrdered = new Set<Id>();

            for(OrderItem item:o.OrderItems){
                //This root line calculation works for the current 2-level hierarchy. If that
                //expands, then this will need to change as well.
                if(item.Product2.ProductCode != null){
                    rootId = item.SBQQ__QuoteLine__c;
                    orderData.rootItem = item;
                }else{
                    rootId = item.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c;
                    orderData.lines.add(item);
                }

                linesOrdered.add(item.SBQQ__QuoteLine__c);
            }
            for(SBQQ__QuoteLine__c line:data.quote.SBQQ__LineItems__r){
                //Its in the right order
                if(rootId == line.SBQQ__RequiredBy__c || rootId == line.Id){
                    if(linesOrdered.contains(line.Id)){
                        continue;
                    }
                    if(line.SBQQ__Product__r.ProductCode != null){
                        orderData.rootItem = line.SBQQ__UpgradedSubscription__r.SBQQ__OrderProduct__r;
                        orderData.rootItem.Order_Type__c = 'Change';
                        if(orderData.rootItem.Circuit_ID__c == null){
                            orderData.rootItem.Circuit_ID__c = line.SBQQ__UpgradedSubscription__r.Circuit_ID__c;
                        }
                    }else{
                        orderData.lines.add(line.SBQQ__UpgradedSubscription__r.SBQQ__OrderProduct__r);
                    }
                }
            }
        }

        return data;
    }

    private SBQQ__Quote__c getQuote(String quoteId){
        Map<String, Object> bindsMap = new Map<String, Object>();
        bindsmap.put('quoteId', quoteId);

        //Quote Query
        String query = '';
        query += 'SELECT Id, Name,';
        query += 'Account_Account_Name__r.CRM_Id__c,';
        query += 'SBQQ__Account__r.CRM_Id__c,';
        query += 'SBQQ__SalesRep__r.CRM_User_Id__c,';
        query += 'SBQQ__Opportunity2__r.Name,';

        //Orders Subselect
        query += '(';
        query += 'SELECT Id, ';
        query += getSOQLFields(orderFields, '') + ', ';
        //Order Items Subselect
        query += '(';
        query += 'SELECT Id, ';
        query += getSOQLFields(orderItemFields, '');
        query += ' FROM OrderItems';
        query += ') ';
        query += 'FROM SBQQ__Orders__r';
        query += '),';

        //Quote Lines Subselect (to identify amendements)
        query += '(';
        query += 'SELECT Id, ';
        query += 'SBQQ__RequiredBy__c,';
        query += 'SBQQ__Product__r.ProductCode,';
        query += 'SBQQ__UpgradedSubscription__r.SBQQ__OrderProduct__r.Id, ';
        query += getSOQLFields(orderItemFields, 'SBQQ__UpgradedSubscription__r.SBQQ__OrderProduct__r.');
        query += ', ';
        query += getSOQLFields(subscriptionFields, 'SBQQ__UpgradedSubscription__r.');
        query += ' FROM SBQQ__LineItems__r';
        query += ' WHERE SBQQ__UpgradedSubscription__c != null';
        query += ') ';

        //Quote Query
        query += 'FROM SBQQ__Quote__c ';
        query += 'WHERE Id = :quoteId ';
        query += 'LIMIT 1';

        return Database.queryWithBinds(query, bindsMap, AccessLevel.SYSTEM_MODE);
    }


    private Map<Id, Order> getOrders(String payloadId){
        String query = 'SELECT ';
        query += getSOQLFields(orderFields, '') + ', ';
        query += '(SELECT Id, ' + getSOQLFields(orderItemFields, '');
        query += ' FROM OrderItems) ';
        query += 'FROM Order ';
        query += 'WHERE SBQQ__Quote__c = \'' + payloadId + '\'';
        return new Map<Id, Order>((List<Order>) Database.query(query));
    }

    private List<API_OM_Connection_Util.Order> createOrders(List<OfsOrderData> ofsOrders){
        List<API_OM_Connection_Util.Order> orders = new List<API_OM_Connection_Util.Order>();

        for(OfsOrderData order:ofsOrders){
            orders.add(createOrder(order));
        }

        return orders;
    }

    private API_OM_Connection_Util.Order createOrder(OfsOrderData orderData){
        API_OM_Connection_Util.Order omOrder = new API_OM_Connection_Util.Order(orderData.order.Id);
        omOrder.internal_reference = orderData.order.OrderNumber;
        omOrder.description = orderData.order.Description;
        omOrder.order_data = createOrderData(orderData);

        omOrder.misc.addAll(addMiscFromLine(orderData.rootItem));

        for(OrderItem serviceLine:orderData.lines){
            //Create Miscs on Order Item
            omOrder.misc.addAll(addMiscFromLine(serviceLine));

            //Provided Services
            if(serviceLine.Product2.Provided_Service_Required__c){//Has Location
                omOrder.provided_services.addAll(createProvidedServices(orderData.lines));
            }

            //Create Services (if not a secondary usage charge)
            if(serviceLine.Product2?.Retail_Service_Component_ID__c.contains('USAGE')){
                //skip
            } else {
            	omOrder.services.add(createService(omOrder.order_data, serviceLine, orderData.lines));                
            }

        }

        //Create Miscs on Order
        for(Schema.FieldSet fieldSet:orderFieldSets.values()){
            if(fieldSet.getName().startsWithIgnoreCase('OM_')){
                for(Schema.FieldSetMember member:fieldSet.getFields()){
                    API_OM_Connection_Util.Misc misc = createMisc(orderData.order, fieldSet, member);
                    if(misc != null){
                        omOrder.misc.add(misc);
                    }
                }
            }
        }

        // Create Notes
        if(orderData.rootItem.Order_Notes__c != null){
            omOrder.notes.add(createOrderNote(orderData.rootItem));
        }
        for(OrderItem line:orderdata.lines){
            if(line.Order_Notes__c != null){
                omOrder.notes.add(createOrderNote(line));
            }
        }

        return omOrder;
    }

    @testVisible
    private API_OM_Connection_Util.OrderData createOrderData(OfsOrderData ofsOrderData){
        API_OM_Connection_Util.OrderData orderData = new API_OM_Connection_Util.OrderData();

        Order order = ofsOrderData.order;
        OrderItem line = ofsOrderData.rootItem;

        if(line != null){
            orderData.product_cd = line.Product2.ProductCode;
            Integer months = 0;
            if(line.SBQQ__SubscriptionTerm__c != null){
                months = Integer.valueOf(line.SBQQ__SubscriptionTerm__c);
            }else if(line.EndDate != null){
                months = line.ServiceDate.monthsBetween(line.EndDate);
            }
            if(Math.mod(months, 12) == 0){
                orderData.term_cd = String.valueOf(months / 12) + 'Y';
            }else{
                orderData.term_cd = String.valueOf(months) + 'M';
            }
            orderData.requested_due_date = line.ServiceDate;
            orderData.service_id = line.Circuit_ID__c;

            orderData.service_bandwidth_id = calculateServiceBandwidth(line.Product_Bandwidth__c);
            orderData.customer_serving_a_loc = getLocation(true, line, ofsOrderData.lines);
            orderData.customer_serving_z_loc = getLocation(false, line, ofsOrderData.lines);
            orderData.uss_quote_id = line.External_Quote_Id__c;
            orderData.customer_ref = line.Customer_Reference__c;
            
            try{
                line.SBQQ__QuoteLine__r.Order_Type__c = line.Order_Type__c; 
            }catch(Exception e){
                System.debug('order is not an amendment from a subscription: system message::: ' + e);
            }
            orderData.order_type = line.SBQQ__QuoteLine__r.Order_Type__c;
        }

        orderData.agent_company_id = convertToLong(order.Partner__r?.CRM_Id__c?.substring(2));
        orderData.sales_rep_id = convertToLong(order.Sales_Rep__r?.CRM_User_ID__c);
        orderData.retention_rep_id = convertToLong(order.Opportunity.Client_Development_Rep__r?.CRM_User_ID__c);
        orderData.elective_pin = order.Elective_Pin__c;
        orderData.hipaa_compliance = order.HIPAA_Is_a_Bus_Associates_Agr_Required__c || order.HIPAA_ePHI_Present__c;
        orderData.pci_compliance = order.PCI_DSS_Cardholder_data_present__c;
        orderData.gdpr_compliance = order.GDPR_Personal_or_Sensitive_Data_Present__c;
        orderData.cjis_compliance = order.CJIS_Maintain_Criminal_Justice_Info__c;

        return orderData;
    }

    /**
     * Slated for deprecation
     */
    private OrderItem getRootOrderLine(List<OrderItem> items){
        if(items != null){
            for(OrderItem item:items){
                if(item.SBQQ__RequiredBy__c == null){
                    return item;
                }
            }
        }
        return null;
    }

    @testVisible
    private String getLocation(Boolean isA, OrderItem line, List<OrderItem> orderItems){
        if(isA){
            if(line.Facility__c != null){
                return line.Facility__c;
            }
            if(line.Backup_Target_Data_Center__c != null){
                return line.Backup_Target_Data_Center__c;
            }
        }else{
            if(line.Backup_Target_Data_Center__c != null){
                return line.Backup_Target_Data_Center__c;
            }
            if(line.Facility__c != null){
                return line.Facility__c;
            }

            for(OrderItem item:orderItems){
                if(isValidLocation(item)){
                    if(item.Location__c == 'Z' && item?.Customer_Service_Location__c != null){
                        return item.Customer_Service_Location__c;
                    }
                }
            }
        }
        for(OrderItem item:orderItems){
            if(isValidLocation(item)){
                if(item.Location__c == 'A' && item?.Customer_Service_Location__c != null){
                    return item.Customer_Service_Location__c;
                }
            }
        }
        return null;
    }

    private List<API_OM_Connection_Util.ProvidedService> createProvidedServices(List<OrderItem> orderItems){
        List<API_OM_Connection_Util.ProvidedService> pservices = new List<API_OM_Connection_Util.ProvidedService>();

        for(OrderItem line:orderItems){
            if(line.Product2.ProductCode == null && line.Facility__c != null){
                pservices.add(createProvidedService(line, 'Facility__c'));
            }

            if(line.SBQQ__RequiredBy__c == null && line.Backup_Target_Data_Center__c != null){
                pservices.add(createProvidedService(line, 'Backup_Target_Data_Center__c'));
            }

            if(line.SBQQ__RequiredBy__c != null && isValidLocation(line)){
                if(line.Location__c == 'A' || line.Location__c == 'Z'){
                    pservices.add(createProvidedService(line, null));
                }
            }
        }
        return pservices;
    }

    @testVisible
    private Boolean isValidLocation(OrderItem line){
        return
            line.Facility__c != null ||
            line.Backup_Target_Data_Center__c != null ||
            //line.Ordering_Location__c != null ||
            line.Customer_Service_Location__c != null;
    }

    private API_OM_Connection_Util.ProvidedService createProvidedService(OrderItem line, String target){
        API_OM_Connection_Util.ProvidedService providedService = new API_OM_Connection_Util.ProvidedService();

        providedService.expected_mrc = line.OM_MRC__c;
        providedService.expected_nrc = line.NRC_Price__c;
        // if(line.Vendor_Id__c != null){
        //     providedService.lec_vendor_id = convertToLong(line.Vendor_ID__c);
        // }

        // providedService.service_address = createAddress(line, target);

        if(target == null){
            // providedService.ordering_clli = line.Ordering_Location__c;
            providedService.serving_clli = line.Customer_Service_Location__c;
        }else{
            providedService.ordering_clli = (String) line.get(target);
            providedService.serving_clli = (String) line.get(target);
        }

        return providedService;
    }

    @testVisible
    private API_OM_Connection_Util.Service createService(API_OM_Connection_Util.OrderData orderData, OrderItem line, List<OrderItem> lines){
        API_OM_Connection_Util.Service service = new API_OM_Connection_Util.Service();

        service.service_component_id = convertToLong(line.Service_Component_Id__c);
        service.mrc = line.OM_MRC__c;
        service.nrc = line.NRC_Price__c;
        service.quoted_mrc = line.OM_MRC__c;
        service.quoted_nrc = line.NRC_Price__c;
        if(line.SBQQ__QuoteLine__r.SBQQ__Discount__c == null){
            service.discounted_from_std_rate = 0;
        } else {
            service.discounted_from_std_rate = line.SBQQ__QuoteLine__r.SBQQ__Discount__c;
        }
            
        service.quantity = line.OM_Quantity__c;
        service.unit_of_measure = line.Unit_of_Measure__c != null ? line.Unit_of_Measure__c : 'Each';
        service.customer_ref = line.Customer_Reference__c;

        if(line.Product2?.Usage_Product__c == true){
            service.mrc = 0;
            service.nrc = 0;

            service.usage_rate = line.SBQQ__QuotedListPrice__c;
            
            for(OrderItem i: lines){
                if(i.Product2?.Retail_Service_Component_ID__c.contains('USAGE')){
                    if(i.Product2?.Retail_Service_Component_ID__c.contains(line.Service_Component_Id__c) || i.Product2?.Wholesale_Service_Component_ID__c.contains(line.Service_Component_Id__c)){
                        service.secondary_usage_rate = i.SBQQ__QuotedListPrice__c;
                    }
                }
            }

        }

        return service;
    }

    // private API_OM_Connection_Util.Address createAddress(OrderItem line, String type){
    //     if(line == null){
    //         return null;
    //     }

    //     API_OM_Connection_Util.Address add = new API_OM_Connection_Util.Address();
    //     if(type == 'Backup_Target_Data_Center__c'){
    //         add.address1 = line.Backup_Address__Street__s;
    //         add.city = line.Backup_Address__City__s;
    //         add.state = line.Backup_Address__StateCode__s;
    //         if(line.Backup_Address__PostalCode__s != null){
    //             add.zip = line.Backup_Address__PostalCode__s.subStringBefore('+');
    //             // add.zip4 = line.Backup_Zip__c.substringAfter('+');
    //         }
    //     }else{
    //         add.address1 = line.Address__c;
    //         add.address2 = line.Address_2__c;
    //         add.city = line.City__c;
    //         add.state = line.State__c;
    //         if(line.Zip__c != null){
    //             add.zip = line.Zip__c.subStringBefore('+');
    //             // add.zip4 = line.Zip__c.substringAfter('+');
    //         }
    //     }
    //     return add;
    // }

    @testVisible
    private API_OM_Connection_Util.Note createNotes(ContentNote cn){
        API_OM_Connection_Util.Note note = new API_OM_Connection_Util.Note();

        note.subject = cn.Title;
        note.note = String.valueOf(cn.Content);
        note.created = cn.ContentModifiedDate?.formatGMT('yyyy-MM-dd HH:mm:ss');
        note.created_by_id = convertToLong(cn.Owner.CRM_User_ID__c);

        return note;
    }

    @testVisible
    private API_OM_Connection_Util.Note createOrderNote(OrderItem line){
        API_OM_Connection_Util.Note note = new API_OM_Connection_Util.Note();

        note.subject = 'Order Note';
        note.note = line.Order_Notes__c;
        note.created = line.LastModifiedDate?.formatGMT('yyyy-MM-dd HH:mm:ss');
        note.created_by_id = convertToLong(line.LastModifiedBy?.CRM_User_Id__c);

        return note;
    }

    @testVisible
    private List<API_OM_Connection_Util.Misc> addMiscFromLine(OrderItem line){
        List<API_OM_Connection_Util.Misc> miscs = new List<API_OM_Connection_Util.Misc>();

        if(line?.Product2?.OM_Field_Sets_Order_Item__c != null){
            for(String key:line.Product2.OM_Field_Sets_Order_Item__c.split(';')){
                Schema.FieldSet fieldSet = orderItemFieldSets.get(key.toLowerCase());
                if(fieldSet != null && fieldSet.getName().startsWithIgnoreCase('OM_')){
                    for(Schema.FieldSetMember member:fieldSet.getFields()){
                        API_OM_Connection_Util.Misc misc = createMisc(line, fieldSet, member);
                        if(misc != null){
                            miscs.add(misc);
                        }
                    }
                }
            }
        }

        return miscs;
    }

    private API_OM_Connection_Util.Misc createMisc(SObject line, Schema.FieldSet fieldSet, Schema.FieldSetMember member){
        API_OM_Connection_Util.Misc misc = new API_OM_Connection_Util.Misc();

        misc.grouping_id = line.Id + ':' + fieldSet.getName();
        misc.grouping_label = fieldSet.getLabel();
        misc.key_id = member.getFieldPath();
        misc.key_label = member.getLabel();
        misc.value = String.valueOf(line.get(member.fieldpath));

        if(misc.value == null){
            return null;
        }

        return misc;
    }

    public List<API_OM_Connection_Util.Attachment> createAttachments(List<Id> fileIds){
        List<API_OM_Connection_Util.Attachment> attachments = new List<API_OM_Connection_Util.Attachment>();

        List<ContentVersion> files = getContentVersions(fileIds);
        for(ContentVersion cv:files){
            attachments.add(new API_OM_Connection_Util.Attachment(cv) );
        }

        return attachments;
    }

    private List<API_OM_Connection_Util.Contact> createContacts(List<API_OM_SubmitOrdersContact_Model> contacts){
        if(contacts == null){
            return new List<API_OM_Connection_Util.Contact>();
        }
        return (List<API_OM_Connection_Util.Contact>) JSON.deserialize(JSON.serialize(contacts), List<API_OM_Connection_Util.Contact>.class);
    }

    private List<ContentVersion> getContentVersions(List<String> fileIds){
        if(fileIds == null){
            return new List<ContentVersion>();
        }
        return [
            SELECT Id, CreatedDate, Title, FileType, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId IN :fileIds AND IsLatest = true
        ];
    }

    public class OfsPayloadData{
        public SBQQ__Quote__c quote;
        public Map<Id, OfsOrderData> orders;

        public OfsPayloadData(){
            this.orders = new Map<Id, OfsOrderData>();
        }
    }

    public class OfsOrderData{
        public Order order;
        public OrderItem rootItem;
        public List<OrderItem> lines;

        public OfsOrderData(){
            lines = new List<OrderItem>();
        }
    }

    public class OfsStatus{
        public SBQQ__Quote__c quote;
        public List<Order> orders;

        public OfsStatus(){
            orders = new List<Order>();
        }
    }

    private Long convertToLong(String value){
        return value != null ? Long.valueOf(value) : null;
    }

    @testVisible
    private Long calculateServiceBandwidth(String productBandwidth){
        switch on productBandwidth{
            when 'UNKWN'    {return 34; }
            when '256 Kb'   {return 9; }
            when '384 Kb'   {return 12; }
            when '475 Mb'   {return 106; }
            when '500 Kb'   {return 103; }
            when '512 Kb'   {return 21; }
            when '768 Kb'   {return 24; }
            when '1 Mb'     {return 53; }
            when '1.5 Mbps'   {return 1; }
            when '2 Mbps'     {return 42; }
            when '3 Mbps'     {return 10; }
            when '4 Mb'     {return 13; }
            when '4.5 Mbps'   {return 14; }
            when '5 Mbps'     {return 19; }
            when '6 Mbps'     {return 22; }
            when '7 Mb'     {return 62; }
            when '7.5 Mbps'   {return 52; }
            when '8 Mb'     {return 61; }
            when '8.4 Mb'    {return 96; }
            when '8.5 Mb'   {return 88; }
            when '9 Mbps'     {return 25; }
            when '9.5 Mb'   {return 97; }
            when '10 Mbps'    {return 2; }
            when '11 Mb'    {return 82; }
            when '12 Mbps'    {return 4; }
            when '13 Mb'    {return 90; }
            when '15 Mb'    {return 5; }
            when '16 Mb'    {return 113; }
            when '17 Mb'    {return 101; }
            when '18 Mb'    {return 54; }
            when '19 Mb'    {return 77; }
            when '20 Mbps'    {return 6; }
            when '24 Mb'    {return 35; }
            when '25 Mb'    {return 8; }
            when '26 Mb'    {return 73; }
            when '30 Mbps'    {return 11; }
            when '35 Mb'    {return 41; }
            when '40 Mbps'    {return 15; }
            when '42 Mb'    {return 27; }
            when '45 Mbps'    {return 16; }
            when '47 Mb'    {return 117; }
            when '48 Mb'    {return 18; }
            when '49 Mb'    {return 151; }
            when '50 Mbps'    {return 20; }
            when '55 Mb'    {return 44; }
            when '60 Mbps'    {return 23; }
            when '65 Mb'    {return 36; }
            when '70 Mbps'    {return 55; }
            when '75 Mb'    {return 56; }
            when '80 Mbps'    {return 47; }
            when '85 Mb'    {return 64; }
            when '98 Mb'    {return 107; }
            when '90 Mbps'    {return 26; }
            when '95 Mb'    {return 65; }
            when '100 Mbps'   {return 3; }
            when '105 Mb'   {return 66; }
            when '110 Mb'   {return 40; }
            when '115 Mb'   {return 67; }
            when '120 Mb'   {return 68; }
            when '125 Mb'   {return 59; }
            when '130 Mb'   {return 69; }
            when '132 Mb'   {return 86; }
            when '135 Mb'   {return 70; }
            when '140 Mb'   {return 71; }
            when '145 Mb'   {return 72; }
            when '150 Mbps'   {return 46; }
            when '155 Mb'   {return 33; }
            when '170 Mb'   {return 154; }
            when '175 Mb'   {return 150; }
            when '180 Mb'   {return 80; }
            when '190 Mb'   {return 227; }
            when '195 Mb'   {return 224; }
            when '200 Mbps'   {return 7; }
            when '220 Mb'   {return 114; }
            when '240 Mb'   {return 84; }
            when '250 Mbps'   {return 51; }
            when '295 Mb'   {return 220; }
            when '300 Mbps'   {return 48; }
            when '320 Mb'   {return 222; }
            when '325 Mb'   {return 104; }
            when '345 Mb'   {return 226; }
            when '350 Mb'   {return 58; }
            when '390 Mb'   {return 109; }
            when '395 Mb'   {return 223; }
            when '400 Mbps'   {return 39; }
            when '450 Mb'   {return 17; }
            when '470 Mb'   {return 115; }
            when '480 Mb'   {return 110; }
            when '490 Mb'   {return 108; }
            when '500 Mbps'   {return 38; }
            when '550 Mb'   {return 112; }
            when '600 Mbps'   {return 49; }
            when '622 Mb'   {return 30; }
            when '650 Mb'   {return 152; }
            when '700 Mbps'   {return 78; }
            when '750 Mb'   {return 60; }
            when '800 Mbps'   {return 79; }
            when '845 Mb'   {return 228; }
            when '850 Mb'   {return 225; }
            when '900 Mbps'   {return 43; }
            when '940Mb'    {return 57; }
            when '965 Mb'   {return 111; }
            when '950 Mb'   {return 93; }
            when '980 Mb'   {return 89; }
            when '995 Mb'   {return 221; }
            when '997 Mb'   {return 153; }
            when '1000 Mbps'  {return 50; }
            when '1 Gb'     {return 28; }
            when '1.25 Gb'  {return 105; }
            when '1.5 Gb'   {return 91; }
            when '2 Gb'     {return 81; }
            when '2.1 Gb'   {return 116; }
            when '2.5 Gb'   {return 31; }
            when '3 Gb'     {return 37; }
            when '4 Gb'     {return 99; }
            when '5 Gb'     {return 94; }
            when '7.5 Gb'   {return 100; }
            when '9.6 Gb'   {return 32; }
            when '10 Gb'    {return 29; }
            when '20 Gb'    {return 229; }
            when '40 Gb'    {return 75; }
            when '100 Gb'   {return 76; }
            when '200 Gb'   {return 187; }
            when else       {return null; }
        }
    }
}