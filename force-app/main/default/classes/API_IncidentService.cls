public with sharing class API_IncidentService {

    private static final String ENDPOINT_INCIDENTS = '/api/v1/com/incidents';
    private static final String SERVICE_NAME = 'incidents';
    private static final String LOG_PREFIX = 'API_IncidentService';

    private static Map<String, String> getHeaders() {
        return new Map<String, String>{
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        };
    }

    public static HttpRequestResponseModel.CRCreateResponse createIncident(Case c) {
        try {
            HttpRequestResponseModel.CreateIncidents payload = buildCreateIncidentPayload(c);

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'CreateInc'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('POST', ENDPOINT_INCIDENTS, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' createIncident', String.valueOf(c.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'createIncident', e);
            return null;
        }
    }

    private static HttpRequestResponseModel.CreateIncidents buildCreateIncidentPayload(Case c) {
        HttpRequestResponseModel.CreateIncidents payload = new HttpRequestResponseModel.CreateIncidents();
        payload.u_vendor_incident_number = String.valueOf(c.CaseNumber);
        payload.u_description = String.valueOf(c.Description);
        payload.u_major_incident = 'False';
        payload.u_primary_ci = (c.Vendor_Service_ID__c != null) ? String.valueOf(c.Vendor_Service_ID__c) : '';
        payload.u_priority = CityIntegrationConstants.getPriorityNumber(c.Priority);
        payload.u_cherwell_rec_id = String.valueOf(c.Id);
        payload.u_short_description = (c.Subject != null) ? String.valueOf(c.Subject) : '';
        payload.u_category = (c.Category__c != null) ? String.valueOf(c.Category__c) : '';
        return payload;
    }

    private static String toPlainText(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String plainText = value.replaceAll('<[^>]*>', '');
        plainText = plainText.replaceAll('&nbsp;', ' ');
        return plainText.trim();
    }

    public static HttpRequestResponseModel.CRCreateResponse createWorkNote(FeedItem notes, String vendorNumber) {
        try {
            API_ChangeRequestService.WorkNoteDetails workNote = API_ChangeRequestService.getWorkNote(notes, vendorNumber);

            if (workNote == null || String.isBlank(workNote.title) || String.isBlank(vendorNumber)) {
                return null;
            }

            HttpRequestResponseModel.CreateWorknoteRequest payload = new HttpRequestResponseModel.CreateWorknoteRequest();
            payload.Worknote = workNote.title;

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'CreateIncWN'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_INCIDENTS + '/' + vendorNumber, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' createWorkNote', String.valueOf(notes.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'createWorkNote', e);
            return null;
        }
    }

    public static HttpRequestResponseModel.CRCreateResponse updateIncidentStatus(Case c) {
        try {
            String incidentNumber = c.Customer_Rec_Id__c;

            if (String.isBlank(incidentNumber)) {
                return null;
            }

            HttpRequestResponseModel.UpdateIncidentStatus payload = new HttpRequestResponseModel.UpdateIncidentStatus();
            payload.status = 'pending';

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'ChangeIncStatus'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_INCIDENTS + '/' + incidentNumber, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' updateIncidentStatus', String.valueOf(c.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'updateIncidentStatus', e);
            return null;
        }
    }

    public static HttpRequestResponseModel.CRCreateResponse resolveIncidents(Case c) {
        try {
            String incidentNumber = c.Customer_Rec_Id__c;

            if (String.isBlank(incidentNumber)) {
                return null;
            }

            HttpRequestResponseModel.ResolveIncident payload = new HttpRequestResponseModel.ResolveIncident();
            payload.CloseNote = toPlainText(c.Details__c);

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'ResolveInc'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_INCIDENTS + '/' + incidentNumber, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' resolveIncidents', String.valueOf(c.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'resolveIncidents', e);
            return null;
        }
    }

    public static HttpRequestResponseModel.CRCreateResponse updatePriorityOnIncidents(Case c) {
        try {
            String incidentNumber = c.Customer_Rec_Id__c;

            if (String.isBlank(incidentNumber)) {
                return null;
            }

            HttpRequestResponseModel.UpdateIncidentPriority payload = new HttpRequestResponseModel.UpdateIncidentPriority();
            payload.u_priority = CityIntegrationConstants.getPriorityNumber(c.Priority);

            Map<String, String> qp = new Map<String, String>{
                'apiAction' => 'UpdatePriorityInc'
            };

            MulesoftApiClient.HttpDetails result = MulesoftApiClient.sendRequest('PATCH', ENDPOINT_INCIDENTS + '/' + incidentNumber, qp, getHeaders(), JSON.serialize(payload), SERVICE_NAME);
            return ApiResponseHelper.processApiResponse(result, LOG_PREFIX + ' updatePriorityOnIncidents', String.valueOf(c.Id));
        } catch (Exception e) {
            ApiResponseHelper.logException(LOG_PREFIX, 'updatePriorityOnIncidents', e);
            return null;
        }
    }
}