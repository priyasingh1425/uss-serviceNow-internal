public without sharing class HLP_Home_Announcements_CTL {
    public Id groupId {get; set;}
    public HLP_Home_Announcements_CTL(){
        groupId=[Select Id from CollaborationGroup Where Name= 'Announcements'].Id;
    }
}