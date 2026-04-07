public class MPLRequest {

    public class CreateIncident {
        public String Description;
        public String ShortDescription;
        public String Priority;
        public String APITicketID;
        public String Category;
        public String Subcategory;
    }

    public class CreateWorkNote {
        public String ParentRecID;
        public String Details;
    }

    public class ResolveIncident {
        public String IncidentRecID;
        public String CloseDescription;
    }

    public class ReopenIncident {
        public String IncidentRecID;
    }

    public class CreateChangeRequest {
        public String Description;
        public String ShortDescription;
        public String ScheduledStartDate;
        public String ScheduledEndDate;
        public String Priority;
        public String Type;
        public String APIChangeID;
        public String SalesforceID;
        public String State;
        public List<ChangeRequestTask> tasks;
    }

    public class ChangeRequestTask {
        public String Title;
        public String Description;
        public String Type;
        public String Priority;
        public String ScheduledStartDate;
        public String ScheduledEndDate;
        public String APITicketID;
    }
}
