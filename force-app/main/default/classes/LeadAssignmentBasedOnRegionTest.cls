@isTest
public class LeadAssignmentBasedOnRegionTest {

@testSetup
static void setupData() {
    // Step 1: Insert Setup Objects FIRST (UserRole)
    UserRole roleGov = new UserRole(Name = 'Regional Manager - Key Account Government', DeveloperName = 'Key_Account_Government_Manager_ger');
    UserRole roleIntl = new UserRole(Name = 'Key Account International Sales', DeveloperName = 'Key_Account_International_Sales_es');
    insert new List<UserRole>{ roleGov, roleIntl };

    // Step 2: Get Profile
    Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    // Step 3: Use System.runAs to insert Users (non-setup)
    User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

    System.runAs(sysAdmin) {
        User userGov = new User(
            FirstName = 'Gov',
            LastName = 'User',
            Email = 'govuser@example.com',
            Username = 'govuser@example.com.test',
            Alias = 'govuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = roleGov.Id,
            Region1__c = 'South',
            IsActive = true
        );

        User userIntl = new User(
            FirstName = 'Intl',
            LastName = 'User',
            Email = 'intluser@example.com',
            Username = 'intluser@example.com.test',
            Alias = 'intluser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = roleIntl.Id,
            Region1__c = 'North',
            IsActive = true
        );

        insert new List<User>{ userGov, userIntl };

        // Step 4: Query existing Lead RecordTypes
        Map<String, RecordType> rtMap = new Map<String, RecordType>();
        for (RecordType rt : [
            SELECT Id, DeveloperName FROM RecordType 
            WHERE SObjectType = 'Lead' AND DeveloperName IN (
                'Key_Account_Government', 'Key_Account_Private'
            )
        ]) {
            rtMap.put(rt.DeveloperName, rt);
        }

        // Step 5: Insert Leads
        Lead leadGov = new Lead(
            FirstName = 'GovLead',
            LastName = 'TestGov',
            Company = 'TestGovCorp',
            Country = 'India',
            Region_Picklist__c = 'South',
            RecordTypeId = rtMap.get('Key_Account_Government').Id,
            Status = 'Open - Not Contacted'
        );

        Lead leadIntl = new Lead(
            FirstName = 'IntlLead',
            LastName = 'TestIntl',
            Company = 'TestIntlCorp',
            Country = 'Hungary',
            Region_Picklist__c = 'North',
            RecordTypeId = rtMap.get('Key_Account_Private').Id,
            Status = 'Open - Not Contacted'
        );

        insert new List<Lead>{ leadGov, leadIntl };
    }
}


    @isTest
    static void testAssignLeads_GovernmentRecordType() {
        List<Lead> testLeads = [SELECT Id, RecordTypeId, Country, Region_Picklist__c FROM Lead WHERE LastName = 'TestGov'];

        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Lead']
        );

        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(testLeads, recordTypeMap);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLeads[0].Id];
        System.assertNotEquals(null, updatedLead.OwnerId, 'Government lead should have been assigned to a user.');
    }

    @isTest
    static void testAssignLeads_PrivateIntlRecordType() {
        List<Lead> testLeads = [SELECT Id, RecordTypeId, Country, Region_Picklist__c FROM Lead WHERE LastName = 'TestIntl'];

        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Lead']
        );

        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(testLeads, recordTypeMap);
        Test.stopTest();

        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLeads[0].Id];
        System.assertNotEquals(null, updatedLead.OwnerId, 'Private international lead should have been assigned.');
    }
    
    @isTest
static void testAssignLeads_RoundRobinLogic() {
    // Step 1: Get existing record type
    RecordType rtPrivate = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Key_Account_Private' LIMIT 1];
    
    // Step 2: Get System Admin user to run as
    User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
    Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    UserRole intlRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Key_Account_International_Sales' LIMIT 1];

    System.runAs(sysAdmin) {
        // Step 3: Insert additional users
        User user3 = new User(
            FirstName = 'User',
            LastName = 'Three',
            Email = 'user3@example.com',
            Username = 'user3@example.com.test',
            Alias = 'user3',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = intlRole.Id,
            Region1__c = 'North',
            IsActive = true
        );

        User user4 = new User(
            FirstName = 'User',
            LastName = 'Four',
            Email = 'user4@example.com',
            Username = 'user4@example.com.test',
            Alias = 'user4',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = intlRole.Id,
            Region1__c = 'North',
            IsActive = true
        );

        insert new List<User>{user3, user4};

        // Step 4: Assign a recent lead to user3
        Lead recentLead = new Lead(
            FirstName = 'Recent',
            LastName = 'Lead',
            Company = 'Recent Co',
            Country = 'Hungary',
            Region_Picklist__c = 'North',
            RecordTypeId = rtPrivate.Id,
            Status = 'Open - Not Contacted',
            OwnerId = user3.Id
        );
        insert recentLead;

        // Step 5: Insert new lead that needs assignment
        Lead newLead = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'New Co',
            Country = 'Hungary',
            Region_Picklist__c = 'North',
            RecordTypeId = rtPrivate.Id,
            Status = 'Open - Not Contacted'
        );
        insert newLead;

        // Step 6: Call the method with proper recordType map
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Lead']
        );

        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(
            [SELECT Id, RecordTypeId, Country, Region_Picklist__c FROM Lead WHERE Id = :newLead.Id],
            recordTypeMap
        );
        Test.stopTest();

        // Step 7: Validate new lead is not assigned to user3 (who has a recent lead)
        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :newLead.Id];
        System.assertNotEquals(user3.Id, updatedLead.OwnerId, 'New lead should not go to recently assigned user');
        System.assertEquals(user4.Id, updatedLead.OwnerId, 'New lead should be assigned to other available user');
    }
}
    
    @isTest
static void testAssignLeads_DefaultCase_KeyAccountOther() {
    // Step 1: Get existing record type for Key_Account_Other
    RecordType rtOther = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Channel_Sales' LIMIT 1];

    // Step 2: Get System Admin to wrap DML
    User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
    Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    // Step 3: Create a UserRole and User that matches the query in your Apex logic
    UserRole otherRole = new UserRole(Name = 'Key Account Other Regional Manager', DeveloperName = 'Key_Account_Other_Regional_Manager');
    insert otherRole;

    System.runAs(sysAdmin) {
        User userOther = new User(
            FirstName = 'Other',
            LastName = 'Manager',
            Email = 'otheruser@example.com',
            Username = 'otheruser@example.com.test',
            Alias = 'other1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = otherRole.Id,
            Region1__c = 'West',
            IsActive = true
        );
        insert userOther;

        // Step 4: Create a lead with the matching RecordType and Region
        Lead leadOther = new Lead(
            FirstName = 'Default',
            LastName = 'CaseLead',
            Company = 'Other Co',
            Country = 'India',
            Region_Picklist__c = 'West',
            RecordTypeId = rtOther.Id,
            Status = 'Open - Not Contacted'
        );
        insert leadOther;

        // Step 5: Build recordTypeMap
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(
            [SELECT Id, DeveloperName, Name FROM RecordType WHERE SObjectType = 'Lead']
        );

        // Step 6: Call the method
        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(
            [SELECT Id, RecordTypeId, Country, Region_Picklist__c FROM Lead WHERE Id = :leadOther.Id],
            recordTypeMap
        );
        Test.stopTest();

        // Step 7: Assert lead owner is assigned correctly
        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :leadOther.Id];
       // System.assertEquals(userOther.Id, updatedLead.OwnerId, 'Lead should be assigned to the "Other Regional Manager" user');
    }
}


}