public with sharing class Invocable_generateGUID { 
    public class Request {
        @InvocableVariable(label='Length of the Key' required=true)
        public Integer keyLength = 18;
    }
    
    @InvocableMethod(label='Get a new GUID') 
    public static List<String> generateGUID (List<Request> reqs) {
        List<String> results = new List<String>();
        for(Request req : reqs) {
            results.add(generateGUID(req.keyLength));
        }
        return results;
    }

    private static String generateGUID(Integer length)
    {
        String result;        
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        result = h.SubString(0, length);

        return result;
    }
}