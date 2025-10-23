public without sharing class TurnOverController {    
  @AuraEnabled(cacheable=true)
public static Map<String, List<AggregatePayoutResult>> getFilteredTurnover(Date startDate, Date endDate) 
{
    Id currentUserId = UserInfo.getUserId();
    User currentUser = [
        SELECT Id, Contact.AccountId
        FROM User
        WHERE Id = :currentUserId
        LIMIT 1
    ];

    Id distributorAccountId = currentUser.Contact.AccountId;

    // Get all TOD configurations for the distributor that overlap with the date range
    List<TurnOver_Discounts__c> allDiscounts = [
        SELECT Id, Distributor__c, Period__c, Valid_From__c, Valid_To__c,
               Target_Unit__c, To_Target__c, Payout__c, Payout_NDCR__c,
               Achieved__c
        FROM TurnOver_Discounts__c
        WHERE Distributor__c = :distributorAccountId
        AND Valid_From__c <= :endDate
        AND Valid_To__c >= :startDate
        ORDER BY To_Target__c DESC NULLS LAST
    ];

    // Get all invoices for the distributor within the date range
    List<Invoice__c> allInvoices = [
        SELECT Id, Invoice_Date__c, CreatedDate
        FROM Invoice__c
        WHERE Account__c = :distributorAccountId
        AND CreatedDate >= :startDate
        AND CreatedDate <= :endDate
    ];

    // Get all invoice line items for the invoices
    Map<Id, List<Invoice_Line_Item__c>> invoiceLineMap = new Map<Id, List<Invoice_Line_Item__c>>();
    for (Invoice_Line_Item__c line : [
        SELECT Id, Invoice__c, Quantity__c,
               Product__r.DCR_NonDCR__c, Product__r.Wp__c
        FROM Invoice_Line_Item__c
        WHERE Invoice__c IN :allInvoices
    ]) {
        if (!invoiceLineMap.containsKey(line.Invoice__c)) {
            invoiceLineMap.put(line.Invoice__c, new List<Invoice_Line_Item__c>());
        }
        invoiceLineMap.get(line.Invoice__c).add(line);
    }

    // Prepare the result structure
    Map<String, List<AggregatePayoutResult>> categorizedResults = new Map<String, List<AggregatePayoutResult>>();
    categorizedResults.put('Month', new List<AggregatePayoutResult>());
    categorizedResults.put('Quarter', new List<AggregatePayoutResult>());
    categorizedResults.put('Year', new List<AggregatePayoutResult>());

    // Process monthly TODs
    processPeriodTODs('Month', allDiscounts, allInvoices, invoiceLineMap, categorizedResults, startDate, endDate);
    
    // Process quarterly TODs
    processPeriodTODs('Quarter', allDiscounts, allInvoices, invoiceLineMap, categorizedResults, startDate, endDate);
    
    // Process yearly TODs
    processPeriodTODs('Year', allDiscounts, allInvoices, invoiceLineMap, categorizedResults, startDate, endDate);

    return categorizedResults;
}

// Helper method to process TODs by period (Month/Quarter/Year)
private static void processPeriodTODs(String period, List<TurnOver_Discounts__c> allDiscounts, 
                                    List<Invoice__c> allInvoices, Map<Id, List<Invoice_Line_Item__c>> invoiceLineMap,
                                    Map<String, List<AggregatePayoutResult>> categorizedResults,
                                    Date startDate, Date endDate) {
    
    // Filter TODs for this period
    List<TurnOver_Discounts__c> periodDiscounts = new List<TurnOver_Discounts__c>();
    for (TurnOver_Discounts__c d : allDiscounts) {
        if (d.Period__c == period) {
            periodDiscounts.add(d);
        }
    }
    
    if (periodDiscounts.isEmpty()) return;

    // Group TODs by their date range
    Map<String, List<TurnOver_Discounts__c>> discountMap = new Map<String, List<TurnOver_Discounts__c>>();
    for (TurnOver_Discounts__c d : periodDiscounts) {
        String key = d.Distributor__c + '|' + d.Period__c + '|' + d.Valid_From__c + '|' + d.Valid_To__c;
        if (!discountMap.containsKey(key)) {
            discountMap.put(key, new List<TurnOver_Discounts__c>());
        }
        discountMap.get(key).add(d);
    }

    // Process each TOD group
    for (String key : discountMap.keySet()) {
        List<TurnOver_Discounts__c> groups = discountMap.get(key);
        TurnOver_Discounts__c ref = groups[0];
        
        // For monthly TODs, break down by each month in the TOD's date range
        if (period == 'Month') {
            Date monthStart = ref.Valid_From__c;
            while (monthStart <= ref.Valid_To__c && monthStart <= endDate) {
                Date monthEnd = monthStart.addMonths(1).toStartOfMonth().addDays(-1);
                if (monthEnd > ref.Valid_To__c) monthEnd = ref.Valid_To__c;
                if (monthEnd > endDate) monthEnd = endDate;
                
                processTimePeriod(monthStart, monthEnd, groups, allInvoices, invoiceLineMap, 
                                 categorizedResults, period, monthStart.month() + '/' + monthStart.year());
                
                monthStart = monthEnd.addDays(1);
            }
        }
        // For quarterly TODs, use the hardcoded quarters
        else if (period == 'Quarter') {
            // Determine which quarters overlap with the TOD's date range
            List<QuarterPeriod> quarters = getQuarterPeriods(ref.Valid_From__c, ref.Valid_To__c, startDate, endDate);
            
            for (QuarterPeriod qp : quarters) {
                processTimePeriod(qp.startDate, qp.endDate, groups, allInvoices, invoiceLineMap, 
                                 categorizedResults, period, 'Q' + qp.quarterNumber + ' ' + qp.yearString);
            }
        }
        // For yearly TODs, use the TOD's configured year (Apr-Mar)
        else if (period == 'Year') {
            // Process the full year period
            processTimePeriod(ref.Valid_From__c, ref.Valid_To__c, groups, allInvoices, invoiceLineMap, 
                             categorizedResults, period, 
                             'FY ' + ref.Valid_From__c.year() + '-' + ref.Valid_To__c.year());
        }
    }
}

// Helper class for quarter periods
private class QuarterPeriod {
    Date startDate;
    Date endDate;
    Integer quarterNumber;
    String yearString;
    
    public QuarterPeriod(Date s, Date e, Integer q, String y) {
        startDate = s;
        endDate = e;
        quarterNumber = q;
        yearString = y;
    }
}

// Get the quarter periods that overlap with the TOD's date range
private static List<QuarterPeriod> getQuarterPeriods(Date todStart, Date todEnd, Date queryStart, Date queryEnd) {
    List<QuarterPeriod> quarters = new List<QuarterPeriod>();
    
    // Define all possible quarters that might overlap
    Date currentQuarterStart = Date.newInstance(todStart.year(), 4, 1); // Start with April
    Integer currentQuarter = 1;
    
    while (currentQuarterStart <= todEnd) {
        Date quarterEnd = currentQuarterStart.addMonths(3).addDays(-1);
        
        // Check if this quarter overlaps with the query period
        if (!(quarterEnd < queryStart || currentQuarterStart > queryEnd)) {
            // Determine the fiscal year label
            String yearLabel;
            if (currentQuarterStart.month() <= 3) {
                yearLabel = String.valueOf(currentQuarterStart.year() - 1) + '-' + currentQuarterStart.year();
            } else {
                yearLabel = String.valueOf(currentQuarterStart.year()) + '-' + (currentQuarterStart.year() + 1);
            }
            
            quarters.add(new QuarterPeriod(
                currentQuarterStart < queryStart ? queryStart : currentQuarterStart,
                quarterEnd > queryEnd ? queryEnd : quarterEnd,
                currentQuarter,
                yearLabel
            ));
        }
        
        currentQuarterStart = currentQuarterStart.addMonths(3);
        currentQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1;
    }
    
    return quarters;
}

// Process a specific time period (month/quarter/year)
private static void processTimePeriod(Date periodStart, Date periodEnd, List<TurnOver_Discounts__c> discounts,
                                    List<Invoice__c> allInvoices, Map<Id, List<Invoice_Line_Item__c>> invoiceLineMap,
                                    Map<String, List<AggregatePayoutResult>> categorizedResults,
                                    String periodType, String periodLabel) {
    
    Decimal totalActualMwp = 0;
    Decimal totalDcrSales = 0; // In watts
    Decimal totalNdcrSales = 0; // In watts

    // Calculate sales for invoices that fall within this period
    for (Invoice__c inv : allInvoices) {
        if (inv.CreatedDate >= periodStart && inv.CreatedDate <= periodEnd) {
            List<Invoice_Line_Item__c> lines = invoiceLineMap.get(inv.Id);
            if (lines != null && !lines.isEmpty()) {
                for (Invoice_Line_Item__c line : lines) {
                    Decimal qty = line.Quantity__c != null ? line.Quantity__c : 0;
                    Decimal wp = (line.Product__r != null && line.Product__r.Wp__c != null) ? line.Product__r.Wp__c : 0;
                    
                    // Calculate actual sales in watts (not MWp for DCR/Non-DCR)
                    String cat = line.Product__r != null ? line.Product__r.DCR_NonDCR__c : '';
                    if (cat == 'DCR') {
                        totalDcrSales += (qty * wp);
                    } else if (cat == 'NDCR') {
                        totalNdcrSales += (qty * wp);
                    }
                    
                    // Calculate total in MWp for target comparison
                    totalActualMwp += (qty * wp) / 1000000;
                }
            }
        }
    }

    Decimal netPayout = 0;
    Decimal matchedTarget = 0;
    TurnOver_Discounts__c matchedDiscount = null;
    
    // Process TOD records in descending order of To_Target__c
    for (TurnOver_Discounts__c d : discounts) {
        Decimal toTarget = d.To_Target__c != null ? d.To_Target__c : Decimal.valueOf(999999999);
        
        if (totalActualMwp > toTarget) {
            matchedTarget = toTarget;
            netPayout = (totalDcrSales * (d.Payout__c != null ? d.Payout__c : 0)) 
                      + (totalNdcrSales * (d.Payout_NDCR__c != null ? d.Payout_NDCR__c : 0));
            
            matchedDiscount = d;
            break; // Use the first matching bracket (highest target achieved)
        }
    }

    // Create the result object
    AggregatePayoutResult payout = new AggregatePayoutResult(
        matchedDiscount != null ? matchedDiscount.Distributor__c : null,
        periodType,
        periodStart,
        periodEnd,
        totalActualMwp,
        totalDcrSales,
        totalNdcrSales,
        netPayout,
        matchedTarget
    );
    
    // Add period label for display
    payout.periodLabel = periodLabel;

    // Add to results
    categorizedResults.get(periodType).add(payout);
}

// Result wrapper class
public class AggregatePayoutResult {
    @AuraEnabled public Id distributorAccountId;
    @AuraEnabled public String period;
    @AuraEnabled public Date validFrom;
    @AuraEnabled public Date validTo;
    @AuraEnabled public Decimal totalActualMwp;
    @AuraEnabled public Decimal dcrSales;
    @AuraEnabled public Decimal ndcrSales;
    @AuraEnabled public Decimal netPayout;
    @AuraEnabled public Decimal matchedTarget;
    @AuraEnabled public String periodLabel; // Added for display purposes

    public AggregatePayoutResult(Id distributorAccountId, String period, Date validFrom, Date validTo,
                               Decimal totalActualMwp, Decimal dcrSales, Decimal ndcrSales,
                               Decimal netPayout, Decimal matchedTarget) {
        this.distributorAccountId = distributorAccountId;
        this.period = period;
        this.validFrom = validFrom;
        this.validTo = validTo;
        this.totalActualMwp = totalActualMwp;
        this.dcrSales = dcrSales;
        this.ndcrSales = ndcrSales;
        this.netPayout = netPayout;
        this.matchedTarget = matchedTarget;
    }
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