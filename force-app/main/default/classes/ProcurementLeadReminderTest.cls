@isTest
public class ProcurementLeadReminderTest {
    
    static User user1;
    static User user2;
    static User user3;
    static UserRole userRole1;
    static UserRole userRole2;
    static UserRole userRole3;
    
    @testSetup
    static void testSetUp() {
        
        userRole1 = [
                SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Procurement'
            ];
        
        userRole2 = [
                SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Inbound_Logistics'
            ];
        
        userRole3 = [
                SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'Outbound_Logistics'
            ];
        
        user1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'test2user1@example.com',
            ProfileId = UserInfo.getProfileId(), // Set user role
            Alias = 'tuser1',
            userRoleId = userRole1.Id,
            Username = 'test2u1ser21@example.com',
            CommunityNickname = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        
        user2 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'test2u3ser1@example.com',
            ProfileId = UserInfo.getProfileId(), // Set user role
            Alias = 'tuser1',
            userRoleId = userRole2.Id,
            Username = 'test2u1s1er21@example.com',
            CommunityNickname = 'user2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert user2;
        
        user3 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            ProfileId = UserInfo.getProfileId(), // Set user role
            Alias = 'tuser1',
            userRoleId = userRole3.Id,
            Username = 'test2u1s7er21@example.com',
            CommunityNickname = 'user3',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert user3;
    }
    
    @isTest
    static void testExecuteBatch(){
        
        Test.startTest();
        
        ProcurementLeadReminder pL = new ProcurementLeadReminder();
        pL.sendProcurementEmails();
        
        Test.stopTest();
    }
    
    @isTest
    static void testSchedulableExecution() {
        // Test the schedulable interface
        Test.startTest();
        
        String jobID = System.schedule('Opportunity So Reminder', '0 0 0 15 8 ?', new ProcurementLeadReminder());
        
        // Wait for the scheduled job to be processed
        Test.stopTest();
        
        // Verify that the batch job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobID LIMIT 1];
        System.assertNotEquals(null, ct, 'The batch job should have been scheduled.');
    }
}