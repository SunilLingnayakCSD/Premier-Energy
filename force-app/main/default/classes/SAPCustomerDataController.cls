@RestResource(urlMapping='/sapCustomerData/*')
global with sharing class SAPCustomerDataController {

    @HttpPost
    global static void upsertAddressOnly() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String reqBody = req.requestBody.toString();
            Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(reqBody);

            if (!input.containsKey('addresses')) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Missing "addresses" key.');
                return;
            }

            List<Object> rawList = (List<Object>) input.get('addresses');

            // Convert to proper type
            List<Map<String, Object>> typedList = new List<Map<String, Object>>();
            for (Object obj : rawList) {
                typedList.add((Map<String, Object>) obj);
            }

            // 🧠 Enqueue the job
            System.enqueueJob(new customerAddressUpsert(typedList));

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Success');
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
}