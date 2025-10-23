@isTest
private class SAPCustomerDataControllerTest {

    @isTest
    static void testUpsertAddressOnly_Success() {
        // Prepare mock request body with valid address data
        String requestBody = JSON.serialize(new Map<String, Object>{
            'addresses' => new List<Object>{
                new Map<String, Object>{
                    'Customer_Code__c' => '10001',
                    'Street__c'        => '123 Main Street',
                    'City__c'          => 'Pune',
                    'State__c'         => 'MH',
                    'Country__c'       => 'India',
                    'Postal_Code__c'   => '411001'
                }
            }
        });

        // Set up the mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sapCustomerData/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        // Enqueueable job monitoring
        Test.startTest();
        SAPCustomerDataController.upsertAddressOnly();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Expected success status code');
        System.assert(RestContext.response.responseBody.toString().contains('Success'), 'Expected success message');
    }

    @isTest
    static void testUpsertAddressOnly_MissingKey() {
        // Missing "addresses" key
        String requestBody = JSON.serialize(new Map<String, Object>{
            'invalidKey' => 'test'
        });

        // Setup mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sapCustomerData/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SAPCustomerDataController.upsertAddressOnly();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Expected bad request status');
        System.assert(RestContext.response.responseBody.toString().contains('Missing'), 'Expected missing key error');
    }

    // Optional: Test exception scenario
    @isTest
    static void testUpsertAddressOnly_Exception() {
        // Malformed JSON
        String badRequestBody = '{this is not valid json';

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/sapCustomerData/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(badRequestBody);

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SAPCustomerDataController.upsertAddressOnly();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode, 'Expected server error for invalid JSON');
        System.assert(RestContext.response.responseBody.toString().contains('Error:'), 'Expected error message');
    }
}