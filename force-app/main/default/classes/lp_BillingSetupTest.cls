/**
 * Created by Ladd Partners on 4/23/2025.
 */

 @isTest
 public with sharing class lp_BillingSetupTest {
 
    public lp_SetupTestFFA.TestData testData { get; set; }
    public Opportunity opp { get; set; }

    public static final String billingUnitOfMeasureName = 'Each';
    public static final String companyName = lp_ErpCompany.NAME_US_SIGNAL;
    public static final String opportunitySplitType = 'Revenue';
    public Account acct { get; set; }
    public Contact acctContact { get; set; }
    public Account billingAccount { get; set; }
    public ffbc__UnitOfMeasure__c billingUnitOfMeasure { get; set; }
    public Contract contract { get; set; }
    public fferpcore__Company__c ffeCoreCompany { get; set; }
    public Order order { get; set; }
    public Map<Id, PricebookEntry> priceBookEntryByProductId { get; set; }
    public Product2 productItem { get; set; }
    public ffbc__SoftDate__c softDate { get; set; }
    public Product2 surchargeItem { get; set; }
   
    /**
    * Default constructor, runs in "create" mode.
    */
    public lp_BillingSetupTest() {
        this(false);
    }

    /**
     * Main constructor.
     * @param queryData If true, queries for existing data. If false, creates new data.
     */
    public lp_BillingSetupTest(Boolean queryData) {
        if (queryData) {
            lp_SetupTestFFA.testData.refresh(companyName);

            this.testData = lp_SetupTestFFA.TestData;
            this.acct = [SELECT Id, ffbc__BillingAccount__c FROM Account WHERE Id = :lp_SetupTestFFA.TestData.Account.Id];
            
            this.billingAccount = [SELECT Id FROM Account WHERE Name = 'Billing Account' LIMIT 1];
            this.billingUnitOfMeasure = [SELECT Id, Name, ffbc__DisplayName__c FROM ffbc__UnitOfMeasure__c WHERE Name = :billingUnitOfMeasureName LIMIT 1];
            this.opp = [SELECT Id, PriceBook2Id FROM Opportunity WHERE AccountId = :this.acct.Id ORDER BY CreatedDate DESC LIMIT 1];
            this.ffeCoreCompany = [SELECT Id FROM fferpcore__Company__c WHERE Name = :companyName LIMIT 1];
            this.softDate = [SELECT Id FROM ffbc__SoftDate__c WHERE Name = :lp_OrderItem.getSoftDateName(lp_OrderItem.BILLING_FREQUENCY_MONTHLY) LIMIT 1];

            // Re-populate products
            Map<String, Product2> productsMap = new Map<String, Product2>();
            for (Product2 p : [SELECT Id, Name, ProductCode FROM Product2 WHERE ProductCode IN ('ROU101', 'TS01') OR Name = 'Internet']) {
                if (p.Name == 'Internet') {
                    // This assumes TestData.Product was the 'Internet' one
                    this.testData.Product = p;
                } else if (p.ProductCode == 'ROU101') {
                    this.productItem = p;
                } else if (p.ProductCode == 'TS01') {
                    this.surchargeItem = p;
                }
            }

            // Re-populate Pricebook Entries
            this.priceBookEntryByProductId = new Map<Id, PricebookEntry>();
            if (this.opp != null && this.testData.Product != null && this.productItem != null && this.surchargeItem != null) {
                Set<Id> productIds = new Set<Id>{ this.testData.Product.Id, this.productItem.Id, this.surchargeItem.Id };
                for (PricebookEntry pbe : [
                    SELECT Id, Product2Id
                    FROM PricebookEntry
                    WHERE Pricebook2Id = :this.opp.PriceBook2Id AND Product2Id IN :productIds
                ]) {
                    this.priceBookEntryByProductId.put(pbe.Product2Id, pbe);
                }
            }
            
            this.contract = [SELECT Id, CompanySignedDate, Status FROM Contract WHERE AccountId = :this.acct.Id ORDER BY CreatedDate DESC LIMIT 1];
            if (this.contract != null) {
                this.order = [SELECT Id, Status, SBQQ__Contracted__c, EffectiveDate FROM Order WHERE ContractId = :this.contract.Id ORDER BY CreatedDate DESC LIMIT 1];
            }

        } else {
            createBaseData();
        }
    }

    /**
     * Contains all the DML logic moved from the original constructor.
     */
    private void createBaseData() {
        testData = lp_SetupTestFFA.TestData;
        if(lp_SetupTestFFA.TestData?.TestUser == null){
            lp_SetupTestFFA.createBaseFFAData(companyName, 'Test Bank Account');
        }
        acct = testData.Account;        

        billingAccount = new Account();
        billingAccount.Name = 'Billing Account';
        insert billingAccount;

        acct.ffbc__BillingAccount__c = billingAccount.Id;
        update new Account(Id = acct.Id, ffbc__BillingAccount__c = acct.ffbc__BillingAccount__c);

        billingUnitOfMeasure = new ffbc__UnitOfMeasure__c();
        billingUnitOfMeasure.Name = billingUnitOfMeasureName;
        billingUnitOfMeasure.ffbc__DisplayName__c = billingUnitOfMeasure.Name;
        insert billingUnitOfMeasure;

        opp = lp_SetupTestFFA.createOpportunity(acct.Id, true);

        ffeCoreCompany = createCoreCompany(companyName, testData.CurrentCompany.Id, true);

        softDate = createSoftDate(lp_OrderItem.BILLING_FREQUENCY_MONTHLY, true);

        testData.Product.Name = 'Internet';

        productItem = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, false);
        productItem.Name = 'Router';
        productItem.ProductCode = 'ROU101';

        surchargeItem = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, false);
        surchargeItem.Name = 'Technology Surcharge';
        surchargeItem.ProductCode = 'TS01';

        List<Product2> products = new List<Product2>{testData.Product, productItem, surchargeItem};
        upsert products;

        priceBookEntryByProductId = new Map<Id, PricebookEntry>();
        for(Product2 product : products){
            PricebookEntry bookEntry = createPricebookEntry(opp?.PriceBook2Id, product?.Id, false);
            priceBookEntryByProductId.put(product?.Id, bookEntry);
        }
        insert priceBookEntryByProductId.values();
    }
     
    public OrderItem setupOrderProductForBillingContract(){
        return setupOrderProduct(false);
    }
         
    public OrderItem setupOrderProduct(Boolean startBilling){
         
        this.contract = createContract(true);
        this.contract.Status = 'Activated';
        update this.contract;
         
        this.order = createOrder(this.contract, this.opp, true);
 
        List<OrderItem> orderProducts = new List<OrderItem>();
        OrderItem internetOrderProduct = createOrderProduct(order.Id, testData.Product, false);
        internetOrderProduct.UnitPrice = 1000;
        internetOrderProduct.Quantity = 5;
        internetOrderProduct.MRC_Per_Unit__c = 500;
        internetOrderProduct.NRC_List_Unit_Price__c  = 500;
        internetOrderProduct.NRC_Price__c = 500;
        internetOrderProduct.PricebookEntryId = priceBookEntryByProductId.get(testData.Product.Id)?.Id;
        internetOrderProduct.SBQQ__BillingFrequency__c = lp_OrderItem.BILLING_FREQUENCY_MONTHLY;
        internetOrderProduct.State__c = 'UT';
        internetOrderProduct.State_Z__c = 'IN';
        insert internetOrderProduct;

        createProductTaxDetails(testData.Product.Id, lp_BillingContractLine.BILLING_TYPE_RECURRING_FIXED, true);

        order.Status = 'Activated';
        order.SBQQ__Contracted__c = true;
        update order;
        
        if(startBilling){
            internetOrderProduct.Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_DISPLAY;
            internetOrderProduct.ServiceDate = order.EffectiveDate;
            internetOrderProduct.Start_Billing__c = true;
            update internetOrderProduct;
        }
        
        return internetOrderProduct;
    }
     
    public OrderItem setupOrderProduct_UsageProduct(){
        return setupOrderProduct_UsageProduct(null);
    }

    public OrderItem setupOrderProduct_UsageProduct(String facilityName){
        this.contract = createContract(true);
        this.contract.Status = 'Activated';
        update this.contract;
        
        this.order = createOrder(this.contract, this.opp, true);
 
        ffbc__Contract__c ffbcContract = lp_BillingContract.createFromOrder(order);
        ffbcContract.ffbc__Account__c = acct.Id;
        insert ffbcContract;
        
        update new Order(Id = order.Id, LPC_Billing_Contract__c = ffbcContract.Id);

        update new Product2(Id = testData.Product.Id, Usage_Product__c = true);

        OrderItem internetOrderProduct = createOrderProduct(order.Id, testData.Product, false);
        internetOrderProduct.Quantity = 5;
        internetOrderProduct.State__c = 'IN';
        internetOrderProduct.ServiceDate = order.EffectiveDate;
        internetOrderProduct.State_Z__c = 'IN';
        internetOrderProduct.UnitPrice = 1000;
        internetOrderProduct.SBQQ__BillingFrequency__c = lp_OrderItem.BILLING_FREQUENCY_MONTHLY;
        internetOrderProduct.Facility__c = facilityName;
        internetOrderProduct.Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_DISPLAY;

        internetOrderProduct.PricebookEntryId = priceBookEntryByProductId.get(testData.Product.Id)?.Id;
        insert internetOrderProduct;

        createProductTaxDetails(testData.Product.Id, lp_BillingContractLine.BILLING_TYPE_RECURRING_VARIABLE, true);

        order.Status = 'Activated';
        order.SBQQ__Contracted__c = true;
        update order;
         
        internetOrderProduct.Start_Billing__c = true;
        update internetOrderProduct;
         
        internetOrderProduct = new lp_OrderItemSelector().getWithOrderComponentsById(internetOrderProduct.Id);
        List<ffbc__ContractLineItem__c> contractLines = lp_BillingContractLine.createFromOrderItem(internetOrderProduct, ffbcContract.Id);
        ffbc__ContractLineItem__c contractLine = contractLines[0];
        lp_BillingContract.activateContracts(new Set<Id>{ffbcContract.Id});
        
        createUsage(contractLine);

        return internetOrderProduct;
    }
 
    public Contract createContract(Boolean doSave){
        Contract newContract = new Contract();
        newContract.CompanySignedDate = system.today().addDays(-30);
        newContract.AccountId = acct.Id;
        if(doSave){
            insert newContract;
        }
        return newContract;
    }
     
    public Order createOrder(Contract contract, Opportunity opp, Boolean doSave){
        Order newOrder = new Order();
        newOrder.Account_Account_Name__c = billingAccount.Id;
        newOrder.AccountId = acct.Id;
        newOrder.ContractId = contract?.Id;
        newOrder.EffectiveDate = contract?.CompanySignedDate;
        newOrder.OpportunityId = opp.Id;
        newOrder.PriceBook2Id = opp.PriceBook2Id;
        newOrder.Type = 'New';
        newOrder.Status = 'Draft';
        if(doSave){
            insert newOrder;
        }
        return newOrder;
    }
       
    public OrderItem createOrderProduct(Id orderId, Product2 productItem, Boolean doSave){
        OrderItem newOrderProduct = new OrderItem();
        newOrderProduct.OrderId = orderId;
        newOrderProduct.SBQQ__BillingFrequency__c = lp_OrderItem.BILLING_FREQUENCY_MONTHLY;
        newOrderProduct.SBQQ__Contracted__c = true;
        newOrderProduct.Quantity = 1;
        newOrderProduct.UnitPrice = 0;
        newOrderProduct.Unit_of_Measure__c = billingUnitOfMeasure.ffbc__DisplayName__c;
        if(doSave){
            insert newOrderProduct;
        }
        return newOrderProduct;
    }
 
    public static fferpcore__Company__c createCoreCompany(String companyName, Id accountingCompanyId, Boolean doSave){
        fferpcore__Company__c company = new fferpcore__Company__c();
        company.Name = companyName;
        company.c2g__msg_link_ffa_id__c = accountingCompanyId;
        company.fferpcore__City__c = 'Test City';
        company.fferpcore__Street__c = '001 Test Address';
        company.fferpcore__State__c = 'UT';
        company.fferpcore__Country__c = 'United States';
        company.fferpcore__Zip__c = '00000';
        company.fferpcore__Email__c = 'test@testEmail.com';
        if(doSave){
            insert company;
        }
        return company;
    }
     
    public static Async_Job_Staging__c createAsyncJob(Id orderProductId, String jobType, Boolean doSave){
        Async_Job_Staging__c job = new Async_Job_Staging__c();
        job.Order_Product__c = orderProductId;
        job.Job__c = jobType;
        if(doSave){
            insert job;
        }
        return job;
    }
     
    public static PricebookEntry createPricebookEntry(Id priceBookId, Id productId, Boolean doSave){
        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.put('Pricebook2Id', priceBookId);
        priceBookEntry.put('Product2Id', productId);
        priceBookEntry.put('UnitPrice', 100);
        priceBookEntry.put('IsActive', true);
        priceBookEntry.put('UseStandardPrice', false);
        if(doSave){
            insert priceBookEntry;
        }
        return priceBookEntry;
    }
     
    public static LPC_Product_Tax_Details__c createProductTaxDetails(Id productId, String billingType, Boolean doSave){
        LPC_Product_Tax_Details__c taxDetails = new LPC_Product_Tax_Details__c();
        taxDetails.Interstate__c = true;
        taxDetails.Product__c = productId;
        taxDetails.Contract_Billing_Type__c = BillingType;
        if(doSave){
            insert taxDetails;
        }
        return taxDetails;
    }
 
    public static ffbc__SoftDate__c createSoftDate(string billTerm, boolean doSave){
        ffbc__SoftDate__c softDate = new ffbc__SoftDate__c();
        softDate.CurrencyIsoCode = 'USD';
        softDate.Name = lp_OrderItem.getSoftDateName(billTerm);
        softDate.ffbc__Definition__c = 'ME';
        softDate.ffbc__Description__c = 'Sets the date Test.';
        softDate.ffbc__EstimatedDaysPerTerm__c = 30;
        if(doSave){
            insert softDate;
        }
        return softDate;
    }

    public static Facility__c createFacility(String facilityName, Id analysisItemId, Boolean doSave) {
        Facility__c facility = new Facility__c();
        facility.Facility__c = facilityName;
        facility.LPC_Analysis_Item_3__c = analysisItemId;

        if (doSave) {
            insert facility;
        }

        return facility;
    }

    public static fferpcore__AnalysisItem__c createAnalysisItem(String itemName, String recordTypeName, Boolean doSave) {
        fferpcore__AnalysisItem__c analysisItem = new fferpcore__AnalysisItem__c();
        analysisItem.Name = itemName;
        analysisItem.fferpcore__ReportingCode__c = itemName;

        analysisItem.RecordTypeId = lp_Utility.getRecordType(fferpcore__AnalysisItem__c.SObjectType, recordTypeName);

        if (doSave) {
            insert analysisItem;
        }

        return analysisItem;
    }
    
    public ffbc__Usage__c createUsage(ffbc__ContractLineItem__c contractLine) {
        fferpcore__BillingDocument__c billDoc = lp_SetupTest.createBillingDocument(acct.Id, false);
        billDoc.fferpcore__Company__c = ffeCoreCompany.Id;
        billDoc.fferpcore__DocumentDate__c = Date.today().addDays(-15);
        billDoc.fferpcore__DocumentDueDate__c = Date.today().addDays(-5);
        insert billDoc;

        fferpcore__BillingDocumentLineItem__c billDocLine = lp_SetupTest.createBillingDocumentLine(billDoc.Id, contractLine.ffbc__ProductService__c, true);
        billDoc.fferpcore__DocumentStatus__c = 'Complete';
        upsert billDoc;
        billDoc = new lp_BillingDocumentSelector().getById(billDoc.Id);
        
        ffbc__Usage__c usage = new ffbc__Usage__c();
        usage.ffbc__BillingDocumentLineItem__c = billDocLine.Id;
        usage.ffbc__ContractLineItem__c = contractLine.Id;
        usage.ffbc__Date__c = Date.today().addMonths(1);
        usage.ffbc__Quantity__c = 100;
        insert usage;

        return usage;
    }
}