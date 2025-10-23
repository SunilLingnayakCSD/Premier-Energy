@isTest
public class TerritoryUpdateTest {
    
    @testsetup
    static void setupTestData(){
        Account acc = new Account(
            name = 'Test',
    		RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Distributor').getRecordTypeId());
        insert acc;
        
       Address__c addr = new Address__c(
            Name = 'Test Address',
            Account__c = acc.Id,
            Territory__c = 'East'
        );
        insert addr;
        
         // Create a test AOP_Targets__c record
        AOP_Targets__c aop = new AOP_Targets__c(
            Territory__c = 'T1',
            Distributor_Account__c = acc.Id
        );
        insert aop;
    }
    
        @isTest
    static void testGetAccountsWithAddresses() {
        Test.startTest();
        List<Account> accounts = TerritoryUpdate.getAccountsWithAddresses();
        Test.stopTest();

        System.assertNotEquals(0, accounts.size(), 'Accounts should be returned');
    }

    @isTest
    static void testGetAddressesForAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Address__c> addresses = TerritoryUpdate.getAddressesForAccount(acc.Id);
        Test.stopTest();

        System.assertNotEquals(0, addresses.size(), 'Addresses should be returned for the account');
        System.assertEquals('East', addresses[0].Territory__c);
    }

    @isTest
    static void testUpdateAOP() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        AOP_Targets__c aop = [SELECT Id FROM AOP_Targets__c LIMIT 1];

        Test.startTest();
        TerritoryUpdate.updateAOP(aop.Id, acc.Id, 'West');
        Test.stopTest();

        AOP_Targets__c updatedAop = [SELECT Territory__c, Distributor_Account__c FROM AOP_Targets__c WHERE Id = :aop.Id];
        System.assertEquals('West', updatedAop.Territory__c, 'Territory should be updated');
        System.assertEquals(acc.Id, updatedAop.Distributor_Account__c, 'Distributor account should be updated');
    }
}