/*public class TurnOverController {
    @AuraEnabled(cacheable=true)
public static Map<String, List<TurnOver_Discounts__c>> getFilteredTurnover(Date startDate, Date endDate) {
    System.debug('startDate'+startDate+'endDate'+endDate);
    Map<String, List<TurnOver_Discounts__c>> resultMap = new Map<String, List<TurnOver_Discounts__c>>();
    
    

    List<TurnOver_Discounts__c> records = [
        SELECT Id,Distributor__c, Material_No__c, Payout__c, Payout_Type__c, Period__c, Product__r.Name,Net_Payout__c, Target_Unit__c, Achieved__c
        FROM TurnOver_Discounts__c
        WHERE Period__c IN ('Month', 'Quarter', 'Year')
        AND CreatedDate >= :startDate
        AND CreatedDate < :endDate.addDays(1)
    ];

    for (TurnOver_Discounts__c record : records) {
        if (!resultMap.containsKey(record.Period__c)) {
            resultMap.put(record.Period__c, new List<TurnOver_Discounts__c>());
        }
        resultMap.get(record.Period__c).add(record);
    }
	System.debug('resultMap'+resultMap);
    return resultMap;
    
}
    
    public class ProductWrapper {
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal price;

        public ProductWrapper(Id id, String name, Decimal price) {
            this.productId = id;
            this.productName = name;
            this.price = price;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getProductsByMonthYear(Integer startYear, Integer startMonth, Integer endYear, Integer endMonth) {
        Date startDate;
        Date endDate;

        if (startYear != null && startMonth != null) {
            startDate = Date.newInstance(startYear, startMonth, 1);
        }
        if (endYear != null && endMonth != null) {
            endDate = Date.newInstance(endYear, endMonth, 1).addMonths(1).addDays(-1);
        }

        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;


        List<PricebookEntry> entries;

        if (startDate != null && endDate != null) {
            entries = [
                SELECT Product2Id, Product2.Name, UnitPrice, Product2.CreatedDate
                FROM PricebookEntry
                WHERE IsActive = true
                AND Pricebook2Id = :standardPricebookId
                AND Product2.CreatedDate >= :startDate AND Product2.CreatedDate <= :endDate
            ];
        } else {
            entries = [
                SELECT Product2Id, Product2.Name, UnitPrice
                FROM PricebookEntry
                WHERE IsActive = true AND Pricebook2Id = :standardPricebookId
            ];
        }

        List<ProductWrapper> wrapped = new List<ProductWrapper>();
        for (PricebookEntry pbe : entries) {
            wrapped.add(new ProductWrapper(pbe.Product2Id, pbe.Product2.Name, pbe.UnitPrice));
        }
        System.debug('wrapped'+wrapped);
        return wrapped;
    }
}*/

public class TurnOverController {
    
    // Method to get filtered turnover based on the logged-in user
    @AuraEnabled(cacheable=true)
    public static Map<String, List<TurnOver_Discounts__c>> getFilteredTurnover(Date startDate, Date endDate) {
        // Get the logged-in user's ID
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId'+currentUserId);
        
        System.debug('startDate: ' + startDate + ' endDate: ' + endDate);
        
        Map<String, List<TurnOver_Discounts__c>> resultMap = new Map<String, List<TurnOver_Discounts__c>>();
        
        // Query TurnOver_Discounts__c records for the logged-in user
        List<TurnOver_Discounts__c> records = [
            SELECT Id, Distributor__c, Material_No__c, Payout__c, Payout_Type__c, Period__c, Product__r.Name, 
                   Net_Payout__c, Target_Unit__c, Achieved__c
            FROM TurnOver_Discounts__c
            WHERE Period__c IN ('Month', 'Quarter', 'Year')
              AND CreatedDate >= :startDate
              AND CreatedDate < :endDate.addDays(1)
              AND OwnerId = :currentUserId  // Filter by the logged-in user's ID
        ];

        // Group records by their Period__c field
        for (TurnOver_Discounts__c record : records) {
            if (!resultMap.containsKey(record.Period__c)) {
                resultMap.put(record.Period__c, new List<TurnOver_Discounts__c>());
            }
            resultMap.get(record.Period__c).add(record);
        }
        
        System.debug('resultMap: ' + resultMap);
        
        return resultMap;
    }

    // ProductWrapper class to wrap product data for use in LWC
    public class ProductWrapper {
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal price;

        public ProductWrapper(Id id, String name, Decimal price) {
            this.productId = id;
            this.productName = name;
            this.price = price;
        }
    }

    // Method to get products by month and year for the logged-in user
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getProductsByMonthYear(Integer startYear, Integer startMonth, Integer endYear, Integer endMonth) {
        // Get the logged-in user's ID
        Id currentUserId = UserInfo.getUserId();

        Date startDate;
        Date endDate;

        if (startYear != null && startMonth != null) {
            startDate = Date.newInstance(startYear, startMonth, 1);
        }
        if (endYear != null && endMonth != null) {
            endDate = Date.newInstance(endYear, endMonth, 1).addMonths(1).addDays(-1);
        }

        // Get the standard pricebook ID
        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        List<PricebookEntry> entries;

        // Query PricebookEntry records filtered by the logged-in user and selected date range
        if (startDate != null && endDate != null) {
            entries = [
                SELECT Product2Id, Product2.Name, UnitPrice, Product2.CreatedDate
                FROM PricebookEntry
                WHERE IsActive = true
                  AND Pricebook2Id = :standardPricebookId
                  AND Product2.CreatedDate >= :startDate 
                  AND Product2.CreatedDate <= :endDate
                  AND CreatedById = :currentUserId  // Filter by the logged-in user's ID
            ];
        } else {
            entries = [
                SELECT Product2Id, Product2.Name, UnitPrice
                FROM PricebookEntry
                WHERE IsActive = true 
                  AND Pricebook2Id = :standardPricebookId
                  AND CreatedById = :currentUserId  // Filter by the logged-in user's ID
            ];
        }

        List<ProductWrapper> wrapped = new List<ProductWrapper>();
        
        // Wrap the data into ProductWrapper objects
        for (PricebookEntry pbe : entries) {
            wrapped.add(new ProductWrapper(pbe.Product2Id, pbe.Product2.Name, pbe.UnitPrice));
        }

        System.debug('wrapped: ' + wrapped);
        
        return wrapped;
    }
}