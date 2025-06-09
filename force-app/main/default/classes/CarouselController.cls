// public with sharing class CarouselController {
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



public with sharing class CarouselController {
    @AuraEnabled(cacheable=true)
    public static List<String> getImageUrls() {
        List<Promotional_Content__c> promoRecords = [
            SELECT Id, Site_URL__c, Type__c 
            FROM Promotional_Content__c
            WHERE Site_URL__c != null
        ];

        // Create lists for each priority type
        List<String> centralImages = new List<String>();
        List<String> regionalImages = new List<String>();
        List<String> distributorImages = new List<String>();

        // Categorize images based on Type__c
        for (Promotional_Content__c promo : promoRecords) {
            if (promo.Site_URL__c != null) {
                if (promo.Type__c == 'Central') {
                    centralImages.add(promo.Site_URL__c);
                } else if (promo.Type__c == 'Region') {
                    regionalImages.add(promo.Site_URL__c);
                } else if (promo.Type__c == 'Distributor') {
                    distributorImages.add(promo.Site_URL__c);
                }
            }
        }

        // Return all images of the highest available priority
        if (!distributorImages.isEmpty()) {
            return distributorImages;  // Include all Site_URL__c from all Distributor records
        }
        if (!regionalImages.isEmpty()) {
            return regionalImages;  // Include all Site_URL__c from all Region records
        }
        return centralImages;  // Include all Site_URL__c from all Central records
    }
}