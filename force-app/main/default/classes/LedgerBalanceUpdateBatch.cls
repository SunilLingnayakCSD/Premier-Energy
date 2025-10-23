global without sharing class LedgerBalanceUpdateBatch implements Database.Batchable<LedgerBalanceUpdateBatch.LedgerWrapper> {

    global class LedgerWrapper {
        public String customerCode;
        public Decimal amountValue;
    }

    private List<LedgerWrapper> allEntries;

    public LedgerBalanceUpdateBatch(List<LedgerWrapper> entries) {
        this.allEntries = entries;
    }

    global Iterable<LedgerWrapper> start(Database.BatchableContext context) {
        return allEntries;
    }

    global void execute(Database.BatchableContext context, List<LedgerWrapper> scope) {
    // Step 1: Group and Sum Amounts by Customer_Code
    Map<String, Decimal> summedAmounts = new Map<String, Decimal>();
    for (LedgerWrapper l : scope) {
        if (String.isNotBlank(l.customerCode)) {
            String custCode = l.customerCode.trim();
            Decimal existing = summedAmounts.containsKey(custCode) ? summedAmounts.get(custCode) : 0;
            summedAmounts.put(custCode, existing + l.amountValue);
        }
    }

    // Step 2: Query Address__c records for those customer codes
    Set<String> customerCodes = summedAmounts.keySet();
    Map<String, Address__c> existingMap = new Map<String, Address__c>();
    for (Address__c addr : [
        SELECT Id, Customer_Code__c, Amount__c
        FROM Address__c
        WHERE Customer_Code__c IN :customerCodes
    ]) {
        existingMap.put(addr.Customer_Code__c, addr);
    }

    // Step 3: Update Address__c records with summed values
    List<Address__c> toUpdate = new List<Address__c>();
    for (String custCode : summedAmounts.keySet()) {
        if (existingMap.containsKey(custCode)) {
            Address__c addr = existingMap.get(custCode);
            addr.Amount__c = summedAmounts.get(custCode);
            toUpdate.add(addr);
            System.debug('>>> Updating ' + custCode + ' with Amount__c: ' + addr.Amount__c);
        } else {
            System.debug('>>> Skipping - No Address__c found for Customer_Code__c: ' + custCode);
        }
    }

    if (!toUpdate.isEmpty()) {
        update toUpdate;
        System.debug('>>> Total Updated Records: ' + toUpdate.size());
    }
}


    global void finish(Database.BatchableContext context) {
        System.debug('>>> LedgerBalanceBatch Finished');
    }

    // Parser utility to convert JSON to wrapper list
    public static List<LedgerWrapper> parseJson(String jsonBody) {
        List<LedgerWrapper> result = new List<LedgerWrapper>();
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

        if (!parsed.containsKey('ledgerUpdates')) {
            throw new CalloutException('Missing "ledgerUpdates" key');
        }

        List<Object> rawList = (List<Object>) parsed.get('ledgerUpdates');
        for (Object obj : rawList) {
            Map<String, Object> mapEntry = (Map<String, Object>) obj;
            LedgerWrapper l = new LedgerWrapper();
            l.customerCode = String.valueOf(mapEntry.get('Customer_Code'));
            l.amountValue = mapEntry.containsKey('Amount') ? Decimal.valueOf(String.valueOf(mapEntry.get('Amount'))) : 0;
            result.add(l);
        }

        return result;
    }
}