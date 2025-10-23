public with sharing class OutboundLogisticController {
    // Get picklist values for State__c field
    @AuraEnabled(cacheable=true)
    public static List<String> getStatePicklistValues() {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Outbound_Logistic__c.State__c.getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                picklistValues.add(entry.getValue());
            }
        }
        return picklistValues;
    }

    // Get state averages and grand total
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getStateAverages() {
        Map<String, Object> result = new Map<String, Object>();
        List<StateAverage> stateAverages = new List<StateAverage>();
        Decimal grandTotal = 0;
        Integer stateCount = 0;
        
        // Get average price per state
        AggregateResult[] groupedResults = [
            SELECT State__c state, AVG(Price_Km__c) avgPrice
            FROM Outbound_Logistic__c
            WHERE State__c != null
            GROUP BY State__c
        
        ];
        
        for (AggregateResult ar : groupedResults) {
            String state = (String) ar.get('state');
            Decimal avgPrice = (Decimal) ar.get('avgPrice');
            stateAverages.add(new StateAverage(state, avgPrice));
            grandTotal += avgPrice;
            stateCount++;
        }
        
        // Calculate grand total average
        //Decimal overallAverage = stateCount > 0 ? grandTotal / stateCount : 0;
		 Decimal overallAverage = grandTotal;
        
        // Sort states alphabetically
        stateAverages.sort();
        
        result.put('stateAverages', stateAverages);
        result.put('overallAverage', overallAverage);
        return result;
    }

    // Update all records for selected state
    @AuraEnabled
    public static void updateStatePrice(String selectedState, Decimal newPrice) {
        // Validate input
        if (String.isBlank(selectedState)) {
            throw new AuraHandledException('Please select a valid state');
        }
        if (newPrice == null || newPrice < 0) {
            throw new AuraHandledException('Price must be a positive number');
        }

        // Get records to update
        List<Outbound_Logistic__c> recordsToUpdate = [
            SELECT Id 
            FROM Outbound_Logistic__c 
            WHERE State__c = :selectedState
            WITH SECURITY_ENFORCED
        ];

        if (recordsToUpdate.isEmpty()) {
            throw new AuraHandledException('No records found for ' + selectedState);
        }

        // Update records
        for (Outbound_Logistic__c record : recordsToUpdate) {
            record.Price_Km__c = newPrice;
        }

        try {
            update recordsToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Update failed: ' + e.getMessage());
        }
    }
    
    // Wrapper class for state averages
    public class StateAverage implements Comparable {
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public Decimal averagePrice { get; set; }
        
        public StateAverage(String state, Decimal averagePrice) {
            this.state = state;
            this.averagePrice = averagePrice;
        }
        
        // Implement compareTo for sorting
        public Integer compareTo(Object compareTo) {
            StateAverage other = (StateAverage) compareTo;
            return this.state.compareTo(other.state);
        }
    }
}