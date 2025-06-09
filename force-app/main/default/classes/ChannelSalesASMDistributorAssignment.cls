public class ChannelSalesASMDistributorAssignment {

   // Method to validate and restrict based on conditions
    public static void validateAndRestrict(List<Lead> leadList) {
        Set<String> regionSet = new Set<String>();
        Map<String, String> profileMap = getUserProfileMap();

        // Fetch RecordType information to avoid using Name directly
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName ='Channel_Sales']) {
            recordTypeMap.put(rt.Id, rt.DeveloperName);
        }

        // Collecting regions to query matching ASM users
        for (Lead lead : leadList) {
           
                regionSet.add(lead.Region_Picklist__c);
            
        }

        // Query to find ASM users matching lead region
        Map<String, User> asmUserMap = new Map<String, User>();
        List<User> asmUsers = [SELECT Id, Region__c, Profile.Name 
                               FROM User 
                               WHERE Region__c IN :regionSet AND Profile.Name = 'Channel Sales ASM'];

        for (User u : asmUsers) {
            asmUserMap.put(u.Region__c, u);
        }

        // Loop through leads to apply business logic
        for (Lead lead : leadList) {
            if (recordTypeMap.get(lead.RecordTypeId) == 'Channel_Sales') {
                String userProfile = profileMap.get(UserInfo.getUserId());

                // Check if the current user is a Region Head
                if (userProfile == 'Channel Sales East Region Head' ||
                    userProfile == 'Channel Sales North Region Head' ||
                    userProfile == 'Channel Sales South Region Head' ||
                    userProfile == 'Channel Sales West Region Head') {

                    Boolean isASMAvailable = asmUserMap.containsKey(lead.Region_Picklist__c);

                    // 🚨 Case 1: ASM available - Block Distributor__c assignment
                    if (isASMAvailable) {
                        if (lead.Distributor__c != null) {
                            lead.addError('ASM is available for this region. You cannot assign a Distributor.');
                        }
                    }
                    // ✅ Case 2: No ASM available - Block ASM__c assignment and allow only Distributor__c
                    else {
                        if (lead.ASM__c != null) {
                            lead.addError('No ASM found for this region. Assign a Distributor instead.');
                        }
                    }
                }
            }
        }
    }

    // Method to share lead records with the selected user
    public static void shareLeadRecords(List<Lead> leadList) {
        List<LeadShare> leadShares = new List<LeadShare>();

        for (Lead lead : leadList) {
            // Check if record type is 'Channel_Sales'
            if (lead.RecordTypeId != null) {
                Id userIdToShare;

                // Share with ASM if available, else with Distributor
                if (lead.ASM__c != null) {
                    userIdToShare = lead.ASM__c;
                } else if (lead.Distributor__c != null) {
                    userIdToShare = lead.Distributor__c;
                } else {
                    continue; // No user to share with
                }

                LeadShare ls = new LeadShare();
                ls.LeadId = lead.Id;
                ls.UserOrGroupId = userIdToShare;
                ls.LeadAccessLevel = 'Edit';
                ls.RowCause = Schema.LeadShare.RowCause.Manual;
                leadShares.add(ls);
            }
        }

        if (!leadShares.isEmpty()) {
            Database.insert(leadShares, false);
        }
    }

    // Helper method to get the current user's profile
    public static Map<String, String> getUserProfileMap() {
        Map<String, String> profileMap = new Map<String, String>();
        for (User u : [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()]) {
            profileMap.put(u.Id, u.Profile.Name);
        }
        return profileMap;
    }
}