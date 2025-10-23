public without sharing class LeadAssignmentBasedOnRegionAndRecordType {
    public static void assignLeads(List<Lead> leads, Map<Id, RecordType> recordTypeMap) {
    	  
       String recordTypeName = recordTypeMap.get(leads[0].RecordTypeId).Name;
       String recordTypeDevName = recordTypeMap.get(leads[0].RecordTypeId).DeveloperName;
       String regionnameoflead = leads[0].Region_Picklist__c; 
        List<User> users = new List<User>();
        if(leads[0].Country !='India' && recordTypeDevName == 'Key_Account_Private'){
            users = [Select Id, UserRole.Name,UserRole.DeveloperName  from User where UserRole.DeveloperName = 'Key_Account_International_Sales' And IsActive = true];
            System.debug('Spl case');
        }else if(recordTypeDevName =='Key_Account_Government'){
            users = Database.query(
            'SELECT Id, UserRole.Name ' +
            'FROM User ' +
            'WHERE IsActive = true ' +
            'AND (UserRole.Name LIKE \'%Regional Manager%\')'+
            'AND Region1__c INCLUDES (\'' + regionnameoflead + '\')'
        ); 
        }else{
           users = Database.query(
            'SELECT Id, UserRole.Name ' +
            'FROM User ' +
            'WHERE IsActive = true ' +
            'AND UserRole.Name LIKE \'%' + recordTypeName + '%\' ' +
            'AND (UserRole.Name LIKE \'%Region Head%\' OR UserRole.Name LIKE \'%Regional Manager%\')'+
            'AND Region1__c INCLUDES (\'' + regionnameoflead + '\')'
        ); 
            System.debug('Not spl case');
        }
        
        
        System.debug('Users fetched with matching roles: ' + users.size());
                
        if (users.isEmpty()) {
            System.debug('No active users found for the matched roles. Exiting.');
            return;
        }
        List<Lead> updateLead = new List<Lead>();
        List<Id> userIds = new List<Id>();
        if(!users.isEmpty()){
            for (User u : users) {
                userIds.add(u.Id);
                System.debug('Eligible User: ' + u.Id + ' with Role: ' + u.UserRole.Name);
            }
        }
        if(userIds.size()==1){
            for (Lead l : leads) {
                Lead updatedLead = new Lead(Id = l.Id);
                updatedLead.OwnerId = userIds[0];
                updateLead.add(updatedLead);
            }
        }else{
            Integer count = userIds.size() - 1;
            System.debug('Limit for recent leads (count): ' + count);
            
            List<Lead> existingLeads = [
                SELECT Id, OwnerId 
                FROM Lead 
                WHERE OwnerId IN :userIds 
                ORDER BY CreatedDate DESC 
                LIMIT :count
            ];
            System.debug('Existing leads owned by eligible users: ' + existingLeads.size());
            
            Set<Id> recentOwnerIds = new Set<Id>();
            for (Lead l : existingLeads) {
                recentOwnerIds.add(l.OwnerId);
            }
            System.debug('Recent owner user IDs: ' + recentOwnerIds);
            
            List<Id> availableUserIds = new List<Id>();
            for (Id uid : userIds) {
                if (!recentOwnerIds.contains(uid)) {
                    availableUserIds.add(uid);
                }
            }
            System.debug('Available user IDs for assignment: ' + availableUserIds);
            
            if(!availableUserIds.isEmpty()){
                /* for(Lead l:leads){
l.OwnerId = availableUserIds[0];
updateLead.add(l);
}*/
            }
            for (Lead l : leads) {
                Lead updatedLead = new Lead(Id = l.Id);
                updatedLead.OwnerId = availableUserIds[0];
                updateLead.add(updatedLead);
            }
        }
        if(!updateLead.isEmpty()){
            update updateLead;
            System.debug('updateLead-->'+updateLead);
        }
    }
}