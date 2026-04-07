public with sharing class API_ChangeRequestService {

    private static final String ENDPOINT_CHANGE_REQUESTS = '/api/v1/com/change-requests';
    private static final String SERVICE_NAME = 'changeRequest';
    private static final String LOG_PREFIX = 'API_ChangeRequestService';

    private static Map<String, String> getHeaders() {
        return new Map<String, String>{
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        };
    }

    public static HttpRequestResponseModel.CRCreateResponse createCR(Case c) {
        try {
            HttpRequestResponseModel.CRCreateRequest payload = buildCreateCRPayload(c);

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'CreateCR'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('POST', ENDPOINT_CHANGE_REQUESTS, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' CreateCR', String.valueOf(c.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'createCR', e);
            return null;
        }
    }

    private static HttpRequestResponseModel.CRCreateRequest buildCreateCRPayload(Case c) {
        HttpRequestResponseModel.CRCreateRequest payload = new HttpRequestResponseModel.CRCreateRequest();
        payload.u_cherwell_rec_id = String.valueOf(c.Id);
        payload.u_vendor_change_number = String.valueOf(c.CaseNumber);
        payload.u_short_description = (c.Subject != null) ? String.valueOf(c.Subject) : '';
        payload.u_description = (c.Description != null) ? String.valueOf(c.Description) : '';
        payload.u_start_date = (c.Planned_Start_Date__c != null) ? String.valueOf(c.Planned_Start_Date__c) : '';
        payload.u_end_date = (c.Planned_Delivery_Date__c != null) ? String.valueOf(c.Planned_Delivery_Date__c) : '';
        payload.closureInfo = '';
        payload.u_type = 'Normal';
        payload.u_state = 'pending_approval';
        payload.test_plan = (c.Test_Plan__c != null) ? String.valueOf(c.Test_Plan__c).stripHtmlTags() : '';
        payload.implementation_plan = (c.Implementation_Plan__c != null) ? String.valueOf(c.Implementation_Plan__c).stripHtmlTags() : '';
        payload.backout_plan = (c.Backout_Plan__c != null) ? String.valueOf(c.Backout_Plan__c).stripHtmlTags() : '';
        payload.u_impact_post_deployment = (c.Users_Systems_Impacted__c != null) ? String.valueOf(c.Users_Systems_Impacted__c) : '';
        payload.u_user_impact_after_deployment = (c.Service_Affecting__c != null) ? String.valueOf(c.Service_Affecting__c) : '';
        return payload;
    }

    public static HttpRequestResponseModel.CRCreateResponse createWorkNote(FeedItem notes, String vendorNumber) {
        try {
            WorkNoteDetails workNote = getWorkNote(notes, vendorNumber);

            if (workNote == null || String.isBlank(workNote.title) || String.isBlank(workNote.VendorNumber)) {
                return null;
            }

            HttpRequestResponseModel.CreateWorknoteRequest payload = new HttpRequestResponseModel.CreateWorknoteRequest();
            payload.Worknote = workNote.title;

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'CreateCHGWN'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_CHANGE_REQUESTS + '/' + workNote.VendorNumber, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' createWorkNote', String.valueOf(notes.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'createWorkNote', e);
            return null;
        }
    }

    public static HttpRequestResponseModel.CRCreateResponse closeChangeRequest(Case c) {
        try {
            String changeNumber = c.Customer_Rec_Id__c;
            Boolean isParent = c.ParentId == null;

            if (String.isBlank(changeNumber) || isParent) {
                return null;
            }

            HttpRequestResponseModel.CloseCRRequest payload = buildClosePayloadChildCase(c);

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'ChangeClosureInfo'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_CHANGE_REQUESTS + '/' + changeNumber, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' closeChangeRequest', String.valueOf(c.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'closeChangeRequest', e);
            return null;
        }
    }

    private static HttpRequestResponseModel.CloseCRRequest buildClosePayloadChildCase(Case c) {
        HttpRequestResponseModel.CloseCRRequest payload = new HttpRequestResponseModel.CloseCRRequest();
        payload.state = 3;
        payload.close_code = 'successful';
        payload.closed_at = (c.ClosedDate != null) ? String.valueOf(c.ClosedDate) : String.valueOf(System.now());
        payload.close_notes = (c.Details__c != null) ? String.valueOf(c.Details__c).stripHtmlTags() : 'Closed by Third Party';
        return payload;
    }

    public static HttpRequestResponseModel.CRCreateResponse updateTaskStatus(Task t) {
        try {
            String taskName = t.Customer_Rec_Id__c;

            if (String.isBlank(taskName)) {
                return null;
            }

            HttpRequestResponseModel.UpdateTaskStatusRequest payload = buildTaskStatusPayload(t);

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'ChangeTaskStatus'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_CHANGE_REQUESTS + '/tasks/' + taskName, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' updateTaskStatus', String.valueOf(t.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'updateTaskStatus', e);
            return null;
        }
    }

    private static HttpRequestResponseModel.UpdateTaskStatusRequest buildTaskStatusPayload(Task t) {
        HttpRequestResponseModel.UpdateTaskStatusRequest payload = new HttpRequestResponseModel.UpdateTaskStatusRequest();
        payload.worknote = (t.Subject != null) ? String.valueOf(t.Subject) : '';
        payload.status = (t.Status != null && t.Status == 'Completed') ? 'completed' : '';
        return payload;
    }

    public static WorkNoteDetails getWorkNote(FeedItem notes, String changeNumber) {
        try {
            if (String.isBlank(changeNumber)) {
                return null;
            }

            List<FeedItem> notesDataList = [
                SELECT Id, Parent.Id, Parent.Name, Type, Body, Visibility
                FROM FeedItem
                WHERE Id = :notes.Id
                LIMIT 1
            ];

            if (notesDataList.isEmpty()) {
                return null;
            }

            FeedItem notesData = notesDataList[0];
            String body = notesData.Body != null ? notesData.Body.toString() : '';

            String cleanBody = body.stripHtmlTags();
            WorkNoteDetails wn = new WorkNoteDetails();
            wn.VendorNumber = changeNumber;
            wn.title = cleanBody;
            return wn;
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'getWorkNote', e);
            return null;
        }
    }

    public class WorkNoteDetails {
        public String VendorNumber;
        public String title;
    }
}
