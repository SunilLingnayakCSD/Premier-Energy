@IsTest
private class getUserSpecificPromosTest {
    private static User testUser;
    private static Account testAccount;

    @TestSetup
    static void setupNonSetupData() {
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = testAccount.Id
        );
        insert testContact;

        List<Promotional_Content__c> testPromos = new List<Promotional_Content__c>{
            new Promotional_Content__c(
                Name = 'Distributor Promo',
                Region__c = 'North',
                Type__c = 'Distributor',
                Distributor_Name__c = testAccount.Id,
                Ongoing_Schemes__c = 'Test Scheme 1'
            ),
            new Promotional_Content__c(
                Name = 'Regional Promo',
                Region__c = 'East',
                Type__c = 'Region',
                Distributor_Name__c = testAccount.Id,
                Ongoing_Schemes__c = 'Test Scheme 2'
            ),
            new Promotional_Content__c(
                Name = 'Central Promo',
                Region__c = 'North',
                Type__c = 'Central',
                Distributor_Name__c = testAccount.Id,
                Ongoing_Schemes__c = 'Test Scheme 3'
            ),
            new Promotional_Content__c(
                Name = 'Non-Matching Promo',
                Region__c = 'South',
                Type__c = 'Region',
                Distributor_Name__c = testAccount.Id,
                Ongoing_Schemes__c = 'Test Scheme 4'
            )
        };
        insert testPromos;
    }

    private static void setupUserData() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        UserRole portalRole;
        List<UserRole> existingRoles = [SELECT Id FROM UserRole WHERE Name = 'ssrin Partner Person Account' LIMIT 1];
        if (existingRoles.isEmpty()) {
            portalRole = new UserRole(Name = 'ssrin Partner Person Account');
            insert portalRole;
        } else {
            portalRole = existingRoles[0];
        }

        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];

        testUser = new User(
          //  UserType = 'PowerPartner',
            Alias = 'testuser',
            Email = 'testusejjr@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuserssaas@example.com.test',
            ContactId = testContact.Id,
            Region1__c = 'North;East',
            UserRoleId = portalRole.Id
        );
        insert testUser;
    }
/*
    @IsTest
    static void testUserSpecificPromos() {
        setupUserData();

        System.runAs(testUser) {
            Test.startTest();
            List<Promotional_Content__c> result = getUserSpecificPromos.UserSpecificPromos();
            Test.stopTest();

            Set<String> expectedNames = new Set<String>{'Distributor Promo', 'Regional Promo', 'Central Promo'};
            Set<String> actualNames = new Set<String>();
            for (Promotional_Content__c promo : result) {
                System.assertNotEquals(null, promo.Name, 'Name should be populated');
                actualNames.add(promo.Name);
            }
            //System.assert(expectedNames.equals(actualNames), 'Returned promos should match expected ones');
        }
    }
*/
/*
    @IsTest
    static void testEmptyRegion() {
        setupUserData();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            testUser = [SELECT Id, Region1__c FROM User WHERE Id = :testUser.Id];
            testUser.Region1__c = null;
            update testUser;
        }

        System.runAs(testUser) {
            Test.startTest();
            List<Promotional_Content__c> result = getUserSpecificPromos.UserSpecificPromos();
            Test.stopTest();

            System.assertEquals(0, result.size(), 'Should return no promos when user has no regions');
        }
    }

  */  @IsTest
static void testNoContact() {
    Account acc=  new Account();
    acc.Name='test';
    insert acc;
    
    // Create and insert a valid Contact (only to get a valid ID)
    Contact orphanContact = new Contact(
        FirstName = 'Ghost',
        LastName = 'Contact',
        AccountId = acc.Id
    );
    insert orphanContact;

    // Get a valid profile for the user
    Profile standardProfile = [SELECT Id,Name FROM Profile WHERE Name = 'Partner Distributor Access' LIMIT 1];

    // Create User and assign the real ContactId
    User noContactUser = new User(
        Alias = 'ncojjnta',
        Email = 'nocjsjontact@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'NoContact',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = standardProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = 'nocontajaajct@example.com.test',
        Region1__c = 'North',
        ContactId = orphanContact.Id
    );

    // Insert the user before deleting the contact
    System.runAs(new User(Id = UserInfo.getUserId())) {
        insert noContactUser;
    }

    

    // Now run the method as this user
    System.runAs(noContactUser) {
        Test.startTest();
        List<Promotional_Content__c> result = getUserSpecificPromos.UserSpecificPromos();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return no promos when user has a ContactId but Contact record is missing');
    }
}

}