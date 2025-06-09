public with sharing class ContactUIController {
    @AuraEnabled(cacheable=true)
    public static Contact getContactDetails(Id recordId) {
        try {
            Contact contactRec = [
                SELECT Id, Name, Email, Phone, MailingStreet,MailingCity,MailingState,MailingPostalCode,MailingCountry, Image__c,Customer_Since__c
                FROM Contact 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            
            if (String.isEmpty(contactRec.Image__c)) {
                try {
                    ContentDocumentLink cdl = [
                        SELECT ContentDocument.LatestPublishedVersionId 
                        FROM ContentDocumentLink 
                        WHERE LinkedEntityId = :recordId
                        ORDER BY ContentDocument.LastModifiedDate DESC 
                        LIMIT 1
                    ];
                    
                    if (cdl != null) {
                        // Clone Contact to update field
                        contactRec = contactRec.clone(false, true, false);
                        contactRec.Image__c = '/sfc/servlet.shepherd/version/download/' + cdl.ContentDocument.LatestPublishedVersionId;
                    }
                } catch (Exception e) {
                    System.debug('Error fetching Content Document for Contact: ' + e.getMessage());
                }
            }

            return contactRec;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Contact details: ' + e.getMessage());
        }
    }
}