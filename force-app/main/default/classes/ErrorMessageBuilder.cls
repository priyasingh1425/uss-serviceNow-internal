public class ErrorMessageBuilder {

    public static String build(Database.Error err) {

        if (err == null) {
            return 'Unable to process the request due to an unknown error.';
        }

        if (err.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING) {
            return 'Missing or invalid required information: '
                + String.join(err.getFields(), ', ');
        }

        if (err.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
            return 'A record with the same information already exists.';
        }

        if (err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW) {
            return 'The record is currently being updated by another process. Please try again.';
        }

        if (err.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY) {
            return 'You do not have permission to perform this action.';
        }

        if (err.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
            return 'The record does not meet business validation rules: ' + err.getMessage();
        }

        if (err.getFields() != null && !err.getFields().isEmpty()) {
            return 'Unable to save the record. Fields with issues: '
                + String.join(err.getFields(), ', ') + '. Detail: ' + err.getMessage();
        }

        return 'Unable to save the record due to a system validation error: ' + err.getMessage();
    }
}
