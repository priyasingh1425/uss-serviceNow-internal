/*
 * Copyright 2017-present Sirono LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@IsTest
private class lp_CollectionUtilTest {

    private static final List<Integer> NULL_LIST = null;
    private static final Integer[] NULL_ARRAY = null;
    private static final List<Integer> EMPTY_LIST = new List<Integer>();
    private static final Integer[] EMPTY_ARRAY = new Integer[0];
    private static final List<Integer> TEST_LIST = new List<Integer> { 10, 20, 30 };
    private static final Integer[] TEST_ARRAY = new Integer[] { 10, 20, 30 };

    // TODO: These are disabled for now because of issues with proper polymorphic behavior with type parameters of
    // TODO: Set and Map. Once those issues are resolved by Salesforce these can be restored.

//    private static final Set<Integer> NULL_SET = null;
//    private static final Set<Integer> EMPTY_SET = new Set<Integer>();
//    private static final Set<Integer> TEST_SET = new Set<Integer> { 10, 20, 30 };
//
//    private static final Map<Integer, Integer> NULL_MAP = null;
//    private static final Map<Integer, Integer> EMPTY_MAP = new Map<Integer, Integer>();
//    private static final Map<Integer, Integer> TEST_MAP = new Map<Integer, Integer> { 10 => 100, 20 => 200, 30 => 300 };

    @IsTest
    static void testIsEmpty_List() {
        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(NULL_LIST), 'Expected true for null list.');
        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(NULL_ARRAY), 'Expected true for null array.');
        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(EMPTY_LIST), 'Expected true for empty list.');
        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(EMPTY_ARRAY), 'Expected true for empty array.');
        lp_Assert.isFalse(lp_CollectionUtil.isEmpty(TEST_LIST), 'Expected false for list with values.');
        lp_Assert.isFalse(lp_CollectionUtil.isEmpty(TEST_ARRAY), 'Expected false for array with values.');
    }

    @IsTest
    static void testIsNotEmpty_List() {
        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(NULL_LIST), 'Expected false for null list.');
        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(NULL_ARRAY), 'Expected false for null array.');
        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(EMPTY_LIST), 'Expected false for empty list.');
        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(EMPTY_ARRAY), 'Expected false for empty array.');
        lp_Assert.isTrue(lp_CollectionUtil.isNotEmpty(TEST_LIST), 'Expected true for list with values.');
        lp_Assert.isTrue(lp_CollectionUtil.isNotEmpty(TEST_ARRAY), 'Expected true for array with values.');
    }

//    @IsTest
//    static void testIsEmpty_Set() {
//        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(NULL_SET), 'Expected true for null set.');
//        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(EMPTY_SET), 'Expected true for empty set.');
//        lp_Assert.isFalse(lp_CollectionUtil.isEmpty(TEST_SET), 'Expected false for set with values.');
//    }
//
//    @IsTest
//    static void testIsNotEmpty_Set() {
//        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(NULL_SET), 'Expected false for null set.');
//        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(EMPTY_SET), 'Expected false for empty set.');
//        lp_Assert.isTrue(lp_CollectionUtil.isNotEmpty(TEST_SET), 'Expected true for set with values.');
//    }
//
//    @IsTest
//    static void testIsEmpty_Map() {
//        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(NULL_MAP), 'Expected true for null map.');
//        lp_Assert.isTrue(lp_CollectionUtil.isEmpty(EMPTY_MAP), 'Expected true for empty map.');
//        lp_Assert.isFalse(lp_CollectionUtil.isEmpty(TEST_MAP), 'Expected false for map with values.');
//    }
//
//    @IsTest
//    static void testIsNotEmpty_Map() {
//        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(NULL_MAP), 'Expected false for null map.');
//        lp_Assert.isFalse(lp_CollectionUtil.isNotEmpty(EMPTY_MAP), 'Expected false for empty map.');
//        lp_Assert.isTrue(lp_CollectionUtil.isNotEmpty(TEST_MAP), 'Expected true for map with values.');
//    }

    @IsTest
    static void testAddIfNotNull_List() {
        try {
            lp_CollectionUtil.addIfNotNull((List<Object>) null, null);
            lp_Assert.fail('Expected an lp_IllegalArgumentException for a null list.');
        } catch (lp_IllegalArgumentException e) {
            // Expected
        }

        List<Integer> ints = new List<Integer> { 1, 2, 3 };
        lp_CollectionUtil.addIfNotNull(ints, null);
        lp_Assert.equals(3, ints.size(), 'Expected the list size to be unchanged.');
        lp_Assert.isFalse(ints.contains(null), 'Expected the list not to contain a null value.');

        lp_CollectionUtil.addIfNotNull(ints, 4);
        lp_Assert.equals(4, ints.size(), 'Expected the list size to increase by one.');
        lp_Assert.isTrue(ints.contains(4), 'Expected the list to contain the new value.');
    }

//    @IsTest
//    static void testAddIfNotNull_Set() {
//        try {
//            lp_CollectionUtil.addIfNotNull((List<Object>) null, null);
//            AssertUtil.fail('Expected an lp_IllegalArgumentException for a null set.');
//        } catch (lp_IllegalArgumentException e) {
//            // Expected
//        }
//
//        Set<Integer> ints = new Set<Integer> { 1, 2, 3 };
//        lp_CollectionUtil.addIfNotNull(ints, null);
//        lp_Assert.equals(3, ints.size(), 'Expected the set size to be unchanged.');
//        AssertUtil.assertFalse(ints.contains(null), 'Expected the set not to contain a null value.');
//
//        lp_CollectionUtil.addIfNotNull(ints, 4);
//        lp_Assert.equals(4, ints.size(), 'Expected the set size to increase by one.');
//        lp_Assert.isTrue(ints.contains(4), 'Expected the set to contain the new value.');
//    }

    @IsTest
    static void testAddAllNotNull_List() {
        try {
            lp_CollectionUtil.addAllNotNull((List<Object>) null, null);
            lp_Assert.fail('Expected an lp_IllegalArgumentException for a null list.');
        } catch (lp_IllegalArgumentException e) {
            // Expected
        }

        List<Integer> ints = new List<Integer> { 1, 2, 3 };
        lp_CollectionUtil.addAllNotNull(ints, null);
        lp_Assert.equals(3, ints.size(), 'Expected the list size to be unchanged.');
        lp_Assert.isFalse(ints.contains(null), 'Expected the list not to contain a null value.');

        lp_CollectionUtil.addAllNotNull(ints, null);
        lp_Assert.equals(3, ints.size(), 'Expected the list size to be unchanged.');
        lp_Assert.isFalse(ints.contains(null), 'Expected the list not to contain a null value.');

        List<Integer> moreIntsAndSomeNulls = new List<Integer> { 4, null, 5, null, 6 };
        lp_CollectionUtil.addAllNotNull(ints, moreIntsAndSomeNulls);
        lp_Assert.equals(6, ints.size(), 'Expected the list size to increase by three.');
        lp_Assert.isTrue(ints.contains(4) && ints.contains(5) && ints.contains(6),
                'Expected the list to contain the non-null values.');
        lp_Assert.isFalse(ints.contains(null), 'Expected the list not to contain a null value.');

        List<Integer> allNulls = new List<Integer> { null, null, null, null };
        lp_CollectionUtil.addAllNotNull(ints, allNulls);
        lp_Assert.equals(6, ints.size(), 'Expected the list size to be unchanged.');
        lp_Assert.isFalse(ints.contains(null), 'Expected the list not to contain a null value.');
    }

    @IsTest
    static void testGetFirstItem() {
        lp_Assert.isNull(lp_CollectionUtil.getFirstItem(null), 'Expected a null first item for a null list.');
        lp_Assert.isNull(lp_CollectionUtil.getFirstItem(new List<String>()), 'Expected a null first item for an empty list.');
        lp_Assert.isNull(lp_CollectionUtil.getFirstItem(new String[0]), 'Expected a null first item for an empty array.');
        lp_Assert.equals('Foo', lp_CollectionUtil.getFirstItem(new List<String> { 'Foo' }));
        lp_Assert.equals('Foo', lp_CollectionUtil.getFirstItem(new String[] { 'Foo' }));
        lp_Assert.equals('Foo', lp_CollectionUtil.getFirstItem(new List<String> { 'Foo', 'Bar' }));
        lp_Assert.equals('Foo', lp_CollectionUtil.getFirstItem(new String[] { 'Foo', 'Bar' }));
    }

    @IsTest
    static void testGetLastItem() {
        lp_Assert.isNull(lp_CollectionUtil.getLastItem(null), 'Expected a null last item for a null list.');
        lp_Assert.isNull(lp_CollectionUtil.getLastItem(new List<String>()), 'Expected a null last item for an empty list.');
        lp_Assert.isNull(lp_CollectionUtil.getLastItem(new String[0]), 'Expected a null last item for an empty array.');
        lp_Assert.equals('Foo', lp_CollectionUtil.getLastItem(new List<String> { 'Foo' }));
        lp_Assert.equals('Foo', lp_CollectionUtil.getLastItem(new String[] { 'Foo' }));
        lp_Assert.equals('Bar', lp_CollectionUtil.getLastItem(new List<String> { 'Foo', 'Bar' }));
        lp_Assert.equals('Bar', lp_CollectionUtil.getLastItem(new String[] { 'Foo', 'Bar' }));
    }

    @IsTest
    static void testToIdsBaseCases() {
        // Null for list signature should return an empty set
        Set<Id> ids = lp_CollectionUtil.toIds((List<Object>) null);
        lp_Assert.isNotNull(ids);
        lp_Assert.isTrue(ids.isEmpty());

        // Null for set signature should return an empty set
        ids = lp_CollectionUtil.toIds((Set<Object>) null);
        lp_Assert.isNotNull(ids);
        lp_Assert.isTrue(ids.isEmpty());

        // Null for list signature should return an empty set
        ids = lp_CollectionUtil.toIds(new List<Object>());
        lp_Assert.isNotNull(ids);
        lp_Assert.isTrue(ids.isEmpty());

        // Null for set signature should return an empty set
        ids = lp_CollectionUtil.toIds(new Set<Object>());
        lp_Assert.isNotNull(ids);
        lp_Assert.isTrue(ids.isEmpty());
    }

    @IsTest
    static void testToIdsInvalid() {
        // Null entry should result in lp_IllegalArgumentException
        try {
            lp_CollectionUtil.toIds(new List<Object> { null });
            lp_Assert.fail('Expected lp_IllegalArgumentException.');
        } catch (lp_IllegalArgumentException e) {
        }

        // Null entry should result in lp_IllegalArgumentException
        try {
            lp_CollectionUtil.toIds(new Set<Object> { null });
            lp_Assert.fail('Expected lp_IllegalArgumentException.');
        } catch (lp_IllegalArgumentException e) {
        }

        // Wrong type entry should result in lp_IllegalArgumentException
        try {
            lp_CollectionUtil.toIds(new List<Object> { 10 });
            lp_Assert.fail('Expected lp_IllegalArgumentException.');
        } catch (lp_IllegalArgumentException e) {
        }

        // Wrong type entry should result in lp_IllegalArgumentException
        try {
            lp_CollectionUtil.toIds(new Set<Object> { 10 });
            lp_Assert.fail('Expected lp_IllegalArgumentException.');
        } catch (lp_IllegalArgumentException e) {
        }
    }

    @IsTest
    static void testToIds() {
        // Create a few dummy objects to give us IDs to work with
        List<User> users = new List<User>();
        for (Integer i = 0; i < 5; i++) {
            String username = UserInfo.getOrganizationId() + i + '@test.com';
            User user = new User(
                    Username = username,
                    Email = username,
                    LastName = 'McTest',
                    Alias = 'test' + i,
                    ProfileId = UserInfo.getProfileId(),
                    TimeZoneSidKey = UserInfo.getTimeZone().toString(),
                    LocaleSidKey = UserInfo.getLocale(),
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = UserInfo.getLocale()
            );
            users.add(user);
        }
        insert users;

        // List signature
        List<Object> rawIdList = new List<Object>();
        for (User usr : users) {
            rawIdList.add(usr.Id);
        }

        Set<Id> ids = lp_CollectionUtil.toIds(rawIdList);
        lp_Assert.equals(ids.size(), rawIdList.size());
        for (Object rawId : rawIdList) {
            lp_Assert.isTrue(ids.contains((Id) rawId));
        }

        // Set signature
        Set<Object> rawIdSet = new Set<Object>();
        for (User usr : users) {
            rawIdSet.add(usr.Id);
        }

        ids = lp_CollectionUtil.toIds(rawIdSet);
        lp_Assert.equals(ids.size(), rawIdSet.size());
        for (Object rawId : rawIdSet) {
            lp_Assert.isTrue(ids.contains((Id) rawId));
        }
    }

    @IsTest
    static void testToStrings_Set() {
        Set<Object> rawValues = new Set<Object> {
                'Foobar',
                10,
                20.0,
                true,
                LoggingLevel.DEBUG
        };

        Set<String> stringValues = lp_CollectionUtil.toStrings(rawValues);
        lp_Assert.equals(rawValues.size(), stringValues.size());
        for (Object rawValue : rawValues) {
            lp_Assert.isTrue(stringValues.contains(String.valueOf(rawValue)));
        }
    }

    @IsTest
    static void testToStringsWithNulls_Set() {
        Set<Object> rawValues = new Set<Object> {
                'Foobar',
                null
        };

        try {
            lp_CollectionUtil.toStrings(rawValues);
            lp_Assert.fail('Expected an lp_IllegalArgumentException');
        } catch (lp_IllegalArgumentException e) {
        }
    }

    @IsTest
    static void testToStrings_List() {
        List<Object> rawValues = new List<Object> {
                'Foobar',
                10,
                20.0,
                true,
                LoggingLevel.DEBUG
        };

        List<String> stringValues = lp_CollectionUtil.toStrings(rawValues);
        lp_Assert.equals(rawValues.size(), stringValues.size());
        for (Integer i = 0; i < stringValues.size(); i++) {
            Object rawValue = rawValues.get(i);
            String stringValue = stringValues.get(i);
            lp_Assert.equals(String.valueOf(rawValue), stringValue);
        }
    }

    @IsTest
    static void testToStringsWithNulls_List() {
        List<Object> rawValues = new List<Object> {
                'Foobar',
                null
        };

        try {
            lp_CollectionUtil.toStrings(rawValues);
            lp_Assert.fail('Expected an lp_IllegalArgumentException');
        } catch (lp_IllegalArgumentException e) {
        }
    }

    @IsTest
    static void testGetIds() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                    Name = 'Account ' + (i + 1)
            ));
        }
        insert accounts;

        List<Id> accountIds = lp_CollectionUtil.getIds(accounts);
        lp_Assert.equals(accounts.size(), accountIds.size());
        for (Integer i = 0; i < accounts.size(); i++) {
            Account account = accounts.get(i);
            Id accountId = accountIds.get(i);
            lp_Assert.equals(account.Id, accountId);
        }
    }

    @IsTest
    static void testGetIdSet() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(
                    Name = 'Account ' + (i + 1)
            ));
        }
        insert accounts;

        // Create a list with duplicate entries
        List<Account> duplicateAccounts = new List<Account>();
        duplicateAccounts.addAll(accounts);
        duplicateAccounts.addAll(accounts);

        Set<Id> accountIds = lp_CollectionUtil.getIdSet(duplicateAccounts);
        lp_Assert.equals(accounts.size(), accountIds.size());
        for (Account account : accounts) {
            Id accountId = account.Id;
            lp_Assert.isTrue(accountIds.contains(accountId));
            accountIds.remove(accountId);
        }
        lp_Assert.isTrue(accountIds.isEmpty());
    }

    @IsTest
    static void testHasField() {
        lp_Assert.isFalse(lp_CollectionUtil.hasField(new Account(), Contact.FirstName), 'Unexpected field');
        lp_Assert.isFalse(lp_CollectionUtil.hasField(null, Contact.FirstName), 'Unexpected field');
        lp_Assert.isFalse(lp_CollectionUtil.hasField(new Account(), null), 'Unexpected field');
        lp_Assert.isFalse(lp_CollectionUtil.hasField(new Account(), Contact.Id), 'Unexpected field');
        lp_Assert.isTrue(lp_CollectionUtil.hasField(new Account(), Account.AccountNumber));
    }

    @IsTest
    static void testMapByIdField() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accounts.add(new Account(
                    Name = 'Account ' + (i + 1)
            ));
        }
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 2; i++) {
            contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'User ' + (i + 1),
                    AccountId = accounts.get(i).Id
            ));
        }
        insert contacts;

        Map<Id, SObject> contactsByAccountId = lp_CollectionUtil.mapByIdField(contacts, Contact.AccountId);
        lp_Assert.equals(contacts.size(), contactsByAccountId.size());
        for (Id accountId : contactsByAccountId.keySet()) {
            Contact contact = (Contact) contactsByAccountId.get(accountId);
            lp_Assert.equals(accountId, contact.AccountId);
        }
    }

    @IsTest
    static void testMapByIdFieldWithDupes() {
        Account account = new Account(
                Name = 'Account'
        );
        insert account;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 2; i++) {
            contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'User ' + (i + 1),
                    AccountId = account.Id
            ));
        }
        insert contacts;

        try {
            lp_CollectionUtil.mapByIdField(contacts, Contact.AccountId);
            lp_Assert.fail('Expected lp_IllegalStateException');
        } catch (lp_IllegalStateException e) {
        }
    }

    @IsTest
    static void testMapByField() {
        Account acct = new Account(
                Name = 'Account 1',
                AccountNumber = '12345'
        );
        insert acct;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 2; i++) {
            contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'User ' + (i + 1),
                    AccountId = acct.Id
            ));
        }
        insert contacts;

        Map<Object, SObject> contactsByAccountId = lp_CollectionUtil.mapByField(contacts, Contact.LastName);
        lp_Assert.equals(contacts.size(), contactsByAccountId.size());
        for (Object lastName : contactsByAccountId.keySet()) {
            Contact contact = (Contact) contactsByAccountId.get(lastName);
            lp_Assert.equals(lastName, contact.LastName);
        }
    }

    @IsTest
    static void testMapByFieldWithDupes() {
        Account acct = new Account(
                Name = 'Account 1',
                AccountNumber = '12345'
        );
        insert acct;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 2; i++) {
            contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'User ' + (i + 1),
                    AccountId = acct.Id
            ));
        }
        insert contacts;

        try {
            lp_CollectionUtil.mapByField(contacts, Contact.FirstName);
            lp_Assert.fail('Expected lp_IllegalStateException');
        } catch (lp_IllegalStateException e) {
        }
    }

    @IsTest
    static void testMapByFieldWithNullFieldValues() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accounts.add(new Account(
                    Name = 'Account ' + (i + 1),
                    AccountNumber = (i == 0) ? null : '12345'
            ));
        }
        insert accounts;

        Map<Object, SObject> accountsByAccountNumber = lp_CollectionUtil.mapByField(accounts, Account.AccountNumber);
        lp_Assert.equals(accounts.size() - 1, accountsByAccountNumber.size());
        for (Object accountNumber : accountsByAccountNumber.keySet()) {
            Account account = (Account) accountsByAccountNumber.get(accountNumber);
            lp_Assert.isNotNull(account.AccountNumber);
            lp_Assert.equals(accountNumber, account.AccountNumber);
        }
    }

    @IsTest
    static void testMultiMapByField() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accounts.add(new Account(
                    Name = 'Account ' + (i + 1)
            ));
        }
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            Account account = accounts.get(Math.mod(i, 2));
            contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'User ' + (i + 1),
                    AccountId = account.Id
            ));
        }
        insert contacts;

        lp_MultiMap contactsByAccountId = lp_CollectionUtil.multiMapByField(contacts, Contact.AccountId);
        lp_Assert.equals(accounts.size(), contactsByAccountId.keySet().size());
        lp_Assert.equals(contacts.size(), contactsByAccountId.values().size());
        for (Object key : contactsByAccountId.keySet()) {
            Id accountId = (Id) key;
            List<Object> values = contactsByAccountId.getValues(accountId);
            lp_Assert.equals(contacts.size() / 2, values.size());
            for (Object value : values) {
                Contact contact = (Contact) value;
                lp_Assert.equals(accountId, contact.AccountId);
            }
        }
    }
}