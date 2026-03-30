/**
 * @author Ladd Partners
 * @date 4/22/2025
*/

public with sharing class lp_EcmsGetByAccountIdMockImpl {

    public static HttpResponse create(String ecmsAccountId, String accountNumber, List<Integer> designatorIds, Boolean isExpired) {
        HttpResponse response = new HttpResponse();
        response.setStatus('OK');
        response.setStatusCode(200);

        lp_EcmsTypes.Customer customer1 = new lp_EcmsTypes.Customer();
        customer1.accountId = ecmsAccountId;
        customer1.accountNumber = accountNumber;
        customer1.shipToAccountNumber = null;

        lp_EcmsTypes.GetByAccountIdResponse getByAccountResponse = new lp_EcmsTypes.GetByAccountIdResponse();
        getByAccountResponse.top = 100;
        getByAccountResponse.skip = 0;
        getByAccountResponse.recordSetCount = designatorIds.size();
        getByAccountResponse.customerRef = customer1;
        getByAccountResponse.value = new List<lp_EcmsTypes.Value>();

        for (Integer i = 0; i < designatorIds.size(); i++) {
            lp_EcmsTypes.Value v1 = createExemption(designatorIds.get(i));

            if (isExpired) {
                v1.expirationDate = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
            }

            getByAccountResponse.value.add(v1);
        }

        response.setBody(JSON.serialize(getByAccountResponse));

        return response;
    }

    private static lp_EcmsTypes.Value createExemption(Integer designatorId) {
        lp_EcmsTypes.Value value1 = new lp_EcmsTypes.Value();

        value1.certificateId = '999999';
        value1.effectiveDate = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        value1.expirationDate = null;

        lp_EcmsTypes.Location location1 = new lp_EcmsTypes.Location();
        location1.state = 'CA';
        location1.country = 'US';

        value1.location = location1;

        lp_EcmsTypes.Designator designator1 = new lp_EcmsTypes.Designator();
        designator1.id = String.valueOf(designatorId);
        designator1.name = 'Sales and Use Taxes';
        designator1.type = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE;

        value1.exemptionDesignator = designator1;

        value1.scope = new List<String>{'All'};
        value1.domain = 'State';

        return value1;
    }

}