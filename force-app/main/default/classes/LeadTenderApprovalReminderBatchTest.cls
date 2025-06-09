@isTest
public class LeadTenderApprovalReminderBatchTest {
    
    static User user1;
    static User user2;
    static Lead lead1;
    static Lead lead2;
    static UserRole userRole;
    
    @testSetup
    static void testSetUp() {
        // Create User Role
        userRole = [
            SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'North_Government_Projects_Regional_Manager'
        ];
        
        // Create Users (This is considered setup data)
        user1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            ProfileId = UserInfo.getProfileId(), // Use the current profile
            UserRoleId = userRole.Id, // Set user role
            Alias = 'tuser1',
            Username = 'test2user21@example.com',
            CommunityNickname = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        
        user2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'test5user52@example.com',
            ProfileId = UserInfo.getProfileId(), // Use the current profile
            UserRoleId = userRole.Id, // Set user role
            Alias = 'tuser2',
            Username = 'test5user52@example.com',
            CommunityNickname = 'user2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert user2;
    }
    
    @isTest
    static void testBatchExecution() {
        // Re-query the users to ensure their IDs are populated
        user1 = [SELECT Id FROM User WHERE Username = 'test2user21@example.com' LIMIT 1];
        user2 = [SELECT Id FROM User WHERE Username = 'test5user52@example.com' LIMIT 1];
        
        // Create Leads in the test method (non-setup object)
        lead1 = new Lead(
            LastName = 'Lead1',
            Company = 'Company1',
            DCR_Non_DCR__c='DCR',
            Status = 'Tender Participation Request',
            Region_Picklist__c = 'North',
            OwnerId = user1.Id,  // Ensure user1.Id is properly populated
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Government' LIMIT 1].Id,
            Tender_Number__c = 'TN001'
        );
        insert lead1;
        
        lead2 = new Lead(
            LastName = 'Lead2',
            Company = 'Company2',
             DCR_Non_DCR__c='DCR',
            Status = 'Tender Participation Request',
            Region_Picklist__c = 'North',
            OwnerId = user2.Id,  // Ensure user2.Id is properly populated
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Government' LIMIT 1].Id,
            Tender_Number__c = 'TN002'
        );
        insert lead2;
        
        // Start Test context
        Test.startTest();
        
        // Execute the batch
        LeadTenderApprovalReminderBatch batch = new LeadTenderApprovalReminderBatch();
        Database.executeBatch(batch, 200);
        
        // Stop Test context
        Test.stopTest();
    }
    
    
    @isTest
    static void testSchedulableExecution() {
        // Test the schedulable interface
        Test.startTest();
        
        String jobID = System.schedule('Lead Tender Approval Reminder', '0 0 0 15 8 ?', new LeadTenderApprovalReminderBatch());
        
        // Wait for the scheduled job to be processed
        Test.stopTest();
        
        // Verify that the batch job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobID LIMIT 1];
        System.assertNotEquals(null, ct, 'The batch job should have been scheduled.');
    }
}