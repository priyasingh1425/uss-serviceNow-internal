/**
 * @author Ladd Partners
 * @date 3/13/2019
*/

public with sharing class lp_TriggerContext {

    public Boolean isExecuting { get; private set; }
    public Boolean isInsert { get; private set; }
    public Boolean isUpdate { get; private set; }
    public Boolean isDelete { get; private set; }
    public Boolean isBefore { get; private set; }
    public Boolean isAfter { get; private set; }
    public Boolean isUndelete { get; private set; }
    public List<SObject> newList { get; private set; }
    public Map<Id, SObject> newMap { get; private set; }
    public List<SObject> oldList { get; private set; }
    public Map<Id, SObject> oldMap { get; private set; }
    public Integer size { get; private set; }

    public lp_TriggerContext(Boolean isExecuting,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            Boolean isBefore,
            Boolean isAfter,
            Boolean isUndelete,
            List<SObject> newList,
            Map<Id, SObject> newMap,
            List<SObject> oldList,
            Map<Id, SObject> oldMap,
            Integer size) {
        this.isExecuting = isExecuting;
        this.isInsert = isInsert;
        this.isUpdate = isUpdate;
        this.isDelete = isDelete;
        this.isBefore = isBefore;
        this.isAfter = isAfter;
        this.isUndelete = isUndelete;
        this.newList = newList;
        this.newMap = newMap;
        this.oldList = oldList;
        this.oldMap = oldMap;
        this.size = size;
    }

}