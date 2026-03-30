/**
 * Created by Ladd Partners on 3/25/2025.
 */

public class lp_EcmsTypes {

    public class GetByAccountIdRequest {
        public Boolean approved;
        public Integer top;
        public Integer skip;
        public Boolean count;
        public Boolean countOnly;
        public String api_token;
    }

    public class GetByAccountIdResponse {
        public Customer customerRef;
        public Integer recordSetCount;
        public Integer top;
        public Integer skip;
        public Integer nextSkip;
        public List<Value> value;
    }

    public class Value {
        public String certificateId;
        public String effectiveDate;
        public String expirationDate;
        public Location location;
        public Designator exemptionDesignator;
        public List<String> scope;
        public String domain;
    }

    public class Customer {
        public String accountId;
        public String accountNumber;
        public String shipToAccountNumber;
    }

    public class Exemption {
        public String certificateId;
        public String effectiveDate;
        public String expirationDate;
        public Location location;
        public Designator exemptionDesignator;
        public List<String> scope;
        public String domain;
    }

    public class Location {
        public String country;
        public String state;
        public String county;
        public String city;
    }

    public class Designator {
        public String type;
        public String id;
        public String name;
    }

    public class GetSummaryRequest {
        public String start;
        public String end_Z; // in JSON - end
        public String api_token;
    }

    public class GetSummaryResponse {
        public List<String> updated;
        public List<String> deleted;
    }

}