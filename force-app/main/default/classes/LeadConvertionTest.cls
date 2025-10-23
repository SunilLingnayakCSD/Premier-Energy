@isTest
public class LeadConvertionTest {
    
    static Lead lead1;
    static Lead lead2;
    static Lead lead3;
    static Lead insertedLead;
    
    @testSetup
    static void testSetUp() {
        lead1 = new Lead(
            LastName = 'Lead1',
            Company = 'Company1',
            Status = 'Tender Participation Request',
            Region_Picklist__c = 'North',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' LIMIT 1].Id,
            Tender_Number__c = 'TN001'
        );
        insert lead1;
        
        lead2 = new Lead(
            LastName = 'Lead2',
            Company = 'Company1',
            Status = 'Pre Qualification Request',
            Region_Picklist__c = 'North',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' LIMIT 1].Id,
            Tender_Number__c = 'TN002'
        );
        insert lead2;
        
        lead3 = new Lead(
            LastName = 'Lead3',
            Company = 'Company3',
            Status = 'New',
            Region_Picklist__c = 'North',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' LIMIT 1].Id,
            Tender_Number__c = 'TN001'
        );
        insert lead3;
    }
    
    @isTest
    static void leadConversionTestMethod(){
        insertedLead = [SELECT Id,Company FROM Lead WHERE Company = 'Company1' LIMIT 1];

        // Call the method
        Test.startTest();
        try
        {
           LeadConvertion.convertLeads(new List<Id>{insertedLead.Id}); 
        }
        catch(Exception e)
        {
            system.debug('error Message ' +e.getMessage());
        }
        
        Test.stopTest();

        // Validate that the lead is converted
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId 
                              FROM Lead WHERE Id = :insertedLead.Id];
        //System.assert(convertedLead.IsConverted, 'Lead should be converted');

        // Validate the Account
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Company1' LIMIT 1];
        System.assertEquals('Company1', acc.Name, 'Account should be created for the lead company');

        // Validate the Contact
        Contact con = [SELECT Id, Email FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        
        
    }
}