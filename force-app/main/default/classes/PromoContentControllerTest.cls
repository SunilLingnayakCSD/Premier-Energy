@isTest
private class PromoContentControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test profiles
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test users (standard users only - no portal users)
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'admin@test.com',
            Username = 'admin@test.com.' + DateTime.now().getTime(),
            Alias = 'admin',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = adminProfile.Id
        );
        
        User standardUser = new User(
            FirstName = 'Standard',
            LastName = 'User',
            Email = 'standard@test.com',
            Username = 'standard@test.com.' + DateTime.now().getTime(),
            Alias = 'standard',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = standardProfile.Id
        );
        
        insert new List<User>{adminUser, standardUser};
        
        // Create test promotional content records
        List<Promotional_Content__c> promoContents = new List<Promotional_Content__c>{
            new Promotional_Content__c(Type__c = 'Central'),
            new Promotional_Content__c(Type__c = 'Region'),
            new Promotional_Content__c(Type__c = 'Distributor')
        };
        insert promoContents;
        
        // Create test content versions and links
        ContentVersion centralImage = new ContentVersion(
            Title = 'Central Image',
            PathOnClient = 'central.jpg',
            VersionData = Blob.valueOf('Test Central Image'),
            IsMajorVersion = true
        );
        ContentVersion regionImage = new ContentVersion(
            Title = 'Region Image',
            PathOnClient = 'region.jpg',
            VersionData = Blob.valueOf('Test Region Image'),
            IsMajorVersion = true
        );
        ContentVersion distributorImage = new ContentVersion(
            Title = 'Distributor Image',
            PathOnClient = 'distributor.jpg',
            VersionData = Blob.valueOf('Test Distributor Image'),
            IsMajorVersion = true
        );
        insert new List<ContentVersion>{centralImage, regionImage, distributorImage};
        
        // Get content document IDs
        centralImage = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :centralImage.Id];
        regionImage = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :regionImage.Id];
        distributorImage = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :distributorImage.Id];
        
        // Link content to promotional content records
        List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = centralImage.ContentDocumentId,
                LinkedEntityId = promoContents[0].Id,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                ContentDocumentId = regionImage.ContentDocumentId,
                LinkedEntityId = promoContents[1].Id,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                ContentDocumentId = distributorImage.ContentDocumentId,
                LinkedEntityId = promoContents[2].Id,
                ShareType = 'V'
            )
        };
        insert docLinks;
    }
    
    @isTest
    static void testAdminUserAccess() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            List<String> images = PromoContentController.getImageBase64();
            Test.stopTest();
            
            System.assert(!images.isEmpty(), 'Admin user should have access to images');
        }
    }
    
    @isTest
    static void testStandardUserAccessDenied() {
        User standardUser = [SELECT Id FROM User WHERE Email = 'standard@test.com' LIMIT 1];
        System.runAs(standardUser) {
            Test.startTest();
            List<String> images = PromoContentController.getImageBase64();
            Test.stopTest();
            
            System.assert(images.isEmpty(), 'Standard user should not have access to images');
        }
    }
    
    @isTest
    static void testNoCentralContent() {
        // Delete central content for this test
        delete [SELECT Id FROM Promotional_Content__c WHERE Type__c = 'Central' LIMIT 1];
        
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            List<String> images = PromoContentController.getImageBase64();
            Test.stopTest();
            
            System.assert(images.isEmpty(), 'Should return no images when no Central content exists');
        }
    }
    
    @isTest
    static void testPriorityOrder() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            List<String> images = PromoContentController.getImageBase64();
            Test.stopTest();
            
        }
    }
    
    @isTest
    static void testImageFormatting() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            List<String> images = PromoContentController.getImageBase64();
            Test.stopTest();
            
            System.assert(images[0].startsWith('data:image/jpg;base64,'), 'Image should be properly formatted as base64');
        }
    }
    
    @isTest
    static void testNoContentDocuments() {
        // Remove all content document links for this test
        delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Promotional_Content__c)];
        
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            List<String> images = PromoContentController.getImageBase64();
            Test.stopTest();
            
            System.assert(images.isEmpty(), 'Should return no images when no content documents exist');
        }
    }
}