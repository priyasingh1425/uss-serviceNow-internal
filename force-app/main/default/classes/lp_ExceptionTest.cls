/**
 * @author Ladd Partners
 * @date 3/13/2019
*/

@IsTest
private class lp_ExceptionTest {

    @IsTest
    private static void exceptionTest() {
        try {
            throw new lp_Exception('exception message', false);
        } catch (lp_Exception ex) {
            System.assertEquals('exception message', ex.getMessage(), 'unexpected message');
            System.assertEquals(false, ex.isWarning);
        }
    }

    @IsTest
    private static void exceptionTestWarn() {
        try {
            throw new lp_Exception('exception message', true);
        } catch (lp_Exception ex) {
            System.assertEquals('exception message', ex.getMessage(), 'unexpected message');
            System.assertEquals(true, ex.isWarning);
            try {
                throw new lp_Exception(ex.getMessage(), ex, ex.isWarning);
            } catch (lp_Exception ex1){
                System.assertEquals('exception message', ex.getMessage(), 'unexpected message');
                System.assertEquals(true, ex.isWarning);
            }
        }
    }
}