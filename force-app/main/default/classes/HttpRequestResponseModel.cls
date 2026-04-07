public with sharing class HttpRequestResponseModel {

    /* ===================== REQUEST MODELS ===================== */

    public class CRCreateRequest {
        public String u_cherwell_rec_id;
        public String u_vendor_change_number;
        public String u_short_description;
        public String u_description;
        public String u_start_date;
        public String u_end_date;
        public String closureInfo;
        public String u_type;
        public String u_state;
        public String implementation_plan;
        public String test_plan;
        public String backout_plan;
        public String u_impact_post_deployment;
        public String u_user_impact_after_deployment;
    }

    public class CreateWorknoteRequest {
        public String Worknote;
    }

    public class CloseCRRequest {
        public String close_code;
        public String closed_at;
        public String close_notes;
        public Integer state;
    }

    public class UpdateTaskStatusRequest {
        public String worknote;
        public String status;
    }

    public class CreateIncidents {
        public String u_vendor_incident_number;
        public String u_description;
        public String u_major_incident;
        public String u_primary_ci;
        public String u_priority;
        public String u_cherwell_rec_id;
        public String u_short_description;
        public String u_category;
    }

    public class ResolveIncident {
        public String CloseNote;
    }

    public class UpdateIncidentStatus {
        public String status;
    }

    public class UpdateIncidentPriority {
        public String u_priority;
    }

    /* ===================== SHARED RESPONSE TYPES ===================== */

    public class Result {
        public String response;
    }

    public class ErrorInfo {
        public String message;
        public String detail;
    }

    public class ErrorDetails {
        public String status;
        public ErrorInfo error;
    }

    /* ===================== RESPONSE WRAPPER ===================== */

    public class CRCreateResponse {

        public String status;
        public String message;
        public String crNumber;

        public Result result;

        public ErrorDetails Details;
        public String Description;

        public Boolean isSuccess() {
            return result != null;
        }

        public Boolean isFailure() {
            return Details != null && Details.status == 'failure';
        }

        public String getResolvedMessage() {
            if (isSuccess() && result != null && result.response != null) {
                return result.response;
            }
            if (Details != null && Details.error != null) {
                return Details.error.message;
            }
            return Description;
        }
    }
}
