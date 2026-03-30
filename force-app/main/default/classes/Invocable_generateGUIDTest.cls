@IsTest
public class Invocable_generateGUIDTest {
    @IsTest
    public static void testGetGUIDs() {
        Invocable_generateGUID.Request req1 = new Invocable_generateGUID.Request();
        req1.keyLength = 10;
        Invocable_generateGUID.Request req2 = new Invocable_generateGUID.Request();
        req2.keyLength = 18;

        List<Invocable_generateGUID.Request> reqs = new List<Invocable_generateGUID.Request>{req1, req2};
        List<String> resps = Invocable_generateGUID.generateGUID(reqs);

        System.assertEquals(2, resps.size(), 'There should be as many responses as requests.');
        System.assertEquals(req1.keyLength, resps.get(0).length(), 'Key length should match value in request.');
        System.assertEquals(req2.keyLength, resps.get(1).length(), 'Key length should match value in request.');
    }
}