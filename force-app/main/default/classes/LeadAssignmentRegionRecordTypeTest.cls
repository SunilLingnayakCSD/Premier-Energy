@isTest
public class LeadAssignmentRegionRecordTypeTest {

    @testSetup
    static void setupData() {
        // Query required UserRoles
        //List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN ('Key_Account_International_Sales', 'Regional_Manager_Govt', 'Key_Account_Private_RM')];
        List<UserRole> roles = [
    SELECT Id, DeveloperName FROM UserRole 
    WHERE DeveloperName LIKE 'Key_Account_International_Sales'
       //OR DeveloperName LIKE 'Key_Account_Private_RM'
];

        
        Map<String, Id> roleMap = new Map<String, Id>();
        for (UserRole r : roles) {
            roleMap.put(r.DeveloperName, r.Id);
        }
        

        // Query a valid Profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        System.assertNotEquals(null, p, 'Standard User profile must exist.');

        // Create Users for each role
        List<User> users = new List<User>{
            new User(
                FirstName = 'Govt',
                LastName = 'User',
                Email = 'govtuser@test.com',
                Username = 'govtuser' + System.currentTimeMillis() + '@test.com',
                Alias = 'govtu',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                UserRoleId = roleMap.get('Regional_Manager_Govt'),
                IsActive = true,
                Region1__c = 'North'
            ),
            new User(
                FirstName = 'Intl',
                LastName = 'User',
                Email = 'intluser@test.com',
                Username = 'intluser' + System.currentTimeMillis() + '@test.com',
                Alias = 'intlusr',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                UserRoleId = roleMap.get('Key_Account_International_Sales'),
                IsActive = true
            ),
            new User(
                FirstName = 'Private',
                LastName = 'RM',
                Email = 'privrm@test.com',
                Username = 'privrm' + System.currentTimeMillis() + '@test.com',
                Alias = 'privrm',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                UserRoleId = roleMap.get('Key_Account_Private_RM'),
                IsActive = true,
                Region1__c = 'North'
            )
        };
        insert users;
    }

    @isTest
    static void testPrivateInternationalSalesAssignment() {
        Id privateRtId = getRecordTypeId('Key_Account_Private');
        System.assertNotEquals(null, privateRtId, 'RecordType Key_Account_Private must exist.');

        Lead l = new Lead(
            FirstName = 'Intl',
            LastName = 'Lead',
            Company = 'Company',
            Country = 'Germany',
            Region_Picklist__c = 'North',
            RecordTypeId = privateRtId
        );
        insert l;

        Map<Id, RecordType> rtMap = new Map<Id, RecordType>(
            [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']
        );

        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(new List<Lead>{l}, rtMap);
        Test.stopTest();

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(l.OwnerId, updatedLead.OwnerId, 'Owner should be assigned.');
    }

    @isTest
    static void testGovernmentAssignment() {
        Id govtRtId = getRecordTypeId('Key_Account_Government');
        System.assertNotEquals(null, govtRtId, 'RecordType Key_Account_Government must exist.');

        Lead l = new Lead(
            FirstName = 'Govt',
            LastName = 'Lead',
            Company = 'Company',
            Country = 'India',
            Region_Picklist__c = 'North',
            RecordTypeId = govtRtId
        );
        insert l;

        Map<Id, RecordType> rtMap = new Map<Id, RecordType>(
            [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']
        );

        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(new List<Lead>{l}, rtMap);
        Test.stopTest();

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(l.OwnerId, updatedLead.OwnerId, 'Owner should be reassigned for Govt case');
    }

    @isTest
    static void testPrivateRMAssignment() {
        Id privateRtId = getRecordTypeId('Key_Account_Private');
        System.assertNotEquals(null, privateRtId, 'RecordType Key_Account_Private must exist.');

        Lead l = new Lead(
            FirstName = 'Private',
            LastName = 'Lead',
            Company = 'Company',
            Country = 'India',
            Region_Picklist__c = 'North',
            RecordTypeId = privateRtId
        );
        insert l;

        Map<Id, RecordType> rtMap = new Map<Id, RecordType>(
            [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']
        );

        Test.startTest();
        LeadAssignmentBasedOnRegionAndRecordType.assignLeads(new List<Lead>{l}, rtMap);
        Test.stopTest();

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(l.OwnerId, updatedLead.OwnerId, 'Owner should be reassigned for Private RM case');
    }
    
    // no active user
    @isTest
static void testPrivateRMAssignment_NoActiveUser() {
    // Fetch roles
    List<UserRole> roles = [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN ('Regional_Manager_Govt')];
    Map<String, Id> roleMap = new Map<String, Id>();
    for (UserRole r : roles) {
        roleMap.put(r.DeveloperName, r.Id);
    }

    // Profile
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    System.assertNotEquals(null, p, 'Standard User profile must exist.');

    // Insert Inactive User
    User inactiveUser = new User(
        FirstName = 'Govt',
        LastName = 'User',
        Email = 'govtuser@test.com',
        Username = 'govtuser' + System.currentTimeMillis() + '@test.com',
        Alias = 'govtu',
        ProfileId = p.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        UserRoleId = roleMap.get('Regional_Manager_Govt'),
        IsActive = false, // Inactive user
        Region1__c = 'North'
    );
    insert inactiveUser;

    // RecordType
    Id privateRtId = getRecordTypeId('Key_Account_Private');
    System.assertNotEquals(null, privateRtId, 'RecordType Key_Account_Private must exist.');

    // Create Lead
    Lead l = new Lead(
        FirstName = 'Private',
        LastName = 'Lead',
        Company = 'Company',
        Country = 'India',
        Region_Picklist__c = 'North',
        RecordTypeId = privateRtId
    );
    insert l;

    Map<Id, RecordType> rtMap = new Map<Id, RecordType>(
        [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']
    );

    // Run assignment logic
    Test.startTest();
    LeadAssignmentBasedOnRegionAndRecordType.assignLeads(new List<Lead>{l}, rtMap);
    Test.stopTest();

    // Fetch updated lead
    Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :l.Id];

    // Assert OwnerId is different than the inactive user (or null or default Queue based on your implementation)
    System.assertNotEquals(inactiveUser.Id, updatedLead.OwnerId, 'Lead should not be assigned to an inactive user.');
}

    
    


    // Utility method to get RecordType Id by DeveloperName
    private static Id getRecordTypeId(String devName) {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = :devName LIMIT 1];
        return (rts.isEmpty()) ? null : rts[0].Id;
    }
    
}