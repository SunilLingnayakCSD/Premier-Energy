/*public without sharing class getUserSpecificPromos {
    
    @AuraEnabled(cacheable=true)
    public static List<Promotional_Content__c> UserSpecificPromos() {
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId: ' + currentUserId);
        
        // Get Contact and AccountId
        Contact userContact = [
            SELECT AccountId 
            FROM Contact 
            WHERE Id = :[SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1].ContactId 
            LIMIT 1
        ];
        Id currentUserAccountId = userContact.AccountId;
        System.debug('currentUserAccountId: ' + currentUserAccountId);
        
        // Get User's Region1__c and split multi-picklist
        String regionStr = [SELECT Region1__c FROM User WHERE Id = :currentUserId].Region1__c;
        System.debug('Raw Region1__c: ' + regionStr);

        List<String> userRegions = new List<String>();
        if (!String.isBlank(regionStr)) {
            userRegions = regionStr.split(';');
        }
        System.debug('Parsed userRegions: ' + userRegions);
        
        // Get all promos matching any of the user regions
        List<Promotional_Content__c> allPromos = [
            SELECT Id,Name, Region__c, Type__c, Ongoing_Schemes__c
            FROM Promotional_Content__c
            WHERE Region__c IN :userRegions
            AND Distributor_Name__c = :currentUserAccountId
        ];
        System.debug('allPromos: ' + allPromos);

        // Filtering logic (can be simplified, kept as-is for clarity)
        List<Promotional_Content__c> result = new List<Promotional_Content__c>();
        for (Promotional_Content__c promo : allPromos) {
            if (promo.Type__c == 'Distributor') {
                result.add(promo);
            }
            else if (promo.Type__c == 'Region' || promo.Type__c == 'Central') {
                result.add(promo);
            }
        }
        System.debug('result: ' + result);
        return result;
    }
}*/

public without sharing class getUserSpecificPromos {
    
    @AuraEnabled(cacheable=true)
    public static List<Promotional_Content__c> UserSpecificPromos() {
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId: ' + currentUserId);
        
        // Get User details: Contact, AccountId, Region1__c
        User currentUser = [
            SELECT ContactId, Region1__c 
            FROM User 
            WHERE Id = :currentUserId
            LIMIT 1
        ];
        
        Contact userContact = [
            SELECT AccountId 
            FROM Contact 
            WHERE Id = :currentUser.ContactId
            LIMIT 1
        ];
        Id currentUserAccountId = userContact.AccountId;
        System.debug('currentUserAccountId: ' + currentUserAccountId);
        
        // Parse Region1__c multi-picklist
        List<String> userRegions = new List<String>();
        if (!String.isBlank(currentUser.Region1__c)) {
            userRegions = currentUser.Region1__c.split(';');
        }
        System.debug('Parsed userRegions: ' + userRegions);
        
        // Query all promo content of interest
        List<Promotional_Content__c> allPromos = [
            SELECT Id, Name, Region__c, Type__c, Ongoing_Schemes__c, Distributor_Name__c
            FROM Promotional_Content__c
            WHERE 
                ((Type__c = 'Distributor' AND Distributor_Name__c = :currentUserAccountId)
                OR
                (Type__c = 'Region' AND Region__c IN :userRegions)
                OR
                (Type__c = 'Central')) AND Active__c = true
        ];
        System.debug('Filtered Promos: ' + allPromos);

        return allPromos;
    }
}