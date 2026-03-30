/**
 * @author Ladd Partners
 * @date 11/28/2017
*/

@isTest
public with sharing class lp_SetupTest {

    public SCMC__Condition_Code__c condition_code { get; private set; }
    public SCMC__Unit_of_Measure__c uom { get; private set; }
    public SCMC__Currency_Master__c currency_master { get; private set; }

    public lp_SetupTest() {
        this.condition_code = createConditionCode('New');
        this.uom = createUom();
        this.currency_master = createCurrencyMaster('USD', true, true);
    }

    public SCMC__Condition_Code__c createConditionCode(String code) {
        SCMC__Condition_Code__c cCode = null;
        try {
            cCode = [select id from SCMC__Condition_Code__c where name = :code];
        } catch (Exception ex) {
            cCode = new SCMC__Condition_Code__c();
            cCode.name = code;
            cCode.SCMC__description__c = 'Description for ' + code;
            cCode.SCMC__Disposal_Code__c = '1 -Excellent';
            cCode.SCMC__Supply_Code__c = 'A -Serviceable';
            insert cCode;
        }
        return cCode;
    }

    public SCMC__Currency_Master__c createCurrencyMaster(String currName, boolean isCorporate, boolean doInsert) {
        SCMC__Currency_Master__c curr = new SCMC__Currency_Master__c(
                name = currName,
                SCMC__Active__c = true,
                SCMC__Corporate_Currency__c = isCorporate
        );

        if (doInsert) {
            insert curr;
        }
        return curr;
    }

    public SCMC__Unit_of_Measure__c createUom() {
        SCMC__Unit_of_Measure__c unitOfMeasure = new SCMC__Unit_of_Measure__c(name = 'TestUOM');
        insert unitOfMeasure;
        return unitOfMeasure;
    }

    public SCMC__Product_Group__c createProductGroup(boolean doInsert) {
        SCMC__Product_Group__c product_group = new SCMC__Product_Group__c();
        product_group.Name = 'Test PG1';

        if (doInsert) {
            insert product_group;
        }

        return product_group;
    }

    public SCMC__Reason_Code__c createReasonCode(boolean doInsert) {
        SCMC__Reason_Code__c reason = new SCMC__Reason_Code__c(name = 'Manufactured Product');

        if (doInsert) {
            insert reason;
        }

        return reason;
    }

    public Account createAccount(boolean doInsert) {
        Account acct = new Account();
        acct.SCMC__Active__c = true;
        acct.SCMC__Customer__c = true;
        acct.SCMC__Corp_Line1__c = '123 Ocean Blvd.';
        acct.SCMC__Corp_Line2__c = null;
        acct.SCMC__Corp_City__c = 'San Diego';
        acct.SCMC__Corp_State_Province__c = 'California';
        acct.SCMC__Corp_PostalCode__c = '92130';
        acct.SCMC__Corp_Country__c = 'United States';
        acct.Name = 'Test acct';
        acct.Description = 'Test acct';
        acct.FAX = '555-1234';
        acct.SCMC__FOB__c = null;
        acct.SCMC__Freight__c = null;
        acct.SCMC__Preferred_Communication__c = 'Fax';

        if (doInsert) {
            insert acct;
        }

        return acct;
    }

    public SCMC__Item__c createItem(boolean doInsert) {
        SCMC__Item__c item = new SCMC__Item__c (
            name = 'Test01',
            SCMC__Item_Description__c = 'Test part for unit tests',
            SCMC__Inspection_Required__c  = false,
            SCMC__Serial_Number_Control__c = false,
            SCMC__Lot_Number_Control__c = false,
            SCMC__Stocking_UOM__c = uom.id
        );

        if (doInsert) {
            insert item;
        }

        return item;
    }

    public SCMC__Currency_Master__c createCurrencyMaster(String currName) {
        return createCurrencyMaster(currName, true, true);
    }

    public SCMC__Address__c createAddress() {
        SCMC__Address__c address = new SCMC__Address__c();
        address.name = 'Test Address';
        address.SCMC__City__c = 'San Francisco';
        address.SCMC__Country__c = 'United States';
        address.SCMC__Line1__c = 'Address line 1';
        address.SCMC__PostalCode__c = 'Postcd';
        address.SCMC__State__c = 'California';
        insert address;
        return address;
    }

    public SCMC__ICP__c createICP(SCMC__Address__c address, SCMC__Currency_Master__c curr) {
        SCMC__ICP__c icp = new SCMC__ICP__c ();
        icp.name = 'Test ICP';
        if (address == null)
            icp.SCMC__Address__c = createAddress().id;
        else
                icp.SCMC__Address__c = address.id;
        if (curr == null)
            icp.SCMC__Currency__c = createCurrencyMaster('USD').id;
        else
                icp.SCMC__Currency__c = curr.id;
        insert icp;
        return icp;
    }

    public SCMC__Warehouse__c createWarehouse(SCMC__Address__c address, SCMC__ICP__c icp) {
        return createWarehouse(address, icp, true);
    }

    public SCMC__Warehouse__c createWarehouse(SCMC__Address__c address, SCMC__ICP__c icp, Boolean isInsert) {
        SCMC__Warehouse__c warehouse = new SCMC__Warehouse__c (
                SCMC__ICP__c = icp.id
        , SCMC__Address__c = address.id
        , name = 'TestWarehouse'
        );
        if (isInsert) {
            insert warehouse;
        }
        return warehouse;
    }

    public SCMC__Inventory_Location__c createInventoryLocation(SCMC__Warehouse__c warehouse) {
        SCMC__Inventory_Location__c location = new SCMC__Inventory_Location__c (
                name = 'Test Warehouse'
        , SCMC__Level1__c = 'Level-1'
        , SCMC__Warehouse__c = warehouse.id
        );
        insert location;
        return location;
    }

    public SCMC__Inventory_Transaction_Perpetual_Record__c createPerpetualRecord(SCMC__Item__c itemMaster, SCMC__Inventory_Location__c invLocation, boolean doInsert) {
        SCMC__Inventory_Transaction_Perpetual_Record__c perpetual_record = new SCMC__Inventory_Transaction_Perpetual_Record__c();
        perpetual_record.SCMC__Inventory_Transactions__c = 'Receive Customer Returned Material'; // valid placeholder
        perpetual_record.SCMC__Inventory_Location__c = invLocation.Id;
        if (itemMaster != null) {
            perpetual_record.SCMC__Item_Master__c = itemMaster.Id;
        }
        perpetual_record.SCMC__Quantity__c = 1;

        if (doInsert) {
            insert perpetual_record;
        }

        return perpetual_record;
    }

    public SCMC__Inventory_Transaction_Financial_Records__c createFinancialRecord(SCMC__Inventory_Transaction_Perpetual_Record__c perpetual_record, string scmGLAccount, SCMC__Currency_Master__c curr, boolean doInsert) {
        SCMC__Inventory_Transaction_Financial_Records__c financial_record = new SCMC__Inventory_Transaction_Financial_Records__c();
        financial_record.SCMC__Inventory_Transaction__c = perpetual_record.Id;
        financial_record.SCMC__Quantity__c = 1;
        financial_record.SCMC__GL_Account__c = scmGLAccount;
        financial_record.SCMC__ICP_Currency__c = curr.Id;
        financial_record.SCMC__ICP_Unit_Cost__c = 100;
        financial_record.SCMC__ICP_Value_Amount__c = 100;
        financial_record.SCMC__Trade_Currency__c = curr.Id;
        financial_record.SCMC__Trade_Unit_Cost__c = 100;
        financial_record.SCMC__Trade_Value_Amount__c = 100;

        if (doInsert) {
            insert financial_record;
        }

        return financial_record;
    }

    public static id getRecordType(String name, SObject userObject) {
        Map<String,List<RecordType>>rTypes = new Map<String, List<RecordType>>();
        ID retId = null;
        // Get the sObject describe result for the userObject
        Schema.DescribeSObjectResult r = userObject.getSObjectType().getDescribe();
        String objName = r.getName();
        List<RecordType> info = rTypes.get(objName);
        if (info == null){
            Map<ID, Schema.RecordTypeInfo> rInfo = r.getRecordTypeInfosByID();
            info = [select id
                    ,name
                    ,developerName
            from RecordType
            where id in :rInfo.keySet()];
            rTypes.put(objName, info);
        }
        for (RecordType rType : rTypes.get(objName)){
            if (rType.developerName == name){
                retId = rType.id;
                break;
            }
        }
        return retId;

    }

    public SCMC__Sales_Order__c createSalesOrder(Account acct, boolean doInsert) {
        SCMC__Sales_Order__c so = new SCMC__Sales_Order__c();

        so.SCMC__Sales_Order_Date__c = Date.today();
        so.SCMC__Customer_Account__c = acct.Id;
        so.SCMC__Currency__c = this.currency_master.Id;
        so.RecordTypeId = lp_Utility.getRecordType(SCMC__Sales_Order__c.getSObjectType(), 'Inventory');

        if (doInsert) {
            insert so;
        }

        return so;
    }

    public SCMC__Sales_Order_Line_Item__c createSalesOrderLine(SCMC__Sales_Order__c so, SCMC__Item__c item, String status, boolean doInsert) {
        SCMC__Sales_Order_Line_Item__c line = new SCMC__Sales_Order_Line_Item__c();

        line.RecordTypeId = lp_Utility.getRecordType(SCMC__Sales_Order_Line_Item__c.getSObjectType(), 'Item');
        line.SCMC__Sales_Order__c = so.Id;
        line.SCMC__Quantity__c = 1;
        line.SCMC__Price__c = 2.5;
        line.SCMC__Item_Master__c = item.Id;
        line.SCMC__Customer_Commitment_Date__c = Date.today();
        line.SCMC__Status__c = status;
        line.SCMC__Condition_Code__c = null;

        if (doInsert) {
            insert line;
        }

        return line;
    }

    public SCMC__GL_Account__c createSCMGLAccountMapping(string scmAccount, c2g__codaGeneralLedgerAccount__c gla, boolean doInsert) {
        SCMC__GL_Account__c gl_account = new SCMC__GL_Account__c();
        gl_account.SCMC__SCM_Account__c = scmAccount;
        gl_account.SCMFFA__General_Ledger_Account__c = gla.Id;

        if (doInsert) {
            insert gl_account;
        }

        return gl_account;
    }

    public SCMC__Supplier_Site__c createSupplier(SCMC__Currency_Master__c curr, boolean doInsert) {
        SCMC__Supplier_Site__c sc = new SCMC__Supplier_Site__c();
        sc.name = 'Test supplier for unit tests';
        sc.SCMC__Currency__c = curr.Id;
        sc.SCMC__Preferred_Communication_Sourcing__c = 'E-Mail';
        sc.SCMC__Preferred_Communication_Purchase_Order__c = 'E-Mail';
        sc.SCMC__E_Mail__c = 'test@test.com';

        if (doInsert) {
            insert sc;
        }
        return sc;
    }

    public SCMC__Purchase_Order__c createPurchaseOrder(SCMC__Supplier_Site__c supplier, Id warehouseId, boolean doInsert) {
        SCMC__Purchase_Order__c po = new SCMC__Purchase_Order__c();
        po.SCMC__Currency_Master__c = currency_master.Id;
        po.SCMC__Supplier_Site__c = supplier.Id;
        po.SCMC__Status__c = lp_Constants.PURCHASE_ORDER_STATUS_OPEN;
        po.SCMC__Purchase_Order_Date__c = Date.today();
        po.RecordTypeId = lp_Utility.getRecordType(SCMC__Purchase_Order__c.getSObjectType(), lp_Constants.PURCHASE_ORDER_RECORD_TYPE_DROP_SHIP);
        po.SCMC__Ship_To_Warehouse__c = warehouseId;

        if (doInsert) {
            insert po;
        }
        return po;
    }

    public SCMC__Purchase_Order_Line_Item__c createPurchaseOrderLine(SCMC__Purchase_Order__c po, SCMC__Warehouse__c warehouse, SCMC__Item__c item, string lineType, Boolean doInsert) {
        SCMC__Purchase_Order_Line_Item__c line = new SCMC__Purchase_Order_Line_Item__c();
        line.RecordTypeId = lp_Utility.getRecordType(SCMC__Purchase_Order_Line_Item__c.getSObjectType(), lineType);
        line.SCMC__Purchase_Order__c = po.Id;
        line.SCMC__Supplier_Commitment_Date__c = Date.today();
        line.SCMC__Supplier_Current_Promise_Date__c = Date.today();
        line.SCMC__Status__c = lp_Constants.PURCHASE_ORDER_LINE_STATUS_OPEN;

        if (item != null) {
            line.SCMC__Item_Master__c = item.id;
        }

        line.SCMC__Quantity__c = 10;
        line.SCMC__Quantity_Received__c = 0;
        line.SCMC__Unit_Cost__c = 100.00;

        if (warehouse != null) {
            line.SCMC__Warehouse__c = warehouse.Id;
        }

        if (doInsert) {
            insert line;
        }

        return line;
    }

    public SCMC__Customer_Address__c createCustomerAddress(Account acct, boolean doInsert) {
        SCMC__Customer_Address__c customer_address = new SCMC__Customer_Address__c();
        customer_address.SCMC__Customer_Site__c = acct.Id;
        customer_address.SCMC__Active__c = true;

        if (doInsert) {
            insert customer_address;
        }

        return customer_address;
    }

    public SCMC__Customer_Quotation__c createCustomerQuotation(Account acct, boolean doInsert) {
        SCMC__Customer_Quotation__c customer_quotation = new SCMC__Customer_Quotation__c();

        if (acct != null) {
            customer_quotation.SCMC__Customer_Account__c = acct.Id;
        } else {
            customer_quotation.SCMC__Prospect_Company__c = 'Prospect1';
            customer_quotation.SCMC__Mailing_Street__c = '123 Main St';
            customer_quotation.SCMC__Mailing_Street_Additional_Information__c = 'Building 1';
            customer_quotation.SCMC__Mailing_City__c = 'Anytown';
            customer_quotation.SCMC__Mailing_State_Province__c = 'CA';
            customer_quotation.SCMC__Mailing_Zip_Postal_Code__c = '12345';
            customer_quotation.SCMC__Mailing_Country__c = 'USA';
            customer_quotation.SCMC__Prospect_Email__c = 'a@b.com';
        }
        customer_quotation.SCMC__Status__c = 'Open';

        if (doInsert) {
            insert customer_quotation;
        }

        return customer_quotation;
    }

    public SCMC__Customer_Quotation_Line__c createCustomerQuotationLine(SCMC__Customer_Quotation__c quote, SCMC__Item__c item, Boolean doInsert){
        SCMC__Customer_Quotation_Line__c quoteLine = new SCMC__Customer_Quotation_Line__c();
        quoteLine.SCMC__Customer_Quotation__c = quote.Id;
        quoteLine.SCMC__Quantity__c = 1;
        quoteLine.SCMC__List_Price__c = 1000;
        quoteLine.SCMC__Margin_Percent__c = 0;
        quoteLine.SCMC__Item_Number__c = item.Id;
        quoteLine.RecordTypeId = lp_Utility.getRecordType(SCMC__Customer_Quotation_Line__c.getSObjectType(), 'Item');
        if(doInsert){
            insert quoteLine;
        }
        return quoteLine;
    }

    public SCMC__AP_Voucher__c createAPVoucher(SCMC__Supplier_Site__c supplier, SCMC__Purchase_Order__c purchase_order, boolean doInsert) {
        SCMC__AP_Voucher__c ap_voucher = new SCMC__AP_Voucher__c();
        ap_voucher.SCMC__Supplier_Site__c = supplier.Id;
        ap_voucher.SCMC__Purchase_Order__c = purchase_order.Id;
        ap_voucher.SCMC__Status__c = lp_Constants.AP_VOUCHER_STATUS_NEW;
        ap_voucher.SCMC__Invoice_Number__c = '1234';
        ap_voucher.SCMC__Registered_Date__c = System.today();
        ap_voucher.SCMC__Invoice_Date__c = System.today();
        ap_voucher.SCMC__Due_Date__c = System.today() + 30;

        if (doInsert) {
            insert ap_voucher;
        }

        return ap_voucher;
    }

    public SCMC__AP_Voucher_Line__c createAPVoucherLine(SCMC__AP_Voucher__c voucher, SCMC__Purchase_Order_Line_Item__c purchase_order_line, boolean doInsert) {
        SCMC__AP_Voucher_Line__c voucher_line = new SCMC__AP_Voucher_Line__c();

        voucher_line.SCMC__AP_Voucher__c = voucher.Id;
        if (purchase_order_line != null) {
            voucher_line.SCMC__Purchase_Order_Line_Item__c = purchase_order_line.Id;
        }
        voucher_line.SCMC__Quantity__c = 1;
        voucher_line.SCMC__Unit_Price__c = 100;

        if (doInsert) {
            insert voucher_line;
        }

        return voucher_line;
    }

    public SCMC__Production_Order__c createProductionOrder(SCMC__Item__c item, Id salesOrderLineId, boolean doInsert) {
        SCMC__Production_Order__c production_order = new SCMC__Production_Order__c();
        production_order.SCMC__Item_Master__c = item.Id;
        production_order.SCMC__Quantity__c = 1;
        production_order.SCMC__Sales_Order_Line_Item__c = salesOrderLineId;
        production_order.RecordTypeId = lp_Utility.getRecordType(SCMC__Production_Order__c.getSObjectType(), 'Open');
        

        if (doInsert) {
            insert production_order;
        }

        return production_order;
    }

    public SCMC__Bill_of_Material__c createBillOfMaterial(SCMC__Bill_of_Material__c parentBOM, SCMC__Item__c item, boolean doInsert) {
        SCMC__Bill_of_Material__c bill_of_material = new SCMC__Bill_of_Material__c();
        bill_of_material.SCMC__Item__c = item.Id;
        if (parentBOM != null) {
            bill_of_material.SCMC__Parent__c = parentBOM.Id;
            bill_of_material.SCMC__Level__c = 2;
        } else {
            bill_of_material.SCMC__Level__c = 1;
        }
        bill_of_material.SCMC__QPA__c =1;
        bill_of_material.SCMC__QPA_Use__c =1;

        if (doInsert) {
            insert bill_of_material;
        }

        return bill_of_material;
    }

    public SCMC__Warehouse__c setupWarehouse() {
        SCMC__Address__c address = createAddress();
        SCMC__ICP__c icp = createICP(address, this.currency_master);
        return createWarehouse(address, icp);
    }

    public SCMC__Requisition__c createRequisition(Id warehouseId, Boolean doInsert){
        // create the Requisition
        SCMC__Requisition__c requisition = new SCMC__Requisition__c();
        requisition.SCMC__Warehouse__c = warehouseId;
        if (doInsert) {
            insert requisition;
        }
        return requisition;
    }

    public SCMC__Requisition_Line_Item__c createRequisitionLine(Id requisitionId, Id buyerId, Id itemId, String status, Decimal qty, Boolean doInsert){
        // create the Requisition Line Item
        SCMC__Requisition_Line_Item__c requisitionLineItem = new SCMC__Requisition_Line_Item__c();
        requisitionLineItem.SCMC__Requisition__c = requisitionId;
        requisitionLineItem.SCMC__Line_Status__c = status;
        requisitionLineItem.SCMC__Item_Master__c = itemId;
        requisitionLineItem.SCMC__Buyer_User__c = buyerId;
        requisitionLineItem.RecordTypeId = lp_Utility.getRecordType(SCMC__Requisition_Line_Item__c.getSObjectType(), 'Item');
        RequisitionLineItem.SCMC__Quantity__c = qty;
        if (doInsert){
            insert requisitionLineItem;
        }
        return requisitionLineItem;
    }

    public Opportunity createOpportunity(Id accountId, boolean doInsert) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Qualification';
        opp.CloseDate = system.today();// + 10;

        if (doInsert) {
            insert opp;
        }

        return opp;
    }

    public SCMC__Invoicing__c createInvoice(SCMC__Sales_Order__c sales_order, boolean doInsert) {
        SCMC__Invoicing__c invoicing = new SCMC__Invoicing__c();

        if (sales_order != null) {
            invoicing.SCMC__Sales_Order__c = sales_order.Id;
        }
        invoicing.SCMC__Invoice_Date__c = system.today();
        invoicing.SCMC__Invoice_Due_Date__c = system.today() + 30;

        if (doInsert) {
            insert invoicing;
        }

        return invoicing;
    }

    public SCMC__Invoice_Line_Item__c createInvoiceLine(SCMC__Invoicing__c invoice, SCMC__Item__c item, string recordTypeName, boolean doInsert) {
        SCMC__Invoice_Line_Item__c invoice_line_item = new SCMC__Invoice_Line_Item__c();

        invoice_line_item.SCMC__Invoicing__c = invoice.Id;
        invoice_line_item.SCMC__Amount_Description__c = 'Deposit';
        invoice_line_item.SCMC__Amount__c = 50.0;
        if (item != null) {
            invoice_line_item.SCMC__Item__c = item.Id;
        }
        invoice_line_item.SCMC__Option_Price_Per_Unit__c = 0.0;
        invoice_line_item.SCMC__Quantity__c = 1.0;
        invoice_line_item.SCMC__Unit_Price__c = 50.0;
        invoice_line_item.RecordTypeId = lp_Utility.getRecordType(SCMC__Invoice_Line_Item__c.getSObjectType(), recordTypeName);

        if (doInsert) {
            insert invoice_line_item;
        }

        return invoice_line_item;
    }

    public SCMC__Price_Type__c createPriceType(String title, boolean doInsert){
        SCMC__Price_Type__c priceType = new SCMC__Price_Type__c();
        priceType.Name = title;
        priceType.SCMC__Selection_Order__c = 1;
        if(doInsert){
            insert priceType;
        }
        return priceType;
    }

    public SCMC__Supplier_Catalogue__c createSupplierCatalogue(boolean doInsert, SCMC__Supplier_Site__c supplier) {
        SCMC__Supplier_Catalogue__c sa = new SCMC__Supplier_Catalogue__c();
        sa.SCMC__Supplier_Site__c = supplier.Id;
        sa.SCMC__Catalogue_Name__c = 'TestSA1234!$#@%#$%';
        sa.SCMC__Buyer_User__c = UserInfo.getUserId();
        sa.SCMC__Available_for_Use__c = true;
        sa.SCMC__Currency__c = currency_master.Id;
        if(doInsert){
          insert sa;
        }
        return sa;
    }

    public SCMC__Supplier_Catalogue_Item__c createSupplierCatalogueItem(SCMC__Supplier_Catalogue__c sc, SCMC__Item__c item, boolean doInsert) {
        SCMC__Supplier_Catalogue_Item__c catItem = new SCMC__Supplier_Catalogue_Item__c();
        catItem.SCMC__Supplier_Catalogue__c = sc.Id;
        catItem.SCMC__Item_Master__c = item.Id;
        catItem.SCMC__Active__c = true;
        if (doInsert) {
            insert catItem;
        }
        return catItem;
    }

    public SCMC__Supplier_Catalogue_Price_Break__c createPriceBreak(SCMC__Supplier_Catalogue_Item__c catItem, boolean doInsert) {
        SCMC__Supplier_Catalogue_Price_Break__c priceBreak = new SCMC__Supplier_Catalogue_Price_Break__c();
        priceBreak.SCMC__Supplier_Catalogue_Item__c = catItem.Id;
        priceBreak.SCMC__Price__c = 40;
        priceBreak.SCMC__Valid_Until_Quantity__c = 1;
        if (doInsert){
            insert priceBreak;
        }
        return priceBreak;
    }

    public SCMC__PO_Payment_Terms__c createPOPaymentTerms(string termName, String discountBy, Integer numberOfDays,
            Integer discountPercentage, Integer discountDays, String basisForDue, Boolean doInsert) {
        SCMC__PO_Payment_Terms__c term = new SCMC__PO_Payment_Terms__c(
            SCMC__Terms_Name__c = termName
            ,SCMC__Description__c = termName
            ,SCMC__Discount_Determined_by__c = discountBy
            ,SCMC__Number_of_Days__c = numberOfDays
            ,SCMC__Discount_Percentage__c = discountPercentage
            ,SCMC__Discount_Days__c = discountDays
            ,SCMC__Basis_for_Due__c = basisForDue
        );
        if (doInsert) {
            insert term;
        }
        return term;
    }

    public SCMC__Inventory_Position__c createInventoryPosition(SCMC__Item__c item, Decimal quantity, SCMC__Inventory_Location__c location, Id ownershipId, Boolean doInsert) {
        SCMC__Inventory_Position__c ip = new SCMC__Inventory_Position__c();
        ip.SCMC__Condition_Code__c = null;
        ip.SCMC__Shelf_Life_Expiration__c = null;
        ip.SCMC__Bin__c = location.Id;
        ip.SCMC__Item_Master__c = item.Id;
        ip.SCMC__Lot_Number__c = null;
        ip.SCMC__Quantity__c = quantity;
        ip.SCMC__Ownership_Code__c = ownershipId;
        ip.SCMC__Quantity_Allocated__c = 0;
        ip.SCMC__Quantity_in_Transit__c = 0;
        ip.SCMC__Current_Value__c = 25;
        ip.SCMC__ICP_Currency__c = this.currency_master.Id;
        ip.SCMC__Acquisition_Currency__c = this.currency_master.Id;
        ip.SCMC__Availability__c = true;
        ip.SCMC__Availability_Code__c = 'In Stock';
        ip.SCMC__Acquisition_Cost__c = 0;
        ip.SCMC__Adjustment_Cost__c = 0;
        ip.SCMC__Logistics_Cost__c = 0;
        ip.SCMC__Sale_Price__c = 0;
        ip.SCMC__Service_Cost__c = 0;

        if (doInsert) {
            insert ip;
        }

        return ip;
    }
	
	public Contact createContact(Id accountId, Boolean doInsert) {
        Contact contact = new Contact (AccountId = accountId
                , Salutation = 'Mr.'
                , FirstName = 'John'
                , LastName = 'Smith'
                , Email = 'a@b.com');

        if (doInsert) {
            insert contact;
        }

        return contact;
    }

    public static void testSchedulable(Object schedulableJob){
        String chron = '0 0 23 * * ?';
        String jobId = System.schedule('Test Schedulable Job', chron, (System.Schedulable)schedulableJob);
        CronTrigger[] cts = [SELECT Id, CronExpression, TimesTriggered,
        NextFireTime
        FROM CronTrigger WHERE id = :jobId];
        Assert.areEqual(jobId, cts[0].Id, 'Job was not scheduled.');
    }

    public static fferpcore__BillingDocument__c createBillingDocument(Id accountId, Boolean doInsert) {
        fferpcore__BillingDocument__c billingDocument = new fferpcore__BillingDocument__c();
        billingDocument.fferpcore__Account__c = accountId;
        billingDocument.fferpcore__DocumentType__c = 'Invoice';
        billingDocument.fferpcore__ShippingCity__c = '';
        billingDocument.fferpcore__ShippingStreet__c = '123 Ocean Blvd.';
        billingDocument.fferpcore__ShippingCity__c = 'San Diego';
        billingDocument.fferpcore__ShippingState__c = 'California';
        billingDocument.fferpcore__ShippingPostalCode__c = '92130';
        billingDocument.fferpcore__ShippingCountry__c = 'United States';
        if (doInsert) {
            insert billingDocument;
        }
        return billingDocument;
    }

    public static fferpcore__BillingDocumentLineItem__c createBillingDocumentLine(Id billingDocumentId, Id productId, Boolean doInsert) {
        fferpcore__BillingDocumentLineItem__c billingDocumentLineItem = new fferpcore__BillingDocumentLineItem__c();
        billingDocumentLineItem.fferpcore__BillingDocument__c = billingDocumentId;
        billingDocumentLineItem.fferpcore__ProductService__c = productId;
        billingDocumentLineItem.fferpcore__Quantity__c = 1;
        billingDocumentLineItem.fferpcore__UnitPrice__c = 100;
        if (doInsert) {
            insert billingDocumentLineItem;
        }
        return billingDocumentLineItem;
    }
}