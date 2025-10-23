@isTest
private class SAPLedgerAmountControllerTest {

    @isTest
    static void testRunLedgerBatch_Success() {
        // Step 1: Prepare valid request body
        String validJson = JSON.serialize(new Map<String, Object>{
            'ledgerUpdates' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Customer Code' => '10001',
                    'Amount'        => '1000.50'
                },
                new Map<String, Object>{
                    'Customer Code' => '10002',
                    'Amount'        => '250.75'
                }
            }
        });

        // Step 2: Set up mock REST context
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/updateLedgerBalance/';
        req.requestBody = Blob.valueOf(validJson);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Step 3: Run the controller method
        Test.startTest();
        SAPLedgerAmountController.runLedgerBatch();
        Test.stopTest();

        // Step 4: Assert response
        System.assertEquals(202, RestContext.response.statusCode, 'Expected success status code');
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"status":"Success"'), 'Expected success message in response');
    }

    @isTest
    static void testRunLedgerBatch_InvalidJson() {
        // Step 1: Set up invalid JSON
        String badJson = '{not a valid JSON}';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/updateLedgerBalance/';
        req.requestBody = Blob.valueOf(badJson);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Step 2: Run the controller method
        Test.startTest();
        SAPLedgerAmountController.runLedgerBatch();
        Test.stopTest();

        // Step 3: Assert failure response
        System.assertEquals(500, RestContext.response.statusCode, 'Expected error status code');
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"status":"error"'), 'Expected error response');
        System.assert(body.contains('Unexpected character'), 'Expected JSON parsing error');
    }
}