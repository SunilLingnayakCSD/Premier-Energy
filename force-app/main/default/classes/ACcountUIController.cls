public class ACcountUIController {
	@AuraEnabled(cacheable=true)
   public static Account getAccountDetails(Id recordId) {
        Account acc = [
            SELECT Name, Phone, Type, Industry, BillingStreet, BillingCity, BillingState, Email__c,
                   BillingPostalCode, BillingCountry, Website, Logo__c, image__c
            FROM Account 
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        // If image__c is empty, fetch the latest Content Document and set its URL
        if (String.isEmpty(acc.image__c)) {
            try {
                ContentDocumentLink cdl = [
                    SELECT ContentDocument.LatestPublishedVersionId 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :recordId
                    ORDER BY ContentDocument.LastModifiedDate DESC 
                    LIMIT 1
                ];
                
                if (cdl != null) {
                    acc.image__c = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
                }
            } catch (Exception e) {
                System.debug('Error fetching Content Document: ' + e.getMessage());
            }
        }
        
        return acc;
    }
}