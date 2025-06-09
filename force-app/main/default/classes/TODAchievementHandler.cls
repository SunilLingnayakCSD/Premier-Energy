public class TODAchievementHandler {
    
    public static void calculateTODAchievements(List<TurnOver_Discounts__c> newTODs, Map<Id, TurnOver_Discounts__c> oldMap) {
        // Filter which TOD records need processing
        List<TurnOver_Discounts__c> todsToProcess = new List<TurnOver_Discounts__c>();
        Set<Id> distributorIds = new Set<Id>();
        
        for (TurnOver_Discounts__c tod : newTODs) {
            if (Trigger.isInsert || 
                tod.Valid_From__c != oldMap.get(tod.Id).Valid_From__c ||
                tod.Valid_To__c != oldMap.get(tod.Id).Valid_To__c ||
                tod.Period__c != oldMap.get(tod.Id).Period__c ||
                tod.Distributor__c != oldMap.get(tod.Id).Distributor__c ||
                tod.Payout_Type__c != oldMap.get(tod.Id).Payout_Type__c) {
                todsToProcess.add(tod);
                distributorIds.add(tod.Distributor__c);
            }
        }
        
        if (todsToProcess.isEmpty()) return;
        
        // Get all invoices for the affected distributors
        Map<Id, List<Invoice__c>> distributorInvoices = new Map<Id, List<Invoice__c>>();
        for (Invoice__c inv : [
            SELECT Id, Account__c, Total_Capacity_in_MWp__c, Amount__c, Invoice_Date__c 
            FROM Invoice__c 
            WHERE Account__c IN :distributorIds
            AND (Total_Capacity_in_MWp__c != null OR Amount__c != null)
        ]) {
            if (!distributorInvoices.containsKey(inv.Account__c)) {
                distributorInvoices.put(inv.Account__c, new List<Invoice__c>());
            }
            distributorInvoices.get(inv.Account__c).add(inv);
        }
        
        // Process each TOD
        for (TurnOver_Discounts__c tod : todsToProcess) {
            if (tod.Distributor__c == null || tod.Valid_From__c == null || tod.Valid_To__c == null || tod.Payout_Type__c == null) {
                continue;
            }
            
            Date startDate = tod.Valid_From__c;
            Date endDate = tod.Valid_To__c;
            
            // Adjust end date based on period type
            if (tod.Period__c == 'Month') {
                endDate = startDate.addMonths(1).addDays(-1);
            } else if (tod.Period__c == 'Quarter') {
                endDate = startDate.addMonths(3).addDays(-1);
            } else if (tod.Period__c == 'Year') {
                endDate = startDate.addYears(1).addDays(-1);
            }
            
            // Calculate achievement based on Target Type (which is determined by Payout_Type__c)
            Decimal totalAchieved = 0;
            
            // Since Target_Type__c is a formula, it will be dynamically calculated
            String targetType = tod.Target_Type__c; // This will give 'Wp' or 'Amount'
            
            if (distributorInvoices.containsKey(tod.Distributor__c)) {
                for (Invoice__c inv : distributorInvoices.get(tod.Distributor__c)) {
                    if (inv.Invoice_Date__c >= startDate && inv.Invoice_Date__c <= endDate) {
                        // Check the Target Type to decide whether to sum Total_Capacity_in_MWp or Amount
                        if (targetType == 'Wp') {
                            totalAchieved += inv.Total_Capacity_in_MWp__c != null ? inv.Total_Capacity_in_MWp__c : 0;
                        } else if (targetType == 'Amount') {
                            totalAchieved += inv.Amount__c != null ? inv.Amount__c : 0;
                        }
                    }
                }
            }
            
            // Set the achieved value on the TOD record
            tod.Achieved__c = totalAchieved;
        }
    }
}