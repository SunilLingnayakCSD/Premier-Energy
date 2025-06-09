@isTest
public class ContactUIControllerTest {

    @isTest
    static void testGetContactDetails_WithImageFieldSet() {
        // Contact with Image__c already set - should skip ContentDocumentLink logic
        Contact contactWithImage = new Contact(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'test1@example.com',
            Image__c = 'someimageurl'
        );
        insert contactWithImage;

        Test.startTest();
        Contact result = ContactUIController.getContactDetails(contactWithImage.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(contactWithImage.Id, result.Id);
        System.assertEquals('someimageurl', result.Image__c, 'Image__c should remain unchanged');
    }

    @isTest
    static void testGetContactDetails_WithEmptyImageFieldAndContentDocument() {
        // Contact with empty Image__c, must hit ContentDocumentLink query and update Image__c via cloning
        Contact contactWithoutImage = new Contact(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'test2@example.com'
        );
        insert contactWithoutImage;

        // Create ContentVersion (this automatically creates ContentDocument)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestFile';
        cv.PathOnClient = 'TestFile.png';
        cv.VersionData = Blob.valueOf('Test Content');
        insert cv;

        // Wait for ContentDocumentId to be assigned and query ContentDocument via ContentVersion
        ContentVersion cvWithDoc = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Defensive check: If ContentDocumentId is null, fail test early
        System.assertNotEquals(null, cvWithDoc.ContentDocumentId, 'ContentDocumentId must not be null after insert');

        // Link ContentDocument to Contact
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cvWithDoc.ContentDocumentId,
            LinkedEntityId = contactWithoutImage.Id,
            ShareType = 'V' // Viewer permission
        );
        insert cdl;

        Test.startTest();
        Contact result = ContactUIController.getContactDetails(contactWithoutImage.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
       

        // Verify Image__c is populated with the download URL prefix
        System.assert(result.Image__c != null, 'Image__c should be populated');
        System.assert(result.Image__c.startsWith('/sfc/servlet.shepherd/version/download/'),
            'Image__c should contain the download URL');
    }

    @isTest
    static void testGetContactDetails_WithEmptyImageFieldAndNoContentDocument() {
        // Contact with empty Image__c but no related ContentDocumentLink - test the catch block path
        Contact contactNoDoc = new Contact(
            FirstName = 'Test',
            LastName = 'User3',
            Email = 'test3@example.com'
        );
        insert contactNoDoc;

        Test.startTest();
        Contact result = ContactUIController.getContactDetails(contactNoDoc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(contactNoDoc.Id, result.Id);

        // Image__c should remain null because no ContentDocumentLink found
        System.assertEquals(null, result.Image__c, 'Image__c should remain null');
    }

    @isTest
    static void testGetContactDetails_NoContactFound() {
        // Test with invalid Id to ensure exception is thrown and handled properly
        Id fakeId = Id.valueOf('003000000000000AAA'); // Contact Id prefix is '003'

        try {
            Test.startTest();
            ContactUIController.getContactDetails(fakeId);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException ex) {
            
        }
    }
}