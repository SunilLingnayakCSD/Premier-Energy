@isTest
public class ContentDocumentLinkTriggerTest {
    
    @isTest(SeeAllData=true)
    static void testContentDocumentLinkTrigger() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a ContentVersion (this automatically creates ContentDocument after insert)
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is test content')
        );
        insert cv;

        // Retrieve the related ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Create the ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V' // Viewer
            // Note: We do NOT set Visibility here to test if trigger sets it to 'AllUsers'
        );
        insert cdl;
        
        // Fetch the inserted ContentDocumentLink and verify the Visibility
        ContentDocumentLink insertedCDL = [SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :cdl.Id];
        System.assertEquals('AllUsers', insertedCDL.Visibility, 'Visibility should be set to AllUsers by the trigger.');
    }
}