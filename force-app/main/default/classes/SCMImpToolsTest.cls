/**
 * @author Ladd Partners
 * @date 9/29/2020
*/

@IsTest
private class SCMImpToolsTest {

    @IsTest
    private static void testController() {
        SCMImpToolsCon controller = new SCMImpToolsCon();
        System.assertNotEquals(0, controller.displayLinks.size(), 'unexpected number of display links');
    }

    @IsTest
    private static void exceptionTest() {
        try {
            throw new SCMImpToolsException('Error');
        } catch (Exception ex) {

        }
    }

}