global class MPLResponse {

    private static final String STATUS_SUCCESS = 'success';
    private static final String STATUS_ERROR = 'error';
    private static final String TYPE_CHANGE = 'CHANGE';
    private static final String TYPE_WORKNOTE = 'WORKNOTE';

    public String status;
    public String message;
    public String recordId;
    public List<String> Messages;
    public String IncidentID;
    public String IncidentRecID;
    public String JournalNoteRecID;
    public String LogID;
    public String ChangeID;
    public String ChangeRecID;

    public static MPLResponse incidentSuccess(String msg, String id, String caseNumber) {
        MPLResponse r = initializeSuccessResponse(msg, id);
        r.IncidentID = caseNumber;
        r.IncidentRecID = id;
        return r;
    }

    public static MPLResponse success(String msg, String id) {
        MPLResponse r = initializeSuccessResponse(msg, id);
        r.IncidentID = id;
        r.IncidentRecID = id;
        return r;
    }

    public static MPLResponse success(String msg, String id, String responseType) {
        MPLResponse r = initializeSuccessResponse(msg, id);

        if (responseType == TYPE_CHANGE) {
            r.ChangeID = id;
            r.ChangeRecID = id;
        } else if (responseType == TYPE_WORKNOTE) {
            r.JournalNoteRecID = id;
        }

        return r;
    }

    public static MPLResponse successChange(String msg, String changeId, String changeRecId) {
        MPLResponse r = initializeSuccessResponse(msg, changeRecId);
        r.ChangeID = changeId;
        r.ChangeRecID = changeRecId;
        return r;
    }

    public static MPLResponse error(String msg) {
        MPLResponse r = new MPLResponse();
        r.status = STATUS_ERROR;
        r.message = msg;
        return r;
    }

    private static MPLResponse initializeSuccessResponse(String msg, String id) {
        MPLResponse r = new MPLResponse();
        r.status = STATUS_SUCCESS;
        r.message = msg;
        r.recordId = id;
        r.Messages = new List<String>{ msg };
        r.LogID = null;
        return r;
    }
}