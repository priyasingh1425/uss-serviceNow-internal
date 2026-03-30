@isTest
public class NubikTestDataGenerator {
    
    private static Integer accountCnt = 1;
    public static Account getAccount(Boolean doInsert){
        Account acc = new Account();
        acc.Name = 'Test Account #' + String.valueOf(accountCnt++);
        
        if(doInsert)
            insert acc;
    
        return acc;
    }

    private static Integer oppCnt = 1;
    public static Opportunity getOpportunity(Boolean doInsert){
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp #' + String.valueOf(oppCnt++);
        opp.StageName = 'Qualification';
        opp.CloseDate = Date.today();
        
        if(doInsert)
            insert opp;
    
        return opp;
    }

    private static Integer quoteCnt = 1;
    public static SBQQ__Quote__c getQuote(Id oppId, Boolean isPrimary, Boolean doInsert){
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = oppId;
        //quote.SBQQ__PricebookId__c = Test.getStandardPricebookId();
        quote.SBQQ__PricebookId__c = getStandardPricebookId();
        quote.SBQQ__Primary__c = isPrimary;
        
        if(doInsert)
            insert quote;
        
        return quote;
    }

    public static Order getOrder(Id accId, Id quoteId, Boolean doInsert){
        Order order = new Order();
        order.AccountId = accId;
        order.EffectiveDate = Date.today();
        order.SBQQ__Quote__c = quoteId;
        order.Status = 'Draft';
        //order.Pricebook2Id = Test.getStandardPricebookId();
        order.Pricebook2Id = getStandardPricebookId();
        order.Channel__c = 'W';

        if(doInsert)
            insert order;
   
        return order;
    }

    private static Integer productCnt = 1;
    public static Product2 getProduct(String productCode, Boolean doInsert){
        Product2 product = new Product2();
        product.Name = 'Product #' + String.valueOf(productCnt++);
        product.customer_type_cd__c = 'W';
        product.ProductCode = productCode;
        product.product_cd__c = productCode;
        product.SBQQ__DefaultQuantity__c = 1;

        if(doInsert)
            insert product;
        
        return product;
    }

    
    private static Integer serviceComponentCnt = 1;
    public static Product2 getServiceComponent(String serviceComponentId, Boolean doInsert){
        Product2 product = new Product2();
        product.Name = 'Service Component #' + String.valueOf(serviceComponentCnt++);
        product.customer_type_cd__c = 'W';
        product.service_component_id__c = serviceComponentId;
        product.SBQQ__DefaultQuantity__c = 1;

        if(doInsert)
            insert product;
        
        return product;
    }

    public static PricebookEntry getPricebookEntry(Id productId, Boolean doInsert){
        PricebookEntry standardPBE = new PricebookEntry();
        standardPBE.Pricebook2Id = Test.getStandardPricebookId();
        standardPBE.Product2Id = productId;
        standardPBE.IsActive = true;
        standardPBE.UnitPrice = 1;
        insert standardPBE;
        
        PricebookEntry pbe = new PricebookEntry();
        //pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Pricebook2Id = getStandardPricebookId();
        pbe.Product2Id = productId;
        pbe.IsActive = true;
        pbe.UnitPrice = 1;
        pbe.UseStandardPrice = true;
        
        if(doInsert)
            insert pbe;

        return pbe;
    }

    public static SBQQ__QuoteLine__c getQuoteLine(Id quoteId, Id productId, Id pbeId, Boolean doInsert){
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine.SBQQ__Quote__c = quoteId;
        quoteLine.SBQQ__Product__c = productId;
        quoteLine.SBQQ__Quantity__c = 1;
        quoteLine.SBQQ__PricebookEntryId__c = pbeId;
        
        if(doInsert)
            insert quoteLine;
        
        return quoteLine;
    }

    public static OrderItem getOrderItem(Id orderId, Id quoteLineId, Id productId, Id pbeId, Id requiredById, Boolean doInsert){
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = orderId;
        orderItem.SBQQ__QuoteLine__c = quoteLineId;
        orderItem.Product2Id = productId;
        orderItem.UnitPrice = 1.00;
        orderItem.Quantity = 1;
        orderItem.PricebookEntryId = pbeId;
        if(requiredById != null)
            orderItem.SBQQ__RequiredBy__c = requiredById;
        
        if(doInsert)
            insert orderItem;

        return orderItem;
    }

    public static Id stdPricebookId;
    public static Id getStandardPricebookId(){
        if(stdPricebookId != null){
            return stdPricebookId;
        }

        Pricebook2 stdPricebook = new Pricebook2();
        stdPricebook.IsActive = true;
        stdPricebook.Name = 'Test Std Pricebook';
        stdPricebook.Description = 'Test Std Pricebook';
        insert stdPricebook;

        stdPricebookId = stdPricebook.Id;

        return stdPricebookId;
    }

}