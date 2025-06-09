@isTest
private class ACcountUIControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a test Account
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '9876543210',
            Type = 'Customer',
            Industry = 'Manufacturing',
            BillingStreet = '123 Test Street',
            BillingCity = 'Test City',
            BillingState = 'Andhra Pradesh',
            BillingPostalCode = '123456',
            BillingCountry = 'India',
            Website = 'https://www.testaccount.com',
            Email__c = 'testaccount@example.com',
            Logo__c = 'TestLogo.png',
            image__c = null // intentionally null to test content doc logic
        );
        insert acc;

        // Create a ContentVersion (to simulate file upload)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Image',
            PathOnClient = 'TestImage.png',
            VersionData = Blob.valueOf('Test image content')
        );
        insert cv;

        // Retrieve ContentDocumentId from inserted ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Create ContentDocumentLink to link file with Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );
        insert cdl;
    }

    @isTest
    static void testGetAccountDetailsWithImage() {
        // Get test Account Id
        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Account result = ACcountUIController.getAccountDetails(testAcc.Id);
        Test.stopTest();

        // Validate the returned Account details
        System.assertNotEquals(null, result);
        System.assertEquals('Test Account', result.Name);
        System.assertEquals('9876543210', result.Phone);
        System.assertEquals('Customer', result.Type);
        System.assertEquals('Manufacturing', result.Industry);
        System.assertEquals('123 Test Street', result.BillingStreet);
        System.assertNotEquals(null, result.image__c, 'image__c should be populated from ContentDocumentLink');
        System.assert(result.image__c.contains('/sfc/servlet.shepherd/version/download/'), 'image__c URL should contain shepherd path');
    }

    @isTest
    static void testGetAccountDetailsWithoutContentDocument() {
        // Create an account without ContentDocumentLink
        Account accNoFile = new Account(
            Name = 'No File Account',
            image__c = null
        );
        insert accNoFile;

        Test.startTest();
        Account result = ACcountUIController.getAccountDetails(accNoFile.Id);
        Test.stopTest();

        // Validate Account details
        System.assertNotEquals(null, result);
        System.assertEquals('No File Account', result.Name);
        System.assertEquals(null, result.image__c, 'image__c should remain null when no ContentDocumentLink exists');
    }
}