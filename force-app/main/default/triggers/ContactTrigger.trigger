trigger ContactTrigger on Contact (before insert,Before Update,After Insert,After Update) {

    if(Trigger.IsBefore && (Trigger.IsInsert || Trigger.IsUpdate))
    {
        list<contact> conlist = new list<contact>();
        ContactTriggerHandler handler = new ContactTriggerHandler();
   
        
        for(Contact con : trigger.new)
        {
            //if(con.AccountId == Null && con.company__c != '')
            if(con.AccountId == Null && con.mailingstreet != '')    
            {
              conlist.add(con); 
            }
        }
        
        if(!conlist.IsEmpty())
        {
            handler.onBefore(conlist);
            
        }
    }
    
    if(Trigger.IsAfter & (Trigger.IsInsert || Trigger.IsUpdate))
    {
        system.debug('entered after');
        map<id,contact> contactMap = new map<id,contact>();
        for(contact c : Trigger.New)
        {
            system.debug('c'+c);
           if(c.AccountId != Null)
           {
              contactMap.put(c.Id,c); 
           }
        }
        
       if(contactMap.size() > 0)
       {
           ContactTriggerHandler.AdjustAdresses(contactMap.keyset());
       }
    }

    

}