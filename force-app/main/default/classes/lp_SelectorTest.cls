/**
 * @author Ladd Partners
 * @date 3/13/2019
*/

@IsTest
private class lp_SelectorTest {

    private class TestSelector extends lp_Selector {}

    @IsTest
    private static void testSelector() {
        TestSelector selector = new TestSelector();

        selector.setSObjectType(Account.getSObjectType());

        selector.addField('Id');
        selector.addField(Account.Name);

        String query = selector.getSelectStatement();
        System.assertEquals('SELECT Id, Name FROM Account', query, 'unexpected query');

        String subSelect = 'SELECT Id FROM Contacts';

        query = selector.getSelectStatement(subSelect);
        System.assertEquals('SELECT Id, Name, (' + subSelect + ') FROM Account', query, 'unexpected query with subselect');

        selector.setSObjectType('Contact');
        query = selector.getSelectStatement();
        System.assertEquals('SELECT Id, Name FROM Contact', query, 'unexpected query');
    }

}