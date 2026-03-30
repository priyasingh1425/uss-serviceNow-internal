/**
 * @author Ladd Partners
 * @date 2/8/2017
 * @group
*/

public with sharing class lp_Exception extends Exception {
    public boolean isWarning {
        get {
            // if we use a standard Exception constructor, this won't get set.
            // ensure we return a boolean.
            if (isWarning == null) {
                isWarning = false;
            }
            return isWarning;
        }
        private set;
    }

    public lp_Exception(string msg, boolean isWarning) {
        setMessage(msg);
        this.isWarning = isWarning;
    }

    public lp_Exception(string msg, Exception ex, boolean isWarning) {
        setMessage(msg);
        initCause(ex);
        this.isWarning = isWarning;
    }
}