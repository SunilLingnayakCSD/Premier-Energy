public class LeadAssignmentHandler {
   private static Map<String, String> queueMapping = new Map<String, String>{
        'North:Channel_Sales' => 'North_CS',
        'East:Channel_Sales' => 'East_CS',
        'South:Channel_Sales' => 'South_CS',
        'West:Channel_Sales' => 'West_CS',
        'North:Key_Account_Private' => 'North_KAP',
        'East:Key_Account_Private' => 'East_KAP',
        'South:Key_Account_Private' => 'South_KAP',
        'West:Key_Account_Private' => 'West_KAP',
        'North:Key_Account_Government' => 'North_KAG',
        'East:Key_Account_Government' => 'East_KAG',
        'South:Key_Account_Government' => 'South_KAG',
        'West:Key_Account_Government' => 'West_KAG'
    };

    public static void assignLeads(List<Lead> leads, Map<Id, RecordType> recordTypeMap) {
        Set<String> queueNames = new Set<String>();

        // Fetch Record Types
        Map<String, RecordType> recordTypes = new Map<String, RecordType>();
        for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'Lead']) {
            recordTypes.put(rt.DeveloperName, rt);
        }

        for (Lead lead : leads) {
            if (lead.Region_Picklist__c != null && lead.RecordTypeId != null) {
                String recordTypeName = recordTypeMap.get(lead.RecordTypeId).DeveloperName;
                RecordType KAPRecordType= [SELECT DeveloperName FROM RecordType WHERE SObjectType = 'Lead'AND DeveloperName ='Key_Account_Private'];
                RecordType CSRecordType= [SELECT DeveloperName FROM RecordType WHERE SObjectType = 'Lead'AND DeveloperName ='Channel_Sales'];
                RecordType KAGRecordType= [SELECT DeveloperName FROM RecordType WHERE SObjectType = 'Lead'AND DeveloperName ='Key_Account_Government'];

                String queueAPIName;

                if (recordTypeName == 'KAPRecordType' && lead.Total_Capacity_in_MWp__c != null && lead.Total_Capacity_in_MWp__c >= 1) {
                    queueAPIName = queueMapping.get(lead.Region_Picklist__c + ':' + recordTypeName);
                } else if (recordTypeName == 'KAGRecordType') {
                    queueAPIName = queueMapping.get(lead.Region_Picklist__c + ':' + recordTypeName);
                } else if (recordTypeName == 'CSRecordType' && lead.Total_Capacity_in_MWp__c != null && lead.Total_Capacity_in_MWp__c < 1) {
                    queueAPIName = queueMapping.get(lead.Region_Picklist__c + ':' + recordTypeName);
                } else {
                    queueAPIName = queueMapping.get(lead.Region_Picklist__c+ ':' + recordTypeName);
                }

                if (queueAPIName != null) {
                    queueNames.add(queueAPIName);
                }
            }
        }

        if (queueNames.isEmpty()) {
            return;
        }

        // Fetch Queue IDs
        Map<String, Id> queueIds = new Map<String, Id>();
        for (Group queue : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames]) {
            queueIds.put(queue.DeveloperName, queue.Id);
        }

        // Fetch Users under each Queue
        Map<Id, List<Id>> queueUsers = new Map<Id, List<Id>>();
        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :queueIds.values()]) {
            if (!queueUsers.containsKey(gm.GroupId)) {
                queueUsers.put(gm.GroupId, new List<Id>());
            }
            queueUsers.get(gm.GroupId).add(gm.UserOrGroupId);
        }

        // Fetch Last Assigned Users
        Map<String, Id> lastAssignedUsers = new Map<String, Id>();
        for (QueueAssignmentTracker__c tracker : [SELECT Name, LastAssignedUserId__c FROM QueueAssignmentTracker__c WHERE Name IN :queueNames]) {
            lastAssignedUsers.put(tracker.Name, tracker.LastAssignedUserId__c);
        }

        // Assign Leads in Round-Robin
        List<QueueAssignmentTracker__c> trackersToUpdate = new List<QueueAssignmentTracker__c>();
        for (Lead lead : leads) {
            if (lead.Region_Picklist__c != null && lead.RecordTypeId != null) {
                String recordTypeName = recordTypeMap.get(lead.RecordTypeId).DeveloperName;
                String queueAPIName = queueMapping.get(lead.Region_Picklist__c + ':' + recordTypeName);

                if (queueAPIName != null) {
                    Id queueId = queueIds.get(queueAPIName);
                    if (queueUsers.containsKey(queueId) && !queueUsers.get(queueId).isEmpty()) {
                        List<Id> users = queueUsers.get(queueId);
                        Id lastAssignedUser = lastAssignedUsers.get(queueAPIName);
                        Integer index = lastAssignedUser != null ? users.indexOf(lastAssignedUser) + 1 : 0;
                        if (index >= users.size()) {
                            index = 0;
                        }
                        lead.OwnerId = users[index];
                        lastAssignedUsers.put(queueAPIName, users[index]);

                        // Update Tracker Object
                        QueueAssignmentTracker__c tracker = new QueueAssignmentTracker__c(
                            Name = queueAPIName,
                            LastAssignedUserId__c = users[index]
                        );
                        trackersToUpdate.add(tracker);
                    }
                }
            }
        }

        // Upsert Tracker Records
        if (!trackersToUpdate.isEmpty()) {
            upsert trackersToUpdate Name;
        }
    }
}