public class AccountStatsWrapper {
    @AuraEnabled public Account account;
    @AuraEnabled public Integer nonConvertedLeads;
    
    public AccountStatsWrapper(Account acc) {
        this.account = acc;
        this.nonConvertedLeads = 0;
    }
}