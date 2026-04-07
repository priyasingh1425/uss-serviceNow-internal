@isTest
private class HttpRequestResponseModelTest {

    @isTest
    static void test_CRCreateRequest_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.CRCreateRequest req = new HttpRequestResponseModel.CRCreateRequest();
        req.u_cherwell_rec_id            = '500000000000001';
        req.u_vendor_change_number       = 'CHG001';
        req.u_short_description          = 'Short desc';
        req.u_description                = 'Full description';
        req.u_start_date                 = '2026-04-01';
        req.u_end_date                   = '2026-04-02';
        req.closureInfo                  = '';
        req.u_type                       = 'Normal';
        req.u_state                      = 'pending_approval';
        req.implementation_plan          = 'Impl plan text';
        req.test_plan                    = 'Test plan text';
        req.backout_plan                 = 'Backout plan text';
        req.u_impact_post_deployment     = 'Minimal impact';
        req.u_user_impact_after_deployment = 'No user impact';
        Test.stopTest();

        System.assertEquals('500000000000001', req.u_cherwell_rec_id,
            'u_cherwell_rec_id should match assigned value');
        System.assertEquals('CHG001', req.u_vendor_change_number,
            'u_vendor_change_number should match assigned value');
        System.assertEquals('Short desc', req.u_short_description,
            'u_short_description should match assigned value');
        System.assertEquals('Full description', req.u_description,
            'u_description should match assigned value');
        System.assertEquals('Normal', req.u_type,
            'u_type should match assigned value');
        System.assertEquals('pending_approval', req.u_state,
            'u_state should match assigned value');
        System.assertEquals('Impl plan text', req.implementation_plan,
            'implementation_plan should match assigned value');
        System.assertEquals('Test plan text', req.test_plan,
            'test_plan should match assigned value');
        System.assertEquals('Backout plan text', req.backout_plan,
            'backout_plan should match assigned value');
    }

    @isTest
    static void test_CreateWorknoteRequest_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.CreateWorknoteRequest req = new HttpRequestResponseModel.CreateWorknoteRequest();
        req.Worknote = 'This is a work note entry';
        Test.stopTest();

        System.assertEquals('This is a work note entry', req.Worknote,
            'Worknote should match assigned value');
    }

    @isTest
    static void test_CloseCRRequest_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.CloseCRRequest req = new HttpRequestResponseModel.CloseCRRequest();
        req.close_code  = 'successful';
        req.closed_at   = '2026-04-01T10:00:00Z';
        req.close_notes = 'Closed by automation';
        req.state       = 3;
        Test.stopTest();

        System.assertEquals('successful', req.close_code,
            'close_code should match assigned value');
        System.assertEquals('2026-04-01T10:00:00Z', req.closed_at,
            'closed_at should match assigned value');
        System.assertEquals('Closed by automation', req.close_notes,
            'close_notes should match assigned value');
        System.assertEquals(3, req.state,
            'state should match assigned integer value');
    }

    @isTest
    static void test_UpdateTaskStatusRequest_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.UpdateTaskStatusRequest req = new HttpRequestResponseModel.UpdateTaskStatusRequest();
        req.worknote = 'Task completed successfully';
        req.status   = 'completed';
        Test.stopTest();

        System.assertEquals('Task completed successfully', req.worknote,
            'worknote should match assigned value');
        System.assertEquals('completed', req.status,
            'status should match assigned value');
    }

    @isTest
    static void test_CreateIncidents_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.CreateIncidents req = new HttpRequestResponseModel.CreateIncidents();
        req.u_vendor_incident_number = 'INC001';
        req.u_description            = 'Server outage';
        req.u_major_incident         = 'False';
        req.u_primary_ci             = 'CI-12345';
        req.u_priority               = '1';
        req.u_cherwell_rec_id        = '500000000000002';
        req.u_short_description      = 'Outage';
        req.u_category               = 'break fix';
        Test.stopTest();

        System.assertEquals('INC001', req.u_vendor_incident_number,
            'u_vendor_incident_number should match assigned value');
        System.assertEquals('Server outage', req.u_description,
            'u_description should match assigned value');
        System.assertEquals('False', req.u_major_incident,
            'u_major_incident should match assigned value');
        System.assertEquals('1', req.u_priority,
            'u_priority should match assigned value');
        System.assertEquals('break fix', req.u_category,
            'u_category should match assigned value');
    }

    @isTest
    static void test_ResolveIncident_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.ResolveIncident req = new HttpRequestResponseModel.ResolveIncident();
        req.CloseNote = 'Root cause identified and resolved';
        Test.stopTest();

        System.assertEquals('Root cause identified and resolved', req.CloseNote,
            'CloseNote should match assigned value');
    }

    @isTest
    static void test_UpdateIncidentStatus_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.UpdateIncidentStatus req = new HttpRequestResponseModel.UpdateIncidentStatus();
        req.status = 'pending';
        Test.stopTest();

        System.assertEquals('pending', req.status,
            'status should match assigned value');
    }

    @isTest
    static void test_UpdateIncidentPriority_properties_coverage() {
        Test.startTest();
        HttpRequestResponseModel.UpdateIncidentPriority req = new HttpRequestResponseModel.UpdateIncidentPriority();
        req.u_priority = '2';
        Test.stopTest();

        System.assertEquals('2', req.u_priority,
            'u_priority should match assigned value');
    }

    @isTest
    static void test_Result_ErrorInfo_ErrorDetails_properties_coverage() {
        Test.startTest();

        HttpRequestResponseModel.Result res = new HttpRequestResponseModel.Result();
        res.response = 'CHG0012345';

        HttpRequestResponseModel.ErrorInfo ei = new HttpRequestResponseModel.ErrorInfo();
        ei.message = 'Bad Request';
        ei.detail  = 'Missing required field';

        HttpRequestResponseModel.ErrorDetails ed = new HttpRequestResponseModel.ErrorDetails();
        ed.status = 'failure';
        ed.error  = ei;

        Test.stopTest();

        System.assertEquals('CHG0012345', res.response,
            'Result.response should match assigned value');
        System.assertEquals('Bad Request', ei.message,
            'ErrorInfo.message should match assigned value');
        System.assertEquals('Missing required field', ei.detail,
            'ErrorInfo.detail should match assigned value');
        System.assertEquals('failure', ed.status,
            'ErrorDetails.status should match assigned value');
        System.assertNotEquals(null, ed.error,
            'ErrorDetails.error should reference the ErrorInfo instance');
    }

    @isTest
    static void test_CRCreateResponse_isSuccess_true() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.result = new HttpRequestResponseModel.Result();
        resp.result.response = 'CHG0012345';

        Test.startTest();
        Boolean success = resp.isSuccess();
        Test.stopTest();

        System.assertEquals(true, success,
            'isSuccess() should return true when result is not null');
    }

    @isTest
    static void test_CRCreateResponse_isSuccess_false() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();

        Test.startTest();
        Boolean success = resp.isSuccess();
        Test.stopTest();

        System.assertEquals(false, success,
            'isSuccess() should return false when result is null');
    }

    @isTest
    static void test_CRCreateResponse_isFailure_true() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.Details = new HttpRequestResponseModel.ErrorDetails();
        resp.Details.status = 'failure';

        Test.startTest();
        Boolean failure = resp.isFailure();
        Test.stopTest();

        System.assertEquals(true, failure,
            'isFailure() should return true when Details.status is "failure"');
    }

    @isTest
    static void test_CRCreateResponse_isFailure_false_nullDetails() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();

        Test.startTest();
        Boolean failure = resp.isFailure();
        Test.stopTest();

        System.assertEquals(false, failure,
            'isFailure() should return false when Details is null');
    }

    @isTest
    static void test_CRCreateResponse_isFailure_false_differentStatus() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.Details = new HttpRequestResponseModel.ErrorDetails();
        resp.Details.status = 'success';

        Test.startTest();
        Boolean failure = resp.isFailure();
        Test.stopTest();

        System.assertEquals(false, failure,
            'isFailure() should return false when Details.status is not "failure"');
    }

    @isTest
    static void test_CRCreateResponse_getResolvedMessage_successBranch() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.result = new HttpRequestResponseModel.Result();
        resp.result.response = 'CHG0012345';

        Test.startTest();
        String msg = resp.getResolvedMessage();
        Test.stopTest();

        System.assertEquals('CHG0012345', msg,
            'getResolvedMessage should return result.response on the success branch');
    }

    @isTest
    static void test_CRCreateResponse_getResolvedMessage_successNullResponse() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.result = new HttpRequestResponseModel.Result();
        resp.result.response = null;
        resp.Description = 'Fallback desc';

        Test.startTest();
        String msg = resp.getResolvedMessage();
        Test.stopTest();

        System.assertEquals('Fallback desc', msg,
            'getResolvedMessage should fall to Description when result.response is null');
    }

    @isTest
    static void test_CRCreateResponse_getResolvedMessage_errorBranch() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.Details = new HttpRequestResponseModel.ErrorDetails();
        resp.Details.status = 'failure';
        resp.Details.error  = new HttpRequestResponseModel.ErrorInfo();
        resp.Details.error.message = 'Bad Request: Missing field';

        Test.startTest();
        String msg = resp.getResolvedMessage();
        Test.stopTest();

        System.assertEquals('Bad Request: Missing field', msg,
            'getResolvedMessage should return Details.error.message on the error branch');
    }

    @isTest
    static void test_CRCreateResponse_getResolvedMessage_fallbackBranch() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();
        resp.Description = 'Generic error description';

        Test.startTest();
        String msg = resp.getResolvedMessage();
        Test.stopTest();

        System.assertEquals('Generic error description', msg,
            'getResolvedMessage should return Description as the final fallback');
    }

    @isTest
    static void test_CRCreateResponse_getResolvedMessage_allNull() {
        HttpRequestResponseModel.CRCreateResponse resp = new HttpRequestResponseModel.CRCreateResponse();

        Test.startTest();
        String msg = resp.getResolvedMessage();
        Test.stopTest();

        System.assertEquals(null, msg,
            'getResolvedMessage should return null when all properties are null');
    }

    @isTest
    static void test_CRCreateResponse_jsonDeserialization_successLayout() {
        String jsonPayload = '{"status":"success","message":"OK","crNumber":"CHG0012345",'
            + '"result":{"response":"CHG0012345"}}';

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            (HttpRequestResponseModel.CRCreateResponse) JSON.deserialize(
                jsonPayload, HttpRequestResponseModel.CRCreateResponse.class
            );
        Test.stopTest();

        System.assertEquals('success', resp.status,
            'Deserialized status should match JSON value');
        System.assertEquals('OK', resp.message,
            'Deserialized message should match JSON value');
        System.assertEquals('CHG0012345', resp.crNumber,
            'Deserialized crNumber should match JSON value');
        System.assertEquals(true, resp.isSuccess(),
            'isSuccess() should return true for deserialized success response');
        System.assertEquals('CHG0012345', resp.getResolvedMessage(),
            'getResolvedMessage() should return the result.response value');
    }

    @isTest
    static void test_CRCreateResponse_jsonDeserialization_errorLayout() {
        String jsonPayload = '{"Details":{"status":"failure","error":{"message":"Not Found","detail":"Record does not exist"}},'
            + '"Description":"Record lookup failed"}';

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            (HttpRequestResponseModel.CRCreateResponse) JSON.deserialize(
                jsonPayload, HttpRequestResponseModel.CRCreateResponse.class
            );
        Test.stopTest();

        System.assertEquals(false, resp.isSuccess(),
            'isSuccess() should return false for error response');
        System.assertEquals(true, resp.isFailure(),
            'isFailure() should return true for deserialized failure response');
        System.assertEquals('Not Found', resp.getResolvedMessage(),
            'getResolvedMessage() should return the error message from Details');
    }

    @isTest
    static void test_outerClass_canBeInstantiated() {
        Test.startTest();
        HttpRequestResponseModel outerInstance = new HttpRequestResponseModel();
        Test.stopTest();

        System.assertNotEquals(null, outerInstance,
            'Outer HttpRequestResponseModel class should be instantiable');
    }
}
