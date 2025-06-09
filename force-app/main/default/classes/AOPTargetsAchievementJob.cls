global class AOPTargetsAchievementJob implements Schedulable, Database.Batchable<SObject> {

    Integer currentYear = Date.today().year();

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Distributor_Account__c
            FROM AOP_Targets__c
            WHERE Distributor_Account__c != null
            AND Distributor_Account__r.RecordType.DeveloperName = 'Distributor'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<AOP_Targets__c> targets) {
        Set<Id> accountIds = new Set<Id>();
        for (AOP_Targets__c t : targets) {
            accountIds.add(t.Distributor_Account__c);
        }

        List<Invoice__c> invoices = [
            SELECT Account__c, Invoice_Date__c, Amount__c
            FROM Invoice__c
            WHERE Account__c IN :accountIds
            AND CALENDAR_YEAR(Invoice_Date__c) = :currentYear
        ];

        Map<Id, Map<Integer, Decimal>> distributorMonthMap = new Map<Id, Map<Integer, Decimal>>();

        for (Invoice__c inv : invoices) {
            if (inv.Invoice_Date__c == null || inv.Amount__c == null) continue;

            Id acctId = inv.Account__c;
            Integer month = inv.Invoice_Date__c.month();

            if (!distributorMonthMap.containsKey(acctId)) {
                distributorMonthMap.put(acctId, new Map<Integer, Decimal>());
            }

            Map<Integer, Decimal> monthMap = distributorMonthMap.get(acctId);
            Decimal existing = monthMap.containsKey(month) ? monthMap.get(month) : 0;
            monthMap.put(month, existing + inv.Amount__c);
        }

        for (AOP_Targets__c target : targets) {
            Map<Integer, Decimal> monthMap = distributorMonthMap.get(target.Distributor_Account__c);
            if (monthMap == null) continue;

            target.April_Achieved__c     = monthMap.containsKey(4)  ? monthMap.get(4)  : 0;
            target.May_Achieved__c       = monthMap.containsKey(5)  ? monthMap.get(5)  : 0;
            target.June_Achieved__c      = monthMap.containsKey(6)  ? monthMap.get(6)  : 0;
            target.July_Achieved__c      = monthMap.containsKey(7)  ? monthMap.get(7)  : 0;
            target.August_Achieved__c    = monthMap.containsKey(8)  ? monthMap.get(8)  : 0;
            target.September_Achieved__c = monthMap.containsKey(9)  ? monthMap.get(9)  : 0;
            target.October_Achieved__c   = monthMap.containsKey(10) ? monthMap.get(10) : 0;
            target.November_Achieved__c  = monthMap.containsKey(11) ? monthMap.get(11) : 0;
            target.December_Achieved__c  = monthMap.containsKey(12) ? monthMap.get(12) : 0;
            target.January_Achieved__c   = monthMap.containsKey(1)  ? monthMap.get(1)  : 0;
            target.February_Achieved__c  = monthMap.containsKey(2)  ? monthMap.get(2)  : 0;
            target.March_Achieved__c     = monthMap.containsKey(3)  ? monthMap.get(3)  : 0;

            // Quarterly
            target.Q1_Achieved__c = target.April_Achieved__c + target.May_Achieved__c + target.June_Achieved__c;
            target.Q2_Achieved__c = target.July_Achieved__c + target.August_Achieved__c + target.September_Achieved__c;
            target.Q3_Achieved__c = target.October_Achieved__c + target.November_Achieved__c + target.December_Achieved__c;
            target.Q4_Achieved__c = target.January_Achieved__c + target.February_Achieved__c + target.March_Achieved__c;

            // Annual
            target.Annual_Achieved__c = target.Q1_Achieved__c + target.Q2_Achieved__c + target.Q3_Achieved__c + target.Q4_Achieved__c;
        }

        update targets;
    }

    global void finish(Database.BatchableContext bc) {
        // Optional
    }
}