/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

@isTest
private class lp_BillingDocumentTest {
    @isTest
    private static void createLateMonthlyBillDoc() {
        lp_SetupTestFFA.createBaseFFAData('US Signal', 'US Checking');
        lp_SetupTestFFA.TestData testData = lp_SetupTestFFA.testData;

        lp_BillingDocumentSelector docSelector = new lp_BillingDocumentSelector();

        System.runAs(testData.TestUser) {
            LPC_Billing_Central_Configuration__c billConfig = new LPC_Billing_Central_Configuration__c();
            billConfig.Days_Past_Due__c = 1;
            billConfig.Finance_Charge_SF_Product__c = 'Test Finance Charge';
            insert billConfig;

            fferpcore__Company__c coreCompany = new fferpcore__Company__c(
                    Name = 'FFERCore Company Signal',
                    c2g__msg_link_ffa_id__c = testData.CurrentCompany.Id
            );
            insert coreCompany;

            Product2 testProduct = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, true);
            testProduct.Name = '2 x 1 Gbps CDC Connection';
            update testProduct;

            Product2 financeCharge = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, true);
            financeCharge.Name = 'Test Finance Charge';
            update financeCharge;
            
            Account testAccount = testData.Account;
            testAccount.Finance_Charge__c = 10.5;
            testAccount.USS_Grace_Period__c = 0;
            testAccount.Suppress_Late_Charge__c = false;
            update testAccount;

            System.debug('Current Percent is: ' + testData.Account.Finance_Charge__c);

            fferpcore__BillingDocument__c billDoc = lp_SetupTest.createBillingDocument(testAccount.Id, false);
            billDoc.fferpcore__Company__c = coreCompany.Id;
            billDoc.fferpcore__DocumentDate__c = Date.today().addDays(-15);
            billDoc.fferpcore__DocumentDueDate__c = Date.today().addDays(-5);
            insert billDoc;
    
            fferpcore__BillingDocumentLineItem__c billDocLine = lp_SetupTest.createBillingDocumentLine(billDoc.Id, testProduct.Id, true);
 
            billDoc.fferpcore__DocumentStatus__c = 'Complete';
            upsert billDoc;

            billDoc = docSelector.getById(billDoc.Id);

            c2g.CODAAPICommon_6_0.Context ctx = new c2g.CODAAPICommon_6_0.Context();
            ctx.companyName = 'Test Company';
            List<c2g.CODAAPICommon.Reference> refs = new List<c2g.CODAAPICommon.Reference>();

            try {
                c2g.CODAAPICommon_10_0.Context context = new c2g.CODAAPICommon_10_0.Context();
                context.CompanyName = testData.CurrentCompany.Name;
                c2g.BillingDocumentPostingService.PostingRequest request = new c2g.BillingDocumentPostingService.PostingRequest(new Set<Id> {billDoc.Id});
                c2g.BillingDocumentPostingService.postNow(request);
                System.assert(true, 'Post worked!');
            }
            catch(Exception e) {
                throw new lp_Exception('Certinia Post failed: ' + e.getMessage(), false);
            }

            billDoc = docSelector.getById(billDoc.Id);

            Assert.areEqual(100, billDoc.c2g__OutstandingValue__c, 'Outstanding Value: ' + billDoc.c2g__OutstandingValue__c);
            Assert.areEqual(true, billDoc.Finance_Charge_Calculation__c, 'Finance Charge Calc Formula Field Value: ' + billDoc.Finance_Charge_Calculation__c);
            Assert.areEqual(true, billDoc.Document_Is_Late__c, 'Document Is Late Formula Field Value: ' + billDoc.Document_Is_Late__c);
            Assert.areEqual(10.5, billDoc.fferpcore__Account__r.Finance_Charge__c, 'Finance Charge Value: ' + billDoc.fferpcore__Account__r.Finance_Charge__c);
            Assert.areEqual(false, billDoc.fferpcore__Account__r.Suppress_Late_Charge__c, 'Suppress Charge Value: ' + billDoc.fferpcore__Account__r.Suppress_Late_Charge__c);
    
            Test.startTest();
            lp_MonthlyLateFeesBatch.runJob();
            Test.stopTest();

            List<fferpcore__BillingDocument__c> lateBillDocs = new lp_BillingDocumentSelector().getLateBillingDocuments();

            Assert.isTrue(lateBillDocs.size() > 0, 'Late Billing Documents not created successfully');

            fferpcore__BillingDocument__c resultBillDoc = lateBillDocs[0];
            Assert.areEqual(testAccount.Id, resultBillDoc.fferpcore__Account__c, 'Accounts don\'t match!');
            Assert.areEqual(Date.today(), resultBillDoc.fferpcore__DocumentDate__c, 'Date is not today!');
            Assert.areEqual('Finance Charge - ' + DateTime.newInstance(Date.today().year(), Date.today().month(), 1).format('MMMM'), resultBillDoc.Customer_Notes__c, 'Customer Notes field not set correctly - Value is: ' + resultBillDoc.Customer_Notes__c);
            Assert.areEqual('Posted', resultBillDoc.c2g__PostingStatus__c, 'Document wasn\'t posted properly - Value is: ' + resultBillDoc.fferpcore__DocumentStatus__c);
            Assert.isNull(resultBillDoc.c2g__PostingError__c, 'Posting Error field not blank - ' + resultBillDoc.c2g__PostingError__c);

            for(fferpcore__BillingDocument__c currentDoc : lateBillDocs) {
                fferpcore__BillingDocument__c currentDocWithLines = new lp_BillingDocumentSelector().getWithLinesById(currentDoc.Id);

                for(fferpcore__BillingDocumentLineItem__c currentLine : currentDocWithLines.fferpcore__ChildBillingDocumentLineItems__r) {
                    Assert.areEqual(1, currentLine.fferpcore__Quantity__c, 'Quantity not set correctly!');
                    Assert.areEqual(10.5, currentLine.fferpcore__NetValueOverride__c, 'Net Value not set correctly!');
                    Assert.areEqual(financeCharge.Id, currentLine.fferpcore__ProductService__r.Id, 'Finance Charge Product incorrect!');
                }
            }
        }
    }

    @isTest
    private static void invalidLateMonthlyBillDoc() {
        lp_SetupTestFFA.createBaseFFAData('US Signal', 'US Checking');
        lp_SetupTestFFA.TestData testData = lp_SetupTestFFA.testData;

        lp_BillingDocumentSelector docSelector = new lp_BillingDocumentSelector();

        System.runAs(testData.TestUser) {
            c2g.CODAAPICommon_6_0.Context ctx = new c2g.CODAAPICommon_6_0.Context();
            ctx.companyName = 'TestCompany';

            LPC_Billing_Central_Configuration__c billConfig = new LPC_Billing_Central_Configuration__c();
            billConfig.Days_Past_Due__c = 1;
            billConfig.Finance_Charge_SF_Product__c = 'Test Finance Charge';
            insert billConfig;

            fferpcore__Company__c coreCompany = new fferpcore__Company__c(
                    Name = 'FFERCore Company Signal',
                    c2g__msg_link_ffa_id__c = testData.CurrentCompany.Id
            );
            insert coreCompany;

            Product2 testProduct = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, true);
            testProduct.Name = '2 x 1 Gbps CDC Connection';
            update testProduct;

            Product2 financeCharge = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, true);
            financeCharge.Name = 'Test Finance Charge';
            update financeCharge;
            
            Account testAccount = testData.Account;
            testAccount.Finance_Charge__c = 10.5;
            testAccount.USS_Grace_Period__c = 0;
            testAccount.Suppress_Late_Charge__c = true;
            upsert testAccount;

            System.debug('Current Percent is: ' + testData.Account.Finance_Charge__c);

            fferpcore__BillingDocument__c billDoc = lp_SetupTest.createBillingDocument(testAccount.Id, true);
            billDoc.fferpcore__Company__c = coreCompany.Id;
            billDoc.fferpcore__DocumentDate__c = Date.today().addDays(-15);
            billDoc.fferpcore__DocumentDueDate__c = Date.today().addDays(-5);
            upsert billDoc;

            fferpcore__BillingDocumentLineItem__c billDocLine = lp_SetupTest.createBillingDocumentLine(billDoc.Id, testProduct.Id, true);
            
            billDoc.fferpcore__DocumentStatus__c = 'Complete';
            upsert billDoc;

            c2g.CODAAPICommon_10_0.Context context = new c2g.CODAAPICommon_10_0.Context();
            List<c2g.CODAAPICommon.Reference> refs = new List<c2g.CODAAPICommon.Reference>();
            context.CompanyName = testData.CurrentCompany.Name;

            try {
                c2g.BillingDocumentPostingService.PostingRequest request = new c2g.BillingDocumentPostingService.PostingRequest(new Set<Id> {billDoc.Id});
                c2g.BillingDocumentPostingService.postNow(request);
                System.assert(true, 'Post worked!');
            }
            catch(Exception e) {
                throw new lp_Exception('Certinia Post failed: ' + e.getMessage(), false);
            }

            billDoc = docSelector.getById(billDoc.Id);

            Assert.areEqual(100, billDoc.c2g__OutstandingValue__c, 'Outstanding Value: ' + billDoc.c2g__OutstandingValue__c);
            Assert.areEqual(false, billDoc.Finance_Charge_Calculation__c, 'Finance Charge Calc Formula Field Value: ' + billDoc.Finance_Charge_Calculation__c);
            Assert.areEqual(true, billDoc.Document_Is_Late__c, 'Document Is Late Formula Field Value: ' + billDoc.Document_Is_Late__c);
            Assert.areEqual(10.5, billDoc.fferpcore__Account__r.Finance_Charge__c, 'Finance Charge Value: ' + billDoc.fferpcore__Account__r.Finance_Charge__c);
            Assert.areEqual(true, billDoc.fferpcore__Account__r.Suppress_Late_Charge__c, 'Suppress Charge Value: ' + billDoc.fferpcore__Account__r.Suppress_Late_Charge__c);
    
            Test.startTest();
            lp_MonthlyLateFeesBatch.runJob();
            Test.stopTest();

            List<fferpcore__BillingDocument__c> lateBillDocs = new lp_BillingDocumentSelector().getLateBillingDocuments();

            Assert.isTrue(lateBillDocs.size() == 0, 'Late Billing Documents were incorrectly created!');
        }
    }
}