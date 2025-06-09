public with sharing class InvoiceCount {
/*
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getInvoiceCounts( string record,Date startDate, Date endDate) {
        Map<String, Integer> result = new Map<String, Integer>();
        
        // Get RecordType Id for 'Distributor'
        Id distributorRtId = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Distributor' LIMIT 1].Id;
        Id currentUserId = UserInfo.getUserId();
        // Build SOQL query string
        String baseQuery =
            'SELECT Id, POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
            'FROM Invoice__c ' +
            'WHERE' +
            'Account__r.RecordType.Name = \'Distributor\' ' +
            'AND OwnerId = :currentUserId';

        if (startDate != null) {
            baseQuery += ' AND CreatedDate >= :startDate';
        }
        if (endDate != null) {
            baseQuery += ' AND CreatedDate <= :endDate';
        }

        // Run query
        List<Invoice__c> invoices = Database.query(baseQuery);

        // Initialize counters
        Integer totalInvoices = invoices.size();
        Integer totalPODInvoices = 0;
        Integer totalFTRInvoices = 0;

        for (Invoice__c inv : invoices) {
            if (inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) {
                totalPODInvoices++;
            }
            if (inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) {
                totalFTRInvoices++;
            }
        }

        // Put final counts into result map
        result.put('totalInvoices', totalInvoices);
        result.put('totalPODInvoices', totalPODInvoices);
        result.put('totalFTRInvoices', totalFTRInvoices);

        return result;
    }
	
*/
//  100 percent working code
// @AuraEnabled(cacheable=true)
// public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
//     Map<String, Integer> result = new Map<String, Integer>();
    
//     try {
//         // 1. Get RecordType Id SAFELY
//         List<RecordType> rtList = [SELECT Id FROM RecordType 
//                                   WHERE SObjectType = 'Account' 
//                                   AND DeveloperName = 'Distributor' 
//                                   LIMIT 1];
        
       

//         // 2. Build Base Query Correctly
//         String query = 
//             'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
//             'FROM Invoice__c '; // Space at end

//         // 3. Add Date Filters Properly
//         if(startDate != null) {
//             query += 'AND DAY_ONLY(CreatedDate) >= :startDate ';
//         }
//         if(endDate != null) {
//             query += 'AND DAY_ONLY(CreatedDate) <= :endDate ';
//         }

//         // 4. Execute Query
//         List<Invoice__c> invoices = Database.query(query);

//         // 5. Initialize Counters
//         Integer totalPOD = 0;
//         Integer totalFTR = 0;

//         // 6. Count Valid Records
//         for(Invoice__c inv : invoices) {
//             if(inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) {
//                 totalPOD++;
//             }
//             if(inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) {
//                 totalFTR++;
//             }
//         }

//         // 7. Return Results
//         result.put('totalInvoices', invoices.size());
//         result.put('totalPODInvoices', totalPOD);
//         result.put('totalFTRInvoices', totalFTR);

//     } catch(Exception e) {
//         throw new AuraHandledException('Error: ' + e.getMessage());
//     }
    
//     return result;
// } 

//100 percent code 3
@AuraEnabled(cacheable=true)
public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
    Map<String, Integer> result = new Map<String, Integer>();
    try {
        Id currentUserId = UserInfo.getUserId();
        
        
        
        // Get User's Contact and Account
        User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
        if (currentUser.ContactId == null) {
            throw new AuraHandledException('User not linked to a Contact.');
        }
        Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
        if (userContact.AccountId == null) {
            throw new AuraHandledException('Contact not linked to an Account.');
        }
        Id currentUserAccountId = userContact.AccountId;
        
        // Get RecordTypeId by DeveloperName
        String recordTypeDevName = 'Distributor'; // Update this!
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get(recordTypeDevName).getRecordTypeId();
        
        // Build Query
        String query = 
            'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
            'FROM Invoice__c ' +
            'WHERE Account__c = :currentUserAccountId ';
            //+
           // 'AND RecordTypeId = :recordTypeId';
        
        // Add Date Filters
        if (startDate != null) {
            query += ' AND DAY_ONLY(CreatedDate) >= :startDate';
        }
        if (endDate != null) {
            query += ' AND DAY_ONLY(CreatedDate) <= :endDate';
        }
        
        System.debug('Final Query: ' + query);
        List<Invoice__c> invoices = Database.query(query);
        
        // Count Logic (unchanged)
        Integer totalPOD = 0, totalFTR = 0;
        for (Invoice__c inv : invoices) {
            if (inv.POD_Status__c != 'uploaded' && inv.POD_Date__c != null) totalPOD++;
            if (inv.Status__c != 'uploaded' && inv.FTR_Upload_Date__c != null) totalFTR++;
        }
        
        result.put('totalInvoices', invoices.size());
        result.put('totalPODInvoices', totalPOD);
        result.put('totalFTRInvoices', totalFTR);
        
    } catch (Exception e) {
        System.debug('Error: ' + e.getMessage() + ' at ' + e.getLineNumber());
        throw new AuraHandledException('Error: ' + e.getMessage());
    }
    return result;
}


































//whole code 
// @AuraEnabled(cacheable=true)
//     public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
//         Map<String, Integer> result = new Map<String, Integer>{
//             'totalInvoices' => 0,
//             'totalPODInvoices' => 0,
//             'totalFTRInvoices' => 0
//         };
        
//         try {
//             // 1. Get Distributor RecordType ID
//             Id distributorRecordTypeId = Schema.SObjectType.Account
//                 .getRecordTypeInfosByDeveloperName()
//                 .get('Distributor')
//                 .getRecordTypeId();
                
//             if(distributorRecordTypeId == null) {
//                 return result;
//             }

//             // 2. Get portal user's Account via Contact
//             User currentUser = [SELECT Id, ContactId 
//                               FROM User 
//                               WHERE Id = :UserInfo.getUserId()
//                               LIMIT 1];
            
//             if(currentUser.ContactId == null) {
//                 return result;
//             }

//             Contact userContact = [SELECT AccountId 
//                                  FROM Contact 
//                                  WHERE Id = :currentUser.ContactId
//                                  LIMIT 1];
            
//             if(userContact.AccountId == null) {
//                 return result;
//             }

//             // 3. Verify Account is Distributor type
//             List<Account> distributorAccounts = [SELECT Id 
//                                                FROM Account 
//                                                WHERE Id = :userContact.AccountId 
//                                                AND RecordTypeId = :distributorRecordTypeId
//                                                LIMIT 1];
            
//             if(distributorAccounts.isEmpty()) {
//                 return result;
//             }
//             Id accountId = distributorAccounts[0].Id;

//             // 4. Build dynamic query
//             String query = 'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
//                          'FROM Invoice__c ' +
//                          'WHERE Account__c = :accountId '; // Use your relationship field name

//             List<String> conditions = new List<String>();
            
//             if(startDate != null) {
//                 conditions.add('DAY_ONLY(CreatedDate) >= :startDate');
//             }
//             if(endDate != null) {
//                 conditions.add('DAY_ONLY(CreatedDate) <= :endDate');
//             }
            
//             if(!conditions.isEmpty()) {
//                 query += 'AND ' + String.join(conditions, ' AND ');
//             }

//             // 5. Execute with security checks
//             List<Invoice__c> invoices = Database.queryWithBinds(
//                 query,
//                 new Map<String, Object>{
//                     'accountId' => accountId,
//                     'startDate' => startDate,
//                     'endDate' => endDate
//                 },
//                 AccessLevel.USER_MODE
//             );

//             // 6. Calculate counts
//             Integer totalPOD = 0, totalFTR = 0;
//             for(Invoice__c inv : invoices) {
//                 if(inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) totalPOD++;
//                 if(inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) totalFTR++;
//             }

//             result.put('totalInvoices', invoices.size());
//             result.put('totalPODInvoices', totalPOD);
//             result.put('totalFTRInvoices', totalFTR);

//         } catch(Exception e) {
//             System.debug('Error: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
//         }
//         return result;
//     }




























// 100 percent code 4 
//     @AuraEnabled(cacheable=true)
//     public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
//         System.debug('startDate----'+startDate+'endDate----'+endDate);
//     Id currentUserId = UserInfo.getUserId();
//     Map<String, Integer> result = new Map<String, Integer>();

//     try {
//         System.debug('inside try');
//         List<String> conditions = new List<String>();
//         String query = 'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c FROM Invoice__c';
//         System.debug('query'+query);

//         // Build WHERE clause dynamically
//         if (startDate != null) {
//             conditions.add('DAY_ONLY(CreatedDate) >= \'' + startDate.format() + '\'');
//         }
//         if (endDate != null) {
//             conditions.add('DAY_ONLY(CreatedDate) <= \'' + endDate.format() + '\'');
//         }

//         if (!conditions.isEmpty()) {
//             query += ' WHERE OwnerId = \'' + currentUserId + '\' AND ' + String.join(conditions, ' AND ');
//         } else {
//             query += ' WHERE OwnerId = \'' + currentUserId + '\'';
//         }

//         // Debugging the final query (always good for testing)
//         System.debug('Final Query: ' + query);

//         List<Invoice__c> invoices = Database.query(query);

//         Integer totalPOD = 0;
//         Integer totalFTR = 0;

//         for (Invoice__c inv : invoices) {
//             if (inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) {
//                 totalPOD++;
//             }
//             if (inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) {
//                 totalFTR++;
//             }
//         }

//         result.put('totalInvoices', invoices.size());
//         result.put('totalPODInvoices', totalPOD);
//         result.put('totalFTRInvoices', totalFTR);

//     } catch (Exception e) {
//         throw new AuraHandledException('Error: ' + e.getMessage());
//     }
//     System.debug('result'+result);
//     return result;
// }




    // code 3 fetching login userId
    
    // @AuraEnabled(cacheable=true)
    // public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) 
    // {
         
    //     Map<String, Integer> result = new Map<String, Integer>{
    //         'totalInvoices' => 0,
    //         'totalPODInvoices' => 0,
    //         'totalFTRInvoices' => 0
    //     };
        
    //     try {
    //         // 1. Get logged-in user's associated Distributor Account
    //         Id accountId = getDistributorAccountId();
    //         if(accountId == null) return result;

    //         // 2. Build base query with security enforcement
    //         List<String> conditions = new List<String>{
    //             'Account__c = :accountId' // Use your actual relationship field name
    //         };

    //         // 3. Add date filters
    //         if(startDate != null) {
    //             conditions.add('DAY_ONLY(CreatedDate) >= :startDate');
    //         }
    //         if(endDate != null) {
    //             conditions.add('DAY_ONLY(CreatedDate) <= :endDate');
    //         }

    //         // 4. Construct dynamic query
    //         String query = 'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
    //                        'FROM Invoice__c ' +
    //                        'WHERE ' + String.join(conditions, ' AND ');

    //         // 5. Execute with USER_MODE for security checks
    //         List<Invoice__c> invoices = Database.queryWithBinds(
    //             query,
    //             new Map<String, Object>{
    //                 'accountId' => accountId,
    //                 'startDate' => startDate,
    //                 'endDate' => endDate
    //             },
    //             AccessLevel.USER_MODE
    //         );

    //         // 6. Process counts
    //         Integer totalPOD = 0;
    //         Integer totalFTR = 0;

    //         for(Invoice__c inv : invoices) {
    //             if(inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) {
    //                 totalPOD++;
    //             }
    //             if(inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) {
    //                 totalFTR++;
    //             }
    //         }

    //         // 7. Update results
    //         result.put('totalInvoices', invoices.size());
    //         result.put('totalPODInvoices', totalPOD);
    //         result.put('totalFTRInvoices', totalFTR);

    //     } catch(Exception e) {
    //         throw new AuraHandledException('Error: ' + e.getMessage());
    //     }
        
    //     return result;
    // }

    // private static Id getDistributorAccountId() {
    //     try {
    //         // Get portal user's associated Account
    //         User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    //         if(u.ContactId == null) return null;

    //         Contact c = [SELECT AccountId FROM Contact WHERE Id = :u.ContactId LIMIT 1];
            
    //         return [SELECT Id FROM Account 
    //                 WHERE Id = :c.AccountId 
    //                 AND RecordType.DeveloperName = 'Distributor'
    //                 LIMIT 1].Id;
            
    //     } catch(Exception e) {
    //         throw new AuraHandledException('User is not associated with a Distributor Account');
    //     }
    // }

        
    
    // @AuraEnabled(cacheable=true)
    // public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
    //     Map<String, Integer> result = new Map<String, Integer>{
    //         'totalInvoices' => 0,
    //         'totalPODInvoices' => 0,
    //         'totalFTRInvoices' => 0
    //     };
        
    //     try {
    //         // 1. Get Distributor RecordType ID
    //         List<RecordType> rtList = [SELECT Id FROM RecordType 
    //                                   WHERE SObjectType = 'Account' 
    //                                   AND DeveloperName = 'Distributor' 
    //                                   LIMIT 1];
    //         if(rtList.isEmpty()) return result;
            
    //         // 2. Get portal user's associated Account
    //         User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
    //         if(currentUser.ContactId == null) return result;
            
    //         Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :currentUser.ContactId];
    //         Account distributorAccount = [SELECT Id FROM Account 
    //                                     WHERE Id = :userContact.AccountId 
    //                                     AND RecordTypeId = :rtList[0].Id 
    //                                     LIMIT 1];
    //         if(distributorAccount == null) return result;

    //         // 3. Build dynamic query
    //         List<String> conditions = new List<String>{
    //             'Account__c = :accountId' // Use your Invoice-Account relationship field
    //         };
            
    //         if(startDate != null) conditions.add('DAY_ONLY(CreatedDate) >= :startDate');
    //         if(endDate != null) conditions.add('DAY_ONLY(CreatedDate) <= :endDate');
            
    //         String query = 'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
    //                      'FROM Invoice__c ' +
    //                      'WHERE ' + String.join(conditions, ' AND ');

    //         // 4. Execute with security enforcement
    //         List<Invoice__c> invoices = Database.queryWithBinds(
    //             query,
    //             new Map<String, Object>{
    //                 'accountId' => distributorAccount.Id,
    //                 'startDate' => startDate,
    //                 'endDate' => endDate
    //             },
    //             AccessLevel.USER_MODE
    //         );

    //         // 5. Calculate counts
    //         Integer totalPOD = 0, totalFTR = 0;
    //         for(Invoice__c inv : invoices) {
    //             if(inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) totalPOD++;
    //             if(inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) totalFTR++;
    //         }

    //         result.put('totalInvoices', invoices.size());
    //         result.put('totalPODInvoices', totalPOD);
    //         result.put('totalFTRInvoices', totalFTR);

    //     } catch(Exception e) {
    //         throw new AuraHandledException('Error: ' + e.getMessage());
    //     }
    //     return result;
    // }





















































































 /* @AuraEnabled(cacheable=true)
public static Map<String, Integer> getInvoiceCounts(Date startDate, Date endDate) {
    Map<String, Integer> result = new Map<String, Integer>();

    try {
        // 1. Get current user's Accounts
        Id userId = UserInfo.getUserId();
        List<Id> accountIds = new List<Id>();

        for (Account acc : [
            SELECT Id FROM Account WHERE OwnerId = :userId
        ]) {
            accountIds.add(acc.Id);
        }

        if (accountIds.isEmpty()) {
            result.put('totalInvoices', 0);
            result.put('totalPODInvoices', 0);
            result.put('totalFTRInvoices', 0);
            return result;
        }

        // 2. Build Invoice Query dynamically
        String query = 
            'SELECT POD_Status__c, POD_Date__c, Status__c, FTR_Upload_Date__c ' +
            'FROM Invoice__c WHERE Account__c IN :accountIds';

        if (startDate != null) {
            query += ' AND CreatedDate >= :startDate';
        }
        if (endDate != null) {
            query += ' AND CreatedDate <= :endDate';
        }

        // 3. Execute query
        List<Invoice__c> invoices = Database.query(query);

        // 4. Count totals
        Integer totalPOD = 0;
        Integer totalFTR = 0;

        for (Invoice__c inv : invoices) {
            if (inv.POD_Status__c == 'uploaded' && inv.POD_Date__c != null) {
                totalPOD++;
            }
            if (inv.Status__c == 'uploaded' && inv.FTR_Upload_Date__c != null) {
                totalFTR++;
            }
        }

        // 5. Return counts
        result.put('totalInvoices', invoices.size());
        result.put('totalPODInvoices', totalPOD);
        result.put('totalFTRInvoices', totalFTR);

    } catch (Exception e) {
        throw new AuraHandledException('Error: ' + e.getMessage());
    }
	System.debug('result'+result);
    return result;
}*/






}