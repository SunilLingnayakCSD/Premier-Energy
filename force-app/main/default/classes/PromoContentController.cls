/**
* @File Name : PromoContentController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : April 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 3, 2025 |   | Initial Version
**/

// public with sharing class PromoContentController {
//     @AuraEnabled(cacheable=true)
//     public static List<String> getImageUrls() {
//         List<Promotional_Content__c> promoRecords = [
//             SELECT Id, Image_URL__c, Type__c, Site_URL__c 
//             FROM Promotional_Content__c
//         ];

//         List<String> centralImages = new List<String>();
//         List<String> regionalImages = new List<String>();
//         List<String> distributorImages = new List<String>();

//         for (Promotional_Content__c promo : promoRecords) {
//             if (promo.Site_URL__c != null) {
//                 if (promo.Type__c == 'Central') {
//                     centralImages.add(promo.Site_URL__c);
//                 } else if (promo.Type__c == 'Region') {
//                     regionalImages.add(promo.Site_URL__c);
//                 } else if (promo.Type__c == 'Distributor') {
//                     distributorImages.add(promo.Site_URL__c);
//                 }
//             }
//         }

       
//         if (centralImages.isEmpty()) {
//             return new List<String>();
//         }

        
//         if (!distributorImages.isEmpty()) {
//             return distributorImages;
//         }
//         if (!regionalImages.isEmpty()) {
//             return regionalImages;
//         }
//         return centralImages;
//     }
// }




// public with sharing class PromoContentController {
//     @AuraEnabled(cacheable=true)
//     public static List<String> getImageUrls() {
//         List<Promotional_Content__c> promoRecords = [
//             SELECT Id, Image_URL__c, Site_URL__c, Type__c 
//             FROM Promotional_Content__c
//         ];

//         List<String> centralImages = new List<String>();
//         List<String> regionalImages = new List<String>();
//         List<String> distributorImages = new List<String>();

//         for (Promotional_Content__c promo : promoRecords) {
//             if (promo.Site_URL__c != null) {
//                 if (promo.Type__c == 'Central') {
//                     centralImages.add(promo.Site_URL__c);
//                 } else if (promo.Type__c == 'Region') {
//                     regionalImages.add(promo.Site_URL__c);
//                 } else if (promo.Type__c == 'Distributor') {
//                     distributorImages.add(promo.Site_URL__c);
//                 }
//             }
//         }

        
//         if (centralImages.isEmpty()) {
//             return new List<String>();
//         }


//         if (!distributorImages.isEmpty()) {
//             return distributorImages;
//         }
//         if (!regionalImages.isEmpty()) {
//             return regionalImages;
//         }
//         return centralImages;
//     }
// }


public without sharing class PromoContentController {
    @AuraEnabled(cacheable=true)
    public static List<String> getImageBase64() {
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        Boolean isAdmin = profileName == 'System Administrator';

        if (profileName != 'Partner Distributor Access' && !isAdmin) {
            System.debug('Access Denied: Profile - ' + profileName);
            return new List<String>();
        }

        // Fetch all records of interest
        List<Promotional_Content__c> promoRecords = [
            SELECT Id, Type__c,
                (SELECT ContentDocumentId FROM ContentDocumentLinks)
            FROM Promotional_Content__c
            WHERE Type__c IN ('Distributor', 'Region', 'Central')
        ];

        // Check if there's at least one Central record
        Boolean hasCentral = false;
        for (Promotional_Content__c rec : promoRecords) {
            if (rec.Type__c == 'Central') {
                hasCentral = true;
                break;
            }
        }

        if (!hasCentral) {
            System.debug('No Central record found. Returning no images.');
            return new List<String>();
        }

        List<String> finalImages = new List<String>();
        Set<String> addedDocs = new Set<String>();
        List<String> typePriority = new List<String>{'Distributor', 'Region', 'Central'};

        for (String type : typePriority) {
            for (Promotional_Content__c promo : promoRecords) {
                if (promo.Type__c != type) continue;

                for (ContentDocumentLink docLink : promo.ContentDocumentLinks) {
                    if (addedDocs.contains(docLink.ContentDocumentId)) continue;

                    List<ContentVersion> versions = [
                        SELECT VersionData, FileExtension
                        FROM ContentVersion
                        WHERE ContentDocumentId = :docLink.ContentDocumentId
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];

                    if (!versions.isEmpty()) {
                        ContentVersion version = versions[0];
                        String base64Image = 'data:image/' + version.FileExtension + ';base64,' +
                                             EncodingUtil.base64Encode(version.VersionData);
                        finalImages.add(base64Image);
                        addedDocs.add(docLink.ContentDocumentId);
                    }
                }
            }

            if (!finalImages.isEmpty()) {
                System.debug('Images found for type: ' + type + ', Count: ' + finalImages.size());
                break;
            }
        }

        System.debug('Total images returned: ' + finalImages.size());
        return finalImages;
    }
}





// public without sharing class PromoContentController {
//     @AuraEnabled(cacheable=true)
//     public static List<String> getImageUrls() {
//         String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
//         Boolean isAdmin = profileName == 'System Administrator';

//         if (profileName != 'Partner Distributor Access' && !isAdmin) {
//             return new List<String>();
//         }

//         List<String> typePriority = new List<String>{'Distributor', 'Region', 'Central'};
//         Set<String> seenUrls = new Set<String>();
//         List<String> finalImages = new List<String>();

//         for (String type : typePriority) {
//             List<Promotional_Content__c> promos = [
//                 SELECT Site_URL__c 
//                 FROM Promotional_Content__c 
//                 WHERE Type__c = :type AND Site_URL__c != null
//             ];

//             for (Promotional_Content__c promo : promos) {
//                 String url = promo.Site_URL__c.trim();
//                 if (!seenUrls.contains(url)) {
//                     seenUrls.add(url);
//                     finalImages.add(url);
//                 }
//             }

//             if (!finalImages.isEmpty()) {
//                 return finalImages;
//             }
//         }

//         return new List<String>();
//     }
// }