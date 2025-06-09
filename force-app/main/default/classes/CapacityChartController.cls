// public with sharing class CapacityChartController {
//     @AuraEnabled(cacheable=true)
//     public static List<CapacityData> getCapacityData() {
//         List<CapacityData> results = new List<CapacityData>();

//         // Fetch all Account records with Total Capacity
//         List<Account> accounts = [SELECT Id, Premier_Business_Entity__c, 
//             Plant_Name__c, Plant_Name1__c, Plant_Name2__c, Plant_Name3__c,
//             Total_Capacity_in_MWp__c FROM Account 
//             WHERE Premier_Business_Entity__c != NULL 
//             AND Total_Capacity_in_MWp__c != NULL];

//         // Fetch Custom Metadata (targets)
//         List<Plant_Capacity_Metadata__mdt> metadataList = [
//             SELECT Company__c, Plant_Name__c, Capacity__c, Capacity_Unit__c 
//             FROM Plant_Capacity_Metadata__mdt
//         ];

//         // Aggregate Account capacity by entity+plant
//         Map<String, Decimal> actualMap = new Map<String, Decimal>();
//         for (Account acc : accounts) {
//             List<String> plantFields = new List<String>{
//                 acc.Plant_Name__c, acc.Plant_Name1__c, acc.Plant_Name2__c, acc.Plant_Name3__c
//             };

//             for (String plant : plantFields) {
//                 if (String.isNotBlank(plant)) {
//                     String key = acc.Premier_Business_Entity__c + '###' + plant;
//                     actualMap.put(key, actualMap.containsKey(key) ? actualMap.get(key) + acc.Total_Capacity_in_MWp__c : acc.Total_Capacity_in_MWp__c);
//                 }
//             }
//         }

//         // Match and build result list
//         for (Plant_Capacity_Metadata__mdt meta : metadataList) {
//             String key = meta.Company__c + '###' + meta.Plant_Name__c;
//             if (actualMap.containsKey(key)) {
//                 Decimal achieved = actualMap.get(key);
//                 Decimal target = 0;
//                 if (meta.Capacity__c != null) {
//                     Decimal capacityVal = Decimal.valueOf(meta.Capacity__c);
//                     target = meta.Capacity_Unit__c == 'GWp' ? capacityVal * 1000 : capacityVal;
//                 }

//                 results.add(new CapacityData(meta.Company__c, meta.Plant_Name__c, achieved, target));
//             }
//         }

//         return results;
//     }

//     public class CapacityData {
//         @AuraEnabled public String entity;
//         @AuraEnabled public String plant;
//         @AuraEnabled public Decimal achieved;
//         @AuraEnabled public Decimal target;

//         public CapacityData(String entity, String plant, Decimal achieved, Decimal target) {
//             this.entity = entity;
//             this.plant = plant;
//             this.achieved = achieved;
//             this.target = target;
//         }
//     }
// }




// public with sharing class CapacityChartController {
//     @AuraEnabled(cacheable=true)
//     public static List<CapacityData> getCapacityData() {
//         List<CapacityData> results = new List<CapacityData>();

//         // Fetch all relevant Account records
//         List<Account> accounts = [
//             SELECT Id, Premier_Business_Entity__c, 
//                    Plant_Name__c, Plant_Name1__c, Plant_Name2__c, Plant_Name3__c,
//                    Total_WP_Consumed__c
//             FROM Account 
//             WHERE Premier_Business_Entity__c != NULL 
//             AND Total_WP_Consumed__c != NULL
//         ];

//         // Fetch all target capacities from custom metadata
//         List<Plant_Capacity_Metadata__mdt> metadataList = [
//             SELECT Company__c, Plant_Name__c, Capacity__c, Capacity_Unit__c 
//             FROM Plant_Capacity_Metadata__mdt
//         ];

//         // Aggregate Total_WP_Consumed by entity+plant
//         Map<String, Decimal> actualMap = new Map<String, Decimal>();
//         for (Account acc : accounts) {
//             List<String> plantFields = new List<String>{
//                 acc.Plant_Name__c, acc.Plant_Name1__c, acc.Plant_Name2__c, acc.Plant_Name3__c
//             };

//             for (String plant : plantFields) {
//                 if (String.isNotBlank(plant)) {
//                     String key = acc.Premier_Business_Entity__c + '###' + plant;
//                     actualMap.put(
//                         key,
//                         actualMap.containsKey(key) 
//                             ? actualMap.get(key) + acc.Total_WP_Consumed__c 
//                             : acc.Total_WP_Consumed__c
//                     );
//                 }
//             }
//         }

//         // Match actual vs. target and build results
//         for (Plant_Capacity_Metadata__mdt meta : metadataList) {
//             String key = meta.Company__c + '###' + meta.Plant_Name__c;
//             if (actualMap.containsKey(key)) {
//                 Decimal achieved = actualMap.get(key);
//                 Decimal target = 0;

//                 if (meta.Capacity__c != null) {
//                     Decimal capacityVal = Decimal.valueOf(meta.Capacity__c);
//                     target = (meta.Capacity_Unit__c == 'GWp') ? capacityVal * 1000 : capacityVal;
//                 }

//                 results.add(new CapacityData(meta.Company__c, meta.Plant_Name__c, achieved, target));
//             }
//         }

//         return results;
//     }

//     public class CapacityData {
//         @AuraEnabled public String entity;
//         @AuraEnabled public String plant;
//         @AuraEnabled public Decimal achieved;
//         @AuraEnabled public Decimal target;

//         public CapacityData(String entity, String plant, Decimal achieved, Decimal target) {
//             this.entity = entity;
//             this.plant = plant;
//             this.achieved = achieved;
//             this.target = target;
//         }
//     }
// }



public with sharing class CapacityChartController {
    @AuraEnabled(cacheable=true)
    public static List<CapacityData> getCapacityData() {
        List<CapacityData> results = new List<CapacityData>();

        // Fetch only 'Distributor' Accounts with required fields
        List<Account> accounts = [
            SELECT Id, Premier_Business_Entity__c, 
                   Plant_Name__c, Plant_Name1__c, Plant_Name2__c, Plant_Name3__c,
                   Total_WP_Consumed__c, RecordType.DeveloperName
            FROM Account 
            WHERE RecordType.DeveloperName = 'Distributor'
            AND Premier_Business_Entity__c != NULL 
            AND Total_WP_Consumed__c != NULL
        ];

        // Fetch all target capacities from custom metadata
        List<Plant_Capacity_Metadata__mdt> metadataList = [
            SELECT Company__c, Plant_Name__c, Capacity__c, Capacity_Unit__c 
            FROM Plant_Capacity_Metadata__mdt
        ];

        // Aggregate Total_WP_Consumed by entity+plant
        Map<String, Decimal> actualMap = new Map<String, Decimal>();
        for (Account acc : accounts) {
            List<String> plantFields = new List<String>{
                acc.Plant_Name__c, acc.Plant_Name1__c, acc.Plant_Name2__c, acc.Plant_Name3__c
            };

            for (String plant : plantFields) {
                if (String.isNotBlank(plant)) {
                    String key = acc.Premier_Business_Entity__c + '###' + plant;
                    actualMap.put(
                        key,
                        actualMap.containsKey(key) 
                            ? actualMap.get(key) + acc.Total_WP_Consumed__c 
                            : acc.Total_WP_Consumed__c
                    );
                }
            }
        }

        // Match actual vs. target and build results
        for (Plant_Capacity_Metadata__mdt meta : metadataList) {
            String key = meta.Company__c + '###' + meta.Plant_Name__c;
            if (actualMap.containsKey(key)) {
                Decimal achieved = actualMap.get(key);
                Decimal target = 0;

                if (meta.Capacity__c != null) {
                    Decimal capacityVal = Decimal.valueOf(meta.Capacity__c);
                    target = (meta.Capacity_Unit__c == 'GWp') ? capacityVal * 1000 : capacityVal;
                }

                results.add(new CapacityData(meta.Company__c, meta.Plant_Name__c, achieved, target));
            }
        }

        return results;
    }

    public class CapacityData {
        @AuraEnabled public String entity;
        @AuraEnabled public String plant;
        @AuraEnabled public Decimal achieved;
        @AuraEnabled public Decimal target;

        public CapacityData(String entity, String plant, Decimal achieved, Decimal target) {
            this.entity = entity;
            this.plant = plant;
            this.achieved = achieved;
            this.target = target;
        }
    }
}