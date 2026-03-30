/**
 * Created by Ladd Partners on 4/18/2025.
 */

 @IsTest
 private class lp_BillingContractTest {
    static lp_BillingSetupTest setupTest;
 
    @TestSetup
    static void createData() {
    setupTest = new lp_BillingSetupTest(false);
    setupTest.setupOrderProduct_UsageProduct();
    }
 
    @IsTest
    static void createContract() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        List<OrderItem> orderProducts = [SELECT Id FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];

        test.startTest();
            Async_Job_Staging__c job = lp_BillingSetupTest.createAsyncJob(orderProduct.Id, lp_AsyncJobStaging.JOB_BILL_ORDER_ITEMS, true);
            Test.getEventBus().deliver();
        test.stopTest();

        job = new lp_AsyncJobStagingSelector().getById(job.Id);
        Assert.areEqual(lp_AsyncJobStaging.STATUS_COMPLETED, job.Status__c, 'Error creating the Billing Contract, error: ' + job.Error_Message__c);
        Assert.isNotNull(job.Billing_Contract__c, 'Missing the Billing Contract');

        Savepoint sp = Database.setSavepoint();
        lp_AsyncJobStaging.reportError(job.Id, 'Test Error', sp, new lp_Exception('Test Error'));
    }
     
    @IsTest
    static void createContractFromOrderProductUpdate() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        List<OrderItem> orderProducts = [SELECT Id, OrderId FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];
        update new Order(Id = orderProduct.OrderId, Status = 'Activated', SBQQ__Contracted__c = true);

        test.startTest();
            update new OrderItem(Id = orderProduct.Id, Start_Billing__c = true, ServiceDate = System.today(), Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_DISPLAY);
            Test.getEventBus().deliver();
        test.stopTest();

        orderProduct = new lp_OrderItemSelector().getById(orderProduct.Id);
        Assert.isNotNull(orderProduct.LPC_BillingContractLine__c, 'The Billing Contract Line should have been created');

        List<ffbc__ContractLineItem__c> contractLines = new lp_BillingContractLineSelector().getByContractIds(new Set<Id>{ orderProduct.LPC_BillingContractLine__r.ffbc__Contract__c });
        Assert.isFalse(contractLines.isEmpty(), 'The Billing Contract Lines should have been returned');
        
        try{
            lp_BillingContract.throwError(new lp_Exception('Test Error'));
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Test Error'), 'Error applying changes, error: ' + e.getMessage());
        }
    }

    @IsTest
    static void testAmendOrderItem() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        setupTest = new lp_BillingSetupTest(true);

        List<OrderItem> orderProducts = [SELECT Id, Quantity, LPC_BillingContractLine__c, LPC_BillingContractLine__r.ffbc__Contract__c FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];

        // Set end date for amendment
        Order amendmentOrder = setupTest.createOrder(setupTest.contract, setupTest.opp, false);
        amendmentOrder.Bill_Start_Date__c = System.today().addDays(-30);
        amendmentOrder.EffectiveDate = System.today().addDays(-30);
        insert amendmentOrder;

        OrderItem amendmentOrderProduct = orderProduct.clone();
        amendmentOrderProduct.Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_SUPPRESS;
        amendmentOrderProduct.OrderId = amendmentOrder.Id;
        amendmentOrderProduct.PricebookEntryId = setupTest.priceBookEntryByProductId.get(setupTest.testData.Product.Id)?.Id;
        amendmentOrderProduct.Quantity = orderProduct.Quantity + 1; // Different quantity for amendment
        amendmentOrderProduct.Prior_Order_Product__c = orderProduct.Id;
        amendmentOrderProduct.ServiceDate = System.today();
        amendmentOrderProduct.UnitPrice = 1;
        insert amendmentOrderProduct;
        
        test.startTest();
            // Create async job for amendment
            Async_Job_Staging__c job = lp_BillingSetupTest.createAsyncJob(amendmentOrderProduct.Id, lp_AsyncJobStaging.JOB_AMEND_ORDER_ITEMS, true);
            Test.getEventBus().deliver();
        test.stopTest();

        // Verify results
        job = new lp_AsyncJobStagingSelector().getById(job.Id);
        Assert.areEqual(lp_AsyncJobStaging.STATUS_COMPLETED, job.Status__c, 'Error amending the Order Product, error: ' + job.Error_Message__c);
        Assert.isNotNull(job.Billing_Contract__c, 'Missing the Billing Contract');

        // Verify contract line was created
        amendmentOrderProduct = new lp_OrderItemSelector().getById(amendmentOrderProduct.Id);
        Assert.isNotNull(amendmentOrderProduct.LPC_BillingContractLine__c, 'The amended Billing Contract Line should have been created');
    }
    
    @IsTest
    static void testAmendOrderItem_Credit() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        setupTest = new lp_BillingSetupTest(true);

        List<OrderItem> orderProducts = [SELECT Id, Quantity, LPC_BillingContractLine__c, LPC_BillingContractLine__r.ffbc__BilledTo__c, LPC_BillingContractLine__r.ffbc__Contract__c FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];
        
        System.debug('orderProduct.LPC_BillingContractLine__r.ffbc__BilledTo__c: ' + orderProduct.LPC_BillingContractLine__r.ffbc__BilledTo__c);

        // Set end date for amendment
        Order amendmentOrder = setupTest.createOrder(setupTest.contract, setupTest.opp, false);
        amendmentOrder.Bill_Start_Date__c = System.today().addDays(-30);
        amendmentOrder.EffectiveDate = System.today().addDays(-30);
        insert amendmentOrder;

        OrderItem amendmentOrderProduct = orderProduct.clone();
        amendmentOrderProduct.Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_SUPPRESS;
        amendmentOrderProduct.OrderId = amendmentOrder.Id;
        amendmentOrderProduct.PricebookEntryId = setupTest.priceBookEntryByProductId.get(setupTest.testData.Product.Id)?.Id;
        amendmentOrderProduct.Quantity = orderProduct.Quantity + 1; // Different quantity for amendment
        amendmentOrderProduct.Prior_Order_Product__c = orderProduct.Id;
        amendmentOrderProduct.ServiceDate = System.today();
        amendmentOrderProduct.UnitPrice = 1;
        insert amendmentOrderProduct;
        
        test.startTest();
            // Create async job for amendment
            Async_Job_Staging__c job = lp_BillingSetupTest.createAsyncJob(amendmentOrderProduct.Id, lp_AsyncJobStaging.JOB_AMEND_ORDER_ITEMS, true);
            Test.getEventBus().deliver();
        test.stopTest();

        // Verify results
        job = new lp_AsyncJobStagingSelector().getById(job.Id);
        Assert.areEqual(lp_AsyncJobStaging.STATUS_COMPLETED, job.Status__c, 'Error amending the Order Product, error: ' + job.Error_Message__c);
        Assert.isNotNull(job.Billing_Contract__c, 'Missing the Billing Contract');

        // Verify contract line was created
        amendmentOrderProduct = new lp_OrderItemSelector().getById(amendmentOrderProduct.Id);
        Assert.isNotNull(amendmentOrderProduct.LPC_BillingContractLine__c, 'The amended Billing Contract Line should have been created');
    }
 
    @IsTest
    static void testDisconnectOrderItem() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        setupTest = new lp_BillingSetupTest(true);

        List<OrderItem> orderProducts = [SELECT Id, LPC_BillingContractLine__c, Usage_Product__c, LPC_BillingContractLine__r.ffbc__Contract__c FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];

        // Set end date for disconnection
        Order discoOrder = setupTest.createOrder(setupTest.contract, setupTest.opp, false);
        discoOrder.Bill_Start_Date__c = System.today().addDays(-30);
        discoOrder.EffectiveDate = System.today().addDays(-30);
        insert discoOrder;

        OrderItem discoOrderProduct = orderProduct.clone();
        discoOrderProduct.Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_SUPPRESS;
        discoOrderProduct.EndDate = System.today().addDays(-30);
        discoOrderProduct.OrderId = discoOrder.Id;
        discoOrderProduct.PricebookEntryId = setupTest.priceBookEntryByProductId.get(setupTest.testData.Product.Id)?.Id;
        discoOrderProduct.Quantity = 1;
        discoOrderProduct.Prior_Order_Product__c = orderProduct.Id;
        discoOrderProduct.ServiceDate = System.today().addDays(-30);
        discoOrderProduct.UnitPrice = 1;
        insert discoOrderProduct;

        test.startTest();
            // Create async job for disconnection
            Async_Job_Staging__c job = lp_BillingSetupTest.createAsyncJob(discoOrderProduct.Id, lp_AsyncJobStaging.JOB_DISCONNECT_ORDER_ITEMS, true);
            Test.getEventBus().deliver();
        test.stopTest();

        // Verify results
        job = new lp_AsyncJobStagingSelector().getById(job.Id);
        Assert.areEqual(lp_AsyncJobStaging.STATUS_COMPLETED, job.Status__c, 'Error disconnecting the Order Product, error: ' + job.Error_Message__c);
        Assert.isNotNull(job.Billing_Contract__c, 'Missing the Billing Contract');

        // Verify contract line was updated with end date
        List<ffbc__ContractLineItem__c> contractLines = new lp_BillingContractLineSelector().getByContractIds(new Set<Id>{ job.Billing_Contract__c });
        Assert.isFalse(contractLines.isEmpty(), 'The Billing Contract Lines should have been returned');
        ffbc__ContractLineItem__c discoContractLine = null;
        for (ffbc__ContractLineItem__c contractLine : contractLines) {
            if (contractLine.LPC_Order_Item__c == orderProduct.Id) {
                discoContractLine = contractLine;
                break; 
            }
        }
        Assert.isNotNull(discoContractLine, 'The disco contract line was not found');
        Date endDate = System.today().addMonths(1);
        Boolean isUsageProduct = discoOrderProduct.Usage_Product__c ?? false;
        if (isUsageProduct) {
            //endDate = endDate.addMonths(1).toStartOfMonth().addDays(-1).addMonths(2);
        } 
        Assert.areEqual(endDate, discoContractLine.ffbc__EndDate__c, 'The contract line end date should match the order product end date');
    }

    @IsTest
    static void testRenewOrderItem() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        setupTest = new lp_BillingSetupTest(true);

        List<OrderItem> orderProducts = [SELECT Id, LPC_BillingContractLine__c, LPC_BillingContractLine__r.ffbc__Contract__c FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];

        // Create new order product for renewal
        Order renewalOrder = setupTest.createOrder(setupTest.contract, setupTest.opp, false);
        renewalOrder.Bill_Start_Date__c = System.today().addDays(-30);
        renewalOrder.EffectiveDate = System.today().addDays(-30);
        insert renewalOrder;

        OrderItem renewalOrderProduct = orderProduct.clone();
        renewalOrderProduct.Billing_Display__c = lp_OrderItem.BILLING_DISPLAY_SUPPRESS;
        renewalOrderProduct.MRC_Per_Unit__c = 150.00; // Different MRC for renewal
        renewalOrderProduct.OrderId = renewalOrder.Id;
        renewalOrderProduct.PricebookEntryId = setupTest.priceBookEntryByProductId.get(setupTest.testData.Product.Id)?.Id;
        renewalOrderProduct.Prior_Order_Product__c = orderProduct.Id;
        renewalOrderProduct.Quantity = 1;
        renewalOrderProduct.ServiceDate = System.today().addDays(-30);
        renewalOrderProduct.UnitPrice = 1;
        insert renewalOrderProduct;

        test.startTest();
            // Create async job for renewal
            Async_Job_Staging__c job = lp_BillingSetupTest.createAsyncJob(renewalOrderProduct.Id, lp_AsyncJobStaging.JOB_RENEW_ORDER_ITEMS, true);
            Test.getEventBus().deliver();
        test.stopTest();

        // Verify results
        job = new lp_AsyncJobStagingSelector().getById(job.Id);
        Assert.areEqual(lp_AsyncJobStaging.STATUS_COMPLETED, job.Status__c, 'Error renewing the Order Product, error: ' + job.Error_Message__c);
        Assert.isNotNull(job.Billing_Contract__c, 'Missing the Billing Contract');

        // Verify contract line was created
        renewalOrderProduct = new lp_OrderItemSelector().getById(renewalOrderProduct.Id);
        Assert.isNotNull(renewalOrderProduct.LPC_BillingContractLine__c, 'The renewed Billing Contract Line should have been created');
    }
     
    @IsTest
    static void testGetActiveChangeRequest() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        setupTest = new lp_BillingSetupTest(true);

        List<OrderItem> orderProducts = [SELECT Id, OrderId, LPC_BillingContractLine__c, LPC_BillingContractLine__r.ffbc__Contract__c FROM OrderItem];
        System.debug('orderProducts: ' + orderProducts);
        System.debug('orderProducts.size(): ' + orderProducts.size());
        OrderItem orderProduct = orderProducts[0];
        Assert.isNotNull(orderProduct.LPC_BillingContractLine__r.ffbc__Contract__c, 'The Billing Contract should have been created');
        
        Id contractId = lp_BillingContract.getActiveChangeRequest(orderProduct.LPC_BillingContractLine__r.ffbc__Contract__c);
        Assert.isNotNull(contractId, 'The Billing Contract Id should have been returned');

        // For Coverage
        lp_BillingContract.activateContractsOrApplyChange(new Set<Id>{  contractId });
        lp_BillingContract.activateContractsAsync(new Set<Id>{  contractId });
        Order order = new lp_OrderSelector().getWithOrderItemsById(orderProduct.OrderId);
        lp_FacilitySelector facilitySelector = new lp_FacilitySelector();
        facilitySelector.getById(new Set<Id>());
        facilitySelector.getByFacility('Test Facility');
    }
  
    @IsTest
    static void coverCreateFromContractLine() {
        ffbc__ContractLineItem__c contractLine = new ffbc__ContractLineItem__c();
        lp_BillingContractLine.createFromContractLine(contractLine, new OrderItem());
    }
      
    @IsTest
    static void coverApplyChanges() {
        lp_BillingContract.applyChanges(new Set<Id>());
    }
}