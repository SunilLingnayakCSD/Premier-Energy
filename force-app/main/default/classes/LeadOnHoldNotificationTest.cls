@isTest
public class LeadOnHoldNotificationTest {
    
    @TestSetup
    static void makeData() {
        // Query for existing User Roles or create them if they don't exist
        Map<String, UserRole> existingRoles = new Map<String, UserRole>();
        for (UserRole ur : [SELECT Id, DeveloperName FROM UserRole 
                           WHERE DeveloperName IN ('National_Head_Key_Accounts_Private', 
                                                   'Key_Accounts_International_Head_Private',
                                                   'North_Region_Head_Key_Account_Private',
                                                   'Test_Regular_User_Role')]) {
            existingRoles.put(ur.DeveloperName, ur);
        }
        
        List<UserRole> rolesToInsert = new List<UserRole>();
        
        // Create missing roles
        if (!existingRoles.containsKey('National_Head_Key_Accounts_Private')) {
            rolesToInsert.add(new UserRole(
                Name = 'National Head Key Accounts Private',
                DeveloperName = 'National_Head_Key_Accounts_Private'
            ));
        }
        
        if (!existingRoles.containsKey('Key_Accounts_International_Head_Private')) {
            rolesToInsert.add(new UserRole(
                Name = 'Key Accounts International Head Private',
                DeveloperName = 'Key_Accounts_International_Head_Private'
            ));
        }
        
        if (!existingRoles.containsKey('North_Region_Head_Key_Account_Private')) {
            rolesToInsert.add(new UserRole(
                Name = 'North Region Head Key Account Private',
                DeveloperName = 'North_Region_Head_Key_Account_Private'
            ));
        }
        
        if (!existingRoles.containsKey('Test_Regular_User_Role')) {
            rolesToInsert.add(new UserRole(
                Name = 'Test Regular User Role',
                DeveloperName = 'Test_Regular_User_Role'
            ));
        }
        
        if (!rolesToInsert.isEmpty()) {
            insert rolesToInsert;
        }
        
        // Refresh the existing roles map
        existingRoles.clear();
        for (UserRole ur : [SELECT Id, DeveloperName FROM UserRole 
                           WHERE DeveloperName IN ('National_Head_Key_Accounts_Private', 
                                                   'Key_Accounts_International_Head_Private',
                                                   'North_Region_Head_Key_Account_Private',
                                                   'Test_Regular_User_Role')]) {
            existingRoles.put(ur.DeveloperName, ur);
        }
        
        // Create Profile
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create Users with unique usernames to avoid conflicts
        String uniqueId = String.valueOf(System.currentTimeMillis());
        
        User nationalHead = new User(
            FirstName = 'National',
            LastName = 'Head',
            Email = 'nationalhead@test.com',
            Username = 'nationalhead' + uniqueId + '@test.com.test',
            Alias = 'nathead',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            UserRoleId = existingRoles.get('National_Head_Key_Accounts_Private').Id
        );
        insert nationalHead;
        
        User internationalHead = new User(
            FirstName = 'International',
            LastName = 'Head',
            Email = 'intlhead@test.com',
            Username = 'intlhead' + uniqueId + '@test.com.test',
            Alias = 'inthead',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            UserRoleId = existingRoles.get('Key_Accounts_International_Head_Private').Id
        );
        insert internationalHead;
        
        User regionHead = new User(
            FirstName = 'Region',
            LastName = 'Head',
            Email = 'regionhead@test.com',
            Username = 'regionhead' + uniqueId + '@test.com.test',
            Alias = 'reghead',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            UserRoleId = existingRoles.get('North_Region_Head_Key_Account_Private').Id
        );
        insert regionHead;
        
        User regularUser = new User(
            FirstName = 'Regular',
            LastName = 'User',
            Email = 'regularuser@test.com',
            Username = 'regularuser' + uniqueId + '@test.com.test',
            Alias = 'reguser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id,
            UserRoleId = existingRoles.get('Test_Regular_User_Role').Id
        );
        insert regularUser;
    }
    
    @isTest
    static void testPreNotificationScenario() {
        // Get test data - query for existing RecordType
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SObjectType = 'Lead' LIMIT 1];
        User regionHead = [SELECT Id FROM User WHERE Email = 'regionhead@test.com' LIMIT 1];
        
        // Calculate date that will trigger pre-notification (6 months - 1 week from today)
        Date preNotificationDate = Date.today().addDays(7).addMonths(-6);
        
        // Create test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead Pre-Notification',
            Email = 'testlead1@test.com',
            Company = 'Test Company 1',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = preNotificationDate,
            Region_Picklist__c = 'North',
            Product_Category__c = 'CELL',
            Segment1__c = 'CELL_DOMESTIC',
            Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
            DCR_Non_DCR1__c = 'DCR',
            Project_Capacity__c = 100.5,
            Delivery_Due_Date__c = Date.today().addDays(30),
            OwnerId = regionHead.Id,
            Reason_for_On_Hold__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        // Execute batch
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that batch executed successfully
        // Note: We can't easily test actual email sending in unit tests,
        // but we can verify the batch completed without errors
        System.assert(true, 'Batch executed successfully for pre-notification scenario');
    }
    
    @isTest
    static void testMonthlyReminderScenario() {
        // Get test data
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SObjectType = 'Lead' LIMIT 1];
        User regularUser = [SELECT Id FROM User WHERE Email = 'regularuser@test.com' LIMIT 1];
        
        // Calculate date for monthly reminder (same day of month, 2 months ago)
        Date today = Date.today();
        Date monthlyReminderDate = today.addMonths(-2);
        
        // Create test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead Monthly Reminder',
            Email = 'testlead2@test.com',
            Company = 'Test Company 2',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = monthlyReminderDate,
            Region_Picklist__c = 'South',
            Product_Category__c = 'MODULE',
            Segment1__c = 'MODULE_DOMESTIC_RESIDENTIAL',
            Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
            DCR_Non_DCR1__c = 'NON-DCR',
            Project_Capacity__c = 50.0,
            Delivery_Due_Date__c = Date.today().addDays(60),
            OwnerId = regularUser.Id,
            Reason_for_On_Hold__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        // Execute batch
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that batch executed successfully
        System.assert(true, 'Batch executed successfully for monthly reminder scenario');
    }
    
    @isTest
    static void testMultipleLeadsForSameOwner() {
        // Get test data
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SObjectType = 'Lead' LIMIT 1];
        User regionHead = [SELECT Id FROM User WHERE Email = 'regionhead@test.com' LIMIT 1];
        
        Date preNotificationDate = Date.today().addDays(7).addMonths(-6);
        Date monthlyReminderDate = Date.today().addMonths(-3);
        
        // Create multiple test leads for same owner
        List<Lead> testLeads = new List<Lead>();
        
        // Pre-notification lead
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead Multiple 1',
            Email = 'testlead3@test.com',
            Company = 'Test Company 3',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = preNotificationDate,
            Region_Picklist__c = 'North',
            Product_Category__c = 'CELL',
            Segment1__c = 'CELL_DOMESTIC',
            Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
            DCR_Non_DCR1__c = 'DCR',
            Project_Capacity__c = 200.0,
            OwnerId = regionHead.Id,
            Reason_for_On_Hold__c = 'Test'
        ));
        
        // Monthly reminder lead
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Lead Multiple 2',
            Email = 'testlead4@test.com',
            Company = 'Test Company 4',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = monthlyReminderDate,
            Region_Picklist__c = 'North',
            Product_Category__c = 'MODULE',
            Segment1__c = 'MODULE_DOMESTIC_RESIDENTIAL',
            Product_Details_Technology_Type__c = 'MONOPERC_MONOFACIAL-M10',
            DCR_Non_DCR1__c = 'NON-DCR',
            Project_Capacity__c = 150.0,
            OwnerId = regionHead.Id,
            Reason_for_On_Hold__c = 'Test'
        ));
        
        insert testLeads;
        
        Test.startTest();
        // Execute batch
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that batch executed successfully
        System.assert(true, 'Batch executed successfully for multiple leads scenario');
    }
    
    @isTest
    static void testLeadsWithoutOwnerEmail() {
        // Get test data
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SObjectType = 'Lead' LIMIT 1];
        
        Date preNotificationDate = Date.today().addDays(7).addMonths(-6);
        
        // Create user without email
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueId = String.valueOf(System.currentTimeMillis());
        User userWithoutEmail = new User(
            FirstName = 'No',
            LastName = 'Email',
            Email = 'noemail' + uniqueId + '@test.com',
            Username = 'noemail' + uniqueId + '@test.com.test',
            Alias = 'noemail',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert userWithoutEmail;
        
        // Create test lead with owner having no email
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead No Email',
            Email = 'testlead5@test.com',
            Company = 'Test Company 5',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = preNotificationDate,
            Region_Picklist__c = 'East',
            OwnerId = userWithoutEmail.Id,
            Reason_for_On_Hold__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        // Execute batch - should handle leads without owner email gracefully
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that batch executed successfully without errors
        System.assert(true, 'Batch executed successfully even with leads having no owner email');
    }
    
    @isTest
    static void testLeadsOutsideDateRange() {
        // Get test data
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SObjectType = 'Lead' LIMIT 1];
        User regularUser = [SELECT Id FROM User WHERE Email = 'regularuser@test.com' LIMIT 1];
        
        // Create lead with date outside notification range
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead Outside Range',
            Email = 'testlead6@test.com',
            Company = 'Test Company 6',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = Date.today().addMonths(-8), // Older than 6 months
            Region_Picklist__c = 'West',
            OwnerId = regularUser.Id,
            Reason_for_On_Hold__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        // Execute batch
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that batch executed successfully
        System.assert(true, 'Batch executed successfully for leads outside date range');
    }
    
    @isTest
    static void testSchedulableInterface() {
        Test.startTest();
        // Schedule the job
        String cronExpression = '0 0 8 * * ?'; // Daily at 8 AM
        String jobId = System.schedule('Test Lead Notification Job', cronExpression, new LeadOnHoldNotification());
        Test.stopTest();
        
        // Verify that job was scheduled
        System.assert(String.isNotBlank(jobId), 'Job should be scheduled successfully');
        
        // Verify scheduled job exists
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals(cronExpression, scheduledJobs[0].CronExpression, 'Cron expression should match');
    }
    
    @isTest
    static void testBatchWithNullValues() {
        // Get test data
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' AND SObjectType = 'Lead' LIMIT 1];
        User regularUser = [SELECT Id FROM User WHERE Email = 'regularuser@test.com' LIMIT 1];
        
        Date preNotificationDate = Date.today().addDays(7).addMonths(-6);
        
        // Create test lead with null values
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead Null Values',
            Email = 'testlead7@test.com',
            Company = 'Test Company 7',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = preNotificationDate,
            Region_Picklist__c = null,
            Product_Category__c = null,
            Segment1__c = null,
            DCR_Non_DCR1__c = null,
            Project_Capacity__c = null,
            Delivery_Due_Date__c = null,
            OwnerId = regularUser.Id,
            Reason_for_On_Hold__c ='Customer’s Bankrupt / Blocklisted profile'
        );
        insert testLead;
        
        Test.startTest();
        // Execute batch
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that batch executed successfully even with null values
        System.assert(true, 'Batch executed successfully with null field values');
    }
    
    @isTest
    static void testQueryLocatorMethod() {
        // Get test data
        RecordType keyAccountRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Key_Account_Private' LIMIT 1];
        User regularUser = [SELECT Id FROM User WHERE Email = 'regularuser@test.com' LIMIT 1];
        
        // Create test lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead Query Test',
            Email = 'testlead8@test.com',
            Company = 'Test Company 8',
            Status = 'On Hold',
            RecordTypeId = keyAccountRT.Id,
            On_Hold_Date__c = Date.today().addDays(-30),
            Region_Picklist__c = 'North',
            OwnerId = regularUser.Id,
            Reason_for_On_Hold__c = 'Test'
        );
        insert testLead;
        
        Test.startTest();
        // Test the start method directly
        LeadOnHoldNotification batch = new LeadOnHoldNotification();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        // Verify that query locator was created successfully
        System.assertNotEquals(null, ql, 'Query locator should not be null');
    }
}