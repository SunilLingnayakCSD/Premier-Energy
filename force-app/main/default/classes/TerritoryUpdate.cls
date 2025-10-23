public class TerritoryUpdate {
	 @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsWithAddresses() {
        // Query accounts with their related addresses
        return [SELECT Id, Name FROM Account];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Address__c> getAddressesForAccount(String accountId) {
        // Query addresses for a specific account
        return [SELECT Id, Name,Territory__c
                FROM Address__c
                WHERE Account__c = :accountId];
    }
    
    @AuraEnabled
public static void updateAOP(Id recordId, String accountId, String territory) {
    AOP_Targets__c aop = [
        SELECT Id, Territory__c, Distributor_Account__c
        FROM AOP_Targets__c
        WHERE Id = :recordId
        LIMIT 1
    ];

    aop.Territory__c = territory;
    aop.Distributor_Account__c = accountId;
    update aop;
}
}