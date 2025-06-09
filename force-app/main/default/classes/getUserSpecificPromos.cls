public without sharing class getUserSpecificPromos {
    
    @AuraEnabled(cacheable=true)
public static List<Promotional_Content__c> UserSpecificPromos() {
     Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId'+currentUserId);
        
        // Query the Contact record associated with the logged-in user
        Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :[SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1].ContactId LIMIT 1];
        
        // Get the AccountId from the Contact record
        Id currentUserAccountId = userContact.AccountId;
        System.debug('currentUserAccountId: ' + currentUserAccountId);
    
    // 1. Get current user's region (assumes it's stored on the User object)
    String userRegion = [SELECT Region__c FROM User WHERE Id = :currentUserId].Region__c;
    System.debug('userRegion'+userRegion);

    // 2. Fetch all Promo records for that region
    List<Promotional_Content__c> allPromos = [
        SELECT Id, Region__c, Type__c, Ongoing_Schemes__c
        FROM Promotional_Content__c
        WHERE Region__c = :userRegion
        AND Distributor_Name__c = :currentUserAccountId
    ];
    System.debug('allPromos'+allPromos);

    List<Promotional_Content__c> result = new List<Promotional_Content__c>();

    // 3. Apply layered condition logic
    for (Promotional_Content__c promo : allPromos) {
        if (promo.Type__c == 'Distributor') {
            result.add(promo);
        }
        else if ((promo.Type__c == 'Regional' || promo.Type__c == 'Central')) {
            result.add(promo);
        }
        else if ((promo.Type__c == 'Central' || promo.Type__c == 'Regional')) {
            result.add(promo); // priority to distributor
        }
        else if (promo.Type__c == 'Central') {
            result.add(promo); // final fallback
        }
    }
	System.debug('result'+result);
    return result;
}
}