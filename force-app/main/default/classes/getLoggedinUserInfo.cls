public class getLoggedinUserInfo {
	   @AuraEnabled(cacheable=true)
    public static String getUserProfileName(String userId){
       Id profileId = [SELECT ProfileId FROM User WHERE Id = :userId].ProfileId;
       String profilename =[SELECT Name FROM Profile WHERE Id = :profileId].Name;
        return profilename;
    }
}