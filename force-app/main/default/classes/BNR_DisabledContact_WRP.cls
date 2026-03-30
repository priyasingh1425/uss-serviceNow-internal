public class BNR_DisabledContact_WRP {
    @AuraEnabled
    Public String role {get; set;}
    @AuraEnabled
    Public String email {get; set;}
        public BNR_DisabledContact_WRP(String role, String email){
            this.role = role;
            this.email = email;
        }
}