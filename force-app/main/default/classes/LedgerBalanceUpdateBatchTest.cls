@isTest
private class LedgerBalanceUpdateBatchTest {

    // Setup test Address__c records that can be matched and updated
    @testSetup
    static void setupData() {
        List<Address__c> addresses = new List<Address__c>{
            new Address__c(Name = 'Customer A', Customer_Code__c = '10001', Amount__c = 0),
            new Address__c(Name = 'Customer B', Customer_Code__c = '10002', Amount__c = 0),
            new Address__c(Name = 'Customer C', Customer_Code__c = '10003', Amount__c = 0)
        };
        insert addresses;
    }

   @isTest
static void testBatchExecution_UpdateAmounts() {
    List<LedgerBalanceUpdateBatch.LedgerWrapper> input = new List<LedgerBalanceUpdateBatch.LedgerWrapper>();

    LedgerBalanceUpdateBatch.LedgerWrapper lw1 = new LedgerBalanceUpdateBatch.LedgerWrapper();
    lw1.customerCode = '10001';
    lw1.amountValue = 100;

    LedgerBalanceUpdateBatch.LedgerWrapper lw2 = new LedgerBalanceUpdateBatch.LedgerWrapper();
    lw2.customerCode = '10002';
    lw2.amountValue = 200;

    LedgerBalanceUpdateBatch.LedgerWrapper lw3 = new LedgerBalanceUpdateBatch.LedgerWrapper();
    lw3.customerCode = '10001';
    lw3.amountValue = 50;

    input.add(lw1);
    input.add(lw2);
    input.add(lw3);

    Test.startTest();
    Database.executeBatch(new LedgerBalanceUpdateBatch(input), 3);
    Test.stopTest();

    // Validate updated records
    Map<String, Decimal> expected = new Map<String, Decimal>{
        '10001' => 150,
        '10002' => 200
    };

    List<Address__c> updated = [
        SELECT Customer_Code__c, Amount__c
        FROM Address__c
        WHERE Customer_Code__c IN :expected.keySet()
    ];

    System.assertEquals(2, updated.size(), 'Two address records should be updated');
    for (Address__c addr : updated) {
        System.assertEquals(expected.get(addr.Customer_Code__c), addr.Amount__c,
            'Amount__c should be correctly summed for Customer_Code__c ' + addr.Customer_Code__c);
    }
}


  @isTest
static void testBatchExecution_SkipUnmatchedCustomer() {
    // Insert matching Address__c record
    Address__c testAddr = new Address__c(
        Name = 'Customer C',
        Customer_Code__c = '10003',
        Amount__c = 0
    );
    insert testAddr;

    // Create a matching LedgerWrapper entry
    LedgerBalanceUpdateBatch.LedgerWrapper lw = new LedgerBalanceUpdateBatch.LedgerWrapper();
    lw.customerCode = '10003';
    lw.amountValue = 300;

    // Only use one record to ensure single batch execution
    List<LedgerBalanceUpdateBatch.LedgerWrapper> input = new List<LedgerBalanceUpdateBatch.LedgerWrapper>{ lw };

    Test.startTest();
    Database.executeBatch(new LedgerBalanceUpdateBatch(input), 1);
    Test.stopTest();

    // Query and assert updated record
    Address__c updated = [SELECT Amount__c FROM Address__c WHERE Id = :testAddr.Id];
    System.assertEquals(300, updated.Amount__c, 'Amount__c should be updated to 300 for matching Customer_Code__c');
}


    @isTest
    static void testParseJsonMethod() {
        String jsonInput = JSON.serialize(new Map<String, Object>{
            'ledgerUpdates' => new List<Map<String, Object>>{
                new Map<String, Object>{ 'Customer_Code' => '10001', 'Amount' => '123.45' },
                new Map<String, Object>{ 'Customer_Code' => '10002', 'Amount' => '678.90' }
            }
        });

        List<LedgerBalanceUpdateBatch.LedgerWrapper> result = LedgerBalanceUpdateBatch.parseJson(jsonInput);
        System.assertEquals(2, result.size(), 'Should parse 2 records');
        System.assertEquals('10001', result[0].customerCode);
        System.assertEquals(123.45, result[0].amountValue);
    }

    @isTest
    static void testParseJson_MissingKey() {
        String badJson = JSON.serialize(new Map<String, Object>{ 'invalidKey' => 'oops' });
        try {
            LedgerBalanceUpdateBatch.parseJson(badJson);
            System.assert(false, 'Should have thrown exception for missing key');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Missing "ledgerUpdates"'), 'Expected missing key exception');
        }
    }
}