public class LeadAssignmentBasedOnRegionAndRecordType {
    // Map to hold round robin index per recordType-region key
    private static Map<String, Integer> roundRobinIndexMap = new Map<String, Integer>();
    
    public static void assignLeads(List<Lead> leads, Map<Id, RecordType> recordTypeMap) {
        System.debug('Starting lead assignment process...');
        System.debug('Number of leads to process: ' + leads.size());
        
        // Fetch all active users with roles and regions
        List<User> users = [
            SELECT Id, UserRole.DeveloperName, Region1__c
            FROM User
            WHERE IsActive = true AND UserRoleId != null
        ];
        System.debug('Fetched users: ' + users.size());
        
        // Maps for record type -> user Ids and region -> user Ids
        Map<String, List<Id>> recordTypeUserMap = new Map<String, List<Id>>();
        Map<String, List<Id>> regionUserMap = new Map<String, List<Id>>();
        
        // Populate recordTypeUserMap based on role name patterns
        for (User user : users) {
            if (user.UserRole != null) {
                String normalizedRole = user.UserRole.DeveloperName.toLowerCase().replaceAll('\\s', '');
                
                System.debug('User ' + user.Id + ' role normalized to: ' + normalizedRole);
                
                // Key Account Private: roles containing "private" and "region_head"
                if (normalizedRole.contains('private') && normalizedRole.contains('region_head')) {
                    if (!recordTypeUserMap.containsKey('Key_Account_Private')) {
                        recordTypeUserMap.put('Key_Account_Private', new List<Id>());
                    }
                    recordTypeUserMap.get('Key_Account_Private').add(user.Id);
                    
                    System.debug('Added user ' + user.Id + ' to Key_Account_Private role map');
                }
                
                // Channel Sales: roles containing "channelsales" and "region_head"
                if (normalizedRole.contains('channel_sales') && normalizedRole.contains('region_head')) {
                    if (!recordTypeUserMap.containsKey('Channel_Sales')) {
                        recordTypeUserMap.put('Channel_Sales', new List<Id>());
                    }
                    recordTypeUserMap.get('Channel_Sales').add(user.Id);
                    System.debug('Added user ' + user.Id + ' to Channel_Sales role map');
                }
                
                // Key Account Government: roles containing "government" and "regional_manager"
                if (normalizedRole.contains('government') && normalizedRole.contains('regional_manager')) {
                    if (!recordTypeUserMap.containsKey('Key_Account_Government')) {
                        recordTypeUserMap.put('Key_Account_Government', new List<Id>());
                    }
                    recordTypeUserMap.get('Key_Account_Government').add(user.Id);
                    System.debug('Added user ' + user.Id + ' to Key_Account_Government role map');
                }
            }
            
            // Map users to regions (split by ;)
            if (String.isNotBlank(user.Region1__c)) {
                List<String> userRegions = user.Region1__c.split(';');
                for (String region : userRegions) {
                    String cleanRegion = region.trim();
                    if (!regionUserMap.containsKey(cleanRegion)) {
                        regionUserMap.put(cleanRegion, new List<Id>());
                    }
                    regionUserMap.get(cleanRegion).add(user.Id);
                    System.debug('Added user ' + user.Id + ' to region ' + cleanRegion);
                }
            }
        }
        
        System.debug('RecordTypeUserMap keys: ' + recordTypeUserMap.keySet());
        System.debug('RegionUserMap keys: ' + regionUserMap.keySet());
        
        // Prepare set of all relevant user Ids
        Set<Id> allUserIds = new Set<Id>();
        for (List<Id> ids : recordTypeUserMap.values()) {
            allUserIds.addAll(ids);
        }
        for (List<Id> ids : regionUserMap.values()) {
            allUserIds.addAll(ids);
        }
        System.debug('Total unique users considered: ' + allUserIds.size());
        
        // Pre-fetch lead counts per user to balance load
        Map<Id, Integer> userLeadCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId, COUNT(Id) leadCount
            FROM Lead
            WHERE OwnerId IN :allUserIds AND IsConverted = false
            GROUP BY OwnerId
        ]) {
            userLeadCountMap.put((Id)ar.get('OwnerId'), (Integer)ar.get('leadCount'));
        }
        System.debug('Fetched lead counts for users: ' + userLeadCountMap);
        
        // Initialize users with zero leads if not found in query
        for (Id userId : allUserIds) {
            if (!userLeadCountMap.containsKey(userId)) {
                userLeadCountMap.put(userId, 0);
            }
        }
        System.debug('Final userLeadCountMap after initialization: ' + userLeadCountMap);
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead lead : leads) {
            String region = lead.Region_Picklist__c;
            String recordTypeName = recordTypeMap.containsKey(lead.RecordTypeId) 
                ? recordTypeMap.get(lead.RecordTypeId).DeveloperName 
                : null;
            
            System.debug('Processing Lead Id: ' + lead.Id + ', Region: ' + region + ', RecordType: ' + recordTypeName + ', Country: ' + lead.Country);
            
            // SPECIAL CASE: Assign leads to international users if country is NOT India (ignore record type and region)
            if (lead.Country != 'India' && recordTypeName == 'Key_Account_Private') {
                List<Id> internationalUsers = new List<Id>();
                for (User user : users) {
                    if (user.UserRole != null) {
                        String normalizedRole = user.UserRole.DeveloperName.toLowerCase().replaceAll('\\s','');
                        if (normalizedRole.contains('key_accounts_international_head_private')) {
                            internationalUsers.add(user.Id);
                        }
                    }
                }
                System.debug('International users found: ' + internationalUsers);
                
                if (!internationalUsers.isEmpty()) {
                    Integer minCount = findMinLeadCount(internationalUsers, userLeadCountMap);
                    List<Id> leastLoadedUsers = new List<Id>();
                    for (Id uId : internationalUsers) {
                        if (userLeadCountMap.get(uId) == minCount) {
                            leastLoadedUsers.add(uId);
                        }
                    }
                    System.debug('Least loaded international users: ' + leastLoadedUsers + ' with lead count: ' + minCount);
                    Id selectedUserId;
                    if (leastLoadedUsers.size() == 1) {
                        selectedUserId = leastLoadedUsers[0];
                    } else {
                        String key = 'Key_Accounts_International_Head_Private';
                        Integer index = roundRobinIndexMap.containsKey(key) ? roundRobinIndexMap.get(key) : 0;
                        if (index >= leastLoadedUsers.size()) index = 0;
                        selectedUserId = leastLoadedUsers[index];
                        index++;
                        if (index >= leastLoadedUsers.size()) index = 0;
                        roundRobinIndexMap.put(key, index);
                        System.debug('Round robin index for ' + key + ' updated to ' + index);
                    }
                    leadsToUpdate.add(new Lead(Id = lead.Id, OwnerId = selectedUserId));
                    userLeadCountMap.put(selectedUserId, userLeadCountMap.get(selectedUserId) + 1);
                    System.debug('Assigned international lead ' + lead.Id + ' to user ' + selectedUserId);
                } else {
                    System.debug('No international users found for lead ' + lead.Id);
                }
                continue; // skip to next lead after assigning international lead
            }
            
            // NORMAL ASSIGNMENT based on recordType + region
            if (String.isNotBlank(region) && String.isNotBlank(recordTypeName)) {
                List<Id> recordTypeUsers = recordTypeUserMap.get(recordTypeName);
                List<Id> regionUsers = regionUserMap.get(region);
                
                System.debug('RecordType users: ' + recordTypeUsers);
                System.debug('Region users: ' + regionUsers);
                
                if (recordTypeUsers == null || regionUsers == null) {
                    System.debug('No users found for record type ' + recordTypeName + ' or region ' + region);
                    continue;
                }
                
                Set<Id> eligibleUserIds = new Set<Id>(recordTypeUsers);
                eligibleUserIds.retainAll(new Set<Id>(regionUsers));
                List<Id> eligibleUsers = new List<Id>(eligibleUserIds);
                
                System.debug('Eligible users after intersection: ' + eligibleUsers);
                
                if (!eligibleUsers.isEmpty()) {
                    String compositeKey = recordTypeName + ':' + region;
                    Integer minCount = findMinLeadCount(eligibleUsers, userLeadCountMap);
                    
                    List<Id> leastLoadedUsers = new List<Id>();
                    for (Id userId : eligibleUsers) {
                        if (userLeadCountMap.get(userId) == minCount) {
                            leastLoadedUsers.add(userId);
                        }
                    }
                    
                    System.debug('Least loaded users for key ' + compositeKey + ': ' + leastLoadedUsers + ' with lead count: ' + minCount);
                    
                    Integer index = roundRobinIndexMap.containsKey(compositeKey) 
                        ? roundRobinIndexMap.get(compositeKey) : 0;
                    if (index >= leastLoadedUsers.size()) {
                        index = 0;
                    }
                    
                    Id selectedUserId = leastLoadedUsers[index];
                    leadsToUpdate.add(new Lead(Id = lead.Id, OwnerId = selectedUserId));
                    userLeadCountMap.put(selectedUserId, userLeadCountMap.get(selectedUserId) + 1);
                    
                    index++;
                    if (index >= leastLoadedUsers.size()) {
                        index = 0;
                    }
                    roundRobinIndexMap.put(compositeKey, index);
                    
                    System.debug('Assigned lead ' + lead.Id + ' to user ' + selectedUserId + 
                                 ' (Lead Count: ' + userLeadCountMap.get(selectedUserId) + ', next round robin index: ' + index + ')');
                } else {
                    System.debug('No eligible users found for record type ' + recordTypeName + ' and region ' + region);
                }
            } else {
                System.debug('Lead ' + lead.Id + ' skipped due to missing region or record type');
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
            System.debug('Updated ' + leadsToUpdate.size() + ' leads.');
        } else {
            System.debug('No leads assigned.');
        }
    }
    
    private static Integer findMinLeadCount(List<Id> userIds, Map<Id, Integer> userLeadCountMap) {
        Integer minCount = null;
        for (Id userId : userIds) {
            Integer count = userLeadCountMap.get(userId);
            if (minCount == null || count < minCount) {
                minCount = count;
            }
        }
        return minCount != null ? minCount : 0;
    }
}