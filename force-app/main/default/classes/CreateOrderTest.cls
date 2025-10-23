@IsTest
private class CreateOrderTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account', Customer_Code__c = 'CUST001');
        insert acc;

        // Create test Product
        Product2 prod = new Product2(Name = 'Test Product', Product_Details__c = 'PROD-001', Family = 'Test', IsActive = true);
        insert prod;

        Id stdPbId = Test.getStandardPricebookId();

        // Create Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Get Sales Order RecordType
        Id salesOrderRtId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();

        // Create Orders
        Order ord1 = new Order(
            Name = 'Order1',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            RecordTypeId = salesOrderRtId,
            Pricebook2Id = stdPbId,
            Distribution_Channel__c = '10',
            Division__c = '10',
            Incolocation__c = 'LOC1',
            Incoterms__c = 'EXW',
            Payment_Terms__c = 'NET30',
            Plant__c = 'PLANT1',
            Sales_Org__c = '2000',
            Segment__c = 'CELL_EXPORT',
            Bill_To_Customer_Code__c = 'BILL001',
            Ship_To_Customer_Code__c = 'SHIP001',
            Shipping_Point__c = 'SP1',
            PoNumber = 'PO001',
            Product_Category__c = 'MODULE'
           // Cust_Ref_Date__c = Date.today()
        );

        insert ord1;

        // OrderItem
        OrderItem oi1 = new OrderItem(
            OrderId = ord1.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id,
            Material_Number__c = 'MAT001',
            Segment1__c = 'CELL_EXPORT',
            DCR_Non_DCR__c = 'DCR'
           // CurrencyIsoCode = 'USD'
        );

        insert oi1;
    }

    @IsTest
    static void testGetAllOrderDetails() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'GET';
        req.requestURI = '/services/apexrest/externalOrders/';
        RestContext.request = req;

        Test.startTest();
        List<CreateOrder.ExternalOrderWrapper> result = CreateOrder.getAllOrderDetails();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'At least one order should be returned');

        for (CreateOrder.ExternalOrderWrapper wrap : result) {
            System.assertEquals('ZDOR', wrap.Order_Type);
            System.assertEquals('2000', wrap.Sales_org);
            System.assertEquals('10', wrap.Distribution_Channel);
            System.assertEquals('10', wrap.Division);
            System.assertEquals('BILL001', wrap.Sold_To_Party);
            System.assertEquals('SHIP001', wrap.Ship_to_Party);
            System.assertEquals('NET30', wrap.Pyt_terms);
            System.assertEquals('EXW', wrap.Incoterms);
            System.assertEquals('LOC1', wrap.Inco_Location);
            System.assertEquals('MODULE', wrap.productType);
            System.assert(wrap.Line_items.size() > 0, 'Line items should be populated');
        }
    }

    @IsTest
    static void testUpdateSAPOrderId_Success() {
        Order ord = [SELECT Id, OrderNumber FROM Order LIMIT 1];
        String reqBody = '{"OrderNumber":"' + ord.OrderNumber + '", "SAPOrderId":"SAP123", "Message":"Success"}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/externalOrders/';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;

        Test.startTest();
        Map<String, String> res = CreateOrder.updateSAPOrderId();
        Test.stopTest();

        System.assertEquals('success', res.get('status'));
        System.assert(res.get('message').contains('Order updated'));

        Order updated = [SELECT SAP_Order_Id__c, Response_Message__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('SAP123', updated.SAP_Order_Id__c);
        System.assertEquals('Success', updated.Response_Message__c);
    }

    @IsTest
    static void testUpdateSAPOrderId_MissingFields() {
        String reqBody = '{"OrderNumber":"0000001"}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/externalOrders/';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;

        Test.startTest();
        Map<String, String> res = CreateOrder.updateSAPOrderId();
        Test.stopTest();

        System.assertEquals('error', res.get('status'));
        System.assertEquals('Missing OrderNumber or SAPOrderId.', res.get('message'));
    }

    @IsTest
    static void testUpdateSAPOrderId_OrderNotFound() {
        String reqBody = '{"OrderNumber":"999999", "SAPOrderId":"SAP999", "Message":"Not Found"}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/externalOrders/';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;

        Test.startTest();
        Map<String, String> res = CreateOrder.updateSAPOrderId();
        Test.stopTest();

        System.assertEquals('error', res.get('status'));
        System.assert(res.get('message').contains('OrderNumber not found'));
    }

    @IsTest
    static void testUpdateSAPOrderId_Exception() {
        String reqBody = '{Invalid JSON}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/externalOrders/';
        req.requestBody = Blob.valueOf(reqBody);
        RestContext.request = req;

        Test.startTest();
        Map<String, String> res = CreateOrder.updateSAPOrderId();
        Test.stopTest();

        System.assertEquals('error', res.get('status'));
        System.assert(res.get('message').startsWith('Exception'));
    }

    @IsTest
    static void testLineItemWrapperConstructor() {
        CreateOrder.LineItemWrapper item = new CreateOrder.LineItemWrapper(
            'TestProd', 'CELL_EXPORT', 5, 'PLANT1', 'SP1', 100.0, 'USD', 'MAT001', 'DCR'
        );

        System.assertEquals('TestProd', item.Product);
        System.assertEquals('CELL_EXPORT', item.Segment);
        System.assertEquals(5, item.Qty);
        System.assertEquals('PLANT1', item.Plant);
        System.assertEquals('SP1', item.Shipping_point);
        System.assertEquals(100.0, item.Price);
        System.assertEquals('USD', item.currencyVal);
        System.assertEquals('MAT001', item.Material);
        System.assertEquals('DCR', item.DCR_NON_DCR);
    }
}