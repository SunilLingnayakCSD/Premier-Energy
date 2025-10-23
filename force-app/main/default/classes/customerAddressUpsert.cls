public class customerAddressUpsert implements Queueable {
    List<Map<String, Object>> rawList;
    static final Integer BATCH_SIZE = 500;

    public customerAddressUpsert(List<Map<String, Object>> rawList) {
        this.rawList = rawList;
    }

    public void execute(QueueableContext context) {
        if (rawList == null || rawList.isEmpty()) return;

        Integer li = Math.min(BATCH_SIZE, rawList.size());

        List<Map<String, Object>> currentBatch = new List<Map<String, Object>>();
        for (Integer i = 0; i < li; i++) {
            currentBatch.add(rawList[i]);
        }

        // ✅ Collect unique Customer Codes
        Set<String> customerCodes = new Set<String>();
        for (Map<String, Object> data : currentBatch) {
            if (data.containsKey('Customer_Address_Code')) {
                String code = (String) data.get('Customer_Address_Code');
                if (!String.isBlank(code)) {
                    customerCodes.add(code.trim());
                }
            }
        }

        // ✅ Fetch existing Address__c records
        Map<String, Address__c> existingMap = new Map<String, Address__c>();
        for (Address__c addr : [
            SELECT Id, Customer_Code__c
            FROM Address__c
            WHERE Customer_Code__c IN :customerCodes
        ]) {
            existingMap.put(addr.Customer_Code__c, addr);
        }

        List<Address__c> toInsert = new List<Address__c>();
        Map<Id, Address__c> toUpdateMap = new Map<Id, Address__c>(); // ✅ Use Map to avoid duplicate IDs

        // ✅ Prevent multiple inserts for same customer code
        Set<String> alreadyHandled = new Set<String>();

        for (Map<String, Object> data : currentBatch) {
            String custCode = (String) data.get('Customer_Address_Code');
            if (String.isBlank(custCode)) continue;
            custCode = custCode.trim();

            Boolean isUpdate = existingMap.containsKey(custCode);

            // Skip if we've already handled a new insert for this code
            if (!isUpdate && alreadyHandled.contains(custCode)) {
                continue;
            }

            Address__c addr;
            if (isUpdate) {
                addr = existingMap.get(custCode);
            } else {
                addr = new Address__c(Customer_Code__c = custCode);
                alreadyHandled.add(custCode);
            }

            addr.Name = truncate((String) data.get('Name'), 80);
            addr.Street__c = truncate((String) data.get('Street'), 255);
            addr.City__c = truncate((String) data.get('City'), 255);
            addr.State__c = truncate((String) data.get('State'), 255);
            addr.Country__c = truncate((String) data.get('Country'), 255);
            addr.Pincode__c = truncate((String) data.get('Pincode'), 10);
            addr.Address_Type__c = (String) data.get('Address_Type');
          

            if (isUpdate) {
                toUpdateMap.put(addr.Id, addr); // ✅ Only one per Id
            } else {
                toInsert.add(addr);
            }
        }

        // ✅ Perform DML
        try {
            if (!toInsert.isEmpty()) insert toInsert;
            if (!toUpdateMap.isEmpty()) update toUpdateMap.values(); // ✅ De-duplicated update
        } catch (DmlException e) {
            //HandleCustomException.LogException(e);
            System.debug('DML error: ' + e.getMessage());
        }

        // ✅ Enqueue remaining records
        if (rawList.size() > li) {
            List<Map<String, Object>> remaining = new List<Map<String, Object>>();
            for (Integer i = li; i < rawList.size(); i++) {
                remaining.add(rawList[i]);
            }
            System.enqueueJob(new customerAddressUpsert(remaining));
        }
    }

    private static String truncate(String input, Integer maxLen) {
        return (input != null && input.length() > maxLen) ? input.substring(0, maxLen) : input;
    }
}