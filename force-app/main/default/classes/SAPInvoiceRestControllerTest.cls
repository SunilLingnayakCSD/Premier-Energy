@isTest
private class SAPInvoiceRestControllerTest {
    @isTest
    static void testRunBatch_Success() {
        // Prepare mock Order and Product2 for lookups
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            SAP_Order_Id__c = 'SO1234'
        );
        insert ord;

        Product2 prod = new Product2(Name = 'Test Product', Material_Number__c = 'MAT001');
        insert prod;

        // Prepare the valid JSON body
        String validJson = JSON.serialize(new Map<String, Object>{
            'root' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'SAP_Invoice_Number'      => 'INV001',
                    'SAP_Sales_Order_Number'  => 'SO1234',
                    'Document_Type'           => 'Domestic Invoice',
                    'Invoice_Date'            => '2025-07-15',
                    'Sales_Doc_No'            => 'SD12345',
                    'LineItems' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'Material_Number'      => 'MAT001',
                            'Material_Description' => 'Test Material',
                            'Quantity'             => '10',
                            'Quantity_Unit'        => 'EA',
                            'Amount'               => '500.00',
                            'Amount_Currency'      => 'INR',
                            'Discount'             => '25.00',
                            'CGST'                 => '5.00',
                            'SGST'                 => '5.00',
                            'IGST'                 => '0.00'
                        }
                    }
                }
            }
        });

        // Mock REST context
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/sapInvoiceData/';
        req.requestBody = Blob.valueOf(validJson);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Execute REST method
        Test.startTest();
        SAPInvoiceRestController.runBatch();
        Test.stopTest();

        // Validate response
        System.assertEquals(202, RestContext.response.statusCode);
        String response = RestContext.response.responseBody.toString();
        System.assert(response.contains('"status":"Success"'), 'Expected success response');

        // Verify invoice was inserted
        List<Invoice__c> invoices = [SELECT Id, Invoice_Number__c FROM Invoice__c WHERE Invoice_Number__c = 'INV001'];
        System.assertEquals(1, invoices.size());

        // Verify line item was inserted
        List<Invoice_Line_Item__c> lineItems = [SELECT Id, Amount__c FROM Invoice_Line_Item__c WHERE Invoice__c = :invoices[0].Id];
        System.assertEquals(1, lineItems.size());
        System.assertEquals(500.00, lineItems[0].Amount__c);
    }

    @isTest
    static void testRunBatch_InvalidJson() {
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/sapInvoiceData/';
        req.requestBody = Blob.valueOf('{invalid json}');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        SAPInvoiceRestController.runBatch();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"status":"error"'));
    }
}