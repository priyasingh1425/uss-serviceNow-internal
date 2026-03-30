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
private class lp_MultiMapTest {

    @IsTest
    static void testContainsKeyList() {
        testContainsKey(true);
    }

    @IsTest
    static void testContainsKeySet() {
        testContainsKey(false);
    }

    static void testContainsKey(Boolean allowDuplicates) {
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);

        // Nothing added yet
        lp_Assert.isFalse(testMultiMap.containsKey('key'));

        // Add a value for the key
        testMultiMap.putValue('key', 'value1');
        lp_Assert.isTrue(testMultiMap.containsKey('key'));

        // Add a second value for the key
        testMultiMap.putValue('key', 'value2');
        lp_Assert.isTrue(testMultiMap.containsKey('key'));

        // Remove the second value for the key
        testMultiMap.removeValue('key', 'value2');
        lp_Assert.isTrue(testMultiMap.containsKey('key'));

        // Remove the first value for the key
        testMultiMap.removeValue('key', 'value1');
        lp_Assert.isFalse(testMultiMap.containsKey('key'));

        // Add multiple values for the key
        testMultiMap.putValues('key', new String[] { 'value1', ' value2' });
        lp_Assert.isTrue(testMultiMap.containsKey('key'));

        // Remove all values for the key
        testMultiMap.remove('key');
        lp_Assert.isFalse(testMultiMap.containsKey('key'));

        // Add multiple values for the key
        testMultiMap.putValues('key', new String[] { 'value1', ' value2' });
        lp_Assert.isTrue(testMultiMap.containsKey('key'));

        // Clear the map
        testMultiMap.clear();
        lp_Assert.isFalse(testMultiMap.containsKey('key'));
    }

    @IsTest
    static void testPutValueList() {
        testPutValue(true);
    }

    @IsTest
    static void testPutValueSet() {
        testPutValue(false);
    }

    static void testPutValue(Boolean allowDuplicates) {
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);

        // Add a value
        lp_Assert.equals(0, testMultiMap.size());
        lp_Assert.equals(0, testMultiMap.values().size());
        lp_Assert.equals(0, testMultiMap.getValues('key').size());
        testMultiMap.putValue('key', 'value1');
        lp_Assert.equals(1, testMultiMap.size());
        lp_Assert.equals(1, testMultiMap.values().size());
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1' }, testMultiMap.getValues('key'), allowDuplicates);

        // Add a different value
        testMultiMap.putValue('key', 'value2');
        lp_Assert.equals(1, testMultiMap.size());
        lp_Assert.equals(2, testMultiMap.values().size());
        lp_Assert.equals(2, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1', 'value2' }, testMultiMap.getValues('key'), allowDuplicates);

        // Add a value for another key
        testMultiMap.putValue('key2', 'value2_1');
        lp_Assert.equals(2, testMultiMap.size());
        lp_Assert.equals(3, testMultiMap.values().size());
        lp_Assert.equals(1, testMultiMap.getValues('key2').size());
        verifyContents(new String[] { 'value2_1' }, testMultiMap.getValues('key2'), allowDuplicates);
    }

    @IsTest
    static void testPutValuesList() {
        testPutValues(true);
    }

    @IsTest
    static void testPutValuesSet() {
        testPutValues(false);
    }

    static void testPutValues(Boolean allowDuplicates) {
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);

        // List signature

        // Add a single value
        lp_Assert.equals(0, testMultiMap.size());
        lp_Assert.equals(0, testMultiMap.values().size());
        lp_Assert.equals(0, testMultiMap.getValues('key').size());
        testMultiMap.putValues('key', new String[] { 'value1' });
        lp_Assert.equals(1, testMultiMap.size());
        lp_Assert.equals(1, testMultiMap.values().size());
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1' }, testMultiMap.getValues('key'), allowDuplicates);

        // Add multiple values
        testMultiMap.putValues('key', new String[] { 'value2', 'value3' });
        lp_Assert.equals(1, testMultiMap.size());
        lp_Assert.equals(3, testMultiMap.values().size());
        lp_Assert.equals(3, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1', 'value2', 'value3' }, testMultiMap.getValues('key'), allowDuplicates);

        // Add multiple values for another key
        testMultiMap.putValues('key2', new String[] { 'value2_1', 'value2_2' });
        lp_Assert.equals(2, testMultiMap.size());
        lp_Assert.equals(5, testMultiMap.values().size());
        lp_Assert.equals(2, testMultiMap.getValues('key2').size());
        verifyContents(new String[] { 'value2_1', 'value2_2' }, testMultiMap.getValues('key2'), allowDuplicates);

        // Set signature

        testMultiMap = createMultiMap(allowDuplicates);

        // Add a single value
        lp_Assert.equals(0, testMultiMap.size());
        lp_Assert.equals(0, testMultiMap.values().size());
        lp_Assert.equals(0, testMultiMap.getValues('key').size());
        testMultiMap.putValues('key', new Set<Object> { 'value1', 'value1' });
        lp_Assert.equals(1, testMultiMap.size());
        lp_Assert.equals(1, testMultiMap.values().size());
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1' }, testMultiMap.getValues('key'), allowDuplicates);

        // Add multiple values
        testMultiMap.putValues('key', new Set<Object> { 'value2', 'value3', 'value2', 'value3' });
        lp_Assert.equals(1, testMultiMap.size());
        lp_Assert.equals(3, testMultiMap.values().size());
        lp_Assert.equals(3, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1', 'value2', 'value3' }, testMultiMap.getValues('key'), allowDuplicates);

        // Add multiple values for another key
        testMultiMap.putValues('key2', new Set<Object> { 'value2_1', 'value2_2', 'value2_1', 'value2_2' });
        lp_Assert.equals(2, testMultiMap.size());
        lp_Assert.equals(5, testMultiMap.values().size());
        lp_Assert.equals(2, testMultiMap.getValues('key2').size());
        verifyContents(new String[] { 'value2_1', 'value2_2' }, testMultiMap.getValues('key2'), allowDuplicates);
    }

    @IsTest
    static void testPutAllValuesList() {
        testPutAllValues(true);
    }

    @IsTest
    static void testPutAllValuesSet() {
        testPutAllValues(false);
    }

    static void testPutAllValues(Boolean allowDuplicates) {
        // Create a source multi-map
        lp_MultiMap sourceMultiMap1 = createMultiMap(allowDuplicates);
        sourceMultiMap1.putValues('key1', new String[] { 'value1_1', 'value1_2' });
        sourceMultiMap1.putValues('key2', new String[] { 'value2_1', 'value2_2' });

        // Use that to populate a new multi-map
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        testMultiMap.putAllValues(sourceMultiMap1);
        lp_Assert.equals(sourceMultiMap1.size(), testMultiMap.size());
        lp_Assert.equals(sourceMultiMap1.keySet(), testMultiMap.keySet());
        lp_Assert.equals(sourceMultiMap1.values(), testMultiMap.values());

        // Create a second source multi-map
        lp_MultiMap sourceMultiMap2 = createMultiMap(allowDuplicates);
        sourceMultiMap2.putValues('key1', new String[] { 'value1_3', 'value1_4' });
        sourceMultiMap2.putValues('key2', new String[] { 'value2_3', 'value2_4' });
        sourceMultiMap2.putValues('key3', new String[] { 'value3_1', 'value3_2' });

        // Add those as well
        testMultiMap.putAllValues(sourceMultiMap2);
        // NOTE: We only added one new key
        lp_Assert.equals(sourceMultiMap1.size() + 1, testMultiMap.size());
        lp_Assert.equals(sourceMultiMap1.keySet().size() + 1, testMultiMap.keySet().size());
        // Make sure that all keys were copied over
        lp_Assert.isTrue(testMultiMap.keySet().containsAll(sourceMultiMap1.keySet()));
        lp_Assert.isTrue(testMultiMap.keySet().containsAll(sourceMultiMap2.keySet()));
        // And all values
        lp_Assert.equals(sourceMultiMap1.values().size() + sourceMultiMap2.values().size(), testMultiMap.values().size());
        // TODO: Apex doesn't really have a good way to do a containsAll() on lists
    }

    @IsTest
    static void testGetValuesList() {
        testGetValues(true);
    }

    @IsTest
    static void testGetValuesSet() {
        testGetValues(false);
    }

    static void testGetValues(Boolean allowDuplicates) {
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);

        // Shouldn't ever return null even when nothing has ever been added for a key
        lp_Assert.isNotNull(testMultiMap.getValues('key'));
        testMultiMap.remove('key');
        lp_Assert.isNotNull(testMultiMap.getValues('key'));
        testMultiMap.clear();
        lp_Assert.isNotNull(testMultiMap.getValues('key'));

        // Add a single value and make sure we get that value back
        testMultiMap.putValue('key1', 'value1');
        lp_Assert.equals(1, testMultiMap.getValues('key1').size());
        verifyContents(new String[] { 'value1' }, testMultiMap.getValues('key1'), allowDuplicates);

        // Add multiple values for a different key
        testMultiMap.putValues('key2', new String[] { 'value2_1', 'value2_2' });
        lp_Assert.equals(1, testMultiMap.getValues('key1').size());
        verifyContents(new String[] { 'value1' }, testMultiMap.getValues('key1'), allowDuplicates);
        lp_Assert.equals(2, testMultiMap.getValues('key2').size());
        verifyContents(new String[] { 'value2_1', 'value2_2' }, testMultiMap.getValues('key2'), allowDuplicates);

        // Remove the values for the first key and make sure we still get back an empty list
        testMultiMap.removeValue('key1', 'value1');
        lp_Assert.isNotNull(testMultiMap.getValues('key1'));
        lp_Assert.isTrue(testMultiMap.getValues('key1').isEmpty());

        // Same with the second
        testMultiMap.remove('key2');
        lp_Assert.isNotNull(testMultiMap.getValues('key2'));
        lp_Assert.isTrue(testMultiMap.getValues('key2').isEmpty());

        // And now clear the multi-map and make sure we still get back empty lists
        testMultiMap.clear();
        lp_Assert.isNotNull(testMultiMap.getValues('key1'));
        lp_Assert.isTrue(testMultiMap.getValues('key1').isEmpty());
        lp_Assert.isNotNull(testMultiMap.getValues('key2'));
        lp_Assert.isTrue(testMultiMap.getValues('key2').isEmpty());
    }

    @IsTest
    static void testGetValueSetList() {
        testGetValueSet(true);
    }

    @IsTest
    static void testGetValueSetSet() {
        testGetValueSet(false);
    }

    static void testGetValueSet(Boolean allowDuplicates) {
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);

        // Shouldn't ever return null even when nothing has ever been added for a key
        lp_Assert.isNotNull(testMultiMap.getValueSet('key'));
        testMultiMap.remove('key');
        lp_Assert.isNotNull(testMultiMap.getValueSet('key'));
        testMultiMap.clear();
        lp_Assert.isNotNull(testMultiMap.getValueSet('key'));

        // Add a single value and make sure we get that value back
        testMultiMap.putValue('key1', 'value1');
        lp_Assert.equals(1, testMultiMap.getValueSet('key1').size());
        lp_Assert.equals(new Set<Object> { 'value1' }, testMultiMap.getValueSet('key1'));

        // Add the same value and make sure we only get it back once
        testMultiMap.putValue('key1', 'value1');
        // First make sure the actual storage is correct
        lp_Assert.equals(allowDuplicates ? 2 : 1, testMultiMap.getValues('key1').size());
        verifyContents(allowDuplicates ? new String[] { 'value1', 'value1' } : new String[] { 'value1' }, testMultiMap.getValues('key1'), allowDuplicates);
        // And then verify the result of getValueSet()
        lp_Assert.equals(1, testMultiMap.getValueSet('key1').size());
        lp_Assert.equals(new Set<Object> { 'value1' }, testMultiMap.getValueSet('key1'));
    }

    @IsTest
    static void testRemoveList() {
        testRemove(true);
    }

    @IsTest
    static void testRemoveSet() {
        testRemove(false);
    }

    static void testRemove(Boolean allowDuplicates) {
        // Add values for multiple keys to a multi-map
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.equals(2, testMultiMap.getValues('key1').size());
        lp_Assert.equals(3, testMultiMap.getValues('key2').size());

        // Remove the first key and make sure the second still looks right
        lp_Assert.isTrue(testMultiMap.remove('key1'));
        lp_Assert.equals(0, testMultiMap.getValues('key1').size());
        lp_Assert.equals(3, testMultiMap.getValues('key2').size());

        // Try to remove the key again and it should return false
        lp_Assert.isFalse(testMultiMap.remove('key1'));
        lp_Assert.equals(0, testMultiMap.getValues('key1').size());
        lp_Assert.equals(3, testMultiMap.getValues('key2').size());

        // Remove the second key
        lp_Assert.isTrue(testMultiMap.remove('key2'));
        lp_Assert.equals(0, testMultiMap.getValues('key1').size());
        lp_Assert.equals(0, testMultiMap.getValues('key2').size());

        // Try to remove the second key again and it should return false
        lp_Assert.isFalse(testMultiMap.remove('key2'));
        lp_Assert.equals(0, testMultiMap.getValues('key1').size());
        lp_Assert.equals(0, testMultiMap.getValues('key2').size());
    }

    @IsTest
    static void testRemoveValueList() {
        testRemoveValue(true);
    }

    @IsTest
    static void testRemoveValueSet() {
        testRemoveValue(false);
    }

    static void testRemoveValue(Boolean allowDuplicates) {
        // Add values for multiple keys to a multi-map
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.equals(2, testMultiMap.getValues('key1').size());
        lp_Assert.equals(3, testMultiMap.getValues('key2').size());

        // Remove a value for the first key
        lp_Assert.equals('value1_1', testMultiMap.removeValue('key1', 'value1_1'));
        lp_Assert.equals(1, testMultiMap.getValues('key1').size());
        lp_Assert.equals(3, testMultiMap.getValues('key2').size());

        // Now try to remove the same value again and it should return null
        lp_Assert.isNull(testMultiMap.removeValue('key1', 'value1_1'));
        lp_Assert.equals(1, testMultiMap.getValues('key1').size());
        lp_Assert.equals(3, testMultiMap.getValues('key2').size());

        // Remove a value for the second key
        lp_Assert.equals('value2_3', testMultiMap.removeValue('key2', 'value2_3'));
        lp_Assert.equals(1, testMultiMap.getValues('key1').size());
        lp_Assert.equals(2, testMultiMap.getValues('key2').size());

        // Now try to remove the same value again and it should return null
        lp_Assert.isNull(testMultiMap.removeValue('key2', 'value2_3'));
        lp_Assert.equals(1, testMultiMap.getValues('key1').size());
        lp_Assert.equals(2, testMultiMap.getValues('key2').size());
    }

    @IsTest
    static void testClearList() {
        testClear(true);
    }

    @IsTest
    static void testClearSet() {
        testClear(false);
    }

    static void testClear(Boolean allowDuplicates) {
        // Fill up a multi-map
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.isFalse(testMultiMap.isEmpty());
        lp_Assert.equals(2, testMultiMap.keySet().size());
        lp_Assert.equals(5, testMultiMap.values().size());

        // And now clear it
        testMultiMap.clear();
        lp_Assert.isTrue(testMultiMap.isEmpty());
        lp_Assert.equals(0, testMultiMap.keySet().size());
        lp_Assert.equals(0, testMultiMap.values().size());
    }

    @IsTest
    static void testKeySetList() {
        testKeySet(true);
    }

    @IsTest
    static void testKeySetSet() {
        testKeySet(false);
    }

    static void testKeySet(Boolean allowDuplicates) {
        // Start empty
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        lp_Assert.isTrue(testMultiMap.keySet().isEmpty());

        // Add data
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.equals(2, testMultiMap.keySet().size());
        lp_Assert.isTrue(testMultiMap.keySet().contains('key1'));
        lp_Assert.isTrue(testMultiMap.keySet().contains('key2'));

        // Remove all values for one key
        testMultiMap.remove('key1');
        lp_Assert.equals(1, testMultiMap.keySet().size());
        lp_Assert.isFalse(testMultiMap.keySet().contains('key1'));
        lp_Assert.isTrue(testMultiMap.keySet().contains('key2'));

        // And now clear it
        testMultiMap.clear();
        lp_Assert.isTrue(testMultiMap.keySet().isEmpty());
    }

    @IsTest
    static void testValuesList() {
        testValues(true);
    }

    @IsTest
    static void testValuesSet() {
        testValues(false);
    }

    static void testValues(Boolean allowDuplicates) {
        // Start empty
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        lp_Assert.isTrue(testMultiMap.values().isEmpty());

        // Add data
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.equals(5, testMultiMap.values().size());

        // Remove a value for one key
        testMultiMap.removeValue('key1', 'value1_1');
        lp_Assert.equals(4, testMultiMap.values().size());

        // Remove all values for one key
        testMultiMap.remove('key2');
        lp_Assert.equals(1, testMultiMap.values().size());

        // And now clear it
        testMultiMap.clear();
        lp_Assert.isTrue(testMultiMap.values().isEmpty());
    }

    @IsTest
    static void testIsEmptyList() {
        testIsEmpty(true);
    }

    @IsTest
    static void testIsEmptySet() {
        testIsEmpty(false);
    }

    static void testIsEmpty(Boolean allowDuplicates) {
        // Start empty
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        lp_Assert.isTrue(testMultiMap.values().isEmpty());

        // Add data
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.isFalse(testMultiMap.values().isEmpty());

        // Remove a value for one key
        testMultiMap.removeValue('key1', 'value1_1');
        lp_Assert.isFalse(testMultiMap.values().isEmpty());

        // Remove all values for one key
        testMultiMap.remove('key2');
        lp_Assert.isFalse(testMultiMap.values().isEmpty());

        // And now clear it
        testMultiMap.clear();
        lp_Assert.isTrue(testMultiMap.values().isEmpty());
    }

    @IsTest
    static void testSizeList() {
        testSize(true);
    }

    @IsTest
    static void testSizeSet() {
        testSize(false);
    }

    static void testSize(Boolean allowDuplicates) {
        // Start empty
        lp_MultiMap testMultiMap = createMultiMap(allowDuplicates);
        lp_Assert.equals(0, testMultiMap.size());

        // Add data
        testMultiMap.putValue('key1', 'value1_1');
        testMultiMap.putValue('key1', 'value1_2');
        testMultiMap.putValue('key2', 'value2_1');
        testMultiMap.putValue('key2', 'value2_2');
        testMultiMap.putValue('key2', 'value2_3');
        lp_Assert.equals(2, testMultiMap.size());

        // Add more data
        testMultiMap.putValue('key3', 'value3_1');
        testMultiMap.putValue('key3', 'value3_2');
        testMultiMap.putValue('key3', 'value3_3');
        testMultiMap.putValue('key3', 'value3_4');
        lp_Assert.equals(3, testMultiMap.size());

        // Remove a value for one key
        testMultiMap.removeValue('key1', 'value1_1');
        lp_Assert.equals(3, testMultiMap.size());

        // Remove all values for one key
        testMultiMap.remove('key2');
        lp_Assert.equals(2, testMultiMap.size());

        // And now clear it
        testMultiMap.clear();
        lp_Assert.equals(0, testMultiMap.size());
    }

    @IsTest
    static void testListCollection() {
        // Add values for multiple keys to a list-backed multi-map
        lp_MultiMap testMultiMap = lp_MultiMap.newListInstance();
        testMultiMap.putValue('key', 'value1');
        testMultiMap.putValue('key', 'value2');
        // Add the same value twice
        testMultiMap.putValue('key', 'value1');
        lp_Assert.equals(3, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1', 'value2', 'value1' }, testMultiMap.getValues('key'), true);

        // Remove the duplicate value
        lp_Assert.equals('value1', testMultiMap.removeValue('key', 'value1'));
        lp_Assert.equals(2, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value2', 'value1' }, testMultiMap.getValues('key'), true);

        // Remove the same value which was added in duplicate
        lp_Assert.equals('value1', testMultiMap.removeValue('key', 'value1'));
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value2' }, testMultiMap.getValues('key'), true);

        // Now try to remove the same value again and it should return null
        lp_Assert.isNull(testMultiMap.removeValue('key', 'value1'));
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value2' }, testMultiMap.getValues('key'), true);
    }

    @IsTest
    static void testSetCollection() {
        // Add values for multiple keys to a set-backed multi-map
        lp_MultiMap testMultiMap = lp_MultiMap.newSetInstance();
        testMultiMap.putValue('key', 'value1');
        testMultiMap.putValue('key', 'value2');
        // Add the same value twice
        testMultiMap.putValue('key', 'value1');
        lp_Assert.equals(2, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value1', 'value2' }, testMultiMap.getValues('key'), false);

        // Remove the attempted duplicate value
        lp_Assert.equals('value1', testMultiMap.removeValue('key', 'value1'));
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value2' }, testMultiMap.getValues('key'), false);

        // Now try to remove the same value again and it should return null
        lp_Assert.isNull(testMultiMap.removeValue('key', 'value1'));
        lp_Assert.equals(1, testMultiMap.getValues('key').size());
        verifyContents(new String[] { 'value2' }, testMultiMap.getValues('key'), false);
    }

    static lp_MultiMap createMultiMap(Boolean allowDuplicates) {
        return allowDuplicates ? lp_MultiMap.newListInstance() : lp_MultiMap.newSetInstance();
    }

    static void verifyContents(List<Object> expectedValues, List<Object> actualValues, Boolean orderMatters) {
        lp_Assert.equals(expectedValues.size(), actualValues.size(), 'The list sizes do not match.');

        if (orderMatters) {
            for (Integer i = 0, numValues = expectedValues.size(); i < numValues; i++) {
                Object expectedValue = expectedValues.get(i);
                Object actualValue = actualValues.get(i);
                lp_Assert.equals(expectedValue, actualValue, 'Elements at index ' + i + ' do not match.');
            }
        } else {
            Set<Object> expectedValuesSet = new Set<Object>();
            expectedValuesSet.addAll(expectedValues);
            Set<Object> actualValuesSet = new Set<Object>();
            actualValuesSet.addAll(actualValues);
            lp_Assert.equals(expectedValuesSet, actualValuesSet, 'The contents do not match.');
        }
    }
}