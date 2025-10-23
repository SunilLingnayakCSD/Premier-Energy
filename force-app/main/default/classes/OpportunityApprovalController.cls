public with sharing class OpportunityApprovalController {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesForApproval() {
        User currentUser = [
            SELECT UserRole.Name, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        Boolean isSystemAdmin = currentUser.Profile.Name == 'System Administrator';
        // Boolean isValidRole = currentUser.UserRole != null &&
        //                       currentUser.UserRole.Name == 'National Head, Key Accounts Private';

        Boolean isValidRole = currentUser.UserRole != null &&
                      (currentUser.UserRole.Name == 'National Head, Key Accounts Private' ||
                       currentUser.UserRole.Name == 'Key Accounts International Head Private');


        if (!isSystemAdmin && !isValidRole) {
            return new List<Opportunity>();
        }

        return [
            SELECT Id, Name, StageName, Owner.Name, Customer_Type__c, Approval_Status__c
            FROM Opportunity
            WHERE Customer_Type__c = 'Existing /Pipeline'
              AND RecordType.DeveloperName = 'Key_Account_Private'
              AND Approval_Status__c != 'Approved' AND Approval_Status__c != 'Rejected' // Only show non-approved opportunities
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static String approveOrRejectOpportunity(Id oppId, String action) {
        User currentUser = [
            SELECT UserRole.Name, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        Boolean isSystemAdmin = currentUser.Profile.Name == 'System Administrator';
        // Boolean isValidRole = currentUser.UserRole != null &&
        //                       currentUser.UserRole.Name == 'National Head, Key Accounts Private';
        Boolean isValidRole = currentUser.UserRole != null &&
                      (currentUser.UserRole.Name == 'National Head, Key Accounts Private' ||
                       currentUser.UserRole.Name == 'Key Accounts International Head Private');


        if (!isSystemAdmin && !isValidRole) {
            throw new AuraHandledException('You do not have permission to approve or reject Opportunities.');
        }

        Opportunity opp = [
            SELECT Id, Approval_Status__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        if (action == 'approve') {
            opp.Approval_Status__c = 'Approved';
        } else if (action == 'reject') {
            opp.Approval_Status__c = 'Rejected';
        } else {
            throw new AuraHandledException('Invalid action specified.');
        }

        update opp;
        return opp.Approval_Status__c;
    }
}