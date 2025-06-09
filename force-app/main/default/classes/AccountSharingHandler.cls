public with sharing class AccountSharingHandler {
    
    public static void shareDistributorAccountForLoggedInUser() {
        // Get the logged-in user's contact
        User currentUser = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        if (currentUser.ContactId == null) {
            // User is not associated with a contact, so exit
            return;
        }

        // Get the Account linked to this Contact (assuming it's via Contact.AccountId)
        Contact userContact = [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE Id = :currentUser.ContactId 
            AND AccountId != null 
            LIMIT 1
        ];

        // Get the Account with RecordType
        Account relatedAccount = [
            SELECT Id, Name, RecordType.DeveloperName 
            FROM Account 
            WHERE Id = :userContact.AccountId 
            LIMIT 1
        ];

        if (relatedAccount.RecordType.DeveloperName == 'Distributor') {
            // Check if sharing already exists
            List<AccountShare> existingShares = [
                SELECT Id 
                FROM AccountShare 
                WHERE AccountId = :relatedAccount.Id 
                AND UserOrGroupId = :UserInfo.getUserId()
            ];

            if (existingShares.isEmpty()) {
                // Create a new share
                AccountShare shareRecord = new AccountShare();
                shareRecord.AccountId = relatedAccount.Id;
                shareRecord.UserOrGroupId = UserInfo.getUserId();
                shareRecord.AccountAccessLevel = 'Edit'; // Read/Write
                shareRecord.OpportunityAccessLevel = 'Read'; // Optional
                shareRecord.CaseAccessLevel = 'Read'; // Optional
                insert shareRecord;
            }
        }
    }
}