/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_AccountSelector extends lp_Selector {
    public lp_AccountSelector() {
        setSObjectType(Account.getSObjectType());
        addField(Account.Id);
        addField(Account.Name);
        addField(Account.c2g__CODAAccountsReceivableControl__c);
        addField(Account.Certify_Employee_Id__c);
        addField(Account.Customer_Number__c);
        addField(Account.Customer_Number_Truncated__c);
        addField(Account.Finance_Charge__c);
        addField(Account.Suppress_Late_Charge__c);
    }

    public String getQueryStringForMonthlyLateFeesAccounts(Set<Id> accounts) {
        List<String> queryParams = new List<String>{'\''};

        String query = getSelectStatement();

        if (accounts != null && !accounts.isEmpty()) {
            query += String.format(
                    ' WHERE Id IN ({0})',
                    new List<String>{lp_Utility.convertSetIdsToString(accounts)}
            );
        }

        return query;
    }

    public static Map<Id, Map<Id, Decimal>> getAccountOutstandingAggregate(Set<Id> accounts) {
        List<AggregateResult> accountsWithOutstandingTotals = [
                SELECT
                    fferpcore__Account__c accountId,
                    fferpcore__Company__c companyId,
                    SUM(c2g__OutstandingValue__c) outstandingTotal
                FROM fferpcore__BillingDocument__c
                WHERE
                    fferpcore__Account__r.Id IN :accounts
                    AND c2g__PostingStatus__c = :lp_BillingDocumentSelector.INVOICE_STATUS_POSTED
                    AND Finance_Charge_Calculation__c = true
                    AND Document_Is_Late__c = true
                GROUP BY fferpcore__Account__c, fferpcore__Company__c
        ];

        Map<Id, Map<Id, Decimal>> accountsTotalMap = new Map<Id, Map<Id, Decimal>>();

        Id accountId;
        Id companyId;
        Decimal total;

        for (AggregateResult ar : accountsWithOutstandingTotals) {
            Map<Id, Decimal> companiesTotalMap = new Map<Id, Decimal>();

            accountId = (Id) ar.get('accountId');
            companyId = (Id) ar.get('companyId');
            total = (Decimal) ar.get('outstandingTotal');

            if (!accountsTotalMap.containsKey(accountId)) {
                if (total == null) {
                    companiesTotalMap.put(companyId, 0);
                    accountsTotalMap.put(accountId, companiesTotalMap);
                } else {
                    companiesTotalMap.put(companyId, total);
                    accountsTotalMap.put(accountId, companiesTotalMap);
                }
            }
        }

        return accountsTotalMap;
    }

    public List<Account> getByIds(Set<Id> ids) {
        String query = getSelectStatement();
        query += ' WHERE Id IN :ids';

        return Database.query(query);
    }

    public Map<Id, Account> getMapById(Set<Id> ids) {
        return new Map<Id, Account>((getByIds(ids)));
    }

    public List<Account> getByCustomerNumber(Set<String> customerNumbers) {
        String query = getSelectStatement();
        query += ' WHERE Customer_Number_Truncated__c IN :customerNumbers';

        return Database.query(query);
    }

    public Map<String, Account> getByCustomerNumberMap(Set<String> customerNumbers) {
        List<Account> accounts = getByCustomerNumber(customerNumbers);
        Map<String, Account> accountsByCustomerNumber = new Map<String, Account>();

        for (Account account1 : accounts) {
            accountsByCustomerNumber.put(account1.Customer_Number_Truncated__c?.toLowerCase(), account1);
        }

        return accountsByCustomerNumber;
    }
    
	public Map<String, Id> getMapByNames(Set<String> names) {
		Map<String, Id> mapByName = new Map<String, Id>();

		String query = getSelectStatement();
		query += ' WHERE Name IN :names';

		List<Account> accounts = Database.query(query);

		for(Account account : accounts) {
			if(!mapByName.containsKey(account.Name)) {
				mapByName.put(account.Name, account.Id);
			}
		}

		return mapByName;
	}
}