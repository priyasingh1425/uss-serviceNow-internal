/**
 * @author Ladd Partners
 * @date 11/28/2017
 * @group
*/

@isTest
public with sharing class lp_SetupTestFFA {

    public static TestData testData = new TestData();

    public static void createBaseFFAData() {
        createBaseFFAData('TestCompany', 'US Checking' );
    }
    public static void createBaseFFAData(String companyName, String bankAccountName)
    {
        if(testData.TestUser != null){ return; }
        
        testData.TestUser = createUser();

        System.runAs(testData.TestUser)
        {
            // GLA's, Accounts and Products are not company aware, create them first
            testData.GLAMap = createGLAccounts();
            testData.Account = createAccount('Tony Stark Enterprises', testData.GLAMap.get('accountsReceivableControl').Id, testData.GLAMap.get('accountsPayableControl').Id);
            testData.Product = createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, true);
            // create all 'Company' aware data objects
            // Create the Queue and simulate activating the company
            testData.CurrentCompany = createFFACompany(companyName, createFFAQueue(testData.TestUser.Id).Id);
            // Add a user Company
            createUserCompany(testData.CurrentCompany.Id, testData.TestUser.Id);
            List<String> companies_selected = c2g.CODAAPICompany_2_0.GetCurrentCompanies(null);
            // create other base data types...
            testData.HomeCurrency = createHomeCurrency(testData.CurrentCompany.Id, 'USD');
            testData.CurrentPeriod = createYearPeriods();
            testData.bankAccount = createBankAccount(bankAccountName,testData.GLAMap.get('bankAccCurUK').id
                    ,testData.HomeCurrency.id);

            // create 2nd company
            testData.Company2 = createFFACompany('TestCompany2', createFFAQueue(null).Id);
            // Add a user Company
            //createUserCompany(testData.Company2.Id, UserInfo.getUserId());

            testData.Dimension1 = createDimension1();
            testData.Dimension2 = createDimension2();
            testData.Dimension3 = createDimension3();
            testData.Dimension4 = createDimension4();

            testData.AccountSettings = createAccountingSettingsCustomSettings();
        }
    }

    public static User createUser()
    {
        Profile p = [select id from profile where name='System Administrator'];

        User u = new User();
        u.FirstName = 'FFA';
        u.LastName = 'User';
        u.Alias = 'FFAUSER';
        u.Username = 'developer@nowhere.com';
        u.Email = 'developer@nowhere.com';
        u.CommunityNickname = 'ffd';
        u.Phone = '555.555.5555';
        u.IsActive = true;
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'en_US';
        u.CompanyName = 'Test Company';

        insert u;

        return u;
    }

    public static c2g__codaAccountingSettings__c createAccountingSettingsCustomSettings(){
        c2g__codaAccountingSettings__c accountingSettings = c2g__codaAccountingSettings__c.getInstance();
        if(accountingSettings == null) {
            accountingSettings = new c2g__codaAccountingSettings__c();
        }
        accountingSettings.c2g__EnableOverrideProductGLA__c = true;
        upsert accountingSettings;
        return accountingSettings;
    }

    /**
        *   Create FFA Queue (FinancialForce)
        *   No @Parms required
    **/
    public static Group createFFAQueue(Id userId)
    {
        //Create queue
        Group grp = new Group(Type = 'Queue', Name = 'FF FinancialForce');
        insert grp;

        //Create list of all FinancialForce Objctes
        List<String> queueObjectNames =  getQueueObjectNames();

        //Assign Objects to Queue
        List<QueueSObject> newQueueObjects = new List<QueueSObject>();
        for (String queueObjectName : queueObjectNames)
        {
            newQueueObjects.add(new QueueSObject(QueueId = grp.id, SobjectType = queueObjectName));
        }
        insert newQueueObjects;

        if (userId != null)
        {
            //Assign group to a current user
            insert new GroupMember(GroupId = grp.id, UserOrGroupId = userId);
        }

        return grp;
    }

    /**
        *   Create FFA Company (FinancialForce Test Company)
        *   No @Parms required
    **/
    public static c2g__codaCompany__c createFFACompany(String name, Id queueMemberId)
    {
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c();
        testCompany.put('Name', name);
        testCompany.put('OwnerId', queueMemberId);
        testCompany.put('c2g__Street__c', 'Cardale Park');
        testCompany.put('c2g__StateProvince__c', 'Beckwith Head Road');
        testCompany.put('c2g__City__c', 'Harrogate');
        testCompany.put('c2g__ZipPostCode__c', 'HG3 1RY');
        testCompany.put('c2g__Country__c', 'United Kingdom');
        testCompany.put('c2g__Phone__c', '+44 (0)1423 537728)');

        insert testCompany;

        return testCompany;

    }

    public static void createUserCompany(Id companyId, Id userId)
    {
        insert new c2g__codaUserCompany__c(c2g__Company__c = companyId, c2g__User__c = userId);
    }

    /**
        *   Create FFA Currency (USD)
        *   No @Parms required
    **/
    public static c2g__codaAccountingCurrency__c createHomeCurrency(Id companyId, String name)
    {
        c2g__codaAccountingCurrency__c testCurrency = new c2g__codaAccountingCurrency__c();
        testCurrency.put('Name', name);
        //testCurrency.put('c2g__UnitOfWork__c', 1);
        testCurrency.put('c2g__DecimalPlaces__c', 2);
        testCurrency.put('c2g__Home__c', true);
        testCurrency.put('c2g__Dual__c', true);
        testCurrency.put('c2g__OwnerCompany__c', companyId);

        insert testCurrency;

        return testCurrency;
    }

    public static c2g__codaPeriod__c createYearPeriods()
    {
        String currentYear = String.valueOf(Date.today().year());

        c2g__codaYear__c yr = new c2g__codaYear__c();
        yr.put('Name', currentYear);
        yr.put('c2g__NumberOfPeriods__c', 12);
        yr.put('c2g__AutomaticPeriodList__c', true);
        yr.put('c2g__StartDate__c', Date.valueOf(currentYear + '-01-01 00:00:00'));
        yr.put('c2g__EndDate__c', Date.valueOf(currentYear + '-12-31 00:00:00'));
        yr.put('c2g__PeriodCalculationBasis__c', 'Month End');

        insert yr;

        String currentMth = String.valueOf(Date.today().month());
        if(currentMth.length() == 1)
            currentMth = '0' + currentMth;

        List<c2g__codaPeriod__c> periods = new List<c2g__codaPeriod__c>();

        c2g__codaPeriod__c currentTestPeriod;
        List<String> monthNumbers = new List<String>{'01','02','03','04','05','06','07','08','09','10','11','12','01','12','12'};
        for (String monthNumber : monthNumbers)
        {
            c2g__codaPeriod__c period = new c2g__codaPeriod__c();
            period.put('Name', currentYear + '/' + '0' + monthNumber);
            period.put('c2g__YearName__c', yr.id);
            period.put('c2g__PeriodNumber__c', '0' + monthNumber);
            period.put('c2g__Description__c', 'Trading Period');
            period.put('c2g__StartDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00'));
            period.put('c2g__EndDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00').addMonths(1).addDays(-1));
            periods.add(period);

            //returns current period
            if (currentTestPeriod == null && monthNumber == currentMth)
                currentTestPeriod = period;
        }
        // fix the opening period
        periods[12].put('Name', currentYear + '/000');
        periods[12].put('c2g__PeriodNumber__c', '000');
        periods[12].put('c2g__Description__c', 'Opening (B/fwd)');
        periods[12].put('c2g__EndDate__c', periods[12].c2g__StartDate__c);

        // fix the closing period
        periods[13].put('Name' , currentYear + '/101');
        periods[13].put('c2g__PeriodNumber__c', '101');
        periods[13].put('c2g__Description__c', 'Closing (C/fwd)');
        periods[13].put('c2g__StartDate__c', periods[13].c2g__EndDate__c);

        // fix the adjustment period
        periods[14].put('Name' , currentYear + '/100');
        periods[14].put('c2g__PeriodNumber__c', '100');
        periods[14].put('c2g__Description__c', 'Adjustment Period');
        periods[14].put('c2g__StartDate__c', periods[14].c2g__EndDate__c);

        insert periods;

        return currentTestPeriod;
    }

    /**
    *   Create GLA Accounts
    *   No @Parms required
    **/
    public static Map<String,c2g__codaGeneralLedgerAccount__c> createGLAccounts()
    {
        c2g__codaGeneralLedgerAccount__c accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs;

        List<c2g__codaGeneralLedgerAccount__c> glaList;

        deferredIncome = new c2g__codaGeneralLedgerAccount__c();
        deferredIncome.put('Name' , '2200 - Deferred Income');
        deferredIncome.put('c2g__ReportingCode__c' , '2200t');
        deferredIncome.put('c2g__Type__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__TrialBalance3__c' , 'Accruals and Deferred Income');
        deferredIncome.put('c2g__TrialBalance4__c' , '-');
        deferredIncome.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__BalanceSheet3__c' , 'Accruals and Deferred Income');

        accountsPayableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsPayableControl.put('Name' , '2000 - Accounts Payable Control');
        accountsPayableControl.put('c2g__ReportingCode__c' , '2000t');
        accountsPayableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__TrialBalance3__c' , 'Creditors');
        accountsPayableControl.put('c2g__TrialBalance4__c' , '-');
        accountsPayableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__BalanceSheet3__c' , 'Creditors');

        accountsReceivableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsReceivableControl.put('Name' , '1200 - Accounts Receivable Control');
        accountsReceivableControl.put('c2g__ReportingCode__c' , '1200t');
        accountsReceivableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__TrialBalance3__c' , 'Debtors');
        accountsReceivableControl.put('c2g__TrialBalance4__c' , '-');
        accountsReceivableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__BalanceSheet2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__BalanceSheet3__c' , 'Debtors');

        grossRevenue = new c2g__codaGeneralLedgerAccount__c();
        grossRevenue.put('Name' , '4000 - Gross revenue');
        grossRevenue.put('c2g__ReportingCode__c' , '4000t');
        grossRevenue.put('c2g__Type__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance2__c' , 'Gross Profit');
        grossRevenue.put('c2g__TrialBalance3__c' , 'Sales Revenue');
        grossRevenue.put('c2g__TrialBalance4__c' , 'Sales - Direct');
        grossRevenue.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        grossRevenue.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        grossRevenue.put('c2g__BalanceSheet3__c' , '-');

        //Bank Account - Current UK
        bankAccCurUK = new c2g__codaGeneralLedgerAccount__c();
        bankAccCurUK.put('Name' , '24000 - Customer Prepaids (MPS)');
        bankAccCurUK.put('c2g__ReportingCode__c' , 'BNK001');
        bankAccCurUK.put('c2g__Type__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__TrialBalance3__c' , 'Bank and Cash');
        bankAccCurUK.put('c2g__TrialBalance4__c' , '');
        bankAccCurUK.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__BalanceSheet3__c' , 'Bank and Cash');

        //Bank Charges
        bankCharges = new c2g__codaGeneralLedgerAccount__c();
        bankCharges.put('Name' , 'Bank Charges');
        bankCharges.put('c2g__ReportingCode__c' , '61620');
        bankCharges.put('c2g__Type__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance2__c' , 'Operating Expenses');
        bankCharges.put('c2g__TrialBalance3__c' , 'Administration Costs');
        bankCharges.put('c2g__TrialBalance4__c' , '');
        bankCharges.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankCharges.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankCharges.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Bank Charges
        bankInterest = new c2g__codaGeneralLedgerAccount__c();
        bankInterest.put('Name' , 'Bank Interest');
        bankInterest.put('c2g__ReportingCode__c' , '64740');
        bankInterest.put('c2g__Type__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance2__c' , 'Interest and Taxation');
        bankInterest.put('c2g__TrialBalance3__c' , 'Finance Costs');
        bankInterest.put('c2g__TrialBalance4__c' , '');
        bankInterest.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankInterest.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankInterest.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Tax Code
        salesTaxA = new c2g__codaGeneralLedgerAccount__c();
        salesTaxA.put('Name' , '2160 - Sales Tax A');
        salesTaxA.put('c2g__ReportingCode__c' , '2160t');
        salesTaxA.put('c2g__Type__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__TrialBalance3__c' , 'Tax Liability');
        salesTaxA.put('c2g__TrialBalance4__c' , '');
        salesTaxA.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__BalanceSheet3__c' , 'Tax Liability');

        cogs = new c2g__codaGeneralLedgerAccount__c();
        cogs.put('Name' , '5100 - COGS - Materials');
        cogs.put('c2g__ReportingCode__c' , '5100t');
        cogs.put('c2g__Type__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance2__c' , 'Gross Profit');
        cogs.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        cogs.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        cogs.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        cogs.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        cogs.put('c2g__BalanceSheet3__c' , '');

        glaList = new List<c2g__codaGeneralLedgerAccount__c>{accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs};
        insert glaList;

        return new Map<String,c2g__codaGeneralLedgerAccount__c>{
                'accountsPayableControl'=>accountsPayableControl,
                'accountsReceivableControl'=>accountsReceivableControl,
                'grossRevenue'=>grossRevenue,
                'bankAccCurUK'=>bankAccCurUK,
                'bankCharges'=>bankCharges,
                'bankInterest'=>bankInterest,
                'deferredIncome'=>deferredIncome,
                'salesTaxA'=>salesTaxA,
                'cogs'=>cogs
        };

    }

    /**
    *   Create or Insert Account
    *   No @Parms required
    **/
    public static Account createAccount(String name, Id accountsReceivableControlId, Id accountsPayableControlId) {
       return createAccount(name, accountsReceivableControlId, accountsPayableControlId, true);
    }

    public static Account createAccount(String name, Id accountsReceivableControlId, Id accountsPayableControlId, boolean doSave)
    {
        Account productServices = new Account();
        productServices.put('Name', name);
        if(UserInfo.isMultiCurrencyOrganization()) {
            productServices.put('CurrencyIsoCode', 'USD');
        }
        productServices.put('Type', 'Customer - Direct');
        productServices.put('Industry', 'Apparel');
        productServices.put('AnnualRevenue', 350000000);
        productServices.put('Ownership', 'Public');
        productServices.put('Rating', 'Warm');
        productServices.put('Phone', '(336) 222-7000');
        productServices.put('Fax', '(336) 222-8000');
        productServices.put('Website', 'http://www.financialforce.com');
        productServices.put('TickerSymbol', 'BTXT');
        productServices.put('NumberOfEmployees', 9000);
        productServices.put('SIC', '546732');
        productServices.put('BillingCountryCode', 'US');
        productServices.put('BillingStateCode','CA');
        productServices.put('ShippingCountryCode', 'US');
        productServices.put('ShippingStateCode','CA');
        productServices.put('c2g__CODAReportingCode__c', 'ABC123t');
        productServices.put('c2g__CODAAccountsReceivableControl__c', accountsReceivableControlId);
        productServices.put('c2g__CODAAccountsPayableControl__c', accountsPayableControlId);
        productServices.put('c2g__CODASalesTaxStatus__c', 'Exempt');
        productServices.put('c2g__CODAVATStatus__c', 'EC Registered');
        productServices.put('c2g__CODAECCountryCode__c', 'FR');
        productServices.put('c2g__CODAVATRegistrationNumber__c', '123 43223 3');
        productServices.put('c2g__CODATaxCalculationMethod__c', 'Gross');
        productServices.put('c2g__CODAInvoiceEmail__c', 'productservices@financialforce.com');
        productServices.put('c2g__CODADescription1__c', 'Standard Terms');
        productServices.put('c2g__CODADaysOffset1__c', 30);
        productServices.put('c2g__CODABaseDate1__c', 'Invoice Date');
        productServices.put('c2g__CODADiscount1__c', 0);
        productServices.put('c2g__CODAAccountTradingCurrency__c', 'USD');
        productServices.put('c2g__CODABankAccountNumber__c','85595740');
        productServices.SCMC__Active__c = true;
        productServices.SCMC__Customer__c = true;
        productServices.SCMC__Preferred_Communication__c = 'E-Mail';
        productServices.SCMC__E_Mail__c = 'a@b.com';

        if(doSave){
            insert productServices;
        }

        return productServices;
    }

    /**
    *   Create or Insert Bank Account
    *   @param name The name of the bank account
    *   @param bankAccountGLId The id of the general ledger associated with the bank account
    *   @param bankAccountCurrencyId The id of accounting currency associated with the bank account
    **/
    public static c2g__codaBankAccount__c createBankAccount(String name, Id bankAccountGLId, ID bankAccountCurrencyId)
    {
        c2g__codaBankAccount__c productServices = new c2g__codaBankAccount__c();

        productServices.put('Name', name);
        if(UserInfo.isMultiCurrencyOrganization()) {
            productServices.put('CurrencyIsoCode', 'USD');
        }
        productServices.put('c2g__AccountName__c', name);
        productServices.put('c2g__AccountNumber__c', 'Account Number');
        productServices.put('c2g__BankAccountCurrency__c', bankAccountCurrencyId);
        productServices.put('c2g__GeneralLedgerAccount__c', bankAccountGLId);
        productServices.put('c2g__BankName__c', name);
        productServices.put('c2g__ReportingCode__c', 'Bank rep code');
        productServices.put('c2g__SortCode__c', '102001');
        productServices.put('c2g__OwnerCompany__c', testData.CurrentCompany.ID);

        insert productServices;

        return productServices;
    }
    /**
        *   Create Product
        *   No @Parms required
    **/
    public static Product2 createProduct(Id cogsId, Id grossRevenueId, boolean doInsert)
    {
        Product2 prod = new Product2();
        prod.put('Name' , 'Titanium');
        prod.put('ProductCode' , 'TIT101');
        prod.put('IsActive' , true);
        prod.put('c2g__CODAPurchaseAnalysisAccount__c' , cogsId);
        prod.put('c2g__CODASalesRevenueAccount__c' , grossRevenueId);
        prod.put('c2g__CODASalesTaxStatus__c' , 'Taxable');
        prod.put('System_Origin__c' , 'Salesforce');
        prod.put('Billing_Display__c' , 'Display');

        if (doInsert) {insert prod;}
        return prod;
    }

    /**
        *   Create PricebookEntry
        *   Two Params required
        *       - Id prodId - Product2 Id
        *       - Boolean doInsert - Invoke DML insert or not
    **/
    public static PricebookEntry createPriceBookEntry(Id prodId, Boolean doInsert)
    {
        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.put('Pricebook2Id' , Test.getStandardPricebookId());
        priceBookEntry.put('Product2Id' , prodId);
        priceBookEntry.put('UnitPrice' , 5000);
        priceBookEntry.put('IsActive' , true);
        priceBookEntry.put('UseStandardPrice' , false);

        if(doInsert){
            insert priceBookEntry;
        }
        return priceBookEntry;
    }

    /**
    *   Create Sales Invoice Header
    *   One Param required
    *       - Id accId - Account Id
    **/
    public static c2g__codaInvoice__c createSalesInvoice(Id accId, Id currencyId, Id periodId) {
        return lp_SetupTestFFA.createSalesInvoice(accId, currencyId, periodId, true);
    }

    public static c2g__codaInvoice__c createSalesInvoice(Id accId, Id currencyId, Id periodId, Boolean do_save)
    {
        c2g__codaInvoice__c invoice = new c2g__codaInvoice__c();
        invoice.put('c2g__Account__c' , accId);
        invoice.put('c2g__InvoiceDate__c' , System.today());
        invoice.put('c2g__InvoiceCurrency__c' , currencyId);
        invoice.put('c2g__Period__c' , periodId);

        if(do_save){
            insert invoice;
        }
        return invoice;
    }

    /**
    *   Create Sales Invoice Line
    *   Two Param required
    *       - Id prodId - Product2 Id
    *       - Id headerId - Sales Invoice Header Id
    **/

    public static c2g__codaInvoiceLineItem__c createSalesInvoiceLine(Id headerId, Id prodId){
        return lp_SetupTestFFA.createSalesInvoiceLine(headerId, prodId, 500, true);
    }

    public static c2g__codaInvoiceLineItem__c createSalesInvoiceLine(Id headerId, Id prodId, Decimal amount, Boolean doSave){
        c2g__codaInvoiceLineItem__c invoiceLine = new c2g__codaInvoiceLineItem__c();
        invoiceLine.put('c2g__Quantity__c' ,amount);
        invoiceLine.put('c2g__LineDescription__c' , 'Testing123CoolDude123Income');
        invoiceLine.put('c2g__UnitPrice__c' , 1);
        invoiceLine.put('c2g__Product__c' , prodId);
        invoiceLine.put('c2g__DeriveUnitPriceFromProduct__c' , false);
        invoiceLine.put('c2g__Invoice__c' , headerId);

        if(doSave){
            insert invoiceLine;
        }
        return invoiceLine;
    }

    public static c2g__codaCreditNote__c createCreditNote(Id accId, Id currencyId, boolean doInsert) {
        c2g__codaCreditNote__c codaCreditNote = new c2g__codaCreditNote__c();
        codaCreditNote.c2g__Account__c = accId;
        codaCreditNote.c2g__CreditNoteCurrency__c = currencyId;
        codaCreditNote.c2g__CreditNoteDate__c = System.today();

        if (doInsert) {
            insert codaCreditNote;
        }

        return codaCreditNote;
    }

    public static c2g__codaCreditNoteLineItem__c createCreditNoteLine(Id headerId, Id productId, boolean doInsert) {
        c2g__codaCreditNoteLineItem__c codaCreditNoteLineItem = new c2g__codaCreditNoteLineItem__c();
        codaCreditNoteLineItem.c2g__CreditNote__c = headerId;
        codaCreditNoteLineItem.c2g__Quantity__c = 1;
        codaCreditNoteLineItem.c2g__Product__c = productId;
        codaCreditNoteLineItem.c2g__UnitPrice__c = 100;

        if (doInsert) {
            insert codaCreditNoteLineItem;
        }

        return codaCreditNoteLineItem;
    }

    /**
        *   Create List of Object Queue Names
        *   No @Parms required
    **/
    public static List<String> getQueueObjectNames()
    {
        List<String> objectNames = new List<String>();

        //Financial Objects
        objectNames.add('c2g__codaCompany__c');
        objectNames.add('c2g__codaYear__c');
        objectNames.add('c2g__codaCurrencyRevaluation__c');
        objectNames.add('c2g__ReportingBalance__c');
        objectNames.add('c2g__codaBudget__c');
        objectNames.add('c2g__codaBankAccount__c');
        objectNames.add('c2g__codaBankStatement__c');
        objectNames.add('c2g__codaPaymentMediaControl__c');
        objectNames.add('c2g__codaBankReconciliation__c');
        objectNames.add('c2g__codaPaymentMediaSummary__c');
        objectNames.add('c2g__codaMatchingReference__c');
        objectNames.add('c2g__codaAccountingCurrency__c');
        objectNames.add('c2g__codaGroupingReference__c');
        objectNames.add('c2g__codaPaymentTemplate__c');

        //Document Objects
        objectNames.add('c2g__codaTransaction__c');
        objectNames.add('c2g__codaInvoice__c');
        objectNames.add('c2g__codaJournal__c');
        objectNames.add('c2g__codaCreditNote__c');
        objectNames.add('c2g__codaCashEntry__c');
        objectNames.add('c2g__codaPurchaseInvoice__c');
        objectNames.add('c2g__codaPurchaseCreditNote__c');
        objectNames.add('c2g__codaPayment__c');
        //objectNames.add('c2g__CancelPayment__c');
        objectNames.add('c2g__codaCashMatchingHistory__c');

        //Random Objects
        objectNames.add('c2g__codaTextDefinition__c');
        objectNames.add('c2g__codaIntercompanyDefinition__c');
        //objectNames.add('c2g__AsOfAging__c');
        objectNames.add('c2g__codaIntercompanyTransfer__c');
        objectNames.add('c2g__codaYear__c');

        return objectNames;
    }

    public static c2g__codaDimension1__c createDimension1()
    {
        c2g__codaDimension1__c testDimension = new c2g__codaDimension1__c(Name='$$$$TestDim1$$$$',c2g__ReportingCode__c='$$$$TestDim1$$$$');

        insert testDimension;

        return testDimension;
    }

    public static c2g__codaDimension2__c createDimension2()
    {
        c2g__codaDimension2__c testDimension = new c2g__codaDimension2__c(Name='$$$$TestDim2$$$$',c2g__ReportingCode__c='$$$$TestDim2$$$$');

        insert testDimension;

        return testDimension;
    }

    public static c2g__codaDimension3__c createDimension3()
    {
        c2g__codaDimension3__c testDimension = new c2g__codaDimension3__c(Name='$$$$TestDim3$$$$',c2g__ReportingCode__c='$$$$TestDim3$$$$');

        insert testDimension;

        return testDimension;
    }

    public static c2g__codaDimension4__c createDimension4()
    {
        c2g__codaDimension4__c testDimension = new c2g__codaDimension4__c(Name='$$$$TestDim4$$$$',c2g__ReportingCode__c='$$$$TestDim4$$$$');

        insert testDimension;

        return testDimension;
    }


    public static c2g__codaGeneralLedgerAccount__c createGLAcount(string glName, string reportingCode, boolean do_save) {
        c2g__codaGeneralLedgerAccount__c glAccount = new c2g__codaGeneralLedgerAccount__c();
        glAccount.put('Name' , glName);
        glAccount.put('c2g__ReportingCode__c' , reportingCode);
        glAccount.put('c2g__Type__c' , 'Balance Sheet');
        glAccount.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        glAccount.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        glAccount.put('c2g__TrialBalance3__c' , 'Accruals and Deferred Income');
        glAccount.put('c2g__TrialBalance4__c' , '-');
        glAccount.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        glAccount.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        glAccount.put('c2g__BalanceSheet3__c' , 'Accruals and Deferred Income');

        if (do_save) {
            insert glAccount;
        }

        return glAccount;
    }

    public static Opportunity createOpportunity(Id accountId, boolean doInsert) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Qualification';
        opp.CloseDate = system.today();
        opp.PriceBook2Id = Test.getStandardPricebookId();
        opp.Primary_Contact_Added__c = true;
        opp.AccountId = accountId;
        if (doInsert) {
            insert opp;
        }

        return opp;
    }

    public class TestData
    {
        public Account Account {get;set;}
        public c2g__codaCompany__c CurrentCompany {get;set;}
        public c2g__codaCompany__c Company2 {get;set;}
        public c2g__codaBankAccount__c bankAccount {get; set;}
        public c2g__codaPeriod__c CurrentPeriod {get;set;}
        public c2g__codaAccountingCurrency__c HomeCurrency {get;set;}
        public Product2 Product {get;set;}
        public Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap {get;set;}
        public User TestUser {get;set;}
        public Map<String, Product2> SpecialProducts {get;set;}
        public c2g__codaDimension1__c Dimension1 {get;set;}
        public c2g__codaDimension2__c Dimension2 {get;set;}
        public c2g__codaDimension3__c Dimension3 {get;set;}
        public c2g__codaDimension4__c Dimension4 {get;set;}
        public c2g__codaAccountingSettings__c AccountSettings {get; set;}

        public void refresh(){
            refresh(null);
        }

        public void refresh(String companyName)
        {
            
            List<User> users = [SELECT Id FROM User WHERE Username = 'developer@nowhere.com'];
            this.TestUser = users.isEmpty() ? null : users[0];

            // Query for the specific account created in createAccount
            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'Tony Stark Enterprises'];
            this.Account = accounts.isEmpty() ? null : accounts[0];

            // Query for company. Assumes 'TestCompany' is the default/expected name if not specified.
            List<c2g__codaCompany__c> companies = [SELECT Id FROM c2g__codaCompany__c WHERE Name = 'TestCompany'];
            this.CurrentCompany = companies.isEmpty() ? null : companies[0];
            
            List<c2g__codaCompany__c> company2List = [SELECT Id FROM c2g__codaCompany__c WHERE Name = 'TestCompany2'];
            this.Company2 = company2List.isEmpty() ? null : company2List[0];
            
            // Query for currency. Assumes 'USD' is the one.
            List<c2g__codaAccountingCurrency__c> currencies = [SELECT Id, Name FROM c2g__codaAccountingCurrency__c WHERE Name = 'USD'];
            this.HomeCurrency = currencies.isEmpty() ? null : currencies[0];

            // Query for the specific product created in createProduct, using its unique code.
            List<Product2> products = [SELECT Id, Name FROM Product2 WHERE ProductCode = 'TIT101'];
            this.Product = products.isEmpty() ? null : products[0];
            
            List<c2g__codaPeriod__c> periods = [SELECT Id FROM c2g__codaPeriod__c WHERE c2g__Description__c = 'Trading Period' AND c2g__StartDate__c <= :System.today() AND c2g__EndDate__c >= :System.today()];
            this.CurrentPeriod = periods.isEmpty() ? null : periods[0];

            this.GLAMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
            Set<String> glaNames = new Set<String>{
                '2000 - Accounts Payable Control', '1200 - Accounts Receivable Control',
                '4000 - Gross revenue', '24000 - Customer Prepaids (MPS)',
                'Bank Charges', 'Bank Interest', '2200 - Deferred Income',
                '2160 - Sales Tax A', '5100 - COGS - Materials'
            };
            for (c2g__codaGeneralLedgerAccount__c gla : [SELECT Id, Name FROM c2g__codaGeneralLedgerAccount__c WHERE Name IN :glaNames]) {
                if (gla.Name == '2000 - Accounts Payable Control') {
                    this.GLAMap.put('accountsPayableControl', gla);
                } else if (gla.Name == '1200 - Accounts Receivable Control') {
                    this.GLAMap.put('accountsReceivableControl', gla);
                } else if (gla.Name == '4000 - Gross revenue') {
                    this.GLAMap.put('grossRevenue', gla);
                } else if (gla.Name == '24000 - Customer Prepaids (MPS)') {
                    this.GLAMap.put('bankAccCurUK', gla);
                } else if (gla.Name == 'Bank Charges') {
                    this.GLAMap.put('bankCharges', gla);
                } else if (gla.Name == 'Bank Interest') {
                    this.GLAMap.put('bankInterest', gla);
                } else if (gla.Name == '2200 - Deferred Income') {
                    this.GLAMap.put('deferredIncome', gla);
                } else if (gla.Name == '2160 - Sales Tax A') {
                    this.GLAMap.put('salesTaxA', gla);
                } else if (gla.Name == '5100 - COGS - Materials') {
                    this.GLAMap.put('cogs', gla);
                }
            }
        }
    }

}